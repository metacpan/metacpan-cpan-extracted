#!perl
use strict;
use warnings;
use Test::More tests => 22;
use_ok('PPIx::IndexOffsets');

my $document = PPI::Document->new('t/hello.pl');
$document->index_offsets;

my @tokens = $document->tokens;

my $token = shift @tokens;
is( $token,               "#!perl\n" );
is( $token->start_offset, 0 );
is( $token->stop_offset,  7 );

$token = shift @tokens;
is( $token,               "\n" );
is( $token->start_offset, 7 );
is( $token->stop_offset,  8 );

$token = shift @tokens;
is( $token,               'print' );
is( $token->start_offset, 8 );
is( $token->stop_offset,  13 );

$token = shift @tokens;
is( $token,               ' ' );
is( $token->start_offset, 13 );
is( $token->stop_offset,  14 );

$token = shift @tokens;
is( $token,               '"Hello world!\n"' );
is( $token->start_offset, 14 );
is( $token->stop_offset,  30 );

$token = shift @tokens;
is( $token,               ';' );
is( $token->start_offset, 30 );
is( $token->stop_offset,  31 );

$token = shift @tokens;
is( $token,               "\n" );
is( $token->start_offset, 31 );
is( $token->stop_offset,  32 );
