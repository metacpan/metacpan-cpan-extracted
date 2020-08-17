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
               'multiline_empty_four' => '',
               'equivalent_three' => 'The quick brown fox jumps over the lazy dog.',
               'equivalent_one' => 'The quick brown fox jumps over the lazy dog.',
               'multiline_empty_one' => '',
               'multiline_empty_two' => '',
               'equivalent_two' => 'The quick brown fox jumps over the lazy dog.',
               'multiline_empty_three' => ''
             };


my $actual = from_toml(q{multiline_empty_one = """"""
multiline_empty_two = """
"""
multiline_empty_three = """\\
    """
multiline_empty_four = """\\
   \\
   \\
   """

equivalent_one = "The quick brown fox jumps over the lazy dog."
equivalent_two = """
The quick brown \\


  fox jumps over \\
    the lazy dog."""

equivalent_three = """\\
       The quick brown \\
       fox jumps over \\
       the lazy dog.\\
       """
});

is($actual, $expected1, 'multiline-string - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag '';
  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ scalar from_toml(to_toml($actual)) }, $expected1, 'multiline-string - to_toml') or do{
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