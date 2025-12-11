# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20251210153524;

my $formatters = [
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '
            1[238]|
            [34]
          ',
                  'pattern' => '(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'intl_format' => 'NA',
                  'leading_digits' => '14',
                  'pattern' => '(\\d{2})(\\d{3,4})'
                },
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[89]0',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{4,7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '66',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '6',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{8})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            1[16-8]|
            2[259]|
            3[124]|
            4[17-9]|
            5[124679]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [1-578]|
            91
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{5})'
                }
              ];

my $validators = {
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
            7\\d\\d
          )\\d{6}
        ',
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
            7\\d\\d
          )\\d{6}
        ',
                'mobile' => '
          (?:
            6[1-58]|
            970\\d
          )\\d{7}
        ',
                'pager' => '66\\d{7}',
                'personal_number' => '',
                'specialrate' => '(90[069]\\d{4,7})|(
          140(?:
            1[035]|
            2[0346]|
            3[03568]|
            4[0356]|
            5[0358]|
            8[458]
          )|
          (?:
            140(?:
              1[16-8]|
              2[259]|
              3[124]|
              4[17-9]|
              5[124679]|
              7
            )|
            8[478]\\d{6}
          )\\d
        )',
                'toll_free' => '800\\d{4,7}',
                'voip' => '
          (?:
            85|
            91
          )\\d{7}
        '
              };
my %areanames = ();
$areanames{nl} = {"31486", "Schaijk",
"31481", "Elst",
"31229", "Hoorn",
"3170", "Den\ Haag",};
$areanames{en} = {"3146", "Sittard",
"31487", "Druten",
"31527", "Emmeloord",
"31168", "Zevenbergen",
"31547", "Goor",
"31596", "Delfzijl",
"31515", "Sneek",
"31411", "Boxtel",
"31318", "Veenendaal",
"31541", "Oldenzaal",
"3173", "\'s\-Hertogenbosch",
"31118", "Middelburg",
"31481", "Bemmel",
"31593", "Beilen",
"31521", "Steenwijk",
"31499", "Best",
"31343", "Driebergen\-Rijsenburg",
"31524", "Coevorden",
"31229", "Horn",
"31475", "Roermond",
"3150", "Groningen",
"31577", "Elspeet",
"3176", "Breda",
"31228", "Enkhuizen",
"31562", "West\-Terschelling",
"31544", "Lichtenvoorde",
"31512", "Drachten",
"3143", "Maastricht",
"31346", "Maarssen",
"3171", "Leiden",
"3155", "Apeldoorn",
"3178", "Dordrecht",
"31571", "Twello",
"31598", "Veendam",
"31514", "Lemmer",
"31113", "Goes",
"31166", "Tholen",
"3140", "Eindhoven",
"31575", "Zutphen",
"31294", "Weesp",
"31599", "Stadskanaal",
"31313", "Dieren",
"31183", "Gorinchem",
"31522", "Meppel",
"31570", "Deventer",
"3172", "Alkmaar",
"3145", "Heerlen",
"3174", "Hengelo",
"31412", "Oss",
"31186", "Oud\-Beijerland",
"3153", "Enschede",
"31316", "Zevenaar",
"31226", "Noord\ Scharwoude",
"31561", "Wolvega",
"31545", "Eibergen",
"3170", "The\ Hague",
"31517", "Harlingen",
"31485", "Cuyk",
"31297", "Aalsmeer",
"31525", "Elburg",
"31223", "Den\ Helder",
"31572", "Raalte",
"3175", "Zaandam",
"31493", "Deurne",
"3177", "Venlo",
"3158", "Leeuwarden",
"31348", "Woerden",
"31511", "Veenwouden",
"31162", "Oosterhout",
"3130", "Utrecht",
"31543", "Winterswijk",
"31413", "Uden",
"31523", "Hardenberg",
"3110", "Rotterdam",
"31344", "Tiel",
"31591", "Emmen",
"31252", "Nieuw\-Vennep",
"3135", "Hilversum",
"31597", "Winschoten",
"31546", "Almelo",
"31182", "Gouda",
"3126", "Arnhem",
"31416", "Waalwijk",
"31495", "Weert",
"31478", "Venray",
"3115", "Delft",
"31486", "Grave",
"31115", "Terneuzen",
"3123", "Haarlem",
"31222", "Den\ Burg",
"31573", "Lochem",
"31315", "Terborg",
"31492", "Helmond",
"31347", "Vianen",
"31174", "Naaldwijk",
"31255", "IJmuiden",
"31180", "Barendrecht",
"31341", "Harderwijk",
"31518", "St\.\ Annaparochie",
"31594", "Zuidhorn",
"31299", "Purmerend",
"31321", "Dronten",
"31519", "Dokkum",
"31165", "Roosendaal",
"31317", "Wageningen",
"31251", "Beverwijk",
"31187", "Middelharnis",
"3179", "Zoetermeer",
"31592", "Assen",
"31345", "Culemborg",
"3136", "Almere",
"31117", "Oostburg",
"31161", "Rijen",
"31488", "Zetten",
"31320", "Lelystad",
"31111", "Zierikzee",
"31528", "Hoogeveen",
"31167", "Steenbergen",
"31181", "Spijkenisse",
"31548", "Rijssen",
"31529", "Dalfsen",
"31418", "Zaltbommel",
"31224", "Schagen",
"31172", "Alphen\ aan\ den\ Rijn",
"3120", "Amsterdam",
"3138", "Zwolle",
"31184", "Sliedrecht",
"3124", "Nijmegen",
"31314", "Doetinchem",
"31566", "Grou",
"31513", "Heerenveen",
"31114", "Hulst",
"31164", "Bergen\ op\ Zoom",
"3113", "Tilburg",
"31578", "Epe",
"3133", "Amersfoort",
"31516", "Oosterwolde",
"31595", "Warffum",
"31342", "Barneveld",
"31497", "Eersel",
"31227", "Medemblik",};
my $timezones = {
               '' => [
                       'Europe/Amsterdam'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+31|\D)//g;
      my $self = bless({ country_code => '31', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '31', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;