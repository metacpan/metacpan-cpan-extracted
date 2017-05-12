use strict;
use warnings;
use utf8;
use Test::More tests => 1;

{
    package Foo;

    use Number::ZipCode::JP;
    use Number::ZipCode::JP;

    sub invoke {
        my ( $self ) = @_;

        my $ins = Number::ZipCode::JP->new;
        my $result = $ins->set_number('1000001')->is_valid_number;
        return  $result;
    }
}


is(Foo::invoke(), 1);
