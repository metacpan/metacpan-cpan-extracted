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
package Number::Phone::StubCountry::ZW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180410221548;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'leading_digits' => '
            4|
            9[2-9]
          ',
                  'format' => '$1 $2 $3',
                  'pattern' => '([49])(\\d{3})(\\d{2,4})'
                },
                {
                  'pattern' => '(7\\d)(\\d{3})(\\d{4})',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'leading_digits' => '7'
                },
                {
                  'pattern' => '(86\\d{2})(\\d{3})(\\d{3})',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'leading_digits' => '86[24]'
                },
                {
                  'leading_digits' => '
            2(?:
              0[45]|
              2[278]|
              [49]8|
              [78]
            )|
            3(?:
              [09]8|
              17|
              3[78]|
              7[1569]|
              8[37]
            )|
            5[15][78]|
            6(?:
              [29]8|
              37|
              [68][78]|
              75
            )
          ',
                  'national_rule' => '0$1',
                  'format' => '$1 $2',
                  'pattern' => '([2356]\\d{2})(\\d{3,5})'
                },
                {
                  'leading_digits' => '
            2(?:
              1[39]|
              2[0157]|
              31|
              [56][14]|
              7[35]|
              84
            )|
            329
          ',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2',
                  'national_rule' => '0$1',
                  'leading_digits' => '
            1[3-9]|
            2[02569]|
            3[0-69]|
            5[05689]|
            6
          ',
                  'pattern' => '([1-356]\\d)(\\d{3,5})'
                },
                {
                  'pattern' => '([235]\\d)(\\d{3})(\\d{3,4})',
                  'leading_digits' => '
            [23]9|
            54
          ',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '([25]\\d{3})(\\d{3,5})',
                  'leading_digits' => '
            258[23]|
            5483
          ',
                  'national_rule' => '0$1',
                  'format' => '$1 $2'
                },
                {
                  'national_rule' => '0$1',
                  'leading_digits' => '86',
                  'format' => '$1 $2',
                  'pattern' => '(8\\d{3})(\\d{6})'
                },
                {
                  'pattern' => '(80\\d)(\\d{4})',
                  'format' => '$1 $2',
                  'national_rule' => '0$1',
                  'leading_digits' => '80'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              0(?:
                4\\d|
                5\\d{2}
              )|
              2[278]\\d|
              48\\d|
              7(?:
                [1-7]\\d|
                [089]\\d{2}
              )|
              8(?:
                [2-57-9]|
                [146]\\d{2}
              )|
              98
            )|
            3(?:
              08|
              17|
              3[78]|
              7(?:
                [19]|
                [56]\\d
              )|
              8[37]|
              98
            )|
            5[15][78]|
            6(?:
              28\\d{2}|
              37|
              6[78]|
              75\\d|
              98|
              8(?:
                7\\d|
                8
              )
            )
          )\\d{3}|
          (?:
            2(?:
              1[39]|
              2[0157]|
              31|
              [56][14]|
              7[35]|
              84
            )|
            329
          )\\d{7}|
          (?:
            1(?:
              3\\d{2}|
              [4-8]|
              9\\d
            )|
            2(?:
              0\\d{2}|
              12|
              292|
              [569]\\d
            )|
            3(?:
              [26]|
              [013459]\\d
            )|
            5(?:
              0|
              1[2-4]|
              26|
              [37]2|
              5\\d{2}|
              [689]\\d
            )|
            6(?:
              [39]|
              [01246]\\d|
              [78]\\d{2}
            )
          )\\d{3}|
          (?:
            29\\d|
            39|
            54
          )\\d{6}|
          (?:
            (?:
              25|
              54
            )83\\d|
            2582\\d{2}|
            65[2-8]
          )\\d{2}|
          (?:
            4\\d{6,7}|
            9[2-9]\\d{4,5}
          )
        ',
                'toll_free' => '
          80(?:
            [01]\\d|
            20|
            8[0-8]
          )\\d{3}
        ',
                'voip' => '
          86(?:
            1[12]|
            30|
            55|
            77|
            8[368]
          )\\d{6}
        ',
                'geographic' => '
          (?:
            2(?:
              0(?:
                4\\d|
                5\\d{2}
              )|
              2[278]\\d|
              48\\d|
              7(?:
                [1-7]\\d|
                [089]\\d{2}
              )|
              8(?:
                [2-57-9]|
                [146]\\d{2}
              )|
              98
            )|
            3(?:
              08|
              17|
              3[78]|
              7(?:
                [19]|
                [56]\\d
              )|
              8[37]|
              98
            )|
            5[15][78]|
            6(?:
              28\\d{2}|
              37|
              6[78]|
              75\\d|
              98|
              8(?:
                7\\d|
                8
              )
            )
          )\\d{3}|
          (?:
            2(?:
              1[39]|
              2[0157]|
              31|
              [56][14]|
              7[35]|
              84
            )|
            329
          )\\d{7}|
          (?:
            1(?:
              3\\d{2}|
              [4-8]|
              9\\d
            )|
            2(?:
              0\\d{2}|
              12|
              292|
              [569]\\d
            )|
            3(?:
              [26]|
              [013459]\\d
            )|
            5(?:
              0|
              1[2-4]|
              26|
              [37]2|
              5\\d{2}|
              [689]\\d
            )|
            6(?:
              [39]|
              [01246]\\d|
              [78]\\d{2}
            )
          )\\d{3}|
          (?:
            29\\d|
            39|
            54
          )\\d{6}|
          (?:
            (?:
              25|
              54
            )83\\d|
            2582\\d{2}|
            65[2-8]
          )\\d{2}|
          (?:
            4\\d{6,7}|
            9[2-9]\\d{4,5}
          )
        ',
                'mobile' => '
          (?:
            7(?:
              1[2-8]|
              3[2-9]|
              7[1-9]|
              8[2-5]
            )|
            8644
          )\\d{6}
        ',
                'specialrate' => '',
                'pager' => '',
                'personal_number' => ''
              };
