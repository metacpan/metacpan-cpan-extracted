use strict;
use Benchmark qw{:all};

#my @arr = map { [map { rand(100) } (1 .. 23)] } (1 .. 23);
#my @arr = map { [map { rand(100) } (1 .. 347)] } (1 .. 23);
my @arr = map { [map { rand(100) } (1 .. 1009)] } (1 .. 23);

sub subtract(@) {
  my %set;
	my $lhs = shift;
  undef @set{@$lhs} if @$lhs;
	do { delete @set{@$_} if @$_ } for @_;
  return keys %set;
}

my $id = sub { $_[0] };

my $counter = 0;
sub get_next(){ $arr[ $counter++ % @arr ] }
sub get_rand(){ $arr[ int(@arr * rand) ] }

############################################

sub intersection_counter {
	my $size = @_;
	my %hash;
	do { ++$hash{$_} for @$_ } for (@_);
	return grep { $hash{$_} == $size } keys %hash;
}

sub intersection_delete(@) {
	my $first = shift;

	do { return unless @$_ } for @_;

	my (%set, %other_set);

	undef @set{@$first};

	for (@_) {
		undef @other_set{@$_};
		delete @set{grep { ! exists $other_set{$_} } keys %set};
		#return unless keys %set;
		%other_set = ();
	}

	return keys %set;
}

sub intersection_delete_fn(&@) {
	my $func = shift;
	my $first = shift;

	do { return unless @$_ } for @_;

	my (%set, %other_set);

	@set{ map { $func->($_) } @$first } = @$first;

	for (@_) {
		undef @other_set{map { $func->($_) } @$_};
		delete @set{grep { ! exists $other_set{$_} } keys %set};
		#return unless keys %set;
		%other_set = ();
	}

	return values %set;
}

sub intersection_grep {
	my %set;
	undef @set{@{$_[0]}};
	return grep { exists $set{$_} } @{$_[1]};
}

sub intersection_grep_defined_fn(&@) {
	my $func = shift;
	my $lhs = shift;

	return unless $lhs && @$lhs;

	my @int;
	my %set;
	@set{ map { $func->($_) } @$lhs } = @$lhs;

	for (@_) {
		@int = grep { defined } @set{ map { $func->($_) } @$_ };
		return unless @int;
		undef %set;
		@set{ map { $func->($_) } @int } = @int;
	}
	return keys %set;
}

sub intersection_grep_exists_fn(&@) {
	my $func = shift;
	my $lhs = shift;

	return unless $lhs && @$lhs;

	my @int;
	my %set;
	@set{ map { $func->($_) } @$lhs } = @$lhs;

	for (@_) {
		@int = grep { exists $set{$func->($_)} } @$_;
		return unless @int;
		undef %set;
		@set{ map { $func->($_) } @int } = @int;
	}
	return keys %set;
}

sub intersection_grep_exists_fn_2(&@) {
	my $func = shift;
	my $lhs = shift;

	return unless $lhs && @$lhs;

	my @int;
	my %set;
	@set{ map { $func->($_) } @$lhs } = @$lhs;

	for (@_) {
		@int = grep { exists $set{$func->($_)} } @$_;
		return unless @int;
		%set = ();
		@set{ map { $func->($_) } @int } = @int;
	}
	return keys %set;
}

sub intersection_grep_multi {
	my %set;
	undef @set{shift @_};
	for (@_) {
		my @int = grep { exists $set{$_} } @$_;
		return unless @int;
		undef %set;
		undef @set{@int};
	}
	return keys %set;
}

sub intersection_grep_multi_2 {
	my %set;
	undef @set{shift @_};
	for (@_) {
		my @int = grep { exists $set{$_} } @$_;
		return unless @int;
		%set = ();
		undef @set{@int};
	}
	return keys %set;
}

sub intersection_slice {
	my %set = map { ($_ => \$_) } @{$_[0]};
	return map { $$_ } grep { defined } @set{@{$_[1]}};
}

sub intersection_subtract {
	my @only_a = subtract(@_);
	return subtract($_[0], \@only_a);
}

sub intersection_subtract_multi {
	my $lhs = shift;
	do {
		my @lhs_only = subtract($lhs, $_);
		my @int = subtract($lhs, \@lhs_only);
		$lhs = \@int;
	} for (@_);
	return @$lhs;
}

cmpthese(10000, {
	intersection_counter  => sub { intersection_counter(get_next, get_rand) },
	intersection_delete   => sub { intersection_delete(get_next, get_rand) },
	intersection_grep     => sub { intersection_grep(get_next, get_rand) },
	intersection_slice    => sub { intersection_slice(get_next, get_rand) },
	intersection_subtract => sub { intersection_subtract(get_next, get_rand) },
});

cmpthese(10000, {
	intersection_counter        => sub { intersection_counter(get_next, get_rand, get_rand, get_rand, get_rand) },
	intersection_delete         => sub { intersection_delete(get_next, get_rand, get_rand, get_rand, get_rand) },
	intersection_grep_multi     => sub { intersection_grep_multi(get_next, get_rand, get_rand, get_rand, get_rand) },
	intersection_grep_multi_2   => sub { intersection_grep_multi_2(get_next, get_rand, get_rand, get_rand, get_rand) },
	intersection_subtract_multi => sub { intersection_subtract_multi(get_next, get_rand, get_rand, get_rand, get_rand) },
});


cmpthese(10000, {
	intersection_delete_fn        => sub { &intersection_delete_fn($id, get_next, get_rand, get_rand, get_rand, get_rand) },
	intersection_grep_defined_fn  => sub { &intersection_grep_defined_fn($id, get_next, get_rand, get_rand, get_rand, get_rand) },
	intersection_grep_exists_fn   => sub { &intersection_grep_exists_fn($id, get_next, get_rand, get_rand, get_rand, get_rand) },
	intersection_grep_exists_fn_2 => sub { &intersection_grep_exists_fn_2($id, get_next, get_rand, get_rand, get_rand, get_rand) },
});
