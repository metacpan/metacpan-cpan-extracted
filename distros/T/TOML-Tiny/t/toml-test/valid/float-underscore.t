# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use Data::Dumper;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $expected1 = {
               'before' => bless( {
                                    '_file' => '(eval 393)',
                                    'code' => sub {
                                                  BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                  use strict;
                                                  no feature ':all';
                                                  use feature ':5.16';
                                                  require Math::BigFloat;
                                                  'Math::BigFloat'->new('3141.5927')->beq($_);
                                              },
                                    '_lines' => [
                                                  6
                                                ],
                                    'name' => '<Custom Code>',
                                    'operator' => 'CODE(...)'
                                  }, 'Test2::Compare::Custom' ),
               'after' => bless( {
                                   '_lines' => [
                                                 6
                                               ],
                                   'code' => sub {
                                                 BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                 use strict;
                                                 no feature ':all';
                                                 use feature ':5.16';
                                                 require Math::BigFloat;
                                                 'Math::BigFloat'->new('3141.5927')->beq($_);
                                             },
                                   'operator' => 'CODE(...)',
                                   'name' => '<Custom Code>',
                                   '_file' => '(eval 392)'
                                 }, 'Test2::Compare::Custom' ),
               'exponent' => bless( {
                                      '_file' => '(eval 391)',
                                      'operator' => 'CODE(...)',
                                      'name' => '<Custom Code>',
                                      'code' => sub {
                                                    BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                    use strict;
                                                    no feature ':all';
                                                    use feature ':5.16';
                                                    require Math::BigFloat;
                                                    'Math::BigFloat'->new('3e14')->beq($_);
                                                },
                                      '_lines' => [
                                                    6
                                                  ]
                                    }, 'Test2::Compare::Custom' )
             };


my $actual = from_toml(q{before = 3_141.5927
after = 3141.592_7
exponent = 3e1_4
});

is($actual, $expected1, 'float-underscore - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ from_toml(to_toml($actual)) }, $actual, 'float-underscore - to_toml') or do{
  diag 'INPUT:';
  diag Dumper($actual);

  diag 'TOML OUTPUT:';
  diag to_toml($actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml($actual)));
};

done_testing;