my %areanames = (
  26313 => "Victoria\ Falls",
  26314 => "Rutenga",
  26315 => "Binga",
  26316 => "West\ Nicholson",
  26317 => "Filabusi",
  26318 => "Dete",
  26319 => "Plumtree",
  263204 => "Odzi",
  263205 => "Pengalonga",
  263206 => "Mutare",
  26321 => "Murambinda",
  263213 => "Victoria\ Falls",
  263219 => "Plumtree",
  263220201 => "Chikanga\/Mutare",
  263220202 => "Mutare",
  263220203 => "Dangamvura",
  263221 => "Murambinda",
  263222 => "Wedza",
  263225 => "Rusape",
  263227 => "Chipinge",
  263228 => "Hauna",
  263229 => "Juliasdale",
  263231 => "Chiredzi",
  26324 => "Chipangayi",
  263248 => "Birchenough\ Bridge",
  26325 => "Rusape",
  263251 => "Zvishavane",
  263254 => "Gweru",
  2632582 => "Headlands",
  2632583 => "Nyazura",
  26326 => "Chimanimani",
  263261 => "Kariba",
  263264 => "Karoi",
  263270 => "Chitungwiza",
  263271 => "Bindura",
  263272 => "Mutoko",
  263273 => "Ruwa",
  263274 => "Arcturus",
  263275219 => "Mazowe",
  26327522 => "Mt\.\ Darwin",
  26327523 => "Mt\.\ Darwin",
  26327524 => "Mt\.\ Darwin",
  26327525 => "Mt\.\ Darwin",
  26327526 => "Mt\.\ Darwin",
  26327527 => "Mt\.\ Darwin",
  26327528 => "Mt\.\ Darwin",
  26327529 => "Mt\.\ Darwin",
  2632753 => "Mt\.\ Darwin",
  26327540 => "Mt\.\ Darwin",
  26327541 => "Mt\.\ Darwin",
  263277 => "Mvurwi",
  263278 => "Murewa",
  263279 => "Marondera",
  263281 => "Hwange",
  263282 => "Kezi",
  263283 => "Figtree",
  263284 => "Gwanda",
  263285 => "Turkmine",
  263286 => "Beitbridge",
  263287 => "Tsholotsho",
  263288 => "Esigodini",
  263289 => "Jotsholo",
  26329 => "Bulawayo",
  263292320 => "Bulawayo",
  263292321 => "Bulawayo",
  26329246 => "Bellevue",
  26329252 => "Luveve",
  26330 => "Gutu",
  263308 => "Chatsworth",
  26331 => "Chiredzi",
  263317 => "Checheche",
  26332 => "Mvuma",
  263329 => "Nyanga",
  26333 => "Triangle",
  263337 => "Nyaningwe",
  263338 => "Nyika",
  26334 => "Jerera",
  26335 => "Mashava",
  26336 => "Ngundu",
  263371 => "Shamva",
  263375 => "Concession",
  263376 => "Glendale",
  263379 => "Macheke",
  263383 => "Matopose",
  263387 => "Nyamandhlovu",
  26339 => "Masvingo",
  263398 => "Lupane",
  2634 => "Harare",
  263420085 => "Selous",
  263420086 => "Selous",
  263420087 => "Selous",
  263420088 => "Selous",
  263420089 => "Selous",
  26342009 => "Selous",
  263420100 => "Selous",
  263420101 => "Selous",
  263420102 => "Selous",
  263420103 => "Selous",
  263420104 => "Selous",
  263420105 => "Selous",
  263420106 => "Norton",
  263420107 => "Norton",
  263420108 => "Norton",
  263420109 => "Norton",
  263420110 => "Norton",
  26342722 => "Chitungwiza",
  26342723 => "Chitungwiza",
  26342728 => "Marondera",
  26342729 => "Marondera",
  26350 => "Shanagani",
  26351 => "Zvishavane",
  263517 => "Mataga",
  263518 => "Mberengwa",
  26352 => "Shurugwi",
  26353 => "Chegutu",
  26354 => "Gweru",
  2635483 => "Lalapanzi",
  26355 => "Kwekwe",
  263557 => "Munyati",
  263558 => "Nkayi",
  26356 => "Chivhu",
  26357 => "Centenary",
  26358 => "Guruve",
  26359 => "Gokwe",
  26360 => "Mhangura",
  26361 => "Kariba",
  26362 => "Norton",
  263628 => "Selous",
  26363 => "Makuti",
  263637 => "Chirundu",
  26364 => "Karoi",
  26365 => "Beatrice",
  26366 => "Banket",
  263667 => "Raffingora",
  263668 => "Mutorashanga",
  26367 => "Chinhoyi",
  263675 => "Murombedzi",
  26368 => "Kadoma",
  263687 => "Sanyati",
  263688 => "Chakari",
  26369 => "Darwendale",
  263698 => "Trelawney",
  2639 => "Bulawayo",
  263920 => "Northend",
  263921 => "Northend",
  2639226 => "Queensdale",
  2639228 => "Queensdale",
  263924 => "Hillside",
  263929 => "Killarney",
  263940 => "Mabutewni",
  263941 => "Mabutewni",
  263942 => "Mabutewni",
  263943 => "Mabutewni",
  263946 => "Bellevue",
  263947 => "Bellevue",
  263948 => "Nkulumane",
  2639490 => "Nkulumane",
  2639491 => "Nkulumane",
  2639492 => "Nkulumane",
  2639493 => "Nkulumane",
  2639494 => "Nkulumane",
  2639495 => "Nkulumane",
  2639496 => "Nkulumane",
  2639497 => "Nkulumane",
  263952 => "Luveve",
  263956 => "Luveve",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+263|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;