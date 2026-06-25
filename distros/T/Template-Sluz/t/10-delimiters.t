#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

# -------------------------------------------------------------------
# Test configurable delimiters with '<' and '>'
# -------------------------------------------------------------------

my $sluz = Template::Sluz->new();
$sluz->set_delimiters('<', '>');
$sluz->assign(name => 'World');
$sluz->assign(age  => 42);
$sluz->assign(items => ['apple', 'banana', 'cherry']);
$sluz->assign(colors => {r => 'red', g => 'green', b => 'blue'});
$sluz->{perl_file_dir} = "$FindBin::Bin";

# Delimiters #1 - Variable
sluz_test($sluz, '<$name>', 'World', 'Delimiters #1 - Variable');

# Delimiters #2 - Variable with dot access
$sluz->assign(person => {first => 'Scott', last => 'Baker'});
sluz_test($sluz, '<$person.first>', 'Scott', 'Delimiters #2 - Variable dot access');

# Delimiters #3 - Simple if (true)
sluz_test($sluz, '<if 1>yes</if>', 'yes', 'Delimiters #3 - If true');

# Delimiters #4 - Simple if (false)
sluz_test($sluz, '<if 0>yes</if>', '', 'Delimiters #4 - If false');

# Delimiters #5 - If/else
sluz_test($sluz, '<if 0>yes<else>no</if>', 'no', 'Delimiters #5 - If/else');

# Delimiters #6 - If with variable
sluz_test($sluz, '<if $name eq "World">hello</if>', 'hello', 'Delimiters #6 - If with variable');

# Delimiters #7 - If/elseif/else
sluz_test($sluz, '<if 0>first<elseif 1>second</if>', 'second', 'Delimiters #7 - If/elseif');

# Delimiters #8 - Comment
sluz_test($sluz, 'before<* this is a comment *>after', 'beforeafter', 'Delimiters #8 - Comment');

# Delimiters #9 - Literal
sluz_test($sluz, '<literal><$name></literal>', '<$name>', 'Delimiters #9 - Literal');

# Delimiters #10 - Foreach over array
sluz_test($sluz, '<foreach $items as $item><$item> </foreach>', 'apple banana cherry ', 'Delimiters #10 - Foreach array');

# Delimiters #11 - Foreach over hash
sluz_test($sluz, '<foreach $colors as $key => $val><$key>=<$val> </foreach>', 'b=blue g=green r=red ', 'Delimiters #11 - Foreach hash');

# Delimiters #12 - Expression/function block
sluz_test($sluz, '<count($items)>', '3', 'Delimiters #12 - Expression function');

# Delimiters #13 - Chained modifiers
sluz_test($sluz, '<$name|uc>', 'WORLD', 'Delimiters #13 - Modifier');

# Delimiters #14 - Default modifier on missing var
sluz_test($sluz, '<$nonexistent|default:"N/A">', 'N/A', 'Delimiters #14 - Default modifier');

# Delimiters #15 - Nested if inside foreach
sluz_test($sluz, '<foreach $items as $item><if $item eq "banana">FOUND</if></foreach>', 'FOUND', 'Delimiters #15 - Nested if in foreach');

# Delimiters #16 - Foreach with first/last/index
sluz_test($sluz, '<foreach $items as $item><if $__FOREACH_FIRST>F</if></foreach>', 'F', 'Delimiters #16 - Foreach first');

# Delimiters #17 - Literal with JSON-like content
sluz_test($sluz, '<literal>{"key": "value"}</literal>', '{"key": "value"}', 'Delimiters #17 - Literal JSON');

# Delimiters #18 - Plain text passthrough
sluz_test($sluz, 'Hello World', 'Hello World', 'Delimiters #18 - Plain text');

# Delimiters #19 - Multiple variables
sluz_test($sluz, '<$name> is <$age>', 'World is 42', 'Delimiters #19 - Multiple vars');

# Delimiters #20 - Default modifier
sluz_test($sluz, '<$missing|default:"fallback">', 'fallback', 'Delimiters #20 - Default modifier');

done_testing();
