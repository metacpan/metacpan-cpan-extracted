# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
# http://code.google.com/p/libphonenumber/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
package Number::Phone::StubCountry::KI;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240607153920;

my $formatters = [];

my $validators = {
                'fixed_line' => '
          (?:
            [24]\\d|
            3[1-9]|
            50|
            65(?:
              02[12]|
              12[56]|
              22[89]|
              [3-5]00
            )|
            7(?:
              27\\d\\d|
              3100|
              5(?:
                02[12]|
                12[56]|
                22[89]|
                [34](?:
                  00|
                  81
                )|
                500
              )
            )|
            8[0-5]
          )\\d{3}
        ',
                'geographic' => '
          (?:
            [24]\\d|
            3[1-9]|
            50|
            65(?:
              02[12]|
              12[56]|
              22[89]|
              [3-5]00
            )|
            7(?:
              27\\d\\d|
              3100|
              5(?:
                02[12]|
                12[56]|
                22[89]|
                [34](?:
                  00|
                  81
                )|
                500
              )
            )|
            8[0-5]
          )\\d{3}
        ',
                'mobile' => '
          (?:
            6200[01]|
            7(?:
              310[1-9]|
              5(?:
                02[03-9]|
                12[0-47-9]|
                22[0-7]|
                [34](?:
                  0[1-9]|
                  8[02-9]
                )|
                50[1-9]
              )
            )
          )\\d{3}|
          (?:
            63\\d\\d|
            7(?:
              (?:
                [0146-9]\\d|
                2[0-689]
              )\\d|
              3(?:
                [02-9]\\d|
                1[1-9]
              )|
              5(?:
                [0-2][013-9]|
                [34][1-79]|
                5[1-9]|
                [6-9]\\d
              )
            )
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => '
          30(?:
            0[01]\\d\\d|
            12(?:
              11|
              20
            )
          )\\d\\d
        '
              };
my %areanames = ();
$areanames{en} = {"68645", "Onotoa",
"68675481", "Line\ Islands",
"68675300", "Gilbert\ Islands",
"68644", "Tabiteuea\ South",
"68622", "Bairiki",
"68638", "Maiana",
"68641", "Abemama",
"68623", "Bairiki",
"68627", "Tarawa",
"68621", "Bairiki",
"686652", "Bikenibeu",
"68639", "Kuria",
"68643", "Tabiteuea\ North",
"68636", "Makin",
"68647", "Nikunau",
"68625", "Betio",
"686653", "Gilbert\ Islands",
"68672700", "Gilbert\ Islands",
"68624", "Bairiki",
"68642", "Nonouti",
"68675125", "Betio",
"68675126", "Betio",
"68675400", "Phoenix\ Islands",
"68683", "Fanning",
"686650", "Bairiki",
"68628", "Bikenibeu",
"68646", "Beru",
"68637", "Banaba",
"68675381", "Line\ Islands",
"68649", "Arorae",
"68675021", "Bairiki",
"68675229", "Bikenibeu",
"68633", "Abaiang",
"68682", "Kiritimati",
"68675500", "Phoenix\ Islands",
"68640", "Aranuka",
"68632", "North\ Tarawa",
"686651", "Betio",
"686655", "Phoenix\ Islands",
"68684", "Washington",
"68635", "Butaritari",
"68634", "Marakei",
"68685", "Kanton",
"68675228", "Bikenibeu",
"686654", "Gilbert\ Islands",
"68631", "North\ Tarawa",
"68648", "Tamana",
"68626", "Betio",
"68681", "Kiritimati",
"68675022", "Bairiki",
"68629", "Bikenibeu",};
my $timezones = {
               '' => [
                       'Pacific/Enderbury',
                       'Pacific/Kiritimati',
                       'Pacific/Tarawa'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+686|\D)//g;
      my $self = bless({ country_code => '686', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '686', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;