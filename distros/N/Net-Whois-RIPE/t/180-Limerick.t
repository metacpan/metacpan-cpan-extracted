use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::Limerick'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( limerick descr text admin_c author remarks notify mnt_by
    changed source );

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'limerick'
$tested{'limerick'}++;
is( $object->limerick(), 'LIMERICK-DEMO', 'limerick properly parsed' );
$object->limerick('LIMERICK2-DEMO');
is( $object->limerick(), 'LIMERICK2-DEMO', 'limerick properly set' );

# Test 'descr'
$tested{'descr'}++;
is_deeply( $object->descr(), ['Limerick example'], 'descr properly parsed' );
$object->descr('Added descr');
is( $object->descr()->[1], 'Added descr', 'descr properly added' );

# Test 'text'
$tested{'text'}++;
is( $object->text()->[0], 'This won\'t be an ode',  'text[0] properly parsed' );
is( $object->text()->[4], 'I should have used POD', 'text[4] properly parsed' );
$object->text('Added text');
is( $object->text()->[5], 'Added text', 'text properly added' );

# Test 'admin_c'
$tested{'admin_c'}++;
is_deeply( $object->admin_c(), ['ADM-CTCT'], 'admin_c properly parsed' );
$object->admin_c('ADM2-CTCT');
is( $object->admin_c()->[1], 'ADM2-CTCT', 'admin_c properly added' );

# Test 'author'
$tested{'author'}++;
is_deeply( $object->author(), ['GEEK-01'], 'author properly parsed' );
$object->author('GEEK-02');
is( $object->author()->[1], 'GEEK-02', 'author properly added' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), ['No remarks'], 'remarks properly parsed' );
$object->remarks('Added remarks');
is( $object->remarks()->[1], 'Added remarks', 'remarks properly added' );

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
limerick:       LIMERICK-DEMO
descr:          Limerick example
text:           This won't be an ode
text:           I'm only here to code
text:           Please don't read this mess
text:           Ugly I confess
text:           I should have used POD
admin-c:        ADM-CTCT
author:         GEEK-01
remarks:        No remarks
notify:         watcher@somewhere.com
mnt-by:         MAINT-EXAMPLECOM
changed:        abc@somewhere.com 20120131
source:         RIPE

