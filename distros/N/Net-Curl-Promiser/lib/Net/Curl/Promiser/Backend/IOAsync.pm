package Net::Curl::Promiser::Backend::IOAsync;

use strict;
use warnings;

use parent 'Net::Curl::Promiser::Backend::LoopBase';

use IO::Async::Handle ();
use Net::Curl::Multi ();

use Net::Curl::Promiser::FDFHStore ();

sub new {
    my ($class, $loop) = @_;

    my $self = $class->SUPER::new();

    $self->{'_loop'} = $loop;
    $self->{'_fhstore'} = Net::Curl::Promiser::FDFHStore->new();

    return $self;
}

#----------------------------------------------------------------------

sub SET_TIMER {
    my ($self, $multi, $timeout_ms) = @_;

    $self->{'timer_id'} = $self->{'_loop'}->watch_time(
        after => $timeout_ms / 1000,
        code => sub { $self->time_out($multi) },
    );
}

sub CLEAR_TIMER {
    my ($self) = @_;

    if ( my $old_id = delete $self->{'timer_id'} ) {
        $self->{'_loop'}->unwatch_time($old_id);
    }
}

sub _get_handle {
    my ($self, $fd, $multi) = @_;

    return $self->{'_handle'}{$fd} ||= do {
        my $s = $self->{'_fhstore'}->get_fh($fd);

        my $handle = IO::Async::Handle->new(
            read_handle => $s,
            write_handle => $s,

            on_read_ready => sub {
                $self->process($multi, [$fd, Net::Curl::Multi::CURL_CSELECT_IN()]);
            },

            on_write_ready => sub {
                $self->process($multi, [$fd, Net::Curl::Multi::CURL_CSELECT_OUT()]);
            },
        );

        $self->{'_loop'}->add($handle);

        $handle;
    };
}

sub CLEAR { $_[0]->{'timer'} = undef }

sub SET_POLL_IN {
    my ($self, $fd, $multi) = @_;

    my $h = $self->_get_handle($fd, $multi);

    $h->want_readready(1);
    $h->want_writeready(0);

    return;
}

sub SET_POLL_OUT {
    my ($self, $fd, $multi) = @_;

    my $h = $self->_get_handle($fd, $multi);

    $h->want_readready(0);
    $h->want_writeready(1);

    return;
}

sub SET_POLL_INOUT {
    my ($self, $fd, $multi) = @_;

    my $h = $self->_get_handle($fd, $multi);

    $h->want_readready(1);
    $h->want_writeready(1);

    return;
}

sub STOP_POLL {
    my ($self, $fd) = @_;

    if ( my $fh = delete $self->{'_handle'}{$fd} ) {
        $self->{'_loop'}->remove($fh);
    }

    return;
}

1;
