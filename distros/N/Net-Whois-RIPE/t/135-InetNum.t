use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::InetNum'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( inetnum netname descr country org admin_c tech_c status remarks notify mnt_by mnt_lower mnt_routes mnt_domains mnt_irt changed source);

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'inetnum'
$tested{'inetnum'}++;
is( $object->inetnum(), '10.0.0.1 - 10.0.0.255', 'inetnum properly parsed' );
$object->inetnum('192.168.0.1 - 192.168.0.255');
is( $object->inetnum(), '192.168.0.1 - 192.168.0.255', 'inetnum properly set' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), ['No remarks'], 'remarks properly parsed' );
$object->remarks('Added remarks');
is( $object->remarks()->[1], 'Added remarks', 'remarks properly added' );

# Test 'netname'
$tested{'netname'}++;
is( $object->netname(), 'EXAMPLENET-AP', 'netname properly parsed' );
$object->netname('EXAMPLENET-AP2');
is( $object->netname(), 'EXAMPLENET-AP2', 'netname properly set' );

# Test 'descr'
$tested{'descr'}++;
is_deeply( $object->descr(), ['Example net Pty Ltd'], 'descr properly parsed' );
$object->descr('Added descr');
is( $object->descr()->[1], 'Added descr', 'descr properly added' );

# Test 'country'
$tested{'country'}++;
is_deeply( $object->country(), ['FR'], 'country properly parsed' );
$object->country('Added country');
is( $object->country()->[1], 'Added country', 'country properly added' );

# Test 'geoloc'
$tested{'geoloc'}++;
is( $object->geoloc(), '[-90,90]', 'geoloc properly parsed' );
$object->geoloc('[-90,91]');
is( $object->geoloc(), '[-90,91]', 'geoloc properly set' );

# Test 'language'
$tested{'language'}++;
is_deeply( $object->language(), ['FR','EN'], 'language properly parsed' );
$object->language('ES');
is( $object->language()->[2], 'ES', 'language properly added' );

# Test 'org'
$tested{'org'}++;
is( $object->org(), 'ORG-MISC01-RIPE', 'org properly parsed' );
$object->org('ORG-MISC02-RIPE');
is( $object->org(), 'ORG-MISC02-RIPE', 'org properly set' );

# Test 'admin_c'
$tested{'admin_c'}++;
is_deeply( $object->admin_c(), ['FR123-AP'], 'admin_c properly parsed' );
$object->admin_c('Added admin_c');
is( $object->admin_c()->[1], 'Added admin_c', 'admin_c properly added' );

# Test 'tech_c'
$tested{'tech_c'}++;
is_deeply( $object->tech_c(), ['FR123-AP'], 'tech_c properly parsed' );
$object->tech_c('Added tech_c');
is( $object->tech_c()->[1], 'Added tech_c', 'tech_c properly added' );

# Test 'status'
$tested{'status'}++;
is( $object->status(), 'ALLOCATED PA', 'status properly parsed' );
$object->status('ALLOCATED PI');
is( $object->status(), 'ALLOCATED PI', 'status properly set' );

# Test 'mnt_by'
$tested{'mnt_by'}++;
is_deeply( $object->mnt_by(), ['MAINT-EXAMPLENET-AP'], 'mnt_by properly parsed' );
$object->mnt_by('MAINT2');
is( $object->mnt_by()->[1], 'MAINT2', 'mnt_by properly added' );

# Test 'mnt_lower'
$tested{'mnt_lower'}++;
is_deeply( $object->mnt_lower(), ['MAINL-EXAMPLENET-AP'], 'mnt_lower properly parsed' );
$object->mnt_lower('MAINT2');
is( $object->mnt_lower()->[1], 'MAINT2', 'mnt_lower properly added' );

# Test 'mnt_domains'
$tested{'mnt_domains'}++;
is_deeply( $object->mnt_domains(), ['DMNS-MNT'], 'mnt_domains properly parsed' );
$object->mnt_domains('MAINT2');
is( $object->mnt_domains()->[1], 'MAINT2', 'mnt_domains properly added' );

# Test 'mnt_irt'
$tested{'mnt_irt'}++;
is_deeply( $object->mnt_irt(), ['IRT-EXAMPLENET-AP'], 'mnt_irt properly parsed' );
$object->mnt_irt('IRT-EX2');
is( $object->mnt_irt()->[1], 'IRT-EX2', 'mnt_irt properly added' );

# Test 'changed'
$tested{'changed'}++;
is_deeply( $object->changed(), ['abc@examplenet.com 20101231'], 'changed properly parsed' );
$object->changed('Added changed');
is( $object->changed()->[1], 'Added changed', 'changed properly added' );

# Test 'source'
$tested{'source'}++;
is( $object->source(), 'RIPE', 'source properly parsed' );
$object->source('APNIC');
is( $object->source(), 'APNIC', 'source properly set' );

# Test 'notify'
$tested{'notify'}++;
is_deeply( $object->notify(), ['watcher@somewhere.net'], 'notify properly parsed' );
$object->notify('otherwatcher@somewhere.net');
is( $object->notify()->[1], 'otherwatcher@somewhere.net', 'notify properly added' );

# Test 'mnt_routes'
$tested{'mnt_routes'}++;
is_deeply( $object->mnt_routes(), ['RTES-MNT'], 'mnt_routes properly parsed' );
$object->mnt_routes('RTES-MNT2');
is( $object->mnt_routes()->[1], 'RTES-MNT2', 'mnt_routes properly added' );

# Common tests
do 't/common.pl';
ok( $tested{common_loaded}, "t/common.pl properly loaded" );
ok( !$@, "Can evaluate t/common.pl ($@)" );

__DATA__
inetnum:        10.0.0.1 - 10.0.0.255
remarks:        No remarks
netname:        EXAMPLENET-AP
descr:          Example net Pty Ltd
country:        FR
language:       FR
language:       EN
org:            ORG-MISC01-RIPE
geoloc:         [-90,90]
admin-c:        FR123-AP
tech-c:         FR123-AP
status:         ALLOCATED PA
mnt-by:         MAINT-EXAMPLENET-AP
mnt-lower:      MAINL-EXAMPLENET-AP
mnt-routes:     RTES-MNT
mnt-domains:    DMNS-MNT
mnt-irt:        IRT-EXAMPLENET-AP
changed:        abc@examplenet.com 20101231
source:         RIPE
notify:         watcher@somewhere.net

