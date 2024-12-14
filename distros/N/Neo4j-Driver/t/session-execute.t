#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.94;
use Test::Exception;
use Test::Warnings 0.010 qw(warning :no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';


# The execute_... group of methods are used to run managed transactions
# that can perform retries automatically for certain kinds of errors.

use Scalar::Util qw(weaken);
use Time::HiRes ();

use Neo4j::Driver;
use Neo4j::Error;
use Neo4j_Test;
use Neo4j_Test::EchoHTTP;
use Neo4j_Test::MockQuery;

plan tests => 10 + $no_warnings;


my ($d, $s, $r, @r);
my $echo = Neo4j_Test::EchoHTTP->new;
my $mock;


subtest 'access mode' => sub {
	plan tests => 2;
	$s = Neo4j::Driver->new->plugin($echo)->session;
	$r = $s->execute_read(sub { shift->run('foo')->single });
	is $r->get('mode'), 'READ', 'access mode read';
	$r = $s->execute_write(sub { shift->run('foo')->single });
	is $r->get('mode'), 'WRITE', 'access mode write';
};


subtest 'server error no retry' => sub {
	plan tests => 3 + 2;
	$mock = Neo4j_Test::MockQuery->new;
	$mock->query_result('foo' => 'bar');
	
	# Permanent error
	$mock->query_result('perm error' => Neo4j::Error->new( Server => {
		code => 'Neo.ClientError.Statement.SyntaxError',
	}));
	$s = Neo4j::Driver->new->plugin($mock)->session;
	my $try = 0;
	throws_ok {
		$s->execute_read(sub { $try++; shift->run('perm error'); });
	} qr/\.SyntaxError\b/, 'perm error dies';
	is $try, 1, 'no retry';
	$mock->query_result('foo' => 'bar');
	$r = $s->execute_read(sub { shift->run('foo')->single });
	is $r->get, 'bar', 'session usable';
	
	# Temporary error, retry disabled
	$mock->query_result('temp error' => Neo4j::Error->new( Server => {
		code => 'Neo.TransientError.Database.DatabaseUnavailable',
	}));
	$d = Neo4j::Driver->new->plugin($mock);
	$s = $d->config(max_transaction_retry_time => 0)->session;
	$try = 0;
	throws_ok {
		$s->execute_read(sub { $try++; shift->run('temp error'); });
	} qr/\.DatabaseUnavailable\b/, 'temp error dies';
	is $try, 1, 'disabled retry';
};


subtest 'server error with retry' => sub {
	$mock = Neo4j_Test::MockQuery->new;
	$mock->query_result('foo' => 'bar');
	$mock->query_result('error' => Neo4j::Error->new( Server => {
		code => 'Neo.TransientError.Database.DatabaseUnavailable',
	}));
	
	# Establish baseline timing
	$d = Neo4j::Driver->new->plugin($mock);
	$s = $d->config(max_transaction_retry_time => 0)->session;
	my $sleep = - Time::HiRes::time;
	eval { $s->execute_read(sub { shift->run('error') }) };
	Time::HiRes::sleep 0.001;  # 1/1000 of default
	$sleep += Time::HiRes::time;
	my $timeout = $sleep * 30;
	
	# limit: retry speed 10 ms
	plan skip_all => "(test too slow)" unless $ENV{EXTENDED_TESTING} || $timeout < 0.3;
	plan tests => 1 + 3;
	
	$d = Neo4j::Driver->new->plugin($mock);
	$s = $d->config(max_transaction_retry_time => $timeout)->session;
	$s->{retry_sleep} = $sleep;
	
	# Temporary error, retry keeps failing
	my $start = Time::HiRes::time;
	my $try = 0;
	throws_ok {
		$s->execute_read(sub { $try++; shift->run('error'); });
	} qr/\.DatabaseUnavailable\b/, 'retry dies';
	$try > 2 or warn sprintf "retry stops after run %i (%i ms, limit %i ms)",
		$try, map {$_ * 1000} Time::HiRes::time - $start, $timeout;  # 6 tries are expected
	
	# Temporary error, retry eventually succeeds
	$try = 0;
	lives_ok {
		$s->execute_read(sub {
			$r = ++$try < 2 ? shift->run('error') : shift->run('foo')
		});
	} 'retry lives';
	is $try, 2, 'succeeds on 2nd try';
	is $r->single->get, 'bar', 'result';
};


subtest 'commit/rollback' => sub {
	plan tests => 6;
	my $commit;
	$mock = Neo4j_Test::MockQuery->new;
	$mock->query_result('q1' => 'baz', sub { $commit *= 3 });
	$mock->query_result('q2' => 'baz', sub { $commit *= 5 });
	$mock->query_result('q3' => 'baz', sub { $commit *= 7 });
	$s = Neo4j::Driver->new->plugin($mock)->session;
	
	$commit = 1;
	$r = $s->execute_write(sub {
		my $tx = shift;
		$tx->run('q1');
		$tx->run('q2');
		$tx->run('q2');
		return $commit;
	});
	is $r, 1, 'no commit before return';
	is $commit, 3*5*5, 'commit q1 q2 q2';
	
	$commit = 1;
	dies_ok { $s->execute_write(sub {
		my $tx = shift;
		$tx->run('q2');
		$tx->run('q3');
		die;
	})} 'rollback q2 q3';
	is $commit, 1, 'no commit q2 q3';
	
	$commit = 1;
	dies_ok { $s->execute_write(sub {
		shift->run('q1');
		die $s;  # blessed object that isn't a Neo4j::Error
	})} 'rollback q1';
	weaken $s;
	is $commit, 1, 'no commit q1';
};


subtest 'function executed exactly once for no retry' => sub {
	plan tests => 2;
	$s = Neo4j::Driver->new({ max_transaction_retry_time => 0 })->plugin($mock)->session;
	my $run;
	$r = $s->execute_write(sub { ++$run });
	is $run, 1, 'scalar context runs once';
	@r = $s->execute_write(sub { ++$run });
	is $run, 2, 'list context runs once';
};


subtest 'wantarray context passed through' => sub {
	plan tests => 4;
	$s = Neo4j::Driver->new->plugin($echo)->session;
	$r = $s->execute_read(sub { wantarray });
	is $r, !!0, 'no wantarray read';
	$r = $s->execute_write(sub { wantarray });
	is $r, !!0, 'no wantarray write';
	@r = $s->execute_read(sub { wantarray });
	is $r[0], !!1, 'yes wantarray read';
	@r = $s->execute_write(sub { wantarray });
	is $r[0], !!1, 'yes wantarray write';
};


subtest 'usage errors' => sub {
	plan tests => 4;
	$s = Neo4j::Driver->new->plugin($echo)->session;
	throws_ok {
		$s->execute_write('RETURN 42');
	} qr/\brequires subroutine ref\b/i, 'wrong arg type';
	throws_ok {
		$s->execute_read;
	} qr/\brequires subroutine ref\b/i, 'too few args';
	throws_ok {
		$s->execute_write(sub { shift->commit });
	} qr/\bcommit\b.*\bmanaged transaction\b/i, 'explicit commit';
	throws_ok {
		$s->execute_read(sub { shift->rollback });
	} qr/\brollback\b.*\bmanaged transaction\b/i, 'explicit rollback';
};


subtest 'warn when returning the result' => sub {
	plan tests => 3;
	$s = Neo4j::Driver->new->plugin($echo)->session;
	my ($w, $rr);
	lives_and {
		$w = warning { $rr = scalar $s->execute_read(sub { $r = $s->run }) };
		is $rr, $r;
	} 'returning result allowed';
	like $w, qr/\bResult object\b.*valid\b/i, 'returning result: warning in scalar context'
		or diag 'got warning(s): ', explain $w;
	$w = warning { $s->execute_read(sub { $s->run }) };
	ok ref $w eq 'ARRAY' && ! @$w, 'returning result: no warning in void context'
		or diag 'got warning(s): ', explain $w;
};


{
	package Neo4j_Test::IgnoreErrors;
	use parent 'Neo4j::Driver::Plugin';
	sub new { bless {}, shift }
	sub register {
		my ($self, $events) = @_;
		$events->add_handler( error => sub { $self->{error}++ } );
		Scalar::Util::weaken $self;
	}
}


subtest 'custom error handler' => sub {
	plan tests => 3;
	$d = Neo4j::Driver->new;
	$d->plugin( my $ierr = Neo4j_Test::IgnoreErrors->new );
	$d->plugin( my $mock = Neo4j_Test::MockQuery->new );
	$mock->query_result('error' => Neo4j::Error->new( Server => {
		code => 'Neo.ClientError.Statement.SyntaxError',
	}));
	lives_ok {
		@r = (1); @r = $d->session->execute_read(sub { shift->run('error'); });
	} 'ignored error lives';
	is $ierr->{error}, 1, 'error raised';
	is_deeply [@r], [], 'returns empty';
};


subtest 'live server' => sub {
	my $session = eval { Neo4j_Test->driver->session };
	plan skip_all => "(no session)" unless $session;
	plan skip_all => '(not implemented in simulator)' if $Neo4j_Test::sim;
	plan tests => 7;
	$session->{driver}->{config}->{max_transaction_retry_time} = 0;  # speed up testing
	my $count = $r = $session->run('MATCH (a:Test) WHERE a.test IS NOT NULL RETURN a')->size;
	
	throws_ok {
		$session->execute_write(sub {
			my $tx = shift;
			$tx->run('CREATE (a:Test {test: 1}) RETURN a')->single;
			$tx->run('CREATE (a:Test {test: 2}) RETURN a')->single;
			die "oops, rollback";
		});
	} qr/\boops, rollback\b/, 'write rollback';
	lives_ok {
		$r = $session->run('MATCH (a:Test) WHERE a.test IS NOT NULL RETURN a')->size;
	} 'session usable after rollback';
	is $r, $count, 'rollback no commit';
	
	throws_ok {
		$session->execute_write(sub {
			my $tx = shift;
			$tx->run('CREATE (a:Test {test: 3}) RETURN a')->single;
			$tx->run('syntax error!')->single;
		});
	} qr/\.(?:SyntaxError|InvalidSyntax)\b/, 'write error';
	lives_ok {
		$r = $session->run('MATCH (a:Test) WHERE a.test IS NOT NULL RETURN a')->size;
	} 'session usable after error';
	is $r, $count, 'error no commit';
	
	lives_and {
		$r = $session->execute_read(sub {
			return shift->run('RETURN 42')->single;
		});
		is $r->get, 42;
	} 'read commit';
};


done_testing;
