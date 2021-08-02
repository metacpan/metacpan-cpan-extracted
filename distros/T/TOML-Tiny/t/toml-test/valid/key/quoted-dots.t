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

open my $fh, '<', "./t/toml-test/valid/key/quoted-dots.toml" or die $!;
binmode $fh, ':encoding(UTF-8)';
my $toml = do{ local $/; <$fh>; };
close $fh;

my $expected1 = {
               "plain" => bless( {
                                   "_file" => "(eval 289)",
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
               "plain_table" => {
                                  "plain" => bless( {
                                                      "_file" => "(eval 287)",
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
                                                    }, 'Test2::Compare::Custom' ),
                                  "with.dot" => bless( {
                                                         "_file" => "(eval 288)",
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
                                                                       'Math::BigInt'->new('4')->beq($got);
                                                                   },
                                                         "name" => "Math::BigInt->new(\"4\")->beq(\$_)",
                                                         "operator" => "CODE(...)"
                                                       }, 'Test2::Compare::Custom' )
                                },
               "table" => {
                            "withdot" => {
                                           "key.with.dots" => bless( {
                                                                       "_file" => "(eval 285)",
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
                                                                                     'Math::BigInt'->new('6')->beq($got);
                                                                                 },
                                                                       "name" => "Math::BigInt->new(\"6\")->beq(\$_)",
                                                                       "operator" => "CODE(...)"
                                                                     }, 'Test2::Compare::Custom' ),
                                           "plain" => bless( {
                                                               "_file" => "(eval 286)",
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
                                                                             'Math::BigInt'->new('5')->beq($got);
                                                                         },
                                                               "name" => "Math::BigInt->new(\"5\")->beq(\$_)",
                                                               "operator" => "CODE(...)"
                                                             }, 'Test2::Compare::Custom' )
                                         }
                          },
               "with.dot" => bless( {
                                      "_file" => "(eval 284)",
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
             };


my $actual = from_toml($toml);

is($actual, $expected1, 'key/quoted-dots - from_toml') or do{
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

ok(!$error, 'key/quoted-dots - to_toml - no errors')
  or diag $error;

is($reparsed, $expected1, 'key/quoted-dots - to_toml') or do{
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