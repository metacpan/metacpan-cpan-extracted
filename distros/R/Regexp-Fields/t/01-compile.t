
BEGIN {
    use FindBin qw($Bin);
    require "$Bin/test.pl";
    plan(tests => 11);
}

use Regexp::Fields;

#
# compile a simple regex
#

$rx = eval 'qr/(?<x> .)/';

ok $rx, "compiled qr/$rx/";
is ref($rx), 'Regexp', 'ref($rx) eq "Regexp"';
like "x", qr/$rx/, '"x" =~ /$rx/';


#
# recognize a broken one
#

foreach (qw{ (?<x) (?<x> (?<x->.) }) {
    fail_ok qq{ qr/$_/ }, "qr/$_/ fails";
}

{
    use warnings;
    my $warning;
    local $SIG{__WARN__} = sub { $warning = shift };
    ok qr/(?<x>) $rx/, 'rx with duplicates compiles';
    ok $warning, 'but generates a warning';
}

#
# handle /x
#

$rx = eval "qr/(?<x> # diddle\n x)/x";

ok $rx,          'compile extended pattern with comment/newline';
ok "x" =~ /$rx/, '"x" =~ /$rx/';
is $1, 'x',      '$1 eq "x"';

