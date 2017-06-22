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
            ok $str !~ m/\A \s* (?&PerlString) \s* \Z $PPR::GRAMMAR/xo => "FAIL: $str";
        }
        else {
            ok $str =~ m/\A \s* (?&PerlString) \s* \Z $PPR::GRAMMAR/xo => "MATCH: $str";
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
    'foo'
####
    "foo"
####
    q{foo}
####
    q[foo]
####
    q<foo>
####
    q(foo)
####
    q/foo/
####
    q#foo#
####
    q=foo=
####
    q qfooq
####
    qq{foo}
####
    qq[foo]
####
    qq<foo>
####
    qq(foo)
####
    qq/foo/
####
    qq#foo#
####
    qq=foo=
####
    qq qfooq
####
    q  {foo}
####
    q  [foo]
####
    q  <foo>
####
    q  (foo)
####
    q  /foo/
####
    q  =foo=
####
    qq   {foo}
####
    qq   [foo]
####
    qq   <foo>
####
    qq   (foo)
####
    qq   /foo/
####
    qq   =foo=
####
# THESE SHOULD FAIL
####
    q  #foo#
####
    qq   #foo#
####
