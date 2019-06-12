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
package Number::Phone::StubCountry::MM;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190611222640;

my $formatters = [
                {
                  'leading_digits' => '
            16|
            2
          ',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d)(\\d{2})(\\d{3})'
                },
                {
                  'leading_digits' => '
            [45]|
            6(?:
              0[23]|
              [1-689]|
              7[235-7]
            )|
            7(?:
              [0-4]|
              5[2-7]
            )|
            8[1-6]
          ',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d)(\\d{3})(\\d{3,4})',
                  'leading_digits' => '[12]'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'leading_digits' => '
            [4-7]|
            8[1-35]
          '
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d)(\\d{3})(\\d{4,6})',
                  'leading_digits' => '
            9(?:
              2[0-4]|
              [35-9]|
              4[137-9]
            )
          '
                },
                {
                  'leading_digits' => '2',
                  'pattern' => '(\\d)(\\d{4})(\\d{4})',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8'
                },
                {
                  'leading_digits' => '92',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3 $4',
                  'pattern' => '(\\d)(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'pattern' => '(\\d)(\\d{5})(\\d{4})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9'
                }
              ];

my $validators = {
                'geographic' => '
          (?:
            1(?:
              (?:
                2\\d|
                3[56]|
                [89][0-6]
              )\\d|
              4(?:
                2[2-469]|
                39|
                46|
                6[25]|
                7[0-2]
              )|
              6
            )|
            2(?:
              2(?:
                00|
                8[34]
              )|
              4(?:
                0\\d|
                2[246]|
                39|
                46|
                62|
                7[0-2]
              )|
              51\\d\\d
            )|
            4(?:
              2(?:
                2\\d\\d|
                48[0-2]
              )|
              [34]20\\d
            )|
            6(?:
              0(?:
                [23]|
                88\\d
              )|
              (?:
                124|
                320|
                [56]2\\d
              )\\d|
              247[23]|
              4(?:
                2[04]\\d|
                47[23]
              )|
              7(?:
                (?:
                  3\\d|
                  8[01459]
                )\\d|
                4(?:
                  39|
                  60|
                  7[01]
                )
              )
            )|
            8(?:
              [1-3]2\\d|
              5(?:
                2\\d|
                4[1-9]
              )
            )\\d
          )\\d{4}|
          5(?:
            2(?:
              2\\d{5,6}|
              47[023]\\d{4}
            )|
            (?:
              347[23]|
              42(?:
                1|
                86
              )|
              (?:
                522|
                820
              )\\d|
              7(?:
                20\\d|
                48[0-2]
              )|
              9(?:
                20\\d|
                47[01]
              )
            )\\d{4}
          )|
          7(?:
            120\\d{4,5}|
            (?:
              425\\d|
              5(?:
                202|
                96\\d
              )
            )\\d{4}
          )|
          (?:
            (?:
              1[2-6]\\d|
              4(?:
                2[24-8]|
                356|
                [46][2-6]|
                5[35]
              )|
              5(?:
                [27][2-8]|
                3[2-68]|
                4[25-8]|
                5[23]|
                6[2-4]|
                8[25-7]|
                9[2-7]
              )|
              6(?:
                [19]20|
                42[03-6]|
                (?:
                  52|
                  7[45]
                )\\d
              )|
              7(?:
                [04][25-8]|
                [15][235-7]|
                22|
                3[2-4]
              )
            )\\d|
            8(?:
              [135]2\\d\\d|
              2(?:
                2\\d\\d|
                320
              )
            )
          )\\d{3}|
          25\\d{5,6}|
          (?:
            2[2-9]|
            43[235-7]|
            6(?:
              1[2356]|
              [24][2-6]|
              3[256]|
              5[2-4]|
              6[2-8]|
              7[235-7]|
              8[245]|
              9[24]
            )|
            8(?:
              1[235689]|
              2[2-8]|
              32|
              4[24-7]|
              5[245]|
              6[23]
            )
          )\\d{4}|
          (?:
            4[35]|
            5[48]|
            63|
            7[0145]|
            8[13]
          )470\\d{4}|
          (?:
            4[35]|
            5[48]|
            63|
            7[0145]|
            8[13]
          )4\\d{4}
        ',
                'specialrate' => '',
                'voip' => '
          1333\\d{4}|
          [12]468\\d{4}
        ',
                'fixed_line' => '
          (?:
            1(?:
              (?:
                2\\d|
                3[56]|
                [89][0-6]
              )\\d|
              4(?:
                2[2-469]|
                39|
                46|
                6[25]|
                7[0-2]
              )|
              6
            )|
            2(?:
              2(?:
                00|
                8[34]
              )|
              4(?:
                0\\d|
                2[246]|
                39|
                46|
                62|
                7[0-2]
              )|
              51\\d\\d
            )|
            4(?:
              2(?:
                2\\d\\d|
                48[0-2]
              )|
              [34]20\\d
            )|
            6(?:
              0(?:
                [23]|
                88\\d
              )|
              (?:
                124|
                320|
                [56]2\\d
              )\\d|
              247[23]|
              4(?:
                2[04]\\d|
                47[23]
              )|
              7(?:
                (?:
                  3\\d|
                  8[01459]
                )\\d|
                4(?:
                  39|
                  60|
                  7[01]
                )
              )
            )|
            8(?:
              [1-3]2\\d|
              5(?:
                2\\d|
                4[1-9]
              )
            )\\d
          )\\d{4}|
          5(?:
            2(?:
              2\\d{5,6}|
              47[023]\\d{4}
            )|
            (?:
              347[23]|
              42(?:
                1|
                86
              )|
              (?:
                522|
                820
              )\\d|
              7(?:
                20\\d|
                48[0-2]
              )|
              9(?:
                20\\d|
                47[01]
              )
            )\\d{4}
          )|
          7(?:
            120\\d{4,5}|
            (?:
              425\\d|
              5(?:
                202|
                96\\d
              )
            )\\d{4}
          )|
          (?:
            (?:
              1[2-6]\\d|
              4(?:
                2[24-8]|
                356|
                [46][2-6]|
                5[35]
              )|
              5(?:
                [27][2-8]|
                3[2-68]|
                4[25-8]|
                5[23]|
                6[2-4]|
                8[25-7]|
                9[2-7]
              )|
              6(?:
                [19]20|
                42[03-6]|
                (?:
                  52|
                  7[45]
                )\\d
              )|
              7(?:
                [04][25-8]|
                [15][235-7]|
                22|
                3[2-4]
              )
            )\\d|
            8(?:
              [135]2\\d\\d|
              2(?:
                2\\d\\d|
                320
              )
            )
          )\\d{3}|
          25\\d{5,6}|
          (?:
            2[2-9]|
            43[235-7]|
            6(?:
              1[2356]|
              [24][2-6]|
              3[256]|
              5[2-4]|
              6[2-8]|
              7[235-7]|
              8[245]|
              9[24]
            )|
            8(?:
              1[235689]|
              2[2-8]|
              32|
              4[24-7]|
              5[245]|
              6[23]
            )
          )\\d{4}|
          (?:
            4[35]|
            5[48]|
            63|
            7[0145]|
            8[13]
          )470\\d{4}|
          (?:
            4[35]|
            5[48]|
            63|
            7[0145]|
            8[13]
          )4\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'toll_free' => '
          80080(?:
            [01][1-9]|
            2\\d
          )\\d{3}
        ',
                'mobile' => '
          (?:
            17[01]|
            9(?:
              2(?:
                [0-4]|
                [56]\\d\\d
              )|
              (?:
                3(?:
                  [0-36]|
                  4\\d
                )|
                (?:
                  6[89]|
                  89
                )\\d|
                7(?:
                  3|
                  5[0-2]|
                  [6-9]\\d
                )
              )\\d|
              4(?:
                (?:
                  [0245]\\d|
                  [1379]
                )\\d|
                88
              )|
              5[0-6]|
              9(?:
                [089]|
                [5-7]\\d\\d
              )
            )\\d
          )\\d{4}|
          9[69]1\\d{6}|
          9[68]\\d{6}
        '
              };
