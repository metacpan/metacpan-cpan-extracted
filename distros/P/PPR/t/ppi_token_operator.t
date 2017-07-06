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
            ok $str !~ m/\A \s* (?&PerlDocument) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
        else {
            ok $str =~ m/\A \s* (?&PerlDocument) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
bareword x 3;
####
bareword x3;
####
$a->package x3;
####
sort { $a->package cmp $b->package } ();
####
c->d x 3;
####
1 x 3;
####
"y" x 3;
####
qq{y} x 3;
####
"y"x 3;
####
$a x 3;
####
$a x3;
####
$a++x3;
####
"y"x 3;
####
'y'x 3;
####
(5)x 3;
####
1x0x1;
####
1 x$y;
####
$z x=3;
####
$z x=$y;
####
1;x =>1;
####
1;x=>1;
####
$hash{x}=1;
####
x =>1;
####
x=>1;
####
xx=>1;
####
1=>x;
####
1=>xor 2;
####
(1) x 6;
####
(1) x6;
####
(1)x6;
####
foo()x6;
####
qw(1)x6;
####
qw<1>x6;
####
[1]x6;
####
1x$bar;
####
1x@bar;
####
sub xyzzy : _5x5 {1;};
####
LABEL: x64;
####
1 => 2;
####
foo => 2;
####
-foo => 2;
####
