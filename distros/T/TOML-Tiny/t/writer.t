use strict;
use warnings;

use Test2::V0;
use TOML::Tiny;
use DateTime::Format::RFC3339;
use DateTime::Format::ISO8601;

my $src = do{ local $/; <DATA> };

subtest basics => sub{
  my $data = from_toml($src);
  my $toml = to_toml($data);
  my $got  = from_toml($toml);
  is $got, $data, 'to_toml <=> from_toml';
};

subtest strict_arrays => sub{
  subtest with_bad_array => sub{
    my ($data, $error) = from_toml $src, strict_arrays => 1;
    is $data, U, 'result undefined';
    ok $error, 'error message';
    like $error, qr/expected value of type/, $error, 'expected error';
  };

  subtest without_bad_array => sub{
    my $toml = $src;
    $toml =~ s/^hetero_array.*$//m;
    my ($data, $error) = from_toml $toml, strict_arrays => 1;
    ok $data, 'result defined';
    ok !$error, 'no error';
  };
};

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

  subtest 'decode/encode datetime with floating time zone' => sub{
    my $parser = TOML::Tiny->new(
      inflate_datetime => sub{
        my ($dt_string) = @_;
        # DateTime::Format::RFC3339 will set the resulting DateTime's formatter
        # to itself. Fallback is the DateTime default, ISO8601, with a possibly
        # floating time zone.
        return eval{ DateTime::Format::RFC3339->parse_datetime($dt_string) }
            || DateTime::Format::ISO8601->parse_datetime($dt_string);
      },
    );

    # Parse 2 dates, one with and one without a time zone. Re-encode as TOML
    # and verify that the resulting datetime values are as expected.
    my $with_tz_str = '2020-05-04T16:37:02.905408062+01:00';
    my $no_tz_str   = '1979-05-27T00:32:00.643144312';

    my $data = from_toml( # use default parser, which produces strings for datetimes
      $parser->encode(
        $parser->decode(qq{
with_tz = $with_tz_str
no_tz   = $no_tz_str
        })
      )
    );

    is $data->{with_tz}, $with_tz_str, 'datetime with time zone reproduced faithfully';
    is $data->{no_tz}, $no_tz_str, 'datetime without time zone reproduced faithfully';
  };
};

done_testing;

__DATA__
# This is a TOML document.

title = "TOML Example"

hetero_array = ["life", "universe", "everything", 42]

[owner]
name = "Tom Preston-Werner"
dob = 1979-05-27T07:32:00-08:00 # First class dates

[database]
server = "192.168.1.1"
ports = [ 8001, 8001, 8002 ]
connection_max = 5000
enabled = true
options = {"quote-keys"=false}

[servers]

  # Indentation (tabs and/or spaces) is allowed but not required
  [servers.alpha]
  ip = "10.0.0.1"
  dc = "eqdc10"

  [servers.beta]
  ip = "10.0.0.2"
  dc = "eqdc10"

[clients]
data = [ ["gamma", "delta"], [1, 2] ]

# Line breaks are OK when inside arrays
hosts = [
  "alpha",
  "omega"
]

[[products]]
name = "Hammer"
sku = 738594937

[[products]]

[[products]]
name = "Nail"
sku = 284758393
color = "gray"
