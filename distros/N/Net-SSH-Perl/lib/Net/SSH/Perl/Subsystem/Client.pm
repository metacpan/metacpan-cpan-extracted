# $Id: Client.pm,v 1.8 2001/07/11 21:57:35 btrott Exp $

package Net::SSH::Perl::Subsystem::Client;
use strict;
use warnings;

use Net::SSH::Perl::Constants qw(
    SSH2_MSG_CHANNEL_OPEN_CONFIRMATION
    SSH2_MSG_CHANNEL_SUCCESS
    SSH2_MSG_CHANNEL_FAILURE
    CHAN_INPUT_WAIT_DRAIN
    CHAN_INPUT_CLOSED );
use Net::SSH::Perl::Buffer;
use Net::SSH::Perl;

use Carp qw( croak );

sub new {
    my $class = shift;
    my $sc = bless { }, $class;
    $sc->init(@_);
}

sub subsystem { }
sub buffer_class { 'Net::SSH::Perl::Buffer' }

sub debug {
    my $sc = shift;
    if ($sc->{debug}) {
        $sc->{ssh}->debug($sc->subsystem . ": @_");
    }
}

sub init {
    my $sc = shift;
    my($host, %param) = @_;
    $sc->{host} = $host;
    $sc->{debug} = delete $param{debug};
    $param{ssh_args} ||= [];

    $sc->{_msg_id} = 0;

    my $ssh = Net::SSH::Perl->new($sc->{host}, protocol => 2,
        debug => $sc->{debug}, @{ $param{ssh_args} });
    $ssh->login($param{user}, $param{password});
    $sc->{ssh} = $ssh;

    my $channel = $sc->_open_channel;
    $sc->{channel} = $channel;

    $sc;
}

sub close {
    my $sc = shift;
    my $channel = $sc->{channel};
    $channel->{istate} = CHAN_INPUT_WAIT_DRAIN;
    $channel->send_eof;
    $channel->{istate} = CHAN_INPUT_CLOSED;
    $sc->{ssh}->client_loop;
}

sub _open_channel {
    my $sc = shift;
    my $ssh = $sc->{ssh};

    my $channel = $ssh->_session_channel;
    $channel->open;

    my $system = $sc->subsystem or
        croak "Subclass does not define a subsystem name";
    $channel->register_handler(SSH2_MSG_CHANNEL_OPEN_CONFIRMATION, sub {
        my($channel, $packet) = @_;
        $channel->{ssh}->debug("Sending subsystem: " . $system);
        my $r_packet = $channel->request_start("subsystem", 1);
        $r_packet->put_str($system);
        $r_packet->send;
    });

    my $subsystem_reply = sub {
        my($channel, $packet) = @_;
        my $id = $packet->get_int32;
        if ($packet->type == SSH2_MSG_CHANNEL_FAILURE) {
            $channel->{ssh}->fatal_disconnect("Request for " .
                "subsystem '$system' failed on channel '$id'");
        }
        $channel->{ssh}->break_client_loop;
    };

    my $cmgr = $ssh->channel_mgr;
    $cmgr->register_handler(SSH2_MSG_CHANNEL_FAILURE, $subsystem_reply);
    $cmgr->register_handler(SSH2_MSG_CHANNEL_SUCCESS, $subsystem_reply);

    $sc->{incoming} = $sc->buffer_class->new( MP => 'SSH2' );
    $channel->register_handler("_output_buffer", sub {
        my($channel, $buffer) = @_;
        $sc->{incoming}->append($buffer->bytes);
        $channel->{ssh}->break_client_loop;
    });

    ## Get channel confirmation, etc. Break once we get a response
    ## to subsystem execution.
    $ssh->client_loop;

    $channel;
}

## Messaging methods--messages are essentially sub-packets.

sub msg_id { $_[0]->{_msg_id}++ }

sub new_msg {
    my $sc = shift;
    my($code) = @_;
    my $msg = $sc->buffer_class->new( MP => 'SSH2' );
    $msg->put_int8($code);
    $msg;
}

sub new_msg_w_id {
    my $sc = shift;
    my($code, $sid) = @_;
    my $msg = $sc->new_msg($code);
    my $id = defined $sid ? $sid : $sc->msg_id;
    $msg->put_int32($id);
    ($msg, $id);
}

sub send_msg {
    my $sc = shift;
    my($buf) = @_;
    my $b = $sc->buffer_class->new( MP => 'SSH2' );
    $b->put_int32($buf->length);
    $b->append($buf->bytes);
    $sc->{channel}->send_data($b->bytes);
}

sub get_msg {
    my $sc = shift;
    my $buf = $sc->{incoming};
    my $len;
    unless ($buf->length > 4) {
        $sc->{ssh}->client_loop;
        croak "Connection closed" unless $buf->length > 4;
        $len = unpack "N", $buf->bytes(0, 4, '');
        croak "Received message too long $len" if $len > 256 * 1024;
        while ($buf->length < $len) {
            $sc->{ssh}->client_loop;
        }
    }
    my $b = $sc->buffer_class->new( MP => 'SSH2' );
    $b->append( $buf->bytes(0, $len, '') );
    $b;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Subsystem::Client - Subsystem client base class

=head1 SYNOPSIS

    package My::Subsystem;

    use Net::SSH::Perl::Subsystem::Client;
    @ISA = qw( Net::SSH::Perl::Subsystem::Client );

    use constant MSG_HELLO => 1;

    sub init {
        my $system = shift;
        $system->SUPER::init(@_);

        my $msg = $system->new_msg(MSG_HELLO);
        $msg->put_str("Hello, subsystem server.");
        $msg->send;
    }

    sub subsystem { "mysubsystem" }

=head1 DESCRIPTION

I<Net::SSH::Perl::Subsystem::Client> simplifies the process of writing
a client for an SSH-2 subsystem. A subsystem is generally a networking
protocol that is built on top of an SSH channel--the channel provides
transport, connection, encryption, authentication, message integrity,
etc. The subsystem client and server communicate over this encrypted,
secure channel (a channel built over an insecure network). SSH provides
the encrypted transport, and the subsystem is then free to act like a
standard networking protocol.

I<Subsystem::Client> is built on top of I<Net::SSH::Perl>, which provides
the client end of the services described above (encryption, message
integrity checking, authentication, etc.). It is designed to be used with
a subsystem server, working with respect to an agreed-upon networking
protocol.

SFTP is an example of a subsystem: the underlying transport is set up
by I<Net::SSH::Perl>, and on top of that layer, files can be transferred
and filesystems managed without knowledge of the secure tunnel.

=head1 USAGE

I<Net::SSH::Perl::Subsystem::Client> is intended to be used as a
base class for your protocol-specific client. It handles all
interaction with I<Net::SSH::Perl> so that your focus can be on
sending commands to the subsystem server, etc.

Your subclass will probably be most interested in using and/or
overriding the following methods:

=head2 $sc->init(%args)

Initializes a new I<Subsystem::Client> object: builds the SSH tunnel
using I<Net::SSH::Perl>, then opens up a channel along which the
subsystem traffic will be sent. It then opens a connection to the
subsystem server.

You can override this method to provide any additional functionality
that your client might need; for example, you might wish to use it
to send an 'init' message to the subsystem server.

=cut
