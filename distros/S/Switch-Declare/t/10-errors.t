use strict;
use warnings;
use Test::More;
use Switch::Declare;

# Compile-time diagnostics are raised while parsing; eval STRING captures them.
sub err {
    my $code = shift;
    eval $code;
    return $@;
}

like( err('switch (1) { }'),
      qr/empty switch body/, "empty body" );

like( err('switch (1) { case 1 { "a" } default { "b" } default { "c" } }'),
      qr/multiple 'default'/, "multiple defaults" );

like( err('switch (1) { default { "a" } case 1 { "b" } }'),
      qr/'case' after 'default'/, "case after default" );

like( err('switch 1 { case 1 { "a" } }'),
      qr/expected '\(' after 'switch'/, "missing parens" );

like( err('switch (1) { case 1 "a" }'),
      qr/expected '\{' after case pattern/, "missing block brace" );

like( err('switch (1) { frobnicate { 1 } }'),
      qr/expected 'case' or 'default'/, "unknown keyword" );

like( err('switch ("x") { case /a/Z { 1 } default { 0 } }'),
      qr/unsupported regex flag/, "unsupported regex flag" );

like( err('switch ("x") { case /unterminated { 1 } }'),
      qr/unterminated regex/, "unterminated regex" );

like( err(qq{switch ("x") { case "unterminated { 1 } }}),
      qr/unterminated string/, "unterminated string" );

like( err('switch (1) { case \ 1 { 1 } default { 0 } }'),
      qr/expected '&' after/, "predicate without &" );

like( err('switch (1) { case \& { 1 } default { 0 } }'),
      qr/expected sub name/, "predicate without a name" );

like( err('switch (1) { case [1 . 2] { 1 } default { 0 } }'),
      qr/expected '\.\.' in range/, "malformed range" );

# valid code through the same path still works (sanity)
is( eval('switch (1) { case 1 { "ok" } default { "no" } }'), "ok",
    "eval STRING path compiles valid switch" );

done_testing;
