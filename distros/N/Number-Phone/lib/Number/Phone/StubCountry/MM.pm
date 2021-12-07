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
our $VERSION = 1.20211206222446;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            16|
            2
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
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
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[12]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [4-7]|
            8[1-35]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            9(?:
              2[0-4]|
              [35-9]|
              4[137-9]
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{4,6})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '92',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{5})(\\d{4})'
                }
              ];

my $validators = {
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
                7[0-3]|
                83
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
                7[0-3]|
                83
              )|
              51\\d\\d
            )|
            4(?:
              2(?:
                2\\d\\d|
                48[0-3]
              )|
              3(?:
                20\\d|
                4(?:
                  70|
                  83
                )|
                56
              )|
              420\\d|
              5470
            )|
            6(?:
              0(?:
                [23]|
                88\\d
              )|
              (?:
                124|
                [56]2\\d
              )\\d|
              247[23]|
              3(?:
                20\\d|
                470
              )|
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
                  7[013]
                )
              )
            )
          )\\d{4}|
          5(?:
            2(?:
              2\\d{5,6}|
              47[023]\\d{4}
            )|
            (?:
              347[23]|
              4(?:
                2(?:
                  1|
                  86
                )|
                470
              )|
              522\\d|
              6(?:
                20\\d|
                483
              )|
              7(?:
                20\\d|
                48[0-2]
              )|
              8(?:
                20\\d|
                47[02]
              )|
              9(?:
                20\\d|
                47[01]
              )
            )\\d{4}
          )|
          7(?:
            (?:
              0470|
              4(?:
                25\\d|
                470
              )|
              5(?:
                202|
                470|
                96\\d
              )
            )\\d{4}|
            1(?:
              20\\d{4,5}|
              4(?:
                70|
                83
              )\\d{4}
            )
          )|
          8(?:
            1(?:
              2\\d{5,6}|
              4(?:
                10|
                7[01]\\d
              )\\d{3}
            )|
            2(?:
              2\\d{5,6}|
              (?:
                320|
                490\\d
              )\\d{3}
            )|
            (?:
              3(?:
                2\\d\\d|
                470
              )|
              4[24-7]|
              5(?:
                2\\d|
                4[1-9]|
                51
              )\\d|
              6[23]
            )\\d{4}
          )|
          (?:
            1[2-6]\\d|
            4(?:
              2[24-8]|
              3[2-7]|
              [46][2-6]|
              5[3-5]
            )|
            5(?:
              [27][2-8]|
              3[2-68]|
              4[24-8]|
              5[23]|
              6[2-4]|
              8[24-7]|
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
              [04][24-8]|
              [15][2-7]|
              22|
              3[2-4]
            )|
            8(?:
              1[2-689]|
              2[2-8]|
              [35]2\\d
            )
          )\\d{4}|
          25\\d{5,6}|
          (?:
            2[2-9]|
            6(?:
              1[2356]|
              [24][2-6]|
              3[24-6]|
              5[2-4]|
              6[2-8]|
              7[235-7]|
              8[245]|
              9[24]
            )|
            8(?:
              3[24]|
              5[245]
            )
          )\\d{4}
        ',
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
                7[0-3]|
                83
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
                7[0-3]|
                83
              )|
              51\\d\\d
            )|
            4(?:
              2(?:
                2\\d\\d|
                48[0-3]
              )|
              3(?:
                20\\d|
                4(?:
                  70|
                  83
                )|
                56
              )|
              420\\d|
              5470
            )|
            6(?:
              0(?:
                [23]|
                88\\d
              )|
              (?:
                124|
                [56]2\\d
              )\\d|
              247[23]|
              3(?:
                20\\d|
                470
              )|
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
                  7[013]
                )
              )
            )
          )\\d{4}|
          5(?:
            2(?:
              2\\d{5,6}|
              47[023]\\d{4}
            )|
            (?:
              347[23]|
              4(?:
                2(?:
                  1|
                  86
                )|
                470
              )|
              522\\d|
              6(?:
                20\\d|
                483
              )|
              7(?:
                20\\d|
                48[0-2]
              )|
              8(?:
                20\\d|
                47[02]
              )|
              9(?:
                20\\d|
                47[01]
              )
            )\\d{4}
          )|
          7(?:
            (?:
              0470|
              4(?:
                25\\d|
                470
              )|
              5(?:
                202|
                470|
                96\\d
              )
            )\\d{4}|
            1(?:
              20\\d{4,5}|
              4(?:
                70|
                83
              )\\d{4}
            )
          )|
          8(?:
            1(?:
              2\\d{5,6}|
              4(?:
                10|
                7[01]\\d
              )\\d{3}
            )|
            2(?:
              2\\d{5,6}|
              (?:
                320|
                490\\d
              )\\d{3}
            )|
            (?:
              3(?:
                2\\d\\d|
                470
              )|
              4[24-7]|
              5(?:
                2\\d|
                4[1-9]|
                51
              )\\d|
              6[23]
            )\\d{4}
          )|
          (?:
            1[2-6]\\d|
            4(?:
              2[24-8]|
              3[2-7]|
              [46][2-6]|
              5[3-5]
            )|
            5(?:
              [27][2-8]|
              3[2-68]|
              4[24-8]|
              5[23]|
              6[2-4]|
              8[24-7]|
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
              [04][24-8]|
              [15][2-7]|
              22|
              3[2-4]
            )|
            8(?:
              1[2-689]|
              2[2-8]|
              [35]2\\d
            )
          )\\d{4}|
          25\\d{5,6}|
          (?:
            2[2-9]|
            6(?:
              1[2356]|
              [24][2-6]|
              3[24-6]|
              5[2-4]|
              6[2-8]|
              7[235-7]|
              8[245]|
              9[24]
            )|
            8(?:
              3[24]|
              5[245]
            )
          )\\d{4}
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
                  6\\d|
                  8[89]|
                  9[4-8]
                )\\d|
                7(?:
                  3|
                  40|
                  [5-9]\\d
                )
              )\\d|
              4(?:
                (?:
                  [0245]\\d|
                  [1379]
                )\\d|
                88
              )|
              5[0-6]
            )\\d
          )\\d{4}|
          9[69]1\\d{6}|
          9(?:
            [68]\\d|
            9[089]
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '
          80080(?:
            [01][1-9]|
            2\\d
          )\\d{3}
        ',
                'voip' => '
          1333\\d{4}|
          [12]468\\d{4}
        '
              };
