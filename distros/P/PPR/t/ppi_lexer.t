use strict;
use warnings;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}


use PPR;

my $neg = 0;
while (my $str = <DATA>) {
           if ($str =~ /\A# TH[EI]SE? SHOULD MATCH/) { $neg = 0;       next; }
        elsif ($str =~ /\A# TH[EI]SE? SHOULD FAIL/)  { $neg = 1;       next; }
        elsif ($str !~ /^####\h*\Z/m)                { $str .= <DATA>; redo; }

        $str =~ s/\s*^####\h*\Z//m;

        if ($neg) {
            ok $str !~ m/\A \s* (?&PerlStatement) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
        else {
            ok $str =~ m/\A \s* (?&PerlStatement) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
use constant { One => 1 };
####
use constant 1 { One => 1 };
####
$foo->{bar};
####
$foo[1]{bar};
####
$foo{bar};
####
sub {1};
####
grep { $_ } 0 .. 2;
####
map { $_ => 1 } 0 .. 2;
####
sort { $b <=> $a } 0 .. 2;
####
do {foo};
####
$foo = { One => 1 };
####
$foo ||= { One => 1 };
####
1, { One => 1 };
####
One => { Two => 2 };
####
{foo, bar};
####
{foo => bar};
####
{};
####
+{foo, bar};
####
@foo{'bar', 'baz'};
####
@{$foo}{'bar', 'baz'};
####
${$foo}{bar};
####
return { foo => 'bar' };
####
bless { foo => 'bar' };
####
$foo &&= { One => 1 };
####
$foo //= { One => 1 };
####
$foo //= { 'a' => 1, 'b' => 2 };
####
0 || { One => 1 };
####
1 && { One => 1 };
####
undef // { One => 1 };
####
$x ? {a=>1} : 1;
####
$x ? 1 : {a=>1};
####
$x ? {a=>1} : {b=>1};
####
