use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
# use IO::Handle;
# STDOUT->autoflush(1);
# STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::AsBlock'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited method
can_ok $object, qw( as_block descr remarks tech_c admin_c notify mnt_lower mnt_by changed source);
can_ok $object, qw( org );

can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'as_block'
$tested{'as_block'}++;
is( $object->as_block(), 'AS30720 - AS30895', 'as-block properly parsed' );
$object->as_block('AS1 - AS2');
is( $object->as_block(), 'AS1 - AS2', 'as_block properly set' );

# Test 'descr'
$tested{'descr'}++;
is_deeply( $object->descr(), ['RIPE NCC ASN block'], 'descr properly parsed' );
$object->descr('Added');
is_deeply( $object->descr(), [ 'RIPE NCC ASN block', 'Added' ], 'descr properly added' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), [ 'These AS Numbers are further assigned to network', 'operators in the RIPE NCC service region. AS', 'assignment policy is documented in:', '<http://www.ripe.net/ripe/docs/asn-assignment.html>', 'RIPE NCC members can request AS Numbers using the', 'form available in the LIR Portal or at:', '<http://www.ripe.net/ripe/docs/asnrequestform.html>' ], 'remarks properly parsed' );

$object->remarks('Added remarks');
is( $object->remarks()->[7], 'Added remarks', 'remarks properly added' );

# Test 'org'
$tested{'org'}++;
is( $object->org(), 'ORG-NCC1-RIPE', 'org properly parsed' );
$object->org('ORG-MDFIED');
is( $object->org(), 'ORG-MDFIED', 'org properly set' );

# Test 'admin_c'
$tested{'admin_c'}++;
is_deeply( $object->admin_c(), ['CREW-RIPE'], 'admin_c properly parsed' );
$object->admin_c('Added admin_c');
is( $object->admin_c()->[1], 'Added admin_c', 'admin_c properly added' );

# Test 'tech_c'
$tested{'tech_c'}++;
is_deeply( $object->tech_c(), ['RD132-RIPE'], 'tech_c properly parsed' );
$object->tech_c('Added tech_c');
is( $object->tech_c()->[1], 'Added tech_c', 'tech_c properly added' );

# Test 'mnt_by'
$tested{'mnt_by'}++;
is_deeply( $object->mnt_by(), ['RIPE-DBM-MNT'], 'mnt_by properly parsed' );
$object->mnt_by('Added mnt_by');
is( $object->mnt_by()->[1], 'Added mnt_by', 'mnt_by properly added' );

# Test 'mnt_lower'
$tested{'mnt_lower'}++;
is_deeply( $object->mnt_lower(), ['RIPE-NCC-HM-MNT'], 'mnt_lower properly parsed' );
$object->mnt_lower('Added mnt_lower');
is( $object->mnt_lower()->[1], 'Added mnt_lower', 'mnt_lower properly added' );

# Test 'notify'
$tested{'notify'}++;
is_deeply( $object->notify(), ['RIPE-DBM-MNT'], 'notify properly parsed' );
$object->notify('Added notify');
is( $object->notify()->[1], 'Added notify', 'notify properly added' );

# Test 'changed'
$tested{'changed'}++;
is_deeply( $object->changed(), ['arhuman@gmail.com 20120701'], 'changed properly parsed' );
$object->changed('Added changed');
is( $object->changed()->[1], 'Added changed', 'changed properly added' );

# Test 'source'
$tested{'source'}++;
is( $object->source(), 'RIPE # Filtered', 'source properly parsed' );
$object->source('APNIC');
is( $object->source(), 'APNIC', 'source properly set' );

# test 'align'
my $align = Net::Whois::Object::AsBlock->new(
    as_block  =>   'AS30720 - AS30895',
    descr     =>   'RIPE NCC ASN block',
    remarks   =>   'These AS Numbers are further assigned to network',
    remarks   =>   'operators in the RIPE NCC service region. AS',
    remarks   =>   'assignment policy is documented in:',
    remarks   =>   '<http://www.ripe.net/ripe/docs/asn-assignment.html>',
    remarks   =>   'RIPE NCC members can request AS Numbers using the',
    remarks   =>   'form available in the LIR Portal or at:',
    remarks   =>   '<http://www.ripe.net/ripe/docs/asnrequestform.html>',
    org       =>   'ORG-NCC1-RIPE',
    admin_c   =>   'CREW-RIPE',
    tech_c    =>   'RD132-RIPE',
    mnt_by    =>   'RIPE-DBM-MNT',
    notify    =>   'RIPE-DBM-MNT',
    mnt_lower =>   'RIPE-NCC-HM-MNT',
    changed   =>   'arhuman@gmail.com 20120701',
    source    =>   'RIPE # Filtered',
);

for (split /\n/, $align->dump({align => 30})) {
    ok $_ =~ /^.{29}\s\S/, "Line '$_' is aligned to column 30";
}

# Test 'as_block' on aligned data
is( $align->as_block(), 'AS30720 - AS30895', 'aligned as-block properly parsed' );

# Common tests
do 't/common.pl';
ok( $tested{common_loaded}, "t/common.pl properly loaded" );
ok( !$@, "Can evaluate t/common.pl ($@)" );


__DATA__
as-block:       AS30720 - AS30895
descr:          RIPE NCC ASN block
remarks:        These AS Numbers are further assigned to network
remarks:        operators in the RIPE NCC service region. AS
remarks:        assignment policy is documented in:
remarks:        <http://www.ripe.net/ripe/docs/asn-assignment.html>
remarks:        RIPE NCC members can request AS Numbers using the
remarks:        form available in the LIR Portal or at:
remarks:        <http://www.ripe.net/ripe/docs/asnrequestform.html>
org:            ORG-NCC1-RIPE
admin-c:        CREW-RIPE
tech-c:         RD132-RIPE
mnt-by:         RIPE-DBM-MNT
notify:         RIPE-DBM-MNT
mnt-lower:      RIPE-NCC-HM-MNT
changed:        arhuman@gmail.com 20120701
source:         RIPE # Filtered

