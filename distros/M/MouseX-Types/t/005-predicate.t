use strict;
use warnings;
use Test::More tests => 12;

use MouseX::Types::Mouse qw(is_Int is_ArrayRef);

BEGIN{
    package MyTypes;
    use MouseX::Types -declare => ['ArrayRef2d'];

    subtype ArrayRef2d, as 'ArrayRef[ArrayRef]';
}

MyTypes->import('is_ArrayRef2d');

ok is_Int(10);
ok is_Int('42');
ok!is_Int(3.14);
ok!is_Int(undef);

ok is_ArrayRef([]);
ok is_ArrayRef([10]);
ok!is_ArrayRef(undef);
ok!is_ArrayRef({});

ok is_ArrayRef2d([[]]);
ok!is_ArrayRef2d([10]);
ok!is_ArrayRef2d(undef);
ok!is_ArrayRef2d({});

