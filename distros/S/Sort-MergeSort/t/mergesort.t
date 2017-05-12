#!/usr/bin/perl -Ilib -I../lib 

use strict;
use Sort::MergeSort;
use Sort::MergeSort::Iterator;
use Test::More qw(no_plan);

my $finished = 0;
END { ok $finished, "finished" }


my @data = (
	[ qw(100 110 120 130 140 150 160 200 280) ],
	[ qw(800 810 830 835                    ) ],
	[ qw(121 122 161 162 181 279 305 360 390) ],
	[ qw(811 834 836 837 838 840 920        ) ],
	[ qw(123 124 126 839 921 922 923 950    ) ],
	[ qw(423 424 426 939 971 972 973 990    ) ],
	[ qw(523 524 526 739 771 772 773 790    ) ],
	[ qw(323 324 326 339 471 472 473 490    ) ],
	[ qw(223 224 226 239 371 372 373 391    ) ],
	[ qw(723 724 726 759 761 762 763 780    ) ],
	[ qw(623 624 626 639 671 672 673 690    ) ],
	[ qw(919 924 926 943 991 992 993 994    ) ],
	[ qw(151 152 163 164 165 166 167 168	) ],
	[ qw(351 352 363 364 365 366 367 368	) ],
	[ qw(451 452 463 464 465 466 467 468	) ],
	[ qw(551 552 563 564 565 566 567 568	) ],
	[ qw(651 652 663 664 665 666 667 668	) ],
	[ qw(751 752 764 765 766 767 768	) ],
	[ qw(851 852 863 864 865 866 867 868	) ],
	[ qw(951 952 963 964 965 966 967 968	) ],
	[ qw(389 394 398			) ],
	[ qw(395 399				) ],
	[ qw(392 396				) ],
	[ qw(393 397				) ],
);



my $num = 1000;
my @d2;
sub make2
{
	my ($pos, @items) = @_;
	# diag "make2: $pos: @items";
	if ($pos == @items) {
		for my $i (@items) {
			$d2[$i] = [] unless $d2[$i];
			push(@{$d2[$i]}, $num++);
		}
	} else {
		my @base = splice(@items, 0, $pos);
		for my $i (@items) {
			make2($pos+1, @base, @items);
			push(@items, shift(@items));
		}
	}
}

make2(-1, qw(0 1 2 3 4 5));
#diag "num = $num";
#diag "d2[$_] = @{$d2[$_]}" for 0..$#d2;


my $num3 = 1000;
my @d3;
sub make3
{
	my $ary = shift;
	$d3[$_] = [] for 0..$ary;
	for my $a (0..$ary) {
		for my $b (0..$ary) {
			for my $c (0..$ary) {
				for my $d (0..$ary) {
					for my $e (0..$ary) {
						for my $i ($a, $b, $c, $d, $e) {
							push(@{$d3[$i]}, $num++);
						}
					}
				}
			}
		}
	};
}

make3(5);
#diag "num3 = $num";
#diag "d3[$_] = @{$d3[$_]}" for 0..$#d3;



check_sort(\@data, $_, "hand-made data") for qw(200 4 5 6 7);
check_sort(\@d2, 10, "D2");
check_sort(\@d3, 10, "D3");

sub check_sort
{
	my ($data, $max, $set_name) = @_;

	ok(1, "Running $set_name with MAX=$max");

	my @iter;
	my $count = 0;
	my $anum = 0;
	my %seen;
	for my $a (@$data) {
		$anum++;
		my @d = @$a;
		$count += @d;
		ok(is_sorted(@d), "sortcheck array $anum");
		for my $d (@d) {
			next unless $seen{$d}++;
			ok(0, "element $d repeats");
		}
		push(@iter, Sort::MergeSort::Iterator->new( sub { shift(@d) } ));
	}

	$Sort::MergeSort::max_array = $max;
	my $si = mergesort(sub { $_[0] <=> $_[1] }, @iter);

	my @sorted;
	while(my $num = $si->next()) {
		push(@sorted, $num);
	}

	is(scalar(@sorted), $count, "count of sorted items");
	ok(is_sorted(@sorted), "sorted items are sorted");

	for my $d (@sorted) {
		next if $seen{$d};
		ok(0, "sorted has an element not present in original: $d");
	}
}

$finished = 1;

sub is_sorted
{
	my $ok = 1;
	for my $i (1..$#_) {
		next if $_[$i] >= $_[$i-1];
		$ok = 0;
	}
	return $ok;
}

