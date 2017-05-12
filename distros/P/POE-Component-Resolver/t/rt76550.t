#!/usr/bin/perl -w

use utf8;

use warnings;
use strict;

sub POE::Kernel::ASSERT_DEFAULT   () { 1 }
sub POE::Kernel::CATCH_EXCEPTIONS () { 0 }

use Test::More tests => 1;

use POE;
use POE::Component::Resolver;

my $responses = 0;

my $resolver = POE::Component::Resolver->new(
	max_resolvers => 1,
	idle_timeout  => 2,
);

POE::Session->create(
	inline_states => {
		_start   => sub {
			$_[KERNEL]->alias_set("client_session");
		},
		shutdown => sub {
			$_[KERNEL]->alias_remove("client_session");
		},
		_stop => sub {
			$resolver = undef;
		},
	},
);

# The test fails when it doesn't exit promptly (if at all).
# Use SIGALRM to detect the condition, with enough time for even slow
# computers to finish normally... I hope.

my $timed_out = 0;
alarm(5);
$SIG{ALRM} = sub {
	$timed_out = 1;
	POE::Kernel->post( client_session => 'shutdown' );
};

POE::Kernel->run();

# There is a bit of a race condition here.  The alarm could go off
# somewhere in POE::Kernel->run() as it's trying to clean up.  What
# can be done to mitigate that?

alarm(0);

is($timed_out, 0, "exited normally");

exit;

