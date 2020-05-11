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
our $VERSION = 1.20200511123714;

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
$areanames{en}->{68621} = "Bairiki";
$areanames{en}->{68622} = "Bairiki";
$areanames{en}->{68623} = "Bairiki";
$areanames{en}->{68624} = "Bairiki";
$areanames{en}->{68625} = "Betio";
$areanames{en}->{68626} = "Betio";
$areanames{en}->{68627} = "Tarawa";
$areanames{en}->{68628} = "Bikenibeu";
$areanames{en}->{68629} = "Bikenibeu";
$areanames{en}->{68631} = "North\ Tarawa";
$areanames{en}->{68632} = "North\ Tarawa";
$areanames{en}->{68633} = "Abaiang";
$areanames{en}->{68634} = "Marakei";
$areanames{en}->{68635} = "Butaritari";
$areanames{en}->{68636} = "Makin";
$areanames{en}->{68637} = "Banaba";
$areanames{en}->{68638} = "Maiana";
$areanames{en}->{68639} = "Kuria";
$areanames{en}->{68640} = "Aranuka";
$areanames{en}->{68641} = "Abemama";
$areanames{en}->{68642} = "Nonouti";
$areanames{en}->{68643} = "Tabiteuea\ North";
$areanames{en}->{68644} = "Tabiteuea\ South";
$areanames{en}->{68645} = "Onotoa";
$areanames{en}->{68646} = "Beru";
$areanames{en}->{68647} = "Nikunau";
$areanames{en}->{68648} = "Tamana";
$areanames{en}->{68649} = "Arorae";
$areanames{en}->{686650} = "Bairiki";
$areanames{en}->{686651} = "Betio";
$areanames{en}->{686652} = "Bikenibeu";
$areanames{en}->{686653} = "Gilbert\ Islands";
$areanames{en}->{686654} = "Gilbert\ Islands";
$areanames{en}->{686655} = "Phoenix\ Islands";
$areanames{en}->{68672700} = "Gilbert\ Islands";
$areanames{en}->{686750} = "Bairiki";
$areanames{en}->{686751} = "Betio";
$areanames{en}->{686752} = "Bikenibeu";
$areanames{en}->{6867530} = "Gilbert\ Islands";
$areanames{en}->{6867538} = "Line\ Islands";
$areanames{en}->{6867540} = "Phoenix\ Islands";
$areanames{en}->{6867548} = "Line\ Islands";
$areanames{en}->{686755} = "Phoenix\ Islands";
$areanames{en}->{68681} = "Kiritimati";
$areanames{en}->{68682} = "Kiritimati";
$areanames{en}->{68683} = "Fanning";
$areanames{en}->{68684} = "Washington";
$areanames{en}->{68685} = "Kanton";

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