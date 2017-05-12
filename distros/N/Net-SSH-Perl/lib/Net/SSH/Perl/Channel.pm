# $Id: Channel.pm,v 1.18 2003/12/03 15:35:21 autarch Exp $

package Net::SSH::Perl::Channel;
use strict;
use warnings;

use Net::SSH::Perl::Buffer;
use Net::SSH::Perl::Constants qw( :msg2 :channels );

use Carp qw( croak );
use Scalar::Util qw(weaken);

sub new {
    my $class = shift;
    my($ssh, $mgr) = (shift, shift);
    my $c = bless { ssh => $ssh, mgr => $mgr, @_ }, $class;
    weaken $c->{ssh};
    weaken $c->{mgr};
    $c->init;
    $ssh->debug("channel $c->{id}: new [$c->{remote_name}]");
    $c;
}

sub init {
    my $c = shift;
    $c->{id} = $c->{mgr}->new_channel_id;
    $c->{type} = SSH_CHANNEL_OPENING;
    $c->{input} = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $c->{output} = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $c->{extended} = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $c->{ostate} = CHAN_OUTPUT_OPEN;
    $c->{istate} = CHAN_INPUT_OPEN;
    $c->{flags} = 0;
    $c->{remote_window} = 0;
    $c->{local_window} ||= 32 * 1024;
    $c->{local_window_max} = $c->{local_window};
    $c->{local_consumed} = 0;
    $c->{local_maxpacket} ||= 16 * 1024;
    $c->{ctype} ||= 'session';
    $c->{remote_name} ||= 'client-session';
}

sub open {
    my $c = shift;
    my $ssh = $c->{ssh};
    $ssh->debug("Requesting channel_open for channel $c->{id}.");
    my $packet = $ssh->packet_start(SSH2_MSG_CHANNEL_OPEN);
    $packet->put_str($c->{ctype});
    $packet->put_int32($c->{id});
    $packet->put_int32($c->{local_window});
    $packet->put_int32($c->{local_maxpacket});
    $packet->send;
}

sub request {
    my $c = shift;
    my $packet = $c->request_start(@_);
    $packet->send;
}

sub request_start {
    my $c = shift;
    my($service, $want_reply) = @_;
    my $ssh = $c->{ssh};
    $ssh->debug("Requesting service $service on channel $c->{id}.");
    my $packet = $ssh->packet_start(SSH2_MSG_CHANNEL_REQUEST);
    $packet->put_int32($c->{remote_id});
    $packet->put_str($service);
    $packet->put_int8($want_reply);
    return $packet;
}

sub send_data {
    my $c = shift;
    my($buf) = @_;
    $c->{input}->append($buf);
}

sub process_outgoing {
    my $c = shift;
    return unless ($c->{istate} == CHAN_INPUT_OPEN ||
                   $c->{istate} == CHAN_INPUT_WAIT_DRAIN) &&
                  $c->{input}->length > 0;
    my $len = $c->{input}->length;
    $len = $c->{remote_window} if $len > $c->{remote_window};
    $len = $c->{remote_maxpacket} if $len > $c->{remote_maxpacket};
    my $data = $c->{input}->bytes(0, $len, '');
    my $packet = $c->{ssh}->packet_start(SSH2_MSG_CHANNEL_DATA);
    $packet->put_int32($c->{remote_id});
    $packet->put_str($data);
    $packet->send;
    $c->{remote_window} -= $len;
}

sub check_window {
    my $c = shift;
    if ($c->{type} == SSH_CHANNEL_OPEN &&
       !($c->{flags} & (CHAN_CLOSE_SENT | CHAN_CLOSE_RCVD)) &&
       $c->{local_window} < $c->{local_window_max}/2 &&
       $c->{local_consumed} > 0) {
        my $packet = $c->{ssh}->packet_start(SSH2_MSG_CHANNEL_WINDOW_ADJUST);
        $packet->put_int32($c->{remote_id});
        $packet->put_int32($c->{local_consumed});
        $packet->send;
        $c->{ssh}->debug("channel $c->{id}: window $c->{local_window} sent adjust $c->{local_consumed}");
        $c->{local_window} += $c->{local_consumed};
        $c->{local_consumed} = 0;
    }
}

