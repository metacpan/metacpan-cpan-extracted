#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Temp qw( tempfile );

package TestParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   return $self->token_int;
}

package main;

my $parser = TestParser->new;

isa_ok( $parser, "TestParser", '$parser' );
isa_ok( $parser, "Parser::MGC", '$parser' );

my $value = $parser->from_string( "\t123" );

is( $value, 123, '->from_string' );

ok( !eval { $parser->from_string( "\t123." ) }, 'Trailing input on string fails' );
is( $@,
    qq[Expected end of input on line 1 at:\n].
    qq[\t123.\n].
    qq[\t   ^\n],
    'Exception from trailing input on string' );

ok( !eval { $parser->from_file( \*DATA ) }, 'Trailing input on glob filehandle fails' );
is( $@,
    qq[Expected end of input on line 1 at:\n].
    qq[ 123.\n].
    qq[    ^\n],
    'Exception from trailing input on glob filehandle' );

my ( $fh, $filename ) = tempfile( "tmpfile.XXXXXX", UNLINK => 1 );
END { defined $filename and unlink $filename }

print $fh " 123.\n";
close $fh;

ok( !eval { $parser->from_file( $filename ) }, 'Trailing input on named file fails' );
is( $@,
    qq[Expected end of input in $filename on line 1 at:\n].
    qq[ 123.\n].
    qq[    ^\n],
    'Exception from trailing input on named file' );

done_testing;

__DATA__
 123.
