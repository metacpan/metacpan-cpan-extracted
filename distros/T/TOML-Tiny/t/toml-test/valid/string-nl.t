# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use Data::Dumper;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $expected1 = {
               'lit_nl_end' => 'value\\n',
               'lit_nl_uni' => 'val\\ue',
               'lit_nl_mid' => 'val\\nue',
               'nl_mid' => 'val
ue',
               'nl_end' => 'value
'
             };


my $actual = from_toml(q{nl_mid = "val\\nue"
nl_end = """value\\n"""

lit_nl_end = '''value\\n'''
lit_nl_mid = 'val\\nue'
lit_nl_uni = 'val\\ue'
});

is($actual, $expected1, 'string-nl - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ from_toml(to_toml($actual)) }, $actual, 'string-nl - to_toml') or do{
  diag 'INPUT:';
  diag Dumper($actual);

  diag 'TOML OUTPUT:';
  diag to_toml($actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml($actual)));
};

done_testing;