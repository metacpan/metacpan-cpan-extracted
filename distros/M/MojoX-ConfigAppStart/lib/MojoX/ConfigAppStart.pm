package MojoX::ConfigAppStart;
# ABSTRACT: Start a Mojolicious application with Config::App

use 5.016;
use strict;
use warnings;
use Carp 'croak';

our $VERSION = '1.05'; # VERSION

BEGIN {
    $ENV{CONFIGAPPENV} = $ENV{MOJO_MODE} || $ENV{PLACK_ENV} || 'development';
}

use Config::App;
use Mojolicious::Commands;

my $mojo_app_lib;

sub import {
    my ( $self, $this_mojo_app_lib ) = @_;
    $mojo_app_lib = $this_mojo_app_lib || Config::App->new->get('mojo_app_lib');
    return;
}

sub start {
    my ( $self, $this_mojo_app_lib ) = @_;

    $mojo_app_lib = $this_mojo_app_lib if ($this_mojo_app_lib);
    $mojo_app_lib ||= Config::App->new->get('mojo_app_lib');

    croak('Unable to determine the Mojolicious application control library') unless ($mojo_app_lib);

    return Mojolicious::Commands->start_app($mojo_app_lib);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MojoX::ConfigAppStart - Start a Mojolicious application with Config::App

=head1 VERSION

version 1.05

=for markdown [![test](https://github.com/gryphonshafer/MojoX-ConfigAppStart/workflows/test/badge.svg)](https://github.com/gryphonshafer/MojoX-ConfigAppStart/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/MojoX-ConfigAppStart/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/MojoX-ConfigAppStart)

=head1 SYNOPSIS

    # look for "mojo_app_lib" value in Config::App configuration
    use MojoX::ConfigAppStart;
    MojoX::ConfigAppStart->start;

    # provide explicit Mojolicious application control library on start call
    use MojoX::ConfigAppStart;
    MojoX::ConfigAppStart->start('Application::Control');

    # provide explicit Mojolicious application control library on use call
    use MojoX::ConfigAppStart 'Application::Control';
    MojoX::ConfigAppStart->start;

=head1 DESCRIPTION

The goal of this module is to provide a simplified way to spin up Mojolicious
applications based on settings from a L<Config::App> configuration system.

If you have either C<MOJO_MODE> or C<PLACK_ENV> defined as enviornment
variables, the value will be used as the L<Config::App> enviornment definition.
If not defined at all, then "development" will be used. What this means in
practice is that from the commandline, calling C<morbo> or C<hypnotoad>
typically does what you want and expect.

=head2 Effective Equivalence

The following is effectively equivalent to using this module, except that the
C<Application::Control> library is derived:

    BEGIN {
        $ENV{CONFIGAPPENV} = $ENV{MOJO_MODE} || $ENV{PLACK_ENV} || 'development';
    }

    use Config::App;
    use Mojolicious::Commands;

    Mojolicious::Commands->start_app('Application::Control');

=head1 METHODS

The following is the only method provided:

=head2 start

The C<start()> method calls L<Mojolicious::Commands>'s C<start_app()> and
returns the result.

    MojoX::ConfigAppStart->start;

It can optionally be provided an explicit module name:

    MojoX::ConfigAppStart->start('Application::Control');

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/MojoX-ConfigAppStart>

=item *

L<MetaCPAN|https://metacpan.org/pod/MojoX::ConfigAppStart>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/MojoX-ConfigAppStart/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/MojoX-ConfigAppStart>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/MojoX-ConfigAppStart>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/G/MojoX-ConfigAppStart.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
