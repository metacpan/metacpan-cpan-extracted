# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20230614174404;

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
                2[29]|
                39|
                62|
                7[0-2]|
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
                [26]2|
                39|
                7[0-2]|
                83
              )|
              51\\d\\d
            )|
            4(?:
              2(?:
                2\\d\\d|
                48[013]
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
              2472|
              3(?:
                20\\d|
                470
              )|
              4(?:
                2[04]\\d|
                472
              )|
              7(?:
                (?:
                  3\\d|
                  8[01459]
                )\\d|
                4(?:
                  39|
                  [67]0
                )
              )
            )
          )\\d{4}|
          5(?:
            2(?:
              2\\d{5,6}|
              47[02]\\d{4}
            )|
            (?:
              3472|
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
                48[01]
              )|
              8(?:
                20\\d|
                47[02]
              )|
              9(?:
                20\\d|
                470
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
                (?:
                  2\\d|
                  51
                )\\d|
                4(?:
                  [1-35-9]\\d|
                  4[0-57-9]
                )
              )|
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
                2[29]|
                39|
                62|
                7[0-2]|
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
                [26]2|
                39|
                7[0-2]|
                83
              )|
              51\\d\\d
            )|
            4(?:
              2(?:
                2\\d\\d|
                48[013]
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
              2472|
              3(?:
                20\\d|
                470
              )|
              4(?:
                2[04]\\d|
                472
              )|
              7(?:
                (?:
                  3\\d|
                  8[01459]
                )\\d|
                4(?:
                  39|
                  [67]0
                )
              )
            )
          )\\d{4}|
          5(?:
            2(?:
              2\\d{5,6}|
              47[02]\\d{4}
            )|
            (?:
              3472|
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
                48[01]
              )|
              8(?:
                20\\d|
                47[02]
              )|
              9(?:
                20\\d|
                470
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
                (?:
                  2\\d|
                  51
                )\\d|
                4(?:
                  [1-35-9]\\d|
                  4[0-57-9]
                )
              )|
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
            0[1-9]|
            2\\d
          )\\d{3}
        ',
                'voip' => '
          1333\\d{4}|
          [12]468\\d{4}
        '
              };
my %areanames = ();
$areanames{en} = {"9558470", "Hpa\-An",
"958528", "Pyinoolwin",
"955851", "Myawaddy",
"9581471", "Shan\ \(South\)",
"958546", "Pyinoolwin",
"9545470", "Pyapon",
"95812822", "Moenae",
"951424", "Yangon",
"952424", "Mandalay",
"9582490", "Shan\ \(North\)",
"952483", "Mandalay",
"9556483", "Thanlyin",
"951483", "Yangon",
"951551", "Bahan",
"951550", "Bahan",
"9543565", "Palatwa",
"958529", "Padaythar\ Myothit",
"951552", "Bahan",
"9542483", "Ayeyarwaddy\/Pathein",
"95812824", "Moenae",
"951684", "Bayintnaung",
"9543470", "Sittwe",
"958620", "Mogoke",
"958541", "Pyinoolwin",
"9564472", "Meiktila",
"958621", "Mogoke",
"9585440", "Pyinoolwin",
"958540", "Ohn\ Chaw",
"958542", "Pyinoolwin",
"9567460", "Naypyitaw",
"956323", "Magway",
"9585448", "Pyinoolwin",
"95812820", "Moenae",
"951422", "Yangon",
"956525", "Ngape",
"952422", "Mandalay",
"9542481", "Pathein",
"956124622", "Chauk",
"9582320", "Manton",
"956124643", "Bagan",
"951686", "Bayintnaung",
"95812821", "Moenae",
"9569200", "Aunglan",
"9554470", "Taungoo",
"958630", "Thabeikkyin",
"951681", "Bayintnaung",
"951465", "Yangon",
"956124642", "Bagan",
"951680", "Bayintnaung",
"951682", "Bayintnaung",
"9567439", "Naypyidaw",
"9585447", "Pyinoolwin",
"9571483", "Monywa",
"958141", "Naungtayar",
"9557480", "Mawlamyine\/Thanbyuzayat",
"9567550", "Naypyidaw",
"958523", "Pyinoolwin",
"951426", "Yangon",
"9552472", "Bago",
"952426", "Mandalay",
"951470", "Yangon",
"952471", "Mandalay",
"95522223", "Bago",
"951471", "Yangon",
"952470", "Yangon",
"952472", "Mandalay",
"9585445", "Pyinoolwin",
"956124623", "Chauk",
"951472", "Yangon",
"9585444", "Pyinoolwin",
"951683", "Bayintnaung",
"956124640", "Bagan",
"95522224", "Bago",
"956124644", "Bagan",
"956124641", "Bagan",
"958521", "Pyinoolwin",
"9585441", "Pyinoolwin",
"958522", "Pyinoolwin",
"958635", "Sintkuu",
"9552470", "Bago",
"958238", "Tantyan",
"956260", "Kanma",
"9561200", "Chauk",
"9581470", "Taunggyi",
"958131", "Loilem",
"956124621", "Chauk",
"956320", "Magway",
"958548", "Pyinoolwin",
"955620", "Mandalay",
"9553472", "Pyay",
"951423", "Yangon",
"958130", "Pinlon",
"951439", "Yangon",
"952439", "Mandalay",
"956124624", "Chauk",
"952462", "Mandalay",
"956124620", "Chauk",
"95522222", "Bago",
"95712032", "Ohbotaung",
"951462", "Yangon",
"951685", "Bayintnaung",
"9522000", "Mingalar\ Mandalay",
"95642487", "Shawpin",
"956940", "Sinpaungwae",
"958547", "Pyinoolwin",
"958549", "Pyinoolwin",
"9571470", "Monywa",
"9585449", "Pyinoolwin",
"95522230", "Oathar\ Myothit",
"9563470", "Magway",
"951429", "Yangon",
"955645", "Tandar",
"9557481", "Mawlamyine",
"95256", "Amarapura",
"954353", "Buthidaung",
"9585442", "Pyinoolwin",
"958543", "Pyinoolwin",
"9583470", "Loikaw",
"9574470", "Myitkyinar\/Bahmaw",
"958639", "Letpanhla",
"95812823", "Moenae",
"9558472", "Hpa\-An",
"958149", "Sesin",
"9570470", "Hakha",
"9575470", "Shwebo",
"951687", "Bayintnaung",
"9543202", "Rakhine",
"9542480", "Pathein",
"956324", "Magway",
"9567470", "Naypyitaw",
"951688", "Bayintnaung",
"9543483", "Sittwe\/Thandwe",
"9559470", "Dawei",
"95522221", "Bago",
"951553", "Bahan",
"958551", "Yangon",
"958545", "Pyinoolwin",
"958625", "Kyatpyin",
"9562472", "Pakokku",
"9585443", "Pyinoolwin",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+95|\D)//g;
      my $self = bless({ country_code => '95', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '95', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;