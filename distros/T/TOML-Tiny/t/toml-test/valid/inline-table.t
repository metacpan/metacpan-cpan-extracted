# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use Data::Dumper;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $expected1 = {
               'name' => {
                           'first' => 'Tom',
                           'last' => 'Preston-Werner'
                         },
               'point' => {
                            'y' => bless( {
                                            '_file' => '(eval 399)',
                                            'code' => sub {
                                                          BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                          use strict;
                                                          no feature ':all';
                                                          use feature ':5.16';
                                                          require Math::BigInt;
                                                          'Math::BigInt'->new('2')->beq($_);
                                                      },
                                            '_lines' => [
                                                          6
                                                        ],
                                            'operator' => 'CODE(...)',
                                            'name' => '<Custom Code>'
                                          }, 'Test2::Compare::Custom' ),
                            'x' => bless( {
                                            'name' => '<Custom Code>',
                                            'operator' => 'CODE(...)',
                                            'code' => sub {
                                                          BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                          use strict;
                                                          no feature ':all';
                                                          use feature ':5.16';
                                                          require Math::BigInt;
                                                          'Math::BigInt'->new('1')->beq($_);
                                                      },
                                            '_lines' => [
                                                          6
                                                        ],
                                            '_file' => '(eval 400)'
                                          }, 'Test2::Compare::Custom' )
                          },
               'simple' => {
                             'a' => bless( {
                                             '_file' => '(eval 401)',
                                             '_lines' => [
                                                           6
                                                         ],
                                             'code' => sub {
                                                           BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                           use strict;
                                                           no feature ':all';
                                                           use feature ':5.16';
                                                           require Math::BigInt;
                                                           'Math::BigInt'->new('1')->beq($_);
                                                       },
                                             'operator' => 'CODE(...)',
                                             'name' => '<Custom Code>'
                                           }, 'Test2::Compare::Custom' )
                           },
               'str-key' => {
                              'a' => bless( {
                                              'name' => '<Custom Code>',
                                              'operator' => 'CODE(...)',
                                              '_lines' => [
                                                            6
                                                          ],
                                              'code' => sub {
                                                            BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                            use strict;
                                                            no feature ':all';
                                                            use feature ':5.16';
                                                            require Math::BigInt;
                                                            'Math::BigInt'->new('1')->beq($_);
                                                        },
                                              '_file' => '(eval 404)'
                                            }, 'Test2::Compare::Custom' )
                            },
               'table-array' => [
                                  {
                                    'a' => bless( {
                                                    'operator' => 'CODE(...)',
                                                    'name' => '<Custom Code>',
                                                    '_lines' => [
                                                                  6
                                                                ],
                                                    'code' => sub {
                                                                  BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                                  use strict;
                                                                  no feature ':all';
                                                                  use feature ':5.16';
                                                                  require Math::BigInt;
                                                                  'Math::BigInt'->new('1')->beq($_);
                                                              },
                                                    '_file' => '(eval 402)'
                                                  }, 'Test2::Compare::Custom' )
                                  },
                                  {
                                    'b' => bless( {
                                                    '_file' => '(eval 403)',
                                                    'operator' => 'CODE(...)',
                                                    'name' => '<Custom Code>',
                                                    '_lines' => [
                                                                  6
                                                                ],
                                                    'code' => sub {
                                                                  BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                                  use strict;
                                                                  no feature ':all';
                                                                  use feature ':5.16';
                                                                  require Math::BigInt;
                                                                  'Math::BigInt'->new('2')->beq($_);
                                                              }
                                                  }, 'Test2::Compare::Custom' )
                                  }
                                ]
             };


my $actual = from_toml(q{name = { first = "Tom", last = "Preston-Werner" }
point = { x = 1, y = 2 }
simple = { a = 1 }
str-key = { "a" = 1 }
table-array = [{ "a" = 1 }, { "b" = 2 }]
});

is($actual, $expected1, 'inline-table - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ from_toml(to_toml($actual)) }, $actual, 'inline-table - to_toml') or do{
  diag 'INPUT:';
  diag Dumper($actual);

  diag 'TOML OUTPUT:';
  diag to_toml($actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml($actual)));
};

done_testing;