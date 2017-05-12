#!/usr/bin/perl

# This duplicates the first test, using the original, example TOML,
# the turns that parsed structure into toml and reparses it, thus
# ensuring a round-trip.

use strict;
use Test::More tests => 2;

use_ok("TOML");

# Structure from mojombo/toml
my $data = {
          'database' => {
                        'ports' => [
                                   '8001',
                                   '8001',
                                   '8002'
                                 ],
                        'connection_max' => '5000',
                        'server' => '192.168.1.1',
                        'enabled' => 'true'
                      },
          'owner' => {
                     'dob' => '1979-05-27T07:32:00Z',
                     'name' => 'Tom Preston-Werner',
                     'bio' => 'GitHub Cofounder & CEO
Likes tater tots and beer.',
                     'organization' => 'GitHub'
                   },
          'clients' => {
                       'data' => [
                                 [
                                   'gamma',
                                   'delta'
                                 ],
                                 [
                                   '1',
                                   '2'
                                 ]
                               ]
                     },
          'servers' => {
                       'alpha' => {
                                  'dc' => 'eqdc10',
                                  'ip' => '10.0.0.1'
                                },
                       'beta' => {
                                 'dc' => 'eqdc10',
                                 'ip' => '10.0.0.2'
                               }
                     },
          'title' => 'TOML Example'
        };



# Check that parsing the newly generated toml produces the same data structure
my $new_data = from_toml(to_toml($data));
is_deeply($data, $new_data, "Parsing newly generated structure results in same structure");
