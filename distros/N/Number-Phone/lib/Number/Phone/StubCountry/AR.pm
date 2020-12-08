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
our $VERSION = 1.20201204215954;

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
              4[478]
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
$areanames{es} = {"543404", "Dpto\.\ Las\ Colonias\,\ Santa\ Fe",
"542335", "Dpto\.\ Realicó\/Rancul\,\ La\ Pampa",};
$areanames{en} = {"542474", "Salto\,\ Buenos\ Aires",
"542475", "Rojas\,\ Buenos\ Aires",
"543863", "Monteros\,\ Tucumán",
"5428", "Trelew\/Rawson\,\ Chubut",
"542268", "Maipú\,\ Buenos\ Aires",
"543892", "Amaicha\ del\ Valle\,\ Tucumán",
"543472", "Marcos\ Juárez\,\ Córdoba",
"543741", "Bernardo\ de\ Irigoyen\,\ Misiones",
"542304", "Pilar\,\ Buenos\ Aires",
"542644", "San\ Juan\,\ San\ Juan",
"542645", "San\ Juan\,\ San\ Juan",
"543532", "Oliva\,\ Córdoba",
"543841", "Monte\ Quemado\,\ Santiago\ del\ Estero",
"542335", "Realicó\/Rancul\ Dept\.\,\ La\ Pampa",
"54223", "Mar\ del\ Plata\,\ Buenos\ Aires",
"542657", "Villa\ Mercedes\,\ San\ Luis",
"542334", "Eduardo\ Castex\,\ La\ Pampa",
"5438733", "Tartagal\,\ Salta",
"543544", "Villa\ Dolores\,\ Córdoba",
"5435414", "Villa\ Carlos\ Paz\,\ Córdoba",
"542342", "Bragado\,\ Buenos\ Aires",
"542246", "Santa\ Teresita\,\ Buenos\ Aires",
"542975", "Comodoro\ Rivadavia\,\ Chubut",
"542974", "Comodoro\ Rivadavia\,\ Chubut",
"542320", "José\ C\.\ Paz\,\ Buenos\ Aires",
"543401", "El\ Trébol\,\ Santa\ Fe",
"543460", "Santa\ Teresa\,\ Santa\ Fe",
"542963", "Perito\ Moreno\,\ Santa\ Cruz",
"542227", "Lobos\,\ Buenos\ Aires",
"543446", "Gualeguaychú\,\ Entre\ Ríos",
"543758", "Apóstoles\,\ Misiones",
"542286", "General\ La\ Madrid\,\ Buenos\ Aires",
"543858", "Termas\ de\ Río\ Hondo\,\ Santiago\ del\ Estero",
"543874", "Salta\,\ Salta",
"543875", "Salta\,\ Salta",
"5438735", "Tartagal\,\ Salta",
"543585", "Adelia\ María\,\ Córdoba",
"543775", "Monte\ Caseros\,\ Corrientes",
"543584", "La\ Carlota\,\ Córdoba",
"543774", "Curuzú\ Cuatiá\,\ Corrientes",
"542936", "Carhué\,\ Buenos\ Aires",
"543468", "Corral\ de\ Bustos\,\ Córdoba",
"543781", "Caá\ Catí\,\ Corrientes",
"543571", "Río\ Tercero\,\ Córdoba",
"542272", "Navarro\,\ Buenos\ Aires",
"543385", "Laboulaye\,\ Córdoba",
"543409", "Moisés\ Ville\,\ Santa\ Fe",
"543498", "San\ Justo\,\ Santa\ Fe",
"543855", "Suncho\ Corral\,\ Santiago\ del\ Estero",
"543854", "Frías\,\ Santiago\ del\ Estero",
"542651", "San\ Francisco\ del\ Monte\ de\ Oro\,\ San\ Luis",
"543754", "Leandro\ N\.\ Alem\,\ Misiones",
"543755", "Oberá\,\ Misiones",
"543878", "Orán\,\ Salta",
"543465", "Firmat\,\ Santa\ Fe",
"542252", "San\ Clemente\ del\ Tuyú\,\ Buenos\ Aires",
"542356", "General\ Pinto\,\ Buenos\ Aires",
"543464", "Casilda\,\ Santa\ Fe",
"542273", "Carmen\ de\ Areco\,\ Buenos\ Aires",
"5438884", "San\ Pedro\ de\ Jujuy\,\ Jujuy",
"54342", "Santa\ Fe\,\ Santa\ Fe",
"543388", "General\ Villegas\,\ Buenos\ Aires",
"542962", "Puerto\ San\ Julián\,\ Santa\ Cruz",
"54381", "San\ Miguel\ de\ Tucumán\,\ Tucumán",
"542926", "Coronel\ Suárez\,\ Buenos\ Aires",
"543711", "Ingeniero\ Juárez\,\ Formosa",
"5435417", "Cosquin\/Córdoba",
"542648", "Calingasta\,\ San\ Juan",
"542229", "Juan\ María\ Gutiérrez\/El\ Pato\,\ Buenos\ Aires",
"543533", "Las\ Varillas\,\ Córdoba",
"542338", "Victorica\,\ La\ Pampa",
"543887", "Humahuaca\,\ Jujuy",
"543548", "La\ Falda\,\ Córdoba",
"542343", "Norberto\ de\ La\ Riestra\,\ Buenos\ Aires",
"542954", "Santa\ Rosa\,\ La\ Pampa",
"542478", "Arrecifes\,\ Buenos\ Aires",
"54291", "Bahía\ Blanca\,\ Buenos\ Aires",
"543862", "Trancas\,\ Tucumán",
"542622", "Tunuyán\,\ Mendoza",
"543407", "Ramallo\,\ Buenos\ Aires",
"542982497", "San\ Francisco\ de\ Bellocq\,\ Buenos\ Aires",
"543826", "Chamical\,\ La\ Rioja",
"543437", "La\ Paz\,\ Entre\ Ríos",
"5438736", "Tartagal\,\ Salta",
"542221", "Magdalena\/Verónica\,\ Buenos\ Aires",
"543522", "Villa\ de\ María\,\ Córdoba",
"542264", "La\ Dulce\ \(Nicanor\ Olivera\)\,\ Buenos\ Aires",
"54236", "Junín\,\ Buenos\ Aires",
"542265", "Coronel\ Vidal\,\ Buenos\ Aires",
"542325", "San\ Andrés\ de\ Giles\,\ Buenos\ Aires",
"542324", "Mercedes\,\ Buenos\ Aires",
"542202", "González\ Catán\/Virrey\ del\ Pino\,\ Buenos\ Aires",
"542646", "Villa\ San\ Agustín\,\ San\ Juan",
"5438883", "San\ Pedro\ de\ Jujuy\,\ Jujuy",
"542336", "Huinca\ Renancó\/Villa\ Huidobro\,\ Córdoba",
"543546", "Santa\ Rosa\ de\ Calamuchita\,\ Córdoba",
"542257", "Mar\ de\ Ajó\,\ Buenos\ Aires",
"54263", "San\ Martín\,\ Mendoza",
"543735", "Villa\ Ángela\,\ Chaco",
"543734", "Machagai\/Presidencia\ de\ la\ Plaza\,\ Chaco",
"54364", "Presidencia\ Roque\ Sáenz\ Peña\,\ Chaco",
"542976", "Comodoro\ Rivadavia\,\ Chubut",
"542244", "Las\ Flores\,\ Buenos\ Aires",
"543834", "San\ Fernando\ del\ Valle\ de\ Catamarca\,\ Catamarca",
"542245", "Dolores\,\ Buenos\ Aires",
"543835", "Andalgalá\,\ Catamarca",
"54260", "San\ Rafael\,\ Mendoza",
"543484", "Escobar\,\ Buenos\ Aires",
"54298240", "Orense\,\ Buenos\ Aires",
"542296", "Ayacucho\,\ Buenos\ Aires",
"542317", "9\ de\ Julio\,\ Buenos\ Aires",
"542392", "Trenque\ Lauquen\,\ Buenos\ Aires",
"54379", "Corrientes\,\ Corrientes",
"543471", "Cañada\ de\ Gómez\,\ Santa\ Fe",
"542223", "Brandsen\,\ Buenos\ Aires",
"543891", "Graneros\,\ Tucumán",
"543496", "Esperanza\,\ Santa\ Fe",
"542285", "Laprida\,\ Buenos\ Aires",
"542284", "Olavarría\,\ Buenos\ Aires",
"542935", "Rivera\,\ Buenos\ Aires",
"543586", "Río\ Cuarto\,\ Córdoba",
"542934", "San\ Antonio\ Oeste\,\ Río\ Negro",
"543876", "San\ José\ de\ Metán\,\ Salta",
"542358", "Los\ Toldos\,\ Buenos\ Aires",
"542271", "San\ Miguel\ del\ Monte\,\ Buenos\ Aires",
"543782", "Saladas\,\ Corrientes",
"543572", "Río\ Segundo\,\ Córdoba",
"542942", "Zapala\,\ Neuquén",
"5438885", "San\ Pedro\ de\ Jujuy\,\ Jujuy",
"54249", "Tandil\,\ Buenos\ Aires",
"542920", "Viedma\,\ Río\ Negro",
"54299", "Neuquén\,\ Neuquén",
"543402", "Arroyo\ Seco\,\ Santa\ Fe",
"543867", "Tafí\ del\ Valle\,\ Tucumán",
"543327", "Benavídez\,\ Buenos\ Aires",
"5435416", "Villa\ Carlos\ Paz\,\ Córdoba",
"543445", "Rosario\ del\ Tala\,\ Entre\ Ríos",
"542928", "Pedro\ Luro\,\ Buenos\ Aires",
"543444", "Gualeguay\,\ Entre\ Ríos",
"5438730", "Tartagal\,\ Salta",
"542925", "Villa\ Iris\,\ Buenos\ Aires",
"542924", "Darregueira\,\ Buenos\ Aires",
"543756", "Santo\ Tomé\,\ Corrientes",
"543537", "Bell\ Ville\,\ Córdoba",
"5438731", "Tartagal\,\ Salta",
"543856", "Villa\ Ojo\ de\ Agua\,\ Santiago\ del\ Estero",
"5435413", "Villa\ Carlos\ Paz\,\ Córdoba",
"5438734", "Tartagal\,\ Salta",
"542354", "Vedia\,\ Buenos\ Aires",
"542355", "Lincoln\,\ Buenos\ Aires",
"543466", "Barrancas\,\ Santa\ Fe",
"543883", "San\ Salvador\ de\ Jujuy\,\ Jujuy",
"543573", "Villa\ del\ Rosario\,\ Córdoba",
"54376", "Posadas\,\ Misiones",
"5438886", "San\ Pedro\ de\ Jujuy\,\ Jujuy",
"542393", "Salazar\,\ Buenos\ Aires",
"543825", "Chilecito\,\ La\ Rioja",
"543725", "General\ José\ de\ San\ Martín\,\ Chaco",
"543861", "Nueva\ Esperanza\,\ Santiago\ del\ Estero",
"542266", "Balcarce\,\ Buenos\ Aires",
"542326", "San\ Antonio\ de\ Areco\,\ Buenos\ Aires",
"543521", "Deán\ Funes\,\ Córdoba",
"543564", "San\ Francisco\,\ Córdoba",
"543843", "Quimilí\,\ Santiago\ del\ Estero",
"543743", "Puerto\ Rico\,\ Misiones",
"542983", "Tres\ Arroyos\,\ Buenos\ Aires",
"5435415", "Villa\ Carlos\ Paz\,\ Córdoba",
"543869", "Ranchillos\ y\ San\ Miguel\,\ Tucumán",
"543838", "Santa\ María\,\ Catamarca",
"543329", "San\ Pedro\,\ Buenos\ Aires",
"542964", "Río\ Grande\,\ Tierra\ del\ Fuego",
"543716", "Comandante\ Fontana\,\ Formosa",
"542921", "Coronel\ Dorrego\,\ Buenos\ Aires",
"542314", "Bolívar\,\ Buenos\ Aires",
"54221", "La\ Plata\,\ Buenos\ Aires",
"543487", "Zárate\,\ Buenos\ Aires",
"543837", "Tinogasta\,\ Catamarca",
"543462", "Venado\ Tuerto\,\ Santa\ Fe",
"542255", "Villa\ Gesell\,\ Buenos\ Aires",
"542254", "Pinamar\,\ Buenos\ Aires",
"543493", "Sunchales\,\ Santa\ Fe",
"542656", "Merlo\,\ San\ Luis",
"543773", "Mercedes\,\ Corrientes",
"543583", "Vicuña\ Mackenna\,\ Córdoba",
"542929", "Guaminí\,\ Buenos\ Aires",
"543447", "Colón\,\ Entre\ Ríos",
"542226", "Cañuelas\,\ Buenos\ Aires",
"543524", "Villa\ del\ Totoral\,\ Córdoba",
"543525", "Jesús\ María\,\ Córdoba",
"543454", "Federal\,\ Entre\ Ríos",
"542262", "Necochea\,\ Buenos\ Aires",
"543455", "Villaguay\,\ Entre\ Ríos",
"54336", "San\ Nicolás\,\ Buenos\ Aires",
"54266", "San\ Luis\,\ San\ Luis",
"542473", "Colón\,\ Buenos\ Aires",
"543821", "Chepes\,\ La\ Rioja",
"542624", "Uspallata\,\ Mendoza",
"543721", "Charadai\,\ Chaco",
"543865", "Concepción\,\ Tucumán",
"541", "Buenos\ Aires",
"542625", "General\ Alvear\,\ Mendoza",
"543543", "Córdoba\ \(Argüello\)\,\ Córdoba",
"542952", "General\ Acha\,\ La\ Pampa",
"542643", "San\ Juan\,\ San\ Juan",
"54341", "Rosario\,\ Santa\ Fe",
"542333", "Quemú\ Quemú\,\ La\ Pampa",
"54298242", "Orense\,\ Buenos\ Aires",
"542345", "25\ de\ Mayo\,\ Buenos\ Aires",
"542953", "Macachín\,\ La\ Pampa",
"542344", "Saladillo\,\ Buenos\ Aires",
"543489", "Campana\,\ Buenos\ Aires",
"542972", "San\ Martín\ de\ los\ Andes\,\ Neuquén",
"543731", "Charata\,\ Chaco",
"542357", "Carlos\ Tejedor\,\ Buenos\ Aires",
"54380", "La\ Rioja\,\ La\ Rioja",
"54370", "Formosa\,\ Formosa",
"543542", "Salsacate\,\ Córdoba",
"542241", "Chascomús\,\ Buenos\ Aires",
"543846", "Tintina\,\ Santiago\ del\ Estero",
"5429824", "Claromecó\,\ Buenos\ Aires",
"542302", "General\ Pico\,\ La\ Pampa",
"543534", "Villa\ María\,\ Córdoba",
"543535", "Villa\ María\,\ Córdoba",
"542927", "Médanos\,\ Buenos\ Aires",
"543458", "San\ José\ de\ Feliciano\,\ Entre\ Ríos",
"5438732", "Tartagal\,\ Salta",
"542323", "Luján\,\ Buenos\ Aires",
"543894", "Burruyacú\,\ Tucumán",
"542396", "Pehuajó\,\ Buenos\ Aires",
"543868", "Cafayate\,\ Salta",
"542292", "Benito\ Juárez\,\ Buenos\ Aires",
"542274", "Carlos\ Spegazzini\,\ Buenos\ Aires",
"54237", "Moreno\,\ Buenos\ Aires",
"543463", "Canals\,\ Córdoba",
"543382", "Rufino\,\ Santa\ Fe",
"542946", "Choele\ Choel\,\ Río\ Negro",
"543886", "Libertador\ General\ San\ Martín\,\ Jujuy",
"543786", "Ituzaingó\,\ Corrientes",
"543576", "Arroyito\,\ Córdoba",
"542901", "Ushuaia\,\ Tierra\ del\ Fuego",
"543872", "Salta\,\ Salta",
"543853", "Santiago\ del\ Estero\,\ Santiago\ del\ Estero",
"543772", "Paso\ de\ los\ Libres\,\ Corrientes",
"542281", "Azul\,\ Buenos\ Aires",
"543582", "Sampacho\,\ Córdoba",
"542931", "Río\ Colorado\,\ Río\ Negro",
"543492", "Rafaela\,\ Santa\ Fe",
"543436", "Victoria\,\ Entre\ Ríos",
"543827", "Aimogasta\,\ La\ Rioja",
"543406", "San\ Jorge\,\ Santa\ Fe",
"542948", "Chos\ Malal\,\ Neuquén",
"543547", "Alta\ Gracia\,\ Córdoba",
"542352", "Chacabuco\,\ Buenos\ Aires",
"542283", "Tapalqué\,\ Buenos\ Aires",
"542337", "América\/Rivadavia\,\ Buenos\ Aires",
"542655", "La\ Toma\,\ San\ Luis",
"542903", "Río\ Mayo\,\ Chubut",
"543751", "Eldorado\,\ Misiones",
"543400", "Villa\ Constitución\,\ Santa\ Fe",
"542933", "Huanguelén\,\ Buenos\ Aires",
"542647", "San\ José\ de\ Jáchal\,\ San\ Juan",
"542940", "Ingeniero\ Jacobacci\,\ Río\ Negro",
"542922", "Coronel\ Pringles\,\ Buenos\ Aires",
"54261", "Mendoza\,\ Mendoza",
"543715", "Las\ Lomitas\,\ Formosa",
"542966", "Río\ Gallegos\,\ Santa\ Cruz",
"5435412", "Villa\ Carlos\ Paz\,\ Córdoba",
"54351", "Córdoba\,\ Córdoba",
"543438", "Bovril\,\ Entre\ Ríos",
"543469", "Acebal\,\ Santa\ Fe",
"542297", "Rauch\,\ Buenos\ Aires",
"543408", "San\ Cristóbal\,\ Santa\ Fe",
"542316", "Daireaux\,\ Buenos\ Aires",
"542477", "Pergamino\,\ Buenos\ Aires",
"543387", "Buchardo\,\ Córdoba",
"542243", "General\ Belgrano\,\ Buenos\ Aires",
"543777", "Goya\,\ Corrientes",
"543877", "Joaquín\ Víctor\ González\,\ Salta",
"543497", "Llambi\ Campbell\,\ Santa\ Fe",
"542224", "Glew\/Guernica\,\ Buenos\ Aires",
"542225", "Alejandro\ Korn\,\ Buenos\ Aires",
"54362", "Resistencia\,\ Chaco",
"543562", "Morteros\,\ Córdoba",
"542261", "Lobería\,\ Buenos\ Aires",
"543456", "Chajarí\,\ Entre\ Ríos",
"543483", "Vera\,\ Santa\ Fe",
"542626", "La\ Paz\,\ Mendoza",
"543476", "San\ Lorenzo\,\ Santa\ Fe",
"543563", "Balnearia\,\ Córdoba",
"542291", "Miramar\,\ Buenos\ Aires",
"543549", "Cruz\ del\ Eje\,\ Córdoba",
"543482", "Reconquista\,\ Santa\ Fe",
"542394", "Tres\ Lomas\/Salliqueló\,\ Buenos\ Aires",
"542395", "Carlos\ Casares\,\ Buenos\ Aires",
"542242", "Lezama\,\ Buenos\ Aires",
"543832", "Recreo\,\ Catamarca",
"542346", "Chivilcoy\,\ Buenos\ Aires",
"543467", "Cruz\ Alta\,\ Córdoba\/San\ José\ de\ la\ Esquina\,\ Santa\ Fe",
"543844", "Añatuya\,\ Santiago\ del\ Estero",
"543845", "Loreto\,\ Santiago\ del\ Estero",
"542984", "General\ Roca\,\ Río\ Negro",
"543536", "Villa\ María\,\ Córdoba",
"542331", "Realicó\,\ La\ Pampa",
"542985", "General\ Roca\,\ Río\ Negro",
"543757", "Puerto\ Iguazú\,\ Misiones",
"542205", "Merlo\,\ Buenos\ Aires",
"543857", "Bandera\,\ Santiago\ del\ Estero",
"542204", "Merlo\,\ Buenos\ Aires",
"543442", "Concepción\ del\ Uruguay\,\ Entre\ Ríos",
"542923", "Pigüé\,\ Buenos\ Aires",
"542267", "General\ Juan\ Madariaga\,\ Buenos\ Aires",
"543718", "Clorinda\,\ Formosa",
"543435", "Nogoyá\,\ Entre\ Ríos",
"543434", "Paraná\,\ Entre\ Ríos",
"543404", "Las\ Colonias\ Dept\.\,\ Santa\ Fe",
"543405", "San\ Javier\,\ Santa\ Fe",
"542945", "Esquel\,\ Chubut",
"542353", "General\ Arenales\,\ Buenos\ Aires",
"542944", "San\ Carlos\ de\ Bariloche\,\ Río\ Negro",
"543574", "Río\ Primero\,\ Córdoba",
"543575", "La\ Puerta\,\ Córdoba",
"543885", "La\ Quiaca\,\ Jujuy",
"543884", "San\ Salvador\ de\ Jujuy\,\ Jujuy",
"542932", "Punta\ Alta\,\ Buenos\ Aires",
"542658", "Buena\ Esperanza\,\ San\ Luis",
"543491", "Ceres\,\ Santa\ Fe",
"542902", "Río\ Turbio\,\ Santa\ Cruz",};

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