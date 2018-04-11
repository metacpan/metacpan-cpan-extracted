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
package Number::Phone::StubCountry::NL;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180410221547;

my $formatters = [
                {
                  'leading_digits' => '
            1[035]|
            2[0346]|
            3[03568]|
            4[0356]|
            5[0358]|
            7|
            8[4578]
          ',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'pattern' => '([1-578]\\d)(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '([1-5]\\d{2})(\\d{3})(\\d{3})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            1[16-8]|
            2[259]|
            3[124]|
            4[17-9]|
            5[124679]
          ',
                  'national_rule' => '0$1'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '6[0-57-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(6)(\\d{8})'
                },
                {
                  'format' => '$1 $2',
                  'national_rule' => '0$1',
                  'leading_digits' => '66',
                  'pattern' => '(66)(\\d{7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '14',
                  'national_rule' => '$1',
                  'pattern' => '(14)(\\d{3,4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[89]0',
                  'national_rule' => '0$1',
                  'pattern' => '([89]0\\d)(\\d{4,7})'
                }
              ];

my $validators = {
                'voip' => '
          (?:
            6760|
            85\\d{2}
          )\\d{5}
        ',
                'toll_free' => '800\\d{4,7}',
                'fixed_line' => '
          (?:
            1(?:
              [035]\\d|
              1[13-578]|
              6[124-8]|
              7[24]|
              8[0-467]
            )|
            2(?:
              [0346]\\d|
              2[2-46-9]|
              5[125]|
              9[479]
            )|
            3(?:
              [03568]\\d|
              1[3-8]|
              2[01]|
              4[1-8]
            )|
            4(?:
              [0356]\\d|
              1[1-368]|
              7[58]|
              8[15-8]|
              9[23579]
            )|
            5(?:
              [0358]\\d|
              [19][1-9]|
              2[1-57-9]|
              4[13-8]|
              6[126]|
              7[0-3578]
            )|
            7\\d{2}|
            8[478]\\d
          )\\d{6}
        ',
                'personal_number' => '',
                'pager' => '66\\d{7}',
                'specialrate' => '(90[069]\\d{4,7})|(
          140(?:
            1(?:
              [035]|
              [16-8]\\d
            )|
            2(?:
              [0346]|
              [259]\\d
            )|
            3(?:
              [03568]|
              [124]\\d
            )|
            4(?:
              [0356]|
              [17-9]\\d
            )|
            5(?:
              [0358]|
              [124679]\\d
            )|
            7\\d|
            8[458]
          )
        )',
                'mobile' => '6[1-58]\\d{7}',
                'geographic' => '
          (?:
            1(?:
              [035]\\d|
              1[13-578]|
              6[124-8]|
              7[24]|
              8[0-467]
            )|
            2(?:
              [0346]\\d|
              2[2-46-9]|
              5[125]|
              9[479]
            )|
            3(?:
              [03568]\\d|
              1[3-8]|
              2[01]|
              4[1-8]
            )|
            4(?:
              [0356]\\d|
              1[1-368]|
              7[58]|
              8[15-8]|
              9[23579]
            )|
            5(?:
              [0358]\\d|
              [19][1-9]|
              2[1-57-9]|
              4[13-8]|
              6[126]|
              7[0-3578]
            )|
            7\\d{2}|
            8[478]\\d
          )\\d{6}
        '
              };
