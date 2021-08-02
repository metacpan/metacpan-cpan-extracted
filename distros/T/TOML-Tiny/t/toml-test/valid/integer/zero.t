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

open my $fh, '<', "./t/toml-test/valid/integer/zero.toml" or die $!;
binmode $fh, ':encoding(UTF-8)';
my $toml = do{ local $/; <$fh>; };
close $fh;

my $expected1 = {
               "a2" => bless( {
                                "_file" => "(eval 258)",
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
                                              'Math::BigInt'->new('0')->beq($got);
                                          },
                                "name" => "Math::BigInt->new(\"0\")->beq(\$_)",
                                "operator" => "CODE(...)"
                              }, 'Test2::Compare::Custom' ),
               "a3" => bless( {
                                "_file" => "(eval 249)",
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
                                              'Math::BigInt'->new('0')->beq($got);
                                          },
                                "name" => "Math::BigInt->new(\"0\")->beq(\$_)",
                                "operator" => "CODE(...)"
                              }, 'Test2::Compare::Custom' ),
               "b1" => bless( {
                                "_file" => "(eval 253)",
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
                                              'Math::BigInt'->new('0')->beq($got);
                                          },
                                "name" => "Math::BigInt->new(\"0\")->beq(\$_)",
                                "operator" => "CODE(...)"
                              }, 'Test2::Compare::Custom' ),
               "b2" => bless( {
                                "_file" => "(eval 260)",
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
                                              'Math::BigInt'->new('0')->beq($got);
                                          },
                                "name" => "Math::BigInt->new(\"0\")->beq(\$_)",
                                "operator" => "CODE(...)"
                              }, 'Test2::Compare::Custom' ),
               "b3" => bless( {
                                "_file" => "(eval 252)",
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
                                              'Math::BigInt'->new('0')->beq($got);
                                          },
                                "name" => "Math::BigInt->new(\"0\")->beq(\$_)",
                                "operator" => "CODE(...)"
                              }, 'Test2::Compare::Custom' ),
               "d1" => bless( {
                                "_file" => "(eval 256)",
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
                                              'Math::BigInt'->new('0')->beq($got);
                                          },
                                "name" => "Math::BigInt->new(\"0\")->beq(\$_)",
                                "operator" => "CODE(...)"
                              }, 'Test2::Compare::Custom' ),
               "d2" => bless( {
                                "_file" => "(eval 250)",
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
                                              'Math::BigInt'->new('0')->beq($got);
                                          },
                                "name" => "Math::BigInt->new(\"0\")->beq(\$_)",
                                "operator" => "CODE(...)"
                              }, 'Test2::Compare::Custom' ),
               "d3" => bless( {
                                "_file" => "(eval 259)",
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
                                              'Math::BigInt'->new('0')->beq($got);
                                          },
                                "name" => "Math::BigInt->new(\"0\")->beq(\$_)",
                                "operator" => "CODE(...)"
                              }, 'Test2::Compare::Custom' ),
               "h1" => bless( {
                                "_file" => "(eval 251)",
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
                                              'Math::BigInt'->new('0')->beq($got);
                                          },
                                "name" => "Math::BigInt->new(\"0\")->beq(\$_)",
                                "operator" => "CODE(...)"
                              }, 'Test2::Compare::Custom' ),
               "h2" => bless( {
                                "_file" => "(eval 255)",
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
                                              'Math::BigInt'->new('0')->beq($got);
                                          },
                                "name" => "Math::BigInt->new(\"0\")->beq(\$_)",
                                "operator" => "CODE(...)"
                              }, 'Test2::Compare::Custom' ),
               "h3" => bless( {
                                "_file" => "(eval 254)",
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
                                              'Math::BigInt'->new('0')->beq($got);
                                          },
                                "name" => "Math::BigInt->new(\"0\")->beq(\$_)",
                                "operator" => "CODE(...)"
                              }, 'Test2::Compare::Custom' ),
               "o1" => bless( {
                                "_file" => "(eval 257)",
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
                                              'Math::BigInt'->new('0')->beq($got);
                                          },
                                "name" => "Math::BigInt->new(\"0\")->beq(\$_)",
                                "operator" => "CODE(...)"
                              }, 'Test2::Compare::Custom' )
             };


my $actual = from_toml($toml);

is($actual, $expected1, 'integer/zero - from_toml') or do{
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

ok(!$error, 'integer/zero - to_toml - no errors')
  or diag $error;

is($reparsed, $expected1, 'integer/zero - to_toml') or do{
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