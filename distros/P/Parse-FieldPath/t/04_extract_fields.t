use strict;
use warnings;

use Test::More tests => 12;
use Test::Deep;
use Test::MockObject;

use Parse::FieldPath qw/extract_fields/;

eval { extract_fields("") };
like( $@, qr/extract_fields needs an object/ );

my $obj = Test::MockObject->new();
$obj->set_always( a => 'x' );
$obj->set_always( b => 'y' );
$obj->set_always( all_fields => [qw/a b x/] );

my $obj2 = Test::MockObject->new();
$obj2->set_always( a => 1 );
$obj2->set_always( b => 2 );
$obj2->set_always( all_fields => [qw/a b/] );

$obj->set_always( x => $obj2 );

cmp_deeply( extract_fields( $obj, '' ), { a => 'x', b => 'y', x => { a => 1, b => 2 } } );
cmp_deeply( extract_fields( $obj, '*' ), { a => 'x', b => 'y', x => { a => 1, b => 2 } } );

cmp_deeply( extract_fields( $obj, 'a' ), { a => 'x' } );
cmp_deeply( extract_fields( $obj, 'a,b' ), { a => 'x', b => 'y' } );
cmp_deeply( extract_fields( $obj, 'x/a' ), { x => { a => 1 } } );
cmp_deeply( extract_fields( $obj, 'x(a)' ), { x => { a => 1 } } );
cmp_deeply( extract_fields( $obj, 'x(a,b)' ), { x => { a => 1, b => 2 } } );
cmp_deeply( extract_fields( $obj, 'a/x' ), { a => undef } );
cmp_deeply( extract_fields( $obj, 'x' ), { x => { a => 1, b => 2 } } );

cmp_deeply( extract_fields( $obj, 'x/a,x/b' ), { x => { a => 1, b => 2 } } );
cmp_deeply( extract_fields( $obj, 'x/*' ), { x => { a => 1, b => 2 } } );
