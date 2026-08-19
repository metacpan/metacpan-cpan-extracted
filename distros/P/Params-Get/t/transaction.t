#!/usr/bin/env perl

# Transaction-flow tests for Params::Get::get_params.
#
# "Transaction" here means a multi-step argument-normalisation lifecycle:
#   1. Argument lifecycle -- raw args -> normalise -> consume -> verify
#   2. Multi-step pipeline -- several modules each calling get_params in sequence
#   3. Mid-pipeline croak and recovery -- eval catches, state is clean, retry works
#   4. Idempotency -- same args normalised N times -> consistent, isolated results
#   5. Caller-variable isolation -- get_params never mutates caller variables
#   6. OO method chain -- constructor + methods each call get_params
#   7. State machine transitions -- each transition validates via get_params
#   8. Exception state integrity -- $@, $!, $_ clean across a multi-step sequence
#   9. Concurrent-like independent invocations -- no cross-contamination

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::Most;
use Test::Needs;
use Test::Memory::Cycle;
use Readonly;
use Scalar::Util qw(blessed reftype);

use Params::Get qw(get_params);
use TestHelper qw($USAGE_RE $DEFAULT_CROAK_RE);

# ---- Inline package stubs used by pipeline and state machine subtests ----

package MyApp::Router;
sub dispatch {
	# Stage 1: normalise (route, action) from positional args.
	my (undef, @args) = @_;
	return Params::Get::get_params([qw(route action)], @args);
}

package MyApp::Handler;
sub new {
	# Stage 2: normalise a single mandatory 'request' value.
	my ($class, @args) = @_;
	my $params = Params::Get::get_params('request', @args);
	return bless { request => $params->{request} }, $class;
}
sub handle {
	# Stage 3: normalise an optional options hashref (undef $default -> pass-through).
	my ($self, @args) = @_;
	my $opts = Params::Get::get_params(undef, @args) // {};
	return { request => $self->{request}, options => $opts };
}

package MyApp::Validator;
sub check {
	# Stage 4: accept the result from Handler; re-normalise to confirm it is a hashref.
	my (undef, @args) = @_;
	my $params = Params::Get::get_params(undef, @args);
	return defined($params) && ref($params) eq 'HASH';
}

package MyApp::StateMachine;
# States: idle -> receiving -> processing -> complete.
# Each transition calls get_params with a different calling convention.

sub new {
	my ($class, @args) = @_;
	my $p = Params::Get::get_params([qw(id label)], @args);
	return bless { %$p, state => 'idle' }, $class;
}
sub receive {
	my ($self, @args) = @_;
	die "receive: not in idle state (was '$self->{state}')\n"
		unless $self->{state} eq 'idle';
	my $p = Params::Get::get_params('payload', @args);
	$self->{payload} = $p->{payload};
	$self->{state}   = 'receiving';
	return $self;
}
sub process {
	my ($self, @args) = @_;
	die "process: not in receiving state (was '$self->{state}')\n"
		unless $self->{state} eq 'receiving';
	# Named pairs of options; undef default -> hashref pass-through.
	my $p = Params::Get::get_params(undef, @args) // {};
	$self->{opts}  = $p;
	$self->{state} = 'processing';
	return $self;
}
sub complete {
	my ($self, @args) = @_;
	die "complete: not in processing state (was '$self->{state}')\n"
		unless $self->{state} eq 'processing';
	my $p = Params::Get::get_params('result', @args);
	$self->{result} = $p->{result};
	$self->{state}  = 'complete';
	return $self;
}

package main;
# ---- end stubs ----

Readonly::Scalar my $SENTINEL => 'ORIGINAL';

# =========================================================================
# SECTION 1: Argument lifecycle phases
#
# Each subtest walks args through a complete lifecycle:
#   create -> normalise -> consume -> verify
# =========================================================================

