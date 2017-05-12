use strict;
use Benchmark qw{:all};

#my @arr = map { [map { rand(100) } (1 .. 23)] } (1 .. 23);
#my @arr = map { [map { rand(100) } (1 .. 347)] } (1 .. 23);
my @arr = map { [map { rand(100) } (1 .. 1009)] } (1 .. 23);

my $counter = 0;
sub get_next{ $arr[ $counter++ % @arr ] }
sub get_rand{ $arr[ int(@arr * rand) ] }

cmpthese(10000, {
	'delete'   => sub { my %set; undef @set{@{get_next()}}; delete @set{@{get_rand()}}; return keys %set },
	'delete_m' => sub { my %set; undef @set{@{get_next()}}; do { delete @set{@$_} } for (get_rand()); return keys %set },
	'grep'     => sub { my %set; undef @set{@{get_next()}}; return grep { ! exists $set{$_} } @{get_rand()} },
});


