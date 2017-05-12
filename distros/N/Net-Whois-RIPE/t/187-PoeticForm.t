use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::PoeticForm'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');
can_ok $object, $object->attributes('optional');

# Test 'poetic_form'
$tested{'poetic_form'}++;
is( $object->poetic_form(), 'POEM-EXAMPLE', 'poetic_form properly parsed' );
$object->poetic_form('POEM-EXAMPLE2');
is( $object->poetic_form(), 'POEM-EXAMPLE2', 'poetic_form properly set' );

# Test 'remarks'
$tested{'remarks'}++;
is_deeply( $object->remarks(), ['I hope nobody ever read this text'], 'remarks properly parsed' );
$object->remarks('Added remark');
is( $object->remarks()->[1], 'Added remark', 'remarks properly added' );

# Test 'descr'
$tested{'descr'}++;
is_deeply( $object->descr(), [ 'line 1 is funny', 'line 2 is easy', 'line 3 is boring', 'I\'d stick with coding', '' ], 'descr properly parsed' );
$object->descr('Added descr');
is( $object->descr()->[5], 'Added descr', 'descr properly added' );

# Test 'admin_c'
$tested{'admin_c'}++;
is_deeply( $object->admin_c(), ['CPNY-ADM'], 'admin_c properly parsed' );
$object->admin_c('CPNY-ADM2');
is( $object->admin_c()->[1], 'CPNY-ADM2', 'admin_c properly added' );

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

# Test 'changed'
$tested{'changed'}++;
is_deeply( $object->changed(), ['arhuman@gmail.com 20120623'], 'changed properly parsed' );
$object->changed('arhuman@gmail.com 20120624');
is( $object->changed()->[1], 'arhuman@gmail.com 20120624', 'changed properly added' );

# Test 'source'
$tested{'source'}++;
is( $object->source(), 'RIPE #Filtered', 'source properly parsed' );
$object->source('APNIC');
is( $object->source(), 'APNIC', 'source properly set' );

# Common tests
do 't/common.pl';
ok( $tested{common_loaded}, "t/common.pl properly loaded" );
ok( !$@, "Can evaluate t/common.pl ($@)" );

__DATA__
poetic_form:    POEM-EXAMPLE
remarks:        I hope nobody ever read this text
descr:          line 1 is funny
descr:          line 2 is easy
descr:          line 3 is boring
descr:          I'd stick with coding
descr:           
admin-c:        CPNY-ADM
mnt-by:         CPNY-MNT
notify:         CPNY-MNT
changed:        arhuman@gmail.com 20120623
source:         RIPE #Filtered

