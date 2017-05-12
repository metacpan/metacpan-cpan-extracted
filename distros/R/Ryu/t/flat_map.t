use strict;
use warnings;

use Log::Any::Adapter 'TAP';

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;
use Variable::Disposition;

subtest 'simple chain of arrayrefs' => sub {
	my $src = Ryu::Source->new(label => 'first');
	my @actual;
	is(exception {
		$src->flat_map(sub { [ 1..3 ]})
			->each(sub {
				push @actual, $_;
			});
	}, undef, 'can flat_map without exceptions');
	is(exception {
		$src->emit(1..3);
	}, undef, 'emit works');
	cmp_deeply(\@actual, [ (1..3) x 3 ], 'flat_map operation was performed');
	ok($src, 'source is still valid');
	done_testing;
};

subtest '::Source expansion' => sub {
	my $src = Ryu::Source->new(label => 'first');
	my @actual;
	my @nested;
	my $code = sub {
		my $nested = Ryu::Source->new(label => 'nested');
		push @nested, $nested;
		$nested
	};
	$src->flat_map($code)
		->each(sub {
			push @actual, $_;
		});
	is(0 + @nested, 0, 'no sources created yet');
	$src->emit(1);
	is(0 + @nested, 1, 'now have a nested source');
	$src->emit(1);
	is(0 + @nested, 2, '... and another one');
	$_->emit('a') for @nested;
	cmp_deeply(\@actual, [ ('a') x 2 ], 'flat_map operation was performed');
	ok($src, 'source is still valid');
	done_testing;
};

subtest 'early exit' => sub {
	my $src = Ryu::Source->new(label => 'first');
	my @actual;
	my $count = 0;
	my @nested;
	my $chained = $src->flat_map(sub {
			my $next = Ryu::Source->new(label => 'nested ' . ++$count);
			push @nested, $next;
			$next
		})
		->take(3)
		->each(sub {
			push @actual, $_;
		});
	is($count, 0, 'start with none');
	$src->emit(1);
	is($count, 1, 'count 1');
	is(0 + @nested, 1, '... and single source');
	$_->emit('x') for @nested;
	is($count, 1, 'still count 1');
	is(0 + @nested, 1, '... and single source');
	$_->emit('y') for @nested;
	is($count, 1, 'still count 1');
	ok(!$chained->is_ready, 'chained is not yet ready');
	$_->emit('z') for @nested;
	is($count, 1, 'still count 1');
	ok($chained->is_ready, 'but chained is now ready');
	ok($_->is_ready, 'nested item ' . $_->describe . ' is ready') for @nested;
	cmp_deeply(\@actual, [ qw(x y z) ], 'flat_map operation was performed');
	ok($src, 'source is still valid');
	is(exception {
		dispose($chained)
	}, undef, 'can dispose chained');
	done_testing;
};
done_testing;

