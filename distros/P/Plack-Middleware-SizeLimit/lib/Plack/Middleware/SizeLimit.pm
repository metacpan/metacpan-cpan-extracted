package Plack::Middleware::SizeLimit;
use 5.008;
use strict;
use warnings;
use parent qw(
    Plack::Middleware
    Process::SizeLimit::Core
);
use Plack::Util::Accessor qw(
    max_unshared_size_in_kb
    min_shared_size_in_kb
    max_process_size_in_kb
    check_every_n_requests
    log_when_limits_exceeded
);

our $VERSION = '0.09';

sub prepare_app {
    my $self = shift;
    $self->set_check_interval($self->check_every_n_requests || 1);
    $self->set_max_process_size($self->max_process_size_in_kb);
    $self->set_min_shared_size($self->min_shared_size_in_kb);
    $self->set_max_unshared_size($self->max_unshared_size_in_kb);
}

sub call {
    my ($self, $env) = @_;

    my $res = $self->app->($env);

    return $res unless $env->{'psgix.harakiri'} or $env->{'psgix.harakiri.supported'};

    if (my $interval = $self->check_every_n_requests) {
        my $pinc = $self->get_and_pinc_request_count;
        return $res if ($pinc % $interval);
    }

    my $harakiri;
    if ($env->{'psgix.harakiri'}) {
        # Canonical implementation (Starman 0.2012+)
        $harakiri = $env->{'psgix.harakiri.commit'} = $self->_limits_are_exceeded;
    }
    elsif ($env->{'psgix.harakiri.supported'}) {
        # Legacy implementation (uWSGI)
        $harakiri = $env->{'psgix.harakiri'} = $self->_limits_are_exceeded;
    }

    if ($harakiri && $self->log_when_limits_exceeded) {
        my $message = sprintf(
            'pid %d committed harakiri (size: %d, shared: %d, unshared: %d) at %s',
            $$, $self->_check_size, $env->{REQUEST_URI},
        );
        if (my $logger = $env->{'psgix.logger'}) {
            $logger->( { message => $message, level => 'warn' } );
        }
        else {
            warn "$message\n";
        }
    }

    return $res;
}

1;
__END__

=encoding utf8

=head1 NAME

Plack::Middleware::SizeLimit - Terminate processes if they grow too large

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable SizeLimit => (
            max_unshared_size_in_kb => '4096', # 4MB
            # min_shared_size_in_kb => '8192', # 8MB
            # max_process_size_in_kb => '16384', # 16MB
            check_every_n_requests => 2,
            log_when_limits_exceeded => 1
        );
        $app;
    };

=head1 DESCRIPTION

This middleware is a port of the excellent L<Apache::SizeLimit> module
for multi-process Plack servers, such as L<Starman>, L<Starlet>,
L<Gazelle> and C<uWSGI>.

This middleware only works when the environment C<psgix.harakiri> is
set to a true value by the Plack server.  If it's set to false, then this
middleware simply does nothing.

You must use at least version 0.2006 of Starman (July 2010), and 0.19 of
Starlet (June 2013). Earlier versions ignore the flag to stop the process.

=head1 CONFIGURATIONS

=over 4

=item max_unshared_size_in_kb

The maximum amount of I<unshared> memory the process can use;
usually this option is all one needs.

Experience on one heavily trafficked L<mod_perl> site showed that
setting this option and leaving the others unset is the most effective
policy.

This is because it only kills off processes that are truly using too much
physical RAM, allowing most processes to live longer and reducing the
process churn rate.

=item min_shared_size_in_kb

Sets the minimum amount of shared memory the process must have.

=item max_process_size_in_kb

The maximum size of the process, including both shared and unshared memory.

=item check_every_n_requests

Since checking the process size can take a few system calls on some platforms
(e.g. linux), you may specify this option to check the process size every I<N>
requests. The default value for I<N> is 1, i.e. to check after the processing
of every request.

=item log_when_limits_exceeded

When true, the middleware will log a warning whenever it signals to the server
that the process is to be terminated.  This is false by default.

=back

=head1 SEE ALSO

L<Starman>, L<Starlet>, L<Gazelle>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 LICENSE

This work is under the B<CC0 1.0 Universal> license.

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Plack::Middleware::SizeLimit>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
