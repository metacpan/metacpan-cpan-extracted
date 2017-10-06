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
            ok $str !~ m/\A (?&PerlOWS) (?&PerlQuotelikeQ) (?&PerlOWS) \Z $PPR::GRAMMAR/xo => "FAIL: $str";
        }
        else {
            ok $str =~ m/\A (?&PerlOWS) (?&PerlQuotelikeQ) (?&PerlOWS) \Z $PPR::GRAMMAR/xo => "MATCH: $str";
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
    ''
####
    'f'
####
    'f\'b'
####
    'f\nb'
####
    'f\\b'
####
    'f\\\b'
####
    'f\\\''
####
    q//
####
    q/f/
####
    q/f\'b/
####
    q/f\nb/
####
    q/f\\b/
####
    q/f\\\b/
####
    q/f\\'/
####
    q/f\\\//
####
    q!!
####
    q!f!
####
    q!f\'b!
####
    q !f\nb!
####
    q
    !f\\b!
####
    q
    !
    f\\\b
    !
####
    q!f\\'!
####
    q!f\\\!!
####
    q{}
####
    q{f}
####
    q {f\'b}
####
    q
    {
        {{{f\nb}}}
        ([<
    }
####
    q{f\\b}
####
    q{f\\\b}
####
    q{f\\'}
####
    q{f\\\}}
####
    q[]
####
    q[f]
####
    q [f\'b]
####
    q
    [
        f\nb
    ]
####
    q[f\\b]
####
    q[f\\\b]
####
    q[f\\']
####
    q[f\\\]]
####
    q<>
####
    q<f>
####
    q <f\'b>
####
    q
    <
        <<<<f\nb>>>>
        {[(
    >
####
    q<f\\b>
####
    q<f\\\b>
####
    q<f\\'>
####
    q<f\\\>>
####
    q()
####
    q(f)
####
    q (f\'b)
####
    q   # Comment here
    (
        ((f\nb))
        {[<
    )
####
    q(f\\b)
####
    q(f\\\b)
####
    q(f\\')
####
    q(f\\\))
####
# THESE SHOULD FAIL...
    '\\''
####
    ''''
####
    'f\\\\''
####
    q/\\'
####
    q{\\'
####
    q {
        {
    }
####
    q <\\'
####
    q
    [\\'
####
    q(\\'
####
    q q\\'
####
    q =\\'
####
