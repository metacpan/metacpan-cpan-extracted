use strict;
use warnings;
use Test::More;
use Net::EmptyPort qw(empty_port);

BEGIN {
    if ($^O eq 'MSWin32') {
        plan skip_all => 'Tests hang on Windows :(';
    } else {
        plan tests => 126;
    }
}

use File::Path;
use POE;
use POE::Session;
use YAML; # for Dump!
use lib 't/lib';

# We -will- get recursion warnings the way these tests are written - if you
# think there may be a bug involving runaway recursion, comment this out.
$SIG{__WARN__} = sub {
	my $m = shift;
	return if($m =~ m/recursion/i);
	warn $m;
};

BEGIN {
	my $prefix = 'POE::Component::MessageQueue';
	use_ok("POE::Component::MessageQueue::Test::EngineMaker");
	use_ok("POE::Component::MessageQueue::Test::ForkRun");
	require_ok("${prefix}::Message");
	require_ok("${prefix}::Logger");
	require_ok($_) foreach map { engine_package($_) } engine_names();
	require_ok("${prefix}::Storage::Default");
}
END {
	rmtree(DATA_DIR);	
}

my $port = empty_port();
my $remote = start_fork(sub {
	use POE::Component::MessageQueue::Storage::Remote::Server;
	POE::Component::MessageQueue::Storage::Remote::Server->new(port => $port);
});
ok($remote, "Remote storage engine started.");

my $next_id = 0;
my $when = time();
my @destinations = map {"/queue/$_"} qw(foo bar baz grapefruit);
my %messages = map {
	my $destination = $_;
	map {(++$next_id, POE::Component::MessageQueue::Message->new(
		id          => $next_id,
		timestamp   => ++$when, # We'll fake it so there's a clear time order
		destination => $destination,
		persistent  => 1,
		body        => "I am the body of $next_id.\n".  
		               "I was created at $when.\n". 
		               "I am being sent to $destination.\n",
	))} (1..50);
} (@destinations);

sub message_is {
	my ($one, $two, $name) = @_;
	if(ref $one ne 'POE::Component::MessageQueue::Message') {
		return diag "message_is called with non-message argument: ".Dump($one);
	}
	return (ok($one->equals($two), $name) or
	        diag("got: ", Dump($two), "\nexpected:", Dump($one), "\n"));
}

sub run_in_order
{
	my ($tests, $done) = @_;
	if (my $test = shift(@$tests)) {
		$test->{'sub'}->(@{$test->{args}}, sub {
			$test->{callback}->(@_, sub {
				@_ = ($tests, $done);
				goto &run_in_order;
			});
		});
	}
	else {
		goto $done;
	}
}

sub disown_loop {
	my ($storage, $destination, $client, $done) = @_;

	if($client <= 50) {
		$storage->disown_destination($destination, $client, sub {
			@_ = ($storage, $destination, $client+1, $done);
			goto &disown_loop;
		});
	}
	else {
		goto $done;
	}
}

sub claim_test {
	my ($storage, $name, $destination, $count, $done) = @_;

	$storage->claim_and_retrieve($destination, $count, sub {
		if (my $message = $_[0]) {
			@_ = ($storage, $name, $destination, $count+1, $done);
			goto &claim_test;
		}
		else {
			is($count-1, 50, "$name: $destination");
			goto $done;
		}
	});	
}

sub destination_tests {
	my ($destinations, $storage, $name, $done) = @_;
	my $destination = pop(@$destinations) || goto $done;	

	claim_test($storage, "$name: claim_and_retrieve", $destination, 1, sub {
		disown_loop($storage, $destination, 1, sub {
			claim_test($storage, "$name: disown_destination", $destination, 1, sub {
				disown_loop($storage, $destination, 1, sub {
					@_ = ($destinations, $storage, $name, $done);
					goto &destination_tests;
				});
			});
		}); 	
	});
}

