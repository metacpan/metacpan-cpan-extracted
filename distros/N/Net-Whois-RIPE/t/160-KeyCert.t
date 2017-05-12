use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::KeyCert'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( key_cert method owner fingerpr remarks org certif notify
    admin_c tech_c mnt_by changed source);

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'key_cert'
$tested{'key_cert'}++;
is( $object->key_cert(), 'PGPKEY-4E17C667', 'key_cert properly parsed' );
$object->key_cert('PGPKEY-4E17C668');
is( $object->key_cert(), 'PGPKEY-4E17C668', 'key_cert properly set' );

# Test 'method'
$tested{'method'}++;
is( $object->method(), 'PGP', 'method properly parsed' );
$object->method('PGP2');
is( $object->method(), 'PGP2', 'method properly set' );

# Test 'owner'
$tested{'owner'}++;
is_deeply( $object->owner(), ['KEY-OWNER Arhuman'], 'owner properly parsed' );
$object->owner('Added owner');
is( $object->owner()->[1], 'Added owner', 'owner properly added' );

# Test 'fingerpr'
$tested{'fingerpr'}++;
is( $object->fingerpr(), '8B33 C463 2555 F669 EEEB  105A 68BA 54F3 4E17 C667', 'fingerpr properly parsed' );
$object->fingerpr('8B33 C463 2555 F669 EEEB  105A 68BA 54F3 4E17 FFFF');
is( $object->fingerpr(), '8B33 C463 2555 F669 EEEB  105A 68BA 54F3 4E17 FFFF', 'fingerpr properly set' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), ['Arhuman\'s key'], 'remarks properly parsed' );
$object->remarks('Added remarks');
is( $object->remarks()->[1], 'Added remarks', 'remarks properly added' );

# Test 'certif'
$tested{'certif'}++;
is( $object->certif()->[0],  '-----BEGIN PGP PUBLIC KEY BLOCK-----',                             'certif[0] properly parsed' );
is( $object->certif()->[3],  'mQGiBERfPw4RBACuTDkgkfCGFAgKeShm0FgozRsLkjccsV/Ua5Y0fs6Ay8agueTj', 'certif[3] properly parsed' );
is( $object->certif()->[28], '=opxg',                                                            'certif[28] properly parsed' );
$object->certif('Added certif');
is( $object->certif()->[30], 'Added certif', 'certif properly added' );

# Test 'org'
$tested{'org'}++;
is_deeply( $object->org(), ['ORG-MISC01-RIPE'], 'org properly parsed' );
$object->org('ORG-MISC02-RIPE');
is( $object->org()->[1], 'ORG-MISC02-RIPE', 'org properly added' );

# Test 'notify'
$tested{'notify'}++;
is_deeply( $object->notify(), ['watcher@somewhere.com'], 'notify properly parsed' );
$object->notify('watcher@elsewhere.com');
is( $object->notify()->[1], 'watcher@elsewhere.com', 'notify properly added' );

# Test 'mnt_by'
$tested{'mnt_by'}++;
is_deeply( $object->mnt_by(), ['MAINT-EXAMPLECOM'], 'mnt_by properly parsed' );
$object->mnt_by('MAINT2-EXAMPLECOM');
is( $object->mnt_by()->[1], 'MAINT2-EXAMPLECOM', 'mnt_by properly added' );

# Test 'admin_c'
$tested{'admin_c'}++;
is_deeply( $object->admin_c(), ['FR123-AP'], 'admin_c properly parsed' );
$object->admin_c('FR456-AP');
is( $object->admin_c()->[1], 'FR456-AP', 'admin_c properly added' );

# Test 'tech_c'
$tested{'tech_c'}++;
is_deeply( $object->tech_c(), ['FR123-AP'], 'tech_c properly parsed' );
$object->tech_c('FR456-AP');
is( $object->tech_c()->[1], 'FR456-AP', 'tech_c properly added' );

