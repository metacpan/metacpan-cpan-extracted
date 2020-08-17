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
               'pointupper' => bless( {
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
                                                      'Math::BigFloat'->new('310.0')->beq($got);
                                                  },
                                        'name' => 'Math::BigFloat->new("310.0")->beq($_)',
                                        '_file' => '(eval 332)'
                                      }, 'Test2::Compare::Custom' ),
               'zero' => bless( {
                                  'code' => sub {
                                                BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                use strict;
                                                no feature ':all';
                                                use feature ':5.16';
                                                require Math::BigFloat;
                                                my $got = 'Math::BigFloat'->new($_);
                                                'Math::BigFloat'->new('3.0')->beq($got);
                                            },
                                  'operator' => 'CODE(...)',
                                  '_lines' => [
                                                7
                                              ],
                                  '_file' => '(eval 336)',
                                  'name' => 'Math::BigFloat->new("3.0")->beq($_)'
                                }, 'Test2::Compare::Custom' ),
               'pos' => bless( {
                                 'name' => 'Math::BigFloat->new("300.0")->beq($_)',
                                 '_file' => '(eval 337)',
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
                                               'Math::BigFloat'->new('300.0')->beq($got);
                                           }
                               }, 'Test2::Compare::Custom' ),
               'upper' => bless( {
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
                                                 'Math::BigFloat'->new('300.0')->beq($got);
                                             },
                                   'name' => 'Math::BigFloat->new("300.0")->beq($_)',
                                   '_file' => '(eval 334)'
                                 }, 'Test2::Compare::Custom' ),
               'pointlower' => bless( {
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
                                                      'Math::BigFloat'->new('310.0')->beq($got);
                                                  },
                                        'name' => 'Math::BigFloat->new("310.0")->beq($_)',
                                        '_file' => '(eval 335)'
                                      }, 'Test2::Compare::Custom' ),
               'lower' => bless( {
                                   'name' => 'Math::BigFloat->new("300.0")->beq($_)',
                                   '_file' => '(eval 333)',
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
                                                 'Math::BigFloat'->new('300.0')->beq($got);
                                             }
                                 }, 'Test2::Compare::Custom' ),
               'neg' => bless( {
                                 '_file' => '(eval 338)',
                                 'name' => 'Math::BigFloat->new("0.03")->beq($_)',
                                 'code' => sub {
                                               BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                               use strict;
                                               no feature ':all';
                                               use feature ':5.16';
                                               require Math::BigFloat;
                                               my $got = 'Math::BigFloat'->new($_);
                                               'Math::BigFloat'->new('0.03')->beq($got);
                                           },
                                 'operator' => 'CODE(...)',
                                 '_lines' => [
                                               7
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

  diag '';
  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ scalar from_toml(to_toml($actual)) }, $expected1, 'float-exponent - to_toml') or do{
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