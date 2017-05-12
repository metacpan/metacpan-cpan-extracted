#!perl -T
use 5.008001;
use strict;
use warnings FATAL => 'all';
use Regexp::Optimizer;
use Test::More;

plan tests => 10;
my $ro = Regexp::Optimizer->new();
my $ra = Regexp::Assemble->new->add(qw/foobar fooxar foozap/)->re;
is $ro->as_string(qr/foobar|fooxar|foozap/), $ra, $ra;
my $re_verbose = qr{
   foobar |  # comment
   fooxar    # 
   |         #
   foozap
}msx;
is $ro->as_string($re_verbose), qr/foo(?:[bx]ar|zap)/msx, "qr//msx";

# Not idempotent
# is $ro->as_string($ra), $ra, $ra;

my $re_noneed = qr/no(alteration(in(the(expression))))/;
is $ro->optimize($re_noneed), $re_noneed, 'Already Optimzed';

my $re_escaped = qr/(\(|a|b|c|\))/;
is $ro->as_string($re_escaped), qr/([()abc])/, 'Escaped';

my $re_nested = qr/f(?:oo(?:l|lish|lishness)?)/;
is $ro->as_string($re_nested), qr/f(?:oo(?:l(?:ish(?:ness)?)?)?)/, 'Nested';

SKIP: {
    skip "Perl v5.14 or better required", 5 unless $] >= 5.010;
    eval q{
        my $re_named = qr/(?<abc>a|b|c)/;
        is $ro->as_string($re_named), qr/(?<abc>[abc])/, "Named: $re_named";
        $re_named = qr/(?'abc'a|b|c)/;
        is $ro->as_string($re_named), qr/(?'abc'[abc])/, "Named: $re_named";
        my $re_brset = qr/(?|foo|fool)/;
        is $ro->as_string($re_brset), qr/(?|fool?)/, "Branch Reset";
        for my $str (
            qw{
            (??{0|1})
            (?(?=bar|foo)foo|bar)
            }
          )
        {
            use re 'eval';
            my $re = qr{$str};
            is $ro->as_string($re), $re, "Code: $re";
        }
    };
}
