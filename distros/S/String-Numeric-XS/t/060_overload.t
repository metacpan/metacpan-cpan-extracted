#!perl -w

use strict;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 29;

BEGIN {
    use_ok('String::Numeric', ':all');
}

{
    package MyString;
    use overload '""' => sub { ${ $_[0] } }, fallback => 1;
    sub new {
        @_ == 2 || die(q/Usage: MyString->new($value)/);
        my ($class, $value) = @_;
        return bless(\$value, $class);
    }
}

my @SUBNAMES = qw(
    is_float
    is_decimal
    is_int
    is_int8
    is_int16
    is_int32
    is_int64
    is_int128
    is_uint
    is_uint8
    is_uint16
    is_uint32
    is_uint64
    is_uint128
);

sub TRUE  () { !!1 }
sub FALSE () { !!0 }

sub test_subname ($$$) {
    my ($subname, $test, $expected) = @_;
    my $name = "$subname(MyString->new(@{[ defined $test ? qq['$test'] : 'undef' ]}))";
    my $code = __PACKAGE__->can($subname) || die(qq/No such subname '$subname'/);
    is $code->(MyString->new($test)), $expected, $name;
}

test_subname($_, "0",  TRUE ) for @SUBNAMES;
test_subname($_, "01", FALSE) for @SUBNAMES;

