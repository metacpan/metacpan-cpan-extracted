#!perl
use strict;
use warnings;

use Test::More tests => 2;
use RTF::Tokenizer;

my $tokenizer = RTF::Tokenizer->new();

isa_ok( $tokenizer, 'RTF::Tokenizer', 'new returned an RTF::Tokenizer object' );

$tokenizer->{_BUFFER} = 'a';
$tokenizer->read_string("{\\rtf\n\\ansi}");

is( $tokenizer->{_BUFFER}, "a{\\rtf\n\\ansi}",
    'Data transfered from string to buffer' );
