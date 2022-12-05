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
our $VERSION = 1.20221202211027;

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
$areanames{en} = {"6867540", "Phoenix\ Islands",
"68627", "Tarawa",
"68638", "Maiana",
"6867548", "Line\ Islands",
"68683", "Fanning",
"68682", "Kiritimati",
"68635", "Butaritari",
"686653", "Gilbert\ Islands",
"68622", "Bairiki",
"686750", "Bairiki",
"68623", "Bairiki",
"68649", "Arorae",
"686650", "Bairiki",
"68636", "Makin",
"686651", "Betio",
"68629", "Bikenibeu",
"68643", "Tabiteuea\ North",
"68640", "Aranuka",
"686751", "Betio",
"68642", "Nonouti",
"686655", "Phoenix\ Islands",
"68672700", "Gilbert\ Islands",
"68634", "Marakei",
"686755", "Phoenix\ Islands",
"68631", "North\ Tarawa",
"68647", "Nikunau",
"68632", "North\ Tarawa",
"68625", "Betio",
"68633", "Abaiang",
"68646", "Beru",
"68637", "Banaba",
"686652", "Bikenibeu",
"68641", "Abemama",
"68628", "Bikenibeu",
"686752", "Bikenibeu",
"68644", "Tabiteuea\ South",
"68685", "Kanton",
"6867538", "Line\ Islands",
"68624", "Bairiki",
"68648", "Tamana",
"6867530", "Gilbert\ Islands",
"68621", "Bairiki",
"68681", "Kiritimati",
"68626", "Betio",
"68639", "Kuria",
"686654", "Gilbert\ Islands",
"68684", "Washington",
"68645", "Onotoa",};

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