# $Id: ChannelMgr.pm,v 1.10 2009/01/26 01:00:25 turnstep Exp $

package Net::SSH::Perl::ChannelMgr;
use strict;
use warnings;

use Net::SSH::Perl::Channel;
use Net::SSH::Perl::Packet;
use Net::SSH::Perl::Constants qw( :msg2 :channels );

use Carp qw( croak );
use Scalar::Util qw(weaken);

sub new {
    my $class = shift;
    my $ssh = shift;
    my $cmgr = bless { ssh => $ssh, @_ }, $class;
    weaken $cmgr->{ssh};
    $cmgr->init;
    $cmgr;
}

sub init {
    my $cmgr = shift;
    $cmgr->{channels} = [];
    $cmgr->{handlers} = {
        SSH2_MSG_CHANNEL_CLOSE() => \&input_oclose,
        SSH2_MSG_CHANNEL_DATA() => \&input_data,
        SSH2_MSG_CHANNEL_EOF() => \&input_eof,
        SSH2_MSG_CHANNEL_EXTENDED_DATA() => \&input_extended_data,
        SSH2_MSG_CHANNEL_OPEN_CONFIRMATION() => \&input_open_confirmation,
        SSH2_MSG_CHANNEL_OPEN_FAILURE() => \&input_open_failure,
        SSH2_MSG_CHANNEL_REQUEST() => \&input_channel_request,
        SSH2_MSG_CHANNEL_WINDOW_ADJUST() => \&input_window_adjust,
        SSH2_MSG_KEXINIT() => \&input_kexinit,
    };
}

sub new_channel {
    my $cmgr = shift;
    my $c = Net::SSH::Perl::Channel->new($cmgr->{ssh}, $cmgr, @_);
    push @{ $cmgr->{channels} }, $c;
    $c;
}

sub remove {
    my $cmgr = shift;
    my($id) = @_;
    $cmgr->{channels}->[$id] = undef;
}

sub new_channel_id {
    my $cmgr = shift;
    $cmgr->{_channel_id} ||= 0;
    $cmgr->{_channel_id}++;
}

sub any_open_channels {
    my $cmgr = shift;
    for my $c (@{ $cmgr->{channels} }) {
        next unless defined $c;
        return 1 if
            $c->{type} == SSH_CHANNEL_OPENING        ||
            $c->{type} == SSH_CHANNEL_OPEN           ||
            $c->{type} == SSH_CHANNEL_INPUT_DRAINING ||
            $c->{type} == SSH_CHANNEL_OUTPUT_DRAINING;
    }
}

sub prepare_channels {
    my $cmgr = shift;
    for my $c (@{ $cmgr->{channels} }) {
        next unless defined $c;
        $c->prepare_for_select(@_);
        if ($c->delete_if_full_closed) {
            $cmgr->remove($c->{id});
        }
    }
}

sub process_input_packets {
    my $cmgr = shift;
    for my $c (@{ $cmgr->{channels} }) {
        next unless defined $c;
        $c->process_buffers(@_);
        $c->check_window;
        if ($c->delete_if_full_closed) {
            $cmgr->remove($c->{id});
        }
    }
}

sub process_output_packets {
    my $cmgr = shift;
    for my $c (@{ $cmgr->{channels} }) {
        next unless defined $c;
        $c->process_outgoing;
    }
}

sub _get_channel_from_packet {
    my($cmgr, $packet, $what) = @_;
    my $id = $packet->get_int32;
    my $c = $cmgr->{channels}->[$id];
    croak "Received $what for nonexistent channel $id"
        unless $c;
    $c;
}

sub input_oclose {
    my $cmgr = shift;
    my($packet) = @_;
    my $c = $cmgr->_get_channel_from_packet($packet, 'oclose');
    $c->rcvd_oclose;
}

sub input_data {
    my $cmgr = shift;
    my($packet) = @_;
    my $c = $cmgr->_get_channel_from_packet($packet, 'data');
    return unless $c->{type} == SSH_CHANNEL_OPEN;
    my $data = $packet->get_str;
    $c->{local_window} -= length $data;
    $c->{output}->append($data);
}

