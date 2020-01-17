# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use Data::Dumper;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $expected1 = {
               'equivalent_three' => 'The quick brown fox jumps over the lazy dog.',
               'equivalent_one' => 'The quick brown fox jumps over the lazy dog.',
               'equivalent_two' => 'The quick brown fox jumps over the lazy dog.',
               'multiline_empty_four' => '',
               'multiline_empty_one' => '',
               'multiline_empty_two' => '',
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

  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ from_toml(to_toml($actual)) }, $actual, 'multiline-string - to_toml') or do{
  diag 'INPUT:';
  diag Dumper($actual);

  diag 'TOML OUTPUT:';
  diag to_toml($actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml($actual)));
};

done_testing;