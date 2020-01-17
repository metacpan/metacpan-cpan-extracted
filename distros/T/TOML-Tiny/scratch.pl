use strict;
use warnings;
use v5.18;

use Benchmark qw(:all);
use Data::Dumper;
use TOML::Tiny qw();
use TOML qw();

my $count = shift @ARGV || 1000;
my $toml = do{ local $/; <DATA> };

#timethis $count, sub{ my $data = TOML::Tiny::from_toml($toml) };

timethese $count => {
  'TOML::Tiny' => sub{ my $data = TOML::Tiny::from_toml($toml) },
  'TOML'       => sub{ my $data = TOML::from_toml($toml) },
};

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
