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
               'numoffset' => bless( {
                                       '_file' => '(eval 319)',
                                       'name' => '<Custom Code>',
                                       'code' => sub {
                                                     BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                     use strict;
                                                     no feature ':all';
                                                     use feature ':5.16';
                                                     my $exp = 'DateTime::Format::RFC3339'->parse_datetime('1977-06-28T12:32:00Z');
                                                     my $got = 'DateTime::Format::RFC3339'->parse_datetime($_);
                                                     $exp->set_time_zone('UTC');
                                                     $got->set_time_zone('UTC');
                                                     return 'DateTime'->compare($got, $exp) == 0;
                                                 },
                                       'operator' => 'CODE(...)',
                                       '_lines' => [
                                                     11
                                                   ]
                                     }, 'Test2::Compare::Custom' ),
               'milliseconds' => bless( {
                                          '_lines' => [
                                                        11
                                                      ],
                                          'operator' => 'CODE(...)',
                                          'code' => sub {
                                                        BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                        use strict;
                                                        no feature ':all';
                                                        use feature ':5.16';
                                                        my $exp = 'DateTime::Format::RFC3339'->parse_datetime('1977-12-21T03:32:00.555+00:00');
                                                        my $got = 'DateTime::Format::RFC3339'->parse_datetime($_);
                                                        $exp->set_time_zone('UTC');
                                                        $got->set_time_zone('UTC');
                                                        return 'DateTime'->compare($got, $exp) == 0;
                                                    },
                                          'name' => '<Custom Code>',
                                          '_file' => '(eval 317)'
                                        }, 'Test2::Compare::Custom' ),
               'bestdayever' => bless( {
                                         'name' => '<Custom Code>',
                                         '_file' => '(eval 318)',
                                         'operator' => 'CODE(...)',
                                         '_lines' => [
                                                       11
                                                     ],
                                         'code' => sub {
                                                       BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                       use strict;
                                                       no feature ':all';
                                                       use feature ':5.16';
                                                       my $exp = 'DateTime::Format::RFC3339'->parse_datetime('1987-07-05T17:45:00Z');
                                                       my $got = 'DateTime::Format::RFC3339'->parse_datetime($_);
                                                       $exp->set_time_zone('UTC');
                                                       $got->set_time_zone('UTC');
                                                       return 'DateTime'->compare($got, $exp) == 0;
                                                   }
                                       }, 'Test2::Compare::Custom' )
             };


my $actual = from_toml(q{bestdayever = 1987-07-05T17:45:00Z
numoffset = 1977-06-28T07:32:00-05:00
milliseconds = 1977-12-21T10:32:00.555+07:00
});

is($actual, $expected1, 'datetime - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag '';
  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ scalar from_toml(to_toml($actual)) }, $expected1, 'datetime - to_toml') or do{
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