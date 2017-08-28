use strict;
use warnings;

use Test::More;

use PPR;

my $neg = 0;
while (my $str = <DATA>) {
           if ($str =~ /\A# TH[EI]SE? SHOULD MATCH/) { $neg = 0;       next; }
        elsif ($str =~ /\A# TH[EI]SE? SHOULD FAIL/)  { $neg = 1;       next; }
        elsif ($str !~ /^####\h*\Z/m)                { $str .= <DATA>; redo; }

        $str =~ s/\s*^####\h*\Z//m;

        if ($neg) {
            ok $str !~ m/\A (?&PerlOWS) (?&PerlStatement) (?&PerlOWS) \Z $PPR::GRAMMAR/xo
                => "FAIL:\n$str";
        }
        else {
            ok $str =~ m/\A (?&PerlOWS) (?&PerlStatement) (?&PerlOWS) \Z $PPR::GRAMMAR/xo
                => "MATCH:\n$str";
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
    s/${\<<FOO}/<<"BAR"/e;
    foo
FOO
    say ${\<<"BAZ"}
    'baz'
BAZ
    bar
BAR
####
    s/foo/<<"BAR"/e
    bar ${\<<"BAZ"} bar
    baz
BAZ
    bar
BAR
####
    s/foo/<<"BAR"/eieio
    bar ${\<<"BAZ"} bar
    baz
BAZ
    bar
BAR
####
    s/foo/${\<<"BAR"}/e
    bar ${\<<"BAZ"} bar
    baz
BAZ
    bar
BAR
####
