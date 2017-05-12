use strict;
use Benchmark qw{:all};

#my @arr = map { [map { rand(100) } (1 .. 23)] } (1 .. 23);
#my @arr = map { [map { rand(100) } (1 .. 347)] } (1 .. 23);
my @arr = map { [map { rand(100) } (1 .. 1009)] } (1 .. 23);

my $id = sub { $_[0] };

my $counter = 0;
sub get_next(){ $arr[ $counter++ % @arr ] }
sub get_rand(){ $arr[ int(@arr * rand) ] }

sub symmetric_difference_by_assign(@) {
	my $match;
	my %element_to_count;

	do { ++$element_to_count{$_} for @$_ } for @_;

	return map {
		grep {
			$match = $element_to_count{$_} % 2;
			$element_to_count{$_} = 0;
			$match
		} @$_
	} @_;
}

sub symmetric_difference_by_assign_fn(&@) {
	my $func = shift;

	my $element;
	my $match;
	my %element_to_count;

	do { ++$element_to_count{$func->($_)} for @$_ } for @_;

	return map {
		grep {
			$element = $func->($_);
			$match = $element_to_count{$element} % 2;
			$element_to_count{$element} = 0;
			$match
		} @$_
	} @_;
}

sub symmetric_difference_by_count(@) {
	my $count;
	my %element_to_count;

	do { ++$element_to_count{$_} for @$_ } for @_;

	return grep { $element_to_count{$_} % 2 } keys %element_to_count;
}

sub symmetric_difference_by_delete(@) {
	my $count;
	my %element_to_count;

	do { ++$element_to_count{$_} for @$_ } for @_;

	return map { grep { $count = delete $element_to_count{$_}; defined($count) && $count % 2 } @$_ } @_;
}

sub symmetric_difference_by_delete_fn(&@) {
	my $func = shift;

	my $count;
	my %element_to_count;

	do { ++$element_to_count{$func->($_)} for @$_ } for @_;

	return map { grep { $count = delete $element_to_count{$func->($_)}; defined($count) && $count % 2 } @$_ } @_;
}

sub symmetric_difference_by_exists(@) {
	my %element_to_count;

	do { ++$element_to_count{$_} for @$_ } for @_;

	return map { grep { exists $element_to_count{$_} && delete($element_to_count{$_}) % 2 } @$_ } @_;
}

sub symmetric_difference_by_exists_fn(&@) {
	my $func = shift;

	my $key;
	my %element_to_count;

	do { ++$element_to_count{$func->($_)} for @$_ } for @_;

	return map { grep { $key = $func->($_); exists $element_to_count{$key} && delete($element_to_count{$key}) % 2 } @$_ } @_;
}

sub symmetric_difference_by_push_fn(&@){
	my $func = shift;

	my %key_to_elements;

	do { push @{$key_to_elements{$func->($_)}}, $_ for @$_ } for @_;

	return map { $_->[0] } grep { @$_ % 2 } values %key_to_elements;
}


cmpthese(10000, {
	symmetric_difference_by_assign => sub { symmetric_difference_by_assign(get_next, get_rand, get_rand, get_rand, get_rand) },
	symmetric_difference_by_count  => sub { symmetric_difference_by_count(get_next, get_rand, get_rand, get_rand, get_rand) },
	symmetric_difference_by_delete => sub { symmetric_difference_by_delete(get_next, get_rand, get_rand, get_rand, get_rand) },
	symmetric_difference_by_exists => sub { symmetric_difference_by_exists(get_next, get_rand, get_rand, get_rand, get_rand) },
});

cmpthese(10000, {
	symmetric_difference_by_assign_fn => sub { &symmetric_difference_by_assign_fn($id, get_next, get_rand, get_rand, get_rand, get_rand) },
	symmetric_difference_by_delete_fn => sub { &symmetric_difference_by_delete_fn($id, get_next, get_rand, get_rand, get_rand, get_rand) },
	symmetric_difference_by_exists_fn => sub { &symmetric_difference_by_exists_fn($id, get_next, get_rand, get_rand, get_rand, get_rand) },
	symmetric_difference_by_push_fn   => sub { &symmetric_difference_by_push_fn($id, get_next, get_rand, get_rand, get_rand, get_rand) },
});
