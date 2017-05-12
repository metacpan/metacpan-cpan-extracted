package Plack::Middleware::Profiler::NYTProf;
use strict;
use warnings;
use parent qw(Plack::Middleware);
our $VERSION = '0.17';

use Plack::Util::Accessor qw(
    enable_profile
    enable_reporting
    env_nytprof
    generate_profile_id
    profiling_result_dir
    report_dir
    nytprofhtml_path
    profiling_result_file_name
    nullfile_name
    before_profile
    after_profile
);

use File::Spec;
use Time::HiRes qw(gettimeofday);
use File::Which;

use constant PROFILE_ID       => 'psgix.profiler.nytprof.reqid';
use constant PROFILER_ENABLED => 'psgix.profiler.nytprof.enabled';

my %PROFILER_SETUPED;

my $NYTPROF_LOADED = 0;

# Devel::NYTProf requires to be loaded in a compile phase.
# So you should call this method in the BEGIN of your app.psgi with the NYTPROF environment variable.
sub preload {
    $ENV{NYTPROF} ||= _default_env();
    require Devel::NYTProf;
    DB::disable_profile();
    $NYTPROF_LOADED = 1;
}

sub _default_env { 'start=no:sigexit=int' }

sub prepare_app {
    my $self = shift;

    $self->_setup_profile_id;
    $self->_setup_profiling_file_paths;
    $self->_setup_profiling_hooks;
    $self->_setup_enable_profile;
    $self->_setup_enable_reporting;
    $self->_setup_report_dir;
    $self->_setup_nytprofhtml_path;
}

sub _setup_profiling_file_paths {
    my $self = shift;
    $self->_setup_profiling_result_dir;
    $self->_setup_profiling_result_file_name;
    $self->_setup_nullfile_name;
}

sub _setup_enable_reporting {
    my $self = shift;
    $self->enable_reporting(1) unless defined $self->enable_reporting;
}

sub _setup_enable_profile {
    my $self = shift;
    $self->enable_profile( sub {1} ) unless $self->enable_profile;
}

sub _setup_profiling_result_dir {
    my $self = shift;
    $self->profiling_result_dir( sub {'.'} )
        unless is_code_ref( $self->profiling_result_dir );
}

sub _setup_report_dir {
    my $self = shift;
    $self->report_dir( sub {'report'} )
        unless is_code_ref( $self->report_dir );
}

sub _setup_nytprofhtml_path {
    my $self = shift;
    return if $self->nytprofhtml_path;
    my $nytprofhtml_path = File::Which::which('nytprofhtml')
        or die "Could not find nytprofhtml script. Ensure it's in your path";
    $self->nytprofhtml_path($nytprofhtml_path);
}

sub _setup_profile_id {
    my $self = shift;
    $self->generate_profile_id( sub { return $$ . "-" . gettimeofday; } )
        unless is_code_ref( $self->generate_profile_id );
}

sub _setup_profiling_result_file_name {
    my $self = shift;
    $self->profiling_result_file_name(
        sub { my $id = $_[1]->{PROFILE_ID}; return "nytprof.$id.out"; } )
        unless is_code_ref( $self->profiling_result_file_name );
}

sub _setup_nullfile_name {
    my $self = shift;

    $self->nullfile_name('nytprof.null.out') unless $self->nullfile_name;
}

sub _setup_profiling_hooks {
    my $self = shift;
    $self->before_profile( sub { } )
        unless is_code_ref( $self->before_profile );
    $self->after_profile( sub { } )
        unless is_code_ref( $self->after_profile );

}

sub call {
    my ( $self, $env ) = @_;

    $self->_setup_profiler($env);
    $self->start_profiling_if_needed($env);

    my $res = $self->app->($env);

    if ( ref($res) && ref($res) eq 'ARRAY' ) {
        $self->stop_profiling_and_report_if_needed($env);
        return $res;
    }

    Plack::Util::response_cb(
        $res,
        sub {
            my $res = shift;
            sub {
                my $chunk = shift;
                if ( !defined $chunk ) {
                    $self->stop_profiling_and_report_if_needed($env);
                    return;
                }
                return $chunk;
                }
        }
    );
}

sub start_profiling_if_needed {
    my ( $self, $env ) = @_;
    my $is_profiler_enabled = $self->enable_profile->($env);
    return unless $is_profiler_enabled;

    $env->{PROFILER_ENABLED} = 1;
    $self->before_profile->( $self, $env );
    $self->start_profiling($env);
}

sub stop_profiling_and_report_if_needed {
    my ( $self, $env ) = @_;
    my $is_profiler_enabled = $env->{PROFILER_ENABLED};
    return unless $is_profiler_enabled;

    $self->stop_profiling($env);
    $self->report($env) if $self->enable_reporting;
    $self->after_profile->( $self, $env );
}

