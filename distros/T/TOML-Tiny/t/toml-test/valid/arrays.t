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
               'ints' => [
                           bless( {
                                    'name' => 'Math::BigInt->new("1")->beq($_)',
                                    '_file' => '(eval 307)',
                                    '_lines' => [
                                                  7
                                                ],
                                    'operator' => 'CODE(...)',
                                    'code' => sub {
                                                  BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                  use strict;
                                                  no feature ':all';
                                                  use feature ':5.16';
                                                  require Math::BigInt;
                                                  my $got = 'Math::BigInt'->new($_);
                                                  'Math::BigInt'->new('1')->beq($got);
                                              }
                                  }, 'Test2::Compare::Custom' ),
                           bless( {
                                    'name' => 'Math::BigInt->new("2")->beq($_)',
                                    '_file' => '(eval 308)',
                                    'operator' => 'CODE(...)',
                                    '_lines' => [
                                                  7
                                                ],
                                    'code' => sub {
                                                  BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                  use strict;
                                                  no feature ':all';
                                                  use feature ':5.16';
                                                  require Math::BigInt;
                                                  my $got = 'Math::BigInt'->new($_);
                                                  'Math::BigInt'->new('2')->beq($got);
                                              }
                                  }, 'Test2::Compare::Custom' ),
                           bless( {
                                    '_lines' => [
                                                  7
                                                ],
                                    'operator' => 'CODE(...)',
                                    'code' => sub {
                                                  BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                  use strict;
                                                  no feature ':all';
                                                  use feature ':5.16';
                                                  require Math::BigInt;
                                                  my $got = 'Math::BigInt'->new($_);
                                                  'Math::BigInt'->new('3')->beq($got);
                                              },
                                    'name' => 'Math::BigInt->new("3")->beq($_)',
                                    '_file' => '(eval 309)'
                                  }, 'Test2::Compare::Custom' )
                         ],
               'dates' => [
                            bless( {
                                     '_lines' => [
                                                   11
                                                 ],
                                     'operator' => 'CODE(...)',
                                     'code' => sub {
                                                   BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                   use strict;
                                                   no feature ':all';
                                                   use feature ':5.16';
                                                   my $exp = 'DateTime::Format::RFC3339'->parse_datetime('1987-07-05T17:45:00Z');
                                                   my $got = 'DateTime::Format::RFC3339'->parse_datetime($_);
                                                   $exp->set_time_zone('UTC');
                                                   $got->set_time_zone('UTC');
                                                   return 'DateTime'->compare($got, $exp) == 0;
                                               },
                                     'name' => '<Custom Code>',
                                     '_file' => '(eval 85)'
                                   }, 'Test2::Compare::Custom' ),
                            bless( {
                                     'name' => '<Custom Code>',
                                     '_file' => '(eval 305)',
                                     '_lines' => [
                                                   11
                                                 ],
                                     'operator' => 'CODE(...)',
                                     'code' => sub {
                                                   BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                   use strict;
                                                   no feature ':all';
                                                   use feature ':5.16';
                                                   my $exp = 'DateTime::Format::RFC3339'->parse_datetime('1979-05-27T07:32:00Z');
                                                   my $got = 'DateTime::Format::RFC3339'->parse_datetime($_);
                                                   $exp->set_time_zone('UTC');
                                                   $got->set_time_zone('UTC');
                                                   return 'DateTime'->compare($got, $exp) == 0;
                                               }
                                   }, 'Test2::Compare::Custom' ),
                            bless( {
                                     'code' => sub {
                                                   BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                   use strict;
                                                   no feature ':all';
                                                   use feature ':5.16';
                                                   my $exp = 'DateTime::Format::RFC3339'->parse_datetime('2006-06-01T11:00:00Z');
                                                   my $got = 'DateTime::Format::RFC3339'->parse_datetime($_);
                                                   $exp->set_time_zone('UTC');
                                                   $got->set_time_zone('UTC');
                                                   return 'DateTime'->compare($got, $exp) == 0;
                                               },
                                     'operator' => 'CODE(...)',
                                     '_lines' => [
                                                   11
                                                 ],
                                     '_file' => '(eval 306)',
                                     'name' => '<Custom Code>'
                                   }, 'Test2::Compare::Custom' )
                          ],
               'floats' => [
                             bless( {
                                      'name' => 'Math::BigFloat->new("1.1")->beq($_)',
                                      '_file' => '(eval 82)',
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
                                                    'Math::BigFloat'->new('1.1')->beq($got);
                                                }
                                    }, 'Test2::Compare::Custom' ),
                             bless( {
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
                                                    'Math::BigFloat'->new('2.1')->beq($got);
                                                },
                                      'name' => 'Math::BigFloat->new("2.1")->beq($_)',
                                      '_file' => '(eval 83)'
                                    }, 'Test2::Compare::Custom' ),
                             bless( {
                                      '_file' => '(eval 84)',
                                      'name' => 'Math::BigFloat->new("3.1")->beq($_)',
                                      'code' => sub {
                                                    BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                    use strict;
                                                    no feature ':all';
                                                    use feature ':5.16';
                                                    require Math::BigFloat;
                                                    my $got = 'Math::BigFloat'->new($_);
                                                    'Math::BigFloat'->new('3.1')->beq($got);
                                                },
                                      '_lines' => [
                                                    7
                                                  ],
                                      'operator' => 'CODE(...)'
                                    }, 'Test2::Compare::Custom' )
                           ],
               'comments' => [
                               bless( {
                                        'operator' => 'CODE(...)',
                                        '_lines' => [
                                                      7
                                                    ],
                                        'code' => sub {
                                                      BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                      use strict;
                                                      no feature ':all';
                                                      use feature ':5.16';
                                                      require Math::BigInt;
                                                      my $got = 'Math::BigInt'->new($_);
                                                      'Math::BigInt'->new('1')->beq($got);
                                                  },
                                        'name' => 'Math::BigInt->new("1")->beq($_)',
                                        '_file' => '(eval 80)'
                                      }, 'Test2::Compare::Custom' ),
                               bless( {
                                        'operator' => 'CODE(...)',
                                        '_lines' => [
                                                      7
                                                    ],
                                        'code' => sub {
                                                      BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                      use strict;
                                                      no feature ':all';
                                                      use feature ':5.16';
                                                      require Math::BigInt;
                                                      my $got = 'Math::BigInt'->new($_);
                                                      'Math::BigInt'->new('2')->beq($got);
                                                  },
                                        'name' => 'Math::BigInt->new("2")->beq($_)',
                                        '_file' => '(eval 81)'
                                      }, 'Test2::Compare::Custom' )
                             ],
               'strings' => [
                              'a',
                              'b',
                              'c'
                            ]
             };


my $actual = from_toml(q{ints = [1, 2, 3]
floats = [1.1, 2.1, 3.1]
strings = ["a", "b", "c"]
dates = [
  1987-07-05T17:45:00Z,
  1979-05-27T07:32:00Z,
  2006-06-01T11:00:00Z,
]
comments = [
         1,
         2, #this is ok
]
});

is($actual, $expected1, 'arrays - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag '';
  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ scalar from_toml(to_toml($actual)) }, $expected1, 'arrays - to_toml') or do{
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