use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::InetRtr'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( inet_rtr descr alias local_as ifaddr interface peer mp_peer
    member_of remarks admin_c tech_c  notify mnt_by changed source );

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'inet_rtr'
$tested{'inet_rtr'}++;
is( $object->inet_rtr(), 'RTR.EXAMPLE.COM', 'inet_rtr properly parsed' );
$object->inet_rtr('RTR2.EXAMPLE.COM');
is( $object->inet_rtr(), 'RTR2.EXAMPLE.COM', 'inet_rtr properly set' );

# Test 'alias'
$tested{'alias'}++;
is_deeply( $object->alias(), ['EDGE01.EXAMPLE.COM'], 'alias properly parsed' );
$object->alias('EDGE02.EXAMPLE.COM');
is( $object->alias()->[1], 'EDGE02.EXAMPLE.COM', 'alias properly added' );

# Test 'descr'
$tested{'descr'}++;
is_deeply( $object->descr(), [ 'Edge router for UniverseNet', 'Paris - France' ], 'descr properly parsed' );
$object->descr('Added descr');
is( $object->descr()->[2], 'Added descr', 'descr properly added' );

# Test 'local_as'
$tested{'local_as'}++;
is( $object->local_as(), 'AS1', 'local_as properly parsed' );
$object->local_as('AS2');
is( $object->local_as(), 'AS2', 'local_as properly set' );

# Test 'ifaddr'
$tested{'ifaddr'}++;
is_deeply( $object->ifaddr(), ['147.45.0.17 masklen 32'], 'ifaddr properly parsed' );
$object->ifaddr('147.45.0.18 masklen 32');
is( $object->ifaddr()->[1], '147.45.0.18 masklen 32', 'ifaddr properly added' );

# Test 'interface'
$tested{'interface'}++;
is_deeply( $object->interface(), ['147.45.0.17 masklen 32'], 'interface properly parsed' );
$object->interface('147.45.0.18 masklen 32');
is( $object->interface()->[1], '147.45.0.18 masklen 32', 'interface properly added' );

# Test 'admin_c'
$tested{'admin_c'}++;
is_deeply( $object->admin_c(), ['FR123-AP'], 'admin_c properly parsed' );
$object->admin_c('FR456-AP');
is( $object->admin_c()->[1], 'FR456-AP', 'admin_c properly added' );

# Test 'tech_c'
$tested{'tech_c'}++;
is_deeply( $object->tech_c(), ['FR123-AP'], 'tech_c properly parsed' );
$object->tech_c('FR456-AP');
is( $object->tech_c()->[1], 'FR456-AP', 'tech_c properly added' );

# Test 'mnt_by'
$tested{'mnt_by'}++;
is_deeply( $object->mnt_by(), ['MAINT-EXAMPLENET-AP'], 'mnt_by properly parsed' );
$object->mnt_by('MAINT2-EXAMPLENET-AP');
is( $object->mnt_by()->[1], 'MAINT2-EXAMPLENET-AP', 'mnt_by properly added' );

# Test 'notify'
$tested{'notify'}++;
is_deeply( $object->notify(), ['watcher@example.com'], 'notify properly parsed' );
$object->notify('watcher2@example.com');
is( $object->notify()->[1], 'watcher2@example.com', 'notify properly added' );

# Test 'changed'
$tested{'changed'}++;
is_deeply( $object->changed(), ['abc@examplenet.com 20101231'], 'changed properly parsed' );
$object->changed('abc@examplenet.com 20111231');
is( $object->changed()->[1], 'abc@examplenet.com 20111231', 'changed properly added' );

# Test 'member_of'
$tested{'member_of'}++;
is_deeply( $object->member_of(), ['AS2'], 'member_of properly parsed' );
$object->member_of('AS3');
is( $object->member_of()->[1], 'AS3', 'member_of properly added' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), ['No remarks'], 'remarks properly parsed' );
$object->remarks('Added remarks');
is( $object->remarks()->[1], 'Added remarks', 'remarks properly added' );

# Test 'source'
$tested{'source'}++;
is( $object->source(), 'RIPE', 'source properly parsed' );
$object->source('APNIC');
is( $object->source(), 'APNIC', 'source properly set' );

# Test 'org'
$tested{'org'}++;

# TODO

# Test 'peer'
$tested{'peer'}++;

# TODO

# Test 'mp_peer'
$tested{'mp_peer'}++;

# TODO

# Common tests
do 't/common.pl';
ok( $tested{common_loaded}, "t/common.pl properly loaded" );
ok( !$@, "Can evaluate t/common.pl ($@)" );

__DATA__
inet-rtr:   RTR.EXAMPLE.COM
alias:      EDGE01.EXAMPLE.COM
descr:      Edge router for UniverseNet
descr:      Paris - France
local-as:   AS1
ifaddr:     147.45.0.17 masklen 32
interface:  147.45.0.17 masklen 32
admin-c:    FR123-AP
tech-c:     FR123-AP
mnt-by:     MAINT-EXAMPLENET-AP
notify:     watcher@example.com
changed:    abc@examplenet.com 20101231
member-of:  AS2
remarks:    No remarks
source:     RIPE

