
use strict;
use warnings;
use Test::More;
use Term::FormatColumns qw(format_columns_for_width);

my @data = qw( foo bar baz biz blargh fizzbuzz );
my $output;

$output = format_columns_for_width 20, @data;
is $output, <<'OUTPUT', 'Output is correct for 20 character width';
foo       biz
bar       blargh
baz       fizzbuzz
OUTPUT

$output = format_columns_for_width 30, @data;
is $output, <<'OUTPUT', 'Output is correct for 30 character width';
foo       baz       blargh
bar       biz       fizzbuzz
OUTPUT

$output = format_columns_for_width 1, @data;
is $output, <<'OUTPUT', 'Output is correct for 1 character width';
foo
bar
baz
biz
blargh
fizzbuzz
OUTPUT

$output = format_columns_for_width 20, qw/foo bar baz biz fizzbuzz/;
$output =~ s/ +$//; # Avoid git whitespace errors
is $output, <<'OUTPUT', 'Short lists are padded with empty strings';
foo       biz
bar       fizzbuzz
baz
OUTPUT

my $bold = "\x1b[1mfizzbuzz\x1b[0m";
$output = format_columns_for_width 20, qw/foo bar baz biz blargh/, $bold;
is $output, <<OUTPUT, 'ANSI SGR escape sequences are handled correctly';
foo       biz
bar       blargh
baz       $bold
OUTPUT

done_testing;