sub prepare_for_select {
    my $c = shift;
    my($rb, $wb) = @_;
    if ($c->{rfd} && $c->{istate} == CHAN_INPUT_OPEN &&
        $c->{remote_window} > 0 &&
        $c->{input}->length < $c->{remote_window}) {
        $rb->add($c->{rfd});
    }
    if ($c->{wfd} &&
        $c->{ostate} == CHAN_OUTPUT_OPEN ||
        $c->{ostate} == CHAN_OUTPUT_WAIT_DRAIN) {
        if ($c->{output}->length > 0) {
            $wb->add($c->{wfd});
        }
        elsif ($c->{ostate} == CHAN_OUTPUT_WAIT_DRAIN &&
               $c->{extended}->length == 0) {
            $c->obuf_empty;
        }
    }
    if ($c->{efd} && $c->{extended}->length > 0) {
        $wb->add($c->{efd});
    }
}

sub process_buffers {
    my $c = shift;
    my($rready, $wready) = @_;

    my %fd = (output => $c->{wfd}, extended => $c->{efd});
    for my $buf (keys %fd) {
        if ($fd{$buf} && grep { $fd{$buf} == $_ } @$wready) {
            if (my $r = $c->{handlers}{"_${buf}_buffer"}) {
                $r->{code}->( $c, $c->{$buf}, @{ $r->{extra} } );
            }
            else {
                #warn "No handler for '$buf' buffer set up";
            }
            $c->{local_consumed} += $c->{$buf}->length
                if $buf eq "output";
            $c->{$buf}->empty;
        }
    }

    if ($c->{rfd} && grep { $c->{rfd} == $_ } @$rready) {
        my $buf;
        sysread $c->{rfd}, $buf, 8192;
        ($buf) = $buf =~ /(.*)/s;
        $c->send_data($buf);
    }
}

sub rcvd_ieof {
    my $c = shift;
    $c->{ssh}->debug("channel $c->{id}: rcvd eof");
    if ($c->{ostate} && $c->{ostate} == CHAN_OUTPUT_OPEN) {
        $c->{ssh}->debug("channel $c->{id}: output open -> drain");
        $c->{ostate} = CHAN_OUTPUT_WAIT_DRAIN;
    }
}

sub obuf_empty {
    my $c = shift;
    $c->{ssh}->debug("channel $c->{id}: obuf empty");
    if ($c->{output}->length) {
        warn "internal error: obuf_empty $c->{id} for non empty buffer";
        return;
    }
    if ($c->{ostate} == CHAN_OUTPUT_WAIT_DRAIN) {
        $c->{ssh}->debug("channel $c->{id}: output drain -> closed");
        $c->shutdown_write;
        $c->{ostate} = CHAN_OUTPUT_CLOSED;
    }
    else {
        warn "channel $c->{id}: internal error: obuf_empty for ostate $c->{ostate}";
    }
}

sub drain_outgoing {
    my $c = shift;
    $c->register_handler(SSH2_MSG_CHANNEL_WINDOW_ADJUST, sub {
        $_[0]->{ssh}->break_client_loop
    });
    while ($c->{input}->length) {
        $c->process_outgoing;
        $c->{ssh}->client_loop if $c->{input}->length;
    }
    $c->drop_handler(SSH2_MSG_CHANNEL_WINDOW_ADJUST);
    $c->{ssh}->restore_client_loop;
}

sub shutdown_write {
    my $c = shift;
    $c->{output}->empty;
    return if $c->{type} == SSH_CHANNEL_LARVAL;
    $c->{ssh}->debug("channel $c->{id}: close_write");

    ## XXX: have to check for socket ($c->{socket}) and either
    ## do shutdown or close of file descriptor.
}

