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
package Foo;
use strict;
;
while (1) { last; }
BEGIN { }
sub foo { }
state $x;
$x = 5;
####
