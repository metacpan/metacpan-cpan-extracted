#!perl
use strict;
use warnings;

use Test::More 'no_plan';
use Pod::Elemental::Document;

use Test::Differences;

my $pod_string = do {
  local $/;
  open my $fh, '<', 't/eg/from-lol.pod' or die "can't read test data: $!";
  <$fh>;
};

my $flat_lol = [
  [ '=head1' => "This is a head." ],
  [ '=head2' => "This is a subhead." ],
  [ (undef)  => "Ordinary 1"  ],
  [ (undef)  => "Ordinary 2"  ],
  [ '=begin' => ':pod_region' ],
    [ (undef)  => "Ordinary 3"  ],
    [ (undef)  => "Ordinary 4"  ],
    [ '=head1' => 'This is a head.' ],
    [ '=begin'  => 'nonpod_region' ],
      [ (undef)  => "Data 1"  ],
      [ (undef)  => "Data 2"  ],
      [ (undef)  => "Data 3"  ],
    [ '=end'    => 'nonpod_region' ],
  [ '=end'    => ':pod_region'   ],
  [ '=begin' => ':empty' ],
  [ '=end'   => ':empty' ],
];

{
  my $document = Pod::Elemental::Document->new_from_lol($flat_lol);
  isa_ok($document, 'Pod::Elemental::Document');
  is(
    $document->as_pod_string,
    $pod_string,
    "from_lol stringifies to what we want",
  );
}

# my $nested_lol = [
#   [ '=head1' => "This is a head."    ],
#   [ '=head2' => "This is a subhead." ],
#   [ (undef)  => "Ordinary 1" ],
#   [ (undef)  => "Ordinary 2" ],
#   [ ':pod_region' => [
#     [ (undef)  => "Ordinary 3" ],
#     [ (undef)  => "Ordinary 4" ],
#     [ '=head1' => 'This is a head.' ],
#     [ nonpod_region => [
#       [ (undef)  => "Data 1" ],
#       [ (undef)  => "Data 2" ],
#       [ (undef)  => "Data 3" ],
#     ] ],
#   ] ],
# ];
# 
# {
#   my $document = Pod::Elemental::Document->new_from_lol($nested_lol);
#   isa_ok($document, 'Pod::Elemental::Document');
#   eq_or_diff(
#     $document->as_pod_string,
#     $pod_string,
#     "from_lol stringifies to what we want",
#   );
# }

