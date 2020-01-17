# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use Data::Dumper;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $expected1 = {
               'numtheory' => {
                                'boring' => 0,
                                'perfection' => [
                                                  bless( {
                                                           '_file' => '(eval 373)',
                                                           'operator' => 'CODE(...)',
                                                           'name' => '<Custom Code>',
                                                           '_lines' => [
                                                                         6
                                                                       ],
                                                           'code' => sub {
                                                                         BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                                         use strict;
                                                                         no feature ':all';
                                                                         use feature ':5.16';
                                                                         require Math::BigInt;
                                                                         'Math::BigInt'->new('6')->beq($_);
                                                                     }
                                                         }, 'Test2::Compare::Custom' ),
                                                  bless( {
                                                           'code' => sub {
                                                                         BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                                         use strict;
                                                                         no feature ':all';
                                                                         use feature ':5.16';
                                                                         require Math::BigInt;
                                                                         'Math::BigInt'->new('28')->beq($_);
                                                                     },
                                                           '_lines' => [
                                                                         6
                                                                       ],
                                                           'name' => '<Custom Code>',
                                                           'operator' => 'CODE(...)',
                                                           '_file' => '(eval 374)'
                                                         }, 'Test2::Compare::Custom' ),
                                                  bless( {
                                                           'name' => '<Custom Code>',
                                                           'operator' => 'CODE(...)',
                                                           '_lines' => [
                                                                         6
                                                                       ],
                                                           'code' => sub {
                                                                         BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                                         use strict;
                                                                         no feature ':all';
                                                                         use feature ':5.16';
                                                                         require Math::BigInt;
                                                                         'Math::BigInt'->new('496')->beq($_);
                                                                     },
                                                           '_file' => '(eval 375)'
                                                         }, 'Test2::Compare::Custom' )
                                                ]
                              },
               'best-day-ever' => bless( {
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
                                           '_lines' => [
                                                         11
                                                       ],
                                           'name' => '<Custom Code>',
                                           'operator' => 'CODE(...)',
                                           '_file' => '(eval 376)'
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

  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ from_toml(to_toml($actual)) }, $actual, 'example - to_toml') or do{
  diag 'INPUT:';
  diag Dumper($actual);

  diag 'TOML OUTPUT:';
  diag to_toml($actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml($actual)));
};

done_testing;