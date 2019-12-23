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

use Test::More 0.96 tests => 1 + 2;
use Test::Exception;
use Test::Warnings qw(warning);


my ($w);


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
	plan tests => 8;
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
	# connection issue
	$w = '';
	lives_ok { $w = warning {
		no warnings 'deprecated';
		my $d = Neo4j::Test->driver_no_host;
		$d->{die_on_error} = 0;
		$d->session->run;
	}; } 'no connection';
	(like $w, qr/\bNetwork\b.*\bCan't connect\b/i, 'no connection warning') or diag 'got warning(s): ', explain($w);
};


done_testing;
