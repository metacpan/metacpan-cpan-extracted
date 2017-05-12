package Plack::Middleware::Debug::Profiler::NYTProf;
use 5.008;
use strict;
use warnings;

use Plack::Util::Accessor qw(root exclude base_URL minimal no_merge_evals);
use Time::HiRes;
use File::Path qw(make_path);

use parent 'Plack::Middleware::Debug::Base';
our $VERSION = '0.06';

sub prepare_app {
    my $self = shift;
    $self->root($self->root || '/tmp');
    $self->base_URL($self->base_URL || '');
    $self->minimal($self->minimal || '0');
    $self->no_merge_evals($self->no_merge_evals || '0');
    $self->{files} = Plack::App::File->new(root => $self->root);

    unless(-d $self->root){
        make_path($self->root) or die "Cannot create directory " . $self->root;
    }

    # start=begin - start immediately (the default)
    # start=init  - start at beginning of INIT phase (after compilation)
    # start=end   - start at beginning of END phase
    # start=no    - don't automatically start
    $ENV{NYTPROF} ||= "addpid=1:start=begin:file=".$self->root."/nytprof.null.out";
    require Devel::NYTProf::Core;
    require Devel::NYTProf;

    $self->exclude($self->exclude || [qw(.*\.css .*\.png .*\.ico .*\.js)]);
    Carp::croak "exclude not an array" if ref($self->exclude) ne 'ARRAY';
}

sub call {
    my($self, $env) = @_;
    my $panel = $self->default_panel;

    if ($env->{PATH_INFO} =~ m!nytprofhtml!) {
        $env->{'plack.debug.disabled'} = 1;
        return $self->{files}->call($env);
    }

    foreach my $pattern (@{$self->exclude}) {
        if ($env->{PATH_INFO} =~ m!^$pattern$!) {
            return $self->SUPER::call($env);
        }
    }

    # $ENV{NYTPROF}'s addpid=1 will append ".$$" to the file
    DB::enable_profile($self->root."/nytprof.out"); 

    my $res = $self->SUPER::call($env);
    DB::disable_profile();
    DB::enable_profile($self->root."/nytprof.null.out");
    DB::disable_profile();

    $self->report($env);
    return $res;
}

sub run {
    my($self, $env, $panel) = @_;
    return sub {        
        my $res = shift;
        $panel->nav_subtitle(join ', ', 'OK', ( $self->minimal ? 'Minimal' : () ));
        $panel->content('<a href="'.$self->base_URL.'/nytprofhtml.'.$$.'/index.html" target="_blank">(open in a new window)</a><br>
          <iframe src ="'.$self->base_URL.'/nytprofhtml.'.$$.'/index.html" width="100%" height="100%">
          <p>Your browser does not support iframes.</p>
        </iframe>');
    };
}

sub report {
    my ( $self, $env ) = @_;
    if ( -f $self->root . "/nytprof.out.$$" ) {
        system "nytprofhtml"
          , ( $self->minimal ? '--minimal' : () )
          , ( $self->no_merge_evals ? '--no-mergeevals' : () )
          , "-f", $self->root . "/nytprof.out.$$" 
          , "-o", $self->root . "/nytprofhtml.$$";
    }
}

sub DESTROY {
    DB::finish_profile();
}

1;
__END__

=head1 NAME

Plack::Middleware::Debug::Profiler::NYTProf - Runs NYTProf on your app

=head2 SYNOPSIS

    use Plack::Builder;

    my $app = ...; ## Build your Plack App

    builder {
        enable 'Debug', panels =>['Profiler::NYTProf'];
        $app;
    };

    # or with options

    builder {
        enable 'Debug', panels => [
            [
                'Profiler::NYTProf',
                base_URL => 'http://example.com/NYTProf',
                root     => '/path/to/NYTProf',
                minimal  => 1,
            ]
        ];
        $app;
    };


=head1 DESCRIPTION

Adds a debug panel that runs and displays Devel::NYTProf on your perl source
code.

=head1 OPTIONS

This debug panel defines the following options.

=head2 root

Where to store nytprof.out and nytprofhtml output (default: '/tmp').

=head2 base_URL

By default, this module will grab requests with the string B<nytprofhtml> to
the server, and deliver the reports with Plack::App::File. If instead you don't
want to serve the reports from the same server you're debugging, then you can
set this option to the URL where the B<root> folder above can be reached.

=head2 exclude

List of excluded paths (default: [qw(.*\.css .*\.png .*\.ico .*\.js)]).

=head2 minimal

By default, B<nytprofhtml> will generate graphviz .dot files and
block/sub-level reports. Setting this to a true value will disable this
behaviour and make B<nytprofhtml> considerably faster.

=head2 no_merge_evals

By defaut, B<nytprofhtml> will merge string evals in the reports. Setting this
to a true value will disable this behaviour. B<Warning>: this will make
B<nytprohtml> considerably slower, and might timeout the HTTP request.

=head1 Environment Variable

=head2 NYTPROF

You can customize Devel::NYTProf's behaviour by setting the B<NYTPROF>
environment variable as specified in its documentation. However, this module
requires the following to hold:

=head3 addpid=1

=head3 start=begin

=head1 SEE ALSO

L<Plack::Middleware::Debug>
L<Devel::NYTProf>

=head1 AUTHOR

Sebastian de Castelberg, C<< <sdecaste@cpan.org> >>

=head1 CONTRIBUTORS

Nuba Princigalli, C<< <nuba@cpan.org> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
