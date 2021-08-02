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

open my $fh, '<', "./t/toml-test/valid/array/array.toml" or die $!;
binmode $fh, ':encoding(UTF-8)';
my $toml = do{ local $/; <$fh>; };
close $fh;

my $expected1 = {
               "comments" => [
                               bless( {
                                        "_file" => "(eval 116)",
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
                               bless( {
                                        "_file" => "(eval 117)",
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
                             ],
               "dates" => [
                            "1987-07-05T17:45:00Z",
                            "1979-05-27T07:32:00Z",
                            "2006-06-01T11:00:00Z"
                          ],
               "floats" => [
                             bless( {
                                      "_file" => "(eval 118)",
                                      "_lines" => [
                                                    7
                                                  ],
                                      "code" => sub {
                                                    BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                    use strict;
                                                    no feature ':all';
                                                    use feature ':5.16';
                                                    require Math::BigFloat;
                                                    my $got = 'Math::BigFloat'->new($_);
                                                    'Math::BigFloat'->new('1.1')->beq($got);
                                                },
                                      "name" => "Math::BigFloat->new(\"1.1\")->beq(\$_)",
                                      "operator" => "CODE(...)"
                                    }, 'Test2::Compare::Custom' ),
                             bless( {
                                      "_file" => "(eval 119)",
                                      "_lines" => [
                                                    7
                                                  ],
                                      "code" => sub {
                                                    BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                    use strict;
                                                    no feature ':all';
                                                    use feature ':5.16';
                                                    require Math::BigFloat;
                                                    my $got = 'Math::BigFloat'->new($_);
                                                    'Math::BigFloat'->new('2.1')->beq($got);
                                                },
                                      "name" => "Math::BigFloat->new(\"2.1\")->beq(\$_)",
                                      "operator" => "CODE(...)"
                                    }, 'Test2::Compare::Custom' ),
                             bless( {
                                      "_file" => "(eval 120)",
                                      "_lines" => [
                                                    7
                                                  ],
                                      "code" => sub {
                                                    BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                    use strict;
                                                    no feature ':all';
                                                    use feature ':5.16';
                                                    require Math::BigFloat;
                                                    my $got = 'Math::BigFloat'->new($_);
                                                    'Math::BigFloat'->new('3.1')->beq($got);
                                                },
                                      "name" => "Math::BigFloat->new(\"3.1\")->beq(\$_)",
                                      "operator" => "CODE(...)"
                                    }, 'Test2::Compare::Custom' )
                           ],
               "ints" => [
                           bless( {
                                    "_file" => "(eval 48)",
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
                           bless( {
                                    "_file" => "(eval 114)",
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
                                  }, 'Test2::Compare::Custom' ),
                           bless( {
                                    "_file" => "(eval 115)",
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
                                                  'Math::BigInt'->new('3')->beq($got);
                                              },
                                    "name" => "Math::BigInt->new(\"3\")->beq(\$_)",
                                    "operator" => "CODE(...)"
                                  }, 'Test2::Compare::Custom' )
                         ],
               "strings" => [
                              "a",
                              "b",
                              "c"
                            ]
             };


my $actual = from_toml($toml);

is($actual, $expected1, 'array/array - from_toml') or do{
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

ok(!$error, 'array/array - to_toml - no errors')
  or diag $error;

is($reparsed, $expected1, 'array/array - to_toml') or do{
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