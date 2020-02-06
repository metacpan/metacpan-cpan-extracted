package Net::Curl::Promiser::IOAsync;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::Curl::Promiser::IOAsync - support for L<IO::Async>

=head1 SYNOPSIS

    my $loop = IO::Async::Loop->new();

    my $promiser = Net::Curl::Promiser::IOAsync->new($loop);

    my $handle = Net::Curl::Easy->new();
    $handle->setopt( CURLOPT_URL() => $url );

    $promiser->add_handle($handle)->then(
        sub { print "$url completed.$/" },
        sub { warn "$url failed: " . shift },
    )->finally( sub { $loop->stop() } );

    $loop->run();

=head1 DESCRIPTION

This module provides an L<IO::Async>-compatible interface for
L<Net::Curl::Promiser>.

See F</examples> in the distribution for a fleshed-out demonstration.

B<NOTE:> The actual interface is that provided by
L<Net::Curl::Promiser::LoopBase>.

=cut

#----------------------------------------------------------------------

use parent 'Net::Curl::Promiser::LoopBase';

use IO::Async::Handle ();
use Net::Curl::Multi ();

use Net::Curl::Promiser::FDFHStore ();

#----------------------------------------------------------------------

sub _INIT {
    my ($self, $args_ar) = @_;

    $self->{'_loop'} = $args_ar->[0];

    $self->setopt( Net::Curl::Multi::CURLMOPT_TIMERFUNCTION(), \&_cb_timer );
    $self->setopt( Net::Curl::Multi::CURLMOPT_TIMERDATA(), $self );

    $self->{'_fhstore'} = Net::Curl::Promiser::FDFHStore->new();

    return;
}

sub _cb_timer {
    my ($multi, $timeout_ms, $self) = @_;

    my $loop = $self->{'_loop'};

    if ( my $old_id = $self->{'timer_id'} ) {
        $loop->unwatch_time($old_id);
    }

    my $after;

    if ($timeout_ms) {
        if ($timeout_ms < 0) {
            if ($multi->handles()) {
                $after = 5;
            }
        }
        else {
            $after = $timeout_ms / 1000;
        }

        if ($after) {
            $self->{'timer_id'} = $loop->watch_time(
                after => $after,
                code => sub {
                    $self->_time_out_in_loop();
                },
            );
        }
    }
    else {
        $loop->later( sub { $self->_time_out_in_loop() } );
    }

    return 1;
}

sub _get_handle {
    my ($self, $fd) = @_;

    return $self->{'_handle'}{$fd} ||= do {
        my $s = $self->{'_fhstore'}->get_checked($fd);

        my $handle = IO::Async::Handle->new(
            read_handle => $s,
            write_handle => $s,

            on_read_ready => sub {
                $self->_process_in_loop($fd, Net::Curl::Multi::CURL_CSELECT_IN());
            },

            on_write_ready => sub {
                $self->_process_in_loop($fd, Net::Curl::Multi::CURL_CSELECT_OUT());
            },
        );

        $self->{'_loop'}->add($handle);

        $handle;
    };
}

sub _SET_POLL_IN {
    my ($self, $fd) = @_;

    my $h = $self->_get_handle($fd);

    $h->want_readready(1);
    $h->want_writeready(0);

    return;
}

sub _SET_POLL_OUT {
    my ($self, $fd) = @_;

    my $h = $self->_get_handle($fd);

    $h->want_readready(0);
    $h->want_writeready(1);

    return;
}

sub _SET_POLL_INOUT {
    my ($self, $fd) = @_;

    my $h = $self->_get_handle($fd);

    $h->want_readready(1);
    $h->want_writeready(1);

    return;
}

sub _STOP_POLL {
    my ($self, $fd) = @_;

    if ( my $fh = delete $self->{'_handle'}{$fd} ) {
        $self->{'_loop'}->remove($fh);
    }
    else {
        $self->_handle_extra_stop_poll($fd);
    }

    return;
}

1;
