use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::Inet6Num'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( inet6num netname descr country admin_c tech_c
    status remarks notify mnt_by mnt_lower mnt_routes mnt_domains mnt_irt changed source);
can_ok $object, qw( mnt_irt );

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'inet6num'
$tested{'inet6num'}++;
is( $object->inet6num(), '2001:0DB8::/32', 'inet6num properly parsed' );
$object->inet6num('2001:0DB9::/32');
is( $object->inet6num(), '2001:0DB9::/32', 'inet6num properly set' );

# Test 'netname'
$tested{'netname'}++;
is( $object->netname(), 'EXAMPLENET-AP', 'netname properly parsed' );
$object->netname('EXAMPLE2');
is( $object->netname(), 'EXAMPLE2', 'netname properly set' );

# Test 'descr'
$tested{'descr'}++;
is_deeply( $object->descr(), ['Example net Pty Ltd'], 'descr properly parsed' );
$object->descr('Added descr');
is( $object->descr()->[1], 'Added descr', 'descr properly added' );

# Test 'country'
$tested{'country'}++;
is_deeply( $object->country(), ['AP'], 'country properly parsed' );
$object->country('FR');
is( $object->country()->[1], 'FR', 'country properly added' );

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

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), ['Example subnet'], 'remarks properly parsed' );
$object->remarks('Second remark');
is( $object->remarks()->[1], 'Second remark', 'remarks properly added' );

# Test 'admin_c'
$tested{'admin_c'}++;
is_deeply( $object->admin_c(), ['FR123-AP'], 'admin_c properly parsed' );
$object->admin_c('FR345-APF');
is( $object->admin_c()->[1], 'FR345-APF', 'admin_c properly added' );

# Test 'tech_c'
$tested{'tech_c'}++;
is_deeply( $object->tech_c(), ['FR123-AP'], 'tech_c properly parsed' );
$object->tech_c('FR345-AP');
is( $object->tech_c()->[1], 'FR345-AP', 'tech_c properly added' );

# Test 'status'
$tested{'status'}++;
is( $object->status(), 'ALLOCATED PORTABLE', 'status properly parsed' );
$object->status('ASSIGNED PORTABLE');
is( $object->status(), 'ASSIGNED PORTABLE', 'status properly set' );

# Test 'notify'
$tested{'notify'}++;
is_deeply( $object->notify(), ['abc@examplenet.com'], 'notify properly parsed' );
$object->notify('efg@examplenet.com');
is( $object->notify()->[1], 'efg@examplenet.com', 'notify properly added' );

# Test 'mnt_by'
$tested{'mnt_by'}++;
is_deeply( $object->mnt_by(), ['MAINT-EXAMPLENET-AP'], 'mnt_by properly parsed' );
$object->mnt_by('MAINT2-EXAMPLENET-AP');
is( $object->mnt_by()->[1], 'MAINT2-EXAMPLENET-AP', 'mnt_by properly added' );

# Test 'mnt_lower'
$tested{'mnt_lower'}++;
is_deeply( $object->mnt_lower(), ['MAINT-EXAMPLENET-AP'], 'mnt_lower properly parsed' );
$object->mnt_lower('MAINT2-EXAMPLENET-AP');
is( $object->mnt_lower()->[1], 'MAINT2-EXAMPLENET-AP', 'mnt_lower properly added' );

# Test 'mnt_routes'
$tested{'mnt_routes'}++;
is_deeply( $object->mnt_routes(), ['MAINT-EXAMPLENET-AP'], 'mnt_routes properly parsed' );
$object->mnt_routes('MAINT2-EXAMPLENET-AP');
is( $object->mnt_routes()->[1], 'MAINT2-EXAMPLENET-AP', 'mnt_routes properly added' );

# Test 'mnt_irt'
$tested{'mnt_irt'}++;
is_deeply( $object->mnt_irt(), ['IRT-EXAMPLENET-AP'], 'mnt_irt properly parsed' );
$object->mnt_irt('MAINT2-EXAMPLENET-AP');
is( $object->mnt_irt()->[1], 'MAINT2-EXAMPLENET-AP', 'mnt_irt properly added' );

# Test 'mnt_domains'
$tested{'mnt_domains'}++;
is_deeply( $object->mnt_domains(), ['MAINT-EXAMPLENET-AP'], 'mnt_domains properly parsed' );
$object->mnt_domains('MAINT2-EXAMPLENET-AP');
is( $object->mnt_domains()->[1], 'MAINT2-EXAMPLENET-AP', 'mnt_domains properly added' );

# Test 'changed'
$tested{'changed'}++;
is_deeply( $object->changed(), ['abc@examplenet.com 20101231'], 'changed properly parsed' );
$object->changed('abc@examplenet.com 20121231');
is( $object->changed()->[1], 'abc@examplenet.com 20121231', 'changed properly added' );

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
inet6num:    2001:0DB8::/32
remarks:     Example subnet
netname:     EXAMPLENET-AP
descr:       Example net Pty Ltd
country:     AP
admin-c:     FR123-AP
tech-c:      FR123-AP
status:      ALLOCATED PORTABLE
notify:      abc@examplenet.com
geoloc:      [-90,90]
language:    FR
language:    EN
mnt-by:      MAINT-EXAMPLENET-AP
mnt-lower:   MAINT-EXAMPLENET-AP
mnt-routes:  MAINT-EXAMPLENET-AP
mnt-domains: MAINT-EXAMPLENET-AP
mnt-irt:     IRT-EXAMPLENET-AP
changed:     abc@examplenet.com 20101231
source:      RIPE

