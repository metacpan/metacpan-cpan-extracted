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
               'posanswer' => bless( {
                                       '_lines' => [
                                                     6
                                                   ],
                                       '_file' => '(eval 406)',
                                       'code' => sub {
                                                     BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                     use strict;
                                                     no feature ':all';
                                                     use feature ':5.16';
                                                     require Math::BigInt;
                                                     'Math::BigInt'->new('42')->beq($_);
                                                 },
                                       'name' => '<Custom Code>',
                                       'operator' => 'CODE(...)'
                                     }, 'Test2::Compare::Custom' ),
               'neganswer' => bless( {
                                       '_lines' => [
                                                     6
                                                   ],
                                       'operator' => 'CODE(...)',
                                       'name' => '<Custom Code>',
                                       'code' => sub {
                                                     BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                     use strict;
                                                     no feature ':all';
                                                     use feature ':5.16';
                                                     require Math::BigInt;
                                                     'Math::BigInt'->new('-42')->beq($_);
                                                 },
                                       '_file' => '(eval 405)'
                                     }, 'Test2::Compare::Custom' ),
               'answer' => bless( {
                                    '_lines' => [
                                                  6
                                                ],
                                    '_file' => '(eval 408)',
                                    'code' => sub {
                                                  BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                  use strict;
                                                  no feature ':all';
                                                  use feature ':5.16';
                                                  require Math::BigInt;
                                                  'Math::BigInt'->new('42')->beq($_);
                                              },
                                    'operator' => 'CODE(...)',
                                    'name' => '<Custom Code>'
                                  }, 'Test2::Compare::Custom' ),
               'zero' => bless( {
                                  '_lines' => [
                                                6
                                              ],
                                  'code' => sub {
                                                BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                use strict;
                                                no feature ':all';
                                                use feature ':5.16';
                                                require Math::BigInt;
                                                'Math::BigInt'->new('0')->beq($_);
                                            },
                                  '_file' => '(eval 407)',
                                  'operator' => 'CODE(...)',
                                  'name' => '<Custom Code>'
                                }, 'Test2::Compare::Custom' )
             };


my $actual = from_toml(q{answer = 42
posanswer = +42
neganswer = -42
zero = 0
});

is($actual, $expected1, 'integer - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ from_toml(to_toml($actual)) }, $actual, 'integer - to_toml') or do{
  diag 'INPUT:';
  diag Dumper($actual);

  diag 'TOML OUTPUT:';
  diag to_toml($actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml($actual)));
};

done_testing;