# Test 'changed'
$tested{'changed'}++;
is_deeply( $object->changed(), ['abc@somewhere.com 20120131'], 'changed properly parsed' );
$object->changed('def@somewhere.com 20120228');
is( $object->changed()->[1], 'def@somewhere.com 20120228', 'changed properly added' );

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
key-cert:       PGPKEY-4E17C667
method:         PGP
owner:          KEY-OWNER Arhuman
fingerpr:       8B33 C463 2555 F669 EEEB  105A 68BA 54F3 4E17 C667
remarks:        Arhuman's key
certif:         -----BEGIN PGP PUBLIC KEY BLOCK-----
certif:         Version: GnuPG v1.4.11 (GNU/Linux)
certif:         
certif:         mQGiBERfPw4RBACuTDkgkfCGFAgKeShm0FgozRsLkjccsV/Ua5Y0fs6Ay8agueTj
certif:         6uflVIuPW+KClwU0MINpRfEDK48qDXmiqZ10dg3TC0PwsiS99brMXeJWt09u6tq1
certif:         4gdOVQwOGYsUjvN7bXzQt1lEpsT/BsO753/aLsBXFO4qVAu4hO5VffsMBwCgx0tX
certif:         4d6f7xMSGXLkonilzdlFI7UEAKfBgbbdDSkeNOieyOnHeEOqAdiXY/KCWY6h99y1
certif:         DFwDEd/VDdfKdBnPY+TJhfu6ZhMZTeBjBeldySEuMBG4OY6yPqUdU8NsmpVWpw79
certif:         MxMFTwfkDwwf0cRm1hhhAa9r04Jx/6uXJOI80w30WdEAzsadIZ2H0zqES+h+7PPR
certif:         VthyA/9sT9vPqP6/7RSWKGSrOn1BzFcttosvqCnW4Haf3/2J2ZSDq0AUhmciBMCN
certif:         0CtULwsq3rM09sApQV2pMu4epFfGfGzP66rXHK8O31vt2qo2aGxviUilctd8IWqc
certif:         GPk7PEi03C4aMD8u4iDF8P/Rk+PoqdVkhxh7bHVkHcZC8KSnmLQqQXJuYXVkIEFz
certif:         c2FkIChBcmh1bWFuKSA8YXJodW1hbkBnbWFpbC5jb20+iGAEExECACAFAkRfPw4C
certif:         GwMGCwkIBwMCBBUCCAMEFgIDAQIeAQIXgAAKCRBoulTzThfGZxoKAJ9p7KoNORrN
certif:         KtudYOQDao7I8miBvgCfTykI3TRPfpZM1lEu774SLgGVbsu5Ag0ERF8/ExAIAJpH
certif:         zU4mXML6zXuog9DdlWKR0XVx7/rviKRWn4+uRJkRGjrBtaF+VcLN9eDcUtL85npB
certif:         s8lCcA6HP0raWAYDJ0Np0SWE6Vh2CfcpZxb0rF9pRBjct9TzHrJbEdFx3TgAzVkf
certif:         CcOP1ZeU5s4n6CxH6W7bt5JP0TW3JFzdD4z3wtqmyWdoumjKLmLeJ3Q2wuceMaDk
certif:         w/8ek/PnSjvkBLbsP+RnCG85Wi7bkMzRX1QlSeXpeAVvmlAZSITiBwYVJJS93NIR
certif:         XrYRt6In1YuO7aXR1OXWg7qJM87o32E3ePPBr9cmryhnqcCOfUtQ/CpJtU5mol3R
certif:         C11fH1fiYr7Q2aX0hNcAAwUH/1oSud753HAzI8oOzOQ9qv2mziAnDsTU15WmPDEO
certif:         Jk9Hme60620eIb1RP91Ub5liZRiHRniO1vxvbQC7jyePPIxV5QoUFGt8ZPCVeh4t
certif:         uYVeAztWQGu54xwFWtJB6EH6pti9xThCApyvB+kwdo/ZlJdBH65XLQ02Bfjf9pV3
certif:         ZwElvpYcd0OxC2o0Ph9xszJujVu+DfbvBlbQ9Uc/p6gXnV6W0KB2PrCXRZOSeHEb
certif:         mDzP6XgKC1OG5hX44VaeOwiDpZyZD+bSJQyuxWK+vy0oiuX1IFtwb2BxdKbkeKZ5
certif:         d1HrcwJXxbNM3LiOFaXGC3R/IQSJNktIupsjySSobGwq2FGISQQYEQIACQUCRF8/
certif:         EwIbDAAKCRBoulTzThfGZ/VlAKCjxj+twQmuEyfNc8GzXTAelPTqCgCdES0n233p
certif:         nfIPaiJtK2pPOSViTGk=
certif:         =opxg
certif:         -----END PGP PUBLIC KEY BLOCK-----
org:            ORG-MISC01-RIPE
notify:         watcher@somewhere.com
mnt-by:         MAINT-EXAMPLECOM
admin-c:        FR123-AP
tech-c:         FR123-AP
changed:        abc@somewhere.com 20120131
source:         RIPE

