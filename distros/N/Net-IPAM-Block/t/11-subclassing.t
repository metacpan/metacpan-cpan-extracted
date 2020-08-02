#!perl -T

use 5.10.0;
use strict;
use warnings;
use Test::More;

my $base  = 'Net::IPAM::Block';
my $class = 'My::Block';
@My::Block::ISA = ($base);

use_ok($base);
can_ok( $class, 'new' );

my $b = '2001:db8:dead:beef::/64';

my $object = $class->new($b);
isa_ok( $object, $class );

ok( $object eq $b, 'stringification' );

my @splits;
ok( @splits = $object->cidrsplit, 'split CIDR' );

ok( $splits[0] eq '2001:db8:dead:beef::/65',      'stringification of first split obj' );
ok( $splits[1] eq '2001:db8:dead:beef:8000::/65', 'stringification of second split obj' );

isa_ok( $splits[0], $class );
isa_ok( $splits[1], $class );

my $r = '192.168.0.0-192.168.1.17';
$object = $class->new($r);
isa_ok( $object, $class );
my @cidrs = $object->to_cidrs;
ok( @cidrs == 3, "split block $r to 3 cidrs" );

isa_ok( $cidrs[0], $class );
isa_ok( $cidrs[1], $class );
isa_ok( $cidrs[2], $class );

done_testing();

