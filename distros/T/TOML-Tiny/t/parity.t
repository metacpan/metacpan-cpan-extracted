#-------------------------------------------------------------------------------
# Tests the results of parsing the example TOML from
# https://github.com/toml-lang/toml against the de facto standard TOML module
# on CPAN. Includes the array-of-tables example as well since that is not
# represented in the synopsis example
#-------------------------------------------------------------------------------
use Test2::V0;
use Data::Dumper;
use TOML::Tiny::Parser;

my $toml = do{ local $/; <DATA> };

subtest 'TOML::Parser' => sub{
  use TOML::Parser;

  subtest 'defaults' => sub{
    my $exp = TOML::Parser->new->parse($toml);
    my $got = TOML::Tiny::Parser->new->parse($toml);
    is $got, $exp, 'equivalence'
      or diag Dumper({got => $got, expected => $exp});
  };

  subtest 'inflate_boolean' => sub{
    my $inflate = sub{ shift eq 'true' ? 'yes' : 'no' };
    my $exp = TOML::Parser->new(inflate_boolean => $inflate)->parse($toml);
    my $got = TOML::Tiny::Parser->new(inflate_boolean => $inflate)->parse($toml);
    is $got, $exp, 'equivalence'
      or diag Dumper({got => $got, expected => $exp});
  };

  subtest 'inflate_datetime' => sub{
    require DateTime::Format::RFC3339;
    my $inflate = sub{ DateTime::Format::RFC3339->parse_datetime(shift) };
    my $exp = TOML::Parser->new(inflate_datetime => $inflate)->parse($toml);
    my $got = TOML::Tiny::Parser->new(inflate_datetime => $inflate)->parse($toml);
    is $got, $exp, 'equivalence'
      or diag Dumper({got => $got, expected => $exp});
  };
};

done_testing;

__DATA__
# This is a TOML document.

title = "TOML Example"

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
