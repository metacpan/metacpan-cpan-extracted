#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Fatal;

use File::Temp qw( tempfile );

package TestParser {
   use base qw( Parser::MGC );

   sub parse
   {
      my $self = shift;

      return $self->token_int;
   }
}

my $parser = TestParser->new;

isa_ok( $parser, "TestParser", '$parser' );
isa_ok( $parser, "Parser::MGC", '$parser' );

my $value = $parser->from_string( "\t123" );

is( $value, 123, '->from_string' );

is( exception { $parser->from_string( "\t123." ) },
   qq[Expected end of input on line 1 at:\n].
   qq[\t123.\n].
   qq[\t   ^\n],
   'Exception from trailing input on string' );

is( exception { $parser->from_file( \*DATA ) },
   qq[Expected end of input on line 1 at:\n].
   qq[ 123.\n].
   qq[    ^\n],
   'Exception from trailing input on glob filehandle' );

my ( $fh, $filename ) = tempfile( "tmpfile.XXXXXX", UNLINK => 1 );
END { defined $filename and unlink $filename }

print $fh " 123.\n";
close $fh;

is( exception { $parser->from_file( $filename ) },
   qq[Expected end of input in $filename on line 1 at:\n].
   qq[ 123.\n].
   qq[    ^\n],
   'Exception from trailing input on named file' );

done_testing;

__DATA__
 123.
