use v5.36;

use strict;
use warnings;
use Test::More;
use experimental qw< builtin >;
use builtin      qw< true false >;
use Scalar::Util qw< looks_like_number >;
use Types::Standard ':all';

use Switch::Back;
use Multi::Dispatch;

plan tests => 15;

package ID::Validator {
    sub new ($class)          { bless {}, $class }
    sub validate ($self, $id) { return $id =~ /^\d{5}$/ }
}

package NoOverload {
    sub new ($class) { bless {}, $class }
}

package OverloadedNum {
    sub new ($class) { bless {}, $class }
    use overload q{0+} => sub { return 42 }, fallback => 1;
}

package OverloadedStr {
    sub new ($class) { bless {}, $class }
    use overload q{""} => sub { return "a string" }, fallback => 1;
}

package OverloadedBoth {
    BEGIN { our @ISA = qw< OverloadedNum OverloadedStr > }
}


# Define new smartmatching behaviour on ID::Validator objects...
multi smartmatch ($value, ID::Validator $obj) {
    $obj->validate( $value );
}

# Allow smartmatch() to accept RHS objects that can convert to numbers...
multi smartmatch (Num $left, Overload['0+'] $right) {
    return next::variant($left, 0+$right);
}

# Allow smartmatch() to accept RHS objects that can convert to strings...
multi smartmatch (Str $left, Overload[q{""}] $right) {
    return next::variant($left, "$right");
}

# Change how smartmatch() compares a hash and an array
# (The standard behaviour is to match if ANY hash key is present in the array;
#  but here we change it so that ALL hash keys must be present)...

multi smartmatch (HASH $href, ARRAY $aref) {
    for my $key (keys %{$href}) {
        return false if !smartmatch($key, $aref);
    }
    return true;
}


# Test ID::Validator objects...
{
    state $VALID_ID = ID::Validator->new();

    my $id = 12345;
    given ($id) {
        when ($VALID_ID) { pass 'valid ID' }
        default          { fail 'invalid ID' }
    }

    $id = 654321;
    given ($id) {
        when ($VALID_ID) { fail 'false valid ID' }
        default          { pass 'invalid ID' }
    }
}


# Test (non-)overloaded objects...
{
    my $obj = NoOverload->new();

    ok !eval {
        given (42) {
            when ($obj) { fail 'unexpectedly matched non-overloaded obj'       }
            default     { fail 'unexpectedly did not match non-overloaded obj' }
        }
    } => 'num caused exception on non-overloaded obj';
    like $@, qr/^Smart matching an object breaks encapsulation/ => '\___ with correct error msg';

    ok !eval {
        given ('a string') {
            when ($obj) { fail 'unexpectedly matched non-overloaded obj'       }
            default     { fail 'unexpectedly did not match non-overloaded obj' }
        }
    } => 'string caused exception on non-overloaded obj';
    like $@, qr/^Smart matching an object breaks encapsulation/ => '\___ with correct error msg';
}

{
    my $numobj = OverloadedNum->new();

    given (42) {
        when ($numobj) { pass 'matched overloaded num'       }
        default        { fail 'did not match overloaded num' }
    }

    ok !eval {
        given ('a string') {
            when ($numobj) { fail 'unexpectedly matched overloaded num'       }
            default        { fail 'unexpectedly did not match overloaded num' }
        }
    } => 'string caused exception on overloaded num';
    like $@, qr/^Smart matching an object breaks encapsulation/ => '\___ with correct error msg';
}

{
    my $strobj = OverloadedStr->new();

    given ('a string') {
        when ($strobj) { pass 'matched overloaded str'       }
        default        { fail 'did not match overloaded str' }
    }

    given (42) {
        when ($strobj) { fail 'unexpectedly matched overloaded str'       }
        default        { pass 'did not match overloaded str' }
    }
}

{
    my $bothobj = OverloadedBoth->new();

    given ('a string') {
        when ($bothobj) { pass 'str matched overloaded both'       }
        default         { fail 'str did not match overloaded both' }
    }

    given (42) {
        when ($bothobj) { pass 'num matched overloaded both'       }
        default         { fail 'num did not match overloaded both' }
    }
}


# Test redefined HASH vs ARRAY behaviour (all hash keys must be in array)...
{
    my @array = 'a'..'z';

    given ({a=>1, b=>2, z=>26}) {
        when (@array) { pass 'all keys present (as expected)' }
        default       { fail 'unexpectedly did not match'     }
    }

    given ({a=>1, b=>2, zz=>2626}) {
        when (@array) { fail 'zz unexpectedly matched even though not all keys present' }
        default       { pass 'zz did not match (as expected)'     }
    }

}

done_testing();



