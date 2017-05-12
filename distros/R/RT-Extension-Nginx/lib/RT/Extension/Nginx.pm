use 5.008003;
use strict;
use warnings;

package RT::Extension::Nginx;

our $VERSION = '0.03';

use File::Spec;
use File::Path qw(make_path);
use autodie;

=head1 NAME

RT::Extension::Nginx - optimized request tracker within minutes

=head1 SYNOPSIS

    perl Makefile.PL
    make
    make install

    cd /opt/rt4/local/plugins/RT-Extension-Nginx/
    ./sbin/rt-generate-nginx-conf
    ./sbin/rt-nginx-control start

=head1 DESCRIPTION

B<This is beta> software. Lacks some documentation.

Extension comes with two scripts:

=over 4

=item rt-generate-nginx-conf

Generates optimized nginx config from RT configuration and templates. Creates
required directories and files.

=item rt-nginx-control

Simple script that can start, stop and restart nginx and fcgi processes. Run
without arguments to see help.

=back

=head1 FEATURES

=head2 Fast web server in front

Nginx is very fast web server with low memory footprint.

=head2 Reverse proxy like setup

Two servers schema with web server in front and FastCGI (FCGI)
server running RT as backend. Nginx buffers replies from FCGI, so
heavy FCGI processes get free and ready to serve next request
before user gets the current request.

=head2 Forking FCGI

FCGI processes are forked so share some memory between processes
lowering memory footprint.

=head2 Serving images without FCGI

Nginx serves /NoAuth/images/ location from files without touching
FCGI and does it properly accounting local directory and plugins'
directories.

=head2 Semi-static serving of css and js

Files served from /NoAuth/css/ and /NoAuth/js/ locations are stored
on first request for re-use.

=head2 Content gziping

Html, css and js gzipped. For example size of the primary css file
drops from 78k down to 19kb.

=head2 TODO

A few things can be improved within RT and this extension, but it's
a good start.

=cut

sub RootPath { return (shift)->CreateVarDir }
sub FcgiTempPath { return (shift)->CreateVarDir('fcgi.temp') }
sub FcgiStoragePath { return (shift)->CreateVarDir('fcgi.storage') }

sub NginxConfigPath {
    return File::Spec->catfile( (shift)->RootPath, 'nginx.conf' );
}

sub CreateVarDir {
    my $self = shift;
    my $path = File::Spec->catdir( $RT::VarPath, 'nginx', @_ );
    make_path( $path );
    return $path;
}

sub SetupRights {
    my $self = shift;

    my ($wuid, $wgid) = ( ($self->GetWebUser)[0], ($self->GetWebGroup)[0] );
    my ($rtuid, $rtgid) = (stat $RT::EtcPath)[4, 5];

    my $root = $self->RootPath;

    chmod 0400, map File::Spec->catfile($root, $_), $self->Templates;
    chown $rtuid, $rtgid, map File::Spec->catfile($root, $_), $self->Templates;

    chmod 0770, $self->FcgiTempPath, $self->FcgiStoragePath;
    chown $wuid, $wgid, $self->FcgiTempPath, $self->FcgiStoragePath;

    chmod 0755, $self->RootPath;
    chown $rtuid, $rtgid, $self->RootPath;
}

sub Templates {
    return qw(nginx.conf rt.server.conf fcgi.include.conf mime.types);
}

sub FindExecutable {
    my $self = shift;
    my $name = shift;

    foreach my $dir ( File::Spec->path ) {
        my $file = File::Spec->catfile( $dir, $name );
        return $file if -e $file && -x _;
    }
    return undef;
}

sub GetWebUser {
    my $self = shift;
    my $id = (stat $RT::MasonDataDir)[4];
    return ($id, getpwuid $id);
}

sub GetWebGroup {
    my $self = shift;
    my $id = (stat $RT::MasonDataDir)[5];
    return ($id, getgrgid $id);
}

sub GetSystemUser {
    my $self = shift;
    return ($>, getpwuid $>);
}

sub GenerateFile {
    my $self = shift;
    my $name = shift;
    my $stash = shift;

    require RT::Plugin;
    my $from = RT::Plugin->new( name => 'RT::Extension::Nginx' )->Path('etc');

    return $self->ParseTemplate(
        From  => [$from, $name],
        To    => [$stash->{'nginx_root'}, $name],
        Stash => $stash,
    );
}

sub ParseTemplate {
    my $self = shift;
    my %args = @_;

    $_ = File::Spec->catfile(@$_) foreach grep ref $_, $args{'From'}, $args{'To'};

    use Text::Template;
    my $template = Text::Template->new(
        TYPE       => 'FILE',
        SOURCE     => $args{'From'},
        DELIMITERS => [qw(<% %>)],
        PREPEND    => 'use warnings;',
    );
    my $res = $template->fill_in( HASH => { stash => $args{'Stash'} } );
    return $res unless $args{'To'};

    open my $fh, '>', $args{'To'};
    print $fh $res;
    close $fh;

    return $res;
}


=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;
