use strict;
use warnings;
use utf8;
use Test::More tests => 1;

{
    package Foo;

    use Number::Phone::JP;
    use Number::Phone::JP;

    sub invoke {
        my ( $self ) = @_;

        my $ins = Number::Phone::JP->new;
        my $result = $ins->set_number('03-5321-1111')->is_valid_number;
        return  $result;
    }
}


is(Foo::invoke(), 1);
