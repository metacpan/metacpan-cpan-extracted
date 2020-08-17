# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use Data::Dumper;
use DateTime;
use DateTime::Format::RFC3339;
use Math::BigInt;
use Math::BigFloat;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $expected1 = {
               'notunicode3' => 'This string does not have a unicode \\u0075 escape.',
               'tab' => 'This string has a 	 tab character.',
               'newline' => 'This string has a 
 new line character.',
               'backspace' => 'This string has a  backspace character.',
               'backslash' => 'This string has a \\ backslash character.',
               'formfeed' => 'This string has a  form feed character.',
               'quote' => 'This string has a " quote character.',
               'carriage' => 'This string has a  carriage return character.',
               'notunicode2' => 'This string does not have a unicode \\u escape.',
               'notunicode1' => 'This string does not have a unicode \\u escape.',
               'notunicode4' => 'This string does not have a unicode \\u escape.'
             };


my $actual = from_toml(q{backspace = "This string has a \\b backspace character."
tab = "This string has a \\t tab character."
newline = "This string has a \\n new line character."
formfeed = "This string has a \\f form feed character."
carriage = "This string has a \\r carriage return character."
quote = "This string has a \\" quote character."
backslash = "This string has a \\\\ backslash character."
notunicode1 = "This string does not have a unicode \\\\u escape."
notunicode2 = "This string does not have a unicode \\u005Cu escape."
notunicode3 = "This string does not have a unicode \\\\u0075 escape."
notunicode4 = "This string does not have a unicode \\\\\\u0075 escape."
});

is($actual, $expected1, 'string-escapes - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag '';
  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ scalar from_toml(to_toml($actual)) }, $expected1, 'string-escapes - to_toml') or do{
  diag "ERROR: $@" if $@;

  diag 'INPUT:';
  diag Dumper($actual);

  diag '';
  diag 'GENERATED TOML:';
  diag to_toml($actual);

  diag '';
  diag 'REPARSED FROM GENERATED TOML:';
  diag Dumper(scalar from_toml(to_toml($actual)));
};

done_testing;