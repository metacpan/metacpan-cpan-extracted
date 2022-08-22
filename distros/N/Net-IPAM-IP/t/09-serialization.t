#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN {
  eval "use JSON";
  plan skip_all => "JSON required for testing JSON serialization"
    if $@;

  use_ok('Net::IPAM::IP') || print "Bail out!\n";
}

can_ok( 'Net::IPAM::IP', 'TO_JSON' );

my $items = [
  { ip => '0.0.0.0',         expect => '"0.0.0.0"',         test => 'IPv4 TO_JSON' },
  { ip => '::',              expect => '"::"',              test => 'IPv6 TO_JSON' },
  { ip => '10.0.0.1',        expect => '"10.0.0.1"',        test => 'IPv4 TO_JSON' },
  { ip => '::ffff:10.0.0.1', expect => '"::ffff:10.0.0.1"', test => 'IPv4mappedv6 TO_JSON' },
  { ip => '2001::1',         expect => '"2001::1"',         test => 'IPv6 TO_JSON' },
];

foreach my $item (@$items) {
  my $ip = Net::IPAM::IP->new( $item->{ip} );
  is( JSON->new->convert_blessed->encode($ip), $item->{expect}, $item->{test} );
}

done_testing();

