#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

my $driver;
use Neo4j::Test;
BEGIN {
	unless ($driver = Neo4j::Test->driver) {
		print qq{1..0 # SKIP no connection to Neo4j server\n};
		exit;
	}
}
my $s = $driver->session;


# The following tests all look into deprecated, but still available
# functionality. If the behaviour of such functionality changes, we
# want it to be a conscious decision, hence we test for it.

use Test::More 0.96 tests => 1 + 4;
use Test::Exception;
use Test::Warnings qw(warning warnings);


my ($d, $w, $r);


subtest 'close()' => sub {
	plan tests => 4;
	# close() always was a no-op, so we only check the deprecation warning
	$w = '';
	lives_ok { $w = warning { $driver->close; }; } 'Driver close()';
	(like $w, qr/\bdeprecate/, 'Driver close deprecated') or diag 'got warning(s): ', explain($w);
	$w = '';
	lives_ok { $w = warning { $s->close; }; } 'Session close()';
	(like $w, qr/\bdeprecate/, 'Session close deprecated') or diag 'got warning(s): ', explain($w);
};


subtest 'die_on_error = 0' => sub {
	# die_on_error only ever affected upstream errors via HTTP, 
	# never any errors issued via Bolt or by this driver itself.
	plan skip_all => "(test requires HTTP)" if $Neo4j::Test::bolt;
	plan tests => 6;
	# init
	my $d = Neo4j::Test->driver;
	$d->{die_on_error} = 0;
	my $t;
	$w = '';
	lives_ok { $w = warning { $t = $d->session->begin_transaction; }; } 'Tx open';
	(like $w, qr/\bdeprecate/, 'die_on_error deprecated') or diag 'got warning(s): ', explain($w);
	# successful statement
	lives_and { is $t->run('RETURN 42, "live on error"')->single->get(0), 42 } 'no error';
	# failing statement
	$w = '';
	lives_ok { $w = warning { is $t->run('iced manifolds.')->size, 0 }; } 'execute cypher syntax error';
	(like $w, qr/\bStatement\b.*Syntax/i, 'cypher syntax error') or diag 'got warning(s): ', explain($w);
};


subtest 'driver mutability (config/auth)' => sub {
	plan skip_all => "(test requires HTTP)" if $Neo4j::Test::bolt;
	plan tests => 5;
	lives_ok { $d = 0; $d = Neo4j::Test->driver_maybe; } 'get driver';
	lives_ok { $r = 0; $r = $d->session; } 'get auth session';  # basic_auth used by driver_maybe
	my @credentials = ('unlikely user/password combo', '');
	lives_ok { $w = warning { $d->basic_auth(@credentials) }; } 'auth mutable lives';
	(like $w, qr/\bDeprecate.*\bbasic_auth\b.*\bsession\b/i, 'auth mutable deprecated') or diag 'got warning(s): ', explain($w);
	is $d->{auth}->{principal}, $credentials[0], 'auth mutable';
};


subtest 'stats' => sub {
	plan skip_all => "(test requires HTTP)" if $Neo4j::Test::bolt;
	plan tests => 9;
	my $t = $driver->session->begin_transaction;
	$t->{return_stats} = 0;
	lives_ok { $r = $s->run('RETURN 42'); } 'run normal query';
	# deprecation warnings are expected
	lives_and { warnings { isa_ok $r->stats, 'Neo4j::Driver::SummaryCounters', 'stats' } };
	lives_and { warnings { isa_ok $r->single->stats, 'Neo4j::Driver::SummaryCounters', 'single stats type' } };
	lives_and { warnings { ok ! $r->single->stats->{contains_updates} } } 'single stats value';
	lives_ok { $r = $t->run('RETURN "no stats old syntax"'); } 'run no stats query';
	lives_and { warnings { is ref $r->stats, 'HASH' } } 'no stats: type';
	lives_and { warnings { is scalar keys %{$r->stats}, 0 } } 'no stats: none';
	lives_and { warnings { is ref $r->single->stats, 'HASH' } } 'no single stats: type';
	lives_and { warnings { is scalar keys %{$r->single->stats}, 0 } } 'no single stats: none';
};


done_testing;
