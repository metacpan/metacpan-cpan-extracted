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
               'albums' => [
                             {
                               'name' => 'Born to Run',
                               'songs' => [
                                            {
                                              'name' => 'Jungleland'
                                            },
                                            {
                                              'name' => 'Meeting Across the River'
                                            }
                                          ]
                             },
                             {
                               'name' => 'Born in the USA',
                               'songs' => [
                                            {
                                              'name' => 'Glory Days'
                                            },
                                            {
                                              'name' => 'Dancing in the Dark'
                                            }
                                          ]
                             }
                           ]
             };


my $actual = from_toml(q{[[albums]]
name = "Born to Run"

  [[albums.songs]]
  name = "Jungleland"

  [[albums.songs]]
  name = "Meeting Across the River"

[[albums]]
name = "Born in the USA"
  
  [[albums.songs]]
  name = "Glory Days"

  [[albums.songs]]
  name = "Dancing in the Dark"
});

is($actual, $expected1, 'table-array-nest - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag '';
  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ scalar from_toml(to_toml($actual)) }, $expected1, 'table-array-nest - to_toml') or do{
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