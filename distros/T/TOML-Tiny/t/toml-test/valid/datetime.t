# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use Data::Dumper;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $expected1 = {
               'milliseconds' => bless( {
                                          'operator' => 'CODE(...)',
                                          'name' => '<Custom Code>',
                                          '_lines' => [
                                                        11
                                                      ],
                                          'code' => sub {
                                                        BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                        use strict;
                                                        no feature ':all';
                                                        use feature ':5.16';
                                                        my $exp = 'DateTime::Format::RFC3339'->parse_datetime('1977-12-21T03:32:00.555+00:00');
                                                        my $got = 'DateTime::Format::RFC3339'->parse_datetime($_);
                                                        $exp->set_time_zone('UTC');
                                                        $got->set_time_zone('UTC');
                                                        return 'DateTime'->compare($got, $exp) == 0;
                                                    },
                                          '_file' => '(eval 369)'
                                        }, 'Test2::Compare::Custom' ),
               'numoffset' => bless( {
                                       '_file' => '(eval 370)',
                                       'name' => '<Custom Code>',
                                       'operator' => 'CODE(...)',
                                       '_lines' => [
                                                     11
                                                   ],
                                       'code' => sub {
                                                     BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                     use strict;
                                                     no feature ':all';
                                                     use feature ':5.16';
                                                     my $exp = 'DateTime::Format::RFC3339'->parse_datetime('1977-06-28T12:32:00Z');
                                                     my $got = 'DateTime::Format::RFC3339'->parse_datetime($_);
                                                     $exp->set_time_zone('UTC');
                                                     $got->set_time_zone('UTC');
                                                     return 'DateTime'->compare($got, $exp) == 0;
                                                 }
                                     }, 'Test2::Compare::Custom' ),
               'bestdayever' => bless( {
                                         'name' => '<Custom Code>',
                                         'operator' => 'CODE(...)',
                                         '_lines' => [
                                                       11
                                                     ],
                                         'code' => sub {
                                                       BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                       use strict;
                                                       no feature ':all';
                                                       use feature ':5.16';
                                                       my $exp = 'DateTime::Format::RFC3339'->parse_datetime('1987-07-05T17:45:00Z');
                                                       my $got = 'DateTime::Format::RFC3339'->parse_datetime($_);
                                                       $exp->set_time_zone('UTC');
                                                       $got->set_time_zone('UTC');
                                                       return 'DateTime'->compare($got, $exp) == 0;
                                                   },
                                         '_file' => '(eval 371)'
                                       }, 'Test2::Compare::Custom' )
             };


my $actual = from_toml(q{bestdayever = 1987-07-05T17:45:00Z
numoffset = 1977-06-28T07:32:00-05:00
milliseconds = 1977-12-21T10:32:00.555+07:00
});

is($actual, $expected1, 'datetime - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ from_toml(to_toml($actual)) }, $actual, 'datetime - to_toml') or do{
  diag 'INPUT:';
  diag Dumper($actual);

  diag 'TOML OUTPUT:';
  diag to_toml($actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml($actual)));
};

done_testing;