sub _setup_profiler {
    my ( $self, $env ) = @_;

    my $pid = $$;
    return if $PROFILER_SETUPED{$pid};
    $PROFILER_SETUPED{$pid} = 1;

    my $is_profiler_enabled = $self->enable_profile->($env);
    return unless $is_profiler_enabled;

    return if $NYTPROF_LOADED;

    $ENV{NYTPROF} = $ENV{NYTPROF} || $self->env_nytprof || _default_env();
    require Devel::NYTProf;
    DB::disable_profile();
    $NYTPROF_LOADED = 1;
}

sub start_profiling {
    my ( $self, $env ) = @_;

    $env->{PROFILE_ID} = $self->generate_profile_id->( $self, $env );
    DB::enable_profile( $self->profiling_result_file_path($env) );
}

sub stop_profiling {
    DB::disable_profile();
}

sub report {
    my ( $self, $env ) = @_;

    return unless $env->{PROFILE_ID};

    DB::enable_profile( $self->nullfile_path );
    DB::disable_profile();
    my $profiling_result_file = $self->profiling_result_file_path($env);
    return unless ( -f $profiling_result_file );
    system $self->nytprofhtml_path, "-f", $profiling_result_file,
        '-o', $self->report_dir->();
}

sub profiling_result_file_path {
    my ( $self, $env ) = @_;

    return File::Spec->catfile(
        $self->profiling_result_dir->( $self, $env ),
        $self->profiling_result_file_name->( $self, $env )
    );
}

sub nullfile_path {
    my ( $self, $env ) = @_;

    return File::Spec->catfile( $self->profiling_result_dir->( $self, $env ),
        $self->nullfile_name );
}

sub is_code_ref {
    my $ref = shift;
    return ( ref($ref) eq 'CODE' ) ? 1 : 0;
}

sub DESTROY {
    DB::finish_profile() if defined &{"DB::finish_profile"};
}

1;

__END__


=encoding utf-8

=head1 NAME

Plack::Middleware::Profiler::NYTProf - Middleware for Profiling a Plack App

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'Profiler::NYTProf';
        [ '200', [], [ 'Hello Profiler' ] ];
    };

=head1 DESCRIPTION

Plack::Middleware::Profiler::NYTProf helps you to get profiles of Plack App.

Enabling this middleware will result in a huge performance penalty.
It is intended for use in development only.

Read L<Devel::NYTProf> documentation if you use it for production.
Some options of Devel::NYTProf is useful to reduce profling overhead.
See MAKING_NYTPROF_FASTER section of NYTProf's pod.

=head1 OPTIONS

NOTE that some options expect a code reference. Maybe, you feel it is complicated. 
However that will enable to control them programmably. It is more useful to your apps.

=over 4

=item enable_profile

default

    sub { 1 }

Use code reference if you want to enable profiling programmably 
This option is optional.

=item enable_reporting

default

    1

Devel::NYTProf doesn't generate HTML profiling report if you set 0 to this option.
This option is optional.

=item env_nytprof

Warning: This option is DEPRECAED from 0.16. Use NYTPROF environment variable.

This option set to $ENV{NYTPROF}. See L<Devel::NYTProf>: NYTPROF ENVIRONMENT VARIABLE section. 
By default, Plack::Middleware::Profiler::NYTProf loads Devel::NYTProf lazily.

default

    'start=no:sigexit=int'

NOTE that Devel::NYTProf expects to be loaded in compile phase. It would be better to load manually like this

    # in your app.psgi
    BEGIN {
        use Plack::Middleware::Profiler::NYTProf;
        $ENV{NYTPROF} = 'start=no:sigexit=int:stmts=0:savesrc=0';
        Plack::Middleware::Profiler::NYTProf->preload;
    }

If you set enable_reporting TRUE (you get a profile for each request), you should NOT load Devel::NYTProf manually.

=item profiling_result_dir 

NYTProf write profile data to this directory.
The default directory is current directory.
This option is optional.

default

    sub { '.' }

=item profiling_result_file_name

The file name about profile.
This options is optional.

default

    sub { my $id = $_[1]->{PROFILE_ID}; return "nytprof.$id.out"; }

=item generate_profile_id

Generate ID for every profile.
This option is optional.

default

    sub { return $$ . "-" . Time::HiRes::gettimeofday; } )

=item nullfile

The file name of dummy profile for NYTProf. 
This option is optional.

default

    'nytprof.null.out'

=item before_profile 

This is the hook before profiling
This option is optional.

=item after_profile

This is the hook after profiling
This option is optional.

=back

=head1 HOW TO SEE REPORT 

  $ plackup -MPlack::App::Directory -e 'Plack::App::Directory->new({root => "./report"})->to_app'

=head1 SOURCE AVAILABILITY

This source is in Github:

  http://github.com/dann/p5-plack-middleware-profiler-nytprof

=head1 CONTRIBUTORS

Many thanks to: bayashi

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>
Dai Okabayashi

=head1 SEE ALSO

L<Devel::NYTProf> 

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
