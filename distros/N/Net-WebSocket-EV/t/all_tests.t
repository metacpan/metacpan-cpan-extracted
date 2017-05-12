use strict;
no warnings;
use Socket;
use blib;
use utf8;

# use Data::Dumper;

use Test::More tests => 3;
use Net::WebSocket::EV;

BEGIN { use_ok('Net::WebSocket::EV') };

my $server_sock = IO::Socket::INET->new(
	Listen    => 5,
	LocalAddr => '127.0.0.1',
	LocalPort => 42235,
	Proto     => 'tcp',
	# Blocking => 0,
) or die 'Failed to bind server!';
	

my (@server, @client, $server, $connected_client_socket);

my $server;

my ($fragmented_rcv_state);

EV::once $server_sock, EV::READ, 10, sub {
	
	$connected_client_socket = $server_sock->accept();
	$connected_client_socket->blocking(0);
	
	$server = Net::WebSocket::EV::Server->new({
		fh => $connected_client_socket,
		on_frame_recv_start => sub { 
			@server = @_;
			# warn 'on_frame_recv_start';
			 # warn Dumper \@_;
		},
		on_frame_recv_chunk	=> sub { 
			@server = @_;
			# warn 'on_frame_recv_chunk';
			 # warn Dumper \@_;
		},
		on_frame_recv_end 	=> sub { 
			@server = @_;
			# warn 'on_frame_recv_end';
			 # warn Dumper \@_;
		},
		on_msg_recv		 	=> sub { 
			my ($rsv,$opcode,$msg, $status_code) = @_;
			@server = @_;
			# warn 'on_msg_recv';
			
			if(($msg eq 'first test message test test Юникод') and $opcode == 1){
				pass("Send and receive text meassge" );
				call_next_test();
			}
			
			if(($msg eq 'DataChunkDataChunk2') and $opcode == 2){
				# pass("Fragmented binary message received" );
				pass("Fragmented binary message received" );
				call_next_test();
			}
		},
		
		on_close => sub {
			@server = @_;
		},
		
		buffering => 1, 
		# max_recv_size => 1024 * 10,
	});
};

my $client_sock = IO::Socket::INET->new(
	PeerAddr => '127.0.0.1',
	PeerPort => 42235,
	Proto     => 'tcp',
	Blocking => 0,
) or die 'Failed to client connect!';


my $client = Net::WebSocket::EV::Client->new({
	fh => $client_sock,
	on_frame_recv_start => sub { 
		@client = @_;
	},
	on_frame_recv_chunk	=> sub { 
		@client = @_;
	},
	on_frame_recv_end 	=> sub { 
		@client = @_;
	},
	on_msg_recv		 	=> sub { 
		my ($rsv,$opcode,$msg, $status_code) = @_;
		@client = @_;
		
	},
	
	on_close => sub {
		@client = @_;
	},
	
	buffering => 0, 
	# max_recv_size => 1024 * 10,
});

print Dumper [@server, @client];

my $w = EV::timer 0.1, 1, sub {};
my $w = EV::timer 0.1, 1, sub {print Dumper [@server, @client];};
# my $w = EV::timer 0.1, 0.1, sub {print Dumper [@server, @client];};


{
	my $state = 0;
	my $starter;
	
	sub fragment_gen {
	
		if($state == 0){
			$state++;
			return 'DataChunk';
		}
		elsif($state == 1){
		
			$starter = EV::once undef, undef, 0.8 , sub {
				$state++;
				# $client->start;;
				$client->start_write;
			};
			
			# $client->stop;
			$client->stop_write;
			return '';
		}
		elsif($state == 2){
			return( 'DataChunk2', WS_FRAGMENTED_EOF);
		}
		
	};
	
}




my @async_tests;
sub call_next_test {
	 ( (shift @async_tests) or sub { exit 0 } )->();
};

@async_tests = ( 
	sub {
		$client->queue_msg('first test message test test Юникод', 1);
	},
	sub {
		$client->queue_fragmented(\&fragment_gen, 2);
	},
	
);




call_next_test;

EV::run;