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
               'electron_mass' => bless( {
                                           'operator' => 'CODE(...)',
                                           '_lines' => [
                                                         7
                                                       ],
                                           'code' => sub {
                                                         BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                         use strict;
                                                         no feature ':all';
                                                         use feature ':5.16';
                                                         require Math::BigFloat;
                                                         my $got = 'Math::BigFloat'->new($_);
                                                         'Math::BigFloat'->new('9.109109383e-31')->beq($got);
                                                     },
                                           'name' => 'Math::BigFloat->new("9.109109383e-31")->beq($_)',
                                           '_file' => '(eval 375)'
                                         }, 'Test2::Compare::Custom' )
             };


my $actual = from_toml(q{electron_mass = 9_109.109_383e-3_4
});

is($actual, $expected1, 'underscored-float - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag '';
  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ scalar from_toml(to_toml($actual)) }, $expected1, 'underscored-float - to_toml') or do{
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