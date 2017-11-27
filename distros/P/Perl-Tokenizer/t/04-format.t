#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 17;

use Perl::Tokenizer qw(perl_tokens);

my $code = <<'EOT';
format STDOUT_TOP =
CHR             ORD            USED
-----------------------------------
.

format STDOUT =
@>>         @>>>>>>         @>>>>>>
$white_spaces{$key} // chr $key, $key, $table{$key}
.
EOT

my @tokens = qw(
    keyword
    horizontal_space
    bare_word
    horizontal_space
    assignment_operator

    vertical_space
    format
    vertical_space

    keyword
    horizontal_space
    special_fh
    horizontal_space
    assignment_operator
    vertical_space
    format
    vertical_space
);

perl_tokens {
    is($_[0], shift(@tokens));
} $code;

ok(scalar(@tokens) == 0);
