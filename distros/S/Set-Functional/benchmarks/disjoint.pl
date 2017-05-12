use strict;
use Benchmark qw{:all};

#my @arr = map { [map { rand(100) } (1 .. 23)] } (1 .. 23);
#my @arr = map { [map { rand(100) } (1 .. 347)] } (1 .. 23);
my @arr = map { [map { rand(100) } (1 .. 1009)] } (1 .. 23);

my $id = sub { $_[0] };

my $counter = 0;
sub get_next{ $arr[ $counter++ % @arr ] }
sub get_rand{ $arr[ int(@arr * rand) ] }

cmpthese(10000, {
	'counter' => sub {
		my @arr = (get_next(), get_rand());

		my %set;
		do { ++$set{$_} for @$_ } for @arr;
		return map { [grep { $set{$_} == 1 } @$_] } @arr;
	},
	'undef' => sub {
		my $index = 0;
	  my @results = ([]) x 2;
		my %set;

		for (get_next(), get_rand()) {
			$set{$_} = exists $set{$_} ? undef : $index for @$_;
			++$index;
		}

		while (my ($key, $index) = each %set) {
			next unless defined $index;
			push @{$results[$index]}, $key;
		}

		return @results;
	},
});

cmpthese(10000, {
	'counter_m' => sub {
		my @arr = (get_next(), get_rand(), get_rand(), get_rand(), get_rand());

		my %set;
		do { ++$set{$_} for @$_ } for @arr;
		return map { [grep { $set{$_} == 1 } @$_] } @arr;
	},
	'undef_m' => sub {
		my $index = 0;
	  my @results = ([]) x 5;
		my %set;

		for (get_next(), get_rand(), get_rand(), get_rand(), get_rand()) {
			$set{$_} = exists $set{$_} ? undef : $index for @$_;
			++$index;
		}

		while (my ($key, $index) = each %set) {
			next unless defined $index;
			push @{$results[$index]}, $key;
		}

		return @results;
	},
});

#cmpthese(10000, {
#
#	'exists_fn' => sub {
#		my $lhs = get_next();
#
#		my %set;
#		@set{ map { $id->($_) } @$lhs } = @$lhs;
#
#		for (get_rand(), get_rand(), get_rand(), get_rand()) {
#			my @int = grep { exists $set{$id->($_)} } @$_;
#			return unless @int;
#			undef %set;
#			@set{ map { $id->($_) } @int } = @int;
#		}
#		return keys %set;
#	},
#
#	'slice_defined_fn' => sub {
#		my $lhs = get_next();
#
#		my %set;
#		@set{ map { $id->($_) } @$lhs } = @$lhs;
#
#		for (get_rand(), get_rand(), get_rand(), get_rand()) {
#			my @int = grep { defined } @set{ map { $id->($_) } @$_ };
#			return unless @int;
#			undef %set;
#			@set{ map { $id->($_) } @int } = @int;
#		}
#		return keys %set;
#	},
#
#});
