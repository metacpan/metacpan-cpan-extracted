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
               'minustenth' => bless( {
                                        'name' => 'Math::BigFloat->new("-0.1")->beq($_)',
                                        '_file' => '(eval 326)',
                                        'operator' => 'CODE(...)',
                                        '_lines' => [
                                                      7
                                                    ],
                                        'code' => sub {
                                                      BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                      use strict;
                                                      no feature ':all';
                                                      use feature ':5.16';
                                                      require Math::BigFloat;
                                                      my $got = 'Math::BigFloat'->new($_);
                                                      'Math::BigFloat'->new('-0.1')->beq($got);
                                                  }
                                      }, 'Test2::Compare::Custom' ),
               'beast' => bless( {
                                   '_lines' => [
                                                 7
                                               ],
                                   'operator' => 'CODE(...)',
                                   'code' => sub {
                                                 BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                 use strict;
                                                 no feature ':all';
                                                 use feature ':5.16';
                                                 require Math::BigFloat;
                                                 my $got = 'Math::BigFloat'->new($_);
                                                 'Math::BigFloat'->new('666')->beq($got);
                                             },
                                   'name' => 'Math::BigFloat->new("666")->beq($_)',
                                   '_file' => '(eval 325)'
                                 }, 'Test2::Compare::Custom' ),
               'million' => bless( {
                                     '_file' => '(eval 327)',
                                     'name' => 'Math::BigFloat->new("1000000")->beq($_)',
                                     'code' => sub {
                                                   BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                   use strict;
                                                   no feature ':all';
                                                   use feature ':5.16';
                                                   require Math::BigFloat;
                                                   my $got = 'Math::BigFloat'->new($_);
                                                   'Math::BigFloat'->new('1000000')->beq($got);
                                               },
                                     '_lines' => [
                                                   7
                                                 ],
                                     'operator' => 'CODE(...)'
                                   }, 'Test2::Compare::Custom' )
             };


my $actual = from_toml(q{million = 1e6
minustenth = -1E-1
beast = 6.66E2
});

is($actual, $expected1, 'exponent-part-float - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag '';
  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ scalar from_toml(to_toml($actual)) }, $expected1, 'exponent-part-float - to_toml') or do{
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