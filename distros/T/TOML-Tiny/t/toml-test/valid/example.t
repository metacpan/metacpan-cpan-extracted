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

open my $fh, '<', "./t/toml-test/valid/example.toml" or die $!;
binmode $fh, ':encoding(UTF-8)';
my $toml = do{ local $/; <$fh>; };
close $fh;

my $expected1 = {
               "best-day-ever" => "1987-07-05T17:45:00Z",
               "numtheory" => {
                                "boring" => 0,
                                "perfection" => [
                                                  bless( {
                                                           "_file" => "(eval 164)",
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
                                                  bless( {
                                                           "_file" => "(eval 165)",
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
                                                                         'Math::BigInt'->new('28')->beq($got);
                                                                     },
                                                           "name" => "Math::BigInt->new(\"28\")->beq(\$_)",
                                                           "operator" => "CODE(...)"
                                                         }, 'Test2::Compare::Custom' ),
                                                  bless( {
                                                           "_file" => "(eval 166)",
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
                                                                         'Math::BigInt'->new('496')->beq($got);
                                                                     },
                                                           "name" => "Math::BigInt->new(\"496\")->beq(\$_)",
                                                           "operator" => "CODE(...)"
                                                         }, 'Test2::Compare::Custom' )
                                                ]
                              }
             };


my $actual = from_toml($toml);

is($actual, $expected1, 'example - from_toml') or do{
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

ok(!$error, 'example - to_toml - no errors')
  or diag $error;

is($reparsed, $expected1, 'example - to_toml') or do{
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