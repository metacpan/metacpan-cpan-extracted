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
               'group' => {
                            'more' => [
                                        bless( {
                                                 'name' => 'Math::BigInt->new("42")->beq($_)',
                                                 '_file' => '(eval 315)',
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
                                                               'Math::BigInt'->new('42')->beq($got);
                                                           }
                                               }, 'Test2::Compare::Custom' ),
                                        bless( {
                                                 'code' => sub {
                                                               BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                               use strict;
                                                               no feature ':all';
                                                               use feature ':5.16';
                                                               require Math::BigInt;
                                                               my $got = 'Math::BigInt'->new($_);
                                                               'Math::BigInt'->new('42')->beq($got);
                                                           },
                                                 'operator' => 'CODE(...)',
                                                 '_lines' => [
                                                               7
                                                             ],
                                                 '_file' => '(eval 316)',
                                                 'name' => 'Math::BigInt->new("42")->beq($_)'
                                               }, 'Test2::Compare::Custom' )
                                      ],
                            'answer' => bless( {
                                                 'code' => sub {
                                                               BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15\x00\x04\x40\x05\x04\x50"}
                                                               use strict;
                                                               no feature ':all';
                                                               use feature ':5.16';
                                                               require Math::BigInt;
                                                               my $got = 'Math::BigInt'->new($_);
                                                               'Math::BigInt'->new('42')->beq($got);
                                                           },
                                                 'operator' => 'CODE(...)',
                                                 '_lines' => [
                                                               7
                                                             ],
                                                 '_file' => '(eval 314)',
                                                 'name' => 'Math::BigInt->new("42")->beq($_)'
                                               }, 'Test2::Compare::Custom' )
                          }
             };


my $actual = from_toml(q{# Top comment.
  # Top comment.
# Top comment.

# [no-extraneous-groups-please]

[group] # Comment
answer = 42 # Comment
# no-extraneous-keys-please = 999
# Inbetween comment.
more = [ # Comment
  # What about multiple # comments?
  # Can you handle it?
  #
          # Evil.
# Evil.
  42, 42, # Comments within arrays are fun.
  # What about multiple # comments?
  # Can you handle it?
  #
          # Evil.
# Evil.
# ] Did I fool you?
] # Hopefully not.
});

is($actual, $expected1, 'comments-everywhere - from_toml') or do{
  diag 'EXPECTED:';
  diag Dumper($expected1);

  diag '';
  diag 'ACTUAL:';
  diag Dumper($actual);
};

is(eval{ scalar from_toml(to_toml($actual)) }, $expected1, 'comments-everywhere - to_toml') or do{
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