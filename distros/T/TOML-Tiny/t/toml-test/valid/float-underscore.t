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
               'before' => bless( {
                                    'name' => 'Math::BigFloat->new("3141.5927")->beq($_)',
                                    '_file' => '(eval 339)',
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
                                                  'Math::BigFloat'->new('3141.5927')->beq($got);
                                              }
                                  }, 'Test2::Compare::Custom' ),
               'exponent' => bless( {
                                      '_lines' => [
                                                    7
                                                  ],
                                      'operator' => 'CODE(...)',
                                      'code' => sub {
                                                    BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                    use strict;
                                                    no feature ':all';
                                                    use feature ':5.16';
                                                    require Math::BigFloat;
                                                    my $got = 'Math::BigFloat'->new($_);
                                                    'Math::BigFloat'->new('3e14')->beq($got);
                                                },
                                      'name' => 'Math::BigFloat->new("3e14")->beq($_)',
                                      '_file' => '(eval 341)'
                                    }, 'Test2::Compare::Custom' ),
               'after' => bless( {
                                   '_file' => '(eval 340)',
                                   'name' => 'Math::BigFloat->new("3141.5927")->beq($_)',
                                   'code' => sub {
                                                 BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                 use strict;
                                                 no feature ':all';
                                                 use feature ':5.16';
                                                 require Math::BigFloat;
                                                 my $got = 'Math::BigFloat'->new($_);
                                                 'Math::BigFloat'->new('3141.5927')->beq($got);
                                             },
                                   'operator' => 'CODE(...)',
                                   '_lines' => [
                                                 7
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

  diag '';
  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ scalar from_toml(to_toml($actual)) }, $expected1, 'float-underscore - to_toml') or do{
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