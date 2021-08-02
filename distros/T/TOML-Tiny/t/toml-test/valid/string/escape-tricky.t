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

open my $fh, '<', "./t/toml-test/valid/string/escape-tricky.toml" or die $!;
binmode $fh, ':encoding(UTF-8)';
my $toml = do{ local $/; <$fh>; };
close $fh;

my $expected1 = {
               "end_esc" => "String does not end here\" but ends here\\",
               "lit_end_esc" => "String ends here\\",
               "lit_multiline_end" => "There is no escape\\",
               "lit_multiline_not_unicode" => "\\u007f",
               "multiline_end_esc" => "When will it end? \"\"\"...\"\"\" should be here\"",
               "multiline_not_unicode" => "\\u0041",
               "multiline_unicode" => "\x{a0}"
             };


my $actual = from_toml($toml);

is($actual, $expected1, 'string/escape-tricky - from_toml') or do{
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

ok(!$error, 'string/escape-tricky - to_toml - no errors')
  or diag $error;

is($reparsed, $expected1, 'string/escape-tricky - to_toml') or do{
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