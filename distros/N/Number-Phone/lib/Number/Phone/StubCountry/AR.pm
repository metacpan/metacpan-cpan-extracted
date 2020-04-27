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
package Number::Phone::StubCountry::AR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120026;

my $formatters = [
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '
            0|
            1(?:
              0[0-35-7]|
              1[02-5]|
              2[015]|
              34|
              4[78]
            )|
            911
          ',
                  'pattern' => '(\\d{3})'
                },
                {
                  'format' => '$1-$2',
                  'intl_format' => 'NA',
                  'leading_digits' => '[1-9]',
                  'pattern' => '(\\d{2})(\\d{4})'
                },
                {
                  'format' => '$1-$2',
                  'intl_format' => 'NA',
                  'leading_digits' => '[2-8]',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1-$2',
                  'intl_format' => 'NA',
                  'leading_digits' => '[1-8]',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2-$3',
                  'leading_digits' => '
            2(?:
              [23]02|
              6(?:
                [25]|
                4(?:
                  64|
                  [78]
                )
              )|
              9(?:
                [02356]|
                4(?:
                  [0268]|
                  5[2-6]
                )|
                72|
                8[23]
              )
            )|
            3(?:
              3[28]|
              4(?:
                [04679]|
                3(?:
                  5(?:
                    4[0-25689]|
                    [56]
                  )|
                  [78]
                )|
                58|
                8[2379]
              )|
              5(?:
                [2467]|
                3[237]|
                8(?:
                  [23]|
                  4(?:
                    [45]|
                    60
                  )|
                  5(?:
                    4[0-39]|
                    5|
                    64
                  )
                )
              )|
              7[1-578]|
              8(?:
                [2469]|
                3[278]|
                54(?:
                  4|
                  5[13-7]|
                  6[89]
                )|
                86[3-6]
              )
            )|
            2(?:
              2[24-9]|
              3[1-59]|
              47
            )|
            38(?:
              [58][78]|
              7[378]
            )|
            3(?:
              454|
              85[56]
            )[46]|
            3(?:
              4(?:
                36|
                5[56]
              )|
              8(?:
                [38]5|
                76
              )
            )[4-6]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4})(\\d{2})(\\d{4})'
                },
                {
                  'format' => '$1 $2-$3',
                  'leading_digits' => '1',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '[68]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2-$3',
                  'leading_digits' => '[23]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$2 15-$3-$4',
                  'intl_format' => '$1 $2 $3-$4',
                  'leading_digits' => '
            9(?:
              2(?:
                [23]02|
                6(?:
                  [25]|
                  4(?:
                    64|
                    [78]
                  )
                )|
                9(?:
                  [02356]|
                  4(?:
                    [0268]|
                    5[2-6]
                  )|
                  72|
                  8[23]
                )
              )|
              3(?:
                3[28]|
                4(?:
                  [04679]|
                  3(?:
                    5(?:
                      4[0-25689]|
                      [56]
                    )|
                    [78]
                  )|
                  5(?:
                    4[46]|
                    8
                  )|
                  8[2379]
                )|
                5(?:
                  [2467]|
                  3[237]|
                  8(?:
                    [23]|
                    4(?:
                      [45]|
                      60
                    )|
                    5(?:
                      4[0-39]|
                      5|
                      64
                    )
                  )
                )|
                7[1-578]|
                8(?:
                  [2469]|
                  3[278]|
                  5(?:
                    4(?:
                      4|
                      5[13-7]|
                      6[89]
                    )|
                    [56][46]|
                    [78]
                  )|
                  7[378]|
                  8(?:
                    6[3-6]|
                    [78]
                  )
                )
              )
            )|
            92(?:
              2[24-9]|
              3[1-59]|
              47
            )|
            93(?:
              4(?:
                36|
                5[56]
              )|
              8(?:
                [38]5|
                76
              )
            )[4-6]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{4})(\\d{2})(\\d{4})'
                },
                {
                  'format' => '$2 15-$3-$4',
                  'intl_format' => '$1 $2 $3-$4',
                  'leading_digits' => '91',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$2 15-$3-$4',
                  'intl_format' => '$1 $2 $3-$4',
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          3888[013-9]\\d{5}|
          (?:
            29(?:
              54|
              66
            )|
            3(?:
              777|
              865
            )
          )[2-8]\\d{5}|
          3(?:
            7(?:
              1[15]|
              81
            )|
            8(?:
              21|
              4[16]|
              69|
              9[12]
            )
          )[46]\\d{5}|
          (?:
            2(?:
              2(?:
                2[59]|
                44|
                52
              )|
              3(?:
                26|
                44
              )|
              473|
              9(?:
                [07]2|
                2[26]|
                34|
                46
              )
            )|
            3327
          )[45]\\d{5}|
          (?:
            2(?:
              284|
              302|
              657|
              920
            )|
            3(?:
              4(?:
                8[27]|
                92
              )|
              541|
              755|
              878
            )
          )[2-7]\\d{5}|
          (?:
            2(?:
              (?:
                26|
                62
              )2|
              32[03]|
              477|
              9(?:
                42|
                83
              )
            )|
            3(?:
              329|
              4(?:
                [47]6|
                62|
                89
              )|
              564
            )
          )[2-6]\\d{5}|
          (?:
            (?:
              11[1-8]|
              670
            )\\d|
            2(?:
              2(?:
                0[45]|
                1[2-6]|
                3[3-6]
              )|
              3(?:
                [06]4|
                7[45]
              )|
              494|
              6(?:
                04|
                1[2-7]|
                [36][45]|
                4[3-6]
              )|
              80[45]|
              9(?:
                [17][4-6]|
                [48][45]|
                9[3-6]
              )
            )|
            3(?:
              364|
              4(?:
                1[2-7]|
                [235][4-6]|
                84
              )|
              5(?:
                1[2-8]|
                [38][4-6]
              )|
              6(?:
                2[45]|
                44
              )|
              7[069][45]|
              8(?:
                [03][45]|
                [17][2-6]|
                [58][3-6]
              )
            )
          )\\d{6}|
          2(?:
            2(?:
              21|
              4[23]|
              6[145]|
              7[1-4]|
              8[356]|
              9[267]
            )|
            3(?:
              16|
              3[13-8]|
              43|
              5[346-8]|
              9[3-5]
            )|
            475|
            6(?:
              2[46]|
              4[78]|
              5[1568]
            )|
            9(?:
              03|
              2[1457-9]|
              3[1356]|
              4[08]|
              [56][23]|
              82
            )
          )4\\d{5}|
          (?:
            2(?:
              2(?:
                57|
                81
              )|
              3(?:
                24|
                46|
                92
              )|
              9(?:
                01|
                23|
                64
              )
            )|
            3(?:
              4(?:
                42|
                71
              )|
              5(?:
                25|
                37|
                4[347]|
                71
              )|
              7(?:
                18|
                5[17]
              )
            )
          )[3-6]\\d{5}|
          (?:
            2(?:
              2(?:
                02|
                2[3467]|
                4[156]|
                5[45]|
                6[6-8]|
                91
              )|
              3(?:
                1[47]|
                25|
                [45][25]|
                96
              )|
              47[48]|
              625|
              932
            )|
            3(?:
              38[2578]|
              4(?:
                0[0-24-9]|
                3[78]|
                4[457]|
                58|
                6[03-9]|
                72|
                83|
                9[136-8]
              )|
              5(?:
                2[124]|
                [368][23]|
                4[2689]|
                7[2-6]
              )|
              7(?:
                16|
                2[15]|
                3[145]|
                4[13]|
                5[468]|
                7[2-5]|
                8[26]
              )|
              8(?:
                2[5-7]|
                3[278]|
                4[3-5]|
                5[78]|
                6[1-378]|
                [78]7|
                94
              )
            )
          )[4-6]\\d{5}
        ',
                'geographic' => '
          3888[013-9]\\d{5}|
          (?:
            29(?:
              54|
              66
            )|
            3(?:
              777|
              865
            )
          )[2-8]\\d{5}|
          3(?:
            7(?:
              1[15]|
              81
            )|
            8(?:
              21|
              4[16]|
              69|
              9[12]
            )
          )[46]\\d{5}|
          (?:
            2(?:
              2(?:
                2[59]|
                44|
                52
              )|
              3(?:
                26|
                44
              )|
              473|
              9(?:
                [07]2|
                2[26]|
                34|
                46
              )
            )|
            3327
          )[45]\\d{5}|
          (?:
            2(?:
              284|
              302|
              657|
              920
            )|
            3(?:
              4(?:
                8[27]|
                92
              )|
              541|
              755|
              878
            )
          )[2-7]\\d{5}|
          (?:
            2(?:
              (?:
                26|
                62
              )2|
              32[03]|
              477|
              9(?:
                42|
                83
              )
            )|
            3(?:
              329|
              4(?:
                [47]6|
                62|
                89
              )|
              564
            )
          )[2-6]\\d{5}|
          (?:
            (?:
              11[1-8]|
              670
            )\\d|
            2(?:
              2(?:
                0[45]|
                1[2-6]|
                3[3-6]
              )|
              3(?:
                [06]4|
                7[45]
              )|
              494|
              6(?:
                04|
                1[2-7]|
                [36][45]|
                4[3-6]
              )|
              80[45]|
              9(?:
                [17][4-6]|
                [48][45]|
                9[3-6]
              )
            )|
            3(?:
              364|
              4(?:
                1[2-7]|
                [235][4-6]|
                84
              )|
              5(?:
                1[2-8]|
                [38][4-6]
              )|
              6(?:
                2[45]|
                44
              )|
              7[069][45]|
              8(?:
                [03][45]|
                [17][2-6]|
                [58][3-6]
              )
            )
          )\\d{6}|
          2(?:
            2(?:
              21|
              4[23]|
              6[145]|
              7[1-4]|
              8[356]|
              9[267]
            )|
            3(?:
              16|
              3[13-8]|
              43|
              5[346-8]|
              9[3-5]
            )|
            475|
            6(?:
              2[46]|
              4[78]|
              5[1568]
            )|
            9(?:
              03|
              2[1457-9]|
              3[1356]|
              4[08]|
              [56][23]|
              82
            )
          )4\\d{5}|
          (?:
            2(?:
              2(?:
                57|
                81
              )|
              3(?:
                24|
                46|
                92
              )|
              9(?:
                01|
                23|
                64
              )
            )|
            3(?:
              4(?:
                42|
                71
              )|
              5(?:
                25|
                37|
                4[347]|
                71
              )|
              7(?:
                18|
                5[17]
              )
            )
          )[3-6]\\d{5}|
          (?:
            2(?:
              2(?:
                02|
                2[3467]|
                4[156]|
                5[45]|
                6[6-8]|
                91
              )|
              3(?:
                1[47]|
                25|
                [45][25]|
                96
              )|
              47[48]|
              625|
              932
            )|
            3(?:
              38[2578]|
              4(?:
                0[0-24-9]|
                3[78]|
                4[457]|
                58|
                6[03-9]|
                72|
                83|
                9[136-8]
              )|
              5(?:
                2[124]|
                [368][23]|
                4[2689]|
                7[2-6]
              )|
              7(?:
                16|
                2[15]|
                3[145]|
                4[13]|
                5[468]|
                7[2-5]|
                8[26]
              )|
              8(?:
                2[5-7]|
                3[278]|
                4[3-5]|
                5[78]|
                6[1-378]|
                [78]7|
                94
              )
            )
          )[4-6]\\d{5}
        ',
                'mobile' => '
          93888[013-9]\\d{5}|
          9(?:
            29(?:
              54|
              66
            )|
            3(?:
              777|
              865
            )
          )[2-8]\\d{5}|
          93(?:
            7(?:
              1[15]|
              81
            )|
            8(?:
              21|
              4[16]|
              69|
              9[12]
            )
          )[46]\\d{5}|
          9(?:
            2(?:
              2(?:
                2[59]|
                44|
                52
              )|
              3(?:
                26|
                44
              )|
              473|
              9(?:
                [07]2|
                2[26]|
                34|
                46
              )
            )|
            3327
          )[45]\\d{5}|
          9(?:
            2(?:
              284|
              302|
              657|
              920
            )|
            3(?:
              4(?:
                8[27]|
                92
              )|
              541|
              755|
              878
            )
          )[2-7]\\d{5}|
          9(?:
            2(?:
              (?:
                26|
                62
              )2|
              32[03]|
              477|
              9(?:
                42|
                83
              )
            )|
            3(?:
              329|
              4(?:
                [47]6|
                62|
                89
              )|
              564
            )
          )[2-6]\\d{5}|
          (?:
            675\\d|
            9(?:
              11[1-8]\\d|
              2(?:
                2(?:
                  0[45]|
                  1[2-6]|
                  3[3-6]
                )|
                3(?:
                  [06]4|
                  7[45]
                )|
                494|
                6(?:
                  04|
                  1[2-7]|
                  [36][45]|
                  4[3-6]
                )|
                80[45]|
                9(?:
                  [17][4-6]|
                  [48][45]|
                  9[3-6]
                )
              )|
              3(?:
                364|
                4(?:
                  1[2-7]|
                  [235][4-6]|
                  84
                )|
                5(?:
                  1[2-8]|
                  [38][4-6]
                )|
                6(?:
                  2[45]|
                  44
                )|
                7[069][45]|
                8(?:
                  [03][45]|
                  [17][2-6]|
                  [58][3-6]
                )
              )
            )
          )\\d{6}|
          92(?:
            2(?:
              21|
              4[23]|
              6[145]|
              7[1-4]|
              8[356]|
              9[267]
            )|
            3(?:
              16|
              3[13-8]|
              43|
              5[346-8]|
              9[3-5]
            )|
            475|
            6(?:
              2[46]|
              4[78]|
              5[1568]
            )|
            9(?:
              03|
              2[1457-9]|
              3[1356]|
              4[08]|
              [56][23]|
              82
            )
          )4\\d{5}|
          9(?:
            2(?:
              2(?:
                57|
                81
              )|
              3(?:
                24|
                46|
                92
              )|
              9(?:
                01|
                23|
                64
              )
            )|
            3(?:
              4(?:
                42|
                71
              )|
              5(?:
                25|
                37|
                4[347]|
                71
              )|
              7(?:
                18|
                5[17]
              )
            )
          )[3-6]\\d{5}|
          9(?:
            2(?:
              2(?:
                02|
                2[3467]|
                4[156]|
                5[45]|
                6[6-8]|
                91
              )|
              3(?:
                1[47]|
                25|
                [45][25]|
                96
              )|
              47[48]|
              625|
              932
            )|
            3(?:
              38[2578]|
              4(?:
                0[0-24-9]|
                3[78]|
                4[457]|
                58|
                6[03-9]|
                72|
                83|
                9[136-8]
              )|
              5(?:
                2[124]|
                [368][23]|
                4[2689]|
                7[2-6]
              )|
              7(?:
                16|
                2[15]|
                3[145]|
                4[13]|
                5[468]|
                7[2-5]|
                8[26]
              )|
              8(?:
                2[5-7]|
                3[278]|
                4[3-5]|
                5[78]|
                6[1-378]|
                [78]7|
                94
              )
            )
          )[4-6]\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(60[04579]\\d{7})|(810\\d{7})',
                'toll_free' => '800\\d{7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{es}->{541} = "Buenos\ Aires";
$areanames{es}->{542202} = "González\ Catán\/Virrey\ del\ Pino\,\ Buenos\ Aires";
$areanames{es}->{542204} = "Merlo\,\ Buenos\ Aires";
$areanames{es}->{542205} = "Merlo\,\ Buenos\ Aires";
$areanames{es}->{54221} = "La\ Plata\,\ Buenos\ Aires";
$areanames{es}->{542221} = "Magdalena\/Verónica\,\ Buenos\ Aires";
$areanames{es}->{542223} = "Brandsen\,\ Buenos\ Aires";
$areanames{es}->{542224} = "Glew\/Guernica\,\ Buenos\ Aires";
$areanames{es}->{542225} = "Alejandro\ Korn\,\ Buenos\ Aires";
$areanames{es}->{542226} = "Cañuelas\,\ Buenos\ Aires";
$areanames{es}->{542227} = "Lobos\,\ Buenos\ Aires";
$areanames{es}->{542229} = "Juan\ María\ Gutiérrez\/El\ Pato\,\ Buenos\ Aires";
$areanames{es}->{54223} = "Mar\ del\ Plata\,\ Buenos\ Aires";
$areanames{es}->{542241} = "Chascomús\,\ Buenos\ Aires";
$areanames{es}->{542242} = "Lezama\,\ Buenos\ Aires";
$areanames{es}->{542243} = "General\ Belgrano\,\ Buenos\ Aires";
$areanames{es}->{542244} = "Las\ Flores\,\ Buenos\ Aires";
$areanames{es}->{542245} = "Dolores\,\ Buenos\ Aires";
$areanames{es}->{542246} = "Santa\ Teresita\,\ Buenos\ Aires";
$areanames{es}->{542252} = "San\ Clemente\ del\ Tuyú\,\ Buenos\ Aires";
$areanames{es}->{542254} = "Pinamar\,\ Buenos\ Aires";
$areanames{es}->{542255} = "Villa\ Gesell\,\ Buenos\ Aires";
$areanames{es}->{542257} = "Mar\ de\ Ajó\,\ Buenos\ Aires";
$areanames{es}->{542261} = "Lobería\,\ Buenos\ Aires";
$areanames{es}->{542262} = "Necochea\,\ Buenos\ Aires";
$areanames{es}->{542264} = "La\ Dulce\ \(Nicanor\ Olivera\)\,\ Buenos\ Aires";
$areanames{es}->{542265} = "Coronel\ Vidal\,\ Buenos\ Aires";
$areanames{es}->{542266} = "Balcarce\,\ Buenos\ Aires";
$areanames{es}->{542267} = "General\ Juan\ Madariaga\,\ Buenos\ Aires";
$areanames{es}->{542268} = "Maipú\,\ Buenos\ Aires";
$areanames{es}->{542271} = "San\ Miguel\ del\ Monte\,\ Buenos\ Aires";
$areanames{es}->{542272} = "Navarro\,\ Buenos\ Aires";
$areanames{es}->{542273} = "Carmen\ de\ Areco\,\ Buenos\ Aires";
$areanames{es}->{542274} = "Carlos\ Spegazzini\,\ Buenos\ Aires";
$areanames{es}->{542281} = "Azul\,\ Buenos\ Aires";
$areanames{es}->{542283} = "Tapalqué\,\ Buenos\ Aires";
$areanames{es}->{542284} = "Olavarría\,\ Buenos\ Aires";
$areanames{es}->{542285} = "Laprida\,\ Buenos\ Aires";
$areanames{es}->{542286} = "General\ La\ Madrid\,\ Buenos\ Aires";
$areanames{es}->{542291} = "Miramar\,\ Buenos\ Aires";
$areanames{es}->{542292} = "Benito\ Juárez\,\ Buenos\ Aires";
$areanames{es}->{542296} = "Ayacucho\,\ Buenos\ Aires";
$areanames{es}->{542297} = "Rauch\,\ Buenos\ Aires";
$areanames{es}->{542302} = "General\ Pico\,\ La\ Pampa";
$areanames{es}->{542304} = "Pilar\,\ Buenos\ Aires";
$areanames{es}->{542314} = "Bolívar\,\ Buenos\ Aires";
$areanames{es}->{542316} = "Daireaux\,\ Buenos\ Aires";
$areanames{es}->{542317} = "9\ de\ Julio\,\ Buenos\ Aires";
$areanames{es}->{542320} = "José\ C\.\ Paz\,\ Buenos\ Aires";
$areanames{es}->{542323} = "Luján\,\ Buenos\ Aires";
$areanames{es}->{542324} = "Mercedes\,\ Buenos\ Aires";
$areanames{es}->{542325} = "San\ Andrés\ de\ Giles\,\ Buenos\ Aires";
$areanames{es}->{542326} = "San\ Antonio\ de\ Areco\,\ Buenos\ Aires";
$areanames{es}->{542331} = "Realicó\,\ La\ Pampa";
$areanames{es}->{542333} = "Quemú\ Quemú\,\ La\ Pampa";
$areanames{es}->{542334} = "Eduardo\ Castex\,\ La\ Pampa";
$areanames{es}->{542335} = "Dpto\.\ Realicó\/Rancul\,\ La\ Pampa";
$areanames{es}->{542336} = "Huinca\ Renancó\/Villa\ Huidobro\,\ Córdoba";
$areanames{es}->{542337} = "América\/Rivadavia\,\ Buenos\ Aires";
$areanames{es}->{542338} = "Victorica\,\ La\ Pampa";
$areanames{es}->{542342} = "Bragado\,\ Buenos\ Aires";
$areanames{es}->{542343} = "Norberto\ de\ La\ Riestra\,\ Buenos\ Aires";
$areanames{es}->{542344} = "Saladillo\,\ Buenos\ Aires";
$areanames{es}->{542345} = "25\ de\ Mayo\,\ Buenos\ Aires";
$areanames{es}->{542346} = "Chivilcoy\,\ Buenos\ Aires";
$areanames{es}->{542352} = "Chacabuco\,\ Buenos\ Aires";
$areanames{es}->{542353} = "General\ Arenales\,\ Buenos\ Aires";
$areanames{es}->{542354} = "Vedia\,\ Buenos\ Aires";
$areanames{es}->{542355} = "Lincoln\,\ Buenos\ Aires";
$areanames{es}->{542356} = "General\ Pinto\,\ Buenos\ Aires";
$areanames{es}->{542357} = "Carlos\ Tejedor\,\ Buenos\ Aires";
$areanames{es}->{542358} = "Los\ Toldos\,\ Buenos\ Aires";
$areanames{es}->{54236} = "Junín\,\ Buenos\ Aires";
$areanames{es}->{54237} = "Moreno\,\ Buenos\ Aires";
$areanames{es}->{542392} = "Trenque\ Lauquen\,\ Buenos\ Aires";
$areanames{es}->{542393} = "Salazar\,\ Buenos\ Aires";
$areanames{es}->{542394} = "Tres\ Lomas\/Salliqueló\,\ Buenos\ Aires";
$areanames{es}->{542395} = "Carlos\ Casares\,\ Buenos\ Aires";
$areanames{es}->{542396} = "Pehuajó\,\ Buenos\ Aires";
$areanames{es}->{542473} = "Colón\,\ Buenos\ Aires";
$areanames{es}->{542474} = "Salto\,\ Buenos\ Aires";
$areanames{es}->{542475} = "Rojas\,\ Buenos\ Aires";
$areanames{es}->{542477} = "Pergamino\,\ Buenos\ Aires";
$areanames{es}->{542478} = "Arrecifes\,\ Buenos\ Aires";
$areanames{es}->{54249} = "Tandil\,\ Buenos\ Aires";
$areanames{es}->{54260} = "San\ Rafael\,\ Mendoza";
$areanames{es}->{54261} = "Mendoza\,\ Mendoza";
$areanames{es}->{542622} = "Tunuyán\,\ Mendoza";
$areanames{es}->{542624} = "Uspallata\,\ Mendoza";
$areanames{es}->{542625} = "General\ Alvear\,\ Mendoza";
$areanames{es}->{542626} = "La\ Paz\,\ Mendoza";
$areanames{es}->{54263} = "San\ Martín\,\ Mendoza";
$areanames{es}->{542643} = "San\ Juan\,\ San\ Juan";
$areanames{es}->{542644} = "San\ Juan\,\ San\ Juan";
$areanames{es}->{542645} = "San\ Juan\,\ San\ Juan";
$areanames{es}->{542646} = "Villa\ San\ Agustín\,\ San\ Juan";
$areanames{es}->{542647} = "San\ José\ de\ Jáchal\,\ San\ Juan";
$areanames{es}->{542648} = "Calingasta\,\ San\ Juan";
$areanames{es}->{542651} = "San\ Francisco\ del\ Monte\ de\ Oro\,\ San\ Luis";
$areanames{es}->{542655} = "La\ Toma\,\ San\ Luis";
$areanames{es}->{542656} = "Merlo\,\ San\ Luis";
$areanames{es}->{542657} = "Villa\ Mercedes\,\ San\ Luis";
$areanames{es}->{542658} = "Buena\ Esperanza\,\ San\ Luis";
$areanames{es}->{54266} = "San\ Luis\,\ San\ Luis";
$areanames{es}->{5428} = "Trelew\/Rawson\,\ Chubut";
$areanames{es}->{542901} = "Ushuaia\,\ Tierra\ del\ Fuego";
$areanames{es}->{542902} = "Río\ Turbio\,\ Santa\ Cruz";
$areanames{es}->{542903} = "Río\ Mayo\,\ Chubut";
$areanames{es}->{54291} = "Bahía\ Blanca\,\ Buenos\ Aires";
$areanames{es}->{542920} = "Viedma\,\ Río\ Negro";
$areanames{es}->{542921} = "Coronel\ Dorrego\,\ Buenos\ Aires";
$areanames{es}->{542922} = "Coronel\ Pringles\,\ Buenos\ Aires";
$areanames{es}->{542923} = "Pigüé\,\ Buenos\ Aires";
$areanames{es}->{542924} = "Darregueira\,\ Buenos\ Aires";
$areanames{es}->{542925} = "Villa\ Iris\,\ Buenos\ Aires";
$areanames{es}->{542926} = "Coronel\ Suárez\,\ Buenos\ Aires";
$areanames{es}->{542927} = "Médanos\,\ Buenos\ Aires";
$areanames{es}->{542928} = "Pedro\ Luro\,\ Buenos\ Aires";
$areanames{es}->{542929} = "Guaminí\,\ Buenos\ Aires";
$areanames{es}->{542931} = "Río\ Colorado\,\ Río\ Negro";
$areanames{es}->{542932} = "Punta\ Alta\,\ Buenos\ Aires";
$areanames{es}->{542933} = "Huanguelén\,\ Buenos\ Aires";
$areanames{es}->{542934} = "San\ Antonio\ Oeste\,\ Río\ Negro";
$areanames{es}->{542935} = "Rivera\,\ Buenos\ Aires";
$areanames{es}->{542936} = "Carhué\,\ Buenos\ Aires";
$areanames{es}->{542940} = "Ingeniero\ Jacobacci\,\ Río\ Negro";
$areanames{es}->{542942} = "Zapala\,\ Neuquén";
$areanames{es}->{542944} = "San\ Carlos\ de\ Bariloche\,\ Río\ Negro";
$areanames{es}->{542945} = "Esquel\,\ Chubut";
$areanames{es}->{542946} = "Choele\ Choel\,\ Río\ Negro";
$areanames{es}->{542948} = "Chos\ Malal\,\ Neuquén";
$areanames{es}->{542952} = "General\ Acha\,\ La\ Pampa";
$areanames{es}->{542953} = "Macachín\,\ La\ Pampa";
$areanames{es}->{542954} = "Santa\ Rosa\,\ La\ Pampa";
$areanames{es}->{542962} = "Puerto\ San\ Julián\,\ Santa\ Cruz";
$areanames{es}->{542963} = "Perito\ Moreno\,\ Santa\ Cruz";
$areanames{es}->{542964} = "Río\ Grande\,\ Tierra\ del\ Fuego";
$areanames{es}->{542966} = "Río\ Gallegos\,\ Santa\ Cruz";
$areanames{es}->{542972} = "San\ Martín\ de\ los\ Andes\,\ Neuquén";
$areanames{es}->{542974} = "Comodoro\ Rivadavia\,\ Chubut";
$areanames{es}->{542975} = "Comodoro\ Rivadavia\,\ Chubut";
$areanames{es}->{542976} = "Comodoro\ Rivadavia\,\ Chubut";
$areanames{es}->{5429824} = "Claromecó\,\ Buenos\ Aires";
$areanames{es}->{54298240} = "Orense\,\ Buenos\ Aires";
$areanames{es}->{54298242} = "Orense\,\ Buenos\ Aires";
$areanames{es}->{542982497} = "San\ Francisco\ de\ Bellocq\,\ Buenos\ Aires";
$areanames{es}->{542983} = "Tres\ Arroyos\,\ Buenos\ Aires";
$areanames{es}->{542984} = "General\ Roca\,\ Río\ Negro";
$areanames{es}->{542985} = "General\ Roca\,\ Río\ Negro";
$areanames{es}->{54299} = "Neuquén\,\ Neuquén";
$areanames{es}->{543327} = "Benavídez\,\ Buenos\ Aires";
$areanames{es}->{543329} = "San\ Pedro\,\ Buenos\ Aires";
$areanames{es}->{54336} = "San\ Nicolás\,\ Buenos\ Aires";
$areanames{es}->{543382} = "Rufino\,\ Santa\ Fe";
$areanames{es}->{543385} = "Laboulaye\,\ Córdoba";
$areanames{es}->{543387} = "Buchardo\,\ Córdoba";
$areanames{es}->{543388} = "General\ Villegas\,\ Buenos\ Aires";
$areanames{es}->{543400} = "Villa\ Constitución\,\ Santa\ Fe";
$areanames{es}->{543401} = "El\ Trébol\,\ Santa\ Fe";
$areanames{es}->{543402} = "Arroyo\ Seco\,\ Santa\ Fe";
$areanames{es}->{543404} = "Dpto\.\ Las\ Colonias\,\ Santa\ Fe";
$areanames{es}->{543405} = "San\ Javier\,\ Santa\ Fe";
$areanames{es}->{543406} = "San\ Jorge\,\ Santa\ Fe";
$areanames{es}->{543407} = "Ramallo\,\ Buenos\ Aires";
$areanames{es}->{543408} = "San\ Cristóbal\,\ Santa\ Fe";
$areanames{es}->{543409} = "Moisés\ Ville\,\ Santa\ Fe";
$areanames{es}->{54341} = "Rosario\,\ Santa\ Fe";
$areanames{es}->{54342} = "Santa\ Fe\,\ Santa\ Fe";
$areanames{es}->{543434} = "Paraná\,\ Entre\ Ríos";
$areanames{es}->{543435} = "Nogoyá\,\ Entre\ Ríos";
$areanames{es}->{543436} = "Victoria\,\ Entre\ Ríos";
$areanames{es}->{543437} = "La\ Paz\,\ Entre\ Ríos";
$areanames{es}->{543438} = "Bovril\,\ Entre\ Ríos";
$areanames{es}->{543442} = "Concepción\ del\ Uruguay\,\ Entre\ Ríos";
$areanames{es}->{543444} = "Gualeguay\,\ Entre\ Ríos";
$areanames{es}->{543445} = "Rosario\ del\ Tala\,\ Entre\ Ríos";
$areanames{es}->{543446} = "Gualeguaychú\,\ Entre\ Ríos";
$areanames{es}->{543447} = "Colón\,\ Entre\ Ríos";
$areanames{es}->{543454} = "Federal\,\ Entre\ Ríos";
$areanames{es}->{543455} = "Villaguay\,\ Entre\ Ríos";
$areanames{es}->{543456} = "Chajarí\,\ Entre\ Ríos";
$areanames{es}->{543458} = "San\ José\ de\ Feliciano\,\ Entre\ Ríos";
$areanames{es}->{543460} = "Santa\ Teresa\,\ Santa\ Fe";
$areanames{es}->{543462} = "Venado\ Tuerto\,\ Santa\ Fe";
$areanames{es}->{543463} = "Canals\,\ Córdoba";
$areanames{es}->{543464} = "Casilda\,\ Santa\ Fe";
$areanames{es}->{543465} = "Firmat\,\ Santa\ Fe";
$areanames{es}->{543466} = "Barrancas\,\ Santa\ Fe";
$areanames{es}->{543467} = "Cruz\ Alta\,\ Córdoba\/San\ José\ de\ la\ Esquina\,\ Santa\ Fe";
$areanames{es}->{543468} = "Corral\ de\ Bustos\,\ Córdoba";
$areanames{es}->{543469} = "Acebal\,\ Santa\ Fe";
$areanames{es}->{543471} = "Cañada\ de\ Gómez\,\ Santa\ Fe";
$areanames{es}->{543472} = "Marcos\ Juárez\,\ Córdoba";
$areanames{es}->{543476} = "San\ Lorenzo\,\ Santa\ Fe";
$areanames{es}->{543482} = "Reconquista\,\ Santa\ Fe";
$areanames{es}->{543483} = "Vera\,\ Santa\ Fe";
$areanames{es}->{543484} = "Escobar\,\ Buenos\ Aires";
$areanames{es}->{543487} = "Zárate\,\ Buenos\ Aires";
$areanames{es}->{543489} = "Campana\,\ Buenos\ Aires";
$areanames{es}->{543491} = "Ceres\,\ Santa\ Fe";
$areanames{es}->{543492} = "Rafaela\,\ Santa\ Fe";
$areanames{es}->{543493} = "Sunchales\,\ Santa\ Fe";
$areanames{es}->{543496} = "Esperanza\,\ Santa\ Fe";
$areanames{es}->{543497} = "Llambi\ Campbell\,\ Santa\ Fe";
$areanames{es}->{543498} = "San\ Justo\,\ Santa\ Fe";
$areanames{es}->{54351} = "Córdoba\,\ Córdoba";
$areanames{es}->{543521} = "Deán\ Funes\,\ Córdoba";
$areanames{es}->{543522} = "Villa\ de\ María\,\ Córdoba";
$areanames{es}->{543524} = "Villa\ del\ Totoral\,\ Córdoba";
$areanames{es}->{543525} = "Jesús\ María\,\ Córdoba";
$areanames{es}->{543532} = "Oliva\,\ Córdoba";
$areanames{es}->{543533} = "Las\ Varillas\,\ Córdoba";
$areanames{es}->{543534} = "Villa\ María\,\ Córdoba";
$areanames{es}->{543535} = "Villa\ María\,\ Córdoba";
$areanames{es}->{543536} = "Villa\ María\,\ Córdoba";
$areanames{es}->{543537} = "Bell\ Ville\,\ Córdoba";
$areanames{es}->{5435412} = "Villa\ Carlos\ Paz\,\ Córdoba";
$areanames{es}->{5435413} = "Villa\ Carlos\ Paz\,\ Córdoba";
$areanames{es}->{5435414} = "Villa\ Carlos\ Paz\,\ Córdoba";
$areanames{es}->{5435415} = "Villa\ Carlos\ Paz\,\ Córdoba";
$areanames{es}->{5435416} = "Villa\ Carlos\ Paz\,\ Córdoba";
$areanames{es}->{5435417} = "Cosquin\/Córdoba";
$areanames{es}->{543542} = "Salsacate\,\ Córdoba";
$areanames{es}->{543543} = "Córdoba\ \(Argüello\)\,\ Córdoba";
$areanames{es}->{543544} = "Villa\ Dolores\,\ Córdoba";
$areanames{es}->{543546} = "Santa\ Rosa\ de\ Calamuchita\,\ Córdoba";
$areanames{es}->{543547} = "Alta\ Gracia\,\ Córdoba";
$areanames{es}->{543548} = "La\ Falda\,\ Córdoba";
$areanames{es}->{543549} = "Cruz\ del\ Eje\,\ Córdoba";
$areanames{es}->{543562} = "Morteros\,\ Córdoba";
$areanames{es}->{543563} = "Balnearia\,\ Córdoba";
$areanames{es}->{543564} = "San\ Francisco\,\ Córdoba";
$areanames{es}->{543571} = "Río\ Tercero\,\ Córdoba";
$areanames{es}->{543572} = "Río\ Segundo\,\ Córdoba";
$areanames{es}->{543573} = "Villa\ del\ Rosario\,\ Córdoba";
$areanames{es}->{543574} = "Río\ Primero\,\ Córdoba";
$areanames{es}->{543575} = "La\ Puerta\,\ Córdoba";
$areanames{es}->{543576} = "Arroyito\,\ Córdoba";
$areanames{es}->{543582} = "Sampacho\,\ Córdoba";
$areanames{es}->{543583} = "Vicuña\ Mackenna\,\ Córdoba";
$areanames{es}->{543584} = "La\ Carlota\,\ Córdoba";
$areanames{es}->{543585} = "Adelia\ María\,\ Córdoba";
$areanames{es}->{543586} = "Río\ Cuarto\,\ Córdoba";
$areanames{es}->{54362} = "Resistencia\,\ Chaco";
$areanames{es}->{54364} = "Presidencia\ Roque\ Sáenz\ Peña\,\ Chaco";
$areanames{es}->{54370} = "Formosa\,\ Formosa";
$areanames{es}->{543711} = "Ingeniero\ Juárez\,\ Formosa";
$areanames{es}->{543715} = "Las\ Lomitas\,\ Formosa";
$areanames{es}->{543716} = "Comandante\ Fontana\,\ Formosa";
$areanames{es}->{543718} = "Clorinda\,\ Formosa";
$areanames{es}->{543721} = "Charadai\,\ Chaco";
$areanames{es}->{543725} = "General\ José\ de\ San\ Martín\,\ Chaco";
$areanames{es}->{543731} = "Charata\,\ Chaco";
$areanames{es}->{543734} = "Machagai\/Presidencia\ de\ la\ Plaza\,\ Chaco";
$areanames{es}->{543735} = "Villa\ Ángela\,\ Chaco";
$areanames{es}->{543741} = "Bernardo\ de\ Irigoyen\,\ Misiones";
$areanames{es}->{543743} = "Puerto\ Rico\,\ Misiones";
$areanames{es}->{543751} = "Eldorado\,\ Misiones";
$areanames{es}->{543754} = "Leandro\ N\.\ Alem\,\ Misiones";
$areanames{es}->{543755} = "Oberá\,\ Misiones";
$areanames{es}->{543756} = "Santo\ Tomé\,\ Corrientes";
$areanames{es}->{543757} = "Puerto\ Iguazú\,\ Misiones";
$areanames{es}->{543758} = "Apóstoles\,\ Misiones";
$areanames{es}->{54376} = "Posadas\,\ Misiones";
$areanames{es}->{543772} = "Paso\ de\ los\ Libres\,\ Corrientes";
$areanames{es}->{543773} = "Mercedes\,\ Corrientes";
$areanames{es}->{543774} = "Curuzú\ Cuatiá\,\ Corrientes";
$areanames{es}->{543775} = "Monte\ Caseros\,\ Corrientes";
$areanames{es}->{543777} = "Goya\,\ Corrientes";
$areanames{es}->{543781} = "Caá\ Catí\,\ Corrientes";
$areanames{es}->{543782} = "Saladas\,\ Corrientes";
$areanames{es}->{543786} = "Ituzaingó\,\ Corrientes";
$areanames{es}->{54379} = "Corrientes\,\ Corrientes";
$areanames{es}->{54380} = "La\ Rioja\,\ La\ Rioja";
$areanames{es}->{54381} = "San\ Miguel\ de\ Tucumán\,\ Tucumán";
$areanames{es}->{543821} = "Chepes\,\ La\ Rioja";
$areanames{es}->{543825} = "Chilecito\,\ La\ Rioja";
$areanames{es}->{543826} = "Chamical\,\ La\ Rioja";
$areanames{es}->{543827} = "Aimogasta\,\ La\ Rioja";
$areanames{es}->{543832} = "Recreo\,\ Catamarca";
$areanames{es}->{543834} = "San\ Fernando\ del\ Valle\ de\ Catamarca\,\ Catamarca";
$areanames{es}->{543835} = "Andalgalá\,\ Catamarca";
$areanames{es}->{543837} = "Tinogasta\,\ Catamarca";
$areanames{es}->{543838} = "Santa\ María\,\ Catamarca";
$areanames{es}->{543841} = "Monte\ Quemado\,\ Santiago\ del\ Estero";
$areanames{es}->{543843} = "Quimilí\,\ Santiago\ del\ Estero";
$areanames{es}->{543844} = "Añatuya\,\ Santiago\ del\ Estero";
$areanames{es}->{543845} = "Loreto\,\ Santiago\ del\ Estero";
$areanames{es}->{543846} = "Tintina\,\ Santiago\ del\ Estero";
$areanames{es}->{543853} = "Santiago\ del\ Estero\,\ Santiago\ del\ Estero";
$areanames{es}->{543854} = "Frías\,\ Santiago\ del\ Estero";
$areanames{es}->{543855} = "Suncho\ Corral\,\ Santiago\ del\ Estero";
$areanames{es}->{543856} = "Villa\ Ojo\ de\ Agua\,\ Santiago\ del\ Estero";
$areanames{es}->{543857} = "Bandera\,\ Santiago\ del\ Estero";
$areanames{es}->{543858} = "Termas\ de\ Río\ Hondo\,\ Santiago\ del\ Estero";
$areanames{es}->{543861} = "Nueva\ Esperanza\,\ Santiago\ del\ Estero";
$areanames{es}->{543862} = "Trancas\,\ Tucumán";
$areanames{es}->{543863} = "Monteros\,\ Tucumán";
$areanames{es}->{543865} = "Concepción\,\ Tucumán";
$areanames{es}->{543867} = "Tafí\ del\ Valle\,\ Tucumán";
$areanames{es}->{543868} = "Cafayate\,\ Salta";
$areanames{es}->{543869} = "Ranchillos\ y\ San\ Miguel\,\ Tucumán";
$areanames{es}->{543872} = "Salta\,\ Salta";
$areanames{es}->{5438730} = "Tartagal\,\ Salta";
$areanames{es}->{5438731} = "Tartagal\,\ Salta";
$areanames{es}->{5438732} = "Tartagal\,\ Salta";
$areanames{es}->{5438733} = "Tartagal\,\ Salta";
$areanames{es}->{5438734} = "Tartagal\,\ Salta";
$areanames{es}->{5438735} = "Tartagal\,\ Salta";
$areanames{es}->{5438736} = "Tartagal\,\ Salta";
$areanames{es}->{543874} = "Salta\,\ Salta";
$areanames{es}->{543875} = "Salta\,\ Salta";
$areanames{es}->{543876} = "San\ José\ de\ Metán\,\ Salta";
$areanames{es}->{543877} = "Joaquín\ Víctor\ González\,\ Salta";
$areanames{es}->{543878} = "Orán\,\ Salta";
$areanames{es}->{543883} = "San\ Salvador\ de\ Jujuy\,\ Jujuy";
$areanames{es}->{543884} = "San\ Salvador\ de\ Jujuy\,\ Jujuy";
$areanames{es}->{543885} = "La\ Quiaca\,\ Jujuy";
$areanames{es}->{543886} = "Libertador\ General\ San\ Martín\,\ Jujuy";
$areanames{es}->{543887} = "Humahuaca\,\ Jujuy";
$areanames{es}->{5438883} = "San\ Pedro\ de\ Jujuy\,\ Jujuy";
$areanames{es}->{5438884} = "San\ Pedro\ de\ Jujuy\,\ Jujuy";
$areanames{es}->{5438885} = "San\ Pedro\ de\ Jujuy\,\ Jujuy";
$areanames{es}->{5438886} = "San\ Pedro\ de\ Jujuy\,\ Jujuy";
$areanames{es}->{543891} = "Graneros\,\ Tucumán";
$areanames{es}->{543892} = "Amaicha\ del\ Valle\,\ Tucumán";
$areanames{es}->{543894} = "Burruyacú\,\ Tucumán";
$areanames{en}->{541} = "Buenos\ Aires";
$areanames{en}->{542202} = "González\ Catán\/Virrey\ del\ Pino\,\ Buenos\ Aires";
$areanames{en}->{542204} = "Merlo\,\ Buenos\ Aires";
$areanames{en}->{542205} = "Merlo\,\ Buenos\ Aires";
$areanames{en}->{54221} = "La\ Plata\,\ Buenos\ Aires";
$areanames{en}->{542221} = "Magdalena\/Verónica\,\ Buenos\ Aires";
$areanames{en}->{542223} = "Brandsen\,\ Buenos\ Aires";
$areanames{en}->{542224} = "Glew\/Guernica\,\ Buenos\ Aires";
$areanames{en}->{542225} = "Alejandro\ Korn\,\ Buenos\ Aires";
$areanames{en}->{542226} = "Cañuelas\,\ Buenos\ Aires";
$areanames{en}->{542227} = "Lobos\,\ Buenos\ Aires";
$areanames{en}->{542229} = "Juan\ María\ Gutiérrez\/El\ Pato\,\ Buenos\ Aires";
$areanames{en}->{54223} = "Mar\ del\ Plata\,\ Buenos\ Aires";
$areanames{en}->{542241} = "Chascomús\,\ Buenos\ Aires";
$areanames{en}->{542242} = "Lezama\,\ Buenos\ Aires";
$areanames{en}->{542243} = "General\ Belgrano\,\ Buenos\ Aires";
$areanames{en}->{542244} = "Las\ Flores\,\ Buenos\ Aires";
$areanames{en}->{542245} = "Dolores\,\ Buenos\ Aires";
$areanames{en}->{542246} = "Santa\ Teresita\,\ Buenos\ Aires";
$areanames{en}->{542252} = "San\ Clemente\ del\ Tuyú\,\ Buenos\ Aires";
$areanames{en}->{542254} = "Pinamar\,\ Buenos\ Aires";
$areanames{en}->{542255} = "Villa\ Gesell\,\ Buenos\ Aires";
$areanames{en}->{542257} = "Mar\ de\ Ajó\,\ Buenos\ Aires";
$areanames{en}->{542261} = "Lobería\,\ Buenos\ Aires";
$areanames{en}->{542262} = "Necochea\,\ Buenos\ Aires";
$areanames{en}->{542264} = "La\ Dulce\ \(Nicanor\ Olivera\)\,\ Buenos\ Aires";
$areanames{en}->{542265} = "Coronel\ Vidal\,\ Buenos\ Aires";
$areanames{en}->{542266} = "Balcarce\,\ Buenos\ Aires";
$areanames{en}->{542267} = "General\ Juan\ Madariaga\,\ Buenos\ Aires";
$areanames{en}->{542268} = "Maipú\,\ Buenos\ Aires";
$areanames{en}->{542271} = "San\ Miguel\ del\ Monte\,\ Buenos\ Aires";
$areanames{en}->{542272} = "Navarro\,\ Buenos\ Aires";
$areanames{en}->{542273} = "Carmen\ de\ Areco\,\ Buenos\ Aires";
$areanames{en}->{542274} = "Carlos\ Spegazzini\,\ Buenos\ Aires";
$areanames{en}->{542281} = "Azul\,\ Buenos\ Aires";
$areanames{en}->{542283} = "Tapalqué\,\ Buenos\ Aires";
$areanames{en}->{542284} = "Olavarría\,\ Buenos\ Aires";
$areanames{en}->{542285} = "Laprida\,\ Buenos\ Aires";
$areanames{en}->{542286} = "General\ La\ Madrid\,\ Buenos\ Aires";
$areanames{en}->{542291} = "Miramar\,\ Buenos\ Aires";
$areanames{en}->{542292} = "Benito\ Juárez\,\ Buenos\ Aires";
$areanames{en}->{542296} = "Ayacucho\,\ Buenos\ Aires";
$areanames{en}->{542297} = "Rauch\,\ Buenos\ Aires";
$areanames{en}->{542302} = "General\ Pico\,\ La\ Pampa";
$areanames{en}->{542304} = "Pilar\,\ Buenos\ Aires";
$areanames{en}->{542314} = "Bolívar\,\ Buenos\ Aires";
$areanames{en}->{542316} = "Daireaux\,\ Buenos\ Aires";
$areanames{en}->{542317} = "9\ de\ Julio\,\ Buenos\ Aires";
$areanames{en}->{542320} = "José\ C\.\ Paz\,\ Buenos\ Aires";
$areanames{en}->{542323} = "Luján\,\ Buenos\ Aires";
$areanames{en}->{542324} = "Mercedes\,\ Buenos\ Aires";
$areanames{en}->{542325} = "San\ Andrés\ de\ Giles\,\ Buenos\ Aires";
$areanames{en}->{542326} = "San\ Antonio\ de\ Areco\,\ Buenos\ Aires";
$areanames{en}->{542331} = "Realicó\,\ La\ Pampa";
$areanames{en}->{542333} = "Quemú\ Quemú\,\ La\ Pampa";
$areanames{en}->{542334} = "Eduardo\ Castex\,\ La\ Pampa";
$areanames{en}->{542335} = "Realicó\/Rancul\ Dept\.\,\ La\ Pampa";
$areanames{en}->{542336} = "Huinca\ Renancó\/Villa\ Huidobro\,\ Córdoba";
$areanames{en}->{542337} = "América\/Rivadavia\,\ Buenos\ Aires";
$areanames{en}->{542338} = "Victorica\,\ La\ Pampa";
$areanames{en}->{542342} = "Bragado\,\ Buenos\ Aires";
$areanames{en}->{542343} = "Norberto\ de\ La\ Riestra\,\ Buenos\ Aires";
$areanames{en}->{542344} = "Saladillo\,\ Buenos\ Aires";
$areanames{en}->{542345} = "25\ de\ Mayo\,\ Buenos\ Aires";
$areanames{en}->{542346} = "Chivilcoy\,\ Buenos\ Aires";
$areanames{en}->{542352} = "Chacabuco\,\ Buenos\ Aires";
$areanames{en}->{542353} = "General\ Arenales\,\ Buenos\ Aires";
$areanames{en}->{542354} = "Vedia\,\ Buenos\ Aires";
$areanames{en}->{542355} = "Lincoln\,\ Buenos\ Aires";
$areanames{en}->{542356} = "General\ Pinto\,\ Buenos\ Aires";
$areanames{en}->{542357} = "Carlos\ Tejedor\,\ Buenos\ Aires";
$areanames{en}->{542358} = "Los\ Toldos\,\ Buenos\ Aires";
$areanames{en}->{54236} = "Junín\,\ Buenos\ Aires";
$areanames{en}->{54237} = "Moreno\,\ Buenos\ Aires";
$areanames{en}->{542392} = "Trenque\ Lauquen\,\ Buenos\ Aires";
$areanames{en}->{542393} = "Salazar\,\ Buenos\ Aires";
$areanames{en}->{542394} = "Tres\ Lomas\/Salliqueló\,\ Buenos\ Aires";
$areanames{en}->{542395} = "Carlos\ Casares\,\ Buenos\ Aires";
$areanames{en}->{542396} = "Pehuajó\,\ Buenos\ Aires";
$areanames{en}->{542473} = "Colón\,\ Buenos\ Aires";
$areanames{en}->{542474} = "Salto\,\ Buenos\ Aires";
$areanames{en}->{542475} = "Rojas\,\ Buenos\ Aires";
$areanames{en}->{542477} = "Pergamino\,\ Buenos\ Aires";
$areanames{en}->{542478} = "Arrecifes\,\ Buenos\ Aires";
$areanames{en}->{54249} = "Tandil\,\ Buenos\ Aires";
$areanames{en}->{54260} = "San\ Rafael\,\ Mendoza";
$areanames{en}->{54261} = "Mendoza\,\ Mendoza";
$areanames{en}->{542622} = "Tunuyán\,\ Mendoza";
$areanames{en}->{542624} = "Uspallata\,\ Mendoza";
$areanames{en}->{542625} = "General\ Alvear\,\ Mendoza";
$areanames{en}->{542626} = "La\ Paz\,\ Mendoza";
$areanames{en}->{54263} = "San\ Martín\,\ Mendoza";
$areanames{en}->{542643} = "San\ Juan\,\ San\ Juan";
$areanames{en}->{542644} = "San\ Juan\,\ San\ Juan";
$areanames{en}->{542645} = "San\ Juan\,\ San\ Juan";
$areanames{en}->{542646} = "Villa\ San\ Agustín\,\ San\ Juan";
$areanames{en}->{542647} = "San\ José\ de\ Jáchal\,\ San\ Juan";
$areanames{en}->{542648} = "Calingasta\,\ San\ Juan";
$areanames{en}->{542651} = "San\ Francisco\ del\ Monte\ de\ Oro\,\ San\ Luis";
$areanames{en}->{542655} = "La\ Toma\,\ San\ Luis";
$areanames{en}->{542656} = "Merlo\,\ San\ Luis";
$areanames{en}->{542657} = "Villa\ Mercedes\,\ San\ Luis";
$areanames{en}->{542658} = "Buena\ Esperanza\,\ San\ Luis";
$areanames{en}->{54266} = "San\ Luis\,\ San\ Luis";
$areanames{en}->{5428} = "Trelew\/Rawson\,\ Chubut";
$areanames{en}->{542901} = "Ushuaia\,\ Tierra\ del\ Fuego";
$areanames{en}->{542902} = "Río\ Turbio\,\ Santa\ Cruz";
$areanames{en}->{542903} = "Río\ Mayo\,\ Chubut";
$areanames{en}->{54291} = "Bahía\ Blanca\,\ Buenos\ Aires";
$areanames{en}->{542920} = "Viedma\,\ Río\ Negro";
$areanames{en}->{542921} = "Coronel\ Dorrego\,\ Buenos\ Aires";
$areanames{en}->{542922} = "Coronel\ Pringles\,\ Buenos\ Aires";
$areanames{en}->{542923} = "Pigüé\,\ Buenos\ Aires";
$areanames{en}->{542924} = "Darregueira\,\ Buenos\ Aires";
$areanames{en}->{542925} = "Villa\ Iris\,\ Buenos\ Aires";
$areanames{en}->{542926} = "Coronel\ Suárez\,\ Buenos\ Aires";
$areanames{en}->{542927} = "Médanos\,\ Buenos\ Aires";
$areanames{en}->{542928} = "Pedro\ Luro\,\ Buenos\ Aires";
$areanames{en}->{542929} = "Guaminí\,\ Buenos\ Aires";
$areanames{en}->{542931} = "Río\ Colorado\,\ Río\ Negro";
$areanames{en}->{542932} = "Punta\ Alta\,\ Buenos\ Aires";
$areanames{en}->{542933} = "Huanguelén\,\ Buenos\ Aires";
$areanames{en}->{542934} = "San\ Antonio\ Oeste\,\ Río\ Negro";
$areanames{en}->{542935} = "Rivera\,\ Buenos\ Aires";
$areanames{en}->{542936} = "Carhué\,\ Buenos\ Aires";
$areanames{en}->{542940} = "Ingeniero\ Jacobacci\,\ Río\ Negro";
$areanames{en}->{542942} = "Zapala\,\ Neuquén";
$areanames{en}->{542944} = "San\ Carlos\ de\ Bariloche\,\ Río\ Negro";
$areanames{en}->{542945} = "Esquel\,\ Chubut";
$areanames{en}->{542946} = "Choele\ Choel\,\ Río\ Negro";
$areanames{en}->{542948} = "Chos\ Malal\,\ Neuquén";
$areanames{en}->{542952} = "General\ Acha\,\ La\ Pampa";
$areanames{en}->{542953} = "Macachín\,\ La\ Pampa";
$areanames{en}->{542954} = "Santa\ Rosa\,\ La\ Pampa";
$areanames{en}->{542962} = "Puerto\ San\ Julián\,\ Santa\ Cruz";
$areanames{en}->{542963} = "Perito\ Moreno\,\ Santa\ Cruz";
$areanames{en}->{542964} = "Río\ Grande\,\ Tierra\ del\ Fuego";
$areanames{en}->{542966} = "Río\ Gallegos\,\ Santa\ Cruz";
$areanames{en}->{542972} = "San\ Martín\ de\ los\ Andes\,\ Neuquén";
$areanames{en}->{542974} = "Comodoro\ Rivadavia\,\ Chubut";
$areanames{en}->{542975} = "Comodoro\ Rivadavia\,\ Chubut";
$areanames{en}->{542976} = "Comodoro\ Rivadavia\,\ Chubut";
$areanames{en}->{5429824} = "Claromecó\,\ Buenos\ Aires";
$areanames{en}->{54298240} = "Orense\,\ Buenos\ Aires";
$areanames{en}->{54298242} = "Orense\,\ Buenos\ Aires";
$areanames{en}->{542982497} = "San\ Francisco\ de\ Bellocq\,\ Buenos\ Aires";
$areanames{en}->{542983} = "Tres\ Arroyos\,\ Buenos\ Aires";
$areanames{en}->{542984} = "General\ Roca\,\ Río\ Negro";
$areanames{en}->{542985} = "General\ Roca\,\ Río\ Negro";
$areanames{en}->{54299} = "Neuquén\,\ Neuquén";
$areanames{en}->{543327} = "Benavídez\,\ Buenos\ Aires";
$areanames{en}->{543329} = "San\ Pedro\,\ Buenos\ Aires";
$areanames{en}->{54336} = "San\ Nicolás\,\ Buenos\ Aires";
$areanames{en}->{543382} = "Rufino\,\ Santa\ Fe";
$areanames{en}->{543385} = "Laboulaye\,\ Córdoba";
$areanames{en}->{543387} = "Buchardo\,\ Córdoba";
$areanames{en}->{543388} = "General\ Villegas\,\ Buenos\ Aires";
$areanames{en}->{543400} = "Villa\ Constitución\,\ Santa\ Fe";
$areanames{en}->{543401} = "El\ Trébol\,\ Santa\ Fe";
$areanames{en}->{543402} = "Arroyo\ Seco\,\ Santa\ Fe";
$areanames{en}->{543404} = "Las\ Colonias\ Dept\.\,\ Santa\ Fe";
$areanames{en}->{543405} = "San\ Javier\,\ Santa\ Fe";
$areanames{en}->{543406} = "San\ Jorge\,\ Santa\ Fe";
$areanames{en}->{543407} = "Ramallo\,\ Buenos\ Aires";
$areanames{en}->{543408} = "San\ Cristóbal\,\ Santa\ Fe";
$areanames{en}->{543409} = "Moisés\ Ville\,\ Santa\ Fe";
$areanames{en}->{54341} = "Rosario\,\ Santa\ Fe";
$areanames{en}->{54342} = "Santa\ Fe\,\ Santa\ Fe";
$areanames{en}->{543434} = "Paraná\,\ Entre\ Ríos";
$areanames{en}->{543435} = "Nogoyá\,\ Entre\ Ríos";
$areanames{en}->{543436} = "Victoria\,\ Entre\ Ríos";
$areanames{en}->{543437} = "La\ Paz\,\ Entre\ Ríos";
$areanames{en}->{543438} = "Bovril\,\ Entre\ Ríos";
$areanames{en}->{543442} = "Concepción\ del\ Uruguay\,\ Entre\ Ríos";
$areanames{en}->{543444} = "Gualeguay\,\ Entre\ Ríos";
$areanames{en}->{543445} = "Rosario\ del\ Tala\,\ Entre\ Ríos";
$areanames{en}->{543446} = "Gualeguaychú\,\ Entre\ Ríos";
$areanames{en}->{543447} = "Colón\,\ Entre\ Ríos";
$areanames{en}->{543454} = "Federal\,\ Entre\ Ríos";
$areanames{en}->{543455} = "Villaguay\,\ Entre\ Ríos";
$areanames{en}->{543456} = "Chajarí\,\ Entre\ Ríos";
$areanames{en}->{543458} = "San\ José\ de\ Feliciano\,\ Entre\ Ríos";
$areanames{en}->{543460} = "Santa\ Teresa\,\ Santa\ Fe";
$areanames{en}->{543462} = "Venado\ Tuerto\,\ Santa\ Fe";
$areanames{en}->{543463} = "Canals\,\ Córdoba";
$areanames{en}->{543464} = "Casilda\,\ Santa\ Fe";
$areanames{en}->{543465} = "Firmat\,\ Santa\ Fe";
$areanames{en}->{543466} = "Barrancas\,\ Santa\ Fe";
$areanames{en}->{543467} = "Cruz\ Alta\,\ Córdoba\/San\ José\ de\ la\ Esquina\,\ Santa\ Fe";
$areanames{en}->{543468} = "Corral\ de\ Bustos\,\ Córdoba";
$areanames{en}->{543469} = "Acebal\,\ Santa\ Fe";
$areanames{en}->{543471} = "Cañada\ de\ Gómez\,\ Santa\ Fe";
$areanames{en}->{543472} = "Marcos\ Juárez\,\ Córdoba";
$areanames{en}->{543476} = "San\ Lorenzo\,\ Santa\ Fe";
$areanames{en}->{543482} = "Reconquista\,\ Santa\ Fe";
$areanames{en}->{543483} = "Vera\,\ Santa\ Fe";
$areanames{en}->{543484} = "Escobar\,\ Buenos\ Aires";
$areanames{en}->{543487} = "Zárate\,\ Buenos\ Aires";
$areanames{en}->{543489} = "Campana\,\ Buenos\ Aires";
$areanames{en}->{543491} = "Ceres\,\ Santa\ Fe";
$areanames{en}->{543492} = "Rafaela\,\ Santa\ Fe";
$areanames{en}->{543493} = "Sunchales\,\ Santa\ Fe";
$areanames{en}->{543496} = "Esperanza\,\ Santa\ Fe";
$areanames{en}->{543497} = "Llambi\ Campbell\,\ Santa\ Fe";
$areanames{en}->{543498} = "San\ Justo\,\ Santa\ Fe";
$areanames{en}->{54351} = "Córdoba\,\ Córdoba";
$areanames{en}->{543521} = "Deán\ Funes\,\ Córdoba";
$areanames{en}->{543522} = "Villa\ de\ María\,\ Córdoba";
$areanames{en}->{543524} = "Villa\ del\ Totoral\,\ Córdoba";
$areanames{en}->{543525} = "Jesús\ María\,\ Córdoba";
$areanames{en}->{543532} = "Oliva\,\ Córdoba";
$areanames{en}->{543533} = "Las\ Varillas\,\ Córdoba";
$areanames{en}->{543534} = "Villa\ María\,\ Córdoba";
$areanames{en}->{543535} = "Villa\ María\,\ Córdoba";
$areanames{en}->{543536} = "Villa\ María\,\ Córdoba";
$areanames{en}->{543537} = "Bell\ Ville\,\ Córdoba";
$areanames{en}->{5435412} = "Villa\ Carlos\ Paz\,\ Córdoba";
$areanames{en}->{5435413} = "Villa\ Carlos\ Paz\,\ Córdoba";
$areanames{en}->{5435414} = "Villa\ Carlos\ Paz\,\ Córdoba";
$areanames{en}->{5435415} = "Villa\ Carlos\ Paz\,\ Córdoba";
$areanames{en}->{5435416} = "Villa\ Carlos\ Paz\,\ Córdoba";
$areanames{en}->{5435417} = "Cosquin\/Córdoba";
$areanames{en}->{543542} = "Salsacate\,\ Córdoba";
$areanames{en}->{543543} = "Córdoba\ \(Argüello\)\,\ Córdoba";
$areanames{en}->{543544} = "Villa\ Dolores\,\ Córdoba";
$areanames{en}->{543546} = "Santa\ Rosa\ de\ Calamuchita\,\ Córdoba";
$areanames{en}->{543547} = "Alta\ Gracia\,\ Córdoba";
$areanames{en}->{543548} = "La\ Falda\,\ Córdoba";
$areanames{en}->{543549} = "Cruz\ del\ Eje\,\ Córdoba";
$areanames{en}->{543562} = "Morteros\,\ Córdoba";
$areanames{en}->{543563} = "Balnearia\,\ Córdoba";
$areanames{en}->{543564} = "San\ Francisco\,\ Córdoba";
$areanames{en}->{543571} = "Río\ Tercero\,\ Córdoba";
$areanames{en}->{543572} = "Río\ Segundo\,\ Córdoba";
$areanames{en}->{543573} = "Villa\ del\ Rosario\,\ Córdoba";
$areanames{en}->{543574} = "Río\ Primero\,\ Córdoba";
$areanames{en}->{543575} = "La\ Puerta\,\ Córdoba";
$areanames{en}->{543576} = "Arroyito\,\ Córdoba";
$areanames{en}->{543582} = "Sampacho\,\ Córdoba";
$areanames{en}->{543583} = "Vicuña\ Mackenna\,\ Córdoba";
$areanames{en}->{543584} = "La\ Carlota\,\ Córdoba";
$areanames{en}->{543585} = "Adelia\ María\,\ Córdoba";
$areanames{en}->{543586} = "Río\ Cuarto\,\ Córdoba";
$areanames{en}->{54362} = "Resistencia\,\ Chaco";
$areanames{en}->{54364} = "Presidencia\ Roque\ Sáenz\ Peña\,\ Chaco";
$areanames{en}->{54370} = "Formosa\,\ Formosa";
$areanames{en}->{543711} = "Ingeniero\ Juárez\,\ Formosa";
$areanames{en}->{543715} = "Las\ Lomitas\,\ Formosa";
$areanames{en}->{543716} = "Comandante\ Fontana\,\ Formosa";
$areanames{en}->{543718} = "Clorinda\,\ Formosa";
$areanames{en}->{543721} = "Charadai\,\ Chaco";
$areanames{en}->{543725} = "General\ José\ de\ San\ Martín\,\ Chaco";
$areanames{en}->{543731} = "Charata\,\ Chaco";
$areanames{en}->{543734} = "Machagai\/Presidencia\ de\ la\ Plaza\,\ Chaco";
$areanames{en}->{543735} = "Villa\ Ángela\,\ Chaco";
$areanames{en}->{543741} = "Bernardo\ de\ Irigoyen\,\ Misiones";
$areanames{en}->{543743} = "Puerto\ Rico\,\ Misiones";
$areanames{en}->{543751} = "Eldorado\,\ Misiones";
$areanames{en}->{543754} = "Leandro\ N\.\ Alem\,\ Misiones";
$areanames{en}->{543755} = "Oberá\,\ Misiones";
$areanames{en}->{543756} = "Santo\ Tomé\,\ Corrientes";
$areanames{en}->{543757} = "Puerto\ Iguazú\,\ Misiones";
$areanames{en}->{543758} = "Apóstoles\,\ Misiones";
$areanames{en}->{54376} = "Posadas\,\ Misiones";
$areanames{en}->{543772} = "Paso\ de\ los\ Libres\,\ Corrientes";
$areanames{en}->{543773} = "Mercedes\,\ Corrientes";
$areanames{en}->{543774} = "Curuzú\ Cuatiá\,\ Corrientes";
$areanames{en}->{543775} = "Monte\ Caseros\,\ Corrientes";
$areanames{en}->{543777} = "Goya\,\ Corrientes";
$areanames{en}->{543781} = "Caá\ Catí\,\ Corrientes";
$areanames{en}->{543782} = "Saladas\,\ Corrientes";
$areanames{en}->{543786} = "Ituzaingó\,\ Corrientes";
$areanames{en}->{54379} = "Corrientes\,\ Corrientes";
$areanames{en}->{54380} = "La\ Rioja\,\ La\ Rioja";
$areanames{en}->{54381} = "San\ Miguel\ de\ Tucumán\,\ Tucumán";
$areanames{en}->{543821} = "Chepes\,\ La\ Rioja";
$areanames{en}->{543825} = "Chilecito\,\ La\ Rioja";
$areanames{en}->{543826} = "Chamical\,\ La\ Rioja";
$areanames{en}->{543827} = "Aimogasta\,\ La\ Rioja";
$areanames{en}->{543832} = "Recreo\,\ Catamarca";
$areanames{en}->{543834} = "San\ Fernando\ del\ Valle\ de\ Catamarca\,\ Catamarca";
$areanames{en}->{543835} = "Andalgalá\,\ Catamarca";
$areanames{en}->{543837} = "Tinogasta\,\ Catamarca";
$areanames{en}->{543838} = "Santa\ María\,\ Catamarca";
$areanames{en}->{543841} = "Monte\ Quemado\,\ Santiago\ del\ Estero";
$areanames{en}->{543843} = "Quimilí\,\ Santiago\ del\ Estero";
$areanames{en}->{543844} = "Añatuya\,\ Santiago\ del\ Estero";
$areanames{en}->{543845} = "Loreto\,\ Santiago\ del\ Estero";
$areanames{en}->{543846} = "Tintina\,\ Santiago\ del\ Estero";
$areanames{en}->{543853} = "Santiago\ del\ Estero\,\ Santiago\ del\ Estero";
$areanames{en}->{543854} = "Frías\,\ Santiago\ del\ Estero";
$areanames{en}->{543855} = "Suncho\ Corral\,\ Santiago\ del\ Estero";
$areanames{en}->{543856} = "Villa\ Ojo\ de\ Agua\,\ Santiago\ del\ Estero";
$areanames{en}->{543857} = "Bandera\,\ Santiago\ del\ Estero";
$areanames{en}->{543858} = "Termas\ de\ Río\ Hondo\,\ Santiago\ del\ Estero";
$areanames{en}->{543861} = "Nueva\ Esperanza\,\ Santiago\ del\ Estero";
$areanames{en}->{543862} = "Trancas\,\ Tucumán";
$areanames{en}->{543863} = "Monteros\,\ Tucumán";
$areanames{en}->{543865} = "Concepción\,\ Tucumán";
$areanames{en}->{543867} = "Tafí\ del\ Valle\,\ Tucumán";
$areanames{en}->{543868} = "Cafayate\,\ Salta";
$areanames{en}->{543869} = "Ranchillos\ y\ San\ Miguel\,\ Tucumán";
$areanames{en}->{543872} = "Salta\,\ Salta";
$areanames{en}->{5438730} = "Tartagal\,\ Salta";
$areanames{en}->{5438731} = "Tartagal\,\ Salta";
$areanames{en}->{5438732} = "Tartagal\,\ Salta";
$areanames{en}->{5438733} = "Tartagal\,\ Salta";
$areanames{en}->{5438734} = "Tartagal\,\ Salta";
$areanames{en}->{5438735} = "Tartagal\,\ Salta";
$areanames{en}->{5438736} = "Tartagal\,\ Salta";
$areanames{en}->{543874} = "Salta\,\ Salta";
$areanames{en}->{543875} = "Salta\,\ Salta";
$areanames{en}->{543876} = "San\ José\ de\ Metán\,\ Salta";
$areanames{en}->{543877} = "Joaquín\ Víctor\ González\,\ Salta";
$areanames{en}->{543878} = "Orán\,\ Salta";
$areanames{en}->{543883} = "San\ Salvador\ de\ Jujuy\,\ Jujuy";
$areanames{en}->{543884} = "San\ Salvador\ de\ Jujuy\,\ Jujuy";
$areanames{en}->{543885} = "La\ Quiaca\,\ Jujuy";
$areanames{en}->{543886} = "Libertador\ General\ San\ Martín\,\ Jujuy";
$areanames{en}->{543887} = "Humahuaca\,\ Jujuy";
$areanames{en}->{5438883} = "San\ Pedro\ de\ Jujuy\,\ Jujuy";
$areanames{en}->{5438884} = "San\ Pedro\ de\ Jujuy\,\ Jujuy";
$areanames{en}->{5438885} = "San\ Pedro\ de\ Jujuy\,\ Jujuy";
$areanames{en}->{5438886} = "San\ Pedro\ de\ Jujuy\,\ Jujuy";
$areanames{en}->{543891} = "Graneros\,\ Tucumán";
$areanames{en}->{543892} = "Amaicha\ del\ Valle\,\ Tucumán";
$areanames{en}->{543894} = "Burruyacú\,\ Tucumán";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+54|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      my $prefix = qr/^(?:0?(?:(11|2(?:2(?:02?|[13]|2[13-79]|4[1-6]|5[2457]|6[124-8]|7[1-4]|8[13-6]|9[1267])|3(?:02?|1[467]|2[03-6]|3[13-8]|[49][2-6]|5[2-8]|[67])|4(?:7[3-578]|9)|6(?:[0136]|2[24-6]|4[6-8]?|5[15-8])|80|9(?:0[1-3]|[19]|2\d|3[1-6]|4[02568]?|5[2-4]|6[2-46]|72?|8[23]?))|3(?:3(?:2[79]|6|8[2578])|4(?:0[0-24-9]|[12]|3[5-8]?|4[24-7]|5[4-68]?|6[02-9]|7[126]|8[2379]?|9[1-36-8])|5(?:1|2[1245]|3[237]?|4[1-46-9]|6[2-4]|7[1-6]|8[2-5]?)|6[24]|7(?:[069]|1[1568]|2[15]|3[145]|4[13]|5[14-8]|7[2-57]|8[126])|8(?:[01]|2[15-7]|3[2578]?|4[13-6]|5[4-8]?|6[1-357-9]|7[36-8]?|8[5-8]?|9[124])))15)?)/;
      my @matches = $number =~ /$prefix/;
      if (defined $matches[-1]) {
        no warnings 'uninitialized';
        $number =~ s/$prefix/9$1/;
      }
      else {
        $number =~ s/$prefix//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;