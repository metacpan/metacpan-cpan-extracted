package Net::WebSocket::EV;
use strict;
use EV;
use Carp;
use IO::Socket::INET;

our $VERSION = 0.11;

require DynaLoader;

use Encode;
# use Data::Dumper;

DynaLoader::bootstrap Net::WebSocket::EV $VERSION;

use constant {
	WS_FRAGMENTED_EOF   	=> 0,
	WS_FRAGMENTED_ERROR     => -1,
	WS_FRAGMENTED_DATA		=> 1,
};

use Exporter 'import';
our @EXPORT = qw/WS_FRAGMENTED_EOF WS_FRAGMENTED_ERROR WS_FRAGMENTED_NODATA/;



use Carp;

{
	{
		package Net::WebSocket::EV::Server;
		sub new { 
			$_[1]->{type} = 'server'; 
			&Net::WebSocket::EV::new;
		}
	}
	{
		package Net::WebSocket::EV::Client;
		sub new { 
			$_[1]->{type} = 'client'; 
			&Net::WebSocket::EV::new;
		}
	}
}


sub new {
	my ($pkg, $self) = @_;
	
	$self->{buffering} //= 1;
	
	_wslay_event_context_init($self, ($self->{fd} // fileno($self->{fh})),  int($self->{type} eq 'server') );
	
	_wslay_event_config_set_no_buffering($self, int (!$self->{buffering}) );
	
	_wslay_event_config_set_max_recv_msg_length($self, $self->{max_recv_size} ) if defined $self->{max_recv_size};
	
	
	bless($self);
}

sub wait {
	if($_[1]){
		$_[0]->_set_waiter($_[1]);
	} else{
		$_[0]->_set_waiter(Coro::rouse_cb());
		return Coro::rouse_wait();
	}
}


sub dl_load_flags {0}; # Prevent DynaLoader from complaining and croaking

1;

=head1 NAME

Net::WebSocket::EV - Perl wrapper around Wslay websocket library

=head1 DESCRIPTION

Net::WebSocket::EV - websocket module based on Wslay L<http://wslay.sourceforge.net/>. This module uses libev for doing IO.

=head1 SYNOPSIS

	
	##### echo server #####

	use Net::WebSocket::EV;
	use HTTP::Server::EV;
	use Digest::SHA1 qw(sha1_base64);

	HTTP::Server::EV->new->listen(888, sub {
			my $cgi = $_[0];
			
			$cgi->header({
				STATUS 		=> '101 Switching Protocols',
				Upgrade		=> "websocket",
				Connection	=> "Upgrade",
				"Sec-WebSocket-Accept" 	=> scalar 
					sha1_base64( $cgi->{headers}{"Sec-WebSocket-Key"} . "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" ).'=',
			});
			
			$cgi->{self} = $cgi; # circular. Keep object
			
			$cgi->{buffer}->flush_wait(sub {
			
				$cgi->{websocket} = Net::WebSocket::EV::Server->new({
					fh => $cgi->{buffer}->give_up_handle,
					
					on_msg_recv => sub { 
						my ($rsv,$opcode,$msg, $status_code) = @_;
						
						$cgi->{websocket}->queue_msg($msg);
					},
					
					on_close => sub {
						my($code) = @_;
						
						#remove circular
						$cgi->{self} = undef;
						$cgi = undef;
					},
					buffering => 1,
				});
				
			});
	},  { threading => 0 });

	EV::run;
	

=head1 METHODS

=head2 new( { params } )

Can be used as Net::WebSocket::EV::Server->new or Net::WebSocket::EV::Client->new

Params:

=over

=item fh

Filehandle of socket to use. Socket must be set in non blocking mode.

Net::WebSocket::EV doesn't do handshake, you must do it before calling new(). 

=item buffering

If set to 0 - disables buffering. on_msg_recv is always called with empty $msg, use on_frame_recv_* to handle messages. Useful for handling big binary data without buffering it in memory.

Default if not defined : 1

=item max_recv_size

Max message or frame size, see L<http://wslay.sourceforge.net/man/wslay_event_config_set_max_recv_msg_length.html>

=item on_msg_recv

This callback is called when library receives complete message. Close messages aren't handled by this callback. When buffering is disabled $msg is always empty 

Callback arguments: my ($rsv, $opcode, $msg, $status_code) = @_;

=item on_close

Called when connection is closed.

Callback arguments: my ($close_code) = @_;

=item genmask

Used only by Net::WebSocket::EV::Client. Must return $len bytes scalar to mask message. If not specified, then simple rand() mask generator is used. 

Callback arguments: my ($len) = @_;

=item on_frame_recv_start

Called when frame header is received.

Callback arguments: my ($fin, $rsv,$opcode,$payload_length) = @_;

=item on_frame_recv_chunk

Called when next data portion is received.

Callback arguments: my ($data) = @_;

=item on_frame_recv_end

Called when message is received. No arguments

=back

=cut

=head2 queue_msg( message, opcode )

Queue message, opcode is optional default is 1 (text message)

=head2 queue_fragmented ( callback, opcode )

Queue fragmented message, opcode is optional, default is 2 (binary message)

Callback arguments: my ($len) = @_; 

Callback must return array of two elements ( "scalar $len or less(can be 0) bytes length", status )

Status can be:

WS_FRAGMENTED_DATA - Data chunk, optional status value, you can just return one scalar with data. Wslay will constantly reinvoke callback when it returns WS_FRAGMENTED_DATA. It will let other events run, but you will get 100% cpu load if there is no data to send and your callback always returns WS_FRAGMENTED_DATA with empty scalar while waiting for data. To prevent this use ->stop_write to suspend all IO when there is no more data to send and ->start_write when new portion of data is ready.

WS_FRAGMENTED_ERROR - Error. Don't call callback anymore

WS_FRAGMENTED_EOF - End of message.


=head2 wait(cb)

Callback called when send queue becomes empty. If callback isn't specified, then tryes to use Coro::rouse_cb & Coro::rouse_wait to block current coro.

=head2 queued_count()

Returns number of messages in send queue

=head2 start() and stop()

Start or stop all webosocket IO

=head2 start_read() and stop_write()

=head2 start_read() and stop_read()

=head2 shutdown_read() and shutdown_write()

Disable read or write. There is no way to enable it again, use start_* and stop_* instead

=head2 close( status_code, reason_data)

Queue close frame. Status and reason are optional.

Possible atack vector: client can hold connection after receiving close frame and make a lot of connections. So if you want to guaranteed close connection, then call $ws->close() and ->wait until close frame will be sent, then close socket by close($ws->{fh}).

=cut

1;