subtest 'lifecycle-1: positional args -> normalise -> consume -> verify structure' => sub {
	test_needs 'Test::Returns';
	Test::Returns->import;

	# Phase 1: create raw args
	my @raw = ('Alice', 30, 'Berlin');

	# Phase 2: normalise (positional ARRAY $default)
	my $params = get_params([qw(name age city)], @raw);

	# Phase 3: consume
	my $greeting = "Hello, $params->{name} age $params->{age} from $params->{city}";

	# Phase 4: verify structure and content at every boundary
	is($params->{name}, 'Alice',   'lifecycle-1: name mapped');
	is($params->{age},  30,        'lifecycle-1: age mapped');
	is($params->{city}, 'Berlin',  'lifecycle-1: city mapped');
	like($greeting, qr/Hello, Alice age 30 from Berlin/, 'lifecycle-1: consumer output correct');
	returns_ok($params, { type => 'hashref' }, 'lifecycle-1: return type hashref');
	memory_cycle_ok($params, 'lifecycle-1: cycle-free');
};

subtest 'lifecycle-2: named pairs -> normalise -> transform -> re-normalise -> verify' => sub {
	# Phase 1: create named pairs
	my @named = (x => 10, y => 20, z => 30);

	# Phase 2: normalise into hashref
	my $p1 = get_params(undef, @named);
	is_deeply($p1, { x => 10, y => 20, z => 30 }, 'lifecycle-2: first normalise ok');

	# Phase 3: transform -- add computed field
	my %extended = (%$p1, total => $p1->{x} + $p1->{y} + $p1->{z});

	# Phase 4: re-normalise the result via fast path (sole hashref arg)
	my $p2 = get_params(\%extended);
	is($p2, \%extended, 'lifecycle-2: fast-path re-normalise returns same ref');
	is($p2->{total}, 60, 'lifecycle-2: computed total preserved through re-normalise');
};

subtest 'lifecycle-3: OO constructor lifecycle -> method call -> verify chain' => sub {
	# Phase 1: constructor normalises two separate args
	my $obj = MyApp::Handler->new('GET /index');
	is($obj->{request}, 'GET /index', 'lifecycle-3: constructor phase ok');

	# Phase 2: method normalises options hashref
	my $result = $obj->handle(retry => 3, timeout => 5);
	is_deeply($result, {
		request => 'GET /index',
		options => { retry => 3, timeout => 5 },
	}, 'lifecycle-3: method phase ok; constructor state preserved');

	memory_cycle_ok($result, 'lifecycle-3: cycle-free across OO chain');
};

subtest 'lifecycle-4: \@_ passthrough lifecycle -> re-normalise -> idempotent' => sub {
	# Phase 1: simulate a callee that received \@_ from its caller.
	my @caller_args = (a => 1, b => 2);
	my $p1 = get_params(undef, \@caller_args);
	is_deeply($p1, { a => 1, b => 2 }, 'lifecycle-4: \@_ normalised ok');

	# Phase 2: re-normalise the hashref (fast path).
	my $p2 = get_params($p1);
	is($p2, $p1, 'lifecycle-4: re-normalise via fast path returns same ref');

	# Phase 3: caller_args unchanged after both calls.
	is_deeply(\@caller_args, [a => 1, b => 2], 'lifecycle-4: caller array unmodified');
};

# =========================================================================
# SECTION 2: Multi-step dispatch pipeline
#
# Several packages each call get_params in sequence; state is asserted at
# every stage boundary.
# =========================================================================

subtest 'pipeline-1: Router -> Handler -> Validator three-stage chain' => sub {
	# Stage 1: Router normalises positional (route, action).
	my $routed = MyApp::Router->dispatch('/api/user', 'GET');
	is_deeply($routed, { route => '/api/user', action => 'GET' },
		'pipeline-1: stage 1 (Router) ok');

	# Stage 2: Handler is constructed from the route value.
	my $handler = MyApp::Handler->new($routed->{route});
	is($handler->{request}, '/api/user', 'pipeline-1: stage 2 (Handler::new) ok');

	# Stage 3: Handler processes the action; Validator checks the result.
	my $response = $handler->handle(action => $routed->{action}, version => 2);
	my $valid    = MyApp::Validator->check($response);
	ok($valid, 'pipeline-1: stage 3 (Validator) confirms result is a hashref');
	is($response->{request}, '/api/user', 'pipeline-1: stage 3 request preserved');
	is($response->{options}{action}, 'GET', 'pipeline-1: action threaded through');
};

