#!perl
use strict;
use warnings;

package RTF::Mokenizer;
use RTF::Tokenizer;
@RTF::Mokenizer::ISA = ("RTF::Tokenizer");

sub read_string {

    my $self = shift;
    $self->{_BUFFER} = q?\rtf1 Pete\'acPete\u45Pete?;

}

package Main;

use Test::More tests => 7;

my $tokenizer = RTF::Mokenizer->new();

$tokenizer->read_string();

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
ok( $tokenizer->isa("RTF::Tokenizer"),
    '$tokenizer is as RTF::Tokenizer object' );
