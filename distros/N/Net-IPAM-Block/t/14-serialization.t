#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN {
  eval "use JSON";
  plan skip_all => "JSON required for testing JSON serialization"
    if $@;

  use_ok('Net::IPAM::Block') || print "Bail out!\n";
}

can_ok( 'Net::IPAM::Block', 'TO_JSON' );

my $items = [
  { b => '10.0.0.17',               expect => '"10.0.0.17/32"',            test => 'IPv4 addr' },
  { b => '10.0.0.17-10.13.2.3',     expect => '"10.0.0.17-10.13.2.3"',     test => 'IPv4 range' },
  { b => '::',                      expect => '"::/128"',                  test => 'IPv6 addr' },
  { b => '2001:db8::-2001:db8::fe', expect => '"2001:db8::-2001:db8::fe"', test => 'IPv6 range' },
];

foreach my $item (@$items) {
  my $block = Net::IPAM::Block->new( $item->{b} );
  is( JSON->new->convert_blessed->encode($block), $item->{expect}, $item->{test} );
}

done_testing();