subtest 'pipeline-2: two-stage normalise-transform-renormalise' => sub {
	# Stage 1: normalise lat/lon from positional.
	my $location = get_params([qw(lat lon)], 51.5, -0.1);
	is($location->{lat},  51.5, 'pipeline-2: stage 1 lat ok');
	is($location->{lon}, -0.1, 'pipeline-2: stage 1 lon ok');

	# Stage 2: annotate and re-normalise the enriched hashref.
	$location->{label} = 'London';
	my $final = get_params($location);   # fast path
	is($final, $location,     'pipeline-2: stage 2 fast-path returns same ref');
	is($final->{label}, 'London', 'pipeline-2: annotation visible in stage 2');
};

subtest 'pipeline-3: mandatory + options merge across two stages' => sub {
	# Stage 1: normalise the mandatory ID and metadata options.
	my $record = get_params('id', 42, { active => 1, role => 'admin' });
	is($record->{id},     42,      'pipeline-3: stage 1 mandatory id ok');
	is($record->{active}, 1,       'pipeline-3: stage 1 option active merged');
	is($record->{role}, 'admin',   'pipeline-3: stage 1 option role merged');

	# Stage 2: extract just the mandatory field and re-normalise with new options.
	my $update = get_params('id', $record->{id}, { role => 'superadmin' });
	is($update->{id},     42,          'pipeline-3: stage 2 id preserved');
	is($update->{role}, 'superadmin',  'pipeline-3: stage 2 role updated');
};

subtest 'pipeline-4: \@_ chain -- callee passes its own \@_ to a deeper callee' => sub {
	# Simulate: outer_fn(key => val) -> inner_fn(\@_) -> get_params('key', \@_).
	my @outer_args = (colour => 'blue');
	my $inner      = get_params('colour', \@outer_args);   # \@_ passthrough, shorthand fires
	is_deeply($inner, { colour => 'blue' }, 'pipeline-4: \@_ shorthand fires in inner callee');

	# inner passes its result hashref further down (fast path).
	my $deeper = get_params($inner);
	is($deeper, $inner, 'pipeline-4: deeper callee fast-path returns same ref');
};

# =========================================================================
# SECTION 3: Mid-pipeline failure and recovery
#
# An outer eval catches a croak mid-pipeline; the caller's state is inspected;
# a corrected retry succeeds without residual contamination.
# =========================================================================

subtest 'recovery-1: croak in Stage 1 caught; Stage 2 retry succeeds; $@ clean' => sub {
	my $stage1_result;
	my $pipeline_state = 'pre-stage1';

	# Stage 1 fails: missing mandatory arg.
	eval {
		$pipeline_state = 'in-stage1';
		$stage1_result  = get_params('required');   # 0 args, defined $default -> confess
		$pipeline_state = 'post-stage1';            # never reached
	};
	like($@, $USAGE_RE, 'recovery-1: stage 1 croak caught');
	is($pipeline_state, 'in-stage1', 'recovery-1: state frozen at croak point');
	ok(!defined($stage1_result), 'recovery-1: stage 1 result undefined after croak');

	# Clear $@ and retry with corrected args.
	$@ = '';
	$stage1_result  = get_params('required', 'fixed-value');
	$pipeline_state = 'post-stage1';
	is($stage1_result->{required}, 'fixed-value', 'recovery-1: retry with correct args succeeds');
	is($pipeline_state, 'post-stage1', 'recovery-1: state advanced after successful retry');
	is($@, '', 'recovery-1: $@ clean after successful retry');
};

subtest 'recovery-2: Stage 2 consumer dies; Stage 1 output still valid; re-enter from Stage 2' => sub {
	# Stage 1 succeeds.
	my $p1 = get_params([qw(op target)], 'DELETE', '/resource/99');
	is_deeply($p1, { op => 'DELETE', target => '/resource/99' },
		'recovery-2: stage 1 output valid');

	# Stage 2 consumer (simulate a downstream croak).
	my $consumer_result;
	eval {
		die "Consumer error: target not found\n" if $p1->{target} =~ m{99};
		$consumer_result = { status => 'ok' };
	};
	like($@, qr/Consumer error/, 'recovery-2: consumer croak caught');
	ok(!defined($consumer_result), 'recovery-2: consumer result undefined');

	# Stage 1 output is untouched; re-enter Stage 2 with a different target.
	$p1->{target} = '/resource/1';
	$@ = '';
	eval {
		$consumer_result = { status => 'ok', processed => $p1->{target} }
			unless $p1->{target} =~ m{99};
	};
	is($@, '', 'recovery-2: $@ clear after retry');
	is($consumer_result->{processed}, '/resource/1', 'recovery-2: consumer succeeds on retry');
};

