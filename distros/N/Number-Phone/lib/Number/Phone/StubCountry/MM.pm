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
our $VERSION = 1.20190912215427;

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
                4[1-9]|
                51
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
                [68]20
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
                4[1-9]|
                51
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
                [68]20
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
                6[7-9]\\d|
                7(?:
                  3|
                  5[0-2]|
                  [6-9]\\d
                )|
                8(?:
                  8[7-9]|
                  9\\d
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
$areanames{en}->{951422} = "Yangon";
$areanames{en}->{951423} = "Yangon";
$areanames{en}->{951424} = "Yangon";
$areanames{en}->{951426} = "Yangon";
$areanames{en}->{951429} = "Yangon";
$areanames{en}->{951439} = "Yangon";
$areanames{en}->{951446} = "Yangon";
$areanames{en}->{951462} = "Yangon";
$areanames{en}->{951465} = "Yangon";
$areanames{en}->{951470} = "Yangon";
$areanames{en}->{951550} = "Bahan";
$areanames{en}->{951551} = "Bahan";
$areanames{en}->{951552} = "Bahan";
$areanames{en}->{951553} = "Bahan";
$areanames{en}->{951680} = "Bayintnaung";
$areanames{en}->{951681} = "Bayintnaung";
$areanames{en}->{951682} = "Bayintnaung";
$areanames{en}->{951683} = "Bayintnaung";
$areanames{en}->{951684} = "Bayintnaung";
$areanames{en}->{951685} = "Bayintnaung";
$areanames{en}->{951686} = "Bayintnaung";
$areanames{en}->{951687} = "Bayintnaung";
$areanames{en}->{951688} = "Bayintnaung";
$areanames{en}->{9522000} = "Mingalar\ Mandalay";
$areanames{en}->{952422} = "Mandalay";
$areanames{en}->{952424} = "Mandalay";
$areanames{en}->{952426} = "Mandalay";
$areanames{en}->{952439} = "Mandalay";
$areanames{en}->{952446} = "Mandalay";
$areanames{en}->{952462} = "Mandalay";
$areanames{en}->{952470} = "Yangon";
$areanames{en}->{952471} = "Mandalay";
$areanames{en}->{952472} = "Mandalay";
$areanames{en}->{95256} = "Amarapura";
$areanames{en}->{9542480} = "Pathein";
$areanames{en}->{9542481} = "Pathein";
$areanames{en}->{9542482} = "Ayeyarwaddy";
$areanames{en}->{9543202} = "Rakhine";
$areanames{en}->{9543470} = "Sittwe";
$areanames{en}->{954353} = "Buthidaung";
$areanames{en}->{9543565} = "Palatwa";
$areanames{en}->{9545470} = "Pyapon";
$areanames{en}->{95522221} = "Bago";
$areanames{en}->{95522222} = "Bago";
$areanames{en}->{95522223} = "Bago";
$areanames{en}->{95522224} = "Bago";
$areanames{en}->{95522230} = "Oathar\ Myothit";
$areanames{en}->{9552470} = "Bago";
$areanames{en}->{9552472} = "Bago";
$areanames{en}->{9552473} = "Bago";
$areanames{en}->{9553472} = "Pyay";
$areanames{en}->{9553473} = "Pyay";
$areanames{en}->{9554470} = "Taungoo";
$areanames{en}->{955620} = "Mandalay";
$areanames{en}->{955645} = "Tandar";
$areanames{en}->{9557480} = "Mawlamyine\/Thanbyuzayat";
$areanames{en}->{9557481} = "Mawlamyine";
$areanames{en}->{9557482} = "Mon";
$areanames{en}->{9558470} = "Hpa\-An";
$areanames{en}->{955851} = "Myawaddy";
$areanames{en}->{9559470} = "Dawei";
$areanames{en}->{9559471} = "Tanintharyi";
$areanames{en}->{9561200} = "Chauk";
$areanames{en}->{956124620} = "Chauk";
$areanames{en}->{956124621} = "Chauk";
$areanames{en}->{956124622} = "Chauk";
$areanames{en}->{956124623} = "Chauk";
$areanames{en}->{956124624} = "Chauk";
$areanames{en}->{956124640} = "Bagan";
$areanames{en}->{956124641} = "Bagan";
$areanames{en}->{956124642} = "Bagan";
$areanames{en}->{956124643} = "Bagan";
$areanames{en}->{956124644} = "Bagan";
$areanames{en}->{9562472} = "Pakokku";
$areanames{en}->{9562473} = "Magway";
$areanames{en}->{956260} = "Kanma";
$areanames{en}->{956320} = "Magway";
$areanames{en}->{956323} = "Magway";
$areanames{en}->{956324} = "Magway";
$areanames{en}->{9563470} = "Magway";
$areanames{en}->{95642487} = "Shawpin";
$areanames{en}->{9564472} = "Meiktila";
$areanames{en}->{9564473} = "Mandalay";
$areanames{en}->{956525} = "Ngape";
$areanames{en}->{9567439} = "Naypyidaw";
$areanames{en}->{9567460} = "Naypyitaw";
$areanames{en}->{9567470} = "Naypyitaw";
$areanames{en}->{9567471} = "Naypyitaw";
$areanames{en}->{9567550} = "Naypyidaw";
$areanames{en}->{9569200} = "Aunglan";
$areanames{en}->{956940} = "Sinpaungwae";
$areanames{en}->{9570470} = "Hakha";
$areanames{en}->{95712032} = "Ohbotaung";
$areanames{en}->{9571470} = "Monywa";
$areanames{en}->{9574470} = "Myitkyinar\/Bahmaw";
$areanames{en}->{9575470} = "Shwebo";
$areanames{en}->{95812820} = "Moenae";
$areanames{en}->{95812821} = "Moenae";
$areanames{en}->{95812822} = "Moenae";
$areanames{en}->{95812823} = "Moenae";
$areanames{en}->{95812824} = "Moenae";
$areanames{en}->{958130} = "Pinlon";
$areanames{en}->{958131} = "Loilem";
$areanames{en}->{958141} = "Naungtayar";
$areanames{en}->{9581470} = "Taunggyi";
$areanames{en}->{958149} = "Sesin";
$areanames{en}->{9582320} = "Manton";
$areanames{en}->{958238} = "Tantyan";
$areanames{en}->{9583470} = "Loikaw";
$areanames{en}->{958521} = "Pyinoolwin";
$areanames{en}->{958522} = "Pyinoolwin";
$areanames{en}->{958523} = "Pyinoolwin";
$areanames{en}->{958528} = "Pyinoolwin";
$areanames{en}->{958529} = "Padaythar\ Myothit";
$areanames{en}->{958540} = "Ohn\ Chaw";
$areanames{en}->{958541} = "Pyinoolwin";
$areanames{en}->{958542} = "Pyinoolwin";
$areanames{en}->{958543} = "Pyinoolwin";
$areanames{en}->{958544} = "Pyinoolwin";
$areanames{en}->{958545} = "Pyinoolwin";
$areanames{en}->{958546} = "Pyinoolwin";
$areanames{en}->{958547} = "Pyinoolwin";
$areanames{en}->{958548} = "Pyinoolwin";
$areanames{en}->{958549} = "Pyinoolwin";
$areanames{en}->{958551} = "Yangon";
$areanames{en}->{958620} = "Mogoke";
$areanames{en}->{958621} = "Mogoke";
$areanames{en}->{958625} = "Kyatpyin";
$areanames{en}->{958630} = "Thabeikkyin";
$areanames{en}->{958635} = "Sintkuu";
$areanames{en}->{958639} = "Letpanhla";

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