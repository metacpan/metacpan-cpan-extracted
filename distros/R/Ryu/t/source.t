use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::Refcount;

use Variable::Disposition;
use Ryu::Source;

subtest 'emit and filter' => sub {
	my $src = new_ok('Ryu::Source');
	is(exception {
		$src->emit($_) for 1..3;
	}, undef, 'no exception when emitting');

	is(exception {
		my @expected = (1..3);
		isa_ok(my $odd = $src->filter(sub {
			is($_, shift @expected, 'have expected value ' . $_);
			$_ % 2
		}), 'Ryu::Source');
		isnt($odd, $src, 'filtered source is different from original');
		my %odd;
		$odd->each(sub {
			++$odd{$_}
		});
		$src->emit($_) for 1..3;
		cmp_deeply(\%odd, { 1 => 1, 3 => 1 }, 'saw expected values after filtering');
	}, undef, 'no exception when emitting');
	done_testing;
};

subtest 'filter objects with methods' => sub {
	package Local::Object {
		sub new { bless { @_[1..$#_] }, $_[0] }
		sub name { $_[0]->{name} }
		sub id { $_[0]->{id} }
	}

	my @objects = map Local::Object->new(id => $_, name => "thing $_"), 1..5;
	subtest 'method => coderef' => sub {
		my $src = new_ok('Ryu::Source');
		my @expected = @objects;
		my @seen;
		$src->filter(
			id => sub {
				is($_, (shift @expected)->id, 'have expected ID value ' . $_);
				$_ % 2
			}
		)->each(sub { push @seen, $_ });
		$src->emit(@expected)->finish;
		cmp_deeply(\@seen, [
			map methods(id => $_), 1, 3, 5
		], 'saw expected values after method filtering') or note explain \@seen;
		done_testing;
	};
	subtest 'method => regex' => sub {
		my $src = new_ok('Ryu::Source');
		my @expected = @objects;
		my @seen;
		$src->filter(
			id => qr/[23]/
		)->each(sub { push @seen, $_ });
		$src->emit(@expected)->finish;
		cmp_deeply(\@seen, [
			map methods(id => $_), 2, 3
		], 'saw expected values after filtering methods on regex') or note explain \@seen;
		done_testing;
	};
	subtest 'method => string' => sub {
		my $src = new_ok('Ryu::Source');
		my @expected = @objects;
		my @seen;
		$src->filter(
			name => 'thing 4'
		)->each(sub { push @seen, $_ });
		$src->emit(@expected)->finish;
		cmp_deeply(\@seen, [
			map methods(id => $_), 4
		], 'saw expected values after filtering methods on string eq') or note explain \@seen;
		done_testing;
	};
	done_testing;
};

subtest 'filter hashrefs with methods' => sub {
	my @objects = map +{ id => $_, name => "thing $_" }, 1..5;
	subtest 'key => coderef' => sub {
		my $src = new_ok('Ryu::Source');
		my @expected = @objects;
		my @seen;
		$src->filter(
			id => sub {
				is($_, (shift @expected)->{id}, 'have expected ID value ' . $_);
				$_ % 2
			}
		)->each(sub { push @seen, $_ });
		$src->emit(@expected)->finish;
		cmp_deeply(\@seen, [
			map +{ id => $_, name => ignore() }, 1, 3, 5
		], 'saw expected values after key filtering') or note explain \@seen;
		done_testing;
	};
	subtest 'method => regex' => sub {
		my $src = new_ok('Ryu::Source');
		my @expected = @objects;
		my @seen;
		$src->filter(
			id => qr/[23]/
		)->each(sub { push @seen, $_ });
		$src->emit(@expected)->finish;
		cmp_deeply(\@seen, [
			map +{ id => $_, name => ignore() }, 2, 3
		], 'saw expected values after filtering items on regex') or note explain \@seen;
		done_testing;
	};
	subtest 'method => string' => sub {
		my $src = new_ok('Ryu::Source');
		my @expected = @objects;
		my @seen;
		$src->filter(
			name => 'thing 4'
		)->each(sub { push @seen, $_ });
		$src->emit(@expected)->finish;
		cmp_deeply(\@seen, [
			map +{ id => $_, name => ignore() }, 4
		], 'saw expected values after filtering items on string eq') or note explain \@seen;
		done_testing;
	};
	done_testing;
};

subtest 'filter cleanup' => sub {
	{
		my $src = Ryu::Source->new;
		$src->filter(my $code = sub {
			my $copy = $src; 1
		});
		is_refcount($code, 2, 'have our ref and internal for filter callback');
		$src->emit('test')->finish;
		is_oneref($code, 'now only have our ref');
		is(exception {
			dispose($code);
		}, undef, 'and can dispose without error');
	}
	{
		my $src = Ryu::Source->new;
		my $filtered = $src->filter(
			name => qr/test/
		);
		is_refcount($filtered, 3, 'has internal copies of chained source on ->completed and for ->{on_item}');
		$src->emit({ name => 'test' })->finish;
		ok($src->completed->is_ready, 'source is marked as ready');
		ok($src->completed->is_ready, 'and so is filtered source');
		is_oneref($filtered, 'now only have our ref');
		is(exception {
			dispose($filtered);
		}, undef, 'can dispose filtered source without error');
		is(exception {
			dispose($src);
		}, undef, 'and our original source too');
	}
	done_testing;
};

done_testing;

