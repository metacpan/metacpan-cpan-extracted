package Plack::Middleware::LogDispatchouli;

use strict;
use warnings;
use 5.008_005;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(logger);
use Carp ();
use Scalar::Util qw(blessed);

use Log::Dispatchouli;

our $VERSION = '0.01';

sub prepare_app {
    my $self = shift;
    unless ($self->logger) {
        Carp::croak "logger is not defined";
    }
    $self->logger( Log::Dispatchouli->new($self->logger) )
        if ref $self->logger eq 'HASH';
    Carp::croak "logger is not a Log::Dispatchouli object or constructor parameter hash"
        unless blessed($self->logger) and $self->logger->isa("Log::Dispatchouli");
}

sub call {
    my($self, $env) = @_;

    $env->{'psgix.logger'} = sub {
        my $args = shift;
        my $msg  = delete $args->{message};

        ($args->{fatal}, $args->{level}) = (1, 'error')
            if $args->{level} eq 'fatal';

        if ( ref $msg && ref $msg ne 'CODE' ) {
            $msg .= q{};
        }

        $self->logger->log($args, $msg);
    };

    $self->app->($env);
}

1;

__END__
=encoding utf-8

=head1 NAME

Plack::Middleware::LogDispatchouli - Uses Log::Dispatchouli to configure the PSGI logger

=head1 SYNOPSIS

    use Log::Dispatchouli;
    my $logger = Log::Dispatchouli->new(...);

    builder {
        enable "LogDispatchouli", logger => $logger;
        $app;
    }

    # or to make it even easier...
    builder {
        enable "LogDispatchouli", logger => {
            ident     => 'MyApp',
            facility  => 'daemon',
            to_stdout => $ENV{PLACK_ENV} eq "development",
            debug     => $ENV{PLACK_ENV} eq "development",
        };
        $app;
    }

=head1 DESCRIPTION

Plack::Middleware::LogDispatchouli is a L<Plack::Middleware> component that
allows you to use L<Log::Dispatchouli> to configure the logging object,
C<psgix.logger>.

=head1 CONFIGURATION

=over 4

=item logger

L<Log::Dispatchouli> object to send logs to or a hashref of parameters to pass
to L<Log::Dispatchouli/new>.

=back

=head1 AUTHOR

Thomas Sibley E<lt>trsibley@uw.eduE<gt>

=head1 COPYRIGHT

Copyright 2014- Mullins Lab, Department of Microbiology, University of
Washington

This module is based on L<Plack::Middleware::LogDispatch>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Log::Dispatchouli>

L<Plack::Middleware::LogDispatch>

=cut
