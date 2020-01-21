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
               'bestdayever' => bless( {
                                         '_lines' => [
                                                       11
                                                     ],
                                         'code' => sub {
                                                       BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                       use strict;
                                                       no feature ':all';
                                                       use feature ':5.16';
                                                       my $exp = 'DateTime::Format::RFC3339'->parse_datetime('2017-06-06T12:34:56-05:00');
                                                       my $got = 'DateTime::Format::RFC3339'->parse_datetime($_);
                                                       $exp->set_time_zone('UTC');
                                                       $got->set_time_zone('UTC');
                                                       return 'DateTime'->compare($got, $exp) == 0;
                                                   },
                                         '_file' => '(eval 372)',
                                         'name' => '<Custom Code>',
                                         'operator' => 'CODE(...)'
                                       }, 'Test2::Compare::Custom' )
             };


my $actual = from_toml(q{bestdayever = 2017-06-06T12:34:56-05:00
});

is($actual, $expected1, 'datetime-timezone - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ from_toml(to_toml($actual)) }, $actual, 'datetime-timezone - to_toml') or do{
  diag 'INPUT:';
  diag Dumper($actual);

  diag 'TOML OUTPUT:';
  diag to_toml($actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml($actual)));
};

done_testing;