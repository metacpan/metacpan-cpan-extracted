# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use Data::Dumper;
use Math::BigInt;
use Math::BigFloat;
use TOML::Tiny;

local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Useqq    = 1;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

open my $fh, '<', "./t/toml-test/valid/inline-table/inline-table.toml" or die $!;
binmode $fh, ':encoding(UTF-8)';
my $toml = do{ local $/; <$fh>; };
close $fh;

my $expected1 = {
               "name" => {
                           "first" => "Tom",
                           "last" => "Preston-Werner"
                         },
               "point" => {
                            "x" => bless( {
                                            "_file" => "(eval 207)",
                                            "_lines" => [
                                                          7
                                                        ],
                                            "code" => sub {
                                                          BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                          use strict;
                                                          no feature ':all';
                                                          use feature ':5.16';
                                                          require Math::BigInt;
                                                          my $got = 'Math::BigInt'->new($_);
                                                          'Math::BigInt'->new('1')->beq($got);
                                                      },
                                            "name" => "Math::BigInt->new(\"1\")->beq(\$_)",
                                            "operator" => "CODE(...)"
                                          }, 'Test2::Compare::Custom' ),
                            "y" => bless( {
                                            "_file" => "(eval 208)",
                                            "_lines" => [
                                                          7
                                                        ],
                                            "code" => sub {
                                                          BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                          use strict;
                                                          no feature ':all';
                                                          use feature ':5.16';
                                                          require Math::BigInt;
                                                          my $got = 'Math::BigInt'->new($_);
                                                          'Math::BigInt'->new('2')->beq($got);
                                                      },
                                            "name" => "Math::BigInt->new(\"2\")->beq(\$_)",
                                            "operator" => "CODE(...)"
                                          }, 'Test2::Compare::Custom' )
                          },
               "simple" => {
                             "a" => bless( {
                                             "_file" => "(eval 209)",
                                             "_lines" => [
                                                           7
                                                         ],
                                             "code" => sub {
                                                           BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                           use strict;
                                                           no feature ':all';
                                                           use feature ':5.16';
                                                           require Math::BigInt;
                                                           my $got = 'Math::BigInt'->new($_);
                                                           'Math::BigInt'->new('1')->beq($got);
                                                       },
                                             "name" => "Math::BigInt->new(\"1\")->beq(\$_)",
                                             "operator" => "CODE(...)"
                                           }, 'Test2::Compare::Custom' )
                           },
               "str-key" => {
                              "a" => bless( {
                                              "_file" => "(eval 204)",
                                              "_lines" => [
                                                            7
                                                          ],
                                              "code" => sub {
                                                            BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                            use strict;
                                                            no feature ':all';
                                                            use feature ':5.16';
                                                            require Math::BigInt;
                                                            my $got = 'Math::BigInt'->new($_);
                                                            'Math::BigInt'->new('1')->beq($got);
                                                        },
                                              "name" => "Math::BigInt->new(\"1\")->beq(\$_)",
                                              "operator" => "CODE(...)"
                                            }, 'Test2::Compare::Custom' )
                            },
               "table-array" => [
                                  {
                                    "a" => bless( {
                                                    "_file" => "(eval 205)",
                                                    "_lines" => [
                                                                  7
                                                                ],
                                                    "code" => sub {
                                                                  BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                                  use strict;
                                                                  no feature ':all';
                                                                  use feature ':5.16';
                                                                  require Math::BigInt;
                                                                  my $got = 'Math::BigInt'->new($_);
                                                                  'Math::BigInt'->new('1')->beq($got);
                                                              },
                                                    "name" => "Math::BigInt->new(\"1\")->beq(\$_)",
                                                    "operator" => "CODE(...)"
                                                  }, 'Test2::Compare::Custom' )
                                  },
                                  {
                                    "b" => bless( {
                                                    "_file" => "(eval 206)",
                                                    "_lines" => [
                                                                  7
                                                                ],
                                                    "code" => sub {
                                                                  BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                                  use strict;
                                                                  no feature ':all';
                                                                  use feature ':5.16';
                                                                  require Math::BigInt;
                                                                  my $got = 'Math::BigInt'->new($_);
                                                                  'Math::BigInt'->new('2')->beq($got);
                                                              },
                                                    "name" => "Math::BigInt->new(\"2\")->beq(\$_)",
                                                    "operator" => "CODE(...)"
                                                  }, 'Test2::Compare::Custom' )
                                  }
                                ]
             };


my $actual = from_toml($toml);

is($actual, $expected1, 'inline-table/inline-table - from_toml') or do{
  diag 'TOML INPUT:';
  diag "$toml";

  diag '';
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag '';
  diag 'ACTUAL:';
  diag Dumper($actual);
};

my $regenerated = to_toml $actual;
my $reparsed    = eval{ scalar from_toml $regenerated };
my $error       = $@;

ok(!$error, 'inline-table/inline-table - to_toml - no errors')
  or diag $error;

is($reparsed, $expected1, 'inline-table/inline-table - to_toml') or do{
  diag "ERROR: $error" if $error;

  diag '';
  diag 'PARSED FROM TEST SOURCE TOML:';
  diag Dumper($actual);

  diag '';
  diag 'REGENERATED TOML:';
  diag $regenerated;

  diag '';
  diag 'REPARSED FROM REGENERATED TOML:';
  diag Dumper($reparsed);
};

done_testing;