package StoredObjectCommonTests;

use Test::More;
use Pangloss::StoredObject::Common;

sub test {
    my $class = shift;
    my $obj   = shift;

    is( $obj->name(1), $obj,     'name(set)' );
    is( $obj->name, 1,           'name(get)' );

    is( $obj->creator(2), $obj,  'creator(set)' );
    is( $obj->creator, 2,        'creator(get)' );

    is( $obj->date(3), $obj,     'date(set)' );
    is( $obj->date, 3,           'date(get)' );

    is( $obj->notes(4), $obj,    'notes(set)' );
    is( $obj->notes, 4,          'notes(get)' );

    my $obj2 = $obj->class->new;
    if (ok( $obj2->copy( $obj ), 'copy' )) {
	is( keys %{ $obj2 }, keys %{ $obj }, 'same number keys after copy' );
    }

    isa_ok( $obj->clone(), $obj->class, 'clone' );

    return $obj;
}

1;