subtest 'recovery-3: bad $default type mid-pipeline -> croak -> corrected call -> ok' => sub {
	my $result;

	# Stage 1: accidentally pass a HASH ref as $default.
	eval { $result = get_params({}, 'arg') };
	like($@, $DEFAULT_CROAK_RE, 'recovery-3: bad $default type croaks correctly');
	ok(!defined($result), 'recovery-3: result undefined after type-error croak');

	# Stage 2: corrected call with a valid string $default.
	$@ = '';
	$result = get_params('key', 'arg');
	is($result->{key}, 'arg', 'recovery-3: corrected call succeeds');
	is($@, '',               'recovery-3: $@ clean after corrected call');
};

subtest 'recovery-4: confess mid-pipeline; stack trace in $@; re-normalise succeeds' => sub {
	my @partial;
	eval {
		push @partial, get_params([qw(a b)], 1, 2);
		push @partial, get_params('x');  # confess: 0 args, defined $default
	};
	like($@, $USAGE_RE, 'recovery-4: confess caught');
	is(scalar @partial, 1, 'recovery-4: only stage 1 output collected before confess');
	is_deeply($partial[0], { a => 1, b => 2 }, 'recovery-4: stage 1 output intact');

	# Re-enter after confess.
	$@ = '';
	push @partial, get_params('x', 'value');
	is(scalar @partial, 2, 'recovery-4: stage 2 succeeded after retry');
	is($partial[1]->{x}, 'value', 'recovery-4: stage 2 result correct');
};

subtest 'recovery-5: memory clean after croak in multi-step sequence' => sub {
	my ($a, $b);
	eval {
		$a = get_params([qw(p q)], 10, 20);
		$b = get_params('r');    # croak
	};
	like($@, $USAGE_RE, 'recovery-5: croak caught');
	memory_cycle_ok($a, 'recovery-5: stage 1 result cycle-free after croak');
};

# =========================================================================
# SECTION 4: Idempotency
#
# Repeated normalisation of the same args must produce structurally consistent,
# independently isolated results.
# =========================================================================

subtest 'idempotent-1: flat named pairs normalised twice -> equal but not same ref' => sub {
	my @args = (m => 1, n => 2, o => 3);

	my $r1 = get_params(undef, @args);
	my $r2 = get_params(undef, @args);

	is_deeply($r1, $r2, 'idempotent-1: both results structurally equal');
	isnt($r1, $r2, 'idempotent-1: independent hashrefs (not same reference)');
};

subtest 'idempotent-2: hashref arg normalised twice via fast path -> same ref both times' => sub {
	my $h  = { key => 'val' };
	my $r1 = get_params($h);
	my $r2 = get_params($h);

	is($r1, $h,  'idempotent-2: first call returns same ref (fast path)');
	is($r2, $h,  'idempotent-2: second call returns same ref (fast path)');
	is($r1, $r2, 'idempotent-2: both calls return the same ref');
};

subtest 'idempotent-3: positional ARRAY $default normalised 3 times -> all equal' => sub {
	my @r;
	for (1 .. 3) {
		push @r, get_params([qw(x y)], 5, 10);
	}
	is_deeply($r[0], { x => 5, y => 10 }, 'idempotent-3: call 1 correct');
	is_deeply($r[1], $r[0],               'idempotent-3: call 2 equals call 1');
	is_deeply($r[2], $r[0],               'idempotent-3: call 3 equals call 1');
	isnt($r[0], $r[1],                    'idempotent-3: calls 1,2 are independent refs');
	isnt($r[1], $r[2],                    'idempotent-3: calls 2,3 are independent refs');
};

