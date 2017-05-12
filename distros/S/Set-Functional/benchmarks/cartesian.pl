use strict;
use warnings;
use Benchmark qw{:all};

#is_deeply [order_cartesian cartesian get_test_sets], get_test_results, 'cartesian_loop_result_set_idx works';
sub order_cartesian(@) { sort { my $ret = 0; for (0 .. 4) { last if $ret = ($a->[$_] <=> $b->[$_]) }; return $ret } @_ }
sub get_test_sets() { return ([1 .. 5], [6,7], [8], [9 .. 12], [13 .. 15]) }
sub get_test_results() { return [
	[1,6,8, 9,13],
	[1,6,8, 9,14],
	[1,6,8, 9,15],
	[1,6,8,10,13],
	[1,6,8,10,14],
	[1,6,8,10,15],
	[1,6,8,11,13],
	[1,6,8,11,14],
	[1,6,8,11,15],
	[1,6,8,12,13],
	[1,6,8,12,14],
	[1,6,8,12,15],
	[1,7,8, 9,13],
	[1,7,8, 9,14],
	[1,7,8, 9,15],
	[1,7,8,10,13],
	[1,7,8,10,14],
	[1,7,8,10,15],
	[1,7,8,11,13],
	[1,7,8,11,14],
	[1,7,8,11,15],
	[1,7,8,12,13],
	[1,7,8,12,14],
	[1,7,8,12,15],
	[2,6,8, 9,13],
	[2,6,8, 9,14],
	[2,6,8, 9,15],
	[2,6,8,10,13],
	[2,6,8,10,14],
	[2,6,8,10,15],
	[2,6,8,11,13],
	[2,6,8,11,14],
	[2,6,8,11,15],
	[2,6,8,12,13],
	[2,6,8,12,14],
	[2,6,8,12,15],
	[2,7,8, 9,13],
	[2,7,8, 9,14],
	[2,7,8, 9,15],
	[2,7,8,10,13],
	[2,7,8,10,14],
	[2,7,8,10,15],
	[2,7,8,11,13],
	[2,7,8,11,14],
	[2,7,8,11,15],
	[2,7,8,12,13],
	[2,7,8,12,14],
	[2,7,8,12,15],
	[3,6,8, 9,13],
	[3,6,8, 9,14],
	[3,6,8, 9,15],
	[3,6,8,10,13],
	[3,6,8,10,14],
	[3,6,8,10,15],
	[3,6,8,11,13],
	[3,6,8,11,14],
	[3,6,8,11,15],
	[3,6,8,12,13],
	[3,6,8,12,14],
	[3,6,8,12,15],
	[3,7,8, 9,13],
	[3,7,8, 9,14],
	[3,7,8, 9,15],
	[3,7,8,10,13],
	[3,7,8,10,14],
	[3,7,8,10,15],
	[3,7,8,11,13],
	[3,7,8,11,14],
	[3,7,8,11,15],
	[3,7,8,12,13],
	[3,7,8,12,14],
	[3,7,8,12,15],
	[4,6,8, 9,13],
	[4,6,8, 9,14],
	[4,6,8, 9,15],
	[4,6,8,10,13],
	[4,6,8,10,14],
	[4,6,8,10,15],
	[4,6,8,11,13],
	[4,6,8,11,14],
	[4,6,8,11,15],
	[4,6,8,12,13],
	[4,6,8,12,14],
	[4,6,8,12,15],
	[4,7,8, 9,13],
	[4,7,8, 9,14],
	[4,7,8, 9,15],
	[4,7,8,10,13],
	[4,7,8,10,14],
	[4,7,8,10,15],
	[4,7,8,11,13],
	[4,7,8,11,14],
	[4,7,8,11,15],
	[4,7,8,12,13],
	[4,7,8,12,14],
	[4,7,8,12,15],
	[5,6,8, 9,13],
	[5,6,8, 9,14],
	[5,6,8, 9,15],
	[5,6,8,10,13],
	[5,6,8,10,14],
	[5,6,8,10,15],
	[5,6,8,11,13],
	[5,6,8,11,14],
	[5,6,8,11,15],
	[5,6,8,12,13],
	[5,6,8,12,14],
	[5,6,8,12,15],
	[5,7,8, 9,13],
	[5,7,8, 9,14],
	[5,7,8, 9,15],
	[5,7,8,10,13],
	[5,7,8,10,14],
	[5,7,8,10,15],
	[5,7,8,11,13],
	[5,7,8,11,14],
	[5,7,8,11,15],
	[5,7,8,12,13],
	[5,7,8,12,14],
	[5,7,8,12,15],
] }

