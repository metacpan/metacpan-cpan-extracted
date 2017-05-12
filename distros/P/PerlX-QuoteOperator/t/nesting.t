#!perl -T

use Test::More tests => 2;

# test for Text::Balanced patch from TOBYINK in rt72822

my $expected = q{http://example.com/geo?coord[0]=1&coord[1]=30};

use PerlX::QuoteOperator qn => { -emulate => 'q', -with => sub ($) { $_[0] } };
is(
    qn[http://example.com/geo?coord[0]=1&coord[1]=30], 
    $expected,
    'Nesting works without parser'
);

use PerlX::QuoteOperator qnp => { -emulate => 'q', -with => sub ($) { $_[0] }, -parser => 1 };
is(
    qnp[http://example.com/geo?coord[0]=1&coord[1]=30], 
    $expected,
    'Nesting works with parser'
);

# TBD - Add tests for {}, <>, & ()
# Also another delimiter.t for just testing all common delimiters (with & without parser enabled)