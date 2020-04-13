#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

my $base  = 'Net::IPAM::IP';
my $class = 'My::IP';
@My::IP::ISA = ( $base );

use_ok( $base );
can_ok( $class, 'new' );

my $ip = '1.2.3.4';

my $object = $class->new($ip);
isa_ok( $object, $class );
ok( $object eq $ip, 'stringification' );

my $clone;
ok( $clone = $object->new_from_bytes($object->bytes), 'clone IPv4');
ok( $clone eq $ip, 'stringification of cloned obj' );

my $incr = $clone->incr;
ok( $incr eq '1.2.3.5', 'incr of cloned obj' );

isa_ok( $incr, $class );

done_testing();

