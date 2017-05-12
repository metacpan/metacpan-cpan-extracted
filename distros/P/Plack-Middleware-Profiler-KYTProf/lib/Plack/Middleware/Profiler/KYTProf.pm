package Plack::Middleware::Profiler::KYTProf;
use strict;
use warnings;
use parent qw(Plack::Middleware);
our $VERSION = '0.08';

use Plack::Util::Accessor qw(
    namespace_regex
    ignore_class_regex
    context_classes_regex
    logger
    threshold
    remove_linefeed
    profiles
    mutes
    enable_profile_if
);
use Module::Load qw(load);

my %PROFILER_SETUPED;

sub prepare_app {
    my $self = shift;

    $self->_setup_enable_profile_if;
}

sub _setup_enable_profile_if {
    my $self = shift;
    $self->enable_profile_if( sub {1} ) unless $self->enable_profile_if;
}

sub _setup_profiler_if_needed {
    my ( $self, $env ) = @_;

    my $pid = $$;
    return if $PROFILER_SETUPED{$pid};
    $PROFILER_SETUPED{$pid} = 1;

    my $is_profiler_enabled = $self->enable_profile_if->($env);
    return unless $is_profiler_enabled;

    $self->_setup_profiler;
}

sub _setup_profiler {
    my $self = shift;

    $self->_load_kytprof;
    $self->_set_kytprof_options;
    $self->_load_profiles;
    $self->_diable_module_profiling;
}

sub _load_kytprof {
    my $self = shift;
    $self->_load_module('Devel::KYTProf');
}

sub _set_kytprof_options {
    my $self = shift;
    Devel::KYTProf->namespace_regex( $self->namespace_regex )
        if $self->namespace_regex;
    Devel::KYTProf->ignore_class_regex( $self->ignore_class_regex )
        if $self->ignore_class_regex;
    Devel::KYTProf->context_classes_regex( $self->context_classes_regex )
        if $self->context_classes_regex;

    # TODO Should we create logger adapter for popular logging framework?
    Devel::KYTProf->logger( $self->logger )       if $self->logger;
    Devel::KYTProf->threshold( $self->threshold ) if $self->threshold;
    Devel::KYTProf->remove_linefeed( $self->remove_linefeed )
        if $self->remove_linefeed;
}

sub _diable_module_profiling {
    my $self = shift;
    foreach my $module ( keys %{ $self->mutes || {} } ) {
        my $method = $self->mutes->{$module};
        Devel::KYTProf->mute( $module, $method );
    }
}

sub _load_profiles {
    my $self = shift;

    my $profiles ||= $self->profiles;
    $profiles ||= [
        'Plack::Middleware::Profiler::KYTProf::Profile::TemplateEngine',
        'Plack::Middleware::Profiler::KYTProf::Profile::KVS'
    ];
    foreach my $profile (@$profiles) {
        $self->_load_module($profile);
        die "profile class must implement load method"
            unless $profile->can('load');
        $profile->load;
    }
}

sub _load_module {
    my ( $self, $module ) = @_;
    eval { load $module; 1; } or die "Can't load ${module}";
}

sub call {
    my ( $self, $env ) = @_;
    $self->_setup_profiler_if_needed($env);

    my $res = $self->app->($env);

    if ( ref($res) && ref($res) eq 'ARRAY' ) {
        return $res;
    }

    Plack::Util::response_cb(
        $res,
        sub {
        }
    );
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Profiler::KYTProf - Profile psgi app with KYTProf

=head1 SYNOPSIS

    builder {
        enable "Plack::Middleware::Profiler::KYTProf";
        $app;
    };

=head1 DESCRIPTION

Plack::Middleware::Profiler::KYTProf is the PSGI app profiler.
Use enable_profile_if, logger and threshold option in production environment.

Use profiles if you need application specific profiling.
See the sample profile L<Plack::Middleware::Profiler::KYTProf::Profile::TemplateEngine>.

=head1 OPTIONS

NOTE that some options expect a code reference. Maybe, you feel it is complicated. 
However that will enable to control them programmably. It is more useful to your apps.

=over 4

=item enable_profile_if

default

    sub { 1 }

Use code reference if you want to enable profiling programmably 
This option is optional.

=item profiles

You can add profiling target modules if you use this option.

default

    [
        'Plack::Middleware::Profiler::KYTProf::Profile::TemplateEngine',
        'Plack::Middleware::Profiler::KYTProf::Profile::KVS'
    ];

=item namespace_regex

See L<Devel::KYTProf> POD.

default

    undef


=item ignore_class_regex

See L<Devel::KYTProf> POD.

default

    undef


=item context_classes_regex

See L<Devel::KYTProf> POD.

=item logger

See L<Devel::KYTProf> POD.

default

    undef


=item threshold

See L<Devel::KYTProf> POD.

default

    undef

=item remove_linefeed

See L<Devel::KYTProf> POD.

default

    undef

=item mutes

See L<Devel::KYTProf> POD.

default

    undef

=back

=head1 SOURCE AVAILABILITY

This source is in Github:

  http://github.com/dann/p5-plack-middleware-profiler-kytprof

=head1 CONTRIBUTORS

Many thanks to:

=head1 AUTHOR

Dann E<lt>techmemo@gmail.comE<gt>

=head1 SEE ALSO

L<Devel::KYTProf>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