my %areanames = (
  3110 => "Rotterdam",
  31111 => "Zierikzee",
  31113 => "Goes",
  31114 => "Hulst",
  31115 => "Terneuzen",
  31117 => "Oostburg",
  31118 => "Middelburg",
  3113 => "Tilburg",
  3115 => "Delft",
  31161 => "Rijen",
  31162 => "Oosterhout",
  31164 => "Bergen\ op\ Zoom",
  31165 => "Roosendaal",
  31166 => "Tholen",
  31167 => "Steenbergen",
  31168 => "Zevenbergen",
  31172 => "Alphen\ aan\ den\ Rijn",
  31174 => "Naaldwijk",
  31180 => "Barendrecht",
  31181 => "Spijkenisse",
  31182 => "Gouda",
  31183 => "Gorinchem",
  31184 => "Sliedrecht",
  31186 => "Oud\-Beijerland",
  31187 => "Middelharnis",
  3120 => "Amsterdam",
  31222 => "Den\ Burg",
  31223 => "Den\ Helder",
  31224 => "Schagen",
  31226 => "Noord\ Scharwoude",
  31227 => "Medemblik",
  31228 => "Enkhuizen",
  31229 => "Horn",
  3123 => "Haarlem",
  3124 => "Nijmegen",
  31251 => "Beverwijk",
  31252 => "Nieuw\-Vennep",
  31255 => "IJmuiden",
  3126 => "Arnhem",
  31294 => "Weesp",
  31297 => "Aalsmeer",
  31299 => "Purmerend",
  3130 => "Utrecht",
  31313 => "Dieren",
  31314 => "Doetinchem",
  31315 => "Terborg",
  31316 => "Zevenaar",
  31317 => "Wageningen",
  31318 => "Veenendaal",
  31320 => "Lelystad",
  31321 => "Dronten",
  3133 => "Amersfoort",
  31341 => "Harderwijk",
  31342 => "Barneveld",
  31343 => "Driebergen\-Rijsenburg",
  31344 => "Tiel",
  31345 => "Culemborg",
  31346 => "Maarssen",
  31347 => "Vianen",
  31348 => "Woerden",
  3135 => "Hilversum",
  3136 => "Almere",
  3138 => "Zwolle",
  3140 => "Eindhoven",
  31411 => "Boxtel",
  31412 => "Oss",
  31413 => "Uden",
  31416 => "Waalwijk",
  31418 => "Zaltbommel",
  3143 => "Maastricht",
  3145 => "Heerlen",
  3146 => "Sittard",
  31475 => "Roermond",
  31478 => "Venray",
  31481 => "Bemmel",
  31485 => "Cuyk",
  31486 => "Grave",
  31487 => "Druten",
  31488 => "Zetten",
  31492 => "Helmond",
  31493 => "Deurne",
  31495 => "Weert",
  31497 => "Eersel",
  31499 => "Best",
  3150 => "Groningen",
  31511 => "Veenwouden",
  31512 => "Drachten",
  31513 => "Heerenveen",
  31514 => "Lemmer",
  31515 => "Sneek",
  31516 => "Oosterwolde",
  31517 => "Harlingen",
  31518 => "St\.\ Annaparochie",
  31519 => "Dokkum",
  31521 => "Steenwijk",
  31522 => "Meppel",
  31523 => "Hardenberg",
  31524 => "Coevorden",
  31525 => "Elburg",
  31527 => "Emmeloord",
  31528 => "Hoogeveen",
  31529 => "Dalfsen",
  3153 => "Enschede",
  31541 => "Oldenzaal",
  31543 => "Winterswijk",
  31544 => "Lichtenvoorde",
  31545 => "Eibergen",
  31546 => "Almelo",
  31547 => "Goor",
  31548 => "Rijssen",
  3155 => "Apeldoorn",
  31561 => "Wolvega",
  31562 => "West\-Terschelling",
  31566 => "Grou",
  31570 => "Deventer",
  31571 => "Twello",
  31572 => "Raalte",
  31573 => "Lochem",
  31575 => "Zutphen",
  31577 => "Elspeet",
  31578 => "Epe",
  3158 => "Leeuwarden",
  31591 => "Emmen",
  31592 => "Assen",
  31593 => "Beilen",
  31594 => "Zuidhorn",
  31595 => "Warffum",
  31596 => "Delfzijl",
  31597 => "Winschoten",
  31598 => "Veendam",
  31599 => "Stadskanaal",
  3170 => "The\ Hague",
  3171 => "Leiden",
  3172 => "Alkmaar",
  3173 => "\'s\-Hertogenbosch",
  3174 => "Hengelo",
  3175 => "Zaandam",
  3176 => "Breda",
  3177 => "Venlo",
  3178 => "Dordrecht",
  3179 => "Zoetermeer",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+31|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;