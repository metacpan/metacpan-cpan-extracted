#!perl
use strict;
use warnings;

use Test::More;
use RTF::Tokenizer;

my $tokenizer = RTF::Tokenizer->new();

# These are tests to check that control-word delimiters are handled
# as the specification says.
BEGIN {
    eval "use Test::Warn";
    plan skip_all => "Test::Warn needed" if $@;
}

plan tests => 14;

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

# Set sloppy, and make sure we /don't/ break anything...
$tokenizer = RTF::Tokenizer->new( sloppy => 1 );
$tokenizer->read_string(q?\rtf1a}asdf?);

ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'rtf', '1' ] ),
    'RTF control read correctly' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', 'a', '' ] ),
    'next text read correctly' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'group', '0', '' ] ),
    'End of group' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', 'asdf', '' ] ),
    'end text read correctly' );

$tokenizer->sloppy(0);
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

# And again, with feeling...
$tokenizer->sloppy(1);

$tokenizer->read_string(q?\rtf1a}asdf?);
ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'rtf', '1' ] ),
    'RTF control read correctly' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', 'a', '' ] ),
    'next text read correctly' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'group', '0', '' ] ),
    'End of group' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', 'asdf', '' ] ),
    'end text read correctly' );
