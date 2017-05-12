#!perl
use strict;
use warnings;

use Test::More;
use RTF::Tokenizer;

BEGIN {
    eval "use Test::Warn";
    plan skip_all => "Test::Warn needed" if $@;
}
plan tests => 9;

my $tokenizer = RTF::Tokenizer->new();

# These are tests to check that control-word delimiters are handled
# as the specification says, as I've screwed this up once, and
# chromatic says add tests for bugs you find, to stop them creeping
# back in.

$tokenizer->read_string(q?\rtf1 Pete\'acPete\u45Pete?);

ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'rtf', 1 ] ),
    '\rtf1 read correctly' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', 'Pete', '' ] ),
    'Read text "Pete" correctly' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'control', "'", 'ac' ] ),
    'Read entity' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', 'Pete', '' ] ),
    '"Pete" read, which means entity delimiter used' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'u', '45' ] ),
    'u Control read, which means special u delim rules used' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', 'Pete', '' ] ),
    '"Pete" read, which means entity delimiter used' );

$tokenizer->read_string(q?\rtf1a}asdf?);

# Try and break stuff a bit
warnings_like { $tokenizer->get_token() }
[   qr/Your RTF is broken, trying to recover to nearest group/,
    qr/Chances are you have some RTF like/
],
    "Broken RTF caught";

ok( eq_array( [ $tokenizer->get_token() ], [ 'group', '0', '' ] ),
    'End of group' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', 'asdf', '' ] ),
    'end text read correctly' );

