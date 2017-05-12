#!/usr/bin/perl

use strict;
my %test_arg;
my %TESTS;
BEGIN {
%TESTS = (
  '001 scroll test' => {
    prompt => 'Enter/select a country: ',
    'IN' => "A\cp\cp\cuB\cn\cn\cuX\cp\cn\cuAZ\t\r",
    'OUT' => "Enter/select a country: A\ch \chAZERBAIJAN\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \chAUSTRIA\r\nEnter/select a country: B\ch \chBAHAMAS\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \chBAHRAIN\r\nEnter/select a country: X\a\a\r\nEnter/select a country: AZERBAIJAN\r\n",
    'RESULT' => 'AZERBAIJAN'
  },
);

  %test_arg = ( tests => 1 + 3 * keys(%TESTS) );
  eval { require IO::String; };
  if($@) {
    %test_arg = (skip_all => 'IO::String is required for testing Term::Completion');
  }
}
use Test::More %test_arg;

use_ok('Term::Completion');

# must do this here, when DATA is initialized
my @country;
chomp( @country = <DATA> );
for(@country) { s/[\r\n]+//g; }
$TESTS{'001 scroll test'}{choices} = \@country;

foreach my $test (sort keys %TESTS) {
  my %arg = %{$TESTS{$test}};
  my $in = delete($arg{IN}) . "END\n";
  my $in_fh = IO::String->new($in);
  my $out = '';
  my $out_fh = IO::String->new($out);
  my $expected_out = delete($arg{OUT});
  my $expected_result = delete($arg{RESULT});

  my $result = Term::Completion->new(
        in => $in_fh,
        out => $out_fh,
        columns => 80, rows => 24, # to suppress Term::Size on IO::String
        %arg
  )->complete();

  is($result, $expected_result, "$test: complete() returned correct value");
  is($out, $expected_out, "$test: correct data sent to terminal");
  $out =~ s#\t#\\t#g;
  $out =~ s#\r#\\r#g;
  $out =~ s#\n#\\n#g;
  $out =~ s#\a#\\a#g;
  $out =~ s#\ch#\\ch#g;
  $out =~ s#([\x00-\x1f])#sprintf("%%%02x",ord($1))#ge;
  $expected_out =~ s#\t#\\t#g;
  $expected_out =~ s#\r#\\r#g;
  $expected_out =~ s#\n#\\n#g;
  $expected_out =~ s#\a#\\a#g;
  $expected_out =~ s#\ch#\\ch#g;
  $expected_out =~ s#([\x00-\x1f])#sprintf("%%%02x",ord($1))#ge;
  #diag("out = '$out'\nexp = '$expected_out'\n");
  my $in_rest = <$in_fh>;
  is($in_rest, "END\n", "$test: input stream correctly used up");
} # loop tests

exit 0;

__DATA__
AFGHANISTAN
ÅLAND ISLANDS
ALBANIA
ALGERIA
AMERICAN SAMOA
ANDORRA
ANGOLA
ANGUILLA
ANTARCTICA
ANTIGUA AND BARBUDA
ARGENTINA
ARMENIA
ARUBA
AUSTRALIA
AUSTRIA
AZERBAIJAN
BAHAMAS
BAHRAIN
BANGLADESH
BARBADOS
BELARUS
BELGIUM
BELIZE
BENIN
BENIN
BERMUDA
BHUTAN
BOLIVIA, PLURINATIONAL STATE OF
BONAIRE, SINT EUSTATIUS AND SABA
BOSNIA AND HERZEGOVINA
BOTSWANA
BOUVET ISLAND
BRAZIL
BRITISH INDIAN OCEAN TERRITORY
BRUNEI DARUSSALAM
BULGARIA
BURKINA FASO
BURUNDI
CAMBODIA
CAMEROON
CANADA
