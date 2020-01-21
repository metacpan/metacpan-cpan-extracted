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
               'mixed' => [
                            [
                              bless( {
                                       'name' => '<Custom Code>',
                                       'operator' => 'CODE(...)',
                                       'code' => sub {
                                                     BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                     use strict;
                                                     no feature ':all';
                                                     use feature ':5.16';
                                                     require Math::BigInt;
                                                     'Math::BigInt'->new('1')->beq($_);
                                                 },
                                       '_file' => '(eval 362)',
                                       '_lines' => [
                                                     6
                                                   ]
                                     }, 'Test2::Compare::Custom' ),
                              bless( {
                                       'name' => '<Custom Code>',
                                       'operator' => 'CODE(...)',
                                       'code' => sub {
                                                     BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                     use strict;
                                                     no feature ':all';
                                                     use feature ':5.16';
                                                     require Math::BigInt;
                                                     'Math::BigInt'->new('2')->beq($_);
                                                 },
                                       '_file' => '(eval 363)',
                                       '_lines' => [
                                                     6
                                                   ]
                                     }, 'Test2::Compare::Custom' )
                            ],
                            [
                              'a',
                              'b'
                            ],
                            [
                              bless( {
                                       'name' => '<Custom Code>',
                                       'operator' => 'CODE(...)',
                                       'code' => sub {
                                                     BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                     use strict;
                                                     no feature ':all';
                                                     use feature ':5.16';
                                                     require Math::BigFloat;
                                                     'Math::BigFloat'->new('1.1')->beq($_);
                                                 },
                                       '_file' => '(eval 364)',
                                       '_lines' => [
                                                     6
                                                   ]
                                     }, 'Test2::Compare::Custom' ),
                              bless( {
                                       '_lines' => [
                                                     6
                                                   ],
                                       '_file' => '(eval 365)',
                                       'code' => sub {
                                                     BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x54"}
                                                     use strict;
                                                     no feature ':all';
                                                     use feature ':5.16';
                                                     require Math::BigFloat;
                                                     'Math::BigFloat'->new('2.1')->beq($_);
                                                 },
                                       'name' => '<Custom Code>',
                                       'operator' => 'CODE(...)'
                                     }, 'Test2::Compare::Custom' )
                            ]
                          ]
             };


my $actual = from_toml(q{mixed = [[1, 2], ["a", "b"], [1.1, 2.1]]
});

is($actual, $expected1, 'arrays-hetergeneous - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ from_toml(to_toml($actual)) }, $actual, 'arrays-hetergeneous - to_toml') or do{
  diag 'INPUT:';
  diag Dumper($actual);

  diag 'TOML OUTPUT:';
  diag to_toml($actual);

  diag 'REPARSED OUTPUT:';
  diag Dumper(from_toml(to_toml($actual)));
};

done_testing;