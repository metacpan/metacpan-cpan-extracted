
=head1 NAME

SVN::Web::Test - automated web testing for SVN::Web

=head1 DESCRIPTION

=cut

package SVN::Web::Test;

use strict;
use warnings;

our $VERSION = 0.63;

use File::Path;
use File::Spec;
use File::Temp qw(tempdir);
use POSIX ();

use Test::More;

use SVN::Web;
use YAML ();

my $uri_base;
my $script;
my $fake_cgi = 0;

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    %$self = @_;

    my @mech_args = exists $self->{mech_args} ? $self->{mech_args} : ();

    $self->{_mech} =
      SVN::Web::Test::Mechanize->new(@mech_args);

    if ( !exists $self->{root_url} ) {
        if ( exists $self->{httpd_port} ) {
            $self->{root_url} = "http://localhost:$self->{httpd_port}/svnweb";
        }
        else {
            $self->{root_url} = "http://localhost/svnweb";
        }
    }

    $self->{repo_path} = File::Spec->rel2abs( $self->{repo_path} );
    $self->{repo_dump} = File::Spec->rel2abs( $self->{repo_dump} );

    $self->create_env();
    $self->create_install();

    return $self;
}

# Returns the Test::WWW::Mechanize object
sub mech {
    return shift->{_mech};
}

sub install_dir {
    return shift->{install_dir};
}

sub site_root {
    return shift->{root_url};
}

sub set_config {
    my $self = shift;
    my $opts = shift;

    $uri_base = $opts->{uri_base};
    $script   = $opts->{script};
    $fake_cgi = 1;

    my $config = {
        version => $VERSION,
        actions => {
            'browse' => {
                'class'       => 'SVN::Web::Browse',
                'action_menu' => {
                    'show'      => ['directory'],
                    'link_text' => '(browse directory)'
                }
            },
            'blame' => {
                'class'       => 'SVN::Web::Blame',
                'action_menu' => {
                    'show'      => ['file'],
                    'link_text' => '(view blame)'
                }
            },
            'checkout' => {
                'class'       => 'SVN::Web::Checkout',
                'action_menu' => {
                    'show'      => ['file'],
                    'link_text' => '(checkout)'
                }
            },
            'revision' => { 'class' => 'SVN::Web::Revision' },
            'view'     => {
                'class'       => 'SVN::Web::View',
                'action_menu' => {
                    'show'      => ['file'],
                    'link_text' => '(view file)'
                }
            },
            'diff' => { 'class' => 'SVN::Web::Diff' },
            'log'  => {
                'class'       => 'SVN::Web::Log',
                'action_menu' => {
                    'show'      => [ 'file', 'directory' ],
                    'link_text' => '(view revision log)'
                }
            },
           'rss' => {
                'class'       => 'SVN::Web::RSS',
                'action_menu' => {
                    'icon'      => '/css/trac/feed-icon-16x16.png',
                    'show'      => [ 'file', 'directory' ],
                    'head_only' => '1',
                    'link_text' => '(rss)'
                }
            },
            'list' => { 'class' => 'SVN::Web::List' }
        },
        cgi_class    => 'Plack::Request',
        templatedirs => ['template/trac'],
        %{ $opts->{config} },
    };

    SVN::Web::set_config($config);
}

# Create a Subversion repo from a dump file.
sub create_env {

    my $self = shift;

    plan skip_all => 'Test::WWW::Mechanize not installed'
      unless eval { require Test::WWW::Mechanize; 1; };

    plan skip_all => q{Can't find svnadmin}
      unless `svnadmin --version` =~ m/version/;

    rmtree( [ $self->{repo_path} ] ) if -d $self->{repo_path};
    $ENV{SVNFSTYPE} ||= ( ( $SVN::Core::VERSION =~ m/^1\.0/ ) ? 'bdb' : 'fsfs' );

    `svnadmin create --fs-type=$ENV{SVNFSTYPE} $self->{repo_path}`;
    `svnadmin load $self->{repo_path} < $self->{repo_dump}`;

}

# Create a scratch area, run svnweb-install.  The generated config.yaml
# file will be changed to list the repo created create_env().
#
# Returns the directory in which the scratch area is rooted.
sub create_install {

    my $self = shift;

    $self->{install_dir} = tempdir( CLEANUP => 1 );
    #warn "Created $self->{install_dir}\n";
    my $cwd = POSIX::getcwd();
    chdir( $self->{install_dir} );
    my $lib_dir = File::Spec->catdir( $cwd, 'blib', 'lib' );
    my $svnweb_install = File::Spec->catfile( $cwd, 'bin', 'svnweb-install' );

    system "$^X -I$lib_dir $svnweb_install";

    # Make the directory world-readable by all.  Otherwise, if Apache is
    # started as root the default behaviour is to set user/group to -1.
    # This results in the directory being unreadable by SVN::Web.
    chmod 0755, $self->{install_dir};

    chdir($cwd);    # Get back to the original directory

    # Change the config to point to the test repo
    my $config_file =
      File::Spec->catfile( $self->{install_dir}, 'config.yaml' );
    my $config = YAML::LoadFile($config_file);
    $config->{repos}{repos} = $self->{repo_path};
    YAML::DumpFile( $config_file, $config );

    return $self->{install_dir};
}

# Walk the site
sub walk_site {
    my $self = shift;
    my $test = shift;
    my $seen = shift || {};

    $test->($self);

    my @links = $self->mech()->links();
    for my $i ( 0 .. $#links ) {
        my $link_url = $links[$i]->url_abs;

        diag sprintf "Fetching %d/%d %s (%s)",
          $i + 1, $#links + 1, $link_url, $links[$i]->text()||''
          if exists $ENV{TEST_VERBOSE} and $ENV{TEST_VERBOSE};

        next if $seen->{$link_url};
        diag "Skipping $link_url", next
          if $link_url !~ m/(?:localhost|127\.0\.0\.1)/;

        ++$seen->{$link_url};

        $self->mech()->get($link_url);
        $self->walk_site( $test, $seen );
        $self->mech()->back;
    }
}

package SVN::Web::Test::Mechanize;

use base qw(Test::WWW::Mechanize);

use Plack::Test;
use SVN::Web;
use Plack::Builder;

sub send_request {
    my ( $self, $request ) = @_;

    my $buf = '';
    my $uri = $request->uri;
    my $response;

    my $app = builder {
                mount "/svnweb" => sub { SVN::Web->run_psgi(@_) },
            };

    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => $uri);
            $response = $cb->($req);
        }
    ;

    return $response;
}

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt> and E<lt>nik@cpan.org<gt>.

Dean Hamstead E<lt>dean@fragfest.com.auE<gt>

=head1 COPYRIGHT

Copyright (c) 2012 by Dean Hamstead E<lt>dean@fragfest.com.auE<gt>

Copyright (c) 2005-2007 by Nik Clayton E<lt>nik@cpan.org<gt>.

Copyright (c) 2004 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
