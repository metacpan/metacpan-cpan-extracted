#!perl -w
use strict;
use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 1;
my %cover_opts =
  (
   coverage_class => 'Pod::Coverage::CountParents',
   also_private => [ qr/^ITEM_(ID|PAYLOAD|PRIORITY)$/ ],
  );
pod_coverage_ok( "POE::XS::Queue::Array", \%cover_opts);
