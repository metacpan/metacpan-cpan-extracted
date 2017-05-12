use strict;
use Benchmark qw{:all};

#my @arr = map { [map { rand(100) } (1 .. 23)] } (1 .. 23);
#my @arr = map { [map { rand(100) } (1 .. 347)] } (1 .. 23);
my @arr = map { [map { rand(100) } (1 .. 1009)] } (1 .. 23);

my $id = sub { $_[0] };

my $counter = 0;
sub get_next(){ $arr[ $counter++ % @arr ] }
sub get_rand(){ $arr[ int(@arr * rand) ] }

sub union_for(@) {
	my %set;
	do { undef @set{@$_} if @$_ } for @_;
	return keys %set;
}

sub union_map(@) {
	my %set;
	undef @set{map { @$_ } @_};
	return keys %set;
}

cmpthese(10000, {
	union_for => sub { union_for(get_next, get_rand, get_rand, get_rand, get_rand) },
	union_map => sub { union_map(get_next, get_rand, get_rand, get_rand, get_rand) },
});

