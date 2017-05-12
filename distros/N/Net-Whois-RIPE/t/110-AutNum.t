use strict;
use warnings;
use Test::More qw( no_plan );
use Net::Whois::Object;

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;

BEGIN {
    $class = 'Net::Whois::Object::AutNum';

    # use_ok $class;
}

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Test 'aut_num'
$tested{'aut_num'}++;
is( $object->aut_num(), 'AS7', 'aut_num properly parsed' );
$object->aut_num('AS1');
is( $object->aut_num(), 'AS1', 'aut_num properly set' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), ['AS number 7'], 'remarks properly parsed' );
$object->remarks('Added remarks');
is( $object->remarks()->[1], 'Added remarks', 'remarks properly added' );

# Test 'as_name'
$tested{'as_name'}++;
is( $object->as_name(), 'FR-COMPANY', 'as_name properly parsed' );
$object->as_name('FR-C');
is( $object->as_name(), 'FR-C', 'as_name properly set' );

# Test 'descr'
$tested{'descr'}++;
is_deeply( $object->descr(), [ 'French Company', 'FRANCE' ], 'descr properly parsed' );
$object->descr('Added descr');
is( $object->descr()->[2], 'Added descr', 'descr properly added' );

# Test 'org'
$tested{'org'}++;
is( $object->org(), 'ORG-MISC01-RIPE', 'org properly parsed' );
$object->org('ORG-MOD');
is( $object->org(), 'ORG-MOD', 'org properly set' );

# Test 'admin_c'
$tested{'admin_c'}++;
is_deeply( $object->admin_c(), ['NC123-RIPE'], 'admin_c properly parsed' );
$object->admin_c('Added admin_c');
is( $object->admin_c()->[1], 'Added admin_c', 'admin_c properly added' );

# Test 'tech_c'
$tested{'tech_c'}++;
is_deeply( $object->tech_c(), ['NC345-RIPE'], 'tech_c properly parsed' );
$object->tech_c('Added tech_c');
is( $object->tech_c()->[1], 'Added tech_c', 'tech_c properly added' );

is( $object->tech_c()->[1], 'Added tech_c', 'tech_c properly added' );
# Test 'mnt_by'
$tested{'mnt_by'}++;
is_deeply( $object->mnt_by(), [ 'RIPE-NCC-END-MNT', 'MAIN-FR-MNT' ], 'mnt_by properly parsed' );
$object->mnt_by('Added mnt_by');
is( $object->mnt_by()->[2], 'Added mnt_by', 'mnt_by properly added' );

# Test 'source'
$tested{'source'}++;
is( $object->source(), 'RIPE # Filtered', 'source properly parsed' );
$object->source('ANIC');
is( $object->source(), 'ANIC', 'source properly set' );

# Test 'notify'
$tested{'notify'}++;
is_deeply( $object->notify(), ['MAIN-FR-MNT'], 'notify properly parsed' );
$object->notify('Added notify');
is( $object->notify()->[1], 'Added notify', 'notify properly added' );

# Test 'changed'
$tested{'changed'}++;
is_deeply( $object->changed(), ['arhuman@gmail.com 20120701'], 'changed properly parsed' );
$object->changed('Added changed');
is( $object->changed()->[1], 'Added changed', 'changed properly added' );

# Test 'import'
$tested{'import'}++;

# TODO

# Test 'mp_import'
$tested{'mp_import'}++;

# TODO

# Test 'export'
$tested{'export'}++;

# TODO

# Test 'mp_export'
$tested{'mp_export'}++;

# TODO

# Test 'default'
$tested{'default'}++;

# TODO

# Test 'mp_default'
$tested{'mp_default'}++;

# TODO

# Test 'mnt_routes'
$tested{'mnt_routes'}++;

# TODO

# Test 'member_of'
$tested{'member_of'}++;

# TODO

# Test 'mnt_lower'
$tested{'mnt_lower'}++;

# TODO

# Common tests
do 't/common.pl';
ok( $tested{common_loaded}, "t/common.pl properly loaded" );
ok( !$@, "Can evaluate t/common.pl ($@)" );

__DATA__
aut-num:         AS7
remarks:         AS number 7
as-name:         FR-COMPANY
descr:           French Company
descr:           FRANCE
org:             ORG-MISC01-RIPE
admin-c:         NC123-RIPE
tech-c:          NC345-RIPE
mnt-by:          RIPE-NCC-END-MNT
mnt-by:          MAIN-FR-MNT
notify:          MAIN-FR-MNT
mnt-routes:      MAIN-FR-MNT
changed:         arhuman@gmail.com 20120701
source:          RIPE # Filtered

