# 10_perl514.t
#
# Test suite for Regexp::Assemble
# Exercise regular expressions beyond perl 5.12
#
# copyright (C) 2011 David Landgren

use strict;

use Test::More;
if ($] < 5.013) {
    plan skip_all => 'Irrelevant below perl <= 5.12';
}
else {
    plan tests => 3;
}


use Regexp::Assemble;

my $fixed = 'The scalar remains the same';
$_ = $fixed;

{
    my $r = Regexp::Assemble->new->debug(8)->add(qw(this that));
    my $re = $r->re;
    is( $re, '(?^:th(?:at|is))', 'time debug' );
}

{
    my $r = Regexp::Assemble->new->add(qw(this that))->debug(8)->add('those');
    my $re = $r->re;
    is( $re, '(?^:th(?:ose|at|is))', 'deferred time debug' );
}


is( $_, $fixed, '$_ has not been altered' );
