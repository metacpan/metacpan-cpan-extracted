use strict;
use warnings;
use Test::More;
use Sub::Util 'subname';

{
  package Mojo::Collection::ForTesting;
  use Role::Tiny::With;
  sub new {
    my $class = shift;
    return bless [@_], ref $class || $class;
  }
  with 'Mojo::Collection::Role::UtilsBy';
}

my @methods = qw(all_max_by all_min_by bundle_by count_by extract_by
  extract_first_by max_by min_by nsort_by partition_by rev_nsort_by rev_sort_by
  sort_by uniq_by unzip_by weighted_shuffle_by zip_by);

foreach my $method (@methods) {
  ok defined(my $sub = Mojo::Collection::ForTesting->can($method)), "$method is defined";
  is subname($sub), "Mojo::Collection::Role::UtilsBy::$method", 'subname is correct';
}

done_testing;
