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
               'numtheory' => {
                                'perfection' => [
                                                  bless( {
                                                           'operator' => 'CODE(...)',
                                                           '_lines' => [
                                                                         7
                                                                       ],
                                                           'code' => sub {
                                                                         BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                                         use strict;
                                                                         no feature ':all';
                                                                         use feature ':5.16';
                                                                         require Math::BigInt;
                                                                         my $got = 'Math::BigInt'->new($_);
                                                                         'Math::BigInt'->new('6')->beq($got);
                                                                     },
                                                           'name' => 'Math::BigInt->new("6")->beq($_)',
                                                           '_file' => '(eval 322)'
                                                         }, 'Test2::Compare::Custom' ),
                                                  bless( {
                                                           '_lines' => [
                                                                         7
                                                                       ],
                                                           'operator' => 'CODE(...)',
                                                           'code' => sub {
                                                                         BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                                         use strict;
                                                                         no feature ':all';
                                                                         use feature ':5.16';
                                                                         require Math::BigInt;
                                                                         my $got = 'Math::BigInt'->new($_);
                                                                         'Math::BigInt'->new('28')->beq($got);
                                                                     },
                                                           'name' => 'Math::BigInt->new("28")->beq($_)',
                                                           '_file' => '(eval 323)'
                                                         }, 'Test2::Compare::Custom' ),
                                                  bless( {
                                                           '_file' => '(eval 324)',
                                                           'name' => 'Math::BigInt->new("496")->beq($_)',
                                                           'code' => sub {
                                                                         BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                                         use strict;
                                                                         no feature ':all';
                                                                         use feature ':5.16';
                                                                         require Math::BigInt;
                                                                         my $got = 'Math::BigInt'->new($_);
                                                                         'Math::BigInt'->new('496')->beq($got);
                                                                     },
                                                           '_lines' => [
                                                                         7
                                                                       ],
                                                           'operator' => 'CODE(...)'
                                                         }, 'Test2::Compare::Custom' )
                                                ],
                                'boring' => 0
                              },
               'best-day-ever' => bless( {
                                           'name' => '<Custom Code>',
                                           '_file' => '(eval 321)',
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


my $actual = from_toml(q{best-day-ever = 1987-07-05T17:45:00Z

[numtheory]
boring = false
perfection = [6, 28, 496]
});

is($actual, $expected1, 'example - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag '';
  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ scalar from_toml(to_toml($actual)) }, $expected1, 'example - to_toml') or do{
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