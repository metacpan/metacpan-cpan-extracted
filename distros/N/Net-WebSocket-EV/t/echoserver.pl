use strict;

##### echo server

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
				
				on_msg_recv		 	=> sub { 
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