subtest 'idempotent-4: re-normalising a normalised result -> fast path identity' => sub {
	# Normalise once -> re-normalise the result: fast path must return same ref.
	my $step1 = get_params(undef, p => 7, q => 8);
	my $step2 = get_params($step1);
	my $step3 = get_params($step2);

	is($step2, $step1, 'idempotent-4: step2 fast-path returns step1 ref');
	is($step3, $step2, 'idempotent-4: step3 fast-path returns step2 ref (same as step1)');
};

# =========================================================================
# SECTION 5: Caller-variable isolation
#
# get_params must never mutate the caller's variables across a multi-step
# sequence.
# =========================================================================

subtest 'isolation-1: caller @_ array unmodified after multi-step normalise' => sub {
	my @original = (city => 'Rome', country => 'IT');
	my @snapshot = @original;

	my $r1 = get_params(undef, @original);
	my $r2 = get_params(undef, @original);

	is_deeply(\@original, \@snapshot, 'isolation-1: caller array unchanged after two calls');
	is_deeply($r1, { city => 'Rome', country => 'IT' }, 'isolation-1: r1 correct');
	is_deeply($r2, { city => 'Rome', country => 'IT' }, 'isolation-2: r2 correct');
};

subtest 'isolation-2: $val defensive-copy -- SCALAR ref unwrap does not mutate caller variable' => sub {
	# The module works on a copy of $args->[0] (the $val = $args->[0] line) so that
	# REF-unwrap via ${$val} never aliases back to the caller's variable.
	my $original = 'Lisbon';
	my $ref      = \$original;

	my $r1 = get_params('city', $ref);
	my $r2 = get_params('city', $ref);

	is($r1->{city}, 'Lisbon', 'isolation-2: r1 correct');
	is($r2->{city}, 'Lisbon', 'isolation-2: r2 correct');
	is($original,   'Lisbon', 'isolation-2: caller scalar unmodified after two unwrap calls');
	is($ref,       \$original,'isolation-2: caller ref still points to same scalar');
};

subtest 'isolation-3: caller \@_ array not mutated when used as array passthrough' => sub {
	my @args     = (speed => 88, unit => 'mph');
	my @snapshot = @args;

	# Two sequential \@_ normalisations.
	my $r1 = get_params(undef, \@args);
	my $r2 = get_params(undef, \@args);

	is_deeply(\@args, \@snapshot, 'isolation-3: caller array unchanged after \@_ passthrough');
	is_deeply($r1, { speed => 88, unit => 'mph' }, 'isolation-3: r1 correct');
	is_deeply($r2, $r1,                             'isolation-3: r2 equals r1');
};

subtest 'isolation-4: mutating one result hashref does not affect another' => sub {
	my @args = (k => 'original');
	my $r1   = get_params(undef, @args);
	my $r2   = get_params(undef, @args);

	# Mutate r1 in place -- r2 must be unaffected.
	$r1->{k} = 'mutated';

	is($r1->{k}, 'mutated',   'isolation-4: r1 mutated correctly');
	is($r2->{k}, 'original',  'isolation-4: r2 unaffected by r1 mutation');
};

# =========================================================================
# SECTION 6: OO method chain
#
# Simulate a realistic multi-method dispatch where each method calls
# get_params with a different calling convention.
# =========================================================================

subtest 'oo-chain-1: new(positional) -> handle(named) -> Validator::check(result)' => sub {
	my $handler  = MyApp::Handler->new('POST /submit');
	my $response = $handler->handle(content_type => 'application/json', timeout => 10);
	my $valid    = MyApp::Validator->check($response);

	ok($valid, 'oo-chain-1: validator confirms hashref result');
	is($response->{request}, 'POST /submit', 'oo-chain-1: request threaded through chain');
	is($response->{options}{content_type}, 'application/json', 'oo-chain-1: option present');
};

subtest 'oo-chain-2: two independent Handler instances share no state' => sub {
	my $h1 = MyApp::Handler->new('GET /a');
	my $h2 = MyApp::Handler->new('GET /b');

	my $r1 = $h1->handle(tag => 'first');
	my $r2 = $h2->handle(tag => 'second');

	isnt($r1, $r2, 'oo-chain-2: independent result hashrefs');
	is($r1->{request}, 'GET /a',  'oo-chain-2: h1 request correct');
	is($r2->{request}, 'GET /b',  'oo-chain-2: h2 request correct');
	is($r1->{options}{tag}, 'first',  'oo-chain-2: h1 tag correct');
	is($r2->{options}{tag}, 'second', 'oo-chain-2: h2 tag correct');
};

