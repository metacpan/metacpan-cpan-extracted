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
our $VERSION = 1.20181205223704;

my $formatters = [];

my $validators = {
                'voip' => '
          30(?:
            0[01]\\d\\d|
            12(?:
              11|
              20
            )
          )\\d\\d
        ',
                'pager' => '',
                'mobile' => '
          (?:
            6(?:
              200[01]|
              30[01]\\d
            )|
            7(?:
              200[01]|
              3(?:
                0[0-5]\\d|
                140
              )
            )
          )\\d{3}
        ',
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
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
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
        '
              };
my %areanames = (
  68621 => "Bairiki",
  68622 => "Bairiki",
  68623 => "Bairiki",
  68624 => "Bairiki",
  68625 => "Betio",
  68626 => "Betio",
  68627 => "Tarawa",
  68628 => "Bikenibeu",
  68629 => "Bikenibeu",
  68630 => "Tarawa",
  68631 => "North\ Tarawa",
  68632 => "North\ Tarawa",
  68633 => "Abaiang",
  68634 => "Marakei",
  68635 => "Butaritari",
  68636 => "Makin",
  68637 => "Banaba",
  68638 => "Maiana",
  68639 => "Kuria",
  68640 => "Aranuka",
  68641 => "Abemama",
  68642 => "Nonouti",
  68643 => "Tabiteuea\ North",
  68644 => "Tabiteuea\ South",
  68645 => "Onotoa",
  68646 => "Beru",
  68647 => "Nikunau",
  68648 => "Tamana",
  68649 => "Arorae",
  68665021 => "Bairiki",
  68665022 => "Bairiki",
  68665125 => "Betio",
  68665126 => "Betio",
  68665228 => "Bikenibeu",
  68665229 => "Bikenibeu",
  68665300 => "Gilbert\ Islands",
  68665400 => "Gilbert\ Islands",
  68665500 => "Phoenix\ Islands",
  68672700 => "Gilbert\ Islands",
  68675021 => "Bairiki",
  68675022 => "Bairiki",
  68675125 => "Betio",
  68675126 => "Betio",
  68675228 => "Bikenibeu",
  68675229 => "Bikenibeu",
  68675300 => "Gilbert\ Islands",
  68675381 => "Line\ Islands",
  68675400 => "Phoenix\ Islands",
  68675481 => "Line\ Islands",
  68675500 => "Phoenix\ Islands",
  68681 => "Kiritimati",
  68682 => "Kiritimati",
  68683 => "Fanning",
  68684 => "Washington",
  68685 => "Kanton",
);
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