#my @arr = map { [map { rand(100) } (1 .. 11)] } (1 .. 11);
my @arr = map { [map { rand(100) } (1 .. 23)] } (1 .. 23);
#my @arr = map { [map { rand(100) } (1 .. 347)] } (1 .. 23);
#my @arr = map { [map { rand(100) } (1 .. 1009)] } (1 .. 23);

my $id = sub { $_[0] };

my $counter = 0;
sub get_next{ $arr[ $counter++ % @arr ] }
sub get_rand{ $arr[ int(@arr * rand) ] }

sub cartesian_loop_sets_cycles_els_reps(@) {
	return unless @_;
	my $cycles = 1;
	my $repetitions = 1;
	$repetitions *= @$_ || return for @_;
	my @results;
	$#results = $repetitions - 1;

	my $cycle;
	my $idx;
	my $repetition;

	for my $current (@_) {
		$repetitions /= @$current;
		for ($cycle=0; $cycle < $cycles; ++$cycle) {
			for ($idx=0; $idx < @$current; ++$idx) {
				for ($repetition=0; $repetition < $repetitions; ++$repetition) {
					push @{$results[ $cycle * @$current * $repetitions + $idx * $repetitions + $repetition ]}, $current->[$idx];
				}
			}
		}
		$cycles *= @$current;
	}

	return @results;
}

sub cartesian_loop_sets_result_set_idx(@) {
	return unless @_;
	my $repetitions = 1;
	$repetitions *= @$_ || return for @_;
	my @results;
	$#results = $repetitions - 1;

	for my $set (@_) {
		$repetitions /= @$set;
		push @{$results[$_]}, $set->[int($_/$repetitions) % @$set] for (0 .. $#results);
	}

	return @results;
}

sub cartesian_loop_result_set_idx(@) {
	return unless @_;
	my $repetitions = 1;
	$repetitions *= @$_ || return for @_;
	my @results;
	$#results = $repetitions - 1;

	for my $idx (0 .. $#results) {
		$repetitions = @results;
		$results[$idx] = [map { $_->[int($idx/($repetitions /= @$_)) % @$_] } @_];
	}

	return @results;
}

sub cartesian_loop_result_set_idx_cache_all(@) {
	return unless @_;
	my $repetitions = 1;
	$repetitions *= @$_ || return for @_;
	my @results;
	$#results = $repetitions - 1;

	my @set_sizes = map { scalar @$_ } @_;
	my @set_repetitions = map { $repetitions /= $_ } @set_sizes;

	for my $idx (0 .. $#results) {
		$results[$idx] = [map { $_[$_][ int($idx/$set_repetitions[$_]) % $set_sizes[$_] ] } 0 .. $#_];
	}

	return @results;
}

sub cartesian_loop_result_set_idx_cache_reps(@) {
	return unless @_;
	my $repetitions = 1;
	$repetitions *= @$_ || return for @_;
	my @results;
	$#results = $repetitions - 1;

	my @set_repetitions = map { $repetitions /= @$_ } @_;

	for my $idx (0 .. $#results) {
		$results[$idx] = [map { $_[$_][ int($idx/$set_repetitions[$_]) % @{$_[$_]} ] } 0 .. $#_];
	}

	return @results;
}

cmpthese(100, {
	cartesian_loop_result_set_idx            => sub { cartesian_loop_result_set_idx(get_next, get_rand, get_rand, get_rand, get_rand)},
	cartesian_loop_result_set_idx_cache_all  => sub { cartesian_loop_result_set_idx_cache_all(get_next, get_rand, get_rand, get_rand, get_rand)},
	cartesian_loop_result_set_idx_cache_reps => sub { cartesian_loop_result_set_idx_cache_reps(get_next, get_rand, get_rand, get_rand, get_rand)},
	cartesian_loop_sets_cycles_els_reps      => sub { cartesian_loop_sets_cycles_els_reps(get_next, get_rand, get_rand, get_rand, get_rand)},
	cartesian_loop_sets_result_set_idx       => sub { cartesian_loop_sets_result_set_idx(get_next, get_rand, get_rand, get_rand, get_rand)},
});