my %areanames = (
  951422 => "Yangon",
  951423 => "Yangon",
  951424 => "Yangon",
  951426 => "Yangon",
  951429 => "Yangon",
  951439 => "Yangon",
  951446 => "Yangon",
  951462 => "Yangon",
  951465 => "Yangon",
  951470 => "Yangon",
  951550 => "Bahan",
  951551 => "Bahan",
  951552 => "Bahan",
  951553 => "Bahan",
  951680 => "Bayintnaung",
  951681 => "Bayintnaung",
  951682 => "Bayintnaung",
  951683 => "Bayintnaung",
  951684 => "Bayintnaung",
  951685 => "Bayintnaung",
  951686 => "Bayintnaung",
  951687 => "Bayintnaung",
  951688 => "Bayintnaung",
  9522000 => "Mingalar\ Mandalay",
  952422 => "Mandalay",
  952424 => "Mandalay",
  952426 => "Mandalay",
  952439 => "Mandalay",
  952446 => "Mandalay",
  952462 => "Mandalay",
  952470 => "Yangon",
  952471 => "Mandalay",
  952472 => "Mandalay",
  95256 => "Amarapura",
  9542480 => "Pathein",
  9542481 => "Pathein",
  9542482 => "Ayeyarwaddy",
  9543202 => "Rakhine",
  9543470 => "Sittwe",
  954353 => "Buthidaung",
  9543565 => "Palatwa",
  9545470 => "Pyapon",
  95522221 => "Bago",
  95522222 => "Bago",
  95522223 => "Bago",
  95522224 => "Bago",
  95522230 => "Oathar\ Myothit",
  9552470 => "Bago",
  9552472 => "Bago",
  9552473 => "Bago",
  9553472 => "Pyay",
  9553473 => "Pyay",
  9554470 => "Taungoo",
  955645 => "Tandar",
  9557480 => "Mawlamyine\/Thanbyuzayat",
  9557481 => "Mawlamyine",
  9557482 => "Mon",
  9558470 => "Hpa\-An",
  9559470 => "Dawei",
  9559471 => "Tanintharyi",
  9561200 => "Chauk",
  956124620 => "Chauk",
  956124621 => "Chauk",
  956124622 => "Chauk",
  956124623 => "Chauk",
  956124624 => "Chauk",
  956124640 => "Bagan",
  956124641 => "Bagan",
  956124642 => "Bagan",
  956124643 => "Bagan",
  956124644 => "Bagan",
  9562472 => "Pakokku",
  9562473 => "Magway",
  956260 => "Kanma",
  956323 => "Magway",
  956324 => "Magway",
  9563470 => "Magway",
  95642487 => "Shawpin",
  9564472 => "Meiktila",
  9564473 => "Mandalay",
  956525 => "Ngape",
  9567439 => "Naypyidaw",
  9567460 => "Naypyitaw",
  9567470 => "Naypyitaw",
  9567471 => "Naypyitaw",
  9567550 => "Naypyidaw",
  9569200 => "Aunglan",
  956940 => "Sinpaungwae",
  9570470 => "Hakha",
  95712032 => "Ohbotaung",
  9571470 => "Monywa",
  9574470 => "Myitkyinar\/Bahmaw",
  9575470 => "Shwebo",
  95812820 => "Moenae",
  95812821 => "Moenae",
  95812822 => "Moenae",
  95812823 => "Moenae",
  95812824 => "Moenae",
  958130 => "Pinlon",
  958131 => "Loilem",
  958141 => "Naungtayar",
  9581470 => "Taunggyi",
  958149 => "Sesin",
  9582320 => "Manton",
  958238 => "Tantyan",
  9583470 => "Loikaw",
  958521 => "Pyinoolwin",
  958522 => "Pyinoolwin",
  958523 => "Pyinoolwin",
  958528 => "Pyinoolwin",
  958529 => "Padaythar\ Myothit",
  958540 => "Ohn\ Chaw",
  958541 => "Pyinoolwin",
  958542 => "Pyinoolwin",
  958543 => "Pyinoolwin",
  958544 => "Pyinoolwin",
  958545 => "Pyinoolwin",
  958546 => "Pyinoolwin",
  958547 => "Pyinoolwin",
  958548 => "Pyinoolwin",
  958549 => "Pyinoolwin",
  958620 => "Mogoke",
  958621 => "Mogoke",
  958625 => "Kyatpyin",
  958630 => "Thabeikkyin",
  958635 => "Sintkuu",
  958639 => "Letpanhla",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+95|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;