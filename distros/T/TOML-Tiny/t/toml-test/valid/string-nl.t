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
               'nl_mid' => 'val
ue',
               'lit_nl_uni' => 'val\\ue',
               'nl_end' => 'value
',
               'lit_nl_mid' => 'val\\nue',
               'lit_nl_end' => 'value\\n'
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

  diag '';
  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ scalar from_toml(to_toml($actual)) }, $expected1, 'string-nl - to_toml') or do{
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