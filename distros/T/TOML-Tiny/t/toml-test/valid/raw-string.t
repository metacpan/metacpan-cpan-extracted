# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use Data::Dumper;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $expected1 = {
               'formfeed' => 'This string has a \\f form feed character.',
               'slash' => 'This string has a \\/ slash character.',
               'carriage' => 'This string has a \\r carriage return character.',
               'tab' => 'This string has a \\t tab character.',
               'backspace' => 'This string has a \\b backspace character.',
               'newline' => 'This string has a \\n new line character.',
               'backslash' => 'This string has a \\\\ backslash character.'
             };


my $actual = from_toml(q{backspace = 'This string has a \\b backspace character.'
tab = 'This string has a \\t tab character.'
newline = 'This string has a \\n new line character.'
formfeed = 'This string has a \\f form feed character.'
carriage = 'This string has a \\r carriage return character.'
slash = 'This string has a \\/ slash character.'
backslash = 'This string has a \\\\ backslash character.'
});

is($actual, $expected1, 'raw-string - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ from_toml(to_toml($actual)) }, $actual, 'raw-string - to_toml') or do{
  diag 'INPUT:';
  diag Dumper($actual);

  diag 'TOML OUTPUT:';
  diag to_toml($actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml($actual)));
};

done_testing;