# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use Data::Dumper;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $expected1 = {
               'pointlower' => bless( {
                                        '_file' => '(eval 387)',
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
                                                      require Math::BigFloat;
                                                      'Math::BigFloat'->new('310.0')->beq($_);
                                                  }
                                      }, 'Test2::Compare::Custom' ),
               'pointupper' => bless( {
                                        '_file' => '(eval 388)',
                                        'name' => '<Custom Code>',
                                        'operator' => 'CODE(...)',
                                        'code' => sub {
                                                      BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                      use strict;
                                                      no feature ':all';
                                                      use feature ':5.16';
                                                      require Math::BigFloat;
                                                      'Math::BigFloat'->new('310.0')->beq($_);
                                                  },
                                        '_lines' => [
                                                      6
                                                    ]
                                      }, 'Test2::Compare::Custom' ),
               'pos' => bless( {
                                 'code' => sub {
                                               BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                               use strict;
                                               no feature ':all';
                                               use feature ':5.16';
                                               require Math::BigFloat;
                                               'Math::BigFloat'->new('300.0')->beq($_);
                                           },
                                 '_lines' => [
                                               6
                                             ],
                                 'name' => '<Custom Code>',
                                 'operator' => 'CODE(...)',
                                 '_file' => '(eval 389)'
                               }, 'Test2::Compare::Custom' ),
               'zero' => bless( {
                                  '_file' => '(eval 390)',
                                  'name' => '<Custom Code>',
                                  'operator' => 'CODE(...)',
                                  'code' => sub {
                                                BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                use strict;
                                                no feature ':all';
                                                use feature ':5.16';
                                                require Math::BigFloat;
                                                'Math::BigFloat'->new('3.0')->beq($_);
                                            },
                                  '_lines' => [
                                                6
                                              ]
                                }, 'Test2::Compare::Custom' ),
               'upper' => bless( {
                                   'name' => '<Custom Code>',
                                   'operator' => 'CODE(...)',
                                   'code' => sub {
                                                 BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                 use strict;
                                                 no feature ':all';
                                                 use feature ':5.16';
                                                 require Math::BigFloat;
                                                 'Math::BigFloat'->new('300.0')->beq($_);
                                             },
                                   '_lines' => [
                                                 6
                                               ],
                                   '_file' => '(eval 385)'
                                 }, 'Test2::Compare::Custom' ),
               'lower' => bless( {
                                   'name' => '<Custom Code>',
                                   'operator' => 'CODE(...)',
                                   'code' => sub {
                                                 BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                 use strict;
                                                 no feature ':all';
                                                 use feature ':5.16';
                                                 require Math::BigFloat;
                                                 'Math::BigFloat'->new('300.0')->beq($_);
                                             },
                                   '_lines' => [
                                                 6
                                               ],
                                   '_file' => '(eval 384)'
                                 }, 'Test2::Compare::Custom' ),
               'neg' => bless( {
                                 '_file' => '(eval 386)',
                                 'operator' => 'CODE(...)',
                                 'name' => '<Custom Code>',
                                 'code' => sub {
                                               BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                               use strict;
                                               no feature ':all';
                                               use feature ':5.16';
                                               require Math::BigFloat;
                                               'Math::BigFloat'->new('0.03')->beq($_);
                                           },
                                 '_lines' => [
                                               6
                                             ]
                               }, 'Test2::Compare::Custom' )
             };


my $actual = from_toml(q{lower = 3e2
upper = 3E2
neg = 3e-2
pos = 3E+2
zero = 3e0
pointlower = 3.1e2
pointupper = 3.1E2
});

is($actual, $expected1, 'float-exponent - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ from_toml(to_toml($actual)) }, $actual, 'float-exponent - to_toml') or do{
  diag 'INPUT:';
  diag Dumper($actual);

  diag 'TOML OUTPUT:';
  diag to_toml($actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml($actual)));
};

done_testing;