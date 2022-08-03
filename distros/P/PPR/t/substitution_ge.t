#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

use PPR::X;
use re 'eval';

my $METAREGEX = qr{
    \A \s* (?&PerlQuotelike) \s* \Z

    (?(DEFINE)
        (?<PerlInfixBinaryOperator>
            ((?&PerlStdInfixBinaryOperator))
            (?{
                if ($^N eq '//' || $^N eq '||') {
                    pass "Found infix: $^N";
                }
                else {
                    pass "Interim-matched extra infix: $^N";
                }
            })
        )

        (?<PerlBinaryExpression>
            ((?&PerlStdBinaryExpression))
            (?{
                if (   $^N eq q{$var{x} // croak()}
                    || $^N eq q{$var{x} || croak()} )
                {
                    pass "Found correct binary expression: $^N";
                }
                else {
                    pass "Interim-matched extra binary expression: $^N";
                }
            })
        )
    )

    $PPR::X::GRAMMAR
}xms;

for my $src_code (<DATA>) {
    subtest $src_code => sub {
        ok $src_code =~ $METAREGEX  =>  'Matched METAREGEX';

    }
}

done_testing();

__DATA__
s<(RE)>< $var{x} // croak() >ge
s[(RE)][ $var{x} // croak() ]ge
s{(RE)}{ $var{x} // croak() }ge
s((RE))( $var{x} // croak() )ge
s"(RE)"  $var{x} // croak() "ge
s%(RE)%  $var{x} // croak() %ge
s'(RE)'  $var{x} // croak() 'ge
s+(RE)+  $var{x} // croak() +ge
s,(RE),  $var{x} // croak() ,ge
s/(RE)/  $var{x} || croak() /ge
s@(RE)@  $var{x} // croak() @ge
s|(RE)|  $var{x} // croak() |ge
