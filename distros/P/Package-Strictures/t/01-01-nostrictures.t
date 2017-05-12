use strict;
use warnings;

use Test::More tests => 5;
use Test::Fatal;
use B::Deparse;
use FindBin;
use lib "$FindBin::Bin/01-poc-lib";

sub lives_and_is(&$$) {
  my ( $code, $expect, $desc ) = @_;
  my $result = exception {
    is( $code->(), $expect, $desc );
  };
  if ($result) {
    fail("died: $result");
  }
}

BEGIN { use_ok('Example'); }

lives_and_is { Example::slow() } 5, 'Method using strictures execute and return values';
lives_and_is { Example::slow(5) } 5, 'Method using strictures dont execute validation blocks';

my $deparse = B::Deparse->new();

my $code = $deparse->coderef2text( Example->can('slow') );

unlike( $code, qr/if\s*\(\s*STRICT\s*\)\s*{/, 'Stricture constant is eliminated from code' );
unlike( $code, qr/die\s*['"]/, 'Stricture code is eliminated from code' );

