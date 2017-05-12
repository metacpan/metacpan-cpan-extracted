use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::RtrSet'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw(rtr_set descr members mp_members mbrs_by_ref
    admin_c tech_c mnt_by notify changed remarks source);

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'rtr_set'
$tested{'rtr_set'}++;
is( $object->rtr_set(), 'RTRS-EXAMPLENET', 'rtr_set properly parsed' );
$object->rtr_set('RTRS2-EXAMPLENET');
is( $object->rtr_set(), 'RTRS2-EXAMPLENET', 'rtr_set properly set' );

# Test 'descr'
$tested{'descr'}++;
is_deeply( $object->descr(), [ 'Router set for', 'the company Example' ], 'descr properly parsed' );
$object->descr('Added descr');
is( $object->descr()->[2], 'Added descr', 'descr properly added' );

# Test 'members'
$tested{'members'}++;
is_deeply( $object->members(), [ 'INET-RTR1', 'RTRS-SET3' ], 'members properly parsed' );
$object->members('RTRS-SET4');
is( $object->members()->[2], 'RTRS-SET4', 'members properly added' );

# Test 'mp_members'
$tested{'mp_members'}++;
is_deeply( $object->mp_members(), [ '192.168.1.1', '2001:db8:85a3:8d3:1319:8a2e:370:7348', 'INET-RTRV6', 'RTRS-SET1' ], 'mp_members properly parsed' );
$object->mp_members('RTRS-SET2');
is( $object->mp_members()->[4], 'RTRS-SET2', 'mp_members properly added' );

# Test 'mbrs_by_ref'
$tested{'mbrs_by_ref'}++;
is_deeply( $object->mbrs_by_ref(), ['CPNY-MNTNER'], 'mbrs_by_ref properly parsed' );
$object->mbrs_by_ref('CPY2-MNTNER');
is( $object->mbrs_by_ref()->[1], 'CPY2-MNTNER', 'mbrs_by_ref properly added' );

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
$object->changed('abc@examplenet.com 20121231');
is( $object->changed()->[1], 'abc@examplenet.com 20121231', 'changed properly added' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), ['No remarks'], 'remarks properly parsed' );
$object->remarks('Added remarks');
is( $object->remarks()->[1], 'Added remarks', 'remarks properly added' );

# Test 'org'
$tested{'org'}++;
is_deeply( $object->org(), ['ORG-MISC01-RIPE'], 'org properly parsed' );
$object->org('ORG-MISC02-RIPE');
is( $object->org()->[1], 'ORG-MISC02-RIPE', 'org properly added' );

# Test 'source'
$tested{'source'}++;
is( $object->source(), 'RIPE', 'source properly parsed' );
$object->source('APNIC');
is( $object->source(), 'APNIC', 'source properly set' );

# Common tests
do 't/common.pl';
ok( $tested{common_loaded}, "t/common.pl properly loaded" );
ok( !$@, "Can evaluate t/common.pl ($@)" );

__DATA__
rtr-set:        RTRS-EXAMPLENET
descr:          Router set for
descr:          the company Example
members:        INET-RTR1
members:        RTRS-SET3
mp-members:     192.168.1.1
mp-members:     2001:db8:85a3:8d3:1319:8a2e:370:7348
mp-members:     INET-RTRV6
mp-members:     RTRS-SET1
mbrs-by-ref:    CPNY-MNTNER
admin-c:        FR123-AP
tech-c:         FR123-AP
mnt-by:         MAINT-EXAMPLENET-AP
notify:         watcher@example.com
changed:        abc@examplenet.com 20101231
remarks:        No remarks
org:            ORG-MISC01-RIPE
source:         RIPE

