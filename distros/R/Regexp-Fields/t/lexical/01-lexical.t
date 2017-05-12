
BEGIN {
    use FindBin qw($Bin);
    require "$Bin/../test.pl";
    plan(tests => 11);
}

use strict;
use Regexp::Fields qw(my);

my $rx = qr/(?<x> f)/;

ok !defined($x),   '!defined($x)';
ok "foo" =~ /$rx/, "'foo' =~ /$rx/";
is $x, "f",        '(my) $x eq "f"';

{
    "Foo" =~ /(?<x> F)/;
    is $x, "F", '(nested my) $x eq "F"';
}

is $x, "f", '(outer my) $x eq "f"';

"bar" =~ /(?<y> b)/;
is $1, "b",  '$1 eq "b"';
is $y, $1,   '$y eq $1';
isnt $x, $1, '$x ne $1';
is $x, 'f',  '$x eq "f"';

{
    no Regexp::Fields qw(my);
    "Foo" =~ /(?<x> F)/;

    is $&{x}, "F",  '$&{x} eq "F"';
    isnt $x, $&{x}, '$&{x} ne $x (!)';
}
