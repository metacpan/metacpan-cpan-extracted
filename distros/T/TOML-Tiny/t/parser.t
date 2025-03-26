use strict;
use warnings;

use Data::Dumper;
use Test2::V0;
use TOML::Tiny;

local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Useqq    = 1;

subtest 'oddballs and regressions' => sub{
  subtest 'strings that look like numbers' => sub{
    my $parser = TOML::Tiny->new(
      inflate_integer => sub{
        use Math::BigInt;
        Math::BigInt->new(shift);
      },

      inflate_float => sub{
        use Math::BigFloat;
        Math::BigFloat->new(shift);
      }
    );

    my $data = $parser->decode(q{

not_an_int = "42"
is_an_int  = 42

not_a_flt  = "4.2"
is_a_flt   = 4.2

    });

    ok !ref($data->{not_an_int}), 'strings do not inflate as integers';
    ok ref($data->{is_an_int}) && $data->{is_an_int}->isa('Math::BigInt'), 'integers do inflate with inflate_integer';

    ok !ref($data->{not_a_flt}), 'strings do not inflate as floats';
    ok ref($data->{is_a_flt}) && $data->{is_a_flt}->isa('Math::BigFloat'), 'floats do inflate with inflate_float';
  };

  subtest 'no dequoting of raw string keys' => sub {
    my $funky_string = "a \\\\ \\x42 b \\\"";
    my $toml = <<END;
key.'$funky_string' = 'a'
itable = { '$funky_string' = 'b' }
[table.'$funky_string']
x = 'c'
[[array.'$funky_string']]
y = 'd'
END
    my $diag1 = sub {
      diag '';
      diag 'RAW FUNKY STRING';
      diag $funky_string;
      diag '';
      diag 'INPUT TOML';
      diag $toml;
    };
    my $data = eval { from_toml($toml) };
    my $error = $@;
    ok !$error, "parsed ok" or do { $diag1->(); diag $error; };
    my $diag = sub {
    };
    ok $data->{key}{$funky_string} eq 'a', "key.funky" and
    ok $data->{itable}{$funky_string} eq 'b', "not in inline table" and
    ok $data->{table}{$funky_string}{x} eq 'c', "not in table heading" and
    ok $data->{array}{$funky_string}[0]{y} eq 'd', "not in array item heading" or do {
      $diag1->();
      diag '';
      diag 'PARSED AS';
      diag Dumper($data);
    }
  };
};

done_testing;
