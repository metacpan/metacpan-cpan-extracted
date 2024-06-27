use 5.036;
use warnings;
use Test2::V0;

plan tests => 10;

use Switch::Right;
use Scalar::Util qw< looks_like_number >;

# Class with no SMARTMATCH handler...
package NoStyle {
    sub new ($class, $strval, $numval) {
        bless { strval => $strval, numval => $numval }, $class }

    # Doesn't define a SMARTMATCH method
}


# Old style class with SMARTMATCH handler...
package OldStyle {
    sub new ($class, $strval, $numval) {
        bless { strval => $strval, numval => $numval }, $class }

    sub SMARTMATCH ($right, $left) {
        ::looks_like_number($left)
            ? $left == $right->{numval}
            : $left eq $right->{strval};
    }
}


# New style class with SMARTMATCH handler...
use Object::Pad;
class NewStyle {
    field $strval :param;
    field $numval :param;

    method SMARTMATCH ($left) {
        ::looks_like_number($left)
            ? $left == $numval
            : $left eq $strval;
    }
}

# New style class with multiply dispatched SMARTMATCH handler...
class MultiStyle {
    use Multi::Dispatch;
    use Types::Standard ':all';

    field $strval :param;
    field $numval :param;

    multimethod SMARTMATCH (Num $left) { $left == $numval }
    multimethod SMARTMATCH (Str $left) { $left eq $strval }
}


# New style class with no SMARTMATCH handler, but a local smartmatch() handler...
class LocalStyle {
    field $strval :param :reader;
    field $numval :param :reader;
}

use Multi::Dispatch;
use Types::Standard ':all';
multi smartmatch(Num $left, LocalStyle $right) { $left == $right->numval }
multi smartmatch(Str $left, LocalStyle $right) { $left eq $right->strval }


# Test them all...

my $nst = NoStyle->new('no style', 1);
my $old = OldStyle->new('old style', 1);
my $new = NewStyle->new(strval=>'new style', numval=>2);
my $mlt = MultiStyle->new(strval=>'multi style', numval=>3);
my $loc = LocalStyle->new(strval=>'local style', numval=>4);

ok dies { smartmatch("no style", $nst) };
ok dies { smartmatch(         1, $nst) };

ok smartmatch("old style", $old);
ok smartmatch(          1, $old);

ok smartmatch("new style", $new);
ok smartmatch(          2, $new);

ok smartmatch("multi style", $mlt);
ok smartmatch(            3, $mlt);

ok smartmatch("local style", $loc);
ok smartmatch(            4, $loc);


done_testing();
