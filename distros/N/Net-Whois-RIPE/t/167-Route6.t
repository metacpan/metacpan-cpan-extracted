use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::Route6'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( route6 descr country origin org holes member_of inject aggr_mtd
    aggr_bndry export_comps components remarks notify mnt_lower mnt_routes mnt_by
    changed source);

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'route6'
$tested{'route6'}++;
is( $object->route6(), '2001:0DB8::/32', 'route properly parsed' );
$object->route6('2001:0DB8::0001/48');
is( $object->route6(), '2001:0DB8::0001/48', 'route properly set' );

# Test 'descr'
$tested{'descr'}++;
is_deeply( $object->descr(), ['route object for 192.168.1.0/24'], 'descr properly parsed' );
$object->descr('Added descr');
is( $object->descr()->[1], 'Added descr', 'descr properly added' );

# Test 'country'
$tested{'country'}++;
is( $object->country(), 'FR', 'country properly parsed' );
$object->country('GB');
is( $object->country(), 'GB', 'country properly set' );

# Test 'origin'
$tested{'origin'}++;
is( $object->origin(), 'AS1234', 'origin properly parsed' );
$object->origin('AS12');
is( $object->origin(), 'AS12', 'origin properly set' );

# Test 'pingable'
$tested{'pingable'}++;
is_deeply( $object->pingable(), ['10.0.0.1'], 'pingable properly parsed' );
$object->pingable('192.168.1.34');
is( $object->pingable()->[1], '192.168.1.34', 'pingable properly added' );

# Test 'ping_hdl'
$tested{'ping_hdl'}++;
is_deeply( $object->ping_hdl(), ['PING-EXAMPLECOM'], 'ping_hdl properly parsed' );
$object->ping_hdl('PING2-EXAMPLECOM');
is( $object->ping_hdl()->[1], 'PING2-EXAMPLECOM', 'ping_hdl properly added' );

# Test 'org'
$tested{'org'}++;
my $orgs = $object->org();
is( $orgs->[0], 'ORG-MISC01-RIPE', 'org properly parsed' );
$orgs = $object->org('ORG-MOD');
is( $orgs->[0], 'ORG-MISC01-RIPE', 'org array preserved' );
is( $orgs->[1], 'ORG-MOD',         'org properly added' );

# Test 'holes'
$tested{'holes'}++;
is_deeply( $object->holes(), ['192.168.1.23'], 'holes properly parsed' );
$object->holes('192.168.1.123');
is( $object->holes()->[1], '192.168.1.123', 'holes properly added' );

# Test 'member_of'
$tested{'member_of'}++;
is_deeply( $object->member_of(), ['RTES-SET01'], 'member_of properly parsed' );
$object->member_of('RTES-SET02');
is( $object->member_of()->[1], 'RTES-SET02', 'member_of properly added' );

# Test 'inject'
$tested{'inject'}++;
is_deeply( $object->inject(), ['RTR01'], 'inject properly parsed' );
$object->inject('RTR02');
is( $object->inject()->[1], 'RTR02', 'inject properly added' );

# Test 'aggr_mtd'
$tested{'aggr_mtd'}++;
is( $object->aggr_mtd(), 'AAAAAAA', 'aggr_mtd properly parsed' );
$object->aggr_mtd('ABABABAB');
is( $object->aggr_mtd(), 'ABABABAB', 'aggr_mtd properly set' );

# Test 'aggr_bndry'
$tested{'aggr_bndry'}++;
is( $object->aggr_bndry(), 'BBBBBBB', 'aggr_bndry properly parsed' );
$object->aggr_bndry('BCBCBCBCBC');
is( $object->aggr_bndry(), 'BCBCBCBCBC', 'aggr_bndry properly added' );

# Test 'export_comps'
$tested{'export_comps'}++;
is( $object->export_comps(), 'CCCCCCC', 'export_comps properly parsed' );
$object->export_comps('CDCDCDCDCD');
is( $object->export_comps(), 'CDCDCDCDCD', 'export_comps properly added' );

# Test 'components'
$tested{'components'}++;
is( $object->components(), 'DDDDDDD', 'components properly parsed' );
$object->components('DEDEDEDEDE');
is( $object->components(), 'DEDEDEDEDE', 'components properly added' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), ['No remark'], 'remarks properly parsed' );
$object->remarks('Added remarks');
is( $object->remarks()->[1], 'Added remarks', 'remarks properly added' );

# Test 'notify'
$tested{'notify'}++;
is_deeply( $object->notify(), ['watcher@somewhere.com'], 'notify properly parsed' );
$object->notify('watcher2@somewhere.com');
is( $object->notify()->[1], 'watcher2@somewhere.com', 'notify properly added' );

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

# Test 'mnt_routes'
$tested{'mnt_routes'}++;
is_deeply( $object->mnt_routes(), ['MAINT-EXAMPLECOM'], 'mnt_routes properly parsed' );
$object->mnt_routes('MAINT2-EXAMPLECOM');
is( $object->mnt_routes()->[1], 'MAINT2-EXAMPLECOM', 'mnt_routes properly added' );

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

# Common tests
do 't/common.pl';
ok( $tested{common_loaded}, "t/common.pl properly loaded" );
ok( !$@, "Can evaluate t/common.pl ($@)" );

__DATA__
route6:         2001:0DB8::/32
descr:          route object for 192.168.1.0/24
country:        FR
origin:         AS1234
org:            ORG-MISC01-RIPE
holes:          192.168.1.23
member_of:      RTES-SET01
inject:         RTR01
aggr_mtd:       AAAAAAA
aggr_bndry:     BBBBBBB
export_comps:   CCCCCCC
components:     DDDDDDD
remarks:        No remark
notify:         watcher@somewhere.com
mnt-by:         MAINT-EXAMPLECOM
mnt-lower:      MAINT-EXAMPLECOM
mnt-routes:     MAINT-EXAMPLECOM
pingable:       10.0.0.1
ping-hdl:       PING-EXAMPLECOM
changed:        abc@somewhere.com 20120131
source:         RIPE


