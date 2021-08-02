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

open my $fh, '<', "./t/toml-test/valid/integer/literals.toml" or die $!;
binmode $fh, ':encoding(UTF-8)';
my $toml = do{ local $/; <$fh>; };
close $fh;

my $expected1 = {
               "bin1" => bless( {
                                  "_file" => "(eval 236)",
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
                                                'Math::BigInt'->new('214')->beq($got);
                                            },
                                  "name" => "Math::BigInt->new(\"214\")->beq(\$_)",
                                  "operator" => "CODE(...)"
                                }, 'Test2::Compare::Custom' ),
               "bin2" => bless( {
                                  "_file" => "(eval 244)",
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
                                }, 'Test2::Compare::Custom' ),
               "hex1" => bless( {
                                  "_file" => "(eval 237)",
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
                                                'Math::BigInt'->new('3735928559')->beq($got);
                                            },
                                  "name" => "Math::BigInt->new(\"3735928559\")->beq(\$_)",
                                  "operator" => "CODE(...)"
                                }, 'Test2::Compare::Custom' ),
               "hex2" => bless( {
                                  "_file" => "(eval 242)",
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
                                                'Math::BigInt'->new('3735928559')->beq($got);
                                            },
                                  "name" => "Math::BigInt->new(\"3735928559\")->beq(\$_)",
                                  "operator" => "CODE(...)"
                                }, 'Test2::Compare::Custom' ),
               "hex3" => bless( {
                                  "_file" => "(eval 243)",
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
                                                'Math::BigInt'->new('3735928559')->beq($got);
                                            },
                                  "name" => "Math::BigInt->new(\"3735928559\")->beq(\$_)",
                                  "operator" => "CODE(...)"
                                }, 'Test2::Compare::Custom' ),
               "hex4" => bless( {
                                  "_file" => "(eval 240)",
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
                                                'Math::BigInt'->new('2439')->beq($got);
                                            },
                                  "name" => "Math::BigInt->new(\"2439\")->beq(\$_)",
                                  "operator" => "CODE(...)"
                                }, 'Test2::Compare::Custom' ),
               "oct1" => bless( {
                                  "_file" => "(eval 241)",
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
                                                'Math::BigInt'->new('342391')->beq($got);
                                            },
                                  "name" => "Math::BigInt->new(\"342391\")->beq(\$_)",
                                  "operator" => "CODE(...)"
                                }, 'Test2::Compare::Custom' ),
               "oct2" => bless( {
                                  "_file" => "(eval 239)",
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
                                                'Math::BigInt'->new('493')->beq($got);
                                            },
                                  "name" => "Math::BigInt->new(\"493\")->beq(\$_)",
                                  "operator" => "CODE(...)"
                                }, 'Test2::Compare::Custom' ),
               "oct3" => bless( {
                                  "_file" => "(eval 238)",
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
                                                'Math::BigInt'->new('501')->beq($got);
                                            },
                                  "name" => "Math::BigInt->new(\"501\")->beq(\$_)",
                                  "operator" => "CODE(...)"
                                }, 'Test2::Compare::Custom' )
             };


my $actual = from_toml($toml);

is($actual, $expected1, 'integer/literals - from_toml') or do{
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

ok(!$error, 'integer/literals - to_toml - no errors')
  or diag $error;

is($reparsed, $expected1, 'integer/literals - to_toml') or do{
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