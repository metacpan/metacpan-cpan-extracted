#!perl

use strict;
use warnings;

use Test::More 0.96;
use Test::Exception;


use Net::CIDR::Set;

throws_ok {
  Net::CIDR::Set->new( 'foo' );
} qr{Can't decode}, 'parse error on new';

my $set = Net::CIDR::Set->new;

throws_ok {
    $set->add( 'foo' )
} qr{Can't decode}, 'parse error on add';

lives_ok {
    $set->add( '10.0.0.0/8' )
} 'can still parse ipv4';

throws_ok {
    $set->add( '::' )
} qr{Can't decode}, 'ipv4 personality set';

$set = Net::CIDR::Set->new;

throws_ok {
    $set->add( 'foo' )
} qr{Can't decode}, 'parse error on add';

lives_ok {
    $set->add( '::' )
}  'can still parse ipv6';

done_testing;

# vim:ts=2:sw=2:et:ft=perl
