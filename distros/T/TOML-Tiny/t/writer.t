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

#-------------------------------------------------------------------------------
# Adapted from DateTime::Format::RFC3339.
#-------------------------------------------------------------------------------
subtest 'rfc3339 datetimes' => sub{
  my $dt;

  $dt = DateTime->new(year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'UTC');
  is TOML::Tiny::Writer::strftime_rfc3339($dt), '2002-07-01T13:50:05Z', 'UTC';

  $dt = DateTime->new(year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'Europe/London');
  is TOML::Tiny::Writer::strftime_rfc3339($dt), '2002-07-01T13:50:05+01:00', 'positive offset';

  $dt = DateTime->new(year => 2002, month => 1, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'Europe/London');
  is TOML::Tiny::Writer::strftime_rfc3339($dt), '2002-01-01T13:50:05+00:00', 'zero offset';

  $dt = DateTime->new(year => 2002, month => 1, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'America/New_York');
  is TOML::Tiny::Writer::strftime_rfc3339($dt), '2002-01-01T13:50:05-05:00', 'negative offset';

  $dt = DateTime->new(year => 1880, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'America/New_York');
  is TOML::Tiny::Writer::strftime_rfc3339($dt), '1880-01-01T04:56:02Z', 'offset with non-integral minutes';

  $dt = DateTime->new(year => 2002, month => 1, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'floating');
  is TOML::Tiny::Writer::strftime_rfc3339($dt), '2002-01-01T13:50:05', 'floating time zone';
};

subtest 'oddballs and regressions' => sub{
  subtest 'strings that look like numbers' => sub{
    my $data = {
      is_inf  => 'inf',
      not_inf => 'to infinity and beyond',
      is_nan  => 'nan',
      not_nan => 'no nan here',
    };

    is to_toml({a => 'no inf here'}), 'a="no inf here"', '"inf" present in string is string';
    is to_toml({a => 'no nan here'}), 'a="no nan here"', '"nan" present in string is string';
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