sub delete_if_full_closed {
    my $c = shift;
    if ($c->{istate} == CHAN_INPUT_CLOSED && $c->{ostate} == CHAN_OUTPUT_CLOSED) {
        unless ($c->{flags} & CHAN_CLOSE_SENT) {
            $c->send_close;
        }
        if (($c->{flags} & CHAN_CLOSE_SENT) && ($c->{flags} & CHAN_CLOSE_RCVD)) {
            $c->{ssh}->debug("channel $c->{id}: full closed");
            return 1;
        }
    }
    return 0;
}

sub send_close {
    my $c = shift;
    $c->{ssh}->debug("channel $c->{id}: send close");
    if ($c->{ostate} != CHAN_OUTPUT_CLOSED ||
        $c->{istate} != CHAN_INPUT_CLOSED) {
        warn "channel $c->{id}: internal error: cannot send close for istate/ostate $c->{istate}/$c->{ostate}";
    }
    elsif ($c->{flags} & CHAN_CLOSE_SENT) {
        warn "channel $c->{id}: internal error: already sent close";
    }
    else {
        my $packet = $c->{ssh}->packet_start(SSH2_MSG_CHANNEL_CLOSE);
        $packet->put_int32($c->{remote_id});
        $packet->send;
        $c->{flags} |= CHAN_CLOSE_SENT;
    }
}

sub rcvd_oclose {
    my $c = shift;
    $c->{ssh}->debug("channel $c->{id}: rcvd close");
    $c->{flags} |= CHAN_CLOSE_RCVD;
    if ($c->{type} == SSH_CHANNEL_LARVAL) {
        $c->{ostate} = CHAN_OUTPUT_CLOSED;
        $c->{istate} = CHAN_INPUT_CLOSED;
        return;
    }
    if ($c->{ostate} == CHAN_OUTPUT_OPEN) {
        $c->{ssh}->debug("channel $c->{id}: output open -> drain");
        $c->{ostate} = CHAN_OUTPUT_WAIT_DRAIN;
    }
    if ($c->{istate} == CHAN_INPUT_OPEN) {
        $c->{ssh}->debug("channel $c->{id}: input open -> closed");
        $c->shutdown_read;
    }
    elsif ($c->{istate} == CHAN_INPUT_WAIT_DRAIN) {
        $c->{ssh}->debug("channel $c->{id}: input drain -> closed");
        $c->send_eof;
    }
    $c->{istate} = CHAN_INPUT_CLOSED;
}

sub shutdown_read {
    my $c = shift;
    return if $c->{type} == SSH_CHANNEL_LARVAL;
    $c->{input}->empty;
    $c->{ssh}->debug("channel $c->{id}: close_read");

    ## XXX: have to check for socket ($c->{socket}) and either
    ## do shutdown or close of file descriptor.
}

sub send_eof {
    my $c = shift;
    $c->{ssh}->debug("channel $c->{id}: send eof");
    if ($c->{istate} == CHAN_INPUT_WAIT_DRAIN) {
        my $packet = $c->{ssh}->packet_start(SSH2_MSG_CHANNEL_EOF);
        $packet->put_int32($c->{remote_id});
        $packet->send;
    }
    else {
        warn "channel $c->{id}: internal error: cannot send eof for istate $c->{istate}";
    }
}

sub register_handler {
    my $c = shift;
    my($type, $sub, @extra) = @_;
    $c->{handlers}{$type} = { code => $sub, extra => \@extra };
}

sub drop_handler { delete $_[0]->{handlers}{$_[1]} }

1;
__END__

=head1 NAME

Net::SSH::Perl::Channel - SSH2 channel object

=head1 SYNOPSIS

    use Net::SSH::Perl::Channel;

=head1 DESCRIPTION

I<Net::SSH::Perl::Channel> implements a channel object compatible
with the SSH2 channel mechanism.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
