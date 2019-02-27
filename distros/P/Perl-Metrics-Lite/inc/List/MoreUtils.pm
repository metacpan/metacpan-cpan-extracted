#line 1
package List::MoreUtils;

use 5.008_001;
use strict;
use warnings;

my $have_xs;
our $VERSION = '0.428';

BEGIN
{
    unless (defined($have_xs))
    {
        eval { require List::MoreUtils::XS; } unless $ENV{LIST_MOREUTILS_PP};
        die $@ if $@ && defined $ENV{LIST_MOREUTILS_PP} && $ENV{LIST_MOREUTILS_PP} == 0;
        $have_xs = 0+defined( $INC{'List/MoreUtils/XS.pm'});
    }

    use List::MoreUtils::PP qw();
}

use Exporter::Tiny qw();

my @junctions = qw(any all none notall);
my @v0_22     = qw(
  true false
  firstidx lastidx
  insert_after insert_after_string
  apply indexes
  after after_incl before before_incl
  firstval lastval
  each_array each_arrayref
  pairwise natatime
  mesh uniq
  minmax part
  _XScompiled
);
my @v0_24  = qw(bsearch);
my @v0_33  = qw(sort_by nsort_by);
my @v0_400 = qw(one any_u all_u none_u notall_u one_u
  firstres onlyidx onlyval onlyres lastres
  singleton bsearchidx
);
my @v0_420 = qw(arrayify duplicates minmaxstr samples zip6 reduce_0 reduce_1 reduce_u
  listcmp frequency occurrences mode
  binsert bremove equal_range lower_bound upper_bound qsort);

my @all_functions = (@junctions, @v0_22, @v0_24, @v0_33, @v0_400, @v0_420);

no strict "refs";
if ($have_xs)
{
    my $x;
    for (@all_functions)
    {
        List::MoreUtils->can($_) or *$_ = $x if ($x = List::MoreUtils::XS->can($_));
    }
}
List::MoreUtils->can($_) or *$_ = List::MoreUtils::PP->can($_) for (@all_functions);
use strict;

my %alias_list = (
    v0_22 => {
        first_index => "firstidx",
        last_index  => "lastidx",
        first_value => "firstval",
        last_value  => "lastval",
        zip         => "mesh",
    },
    v0_33 => {
        distinct => "uniq",
    },
    v0_400 => {
        first_result  => "firstres",
        only_index    => "onlyidx",
        only_value    => "onlyval",
        only_result   => "onlyres",
        last_result   => "lastres",
        bsearch_index => "bsearchidx",
    },
    v0_420 => {
	bsearch_insert => "binsert",
	bsearch_remove => "bremove",
	zip_unflatten  => "zip6",
    },
);

our @ISA         = qw(Exporter::Tiny);
our @EXPORT_OK   = (@all_functions, map { keys %$_ } values %alias_list);
our %EXPORT_TAGS = (
    all         => \@EXPORT_OK,
    'like_0.22' => [
        any_u    => {-as => 'any'},
        all_u    => {-as => 'all'},
        none_u   => {-as => 'none'},
        notall_u => {-as => 'notall'},
        @v0_22,
        keys %{$alias_list{v0_22}},
    ],
    'like_0.24' => [
        any_u    => {-as => 'any'},
        all_u    => {-as => 'all'},
        notall_u => {-as => 'notall'},
        'none',
        @v0_22,
        @v0_24,
        keys %{$alias_list{v0_22}},
    ],
    'like_0.33' => [
        @junctions,
        @v0_22,
        # v0_24 functions were omitted
        @v0_33,
        keys %{$alias_list{v0_22}},
        keys %{$alias_list{v0_33}},
    ],
);

for my $set (values %alias_list)
{
    for my $alias (keys %$set)
    {
        no strict qw(refs);
        *$alias = __PACKAGE__->can($set->{$alias});
    }
}

#line 1241

1;
