package Guarded;

# Types that the code itself checks: guards of Type::Tiny, and the checkers of Type::Params.

use 5.036;
use warnings FATAL => q{all};

use Type::Params    qw{compile validate};
use Types::Standard qw{ArrayRef HashRef InstanceOf Int Optional Str assert_Int is_HashRef};

# Handing @_ to a checker without unpacking it first is the idiom that these subs exist to test.
## no critic (Subroutines::RequireArgUnpacking)

sub guarded {
    my ( $count, $opts, $list, $thing ) = @_;
    assert_Int($count);
    is_HashRef($opts) or die "opts must be a hash reference\n";
    ArrayRef->assert_valid($list);
    ( InstanceOf ['Foo'] )->check($thing) or die "thing must be a Foo\n";
    return $count;
}

sub compiled {
    state $check = compile( Int, Optional [Str] );
    my ( $x, $y ) = $check->(@_);
    return [ $x, $y ];
}

sub validated {
    my ( $x, $y ) = validate( \@_, Int, Str );
    return [ $x, $y ];
}

sub checker {
    my (@args) = @_;
    return @args;
}

sub via_plain_checker {
    my ( $x, %rest ) = checker(@_);
    return [ $x, \%rest ];
}

1;
