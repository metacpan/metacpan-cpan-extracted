use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::Role'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( role address phone fax_no e_mail trouble admin_c tech_c nic_hdl remarks notify mnt_by changed source);

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'role'
$tested{'role'}++;
is( $object->role(), 'Company Admin', 'role properly parsed' );
$object->role('Role');
is( $object->role(), 'Role', 'role properly set' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), ["The Company's admin"], 'remarks properly parsed' );
$object->remarks('Added remarks');
is( $object->remarks()->[1], 'Added remarks', 'remarks properly added' );

# Test 'address'
$tested{'address'}++;
is_deeply( $object->address(), [ 'The Company', '2 avenue de la gare', '75001 Paris', 'France', ], 'address properly parsed' );
$object->address('Added address');
is( $object->address()->[4], 'Added address', 'address properly added' );

# Test 'phone'
$tested{'phone'}++;
is_deeply( $object->phone(), ['+33 1 44 01 01 00'], 'phone properly parsed' );
$object->phone('Added phone');
is( $object->phone()->[1], 'Added phone', 'phone properly added' );

# Test 'fax_no'
$tested{'fax_no'}++;
is_deeply( $object->fax_no(), ['+33 1 44 01 01 46'], 'fax_no properly parsed' );
$object->fax_no('Added fax_no');
is( $object->fax_no()->[1], 'Added fax_no', 'fax_no properly added' );

# Test 'e_mail'
$tested{'e_mail'}++;
is_deeply( $object->e_mail(), ['role@somewhere.com'], 'e_mail properly parsed' );
$object->e_mail('role2@elsewhere.com');
is( $object->e_mail()->[1], 'role2@elsewhere.com', 'e_mail properly added' );

# Test 'org'
$tested{'org'}++;
is_deeply( $object->org(), ['ORG-MISC01-RIPE'], 'org properly parsed' );
$object->org('ORG-MISC02-RIPE');
is( $object->org()->[1], 'ORG-MISC02-RIPE', 'org properly added' );

# Test 'admin_c'
$tested{'admin_c'}++;
is_deeply( $object->admin_c(), ['CPY01-RIPE'], 'admin_c properly parsed' );
$object->admin_c('Added admin_c');
is( $object->admin_c()->[1], 'Added admin_c', 'admin_c properly added' );

# Test 'tech_c'
$tested{'tech_c'}++;
is_deeply( $object->tech_c(), [ 'CPY01-RIPE', 'C???-RIPE', 'C?????-RIPE' ], 'tech_c properly parsed' );
$object->tech_c('Added tech_c');
is( $object->tech_c()->[3], 'Added tech_c', 'tech_c properly added' );

# Test 'nic_hdl'
$tested{'nic_hdl'}++;
is( $object->nic_hdl(), 'C??????-RIPE', 'nic_hdl properly parsed' );
$object->nic_hdl('NICHDL');
is( $object->nic_hdl(), 'NICHDL', 'nic_hdl properly set' );

# Test 'mnt_by'
$tested{'mnt_by'}++;
is_deeply( $object->mnt_by(), ['E???-MNT'], 'mnt_by properly parsed' );
$object->mnt_by('Added mnt_by');
is( $object->mnt_by()->[1], 'Added mnt_by', 'mnt_by properly added' );

# Test 'notify'
$tested{'notify'}++;
is_deeply( $object->notify(), ['E???-MNT'], 'notify properly parsed' );
$object->notify('Added notify');
is( $object->notify()->[1], 'Added notify', 'notify properly added' );

# Test 'changed'
$tested{'changed'}++;
is_deeply( $object->changed(), ['xxx@somewhere.com 20121016'], 'changed properly parsed' );
$object->changed('Added changed');
is( $object->changed()->[1], 'Added changed', 'changed properly added' );

# Test 'abuse_mailbox'
$tested{'abuse_mailbox'}++;
$object->abuse_mailbox('foo@example.com');
is($object->abuse_mailbox->[0], 'foo@example.com', 'abuse_mailbox');

# Test 'source'
$tested{'source'}++;
is( $object->source(), 'RIPE # Filtered', 'source properly parsed' );
$object->source('RIPE');
is( $object->source(), 'RIPE', 'source properly set' );

# Test 'e_mail'
$tested{'e_mail'}++;

# TODO

# Test 'trouble'
$tested{'trouble'}++;

# TODO

# Common tests
do 't/common.pl';
ok( $tested{common_loaded}, "t/common.pl properly loaded" );
ok( !$@, "Can evaluate t/common.pl ($@)" );

__DATA__
role:           Company Admin
remarks:        The Company's admin
address:        The Company
address:        2 avenue de la gare
address:        75001 Paris
address:        France
phone:          +33 1 44 01 01 00
fax-no:         +33 1 44 01 01 46
e-mail:         role@somewhere.com
org:            ORG-MISC01-RIPE
admin-c:        CPY01-RIPE
tech-c:         CPY01-RIPE
tech-c:         C???-RIPE
tech-c:         C?????-RIPE
nic-hdl:        C??????-RIPE
mnt-by:         E???-MNT
notify:         E???-MNT
changed:        xxx@somewhere.com 20121016
source:         RIPE # Filtered

