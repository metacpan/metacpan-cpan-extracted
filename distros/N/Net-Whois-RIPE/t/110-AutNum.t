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
is( $object->aut_num(), 'AS7', 'aut_num properly parsed' );
$object->aut_num('AS1');
is( $object->aut_num(), 'AS1', 'aut_num properly set' );
$tested{'aut_num'}++;

# Test 'remarks'
is_deeply( $object->remarks(), ['AS number 7'], 'remarks properly parsed' );
$object->remarks('Added remarks');
is( $object->remarks()->[1], 'Added remarks', 'remarks properly added' );
$tested{'remarks'}++;

# Test 'as_name'
is( $object->as_name(), 'FR-COMPANY', 'as_name properly parsed' );
$object->as_name('FR-C');
is( $object->as_name(), 'FR-C', 'as_name properly set' );
$tested{'as_name'}++;

# Test 'descr'
is_deeply( $object->descr(), [ 'French Company', 'FRANCE' ], 'descr properly parsed' );
$object->descr('Added descr');
is( $object->descr()->[2], 'Added descr', 'descr properly added' );
$tested{'descr'}++;

# Test 'org'
is( $object->org(), 'ORG-MISC01-RIPE', 'org properly parsed' );
$object->org('ORG-MOD');
is( $object->org(), 'ORG-MOD', 'org properly set' );
$tested{'org'}++;

# Test 'admin_c'
is_deeply( $object->admin_c(), ['NC123-RIPE'], 'admin_c properly parsed' );
$object->admin_c('Added admin_c');
is( $object->admin_c()->[1], 'Added admin_c', 'admin_c properly added' );
$tested{'admin_c'}++;

# Test 'tech_c'
is_deeply( $object->tech_c(), ['NC345-RIPE'], 'tech_c properly parsed' );
$object->tech_c('Added tech_c');
is( $object->tech_c()->[1], 'Added tech_c', 'tech_c properly added' );
$tested{'tech_c'}++;

# Test 'mnt_by'
is_deeply( $object->mnt_by(), [ 'RIPE-NCC-END-MNT', 'MAIN-FR-MNT' ], 'mnt_by properly parsed' );
$object->mnt_by('Added mnt_by');
is( $object->mnt_by()->[2], 'Added mnt_by', 'mnt_by properly added' );
$tested{'mnt_by'}++;

# Test 'source'
$tested{'source'}++;
is( $object->source(), 'RIPE # Filtered', 'source properly parsed' );
$object->source('ANIC');
is( $object->source(), 'ANIC', 'source properly set' );

# Test 'notify'
is_deeply( $object->notify(), ['MAIN-FR-MNT'], 'notify properly parsed' );
$object->notify('Added notify');
is( $object->notify()->[1], 'Added notify', 'notify properly added' );

# Test 'import'
is_deeply( $object->import(), [ 'import1', 'import2'], 'import properly parsed' );
$object->import('import3');
is( $object->import()->[2], 'import3', 'import properly added' );
$tested{'import'}++;

# Test 'mp_import'
is_deeply( $object->mp_import(), [ 'mp_import1', 'mp_import2'], 'mp_import properly parsed' );
$object->mp_import('mp_import3');
is( $object->mp_import()->[2], 'mp_import3', 'mp_import properly added' );
$tested{'mp_import'}++;

# Test 'export'
is_deeply( $object->export(), [ 'export1', 'export2'], 'export properly parsed' );
$object->export('export3');
is( $object->export()->[2], 'export3', 'export properly added' );
$tested{'export'}++;

# Test 'mp_export'
is_deeply( $object->mp_export(), [ 'mp_export1', 'mp_export2'], 'mp_export properly parsed' );
$object->mp_export('mp_export3');
is( $object->mp_export()->[2], 'mp_export3', 'mp_export properly added' );
$tested{'mp_export'}++;

# Test 'default'
is_deeply( $object->default(), [ 'default1', 'default2'], 'default properly parsed' );
$object->default('default3');
is( $object->default()->[2], 'default3', 'default properly added' );
$tested{'default'}++;

# Test 'mp_default'
is_deeply( $object->mp_default(), [ 'mp_default1', 'mp_default2'], 'mp_default properly parsed' );
$object->mp_default('mp_default3');
is( $object->mp_default()->[2], 'mp_default3', 'mp_default properly added' );
$tested{'mp_default'}++;

# Test 'member_of'
is_deeply( $object->member_of(), [ 'member_of1', 'member_of2'], 'member_of properly parsed' );
$object->member_of('member_of3');
is( $object->member_of()->[2], 'member_of3', 'member_of properly added' );
$tested{'member_of'}++;

# Common tests
do './t/common.pl';
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
import:          import1
import:          import2
mp-import:       mp_import1
mp-import:       mp_import2
export:          export1
export:          export2
mp-export:       mp_export1
mp-export:       mp_export2
default:         default1
default:         default2
mp-default:      mp_default1
mp-default:      mp_default2
member-of:       member_of1
member-of:       member_of2
source:          RIPE # Filtered

