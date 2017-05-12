use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::RouteSet'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( route_set descr members mp_members mbrs_by_ref remarks
    tech_c admin_c notify mnt_by mnt_lower changed source);

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'route_set'
$tested{'route_set'}++;
is( $object->route_set(), 'RS-DENIED-ROUTES', 'route_set properly parsed' );
$object->route_set('RS-ALLOWED-ROUTES');
is( $object->route_set(), 'RS-ALLOWED-ROUTES', 'route_set properly set' );

# Test 'descr'
$tested{'descr'}++;
is_deeply( $object->descr(), ['Set of denied routes'], 'descr properly parsed' );
$object->descr('Added descr');
is( $object->descr()->[1], 'Added descr', 'descr properly added' );

# Test 'members'
$tested{'members'}++;
is_deeply( $object->members(), [ 'RTE01', 'RTE02' ], 'members properly parsed' );
$object->members('RTE03');
is( $object->members()->[2], 'RTE03', 'members properly added' );

# Test 'mp_members'
$tested{'mp_members'}++;
is_deeply( $object->mp_members(), [ 'RTE-V6-01', 'RTE-V6-02' ], 'mp_members properly parsed' );
$object->mp_members('RTE-V6-03');
is( $object->mp_members()->[2], 'RTE-V6-03', 'mp_members properly added' );

# Test 'mbrs_by_ref'
$tested{'mbrs_by_ref'}++;
is_deeply( $object->mbrs_by_ref(), ['RTE-MAINT01'], 'mbrs_by_ref properly parsed' );
$object->mbrs_by_ref('RTE-MAINT02');
is( $object->mbrs_by_ref()->[1], 'RTE-MAINT02', 'mbrs_by_ref properly added' );

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

# Test 'tech_c'
$tested{'tech_c'}++;
is_deeply( $object->tech_c(), ['TECH-CTCT'], 'tech_c properly parsed' );
$object->tech_c('TECH-CTCT2');
is( $object->tech_c()->[1], 'TECH-CTCT2', 'tech_c properly added' );

# Test 'admin_c'
$tested{'admin_c'}++;
is_deeply( $object->admin_c(), ['ADM-CTCT'], 'admin_c properly parsed' );
$object->admin_c('ADM2-CTCT');
is( $object->admin_c()->[1], 'ADM2-CTCT', 'admin_c properly added' );

# Test 'notify'
$tested{'notify'}++;
is_deeply( $object->notify(), ['watcher@somewhere.com'], 'notify properly parsed' );
$object->notify('Added notify');
is( $object->notify()->[1], 'Added notify', 'notify properly added' );

# Test 'mnt_by'
$tested{'mnt_by'}++;
is_deeply( $object->mnt_by(), ['MAINT-EXAMPLECOM'], 'mnt_by properly parsed' );
$object->mnt_by('MAINT2-EXAMPLECOM');
is( $object->mnt_by()->[1], 'MAINT2-EXAMPLECOM', 'mnt_by properly added' );

# Test 'mnt_lower'
$tested{'mnt_lower'}++;
is_deeply( $object->mnt_lower(), ['MAINT-EXAMPLECOM'], 'mnt_lower properly parsed' );
$object->mnt_lower('MAINT2-EXAMPLECOM');
is( $object->mnt_lower()->[1], 'MAINT2-EXAMPLECOM', 'mnt_lower properly added' );

# Test 'changed'
$tested{'changed'}++;
is_deeply( $object->changed(), ['abc@somewhere.com 20120131'], 'changed properly parsed' );
$object->changed('abc@somewhere.com 20120130');
is( $object->changed()->[1], 'abc@somewhere.com 20120130', 'changed properly added' );

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
route-set:      RS-DENIED-ROUTES
descr:          Set of denied routes
members:        RTE01
members:        RTE02
mp-members:     RTE-V6-01
mp-members:     RTE-V6-02
mbrs-by-ref:    RTE-MAINT01
remarks:        No remarks
org:            ORG-MISC01-RIPE
tech-c:         TECH-CTCT
admin-c:        ADM-CTCT
notify:         watcher@somewhere.com
mnt-by:         MAINT-EXAMPLECOM
mnt-lower:      MAINT-EXAMPLECOM
changed:        abc@somewhere.com 20120131
source:         RIPE

