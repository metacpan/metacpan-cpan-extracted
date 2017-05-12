use strict;
use Benchmark qw{:all};
use Set::Functional qw{disjoint intersection};

#my @arr = map { [map { rand(100) } (1 .. 23)] } (1 .. 23);
#my @arr = map { [map { rand(100) } (1 .. 347)] } (1 .. 23);
my @arr = map { [map { rand(100) } (1 .. 1009)] } (1 .. 23);

my $id = sub { $_[0] };

my $counter = 0;
sub get_next{ $arr[ $counter++ % @arr ] }
sub get_rand{ $arr[ int(@arr * rand) ] }


sub is_equal_via_disjoint($$) {
	my ($left, $right) = &disjoint(@_);
	return ! (@$left || @$right);
}
sub is_equal_via_intersection($$) {
	my @set = &intersection(@_);
	return @set == @{$_[0]} && @set == @{$_[1]};
}

sub is_proper_superset_via_disjoint($$) {
	my ($left, $right) = &disjoint(@_);
	return @$left && ! @$right;
}
sub is_proper_superset_via_intersection($$) {
	my @set = &intersection(@_);
	return @set != @{$_[0]} && @set == @{$_[1]};
}

sub is_superset_via_disjoint($$) {
	my ($left, $right) = &disjoint(@_);
	return ! @$right;
}
sub is_superset_via_intersection($$) {
	my @set = &intersection(@_);
	return @set == @{$_[1]};
}

{
local $\ ="\n";
print 'yes eq:', is_equal_via_disjoint [], [];
print 'yes eq:', is_equal_via_disjoint [1,3], [1,3];
print 'no eq:', is_equal_via_disjoint [1,2], [3,4];

print 'yes eq:', is_equal_via_intersection [], [];
print 'yes eq:', is_equal_via_intersection [1,3], [1,3];
print 'no eq:', is_equal_via_intersection [1,2], [3,4];

print 'no eq:', is_proper_superset_via_disjoint [], [];
print 'yes eq:', is_proper_superset_via_disjoint [1,3], [1];
print 'no eq:', is_proper_superset_via_disjoint [1,2], [3,4];

print 'no eq:', is_proper_superset_via_intersection [], [];
print 'yes eq:', is_proper_superset_via_intersection [1,3], [1];
print 'no eq:', is_proper_superset_via_intersection [1,2], [3,4];

print 'yes eq:', is_superset_via_disjoint [], [];
print 'yes eq:', is_superset_via_disjoint [1,3], [1];
print 'no eq:', is_superset_via_disjoint [1,2], [3,4];

print 'yes eq:', is_superset_via_intersection [], [];
print 'yes eq:', is_superset_via_intersection [1,3], [1];
print 'no eq:', is_superset_via_intersection [1,2], [3,4];
}

cmpthese(1000, {
	'disjoint' => sub { is_superset_via_disjoint(get_rand(), get_rand()) },
	'intersect' => sub { is_superset_via_intersection(get_rand(), get_rand()) },
});

cmpthese(1000, {
	'disjoint' => sub { is_proper_superset_via_disjoint(get_rand(), get_rand()) },
	'intersect' => sub { is_proper_superset_via_intersection(get_rand(), get_rand()) },
});

cmpthese(1000, {
	'disjoint' => sub { is_equal_via_disjoint(get_rand(), get_rand()) },
	'intersect' => sub { is_equal_via_intersection(get_rand(), get_rand()) },
});
