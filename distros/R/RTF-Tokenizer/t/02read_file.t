#!perl
use strict;
use warnings;

use Test::More tests => 13;
use RTF::Tokenizer;
use IO::File;

my $tokenizer = RTF::Tokenizer->new();

isa_ok( $tokenizer, 'RTF::Tokenizer', 'new returned an RTF::Tokenizer object' );

# Test from a filename
$tokenizer->{_BUFFER} = 'a';

$tokenizer->read_file('eg/test.rtf');
like( $tokenizer->{_BUFFER}, qr/^a\{\\rtf1\s*/,
    'read_file from filename gets first line' );
is( $tokenizer->{_RS}, "UNIX", 'Line-endings identified as UNIX' );
$tokenizer->{_BUFFER} = '';

# Test from a filehandle

open( FALA, '< eg/test.rtf' ) || die $!;
$tokenizer->read_file( \*FALA );

like( $tokenizer->{_BUFFER}, qr/^\{\\rtf1\s*/,
    'read_file from filehandle gets first line' );
is( $tokenizer->{_RS}, "UNIX", 'Line-endings identified as UNIX' );
$tokenizer->{_BUFFER} = '';

close FALA;

# Test from an IO::File object
my $fh = new IO::File;
$fh->open('< eg/test.rtf');
die "Failed to open eg/test.rtf with IO::File" unless $fh;
$tokenizer->read_file($fh);
like( $tokenizer->{_BUFFER}, qr/^\{\\rtf1\s*/,
    'read_file from IO gets first line' );
is( $tokenizer->{_RS}, "UNIX", 'Line-endings identified as UNIX' );
$tokenizer->{_BUFFER} = '';

# Test that a dodgy GLOB causes problems
my $LAGA = '';
eval '$tokenizer->read_file(\*LAGA)';
my $error_message = $@;
like(
    $error_message,
    qr/Couldn't create an IO::File object from the reference you specified/,
    'Dodgy glob caused a croak' );

# Try and read a non-existant file
my $filename = 'file1';
$filename++ while ( -e $filename );
eval '$tokenizer->read_file($filename)';
$error_message = $@;
like(
    $error_message,
    qr/Couldn't open .+ for reading/,
    'None-existant file caused a croak' );

# Pass a funky reference
my $bad_ref = [];
eval '$tokenizer->read_file($bad_ref)';
$error_message = $@;
like(
    $error_message,
    qr/You passed a reference to read_file of type ARRAY/,
    'Funky reference caused a croak' );

# Test initial_read()
is( $tokenizer->initial_read, 512, 'initial_read() returns 512' );
$tokenizer->initial_read(2);
is( $tokenizer->initial_read, 2, 'initial_read() returns 2' );
is( $tokenizer->initial_read,
    $tokenizer->{_INITIAL_READ},
    'initial_read returns {_INITIAL_READ}' );
