#!/usr/local/bin/perl

use Test;

BEGIN { plan tests => 14 }

unshift @INC, '.';

my $myMAC48;

# There are no reasons any of these tests should ever fail.
# Unless the current release is broken regex engine.
# we will see... ... ... :)

##  Test 1 -=- Can we load the Parse::Extract::Net::MAC48 library?
eval { require Parse::Extract::Net::MAC48; return 1; };
ok($@, '');
croak() if $@;



##  Test 2 -=- Can we instantiate a MAC48 ?
$myMAC48 = new Parse::Extract::Net::MAC48();
ok( $myMAC48->isa('Parse::Extract::Net::MAC48') );



##  Test 3 -=- Can we parse Traditional?
eval{
  my @result = $myMAC48->extract( 'FE:ED:D0:0D:CA:FE' );
  return ( defined $result[0] && $result[0] eq 'FE:ED:D0:0D:CA:FE' ) ? 1 : 0;
};
ok($@, '');



##  Test 4 -=- Can we parse Dashed?
eval{
  my @result = $myMAC48->extract( 'FE-ED-D0-0D-CA-FE' );
  return( defined $result[0] && $result[0] eq 'FE-ED-D0-0D-CA-FE' ) ? 1 : 0;
};
ok($@, '');



##  Test 5 -=- Can we parse with dashed internal seperator?
eval{
  my @result = $myMAC48->extract( '127.0.0.1:FE-ED-D0-0D-CA-FE:cmorris@cs.odu.edu' );
  return( defined $result[0] && $result[0] eq 'FE-ED-D0-0D-CA-FE' ) ? 1 : 0;
};
ok($@, '');



##  Test 6 -=- Can we parse Cisco?
eval{
  my @result = $myMAC48->extract( 'FEED.D00D.CAFE' );
  return( defined $result[0] && $result[0] eq 'FEED.D00D.CAFE' ) ? 1 : 0;
};
ok($@, '');



##  Test 7 -=- Can we parse Cisco internal seperator?
eval{
  my @result = $myMAC48->extract( '127.0.0.1:FEED.D00D.CAFE:cmorris@cs.odu.edu' );
  return( defined $result[0] && $result[0] eq 'FEED.D00D.CAFE' ) ? 1 : 0;
};
ok($@, '');



## Test 8 -=- Can we parse Multiple?
eval{
  my @result = $myMAC48->extract( 'Hello my MAC address is FE:ED:D0:0D:CA:FE and everyones is FF:FF:FF:FF:FF:FF.' );
  return( defined $result[0] && $result[0] eq 'FE:ED:D0:0D:CA:FE' && $result[1] eq 'FF:FF:FF:FF:FF:FF') ? 1 : 0;
};
ok($@, '');



## Test 9 -=- Can we parse all types in one line?
eval{
  my @result = $myMAC48->extract( '0000.0000.0000 11-11-11-11-11-11 22:22:22:22:22:22 3333.3333.3333' );
  return( defined $result[0] && $result[0] eq '0000.0000.0000' && $result[1] eq '11-11-11-11-11-11' &&
          $result[2] eq '22:22:22:22:22:22' && $result[3] eq '3333.3333.3333') ? 1 : 0; 
};
ok($@, '');



##  Test 10 -=- FAIL: Too long?
eval{
  my @result = $myMAC48->extract( 'FE:ED:D0:0D:CA:FE:CA:FE' );
  return( defined $result[0] ) ? 1 : 0;
};
ok($@, '');



##  Test 11 -=- FAIL: Too short?
eval{
  my @result = $myMAC48->extract( 'FE:ED:D0:0D' );
  return( defined $result[0] ) ? 1 : 0;
};
ok($@, '');



##  Test 12 -=- FAIL: Inconsistant seperator?
eval{
  my @result = $myMAC48->extract( 'FE:ED:D0-0D:CA:FE' );
  return( defined $result[0] ) ? 1 : 0;
};
ok($@, '');



##  Test 13 -=- FAIL: Too long (cisco)?
eval{
  my @result = $myMAC48->extract( '0000.1111.2222.3333' );
  return( defined $result[0] ) ? 1 : 0;
};
ok($@, '');



##  Test 14 -=- FAIL: Invalid character?
eval{
  my @result = $myMAC48->extract( 'FE:ED:ZZ:ZZ:CA:FE' );
  return( defined $result[0] ) ? 1 : 0;
};
ok($@, '');
