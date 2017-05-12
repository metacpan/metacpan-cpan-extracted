use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::AsSet'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( as_set descr members mbrs_by_ref remarks tech_c admin_c
    notify mnt_by changed source );

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'as_set'
$tested{'as_set'}++;
is( $object->as_set(), 'AS-COM01', 'as-block properly parsed' );
$object->as_set('AS1-AS2');
is( $object->as_set(), 'AS1-AS2', 'as_set properly set' );

# Test 'descr'
$tested{'descr'}++;
is_deeply( $object->descr(), ['A description'], 'descr properly parsed' );
$object->descr('Added descr');
is( $object->descr()->[1], 'Added descr', 'descr properly added' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), [ '**********************', '*      Remarks       *', '**********************' ], 'remarks properly parsed' );
$object->remarks('Added remarks');
is( $object->remarks()->[3], 'Added remarks', 'remarks properly added' );

# Test 'org'
$tested{'org'}++;
is_deeply( $object->org(), ['ORG-MISC01-RIPE'], 'org properly parsed' );
$object->org('ORG-MISC02-RIPE');
is( $object->org()->[1], 'ORG-MISC02-RIPE', 'org properly added' );

# Test 'members'
$tested{'members'}++;
is_deeply( $object->members(), [ 'AS1', 'AS11', 'AS21', 'AS1211' ], 'members properly parsed' );
$object->members('Added members');
is( $object->members()->[4], 'Added members', 'members properly added' );

# Test 'mbrs_by_ref'
$tested{'mbrs_by_ref'}++;
is_deeply( $object->mbrs_by_ref(), [ 'UNK-MNT', 'UNK2-MNT', ], 'mbrs_by_ref properly parsed' );
$object->mbrs_by_ref('Added mbrs_by_ref');
is( $object->mbrs_by_ref()->[2], 'Added mbrs_by_ref', 'mbrs_by_ref properly added' );

# Test 'admin_c'
$tested{'admin_c'}++;
is_deeply( $object->admin_c(), ['CPY01-RIPE'], 'admin_c properly parsed' );
$object->admin_c('Added admin_c');
is( $object->admin_c()->[1], 'Added admin_c', 'admin_c properly added' );

# Test 'tech_c'
$tested{'tech_c'}++;
is_deeply( $object->tech_c(), [ 'CPY01-RIPE', 'CXXX-RIPE', 'CXXXXX-RIPE' ], 'tech_c properly parsed' );
$object->tech_c('C007-RIPE');
is( $object->tech_c()->[3], 'C007-RIPE', 'tech_c properly added' );

# Test 'notify'
$tested{'notify'}++;
is_deeply( $object->notify(), ['watcher@somewhere.com'], 'notify properly parsed' );
$object->notify('Added notify');
is( $object->notify()->[1], 'Added notify', 'notify properly added' );

# Test 'mnt_by'
$tested{'mnt_by'}++;
is_deeply( $object->mnt_by(), ['THE-MNT'], 'mnt_by properly parsed' );
$object->mnt_by('Added mnt_by');
is( $object->mnt_by()->[1], 'Added mnt_by', 'mnt_by properly added' );

# Test 'mnt_lower'
$tested{'mnt_lower'}++;
is_deeply( $object->mnt_lower(), ['THE-LMNT'], 'mnt_lower properly parsed' );
$object->mnt_lower('Added mnt_lower');
is( $object->mnt_lower()->[1], 'Added mnt_lower', 'mnt_lower properly added' );

# Test 'changed'
$tested{'changed'}++;
is_deeply( $object->changed(), [ 'someone@somewhere.net 20080422', 'someoneelese@somewere.net 20090429' ], 'changed properly parsed' );
$object->changed('Added changed');
is( $object->changed()->[2], 'Added changed', 'changed properly added' );

# Test 'source'
$tested{'source'}++;
is( $object->source(), 'RIPE # Filtered', 'source properly parsed' );
$object->source('RIPE');
is( $object->source(), 'RIPE', 'source properly set' );

# Common tests
do 't/common.pl';
ok( $tested{common_loaded}, "t/common.pl properly loaded" );
ok( !$@, "Can evaluate t/common.pl ($@)" );

__DATA__
as-set:         AS-COM01
descr:          A description
remarks:        **********************
remarks:        *      Remarks       *
remarks:        **********************
org:            ORG-MISC01-RIPE
members:        AS1
members:        AS11
members:        AS21
members:        AS1211
mbrs-by-ref:    UNK-MNT
mbrs-by-ref:    UNK2-MNT
admin-c:        CPY01-RIPE
tech-c:         CPY01-RIPE
tech-c:         CXXX-RIPE
tech-c:         CXXXXX-RIPE
notify:         watcher@somewhere.com
mnt-by:         THE-MNT
mnt-lower:      THE-LMNT
changed:        someone@somewhere.net 20080422
changed:        someoneelese@somewere.net 20090429
source:         RIPE # Filtered

