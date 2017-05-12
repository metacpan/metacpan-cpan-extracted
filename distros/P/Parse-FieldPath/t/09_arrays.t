use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;
use Test::MockObject;

use Parse::FieldPath qw/extract_fields/;

my $a_obj = Test::MockObject->new();
$a_obj->set_always( b => 'ab');
$a_obj->set_always( c => 'ac');
$a_obj->set_always( all_fields => [qw/b c/] );

my $b_obj = Test::MockObject->new();
$b_obj->set_always( b => 'bb');
$b_obj->set_always( c => 'bc');
$b_obj->set_always( all_fields => [qw/b c/] );

my $obj = Test::MockObject->new();
$obj->set_always( a => [$a_obj, $b_obj]);
$obj->set_always( all_fields => [qw/a/] );

cmp_deeply( extract_fields( $obj, 'a' ), { a => [ { b => 'ab', c => 'ac' }, { b => 'bb', c => 'bc' } ] } );
cmp_deeply( extract_fields( $obj, 'a/b' ), { a => [ { b => 'ab' }, { b => 'bb' } ] } );
cmp_deeply( extract_fields( $obj, 'a/c' ), { a => [ { c => 'ac' }, { c => 'bc' } ] } );
cmp_deeply( extract_fields( $obj, 'a(b,c)' ), { a => [ { b => 'ab', c => 'ac' }, { b => 'bb', c => 'bc' } ] } );
cmp_deeply( extract_fields( $obj, 'a/*' ), { a => [ { b => 'ab', c => 'ac' }, { b => 'bb', c => 'bc' } ] } );
