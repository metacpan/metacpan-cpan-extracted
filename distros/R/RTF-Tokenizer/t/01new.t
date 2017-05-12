#!perl

# Some very basic sanity checks
use strict;
use warnings;

use Test::More tests => 6;
use_ok('RTF::Tokenizer');

my $tokenizer = RTF::Tokenizer->new();
isa_ok( $tokenizer, 'RTF::Tokenizer', 'new returned an RTF::Tokenizer object' );

# From a string as a class method
my $string_tokenizer = RTF::Tokenizer->new( string => '{\rtf\n\ansi}' );
is( $string_tokenizer->{_BUFFER},
    '{\rtf\n\ansi}', 'Data transfered from string to buffer' );

# From a string as an object method
my $string_tokenizer2 = $string_tokenizer->new( string => '{\rtf\a\ansi}' );
is( $string_tokenizer2->{_BUFFER},
    '{\rtf\a\ansi}', 'Data transfered from string to buffer' );

# From a file as a class method
my $file_tokenizer = RTF::Tokenizer->new( file => 'eg/test.rtf' );
like( $file_tokenizer->{_BUFFER},
    qr/^{\\rtf1\s*/, 'read_file from filename gets first line' );
$file_tokenizer->{_BUFFER} = '';

# From a file as an object method
my $file_tokenizer2 = $file_tokenizer->new( file => 'eg/test.rtf' );
like( $file_tokenizer2->{_BUFFER},
    qr/^{\\rtf1\s*/, 'read_file from filename gets first line' );
