# automatically generated file, don't edit



# Copyright 2011 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20220903144941;

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
            63\\d{3}|
            73(?:
              0[0-5]\\d|
              140
            )
          )\\d{3}|
          [67]200[01]\\d{3}
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
$areanames{en} = {"6867538", "Line\ Islands",
"686751", "Betio",
"68672700", "Gilbert\ Islands",
"686651", "Betio",
"686650", "Bairiki",
"6867548", "Line\ Islands",
"686750", "Bairiki",
"68644", "Tabiteuea\ South",
"68645", "Onotoa",
"68639", "Kuria",
"686653", "Gilbert\ Islands",
"68647", "Nikunau",
"68684", "Washington",
"68624", "Bairiki",
"68625", "Betio",
"68685", "Kanton",
"68627", "Tarawa",
"68640", "Aranuka",
"686654", "Gilbert\ Islands",
"68629", "Bikenibeu",
"68637", "Banaba",
"68649", "Arorae",
"68634", "Marakei",
"68635", "Butaritari",
"68631", "North\ Tarawa",
"68636", "Makin",
"68633", "Abaiang",
"6867540", "Phoenix\ Islands",
"68626", "Betio",
"68681", "Kiritimati",
"68621", "Bairiki",
"68643", "Tabiteuea\ North",
"6867530", "Gilbert\ Islands",
"68646", "Beru",
"68683", "Fanning",
"68623", "Bairiki",
"68641", "Abemama",
"686752", "Bikenibeu",
"68648", "Tamana",
"686652", "Bikenibeu",
"68632", "North\ Tarawa",
"68628", "Bikenibeu",
"686755", "Phoenix\ Islands",
"68682", "Kiritimati",
"68622", "Bairiki",
"686655", "Phoenix\ Islands",
"68642", "Nonouti",
"68638", "Maiana",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+686|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;