subtest 'oo-chain-3: Router -> Handler -> Validator full three-package sequence' => sub {
	my $route    = MyApp::Router->dispatch('/users', 'POST');
	my $handler  = MyApp::Handler->new($route->{route});
	my $response = $handler->handle(action => $route->{action}, body => '{}');
	my $valid    = MyApp::Validator->check($response);

	ok($valid, 'oo-chain-3: result valid at chain terminus');
	is($route->{action}, 'POST',       'oo-chain-3: router action correct');
	is($handler->{request}, '/users',  'oo-chain-3: handler constructed with route');
	is($response->{options}{action}, 'POST', 'oo-chain-3: action threaded end-to-end');
};

# =========================================================================
# SECTION 7: State machine transitions
#
# Each method in MyApp::StateMachine calls get_params with a different
# convention; the full lifecycle idle->receiving->processing->complete is
# walked in a single transaction.
# =========================================================================

subtest 'statemachine-1: full lifecycle idle -> receiving -> processing -> complete' => sub {
	my $sm = MyApp::StateMachine->new('TX-001', 'shipment');
	is($sm->{state},  'idle',     'sm-1: initial state idle');
	is($sm->{id},     'TX-001',   'sm-1: id set from positional');
	is($sm->{label},  'shipment', 'sm-1: label set from positional');

	$sm->receive('cargo-42');
	is($sm->{state},   'receiving', 'sm-1: after receive -> receiving');
	is($sm->{payload}, 'cargo-42',  'sm-1: payload stored');

	$sm->process(priority => 1, retries => 3);
	is($sm->{state},           'processing', 'sm-1: after process -> processing');
	is($sm->{opts}{priority},  1,            'sm-1: priority option stored');
	is($sm->{opts}{retries},   3,            'sm-1: retries option stored');

	$sm->complete('SUCCESS');
	is($sm->{state},  'complete', 'sm-1: after complete -> complete');
	is($sm->{result}, 'SUCCESS',  'sm-1: result stored');

	memory_cycle_ok($sm, 'sm-1: state machine object cycle-free at terminus');
};

subtest 'statemachine-2: two independent machines share no state' => sub {
	my $sm1 = MyApp::StateMachine->new('A-1', 'alpha');
	my $sm2 = MyApp::StateMachine->new('B-2', 'beta');

	$sm1->receive('payload-A');
	$sm2->receive('payload-B');

	is($sm1->{payload}, 'payload-A', 'sm-2: sm1 payload isolated');
	is($sm2->{payload}, 'payload-B', 'sm-2: sm2 payload isolated');
	is($sm1->{id},      'A-1',       'sm-2: sm1 id correct');
	is($sm2->{id},      'B-2',       'sm-2: sm2 id correct');
};

subtest 'statemachine-3: invalid transition (wrong state) dies; machine state unchanged' => sub {
	my $sm = MyApp::StateMachine->new('ERR-1', 'test');
	is($sm->{state}, 'idle', 'sm-3: starts idle');

	# Attempt to jump directly to process (skipping receive) -- the guard dies.
	eval { $sm->process() };
	like($@, qr/not in receiving state/, 'sm-3: guard die caught');
	is($sm->{state}, 'idle', 'sm-3: state unchanged after failed transition');

	# Correct path: go through receive first.
	$@ = '';
	$sm->receive('fixed-payload')->process()->complete('DONE');
	is($sm->{state}, 'complete', 'sm-3: correct path completes after recovery');
};

# =========================================================================
# SECTION 8: Exception state integrity across multi-step sequences
# =========================================================================

subtest 'exc-state-1: $@ correctly set by croak, cleared before retry, clean after success' => sub {
	$@ = '';
	eval { get_params('k') };
	like($@, $USAGE_RE, 'exc-state-1: $@ set correctly by croak');

	# Retry after clearing $@.
	$@ = '';
	my $r = get_params('k', 'v');
	is($r->{k}, 'v', 'exc-state-1: retry succeeds');
	is($@, '',        'exc-state-1: $@ clean after successful call');
};

