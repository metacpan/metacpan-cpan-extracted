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
package Number::Phone::StubCountry::NL;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20241212130806;

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
$areanames{nl} = {"31229", "Hoorn",
"31486", "Schaijk",
"31481", "Elst",
"3170", "Den\ Haag",};
$areanames{en} = {"31527", "Emmeloord",
"31523", "Hardenberg",
"3140", "Eindhoven",
"31512", "Drachten",
"31485", "Cuyk",
"31519", "Dokkum",
"31562", "West\-Terschelling",
"3130", "Utrecht",
"31570", "Deventer",
"31174", "Naaldwijk",
"31115", "Terneuzen",
"31571", "Twello",
"31165", "Roosendaal",
"3150", "Groningen",
"31167", "Steenbergen",
"31594", "Zuidhorn",
"31412", "Oss",
"31598", "Veendam",
"3177", "Venlo",
"31117", "Oostburg",
"31299", "Purmerend",
"31113", "Goes",
"31487", "Druten",
"31226", "Noord\ Scharwoude",
"31525", "Elburg",
"31182", "Gouda",
"31342", "Barneveld",
"3170", "The\ Hague",
"3120", "Amsterdam",
"31521", "Steenwijk",
"31475", "Roermond",
"31294", "Weesp",
"31592", "Assen",
"31418", "Zaltbommel",
"31599", "Stadskanaal",
"3138", "Zwolle",
"3115", "Delft",
"31348", "Woerden",
"31314", "Doetinchem",
"31318", "Veenendaal",
"31344", "Tiel",
"31184", "Sliedrecht",
"31577", "Elspeet",
"31573", "Lochem",
"31227", "Medemblik",
"31223", "Den\ Helder",
"3178", "Dordrecht",
"31486", "Grave",
"31492", "Helmond",
"31514", "Lemmer",
"31548", "Rijssen",
"31575", "Zutphen",
"31161", "Rijen",
"31544", "Lichtenvoorde",
"31518", "St\.\ Annaparochie",
"3113", "Tilburg",
"31111", "Zierikzee",
"31499", "Best",
"3172", "Alkmaar",
"31166", "Tholen",
"31321", "Dronten",
"31481", "Bemmel",
"31252", "Nieuw\-Vennep",
"31172", "Alphen\ aan\ den\ Rijn",
"31320", "Lelystad",
"3158", "Leeuwarden",
"31187", "Middelharnis",
"31183", "Gorinchem",
"31347", "Vianen",
"31343", "Driebergen\-Rijsenburg",
"31515", "Sneek",
"31251", "Beverwijk",
"31545", "Eibergen",
"31578", "Epe",
"31317", "Wageningen",
"31313", "Dieren",
"3179", "Zoetermeer",
"31162", "Oosterhout",
"31297", "Aalsmeer",
"31413", "Uden",
"3123", "Haarlem",
"31478", "Venray",
"31596", "Delfzijl",
"31529", "Dalfsen",
"3110", "Rotterdam",
"31543", "Winterswijk",
"31547", "Goor",
"31228", "Enkhuizen",
"31315", "Terborg",
"31522", "Meppel",
"3126", "Arnhem",
"31345", "Culemborg",
"31224", "Schagen",
"31513", "Heerenveen",
"31591", "Emmen",
"31517", "Harlingen",
"3124", "Nijmegen",
"31341", "Harderwijk",
"3174", "Hengelo",
"31181", "Spijkenisse",
"31595", "Warffum",
"3176", "Breda",
"3155", "Apeldoorn",
"31416", "Waalwijk",
"31180", "Barendrecht",
"3171", "Leiden",
"3133", "Amersfoort",
"31229", "Horn",
"31528", "Hoogeveen",
"31186", "Oud\-Beijerland",
"31346", "Maarssen",
"31316", "Zevenaar",
"31222", "Den\ Burg",
"3175", "Zaandam",
"31524", "Coevorden",
"31411", "Boxtel",
"31497", "Eersel",
"31493", "Deurne",
"3143", "Maastricht",
"31566", "Grou",
"3173", "\'s\-Hertogenbosch",
"31495", "Weert",
"3145", "Heerlen",
"31488", "Zetten",
"31546", "Almelo",
"31572", "Raalte",
"31516", "Oosterwolde",
"3136", "Almere",
"31168", "Zevenbergen",
"31541", "Oldenzaal",
"31255", "IJmuiden",
"31561", "Wolvega",
"31114", "Hulst",
"3135", "Hilversum",
"3146", "Sittard",
"31118", "Middelburg",
"31511", "Veenwouden",
"31597", "Winschoten",
"31164", "Bergen\ op\ Zoom",
"31593", "Beilen",
"3153", "Enschede",};
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