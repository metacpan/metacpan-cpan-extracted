use 5.006;
use strict;
use warnings;
use Test::More;

#use Sub::Multi::Tiny::Util '*VERBOSE';
#BEGIN { $VERBOSE = 2; }

diag "Type::Tiny / Types::Standard";

#---------------------------------------------------------------
# Type constraints

{
    package main::my_multi;
    use Sub::Multi::Tiny qw(D:TypeParams $foo);
        # D:TypeParams -> use that dispatcher, which pulls in Type::Tiny
    use Types::Standard qw(Str Int);

    sub second :M(Int $foo) {
        return $foo + 42;
    }

    sub first :M(Str $foo) {
        return "Hello, $foo!";
    }

}

ok do { no strict 'refs'; defined *{"main::my_multi"}{CODE} }, 'my_multi() exists';

is my_multi("world"), 'Hello, world!', 'Str multi';
cmp_ok my_multi(0), '==', 42, 'Int multi';
cmp_ok my_multi(42), '==', 84, 'Int multi';

#---------------------------------------------------------------
# Where clauses

{
    package main::check_int;
    use Sub::Multi::Tiny qw(D:TypeParams $num);
    use Types::Standard qw(Str Int);

    sub small :M($num where { $_ < 10}) {
        return $num * 2;
    }

    sub large :M($num where { $_ >= 10}) {
        return "Howdy, $num!";
    }

}

ok do { no strict 'refs'; defined *{"main::check_int"}{CODE} }, 'check_int() exists';

cmp_ok check_int($_), '==', ($_ * 2), "small $_" foreach -10..9;
is check_int($_), "Howdy, $_!", "large $_" foreach 10..15;

#---------------------------------------------------------------
# Types + where clauses

{
    package main::check_2x2;    # Check a 2x2 grid: int or not, long or short
    use Sub::Multi::Tiny qw(D:TypeParams $num);
    use Types::Standard qw(Str Int);

    sub tt :M(Int $num where { length() >= 2 }) { 'tt' }
    sub tf :M(Int $num where { length() <  2 }) { 'tf' }
    sub ft :M(Str $num where { length() >= 2 }) { 'ft' }
    sub ff :M(Str $num where { length() <  2 }) { 'ff' }

}

ok do { no strict 'refs'; defined *{"main::check_2x2"}{CODE} }, 'check_2x2() exists';

{
    my $tt = '43';  # tt: int,     long
    my $tf = '4';   # tf: int,     short
    my $ft = 'xy';  # ft: not int, long
    my $ff = 'z';   # ff: not int, short

    is check_2x2($tf), 'tf', 'tf';
    is check_2x2($tt), 'tt', 'tt';
    is check_2x2($ff), 'ff', 'ff';
    is check_2x2($ft), 'ft', 'ft';
}

#---------------------------------------------------------------
# Arity only

{
    package main::check_arity;
    use Sub::Multi::Tiny qw(D:TypeParams $foo $bar);
    use Types::Standard qw(Str Int);

    sub second :M(Int $foo) {
        return $foo + 42;
    }

    sub first :M(Str $foo) {
        return "Hello, $foo!";
    }

}

ok do { no strict 'refs'; defined *{"main::check_arity"}{CODE} }, 'check_arity() exists';

is check_arity("world"), 'Hello, world!', 'Str multi';
cmp_ok check_arity(0), '==', 42, 'Int multi';
cmp_ok check_arity(42), '==', 84, 'Int multi';

done_testing;