my %areanames = ();
$areanames{en} = {"956124642", "Bagan",
"958522", "Pyinoolwin",
"9543470", "Sittwe",
"9570470", "Hakha",
"95522223", "Bago",
"952483", "Mandalay",
"951685", "Bayintnaung",
"9567470", "Naypyitaw",
"951552", "Bahan",
"9582490", "Shan\ \(North\)",
"952472", "Mandalay",
"9558470", "Hpa\-An",
"951681", "Bayintnaung",
"951683", "Bayintnaung",
"958549", "Pyinoolwin",
"9581471", "Shan\ \(South\)",
"9582320", "Manton",
"9567439", "Naypyidaw",
"956124640", "Bagan",
"958620", "Mogoke",
"951429", "Yangon",
"958238", "Tantyan",
"95642487", "Shawpin",
"9543483", "Sittwe\/Thandwe",
"9574470", "Myitkyinar\/Bahmaw",
"9558472", "Hpa\-An",
"95812820", "Moenae",
"958630", "Thabeikkyin",
"9567550", "Naypyidaw",
"951446", "Yangon",
"951439", "Yangon",
"9553473", "Pyay",
"951684", "Bayintnaung",
"958548", "Pyinoolwin",
"95812824", "Moenae",
"951473", "Yangon",
"951471", "Yangon",
"956124623", "Chauk",
"958149", "Sesin",
"951472", "Yangon",
"958547", "Pyinoolwin",
"958540", "Ohn\ Chaw",
"956124621", "Chauk",
"958131", "Loilem",
"9545470", "Pyapon",
"9542481", "Pathein",
"956124624", "Chauk",
"9557482", "Mon",
"95256", "Amarapura",
"9567473", "Naypyitaw",
"9553472", "Pyay",
"951483", "Yangon",
"9557480", "Mawlamyine\/Thanbyuzayat",
"958639", "Letpanhla",
"952473", "Mandalay",
"951686", "Bayintnaung",
"952439", "Mandalay",
"958551", "Yangon",
"952446", "Mandalay",
"95522222", "Bago",
"95522221", "Bago",
"951682", "Bayintnaung",
"952471", "Mandalay",
"958523", "Pyinoolwin",
"951551", "Bahan",
"9559470", "Dawei",
"9563470", "Magway",
"958521", "Pyinoolwin",
"951553", "Bahan",
"956320", "Magway",
"9552472", "Bago",
"9557481", "Mawlamyine",
"958621", "Mogoke",
"956124643", "Bagan",
"95812821", "Moenae",
"958529", "Padaythar\ Myothit",
"956525", "Ngape",
"9561200", "Chauk",
"958635", "Sintkuu",
"95812822", "Moenae",
"9554470", "Taungoo",
"9559471", "Tanintharyi",
"9542482", "Ayeyarwaddy",
"958542", "Pyinoolwin",
"9575470", "Shwebo",
"9583470", "Loikaw",
"9571483", "Monywa",
"958546", "Pyinoolwin",
"958625", "Kyatpyin",
"9562472", "Pakokku",
"956124620", "Chauk",
"951470", "Yangon",
"952424", "Mandalay",
"951426", "Yangon",
"95522230", "Oathar\ Myothit",
"958528", "Pyinoolwin",
"9543202", "Rakhine",
"951422", "Yangon",
"955851", "Myawaddy",
"9542480", "Pathein",
"951680", "Bayintnaung",
"951462", "Yangon",
"954353", "Buthidaung",
"9571470", "Monywa",
"9564472", "Meiktila",
"9552470", "Bago",
"951687", "Bayintnaung",
"956260", "Kanma",
"956124622", "Chauk",
"958141", "Naungtayar",
"952470", "Yangon",
"958544", "Pyinoolwin",
"9543565", "Palatwa",
"951688", "Bayintnaung",
"9567460", "Naypyitaw",
"951465", "Yangon",
"95712032", "Ohbotaung",
"951550", "Bahan",
"956323", "Magway",
"955620", "Mandalay",
"95522224", "Bago",
"9564473", "Mandalay",
"951423", "Yangon",
"9522000", "Mingalar\ Mandalay",
"958543", "Pyinoolwin",
"952462", "Mandalay",
"95812823", "Moenae",
"9567471", "Naypyitaw",
"958541", "Pyinoolwin",
"958130", "Pinlon",
"956124644", "Bagan",
"9552473", "Bago",
"9556483", "Thanlyin",
"958545", "Pyinoolwin",
"9562473", "Magway",
"952426", "Mandalay",
"956124641", "Bagan",
"9569200", "Aunglan",
"951424", "Yangon",
"956324", "Magway",
"956940", "Sinpaungwae",
"9542483", "Ayeyarwaddy\/Pathein",
"9581470", "Taunggyi",
"952422", "Mandalay",
"955645", "Tandar",};

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