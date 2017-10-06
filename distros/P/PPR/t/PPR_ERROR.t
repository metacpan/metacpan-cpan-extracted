use warnings;
use strict;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

plan tests => 15;

use PPR;

my $OFFSET = __LINE__ + 2;
my $source_code = <<'END_SOURCE';
    sub foo {
        my $x = 1;
        my $y = 2:
        my $z = 3;
    }
END_SOURCE

# Make sure it's undefined, and won't have global consequences...
local $PPR::ERROR;

# Attempt the match...
$source_code =~ m{ (?<Block> (?&PerlBlock) )  $PPR::GRAMMAR }x;

# Check diagnostics...
is $PPR::ERROR->source, 'my $y = 2:'                 => '1: Error source identified';
is $PPR::ERROR->prefix, substr($source_code, 0, 41)  => '1: Prefix identified';
is $PPR::ERROR->line, 3                              => '1: Line identified';
is $PPR::ERROR->line($OFFSET), 19                    => '1: Line with offset identified';
is $PPR::ERROR->diagnostic, 'syntax error near "2:"' => '1: Diagnostic identified';

# Pre-locate the source code fragment...
my $error_with_line = $PPR::ERROR->origin(7);

is $error_with_line->source, 'my $y = 2:'                            => '2: Error source identified';
is $error_with_line->prefix, substr($source_code, 0, 41)             => '2: Prefix identified';
is $error_with_line->line, 9                                         => '2: Line identified';
is $error_with_line->line($OFFSET), 9                                => '2: Line with offset identified';
is $error_with_line->diagnostic, 'syntax error at line 9, near "2:"' => '2: Diagnostic identified';

# Locate the source code fragment's file as well...
my $error_with_file = $PPR::ERROR->origin(7, 'demo.pl');

is $error_with_file->source, 'my $y = 2:'                                    => '3: Error source identified';
is $error_with_file->prefix, substr($source_code, 0, 41)                     => '3: Prefix identified';
is $error_with_file->line, 9                                                 => '3: Line identified';
is $error_with_file->line($OFFSET), 9                                        => '3: Line with offset identified';
is $error_with_file->diagnostic, 'syntax error at demo.pl line 9, near "2:"' => '3: Diagnostic identified';


done_testing();