subtest 'exc-state-2: $! not polluted by normalisation sequence' => sub {
	local $! = 0;
	my $r1 = get_params(undef, a => 1);
	my $r2 = get_params([qw(x)], 9);
	eval { get_params('z') };
	my $errno = $! + 0;
	is($errno, 0, 'exc-state-2: $! remains 0 across mixed-result sequence');
};

subtest 'exc-state-3: $_ not mutated by normalisation sequence' => sub {
	local $_ = $SENTINEL;
	get_params(undef, p => 1);
	get_params([qw(q)], 2);
	eval { get_params('r') };
	is($_, $SENTINEL, 'exc-state-3: $_ unchanged across normalise-then-croak sequence');
};

subtest 'exc-state-4: list-context variables ($, $;) clean across sequence' => sub {
	local $, = undef;
	local $; = "\034";   # default $SUBSEP

	get_params(undef, x => 1, y => 2);
	eval { get_params('z') };
	get_params([qw(a b)], 3, 4);

	ok(!defined($,), 'exc-state-4: $, still undef after sequence');
	is($;, "\034",   'exc-state-4: $; unchanged after sequence');
};

# =========================================================================
# SECTION 9: Concurrent-like independent invocations
#
# Perl is single-threaded, so "concurrency" is simulated with closures that
# capture the same source args and normalise independently.  Neither closure
# should observe the other's result.
# =========================================================================

subtest 'concurrent-1: two closures with same args each get their own hashref' => sub {
	my @shared_args = (lang => 'Perl', year => 1987);

	my $normalise_a = sub { get_params(undef, @shared_args) };
	my $normalise_b = sub { get_params(undef, @shared_args) };

	my $ra = $normalise_a->();
	my $rb = $normalise_b->();

	is_deeply($ra, { lang => 'Perl', year => 1987 }, 'concurrent-1: closure A result correct');
	is_deeply($rb, { lang => 'Perl', year => 1987 }, 'concurrent-1: closure B result correct');
	isnt($ra, $rb, 'concurrent-1: results are independent refs (not aliased)');
	is_deeply(\@shared_args, [lang => 'Perl', year => 1987],
		'concurrent-1: shared source array unmodified');
};

subtest 'concurrent-2: interleaved calls on different arg sets produce no cross-contamination' => sub {
	# Simulate interleaved calls as if two "concurrent" workflows were running.
	my ($a1, $b1, $a2, $b2);
	$a1 = get_params(undef, id => 'A', val => 1);
	$b1 = get_params(undef, id => 'B', val => 2);
	$a2 = get_params($a1);   # fast path -- same ref
	$b2 = get_params($b1);   # fast path -- same ref

	is($a1->{id},  'A', 'concurrent-2: a1 id correct');
	is($b1->{id},  'B', 'concurrent-2: b1 id correct');
	is($a2, $a1,        'concurrent-2: a2 fast-path returns a1 ref');
	is($b2, $b1,        'concurrent-2: b2 fast-path returns b1 ref');

	# Mutate a2; b1/b2 must be unaffected.
	$a2->{id} = 'A-modified';
	is($b1->{id}, 'B', 'concurrent-2: b1 unaffected by a2 mutation');
	is($b2->{id}, 'B', 'concurrent-2: b2 unaffected by a2 mutation');
};

subtest 'concurrent-3: shared \@_ ref normalised by two closures -> independent views' => sub {
	my @shared = (k => 'v');

	my $ra = get_params(undef, \@shared);
	my $rb = get_params(undef, \@shared);

	is_deeply($ra, { k => 'v' }, 'concurrent-3: ra correct');
	is_deeply($rb, { k => 'v' }, 'concurrent-3: rb correct');
	isnt($ra, $rb, 'concurrent-3: independent hashrefs');

	# Mutating ra does not affect rb.
	$ra->{k} = 'mutated';
	is($rb->{k}, 'v', 'concurrent-3: rb unaffected by ra mutation');
	is_deeply(\@shared, [k => 'v'], 'concurrent-3: shared source array unmodified');
};

done_testing();
