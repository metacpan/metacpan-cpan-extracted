# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use Data::Dumper;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $expected1 = {
               'pi' => bless( {
                                '_lines' => [
                                              6
                                            ],
                                'code' => sub {
                                              BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                              use strict;
                                              no feature ':all';
                                              use feature ':5.16';
                                              require Math::BigFloat;
                                              'Math::BigFloat'->new('3.14')->beq($_);
                                          },
                                'operator' => 'CODE(...)',
                                'name' => '<Custom Code>',
                                '_file' => '(eval 381)'
                              }, 'Test2::Compare::Custom' ),
               'zero-intpart' => bless( {
                                          '_file' => '(eval 380)',
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
                                                        require Math::BigFloat;
                                                        'Math::BigFloat'->new('0.123')->beq($_);
                                                    }
                                        }, 'Test2::Compare::Custom' ),
               'pospi' => bless( {
                                   '_file' => '(eval 383)',
                                   'name' => '<Custom Code>',
                                   'operator' => 'CODE(...)',
                                   'code' => sub {
                                                 BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                 use strict;
                                                 no feature ':all';
                                                 use feature ':5.16';
                                                 require Math::BigFloat;
                                                 'Math::BigFloat'->new('3.14')->beq($_);
                                             },
                                   '_lines' => [
                                                 6
                                               ]
                                 }, 'Test2::Compare::Custom' ),
               'negpi' => bless( {
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
                                                 require Math::BigFloat;
                                                 'Math::BigFloat'->new('-3.14')->beq($_);
                                             },
                                   '_file' => '(eval 382)'
                                 }, 'Test2::Compare::Custom' )
             };


my $actual = from_toml(q{pi = 3.14
pospi = +3.14
negpi = -3.14
zero-intpart = 0.123
});

is($actual, $expected1, 'float - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ from_toml(to_toml($actual)) }, $actual, 'float - to_toml') or do{
  diag 'INPUT:';
  diag Dumper($actual);

  diag 'TOML OUTPUT:';
  diag to_toml($actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml($actual)));
};

done_testing;