sub delay_tests {
	my ($storage, $name, $done) = @_;
	
	my $time = time();
	my $delay = 2;
	my $destination = '/queue/delay';
	my $client_id = 9876;

	my $message = POE::Component::MessageQueue::Message->new(
		id          => ++$next_id,
		timestamp   => $time,
		destination => '/queue/delay',
		persistent  => 1,
		deliver_at  => $time + $delay,
		body        => "I am the body of $next_id.\n".  
		               "I was created at $time.\n". 
		               "I am being sent to $destination.\n",
	);

	my $claim;
	$claim = sub {
		my ($cb) = shift;
		$storage->claim_and_retrieve($destination, $client_id, sub {
			my ($message) = @_;
			goto $cb if (defined $message);

			sleep 1;

			# and repeat..
			@_ = ($cb);
			goto $claim;
		});
	};

	$storage->store($message->clone, sub {
		$claim->(sub {
			my $received = time();
			ok($received >= ($time + $delay), "$name: message delayed $delay seconds");
			goto $done;
		});
	});
}

sub api_test {
	my ($storage, $name, $done) = @_;

	my $ordered_tests = [
		{ 
			'sub'      => sub { $storage->get_oldest(@_) }, 
			'args'     => [],
			'callback' => sub { 
				my $cb = pop;
				my $msg = shift;
				message_is($msg, $messages{'1'}, "$name: get_oldest");
				goto $cb;
			},
		}, 
		{
			'sub'      => sub { $storage->get(@_) }, 
			'args'     => ['20'],
			'callback' => sub { 
				my $cb = pop;
				my $msg = shift;
				message_is($msg, $messages{'20'}, "$name: get");
				goto $cb;
			},
		},
		{
			'sub'      => sub { $storage->get_all(@_) },
			'args'     => [],
			'callback' => sub {
				my $cb = pop;
				my $aref = shift;
				my $all_equal = 1;
				foreach my $msg (@$aref)
				{
					my $compare = $messages{$msg->id};
					unless ($msg->equals($compare))
					{
						use YAML;
						print STDERR "Unexpected mismatch: got";
						print STDERR Dump($msg);
						print STDERR "expected";
						print STDERR Dump($compare);
						$all_equal = 0;
					}
				}
				ok($all_equal && @$aref == scalar keys %messages, "$name: get_all");
				goto $cb;
			},
		},
		{
			'sub'      => sub { $storage->claim(@_) },
			'args'     => [1 => 14],
			'callback' => sub {
				my $cb = pop;
				$storage->get(1 => sub {
					my $msg = $_[0];
					is($msg && $msg->claimant, 14, "$name: claim");
					$storage->disown_all(14, $cb);	
				});
			},
		},
		{
			'sub'      => sub { $storage->remove(@_) }, 
			'args'     => [[qw(20 25 30)]],
			'callback' => sub { 
				my $cb = pop;
				$storage->get_all(sub {
					my $messages = $_[0];
					my %hash = map {$_->id => $_} @$messages;
					ok((not exists $hash{'20'}) &&
					   (not exists $hash{'25'}) &&
					   (not exists $hash{'30'}) &&
					   (keys %hash == 197),
					   "$name: remove");
					goto $cb;
				});
			},
		},
		{
			'sub'      => sub { $storage->empty(@_) }, 
			'args'     => [],
			'callback' => sub { 
				my $cb = pop;
				$storage->get_all(sub {
					is(scalar @{$_[0]}, 0, "$name: empty");
					goto $cb;
				});
			},
		},
	];
	my @dclone = @destinations;
	destination_tests(\@dclone, $storage, $name, sub {
		run_in_order($ordered_tests, sub {
			delay_tests($storage, $name, $done);
		});
	});
}

sub store_loop {
	my ($storage, $messages, $done) = @_;
	my $message = pop(@$messages);
	
	if ($message) {
		$storage->store($message->clone, sub {
			@_ = ($storage, $messages, $done);
			goto &store_loop;
		});	
	}
	else {
		goto $done;
	}
}

sub engine_loop {
	my $names = shift;
	my $name = pop(@$names);
	unless ($name)
	{
		ok(stop_fork($remote), "remote storage engine stopped.");
		return;
	}

	rmtree(DATA_DIR);
	mkpath(DATA_DIR);
	make_db();

	my $storage = make_engine($name, { server_port => $port });
	my $clones = [values %messages];

	store_loop($storage, $clones, sub {
		api_test($storage, $name, sub {
			$storage->storage_shutdown(sub {
				ok(1, "$name: storage_shutdown");
				@_ = ($names);
				goto &engine_loop;	
			});
		});
	});
}


POE::Session->create(
	inline_states => { _start => sub {
		engine_loop([$ARGV[0] || engine_names()]);
	}},
);

$poe_kernel->run();
