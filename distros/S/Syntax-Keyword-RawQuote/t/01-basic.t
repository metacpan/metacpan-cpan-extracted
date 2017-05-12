#!perl
use strict;
use warnings;
use Test::More;
use utf8;

require_ok 'Syntax::Keyword::RawQuote';

my @library = (
  <<'EOEXAMPLE',
a\\b\\c
EOEXAMPLE
  <<'EOEXAMPLE',
a \n b \t c \
d \x{banana}
EOEXAMPLE
);

for my $example (@library) {
  is eval "use Syntax::Keyword::RawQuote; r'$example'", $example, "r''";
  is eval "use Syntax::Keyword::RawQuote; r[$example]", $example, "r[]";
  is eval "use Syntax::Keyword::RawQuote -as => q{rawq}; rawq<$example>", $example, "rawq<>";
  is eval "use Syntax::Keyword::RawQuote; r☃$example☃", $example, "snowman";
  is eval "use Syntax::Keyword::RawQuote; \$_ = r☃$example☃; 42", 42, "parse following";
}

done_testing;
