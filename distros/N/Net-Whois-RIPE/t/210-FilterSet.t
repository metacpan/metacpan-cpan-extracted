use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::FilterSet'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( filter_set descr filter mp_filter remarks org tech_c
    admin_c notify mnt_by mnt_lower changed source);

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'filter_set'
$tested{'filter_set'}++;
is( $object->filter_set(), 'FLTR-EXAMPLE', 'filter_set properly parsed' );
$object->filter_set('FLTR-EXAMPLE2');
is( $object->filter_set(), 'FLTR-EXAMPLE2', 'filter_set properly set' );

# Test 'descr'
$tested{'descr'}++;
is_deeply( $object->descr(), ['Filter local community routes'], 'descr properly parsed' );
$object->descr('Added descr');
is( $object->descr()->[1], 'Added descr', 'descr properly added' );

# Test 'filter'
$tested{'filter'}++;
is( $object->filter(), '(AS1 or fltr-foo) and <AS2>', 'filter properly parsed' );
$object->filter('other filter');
is( $object->filter(), 'other filter', 'filter properly modified' );

# Test 'mp_filter'
$tested{'mp_filter'}++;
is( $object->mp_filter(), '{ 192.0.2.0/24, 2001:0DB8::/32 }', 'mp_filter properly parsed' );
$object->mp_filter('other filter v6');
is( $object->mp_filter(), 'other filter v6', 'mp_filter properly added' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), ['No remarks'], 'remarks properly parsed' );
$object->remarks('Added remarks');
is( $object->remarks()->[1], 'Added remarks', 'remarks properly added' );

# Test 'tech_c'
$tested{'tech_c'}++;
is_deeply( $object->tech_c(), ['TECH-CTCT'], 'tech_c properly parsed' );
$object->tech_c('TECH2-CTCT');
is( $object->tech_c()->[1], 'TECH2-CTCT', 'tech_c properly added' );

# Test 'admin_c'
$tested{'admin_c'}++;
is_deeply( $object->admin_c(), ['ADM-CTCT'], 'admin_c properly parsed' );
$object->admin_c('ADM2-CTCT');
is( $object->admin_c()->[1], 'ADM2-CTCT', 'admin_c properly added' );

# Test 'notify'
$tested{'notify'}++;
is_deeply( $object->notify(), ['watcher@somewhere.com'], 'notify properly parsed' );
$object->notify('watcher@elsewhere.com');
is( $object->notify()->[1], 'watcher@elsewhere.com', 'notify properly added' );

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
$object->changed('abc@somewhere.com 20120228');
is( $object->changed()->[1], 'abc@somewhere.com 20120228', 'changed properly added' );

# Test 'source'
$tested{'source'}++;
is( $object->source(), 'RIPE', 'source properly parsed' );
$object->source('APNIC');
is( $object->source(), 'APNIC', 'source properly set' );

# Test 'org'
$tested{'org'}++;
# TODO

# Common tests
do 't/common.pl';
ok( $tested{common_loaded}, "t/common.pl properly loaded" );
ok( !$@, "Can evaluate t/common.pl ($@)" );

__DATA__
filter-set:     FLTR-EXAMPLE
descr:          Filter local community routes
filter:         (AS1 or fltr-foo) and <AS2>
mp-filter:      { 192.0.2.0/24, 2001:0DB8::/32 }
remarks:        No remarks
tech-c:         TECH-CTCT
admin-c:        ADM-CTCT
notify:         watcher@somewhere.com
mnt-by:         MAINT-EXAMPLECOM
mnt-lower:      MAINT-EXAMPLECOM
changed:        abc@somewhere.com 20120131
source:         RIPE

