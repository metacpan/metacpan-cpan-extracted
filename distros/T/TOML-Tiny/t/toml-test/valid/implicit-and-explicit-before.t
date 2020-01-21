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
               'a' => {
                        'b' => {
                                 'c' => {
                                          'answer' => bless( {
                                                               'code' => sub {
                                                                             BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                                             use strict;
                                                                             no feature ':all';
                                                                             use feature ':5.16';
                                                                             require Math::BigInt;
                                                                             'Math::BigInt'->new('42')->beq($_);
                                                                         },
                                                               '_file' => '(eval 397)',
                                                               'operator' => 'CODE(...)',
                                                               'name' => '<Custom Code>',
                                                               '_lines' => [
                                                                             6
                                                                           ]
                                                             }, 'Test2::Compare::Custom' )
                                        }
                               },
                        'better' => bless( {
                                             '_lines' => [
                                                           6
                                                         ],
                                             'operator' => 'CODE(...)',
                                             'name' => '<Custom Code>',
                                             '_file' => '(eval 396)',
                                             'code' => sub {
                                                           BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                           use strict;
                                                           no feature ':all';
                                                           use feature ':5.16';
                                                           require Math::BigInt;
                                                           'Math::BigInt'->new('43')->beq($_);
                                                       }
                                           }, 'Test2::Compare::Custom' )
                      }
             };


my $actual = from_toml(q{[a]
better = 43

[a.b.c]
answer = 42
});

is($actual, $expected1, 'implicit-and-explicit-before - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ from_toml(to_toml($actual)) }, $actual, 'implicit-and-explicit-before - to_toml') or do{
  diag 'INPUT:';
  diag Dumper($actual);

  diag 'TOML OUTPUT:';
  diag to_toml($actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml($actual)));
};

done_testing;