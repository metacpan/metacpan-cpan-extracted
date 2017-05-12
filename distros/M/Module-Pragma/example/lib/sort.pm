package
	sort;

use strict;

our $VERSION = '3.00';

use Module::Pragma;
our @ISA = qw(Module::Pragma);


# The hints for pp_sort are now stored in $^H{sort}; older versions
# of perl used the global variable $sort::hints. -- rjh 2005-12-19

our $quicksort_bit   = 0x00000001;
our $mergesort_bit   = 0x00000002;
our $sort_bits       = 0x000000FF; # allow 256 different ones
our $stable_bit      = 0x00000100;

__PACKAGE__->register_tags(
	_quicksort => $quicksort_bit,
	_qsort     => $quicksort_bit,
	_mergesort => $mergesort_bit,
	stable     => $stable_bit,
);
__PACKAGE__->register_exclusive( qw(_quicksort _mergesort) );

sub import {
	my $class = shift;

	my @args = grep{ $_ ne 'defaults' } @_;

	$^H{sort} = 0 if @_ != @args;

	$class->SUPER::import(@args);
}

sub current() {
    my @sort;
    if (defined(sort::->enabled)) {
	push @sort, 'quicksort' if sort::->enabled('_quicksort');
	push @sort, 'mergesort' if sort::->enabled('_mergesort');
	push @sort, 'stable'    if sort::->enabled('stable');
    }
    push @sort, 'mergesort' unless @sort;
    return join(' ', @sort);
}

1;
