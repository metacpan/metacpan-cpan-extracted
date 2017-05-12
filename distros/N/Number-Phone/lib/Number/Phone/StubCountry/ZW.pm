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
our $VERSION = 1.20170314173055;

my $formatters = [
                {
                  'pattern' => '([49])(\\d{3})(\\d{2,4})',
                  'leading_digits' => '
            4|
            9[2-9]
          '
                },
                {
                  'leading_digits' => '7',
                  'pattern' => '(7\\d)(\\d{3})(\\d{3,4})'
                },
                {
                  'leading_digits' => '86[24]',
                  'pattern' => '(86\\d{2})(\\d{3})(\\d{3})'
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
              08|
              17|
              3[78]|
              7[1569]|
              8[37]|
              98
            )|
            5[15][78]|
            6(?:
              [29]8|
              [38]7|
              6[78]|
              75|
              [89]8
            )
          ',
                  'pattern' => '([2356]\\d{2})(\\d{3,5})'
                },
                {
                  'leading_digits' => '
            2(?:
              1[39]|
              2[0157]|
              6[14]|
              7[35]|
              84
            )|
            329
          ',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                },
                {
                  'leading_digits' => '
            1[3-9]|
            2[0569]|
            3[0-69]|
            5[05689]|
            6[0-46-9]
          ',
                  'pattern' => '([1-356]\\d)(\\d{3,5})'
                },
                {
                  'pattern' => '([235]\\d)(\\d{3})(\\d{3,4})',
                  'leading_digits' => '
            [23]9|
            54
          '
                },
                {
                  'leading_digits' => '
            258[23]|
            5483
          ',
                  'pattern' => '([25]\\d{3})(\\d{3,5})'
                },
                {
                  'pattern' => '(8\\d{3})(\\d{6})',
                  'leading_digits' => '86'
                },
                {
                  'leading_digits' => '80',
                  'pattern' => '(80\\d)(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'specialrate' => '',
                'mobile' => '
          7[1378]\\d{7}
        ',
                'toll_free' => '800\\d{7}',
                'personal_number' => '',
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
               [36]7|
               75\\d|
               [69]8|
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
               6[14]|
               7[35]|
               84
            )|
            329
          )\\d{7}|
          (?:
            1(?:
               3\\d{2}|
               9\\d|
               [4-8]
            )|
            2(?:
               0\\d{2}|
               [569]\\d
            )|
            3(?:
               [26]|
               [013459]\\d
            )|
            5(?:
               0|
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
           )83|
           2582\\d
         )\\d{3}|
         (?:
           4\\d{6,7}|
           9[2-9]\\d{4,5}
         )
        ',
                'voip' => '
          86(?:
            1[12]|
            30|
            44|
            55|
            77|
            8[367]|
            99
          )\\d{6}
        ',
                'pager' => '',
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
               [36]7|
               75\\d|
               [69]8|
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
               6[14]|
               7[35]|
               84
            )|
            329
          )\\d{7}|
          (?:
            1(?:
               3\\d{2}|
               9\\d|
               [4-8]
            )|
            2(?:
               0\\d{2}|
               [569]\\d
            )|
            3(?:
               [26]|
               [013459]\\d
            )|
            5(?:
               0|
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
           )83|
           2582\\d
         )\\d{3}|
         (?:
           4\\d{6,7}|
           9[2-9]\\d{4,5}
         )
        '
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
  26320 => "Mutare",
  263213284 => "Victoria\ Falls",
  263213 => "Victoria\ Falls",
  263219 => "Plumtree",
  26321 => "Murambinda",
  263220 => "Mutare",
  263221 => "Murambinda",
  263222 => "Wedza",
  263225 => "Rusape",
  263227 => "Chipinge",
  263228 => "Hauna",
  263248 => "Birchenough\ Bridge",
  26324 => "Chipangayi",
  2632582 => "Headlands",
  2632583 => "Nyazura",
  26325 => "Rusape",
  263261 => "Kariba",
  263264 => "Karoi",
  26326 => "Chimanimani",
  263270 => "Chitungwiza",
  263271 => "Bindura",
  263272 => "Mutoko",
  263273 => "Ruwa",
  263274 => "Arcturus",
  263275 => "Mazowe",
  263276 => "Mt\.\ Darwin",
  263277 => "Mvurwi",
  263278 => "Murewa",
  263279 => "Marondera",
  263281 => "Hwange",
  263282 => "Kezi",
  263283 => "Figtree",
  263284 => "Gwanda",
  263285 => "Turkmine",
  263286 => "Beitbridge",
  263287 => "Nyamandhlovu",
  263288 => "Esigodini",
  263289 => "Jotsholo",
  26329246 => "Bellevue",
  263298 => "Nyanga",
  26329 => "Juliasdale",
  263308 => "Chatsworth",
  26330 => "Luveve",
  263317 => "Checheche",
  26331 => "Chiredzi",
  263329 => "Nyanga",
  26332 => "Mvuma",
  263337 => "Nyaningwe",
  263338 => "Nyika",
  26333 => "Triangle",
  26334 => "Jerera",
  26335 => "Mashava",
  26336 => "Ngundu",
  263371 => "Shamva",
  263375 => "Concession",
  263376 => "Glendale",
  263379 => "Macheke",
  263383 => "Matopose",
  263387 => "Tsholotsho",
  263398 => "Lupane",
  26339 => "Masvingo",
  26342722 => "Chitungwiza",
  26342723 => "Chitungwiza",
  26342728 => "Marondera",
  26342729 => "Marondera",
  2634 => "Harare",
  26350 => "Shanagani",
  263517 => "Mataga",
  263518 => "Mberengwa",
  26351 => "Zvishavane",
  26352 => "Shurugwi",
  26353 => "Chegutu",
  2635483 => "Lalapanzi",
  26354 => "Gweru",
  263557 => "Munyati",
  263558 => "Nkayi",
  26355 => "Kwekwe",
  26356 => "Chivhu",
  26357 => "Centenary",
  26358 => "Guruve",
  26359 => "Gokwe",
  26360 => "Mhangura",
  26361 => "Kariba",
  263628 => "Selous",
  26362 => "Norton",
  263637 => "Chirundu",
  26363 => "Makuti",
  26364 => "Karoi",
  26365 => "Beatrice",
  263667 => "Raffingora",
  263668 => "Mutorashanga",
  26366 => "Banket",
  263675 => "Murombedzi",
  26367 => "Chinhoyi",
  263687 => "Sanyati",
  263688 => "Chakari",
  26368 => "Kadoma",
  263698 => "Trelawney",
  26369 => "Darwendale",
  263920 => "Northend",
  263922 => "Queensdale",
  263924 => "Hillside",
  263940 => "Mabutewni",
  263947 => "Bellevue",
  263948 => "Nkulumane",
  263952 => "Luveve",
  2639 => "Bulawayo",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+263|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;