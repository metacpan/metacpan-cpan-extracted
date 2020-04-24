use warnings;
use strict;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

plan tests => 5;

use PPR;

my $OFFSET = __LINE__ + 2;
my $source_code = <<'END_SOURCE';
    sub foo {
        my $x = 1;
        my $y = 2;
        my $z = 3;
    }
  }
END_SOURCE

# Make sure it's undefined, and won't have global consequences...
local $PPR::ERROR;

# Attempt the match...
$source_code =~ m{ (?&PerlEntireDocument)  $PPR::GRAMMAR }x;

# Check diagnostics...
is $PPR::ERROR->source, '}'                            => '1: Error source identified';
is $PPR::ERROR->prefix, substr($source_code, 0, -2)    => '1: Prefix identified';
is $PPR::ERROR->line, 6                                => '1: Line identified';
is $PPR::ERROR->line($OFFSET), 22                      => '1: Line with offset identified';
like $PPR::ERROR->diagnostic,
   qr/\AUnmatched right curly bracket at end of line/  => '1: Diagnostic identified';

done_testing();

