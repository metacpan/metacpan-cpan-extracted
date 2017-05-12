use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::Person'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( person address phone fax_no e_mail nic_hdl remarks notify
    mnt_by changed source);

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'person'
$tested{'person'}++;
is( $object->person(), 'COMPANY Contact', 'person properly parsed' );
$object->person('PERSON');
is( $object->person(), 'PERSON', 'person properly set' );

# Test 'address'
$tested{'address'}++;
is_deeply( $object->address(), [ 'The Company', '2 Rue de la Gare', '75001 PARIS', ], 'address properly parsed' );
$object->address('Added address');
is( $object->address()->[3], 'Added address', 'address properly added' );

# Test 'phone'
$tested{'phone'}++;
is_deeply( $object->phone(), ['+33 1 72 44 01 00'], 'phone properly parsed' );
$object->phone('Added phone');
is( $object->phone()->[1], 'Added phone', 'phone properly added' );

# Test 'fax_no'
$tested{'fax_no'}++;
is_deeply( $object->fax_no(), ['+33 1 72 44 01 46'], 'fax_no properly parsed' );
$object->fax_no('Added fax_no');
is( $object->fax_no()->[1], 'Added fax_no', 'fax_no properly added' );

# Test 'e_mail'
$tested{'e_mail'}++;
is_deeply( $object->e_mail(), ['xxx@somewhere.com'], 'e_mail properly parsed' );
$object->e_mail('Added e_mail');
is( $object->e_mail()->[1], 'Added e_mail', 'e_mail properly added' );

# Test 'org'
$tested{'org'}++;
is_deeply( $object->org(), ['ORG-MISC01-RIPE', 'ORG-MISC02-RIPE'], 'org properly parsed' );
$object->org('ORG-MISC03-RIPE');
is( $object->org()->[2], 'ORG-MISC03-RIPE', 'org properly added' );

# Test 'nic_hdl'
$tested{'nic_hdl'}++;
is( $object->nic_hdl(), 'NC123-RIPE', 'nic_hdl properly parsed' );
$object->nic_hdl('NIC-HDL');
is( $object->nic_hdl(), 'NIC-HDL', 'nic_hdl properly set' );

# Test 'mnt_by'
$tested{'mnt_by'}++;
is_deeply( $object->mnt_by(), ['MAIN-FR-MNT'], 'mnt_by properly parsed' );
$object->mnt_by('Added mnt_by');
is( $object->mnt_by()->[1], 'Added mnt_by', 'mnt_by properly added' );

# Test 'notify'
$tested{'notify'}++;
is_deeply( $object->notify(), ['MAIN-FR-MNT'], 'notify properly parsed' );
$object->notify('Added notify');
is( $object->notify()->[1], 'Added notify', 'notify properly added' );

# Test 'abuse_mailbox'
$tested{'abuse_mailbox'}++;
is_deeply( $object->abuse_mailbox(), ['abuse@somewhere.com'], 'abuse_mailbox properly parsed' );
$object->abuse_mailbox('abuse2@elsewhere.com');
is( $object->abuse_mailbox()->[1], 'abuse2@elsewhere.com', 'abuse_mailbox properly added' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), ['Simple person object'], 'remarks properly parsed' );
$object->remarks('Added remarks');
is( $object->remarks()->[1], 'Added remarks', 'remarks properly added' );

# Test 'changed'
$tested{'changed'}++;
is_deeply( $object->changed(), ['xxx@somewhere.com 20121016'], 'changed properly parsed' );
$object->changed('Added changed');
is( $object->changed()->[1], 'Added changed', 'changed properly added' );

# Test 'source'
$tested{'source'}++;
is( $object->source(), 'RIPE # Filtered', 'source properly parsed' );
$object->source('APNIC');
is( $object->source(), 'APNIC', 'source properly set' );

# Common tests
do 't/common.pl';
ok( $tested{common_loaded}, "t/common.pl properly loaded" );
ok( !$@, "Can evaluate t/common.pl ($@)" );

__DATA__
person:       COMPANY Contact
remarks:      Simple person object
address:      The Company
address:      2 Rue de la Gare
address:      75001 PARIS
phone:        +33 1 72 44 01 00
fax-no:       +33 1 72 44 01 46
e-mail:       xxx@somewhere.com
org:          ORG-MISC01-RIPE
org:          ORG-MISC02-RIPE
nic-hdl:      NC123-RIPE
mnt-by:       MAIN-FR-MNT
notify:       MAIN-FR-MNT
abuse-mailbox: abuse@somewhere.com
changed:      xxx@somewhere.com 20121016
source:       RIPE # Filtered