sub input_eof {
    my $cmgr = shift;
    my($packet) = @_;
    my $c = $cmgr->_get_channel_from_packet($packet, 'ieof');
    $c->rcvd_ieof;
}

sub input_extended_data {
    my $cmgr = shift;
    my($packet) = @_;
    my $c = $cmgr->_get_channel_from_packet($packet, 'extended_data');
    return unless $c->{type} == SSH_CHANNEL_OPEN;
    my $code = $packet->get_int32;
    my $data = $packet->get_str;
    $c->{extended}->append($data);
}

sub input_open_confirmation {
    my $cmgr = shift;
    my($packet) = @_;
    my $id = $packet->get_int32;
    my $c = $cmgr->{channels}->[$id];
    croak "Received open confirmation for non-opening channel $id"
        unless $c && $c->{type} == SSH_CHANNEL_OPENING;
    $c->{remote_id} = $packet->get_int32;
    $c->{type} = SSH_CHANNEL_OPEN;
    $c->{remote_window} = $packet->get_int32;
    $c->{remote_maxpacket} = $packet->get_int32;
    if (my $sub = $c->{handlers}{$packet->type}{code}) {
        $sub->($c, $packet);
    }
    $cmgr->{ssh}->debug("channel $id: open confirm rwindow $c->{remote_window} rmax $c->{remote_maxpacket}");
}

sub input_open_failure {
    my $cmgr = shift;
    my($packet) = @_;
    my $id = $packet->get_int32;
    my $c = $cmgr->{channels}->[$id];
    croak "Received open failure for non-opening channel $id"
        unless $c && $c->{type} == SSH_CHANNEL_OPENING;
    my $reason = $packet->get_int32;
    my $msg = $packet->get_str;
    my $lang = $packet->get_str;
    $cmgr->{ssh}->debug("Channel open failure: $id: reason $reason: $msg");
    $cmgr->remove($id);
}

sub input_channel_request {
    my $cmgr = shift;
    my($packet) = @_;
    my $id = $packet->get_int32;
    my $c = $cmgr->{channels}->[$id];
    croak "Received request for non-open channel $id"
        unless $c && $c->{type} == SSH_CHANNEL_OPEN ||
                     $c->{type} == SSH_CHANNEL_LARVAL;
    if (my $sub = $c->{handlers}{$packet->type}{code}) {
        $sub->($c, $packet);
    }
}

sub input_window_adjust {
    my $cmgr = shift;
    my($packet) = @_;
    my $id = $packet->get_int32;
    my $c = $cmgr->{channels}->[$id];
    croak "Received window adjust for non-open channel $id"
        unless $c && $c->{type} == SSH_CHANNEL_OPEN;
    $c->{remote_window} += $packet->get_int32;
    if (my $sub = $c->{handlers}{$packet->type}{code}) {
        $sub->($c, $packet);
    }
}

sub input_kexinit {
    my $cmgr = shift;
    my($packet) = @_;

    my $kex = Net::SSH::Perl::Kex->new($cmgr->{ssh});
    $kex->exchange($packet);
    $cmgr->{ssh}->debug("Re-key complete.");
}

sub register_handler {
    my $cmgr = shift;
    my($type, $code) = @_;
    $cmgr->{handlers}->{ $type } = $code;
}

sub handlers { $_[0]->{handlers} }

1;
__END__

=head1 NAME

Net::SSH::Perl::ChannelMgr - Manages a list of open channels

=head1 SYNOPSIS

    use Net::SSH::Perl::ChannelMgr;
    my $cmgr = Net::SSH::Perl::ChannelMgr->new;
    my $channel = $cmgr->new_channel(@args);

=head1 DESCRIPTION

I<Net::SSH::Perl::ChannelMgr> manages the creation and maintenance
of a list of open channels for the SSH2 protocol.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
