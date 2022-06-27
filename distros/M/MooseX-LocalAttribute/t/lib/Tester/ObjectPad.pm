package Tester::ObjectPad;
use Object::Pad;

class Tester::ObjectPad {
    has $hashref : accessor = { key => 'value' };
    has $string : accessor = 'string';

    method change_hashref {
        my ( $key, $val ) = @_;

        $hashref->{$key} = $val;
    }
}

1;
