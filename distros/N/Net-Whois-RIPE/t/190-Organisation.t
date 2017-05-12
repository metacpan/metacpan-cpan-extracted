use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::Organisation'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( organisation org_name org_type descr remarks address phone
    e_mail fax_no org abuse_c admin_c tech_c ref_nfy mnt_ref notify mnt_by changed source);

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'organisation'
$tested{'organisation'}++;
is( $object->organisation(), 'AUTO-1', 'organisation properly parsed' );
$object->organisation('AUTO-2');
is( $object->organisation(), 'AUTO-2', 'organisation properly set' );

# Test 'org_name'
$tested{'org_name'}++;
is( $object->org_name(), 'The name of the organisation', 'org_name properly parsed' );
$object->org_name('Organisation\'s name');
is( $object->org_name(), 'Organisation\'s name', 'name properly set' );

# Test 'org_type'
$tested{'org_type'}++;
is( $object->org_type(), 'OTHER', 'org_type properly parsed' );
$object->org_type('IANA');
is( $object->org_type(), 'IANA', 'org_type properly set' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), [ 'This is a dummy organisation object.', 'Used for testing' ], 'remarks properly parsed' );
$object->remarks('Added remarks');
is( $object->remarks()->[2], 'Added remarks', 'remarks properly added' );

# Test 'address'
$tested{'address'}++;
is_deeply( $object->address(), [ '2 Rue de la Gare', '75001 Paris', 'France' ], 'address properly parsed' );
$object->address('Added address');
is( $object->address()->[3], 'Added address', 'address properly added' );

# Test 'phone'
$tested{'phone'}++;
is_deeply( $object->phone(), ['+33 1 75 75 75 01'], 'phone properly parsed' );
$object->phone('+33 1 75 75 75 02');
is( $object->phone()->[1], '+33 1 75 75 75 02', 'phone properly added' );

# Test 'fax_no'
$tested{'fax_no'}++;
is_deeply( $object->fax_no(), ['+33 1 75 75 75 91'], 'fax_no properly parsed' );
$object->fax_no('+33 1 75 75 75 92');
is( $object->fax_no()->[1], '+33 1 75 75 75 92', 'fax_no properly added' );

# Test 'e_mail'
$tested{'e_mail'}++;
is_deeply( $object->e_mail(), ['someone@somewhere.com'], 'e_mail properly parsed' );
$object->e_mail('someone@elsewhere.com');
is( $object->e_mail()->[1], 'someone@elsewhere.com', 'e_mail properly added' );

# Test 'geoloc'
$tested{'geoloc'}++;
is( $object->geoloc(), 'OTHER', 'geoloc properly parsed' );
$object->geoloc('IANA');
is( $object->geoloc(), 'IANA', 'geoloc properly set' );

# Test 'language'
$tested{'language'}++;
is_deeply( $object->language(), ['FR','EN'], 'language properly parsed' );
$object->language('ES');
is( $object->language()->[2], 'ES', 'language properly added' );

# Test 'abuse_c'
$tested{'abuse_c'}++;
is( $object->abuse_c(), 'abuse@somewhere.com', 'abuse_c properly parsed' );
$object->abuse_c('abuse3@somewhere.com');
is( $object->abuse_c(), 'abuse3@somewhere.com', 'abuse_c properly changed' );

# Test 'admin_c'
$tested{'admin_c'}++;
is_deeply( $object->admin_c(), ['CPNY-ADM'], 'admin_c properly parsed' );
$object->admin_c('CPNY-ADM2');
is( $object->admin_c()->[1], 'CPNY-ADM2', 'admin_c properly added' );

# Test 'tech_c'
$tested{'tech_c'}++;
is_deeply( $object->tech_c(), ['CPNY-TCH'], 'tech_c properly parsed' );
$object->tech_c('CPNY-TCH2');
is( $object->tech_c()->[1], 'CPNY-TCH2', 'tech_c properly added' );

# Test 'ref_nfy'
$tested{'ref_nfy'}++;
is_deeply( $object->ref_nfy(), ['someone@somewhere.com'], 'ref_nfy properly parsed' );
$object->ref_nfy('someone@elsewhere.com');
is( $object->ref_nfy()->[1], 'someone@elsewhere.com', 'ref_nfy properly added' );

# Test 'mnt_ref'
$tested{'mnt_ref'}++;
is_deeply( $object->mnt_ref(), ['CPNY-MNT'], 'mnt_ref properly parsed' );
$object->mnt_ref('CPNY-MNT2');
is( $object->mnt_ref()->[1], 'CPNY-MNT2', 'mnt_ref properly added' );

# Test 'mnt_by'
$tested{'mnt_by'}++;
is_deeply( $object->mnt_by(), ['CPNY-MNT'], 'mnt_by properly parsed' );
$object->mnt_by('CPNY-MNT2');
is( $object->mnt_by()->[1], 'CPNY-MNT2', 'mnt_by properly added' );

# Test 'notify'
$tested{'notify'}++;
is_deeply( $object->notify(), ['CPNY-MNT'], 'notify properly parsed' );
$object->notify('CPNY-MNT2');
is( $object->notify()->[1], 'CPNY-MNT2', 'notify properly added' );

# Test 'abuse_mailbox'
$tested{'abuse_mailbox'}++;
is_deeply( $object->abuse_mailbox(), ['abuse1@somewhere.com','abuse2@somewhere.com'], 'abuse_mailbox properly parsed' );
$object->abuse_mailbox('abuse3@somewhere.com');
is( $object->abuse_mailbox()->[2], 'abuse3@somewhere.com', 'abuse_mailbox properly added' );

# Test 'descr'
$tested{'descr'}++;
is_deeply( $object->descr(), ['Providing happiness from 7am to 7pm'], 'descr properly parsed' );
$object->descr('Idle');
is( $object->descr()->[1], 'Idle', 'descr properly added' );

# Test 'changed'
$tested{'changed'}++;
is_deeply( $object->changed(), ['someone@somewhere.com 20120131'], 'changed properly parsed' );
$object->changed('someone@somewhere.com 20120228');
is( $object->changed()->[1], 'someone@somewhere.com 20120228', 'changed properly added' );

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
organisation:   AUTO-1
org-name:       The name of the organisation
descr:          Providing happiness from 7am to 7pm
org-type:       OTHER
remarks:        This is a dummy organisation object.
                Used for testing
address:        2 Rue de la Gare
address:        75001 Paris
address:        France
phone:          +33 1 75 75 75 01
fax-no:         +33 1 75 75 75 91
e-mail:         someone@somewhere.com
geoloc:         OTHER
abuse-c:        abuse@somewhere.com
language:       FR
language:       EN
admin-c:        CPNY-ADM
tech-c:         CPNY-TCH
ref-nfy:        someone@somewhere.com
mnt-ref:        CPNY-MNT
mnt-by:         CPNY-MNT
notify:         CPNY-MNT
abuse-mailbox:  abuse1@somewhere.com
abuse-mailbox:  abuse2@somewhere.com
changed:        someone@somewhere.com 20120131
source:         RIPE

