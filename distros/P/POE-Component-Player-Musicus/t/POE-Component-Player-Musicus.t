#!/usr/bin/perl

use Test::More; tests => 528;

use POE;
use warnings;
use strict;

my $musicus;

BEGIN {
	foreach(split(':', $ENV{PATH})) {
		if(-x $_ . '/musicus') {
			$musicus = $_ . '/musicus';
			last;
		}
	}

	if(!$musicus) {
		plan skip_all => 'Cannot run tests without musicus installed.';
	} else {
		plan tests => 528;
		ok($musicus, "Found Musicus executable $musicus");
		use_ok( 'POE::Component::Player::Musicus' );
	}
}

ok(-r 't/test.mp3', 'Found test MP3');
ok(-r 't/test-notags.mp3', 'Found test MP3 with no tags');

my $session = POE::Session->create(
	inline_states	=> {
		_start	=> sub {
			my ($kernel, $heap) = @_[ KERNEL, HEAP ];
			ok($kernel, 'POE Kernel started');
			$kernel->alias_set('main');
			$kernel->delay('timeout', 60);
			$heap->{musicus} = POE::Component::Player::Musicus->new(musicus => $musicus, delay => 10000);
			isa_ok($heap->{musicus}, 'POE::Component::Player::Musicus', 'Musicus Object');
			$heap->{secondtime} = 0;
			$heap->{versiontimes} = 0;
		},
		ready	=> sub {
			my $heap = $_[ HEAP ];
			pass('Got ready event');
			$heap->{musicus}->getinfo('t/test.mp3');
		},
		play	=> sub {
			my $heap = $_[ HEAP ];
			pass('Got play event');
			sleep 1; # Let the audio get going
			if($heap->{secondtime}) {
				$heap->{musicus}->getinfocurr;
			} else {
				# Stress test
				for(1..500) { $heap->{musicus}->version; }
			}
		},
		version	=> sub {
			my ($heap, $version) = @_[ HEAP, ARG0 ];
			ok($version, "Got Musicus version $version " . ++$heap->{versiontimes} . " times");
			if($heap->{versiontimes} >= 500) {
				$heap->{musicus}->getvol;
			}
		},
		getvol	=> sub {
			my ($heap, $left, $right) = @_[ HEAP, ARG0, ARG1 ];
			ok($left, "Got left channel volume $left");
			ok($right, "Got right channel volume $right");
			$heap->{musicus}->setvol($left, $right);
		},
		setvol	=> sub {
			my $heap = $_[ HEAP ];
			pass('Set volume');
			$heap->{musicus}->pause;
		},
		pause	=> sub {
			my $heap = $_[ HEAP ];
			pass('Paused');
			$heap->{musicus}->unpause;
		},
		unpause	=> sub {
			my $heap = $_[ HEAP ];
			pass('Unpaused');
			$heap->{musicus}->setpos(5);
		},
		setpos	=> sub {
			my ($heap, $pos) = @_[ HEAP, ARG0 ];
			is($pos, 5, "Set position to $pos");
			sleep 1; # Just in case
			$heap->{musicus}->getpos;
		},
		getpos	=> sub {
			my ($heap, $pos) = @_[ HEAP, ARG0 ];
			cmp_ok($pos, '>=', 5, "Got position $pos");
			$heap->{musicus}->getlength;
		},
		getlength	=> sub {
			my ($heap, $length) = @_[ HEAP, ARG0 ];
			cmp_ok($length, '>', 0, "Got length $length");
			$heap->{musicus}->getinfocurr;
		},
		getinfo		=> sub {
			my ($heap, $info) = @_[ HEAP, ARG0 ];
			is_deeply($info, {
				length	=> 61271,
				artist	=> 'Curtis "Mr_Person" Hawthorne',
				title	=> 'POE::Component::Player::Musicus Test MP3',
				album	=> '',
				track	=> '',
				genre	=> 'Ambient',
				year	=> '2004',
				date	=> '',
				comment	=> '',
				file	=> 't/test.mp3',
			}, 'Retrieved song info');
		
			$heap->{musicus}->play('t/test.mp3');
		},
		getinfocurr	=> sub {
			my ($heap, $info) = @_[ HEAP, ARG0 ];
			if($heap->{secondtime}) {
				is_deeply($info, {
					length	=> 59975,
					artist	=> '',
					title	=> 'test-notags',
					album	=> '',
					track	=> '',
					genre	=> '',
					year	=> '',
					date	=> '',
					comment	=> '',
					file	=> 't/test-notags.mp3',
				}, 'Retrieved song info');
			} else {
				is_deeply($info, {
					length	=> 61271,
					artist	=> 'Curtis "Mr_Person" Hawthorne',
					title	=> 'POE::Component::Player::Musicus Test MP3',
					album	=> '',
					track	=> '',
					genre	=> 'Ambient',
					year	=> '2004',
					date	=> '',
					comment	=> '',
					file	=> 't/test.mp3',
				}, 'Retrieved song info');
			}
			$heap->{musicus}->stop;
		},
		stop	=> sub {
			my $heap = $_[ HEAP ];
			pass('Got stop event');
			if($heap->{secondtime}) {
				is($heap->{musicus}->xcmd(), -1, 'xcmd returned on null command correctly');
				$heap->{musicus}->xcmd('cheeseburger');
			} else {
				$heap->{secondtime} = 1;
				$heap->{musicus}->play('t/test-notags.mp3');
			}
		},
		quit	=> sub {
			pass('Got quit event');
		},
		done	=> sub {
			my $kernel = $_[ KERNEL ];
			pass('Musicus exited gracefully');
			$kernel->delay('timeout'); # Clear timer event
		},
		died	=> sub {
			fail('Musicus exited with errors');
			die 'Musicus exited with errors';
		},
		timeout	=> sub {
			fail("Test timed out");
			die "Test timed out";
		},
		error	=> sub {
			my ($heap, $error) = @_[ HEAP, ARG1 ];
			is_deeply($error, {
				err	=> -1,
				syscall	=> 'cheeseburger',
				error	=> 'unknown command',
			}, 'Properly handled expected error');
			$heap->{musicus}->quit;
		},
	},
	#options => { trace => 1, debug => 1 },
);

ok($session, 'Created POE Session');

POE::Kernel->run;
pass('POE Kernel stopped');
=for test
$session = POE::Session->create(
	inline_states	=> {
		_start	=> sub {
			my ($kernel, $heap) = @_[ KERNEL, HEAP ];
			ok($kernel, 'POE Kernel started');
			$kernel->alias_set('main');
			$kernel->delay('timeout', 60);
			$heap->{musicus} = POE::Component::Player::Musicus->new(musicus => $musicus, delay => 500);
			isa_ok($heap->{musicus}, 'POE::Component::Player::Musicus', 'Musicus Object');
			$heap->{secondtime} = 0;
		},
		ready	=> sub {
			my $heap = $_[ HEAP ];
			pass('Got ready event');
			$heap->{musicus}->quit();
		},
		quit	=> sub {
			pass('Got quit event');
		},
		timeout	=> sub {
			fail("Test timed out");
			die "Test timed out";
		},
	},
	#options => { trace => 1, debug => 1 },
);

ok($session, 'Created POE Session');

POE::Kernel->run;
pass('POE Kernel stopped');
=cut
