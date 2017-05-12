# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use POE;

use Test;
BEGIN { plan tests => 1 };
use POE::Component::Server::PreforkTCP;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#sub POE::Component::Server::PreforkTCP::DEBUG { 1 }


new POE::Component::Server::PreforkTCP(
		Port => 23000,
#		MaxSessionPerServer => 1,
#		MaxServerLifeTime => 50,
		ShutdownChildren => 1,
		ClientConnected => sub {
			my ( $heap , $input, $kernel) 
				= @_[HEAP, ARG0, KERNEL];
			$heap->{client}->put("test server , welcome$$ !\n");
			},
		ClientInput => sub {
			my ( $heap , $input, $kernel) 
				= @_[HEAP, ARG0, KERNEL];
			$heap->{client}->put("$$ : $input\n");
			print("$$ : $input\n");
			if ( $input eq 'quit' ) {
				$kernel->yield('shutdown');
			}
			if ( $input eq 'exit' ) {
				$kernel->yield('shutdown');
				$kernel->post($heap->{master_alias},
						'shutdown');
			}
			if ( $input eq 'kill' ) {
				exit 1;
			}
		}
	);

POE::Session->create(
	inline_states => {
		_start => sub {
			$_[KERNEL]->post('prefork_master','_stop', 1);
			$_[KERNEL]->delay('exit', 2);
			},
		_stop => sub {},
		exit => sub {
				kill INT => $$;
			},
		},
	);

ok(2);

$poe_kernel->run();

ok(3);

