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
package Number::Phone::StubCountry::IN;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200606132000;

my $formatters = [
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '575',
                  'pattern' => '(\\d{7})'
                },
                {
                  'format' => '$1',
                  'leading_digits' => '
            5(?:
              0|
              2(?:
                21|
                3
              )|
              3(?:
                0|
                3[23]
              )|
              616|
              717|
              8888
            )
          ',
                  'pattern' => '(\\d{8})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '1800',
                  'pattern' => '(\\d{4})(\\d{4,5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '140',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            11|
            2[02]|
            33|
            4[04]|
            79(?:
              [124-6]|
              3(?:
                [02-9]|
                1[0-24-9]
              )|
              7(?:
                1|
                9[1-6]
              )
            )|
            80(?:
              [2-4]|
              6[0-589]
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            1(?:
              2[0-24]|
              3[0-25]|
              4[145]|
              [59][14]|
              6[1-9]|
              7[1257]|
              8[1-57-9]
            )|
            2(?:
              1[257]|
              3[013]|
              4[01]|
              5[0137]|
              6[058]|
              78|
              8[1568]|
              9[14]
            )|
            3(?:
              26|
              4[1-3]|
              5[34]|
              6[01489]|
              7[02-46]|
              8[159]
            )|
            4(?:
              1[36]|
              2[1-47]|
              3[15]|
              5[12]|
              6[0-26-9]|
              7[0-24-9]|
              8[013-57]|
              9[014-7]
            )|
            5(?:
              1[025]|
              22|
              [36][25]|
              4[28]|
              [578]1|
              9[15]
            )|
            6(?:
              12(?:
                [2-6]|
                7[0-8]
              )|
              74[2-7]
            )|
            7(?:
              (?:
                2[14]|
                5[15]
              )[2-6]|
              3171|
              61[346]|
              88(?:
                [2-7]|
                82
              )
            )|
            8(?:
              70[2-6]|
              84(?:
                [2356]|
                7[19]
              )|
              91(?:
                [3-6]|
                7[19]
              )
            )|
            73[134][2-6]|
            (?:
              74[47]|
              8(?:
                16|
                2[014]|
                3[126]|
                6[136]|
                7[78]|
                83
              )
            )(?:
              [2-6]|
              7[19]
            )|
            (?:
              1(?:
                29|
                60|
                8[06]
              )|
              261|
              552|
              6(?:
                [2-4]1|
                5[17]|
                6[13]|
                7(?:
                  1|
                  4[0189]
                )|
                80
              )|
              7(?:
                12|
                88[01]
              )
            )[2-7]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            1(?:
              [2-479]|
              5(?:
                [0236-9]|
                5[013-9]
              )
            )|
            [2-5]|
            6(?:
              2(?:
                84|
                95
              )|
              355|
              83
            )|
            73179|
            807(?:
              1|
              9[1-3]
            )|
            (?:
              1552|
              6(?:
                1[1358]|
                2[2457]|
                3[2-4]|
                4[235-7]|
                5[2-689]|
                6[24578]|
                7[235689]|
                8[124-6]
              )\\d|
              7(?:
                1(?:
                  [013-8]\\d|
                  9[6-9]
                )|
                28[6-8]|
                3(?:
                  2[0-49]|
                  9[2-57]
                )|
                4(?:
                  1[2-4]|
                  [29][0-7]|
                  3[0-8]|
                  [56]\\d|
                  8[0-24-7]
                )|
                5(?:
                  2[1-3]|
                  9[0-6]
                )|
                6(?:
                  0[5689]|
                  2[5-9]|
                  3[02-8]|
                  4\\d|
                  5[0-367]
                )|
                70[13-7]
              )
            )[2-7]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[6-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{5})(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            1(?:
              6|
              8[06]0
            )
          ',
                  'pattern' => '(\\d{4})(\\d{2,4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'intl_format' => 'NA',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '18',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2717(?:
            [2-7]\\d|
            95
          )\\d{4}|
          (?:
            271[0-689]|
            782[0-6]
          )[2-7]\\d{5}|
          (?:
            170[24]|
            2(?:
              (?:
                [02][2-79]|
                90
              )\\d|
              80[13468]
            )|
            (?:
              3(?:
                23|
                80
              )|
              683|
              79[1-7]
            )\\d|
            4(?:
              20[24]|
              72[2-8]
            )|
            552[1-7]
          )\\d{6}|
          (?:
            11|
            33|
            4[04]|
            80
          )[2-7]\\d{7}|
          (?:
            342|
            674|
            788
          )(?:
            [0189][2-7]|
            [2-7]\\d
          )\\d{5}|
          (?:
            1(?:
              2[0-249]|
              3[0-25]|
              4[145]|
              [59][14]|
              6[014]|
              7[1257]|
              8[01346]
            )|
            2(?:
              1[257]|
              3[013]|
              4[01]|
              5[0137]|
              6[0158]|
              78|
              8[1568]|
              9[14]
            )|
            3(?:
              26|
              4[13]|
              5[34]|
              6[01489]|
              7[02-46]|
              8[159]
            )|
            4(?:
              1[36]|
              2[1-47]|
              3[15]|
              5[12]|
              6[0-26-9]|
              7[014-9]|
              8[013-57]|
              9[014-7]
            )|
            5(?:
              1[025]|
              22|
              [36][25]|
              4[28]|
              [578]1|
              9[15]
            )|
            6(?:
              12|
              [2-47]1|
              5[17]|
              6[13]|
              80
            )|
            7(?:
              12|
              2[14]|
              3[134]|
              4[47]|
              5[15]|
              [67]1
            )|
            8(?:
              16|
              2[014]|
              3[126]|
              6[136]|
              7[078]|
              8[34]|
              91
            )
          )[2-7]\\d{6}|
          (?:
            1(?:
              2[35-8]|
              3[346-9]|
              4[236-9]|
              [59][0235-9]|
              6[235-9]|
              7[34689]|
              8[257-9]
            )|
            2(?:
              1[134689]|
              3[24-8]|
              4[2-8]|
              5[25689]|
              6[2-4679]|
              7[3-79]|
              8[2-479]|
              9[235-9]
            )|
            3(?:
              01|
              1[79]|
              2[1245]|
              4[5-8]|
              5[125689]|
              6[235-7]|
              7[157-9]|
              8[2-46-8]
            )|
            4(?:
              1[14578]|
              2[5689]|
              3[2-467]|
              5[4-7]|
              6[35]|
              73|
              8[2689]|
              9[2389]
            )|
            5(?:
              [16][146-9]|
              2[14-8]|
              3[1346]|
              4[14-69]|
              5[46]|
              7[2-4]|
              8[2-8]|
              9[246]
            )|
            6(?:
              1[1358]|
              2[2457]|
              3[2-4]|
              4[235-7]|
              5[2-689]|
              6[24578]|
              7[235689]|
              8[124-6]
            )|
            7(?:
              1[013-9]|
              2[0235-9]|
              3[2679]|
              4[1-35689]|
              5[2-46-9]|
              [67][02-9]|
              8[013-7]|
              9[089]
            )|
            8(?:
              1[1357-9]|
              2[235-8]|
              3[03-57-9]|
              4[0-24-9]|
              5\\d|
              6[2457-9]|
              7[1-6]|
              8[1256]|
              9[2-4]
            )
          )\\d[2-7]\\d{5}
        ',
                'geographic' => '
          2717(?:
            [2-7]\\d|
            95
          )\\d{4}|
          (?:
            271[0-689]|
            782[0-6]
          )[2-7]\\d{5}|
          (?:
            170[24]|
            2(?:
              (?:
                [02][2-79]|
                90
              )\\d|
              80[13468]
            )|
            (?:
              3(?:
                23|
                80
              )|
              683|
              79[1-7]
            )\\d|
            4(?:
              20[24]|
              72[2-8]
            )|
            552[1-7]
          )\\d{6}|
          (?:
            11|
            33|
            4[04]|
            80
          )[2-7]\\d{7}|
          (?:
            342|
            674|
            788
          )(?:
            [0189][2-7]|
            [2-7]\\d
          )\\d{5}|
          (?:
            1(?:
              2[0-249]|
              3[0-25]|
              4[145]|
              [59][14]|
              6[014]|
              7[1257]|
              8[01346]
            )|
            2(?:
              1[257]|
              3[013]|
              4[01]|
              5[0137]|
              6[0158]|
              78|
              8[1568]|
              9[14]
            )|
            3(?:
              26|
              4[13]|
              5[34]|
              6[01489]|
              7[02-46]|
              8[159]
            )|
            4(?:
              1[36]|
              2[1-47]|
              3[15]|
              5[12]|
              6[0-26-9]|
              7[014-9]|
              8[013-57]|
              9[014-7]
            )|
            5(?:
              1[025]|
              22|
              [36][25]|
              4[28]|
              [578]1|
              9[15]
            )|
            6(?:
              12|
              [2-47]1|
              5[17]|
              6[13]|
              80
            )|
            7(?:
              12|
              2[14]|
              3[134]|
              4[47]|
              5[15]|
              [67]1
            )|
            8(?:
              16|
              2[014]|
              3[126]|
              6[136]|
              7[078]|
              8[34]|
              91
            )
          )[2-7]\\d{6}|
          (?:
            1(?:
              2[35-8]|
              3[346-9]|
              4[236-9]|
              [59][0235-9]|
              6[235-9]|
              7[34689]|
              8[257-9]
            )|
            2(?:
              1[134689]|
              3[24-8]|
              4[2-8]|
              5[25689]|
              6[2-4679]|
              7[3-79]|
              8[2-479]|
              9[235-9]
            )|
            3(?:
              01|
              1[79]|
              2[1245]|
              4[5-8]|
              5[125689]|
              6[235-7]|
              7[157-9]|
              8[2-46-8]
            )|
            4(?:
              1[14578]|
              2[5689]|
              3[2-467]|
              5[4-7]|
              6[35]|
              73|
              8[2689]|
              9[2389]
            )|
            5(?:
              [16][146-9]|
              2[14-8]|
              3[1346]|
              4[14-69]|
              5[46]|
              7[2-4]|
              8[2-8]|
              9[246]
            )|
            6(?:
              1[1358]|
              2[2457]|
              3[2-4]|
              4[235-7]|
              5[2-689]|
              6[24578]|
              7[235689]|
              8[124-6]
            )|
            7(?:
              1[013-9]|
              2[0235-9]|
              3[2679]|
              4[1-35689]|
              5[2-46-9]|
              [67][02-9]|
              8[013-7]|
              9[089]
            )|
            8(?:
              1[1357-9]|
              2[235-8]|
              3[03-57-9]|
              4[0-24-9]|
              5\\d|
              6[2457-9]|
              7[1-6]|
              8[1256]|
              9[2-4]
            )
          )\\d[2-7]\\d{5}
        ',
                'mobile' => '
          (?:
            61279|
            7(?:
              887[02-9]|
              9(?:
                313|
                79[07-9]
              )
            )|
            8(?:
              079[04-9]|
              (?:
                84|
                91
              )7[02-8]
            )
          )\\d{5}|
          (?:
            6(?:
              12|
              [2-47]1|
              5[17]|
              6[13]|
              80
            )[0189]|
            7(?:
              1(?:
                2[0189]|
                9[0-5]
              )|
              2(?:
                [14][017-9]|
                8[0-59]
              )|
              3(?:
                2[5-8]|
                [34][017-9]|
                9[016-9]
              )|
              4(?:
                1[015-9]|
                [29][89]|
                39|
                8[389]
              )|
              5(?:
                [15][017-9]|
                2[04-9]|
                9[7-9]
              )|
              6(?:
                0[0-47]|
                1[0-257-9]|
                2[0-4]|
                3[19]|
                5[4589]
              )|
              70[0289]|
              88[089]|
              97[02-8]
            )|
            8(?:
              0(?:
                6[67]|
                7[02-8]
              )|
              70[017-9]|
              84[01489]|
              91[0-289]
            )
          )\\d{6}|
          (?:
            7(?:
              31|
              4[47]
            )|
            8(?:
              16|
              2[014]|
              3[126]|
              6[136]|
              7[78]|
              83
            )
          )(?:
            [0189]\\d|
            7[02-8]
          )\\d{5}|
          (?:
            6(?:
              [09]\\d|
              1[04679]|
              2[03689]|
              3[05-9]|
              4[0489]|
              50|
              6[069]|
              7[07]|
              8[7-9]
            )|
            7(?:
              0\\d|
              2[0235-79]|
              3[05-8]|
              40|
              5[0346-8]|
              6[6-9]|
              7[1-9]|
              8[0-79]|
              9[089]
            )|
            8(?:
              0[01589]|
              1[0-57-9]|
              2[235-9]|
              3[03-57-9]|
              [45]\\d|
              6[02457-9]|
              7[1-69]|
              8[0-25-9]|
              9[02-9]
            )|
            9\\d\\d
          )\\d{7}|
          (?:
            6(?:
              (?:
                1[1358]|
                2[2457]|
                3[2-4]|
                4[235-7]|
                5[2-689]|
                6[24578]|
                8[124-6]
              )\\d|
              7(?:
                [235689]\\d|
                4[0189]
              )
            )|
            7(?:
              1(?:
                [013-8]\\d|
                9[6-9]
              )|
              28[6-8]|
              3(?:
                2[0-49]|
                9[2-5]
              )|
              4(?:
                1[2-4]|
                [29][0-7]|
                3[0-8]|
                [56]\\d|
                8[0-24-7]
              )|
              5(?:
                2[1-3]|
                9[0-6]
              )|
              6(?:
                0[5689]|
                2[5-9]|
                3[02-8]|
                4\\d|
                5[0-367]
              )|
              70[13-7]|
              881
            )
          )[0189]\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(1860\\d{7})|(186[12]\\d{9})|(140\\d{7})',
                'toll_free' => '
          000800\\d{7}|
          1(?:
            600\\d{6}|
            80(?:
              0\\d{4,9}|
              3\\d{9}
            )
          )
        ',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{9111} = "New\ Delhi";
$areanames{en}->{91120} = "Ghaziabad\/Dadri\,\ Uttar\ Pradesh";
$areanames{en}->{91121} = "Meerut\,\ Uttar\ Pradesh";
$areanames{en}->{91122} = "Hapur\,\ Uttar\ Pradesh";
$areanames{en}->{911232} = "Modinagar\,\ Uttar\ Pradesh";
$areanames{en}->{911233} = "Mawana\,\ Uttar\ Pradesh";
$areanames{en}->{911234} = "Baghpat\/Baraut\,\ Uttar\ Pradesh";
$areanames{en}->{911237} = "Sardhana\,\ Uttar\ Pradesh";
$areanames{en}->{91124} = "Gurgaon\,\ Haryana";
$areanames{en}->{911250} = "Charkhidadri\,\ Haryana";
$areanames{en}->{911251} = "Jhajjar\,\ Haryana";
$areanames{en}->{911252} = "Loharu\,\ Haryana";
$areanames{en}->{911253} = "Tohsham\,\ Haryana";
$areanames{en}->{911254} = "Bawanikhera\,\ Haryana";
$areanames{en}->{911255} = "Siwani\,\ Haryana";
$areanames{en}->{911257} = "Meham\,\ Haryana";
$areanames{en}->{911258} = "Kalanaur\,\ Haryana";
$areanames{en}->{911259} = "Kosli\,\ Haryana";
$areanames{en}->{911262} = "Rohtak\,\ Haryana";
$areanames{en}->{911263} = "Gohana\,\ Haryana";
$areanames{en}->{911267} = "Nuh\,\ Haryana";
$areanames{en}->{911268} = "Ferojpur\,\ Haryana";
$areanames{en}->{911274} = "Rewari\,\ Haryana";
$areanames{en}->{911275} = "Palwal\,\ Haryana";
$areanames{en}->{911276} = "Bahadurgarh\,\ Haryana";
$areanames{en}->{911281} = "Jatusana\,\ Haryana";
$areanames{en}->{911282} = "Narnaul\,\ Haryana";
$areanames{en}->{911284} = "Bawal\,\ Haryana";
$areanames{en}->{911285} = "Mohindergarh\,\ Haryana";
$areanames{en}->{91129} = "Faridabad\,\ Haryana";
$areanames{en}->{91130} = "Sonipat\,\ Haryana";
$areanames{en}->{91131} = "Muzaffarnagar\,\ Uttar\ Pradesh";
$areanames{en}->{91132} = "Saharanpur\,\ Uttar\ Pradesh";
$areanames{en}->{911331} = "Nakur\/Gangoh\,\ Uttar\ Pradesh";
$areanames{en}->{911332} = "Roorkee\,\ Uttarakhand";
$areanames{en}->{911334} = "Roorkee\/Haridwar\,\ Uttarakhand";
$areanames{en}->{911336} = "Deoband\,\ Uttar\ Pradesh";
$areanames{en}->{911341} = "Najibabad\,\ Uttar\ Pradesh";
$areanames{en}->{911342} = "Bijnor\,\ Uttar\ Pradesh";
$areanames{en}->{911343} = "Nagina\,\ Uttar\ Pradesh";
$areanames{en}->{911344} = "Dhampur\,\ Uttar\ Pradesh";
$areanames{en}->{911345} = "Bijnor\/Chandpur\,\ Uttar\ Pradesh";
$areanames{en}->{911346} = "Pauri\/Bubakhal\,\ Uttarakhand";
$areanames{en}->{911348} = "Lansdowne\/Syunsi\,\ Uttarakhand";
$areanames{en}->{91135} = "Dehradun\,\ Uttarakhand";
$areanames{en}->{911360} = "Dehradun\ Chakrata\/Dakpattar\,\ Uttarakhand";
$areanames{en}->{911363} = "Karnaprayag\,\ Uttarakhand";
$areanames{en}->{911364} = "Ukhimath\/Guptkashi\,\ Uttarakhand";
$areanames{en}->{911368} = "Pauri\,\ Uttarakhand";
$areanames{en}->{911370} = "Devprayag\/Jakholi\,\ Uttarakhand";
$areanames{en}->{911371} = "Dunda\,\ Uttarakhand";
$areanames{en}->{911372} = "Chamoli\,\ Uttarakhand";
$areanames{en}->{911373} = "Purola\,\ Uttarakhand";
$areanames{en}->{911374} = "Bhatwari\/Uttarkashi\,\ Uttarakhand";
$areanames{en}->{911375} = "Rajgarhi\,\ Uttarakhand";
$areanames{en}->{911376} = "Tehri\,\ Uttarakhand";
$areanames{en}->{911377} = "Bhatwari\/Gangotri\,\ Uttarakhand";
$areanames{en}->{911378} = "Devprayag\,\ Uttarakhand";
$areanames{en}->{911379} = "Pratapnagar\,\ Uttarakhand";
$areanames{en}->{911381} = "Joshimath\/Badrinath\,\ Uttarakhand";
$areanames{en}->{911382} = "Lansdowne\/Kotdwara\,\ Uttarakhand";
$areanames{en}->{911386} = "Lansdowne\,\ Uttarakhand";
$areanames{en}->{911389} = "Joshimath\,\ Uttarakhand";
$areanames{en}->{911392} = "Budhana\,\ Uttar\ Pradesh";
$areanames{en}->{911396} = "Jansath\/Khatauli\,\ Uttar\ Pradesh";
$areanames{en}->{911398} = "Kairana\/Shamli\,\ Uttar\ Pradesh";
$areanames{en}->{91141} = "Jaipur\,\ Rajasthan";
$areanames{en}->{911420} = "Baswa\/Bandikui\,\ Rajasthan";
$areanames{en}->{911421} = "Kotputli\,\ Rajasthan";
$areanames{en}->{911422} = "Viratnagar\/Shahpura\,\ Rajasthan";
$areanames{en}->{911423} = "Amber\/Chomu\,\ Rajasthan";
$areanames{en}->{911424} = "Phulera\/Renwal\,\ Rajasthan";
$areanames{en}->{911425} = "Phulera\/Sambhar\,\ Rajasthan";
$areanames{en}->{911426} = "Jamwa\ Ramgarh\/Achrol\,\ Rajasthan";
$areanames{en}->{911427} = "Dausa\,\ Rajasthan";
$areanames{en}->{911428} = "Dudu\,\ Rajasthan";
$areanames{en}->{911429} = "Bassi\,\ Rajasthan";
$areanames{en}->{911430} = "Phagi\,\ Rajasthan";
$areanames{en}->{911431} = "Lalsot\,\ Rajasthan";
$areanames{en}->{911432} = "Tonk\,\ Rajasthan";
$areanames{en}->{911433} = "Todaraisingh\,\ Rajasthan";
$areanames{en}->{911434} = "Deoli\,\ Rajasthan";
$areanames{en}->{911435} = "Tonk\/Piploo\,\ Rajasthan";
$areanames{en}->{911436} = "Uniayara\,\ Rajasthan";
$areanames{en}->{911437} = "Malpura\,\ Rajasthan";
$areanames{en}->{911438} = "Newai\,\ Rajasthan";
$areanames{en}->{91144} = "Alwar\,\ Rajasthan";
$areanames{en}->{91145} = "Ajmer\,\ Rajasthan";
$areanames{en}->{911460} = "Kishangarhbas\/Khairthal\,\ Rajasthan";
$areanames{en}->{911461} = "Bansur\,\ Rajasthan";
$areanames{en}->{911462} = "Beawar\,\ Rajasthan";
$areanames{en}->{911463} = "Kishangarh\,\ Rajasthan";
$areanames{en}->{911464} = "Rajgarh\,\ Rajasthan";
$areanames{en}->{911465} = "Thanaghazi\,\ Rajasthan";
$areanames{en}->{911466} = "Kekri\,\ Rajasthan";
$areanames{en}->{911467} = "Kekri\,\ Rajasthan";
$areanames{en}->{911468} = "Ramgarh\,\ Rajasthan";
$areanames{en}->{911469} = "Tijara\,\ Rajasthan";
$areanames{en}->{911470} = "Dungla\,\ Rajasthan";
$areanames{en}->{911471} = "Rashmi\,\ Rajasthan";
$areanames{en}->{911472} = "Chittorgarh\,\ Rajasthan";
$areanames{en}->{911473} = "Barisadri\,\ Rajasthan";
$areanames{en}->{911474} = "Begun\,\ Rajasthan";
$areanames{en}->{911475} = "Begun\/Rawatbhata\,\ Rajasthan";
$areanames{en}->{911476} = "Kapasan\,\ Rajasthan";
$areanames{en}->{911477} = "Nimbahera\,\ Rajasthan";
$areanames{en}->{911478} = "Pratapgarh\,\ Rajasthan";
$areanames{en}->{911479} = "Pratapgarh\/Arnod\,\ Rajasthan";
$areanames{en}->{911480} = "Asind\,\ Rajasthan";
$areanames{en}->{911481} = "Raipur\,\ Rajasthan";
$areanames{en}->{911482} = "Bhilwara\,\ Rajasthan";
$areanames{en}->{911483} = "Hurda\/Gulabpura\,\ Rajasthan";
$areanames{en}->{911484} = "Shahapura\,\ Rajasthan";
$areanames{en}->{911485} = "Jahazpur\,\ Rajasthan";
$areanames{en}->{911486} = "Mandal\,\ Rajasthan";
$areanames{en}->{911487} = "Banera\,\ Rajasthan";
$areanames{en}->{911488} = "Kotri\,\ Rajasthan";
$areanames{en}->{911489} = "Mandalgarh\,\ Rajasthan";
$areanames{en}->{911491} = "Nasirabad\,\ Rajasthan";
$areanames{en}->{911492} = "Laxmangarh\/Kherli\,\ Rajasthan";
$areanames{en}->{911493} = "Tijara\,\ Rajasthan";
$areanames{en}->{911494} = "Behror\,\ Rajasthan";
$areanames{en}->{911495} = "Mandawar\,\ Rajasthan";
$areanames{en}->{911496} = "Sarwar\,\ Rajasthan";
$areanames{en}->{911497} = "Kishangarh\,\ Rajasthan";
$areanames{en}->{911498} = "Anupgarh\,\ Rajasthan";
$areanames{en}->{911499} = "Sangaria\,\ Rajasthan";
$areanames{en}->{911501} = "Srikaranpur\,\ Rajasthan";
$areanames{en}->{911502} = "Nohar\/Jedasar\,\ Rajasthan";
$areanames{en}->{911503} = "Sadulshahar\,\ Rajasthan";
$areanames{en}->{911504} = "Bhadra\,\ Rajasthan";
$areanames{en}->{911505} = "Padampur\,\ Rajasthan";
$areanames{en}->{911506} = "Anupgarh\/Gharsana\,\ Rajasthan";
$areanames{en}->{911507} = "Raisinghnagar\,\ Rajasthan";
$areanames{en}->{911508} = "Suratgarh\/Goluwala\,\ Rajasthan";
$areanames{en}->{911509} = "Suratgarh\,\ Rajasthan";
$areanames{en}->{91151} = "Bikaner\,\ Rajasthan";
$areanames{en}->{911520} = "Bikaner\/Chhatargarh\,\ Rajasthan";
$areanames{en}->{911521} = "Bikaner\/Jaimalsar\,\ Rajasthan";
$areanames{en}->{911522} = "Bikaner\/Jamsar\,\ Rajasthan";
$areanames{en}->{911523} = "Bikaner\/Poogal\,\ Rajasthan";
$areanames{en}->{911526} = "Lunkaransar\/Mahajan\,\ Rajasthan";
$areanames{en}->{911527} = "Lunkaransar\/Rajasarb\,\ Rajasthan";
$areanames{en}->{911528} = "Lunkaransar\,\ Rajasthan";
$areanames{en}->{911529} = "Lunkaransar\/Kanholi\,\ Rajasthan";
$areanames{en}->{911531} = "Nokha\,\ Rajasthan";
$areanames{en}->{911532} = "Nokha\/Nathusar\,\ Rajasthan";
$areanames{en}->{911533} = "Kolayat\/Goddo\,\ Rajasthan";
$areanames{en}->{911534} = "Kolayat\,\ Rajasthan";
$areanames{en}->{911535} = "Kolayat\/Bajju\,\ Rajasthan";
$areanames{en}->{911536} = "Kolayat\/Daitra\,\ Rajasthan";
$areanames{en}->{911537} = "Nohar\/Rawatsar\,\ Rajasthan";
$areanames{en}->{911539} = "Tibbi\,\ Rajasthan";
$areanames{en}->{91154} = "Sriganganagar\,\ Rajasthan";
$areanames{en}->{911552} = "Hanumangarh\,\ Rajasthan";
$areanames{en}->{911555} = "Nohar\,\ Rajasthan";
$areanames{en}->{911559} = "Rajgarh\,\ Rajasthan";
$areanames{en}->{911560} = "Sujangarh\/Bidasar\,\ Rajasthan";
$areanames{en}->{911561} = "Taranagar\,\ Rajasthan";
$areanames{en}->{911562} = "Churu\,\ Rajasthan";
$areanames{en}->{911563} = "Sardarshahar\/Jaitsisar\,\ Rajasthan";
$areanames{en}->{911564} = "Sardarshahar\,\ Rajasthan";
$areanames{en}->{911565} = "Sri\ Dungargarh\,\ Rajasthan";
$areanames{en}->{911566} = "Sri\ Dungargarh\/Sudsar\,\ Rajasthan";
$areanames{en}->{911567} = "Ratangarh\,\ Rajasthan";
$areanames{en}->{911568} = "Sujangarh\,\ Rajasthan";
$areanames{en}->{911569} = "Sujangarh\/Lalgarh\,\ Rajasthan";
$areanames{en}->{911570} = "Laxmangarh\/Nechwa\,\ Rajasthan";
$areanames{en}->{911571} = "Fatehpur\,\ Rajasthan";
$areanames{en}->{911572} = "Sikar\,\ Rajasthan";
$areanames{en}->{911573} = "Laxmangarh\,\ Rajasthan";
$areanames{en}->{911574} = "Neem\ Ka\ Thana\,\ Rajasthan";
$areanames{en}->{911575} = "Srimadhopur\,\ Rajasthan";
$areanames{en}->{911576} = "Dantaramgarh\/Shyamji\,\ Rajasthan";
$areanames{en}->{911577} = "Dantaramgarh\,\ Rajasthan";
$areanames{en}->{911580} = "Deedwana\,\ Rajasthan";
$areanames{en}->{911581} = "Ladnun\,\ Rajasthan";
$areanames{en}->{911582} = "Nagaur\,\ Rajasthan";
$areanames{en}->{911583} = "Jayal\,\ Rajasthan";
$areanames{en}->{911584} = "Nagaur\/Mundwa\ Marwar\,\ Rajasthan";
$areanames{en}->{911585} = "Nagaur\/Khinwsar\,\ Rajasthan";
$areanames{en}->{911586} = "Nawa\/Kuchamancity\,\ Rajasthan";
$areanames{en}->{911587} = "Degana\,\ Rajasthan";
$areanames{en}->{911588} = "Parbatsar\/Makrana\,\ Rajasthan";
$areanames{en}->{911589} = "Parbatsar\,\ Rajasthan";
$areanames{en}->{911590} = "Merta\,\ Rajasthan";
$areanames{en}->{911591} = "Merta\/Gotan\,\ Rajasthan";
$areanames{en}->{911592} = "Jhunjhunu\,\ Rajasthan";
$areanames{en}->{911593} = "Khetri\,\ Rajasthan";
$areanames{en}->{911594} = "Udaipurwati\,\ Rajasthan";
$areanames{en}->{911595} = "Jhunjhunu\/Bissau\,\ Rajasthan";
$areanames{en}->{911596} = "Chirawa\,\ Rajasthan";
$areanames{en}->{911602} = "Kharar\,\ Punjab";
$areanames{en}->{911603} = "Kharar\,\ Punjab";
$areanames{en}->{911604} = "Kharar\,\ Punjab";
$areanames{en}->{911605} = "Kharar\,\ Punjab";
$areanames{en}->{911606} = "Kharar\,\ Punjab";
$areanames{en}->{911607} = "Kharar\,\ Punjab";
$areanames{en}->{91161} = "Ludhiana\,\ Punjab";
$areanames{en}->{911624} = "Jagraon\,\ Punjab";
$areanames{en}->{911628} = "Samrala\,\ Punjab";
$areanames{en}->{911632} = "Ferozepur\,\ Punjab";
$areanames{en}->{911633} = "Muktasar\,\ Punjab";
$areanames{en}->{911634} = "Abohar\,\ Punjab";
$areanames{en}->{911635} = "Kotkapura\,\ Punjab";
$areanames{en}->{911636} = "Moga\,\ Punjab";
$areanames{en}->{911637} = "Malaut\,\ Punjab";
$areanames{en}->{911638} = "Fazilka\,\ Punjab";
$areanames{en}->{911639} = "Faridakot\,\ Punjab";
$areanames{en}->{91164} = "Bhatinda\,\ Punjab";
$areanames{en}->{911651} = "Phulmandi\,\ Punjab";
$areanames{en}->{911652} = "Mansa\,\ Punjab";
$areanames{en}->{911655} = "Raman\,\ Punjab";
$areanames{en}->{911659} = "Sardulgarh\,\ Punjab";
$areanames{en}->{911662} = "Hissar\,\ Haryana";
$areanames{en}->{911663} = "Hansi\,\ Haryana";
$areanames{en}->{911664} = "Bhiwani\,\ Haryana";
$areanames{en}->{911666} = "Sirsa\,\ Haryana";
$areanames{en}->{911667} = "Fatehabad\,\ Haryana";
$areanames{en}->{911668} = "Dabwali\,\ Haryana";
$areanames{en}->{911669} = "Adampur\ Mandi\,\ Haryana";
$areanames{en}->{911672} = "Sangrur\,\ Punjab";
$areanames{en}->{911675} = "Malerkotla\,\ Punjab";
$areanames{en}->{911676} = "Sunam\,\ Punjab";
$areanames{en}->{911679} = "Barnala\,\ Punjab";
$areanames{en}->{911681} = "Jind\,\ Haryana";
$areanames{en}->{911682} = "Zira\,\ Punjab";
$areanames{en}->{911683} = "Julana\,\ Haryana";
$areanames{en}->{911684} = "Narwana\,\ Haryana";
$areanames{en}->{911685} = "Guruharsahai\,\ Punjab";
$areanames{en}->{911686} = "Safidon\,\ Haryana";
$areanames{en}->{911692} = "Tohana\,\ Haryana";
$areanames{en}->{911693} = "Barwala\,\ Haryana";
$areanames{en}->{911696} = "Kalanwali\,\ Haryana";
$areanames{en}->{911697} = "Ratia\,\ Haryana";
$areanames{en}->{911698} = "Ellenabad\,\ Haryana";
$areanames{en}->{911702} = "Nahan\,\ Himachal\ Pradesh";
$areanames{en}->{911704} = "Paonta\,\ Himachal\ Pradesh";
$areanames{en}->{91171} = "Ambala\,\ Haryana";
$areanames{en}->{91172} = "Chandigarh\,\ Punjab";
$areanames{en}->{911731} = "Barara\,\ Haryana";
$areanames{en}->{911732} = "Jagadhari\,\ Haryana";
$areanames{en}->{911733} = "Kalka\,\ Haryana";
$areanames{en}->{911734} = "Naraingarh\,\ Haryana";
$areanames{en}->{911735} = "Chaaharauli\,\ Haryana";
$areanames{en}->{911741} = "Pehowa\,\ Haryana";
$areanames{en}->{911743} = "Cheeka\,\ Haryana";
$areanames{en}->{911744} = "Kurukshetra\,\ Haryana";
$areanames{en}->{911745} = "Nilokheri\,\ Haryana";
$areanames{en}->{911746} = "Kaithal\,\ Haryana";
$areanames{en}->{911748} = "Gharaunda\,\ Haryana";
$areanames{en}->{911749} = "Assandh\,\ Haryana";
$areanames{en}->{91175} = "Patiala\,\ Punjab";
$areanames{en}->{911762} = "Rajpura\,\ Punjab";
$areanames{en}->{911763} = "Sarhind\,\ Punjab";
$areanames{en}->{911764} = "Samana\,\ Punjab";
$areanames{en}->{911765} = "Nabha\,\ Punjab";
$areanames{en}->{91177} = "Shimla\,\ Himachal\ Pradesh";
$areanames{en}->{911781} = "Rohru\,\ Himachal\ Pradesh";
$areanames{en}->{911782} = "Rampur\ Bushahar\,\ Himachal\ Pradesh";
$areanames{en}->{911783} = "Theog\,\ Himachal\ Pradesh";
$areanames{en}->{911785} = "Pooh\,\ Himachal\ Pradesh";
$areanames{en}->{911786} = "Kalpa\,\ Himachal\ Pradesh";
$areanames{en}->{911792} = "Solan\,\ Himachal\ Pradesh";
$areanames{en}->{911795} = "Nalagarh\,\ Himachal\ Pradesh";
$areanames{en}->{911796} = "Arki\,\ Himachal\ Pradesh";
$areanames{en}->{911799} = "Rajgarh\,\ Himachal\ Pradesh";
$areanames{en}->{911802} = "Panipat\,\ Haryana";
$areanames{en}->{911803} = "Panipat\,\ Haryana";
$areanames{en}->{911804} = "Panipat\,\ Haryana";
$areanames{en}->{911805} = "Panipat\,\ Haryana";
$areanames{en}->{911806} = "Panipat\,\ Haryana";
$areanames{en}->{911807} = "Panipat\,\ Haryana";
$areanames{en}->{91181} = "Jallandhar\,\ Punjab";
$areanames{en}->{911821} = "Nakodar\,\ Punjab";
$areanames{en}->{911822} = "Kapurthala\,\ Punjab";
$areanames{en}->{911823} = "Nawanshahar\,\ Punjab";
$areanames{en}->{911824} = "Phagwara\,\ Punjab";
$areanames{en}->{911826} = "Phillaur\,\ Punjab";
$areanames{en}->{911828} = "Sultanpur\ Lodhi\,\ Punjab";
$areanames{en}->{91183} = "Amritsar\,\ Punjab";
$areanames{en}->{91184} = "Karnal\,\ Haryana";
$areanames{en}->{911851} = "Patti\,\ Punjab";
$areanames{en}->{911852} = "Taran\,\ Punjab";
$areanames{en}->{911853} = "Rayya\,\ Punjab";
$areanames{en}->{911858} = "Ajnala\,\ Punjab";
$areanames{en}->{911859} = "Goindwal\,\ Punjab";
$areanames{en}->{91186} = "Pathankot\,\ Punjab";
$areanames{en}->{911870} = "Jugial\,\ Punjab";
$areanames{en}->{911871} = "Batala\,\ Punjab";
$areanames{en}->{911872} = "Quadian\,\ Punjab";
$areanames{en}->{911874} = "Gurdaspur\,\ Punjab";
$areanames{en}->{911875} = "Dinanagar\,\ Punjab";
$areanames{en}->{911881} = "Ropar\,\ Punjab";
$areanames{en}->{911882} = "Hoshiarpur\,\ Punjab";
$areanames{en}->{911883} = "Dasua\,\ Punjab";
$areanames{en}->{911884} = "Garhashanker\,\ Punjab";
$areanames{en}->{911885} = "Balachaur\,\ Punjab";
$areanames{en}->{911886} = "Tanda\ Urmar\,\ Punjab";
$areanames{en}->{911887} = "Nangal\,\ Punjab";
$areanames{en}->{911892} = "Kangra\/Dharamsala\,\ Himachal\ Pradesh";
$areanames{en}->{911893} = "Nurpur\,\ Himachal\ Pradesh";
$areanames{en}->{911894} = "Palampur\,\ Himachal\ Pradesh";
$areanames{en}->{911895} = "Bharmour\,\ Himachal\ Pradesh";
$areanames{en}->{911896} = "Churah\/Tissa\,\ Himachal\ Pradesh";
$areanames{en}->{911897} = "Pangi\/Killar\,\ Himachal\ Pradesh";
$areanames{en}->{911899} = "Chamba\,\ Himachal\ Pradesh";
$areanames{en}->{911900} = "Lahul\/Keylong\,\ Himachal\ Pradesh";
$areanames{en}->{911902} = "Kullu\,\ Himachal\ Pradesh";
$areanames{en}->{911903} = "Banjar\,\ Himachal\ Pradesh";
$areanames{en}->{911904} = "Nirmand\,\ Himachal\ Pradesh";
$areanames{en}->{911905} = "Mandi\,\ Himachal\ Pradesh";
$areanames{en}->{911906} = "Spiti\/Kaza\,\ Himachal\ Pradesh";
$areanames{en}->{911907} = "Sundernagar\,\ Himachal\ Pradesh";
$areanames{en}->{911908} = "Jogindernagar\,\ Himachal\ Pradesh";
$areanames{en}->{911909} = "Udaipur\,\ Himachal\ Pradesh";
$areanames{en}->{91191} = "Jammu\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911921} = "Basholi\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911922} = "Kathua\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911923} = "Samba\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911924} = "Akhnoor\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911931} = "Kulgam\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911932} = "Anantnag\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911933} = "Pulwama\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911936} = "Pahalgam\,\ Jammu\ And\ Kashmir";
$areanames{en}->{91194} = "Srinagar\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911951} = "Badgam\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911952} = "Baramulla\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911954} = "Sopore\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911955} = "Kupwara\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911956} = "Uri\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911957} = "Bandipur\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911958} = "Karnah\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911960} = "Nowshera\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911962} = "Rajouri\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911964} = "Kalakot\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911965} = "Poonch\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911970} = "Dehra\ Gopipur\,\ Himachal\ Pradesh";
$areanames{en}->{911972} = "Hamirpur\,\ Himachal\ Pradesh";
$areanames{en}->{911975} = "Una\,\ Himachal\ Pradesh";
$areanames{en}->{911976} = "Amb\,\ Himachal\ Pradesh";
$areanames{en}->{911978} = "Bilaspur\,\ Himachal\ Pradesh";
$areanames{en}->{911980} = "Nobra\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911981} = "Nyoma\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911982} = "Leh\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911983} = "Zanaskar\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911985} = "Kargil\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911990} = "Ramnagar\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911991} = "Reasi\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911992} = "Udhampur\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911995} = "Kishtwar\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911996} = "Doda\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911997} = "Bedarwah\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911998} = "Ramban\,\ Jammu\ And\ Kashmir";
$areanames{en}->{911999} = "Mahore\,\ Jammu\ And\ Kashmir";
$areanames{en}->{91202} = "Pune\,\ Maharashtra";
$areanames{en}->{91203} = "Pune\,\ Maharashtra";
$areanames{en}->{91204} = "Pune\,\ Maharashtra";
$areanames{en}->{91205} = "Pune\,\ Maharashtra";
$areanames{en}->{91206} = "Pune\,\ Maharashtra";
$areanames{en}->{91207} = "Pune\,\ Maharashtra";
$areanames{en}->{912111} = "Indapur\,\ Maharashtra";
$areanames{en}->{912112} = "Baramati\,\ Maharashtra";
$areanames{en}->{912113} = "Bhor\,\ Maharashtra";
$areanames{en}->{912114} = "Lonavala\,\ Maharashtra";
$areanames{en}->{912115} = "Saswad\,\ Maharashtra";
$areanames{en}->{912117} = "Daund\,\ Maharashtra";
$areanames{en}->{912118} = "Walchandnagar\,\ Maharashtra";
$areanames{en}->{912119} = "Kedgaon\,\ Maharashtra";
$areanames{en}->{91212} = "Chinchwad\,\ Maharashtra";
$areanames{en}->{912130} = "Velhe\,\ Maharashtra";
$areanames{en}->{912132} = "Junnar\,\ Maharashtra";
$areanames{en}->{912133} = "Manchar\,\ Maharashtra";
$areanames{en}->{912135} = "Rajgurunagar\,\ Maharashtra";
$areanames{en}->{912136} = "Urlikanchan\,\ Maharashtra";
$areanames{en}->{912137} = "Nahavara\,\ Maharashtra";
$areanames{en}->{912138} = "Shirur\,\ Maharashtra";
$areanames{en}->{912139} = "Pirangut\,\ Maharashtra";
$areanames{en}->{912140} = "Mangaon\,\ Maharashtra";
$areanames{en}->{912141} = "Alibagh\,\ Maharashtra";
$areanames{en}->{912142} = "Pali\,\ Maharashtra";
$areanames{en}->{912143} = "Pen\,\ Maharashtra";
$areanames{en}->{912144} = "Murud\,\ Maharashtra";
$areanames{en}->{912145} = "Mahad\,\ Maharashtra";
$areanames{en}->{912147} = "Shrivardhan\,\ Maharashtra";
$areanames{en}->{912148} = "Karjat\,\ Maharashtra";
$areanames{en}->{912149} = "Mahasala\,\ Maharashtra";
$areanames{en}->{91215} = "Navi\ Mumbai\/Turbhe\,\ Maharashtra";
$areanames{en}->{912160} = "Sakarwadi\,\ Maharashtra";
$areanames{en}->{912161} = "Vaduj\,\ Maharashtra";
$areanames{en}->{912162} = "Satara\,\ Maharashtra";
$areanames{en}->{912163} = "Koregaon\,\ Maharashtra";
$areanames{en}->{912164} = "Karad\,\ Maharashtra";
$areanames{en}->{912165} = "Dhiwadi\,\ Maharashtra";
$areanames{en}->{912166} = "Phaltan\,\ Maharashtra";
$areanames{en}->{912167} = "Wai\,\ Maharashtra";
$areanames{en}->{912168} = "Mahabaleswar\,\ Maharashtra";
$areanames{en}->{912169} = "Shirwal\,\ Maharashtra";
$areanames{en}->{91217} = "Sholapur\,\ Maharashtra";
$areanames{en}->{912181} = "Akkalkot\,\ Maharashtra";
$areanames{en}->{912182} = "Karmala\,\ Maharashtra";
$areanames{en}->{912183} = "Madha\,\ Maharashtra";
$areanames{en}->{912184} = "Barsi\,\ Maharashtra";
$areanames{en}->{912185} = "Malsuras\,\ Maharashtra";
$areanames{en}->{912186} = "Pandharpur\,\ Maharashtra";
$areanames{en}->{912187} = "Sangola\,\ Maharashtra";
$areanames{en}->{912188} = "Mangalwedha\,\ Maharashtra";
$areanames{en}->{912189} = "Mohol\,\ Maharashtra";
$areanames{en}->{912191} = "Poladpur\,\ Maharashtra";
$areanames{en}->{912192} = "Khopoli\,\ Maharashtra";
$areanames{en}->{912194} = "Roha\,\ Maharashtra";
$areanames{en}->{91222} = "Mumbai";
$areanames{en}->{91223} = "Mumbai";
$areanames{en}->{91224} = "Mumbai";
$areanames{en}->{91225} = "Mumbai";
$areanames{en}->{91226} = "Mumbai";
$areanames{en}->{91227} = "Mumbai";
$areanames{en}->{91230} = "Khadakwasala\,\ Maharashtra";
$areanames{en}->{91231} = "Kolhapur\,\ Maharashtra";
$areanames{en}->{912320} = "Chandgad\,\ Maharashtra";
$areanames{en}->{912321} = "Radhanagar\,\ Maharashtra";
$areanames{en}->{912322} = "Shirol\/Jalsingpur\,\ Maharashtra";
$areanames{en}->{912323} = "Ajara\,\ Maharashtra";
$areanames{en}->{912324} = "Hatkangale\/Ichalkaranji\,\ Maharashtra";
$areanames{en}->{912325} = "Kagal\/Murgud\,\ Maharashtra";
$areanames{en}->{912326} = "Gaganbavada\,\ Maharashtra";
$areanames{en}->{912327} = "Gadhinglaj\,\ Maharashtra";
$areanames{en}->{912328} = "Panhala\,\ Maharashtra";
$areanames{en}->{912329} = "Shahuwadi\/Malakapur\,\ Maharashtra";
$areanames{en}->{91233} = "Sangli\,\ Maharashtra";
$areanames{en}->{912341} = "Kavathemankal\,\ Maharashtra";
$areanames{en}->{912342} = "Islampur\,\ Maharashtra";
$areanames{en}->{912343} = "Atpadi\,\ Maharashtra";
$areanames{en}->{912344} = "Jath\,\ Maharashtra";
$areanames{en}->{912345} = "Shirala\,\ Maharashtra";
$areanames{en}->{912346} = "Tasgaon\,\ Maharashtra";
$areanames{en}->{912347} = "Vita\,\ Maharashtra";
$areanames{en}->{912350} = "Madangad\,\ Maharashtra";
$areanames{en}->{912351} = "Langa\,\ Maharashtra";
$areanames{en}->{912352} = "Ratnagiri\,\ Maharashtra";
$areanames{en}->{912353} = "Rajapur\,\ Maharashtra";
$areanames{en}->{912354} = "Sanganeshwar\/Deorukh\,\ Maharashtra";
$areanames{en}->{912355} = "Chiplun\,\ Maharashtra";
$areanames{en}->{912356} = "Khed\,\ Maharashtra";
$areanames{en}->{912357} = "Malgund\,\ Maharashtra";
$areanames{en}->{912358} = "Dapoli\,\ Maharashtra";
$areanames{en}->{912359} = "Guhagar\,\ Maharashtra";
$areanames{en}->{912362} = "Kudal\,\ Maharashtra";
$areanames{en}->{912363} = "Sawantwadi\,\ Maharashtra";
$areanames{en}->{912364} = "Deogad\,\ Maharashtra";
$areanames{en}->{912365} = "Malwan\,\ Maharashtra";
$areanames{en}->{912366} = "Vengurla\,\ Maharashtra";
$areanames{en}->{912367} = "Kankavali\,\ Maharashtra";
$areanames{en}->{912371} = "Wathar\,\ Maharashtra";
$areanames{en}->{912372} = "Patan\,\ Maharashtra";
$areanames{en}->{912373} = "Mahaswad\,\ Maharashtra";
$areanames{en}->{912375} = "Pusegaon\,\ Maharashtra";
$areanames{en}->{912378} = "Medha\,\ Maharashtra";
$areanames{en}->{912381} = "Ahmedpur\,\ Maharashtra";
$areanames{en}->{912382} = "Latur\,\ Maharashtra";
$areanames{en}->{912383} = "Ausa\,\ Maharashtra";
$areanames{en}->{912384} = "Nilanga\,\ Maharashtra";
$areanames{en}->{912385} = "Udgir\,\ Maharashtra";
$areanames{en}->{91241} = "Ahmednagar\,\ Maharashtra";
$areanames{en}->{912421} = "Jamkhed\,\ Maharashtra";
$areanames{en}->{912422} = "Shri\ Rampur\,\ Maharashtra";
$areanames{en}->{912423} = "Koparagon\,\ Maharashtra";
$areanames{en}->{912424} = "Akole\,\ Maharashtra";
$areanames{en}->{912425} = "Sangamner\,\ Maharashtra";
$areanames{en}->{912426} = "Rahuri\,\ Maharashtra";
$areanames{en}->{912427} = "Newasa\,\ Maharashtra";
$areanames{en}->{912428} = "Pathardi\,\ Maharashtra";
$areanames{en}->{912429} = "Shevgaon\,\ Maharashtra";
$areanames{en}->{912430} = "Sillod\,\ Maharashtra";
$areanames{en}->{912431} = "Paithan\,\ Maharashtra";
$areanames{en}->{912432} = "Aurangabad\,\ Maharashtra";
$areanames{en}->{912433} = "Gangapur\,\ Maharashtra";
$areanames{en}->{912435} = "Kannad\,\ Maharashtra";
$areanames{en}->{912436} = "Vijapur\,\ Maharashtra";
$areanames{en}->{912437} = "Khultabad\,\ Maharashtra";
$areanames{en}->{912438} = "Soyegaon\,\ Maharashtra";
$areanames{en}->{912439} = "Golegaon\,\ Maharashtra";
$areanames{en}->{912441} = "Ashti\,\ Maharashtra";
$areanames{en}->{912442} = "Bhir\,\ Maharashtra";
$areanames{en}->{912443} = "Manjalegaon\,\ Maharashtra";
$areanames{en}->{912444} = "Patoda\,\ Maharashtra";
$areanames{en}->{912445} = "Kaij\,\ Maharashtra";
$areanames{en}->{912446} = "Ambejogai\,\ Maharashtra";
$areanames{en}->{912447} = "Gevrai\,\ Maharashtra";
$areanames{en}->{912451} = "Pathari\,\ Maharashtra";
$areanames{en}->{912452} = "Parbhani\,\ Maharashtra";
$areanames{en}->{912453} = "Gangakhed\,\ Maharashtra";
$areanames{en}->{912454} = "Basmatnagar\,\ Maharashtra";
$areanames{en}->{912455} = "Kalamnuri\,\ Maharashtra";
$areanames{en}->{912456} = "Hingoli\,\ Maharashtra";
$areanames{en}->{912457} = "Jintdor\,\ Maharashtra";
$areanames{en}->{912460} = "Delhi\ Tanda\,\ Maharashtra";
$areanames{en}->{912461} = "Mukhed\,\ Maharashtra";
$areanames{en}->{912462} = "Nanded\,\ Maharashtra";
$areanames{en}->{912463} = "Degloor\,\ Maharashtra";
$areanames{en}->{912465} = "Billoli\,\ Maharashtra";
$areanames{en}->{912466} = "Kandhar\,\ Maharashtra";
$areanames{en}->{912467} = "Bhokar\,\ Maharashtra";
$areanames{en}->{912468} = "Hadgaon\,\ Maharashtra";
$areanames{en}->{912469} = "Kinwat\,\ Maharashtra";
$areanames{en}->{912471} = "Tuljapur\,\ Maharashtra";
$areanames{en}->{912472} = "Osmanabad\,\ Maharashtra";
$areanames{en}->{912473} = "Kallam\,\ Maharashtra";
$areanames{en}->{912475} = "Omerga\,\ Maharashtra";
$areanames{en}->{912477} = "Paranda\,\ Maharashtra";
$areanames{en}->{912478} = "Bhoom\,\ Maharashtra";
$areanames{en}->{912481} = "Ner\,\ Maharashtra";
$areanames{en}->{912482} = "Jalna\,\ Maharashtra";
$areanames{en}->{912483} = "Ambad\,\ Maharashtra";
$areanames{en}->{912484} = "Partur\,\ Maharashtra";
$areanames{en}->{912485} = "Bhokardan\,\ Maharashtra";
$areanames{en}->{912487} = "Shrigonda\,\ Maharashtra";
$areanames{en}->{912488} = "Parner\,\ Maharashtra";
$areanames{en}->{912489} = "Karjat\,\ Maharashtra";
$areanames{en}->{91250} = "Bassein\,\ Maharashtra";
$areanames{en}->{91251} = "Kalyan\,\ Maharashtra";
$areanames{en}->{912520} = "Jawahar\,\ Maharashtra";
$areanames{en}->{912521} = "Talasari\,\ Maharashtra";
$areanames{en}->{912522} = "Bhiwandi\,\ Maharashtra";
$areanames{en}->{912524} = "Murbad\,\ Maharashtra";
$areanames{en}->{912525} = "Palghar\,\ Maharashtra";
$areanames{en}->{912526} = "Wada\,\ Maharashtra";
$areanames{en}->{912527} = "Shahapur\,\ Maharashtra";
$areanames{en}->{912528} = "Dahanu\,\ Maharashtra";
$areanames{en}->{912529} = "Mokhada\,\ Maharashtra";
$areanames{en}->{91253} = "Nasik\ City\,\ Maharashtra";
$areanames{en}->{912550} = "Niphad\,\ Maharashtra";
$areanames{en}->{912551} = "Sinnar\,\ Maharashtra";
$areanames{en}->{912552} = "Nandgaon\,\ Maharashtra";
$areanames{en}->{912553} = "Igatpuri\,\ Maharashtra";
$areanames{en}->{912554} = "Malegaon\,\ Maharashtra";
$areanames{en}->{912555} = "Satana\,\ Maharashtra";
$areanames{en}->{912556} = "Chanwad\,\ Maharashtra";
$areanames{en}->{912557} = "Dindori\,\ Maharashtra";
$areanames{en}->{912558} = "Peint\,\ Maharashtra";
$areanames{en}->{912559} = "Yeola\,\ Maharashtra";
$areanames{en}->{912560} = "Kusumba\,\ Maharashtra";
$areanames{en}->{912561} = "Pimpalner\,\ Maharashtra";
$areanames{en}->{912562} = "Dhule\,\ Maharashtra";
$areanames{en}->{912563} = "Shirpur\,\ Maharashtra";
$areanames{en}->{912564} = "Nandurbar\,\ Maharashtra";
$areanames{en}->{912565} = "Shahada\,\ Maharashtra";
$areanames{en}->{912566} = "Sindkheda\,\ Maharashtra";
$areanames{en}->{912567} = "Taloda\,\ Maharashtra";
$areanames{en}->{912568} = "Sakri\,\ Maharashtra";
$areanames{en}->{912569} = "Navapur\,\ Maharashtra";
$areanames{en}->{91257} = "Jalgaon\,\ Maharashtra";
$areanames{en}->{912580} = "Jamner\,\ Maharashtra";
$areanames{en}->{912582} = "Bhusawal\,\ Maharashtra";
$areanames{en}->{912583} = "Edalabad\,\ Maharashtra";
$areanames{en}->{912584} = "Raver\,\ Maharashtra";
$areanames{en}->{912585} = "Yawal\,\ Maharashtra";
$areanames{en}->{912586} = "Chopda\,\ Maharashtra";
$areanames{en}->{912587} = "Amalner\,\ Maharashtra";
$areanames{en}->{912588} = "Erandul\,\ Maharashtra";
$areanames{en}->{912589} = "Chalisgaon\,\ Maharashtra";
$areanames{en}->{912591} = "Manmad\,\ Maharashtra";
$areanames{en}->{912592} = "Kalwan\,\ Maharashtra";
$areanames{en}->{912593} = "Surgena\,\ Maharashtra";
$areanames{en}->{912594} = "Trimbak\,\ Maharashtra";
$areanames{en}->{912595} = "Dhadgaon\,\ Maharashtra";
$areanames{en}->{912596} = "Pachora\,\ Maharashtra";
$areanames{en}->{912597} = "Parola\,\ Maharashtra";
$areanames{en}->{912598} = "Umrane\,\ Maharashtra";
$areanames{en}->{912599} = "Bhudargad\/Gargoti\,\ Maharashtra";
$areanames{en}->{91260} = "Vapi\,\ Gujarat";
$areanames{en}->{91261} = "Surat\,\ Gujarat";
$areanames{en}->{912621} = "Sayan\,\ Gujarat";
$areanames{en}->{912622} = "Bardoli\,\ Gujarat";
$areanames{en}->{912623} = "Mandvi\,\ Gujarat";
$areanames{en}->{912624} = "Fortsongadh\,\ Gujarat";
$areanames{en}->{912625} = "Valod\,\ Gujarat";
$areanames{en}->{912626} = "Vyara\,\ Gujarat";
$areanames{en}->{912628} = "Nizar\,\ Gujarat";
$areanames{en}->{912629} = "M\.M\.Mangrol\,\ Gujarat";
$areanames{en}->{912630} = "Bansada\,\ Gujarat";
$areanames{en}->{912631} = "Ahwa\,\ Gujarat";
$areanames{en}->{912632} = "Valsad\,\ Gujarat";
$areanames{en}->{912633} = "Dharampur\,\ Gujarat";
$areanames{en}->{912634} = "Billimora\,\ Gujarat";
$areanames{en}->{912637} = "Navsari\,\ Gujarat";
$areanames{en}->{912640} = "Rajpipla\,\ Gujarat";
$areanames{en}->{912641} = "Amod\,\ Gujarat";
$areanames{en}->{912642} = "Bharuch\,\ Gujarat";
$areanames{en}->{912643} = "Valia\,\ Gujarat";
$areanames{en}->{912644} = "Jambusar\,\ Gujarat";
$areanames{en}->{912645} = "Jhagadia\,\ Gujarat";
$areanames{en}->{912646} = "Ankleshwar\,\ Gujarat";
$areanames{en}->{912649} = "Dediapada\,\ Gujarat";
$areanames{en}->{91265} = "Vadodara\,\ Gujarat";
$areanames{en}->{912661} = "Naswadi\,\ Gujarat";
$areanames{en}->{912662} = "Padra\,\ Gujarat";
$areanames{en}->{912663} = "Dabhoi\,\ Gujarat";
$areanames{en}->{912664} = "Pavijetpur\,\ Gujarat";
$areanames{en}->{912665} = "Sankheda\,\ Gujarat";
$areanames{en}->{912666} = "Miyagam\,\ Gujarat";
$areanames{en}->{912667} = "Savli\,\ Gujarat";
$areanames{en}->{912668} = "Waghodia\,\ Gujarat";
$areanames{en}->{912669} = "Chhota\ Udaipur\,\ Gujarat";
$areanames{en}->{912670} = "Shehra\,\ Gujarat";
$areanames{en}->{912672} = "Godhra\,\ Gujarat";
$areanames{en}->{912673} = "Dahod\,\ Gujarat";
$areanames{en}->{912674} = "Lunavada\,\ Gujarat";
$areanames{en}->{912675} = "Santrampur\,\ Gujarat";
$areanames{en}->{912676} = "Halol\,\ Gujarat";
$areanames{en}->{912677} = "Limkheda\,\ Gujarat";
$areanames{en}->{912678} = "Devgadhbaria\,\ Gujarat";
$areanames{en}->{912679} = "Jhalod\,\ Gujarat";
$areanames{en}->{91268} = "Nadiad\,\ Gujarat";
$areanames{en}->{912690} = "Balasinor\,\ Gujarat";
$areanames{en}->{912691} = "Kapad\ Wanj\,\ Gujarat";
$areanames{en}->{912692} = "Anand\,\ Gujarat";
$areanames{en}->{912694} = "Kheda\,\ Gujarat";
$areanames{en}->{912696} = "Borsad\,\ Gujarat";
$areanames{en}->{912697} = "Retlad\,\ Gujarat";
$areanames{en}->{912698} = "Khambat\,\ Gujarat";
$areanames{en}->{912699} = "Thasra\,\ Gujarat";
$areanames{en}->{912711} = "Barwala\,\ Gujarat";
$areanames{en}->{912712} = "Gandhi\ Nagar\,\ Gujarat";
$areanames{en}->{912713} = "Dhandhuka\,\ Gujarat";
$areanames{en}->{912714} = "Dholka\,\ Gujarat";
$areanames{en}->{912715} = "Viramgam\,\ Gujarat";
$areanames{en}->{912716} = "Dehgam\,\ Gujarat";
$areanames{en}->{9127172} = "Sanand\,\ Gujarat";
$areanames{en}->{9127173} = "Sanand\,\ Gujarat";
$areanames{en}->{9127174} = "Sanand\,\ Gujarat";
$areanames{en}->{9127175} = "Sanand\,\ Gujarat";
$areanames{en}->{9127176} = "Sanand\,\ Gujarat";
$areanames{en}->{9127177} = "Sanand\,\ Gujarat";
$areanames{en}->{912718} = "Bareja\,\ Gujarat";
$areanames{en}->{912733} = "Harij\,\ Gujarat";
$areanames{en}->{912734} = "Chanasma\,\ Gujarat";
$areanames{en}->{912735} = "Deodar\,\ Gujarat";
$areanames{en}->{912737} = "Tharad\,\ Gujarat";
$areanames{en}->{912738} = "Santalpur\,\ Gujarat";
$areanames{en}->{912739} = "Vadgam\,\ Gujarat";
$areanames{en}->{912740} = "Vav\,\ Gujarat";
$areanames{en}->{912742} = "Palanpur\,\ Gujarat";
$areanames{en}->{912744} = "Deesa\,\ Gujarat";
$areanames{en}->{912746} = "Radhanpur\,\ Gujarat";
$areanames{en}->{912747} = "Thara\,\ Gujarat";
$areanames{en}->{912748} = "Dhanera\,\ Gujarat";
$areanames{en}->{912749} = "Danta\,\ Gujarat";
$areanames{en}->{912751} = "Chotila\,\ Gujarat";
$areanames{en}->{912752} = "Surendranagar\,\ Gujarat";
$areanames{en}->{912753} = "Limbdi\,\ Gujarat";
$areanames{en}->{912754} = "Dhrangadhra\,\ Gujarat";
$areanames{en}->{912755} = "Sayla\,\ Gujarat";
$areanames{en}->{912756} = "Muli\,\ Gujarat";
$areanames{en}->{912757} = "Dasada\,\ Gujarat";
$areanames{en}->{912758} = "Halvad\,\ Gujarat";
$areanames{en}->{912759} = "Lakhtar\,\ Gujarat";
$areanames{en}->{912761} = "Kheralu\,\ Gujarat";
$areanames{en}->{912762} = "Mehsana\,\ Gujarat";
$areanames{en}->{912763} = "Vijapur\,\ Gujarat";
$areanames{en}->{912764} = "Kalol\,\ Gujarat";
$areanames{en}->{912765} = "Visnagar\,\ Gujarat";
$areanames{en}->{912766} = "Patan\,\ Gujarat";
$areanames{en}->{912767} = "Sidhpur\,\ Gujarat";
$areanames{en}->{912770} = "Prantij\,\ Gujarat";
$areanames{en}->{912771} = "Bhiloda\,\ Gujarat";
$areanames{en}->{912772} = "Himatnagar\,\ Gujarat";
$areanames{en}->{912773} = "Malpur\,\ Gujarat";
$areanames{en}->{912774} = "Modasa\,\ Gujarat";
$areanames{en}->{912775} = "Khedbrahma\,\ Gujarat";
$areanames{en}->{912778} = "Idar\,\ Gujarat";
$areanames{en}->{912779} = "Bayad\,\ Gujarat";
$areanames{en}->{91278} = "Bhavnagar\,\ Gujarat";
$areanames{en}->{912791} = "Babra\,\ Gujarat";
$areanames{en}->{912792} = "Amreli\,\ Gujarat";
$areanames{en}->{912793} = "Damnagar\,\ Gujarat";
$areanames{en}->{912794} = "Rajula\,\ Gujarat";
$areanames{en}->{912795} = "Kodinar\,\ Gujarat";
$areanames{en}->{912796} = "Kunkawav\,\ Gujarat";
$areanames{en}->{912797} = "Dhari\,\ Gujarat";
$areanames{en}->{912801} = "Ranavav\,\ Gujarat";
$areanames{en}->{912803} = "Khavda\,\ Gujarat";
$areanames{en}->{912804} = "Kutiyana\,\ Gujarat";
$areanames{en}->{912806} = "Gogodar\,\ Gujarat";
$areanames{en}->{912808} = "Sumrasar\,\ Gujarat";
$areanames{en}->{91281} = "Rajkot\,\ Gujarat";
$areanames{en}->{912820} = "Paddhari\,\ Gujarat";
$areanames{en}->{912821} = "Jasdan\,\ Gujarat";
$areanames{en}->{912822} = "Morvi\,\ Gujarat";
$areanames{en}->{912823} = "Jetpur\,\ Gujarat";
$areanames{en}->{912824} = "Dhoraji\,\ Gujarat";
$areanames{en}->{912825} = "Gondal\,\ Gujarat";
$areanames{en}->{912826} = "Upleta\,\ Gujarat";
$areanames{en}->{912827} = "Kotdasanghani\,\ Gujarat";
$areanames{en}->{912828} = "Wankaner\,\ Gujarat";
$areanames{en}->{912829} = "Maliya\ Miyana\,\ Gujarat";
$areanames{en}->{912830} = "Rahpar\,\ Gujarat";
$areanames{en}->{912831} = "Nalia\,\ Gujarat";
$areanames{en}->{912832} = "Bhuj\,\ Gujarat";
$areanames{en}->{912833} = "Khambhalia\,\ Gujarat";
$areanames{en}->{912834} = "Kutchmandvi\,\ Gujarat";
$areanames{en}->{912835} = "Nakhatrana\,\ Gujarat";
$areanames{en}->{912836} = "Anjar\/Gandhidham\,\ Gujarat";
$areanames{en}->{912837} = "Bhachav\,\ Gujarat";
$areanames{en}->{912838} = "Mundra\,\ Gujarat";
$areanames{en}->{912839} = "Lakhpat\,\ Gujarat";
$areanames{en}->{912841} = "Vallabhipur\,\ Gujarat";
$areanames{en}->{912842} = "Talaja\,\ Gujarat";
$areanames{en}->{912843} = "Gariadhar\,\ Gujarat";
$areanames{en}->{912844} = "Mahuva\,\ Gujarat";
$areanames{en}->{912845} = "Savarkundla\,\ Gujarat";
$areanames{en}->{912846} = "Sihor\,\ Gujarat";
$areanames{en}->{912847} = "Gadhada\,\ Gujarat";
$areanames{en}->{912848} = "Palitana\,\ Gujarat";
$areanames{en}->{912849} = "Botad\,\ Gujarat";
$areanames{en}->{91285} = "Junagarh\,\ Gujarat";
$areanames{en}->{91286} = "Porbander\,\ Gujarat";
$areanames{en}->{912870} = "Malia\ Hatina\,\ Gujarat";
$areanames{en}->{912871} = "Keshod\,\ Gujarat";
$areanames{en}->{912872} = "Vanthali\,\ Gujarat";
$areanames{en}->{912873} = "Visavadar\,\ Gujarat";
$areanames{en}->{912874} = "Manavadar\,\ Gujarat";
$areanames{en}->{912875} = "Una\/Diu\,\ Gujarat";
$areanames{en}->{912876} = "Veraval\,\ Gujarat";
$areanames{en}->{912877} = "Talala\,\ Gujarat";
$areanames{en}->{912878} = "Mangrol\,\ Gujarat";
$areanames{en}->{91288} = "Jamnagar\,\ Gujarat";
$areanames{en}->{912891} = "Jamkalyanpur\,\ Gujarat";
$areanames{en}->{912892} = "Okha\,\ Gujarat";
$areanames{en}->{912893} = "Jodia\,\ Gujarat";
$areanames{en}->{912894} = "Kalawad\,\ Gujarat";
$areanames{en}->{912895} = "Lalpur\,\ Gujarat";
$areanames{en}->{912896} = "Bhanvad\,\ Gujarat";
$areanames{en}->{912897} = "Dhrol\,\ Gujarat";
$areanames{en}->{912898} = "Jamjodhpur\,\ Gujarat";
$areanames{en}->{912900} = "Siwana\/Samdari\,\ Rajasthan";
$areanames{en}->{912901} = "Siwana\,\ Rajasthan";
$areanames{en}->{912902} = "Barmer\/Kanot\,\ Rajasthan";
$areanames{en}->{912903} = "Chohtan\/Gangasar\,\ Rajasthan";
$areanames{en}->{912904} = "Deogarh\,\ Rajasthan";
$areanames{en}->{912905} = "Sarada\/Chawand\,\ Rajasthan";
$areanames{en}->{912906} = "Salumber\,\ Rajasthan";
$areanames{en}->{912907} = "Kherwara\,\ Rajasthan";
$areanames{en}->{912908} = "Amet\,\ Rajasthan";
$areanames{en}->{912909} = "Bhim\/Dawer\,\ Rajasthan";
$areanames{en}->{91291} = "Jodhpur\,\ Rajasthan";
$areanames{en}->{912920} = "Bilara\/Bhopalgarh\,\ Rajasthan";
$areanames{en}->{912921} = "Phalodi\/Bap\,\ Rajasthan";
$areanames{en}->{912922} = "Osian\,\ Rajasthan";
$areanames{en}->{912923} = "Phalodi\/Lohawat\,\ Rajasthan";
$areanames{en}->{912924} = "Phalodi\/Baroo\,\ Rajasthan";
$areanames{en}->{912925} = "Phalodi\,\ Rajasthan";
$areanames{en}->{912926} = "Osian\/Mathania\,\ Rajasthan";
$areanames{en}->{912927} = "Osian\/Dhanwara\,\ Rajasthan";
$areanames{en}->{912928} = "Shergarh\/Deechu\,\ Rajasthan";
$areanames{en}->{912929} = "Shergarh\/Balesar\,\ Rajasthan";
$areanames{en}->{912930} = "Bilara\/Piparcity\,\ Rajasthan";
$areanames{en}->{912931} = "Jodhpur\/Jhanwar\,\ Rajasthan";
$areanames{en}->{912932} = "Pali\,\ Rajasthan";
$areanames{en}->{912933} = "Bali\/Sumerpur\,\ Rajasthan";
$areanames{en}->{912934} = "Desuri\/Rani\,\ Rajasthan";
$areanames{en}->{912935} = "Marwar\ Junction\,\ Rajasthan";
$areanames{en}->{912936} = "Pali\/Rohat\,\ Rajasthan";
$areanames{en}->{912937} = "Raipur\,\ Rajasthan";
$areanames{en}->{912938} = "Bali\,\ Rajasthan";
$areanames{en}->{912939} = "Jaitaran\,\ Rajasthan";
$areanames{en}->{91294} = "Udaipur\ Girwa\/Udaipur\,\ Rajasthan";
$areanames{en}->{912950} = "Dhariawad\,\ Rajasthan";
$areanames{en}->{912951} = "Bhim\,\ Rajasthan";
$areanames{en}->{912952} = "Rajsamand\/Kankorli\,\ Rajasthan";
$areanames{en}->{912953} = "Nathdwara\,\ Rajasthan";
$areanames{en}->{912954} = "Kumbalgarh\/Charbhujaji\,\ Rajasthan";
$areanames{en}->{912955} = "Malvi\/Fatehnagar\,\ Rajasthan";
$areanames{en}->{912956} = "Gogunda\,\ Rajasthan";
$areanames{en}->{912957} = "Vallabhnagar\,\ Rajasthan";
$areanames{en}->{912958} = "Kotra\,\ Rajasthan";
$areanames{en}->{912959} = "Jhadol\,\ Rajasthan";
$areanames{en}->{912960} = "Sojat\,\ Rajasthan";
$areanames{en}->{912961} = "Ghatol\,\ Rajasthan";
$areanames{en}->{912962} = "Banswara\,\ Rajasthan";
$areanames{en}->{912963} = "Gerhi\/Partapur\,\ Rajasthan";
$areanames{en}->{912964} = "Dungarpur\,\ Rajasthan";
$areanames{en}->{912965} = "Kushalgarh\,\ Rajasthan";
$areanames{en}->{912966} = "Sagwara\,\ Rajasthan";
$areanames{en}->{912967} = "Aspur\,\ Rajasthan";
$areanames{en}->{912968} = "Bagidora\,\ Rajasthan";
$areanames{en}->{912969} = "Bhinmal\,\ Rajasthan";
$areanames{en}->{912970} = "Sanchore\/Hadecha\,\ Rajasthan";
$areanames{en}->{912971} = "Pindwara\,\ Rajasthan";
$areanames{en}->{912972} = "Sirohi\,\ Rajasthan";
$areanames{en}->{912973} = "Jalore\,\ Rajasthan";
$areanames{en}->{912974} = "Abu\ Road\,\ Rajasthan";
$areanames{en}->{912975} = "Reodar\,\ Rajasthan";
$areanames{en}->{912976} = "Sheoganj\/Posaliyan\,\ Rajasthan";
$areanames{en}->{912977} = "Jalore\/Sayla\,\ Rajasthan";
$areanames{en}->{912978} = "Ahore\,\ Rajasthan";
$areanames{en}->{912979} = "Sanchore\,\ Rajasthan";
$areanames{en}->{912980} = "Pachpadra\/Korna\,\ Rajasthan";
$areanames{en}->{912981} = "Sheo\/Harsani\,\ Rajasthan";
$areanames{en}->{912982} = "Barmer\,\ Rajasthan";
$areanames{en}->{912983} = "Barmer\/Gudda\,\ Rajasthan";
$areanames{en}->{912984} = "Barmer\/Sindari\,\ Rajasthan";
$areanames{en}->{912985} = "Barmer\/Ramsar\,\ Rajasthan";
$areanames{en}->{912986} = "Barmer\/Dhorimanna\,\ Rajasthan";
$areanames{en}->{912987} = "Sheo\,\ Rajasthan";
$areanames{en}->{912988} = "Pachpadra\/Balotra\,\ Rajasthan";
$areanames{en}->{912989} = "Chohtan\,\ Rajasthan";
$areanames{en}->{912990} = "Bhinmal\/Jasawantpura\,\ Rajasthan";
$areanames{en}->{912991} = "Jaisalmer\/Ramgarh\,\ Rajasthan";
$areanames{en}->{912992} = "Jaisalmer\,\ Rajasthan";
$areanames{en}->{912993} = "Jaisalmer\/Devikot\,\ Rajasthan";
$areanames{en}->{912994} = "Pokhran\,\ Rajasthan";
$areanames{en}->{912995} = "Pokhran\/Nachna\,\ Rajasthan";
$areanames{en}->{912996} = "Pokhran\/Loharki\,\ Rajasthan";
$areanames{en}->{912997} = "Jaisalmer\/Mohargarh\,\ Rajasthan";
$areanames{en}->{912998} = "Jaisalmer\/Khuiyals\,\ Rajasthan";
$areanames{en}->{912999} = "Jaisalmer\/Nehdai\,\ Rajasthan";
$areanames{en}->{913010} = "Jaisalmer\/Shahgarh\,\ Rajasthan";
$areanames{en}->{913011} = "Jaisalmer\/Pasewar\,\ Rajasthan";
$areanames{en}->{913012} = "Jaisalmer\/Mehsana\,\ Rajasthan";
$areanames{en}->{913013} = "Jaisalmer\/Dhanaua\,\ Rajasthan";
$areanames{en}->{913014} = "Jaisalmer\/Khuri\,\ Rajasthan";
$areanames{en}->{913015} = "Jaisalmer\/Myajlar\,\ Rajasthan";
$areanames{en}->{913016} = "Jaisalmer\/Jheenjaniyali\,\ Rajasthan";
$areanames{en}->{913017} = "Pokhran\/Madasar\,\ Rajasthan";
$areanames{en}->{913018} = "Jaisalmer\/Sadhna\,\ Rajasthan";
$areanames{en}->{913019} = "Pokhran\/Phalsoond\,\ Rajasthan";
$areanames{en}->{913174} = "Diamond\ Harbour\,\ West\ Bengal";
$areanames{en}->{913192} = "Andaman\ \&\ Nicobar\,\ Andaman\ Islands";
$areanames{en}->{913193} = "Andaman\ \&\ Nicobar\,\ Nicobar\ Islands";
$areanames{en}->{913210} = "Kakdwip\,\ West\ Bengal";
$areanames{en}->{913211} = "Arambag\,\ West\ Bengal";
$areanames{en}->{913212} = "Champadanga\,\ West\ Bengal";
$areanames{en}->{913213} = "Dhaniakhali\,\ West\ Bengal";
$areanames{en}->{913214} = "Jagatballavpur\,\ West\ Bengal";
$areanames{en}->{913215} = "Bongoan\,\ West\ Bengal";
$areanames{en}->{913216} = "Habra\,\ West\ Bengal";
$areanames{en}->{913217} = "Basirhat\,\ West\ Bengal";
$areanames{en}->{913218} = "Canning\,\ West\ Bengal";
$areanames{en}->{913220} = "Contai\,\ West\ Bengal";
$areanames{en}->{913221} = "Jhargram\,\ West\ Bengal";
$areanames{en}->{913222} = "Kharagpur\,\ West\ Bengal";
$areanames{en}->{913223} = "Nayagarh\/Kultikri\,\ West\ Bengal";
$areanames{en}->{913224} = "Haldia\,\ West\ Bengal";
$areanames{en}->{913225} = "Ghatal\,\ West\ Bengal";
$areanames{en}->{913227} = "Amlagora\,\ West\ Bengal";
$areanames{en}->{913228} = "Tamluk\,\ West\ Bengal";
$areanames{en}->{913229} = "Dantan\,\ West\ Bengal";
$areanames{en}->{913241} = "Gangajalghati\,\ West\ Bengal";
$areanames{en}->{913242} = "Bankura\,\ West\ Bengal";
$areanames{en}->{913243} = "Khatra\,\ West\ Bengal";
$areanames{en}->{913244} = "Bishnupur\,\ West\ Bengal";
$areanames{en}->{913251} = "Adra\,\ West\ Bengal";
$areanames{en}->{913252} = "Purulia\,\ West\ Bengal";
$areanames{en}->{913253} = "Manbazar\,\ West\ Bengal";
$areanames{en}->{913254} = "Jhalda\,\ West\ Bengal";
$areanames{en}->{91326} = "Dhanbad\,\ Bihar";
$areanames{en}->{9133} = "Kolkata\,\ West\ Bengal";
$areanames{en}->{91341} = "Asansol\,\ West\ Bengal";
$areanames{en}->{91342} = "Burdwan\,\ West\ Bengal";
$areanames{en}->{91343} = "Durgapur\,\ West\ Bengal";
$areanames{en}->{913451} = "Seharabazar\,\ West\ Bengal";
$areanames{en}->{913452} = "Guskara\,\ West\ Bengal";
$areanames{en}->{913453} = "Katwa\,\ West\ Bengal";
$areanames{en}->{913454} = "Kalna\,\ West\ Bengal";
$areanames{en}->{913461} = "Rampur\ Hat\,\ West\ Bengal";
$areanames{en}->{913462} = "Suri\,\ West\ Bengal";
$areanames{en}->{913463} = "Bolpur\,\ West\ Bengal";
$areanames{en}->{913465} = "Nalhati\,\ West\ Bengal";
$areanames{en}->{913471} = "Karimpur\,\ West\ Bengal";
$areanames{en}->{913472} = "Krishna\ Nagar\,\ West\ Bengal";
$areanames{en}->{913473} = "Ranaghat\,\ West\ Bengal";
$areanames{en}->{913474} = "Bethuadahari\,\ West\ Bengal";
$areanames{en}->{913481} = "Islampur\,\ West\ Bengal";
$areanames{en}->{913482} = "Berhampur\,\ West\ Bengal";
$areanames{en}->{913483} = "Murshidabad\/Jiaganj\,\ West\ Bengal";
$areanames{en}->{913484} = "Kandi\,\ West\ Bengal";
$areanames{en}->{913485} = "Dhuliyan\,\ West\ Bengal";
$areanames{en}->{913511} = "Bubulchandi\,\ West\ Bengal";
$areanames{en}->{913512} = "Malda\,\ West\ Bengal";
$areanames{en}->{913513} = "Harishchandrapur\,\ West\ Bengal";
$areanames{en}->{913521} = "Gangarampur\,\ West\ Bengal";
$areanames{en}->{913522} = "Balurghat\,\ West\ Bengal";
$areanames{en}->{913523} = "Raiganj\,\ West\ Bengal";
$areanames{en}->{913524} = "Harirampur\,\ West\ Bengal";
$areanames{en}->{913525} = "Dalkhola\,\ West\ Bengal";
$areanames{en}->{913526} = "Islampur\,\ West\ Bengal";
$areanames{en}->{91353} = "Siliguri\,\ West\ Bengal";
$areanames{en}->{91354} = "Darjeeling\,\ West\ Bengal";
$areanames{en}->{913552} = "Kalimpong\,\ West\ Bengal";
$areanames{en}->{913561} = "Jalpaiguri\,\ West\ Bengal";
$areanames{en}->{913562} = "Mal\ Bazar\,\ West\ Bengal";
$areanames{en}->{913563} = "Birpara\,\ West\ Bengal";
$areanames{en}->{913564} = "Alipurduar\,\ West\ Bengal";
$areanames{en}->{913565} = "Nagarakata\,\ West\ Bengal";
$areanames{en}->{913566} = "Kalchini\,\ West\ Bengal";
$areanames{en}->{913581} = "Dinhata\,\ West\ Bengal";
$areanames{en}->{913582} = "Coochbehar\,\ West\ Bengal";
$areanames{en}->{913583} = "Mathabhanga\,\ West\ Bengal";
$areanames{en}->{913584} = "Mekhliganj\,\ West\ Bengal";
$areanames{en}->{913592} = "Gangtok\,\ West\ Bengal";
$areanames{en}->{913595} = "Gauzing\/Nayabazar\,\ West\ Bengal";
$areanames{en}->{91360} = "Itanagar\/Ziro\,\ Arunachal\ Pradesh";
$areanames{en}->{91361} = "Guwahati\,\ Assam";
$areanames{en}->{913621} = "Boko\,\ Assam";
$areanames{en}->{913623} = "Barama\,\ Assam";
$areanames{en}->{913624} = "Nalbari\,\ Assam";
$areanames{en}->{913637} = "Cherrapunjee\,\ Meghalaya";
$areanames{en}->{913638} = "Nongpoh\,\ Meghalaya";
$areanames{en}->{913639} = "Baghmara\,\ Meghalaya";
$areanames{en}->{91364} = "Shillong\,\ Meghalaya";
$areanames{en}->{913650} = "Dadengiri\/Phulbari\,\ Meghalaya";
$areanames{en}->{913651} = "Tura\,\ Meghalaya";
$areanames{en}->{913652} = "Jowai\,\ Meghalaya";
$areanames{en}->{913653} = "Amlarem\/Dawki\,\ Meghalaya";
$areanames{en}->{913654} = "Nongstoin\,\ Meghalaya";
$areanames{en}->{913655} = "Khliehriat\,\ Meghalaya";
$areanames{en}->{913656} = "Mawkyrwat\,\ Meghalaya";
$areanames{en}->{913657} = "Mairang\,\ Meghalaya";
$areanames{en}->{913658} = "Williamnagar\,\ Meghalaya";
$areanames{en}->{913659} = "Resubelpara\/Mendipathar\,\ Meghalaya";
$areanames{en}->{913661} = "Kokrajhar\,\ Assam";
$areanames{en}->{913662} = "Dhubri\,\ Assam";
$areanames{en}->{913663} = "Goalpara\,\ Assam";
$areanames{en}->{913664} = "Hajo\,\ Assam";
$areanames{en}->{913665} = "Tarabarihat\,\ Assam";
$areanames{en}->{913666} = "Barpeta\ Road\,\ Assam";
$areanames{en}->{913667} = "Bilasipara\,\ Assam";
$areanames{en}->{913668} = "Bijni\,\ Assam";
$areanames{en}->{913669} = "Abhayapuri\,\ Assam";
$areanames{en}->{913670} = "Maibong\,\ Assam";
$areanames{en}->{913671} = "Diphu\,\ Assam";
$areanames{en}->{913672} = "Nagaon\,\ Assam";
$areanames{en}->{913673} = "Haflong\,\ Assam";
$areanames{en}->{913674} = "Hojai\,\ Assam";
$areanames{en}->{913675} = "Bokajan\,\ Assam";
$areanames{en}->{913676} = "Howraghat\,\ Assam";
$areanames{en}->{913677} = "Baithalangshu\,\ Assam";
$areanames{en}->{913678} = "Morigaon\,\ Assam";
$areanames{en}->{91368} = "Passighat\,\ Arunachal\ Pradesh";
$areanames{en}->{91369} = "Mokokchung\,\ Nagaland";
$areanames{en}->{91370} = "Kohima\,\ Nagaland";
$areanames{en}->{913711} = "Udalguri\,\ Assam";
$areanames{en}->{913712} = "Tezpur\,\ Assam";
$areanames{en}->{913713} = "Mangaldoi\,\ Assam";
$areanames{en}->{913714} = "Rangapara\,\ Assam";
$areanames{en}->{913715} = "Gohpur\,\ Assam";
$areanames{en}->{91372} = "Lungleh\,\ Mizoram";
$areanames{en}->{91373} = "Dibrugarh\,\ Assam";
$areanames{en}->{91374} = "Tinsukhia\,\ Assam";
$areanames{en}->{913751} = "Digboi\,\ Assam";
$areanames{en}->{913752} = "Lakhimpur\,\ Assam";
$areanames{en}->{913753} = "Dhemaji\,\ Assam";
$areanames{en}->{913754} = "Moranhat\,\ Assam";
$areanames{en}->{913756} = "Sadiya\,\ Assam";
$areanames{en}->{913758} = "Dhakuakhana\,\ Assam";
$areanames{en}->{913759} = "Bihupuria\,\ Assam";
$areanames{en}->{91376} = "Jorhat\,\ Assam";
$areanames{en}->{913771} = "Mariani\,\ Assam";
$areanames{en}->{913772} = "Sibsagar\,\ Assam";
$areanames{en}->{913774} = "Golaghat\,\ Assam";
$areanames{en}->{913775} = "Majuli\,\ Assam";
$areanames{en}->{913776} = "Bokakhat\,\ Assam";
$areanames{en}->{913777} = "Yangkiyang\,\ Arunachal\ Pradesh";
$areanames{en}->{913778} = "Pakkekesang\,\ Arunachal\ Pradesh";
$areanames{en}->{913779} = "Roing\/Mariso\,\ Arunachal\ Pradesh";
$areanames{en}->{913780} = "Dirang\,\ Arunachal\ Pradesh";
$areanames{en}->{913782} = "Kalaktung\/Bomdila\,\ Arunachal\ Pradesh";
$areanames{en}->{913783} = "Along\,\ Arunachal\ Pradesh";
$areanames{en}->{913784} = "Nefra\,\ Arunachal\ Pradesh";
$areanames{en}->{913785} = "Bameng\,\ Arunachal\ Pradesh";
$areanames{en}->{913786} = "Khonsa\,\ Arunachal\ Pradesh";
$areanames{en}->{913787} = "Seppa\,\ Arunachal\ Pradesh";
$areanames{en}->{913788} = "Kolaring\,\ Arunachal\ Pradesh";
$areanames{en}->{913789} = "Huri\,\ Arunachal\ Pradesh";
$areanames{en}->{913790} = "Tali\,\ Arunachal\ Pradesh";
$areanames{en}->{913791} = "Taliha\,\ Arunachal\ Pradesh";
$areanames{en}->{913792} = "Daporizo\,\ Arunachal\ Pradesh";
$areanames{en}->{913793} = "Mechuka\,\ Arunachal\ Pradesh";
$areanames{en}->{913794} = "Tawang\,\ Arunachal\ Pradesh";
$areanames{en}->{913795} = "Basar\,\ Arunachal\ Pradesh";
$areanames{en}->{913797} = "Pangin\,\ Arunachal\ Pradesh";
$areanames{en}->{913798} = "Mariyang\,\ Arunachal\ Pradesh";
$areanames{en}->{913799} = "Tuting\,\ Arunachal\ Pradesh";
$areanames{en}->{913800} = "Jairampur\,\ Arunachal\ Pradesh";
$areanames{en}->{913801} = "Anini\,\ Arunachal\ Pradesh";
$areanames{en}->{913802} = "Roing\/Arda\,\ Arunachal\ Pradesh";
$areanames{en}->{913803} = "Roing\,\ Arunachal\ Pradesh";
$areanames{en}->{913804} = "Tezu\,\ Arunachal\ Pradesh";
$areanames{en}->{913805} = "Hayuliang\,\ Arunachal\ Pradesh";
$areanames{en}->{913806} = "Chowkhem\,\ Arunachal\ Pradesh";
$areanames{en}->{913807} = "Miao\,\ Arunachal\ Pradesh";
$areanames{en}->{913808} = "Changlang\,\ Arunachal\ Pradesh";
$areanames{en}->{913809} = "Sagalee\,\ Arunachal\ Pradesh";
$areanames{en}->{91381} = "Agartala\,\ Tripura";
$areanames{en}->{913821} = "R\.K\.Pur\,\ Tripura";
$areanames{en}->{913822} = "Dharam\ Nagar\,\ Tripura";
$areanames{en}->{913823} = "Belonia\,\ Tripura";
$areanames{en}->{913824} = "Kailsahar\,\ Tripura";
$areanames{en}->{913825} = "Khowai\,\ Tripura";
$areanames{en}->{913826} = "Ambasa\,\ Tripura";
$areanames{en}->{913830} = "Champai\/Chiapui\,\ Mizoram";
$areanames{en}->{913831} = "Champa\,\ Mizoram";
$areanames{en}->{913834} = "Demagiri\,\ Mizoram";
$areanames{en}->{913835} = "Saiha\,\ Mizoram";
$areanames{en}->{913836} = "Saiha\/Tuipang\,\ Mizoram";
$areanames{en}->{913837} = "Kolasib\,\ Mizoram";
$areanames{en}->{913838} = "Aizwal\/Serchip\,\ Mizoram";
$areanames{en}->{913839} = "Jalukie\,\ Nagaland";
$areanames{en}->{913841} = "Vdarbondh\,\ Assam";
$areanames{en}->{913842} = "Silchar\,\ Assam";
$areanames{en}->{913843} = "Karimganj\,\ Assam";
$areanames{en}->{913844} = "Hailakandi\,\ Assam";
$areanames{en}->{913845} = "Ukhrul\ Central\,\ Manipur";
$areanames{en}->{913848} = "Thonbal\,\ Manipur";
$areanames{en}->{91385} = "Imphal\,\ Manipur";
$areanames{en}->{913860} = "Wokha\,\ Nagaland";
$areanames{en}->{913861} = "Tuengsang\,\ Nagaland";
$areanames{en}->{913862} = "Dimapur\,\ Nagaland";
$areanames{en}->{913863} = "Kiphire\,\ Nagaland";
$areanames{en}->{913865} = "Phek\,\ Nagaland";
$areanames{en}->{913867} = "Zuenheboto\,\ Nagaland";
$areanames{en}->{913869} = "Mon\,\ Nagaland";
$areanames{en}->{913870} = "Ukhrursouth\/Kassemkhulen\,\ Manipur";
$areanames{en}->{913871} = "Mao\/Korang\,\ Manipur";
$areanames{en}->{913872} = "Chandel\,\ Manipur";
$areanames{en}->{913873} = "Thinghat\,\ Manipur";
$areanames{en}->{913874} = "Churchandpur\,\ Manipur";
$areanames{en}->{913876} = "Jiribam\,\ Manipur";
$areanames{en}->{913877} = "Tamenglong\,\ Manipur";
$areanames{en}->{913878} = "Chakpikarong\,\ Manipur";
$areanames{en}->{913879} = "Bishenpur\,\ Manipur";
$areanames{en}->{913880} = "Sadarhills\/Kangpokai\,\ Manipur";
$areanames{en}->{91389} = "Aizawal\,\ Mizoram";
$areanames{en}->{9140} = "Hyderabad\ Local\,\ Andhra\ Pradesh";
$areanames{en}->{914111} = "Sriperumbudur\,\ Tamil\ Nadu";
$areanames{en}->{914112} = "Kancheepuram\,\ Tamil\ Nadu";
$areanames{en}->{914114} = "Chengalpattu\,\ Tamil\ Nadu";
$areanames{en}->{914115} = "Madurantakam\,\ Tamil\ Nadu";
$areanames{en}->{914116} = "Tiruvallur\,\ Tamil\ Nadu";
$areanames{en}->{914118} = "Tiruttani\,\ Tamil\ Nadu";
$areanames{en}->{914119} = "Ponneri\,\ Tamil\ Nadu";
$areanames{en}->{91413} = "Pondicherry\,\ Tamil\ Nadu";
$areanames{en}->{914142} = "Cuddalore\,\ Tamil\ Nadu";
$areanames{en}->{914143} = "Virudhachalam\,\ Tamil\ Nadu";
$areanames{en}->{914144} = "Chidambaram\,\ Tamil\ Nadu";
$areanames{en}->{914145} = "Gingee\,\ Tamil\ Nadu";
$areanames{en}->{914146} = "Villupuram\,\ Tamil\ Nadu";
$areanames{en}->{914147} = "Tindivanam\,\ Tamil\ Nadu";
$areanames{en}->{914149} = "Ulundurpet\,\ Tamil\ Nadu";
$areanames{en}->{914151} = "Kallakurichi\,\ Tamil\ Nadu";
$areanames{en}->{914153} = "Arakandanallur\,\ Tamil\ Nadu";
$areanames{en}->{91416} = "Vellore\,\ Tamil\ Nadu";
$areanames{en}->{914171} = "Gudiyatham\,\ Tamil\ Nadu";
$areanames{en}->{914172} = "Ranipet\,\ Tamil\ Nadu";
$areanames{en}->{914173} = "Arni\,\ Tamil\ Nadu";
$areanames{en}->{914174} = "Vaniyambadi\,\ Tamil\ Nadu";
$areanames{en}->{914175} = "Tiruvannamalai\,\ Tamil\ Nadu";
$areanames{en}->{914177} = "Arkonam\,\ Tamil\ Nadu";
$areanames{en}->{914179} = "Tirupattur\,\ Tamil\ Nadu";
$areanames{en}->{914181} = "Polur\,\ Tamil\ Nadu";
$areanames{en}->{914182} = "Tiruvettipuram\,\ Tamil\ Nadu";
$areanames{en}->{914183} = "Vandavasi\,\ Tamil\ Nadu";
$areanames{en}->{914188} = "Chengam\,\ Tamil\ Nadu";
$areanames{en}->{914202} = "Mulanur\,\ Tamil\ Nadu";
$areanames{en}->{914204} = "Kodumudi\,\ Tamil\ Nadu";
$areanames{en}->{91421} = "Tirupur\,\ Tamil\ Nadu";
$areanames{en}->{91422} = "Coimbatore\,\ Tamil\ Nadu";
$areanames{en}->{91423} = "Udhagamandalam\,\ Tamil\ Nadu";
$areanames{en}->{91424} = "Erode\,\ Tamil\ Nadu";
$areanames{en}->{914252} = "Udumalpet\,\ Tamil\ Nadu";
$areanames{en}->{914253} = "Anamalai\,\ Tamil\ Nadu";
$areanames{en}->{914254} = "Mettupalayam\,\ Tamil\ Nadu";
$areanames{en}->{914255} = "Palladam\,\ Tamil\ Nadu";
$areanames{en}->{914256} = "Bhavani\,\ Tamil\ Nadu";
$areanames{en}->{914257} = "Kangeyam\,\ Tamil\ Nadu";
$areanames{en}->{914258} = "Dharampuram\,\ Tamil\ Nadu";
$areanames{en}->{914259} = "Pollachi\,\ Tamil\ Nadu";
$areanames{en}->{914262} = "Gudalur\,\ Tamil\ Nadu";
$areanames{en}->{914266} = "Kotagiri\,\ Tamil\ Nadu";
$areanames{en}->{914268} = "Velur\,\ Tamil\ Nadu";
$areanames{en}->{91427} = "Salem\,\ Tamil\ Nadu";
$areanames{en}->{914281} = "Yercaud\,\ Tamil\ Nadu";
$areanames{en}->{914282} = "Attur\,\ Tamil\ Nadu";
$areanames{en}->{914283} = "Sankagiri\,\ Tamil\ Nadu";
$areanames{en}->{914285} = "Gobichettipalayam\,\ Tamil\ Nadu";
$areanames{en}->{914286} = "Namakkal\,\ Tamil\ Nadu";
$areanames{en}->{914287} = "Rasipuram\,\ Tamil\ Nadu";
$areanames{en}->{914288} = "Tiruchengode\,\ Tamil\ Nadu";
$areanames{en}->{914290} = "Omalur\,\ Tamil\ Nadu";
$areanames{en}->{914292} = "Valapady\,\ Tamil\ Nadu";
$areanames{en}->{914294} = "Perundurai\,\ Tamil\ Nadu";
$areanames{en}->{914295} = "Sathiyamangalam\,\ Tamil\ Nadu";
$areanames{en}->{914296} = "Avanashi\,\ Tamil\ Nadu";
$areanames{en}->{914298} = "Metturdam\,\ Tamil\ Nadu";
$areanames{en}->{91431} = "Tiruchchirappalli\,\ Tamil\ Nadu";
$areanames{en}->{914320} = "Aravakurichi\,\ Tamil\ Nadu";
$areanames{en}->{914322} = "Pudukkottai\,\ Tamil\ Nadu";
$areanames{en}->{914323} = "Kulithalai\,\ Tamil\ Nadu";
$areanames{en}->{914324} = "Karur\,\ Tamil\ Nadu";
$areanames{en}->{914326} = "Musiri\,\ Tamil\ Nadu";
$areanames{en}->{914327} = "Thuraiyur\,\ Tamil\ Nadu";
$areanames{en}->{914328} = "Perambalur\,\ Tamil\ Nadu";
$areanames{en}->{914329} = "Ariyalur\,\ Tamil\ Nadu";
$areanames{en}->{914331} = "Jayamkondan\,\ Tamil\ Nadu";
$areanames{en}->{914332} = "Manaparai\,\ Tamil\ Nadu";
$areanames{en}->{914333} = "Ponnamaravathi\,\ Tamil\ Nadu";
$areanames{en}->{914339} = "Keeranur\,\ Tamil\ Nadu";
$areanames{en}->{914341} = "Uthangarai\,\ Tamil\ Nadu";
$areanames{en}->{914342} = "Dharmapuri\,\ Tamil\ Nadu";
$areanames{en}->{914343} = "Krishnagiri\,\ Tamil\ Nadu";
$areanames{en}->{914344} = "Hosur\,\ Tamil\ Nadu";
$areanames{en}->{914346} = "Harur\,\ Tamil\ Nadu";
$areanames{en}->{914347} = "Denkanikota\,\ Tamil\ Nadu";
$areanames{en}->{914348} = "Palakkodu\,\ Tamil\ Nadu";
$areanames{en}->{91435} = "Kumbakonam\,\ Tamil\ Nadu";
$areanames{en}->{914362} = "Thanjavur\,\ Tamil\ Nadu";
$areanames{en}->{914364} = "Mayiladuthurai\,\ Tamil\ Nadu";
$areanames{en}->{914365} = "Nagapattinam\,\ Tamil\ Nadu";
$areanames{en}->{914366} = "Tiruvarur\,\ Tamil\ Nadu";
$areanames{en}->{914367} = "Mannargudi\,\ Tamil\ Nadu";
$areanames{en}->{914368} = "Karaikal\,\ Tamil\ Nadu";
$areanames{en}->{914369} = "Thiruthuraipoondi\,\ Tamil\ Nadu";
$areanames{en}->{914371} = "Arantangi\,\ Tamil\ Nadu";
$areanames{en}->{914372} = "Orathanad\,\ Tamil\ Nadu";
$areanames{en}->{914373} = "Pattukottai\,\ Tamil\ Nadu";
$areanames{en}->{914374} = "Papanasam\,\ Tamil\ Nadu";
$areanames{en}->{9144} = "Chennai\,\ Tamil\ Nadu";
$areanames{en}->{91451} = "Dindigul\,\ Tamil\ Nadu";
$areanames{en}->{91452} = "Madurai\,\ Tamil\ Nadu";
$areanames{en}->{914542} = "Kodaikanal\,\ Tamil\ Nadu";
$areanames{en}->{914543} = "Batlagundu\,\ Tamil\ Nadu";
$areanames{en}->{914544} = "Natham\,\ Tamil\ Nadu";
$areanames{en}->{914545} = "Palani\,\ Tamil\ Nadu";
$areanames{en}->{914546} = "Theni\,\ Tamil\ Nadu";
$areanames{en}->{914549} = "Thirumanglam\,\ Tamil\ Nadu";
$areanames{en}->{914551} = "Vedasandur\,\ Tamil\ Nadu";
$areanames{en}->{914552} = "Usilampatti\,\ Tamil\ Nadu";
$areanames{en}->{914553} = "Oddanchatram\,\ Tamil\ Nadu";
$areanames{en}->{914554} = "Cumbum\,\ Tamil\ Nadu";
$areanames{en}->{914561} = "Devakottai\,\ Tamil\ Nadu";
$areanames{en}->{914562} = "Virudhunagar\,\ Tamil\ Nadu";
$areanames{en}->{914563} = "Rajapalayam\,\ Tamil\ Nadu";
$areanames{en}->{914564} = "Paramakudi\,\ Tamil\ Nadu";
$areanames{en}->{914565} = "Karaikudi\,\ Tamil\ Nadu";
$areanames{en}->{914566} = "Aruppukottai\,\ Tamil\ Nadu";
$areanames{en}->{914567} = "Ramanathpuram\,\ Tamil\ Nadu";
$areanames{en}->{914573} = "Rameshwaram\,\ Tamil\ Nadu";
$areanames{en}->{914574} = "Manamadurai\,\ Tamil\ Nadu";
$areanames{en}->{914575} = "Sivaganga\,\ Tamil\ Nadu";
$areanames{en}->{914576} = "Mudukulathur\,\ Tamil\ Nadu";
$areanames{en}->{914577} = "Tirupathur\,\ Tamil\ Nadu";
$areanames{en}->{91460} = "Taliparamba\,\ Kerala";
$areanames{en}->{91461} = "Thoothukudi\,\ Tamil\ Nadu";
$areanames{en}->{91462} = "Tirunelvelli\,\ Tamil\ Nadu";
$areanames{en}->{914630} = "Srivaikundam\,\ Tamil\ Nadu";
$areanames{en}->{914632} = "Kovilpatti\,\ Tamil\ Nadu";
$areanames{en}->{914633} = "Tenkasi\,\ Tamil\ Nadu";
$areanames{en}->{914634} = "Ambasamudram\,\ Tamil\ Nadu";
$areanames{en}->{914635} = "Nanguneri\,\ Tamil\ Nadu";
$areanames{en}->{914636} = "Sankarankovil\,\ Tamil\ Nadu";
$areanames{en}->{914637} = "Valliyoor\,\ Tamil\ Nadu";
$areanames{en}->{914638} = "Vilathikulam\,\ Tamil\ Nadu";
$areanames{en}->{914639} = "Tiruchendur\,\ Tamil\ Nadu";
$areanames{en}->{914651} = "Kuzhithurai\,\ Tamil\ Nadu";
$areanames{en}->{914652} = "Nagercoil\,\ Tamil\ Nadu";
$areanames{en}->{91469} = "Tiruvalla\,\ Kerala";
$areanames{en}->{91470} = "Attingal\,\ Kerala";
$areanames{en}->{91471} = "Thiruvananthapuram\,\ Kerala";
$areanames{en}->{914728} = "Nedumangad\,\ Kerala";
$areanames{en}->{914733} = "Pathanamthitta\,\ Kerala";
$areanames{en}->{914734} = "Adoor\,\ Kerala";
$areanames{en}->{914735} = "Ranni\,\ Kerala";
$areanames{en}->{91474} = "Kollam\,\ Kerala";
$areanames{en}->{91475} = "Punalur\,\ Kerala";
$areanames{en}->{91476} = "Karunagapally\,\ Kerala";
$areanames{en}->{91477} = "Alappuzha\,\ Kerala";
$areanames{en}->{91478} = "Cherthala\,\ Kerala";
$areanames{en}->{91479} = "Mavelikkara\,\ Kerala";
$areanames{en}->{91480} = "Irinjalakuda\,\ Kerala";
$areanames{en}->{91481} = "Kottayam\,\ Kerala";
$areanames{en}->{914822} = "Palai\,\ Kerala";
$areanames{en}->{914828} = "Kanjirapally\,\ Kerala";
$areanames{en}->{914829} = "Vaikom\,\ Kerala";
$areanames{en}->{91483} = "Manjeri\,\ Kerala";
$areanames{en}->{91484} = "Ernakulam\,\ Kerala";
$areanames{en}->{91485} = "Muvattupuzha\,\ Kerala";
$areanames{en}->{914862} = "Thodupuzha\,\ Kerala";
$areanames{en}->{914864} = "Adimaly\,\ Kerala";
$areanames{en}->{914865} = "Munnar\,\ Kerala";
$areanames{en}->{914868} = "Nedumkandam\,\ Kerala";
$areanames{en}->{914869} = "Peermedu\,\ Kerala";
$areanames{en}->{91487} = "Thrissur\,\ Kerala";
$areanames{en}->{914884} = "Vadakkanchery\,\ Kerala";
$areanames{en}->{914885} = "Kunnamkulam\,\ Kerala";
$areanames{en}->{914890} = "Bitra\,\ Lakshadweep";
$areanames{en}->{914891} = "Amini\,\ Lakshadweep";
$areanames{en}->{914892} = "Minicoy\,\ Lakshadweep";
$areanames{en}->{914893} = "Androth\,\ Lakshadweep";
$areanames{en}->{914894} = "Agathy\,\ Lakshadweep";
$areanames{en}->{914895} = "Kalpeni\,\ Lakshadweep";
$areanames{en}->{914896} = "Kavaratti\,\ Lakshadweep";
$areanames{en}->{914897} = "Kadamath\,\ Lakshadweep";
$areanames{en}->{914898} = "Kiltan\,\ Lakshadweep";
$areanames{en}->{914899} = "Chetlat\,\ Lakshadweep";
$areanames{en}->{91490} = "Tellicherry\,\ Kerala";
$areanames{en}->{91491} = "Palakkad\,\ Kerala";
$areanames{en}->{914922} = "Alathur\,\ Kerala";
$areanames{en}->{914923} = "Koduvayur\,\ Kerala";
$areanames{en}->{914924} = "Mannarkad\,\ Kerala";
$areanames{en}->{914926} = "Shoranur\,\ Kerala";
$areanames{en}->{914931} = "Nilambur\,\ Kerala";
$areanames{en}->{914933} = "Perinthalmanna\,\ Kerala";
$areanames{en}->{914935} = "Mananthavady\,\ Kerala";
$areanames{en}->{914936} = "Kalpetta\,\ Kerala";
$areanames{en}->{91494} = "Tirur\,\ Kerala";
$areanames{en}->{91495} = "Kozhikode\,\ Kerala";
$areanames{en}->{91496} = "Vatakara\,\ Kerala";
$areanames{en}->{91497} = "Kannur\,\ Kerala";
$areanames{en}->{914982} = "Taliparamba\,\ Kerala";
$areanames{en}->{914985} = "Payyanur\,\ Kerala";
$areanames{en}->{914994} = "Kasaragod\,\ Kerala";
$areanames{en}->{914997} = "Kanhangad\,\ Kerala";
$areanames{en}->{914998} = "Uppala\,\ Kerala";
$areanames{en}->{915111} = "Akbarpur\,\ Uttar\ Pradesh";
$areanames{en}->{915112} = "Bilhaur\,\ Uttar\ Pradesh";
$areanames{en}->{915113} = "Bhognipur\/Pakhrayan\,\ Uttar\ Pradesh";
$areanames{en}->{915114} = "Derapur\/Jhinjak\,\ Uttar\ Pradesh";
$areanames{en}->{915115} = "Ghatampur\,\ Uttar\ Pradesh";
$areanames{en}->{91512} = "Kanpur\,\ Uttar\ Pradesh";
$areanames{en}->{915142} = "Purwa\/Bighapur\,\ Uttar\ Pradesh";
$areanames{en}->{915143} = "Hasanganj\,\ Uttar\ Pradesh";
$areanames{en}->{915144} = "Safipur\,\ Uttar\ Pradesh";
$areanames{en}->{91515} = "Unnao\,\ Uttar\ Pradesh";
$areanames{en}->{915162} = "Orai\,\ Uttar\ Pradesh";
$areanames{en}->{915164} = "Kalpi\,\ Uttar\ Pradesh";
$areanames{en}->{915165} = "Konch\,\ Uttar\ Pradesh";
$areanames{en}->{915168} = "Jalaun\,\ Uttar\ Pradesh";
$areanames{en}->{915170} = "Chirgaon\/Moth\,\ Uttar\ Pradesh";
$areanames{en}->{915171} = "Garauth\,\ Uttar\ Pradesh";
$areanames{en}->{915172} = "Mehraun\,\ Uttar\ Pradesh";
$areanames{en}->{915174} = "Jhansi\,\ Uttar\ Pradesh";
$areanames{en}->{915175} = "Lalitpur\/Talbehat\,\ Uttar\ Pradesh";
$areanames{en}->{915176} = "Lalitpur\,\ Uttar\ Pradesh";
$areanames{en}->{915178} = "Mauranipur\,\ Uttar\ Pradesh";
$areanames{en}->{915180} = "Fatehpur\,\ Uttar\ Pradesh";
$areanames{en}->{915181} = "Bindki\,\ Uttar\ Pradesh";
$areanames{en}->{915182} = "Khaga\,\ Uttar\ Pradesh";
$areanames{en}->{915183} = "Fatehpur\/Gazipur\,\ Uttar\ Pradesh";
$areanames{en}->{915190} = "Baberu\,\ Uttar\ Pradesh";
$areanames{en}->{915191} = "Naraini\/Attarra\,\ Uttar\ Pradesh";
$areanames{en}->{915192} = "Banda\,\ Uttar\ Pradesh";
$areanames{en}->{915194} = "Karvi\/Manikpur\,\ Uttar\ Pradesh";
$areanames{en}->{915195} = "Mau\/Rajapur\,\ Uttar\ Pradesh";
$areanames{en}->{915198} = "Karvi\,\ Uttar\ Pradesh";
$areanames{en}->{915212} = "Malihabad\,\ Uttar\ Pradesh";
$areanames{en}->{91522} = "Lucknow\,\ Uttar\ Pradesh";
$areanames{en}->{915240} = "Fatehpur\,\ Uttar\ Pradesh";
$areanames{en}->{915241} = "Ramsanehi\ Ghat\,\ Uttar\ Pradesh";
$areanames{en}->{915244} = "Haidergarh\,\ Uttar\ Pradesh";
$areanames{en}->{915248} = "Barabanki\,\ Uttar\ Pradesh";
$areanames{en}->{915250} = "Bahraich\/Bhinga\,\ Uttar\ Pradesh";
$areanames{en}->{915251} = "Kaisarganj\/Kaiserganj\,\ Uttar\ Pradesh";
$areanames{en}->{915252} = "Bahraich\/Bahrailh\,\ Uttar\ Pradesh";
$areanames{en}->{915253} = "Nanpara\,\ Uttar\ Pradesh";
$areanames{en}->{915254} = "Nanparah\/Mihinpurwa\,\ Uttar\ Pradesh";
$areanames{en}->{915255} = "Kaisarganh\/Mahasi\,\ Uttar\ Pradesh";
$areanames{en}->{915260} = "Tarabganj\,\ Uttar\ Pradesh";
$areanames{en}->{915261} = "Tarabganj\/Colonelganj\,\ Uttar\ Pradesh";
$areanames{en}->{915262} = "Gonda\,\ Uttar\ Pradesh";
$areanames{en}->{915263} = "Balarampur\/Balrampur\,\ Uttar\ Pradesh";
$areanames{en}->{915264} = "Balarampur\/Tulsipur\,\ Uttar\ Pradesh";
$areanames{en}->{915265} = "Utraula\,\ Uttar\ Pradesh";
$areanames{en}->{915270} = "Bikapur\,\ Uttar\ Pradesh";
$areanames{en}->{915271} = "Akbarpur\,\ Uttar\ Pradesh";
$areanames{en}->{915273} = "Tandai\/Tanda\,\ Uttar\ Pradesh";
$areanames{en}->{915274} = "Tanda\/Baskhari\,\ Uttar\ Pradesh";
$areanames{en}->{915275} = "Akbarpur\/Jalalpur\,\ Uttar\ Pradesh";
$areanames{en}->{915278} = "Faizabad\,\ Uttar\ Pradesh";
$areanames{en}->{915280} = "Rath\,\ Uttar\ Pradesh";
$areanames{en}->{915281} = "Mahoba\,\ Uttar\ Pradesh";
$areanames{en}->{915282} = "Hamirpur\,\ Uttar\ Pradesh";
$areanames{en}->{915283} = "Charkhari\,\ Uttar\ Pradesh";
$areanames{en}->{915284} = "Maudaha\,\ Uttar\ Pradesh";
$areanames{en}->{915311} = "Salon\,\ Uttar\ Pradesh";
$areanames{en}->{915313} = "Salon\/Jais\,\ Uttar\ Pradesh";
$areanames{en}->{915315} = "Dalmau\/Lalganj\,\ Uttar\ Pradesh";
$areanames{en}->{915317} = "Dalmau\,\ Uttar\ Pradesh";
$areanames{en}->{91532} = "Allahabad\,\ Uttar\ Pradesh";
$areanames{en}->{915331} = "Bharwari\,\ Uttar\ Pradesh";
$areanames{en}->{915332} = "Phoolpur\,\ Uttar\ Pradesh";
$areanames{en}->{915333} = "Karchhana\/Shankergarh\,\ Uttar\ Pradesh";
$areanames{en}->{915334} = "Meja\/Sirsa\,\ Uttar\ Pradesh";
$areanames{en}->{915335} = "Soraon\,\ Uttar\ Pradesh";
$areanames{en}->{915341} = "Kunda\,\ Uttar\ Pradesh";
$areanames{en}->{915342} = "Pratapgarh\,\ Uttar\ Pradesh";
$areanames{en}->{915343} = "Patti\,\ Uttar\ Pradesh";
$areanames{en}->{91535} = "Raibareli\,\ Uttar\ Pradesh";
$areanames{en}->{915361} = "Musafirkhana\,\ Uttar\ Pradesh";
$areanames{en}->{915362} = "Sultanpur\,\ Uttar\ Pradesh";
$areanames{en}->{915364} = "Kadipur\,\ Uttar\ Pradesh";
$areanames{en}->{915368} = "Amethi\,\ Uttar\ Pradesh";
$areanames{en}->{915412} = "Chandauli\/Mugalsarai\,\ Uttar\ Pradesh";
$areanames{en}->{915413} = "Chakia\,\ Uttar\ Pradesh";
$areanames{en}->{915414} = "Bhadohi\,\ Uttar\ Pradesh";
$areanames{en}->{91542} = "Varansi\,\ Uttar\ Pradesh";
$areanames{en}->{915440} = "Mirzapur\/Hallia\,\ Uttar\ Pradesh";
$areanames{en}->{915442} = "Mirzapur\,\ Uttar\ Pradesh";
$areanames{en}->{915443} = "Chunur\,\ Uttar\ Pradesh";
$areanames{en}->{915444} = "Robertsganj\,\ Uttar\ Pradesh";
$areanames{en}->{915445} = "Robertsganj\/Obra\,\ Uttar\ Pradesh";
$areanames{en}->{915446} = "Dudhi\/Pipri\,\ Uttar\ Pradesh";
$areanames{en}->{915447} = "Dudhi\,\ Uttar\ Pradesh";
$areanames{en}->{915450} = "Kerakat\,\ Uttar\ Pradesh";
$areanames{en}->{915451} = "Mariyahu\,\ Uttar\ Pradesh";
$areanames{en}->{915452} = "Jaunpur\,\ Uttar\ Pradesh";
$areanames{en}->{915453} = "Shahganj\,\ Uttar\ Pradesh";
$areanames{en}->{915454} = "Machlishahar\,\ Uttar\ Pradesh";
$areanames{en}->{915460} = "Phulpur\,\ Uttar\ Pradesh";
$areanames{en}->{915461} = "Ghosi\,\ Uttar\ Pradesh";
$areanames{en}->{915462} = "Azamgarh\,\ Uttar\ Pradesh";
$areanames{en}->{915463} = "Lalganj\,\ Uttar\ Pradesh";
$areanames{en}->{915464} = "Maunathbhanjan\,\ Uttar\ Pradesh";
$areanames{en}->{915465} = "Phulpur\/Atrawlia\,\ Uttar\ Pradesh";
$areanames{en}->{915466} = "Sagri\,\ Uttar\ Pradesh";
$areanames{en}->{91548} = "Ghazipur\,\ Uttar\ Pradesh";
$areanames{en}->{915491} = "Rasara\,\ Uttar\ Pradesh";
$areanames{en}->{915493} = "Mohamdabad\,\ Uttar\ Pradesh";
$areanames{en}->{915494} = "Bansdeeh\,\ Uttar\ Pradesh";
$areanames{en}->{915495} = "Saidpur\,\ Uttar\ Pradesh";
$areanames{en}->{915496} = "Ballia\/Raniganj\,\ Uttar\ Pradesh";
$areanames{en}->{915497} = "Zamania\,\ Uttar\ Pradesh";
$areanames{en}->{915498} = "Ballia\,\ Uttar\ Pradesh";
$areanames{en}->{91551} = "Gorakhpur\,\ Uttar\ Pradesh";
$areanames{en}->{915521} = "Bansgaon\/Barhal\ Ganj\,\ Uttar\ Pradesh";
$areanames{en}->{915522} = "Pharenda\/Compierganj\,\ Uttar\ Pradesh";
$areanames{en}->{915523} = "Maharajganj\,\ Uttar\ Pradesh";
$areanames{en}->{915524} = "Pharenda\/Anand\ Nagar\,\ Uttar\ Pradesh";
$areanames{en}->{915525} = "Bansgaon\,\ Uttar\ Pradesh";
$areanames{en}->{915541} = "Domariyaganj\,\ Uttar\ Pradesh";
$areanames{en}->{915542} = "Basti\,\ Uttar\ Pradesh";
$areanames{en}->{915543} = "Naugarh\/Barhani\,\ Uttar\ Pradesh";
$areanames{en}->{915544} = "Naugarh\/Tetribazar\,\ Uttar\ Pradesh";
$areanames{en}->{915545} = "Bansi\,\ Uttar\ Pradesh";
$areanames{en}->{915546} = "Harraiya\,\ Uttar\ Pradesh";
$areanames{en}->{915547} = "Khalilabad\,\ Uttar\ Pradesh";
$areanames{en}->{915548} = "Khalilabad\/Mehdawal\,\ Uttar\ Pradesh";
$areanames{en}->{915561} = "Salempur\/Barhaj\,\ Uttar\ Pradesh";
$areanames{en}->{915563} = "Captanganj\/Khadda\,\ Uttar\ Pradesh";
$areanames{en}->{915564} = "Padrauna\,\ Uttar\ Pradesh";
$areanames{en}->{915566} = "Salempur\,\ Uttar\ Pradesh";
$areanames{en}->{915567} = "Captanganj\,\ Uttar\ Pradesh";
$areanames{en}->{915568} = "Deoria\,\ Uttar\ Pradesh";
$areanames{en}->{915612} = "Ferozabad\,\ Uttar\ Pradesh";
$areanames{en}->{915613} = "Achhnera\,\ Uttar\ Pradesh";
$areanames{en}->{915614} = "Jarar\,\ Uttar\ Pradesh";
$areanames{en}->{91562} = "Agra\,\ Uttar\ Pradesh";
$areanames{en}->{915640} = "Kaman\,\ Rajasthan";
$areanames{en}->{915641} = "Deeg\,\ Rajasthan";
$areanames{en}->{915642} = "Dholpur\,\ Rajasthan";
$areanames{en}->{915643} = "Nadbai\,\ Rajasthan";
$areanames{en}->{915644} = "Bharatpur\,\ Rajasthan";
$areanames{en}->{915645} = "Rupbas\,\ Rajasthan";
$areanames{en}->{915646} = "Baseri\,\ Rajasthan";
$areanames{en}->{915647} = "Bari\,\ Rajasthan";
$areanames{en}->{915648} = "Bayana\,\ Rajasthan";
$areanames{en}->{91565} = "Mathura\,\ Uttar\ Pradesh";
$areanames{en}->{915661} = "Sadabad\,\ Uttar\ Pradesh";
$areanames{en}->{915662} = "Chhata\/Kosikalan\,\ Uttar\ Pradesh";
$areanames{en}->{915664} = "Mant\/Vrindavan\,\ Uttar\ Pradesh";
$areanames{en}->{915671} = "Jasrana\,\ Uttar\ Pradesh";
$areanames{en}->{915672} = "Mainpuri\,\ Uttar\ Pradesh";
$areanames{en}->{915673} = "Bhogaon\,\ Uttar\ Pradesh";
$areanames{en}->{915676} = "Shikohabad\,\ Uttar\ Pradesh";
$areanames{en}->{915677} = "Karhal\,\ Uttar\ Pradesh";
$areanames{en}->{915680} = "Bharthana\,\ Uttar\ Pradesh";
$areanames{en}->{915681} = "Bidhuna\,\ Uttar\ Pradesh";
$areanames{en}->{915683} = "Auraiya\,\ Uttar\ Pradesh";
$areanames{en}->{915688} = "Etawah\,\ Uttar\ Pradesh";
$areanames{en}->{915690} = "Kaimganj\,\ Uttar\ Pradesh";
$areanames{en}->{915691} = "Chhibramau\,\ Uttar\ Pradesh";
$areanames{en}->{915692} = "Farrukhabad\/Fategarh\,\ Uttar\ Pradesh";
$areanames{en}->{915694} = "Kannauj\,\ Uttar\ Pradesh";
$areanames{en}->{91571} = "Aligarh\,\ Uttar\ Pradesh";
$areanames{en}->{915721} = "Sikandra\ Rao\,\ Uttar\ Pradesh";
$areanames{en}->{915722} = "Hathras\,\ Uttar\ Pradesh";
$areanames{en}->{915723} = "Atrauli\,\ Uttar\ Pradesh";
$areanames{en}->{915724} = "Khair\,\ Uttar\ Pradesh";
$areanames{en}->{915731} = "Garhmukteshwar\,\ Uttar\ Pradesh";
$areanames{en}->{915732} = "Bulandshahr\,\ Uttar\ Pradesh";
$areanames{en}->{915733} = "Pahasu\,\ Uttar\ Pradesh";
$areanames{en}->{915734} = "Debai\,\ Uttar\ Pradesh";
$areanames{en}->{915735} = "Sikandrabad\,\ Uttar\ Pradesh";
$areanames{en}->{915736} = "Siyana\,\ Uttar\ Pradesh";
$areanames{en}->{915738} = "Khurja\,\ Uttar\ Pradesh";
$areanames{en}->{915740} = "Aliganj\/Ganjdundwara\,\ Uttar\ Pradesh";
$areanames{en}->{915742} = "Etah\,\ Uttar\ Pradesh";
$areanames{en}->{915744} = "Kasganj\,\ Uttar\ Pradesh";
$areanames{en}->{915745} = "Jalesar\,\ Uttar\ Pradesh";
$areanames{en}->{91581} = "Bareilly\,\ Uttar\ Pradesh";
$areanames{en}->{915821} = "Pitamberpur\,\ Uttar\ Pradesh";
$areanames{en}->{915822} = "Baheri\,\ Uttar\ Pradesh";
$areanames{en}->{915823} = "Aonla\,\ Uttar\ Pradesh";
$areanames{en}->{915824} = "Aonla\/Ramnagar\,\ Uttar\ Pradesh";
$areanames{en}->{915825} = "Nawabganj\,\ Uttar\ Pradesh";
$areanames{en}->{915831} = "Dataganj\,\ Uttar\ Pradesh";
$areanames{en}->{915832} = "Badaun\,\ Uttar\ Pradesh";
$areanames{en}->{915833} = "Sahaswan\,\ Uttar\ Pradesh";
$areanames{en}->{915834} = "Bisauli\,\ Uttar\ Pradesh";
$areanames{en}->{915836} = "Gunnaur\,\ Uttar\ Pradesh";
$areanames{en}->{915841} = "Tilhar\,\ Uttar\ Pradesh";
$areanames{en}->{915842} = "Shahjahanpur\,\ Uttar\ Pradesh";
$areanames{en}->{915843} = "Jalalabad\,\ Uttar\ Pradesh";
$areanames{en}->{915844} = "Powayan\,\ Uttar\ Pradesh";
$areanames{en}->{915850} = "Hardoi\/Baghavli\,\ Uttar\ Pradesh";
$areanames{en}->{915851} = "Bilgam\/Madhoganj\,\ Uttar\ Pradesh";
$areanames{en}->{915852} = "Hardoi\,\ Uttar\ Pradesh";
$areanames{en}->{915853} = "Shahabad\,\ Uttar\ Pradesh";
$areanames{en}->{915854} = "Sandila\,\ Uttar\ Pradesh";
$areanames{en}->{915855} = "Bilgram\/Sandi\,\ Uttar\ Pradesh";
$areanames{en}->{915861} = "Misrikh\/Aurangabad\,\ Uttar\ Pradesh";
$areanames{en}->{915862} = "Sitapur\,\ Uttar\ Pradesh";
$areanames{en}->{915863} = "Biswan\,\ Uttar\ Pradesh";
$areanames{en}->{915864} = "Sidhauli\/Mahmodabad\,\ Uttar\ Pradesh";
$areanames{en}->{915865} = "Misrikh\,\ Uttar\ Pradesh";
$areanames{en}->{915870} = "Bhira\,\ Uttar\ Pradesh";
$areanames{en}->{915871} = "Nighasan\/Palia\ Kalan\,\ Uttar\ Pradesh";
$areanames{en}->{915872} = "Kheri\,\ Uttar\ Pradesh";
$areanames{en}->{915873} = "Nighasan\/Tikunia\,\ Uttar\ Pradesh";
$areanames{en}->{915874} = "Nighasan\/Dhaurehra\,\ Uttar\ Pradesh";
$areanames{en}->{915875} = "Mohammadi\/Maigalganj\,\ Uttar\ Pradesh";
$areanames{en}->{915876} = "Mohammadi\,\ Uttar\ Pradesh";
$areanames{en}->{915880} = "Puranpur\,\ Uttar\ Pradesh";
$areanames{en}->{915881} = "Bisalpur\,\ Uttar\ Pradesh";
$areanames{en}->{915882} = "Pilibhit\,\ Uttar\ Pradesh";
$areanames{en}->{91591} = "Moradabad\,\ Uttar\ Pradesh";
$areanames{en}->{915921} = "Bilari\,\ Uttar\ Pradesh";
$areanames{en}->{915922} = "Amroha\,\ Uttar\ Pradesh";
$areanames{en}->{915923} = "Sambhal\,\ Uttar\ Pradesh";
$areanames{en}->{915924} = "Hasanpur\,\ Uttar\ Pradesh";
$areanames{en}->{915942} = "Nainital\,\ Uttar\ Pradesh";
$areanames{en}->{915943} = "Khatima\,\ Uttar\ Pradesh";
$areanames{en}->{915944} = "Kichha\/Rudrapur\,\ Uttar\ Pradesh";
$areanames{en}->{915945} = "Haldwani\/Chorgalian\,\ Uttar\ Pradesh";
$areanames{en}->{915946} = "Haldwani\,\ Uttar\ Pradesh";
$areanames{en}->{915947} = "Kashipur\,\ Uttar\ Pradesh";
$areanames{en}->{915948} = "Khatima\/Sitarganj\,\ Uttar\ Pradesh";
$areanames{en}->{915949} = "Kichha\/Bazpur\,\ Uttar\ Pradesh";
$areanames{en}->{91595} = "Rampur\,\ Uttar\ Pradesh";
$areanames{en}->{915960} = "Shahabad\,\ Uttar\ Pradesh";
$areanames{en}->{915961} = "Munsiari\,\ Uttar\ Pradesh";
$areanames{en}->{915962} = "Almora\,\ Uttar\ Pradesh";
$areanames{en}->{915963} = "Bageshwar\,\ Uttar\ Pradesh";
$areanames{en}->{915964} = "Pithoragarh\,\ Uttar\ Pradesh";
$areanames{en}->{915965} = "Champawat\,\ Uttar\ Pradesh";
$areanames{en}->{915966} = "Ranikhet\,\ Uttar\ Pradesh";
$areanames{en}->{915967} = "Dharchula\,\ Uttar\ Pradesh";
$areanames{en}->{9161112} = "Hilsa\,\ Bihar";
$areanames{en}->{9161113} = "Hilsa\,\ Bihar";
$areanames{en}->{9161114} = "Hilsa\,\ Bihar";
$areanames{en}->{9161115} = "Hilsa\,\ Bihar";
$areanames{en}->{9161116} = "Hilsa\,\ Bihar";
$areanames{en}->{9161117} = "Hilsa\,\ Bihar";
$areanames{en}->{9161122} = "Biharsharif\,\ Bihar";
$areanames{en}->{9161123} = "Biharsharif\,\ Bihar";
$areanames{en}->{9161124} = "Biharsharif\,\ Bihar";
$areanames{en}->{9161125} = "Biharsharif\,\ Bihar";
$areanames{en}->{9161126} = "Biharsharif\,\ Bihar";
$areanames{en}->{9161127} = "Biharsharif\,\ Bihar";
$areanames{en}->{9161142} = "Jahanabad\,\ Bihar";
$areanames{en}->{9161143} = "Jahanabad\,\ Bihar";
$areanames{en}->{9161144} = "Jahanabad\,\ Bihar";
$areanames{en}->{9161145} = "Jahanabad\,\ Bihar";
$areanames{en}->{9161146} = "Jahanabad\,\ Bihar";
$areanames{en}->{9161147} = "Jahanabad\,\ Bihar";
$areanames{en}->{9161152} = "Danapur\,\ Bihar";
$areanames{en}->{9161153} = "Danapur\,\ Bihar";
$areanames{en}->{9161154} = "Danapur\,\ Bihar";
$areanames{en}->{9161155} = "Danapur\,\ Bihar";
$areanames{en}->{9161156} = "Danapur\,\ Bihar";
$areanames{en}->{9161157} = "Danapur\,\ Bihar";
$areanames{en}->{916122} = "Patna\,\ Bihar";
$areanames{en}->{916123} = "Patna\,\ Bihar";
$areanames{en}->{916124} = "Patna\,\ Bihar";
$areanames{en}->{916125} = "Patna\,\ Bihar";
$areanames{en}->{916126} = "Patna\,\ Bihar";
$areanames{en}->{916127} = "Patna\,\ Bihar";
$areanames{en}->{9161322} = "Barh\,\ Bihar";
$areanames{en}->{9161323} = "Barh\,\ Bihar";
$areanames{en}->{9161324} = "Barh\,\ Bihar";
$areanames{en}->{9161325} = "Barh\,\ Bihar";
$areanames{en}->{9161326} = "Barh\,\ Bihar";
$areanames{en}->{9161327} = "Barh\,\ Bihar";
$areanames{en}->{9161352} = "Bikram\,\ Bihar";
$areanames{en}->{9161353} = "Bikram\,\ Bihar";
$areanames{en}->{9161354} = "Bikram\,\ Bihar";
$areanames{en}->{9161355} = "Bikram\,\ Bihar";
$areanames{en}->{9161356} = "Bikram\,\ Bihar";
$areanames{en}->{9161357} = "Bikram\,\ Bihar";
$areanames{en}->{9161502} = "Hathua\,\ Bihar";
$areanames{en}->{9161503} = "Hathua\,\ Bihar";
$areanames{en}->{9161504} = "Hathua\,\ Bihar";
$areanames{en}->{9161505} = "Hathua\,\ Bihar";
$areanames{en}->{9161506} = "Hathua\,\ Bihar";
$areanames{en}->{9161507} = "Hathua\,\ Bihar";
$areanames{en}->{9161512} = "Sidhawalia\,\ Bihar";
$areanames{en}->{9161513} = "Sidhawalia\,\ Bihar";
$areanames{en}->{9161514} = "Sidhawalia\,\ Bihar";
$areanames{en}->{9161515} = "Sidhawalia\,\ Bihar";
$areanames{en}->{9161516} = "Sidhawalia\,\ Bihar";
$areanames{en}->{9161517} = "Sidhawalia\,\ Bihar";
$areanames{en}->{9161522} = "Chapra\,\ Bihar";
$areanames{en}->{9161523} = "Chapra\,\ Bihar";
$areanames{en}->{9161524} = "Chapra\,\ Bihar";
$areanames{en}->{9161525} = "Chapra\,\ Bihar";
$areanames{en}->{9161526} = "Chapra\,\ Bihar";
$areanames{en}->{9161527} = "Chapra\,\ Bihar";
$areanames{en}->{9161532} = "Maharajganj\,\ Bihar";
$areanames{en}->{9161533} = "Maharajganj\,\ Bihar";
$areanames{en}->{9161534} = "Maharajganj\,\ Bihar";
$areanames{en}->{9161535} = "Maharajganj\,\ Bihar";
$areanames{en}->{9161536} = "Maharajganj\,\ Bihar";
$areanames{en}->{9161537} = "Maharajganj\,\ Bihar";
$areanames{en}->{9161542} = "Siwan\,\ Bihar";
$areanames{en}->{9161543} = "Siwan\,\ Bihar";
$areanames{en}->{9161544} = "Siwan\,\ Bihar";
$areanames{en}->{9161545} = "Siwan\,\ Bihar";
$areanames{en}->{9161546} = "Siwan\,\ Bihar";
$areanames{en}->{9161547} = "Siwan\,\ Bihar";
$areanames{en}->{9161552} = "Ekma\,\ Bihar";
$areanames{en}->{9161553} = "Ekma\,\ Bihar";
$areanames{en}->{9161554} = "Ekma\,\ Bihar";
$areanames{en}->{9161555} = "Ekma\,\ Bihar";
$areanames{en}->{9161556} = "Ekma\,\ Bihar";
$areanames{en}->{9161557} = "Ekma\,\ Bihar";
$areanames{en}->{9161562} = "Gopalganj\,\ Bihar";
$areanames{en}->{9161563} = "Gopalganj\,\ Bihar";
$areanames{en}->{9161564} = "Gopalganj\,\ Bihar";
$areanames{en}->{9161565} = "Gopalganj\,\ Bihar";
$areanames{en}->{9161566} = "Gopalganj\,\ Bihar";
$areanames{en}->{9161567} = "Gopalganj\,\ Bihar";
$areanames{en}->{9161572} = "Mairwa\,\ Bihar";
$areanames{en}->{9161573} = "Mairwa\,\ Bihar";
$areanames{en}->{9161574} = "Mairwa\,\ Bihar";
$areanames{en}->{9161575} = "Mairwa\,\ Bihar";
$areanames{en}->{9161576} = "Mairwa\,\ Bihar";
$areanames{en}->{9161577} = "Mairwa\,\ Bihar";
$areanames{en}->{9161582} = "Sonepur\,\ Bihar";
$areanames{en}->{9161583} = "Sonepur\,\ Bihar";
$areanames{en}->{9161584} = "Sonepur\,\ Bihar";
$areanames{en}->{9161585} = "Sonepur\,\ Bihar";
$areanames{en}->{9161586} = "Sonepur\,\ Bihar";
$areanames{en}->{9161587} = "Sonepur\,\ Bihar";
$areanames{en}->{9161592} = "Masrakh\,\ Bihar";
$areanames{en}->{9161593} = "Masrakh\,\ Bihar";
$areanames{en}->{9161594} = "Masrakh\,\ Bihar";
$areanames{en}->{9161595} = "Masrakh\,\ Bihar";
$areanames{en}->{9161596} = "Masrakh\,\ Bihar";
$areanames{en}->{9161597} = "Masrakh\,\ Bihar";
$areanames{en}->{9161802} = "Adhaura\,\ Bihar";
$areanames{en}->{9161803} = "Adhaura\,\ Bihar";
$areanames{en}->{9161804} = "Adhaura\,\ Bihar";
$areanames{en}->{9161805} = "Adhaura\,\ Bihar";
$areanames{en}->{9161806} = "Adhaura\,\ Bihar";
$areanames{en}->{9161807} = "Adhaura\,\ Bihar";
$areanames{en}->{9161812} = "Piro\,\ Bihar";
$areanames{en}->{9161813} = "Piro\,\ Bihar";
$areanames{en}->{9161814} = "Piro\,\ Bihar";
$areanames{en}->{9161815} = "Piro\,\ Bihar";
$areanames{en}->{9161816} = "Piro\,\ Bihar";
$areanames{en}->{9161817} = "Piro\,\ Bihar";
$areanames{en}->{9161822} = "Arrah\,\ Bihar";
$areanames{en}->{9161823} = "Arrah\,\ Bihar";
$areanames{en}->{9161824} = "Arrah\,\ Bihar";
$areanames{en}->{9161825} = "Arrah\,\ Bihar";
$areanames{en}->{9161826} = "Arrah\,\ Bihar";
$areanames{en}->{9161827} = "Arrah\,\ Bihar";
$areanames{en}->{9161832} = "Buxar\,\ Bihar";
$areanames{en}->{9161833} = "Buxar\,\ Bihar";
$areanames{en}->{9161834} = "Buxar\,\ Bihar";
$areanames{en}->{9161835} = "Buxar\,\ Bihar";
$areanames{en}->{9161836} = "Buxar\,\ Bihar";
$areanames{en}->{9161837} = "Buxar\,\ Bihar";
$areanames{en}->{9161842} = "Sasaram\,\ Bihar";
$areanames{en}->{9161843} = "Sasaram\,\ Bihar";
$areanames{en}->{9161844} = "Sasaram\,\ Bihar";
$areanames{en}->{9161845} = "Sasaram\,\ Bihar";
$areanames{en}->{9161846} = "Sasaram\,\ Bihar";
$areanames{en}->{9161847} = "Sasaram\,\ Bihar";
$areanames{en}->{9161852} = "Bikramganj\,\ Bihar";
$areanames{en}->{9161853} = "Bikramganj\,\ Bihar";
$areanames{en}->{9161854} = "Bikramganj\,\ Bihar";
$areanames{en}->{9161855} = "Bikramganj\,\ Bihar";
$areanames{en}->{9161856} = "Bikramganj\,\ Bihar";
$areanames{en}->{9161857} = "Bikramganj\,\ Bihar";
$areanames{en}->{9161862} = "Aurangabad\,\ Bihar";
$areanames{en}->{9161863} = "Aurangabad\,\ Bihar";
$areanames{en}->{9161864} = "Aurangabad\,\ Bihar";
$areanames{en}->{9161865} = "Aurangabad\,\ Bihar";
$areanames{en}->{9161866} = "Aurangabad\,\ Bihar";
$areanames{en}->{9161867} = "Aurangabad\,\ Bihar";
$areanames{en}->{9161872} = "Mohania\,\ Bihar";
$areanames{en}->{9161873} = "Mohania\,\ Bihar";
$areanames{en}->{9161874} = "Mohania\,\ Bihar";
$areanames{en}->{9161875} = "Mohania\,\ Bihar";
$areanames{en}->{9161876} = "Mohania\,\ Bihar";
$areanames{en}->{9161877} = "Mohania\,\ Bihar";
$areanames{en}->{9161882} = "Rohtas\,\ Bihar";
$areanames{en}->{9161883} = "Rohtas\,\ Bihar";
$areanames{en}->{9161884} = "Rohtas\,\ Bihar";
$areanames{en}->{9161885} = "Rohtas\,\ Bihar";
$areanames{en}->{9161886} = "Rohtas\,\ Bihar";
$areanames{en}->{9161887} = "Rohtas\,\ Bihar";
$areanames{en}->{9161892} = "Bhabhua\,\ Bihar";
$areanames{en}->{9161893} = "Bhabhua\,\ Bihar";
$areanames{en}->{9161894} = "Bhabhua\,\ Bihar";
$areanames{en}->{9161895} = "Bhabhua\,\ Bihar";
$areanames{en}->{9161896} = "Bhabhua\,\ Bihar";
$areanames{en}->{9161897} = "Bhabhua\,\ Bihar";
$areanames{en}->{916212} = "Muzaffarpur\,\ Bihar";
$areanames{en}->{916213} = "Muzaffarpur\,\ Bihar";
$areanames{en}->{916214} = "Muzaffarpur\,\ Bihar";
$areanames{en}->{916215} = "Muzaffarpur\,\ Bihar";
$areanames{en}->{916216} = "Muzaffarpur\,\ Bihar";
$areanames{en}->{916217} = "Muzaffarpur\,\ Bihar";
$areanames{en}->{9162222} = "Sheohar\,\ Bihar";
$areanames{en}->{9162223} = "Sheohar\,\ Bihar";
$areanames{en}->{9162224} = "Sheohar\,\ Bihar";
$areanames{en}->{9162225} = "Sheohar\,\ Bihar";
$areanames{en}->{9162226} = "Sheohar\,\ Bihar";
$areanames{en}->{9162227} = "Sheohar\,\ Bihar";
$areanames{en}->{9162232} = "Motipur\,\ Bihar";
$areanames{en}->{9162233} = "Motipur\,\ Bihar";
$areanames{en}->{9162234} = "Motipur\,\ Bihar";
$areanames{en}->{9162235} = "Motipur\,\ Bihar";
$areanames{en}->{9162236} = "Motipur\,\ Bihar";
$areanames{en}->{9162237} = "Motipur\,\ Bihar";
$areanames{en}->{9162242} = "Hajipur\,\ Bihar";
$areanames{en}->{9162243} = "Hajipur\,\ Bihar";
$areanames{en}->{9162244} = "Hajipur\,\ Bihar";
$areanames{en}->{9162245} = "Hajipur\,\ Bihar";
$areanames{en}->{9162246} = "Hajipur\,\ Bihar";
$areanames{en}->{9162247} = "Hajipur\,\ Bihar";
$areanames{en}->{9162262} = "Sitamarhi\,\ Bihar";
$areanames{en}->{9162263} = "Sitamarhi\,\ Bihar";
$areanames{en}->{9162264} = "Sitamarhi\,\ Bihar";
$areanames{en}->{9162265} = "Sitamarhi\,\ Bihar";
$areanames{en}->{9162266} = "Sitamarhi\,\ Bihar";
$areanames{en}->{9162267} = "Sitamarhi\,\ Bihar";
$areanames{en}->{9162272} = "Mahua\,\ Bihar";
$areanames{en}->{9162273} = "Mahua\,\ Bihar";
$areanames{en}->{9162274} = "Mahua\,\ Bihar";
$areanames{en}->{9162275} = "Mahua\,\ Bihar";
$areanames{en}->{9162276} = "Mahua\,\ Bihar";
$areanames{en}->{9162277} = "Mahua\,\ Bihar";
$areanames{en}->{9162282} = "Pupri\,\ Bihar";
$areanames{en}->{9162283} = "Pupri\,\ Bihar";
$areanames{en}->{9162284} = "Pupri\,\ Bihar";
$areanames{en}->{9162285} = "Pupri\,\ Bihar";
$areanames{en}->{9162286} = "Pupri\,\ Bihar";
$areanames{en}->{9162287} = "Pupri\,\ Bihar";
$areanames{en}->{9162292} = "Bidupur\,\ Bihar";
$areanames{en}->{9162293} = "Bidupur\,\ Bihar";
$areanames{en}->{9162294} = "Bidupur\,\ Bihar";
$areanames{en}->{9162295} = "Bidupur\,\ Bihar";
$areanames{en}->{9162296} = "Bidupur\,\ Bihar";
$areanames{en}->{9162297} = "Bidupur\,\ Bihar";
$areanames{en}->{9162422} = "Benipur\,\ Bihar";
$areanames{en}->{9162423} = "Benipur\,\ Bihar";
$areanames{en}->{9162424} = "Benipur\,\ Bihar";
$areanames{en}->{9162425} = "Benipur\,\ Bihar";
$areanames{en}->{9162426} = "Benipur\,\ Bihar";
$areanames{en}->{9162427} = "Benipur\,\ Bihar";
$areanames{en}->{9162432} = "Begusarai\,\ Bihar";
$areanames{en}->{9162433} = "Begusarai\,\ Bihar";
$areanames{en}->{9162434} = "Begusarai\,\ Bihar";
$areanames{en}->{9162435} = "Begusarai\,\ Bihar";
$areanames{en}->{9162436} = "Begusarai\,\ Bihar";
$areanames{en}->{9162437} = "Begusarai\,\ Bihar";
$areanames{en}->{9162442} = "Khagaria\,\ Bihar";
$areanames{en}->{9162443} = "Khagaria\,\ Bihar";
$areanames{en}->{9162444} = "Khagaria\,\ Bihar";
$areanames{en}->{9162445} = "Khagaria\,\ Bihar";
$areanames{en}->{9162446} = "Khagaria\,\ Bihar";
$areanames{en}->{9162447} = "Khagaria\,\ Bihar";
$areanames{en}->{9162452} = "Gogri\,\ Bihar";
$areanames{en}->{9162453} = "Gogri\,\ Bihar";
$areanames{en}->{9162454} = "Gogri\,\ Bihar";
$areanames{en}->{9162455} = "Gogri\,\ Bihar";
$areanames{en}->{9162456} = "Gogri\,\ Bihar";
$areanames{en}->{9162457} = "Gogri\,\ Bihar";
$areanames{en}->{9162462} = "Jainagar\,\ Bihar";
$areanames{en}->{9162463} = "Jainagar\,\ Bihar";
$areanames{en}->{9162464} = "Jainagar\,\ Bihar";
$areanames{en}->{9162465} = "Jainagar\,\ Bihar";
$areanames{en}->{9162466} = "Jainagar\,\ Bihar";
$areanames{en}->{9162467} = "Jainagar\,\ Bihar";
$areanames{en}->{9162472} = "Singhwara\,\ Bihar";
$areanames{en}->{9162473} = "Singhwara\,\ Bihar";
$areanames{en}->{9162474} = "Singhwara\,\ Bihar";
$areanames{en}->{9162475} = "Singhwara\,\ Bihar";
$areanames{en}->{9162476} = "Singhwara\,\ Bihar";
$areanames{en}->{9162477} = "Singhwara\,\ Bihar";
$areanames{en}->{9162502} = "Dhaka\,\ Bihar";
$areanames{en}->{9162503} = "Dhaka\,\ Bihar";
$areanames{en}->{9162504} = "Dhaka\,\ Bihar";
$areanames{en}->{9162505} = "Dhaka\,\ Bihar";
$areanames{en}->{9162506} = "Dhaka\,\ Bihar";
$areanames{en}->{9162507} = "Dhaka\,\ Bihar";
$areanames{en}->{9162512} = "Bagaha\,\ Bihar";
$areanames{en}->{9162513} = "Bagaha\,\ Bihar";
$areanames{en}->{9162514} = "Bagaha\,\ Bihar";
$areanames{en}->{9162515} = "Bagaha\,\ Bihar";
$areanames{en}->{9162516} = "Bagaha\,\ Bihar";
$areanames{en}->{9162517} = "Bagaha\,\ Bihar";
$areanames{en}->{9162522} = "Motihari\,\ Bihar";
$areanames{en}->{9162523} = "Motihari\,\ Bihar";
$areanames{en}->{9162524} = "Motihari\,\ Bihar";
$areanames{en}->{9162525} = "Motihari\,\ Bihar";
$areanames{en}->{9162526} = "Motihari\,\ Bihar";
$areanames{en}->{9162527} = "Motihari\,\ Bihar";
$areanames{en}->{9162532} = "Narkatiaganj\,\ Bihar";
$areanames{en}->{9162533} = "Narkatiaganj\,\ Bihar";
$areanames{en}->{9162534} = "Narkatiaganj\,\ Bihar";
$areanames{en}->{9162535} = "Narkatiaganj\,\ Bihar";
$areanames{en}->{9162536} = "Narkatiaganj\,\ Bihar";
$areanames{en}->{9162537} = "Narkatiaganj\,\ Bihar";
$areanames{en}->{9162542} = "Bettiah\,\ Bihar";
$areanames{en}->{9162543} = "Bettiah\,\ Bihar";
$areanames{en}->{9162544} = "Bettiah\,\ Bihar";
$areanames{en}->{9162545} = "Bettiah\,\ Bihar";
$areanames{en}->{9162546} = "Bettiah\,\ Bihar";
$areanames{en}->{9162547} = "Bettiah\,\ Bihar";
$areanames{en}->{9162552} = "Raxaul\,\ Bihar";
$areanames{en}->{9162553} = "Raxaul\,\ Bihar";
$areanames{en}->{9162554} = "Raxaul\,\ Bihar";
$areanames{en}->{9162555} = "Raxaul\,\ Bihar";
$areanames{en}->{9162556} = "Raxaul\,\ Bihar";
$areanames{en}->{9162557} = "Raxaul\,\ Bihar";
$areanames{en}->{9162562} = "Ramnagar\,\ Bihar";
$areanames{en}->{9162563} = "Ramnagar\,\ Bihar";
$areanames{en}->{9162564} = "Ramnagar\,\ Bihar";
$areanames{en}->{9162565} = "Ramnagar\,\ Bihar";
$areanames{en}->{9162566} = "Ramnagar\,\ Bihar";
$areanames{en}->{9162567} = "Ramnagar\,\ Bihar";
$areanames{en}->{9162572} = "Barachakia\,\ Bihar";
$areanames{en}->{9162573} = "Barachakia\,\ Bihar";
$areanames{en}->{9162574} = "Barachakia\,\ Bihar";
$areanames{en}->{9162575} = "Barachakia\,\ Bihar";
$areanames{en}->{9162576} = "Barachakia\,\ Bihar";
$areanames{en}->{9162577} = "Barachakia\,\ Bihar";
$areanames{en}->{9162582} = "Areraj\,\ Bihar";
$areanames{en}->{9162583} = "Areraj\,\ Bihar";
$areanames{en}->{9162584} = "Areraj\,\ Bihar";
$areanames{en}->{9162585} = "Areraj\,\ Bihar";
$areanames{en}->{9162586} = "Areraj\,\ Bihar";
$areanames{en}->{9162587} = "Areraj\,\ Bihar";
$areanames{en}->{9162592} = "Pakridayal\,\ Bihar";
$areanames{en}->{9162593} = "Pakridayal\,\ Bihar";
$areanames{en}->{9162594} = "Pakridayal\,\ Bihar";
$areanames{en}->{9162595} = "Pakridayal\,\ Bihar";
$areanames{en}->{9162596} = "Pakridayal\,\ Bihar";
$areanames{en}->{9162597} = "Pakridayal\,\ Bihar";
$areanames{en}->{9162712} = "Benipatti\,\ Bihar";
$areanames{en}->{9162713} = "Benipatti\,\ Bihar";
$areanames{en}->{9162714} = "Benipatti\,\ Bihar";
$areanames{en}->{9162715} = "Benipatti\,\ Bihar";
$areanames{en}->{9162716} = "Benipatti\,\ Bihar";
$areanames{en}->{9162717} = "Benipatti\,\ Bihar";
$areanames{en}->{9162722} = "Darbhanga\,\ Bihar";
$areanames{en}->{9162723} = "Darbhanga\,\ Bihar";
$areanames{en}->{9162724} = "Darbhanga\,\ Bihar";
$areanames{en}->{9162725} = "Darbhanga\,\ Bihar";
$areanames{en}->{9162726} = "Darbhanga\,\ Bihar";
$areanames{en}->{9162727} = "Darbhanga\,\ Bihar";
$areanames{en}->{9162732} = "Jhajharpur\,\ Bihar";
$areanames{en}->{9162733} = "Jhajharpur\,\ Bihar";
$areanames{en}->{9162734} = "Jhajharpur\,\ Bihar";
$areanames{en}->{9162735} = "Jhajharpur\,\ Bihar";
$areanames{en}->{9162736} = "Jhajharpur\,\ Bihar";
$areanames{en}->{9162737} = "Jhajharpur\,\ Bihar";
$areanames{en}->{9162742} = "Samastipur\,\ Bihar";
$areanames{en}->{9162743} = "Samastipur\,\ Bihar";
$areanames{en}->{9162744} = "Samastipur\,\ Bihar";
$areanames{en}->{9162745} = "Samastipur\,\ Bihar";
$areanames{en}->{9162746} = "Samastipur\,\ Bihar";
$areanames{en}->{9162747} = "Samastipur\,\ Bihar";
$areanames{en}->{9162752} = "Rosera\,\ Bihar";
$areanames{en}->{9162753} = "Rosera\,\ Bihar";
$areanames{en}->{9162754} = "Rosera\,\ Bihar";
$areanames{en}->{9162755} = "Rosera\,\ Bihar";
$areanames{en}->{9162756} = "Rosera\,\ Bihar";
$areanames{en}->{9162757} = "Rosera\,\ Bihar";
$areanames{en}->{9162762} = "Madhubani\,\ Bihar";
$areanames{en}->{9162763} = "Madhubani\,\ Bihar";
$areanames{en}->{9162764} = "Madhubani\,\ Bihar";
$areanames{en}->{9162765} = "Madhubani\,\ Bihar";
$areanames{en}->{9162766} = "Madhubani\,\ Bihar";
$areanames{en}->{9162767} = "Madhubani\,\ Bihar";
$areanames{en}->{9162772} = "Phulparas\,\ Bihar";
$areanames{en}->{9162773} = "Phulparas\,\ Bihar";
$areanames{en}->{9162774} = "Phulparas\,\ Bihar";
$areanames{en}->{9162775} = "Phulparas\,\ Bihar";
$areanames{en}->{9162776} = "Phulparas\,\ Bihar";
$areanames{en}->{9162777} = "Phulparas\,\ Bihar";
$areanames{en}->{9162782} = "Dalsinghsarai\,\ Bihar";
$areanames{en}->{9162783} = "Dalsinghsarai\,\ Bihar";
$areanames{en}->{9162784} = "Dalsinghsarai\,\ Bihar";
$areanames{en}->{9162785} = "Dalsinghsarai\,\ Bihar";
$areanames{en}->{9162786} = "Dalsinghsarai\,\ Bihar";
$areanames{en}->{9162787} = "Dalsinghsarai\,\ Bihar";
$areanames{en}->{9162792} = "Barauni\,\ Bihar";
$areanames{en}->{9162793} = "Barauni\,\ Bihar";
$areanames{en}->{9162794} = "Barauni\,\ Bihar";
$areanames{en}->{9162795} = "Barauni\,\ Bihar";
$areanames{en}->{9162796} = "Barauni\,\ Bihar";
$areanames{en}->{9162797} = "Barauni\,\ Bihar";
$areanames{en}->{916312} = "Gaya\,\ Bihar";
$areanames{en}->{916313} = "Gaya\,\ Bihar";
$areanames{en}->{916314} = "Gaya\,\ Bihar";
$areanames{en}->{916315} = "Gaya\,\ Bihar";
$areanames{en}->{916316} = "Gaya\,\ Bihar";
$areanames{en}->{916317} = "Gaya\,\ Bihar";
$areanames{en}->{9163222} = "Wazirganj\,\ Bihar";
$areanames{en}->{9163223} = "Wazirganj\,\ Bihar";
$areanames{en}->{9163224} = "Wazirganj\,\ Bihar";
$areanames{en}->{9163225} = "Wazirganj\,\ Bihar";
$areanames{en}->{9163226} = "Wazirganj\,\ Bihar";
$areanames{en}->{9163227} = "Wazirganj\,\ Bihar";
$areanames{en}->{9163232} = "Dumraon\,\ Bihar";
$areanames{en}->{9163233} = "Dumraon\,\ Bihar";
$areanames{en}->{9163234} = "Dumraon\,\ Bihar";
$areanames{en}->{9163235} = "Dumraon\,\ Bihar";
$areanames{en}->{9163236} = "Dumraon\,\ Bihar";
$areanames{en}->{9163237} = "Dumraon\,\ Bihar";
$areanames{en}->{9163242} = "Nawada\,\ Bihar";
$areanames{en}->{9163243} = "Nawada\,\ Bihar";
$areanames{en}->{9163244} = "Nawada\,\ Bihar";
$areanames{en}->{9163245} = "Nawada\,\ Bihar";
$areanames{en}->{9163246} = "Nawada\,\ Bihar";
$areanames{en}->{9163247} = "Nawada\,\ Bihar";
$areanames{en}->{9163252} = "Pakribarwan\,\ Bihar";
$areanames{en}->{9163253} = "Pakribarwan\,\ Bihar";
$areanames{en}->{9163254} = "Pakribarwan\,\ Bihar";
$areanames{en}->{9163255} = "Pakribarwan\,\ Bihar";
$areanames{en}->{9163256} = "Pakribarwan\,\ Bihar";
$areanames{en}->{9163257} = "Pakribarwan\,\ Bihar";
$areanames{en}->{9163262} = "Sherghati\,\ Bihar";
$areanames{en}->{9163263} = "Sherghati\,\ Bihar";
$areanames{en}->{9163264} = "Sherghati\,\ Bihar";
$areanames{en}->{9163265} = "Sherghati\,\ Bihar";
$areanames{en}->{9163266} = "Sherghati\,\ Bihar";
$areanames{en}->{9163267} = "Sherghati\,\ Bihar";
$areanames{en}->{9163272} = "Rafiganj\,\ Bihar";
$areanames{en}->{9163273} = "Rafiganj\,\ Bihar";
$areanames{en}->{9163274} = "Rafiganj\,\ Bihar";
$areanames{en}->{9163275} = "Rafiganj\,\ Bihar";
$areanames{en}->{9163276} = "Rafiganj\,\ Bihar";
$areanames{en}->{9163277} = "Rafiganj\,\ Bihar";
$areanames{en}->{9163282} = "Daudnagar\,\ Bihar";
$areanames{en}->{9163283} = "Daudnagar\,\ Bihar";
$areanames{en}->{9163284} = "Daudnagar\,\ Bihar";
$areanames{en}->{9163285} = "Daudnagar\,\ Bihar";
$areanames{en}->{9163286} = "Daudnagar\,\ Bihar";
$areanames{en}->{9163287} = "Daudnagar\,\ Bihar";
$areanames{en}->{9163312} = "Imamganj\,\ Bihar";
$areanames{en}->{9163313} = "Imamganj\,\ Bihar";
$areanames{en}->{9163314} = "Imamganj\,\ Bihar";
$areanames{en}->{9163315} = "Imamganj\,\ Bihar";
$areanames{en}->{9163316} = "Imamganj\,\ Bihar";
$areanames{en}->{9163317} = "Imamganj\,\ Bihar";
$areanames{en}->{9163322} = "Nabinagar\,\ Bihar";
$areanames{en}->{9163323} = "Nabinagar\,\ Bihar";
$areanames{en}->{9163324} = "Nabinagar\,\ Bihar";
$areanames{en}->{9163325} = "Nabinagar\,\ Bihar";
$areanames{en}->{9163326} = "Nabinagar\,\ Bihar";
$areanames{en}->{9163327} = "Nabinagar\,\ Bihar";
$areanames{en}->{9163362} = "Rajauli\,\ Bihar";
$areanames{en}->{9163363} = "Rajauli\,\ Bihar";
$areanames{en}->{9163364} = "Rajauli\,\ Bihar";
$areanames{en}->{9163365} = "Rajauli\,\ Bihar";
$areanames{en}->{9163366} = "Rajauli\,\ Bihar";
$areanames{en}->{9163367} = "Rajauli\,\ Bihar";
$areanames{en}->{9163372} = "Arwal\,\ Bihar";
$areanames{en}->{9163373} = "Arwal\,\ Bihar";
$areanames{en}->{9163374} = "Arwal\,\ Bihar";
$areanames{en}->{9163375} = "Arwal\,\ Bihar";
$areanames{en}->{9163376} = "Arwal\,\ Bihar";
$areanames{en}->{9163377} = "Arwal\,\ Bihar";
$areanames{en}->{9163412} = "Seikhpura\,\ Bihar";
$areanames{en}->{9163413} = "Seikhpura\,\ Bihar";
$areanames{en}->{9163414} = "Seikhpura\,\ Bihar";
$areanames{en}->{9163415} = "Seikhpura\,\ Bihar";
$areanames{en}->{9163416} = "Seikhpura\,\ Bihar";
$areanames{en}->{9163417} = "Seikhpura\,\ Bihar";
$areanames{en}->{9163422} = "H\.Kharagpur\,\ Bihar";
$areanames{en}->{9163423} = "H\.Kharagpur\,\ Bihar";
$areanames{en}->{9163424} = "H\.Kharagpur\,\ Bihar";
$areanames{en}->{9163425} = "H\.Kharagpur\,\ Bihar";
$areanames{en}->{9163426} = "H\.Kharagpur\,\ Bihar";
$areanames{en}->{9163427} = "H\.Kharagpur\,\ Bihar";
$areanames{en}->{9163442} = "Monghyr\,\ Bihar";
$areanames{en}->{9163443} = "Monghyr\,\ Bihar";
$areanames{en}->{9163444} = "Monghyr\,\ Bihar";
$areanames{en}->{9163445} = "Monghyr\,\ Bihar";
$areanames{en}->{9163446} = "Monghyr\,\ Bihar";
$areanames{en}->{9163447} = "Monghyr\,\ Bihar";
$areanames{en}->{9163452} = "Jamui\,\ Bihar";
$areanames{en}->{9163453} = "Jamui\,\ Bihar";
$areanames{en}->{9163454} = "Jamui\,\ Bihar";
$areanames{en}->{9163455} = "Jamui\,\ Bihar";
$areanames{en}->{9163456} = "Jamui\,\ Bihar";
$areanames{en}->{9163457} = "Jamui\,\ Bihar";
$areanames{en}->{9163462} = "Lakhisarai\,\ Bihar";
$areanames{en}->{9163463} = "Lakhisarai\,\ Bihar";
$areanames{en}->{9163464} = "Lakhisarai\,\ Bihar";
$areanames{en}->{9163465} = "Lakhisarai\,\ Bihar";
$areanames{en}->{9163466} = "Lakhisarai\,\ Bihar";
$areanames{en}->{9163467} = "Lakhisarai\,\ Bihar";
$areanames{en}->{9163472} = "Chakai\,\ Bihar";
$areanames{en}->{9163473} = "Chakai\,\ Bihar";
$areanames{en}->{9163474} = "Chakai\,\ Bihar";
$areanames{en}->{9163475} = "Chakai\,\ Bihar";
$areanames{en}->{9163476} = "Chakai\,\ Bihar";
$areanames{en}->{9163477} = "Chakai\,\ Bihar";
$areanames{en}->{9163482} = "Mallehpur\,\ Bihar";
$areanames{en}->{9163483} = "Mallehpur\,\ Bihar";
$areanames{en}->{9163484} = "Mallehpur\,\ Bihar";
$areanames{en}->{9163485} = "Mallehpur\,\ Bihar";
$areanames{en}->{9163486} = "Mallehpur\,\ Bihar";
$areanames{en}->{9163487} = "Mallehpur\,\ Bihar";
$areanames{en}->{9163492} = "Jhajha\,\ Bihar";
$areanames{en}->{9163493} = "Jhajha\,\ Bihar";
$areanames{en}->{9163494} = "Jhajha\,\ Bihar";
$areanames{en}->{9163495} = "Jhajha\,\ Bihar";
$areanames{en}->{9163496} = "Jhajha\,\ Bihar";
$areanames{en}->{9163497} = "Jhajha\,\ Bihar";
$areanames{en}->{916412} = "Bhagalpur\,\ Bihar";
$areanames{en}->{916413} = "Bhagalpur\,\ Bihar";
$areanames{en}->{916414} = "Bhagalpur\,\ Bihar";
$areanames{en}->{916415} = "Bhagalpur\,\ Bihar";
$areanames{en}->{916416} = "Bhagalpur\,\ Bihar";
$areanames{en}->{916417} = "Bhagalpur\,\ Bihar";
$areanames{en}->{9164202} = "Amarpur\,\ Bihar";
$areanames{en}->{9164203} = "Amarpur\,\ Bihar";
$areanames{en}->{9164204} = "Amarpur\,\ Bihar";
$areanames{en}->{9164205} = "Amarpur\,\ Bihar";
$areanames{en}->{9164206} = "Amarpur\,\ Bihar";
$areanames{en}->{9164207} = "Amarpur\,\ Bihar";
$areanames{en}->{9164212} = "Naugachia\,\ Bihar";
$areanames{en}->{9164213} = "Naugachia\,\ Bihar";
$areanames{en}->{9164214} = "Naugachia\,\ Bihar";
$areanames{en}->{9164215} = "Naugachia\,\ Bihar";
$areanames{en}->{9164216} = "Naugachia\,\ Bihar";
$areanames{en}->{9164217} = "Naugachia\,\ Bihar";
$areanames{en}->{9164222} = "Godda\,\ Bihar";
$areanames{en}->{9164223} = "Godda\,\ Bihar";
$areanames{en}->{9164224} = "Godda\,\ Bihar";
$areanames{en}->{9164225} = "Godda\,\ Bihar";
$areanames{en}->{9164226} = "Godda\,\ Bihar";
$areanames{en}->{9164227} = "Godda\,\ Bihar";
$areanames{en}->{9164232} = "Maheshpur\ Raj\,\ Bihar";
$areanames{en}->{9164233} = "Maheshpur\ Raj\,\ Bihar";
$areanames{en}->{9164234} = "Maheshpur\ Raj\,\ Bihar";
$areanames{en}->{9164235} = "Maheshpur\ Raj\,\ Bihar";
$areanames{en}->{9164236} = "Maheshpur\ Raj\,\ Bihar";
$areanames{en}->{9164237} = "Maheshpur\ Raj\,\ Bihar";
$areanames{en}->{9164242} = "Banka\,\ Bihar";
$areanames{en}->{9164243} = "Banka\,\ Bihar";
$areanames{en}->{9164244} = "Banka\,\ Bihar";
$areanames{en}->{9164245} = "Banka\,\ Bihar";
$areanames{en}->{9164246} = "Banka\,\ Bihar";
$areanames{en}->{9164247} = "Banka\,\ Bihar";
$areanames{en}->{9164252} = "Katoria\,\ Bihar";
$areanames{en}->{9164253} = "Katoria\,\ Bihar";
$areanames{en}->{9164254} = "Katoria\,\ Bihar";
$areanames{en}->{9164255} = "Katoria\,\ Bihar";
$areanames{en}->{9164256} = "Katoria\,\ Bihar";
$areanames{en}->{9164257} = "Katoria\,\ Bihar";
$areanames{en}->{9164262} = "Rajmahal\,\ Bihar";
$areanames{en}->{9164263} = "Rajmahal\,\ Bihar";
$areanames{en}->{9164264} = "Rajmahal\,\ Bihar";
$areanames{en}->{9164265} = "Rajmahal\,\ Bihar";
$areanames{en}->{9164266} = "Rajmahal\,\ Bihar";
$areanames{en}->{9164267} = "Rajmahal\,\ Bihar";
$areanames{en}->{9164272} = "Kathikund\,\ Bihar";
$areanames{en}->{9164273} = "Kathikund\,\ Bihar";
$areanames{en}->{9164274} = "Kathikund\,\ Bihar";
$areanames{en}->{9164275} = "Kathikund\,\ Bihar";
$areanames{en}->{9164276} = "Kathikund\,\ Bihar";
$areanames{en}->{9164277} = "Kathikund\,\ Bihar";
$areanames{en}->{9164282} = "Nala\,\ Bihar";
$areanames{en}->{9164283} = "Nala\,\ Bihar";
$areanames{en}->{9164284} = "Nala\,\ Bihar";
$areanames{en}->{9164285} = "Nala\,\ Bihar";
$areanames{en}->{9164286} = "Nala\,\ Bihar";
$areanames{en}->{9164287} = "Nala\,\ Bihar";
$areanames{en}->{9164292} = "Kahalgaon\,\ Bihar";
$areanames{en}->{9164293} = "Kahalgaon\,\ Bihar";
$areanames{en}->{9164294} = "Kahalgaon\,\ Bihar";
$areanames{en}->{9164295} = "Kahalgaon\,\ Bihar";
$areanames{en}->{9164296} = "Kahalgaon\,\ Bihar";
$areanames{en}->{9164297} = "Kahalgaon\,\ Bihar";
$areanames{en}->{9164312} = "Jharmundi\,\ Bihar";
$areanames{en}->{9164313} = "Jharmundi\,\ Bihar";
$areanames{en}->{9164314} = "Jharmundi\,\ Bihar";
$areanames{en}->{9164315} = "Jharmundi\,\ Bihar";
$areanames{en}->{9164316} = "Jharmundi\,\ Bihar";
$areanames{en}->{9164317} = "Jharmundi\,\ Bihar";
$areanames{en}->{9164322} = "Deoghar\,\ Bihar";
$areanames{en}->{9164323} = "Deoghar\,\ Bihar";
$areanames{en}->{9164324} = "Deoghar\,\ Bihar";
$areanames{en}->{9164325} = "Deoghar\,\ Bihar";
$areanames{en}->{9164326} = "Deoghar\,\ Bihar";
$areanames{en}->{9164327} = "Deoghar\,\ Bihar";
$areanames{en}->{9164332} = "Jamtara\,\ Bihar";
$areanames{en}->{9164333} = "Jamtara\,\ Bihar";
$areanames{en}->{9164334} = "Jamtara\,\ Bihar";
$areanames{en}->{9164335} = "Jamtara\,\ Bihar";
$areanames{en}->{9164336} = "Jamtara\,\ Bihar";
$areanames{en}->{9164337} = "Jamtara\,\ Bihar";
$areanames{en}->{9164342} = "Dumka\,\ Bihar";
$areanames{en}->{9164343} = "Dumka\,\ Bihar";
$areanames{en}->{9164344} = "Dumka\,\ Bihar";
$areanames{en}->{9164345} = "Dumka\,\ Bihar";
$areanames{en}->{9164346} = "Dumka\,\ Bihar";
$areanames{en}->{9164347} = "Dumka\,\ Bihar";
$areanames{en}->{9164352} = "Pakur\,\ Bihar";
$areanames{en}->{9164353} = "Pakur\,\ Bihar";
$areanames{en}->{9164354} = "Pakur\,\ Bihar";
$areanames{en}->{9164355} = "Pakur\,\ Bihar";
$areanames{en}->{9164356} = "Pakur\,\ Bihar";
$areanames{en}->{9164357} = "Pakur\,\ Bihar";
$areanames{en}->{9164362} = "Sahibganj\,\ Bihar";
$areanames{en}->{9164363} = "Sahibganj\,\ Bihar";
$areanames{en}->{9164364} = "Sahibganj\,\ Bihar";
$areanames{en}->{9164365} = "Sahibganj\,\ Bihar";
$areanames{en}->{9164366} = "Sahibganj\,\ Bihar";
$areanames{en}->{9164367} = "Sahibganj\,\ Bihar";
$areanames{en}->{9164372} = "Mahagama\,\ Bihar";
$areanames{en}->{9164373} = "Mahagama\,\ Bihar";
$areanames{en}->{9164374} = "Mahagama\,\ Bihar";
$areanames{en}->{9164375} = "Mahagama\,\ Bihar";
$areanames{en}->{9164376} = "Mahagama\,\ Bihar";
$areanames{en}->{9164377} = "Mahagama\,\ Bihar";
$areanames{en}->{9164382} = "Madhupur\,\ Bihar";
$areanames{en}->{9164383} = "Madhupur\,\ Bihar";
$areanames{en}->{9164384} = "Madhupur\,\ Bihar";
$areanames{en}->{9164385} = "Madhupur\,\ Bihar";
$areanames{en}->{9164386} = "Madhupur\,\ Bihar";
$areanames{en}->{9164387} = "Madhupur\,\ Bihar";
$areanames{en}->{9164512} = "Barsoi\,\ Bihar";
$areanames{en}->{9164513} = "Barsoi\,\ Bihar";
$areanames{en}->{9164514} = "Barsoi\,\ Bihar";
$areanames{en}->{9164515} = "Barsoi\,\ Bihar";
$areanames{en}->{9164516} = "Barsoi\,\ Bihar";
$areanames{en}->{9164517} = "Barsoi\,\ Bihar";
$areanames{en}->{9164522} = "Katihar\,\ Bihar";
$areanames{en}->{9164523} = "Katihar\,\ Bihar";
$areanames{en}->{9164524} = "Katihar\,\ Bihar";
$areanames{en}->{9164525} = "Katihar\,\ Bihar";
$areanames{en}->{9164526} = "Katihar\,\ Bihar";
$areanames{en}->{9164527} = "Katihar\,\ Bihar";
$areanames{en}->{9164532} = "Araria\,\ Bihar";
$areanames{en}->{9164533} = "Araria\,\ Bihar";
$areanames{en}->{9164534} = "Araria\,\ Bihar";
$areanames{en}->{9164535} = "Araria\,\ Bihar";
$areanames{en}->{9164536} = "Araria\,\ Bihar";
$areanames{en}->{9164537} = "Araria\,\ Bihar";
$areanames{en}->{9164542} = "Purnea\,\ Bihar";
$areanames{en}->{9164543} = "Purnea\,\ Bihar";
$areanames{en}->{9164544} = "Purnea\,\ Bihar";
$areanames{en}->{9164545} = "Purnea\,\ Bihar";
$areanames{en}->{9164546} = "Purnea\,\ Bihar";
$areanames{en}->{9164547} = "Purnea\,\ Bihar";
$areanames{en}->{9164552} = "Forbesganj\,\ Bihar";
$areanames{en}->{9164553} = "Forbesganj\,\ Bihar";
$areanames{en}->{9164554} = "Forbesganj\,\ Bihar";
$areanames{en}->{9164555} = "Forbesganj\,\ Bihar";
$areanames{en}->{9164556} = "Forbesganj\,\ Bihar";
$areanames{en}->{9164557} = "Forbesganj\,\ Bihar";
$areanames{en}->{9164572} = "Korha\,\ Bihar";
$areanames{en}->{9164573} = "Korha\,\ Bihar";
$areanames{en}->{9164574} = "Korha\,\ Bihar";
$areanames{en}->{9164575} = "Korha\,\ Bihar";
$areanames{en}->{9164576} = "Korha\,\ Bihar";
$areanames{en}->{9164577} = "Korha\,\ Bihar";
$areanames{en}->{9164592} = "Thakurganj\,\ Bihar";
$areanames{en}->{9164593} = "Thakurganj\,\ Bihar";
$areanames{en}->{9164594} = "Thakurganj\,\ Bihar";
$areanames{en}->{9164595} = "Thakurganj\,\ Bihar";
$areanames{en}->{9164596} = "Thakurganj\,\ Bihar";
$areanames{en}->{9164597} = "Thakurganj\,\ Bihar";
$areanames{en}->{9164612} = "Raniganj\,\ Bihar";
$areanames{en}->{9164613} = "Raniganj\,\ Bihar";
$areanames{en}->{9164614} = "Raniganj\,\ Bihar";
$areanames{en}->{9164615} = "Raniganj\,\ Bihar";
$areanames{en}->{9164616} = "Raniganj\,\ Bihar";
$areanames{en}->{9164617} = "Raniganj\,\ Bihar";
$areanames{en}->{9164622} = "Dhamdaha\,\ Bihar";
$areanames{en}->{9164623} = "Dhamdaha\,\ Bihar";
$areanames{en}->{9164624} = "Dhamdaha\,\ Bihar";
$areanames{en}->{9164625} = "Dhamdaha\,\ Bihar";
$areanames{en}->{9164626} = "Dhamdaha\,\ Bihar";
$areanames{en}->{9164627} = "Dhamdaha\,\ Bihar";
$areanames{en}->{9164662} = "Kishanganj\,\ Bihar";
$areanames{en}->{9164663} = "Kishanganj\,\ Bihar";
$areanames{en}->{9164664} = "Kishanganj\,\ Bihar";
$areanames{en}->{9164665} = "Kishanganj\,\ Bihar";
$areanames{en}->{9164666} = "Kishanganj\,\ Bihar";
$areanames{en}->{9164667} = "Kishanganj\,\ Bihar";
$areanames{en}->{9164672} = "Banmankhi\,\ Bihar";
$areanames{en}->{9164673} = "Banmankhi\,\ Bihar";
$areanames{en}->{9164674} = "Banmankhi\,\ Bihar";
$areanames{en}->{9164675} = "Banmankhi\,\ Bihar";
$areanames{en}->{9164676} = "Banmankhi\,\ Bihar";
$areanames{en}->{9164677} = "Banmankhi\,\ Bihar";
$areanames{en}->{9164712} = "Birpur\,\ Bihar";
$areanames{en}->{9164713} = "Birpur\,\ Bihar";
$areanames{en}->{9164714} = "Birpur\,\ Bihar";
$areanames{en}->{9164715} = "Birpur\,\ Bihar";
$areanames{en}->{9164716} = "Birpur\,\ Bihar";
$areanames{en}->{9164717} = "Birpur\,\ Bihar";
$areanames{en}->{9164732} = "Supaul\,\ Bihar";
$areanames{en}->{9164733} = "Supaul\,\ Bihar";
$areanames{en}->{9164734} = "Supaul\,\ Bihar";
$areanames{en}->{9164735} = "Supaul\,\ Bihar";
$areanames{en}->{9164736} = "Supaul\,\ Bihar";
$areanames{en}->{9164737} = "Supaul\,\ Bihar";
$areanames{en}->{9164752} = "S\.Bakhtiarpur\,\ Bihar";
$areanames{en}->{9164753} = "S\.Bakhtiarpur\,\ Bihar";
$areanames{en}->{9164754} = "S\.Bakhtiarpur\,\ Bihar";
$areanames{en}->{9164755} = "S\.Bakhtiarpur\,\ Bihar";
$areanames{en}->{9164756} = "S\.Bakhtiarpur\,\ Bihar";
$areanames{en}->{9164757} = "S\.Bakhtiarpur\,\ Bihar";
$areanames{en}->{9164762} = "Madhepura\,\ Bihar";
$areanames{en}->{9164763} = "Madhepura\,\ Bihar";
$areanames{en}->{9164764} = "Madhepura\,\ Bihar";
$areanames{en}->{9164765} = "Madhepura\,\ Bihar";
$areanames{en}->{9164766} = "Madhepura\,\ Bihar";
$areanames{en}->{9164767} = "Madhepura\,\ Bihar";
$areanames{en}->{9164772} = "Triveniganj\,\ Bihar";
$areanames{en}->{9164773} = "Triveniganj\,\ Bihar";
$areanames{en}->{9164774} = "Triveniganj\,\ Bihar";
$areanames{en}->{9164775} = "Triveniganj\,\ Bihar";
$areanames{en}->{9164776} = "Triveniganj\,\ Bihar";
$areanames{en}->{9164777} = "Triveniganj\,\ Bihar";
$areanames{en}->{9164782} = "Saharsa\,\ Bihar";
$areanames{en}->{9164783} = "Saharsa\,\ Bihar";
$areanames{en}->{9164784} = "Saharsa\,\ Bihar";
$areanames{en}->{9164785} = "Saharsa\,\ Bihar";
$areanames{en}->{9164786} = "Saharsa\,\ Bihar";
$areanames{en}->{9164787} = "Saharsa\,\ Bihar";
$areanames{en}->{9164792} = "Udakishanganj\,\ Bihar";
$areanames{en}->{9164793} = "Udakishanganj\,\ Bihar";
$areanames{en}->{9164794} = "Udakishanganj\,\ Bihar";
$areanames{en}->{9164795} = "Udakishanganj\,\ Bihar";
$areanames{en}->{9164796} = "Udakishanganj\,\ Bihar";
$areanames{en}->{9164797} = "Udakishanganj\,\ Bihar";
$areanames{en}->{916512} = "Ranchi\,\ Bihar";
$areanames{en}->{916513} = "Ranchi\,\ Bihar";
$areanames{en}->{916514} = "Ranchi\,\ Bihar";
$areanames{en}->{916515} = "Ranchi\,\ Bihar";
$areanames{en}->{916516} = "Ranchi\,\ Bihar";
$areanames{en}->{916517} = "Ranchi\,\ Bihar";
$areanames{en}->{9165222} = "Muri\,\ Bihar";
$areanames{en}->{9165223} = "Muri\,\ Bihar";
$areanames{en}->{9165224} = "Muri\,\ Bihar";
$areanames{en}->{9165225} = "Muri\,\ Bihar";
$areanames{en}->{9165226} = "Muri\,\ Bihar";
$areanames{en}->{9165227} = "Muri\,\ Bihar";
$areanames{en}->{9165232} = "Ghaghra\,\ Bihar";
$areanames{en}->{9165233} = "Ghaghra\,\ Bihar";
$areanames{en}->{9165234} = "Ghaghra\,\ Bihar";
$areanames{en}->{9165235} = "Ghaghra\,\ Bihar";
$areanames{en}->{9165236} = "Ghaghra\,\ Bihar";
$areanames{en}->{9165237} = "Ghaghra\,\ Bihar";
$areanames{en}->{9165242} = "Gumla\,\ Bihar";
$areanames{en}->{9165243} = "Gumla\,\ Bihar";
$areanames{en}->{9165244} = "Gumla\,\ Bihar";
$areanames{en}->{9165245} = "Gumla\,\ Bihar";
$areanames{en}->{9165246} = "Gumla\,\ Bihar";
$areanames{en}->{9165247} = "Gumla\,\ Bihar";
$areanames{en}->{9165252} = "Simdega\,\ Bihar";
$areanames{en}->{9165253} = "Simdega\,\ Bihar";
$areanames{en}->{9165254} = "Simdega\,\ Bihar";
$areanames{en}->{9165255} = "Simdega\,\ Bihar";
$areanames{en}->{9165256} = "Simdega\,\ Bihar";
$areanames{en}->{9165257} = "Simdega\,\ Bihar";
$areanames{en}->{9165262} = "Lohardaga\,\ Bihar";
$areanames{en}->{9165263} = "Lohardaga\,\ Bihar";
$areanames{en}->{9165264} = "Lohardaga\,\ Bihar";
$areanames{en}->{9165265} = "Lohardaga\,\ Bihar";
$areanames{en}->{9165266} = "Lohardaga\,\ Bihar";
$areanames{en}->{9165267} = "Lohardaga\,\ Bihar";
$areanames{en}->{9165272} = "Kolebira\,\ Bihar";
$areanames{en}->{9165273} = "Kolebira\,\ Bihar";
$areanames{en}->{9165274} = "Kolebira\,\ Bihar";
$areanames{en}->{9165275} = "Kolebira\,\ Bihar";
$areanames{en}->{9165276} = "Kolebira\,\ Bihar";
$areanames{en}->{9165277} = "Kolebira\,\ Bihar";
$areanames{en}->{9165282} = "Khunti\,\ Bihar";
$areanames{en}->{9165283} = "Khunti\,\ Bihar";
$areanames{en}->{9165284} = "Khunti\,\ Bihar";
$areanames{en}->{9165285} = "Khunti\,\ Bihar";
$areanames{en}->{9165286} = "Khunti\,\ Bihar";
$areanames{en}->{9165287} = "Khunti\,\ Bihar";
$areanames{en}->{9165292} = "Itki\,\ Bihar";
$areanames{en}->{9165293} = "Itki\,\ Bihar";
$areanames{en}->{9165294} = "Itki\,\ Bihar";
$areanames{en}->{9165295} = "Itki\,\ Bihar";
$areanames{en}->{9165296} = "Itki\,\ Bihar";
$areanames{en}->{9165297} = "Itki\,\ Bihar";
$areanames{en}->{9165302} = "Bundu\,\ Bihar";
$areanames{en}->{9165303} = "Bundu\,\ Bihar";
$areanames{en}->{9165304} = "Bundu\,\ Bihar";
$areanames{en}->{9165305} = "Bundu\,\ Bihar";
$areanames{en}->{9165306} = "Bundu\,\ Bihar";
$areanames{en}->{9165307} = "Bundu\,\ Bihar";
$areanames{en}->{9165312} = "Mandar\,\ Bihar";
$areanames{en}->{9165313} = "Mandar\,\ Bihar";
$areanames{en}->{9165314} = "Mandar\,\ Bihar";
$areanames{en}->{9165315} = "Mandar\,\ Bihar";
$areanames{en}->{9165316} = "Mandar\,\ Bihar";
$areanames{en}->{9165317} = "Mandar\,\ Bihar";
$areanames{en}->{9165322} = "Giridih\,\ Bihar";
$areanames{en}->{9165323} = "Giridih\,\ Bihar";
$areanames{en}->{9165324} = "Giridih\,\ Bihar";
$areanames{en}->{9165325} = "Giridih\,\ Bihar";
$areanames{en}->{9165326} = "Giridih\,\ Bihar";
$areanames{en}->{9165327} = "Giridih\,\ Bihar";
$areanames{en}->{9165332} = "Basia\,\ Bihar";
$areanames{en}->{9165333} = "Basia\,\ Bihar";
$areanames{en}->{9165334} = "Basia\,\ Bihar";
$areanames{en}->{9165335} = "Basia\,\ Bihar";
$areanames{en}->{9165336} = "Basia\,\ Bihar";
$areanames{en}->{9165337} = "Basia\,\ Bihar";
$areanames{en}->{9165342} = "Jhumaritalaiya\,\ Bihar";
$areanames{en}->{9165343} = "Jhumaritalaiya\,\ Bihar";
$areanames{en}->{9165344} = "Jhumaritalaiya\,\ Bihar";
$areanames{en}->{9165345} = "Jhumaritalaiya\,\ Bihar";
$areanames{en}->{9165346} = "Jhumaritalaiya\,\ Bihar";
$areanames{en}->{9165347} = "Jhumaritalaiya\,\ Bihar";
$areanames{en}->{9165352} = "Chainpur\,\ Bihar";
$areanames{en}->{9165353} = "Chainpur\,\ Bihar";
$areanames{en}->{9165354} = "Chainpur\,\ Bihar";
$areanames{en}->{9165355} = "Chainpur\,\ Bihar";
$areanames{en}->{9165356} = "Chainpur\,\ Bihar";
$areanames{en}->{9165357} = "Chainpur\,\ Bihar";
$areanames{en}->{9165362} = "Palkot\,\ Bihar";
$areanames{en}->{9165363} = "Palkot\,\ Bihar";
$areanames{en}->{9165364} = "Palkot\,\ Bihar";
$areanames{en}->{9165365} = "Palkot\,\ Bihar";
$areanames{en}->{9165366} = "Palkot\,\ Bihar";
$areanames{en}->{9165367} = "Palkot\,\ Bihar";
$areanames{en}->{9165382} = "Torpa\,\ Bihar";
$areanames{en}->{9165383} = "Torpa\,\ Bihar";
$areanames{en}->{9165384} = "Torpa\,\ Bihar";
$areanames{en}->{9165385} = "Torpa\,\ Bihar";
$areanames{en}->{9165386} = "Torpa\,\ Bihar";
$areanames{en}->{9165387} = "Torpa\,\ Bihar";
$areanames{en}->{9165392} = "Bolwa\,\ Bihar";
$areanames{en}->{9165393} = "Bolwa\,\ Bihar";
$areanames{en}->{9165394} = "Bolwa\,\ Bihar";
$areanames{en}->{9165395} = "Bolwa\,\ Bihar";
$areanames{en}->{9165396} = "Bolwa\,\ Bihar";
$areanames{en}->{9165397} = "Bolwa\,\ Bihar";
$areanames{en}->{9165402} = "Govindpur\,\ Bihar";
$areanames{en}->{9165403} = "Govindpur\,\ Bihar";
$areanames{en}->{9165404} = "Govindpur\,\ Bihar";
$areanames{en}->{9165405} = "Govindpur\,\ Bihar";
$areanames{en}->{9165406} = "Govindpur\,\ Bihar";
$areanames{en}->{9165407} = "Govindpur\,\ Bihar";
$areanames{en}->{9165412} = "Chatra\,\ Bihar";
$areanames{en}->{9165413} = "Chatra\,\ Bihar";
$areanames{en}->{9165414} = "Chatra\,\ Bihar";
$areanames{en}->{9165415} = "Chatra\,\ Bihar";
$areanames{en}->{9165416} = "Chatra\,\ Bihar";
$areanames{en}->{9165417} = "Chatra\,\ Bihar";
$areanames{en}->{9165422} = "Bokaro\,\ Bihar";
$areanames{en}->{9165423} = "Bokaro\,\ Bihar";
$areanames{en}->{9165424} = "Bokaro\,\ Bihar";
$areanames{en}->{9165425} = "Bokaro\,\ Bihar";
$areanames{en}->{9165426} = "Bokaro\,\ Bihar";
$areanames{en}->{9165427} = "Bokaro\,\ Bihar";
$areanames{en}->{9165432} = "Barhi\,\ Bihar";
$areanames{en}->{9165433} = "Barhi\,\ Bihar";
$areanames{en}->{9165434} = "Barhi\,\ Bihar";
$areanames{en}->{9165435} = "Barhi\,\ Bihar";
$areanames{en}->{9165436} = "Barhi\,\ Bihar";
$areanames{en}->{9165437} = "Barhi\,\ Bihar";
$areanames{en}->{9165442} = "Gomia\,\ Bihar";
$areanames{en}->{9165443} = "Gomia\,\ Bihar";
$areanames{en}->{9165444} = "Gomia\,\ Bihar";
$areanames{en}->{9165445} = "Gomia\,\ Bihar";
$areanames{en}->{9165446} = "Gomia\,\ Bihar";
$areanames{en}->{9165447} = "Gomia\,\ Bihar";
$areanames{en}->{9165452} = "Mandu\,\ Bihar";
$areanames{en}->{9165453} = "Mandu\,\ Bihar";
$areanames{en}->{9165454} = "Mandu\,\ Bihar";
$areanames{en}->{9165455} = "Mandu\,\ Bihar";
$areanames{en}->{9165456} = "Mandu\,\ Bihar";
$areanames{en}->{9165457} = "Mandu\,\ Bihar";
$areanames{en}->{9165462} = "Hazaribagh\,\ Bihar";
$areanames{en}->{9165463} = "Hazaribagh\,\ Bihar";
$areanames{en}->{9165464} = "Hazaribagh\,\ Bihar";
$areanames{en}->{9165465} = "Hazaribagh\,\ Bihar";
$areanames{en}->{9165466} = "Hazaribagh\,\ Bihar";
$areanames{en}->{9165467} = "Hazaribagh\,\ Bihar";
$areanames{en}->{9165472} = "Chavparan\,\ Bihar";
$areanames{en}->{9165473} = "Chavparan\,\ Bihar";
$areanames{en}->{9165474} = "Chavparan\,\ Bihar";
$areanames{en}->{9165475} = "Chavparan\,\ Bihar";
$areanames{en}->{9165476} = "Chavparan\,\ Bihar";
$areanames{en}->{9165477} = "Chavparan\,\ Bihar";
$areanames{en}->{9165482} = "Ichak\,\ Bihar";
$areanames{en}->{9165483} = "Ichak\,\ Bihar";
$areanames{en}->{9165484} = "Ichak\,\ Bihar";
$areanames{en}->{9165485} = "Ichak\,\ Bihar";
$areanames{en}->{9165486} = "Ichak\,\ Bihar";
$areanames{en}->{9165487} = "Ichak\,\ Bihar";
$areanames{en}->{9165492} = "Bermo\,\ Bihar";
$areanames{en}->{9165493} = "Bermo\,\ Bihar";
$areanames{en}->{9165494} = "Bermo\,\ Bihar";
$areanames{en}->{9165495} = "Bermo\,\ Bihar";
$areanames{en}->{9165496} = "Bermo\,\ Bihar";
$areanames{en}->{9165497} = "Bermo\,\ Bihar";
$areanames{en}->{9165502} = "Hunterganj\,\ Bihar";
$areanames{en}->{9165503} = "Hunterganj\,\ Bihar";
$areanames{en}->{9165504} = "Hunterganj\,\ Bihar";
$areanames{en}->{9165505} = "Hunterganj\,\ Bihar";
$areanames{en}->{9165506} = "Hunterganj\,\ Bihar";
$areanames{en}->{9165507} = "Hunterganj\,\ Bihar";
$areanames{en}->{9165512} = "Barkagaon\,\ Bihar";
$areanames{en}->{9165513} = "Barkagaon\,\ Bihar";
$areanames{en}->{9165514} = "Barkagaon\,\ Bihar";
$areanames{en}->{9165515} = "Barkagaon\,\ Bihar";
$areanames{en}->{9165516} = "Barkagaon\,\ Bihar";
$areanames{en}->{9165517} = "Barkagaon\,\ Bihar";
$areanames{en}->{9165532} = "Ramgarh\,\ Bihar";
$areanames{en}->{9165533} = "Ramgarh\,\ Bihar";
$areanames{en}->{9165534} = "Ramgarh\,\ Bihar";
$areanames{en}->{9165535} = "Ramgarh\,\ Bihar";
$areanames{en}->{9165536} = "Ramgarh\,\ Bihar";
$areanames{en}->{9165537} = "Ramgarh\,\ Bihar";
$areanames{en}->{9165542} = "Rajdhanwar\,\ Bihar";
$areanames{en}->{9165543} = "Rajdhanwar\,\ Bihar";
$areanames{en}->{9165544} = "Rajdhanwar\,\ Bihar";
$areanames{en}->{9165545} = "Rajdhanwar\,\ Bihar";
$areanames{en}->{9165546} = "Rajdhanwar\,\ Bihar";
$areanames{en}->{9165547} = "Rajdhanwar\,\ Bihar";
$areanames{en}->{9165562} = "Tisri\,\ Bihar";
$areanames{en}->{9165563} = "Tisri\,\ Bihar";
$areanames{en}->{9165564} = "Tisri\,\ Bihar";
$areanames{en}->{9165565} = "Tisri\,\ Bihar";
$areanames{en}->{9165566} = "Tisri\,\ Bihar";
$areanames{en}->{9165567} = "Tisri\,\ Bihar";
$areanames{en}->{9165572} = "Bagodar\,\ Bihar";
$areanames{en}->{9165573} = "Bagodar\,\ Bihar";
$areanames{en}->{9165574} = "Bagodar\,\ Bihar";
$areanames{en}->{9165575} = "Bagodar\,\ Bihar";
$areanames{en}->{9165576} = "Bagodar\,\ Bihar";
$areanames{en}->{9165577} = "Bagodar\,\ Bihar";
$areanames{en}->{9165582} = "Dumri\(Isribazar\)\,\ Bihar";
$areanames{en}->{9165583} = "Dumri\(Isribazar\)\,\ Bihar";
$areanames{en}->{9165584} = "Dumri\(Isribazar\)\,\ Bihar";
$areanames{en}->{9165585} = "Dumri\(Isribazar\)\,\ Bihar";
$areanames{en}->{9165586} = "Dumri\(Isribazar\)\,\ Bihar";
$areanames{en}->{9165587} = "Dumri\(Isribazar\)\,\ Bihar";
$areanames{en}->{9165592} = "Simaria\,\ Bihar";
$areanames{en}->{9165593} = "Simaria\,\ Bihar";
$areanames{en}->{9165594} = "Simaria\,\ Bihar";
$areanames{en}->{9165595} = "Simaria\,\ Bihar";
$areanames{en}->{9165596} = "Simaria\,\ Bihar";
$areanames{en}->{9165597} = "Simaria\,\ Bihar";
$areanames{en}->{9165602} = "Patan\,\ Bihar";
$areanames{en}->{9165603} = "Patan\,\ Bihar";
$areanames{en}->{9165604} = "Patan\,\ Bihar";
$areanames{en}->{9165605} = "Patan\,\ Bihar";
$areanames{en}->{9165606} = "Patan\,\ Bihar";
$areanames{en}->{9165607} = "Patan\,\ Bihar";
$areanames{en}->{9165612} = "Garhwa\,\ Bihar";
$areanames{en}->{9165613} = "Garhwa\,\ Bihar";
$areanames{en}->{9165614} = "Garhwa\,\ Bihar";
$areanames{en}->{9165615} = "Garhwa\,\ Bihar";
$areanames{en}->{9165616} = "Garhwa\,\ Bihar";
$areanames{en}->{9165617} = "Garhwa\,\ Bihar";
$areanames{en}->{9165622} = "Daltonganj\,\ Bihar";
$areanames{en}->{9165623} = "Daltonganj\,\ Bihar";
$areanames{en}->{9165624} = "Daltonganj\,\ Bihar";
$areanames{en}->{9165625} = "Daltonganj\,\ Bihar";
$areanames{en}->{9165626} = "Daltonganj\,\ Bihar";
$areanames{en}->{9165627} = "Daltonganj\,\ Bihar";
$areanames{en}->{9165632} = "Bhawanathpur\,\ Bihar";
$areanames{en}->{9165633} = "Bhawanathpur\,\ Bihar";
$areanames{en}->{9165634} = "Bhawanathpur\,\ Bihar";
$areanames{en}->{9165635} = "Bhawanathpur\,\ Bihar";
$areanames{en}->{9165636} = "Bhawanathpur\,\ Bihar";
$areanames{en}->{9165637} = "Bhawanathpur\,\ Bihar";
$areanames{en}->{9165642} = "Nagarutari\,\ Bihar";
$areanames{en}->{9165643} = "Nagarutari\,\ Bihar";
$areanames{en}->{9165644} = "Nagarutari\,\ Bihar";
$areanames{en}->{9165645} = "Nagarutari\,\ Bihar";
$areanames{en}->{9165646} = "Nagarutari\,\ Bihar";
$areanames{en}->{9165647} = "Nagarutari\,\ Bihar";
$areanames{en}->{9165652} = "Latehar\,\ Bihar";
$areanames{en}->{9165653} = "Latehar\,\ Bihar";
$areanames{en}->{9165654} = "Latehar\,\ Bihar";
$areanames{en}->{9165655} = "Latehar\,\ Bihar";
$areanames{en}->{9165656} = "Latehar\,\ Bihar";
$areanames{en}->{9165657} = "Latehar\,\ Bihar";
$areanames{en}->{9165662} = "Japla\,\ Bihar";
$areanames{en}->{9165663} = "Japla\,\ Bihar";
$areanames{en}->{9165664} = "Japla\,\ Bihar";
$areanames{en}->{9165665} = "Japla\,\ Bihar";
$areanames{en}->{9165666} = "Japla\,\ Bihar";
$areanames{en}->{9165667} = "Japla\,\ Bihar";
$areanames{en}->{9165672} = "Barwadih\,\ Bihar";
$areanames{en}->{9165673} = "Barwadih\,\ Bihar";
$areanames{en}->{9165674} = "Barwadih\,\ Bihar";
$areanames{en}->{9165675} = "Barwadih\,\ Bihar";
$areanames{en}->{9165676} = "Barwadih\,\ Bihar";
$areanames{en}->{9165677} = "Barwadih\,\ Bihar";
$areanames{en}->{9165682} = "Balumath\,\ Bihar";
$areanames{en}->{9165683} = "Balumath\,\ Bihar";
$areanames{en}->{9165684} = "Balumath\,\ Bihar";
$areanames{en}->{9165685} = "Balumath\,\ Bihar";
$areanames{en}->{9165686} = "Balumath\,\ Bihar";
$areanames{en}->{9165687} = "Balumath\,\ Bihar";
$areanames{en}->{9165692} = "Garu\,\ Bihar";
$areanames{en}->{9165693} = "Garu\,\ Bihar";
$areanames{en}->{9165694} = "Garu\,\ Bihar";
$areanames{en}->{9165695} = "Garu\,\ Bihar";
$areanames{en}->{9165696} = "Garu\,\ Bihar";
$areanames{en}->{9165697} = "Garu\,\ Bihar";
$areanames{en}->{916572} = "Jamshedpur\,\ Bihar";
$areanames{en}->{916573} = "Jamshedpur\,\ Bihar";
$areanames{en}->{916574} = "Jamshedpur\,\ Bihar";
$areanames{en}->{916575} = "Jamshedpur\,\ Bihar";
$areanames{en}->{916576} = "Jamshedpur\,\ Bihar";
$areanames{en}->{916577} = "Jamshedpur\,\ Bihar";
$areanames{en}->{9165812} = "Bhandaria\,\ Bihar";
$areanames{en}->{9165813} = "Bhandaria\,\ Bihar";
$areanames{en}->{9165814} = "Bhandaria\,\ Bihar";
$areanames{en}->{9165815} = "Bhandaria\,\ Bihar";
$areanames{en}->{9165816} = "Bhandaria\,\ Bihar";
$areanames{en}->{9165817} = "Bhandaria\,\ Bihar";
$areanames{en}->{9165822} = "Chaibasa\,\ Bihar";
$areanames{en}->{9165823} = "Chaibasa\,\ Bihar";
$areanames{en}->{9165824} = "Chaibasa\,\ Bihar";
$areanames{en}->{9165825} = "Chaibasa\,\ Bihar";
$areanames{en}->{9165826} = "Chaibasa\,\ Bihar";
$areanames{en}->{9165827} = "Chaibasa\,\ Bihar";
$areanames{en}->{9165832} = "Kharsawa\,\ Bihar";
$areanames{en}->{9165833} = "Kharsawa\,\ Bihar";
$areanames{en}->{9165834} = "Kharsawa\,\ Bihar";
$areanames{en}->{9165835} = "Kharsawa\,\ Bihar";
$areanames{en}->{9165836} = "Kharsawa\,\ Bihar";
$areanames{en}->{9165837} = "Kharsawa\,\ Bihar";
$areanames{en}->{9165842} = "Bishrampur\,\ Bihar";
$areanames{en}->{9165843} = "Bishrampur\,\ Bihar";
$areanames{en}->{9165844} = "Bishrampur\,\ Bihar";
$areanames{en}->{9165845} = "Bishrampur\,\ Bihar";
$areanames{en}->{9165846} = "Bishrampur\,\ Bihar";
$areanames{en}->{9165847} = "Bishrampur\,\ Bihar";
$areanames{en}->{9165852} = "Ghatsila\,\ Bihar";
$areanames{en}->{9165853} = "Ghatsila\,\ Bihar";
$areanames{en}->{9165854} = "Ghatsila\,\ Bihar";
$areanames{en}->{9165855} = "Ghatsila\,\ Bihar";
$areanames{en}->{9165856} = "Ghatsila\,\ Bihar";
$areanames{en}->{9165857} = "Ghatsila\,\ Bihar";
$areanames{en}->{9165862} = "Chainpur\,\ Bihar";
$areanames{en}->{9165863} = "Chainpur\,\ Bihar";
$areanames{en}->{9165864} = "Chainpur\,\ Bihar";
$areanames{en}->{9165865} = "Chainpur\,\ Bihar";
$areanames{en}->{9165866} = "Chainpur\,\ Bihar";
$areanames{en}->{9165867} = "Chainpur\,\ Bihar";
$areanames{en}->{9165872} = "Chakardharpur\,\ Bihar";
$areanames{en}->{9165873} = "Chakardharpur\,\ Bihar";
$areanames{en}->{9165874} = "Chakardharpur\,\ Bihar";
$areanames{en}->{9165875} = "Chakardharpur\,\ Bihar";
$areanames{en}->{9165876} = "Chakardharpur\,\ Bihar";
$areanames{en}->{9165877} = "Chakardharpur\,\ Bihar";
$areanames{en}->{9165882} = "Jagarnathpur\,\ Bihar";
$areanames{en}->{9165883} = "Jagarnathpur\,\ Bihar";
$areanames{en}->{9165884} = "Jagarnathpur\,\ Bihar";
$areanames{en}->{9165885} = "Jagarnathpur\,\ Bihar";
$areanames{en}->{9165886} = "Jagarnathpur\,\ Bihar";
$areanames{en}->{9165887} = "Jagarnathpur\,\ Bihar";
$areanames{en}->{9165892} = "Jhinkpani\,\ Bihar";
$areanames{en}->{9165893} = "Jhinkpani\,\ Bihar";
$areanames{en}->{9165894} = "Jhinkpani\,\ Bihar";
$areanames{en}->{9165895} = "Jhinkpani\,\ Bihar";
$areanames{en}->{9165896} = "Jhinkpani\,\ Bihar";
$areanames{en}->{9165897} = "Jhinkpani\,\ Bihar";
$areanames{en}->{9165912} = "Chandil\,\ Bihar";
$areanames{en}->{9165913} = "Chandil\,\ Bihar";
$areanames{en}->{9165914} = "Chandil\,\ Bihar";
$areanames{en}->{9165915} = "Chandil\,\ Bihar";
$areanames{en}->{9165916} = "Chandil\,\ Bihar";
$areanames{en}->{9165917} = "Chandil\,\ Bihar";
$areanames{en}->{9165932} = "Manoharpur\,\ Bihar";
$areanames{en}->{9165933} = "Manoharpur\,\ Bihar";
$areanames{en}->{9165934} = "Manoharpur\,\ Bihar";
$areanames{en}->{9165935} = "Manoharpur\,\ Bihar";
$areanames{en}->{9165936} = "Manoharpur\,\ Bihar";
$areanames{en}->{9165937} = "Manoharpur\,\ Bihar";
$areanames{en}->{9165942} = "Baharagora\,\ Bihar";
$areanames{en}->{9165943} = "Baharagora\,\ Bihar";
$areanames{en}->{9165944} = "Baharagora\,\ Bihar";
$areanames{en}->{9165945} = "Baharagora\,\ Bihar";
$areanames{en}->{9165946} = "Baharagora\,\ Bihar";
$areanames{en}->{9165947} = "Baharagora\,\ Bihar";
$areanames{en}->{9165962} = "Noamundi\,\ Bihar";
$areanames{en}->{9165963} = "Noamundi\,\ Bihar";
$areanames{en}->{9165964} = "Noamundi\,\ Bihar";
$areanames{en}->{9165965} = "Noamundi\,\ Bihar";
$areanames{en}->{9165966} = "Noamundi\,\ Bihar";
$areanames{en}->{9165967} = "Noamundi\,\ Bihar";
$areanames{en}->{9165972} = "Saraikela\/Adstyapur\,\ Bihar";
$areanames{en}->{9165973} = "Saraikela\/Adstyapur\,\ Bihar";
$areanames{en}->{9165974} = "Saraikela\/Adstyapur\,\ Bihar";
$areanames{en}->{9165975} = "Saraikela\/Adstyapur\,\ Bihar";
$areanames{en}->{9165976} = "Saraikela\/Adstyapur\,\ Bihar";
$areanames{en}->{9165977} = "Saraikela\/Adstyapur\,\ Bihar";
$areanames{en}->{916612} = "Rourkela\,\ Odisha";
$areanames{en}->{916613} = "Rourkela\,\ Odisha";
$areanames{en}->{916614} = "Rourkela\,\ Odisha";
$areanames{en}->{916615} = "Rourkela\,\ Odisha";
$areanames{en}->{916616} = "Rourkela\,\ Odisha";
$areanames{en}->{916617} = "Rourkela\,\ Odisha";
$areanames{en}->{9166212} = "Hemgiri\,\ Odisha";
$areanames{en}->{9166213} = "Hemgiri\,\ Odisha";
$areanames{en}->{9166214} = "Hemgiri\,\ Odisha";
$areanames{en}->{9166215} = "Hemgiri\,\ Odisha";
$areanames{en}->{9166216} = "Hemgiri\,\ Odisha";
$areanames{en}->{9166217} = "Hemgiri\,\ Odisha";
$areanames{en}->{9166222} = "Sundargarh\,\ Odisha";
$areanames{en}->{9166223} = "Sundargarh\,\ Odisha";
$areanames{en}->{9166224} = "Sundargarh\,\ Odisha";
$areanames{en}->{9166225} = "Sundargarh\,\ Odisha";
$areanames{en}->{9166226} = "Sundargarh\,\ Odisha";
$areanames{en}->{9166227} = "Sundargarh\,\ Odisha";
$areanames{en}->{9166242} = "Rajgangpur\,\ Odisha";
$areanames{en}->{9166243} = "Rajgangpur\,\ Odisha";
$areanames{en}->{9166244} = "Rajgangpur\,\ Odisha";
$areanames{en}->{9166245} = "Rajgangpur\,\ Odisha";
$areanames{en}->{9166246} = "Rajgangpur\,\ Odisha";
$areanames{en}->{9166247} = "Rajgangpur\,\ Odisha";
$areanames{en}->{9166252} = "Lahunipara\,\ Odisha";
$areanames{en}->{9166253} = "Lahunipara\,\ Odisha";
$areanames{en}->{9166254} = "Lahunipara\,\ Odisha";
$areanames{en}->{9166255} = "Lahunipara\,\ Odisha";
$areanames{en}->{9166256} = "Lahunipara\,\ Odisha";
$areanames{en}->{9166257} = "Lahunipara\,\ Odisha";
$areanames{en}->{9166262} = "Banaigarh\,\ Odisha";
$areanames{en}->{9166263} = "Banaigarh\,\ Odisha";
$areanames{en}->{9166264} = "Banaigarh\,\ Odisha";
$areanames{en}->{9166265} = "Banaigarh\,\ Odisha";
$areanames{en}->{9166266} = "Banaigarh\,\ Odisha";
$areanames{en}->{9166267} = "Banaigarh\,\ Odisha";
$areanames{en}->{916632} = "Sambalpur\,\ Odisha";
$areanames{en}->{916633} = "Sambalpur\,\ Odisha";
$areanames{en}->{916634} = "Sambalpur\,\ Odisha";
$areanames{en}->{916635} = "Sambalpur\,\ Odisha";
$areanames{en}->{916636} = "Sambalpur\,\ Odisha";
$areanames{en}->{916637} = "Sambalpur\,\ Odisha";
$areanames{en}->{9166402} = "Bagdihi\,\ Odisha";
$areanames{en}->{9166403} = "Bagdihi\,\ Odisha";
$areanames{en}->{9166404} = "Bagdihi\,\ Odisha";
$areanames{en}->{9166405} = "Bagdihi\,\ Odisha";
$areanames{en}->{9166406} = "Bagdihi\,\ Odisha";
$areanames{en}->{9166407} = "Bagdihi\,\ Odisha";
$areanames{en}->{9166412} = "Deodgarh\,\ Odisha";
$areanames{en}->{9166413} = "Deodgarh\,\ Odisha";
$areanames{en}->{9166414} = "Deodgarh\,\ Odisha";
$areanames{en}->{9166415} = "Deodgarh\,\ Odisha";
$areanames{en}->{9166416} = "Deodgarh\,\ Odisha";
$areanames{en}->{9166417} = "Deodgarh\,\ Odisha";
$areanames{en}->{9166422} = "Kuchinda\,\ Odisha";
$areanames{en}->{9166423} = "Kuchinda\,\ Odisha";
$areanames{en}->{9166424} = "Kuchinda\,\ Odisha";
$areanames{en}->{9166425} = "Kuchinda\,\ Odisha";
$areanames{en}->{9166426} = "Kuchinda\,\ Odisha";
$areanames{en}->{9166427} = "Kuchinda\,\ Odisha";
$areanames{en}->{9166432} = "Barkot\,\ Odisha";
$areanames{en}->{9166433} = "Barkot\,\ Odisha";
$areanames{en}->{9166434} = "Barkot\,\ Odisha";
$areanames{en}->{9166435} = "Barkot\,\ Odisha";
$areanames{en}->{9166436} = "Barkot\,\ Odisha";
$areanames{en}->{9166437} = "Barkot\,\ Odisha";
$areanames{en}->{9166442} = "Rairakhol\,\ Odisha";
$areanames{en}->{9166443} = "Rairakhol\,\ Odisha";
$areanames{en}->{9166444} = "Rairakhol\,\ Odisha";
$areanames{en}->{9166445} = "Rairakhol\,\ Odisha";
$areanames{en}->{9166446} = "Rairakhol\,\ Odisha";
$areanames{en}->{9166447} = "Rairakhol\,\ Odisha";
$areanames{en}->{9166452} = "Jharsuguda\,\ Odisha";
$areanames{en}->{9166453} = "Jharsuguda\,\ Odisha";
$areanames{en}->{9166454} = "Jharsuguda\,\ Odisha";
$areanames{en}->{9166455} = "Jharsuguda\,\ Odisha";
$areanames{en}->{9166456} = "Jharsuguda\,\ Odisha";
$areanames{en}->{9166457} = "Jharsuguda\,\ Odisha";
$areanames{en}->{9166462} = "Bargarh\,\ Odisha";
$areanames{en}->{9166463} = "Bargarh\,\ Odisha";
$areanames{en}->{9166464} = "Bargarh\,\ Odisha";
$areanames{en}->{9166465} = "Bargarh\,\ Odisha";
$areanames{en}->{9166466} = "Bargarh\,\ Odisha";
$areanames{en}->{9166467} = "Bargarh\,\ Odisha";
$areanames{en}->{9166472} = "Naktideul\,\ Odisha";
$areanames{en}->{9166473} = "Naktideul\,\ Odisha";
$areanames{en}->{9166474} = "Naktideul\,\ Odisha";
$areanames{en}->{9166475} = "Naktideul\,\ Odisha";
$areanames{en}->{9166476} = "Naktideul\,\ Odisha";
$areanames{en}->{9166477} = "Naktideul\,\ Odisha";
$areanames{en}->{9166482} = "Patnagarh\,\ Odisha";
$areanames{en}->{9166483} = "Patnagarh\,\ Odisha";
$areanames{en}->{9166484} = "Patnagarh\,\ Odisha";
$areanames{en}->{9166485} = "Patnagarh\,\ Odisha";
$areanames{en}->{9166486} = "Patnagarh\,\ Odisha";
$areanames{en}->{9166487} = "Patnagarh\,\ Odisha";
$areanames{en}->{9166492} = "Jamankira\,\ Odisha";
$areanames{en}->{9166493} = "Jamankira\,\ Odisha";
$areanames{en}->{9166494} = "Jamankira\,\ Odisha";
$areanames{en}->{9166495} = "Jamankira\,\ Odisha";
$areanames{en}->{9166496} = "Jamankira\,\ Odisha";
$areanames{en}->{9166497} = "Jamankira\,\ Odisha";
$areanames{en}->{9166512} = "Birmaharajpur\,\ Odisha";
$areanames{en}->{9166513} = "Birmaharajpur\,\ Odisha";
$areanames{en}->{9166514} = "Birmaharajpur\,\ Odisha";
$areanames{en}->{9166515} = "Birmaharajpur\,\ Odisha";
$areanames{en}->{9166516} = "Birmaharajpur\,\ Odisha";
$areanames{en}->{9166517} = "Birmaharajpur\,\ Odisha";
$areanames{en}->{9166522} = "Balangir\,\ Odisha";
$areanames{en}->{9166523} = "Balangir\,\ Odisha";
$areanames{en}->{9166524} = "Balangir\,\ Odisha";
$areanames{en}->{9166525} = "Balangir\,\ Odisha";
$areanames{en}->{9166526} = "Balangir\,\ Odisha";
$areanames{en}->{9166527} = "Balangir\,\ Odisha";
$areanames{en}->{9166532} = "Dunguripali\,\ Odisha";
$areanames{en}->{9166533} = "Dunguripali\,\ Odisha";
$areanames{en}->{9166534} = "Dunguripali\,\ Odisha";
$areanames{en}->{9166535} = "Dunguripali\,\ Odisha";
$areanames{en}->{9166536} = "Dunguripali\,\ Odisha";
$areanames{en}->{9166537} = "Dunguripali\,\ Odisha";
$areanames{en}->{9166542} = "Sonapur\,\ Odisha";
$areanames{en}->{9166543} = "Sonapur\,\ Odisha";
$areanames{en}->{9166544} = "Sonapur\,\ Odisha";
$areanames{en}->{9166545} = "Sonapur\,\ Odisha";
$areanames{en}->{9166546} = "Sonapur\,\ Odisha";
$areanames{en}->{9166547} = "Sonapur\,\ Odisha";
$areanames{en}->{9166552} = "Titlagarh\,\ Odisha";
$areanames{en}->{9166553} = "Titlagarh\,\ Odisha";
$areanames{en}->{9166554} = "Titlagarh\,\ Odisha";
$areanames{en}->{9166555} = "Titlagarh\,\ Odisha";
$areanames{en}->{9166556} = "Titlagarh\,\ Odisha";
$areanames{en}->{9166557} = "Titlagarh\,\ Odisha";
$areanames{en}->{9166572} = "Kantabhanji\,\ Odisha";
$areanames{en}->{9166573} = "Kantabhanji\,\ Odisha";
$areanames{en}->{9166574} = "Kantabhanji\,\ Odisha";
$areanames{en}->{9166575} = "Kantabhanji\,\ Odisha";
$areanames{en}->{9166576} = "Kantabhanji\,\ Odisha";
$areanames{en}->{9166577} = "Kantabhanji\,\ Odisha";
$areanames{en}->{9166702} = "Bhawanipatna\,\ Odisha";
$areanames{en}->{9166703} = "Bhawanipatna\,\ Odisha";
$areanames{en}->{9166704} = "Bhawanipatna\,\ Odisha";
$areanames{en}->{9166705} = "Bhawanipatna\,\ Odisha";
$areanames{en}->{9166706} = "Bhawanipatna\,\ Odisha";
$areanames{en}->{9166707} = "Bhawanipatna\,\ Odisha";
$areanames{en}->{9166712} = "Rajkhariar\,\ Odisha";
$areanames{en}->{9166713} = "Rajkhariar\,\ Odisha";
$areanames{en}->{9166714} = "Rajkhariar\,\ Odisha";
$areanames{en}->{9166715} = "Rajkhariar\,\ Odisha";
$areanames{en}->{9166716} = "Rajkhariar\,\ Odisha";
$areanames{en}->{9166717} = "Rajkhariar\,\ Odisha";
$areanames{en}->{9166722} = "Dharamgarh\,\ Odisha";
$areanames{en}->{9166723} = "Dharamgarh\,\ Odisha";
$areanames{en}->{9166724} = "Dharamgarh\,\ Odisha";
$areanames{en}->{9166725} = "Dharamgarh\,\ Odisha";
$areanames{en}->{9166726} = "Dharamgarh\,\ Odisha";
$areanames{en}->{9166727} = "Dharamgarh\,\ Odisha";
$areanames{en}->{9166732} = "Jayapatna\,\ Odisha";
$areanames{en}->{9166733} = "Jayapatna\,\ Odisha";
$areanames{en}->{9166734} = "Jayapatna\,\ Odisha";
$areanames{en}->{9166735} = "Jayapatna\,\ Odisha";
$areanames{en}->{9166736} = "Jayapatna\,\ Odisha";
$areanames{en}->{9166737} = "Jayapatna\,\ Odisha";
$areanames{en}->{9166752} = "T\.Rampur\,\ Odisha";
$areanames{en}->{9166753} = "T\.Rampur\,\ Odisha";
$areanames{en}->{9166754} = "T\.Rampur\,\ Odisha";
$areanames{en}->{9166755} = "T\.Rampur\,\ Odisha";
$areanames{en}->{9166756} = "T\.Rampur\,\ Odisha";
$areanames{en}->{9166757} = "T\.Rampur\,\ Odisha";
$areanames{en}->{9166762} = "M\.Rampur\,\ Odisha";
$areanames{en}->{9166763} = "M\.Rampur\,\ Odisha";
$areanames{en}->{9166764} = "M\.Rampur\,\ Odisha";
$areanames{en}->{9166765} = "M\.Rampur\,\ Odisha";
$areanames{en}->{9166766} = "M\.Rampur\,\ Odisha";
$areanames{en}->{9166767} = "M\.Rampur\,\ Odisha";
$areanames{en}->{9166772} = "Narlaroad\,\ Odisha";
$areanames{en}->{9166773} = "Narlaroad\,\ Odisha";
$areanames{en}->{9166774} = "Narlaroad\,\ Odisha";
$areanames{en}->{9166775} = "Narlaroad\,\ Odisha";
$areanames{en}->{9166776} = "Narlaroad\,\ Odisha";
$areanames{en}->{9166777} = "Narlaroad\,\ Odisha";
$areanames{en}->{9166782} = "Nowparatan\,\ Odisha";
$areanames{en}->{9166783} = "Nowparatan\,\ Odisha";
$areanames{en}->{9166784} = "Nowparatan\,\ Odisha";
$areanames{en}->{9166785} = "Nowparatan\,\ Odisha";
$areanames{en}->{9166786} = "Nowparatan\,\ Odisha";
$areanames{en}->{9166787} = "Nowparatan\,\ Odisha";
$areanames{en}->{9166792} = "Komana\,\ Odisha";
$areanames{en}->{9166793} = "Komana\,\ Odisha";
$areanames{en}->{9166794} = "Komana\,\ Odisha";
$areanames{en}->{9166795} = "Komana\,\ Odisha";
$areanames{en}->{9166796} = "Komana\,\ Odisha";
$areanames{en}->{9166797} = "Komana\,\ Odisha";
$areanames{en}->{9166812} = "Jujumura\,\ Odisha";
$areanames{en}->{9166813} = "Jujumura\,\ Odisha";
$areanames{en}->{9166814} = "Jujumura\,\ Odisha";
$areanames{en}->{9166815} = "Jujumura\,\ Odisha";
$areanames{en}->{9166816} = "Jujumura\,\ Odisha";
$areanames{en}->{9166817} = "Jujumura\,\ Odisha";
$areanames{en}->{9166822} = "Attabira\,\ Odisha";
$areanames{en}->{9166823} = "Attabira\,\ Odisha";
$areanames{en}->{9166824} = "Attabira\,\ Odisha";
$areanames{en}->{9166825} = "Attabira\,\ Odisha";
$areanames{en}->{9166826} = "Attabira\,\ Odisha";
$areanames{en}->{9166827} = "Attabira\,\ Odisha";
$areanames{en}->{9166832} = "Padmapur\,\ Odisha";
$areanames{en}->{9166833} = "Padmapur\,\ Odisha";
$areanames{en}->{9166834} = "Padmapur\,\ Odisha";
$areanames{en}->{9166835} = "Padmapur\,\ Odisha";
$areanames{en}->{9166836} = "Padmapur\,\ Odisha";
$areanames{en}->{9166837} = "Padmapur\,\ Odisha";
$areanames{en}->{9166842} = "Paikamal\,\ Odisha";
$areanames{en}->{9166843} = "Paikamal\,\ Odisha";
$areanames{en}->{9166844} = "Paikamal\,\ Odisha";
$areanames{en}->{9166845} = "Paikamal\,\ Odisha";
$areanames{en}->{9166846} = "Paikamal\,\ Odisha";
$areanames{en}->{9166847} = "Paikamal\,\ Odisha";
$areanames{en}->{9166852} = "Sohela\,\ Odisha";
$areanames{en}->{9166853} = "Sohela\,\ Odisha";
$areanames{en}->{9166854} = "Sohela\,\ Odisha";
$areanames{en}->{9166855} = "Sohela\,\ Odisha";
$areanames{en}->{9166856} = "Sohela\,\ Odisha";
$areanames{en}->{9166857} = "Sohela\,\ Odisha";
$areanames{en}->{916712} = "Cuttack\,\ Odisha";
$areanames{en}->{916713} = "Cuttack\,\ Odisha";
$areanames{en}->{916714} = "Cuttack\,\ Odisha";
$areanames{en}->{916715} = "Cuttack\,\ Odisha";
$areanames{en}->{916716} = "Cuttack\,\ Odisha";
$areanames{en}->{916717} = "Cuttack\,\ Odisha";
$areanames{en}->{9167212} = "Narsinghpur\,\ Odisha";
$areanames{en}->{9167213} = "Narsinghpur\,\ Odisha";
$areanames{en}->{9167214} = "Narsinghpur\,\ Odisha";
$areanames{en}->{9167215} = "Narsinghpur\,\ Odisha";
$areanames{en}->{9167216} = "Narsinghpur\,\ Odisha";
$areanames{en}->{9167217} = "Narsinghpur\,\ Odisha";
$areanames{en}->{9167222} = "Pardip\,\ Odisha";
$areanames{en}->{9167223} = "Pardip\,\ Odisha";
$areanames{en}->{9167224} = "Pardip\,\ Odisha";
$areanames{en}->{9167225} = "Pardip\,\ Odisha";
$areanames{en}->{9167226} = "Pardip\,\ Odisha";
$areanames{en}->{9167227} = "Pardip\,\ Odisha";
$areanames{en}->{9167232} = "Athgarh\,\ Odisha";
$areanames{en}->{9167233} = "Athgarh\,\ Odisha";
$areanames{en}->{9167234} = "Athgarh\,\ Odisha";
$areanames{en}->{9167235} = "Athgarh\,\ Odisha";
$areanames{en}->{9167236} = "Athgarh\,\ Odisha";
$areanames{en}->{9167237} = "Athgarh\,\ Odisha";
$areanames{en}->{9167242} = "Jagatsinghpur\,\ Odisha";
$areanames{en}->{9167243} = "Jagatsinghpur\,\ Odisha";
$areanames{en}->{9167244} = "Jagatsinghpur\,\ Odisha";
$areanames{en}->{9167245} = "Jagatsinghpur\,\ Odisha";
$areanames{en}->{9167246} = "Jagatsinghpur\,\ Odisha";
$areanames{en}->{9167247} = "Jagatsinghpur\,\ Odisha";
$areanames{en}->{9167252} = "Dhanmandal\,\ Odisha";
$areanames{en}->{9167253} = "Dhanmandal\,\ Odisha";
$areanames{en}->{9167254} = "Dhanmandal\,\ Odisha";
$areanames{en}->{9167255} = "Dhanmandal\,\ Odisha";
$areanames{en}->{9167256} = "Dhanmandal\,\ Odisha";
$areanames{en}->{9167257} = "Dhanmandal\,\ Odisha";
$areanames{en}->{9167262} = "Jajapur\ Road\,\ Odisha";
$areanames{en}->{9167263} = "Jajapur\ Road\,\ Odisha";
$areanames{en}->{9167264} = "Jajapur\ Road\,\ Odisha";
$areanames{en}->{9167265} = "Jajapur\ Road\,\ Odisha";
$areanames{en}->{9167266} = "Jajapur\ Road\,\ Odisha";
$areanames{en}->{9167267} = "Jajapur\ Road\,\ Odisha";
$areanames{en}->{9167272} = "Kendrapara\,\ Odisha";
$areanames{en}->{9167273} = "Kendrapara\,\ Odisha";
$areanames{en}->{9167274} = "Kendrapara\,\ Odisha";
$areanames{en}->{9167275} = "Kendrapara\,\ Odisha";
$areanames{en}->{9167276} = "Kendrapara\,\ Odisha";
$areanames{en}->{9167277} = "Kendrapara\,\ Odisha";
$areanames{en}->{9167282} = "Jajapur\ Town\,\ Odisha";
$areanames{en}->{9167283} = "Jajapur\ Town\,\ Odisha";
$areanames{en}->{9167284} = "Jajapur\ Town\,\ Odisha";
$areanames{en}->{9167285} = "Jajapur\ Town\,\ Odisha";
$areanames{en}->{9167286} = "Jajapur\ Town\,\ Odisha";
$areanames{en}->{9167287} = "Jajapur\ Town\,\ Odisha";
$areanames{en}->{9167292} = "Pattamundai\,\ Odisha";
$areanames{en}->{9167293} = "Pattamundai\,\ Odisha";
$areanames{en}->{9167294} = "Pattamundai\,\ Odisha";
$areanames{en}->{9167295} = "Pattamundai\,\ Odisha";
$areanames{en}->{9167296} = "Pattamundai\,\ Odisha";
$areanames{en}->{9167297} = "Pattamundai\,\ Odisha";
$areanames{en}->{9167312} = "Anandapur\,\ Odisha";
$areanames{en}->{9167313} = "Anandapur\,\ Odisha";
$areanames{en}->{9167314} = "Anandapur\,\ Odisha";
$areanames{en}->{9167315} = "Anandapur\,\ Odisha";
$areanames{en}->{9167316} = "Anandapur\,\ Odisha";
$areanames{en}->{9167317} = "Anandapur\,\ Odisha";
$areanames{en}->{9167322} = "Hindol\,\ Odisha";
$areanames{en}->{9167323} = "Hindol\,\ Odisha";
$areanames{en}->{9167324} = "Hindol\,\ Odisha";
$areanames{en}->{9167325} = "Hindol\,\ Odisha";
$areanames{en}->{9167326} = "Hindol\,\ Odisha";
$areanames{en}->{9167327} = "Hindol\,\ Odisha";
$areanames{en}->{9167332} = "Ghatgaon\,\ Odisha";
$areanames{en}->{9167333} = "Ghatgaon\,\ Odisha";
$areanames{en}->{9167334} = "Ghatgaon\,\ Odisha";
$areanames{en}->{9167335} = "Ghatgaon\,\ Odisha";
$areanames{en}->{9167336} = "Ghatgaon\,\ Odisha";
$areanames{en}->{9167337} = "Ghatgaon\,\ Odisha";
$areanames{en}->{9167352} = "Telkoi\,\ Odisha";
$areanames{en}->{9167353} = "Telkoi\,\ Odisha";
$areanames{en}->{9167354} = "Telkoi\,\ Odisha";
$areanames{en}->{9167355} = "Telkoi\,\ Odisha";
$areanames{en}->{9167356} = "Telkoi\,\ Odisha";
$areanames{en}->{9167357} = "Telkoi\,\ Odisha";
$areanames{en}->{9167402} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167403} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167404} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167405} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167406} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167407} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167412} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167413} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167414} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167415} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167416} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167417} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{916742} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{916743} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{916744} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{916745} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{916746} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{916747} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167482} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167483} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167484} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167485} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167486} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167487} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167492} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167493} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167494} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167495} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167496} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167497} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{9167522} = "Puri\,\ Odisha";
$areanames{en}->{9167523} = "Puri\,\ Odisha";
$areanames{en}->{9167524} = "Puri\,\ Odisha";
$areanames{en}->{9167525} = "Puri\,\ Odisha";
$areanames{en}->{9167526} = "Puri\,\ Odisha";
$areanames{en}->{9167527} = "Puri\,\ Odisha";
$areanames{en}->{9167532} = "Nayagarh\,\ Odisha";
$areanames{en}->{9167533} = "Nayagarh\,\ Odisha";
$areanames{en}->{9167534} = "Nayagarh\,\ Odisha";
$areanames{en}->{9167535} = "Nayagarh\,\ Odisha";
$areanames{en}->{9167536} = "Nayagarh\,\ Odisha";
$areanames{en}->{9167537} = "Nayagarh\,\ Odisha";
$areanames{en}->{9167552} = "Khurda\,\ Odisha";
$areanames{en}->{9167553} = "Khurda\,\ Odisha";
$areanames{en}->{9167554} = "Khurda\,\ Odisha";
$areanames{en}->{9167555} = "Khurda\,\ Odisha";
$areanames{en}->{9167556} = "Khurda\,\ Odisha";
$areanames{en}->{9167557} = "Khurda\,\ Odisha";
$areanames{en}->{9167562} = "Balugaon\,\ Odisha";
$areanames{en}->{9167563} = "Balugaon\,\ Odisha";
$areanames{en}->{9167564} = "Balugaon\,\ Odisha";
$areanames{en}->{9167565} = "Balugaon\,\ Odisha";
$areanames{en}->{9167566} = "Balugaon\,\ Odisha";
$areanames{en}->{9167567} = "Balugaon\,\ Odisha";
$areanames{en}->{9167572} = "Daspalla\,\ Odisha";
$areanames{en}->{9167573} = "Daspalla\,\ Odisha";
$areanames{en}->{9167574} = "Daspalla\,\ Odisha";
$areanames{en}->{9167575} = "Daspalla\,\ Odisha";
$areanames{en}->{9167576} = "Daspalla\,\ Odisha";
$areanames{en}->{9167577} = "Daspalla\,\ Odisha";
$areanames{en}->{9167582} = "Nimapara\,\ Odisha";
$areanames{en}->{9167583} = "Nimapara\,\ Odisha";
$areanames{en}->{9167584} = "Nimapara\,\ Odisha";
$areanames{en}->{9167585} = "Nimapara\,\ Odisha";
$areanames{en}->{9167586} = "Nimapara\,\ Odisha";
$areanames{en}->{9167587} = "Nimapara\,\ Odisha";
$areanames{en}->{9167602} = "Talcher\,\ Odisha";
$areanames{en}->{9167603} = "Talcher\,\ Odisha";
$areanames{en}->{9167604} = "Talcher\,\ Odisha";
$areanames{en}->{9167605} = "Talcher\,\ Odisha";
$areanames{en}->{9167606} = "Talcher\,\ Odisha";
$areanames{en}->{9167607} = "Talcher\,\ Odisha";
$areanames{en}->{9167612} = "Chhendipada\,\ Odisha";
$areanames{en}->{9167613} = "Chhendipada\,\ Odisha";
$areanames{en}->{9167614} = "Chhendipada\,\ Odisha";
$areanames{en}->{9167615} = "Chhendipada\,\ Odisha";
$areanames{en}->{9167616} = "Chhendipada\,\ Odisha";
$areanames{en}->{9167617} = "Chhendipada\,\ Odisha";
$areanames{en}->{9167622} = "Dhenkanal\,\ Odisha";
$areanames{en}->{9167623} = "Dhenkanal\,\ Odisha";
$areanames{en}->{9167624} = "Dhenkanal\,\ Odisha";
$areanames{en}->{9167625} = "Dhenkanal\,\ Odisha";
$areanames{en}->{9167626} = "Dhenkanal\,\ Odisha";
$areanames{en}->{9167627} = "Dhenkanal\,\ Odisha";
$areanames{en}->{9167632} = "Athmallik\,\ Odisha";
$areanames{en}->{9167633} = "Athmallik\,\ Odisha";
$areanames{en}->{9167634} = "Athmallik\,\ Odisha";
$areanames{en}->{9167635} = "Athmallik\,\ Odisha";
$areanames{en}->{9167636} = "Athmallik\,\ Odisha";
$areanames{en}->{9167637} = "Athmallik\,\ Odisha";
$areanames{en}->{9167642} = "Anugul\,\ Odisha";
$areanames{en}->{9167643} = "Anugul\,\ Odisha";
$areanames{en}->{9167644} = "Anugul\,\ Odisha";
$areanames{en}->{9167645} = "Anugul\,\ Odisha";
$areanames{en}->{9167646} = "Anugul\,\ Odisha";
$areanames{en}->{9167647} = "Anugul\,\ Odisha";
$areanames{en}->{9167652} = "Palla\ Hara\,\ Odisha";
$areanames{en}->{9167653} = "Palla\ Hara\,\ Odisha";
$areanames{en}->{9167654} = "Palla\ Hara\,\ Odisha";
$areanames{en}->{9167655} = "Palla\ Hara\,\ Odisha";
$areanames{en}->{9167656} = "Palla\ Hara\,\ Odisha";
$areanames{en}->{9167657} = "Palla\ Hara\,\ Odisha";
$areanames{en}->{9167662} = "Keonjhar\,\ Odisha";
$areanames{en}->{9167663} = "Keonjhar\,\ Odisha";
$areanames{en}->{9167664} = "Keonjhar\,\ Odisha";
$areanames{en}->{9167665} = "Keonjhar\,\ Odisha";
$areanames{en}->{9167666} = "Keonjhar\,\ Odisha";
$areanames{en}->{9167667} = "Keonjhar\,\ Odisha";
$areanames{en}->{9167672} = "Barbil\,\ Odisha";
$areanames{en}->{9167673} = "Barbil\,\ Odisha";
$areanames{en}->{9167674} = "Barbil\,\ Odisha";
$areanames{en}->{9167675} = "Barbil\,\ Odisha";
$areanames{en}->{9167676} = "Barbil\,\ Odisha";
$areanames{en}->{9167677} = "Barbil\,\ Odisha";
$areanames{en}->{9167682} = "Parajang\,\ Odisha";
$areanames{en}->{9167683} = "Parajang\,\ Odisha";
$areanames{en}->{9167684} = "Parajang\,\ Odisha";
$areanames{en}->{9167685} = "Parajang\,\ Odisha";
$areanames{en}->{9167686} = "Parajang\,\ Odisha";
$areanames{en}->{9167687} = "Parajang\,\ Odisha";
$areanames{en}->{9167692} = "Kamakhyanagar\,\ Odisha";
$areanames{en}->{9167693} = "Kamakhyanagar\,\ Odisha";
$areanames{en}->{9167694} = "Kamakhyanagar\,\ Odisha";
$areanames{en}->{9167695} = "Kamakhyanagar\,\ Odisha";
$areanames{en}->{9167696} = "Kamakhyanagar\,\ Odisha";
$areanames{en}->{9167697} = "Kamakhyanagar\,\ Odisha";
$areanames{en}->{9167812} = "Basta\,\ Odisha";
$areanames{en}->{9167813} = "Basta\,\ Odisha";
$areanames{en}->{9167814} = "Basta\,\ Odisha";
$areanames{en}->{9167815} = "Basta\,\ Odisha";
$areanames{en}->{9167816} = "Basta\,\ Odisha";
$areanames{en}->{9167817} = "Basta\,\ Odisha";
$areanames{en}->{9167822} = "Balasore\,\ Odisha";
$areanames{en}->{9167823} = "Balasore\,\ Odisha";
$areanames{en}->{9167824} = "Balasore\,\ Odisha";
$areanames{en}->{9167825} = "Balasore\,\ Odisha";
$areanames{en}->{9167826} = "Balasore\,\ Odisha";
$areanames{en}->{9167827} = "Balasore\,\ Odisha";
$areanames{en}->{9167842} = "Bhadrak\,\ Odisha";
$areanames{en}->{9167843} = "Bhadrak\,\ Odisha";
$areanames{en}->{9167844} = "Bhadrak\,\ Odisha";
$areanames{en}->{9167845} = "Bhadrak\,\ Odisha";
$areanames{en}->{9167846} = "Bhadrak\,\ Odisha";
$areanames{en}->{9167847} = "Bhadrak\,\ Odisha";
$areanames{en}->{9167862} = "Chandbali\,\ Odisha";
$areanames{en}->{9167863} = "Chandbali\,\ Odisha";
$areanames{en}->{9167864} = "Chandbali\,\ Odisha";
$areanames{en}->{9167865} = "Chandbali\,\ Odisha";
$areanames{en}->{9167866} = "Chandbali\,\ Odisha";
$areanames{en}->{9167867} = "Chandbali\,\ Odisha";
$areanames{en}->{9167882} = "Soro\,\ Odisha";
$areanames{en}->{9167883} = "Soro\,\ Odisha";
$areanames{en}->{9167884} = "Soro\,\ Odisha";
$areanames{en}->{9167885} = "Soro\,\ Odisha";
$areanames{en}->{9167886} = "Soro\,\ Odisha";
$areanames{en}->{9167887} = "Soro\,\ Odisha";
$areanames{en}->{9167912} = "Bangiriposi\,\ Odisha";
$areanames{en}->{9167913} = "Bangiriposi\,\ Odisha";
$areanames{en}->{9167914} = "Bangiriposi\,\ Odisha";
$areanames{en}->{9167915} = "Bangiriposi\,\ Odisha";
$areanames{en}->{9167916} = "Bangiriposi\,\ Odisha";
$areanames{en}->{9167917} = "Bangiriposi\,\ Odisha";
$areanames{en}->{9167922} = "Baripada\,\ Odisha";
$areanames{en}->{9167923} = "Baripada\,\ Odisha";
$areanames{en}->{9167924} = "Baripada\,\ Odisha";
$areanames{en}->{9167925} = "Baripada\,\ Odisha";
$areanames{en}->{9167926} = "Baripada\,\ Odisha";
$areanames{en}->{9167927} = "Baripada\,\ Odisha";
$areanames{en}->{9167932} = "Betanati\,\ Odisha";
$areanames{en}->{9167933} = "Betanati\,\ Odisha";
$areanames{en}->{9167934} = "Betanati\,\ Odisha";
$areanames{en}->{9167935} = "Betanati\,\ Odisha";
$areanames{en}->{9167936} = "Betanati\,\ Odisha";
$areanames{en}->{9167937} = "Betanati\,\ Odisha";
$areanames{en}->{9167942} = "Rairangpur\,\ Odisha";
$areanames{en}->{9167943} = "Rairangpur\,\ Odisha";
$areanames{en}->{9167944} = "Rairangpur\,\ Odisha";
$areanames{en}->{9167945} = "Rairangpur\,\ Odisha";
$areanames{en}->{9167946} = "Rairangpur\,\ Odisha";
$areanames{en}->{9167947} = "Rairangpur\,\ Odisha";
$areanames{en}->{9167952} = "Udala\,\ Odisha";
$areanames{en}->{9167953} = "Udala\,\ Odisha";
$areanames{en}->{9167954} = "Udala\,\ Odisha";
$areanames{en}->{9167955} = "Udala\,\ Odisha";
$areanames{en}->{9167956} = "Udala\,\ Odisha";
$areanames{en}->{9167957} = "Udala\,\ Odisha";
$areanames{en}->{9167962} = "Karanjia\,\ Odisha";
$areanames{en}->{9167963} = "Karanjia\,\ Odisha";
$areanames{en}->{9167964} = "Karanjia\,\ Odisha";
$areanames{en}->{9167965} = "Karanjia\,\ Odisha";
$areanames{en}->{9167966} = "Karanjia\,\ Odisha";
$areanames{en}->{9167967} = "Karanjia\,\ Odisha";
$areanames{en}->{9167972} = "Jashipur\,\ Odisha";
$areanames{en}->{9167973} = "Jashipur\,\ Odisha";
$areanames{en}->{9167974} = "Jashipur\,\ Odisha";
$areanames{en}->{9167975} = "Jashipur\,\ Odisha";
$areanames{en}->{9167976} = "Jashipur\,\ Odisha";
$areanames{en}->{9167977} = "Jashipur\,\ Odisha";
$areanames{en}->{916802} = "Berhampur\,\ Odisha";
$areanames{en}->{916803} = "Berhampur\,\ Odisha";
$areanames{en}->{916804} = "Berhampur\,\ Odisha";
$areanames{en}->{916805} = "Berhampur\,\ Odisha";
$areanames{en}->{916806} = "Berhampur\,\ Odisha";
$areanames{en}->{916807} = "Berhampur\,\ Odisha";
$areanames{en}->{9168102} = "Khalikote\,\ Odisha";
$areanames{en}->{9168103} = "Khalikote\,\ Odisha";
$areanames{en}->{9168104} = "Khalikote\,\ Odisha";
$areanames{en}->{9168105} = "Khalikote\,\ Odisha";
$areanames{en}->{9168106} = "Khalikote\,\ Odisha";
$areanames{en}->{9168107} = "Khalikote\,\ Odisha";
$areanames{en}->{9168112} = "Chhatrapur\,\ Odisha";
$areanames{en}->{9168113} = "Chhatrapur\,\ Odisha";
$areanames{en}->{9168114} = "Chhatrapur\,\ Odisha";
$areanames{en}->{9168115} = "Chhatrapur\,\ Odisha";
$areanames{en}->{9168116} = "Chhatrapur\,\ Odisha";
$areanames{en}->{9168117} = "Chhatrapur\,\ Odisha";
$areanames{en}->{9168142} = "Digapahandi\,\ Odisha";
$areanames{en}->{9168143} = "Digapahandi\,\ Odisha";
$areanames{en}->{9168144} = "Digapahandi\,\ Odisha";
$areanames{en}->{9168145} = "Digapahandi\,\ Odisha";
$areanames{en}->{9168146} = "Digapahandi\,\ Odisha";
$areanames{en}->{9168147} = "Digapahandi\,\ Odisha";
$areanames{en}->{9168152} = "Parlakhemundi\,\ Odisha";
$areanames{en}->{9168153} = "Parlakhemundi\,\ Odisha";
$areanames{en}->{9168154} = "Parlakhemundi\,\ Odisha";
$areanames{en}->{9168155} = "Parlakhemundi\,\ Odisha";
$areanames{en}->{9168156} = "Parlakhemundi\,\ Odisha";
$areanames{en}->{9168157} = "Parlakhemundi\,\ Odisha";
$areanames{en}->{9168162} = "Mohana\,\ Odisha";
$areanames{en}->{9168163} = "Mohana\,\ Odisha";
$areanames{en}->{9168164} = "Mohana\,\ Odisha";
$areanames{en}->{9168165} = "Mohana\,\ Odisha";
$areanames{en}->{9168166} = "Mohana\,\ Odisha";
$areanames{en}->{9168167} = "Mohana\,\ Odisha";
$areanames{en}->{9168172} = "R\.Udayigiri\,\ Odisha";
$areanames{en}->{9168173} = "R\.Udayigiri\,\ Odisha";
$areanames{en}->{9168174} = "R\.Udayigiri\,\ Odisha";
$areanames{en}->{9168175} = "R\.Udayigiri\,\ Odisha";
$areanames{en}->{9168176} = "R\.Udayigiri\,\ Odisha";
$areanames{en}->{9168177} = "R\.Udayigiri\,\ Odisha";
$areanames{en}->{9168182} = "Buguda\,\ Odisha";
$areanames{en}->{9168183} = "Buguda\,\ Odisha";
$areanames{en}->{9168184} = "Buguda\,\ Odisha";
$areanames{en}->{9168185} = "Buguda\,\ Odisha";
$areanames{en}->{9168186} = "Buguda\,\ Odisha";
$areanames{en}->{9168187} = "Buguda\,\ Odisha";
$areanames{en}->{9168192} = "Surada\,\ Odisha";
$areanames{en}->{9168193} = "Surada\,\ Odisha";
$areanames{en}->{9168194} = "Surada\,\ Odisha";
$areanames{en}->{9168195} = "Surada\,\ Odisha";
$areanames{en}->{9168196} = "Surada\,\ Odisha";
$areanames{en}->{9168197} = "Surada\,\ Odisha";
$areanames{en}->{9168212} = "Bhanjanagar\,\ Odisha";
$areanames{en}->{9168213} = "Bhanjanagar\,\ Odisha";
$areanames{en}->{9168214} = "Bhanjanagar\,\ Odisha";
$areanames{en}->{9168215} = "Bhanjanagar\,\ Odisha";
$areanames{en}->{9168216} = "Bhanjanagar\,\ Odisha";
$areanames{en}->{9168217} = "Bhanjanagar\,\ Odisha";
$areanames{en}->{9168222} = "Aska\,\ Odisha";
$areanames{en}->{9168223} = "Aska\,\ Odisha";
$areanames{en}->{9168224} = "Aska\,\ Odisha";
$areanames{en}->{9168225} = "Aska\,\ Odisha";
$areanames{en}->{9168226} = "Aska\,\ Odisha";
$areanames{en}->{9168227} = "Aska\,\ Odisha";
$areanames{en}->{9168402} = "Tumudibandha\,\ Odisha";
$areanames{en}->{9168403} = "Tumudibandha\,\ Odisha";
$areanames{en}->{9168404} = "Tumudibandha\,\ Odisha";
$areanames{en}->{9168405} = "Tumudibandha\,\ Odisha";
$areanames{en}->{9168406} = "Tumudibandha\,\ Odisha";
$areanames{en}->{9168407} = "Tumudibandha\,\ Odisha";
$areanames{en}->{9168412} = "Boudh\,\ Odisha";
$areanames{en}->{9168413} = "Boudh\,\ Odisha";
$areanames{en}->{9168414} = "Boudh\,\ Odisha";
$areanames{en}->{9168415} = "Boudh\,\ Odisha";
$areanames{en}->{9168416} = "Boudh\,\ Odisha";
$areanames{en}->{9168417} = "Boudh\,\ Odisha";
$areanames{en}->{9168422} = "Phulbani\,\ Odisha";
$areanames{en}->{9168423} = "Phulbani\,\ Odisha";
$areanames{en}->{9168424} = "Phulbani\,\ Odisha";
$areanames{en}->{9168425} = "Phulbani\,\ Odisha";
$areanames{en}->{9168426} = "Phulbani\,\ Odisha";
$areanames{en}->{9168427} = "Phulbani\,\ Odisha";
$areanames{en}->{9168432} = "Puruna\ Katak\,\ Odisha";
$areanames{en}->{9168433} = "Puruna\ Katak\,\ Odisha";
$areanames{en}->{9168434} = "Puruna\ Katak\,\ Odisha";
$areanames{en}->{9168435} = "Puruna\ Katak\,\ Odisha";
$areanames{en}->{9168436} = "Puruna\ Katak\,\ Odisha";
$areanames{en}->{9168437} = "Puruna\ Katak\,\ Odisha";
$areanames{en}->{9168442} = "Kantamal\,\ Odisha";
$areanames{en}->{9168443} = "Kantamal\,\ Odisha";
$areanames{en}->{9168444} = "Kantamal\,\ Odisha";
$areanames{en}->{9168445} = "Kantamal\,\ Odisha";
$areanames{en}->{9168446} = "Kantamal\,\ Odisha";
$areanames{en}->{9168447} = "Kantamal\,\ Odisha";
$areanames{en}->{9168452} = "Phiringia\,\ Odisha";
$areanames{en}->{9168453} = "Phiringia\,\ Odisha";
$areanames{en}->{9168454} = "Phiringia\,\ Odisha";
$areanames{en}->{9168455} = "Phiringia\,\ Odisha";
$areanames{en}->{9168456} = "Phiringia\,\ Odisha";
$areanames{en}->{9168457} = "Phiringia\,\ Odisha";
$areanames{en}->{9168462} = "Baliguda\,\ Odisha";
$areanames{en}->{9168463} = "Baliguda\,\ Odisha";
$areanames{en}->{9168464} = "Baliguda\,\ Odisha";
$areanames{en}->{9168465} = "Baliguda\,\ Odisha";
$areanames{en}->{9168466} = "Baliguda\,\ Odisha";
$areanames{en}->{9168467} = "Baliguda\,\ Odisha";
$areanames{en}->{9168472} = "G\.Udayagiri\,\ Odisha";
$areanames{en}->{9168473} = "G\.Udayagiri\,\ Odisha";
$areanames{en}->{9168474} = "G\.Udayagiri\,\ Odisha";
$areanames{en}->{9168475} = "G\.Udayagiri\,\ Odisha";
$areanames{en}->{9168476} = "G\.Udayagiri\,\ Odisha";
$areanames{en}->{9168477} = "G\.Udayagiri\,\ Odisha";
$areanames{en}->{9168482} = "Kotagarh\,\ Odisha";
$areanames{en}->{9168483} = "Kotagarh\,\ Odisha";
$areanames{en}->{9168484} = "Kotagarh\,\ Odisha";
$areanames{en}->{9168485} = "Kotagarh\,\ Odisha";
$areanames{en}->{9168486} = "Kotagarh\,\ Odisha";
$areanames{en}->{9168487} = "Kotagarh\,\ Odisha";
$areanames{en}->{9168492} = "Daringbadi\,\ Odisha";
$areanames{en}->{9168493} = "Daringbadi\,\ Odisha";
$areanames{en}->{9168494} = "Daringbadi\,\ Odisha";
$areanames{en}->{9168495} = "Daringbadi\,\ Odisha";
$areanames{en}->{9168496} = "Daringbadi\,\ Odisha";
$areanames{en}->{9168497} = "Daringbadi\,\ Odisha";
$areanames{en}->{9168502} = "Kalimela\,\ Odisha";
$areanames{en}->{9168503} = "Kalimela\,\ Odisha";
$areanames{en}->{9168504} = "Kalimela\,\ Odisha";
$areanames{en}->{9168505} = "Kalimela\,\ Odisha";
$areanames{en}->{9168506} = "Kalimela\,\ Odisha";
$areanames{en}->{9168507} = "Kalimela\,\ Odisha";
$areanames{en}->{9168522} = "Koraput\,\ Odisha";
$areanames{en}->{9168523} = "Koraput\,\ Odisha";
$areanames{en}->{9168524} = "Koraput\,\ Odisha";
$areanames{en}->{9168525} = "Koraput\,\ Odisha";
$areanames{en}->{9168526} = "Koraput\,\ Odisha";
$areanames{en}->{9168527} = "Koraput\,\ Odisha";
$areanames{en}->{9168532} = "Sunabeda\,\ Odisha";
$areanames{en}->{9168533} = "Sunabeda\,\ Odisha";
$areanames{en}->{9168534} = "Sunabeda\,\ Odisha";
$areanames{en}->{9168535} = "Sunabeda\,\ Odisha";
$areanames{en}->{9168536} = "Sunabeda\,\ Odisha";
$areanames{en}->{9168537} = "Sunabeda\,\ Odisha";
$areanames{en}->{9168542} = "Jeypore\,\ Odisha";
$areanames{en}->{9168543} = "Jeypore\,\ Odisha";
$areanames{en}->{9168544} = "Jeypore\,\ Odisha";
$areanames{en}->{9168545} = "Jeypore\,\ Odisha";
$areanames{en}->{9168546} = "Jeypore\,\ Odisha";
$areanames{en}->{9168547} = "Jeypore\,\ Odisha";
$areanames{en}->{9168552} = "Laxmipur\,\ Odisha";
$areanames{en}->{9168553} = "Laxmipur\,\ Odisha";
$areanames{en}->{9168554} = "Laxmipur\,\ Odisha";
$areanames{en}->{9168555} = "Laxmipur\,\ Odisha";
$areanames{en}->{9168556} = "Laxmipur\,\ Odisha";
$areanames{en}->{9168557} = "Laxmipur\,\ Odisha";
$areanames{en}->{9168562} = "Rayagada\,\ Odisha";
$areanames{en}->{9168563} = "Rayagada\,\ Odisha";
$areanames{en}->{9168564} = "Rayagada\,\ Odisha";
$areanames{en}->{9168565} = "Rayagada\,\ Odisha";
$areanames{en}->{9168566} = "Rayagada\,\ Odisha";
$areanames{en}->{9168567} = "Rayagada\,\ Odisha";
$areanames{en}->{9168572} = "Gunupur\,\ Odisha";
$areanames{en}->{9168573} = "Gunupur\,\ Odisha";
$areanames{en}->{9168574} = "Gunupur\,\ Odisha";
$areanames{en}->{9168575} = "Gunupur\,\ Odisha";
$areanames{en}->{9168576} = "Gunupur\,\ Odisha";
$areanames{en}->{9168577} = "Gunupur\,\ Odisha";
$areanames{en}->{9168582} = "Nowrangapur\,\ Odisha";
$areanames{en}->{9168583} = "Nowrangapur\,\ Odisha";
$areanames{en}->{9168584} = "Nowrangapur\,\ Odisha";
$areanames{en}->{9168585} = "Nowrangapur\,\ Odisha";
$areanames{en}->{9168586} = "Nowrangapur\,\ Odisha";
$areanames{en}->{9168587} = "Nowrangapur\,\ Odisha";
$areanames{en}->{9168592} = "Motu\,\ Odisha";
$areanames{en}->{9168593} = "Motu\,\ Odisha";
$areanames{en}->{9168594} = "Motu\,\ Odisha";
$areanames{en}->{9168595} = "Motu\,\ Odisha";
$areanames{en}->{9168596} = "Motu\,\ Odisha";
$areanames{en}->{9168597} = "Motu\,\ Odisha";
$areanames{en}->{9168602} = "Boriguma\,\ Odisha";
$areanames{en}->{9168603} = "Boriguma\,\ Odisha";
$areanames{en}->{9168604} = "Boriguma\,\ Odisha";
$areanames{en}->{9168605} = "Boriguma\,\ Odisha";
$areanames{en}->{9168606} = "Boriguma\,\ Odisha";
$areanames{en}->{9168607} = "Boriguma\,\ Odisha";
$areanames{en}->{9168612} = "Malkangiri\,\ Odisha";
$areanames{en}->{9168613} = "Malkangiri\,\ Odisha";
$areanames{en}->{9168614} = "Malkangiri\,\ Odisha";
$areanames{en}->{9168615} = "Malkangiri\,\ Odisha";
$areanames{en}->{9168616} = "Malkangiri\,\ Odisha";
$areanames{en}->{9168617} = "Malkangiri\,\ Odisha";
$areanames{en}->{9168622} = "Gudari\,\ Odisha";
$areanames{en}->{9168623} = "Gudari\,\ Odisha";
$areanames{en}->{9168624} = "Gudari\,\ Odisha";
$areanames{en}->{9168625} = "Gudari\,\ Odisha";
$areanames{en}->{9168626} = "Gudari\,\ Odisha";
$areanames{en}->{9168627} = "Gudari\,\ Odisha";
$areanames{en}->{9168632} = "Bisam\ Cuttack\,\ Odisha";
$areanames{en}->{9168633} = "Bisam\ Cuttack\,\ Odisha";
$areanames{en}->{9168634} = "Bisam\ Cuttack\,\ Odisha";
$areanames{en}->{9168635} = "Bisam\ Cuttack\,\ Odisha";
$areanames{en}->{9168636} = "Bisam\ Cuttack\,\ Odisha";
$areanames{en}->{9168637} = "Bisam\ Cuttack\,\ Odisha";
$areanames{en}->{9168642} = "Mathili\,\ Odisha";
$areanames{en}->{9168643} = "Mathili\,\ Odisha";
$areanames{en}->{9168644} = "Mathili\,\ Odisha";
$areanames{en}->{9168645} = "Mathili\,\ Odisha";
$areanames{en}->{9168646} = "Mathili\,\ Odisha";
$areanames{en}->{9168647} = "Mathili\,\ Odisha";
$areanames{en}->{9168652} = "Kashipur\,\ Odisha";
$areanames{en}->{9168653} = "Kashipur\,\ Odisha";
$areanames{en}->{9168654} = "Kashipur\,\ Odisha";
$areanames{en}->{9168655} = "Kashipur\,\ Odisha";
$areanames{en}->{9168656} = "Kashipur\,\ Odisha";
$areanames{en}->{9168657} = "Kashipur\,\ Odisha";
$areanames{en}->{9168662} = "Umerkote\,\ Odisha";
$areanames{en}->{9168663} = "Umerkote\,\ Odisha";
$areanames{en}->{9168664} = "Umerkote\,\ Odisha";
$areanames{en}->{9168665} = "Umerkote\,\ Odisha";
$areanames{en}->{9168666} = "Umerkote\,\ Odisha";
$areanames{en}->{9168667} = "Umerkote\,\ Odisha";
$areanames{en}->{9168672} = "Jharigan\,\ Odisha";
$areanames{en}->{9168673} = "Jharigan\,\ Odisha";
$areanames{en}->{9168674} = "Jharigan\,\ Odisha";
$areanames{en}->{9168675} = "Jharigan\,\ Odisha";
$areanames{en}->{9168676} = "Jharigan\,\ Odisha";
$areanames{en}->{9168677} = "Jharigan\,\ Odisha";
$areanames{en}->{9168682} = "Nandapur\,\ Odisha";
$areanames{en}->{9168683} = "Nandapur\,\ Odisha";
$areanames{en}->{9168684} = "Nandapur\,\ Odisha";
$areanames{en}->{9168685} = "Nandapur\,\ Odisha";
$areanames{en}->{9168686} = "Nandapur\,\ Odisha";
$areanames{en}->{9168687} = "Nandapur\,\ Odisha";
$areanames{en}->{9168692} = "Papadhandi\,\ Odisha";
$areanames{en}->{9168693} = "Papadhandi\,\ Odisha";
$areanames{en}->{9168694} = "Papadhandi\,\ Odisha";
$areanames{en}->{9168695} = "Papadhandi\,\ Odisha";
$areanames{en}->{9168696} = "Papadhandi\,\ Odisha";
$areanames{en}->{9168697} = "Papadhandi\,\ Odisha";
$areanames{en}->{9171002} = "Kuhi\,\ Maharashtra";
$areanames{en}->{9171003} = "Kuhi\,\ Maharashtra";
$areanames{en}->{9171004} = "Kuhi\,\ Maharashtra";
$areanames{en}->{9171005} = "Kuhi\,\ Maharashtra";
$areanames{en}->{9171006} = "Kuhi\,\ Maharashtra";
$areanames{en}->{9171007} = "Kuhi\,\ Maharashtra";
$areanames{en}->{9171022} = "Parseoni\,\ Maharashtra";
$areanames{en}->{9171023} = "Parseoni\,\ Maharashtra";
$areanames{en}->{9171024} = "Parseoni\,\ Maharashtra";
$areanames{en}->{9171025} = "Parseoni\,\ Maharashtra";
$areanames{en}->{9171026} = "Parseoni\,\ Maharashtra";
$areanames{en}->{9171027} = "Parseoni\,\ Maharashtra";
$areanames{en}->{9171032} = "Butibori\,\ Maharashtra";
$areanames{en}->{9171033} = "Butibori\,\ Maharashtra";
$areanames{en}->{9171034} = "Butibori\,\ Maharashtra";
$areanames{en}->{9171035} = "Butibori\,\ Maharashtra";
$areanames{en}->{9171036} = "Butibori\,\ Maharashtra";
$areanames{en}->{9171037} = "Butibori\,\ Maharashtra";
$areanames{en}->{9171042} = "Hingua\,\ Maharashtra";
$areanames{en}->{9171043} = "Hingua\,\ Maharashtra";
$areanames{en}->{9171044} = "Hingua\,\ Maharashtra";
$areanames{en}->{9171045} = "Hingua\,\ Maharashtra";
$areanames{en}->{9171046} = "Hingua\,\ Maharashtra";
$areanames{en}->{9171047} = "Hingua\,\ Maharashtra";
$areanames{en}->{9171052} = "Narkhed\,\ Maharashtra";
$areanames{en}->{9171053} = "Narkhed\,\ Maharashtra";
$areanames{en}->{9171054} = "Narkhed\,\ Maharashtra";
$areanames{en}->{9171055} = "Narkhed\,\ Maharashtra";
$areanames{en}->{9171056} = "Narkhed\,\ Maharashtra";
$areanames{en}->{9171057} = "Narkhed\,\ Maharashtra";
$areanames{en}->{9171062} = "Bhiwapur\,\ Maharashtra";
$areanames{en}->{9171063} = "Bhiwapur\,\ Maharashtra";
$areanames{en}->{9171064} = "Bhiwapur\,\ Maharashtra";
$areanames{en}->{9171065} = "Bhiwapur\,\ Maharashtra";
$areanames{en}->{9171066} = "Bhiwapur\,\ Maharashtra";
$areanames{en}->{9171067} = "Bhiwapur\,\ Maharashtra";
$areanames{en}->{9171092} = "Kamptee\,\ Maharashtra";
$areanames{en}->{9171093} = "Kamptee\,\ Maharashtra";
$areanames{en}->{9171094} = "Kamptee\,\ Maharashtra";
$areanames{en}->{9171095} = "Kamptee\,\ Maharashtra";
$areanames{en}->{9171096} = "Kamptee\,\ Maharashtra";
$areanames{en}->{9171097} = "Kamptee\,\ Maharashtra";
$areanames{en}->{9171122} = "Katol\,\ Maharashtra";
$areanames{en}->{9171123} = "Katol\,\ Maharashtra";
$areanames{en}->{9171124} = "Katol\,\ Maharashtra";
$areanames{en}->{9171125} = "Katol\,\ Maharashtra";
$areanames{en}->{9171126} = "Katol\,\ Maharashtra";
$areanames{en}->{9171127} = "Katol\,\ Maharashtra";
$areanames{en}->{9171132} = "Saoner\,\ Maharashtra";
$areanames{en}->{9171133} = "Saoner\,\ Maharashtra";
$areanames{en}->{9171134} = "Saoner\,\ Maharashtra";
$areanames{en}->{9171135} = "Saoner\,\ Maharashtra";
$areanames{en}->{9171136} = "Saoner\,\ Maharashtra";
$areanames{en}->{9171137} = "Saoner\,\ Maharashtra";
$areanames{en}->{9171142} = "Ramtek\,\ Maharashtra";
$areanames{en}->{9171143} = "Ramtek\,\ Maharashtra";
$areanames{en}->{9171144} = "Ramtek\,\ Maharashtra";
$areanames{en}->{9171145} = "Ramtek\,\ Maharashtra";
$areanames{en}->{9171146} = "Ramtek\,\ Maharashtra";
$areanames{en}->{9171147} = "Ramtek\,\ Maharashtra";
$areanames{en}->{9171152} = "Mouda\,\ Maharashtra";
$areanames{en}->{9171153} = "Mouda\,\ Maharashtra";
$areanames{en}->{9171154} = "Mouda\,\ Maharashtra";
$areanames{en}->{9171155} = "Mouda\,\ Maharashtra";
$areanames{en}->{9171156} = "Mouda\,\ Maharashtra";
$areanames{en}->{9171157} = "Mouda\,\ Maharashtra";
$areanames{en}->{9171162} = "Umrer\,\ Maharashtra";
$areanames{en}->{9171163} = "Umrer\,\ Maharashtra";
$areanames{en}->{9171164} = "Umrer\,\ Maharashtra";
$areanames{en}->{9171165} = "Umrer\,\ Maharashtra";
$areanames{en}->{9171166} = "Umrer\,\ Maharashtra";
$areanames{en}->{9171167} = "Umrer\,\ Maharashtra";
$areanames{en}->{9171182} = "Kalmeshwar\,\ Maharashtra";
$areanames{en}->{9171183} = "Kalmeshwar\,\ Maharashtra";
$areanames{en}->{9171184} = "Kalmeshwar\,\ Maharashtra";
$areanames{en}->{9171185} = "Kalmeshwar\,\ Maharashtra";
$areanames{en}->{9171186} = "Kalmeshwar\,\ Maharashtra";
$areanames{en}->{9171187} = "Kalmeshwar\,\ Maharashtra";
$areanames{en}->{917122} = "Nagpur\,\ Maharashtra";
$areanames{en}->{917123} = "Nagpur\,\ Maharashtra";
$areanames{en}->{917124} = "Nagpur\,\ Maharashtra";
$areanames{en}->{917125} = "Nagpur\,\ Maharashtra";
$areanames{en}->{917126} = "Nagpur\,\ Maharashtra";
$areanames{en}->{917127} = "Nagpur\,\ Maharashtra";
$areanames{en}->{9171312} = "Sironcha\,\ Maharashtra";
$areanames{en}->{9171313} = "Sironcha\,\ Maharashtra";
$areanames{en}->{9171314} = "Sironcha\,\ Maharashtra";
$areanames{en}->{9171315} = "Sironcha\,\ Maharashtra";
$areanames{en}->{9171316} = "Sironcha\,\ Maharashtra";
$areanames{en}->{9171317} = "Sironcha\,\ Maharashtra";
$areanames{en}->{9171322} = "Gadchiroli\,\ Maharashtra";
$areanames{en}->{9171323} = "Gadchiroli\,\ Maharashtra";
$areanames{en}->{9171324} = "Gadchiroli\,\ Maharashtra";
$areanames{en}->{9171325} = "Gadchiroli\,\ Maharashtra";
$areanames{en}->{9171326} = "Gadchiroli\,\ Maharashtra";
$areanames{en}->{9171327} = "Gadchiroli\,\ Maharashtra";
$areanames{en}->{9171332} = "Aheri\,\ Maharashtra";
$areanames{en}->{9171333} = "Aheri\,\ Maharashtra";
$areanames{en}->{9171334} = "Aheri\,\ Maharashtra";
$areanames{en}->{9171335} = "Aheri\,\ Maharashtra";
$areanames{en}->{9171336} = "Aheri\,\ Maharashtra";
$areanames{en}->{9171337} = "Aheri\,\ Maharashtra";
$areanames{en}->{9171342} = "Bhamregadh\,\ Maharashtra";
$areanames{en}->{9171343} = "Bhamregadh\,\ Maharashtra";
$areanames{en}->{9171344} = "Bhamregadh\,\ Maharashtra";
$areanames{en}->{9171345} = "Bhamregadh\,\ Maharashtra";
$areanames{en}->{9171346} = "Bhamregadh\,\ Maharashtra";
$areanames{en}->{9171347} = "Bhamregadh\,\ Maharashtra";
$areanames{en}->{9171352} = "Chamorshi\,\ Maharashtra";
$areanames{en}->{9171353} = "Chamorshi\,\ Maharashtra";
$areanames{en}->{9171354} = "Chamorshi\,\ Maharashtra";
$areanames{en}->{9171355} = "Chamorshi\,\ Maharashtra";
$areanames{en}->{9171356} = "Chamorshi\,\ Maharashtra";
$areanames{en}->{9171357} = "Chamorshi\,\ Maharashtra";
$areanames{en}->{9171362} = "Etapalli\,\ Maharashtra";
$areanames{en}->{9171363} = "Etapalli\,\ Maharashtra";
$areanames{en}->{9171364} = "Etapalli\,\ Maharashtra";
$areanames{en}->{9171365} = "Etapalli\,\ Maharashtra";
$areanames{en}->{9171366} = "Etapalli\,\ Maharashtra";
$areanames{en}->{9171367} = "Etapalli\,\ Maharashtra";
$areanames{en}->{9171372} = "Desaiganj\,\ Maharashtra";
$areanames{en}->{9171373} = "Desaiganj\,\ Maharashtra";
$areanames{en}->{9171374} = "Desaiganj\,\ Maharashtra";
$areanames{en}->{9171375} = "Desaiganj\,\ Maharashtra";
$areanames{en}->{9171376} = "Desaiganj\,\ Maharashtra";
$areanames{en}->{9171377} = "Desaiganj\,\ Maharashtra";
$areanames{en}->{9171382} = "Dhanora\,\ Maharashtra";
$areanames{en}->{9171383} = "Dhanora\,\ Maharashtra";
$areanames{en}->{9171384} = "Dhanora\,\ Maharashtra";
$areanames{en}->{9171385} = "Dhanora\,\ Maharashtra";
$areanames{en}->{9171386} = "Dhanora\,\ Maharashtra";
$areanames{en}->{9171387} = "Dhanora\,\ Maharashtra";
$areanames{en}->{9171392} = "Kurkheda\,\ Maharashtra";
$areanames{en}->{9171393} = "Kurkheda\,\ Maharashtra";
$areanames{en}->{9171394} = "Kurkheda\,\ Maharashtra";
$areanames{en}->{9171395} = "Kurkheda\,\ Maharashtra";
$areanames{en}->{9171396} = "Kurkheda\,\ Maharashtra";
$areanames{en}->{9171397} = "Kurkheda\,\ Maharashtra";
$areanames{en}->{9171412} = "Betul\,\ Madhya\ Pradesh";
$areanames{en}->{9171413} = "Betul\,\ Madhya\ Pradesh";
$areanames{en}->{9171414} = "Betul\,\ Madhya\ Pradesh";
$areanames{en}->{9171415} = "Betul\,\ Madhya\ Pradesh";
$areanames{en}->{9171416} = "Betul\,\ Madhya\ Pradesh";
$areanames{en}->{9171417} = "Betul\,\ Madhya\ Pradesh";
$areanames{en}->{9171422} = "Bhimpur\,\ Madhya\ Pradesh";
$areanames{en}->{9171423} = "Bhimpur\,\ Madhya\ Pradesh";
$areanames{en}->{9171424} = "Bhimpur\,\ Madhya\ Pradesh";
$areanames{en}->{9171425} = "Bhimpur\,\ Madhya\ Pradesh";
$areanames{en}->{9171426} = "Bhimpur\,\ Madhya\ Pradesh";
$areanames{en}->{9171427} = "Bhimpur\,\ Madhya\ Pradesh";
$areanames{en}->{9171432} = "Bhainsdehi\,\ Madhya\ Pradesh";
$areanames{en}->{9171433} = "Bhainsdehi\,\ Madhya\ Pradesh";
$areanames{en}->{9171434} = "Bhainsdehi\,\ Madhya\ Pradesh";
$areanames{en}->{9171435} = "Bhainsdehi\,\ Madhya\ Pradesh";
$areanames{en}->{9171436} = "Bhainsdehi\,\ Madhya\ Pradesh";
$areanames{en}->{9171437} = "Bhainsdehi\,\ Madhya\ Pradesh";
$areanames{en}->{9171442} = "Atner\,\ Madhya\ Pradesh";
$areanames{en}->{9171443} = "Atner\,\ Madhya\ Pradesh";
$areanames{en}->{9171444} = "Atner\,\ Madhya\ Pradesh";
$areanames{en}->{9171445} = "Atner\,\ Madhya\ Pradesh";
$areanames{en}->{9171446} = "Atner\,\ Madhya\ Pradesh";
$areanames{en}->{9171447} = "Atner\,\ Madhya\ Pradesh";
$areanames{en}->{9171452} = "Chicholi\,\ Madhya\ Pradesh";
$areanames{en}->{9171453} = "Chicholi\,\ Madhya\ Pradesh";
$areanames{en}->{9171454} = "Chicholi\,\ Madhya\ Pradesh";
$areanames{en}->{9171455} = "Chicholi\,\ Madhya\ Pradesh";
$areanames{en}->{9171456} = "Chicholi\,\ Madhya\ Pradesh";
$areanames{en}->{9171457} = "Chicholi\,\ Madhya\ Pradesh";
$areanames{en}->{9171462} = "Ghorandogri\,\ Madhya\ Pradesh";
$areanames{en}->{9171463} = "Ghorandogri\,\ Madhya\ Pradesh";
$areanames{en}->{9171464} = "Ghorandogri\,\ Madhya\ Pradesh";
$areanames{en}->{9171465} = "Ghorandogri\,\ Madhya\ Pradesh";
$areanames{en}->{9171466} = "Ghorandogri\,\ Madhya\ Pradesh";
$areanames{en}->{9171467} = "Ghorandogri\,\ Madhya\ Pradesh";
$areanames{en}->{9171472} = "Multai\,\ Madhya\ Pradesh";
$areanames{en}->{9171473} = "Multai\,\ Madhya\ Pradesh";
$areanames{en}->{9171474} = "Multai\,\ Madhya\ Pradesh";
$areanames{en}->{9171475} = "Multai\,\ Madhya\ Pradesh";
$areanames{en}->{9171476} = "Multai\,\ Madhya\ Pradesh";
$areanames{en}->{9171477} = "Multai\,\ Madhya\ Pradesh";
$areanames{en}->{9171482} = "Prabha\ Pattan\,\ Madhya\ Pradesh";
$areanames{en}->{9171483} = "Prabha\ Pattan\,\ Madhya\ Pradesh";
$areanames{en}->{9171484} = "Prabha\ Pattan\,\ Madhya\ Pradesh";
$areanames{en}->{9171485} = "Prabha\ Pattan\,\ Madhya\ Pradesh";
$areanames{en}->{9171486} = "Prabha\ Pattan\,\ Madhya\ Pradesh";
$areanames{en}->{9171487} = "Prabha\ Pattan\,\ Madhya\ Pradesh";
$areanames{en}->{9171492} = "Tamia\,\ Madhya\ Pradesh";
$areanames{en}->{9171493} = "Tamia\,\ Madhya\ Pradesh";
$areanames{en}->{9171494} = "Tamia\,\ Madhya\ Pradesh";
$areanames{en}->{9171495} = "Tamia\,\ Madhya\ Pradesh";
$areanames{en}->{9171496} = "Tamia\,\ Madhya\ Pradesh";
$areanames{en}->{9171497} = "Tamia\,\ Madhya\ Pradesh";
$areanames{en}->{9171512} = "Samudrapur\,\ Maharashtra";
$areanames{en}->{9171513} = "Samudrapur\,\ Maharashtra";
$areanames{en}->{9171514} = "Samudrapur\,\ Maharashtra";
$areanames{en}->{9171515} = "Samudrapur\,\ Maharashtra";
$areanames{en}->{9171516} = "Samudrapur\,\ Maharashtra";
$areanames{en}->{9171517} = "Samudrapur\,\ Maharashtra";
$areanames{en}->{9171522} = "Wardha\,\ Maharashtra";
$areanames{en}->{9171523} = "Wardha\,\ Maharashtra";
$areanames{en}->{9171524} = "Wardha\,\ Maharashtra";
$areanames{en}->{9171525} = "Wardha\,\ Maharashtra";
$areanames{en}->{9171526} = "Wardha\,\ Maharashtra";
$areanames{en}->{9171527} = "Wardha\,\ Maharashtra";
$areanames{en}->{9171532} = "Hinganghat\,\ Maharashtra";
$areanames{en}->{9171533} = "Hinganghat\,\ Maharashtra";
$areanames{en}->{9171534} = "Hinganghat\,\ Maharashtra";
$areanames{en}->{9171535} = "Hinganghat\,\ Maharashtra";
$areanames{en}->{9171536} = "Hinganghat\,\ Maharashtra";
$areanames{en}->{9171537} = "Hinganghat\,\ Maharashtra";
$areanames{en}->{9171552} = "Seloo\,\ Maharashtra";
$areanames{en}->{9171553} = "Seloo\,\ Maharashtra";
$areanames{en}->{9171554} = "Seloo\,\ Maharashtra";
$areanames{en}->{9171555} = "Seloo\,\ Maharashtra";
$areanames{en}->{9171556} = "Seloo\,\ Maharashtra";
$areanames{en}->{9171557} = "Seloo\,\ Maharashtra";
$areanames{en}->{9171562} = "Talegaokarangal\,\ Maharashtra";
$areanames{en}->{9171563} = "Talegaokarangal\,\ Maharashtra";
$areanames{en}->{9171564} = "Talegaokarangal\,\ Maharashtra";
$areanames{en}->{9171565} = "Talegaokarangal\,\ Maharashtra";
$areanames{en}->{9171566} = "Talegaokarangal\,\ Maharashtra";
$areanames{en}->{9171567} = "Talegaokarangal\,\ Maharashtra";
$areanames{en}->{9171572} = "Arvi\,\ Maharashtra";
$areanames{en}->{9171573} = "Arvi\,\ Maharashtra";
$areanames{en}->{9171574} = "Arvi\,\ Maharashtra";
$areanames{en}->{9171575} = "Arvi\,\ Maharashtra";
$areanames{en}->{9171576} = "Arvi\,\ Maharashtra";
$areanames{en}->{9171577} = "Arvi\,\ Maharashtra";
$areanames{en}->{9171582} = "Deoli\,\ Maharashtra";
$areanames{en}->{9171583} = "Deoli\,\ Maharashtra";
$areanames{en}->{9171584} = "Deoli\,\ Maharashtra";
$areanames{en}->{9171585} = "Deoli\,\ Maharashtra";
$areanames{en}->{9171586} = "Deoli\,\ Maharashtra";
$areanames{en}->{9171587} = "Deoli\,\ Maharashtra";
$areanames{en}->{9171602} = "Jamai\,\ Madhya\ Pradesh";
$areanames{en}->{9171603} = "Jamai\,\ Madhya\ Pradesh";
$areanames{en}->{9171604} = "Jamai\,\ Madhya\ Pradesh";
$areanames{en}->{9171605} = "Jamai\,\ Madhya\ Pradesh";
$areanames{en}->{9171606} = "Jamai\,\ Madhya\ Pradesh";
$areanames{en}->{9171607} = "Jamai\,\ Madhya\ Pradesh";
$areanames{en}->{9171612} = "Parasia\,\ Madhya\ Pradesh";
$areanames{en}->{9171613} = "Parasia\,\ Madhya\ Pradesh";
$areanames{en}->{9171614} = "Parasia\,\ Madhya\ Pradesh";
$areanames{en}->{9171615} = "Parasia\,\ Madhya\ Pradesh";
$areanames{en}->{9171616} = "Parasia\,\ Madhya\ Pradesh";
$areanames{en}->{9171617} = "Parasia\,\ Madhya\ Pradesh";
$areanames{en}->{9171622} = "Chhindwara\,\ Madhya\ Pradesh";
$areanames{en}->{9171623} = "Chhindwara\,\ Madhya\ Pradesh";
$areanames{en}->{9171624} = "Chhindwara\,\ Madhya\ Pradesh";
$areanames{en}->{9171625} = "Chhindwara\,\ Madhya\ Pradesh";
$areanames{en}->{9171626} = "Chhindwara\,\ Madhya\ Pradesh";
$areanames{en}->{9171627} = "Chhindwara\,\ Madhya\ Pradesh";
$areanames{en}->{9171642} = "Pandhurna\,\ Madhya\ Pradesh";
$areanames{en}->{9171643} = "Pandhurna\,\ Madhya\ Pradesh";
$areanames{en}->{9171644} = "Pandhurna\,\ Madhya\ Pradesh";
$areanames{en}->{9171645} = "Pandhurna\,\ Madhya\ Pradesh";
$areanames{en}->{9171646} = "Pandhurna\,\ Madhya\ Pradesh";
$areanames{en}->{9171647} = "Pandhurna\,\ Madhya\ Pradesh";
$areanames{en}->{9171652} = "Saunsar\,\ Madhya\ Pradesh";
$areanames{en}->{9171653} = "Saunsar\,\ Madhya\ Pradesh";
$areanames{en}->{9171654} = "Saunsar\,\ Madhya\ Pradesh";
$areanames{en}->{9171655} = "Saunsar\,\ Madhya\ Pradesh";
$areanames{en}->{9171656} = "Saunsar\,\ Madhya\ Pradesh";
$areanames{en}->{9171657} = "Saunsar\,\ Madhya\ Pradesh";
$areanames{en}->{9171662} = "Chaurai\,\ Madhya\ Pradesh";
$areanames{en}->{9171663} = "Chaurai\,\ Madhya\ Pradesh";
$areanames{en}->{9171664} = "Chaurai\,\ Madhya\ Pradesh";
$areanames{en}->{9171665} = "Chaurai\,\ Madhya\ Pradesh";
$areanames{en}->{9171666} = "Chaurai\,\ Madhya\ Pradesh";
$areanames{en}->{9171667} = "Chaurai\,\ Madhya\ Pradesh";
$areanames{en}->{9171672} = "Amarwada\,\ Madhya\ Pradesh";
$areanames{en}->{9171673} = "Amarwada\,\ Madhya\ Pradesh";
$areanames{en}->{9171674} = "Amarwada\,\ Madhya\ Pradesh";
$areanames{en}->{9171675} = "Amarwada\,\ Madhya\ Pradesh";
$areanames{en}->{9171676} = "Amarwada\,\ Madhya\ Pradesh";
$areanames{en}->{9171677} = "Amarwada\,\ Madhya\ Pradesh";
$areanames{en}->{9171682} = "Harrai\,\ Madhya\ Pradesh";
$areanames{en}->{9171683} = "Harrai\,\ Madhya\ Pradesh";
$areanames{en}->{9171684} = "Harrai\,\ Madhya\ Pradesh";
$areanames{en}->{9171685} = "Harrai\,\ Madhya\ Pradesh";
$areanames{en}->{9171686} = "Harrai\,\ Madhya\ Pradesh";
$areanames{en}->{9171687} = "Harrai\,\ Madhya\ Pradesh";
$areanames{en}->{9171692} = "Batkakhapa\,\ Madhya\ Pradesh";
$areanames{en}->{9171693} = "Batkakhapa\,\ Madhya\ Pradesh";
$areanames{en}->{9171694} = "Batkakhapa\,\ Madhya\ Pradesh";
$areanames{en}->{9171695} = "Batkakhapa\,\ Madhya\ Pradesh";
$areanames{en}->{9171696} = "Batkakhapa\,\ Madhya\ Pradesh";
$areanames{en}->{9171697} = "Batkakhapa\,\ Madhya\ Pradesh";
$areanames{en}->{9171702} = "Chumur\,\ Maharashtra";
$areanames{en}->{9171703} = "Chumur\,\ Maharashtra";
$areanames{en}->{9171704} = "Chumur\,\ Maharashtra";
$areanames{en}->{9171705} = "Chumur\,\ Maharashtra";
$areanames{en}->{9171706} = "Chumur\,\ Maharashtra";
$areanames{en}->{9171707} = "Chumur\,\ Maharashtra";
$areanames{en}->{9171712} = "Gond\ Pipri\,\ Maharashtra";
$areanames{en}->{9171713} = "Gond\ Pipri\,\ Maharashtra";
$areanames{en}->{9171714} = "Gond\ Pipri\,\ Maharashtra";
$areanames{en}->{9171715} = "Gond\ Pipri\,\ Maharashtra";
$areanames{en}->{9171716} = "Gond\ Pipri\,\ Maharashtra";
$areanames{en}->{9171717} = "Gond\ Pipri\,\ Maharashtra";
$areanames{en}->{9171722} = "Chandrapur\,\ Maharashtra";
$areanames{en}->{9171723} = "Chandrapur\,\ Maharashtra";
$areanames{en}->{9171724} = "Chandrapur\,\ Maharashtra";
$areanames{en}->{9171725} = "Chandrapur\,\ Maharashtra";
$areanames{en}->{9171726} = "Chandrapur\,\ Maharashtra";
$areanames{en}->{9171727} = "Chandrapur\,\ Maharashtra";
$areanames{en}->{9171732} = "Rajura\,\ Maharashtra";
$areanames{en}->{9171733} = "Rajura\,\ Maharashtra";
$areanames{en}->{9171734} = "Rajura\,\ Maharashtra";
$areanames{en}->{9171735} = "Rajura\,\ Maharashtra";
$areanames{en}->{9171736} = "Rajura\,\ Maharashtra";
$areanames{en}->{9171737} = "Rajura\,\ Maharashtra";
$areanames{en}->{9171742} = "Mul\,\ Maharashtra";
$areanames{en}->{9171743} = "Mul\,\ Maharashtra";
$areanames{en}->{9171744} = "Mul\,\ Maharashtra";
$areanames{en}->{9171745} = "Mul\,\ Maharashtra";
$areanames{en}->{9171746} = "Mul\,\ Maharashtra";
$areanames{en}->{9171747} = "Mul\,\ Maharashtra";
$areanames{en}->{9171752} = "Bhadrawati\,\ Maharashtra";
$areanames{en}->{9171753} = "Bhadrawati\,\ Maharashtra";
$areanames{en}->{9171754} = "Bhadrawati\,\ Maharashtra";
$areanames{en}->{9171755} = "Bhadrawati\,\ Maharashtra";
$areanames{en}->{9171756} = "Bhadrawati\,\ Maharashtra";
$areanames{en}->{9171757} = "Bhadrawati\,\ Maharashtra";
$areanames{en}->{9171762} = "Warora\,\ Maharashtra";
$areanames{en}->{9171763} = "Warora\,\ Maharashtra";
$areanames{en}->{9171764} = "Warora\,\ Maharashtra";
$areanames{en}->{9171765} = "Warora\,\ Maharashtra";
$areanames{en}->{9171766} = "Warora\,\ Maharashtra";
$areanames{en}->{9171767} = "Warora\,\ Maharashtra";
$areanames{en}->{9171772} = "Brahmapuri\,\ Maharashtra";
$areanames{en}->{9171773} = "Brahmapuri\,\ Maharashtra";
$areanames{en}->{9171774} = "Brahmapuri\,\ Maharashtra";
$areanames{en}->{9171775} = "Brahmapuri\,\ Maharashtra";
$areanames{en}->{9171776} = "Brahmapuri\,\ Maharashtra";
$areanames{en}->{9171777} = "Brahmapuri\,\ Maharashtra";
$areanames{en}->{9171782} = "Sinderwahi\,\ Maharashtra";
$areanames{en}->{9171783} = "Sinderwahi\,\ Maharashtra";
$areanames{en}->{9171784} = "Sinderwahi\,\ Maharashtra";
$areanames{en}->{9171785} = "Sinderwahi\,\ Maharashtra";
$areanames{en}->{9171786} = "Sinderwahi\,\ Maharashtra";
$areanames{en}->{9171787} = "Sinderwahi\,\ Maharashtra";
$areanames{en}->{9171792} = "Nagbhir\,\ Maharashtra";
$areanames{en}->{9171793} = "Nagbhir\,\ Maharashtra";
$areanames{en}->{9171794} = "Nagbhir\,\ Maharashtra";
$areanames{en}->{9171795} = "Nagbhir\,\ Maharashtra";
$areanames{en}->{9171796} = "Nagbhir\,\ Maharashtra";
$areanames{en}->{9171797} = "Nagbhir\,\ Maharashtra";
$areanames{en}->{9171802} = "Salekasa\,\ Maharashtra";
$areanames{en}->{9171803} = "Salekasa\,\ Maharashtra";
$areanames{en}->{9171804} = "Salekasa\,\ Maharashtra";
$areanames{en}->{9171805} = "Salekasa\,\ Maharashtra";
$areanames{en}->{9171806} = "Salekasa\,\ Maharashtra";
$areanames{en}->{9171807} = "Salekasa\,\ Maharashtra";
$areanames{en}->{9171812} = "Lakhandur\,\ Maharashtra";
$areanames{en}->{9171813} = "Lakhandur\,\ Maharashtra";
$areanames{en}->{9171814} = "Lakhandur\,\ Maharashtra";
$areanames{en}->{9171815} = "Lakhandur\,\ Maharashtra";
$areanames{en}->{9171816} = "Lakhandur\,\ Maharashtra";
$areanames{en}->{9171817} = "Lakhandur\,\ Maharashtra";
$areanames{en}->{9171822} = "Gondia\,\ Maharashtra";
$areanames{en}->{9171823} = "Gondia\,\ Maharashtra";
$areanames{en}->{9171824} = "Gondia\,\ Maharashtra";
$areanames{en}->{9171825} = "Gondia\,\ Maharashtra";
$areanames{en}->{9171826} = "Gondia\,\ Maharashtra";
$areanames{en}->{9171827} = "Gondia\,\ Maharashtra";
$areanames{en}->{9171832} = "Tumsar\,\ Maharashtra";
$areanames{en}->{9171833} = "Tumsar\,\ Maharashtra";
$areanames{en}->{9171834} = "Tumsar\,\ Maharashtra";
$areanames{en}->{9171835} = "Tumsar\,\ Maharashtra";
$areanames{en}->{9171836} = "Tumsar\,\ Maharashtra";
$areanames{en}->{9171837} = "Tumsar\,\ Maharashtra";
$areanames{en}->{9171842} = "Bhandara\,\ Maharashtra";
$areanames{en}->{9171843} = "Bhandara\,\ Maharashtra";
$areanames{en}->{9171844} = "Bhandara\,\ Maharashtra";
$areanames{en}->{9171845} = "Bhandara\,\ Maharashtra";
$areanames{en}->{9171846} = "Bhandara\,\ Maharashtra";
$areanames{en}->{9171847} = "Bhandara\,\ Maharashtra";
$areanames{en}->{9171852} = "Pauni\,\ Maharashtra";
$areanames{en}->{9171853} = "Pauni\,\ Maharashtra";
$areanames{en}->{9171854} = "Pauni\,\ Maharashtra";
$areanames{en}->{9171855} = "Pauni\,\ Maharashtra";
$areanames{en}->{9171856} = "Pauni\,\ Maharashtra";
$areanames{en}->{9171857} = "Pauni\,\ Maharashtra";
$areanames{en}->{9171862} = "Sakoli\,\ Maharashtra";
$areanames{en}->{9171863} = "Sakoli\,\ Maharashtra";
$areanames{en}->{9171864} = "Sakoli\,\ Maharashtra";
$areanames{en}->{9171865} = "Sakoli\,\ Maharashtra";
$areanames{en}->{9171866} = "Sakoli\,\ Maharashtra";
$areanames{en}->{9171867} = "Sakoli\,\ Maharashtra";
$areanames{en}->{9171872} = "Goregaon\,\ Maharashtra";
$areanames{en}->{9171873} = "Goregaon\,\ Maharashtra";
$areanames{en}->{9171874} = "Goregaon\,\ Maharashtra";
$areanames{en}->{9171875} = "Goregaon\,\ Maharashtra";
$areanames{en}->{9171876} = "Goregaon\,\ Maharashtra";
$areanames{en}->{9171877} = "Goregaon\,\ Maharashtra";
$areanames{en}->{9171892} = "Amagaon\,\ Maharashtra";
$areanames{en}->{9171893} = "Amagaon\,\ Maharashtra";
$areanames{en}->{9171894} = "Amagaon\,\ Maharashtra";
$areanames{en}->{9171895} = "Amagaon\,\ Maharashtra";
$areanames{en}->{9171896} = "Amagaon\,\ Maharashtra";
$areanames{en}->{9171897} = "Amagaon\,\ Maharashtra";
$areanames{en}->{9171962} = "Arjuni\ Morgaon\,\ Maharashtra";
$areanames{en}->{9171963} = "Arjuni\ Morgaon\,\ Maharashtra";
$areanames{en}->{9171964} = "Arjuni\ Morgaon\,\ Maharashtra";
$areanames{en}->{9171965} = "Arjuni\ Morgaon\,\ Maharashtra";
$areanames{en}->{9171966} = "Arjuni\ Morgaon\,\ Maharashtra";
$areanames{en}->{9171967} = "Arjuni\ Morgaon\,\ Maharashtra";
$areanames{en}->{9171972} = "Mohadi\,\ Maharashtra";
$areanames{en}->{9171973} = "Mohadi\,\ Maharashtra";
$areanames{en}->{9171974} = "Mohadi\,\ Maharashtra";
$areanames{en}->{9171975} = "Mohadi\,\ Maharashtra";
$areanames{en}->{9171976} = "Mohadi\,\ Maharashtra";
$areanames{en}->{9171977} = "Mohadi\,\ Maharashtra";
$areanames{en}->{9171982} = "Tirora\,\ Maharashtra";
$areanames{en}->{9171983} = "Tirora\,\ Maharashtra";
$areanames{en}->{9171984} = "Tirora\,\ Maharashtra";
$areanames{en}->{9171985} = "Tirora\,\ Maharashtra";
$areanames{en}->{9171986} = "Tirora\,\ Maharashtra";
$areanames{en}->{9171987} = "Tirora\,\ Maharashtra";
$areanames{en}->{9171992} = "Deori\,\ Maharashtra";
$areanames{en}->{9171993} = "Deori\,\ Maharashtra";
$areanames{en}->{9171994} = "Deori\,\ Maharashtra";
$areanames{en}->{9171995} = "Deori\,\ Maharashtra";
$areanames{en}->{9171996} = "Deori\,\ Maharashtra";
$areanames{en}->{9171997} = "Deori\,\ Maharashtra";
$areanames{en}->{917201} = "Kalamb\,\ Maharashtra";
$areanames{en}->{917202} = "Ralegaon\,\ Maharashtra";
$areanames{en}->{917203} = "Babhulgaon\,\ Maharashtra";
$areanames{en}->{91721} = "Amravati\,\ Maharashtra";
$areanames{en}->{917220} = "Chhikaldara\,\ Maharashtra";
$areanames{en}->{917221} = "Nandgaon\,\ Maharashtra";
$areanames{en}->{917222} = "Chandurrly\,\ Maharashtra";
$areanames{en}->{917223} = "Achalpur\,\ Maharashtra";
$areanames{en}->{917224} = "Daryapur\,\ Maharashtra";
$areanames{en}->{917225} = "Tiwasa\,\ Maharashtra";
$areanames{en}->{917226} = "Dharani\,\ Maharashtra";
$areanames{en}->{917227} = "Chandurbazar\,\ Maharashtra";
$areanames{en}->{917228} = "Morshi\,\ Maharashtra";
$areanames{en}->{917229} = "Warlydwarud\,\ Maharashtra";
$areanames{en}->{917230} = "Ghatanji\,\ Maharashtra";
$areanames{en}->{917231} = "Umarkhed\,\ Maharashtra";
$areanames{en}->{917232} = "Yeotmal\,\ Maharashtra";
$areanames{en}->{917233} = "Pusad\,\ Maharashtra";
$areanames{en}->{917234} = "Digras\,\ Maharashtra";
$areanames{en}->{917235} = "Pandharkawada\,\ Maharashtra";
$areanames{en}->{917236} = "Maregaon\,\ Maharashtra";
$areanames{en}->{917237} = "Marigaon\,\ Maharashtra";
$areanames{en}->{917238} = "Darwaha\,\ Maharashtra";
$areanames{en}->{917239} = "Wani\,\ Maharashtra";
$areanames{en}->{91724} = "Akola\,\ Maharashtra";
$areanames{en}->{917251} = "Risod\,\ Maharashtra";
$areanames{en}->{917252} = "Washim\,\ Maharashtra";
$areanames{en}->{917253} = "Mangrulpur\,\ Maharashtra";
$areanames{en}->{917254} = "Malgaon\,\ Maharashtra";
$areanames{en}->{917255} = "Barshi\ Takli\,\ Maharashtra";
$areanames{en}->{917256} = "Murtizapur\,\ Maharashtra";
$areanames{en}->{917257} = "Balapur\,\ Maharashtra";
$areanames{en}->{917258} = "Akot\,\ Maharashtra";
$areanames{en}->{917260} = "Lonar\,\ Maharashtra";
$areanames{en}->{917261} = "Deolgaonraja\,\ Maharashtra";
$areanames{en}->{917262} = "Buldhana\,\ Maharashtra";
$areanames{en}->{917263} = "Khamgaon\,\ Maharashtra";
$areanames{en}->{917264} = "Chikhali\,\ Maharashtra";
$areanames{en}->{917265} = "Nandura\,\ Maharashtra";
$areanames{en}->{917266} = "Jalgaonjamod\,\ Maharashtra";
$areanames{en}->{917267} = "Malkapur\,\ Maharashtra";
$areanames{en}->{917268} = "Mekhar\,\ Maharashtra";
$areanames{en}->{917269} = "Sindkhedaraja\,\ Maharashtra";
$areanames{en}->{9172691} = "Deolgaonraja\,\ Maharashtra";
$areanames{en}->{917270} = "Sonkatch\,\ Madhya\ Pradesh";
$areanames{en}->{917271} = "Bagli\,\ Madhya\ Pradesh";
$areanames{en}->{917272} = "Dewas\,\ Madhya\ Pradesh";
$areanames{en}->{917273} = "Kannod\,\ Madhya\ Pradesh";
$areanames{en}->{917274} = "Khategaon\,\ Madhya\ Pradesh";
$areanames{en}->{917279} = "Nandnva\,\ Maharashtra";
$areanames{en}->{917280} = "Barwaha\,\ Madhya\ Pradesh";
$areanames{en}->{917281} = "Sendhwa\,\ Madhya\ Pradesh";
$areanames{en}->{917282} = "Khargone\,\ Madhya\ Pradesh";
$areanames{en}->{917283} = "Maheshwar\,\ Madhya\ Pradesh";
$areanames{en}->{917284} = "Rajpur\,\ Madhya\ Pradesh";
$areanames{en}->{917285} = "Kasrawad\,\ Madhya\ Pradesh";
$areanames{en}->{9172860} = "Khetia\,\ Madhya\ Pradesh";
$areanames{en}->{9172862} = "Khetia\,\ Madhya\ Pradesh";
$areanames{en}->{9172863} = "Khetia\,\ Madhya\ Pradesh";
$areanames{en}->{9172864} = "Khetia\,\ Madhya\ Pradesh";
$areanames{en}->{9172865} = "Khetia\,\ Madhya\ Pradesh";
$areanames{en}->{9172866} = "Khetia\,\ Madhya\ Pradesh";
$areanames{en}->{9172867} = "Khetia\,\ Madhya\ Pradesh";
$areanames{en}->{9172868} = "Khetia\,\ Madhya\ Pradesh";
$areanames{en}->{9172869} = "Khetia\,\ Madhya\ Pradesh";
$areanames{en}->{9172870} = "Gogaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172872} = "Gogaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172873} = "Gogaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172874} = "Gogaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172875} = "Gogaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172876} = "Gogaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172877} = "Gogaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172878} = "Gogaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172879} = "Gogaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172880} = "Bhikangaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172882} = "Bhikangaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172883} = "Bhikangaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172884} = "Bhikangaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172885} = "Bhikangaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172886} = "Bhikangaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172887} = "Bhikangaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172888} = "Bhikangaon\,\ Madhya\ Pradesh";
$areanames{en}->{9172889} = "Bhikangaon\,\ Madhya\ Pradesh";
$areanames{en}->{917289} = "Zhirnia\,\ Madhya\ Pradesh";
$areanames{en}->{917290} = "Badwani\,\ Madhya\ Pradesh";
$areanames{en}->{917291} = "Manawar\,\ Madhya\ Pradesh";
$areanames{en}->{917292} = "Dhar\,\ Madhya\ Pradesh";
$areanames{en}->{917294} = "Dharampuri\,\ Madhya\ Pradesh";
$areanames{en}->{917295} = "Badnawar\,\ Madhya\ Pradesh";
$areanames{en}->{917296} = "Sardarpur\,\ Madhya\ Pradesh";
$areanames{en}->{917297} = "Kukshi\,\ Madhya\ Pradesh";
$areanames{en}->{91731} = "Indore\,\ Madhya\ Pradesh";
$areanames{en}->{9173200} = "Pandhana\,\ Madhya\ Pradesh";
$areanames{en}->{9173202} = "Pandhana\,\ Madhya\ Pradesh";
$areanames{en}->{9173203} = "Pandhana\,\ Madhya\ Pradesh";
$areanames{en}->{9173204} = "Pandhana\,\ Madhya\ Pradesh";
$areanames{en}->{9173205} = "Pandhana\,\ Madhya\ Pradesh";
$areanames{en}->{9173206} = "Pandhana\,\ Madhya\ Pradesh";
$areanames{en}->{9173207} = "Pandhana\,\ Madhya\ Pradesh";
$areanames{en}->{9173208} = "Pandhana\,\ Madhya\ Pradesh";
$areanames{en}->{9173209} = "Pandhana\,\ Madhya\ Pradesh";
$areanames{en}->{9173210} = "Sanwer\,\ Madhya\ Pradesh";
$areanames{en}->{9173212} = "Sanwer\,\ Madhya\ Pradesh";
$areanames{en}->{9173213} = "Sanwer\,\ Madhya\ Pradesh";
$areanames{en}->{9173214} = "Sanwer\,\ Madhya\ Pradesh";
$areanames{en}->{9173215} = "Sanwer\,\ Madhya\ Pradesh";
$areanames{en}->{9173216} = "Sanwer\,\ Madhya\ Pradesh";
$areanames{en}->{9173217} = "Sanwer\,\ Madhya\ Pradesh";
$areanames{en}->{9173218} = "Sanwer\,\ Madhya\ Pradesh";
$areanames{en}->{9173219} = "Sanwer\,\ Madhya\ Pradesh";
$areanames{en}->{9173220} = "Depalpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173222} = "Depalpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173223} = "Depalpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173224} = "Depalpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173225} = "Depalpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173226} = "Depalpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173227} = "Depalpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173228} = "Depalpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173229} = "Depalpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173230} = "Punasa\,\ Madhya\ Pradesh";
$areanames{en}->{9173232} = "Punasa\,\ Madhya\ Pradesh";
$areanames{en}->{9173233} = "Punasa\,\ Madhya\ Pradesh";
$areanames{en}->{9173234} = "Punasa\,\ Madhya\ Pradesh";
$areanames{en}->{9173235} = "Punasa\,\ Madhya\ Pradesh";
$areanames{en}->{9173236} = "Punasa\,\ Madhya\ Pradesh";
$areanames{en}->{9173237} = "Punasa\,\ Madhya\ Pradesh";
$areanames{en}->{9173238} = "Punasa\,\ Madhya\ Pradesh";
$areanames{en}->{9173239} = "Punasa\,\ Madhya\ Pradesh";
$areanames{en}->{9173240} = "Mhow\,\ Madhya\ Pradesh";
$areanames{en}->{9173242} = "Mhow\,\ Madhya\ Pradesh";
$areanames{en}->{9173243} = "Mhow\,\ Madhya\ Pradesh";
$areanames{en}->{9173244} = "Mhow\,\ Madhya\ Pradesh";
$areanames{en}->{9173245} = "Mhow\,\ Madhya\ Pradesh";
$areanames{en}->{9173246} = "Mhow\,\ Madhya\ Pradesh";
$areanames{en}->{9173247} = "Mhow\,\ Madhya\ Pradesh";
$areanames{en}->{9173248} = "Mhow\,\ Madhya\ Pradesh";
$areanames{en}->{9173249} = "Mhow\,\ Madhya\ Pradesh";
$areanames{en}->{917325} = "Burhanpur\,\ Madhya\ Pradesh";
$areanames{en}->{917326} = "Baldi\,\ Madhya\ Pradesh";
$areanames{en}->{917327} = "Harsud\,\ Madhya\ Pradesh";
$areanames{en}->{917328} = "Khalwa\,\ Madhya\ Pradesh";
$areanames{en}->{9173290} = "Khakner\,\ Madhya\ Pradesh";
$areanames{en}->{9173292} = "Khakner\,\ Madhya\ Pradesh";
$areanames{en}->{9173293} = "Khakner\,\ Madhya\ Pradesh";
$areanames{en}->{9173294} = "Khakner\,\ Madhya\ Pradesh";
$areanames{en}->{9173295} = "Khakner\,\ Madhya\ Pradesh";
$areanames{en}->{9173296} = "Khakner\,\ Madhya\ Pradesh";
$areanames{en}->{9173297} = "Khakner\,\ Madhya\ Pradesh";
$areanames{en}->{9173298} = "Khakner\,\ Madhya\ Pradesh";
$areanames{en}->{9173299} = "Khakner\,\ Madhya\ Pradesh";
$areanames{en}->{91733} = "Khandwa\,\ Madhya\ Pradesh";
$areanames{en}->{91734} = "Ujjain\,\ Madhya\ Pradesh";
$areanames{en}->{917360} = "Shujalpur\,\ Madhya\ Pradesh";
$areanames{en}->{917361} = "Susner\,\ Madhya\ Pradesh";
$areanames{en}->{917362} = "Agar\,\ Madhya\ Pradesh";
$areanames{en}->{917363} = "Berchha\,\ Madhya\ Pradesh";
$areanames{en}->{917364} = "Shajapur\,\ Madhya\ Pradesh";
$areanames{en}->{917365} = "Mahidpurcity\,\ Madhya\ Pradesh";
$areanames{en}->{917366} = "Khachrod\,\ Madhya\ Pradesh";
$areanames{en}->{917367} = "Badnagar\,\ Madhya\ Pradesh";
$areanames{en}->{917368} = "Ghatia\,\ Madhya\ Pradesh";
$areanames{en}->{917369} = "Tarana\,\ Madhya\ Pradesh";
$areanames{en}->{917370} = "Khilchipur\,\ Madhya\ Pradesh";
$areanames{en}->{917371} = "Sarangpur\,\ Madhya\ Pradesh";
$areanames{en}->{917372} = "Rajgarh\,\ Madhya\ Pradesh";
$areanames{en}->{917374} = "Biaora\,\ Madhya\ Pradesh";
$areanames{en}->{917375} = "Narsingharh\,\ Madhya\ Pradesh";
$areanames{en}->{917390} = "Thandla\,\ Madhya\ Pradesh";
$areanames{en}->{917391} = "Petlawad\,\ Madhya\ Pradesh";
$areanames{en}->{9173920} = "Jhabua\,\ Madhya\ Pradesh";
$areanames{en}->{9173922} = "Jhabua\,\ Madhya\ Pradesh";
$areanames{en}->{9173923} = "Jhabua\,\ Madhya\ Pradesh";
$areanames{en}->{9173924} = "Jhabua\,\ Madhya\ Pradesh";
$areanames{en}->{9173925} = "Jhabua\,\ Madhya\ Pradesh";
$areanames{en}->{9173926} = "Jhabua\,\ Madhya\ Pradesh";
$areanames{en}->{9173927} = "Jhabua\,\ Madhya\ Pradesh";
$areanames{en}->{9173928} = "Jhabua\,\ Madhya\ Pradesh";
$areanames{en}->{9173929} = "Jhabua\,\ Madhya\ Pradesh";
$areanames{en}->{9173930} = "Jobat\,\ Madhya\ Pradesh";
$areanames{en}->{9173932} = "Jobat\,\ Madhya\ Pradesh";
$areanames{en}->{9173933} = "Jobat\,\ Madhya\ Pradesh";
$areanames{en}->{9173934} = "Jobat\,\ Madhya\ Pradesh";
$areanames{en}->{9173935} = "Jobat\,\ Madhya\ Pradesh";
$areanames{en}->{9173936} = "Jobat\,\ Madhya\ Pradesh";
$areanames{en}->{9173937} = "Jobat\,\ Madhya\ Pradesh";
$areanames{en}->{9173938} = "Jobat\,\ Madhya\ Pradesh";
$areanames{en}->{9173939} = "Jobat\,\ Madhya\ Pradesh";
$areanames{en}->{9173940} = "Alirajpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173942} = "Alirajpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173943} = "Alirajpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173944} = "Alirajpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173945} = "Alirajpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173946} = "Alirajpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173947} = "Alirajpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173948} = "Alirajpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173949} = "Alirajpur\,\ Madhya\ Pradesh";
$areanames{en}->{9173950} = "Sondhwa\,\ Madhya\ Pradesh";
$areanames{en}->{9173952} = "Sondhwa\,\ Madhya\ Pradesh";
$areanames{en}->{9173953} = "Sondhwa\,\ Madhya\ Pradesh";
$areanames{en}->{9173954} = "Sondhwa\,\ Madhya\ Pradesh";
$areanames{en}->{9173955} = "Sondhwa\,\ Madhya\ Pradesh";
$areanames{en}->{9173956} = "Sondhwa\,\ Madhya\ Pradesh";
$areanames{en}->{9173957} = "Sondhwa\,\ Madhya\ Pradesh";
$areanames{en}->{9173958} = "Sondhwa\,\ Madhya\ Pradesh";
$areanames{en}->{9173959} = "Sondhwa\,\ Madhya\ Pradesh";
$areanames{en}->{917410} = "Alot\,\ Madhya\ Pradesh";
$areanames{en}->{9174120} = "Ratlam\,\ Madhya\ Pradesh";
$areanames{en}->{9174122} = "Ratlam\,\ Madhya\ Pradesh";
$areanames{en}->{9174123} = "Ratlam\,\ Madhya\ Pradesh";
$areanames{en}->{9174124} = "Ratlam\,\ Madhya\ Pradesh";
$areanames{en}->{9174125} = "Ratlam\,\ Madhya\ Pradesh";
$areanames{en}->{9174126} = "Ratlam\,\ Madhya\ Pradesh";
$areanames{en}->{9174127} = "Ratlam\,\ Madhya\ Pradesh";
$areanames{en}->{9174128} = "Ratlam\,\ Madhya\ Pradesh";
$areanames{en}->{9174129} = "Ratlam\,\ Madhya\ Pradesh";
$areanames{en}->{9174130} = "Sailana\,\ Madhya\ Pradesh";
$areanames{en}->{9174132} = "Sailana\,\ Madhya\ Pradesh";
$areanames{en}->{9174133} = "Sailana\,\ Madhya\ Pradesh";
$areanames{en}->{9174134} = "Sailana\,\ Madhya\ Pradesh";
$areanames{en}->{9174135} = "Sailana\,\ Madhya\ Pradesh";
$areanames{en}->{9174136} = "Sailana\,\ Madhya\ Pradesh";
$areanames{en}->{9174137} = "Sailana\,\ Madhya\ Pradesh";
$areanames{en}->{9174138} = "Sailana\,\ Madhya\ Pradesh";
$areanames{en}->{9174139} = "Sailana\,\ Madhya\ Pradesh";
$areanames{en}->{9174140} = "Jaora\,\ Madhya\ Pradesh";
$areanames{en}->{9174142} = "Jaora\,\ Madhya\ Pradesh";
$areanames{en}->{9174143} = "Jaora\,\ Madhya\ Pradesh";
$areanames{en}->{9174144} = "Jaora\,\ Madhya\ Pradesh";
$areanames{en}->{9174145} = "Jaora\,\ Madhya\ Pradesh";
$areanames{en}->{9174146} = "Jaora\,\ Madhya\ Pradesh";
$areanames{en}->{9174147} = "Jaora\,\ Madhya\ Pradesh";
$areanames{en}->{9174148} = "Jaora\,\ Madhya\ Pradesh";
$areanames{en}->{9174149} = "Jaora\,\ Madhya\ Pradesh";
$areanames{en}->{9174200} = "Jawad\,\ Madhya\ Pradesh";
$areanames{en}->{9174202} = "Jawad\,\ Madhya\ Pradesh";
$areanames{en}->{9174203} = "Jawad\,\ Madhya\ Pradesh";
$areanames{en}->{9174204} = "Jawad\,\ Madhya\ Pradesh";
$areanames{en}->{9174205} = "Jawad\,\ Madhya\ Pradesh";
$areanames{en}->{9174206} = "Jawad\,\ Madhya\ Pradesh";
$areanames{en}->{9174207} = "Jawad\,\ Madhya\ Pradesh";
$areanames{en}->{9174208} = "Jawad\,\ Madhya\ Pradesh";
$areanames{en}->{9174209} = "Jawad\,\ Madhya\ Pradesh";
$areanames{en}->{9174210} = "Manasa\,\ Madhya\ Pradesh";
$areanames{en}->{9174212} = "Manasa\,\ Madhya\ Pradesh";
$areanames{en}->{9174213} = "Manasa\,\ Madhya\ Pradesh";
$areanames{en}->{9174214} = "Manasa\,\ Madhya\ Pradesh";
$areanames{en}->{9174215} = "Manasa\,\ Madhya\ Pradesh";
$areanames{en}->{9174216} = "Manasa\,\ Madhya\ Pradesh";
$areanames{en}->{9174217} = "Manasa\,\ Madhya\ Pradesh";
$areanames{en}->{9174218} = "Manasa\,\ Madhya\ Pradesh";
$areanames{en}->{9174219} = "Manasa\,\ Madhya\ Pradesh";
$areanames{en}->{9174220} = "Mandsaur\,\ Madhya\ Pradesh";
$areanames{en}->{9174222} = "Mandsaur\,\ Madhya\ Pradesh";
$areanames{en}->{9174223} = "Mandsaur\,\ Madhya\ Pradesh";
$areanames{en}->{9174224} = "Mandsaur\,\ Madhya\ Pradesh";
$areanames{en}->{9174225} = "Mandsaur\,\ Madhya\ Pradesh";
$areanames{en}->{9174226} = "Mandsaur\,\ Madhya\ Pradesh";
$areanames{en}->{9174227} = "Mandsaur\,\ Madhya\ Pradesh";
$areanames{en}->{9174228} = "Mandsaur\,\ Madhya\ Pradesh";
$areanames{en}->{9174229} = "Mandsaur\,\ Madhya\ Pradesh";
$areanames{en}->{9174230} = "Neemuch\,\ Madhya\ Pradesh";
$areanames{en}->{9174232} = "Neemuch\,\ Madhya\ Pradesh";
$areanames{en}->{9174233} = "Neemuch\,\ Madhya\ Pradesh";
$areanames{en}->{9174234} = "Neemuch\,\ Madhya\ Pradesh";
$areanames{en}->{9174235} = "Neemuch\,\ Madhya\ Pradesh";
$areanames{en}->{9174236} = "Neemuch\,\ Madhya\ Pradesh";
$areanames{en}->{9174237} = "Neemuch\,\ Madhya\ Pradesh";
$areanames{en}->{9174238} = "Neemuch\,\ Madhya\ Pradesh";
$areanames{en}->{9174239} = "Neemuch\,\ Madhya\ Pradesh";
$areanames{en}->{9174240} = "Malhargarh\,\ Madhya\ Pradesh";
$areanames{en}->{9174242} = "Malhargarh\,\ Madhya\ Pradesh";
$areanames{en}->{9174243} = "Malhargarh\,\ Madhya\ Pradesh";
$areanames{en}->{9174244} = "Malhargarh\,\ Madhya\ Pradesh";
$areanames{en}->{9174245} = "Malhargarh\,\ Madhya\ Pradesh";
$areanames{en}->{9174246} = "Malhargarh\,\ Madhya\ Pradesh";
$areanames{en}->{9174247} = "Malhargarh\,\ Madhya\ Pradesh";
$areanames{en}->{9174248} = "Malhargarh\,\ Madhya\ Pradesh";
$areanames{en}->{9174249} = "Malhargarh\,\ Madhya\ Pradesh";
$areanames{en}->{9174250} = "Garoth\,\ Madhya\ Pradesh";
$areanames{en}->{9174252} = "Garoth\,\ Madhya\ Pradesh";
$areanames{en}->{9174253} = "Garoth\,\ Madhya\ Pradesh";
$areanames{en}->{9174254} = "Garoth\,\ Madhya\ Pradesh";
$areanames{en}->{9174255} = "Garoth\,\ Madhya\ Pradesh";
$areanames{en}->{9174256} = "Garoth\,\ Madhya\ Pradesh";
$areanames{en}->{9174257} = "Garoth\,\ Madhya\ Pradesh";
$areanames{en}->{9174258} = "Garoth\,\ Madhya\ Pradesh";
$areanames{en}->{9174259} = "Garoth\,\ Madhya\ Pradesh";
$areanames{en}->{9174260} = "Sitamau\,\ Madhya\ Pradesh";
$areanames{en}->{9174262} = "Sitamau\,\ Madhya\ Pradesh";
$areanames{en}->{9174263} = "Sitamau\,\ Madhya\ Pradesh";
$areanames{en}->{9174264} = "Sitamau\,\ Madhya\ Pradesh";
$areanames{en}->{9174265} = "Sitamau\,\ Madhya\ Pradesh";
$areanames{en}->{9174266} = "Sitamau\,\ Madhya\ Pradesh";
$areanames{en}->{9174267} = "Sitamau\,\ Madhya\ Pradesh";
$areanames{en}->{9174268} = "Sitamau\,\ Madhya\ Pradesh";
$areanames{en}->{9174269} = "Sitamau\,\ Madhya\ Pradesh";
$areanames{en}->{9174270} = "Bhanpura\,\ Madhya\ Pradesh";
$areanames{en}->{9174272} = "Bhanpura\,\ Madhya\ Pradesh";
$areanames{en}->{9174273} = "Bhanpura\,\ Madhya\ Pradesh";
$areanames{en}->{9174274} = "Bhanpura\,\ Madhya\ Pradesh";
$areanames{en}->{9174275} = "Bhanpura\,\ Madhya\ Pradesh";
$areanames{en}->{9174276} = "Bhanpura\,\ Madhya\ Pradesh";
$areanames{en}->{9174277} = "Bhanpura\,\ Madhya\ Pradesh";
$areanames{en}->{9174278} = "Bhanpura\,\ Madhya\ Pradesh";
$areanames{en}->{9174279} = "Bhanpura\,\ Madhya\ Pradesh";
$areanames{en}->{9174300} = "Khanpur\,\ Rajasthan";
$areanames{en}->{9174302} = "Khanpur\,\ Rajasthan";
$areanames{en}->{9174303} = "Khanpur\,\ Rajasthan";
$areanames{en}->{9174304} = "Khanpur\,\ Rajasthan";
$areanames{en}->{9174305} = "Khanpur\,\ Rajasthan";
$areanames{en}->{9174306} = "Khanpur\,\ Rajasthan";
$areanames{en}->{9174307} = "Khanpur\,\ Rajasthan";
$areanames{en}->{9174308} = "Khanpur\,\ Rajasthan";
$areanames{en}->{9174309} = "Khanpur\,\ Rajasthan";
$areanames{en}->{9174310} = "Aklera\,\ Rajasthan";
$areanames{en}->{9174312} = "Aklera\,\ Rajasthan";
$areanames{en}->{9174313} = "Aklera\,\ Rajasthan";
$areanames{en}->{9174314} = "Aklera\,\ Rajasthan";
$areanames{en}->{9174315} = "Aklera\,\ Rajasthan";
$areanames{en}->{9174316} = "Aklera\,\ Rajasthan";
$areanames{en}->{9174317} = "Aklera\,\ Rajasthan";
$areanames{en}->{9174318} = "Aklera\,\ Rajasthan";
$areanames{en}->{9174319} = "Aklera\,\ Rajasthan";
$areanames{en}->{9174320} = "Jhalawar\,\ Rajasthan";
$areanames{en}->{9174322} = "Jhalawar\,\ Rajasthan";
$areanames{en}->{9174323} = "Jhalawar\,\ Rajasthan";
$areanames{en}->{9174324} = "Jhalawar\,\ Rajasthan";
$areanames{en}->{9174325} = "Jhalawar\,\ Rajasthan";
$areanames{en}->{9174326} = "Jhalawar\,\ Rajasthan";
$areanames{en}->{9174327} = "Jhalawar\,\ Rajasthan";
$areanames{en}->{9174328} = "Jhalawar\,\ Rajasthan";
$areanames{en}->{9174329} = "Jhalawar\,\ Rajasthan";
$areanames{en}->{9174330} = "Pachpahar\/Bhawanimandi\,\ Rajasthan";
$areanames{en}->{9174332} = "Pachpahar\/Bhawanimandi\,\ Rajasthan";
$areanames{en}->{9174333} = "Pachpahar\/Bhawanimandi\,\ Rajasthan";
$areanames{en}->{9174334} = "Pachpahar\/Bhawanimandi\,\ Rajasthan";
$areanames{en}->{9174335} = "Pachpahar\/Bhawanimandi\,\ Rajasthan";
$areanames{en}->{9174336} = "Pachpahar\/Bhawanimandi\,\ Rajasthan";
$areanames{en}->{9174337} = "Pachpahar\/Bhawanimandi\,\ Rajasthan";
$areanames{en}->{9174338} = "Pachpahar\/Bhawanimandi\,\ Rajasthan";
$areanames{en}->{9174339} = "Pachpahar\/Bhawanimandi\,\ Rajasthan";
$areanames{en}->{9174340} = "Pirawa\/Raipur\,\ Rajasthan";
$areanames{en}->{9174342} = "Pirawa\/Raipur\,\ Rajasthan";
$areanames{en}->{9174343} = "Pirawa\/Raipur\,\ Rajasthan";
$areanames{en}->{9174344} = "Pirawa\/Raipur\,\ Rajasthan";
$areanames{en}->{9174345} = "Pirawa\/Raipur\,\ Rajasthan";
$areanames{en}->{9174346} = "Pirawa\/Raipur\,\ Rajasthan";
$areanames{en}->{9174347} = "Pirawa\/Raipur\,\ Rajasthan";
$areanames{en}->{9174348} = "Pirawa\/Raipur\,\ Rajasthan";
$areanames{en}->{9174349} = "Pirawa\/Raipur\,\ Rajasthan";
$areanames{en}->{9174350} = "Gangdhar\,\ Rajasthan";
$areanames{en}->{9174352} = "Gangdhar\,\ Rajasthan";
$areanames{en}->{9174353} = "Gangdhar\,\ Rajasthan";
$areanames{en}->{9174354} = "Gangdhar\,\ Rajasthan";
$areanames{en}->{9174355} = "Gangdhar\,\ Rajasthan";
$areanames{en}->{9174356} = "Gangdhar\,\ Rajasthan";
$areanames{en}->{9174357} = "Gangdhar\,\ Rajasthan";
$areanames{en}->{9174358} = "Gangdhar\,\ Rajasthan";
$areanames{en}->{9174359} = "Gangdhar\,\ Rajasthan";
$areanames{en}->{9174360} = "Hindoli\,\ Rajasthan";
$areanames{en}->{9174362} = "Hindoli\,\ Rajasthan";
$areanames{en}->{9174363} = "Hindoli\,\ Rajasthan";
$areanames{en}->{9174364} = "Hindoli\,\ Rajasthan";
$areanames{en}->{9174365} = "Hindoli\,\ Rajasthan";
$areanames{en}->{9174366} = "Hindoli\,\ Rajasthan";
$areanames{en}->{9174367} = "Hindoli\,\ Rajasthan";
$areanames{en}->{9174368} = "Hindoli\,\ Rajasthan";
$areanames{en}->{9174369} = "Hindoli\,\ Rajasthan";
$areanames{en}->{9174370} = "Nainwa\,\ Rajasthan";
$areanames{en}->{9174372} = "Nainwa\,\ Rajasthan";
$areanames{en}->{9174373} = "Nainwa\,\ Rajasthan";
$areanames{en}->{9174374} = "Nainwa\,\ Rajasthan";
$areanames{en}->{9174375} = "Nainwa\,\ Rajasthan";
$areanames{en}->{9174376} = "Nainwa\,\ Rajasthan";
$areanames{en}->{9174377} = "Nainwa\,\ Rajasthan";
$areanames{en}->{9174378} = "Nainwa\,\ Rajasthan";
$areanames{en}->{9174379} = "Nainwa\,\ Rajasthan";
$areanames{en}->{9174380} = "Keshoraipatan\/Patan\,\ Rajasthan";
$areanames{en}->{9174382} = "Keshoraipatan\/Patan\,\ Rajasthan";
$areanames{en}->{9174383} = "Keshoraipatan\/Patan\,\ Rajasthan";
$areanames{en}->{9174384} = "Keshoraipatan\/Patan\,\ Rajasthan";
$areanames{en}->{9174385} = "Keshoraipatan\/Patan\,\ Rajasthan";
$areanames{en}->{9174386} = "Keshoraipatan\/Patan\,\ Rajasthan";
$areanames{en}->{9174387} = "Keshoraipatan\/Patan\,\ Rajasthan";
$areanames{en}->{9174388} = "Keshoraipatan\/Patan\,\ Rajasthan";
$areanames{en}->{9174389} = "Keshoraipatan\/Patan\,\ Rajasthan";
$areanames{en}->{917440} = "Ladpura\/Kota\,\ Rajasthan";
$areanames{en}->{9174411} = "Ladpura\/Kota\,\ Rajasthan";
$areanames{en}->{917442} = "Ladpura\/Kota\,\ Rajasthan";
$areanames{en}->{917443} = "Ladpura\/Kota\,\ Rajasthan";
$areanames{en}->{917444} = "Ladpura\/Kota\,\ Rajasthan";
$areanames{en}->{917445} = "Ladpura\/Kota\,\ Rajasthan";
$areanames{en}->{917446} = "Ladpura\/Kota\,\ Rajasthan";
$areanames{en}->{917447} = "Ladpura\/Kota\,\ Rajasthan";
$areanames{en}->{917448} = "Ladpura\/Kota\,\ Rajasthan";
$areanames{en}->{917449} = "Ladpura\/Kota\,\ Rajasthan";
$areanames{en}->{9174500} = "Sangod\,\ Rajasthan";
$areanames{en}->{9174502} = "Sangod\,\ Rajasthan";
$areanames{en}->{9174503} = "Sangod\,\ Rajasthan";
$areanames{en}->{9174504} = "Sangod\,\ Rajasthan";
$areanames{en}->{9174505} = "Sangod\,\ Rajasthan";
$areanames{en}->{9174506} = "Sangod\,\ Rajasthan";
$areanames{en}->{9174507} = "Sangod\,\ Rajasthan";
$areanames{en}->{9174508} = "Sangod\,\ Rajasthan";
$areanames{en}->{9174509} = "Sangod\,\ Rajasthan";
$areanames{en}->{9174510} = "Atru\,\ Rajasthan";
$areanames{en}->{9174512} = "Atru\,\ Rajasthan";
$areanames{en}->{9174513} = "Atru\,\ Rajasthan";
$areanames{en}->{9174514} = "Atru\,\ Rajasthan";
$areanames{en}->{9174515} = "Atru\,\ Rajasthan";
$areanames{en}->{9174516} = "Atru\,\ Rajasthan";
$areanames{en}->{9174517} = "Atru\,\ Rajasthan";
$areanames{en}->{9174518} = "Atru\,\ Rajasthan";
$areanames{en}->{9174519} = "Atru\,\ Rajasthan";
$areanames{en}->{9174520} = "Chhabra\,\ Rajasthan";
$areanames{en}->{9174522} = "Chhabra\,\ Rajasthan";
$areanames{en}->{9174523} = "Chhabra\,\ Rajasthan";
$areanames{en}->{9174524} = "Chhabra\,\ Rajasthan";
$areanames{en}->{9174525} = "Chhabra\,\ Rajasthan";
$areanames{en}->{9174526} = "Chhabra\,\ Rajasthan";
$areanames{en}->{9174527} = "Chhabra\,\ Rajasthan";
$areanames{en}->{9174528} = "Chhabra\,\ Rajasthan";
$areanames{en}->{9174529} = "Chhabra\,\ Rajasthan";
$areanames{en}->{9174530} = "Baran\,\ Rajasthan";
$areanames{en}->{9174532} = "Baran\,\ Rajasthan";
$areanames{en}->{9174533} = "Baran\,\ Rajasthan";
$areanames{en}->{9174534} = "Baran\,\ Rajasthan";
$areanames{en}->{9174535} = "Baran\,\ Rajasthan";
$areanames{en}->{9174536} = "Baran\,\ Rajasthan";
$areanames{en}->{9174537} = "Baran\,\ Rajasthan";
$areanames{en}->{9174538} = "Baran\,\ Rajasthan";
$areanames{en}->{9174539} = "Baran\,\ Rajasthan";
$areanames{en}->{9174540} = "Chhipaborad\,\ Rajasthan";
$areanames{en}->{9174542} = "Chhipaborad\,\ Rajasthan";
$areanames{en}->{9174543} = "Chhipaborad\,\ Rajasthan";
$areanames{en}->{9174544} = "Chhipaborad\,\ Rajasthan";
$areanames{en}->{9174545} = "Chhipaborad\,\ Rajasthan";
$areanames{en}->{9174546} = "Chhipaborad\,\ Rajasthan";
$areanames{en}->{9174547} = "Chhipaborad\,\ Rajasthan";
$areanames{en}->{9174548} = "Chhipaborad\,\ Rajasthan";
$areanames{en}->{9174549} = "Chhipaborad\,\ Rajasthan";
$areanames{en}->{9174550} = "Digod\/Sultanpur\,\ Rajasthan";
$areanames{en}->{9174552} = "Digod\/Sultanpur\,\ Rajasthan";
$areanames{en}->{9174553} = "Digod\/Sultanpur\,\ Rajasthan";
$areanames{en}->{9174554} = "Digod\/Sultanpur\,\ Rajasthan";
$areanames{en}->{9174555} = "Digod\/Sultanpur\,\ Rajasthan";
$areanames{en}->{9174556} = "Digod\/Sultanpur\,\ Rajasthan";
$areanames{en}->{9174557} = "Digod\/Sultanpur\,\ Rajasthan";
$areanames{en}->{9174558} = "Digod\/Sultanpur\,\ Rajasthan";
$areanames{en}->{9174559} = "Digod\/Sultanpur\,\ Rajasthan";
$areanames{en}->{9174560} = "Kishanganj\/Bhanwargarh\,\ Rajasthan";
$areanames{en}->{9174562} = "Kishanganj\/Bhanwargarh\,\ Rajasthan";
$areanames{en}->{9174563} = "Kishanganj\/Bhanwargarh\,\ Rajasthan";
$areanames{en}->{9174564} = "Kishanganj\/Bhanwargarh\,\ Rajasthan";
$areanames{en}->{9174565} = "Kishanganj\/Bhanwargarh\,\ Rajasthan";
$areanames{en}->{9174566} = "Kishanganj\/Bhanwargarh\,\ Rajasthan";
$areanames{en}->{9174567} = "Kishanganj\/Bhanwargarh\,\ Rajasthan";
$areanames{en}->{9174568} = "Kishanganj\/Bhanwargarh\,\ Rajasthan";
$areanames{en}->{9174569} = "Kishanganj\/Bhanwargarh\,\ Rajasthan";
$areanames{en}->{9174570} = "Mangrol\,\ Rajasthan";
$areanames{en}->{9174572} = "Mangrol\,\ Rajasthan";
$areanames{en}->{9174573} = "Mangrol\,\ Rajasthan";
$areanames{en}->{9174574} = "Mangrol\,\ Rajasthan";
$areanames{en}->{9174575} = "Mangrol\,\ Rajasthan";
$areanames{en}->{9174576} = "Mangrol\,\ Rajasthan";
$areanames{en}->{9174577} = "Mangrol\,\ Rajasthan";
$areanames{en}->{9174578} = "Mangrol\,\ Rajasthan";
$areanames{en}->{9174579} = "Mangrol\,\ Rajasthan";
$areanames{en}->{9174580} = "Pipalda\/Sumerganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174582} = "Pipalda\/Sumerganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174583} = "Pipalda\/Sumerganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174584} = "Pipalda\/Sumerganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174585} = "Pipalda\/Sumerganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174586} = "Pipalda\/Sumerganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174587} = "Pipalda\/Sumerganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174588} = "Pipalda\/Sumerganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174589} = "Pipalda\/Sumerganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174590} = "Ramganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174592} = "Ramganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174593} = "Ramganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174594} = "Ramganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174595} = "Ramganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174596} = "Ramganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174597} = "Ramganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174598} = "Ramganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174599} = "Ramganj\ Mandi\,\ Rajasthan";
$areanames{en}->{9174600} = "Sahabad\,\ Rajasthan";
$areanames{en}->{9174602} = "Sahabad\,\ Rajasthan";
$areanames{en}->{9174603} = "Sahabad\,\ Rajasthan";
$areanames{en}->{9174604} = "Sahabad\,\ Rajasthan";
$areanames{en}->{9174605} = "Sahabad\,\ Rajasthan";
$areanames{en}->{9174606} = "Sahabad\,\ Rajasthan";
$areanames{en}->{9174607} = "Sahabad\,\ Rajasthan";
$areanames{en}->{9174608} = "Sahabad\,\ Rajasthan";
$areanames{en}->{9174609} = "Sahabad\,\ Rajasthan";
$areanames{en}->{9174610} = "Mahuwa\,\ Rajasthan";
$areanames{en}->{9174612} = "Mahuwa\,\ Rajasthan";
$areanames{en}->{9174613} = "Mahuwa\,\ Rajasthan";
$areanames{en}->{9174614} = "Mahuwa\,\ Rajasthan";
$areanames{en}->{9174615} = "Mahuwa\,\ Rajasthan";
$areanames{en}->{9174616} = "Mahuwa\,\ Rajasthan";
$areanames{en}->{9174617} = "Mahuwa\,\ Rajasthan";
$areanames{en}->{9174618} = "Mahuwa\,\ Rajasthan";
$areanames{en}->{9174619} = "Mahuwa\,\ Rajasthan";
$areanames{en}->{9174620} = "Sawaimadhopur\,\ Rajasthan";
$areanames{en}->{9174622} = "Sawaimadhopur\,\ Rajasthan";
$areanames{en}->{9174623} = "Sawaimadhopur\,\ Rajasthan";
$areanames{en}->{9174624} = "Sawaimadhopur\,\ Rajasthan";
$areanames{en}->{9174625} = "Sawaimadhopur\,\ Rajasthan";
$areanames{en}->{9174626} = "Sawaimadhopur\,\ Rajasthan";
$areanames{en}->{9174627} = "Sawaimadhopur\,\ Rajasthan";
$areanames{en}->{9174628} = "Sawaimadhopur\,\ Rajasthan";
$areanames{en}->{9174629} = "Sawaimadhopur\,\ Rajasthan";
$areanames{en}->{9174630} = "Gangapur\,\ Rajasthan";
$areanames{en}->{9174632} = "Gangapur\,\ Rajasthan";
$areanames{en}->{9174633} = "Gangapur\,\ Rajasthan";
$areanames{en}->{9174634} = "Gangapur\,\ Rajasthan";
$areanames{en}->{9174635} = "Gangapur\,\ Rajasthan";
$areanames{en}->{9174636} = "Gangapur\,\ Rajasthan";
$areanames{en}->{9174637} = "Gangapur\,\ Rajasthan";
$areanames{en}->{9174638} = "Gangapur\,\ Rajasthan";
$areanames{en}->{9174639} = "Gangapur\,\ Rajasthan";
$areanames{en}->{9174640} = "Karauli\,\ Rajasthan";
$areanames{en}->{9174642} = "Karauli\,\ Rajasthan";
$areanames{en}->{9174643} = "Karauli\,\ Rajasthan";
$areanames{en}->{9174644} = "Karauli\,\ Rajasthan";
$areanames{en}->{9174645} = "Karauli\,\ Rajasthan";
$areanames{en}->{9174646} = "Karauli\,\ Rajasthan";
$areanames{en}->{9174647} = "Karauli\,\ Rajasthan";
$areanames{en}->{9174648} = "Karauli\,\ Rajasthan";
$areanames{en}->{9174649} = "Karauli\,\ Rajasthan";
$areanames{en}->{9174650} = "Sapotra\,\ Rajasthan";
$areanames{en}->{9174652} = "Sapotra\,\ Rajasthan";
$areanames{en}->{9174653} = "Sapotra\,\ Rajasthan";
$areanames{en}->{9174654} = "Sapotra\,\ Rajasthan";
$areanames{en}->{9174655} = "Sapotra\,\ Rajasthan";
$areanames{en}->{9174656} = "Sapotra\,\ Rajasthan";
$areanames{en}->{9174657} = "Sapotra\,\ Rajasthan";
$areanames{en}->{9174658} = "Sapotra\,\ Rajasthan";
$areanames{en}->{9174659} = "Sapotra\,\ Rajasthan";
$areanames{en}->{9174660} = "Bonli\,\ Rajasthan";
$areanames{en}->{9174662} = "Bonli\,\ Rajasthan";
$areanames{en}->{9174663} = "Bonli\,\ Rajasthan";
$areanames{en}->{9174664} = "Bonli\,\ Rajasthan";
$areanames{en}->{9174665} = "Bonli\,\ Rajasthan";
$areanames{en}->{9174666} = "Bonli\,\ Rajasthan";
$areanames{en}->{9174667} = "Bonli\,\ Rajasthan";
$areanames{en}->{9174668} = "Bonli\,\ Rajasthan";
$areanames{en}->{9174669} = "Bonli\,\ Rajasthan";
$areanames{en}->{9174670} = "Bamanwas\,\ Rajasthan";
$areanames{en}->{9174672} = "Bamanwas\,\ Rajasthan";
$areanames{en}->{9174673} = "Bamanwas\,\ Rajasthan";
$areanames{en}->{9174674} = "Bamanwas\,\ Rajasthan";
$areanames{en}->{9174675} = "Bamanwas\,\ Rajasthan";
$areanames{en}->{9174676} = "Bamanwas\,\ Rajasthan";
$areanames{en}->{9174677} = "Bamanwas\,\ Rajasthan";
$areanames{en}->{9174678} = "Bamanwas\,\ Rajasthan";
$areanames{en}->{9174679} = "Bamanwas\,\ Rajasthan";
$areanames{en}->{9174680} = "Khandar\,\ Rajasthan";
$areanames{en}->{9174682} = "Khandar\,\ Rajasthan";
$areanames{en}->{9174683} = "Khandar\,\ Rajasthan";
$areanames{en}->{9174684} = "Khandar\,\ Rajasthan";
$areanames{en}->{9174685} = "Khandar\,\ Rajasthan";
$areanames{en}->{9174686} = "Khandar\,\ Rajasthan";
$areanames{en}->{9174687} = "Khandar\,\ Rajasthan";
$areanames{en}->{9174688} = "Khandar\,\ Rajasthan";
$areanames{en}->{9174689} = "Khandar\,\ Rajasthan";
$areanames{en}->{9174690} = "Hindaun\,\ Rajasthan";
$areanames{en}->{9174692} = "Hindaun\,\ Rajasthan";
$areanames{en}->{9174693} = "Hindaun\,\ Rajasthan";
$areanames{en}->{9174694} = "Hindaun\,\ Rajasthan";
$areanames{en}->{9174695} = "Hindaun\,\ Rajasthan";
$areanames{en}->{9174696} = "Hindaun\,\ Rajasthan";
$areanames{en}->{9174697} = "Hindaun\,\ Rajasthan";
$areanames{en}->{9174698} = "Hindaun\,\ Rajasthan";
$areanames{en}->{9174699} = "Hindaun\,\ Rajasthan";
$areanames{en}->{9174700} = "Bundi\,\ Rajasthan";
$areanames{en}->{9174701} = "Bundi\,\ Rajasthan";
$areanames{en}->{9174702} = "Bundi\,\ Rajasthan";
$areanames{en}->{9174704} = "Bundi\,\ Rajasthan";
$areanames{en}->{9174705} = "Bundi\,\ Rajasthan";
$areanames{en}->{9174706} = "Bundi\,\ Rajasthan";
$areanames{en}->{9174707} = "Bundi\,\ Rajasthan";
$areanames{en}->{9174708} = "Bundi\,\ Rajasthan";
$areanames{en}->{9174709} = "Bundi\,\ Rajasthan";
$areanames{en}->{9174711} = "Bundi\,\ Rajasthan";
$areanames{en}->{917472} = "Bundi\,\ Rajasthan";
$areanames{en}->{917473} = "Bundi\,\ Rajasthan";
$areanames{en}->{917474} = "Bundi\,\ Rajasthan";
$areanames{en}->{917475} = "Bundi\,\ Rajasthan";
$areanames{en}->{917476} = "Bundi\,\ Rajasthan";
$areanames{en}->{917477} = "Bundi\,\ Rajasthan";
$areanames{en}->{917478} = "Bundi\,\ Rajasthan";
$areanames{en}->{917479} = "Bundi\,\ Rajasthan";
$areanames{en}->{9174800} = "Goharganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174802} = "Goharganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174803} = "Goharganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174804} = "Goharganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174805} = "Goharganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174806} = "Goharganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174807} = "Goharganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174808} = "Goharganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174809} = "Goharganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174810} = "Gairatganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174812} = "Gairatganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174813} = "Gairatganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174814} = "Gairatganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174815} = "Gairatganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174816} = "Gairatganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174817} = "Gairatganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174818} = "Gairatganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174819} = "Gairatganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174820} = "Raisen\,\ Madhya\ Pradesh";
$areanames{en}->{9174822} = "Raisen\,\ Madhya\ Pradesh";
$areanames{en}->{9174823} = "Raisen\,\ Madhya\ Pradesh";
$areanames{en}->{9174824} = "Raisen\,\ Madhya\ Pradesh";
$areanames{en}->{9174825} = "Raisen\,\ Madhya\ Pradesh";
$areanames{en}->{9174826} = "Raisen\,\ Madhya\ Pradesh";
$areanames{en}->{9174827} = "Raisen\,\ Madhya\ Pradesh";
$areanames{en}->{9174828} = "Raisen\,\ Madhya\ Pradesh";
$areanames{en}->{9174829} = "Raisen\,\ Madhya\ Pradesh";
$areanames{en}->{9174840} = "Silwani\,\ Madhya\ Pradesh";
$areanames{en}->{9174842} = "Silwani\,\ Madhya\ Pradesh";
$areanames{en}->{9174843} = "Silwani\,\ Madhya\ Pradesh";
$areanames{en}->{9174844} = "Silwani\,\ Madhya\ Pradesh";
$areanames{en}->{9174845} = "Silwani\,\ Madhya\ Pradesh";
$areanames{en}->{9174846} = "Silwani\,\ Madhya\ Pradesh";
$areanames{en}->{9174847} = "Silwani\,\ Madhya\ Pradesh";
$areanames{en}->{9174848} = "Silwani\,\ Madhya\ Pradesh";
$areanames{en}->{9174849} = "Silwani\,\ Madhya\ Pradesh";
$areanames{en}->{9174850} = "Udaipura\,\ Madhya\ Pradesh";
$areanames{en}->{9174852} = "Udaipura\,\ Madhya\ Pradesh";
$areanames{en}->{9174853} = "Udaipura\,\ Madhya\ Pradesh";
$areanames{en}->{9174854} = "Udaipura\,\ Madhya\ Pradesh";
$areanames{en}->{9174855} = "Udaipura\,\ Madhya\ Pradesh";
$areanames{en}->{9174856} = "Udaipura\,\ Madhya\ Pradesh";
$areanames{en}->{9174857} = "Udaipura\,\ Madhya\ Pradesh";
$areanames{en}->{9174858} = "Udaipura\,\ Madhya\ Pradesh";
$areanames{en}->{9174859} = "Udaipura\,\ Madhya\ Pradesh";
$areanames{en}->{9174860} = "Bareli\,\ Madhya\ Pradesh";
$areanames{en}->{9174862} = "Bareli\,\ Madhya\ Pradesh";
$areanames{en}->{9174863} = "Bareli\,\ Madhya\ Pradesh";
$areanames{en}->{9174864} = "Bareli\,\ Madhya\ Pradesh";
$areanames{en}->{9174865} = "Bareli\,\ Madhya\ Pradesh";
$areanames{en}->{9174866} = "Bareli\,\ Madhya\ Pradesh";
$areanames{en}->{9174867} = "Bareli\,\ Madhya\ Pradesh";
$areanames{en}->{9174868} = "Bareli\,\ Madhya\ Pradesh";
$areanames{en}->{9174869} = "Bareli\,\ Madhya\ Pradesh";
$areanames{en}->{9174870} = "Begamganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174872} = "Begamganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174873} = "Begamganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174874} = "Begamganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174875} = "Begamganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174876} = "Begamganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174877} = "Begamganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174878} = "Begamganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174879} = "Begamganj\,\ Madhya\ Pradesh";
$areanames{en}->{9174900} = "Pohari\,\ Madhya\ Pradesh";
$areanames{en}->{9174902} = "Pohari\,\ Madhya\ Pradesh";
$areanames{en}->{9174903} = "Pohari\,\ Madhya\ Pradesh";
$areanames{en}->{9174904} = "Pohari\,\ Madhya\ Pradesh";
$areanames{en}->{9174905} = "Pohari\,\ Madhya\ Pradesh";
$areanames{en}->{9174906} = "Pohari\,\ Madhya\ Pradesh";
$areanames{en}->{9174907} = "Pohari\,\ Madhya\ Pradesh";
$areanames{en}->{9174908} = "Pohari\,\ Madhya\ Pradesh";
$areanames{en}->{9174909} = "Pohari\,\ Madhya\ Pradesh";
$areanames{en}->{9174910} = "Narwar\,\ Madhya\ Pradesh";
$areanames{en}->{9174912} = "Narwar\,\ Madhya\ Pradesh";
$areanames{en}->{9174913} = "Narwar\,\ Madhya\ Pradesh";
$areanames{en}->{9174914} = "Narwar\,\ Madhya\ Pradesh";
$areanames{en}->{9174915} = "Narwar\,\ Madhya\ Pradesh";
$areanames{en}->{9174916} = "Narwar\,\ Madhya\ Pradesh";
$areanames{en}->{9174917} = "Narwar\,\ Madhya\ Pradesh";
$areanames{en}->{9174918} = "Narwar\,\ Madhya\ Pradesh";
$areanames{en}->{9174919} = "Narwar\,\ Madhya\ Pradesh";
$areanames{en}->{9174920} = "Shivpuri\,\ Madhya\ Pradesh";
$areanames{en}->{9174922} = "Shivpuri\,\ Madhya\ Pradesh";
$areanames{en}->{9174923} = "Shivpuri\,\ Madhya\ Pradesh";
$areanames{en}->{9174924} = "Shivpuri\,\ Madhya\ Pradesh";
$areanames{en}->{9174925} = "Shivpuri\,\ Madhya\ Pradesh";
$areanames{en}->{9174926} = "Shivpuri\,\ Madhya\ Pradesh";
$areanames{en}->{9174927} = "Shivpuri\,\ Madhya\ Pradesh";
$areanames{en}->{9174928} = "Shivpuri\,\ Madhya\ Pradesh";
$areanames{en}->{9174929} = "Shivpuri\,\ Madhya\ Pradesh";
$areanames{en}->{9174930} = "Karera\,\ Madhya\ Pradesh";
$areanames{en}->{9174932} = "Karera\,\ Madhya\ Pradesh";
$areanames{en}->{9174933} = "Karera\,\ Madhya\ Pradesh";
$areanames{en}->{9174934} = "Karera\,\ Madhya\ Pradesh";
$areanames{en}->{9174935} = "Karera\,\ Madhya\ Pradesh";
$areanames{en}->{9174936} = "Karera\,\ Madhya\ Pradesh";
$areanames{en}->{9174937} = "Karera\,\ Madhya\ Pradesh";
$areanames{en}->{9174938} = "Karera\,\ Madhya\ Pradesh";
$areanames{en}->{9174939} = "Karera\,\ Madhya\ Pradesh";
$areanames{en}->{9174940} = "Kolaras\,\ Madhya\ Pradesh";
$areanames{en}->{9174942} = "Kolaras\,\ Madhya\ Pradesh";
$areanames{en}->{9174943} = "Kolaras\,\ Madhya\ Pradesh";
$areanames{en}->{9174944} = "Kolaras\,\ Madhya\ Pradesh";
$areanames{en}->{9174945} = "Kolaras\,\ Madhya\ Pradesh";
$areanames{en}->{9174946} = "Kolaras\,\ Madhya\ Pradesh";
$areanames{en}->{9174947} = "Kolaras\,\ Madhya\ Pradesh";
$areanames{en}->{9174948} = "Kolaras\,\ Madhya\ Pradesh";
$areanames{en}->{9174949} = "Kolaras\,\ Madhya\ Pradesh";
$areanames{en}->{9174950} = "Badarwas\,\ Madhya\ Pradesh";
$areanames{en}->{9174952} = "Badarwas\,\ Madhya\ Pradesh";
$areanames{en}->{9174953} = "Badarwas\,\ Madhya\ Pradesh";
$areanames{en}->{9174954} = "Badarwas\,\ Madhya\ Pradesh";
$areanames{en}->{9174955} = "Badarwas\,\ Madhya\ Pradesh";
$areanames{en}->{9174956} = "Badarwas\,\ Madhya\ Pradesh";
$areanames{en}->{9174957} = "Badarwas\,\ Madhya\ Pradesh";
$areanames{en}->{9174958} = "Badarwas\,\ Madhya\ Pradesh";
$areanames{en}->{9174959} = "Badarwas\,\ Madhya\ Pradesh";
$areanames{en}->{9174960} = "Pichhore\,\ Madhya\ Pradesh";
$areanames{en}->{9174962} = "Pichhore\,\ Madhya\ Pradesh";
$areanames{en}->{9174963} = "Pichhore\,\ Madhya\ Pradesh";
$areanames{en}->{9174964} = "Pichhore\,\ Madhya\ Pradesh";
$areanames{en}->{9174965} = "Pichhore\,\ Madhya\ Pradesh";
$areanames{en}->{9174966} = "Pichhore\,\ Madhya\ Pradesh";
$areanames{en}->{9174967} = "Pichhore\,\ Madhya\ Pradesh";
$areanames{en}->{9174968} = "Pichhore\,\ Madhya\ Pradesh";
$areanames{en}->{9174969} = "Pichhore\,\ Madhya\ Pradesh";
$areanames{en}->{9174970} = "Khaniadhana\,\ Madhya\ Pradesh";
$areanames{en}->{9174972} = "Khaniadhana\,\ Madhya\ Pradesh";
$areanames{en}->{9174973} = "Khaniadhana\,\ Madhya\ Pradesh";
$areanames{en}->{9174974} = "Khaniadhana\,\ Madhya\ Pradesh";
$areanames{en}->{9174975} = "Khaniadhana\,\ Madhya\ Pradesh";
$areanames{en}->{9174976} = "Khaniadhana\,\ Madhya\ Pradesh";
$areanames{en}->{9174977} = "Khaniadhana\,\ Madhya\ Pradesh";
$areanames{en}->{9174978} = "Khaniadhana\,\ Madhya\ Pradesh";
$areanames{en}->{9174979} = "Khaniadhana\,\ Madhya\ Pradesh";
$areanames{en}->{917510} = "Gwalior\,\ Madhya\ Pradesh";
$areanames{en}->{9175111} = "Gwalior\,\ Madhya\ Pradesh";
$areanames{en}->{917512} = "Gwalior\,\ Madhya\ Pradesh";
$areanames{en}->{917513} = "Gwalior\,\ Madhya\ Pradesh";
$areanames{en}->{917514} = "Gwalior\,\ Madhya\ Pradesh";
$areanames{en}->{917515} = "Gwalior\,\ Madhya\ Pradesh";
$areanames{en}->{917516} = "Gwalior\,\ Madhya\ Pradesh";
$areanames{en}->{917517} = "Gwalior\,\ Madhya\ Pradesh";
$areanames{en}->{917518} = "Gwalior\,\ Madhya\ Pradesh";
$areanames{en}->{917519} = "Gwalior\,\ Madhya\ Pradesh";
$areanames{en}->{9175210} = "Seondha\,\ Madhya\ Pradesh";
$areanames{en}->{9175212} = "Seondha\,\ Madhya\ Pradesh";
$areanames{en}->{9175213} = "Seondha\,\ Madhya\ Pradesh";
$areanames{en}->{9175214} = "Seondha\,\ Madhya\ Pradesh";
$areanames{en}->{9175215} = "Seondha\,\ Madhya\ Pradesh";
$areanames{en}->{9175216} = "Seondha\,\ Madhya\ Pradesh";
$areanames{en}->{9175217} = "Seondha\,\ Madhya\ Pradesh";
$areanames{en}->{9175218} = "Seondha\,\ Madhya\ Pradesh";
$areanames{en}->{9175219} = "Seondha\,\ Madhya\ Pradesh";
$areanames{en}->{9175220} = "Datia\,\ Madhya\ Pradesh";
$areanames{en}->{9175222} = "Datia\,\ Madhya\ Pradesh";
$areanames{en}->{9175223} = "Datia\,\ Madhya\ Pradesh";
$areanames{en}->{9175224} = "Datia\,\ Madhya\ Pradesh";
$areanames{en}->{9175225} = "Datia\,\ Madhya\ Pradesh";
$areanames{en}->{9175226} = "Datia\,\ Madhya\ Pradesh";
$areanames{en}->{9175227} = "Datia\,\ Madhya\ Pradesh";
$areanames{en}->{9175228} = "Datia\,\ Madhya\ Pradesh";
$areanames{en}->{9175229} = "Datia\,\ Madhya\ Pradesh";
$areanames{en}->{917523} = "Bhander\,\ Madhya\ Pradesh";
$areanames{en}->{917524} = "Dabra\,\ Madhya\ Pradesh";
$areanames{en}->{917525} = "Bhitarwar\,\ Madhya\ Pradesh";
$areanames{en}->{9175260} = "Ghatigaon\,\ Madhya\ Pradesh";
$areanames{en}->{9175262} = "Ghatigaon\,\ Madhya\ Pradesh";
$areanames{en}->{9175263} = "Ghatigaon\,\ Madhya\ Pradesh";
$areanames{en}->{9175264} = "Ghatigaon\,\ Madhya\ Pradesh";
$areanames{en}->{9175265} = "Ghatigaon\,\ Madhya\ Pradesh";
$areanames{en}->{9175266} = "Ghatigaon\,\ Madhya\ Pradesh";
$areanames{en}->{9175267} = "Ghatigaon\,\ Madhya\ Pradesh";
$areanames{en}->{9175268} = "Ghatigaon\,\ Madhya\ Pradesh";
$areanames{en}->{9175269} = "Ghatigaon\,\ Madhya\ Pradesh";
$areanames{en}->{917527} = "Mehgaon\,\ Madhya\ Pradesh";
$areanames{en}->{917528} = "Bijaypur\,\ Madhya\ Pradesh";
$areanames{en}->{9175290} = "Laher\,\ Madhya\ Pradesh";
$areanames{en}->{9175292} = "Laher\,\ Madhya\ Pradesh";
$areanames{en}->{9175293} = "Laher\,\ Madhya\ Pradesh";
$areanames{en}->{9175294} = "Laher\,\ Madhya\ Pradesh";
$areanames{en}->{9175295} = "Laher\,\ Madhya\ Pradesh";
$areanames{en}->{9175296} = "Laher\,\ Madhya\ Pradesh";
$areanames{en}->{9175297} = "Laher\,\ Madhya\ Pradesh";
$areanames{en}->{9175298} = "Laher\,\ Madhya\ Pradesh";
$areanames{en}->{9175299} = "Laher\,\ Madhya\ Pradesh";
$areanames{en}->{917530} = "Sheopurkalan\,\ Madhya\ Pradesh";
$areanames{en}->{917531} = "Baroda\,\ Madhya\ Pradesh";
$areanames{en}->{917532} = "Morena\,\ Madhya\ Pradesh";
$areanames{en}->{917533} = "Karhal\,\ Madhya\ Pradesh";
$areanames{en}->{917534} = "Bhind\,\ Madhya\ Pradesh";
$areanames{en}->{917535} = "Raghunathpur\,\ Madhya\ Pradesh";
$areanames{en}->{917536} = "Sabalgarh\,\ Madhya\ Pradesh";
$areanames{en}->{917537} = "Jora\,\ Madhya\ Pradesh";
$areanames{en}->{9175381} = "Ambah\,\ Madhya\ Pradesh";
$areanames{en}->{9175382} = "Ambah\,\ Madhya\ Pradesh";
$areanames{en}->{9175383} = "Ambah\,\ Madhya\ Pradesh";
$areanames{en}->{9175384} = "Ambah\,\ Madhya\ Pradesh";
$areanames{en}->{9175385} = "Ambah\,\ Madhya\ Pradesh";
$areanames{en}->{9175386} = "Ambah\,\ Madhya\ Pradesh";
$areanames{en}->{9175387} = "Ambah\,\ Madhya\ Pradesh";
$areanames{en}->{9175388} = "Ambah\,\ Madhya\ Pradesh";
$areanames{en}->{917539} = "Gohad\,\ Madhya\ Pradesh";
$areanames{en}->{9175390} = "Ambah\,\ Madhya\ Pradesh";
$areanames{en}->{9175398} = "Ambah\,\ Madhya\ Pradesh";
$areanames{en}->{917540} = "Bamori\,\ Madhya\ Pradesh";
$areanames{en}->{917541} = "Isagarh\,\ Madhya\ Pradesh";
$areanames{en}->{917542} = "Guna\,\ Madhya\ Pradesh";
$areanames{en}->{917543} = "Ashoknagar\,\ Madhya\ Pradesh";
$areanames{en}->{917544} = "Raghogarh\,\ Madhya\ Pradesh";
$areanames{en}->{917545} = "Arone\,\ Madhya\ Pradesh";
$areanames{en}->{917546} = "Chachaura\,\ Madhya\ Pradesh";
$areanames{en}->{917547} = "Chanderi\,\ Madhya\ Pradesh";
$areanames{en}->{917548} = "Mungaoli\,\ Madhya\ Pradesh";
$areanames{en}->{91755} = "Bhopal\,\ Madhya\ Pradesh";
$areanames{en}->{917560} = "Ashta\,\ Madhya\ Pradesh";
$areanames{en}->{917561} = "Ichhawar\,\ Madhya\ Pradesh";
$areanames{en}->{917562} = "Sehore\,\ Madhya\ Pradesh";
$areanames{en}->{917563} = "Nasrullaganj\,\ Madhya\ Pradesh";
$areanames{en}->{917564} = "Budhni\,\ Madhya\ Pradesh";
$areanames{en}->{917565} = "Berasia\,\ Madhya\ Pradesh";
$areanames{en}->{917570} = "Seonimalwa\,\ Madhya\ Pradesh";
$areanames{en}->{917571} = "Khirkiya\,\ Madhya\ Pradesh";
$areanames{en}->{917572} = "Itarsi\,\ Madhya\ Pradesh";
$areanames{en}->{917573} = "Timarani\,\ Madhya\ Pradesh";
$areanames{en}->{917574} = "Hoshangabad\,\ Madhya\ Pradesh";
$areanames{en}->{917575} = "Sohagpur\,\ Madhya\ Pradesh";
$areanames{en}->{917576} = "Piparia\,\ Madhya\ Pradesh";
$areanames{en}->{917577} = "Harda\,\ Madhya\ Pradesh";
$areanames{en}->{917578} = "Pachmarhi\,\ Madhya\ Pradesh";
$areanames{en}->{917580} = "Bina\,\ Madhya\ Pradesh";
$areanames{en}->{917581} = "Khurai\,\ Madhya\ Pradesh";
$areanames{en}->{917582} = "Sagar\,\ Madhya\ Pradesh";
$areanames{en}->{917583} = "Banda\,\ Madhya\ Pradesh";
$areanames{en}->{917584} = "Rahatgarh\,\ Madhya\ Pradesh";
$areanames{en}->{917585} = "Rehli\,\ Madhya\ Pradesh";
$areanames{en}->{917586} = "Deori\,\ Madhya\ Pradesh";
$areanames{en}->{9175900} = "Lateri\,\ Madhya\ Pradesh";
$areanames{en}->{9175902} = "Lateri\,\ Madhya\ Pradesh";
$areanames{en}->{9175903} = "Lateri\,\ Madhya\ Pradesh";
$areanames{en}->{9175904} = "Lateri\,\ Madhya\ Pradesh";
$areanames{en}->{9175905} = "Lateri\,\ Madhya\ Pradesh";
$areanames{en}->{9175906} = "Lateri\,\ Madhya\ Pradesh";
$areanames{en}->{9175907} = "Lateri\,\ Madhya\ Pradesh";
$areanames{en}->{9175908} = "Lateri\,\ Madhya\ Pradesh";
$areanames{en}->{9175909} = "Lateri\,\ Madhya\ Pradesh";
$areanames{en}->{9175910} = "Sironj\,\ Madhya\ Pradesh";
$areanames{en}->{9175912} = "Sironj\,\ Madhya\ Pradesh";
$areanames{en}->{9175913} = "Sironj\,\ Madhya\ Pradesh";
$areanames{en}->{9175914} = "Sironj\,\ Madhya\ Pradesh";
$areanames{en}->{9175915} = "Sironj\,\ Madhya\ Pradesh";
$areanames{en}->{9175916} = "Sironj\,\ Madhya\ Pradesh";
$areanames{en}->{9175917} = "Sironj\,\ Madhya\ Pradesh";
$areanames{en}->{9175918} = "Sironj\,\ Madhya\ Pradesh";
$areanames{en}->{9175919} = "Sironj\,\ Madhya\ Pradesh";
$areanames{en}->{9175920} = "Vidisha\,\ Madhya\ Pradesh";
$areanames{en}->{9175922} = "Vidisha\,\ Madhya\ Pradesh";
$areanames{en}->{9175923} = "Vidisha\,\ Madhya\ Pradesh";
$areanames{en}->{9175924} = "Vidisha\,\ Madhya\ Pradesh";
$areanames{en}->{9175925} = "Vidisha\,\ Madhya\ Pradesh";
$areanames{en}->{9175926} = "Vidisha\,\ Madhya\ Pradesh";
$areanames{en}->{9175927} = "Vidisha\,\ Madhya\ Pradesh";
$areanames{en}->{9175928} = "Vidisha\,\ Madhya\ Pradesh";
$areanames{en}->{9175929} = "Vidisha\,\ Madhya\ Pradesh";
$areanames{en}->{9175930} = "Kurwai\,\ Madhya\ Pradesh";
$areanames{en}->{9175932} = "Kurwai\,\ Madhya\ Pradesh";
$areanames{en}->{9175933} = "Kurwai\,\ Madhya\ Pradesh";
$areanames{en}->{9175934} = "Kurwai\,\ Madhya\ Pradesh";
$areanames{en}->{9175935} = "Kurwai\,\ Madhya\ Pradesh";
$areanames{en}->{9175936} = "Kurwai\,\ Madhya\ Pradesh";
$areanames{en}->{9175937} = "Kurwai\,\ Madhya\ Pradesh";
$areanames{en}->{9175938} = "Kurwai\,\ Madhya\ Pradesh";
$areanames{en}->{9175939} = "Kurwai\,\ Madhya\ Pradesh";
$areanames{en}->{9175940} = "Ganjbasoda\,\ Madhya\ Pradesh";
$areanames{en}->{9175942} = "Ganjbasoda\,\ Madhya\ Pradesh";
$areanames{en}->{9175943} = "Ganjbasoda\,\ Madhya\ Pradesh";
$areanames{en}->{9175944} = "Ganjbasoda\,\ Madhya\ Pradesh";
$areanames{en}->{9175945} = "Ganjbasoda\,\ Madhya\ Pradesh";
$areanames{en}->{9175946} = "Ganjbasoda\,\ Madhya\ Pradesh";
$areanames{en}->{9175947} = "Ganjbasoda\,\ Madhya\ Pradesh";
$areanames{en}->{9175948} = "Ganjbasoda\,\ Madhya\ Pradesh";
$areanames{en}->{9175949} = "Ganjbasoda\,\ Madhya\ Pradesh";
$areanames{en}->{9175950} = "Nateran\,\ Madhya\ Pradesh";
$areanames{en}->{9175952} = "Nateran\,\ Madhya\ Pradesh";
$areanames{en}->{9175953} = "Nateran\,\ Madhya\ Pradesh";
$areanames{en}->{9175954} = "Nateran\,\ Madhya\ Pradesh";
$areanames{en}->{9175955} = "Nateran\,\ Madhya\ Pradesh";
$areanames{en}->{9175956} = "Nateran\,\ Madhya\ Pradesh";
$areanames{en}->{9175957} = "Nateran\,\ Madhya\ Pradesh";
$areanames{en}->{9175958} = "Nateran\,\ Madhya\ Pradesh";
$areanames{en}->{9175959} = "Nateran\,\ Madhya\ Pradesh";
$areanames{en}->{9175960} = "Gyraspur\,\ Madhya\ Pradesh";
$areanames{en}->{9175962} = "Gyraspur\,\ Madhya\ Pradesh";
$areanames{en}->{9175963} = "Gyraspur\,\ Madhya\ Pradesh";
$areanames{en}->{9175964} = "Gyraspur\,\ Madhya\ Pradesh";
$areanames{en}->{9175965} = "Gyraspur\,\ Madhya\ Pradesh";
$areanames{en}->{9175966} = "Gyraspur\,\ Madhya\ Pradesh";
$areanames{en}->{9175967} = "Gyraspur\,\ Madhya\ Pradesh";
$areanames{en}->{9175968} = "Gyraspur\,\ Madhya\ Pradesh";
$areanames{en}->{9175969} = "Gyraspur\,\ Madhya\ Pradesh";
$areanames{en}->{917601} = "Patharia\,\ Madhya\ Pradesh";
$areanames{en}->{917603} = "Tendukheda\,\ Madhya\ Pradesh";
$areanames{en}->{917604} = "Hatta\,\ Madhya\ Pradesh";
$areanames{en}->{917605} = "Patera\,\ Madhya\ Pradesh";
$areanames{en}->{917606} = "Jabera\,\ Madhya\ Pradesh";
$areanames{en}->{917608} = "Bijawar\,\ Madhya\ Pradesh";
$areanames{en}->{917609} = "Buxwaha\,\ Madhya\ Pradesh";
$areanames{en}->{91761} = "Jabalpur\,\ Madhya\ Pradesh";
$areanames{en}->{917621} = "Patan\,\ Madhya\ Pradesh";
$areanames{en}->{917622} = "Katni\,\ Madhya\ Pradesh";
$areanames{en}->{917623} = "Kundam\,\ Madhya\ Pradesh";
$areanames{en}->{917624} = "Sihora\,\ Madhya\ Pradesh";
$areanames{en}->{9176240} = "Sihora\,\ Madhya\ Pradesh";
$areanames{en}->{9176241} = "Sihora\,\ Madhya\ Pradesh";
$areanames{en}->{9176248} = "Sihora\,\ Madhya\ Pradesh";
$areanames{en}->{9176249} = "Sihora\,\ Madhya\ Pradesh";
$areanames{en}->{9176250} = "Umariapan\,\ Madhya\ Pradesh";
$areanames{en}->{9176252} = "Umariapan\,\ Madhya\ Pradesh";
$areanames{en}->{9176253} = "Umariapan\,\ Madhya\ Pradesh";
$areanames{en}->{9176254} = "Umariapan\,\ Madhya\ Pradesh";
$areanames{en}->{9176255} = "Umariapan\,\ Madhya\ Pradesh";
$areanames{en}->{9176256} = "Umariapan\,\ Madhya\ Pradesh";
$areanames{en}->{9176257} = "Umariapan\,\ Madhya\ Pradesh";
$areanames{en}->{9176258} = "Umariapan\,\ Madhya\ Pradesh";
$areanames{en}->{9176259} = "Umariapan\,\ Madhya\ Pradesh";
$areanames{en}->{9176260} = "Vijayraghogarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176262} = "Vijayraghogarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176263} = "Vijayraghogarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176264} = "Vijayraghogarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176265} = "Vijayraghogarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176266} = "Vijayraghogarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176267} = "Vijayraghogarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176268} = "Vijayraghogarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176269} = "Vijayraghogarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176270} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176272} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176273} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176274} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176275} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176276} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176277} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176278} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176279} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176280} = "Karpa\,\ Madhya\ Pradesh";
$areanames{en}->{9176282} = "Karpa\,\ Madhya\ Pradesh";
$areanames{en}->{9176283} = "Karpa\,\ Madhya\ Pradesh";
$areanames{en}->{9176284} = "Karpa\,\ Madhya\ Pradesh";
$areanames{en}->{9176285} = "Karpa\,\ Madhya\ Pradesh";
$areanames{en}->{9176286} = "Karpa\,\ Madhya\ Pradesh";
$areanames{en}->{9176287} = "Karpa\,\ Madhya\ Pradesh";
$areanames{en}->{9176288} = "Karpa\,\ Madhya\ Pradesh";
$areanames{en}->{9176289} = "Karpa\,\ Madhya\ Pradesh";
$areanames{en}->{9176290} = "Pushprajgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176292} = "Pushprajgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176293} = "Pushprajgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176294} = "Pushprajgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176295} = "Pushprajgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176296} = "Pushprajgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176297} = "Pushprajgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176298} = "Pushprajgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176299} = "Pushprajgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176300} = "Katangi\,\ Madhya\ Pradesh";
$areanames{en}->{9176302} = "Katangi\,\ Madhya\ Pradesh";
$areanames{en}->{9176303} = "Katangi\,\ Madhya\ Pradesh";
$areanames{en}->{9176304} = "Katangi\,\ Madhya\ Pradesh";
$areanames{en}->{9176305} = "Katangi\,\ Madhya\ Pradesh";
$areanames{en}->{9176306} = "Katangi\,\ Madhya\ Pradesh";
$areanames{en}->{9176307} = "Katangi\,\ Madhya\ Pradesh";
$areanames{en}->{9176308} = "Katangi\,\ Madhya\ Pradesh";
$areanames{en}->{9176309} = "Katangi\,\ Madhya\ Pradesh";
$areanames{en}->{9176320} = "Balaghat\,\ Madhya\ Pradesh";
$areanames{en}->{9176322} = "Balaghat\,\ Madhya\ Pradesh";
$areanames{en}->{9176323} = "Balaghat\,\ Madhya\ Pradesh";
$areanames{en}->{9176324} = "Balaghat\,\ Madhya\ Pradesh";
$areanames{en}->{9176325} = "Balaghat\,\ Madhya\ Pradesh";
$areanames{en}->{9176326} = "Balaghat\,\ Madhya\ Pradesh";
$areanames{en}->{9176327} = "Balaghat\,\ Madhya\ Pradesh";
$areanames{en}->{9176328} = "Balaghat\,\ Madhya\ Pradesh";
$areanames{en}->{9176329} = "Balaghat\,\ Madhya\ Pradesh";
$areanames{en}->{9176330} = "Waraseoni\,\ Madhya\ Pradesh";
$areanames{en}->{9176332} = "Waraseoni\,\ Madhya\ Pradesh";
$areanames{en}->{9176333} = "Waraseoni\,\ Madhya\ Pradesh";
$areanames{en}->{9176334} = "Waraseoni\,\ Madhya\ Pradesh";
$areanames{en}->{9176335} = "Waraseoni\,\ Madhya\ Pradesh";
$areanames{en}->{9176336} = "Waraseoni\,\ Madhya\ Pradesh";
$areanames{en}->{9176337} = "Waraseoni\,\ Madhya\ Pradesh";
$areanames{en}->{9176338} = "Waraseoni\,\ Madhya\ Pradesh";
$areanames{en}->{9176339} = "Waraseoni\,\ Madhya\ Pradesh";
$areanames{en}->{9176340} = "Lamta\,\ Madhya\ Pradesh";
$areanames{en}->{9176342} = "Lamta\,\ Madhya\ Pradesh";
$areanames{en}->{9176343} = "Lamta\,\ Madhya\ Pradesh";
$areanames{en}->{9176344} = "Lamta\,\ Madhya\ Pradesh";
$areanames{en}->{9176345} = "Lamta\,\ Madhya\ Pradesh";
$areanames{en}->{9176346} = "Lamta\,\ Madhya\ Pradesh";
$areanames{en}->{9176347} = "Lamta\,\ Madhya\ Pradesh";
$areanames{en}->{9176348} = "Lamta\,\ Madhya\ Pradesh";
$areanames{en}->{9176349} = "Lamta\,\ Madhya\ Pradesh";
$areanames{en}->{9176350} = "Lanji\,\ Madhya\ Pradesh";
$areanames{en}->{9176352} = "Lanji\,\ Madhya\ Pradesh";
$areanames{en}->{9176353} = "Lanji\,\ Madhya\ Pradesh";
$areanames{en}->{9176354} = "Lanji\,\ Madhya\ Pradesh";
$areanames{en}->{9176355} = "Lanji\,\ Madhya\ Pradesh";
$areanames{en}->{9176356} = "Lanji\,\ Madhya\ Pradesh";
$areanames{en}->{9176357} = "Lanji\,\ Madhya\ Pradesh";
$areanames{en}->{9176358} = "Lanji\,\ Madhya\ Pradesh";
$areanames{en}->{9176359} = "Lanji\,\ Madhya\ Pradesh";
$areanames{en}->{9176360} = "Baihar\,\ Madhya\ Pradesh";
$areanames{en}->{9176362} = "Baihar\,\ Madhya\ Pradesh";
$areanames{en}->{9176363} = "Baihar\,\ Madhya\ Pradesh";
$areanames{en}->{9176364} = "Baihar\,\ Madhya\ Pradesh";
$areanames{en}->{9176365} = "Baihar\,\ Madhya\ Pradesh";
$areanames{en}->{9176366} = "Baihar\,\ Madhya\ Pradesh";
$areanames{en}->{9176367} = "Baihar\,\ Madhya\ Pradesh";
$areanames{en}->{9176368} = "Baihar\,\ Madhya\ Pradesh";
$areanames{en}->{9176369} = "Baihar\,\ Madhya\ Pradesh";
$areanames{en}->{9176370} = "Birsa\,\ Madhya\ Pradesh";
$areanames{en}->{9176372} = "Birsa\,\ Madhya\ Pradesh";
$areanames{en}->{9176373} = "Birsa\,\ Madhya\ Pradesh";
$areanames{en}->{9176374} = "Birsa\,\ Madhya\ Pradesh";
$areanames{en}->{9176375} = "Birsa\,\ Madhya\ Pradesh";
$areanames{en}->{9176376} = "Birsa\,\ Madhya\ Pradesh";
$areanames{en}->{9176377} = "Birsa\,\ Madhya\ Pradesh";
$areanames{en}->{9176378} = "Birsa\,\ Madhya\ Pradesh";
$areanames{en}->{9176379} = "Birsa\,\ Madhya\ Pradesh";
$areanames{en}->{9176380} = "Damoh\,\ Madhya\ Pradesh";
$areanames{en}->{9176382} = "Damoh\,\ Madhya\ Pradesh";
$areanames{en}->{9176383} = "Damoh\,\ Madhya\ Pradesh";
$areanames{en}->{9176384} = "Damoh\,\ Madhya\ Pradesh";
$areanames{en}->{9176385} = "Damoh\,\ Madhya\ Pradesh";
$areanames{en}->{9176386} = "Damoh\,\ Madhya\ Pradesh";
$areanames{en}->{9176387} = "Damoh\,\ Madhya\ Pradesh";
$areanames{en}->{9176388} = "Damoh\,\ Madhya\ Pradesh";
$areanames{en}->{9176389} = "Damoh\,\ Madhya\ Pradesh";
$areanames{en}->{9176400} = "Shahpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176402} = "Shahpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176403} = "Shahpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176404} = "Shahpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176405} = "Shahpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176406} = "Shahpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176407} = "Shahpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176408} = "Shahpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176409} = "Shahpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176410} = "Niwas\,\ Madhya\ Pradesh";
$areanames{en}->{9176412} = "Niwas\,\ Madhya\ Pradesh";
$areanames{en}->{9176413} = "Niwas\,\ Madhya\ Pradesh";
$areanames{en}->{9176414} = "Niwas\,\ Madhya\ Pradesh";
$areanames{en}->{9176415} = "Niwas\,\ Madhya\ Pradesh";
$areanames{en}->{9176416} = "Niwas\,\ Madhya\ Pradesh";
$areanames{en}->{9176417} = "Niwas\,\ Madhya\ Pradesh";
$areanames{en}->{9176418} = "Niwas\,\ Madhya\ Pradesh";
$areanames{en}->{9176419} = "Niwas\,\ Madhya\ Pradesh";
$areanames{en}->{9176420} = "Mandla\,\ Madhya\ Pradesh";
$areanames{en}->{9176422} = "Mandla\,\ Madhya\ Pradesh";
$areanames{en}->{9176423} = "Mandla\,\ Madhya\ Pradesh";
$areanames{en}->{9176424} = "Mandla\,\ Madhya\ Pradesh";
$areanames{en}->{9176425} = "Mandla\,\ Madhya\ Pradesh";
$areanames{en}->{9176426} = "Mandla\,\ Madhya\ Pradesh";
$areanames{en}->{9176427} = "Mandla\,\ Madhya\ Pradesh";
$areanames{en}->{9176428} = "Mandla\,\ Madhya\ Pradesh";
$areanames{en}->{9176429} = "Mandla\,\ Madhya\ Pradesh";
$areanames{en}->{9176430} = "Bijadandi\,\ Madhya\ Pradesh";
$areanames{en}->{9176432} = "Bijadandi\,\ Madhya\ Pradesh";
$areanames{en}->{9176433} = "Bijadandi\,\ Madhya\ Pradesh";
$areanames{en}->{9176434} = "Bijadandi\,\ Madhya\ Pradesh";
$areanames{en}->{9176435} = "Bijadandi\,\ Madhya\ Pradesh";
$areanames{en}->{9176436} = "Bijadandi\,\ Madhya\ Pradesh";
$areanames{en}->{9176437} = "Bijadandi\,\ Madhya\ Pradesh";
$areanames{en}->{9176438} = "Bijadandi\,\ Madhya\ Pradesh";
$areanames{en}->{9176439} = "Bijadandi\,\ Madhya\ Pradesh";
$areanames{en}->{9176440} = "Dindori\,\ Madhya\ Pradesh";
$areanames{en}->{9176442} = "Dindori\,\ Madhya\ Pradesh";
$areanames{en}->{9176443} = "Dindori\,\ Madhya\ Pradesh";
$areanames{en}->{9176444} = "Dindori\,\ Madhya\ Pradesh";
$areanames{en}->{9176445} = "Dindori\,\ Madhya\ Pradesh";
$areanames{en}->{9176446} = "Dindori\,\ Madhya\ Pradesh";
$areanames{en}->{9176447} = "Dindori\,\ Madhya\ Pradesh";
$areanames{en}->{9176448} = "Dindori\,\ Madhya\ Pradesh";
$areanames{en}->{9176449} = "Dindori\,\ Madhya\ Pradesh";
$areanames{en}->{9176450} = "Karanjia\,\ Madhya\ Pradesh";
$areanames{en}->{9176452} = "Karanjia\,\ Madhya\ Pradesh";
$areanames{en}->{9176453} = "Karanjia\,\ Madhya\ Pradesh";
$areanames{en}->{9176454} = "Karanjia\,\ Madhya\ Pradesh";
$areanames{en}->{9176455} = "Karanjia\,\ Madhya\ Pradesh";
$areanames{en}->{9176456} = "Karanjia\,\ Madhya\ Pradesh";
$areanames{en}->{9176457} = "Karanjia\,\ Madhya\ Pradesh";
$areanames{en}->{9176458} = "Karanjia\,\ Madhya\ Pradesh";
$areanames{en}->{9176459} = "Karanjia\,\ Madhya\ Pradesh";
$areanames{en}->{9176460} = "Nainpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176462} = "Nainpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176463} = "Nainpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176464} = "Nainpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176465} = "Nainpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176466} = "Nainpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176467} = "Nainpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176468} = "Nainpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176469} = "Nainpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176470} = "Ghughari\,\ Madhya\ Pradesh";
$areanames{en}->{9176472} = "Ghughari\,\ Madhya\ Pradesh";
$areanames{en}->{9176473} = "Ghughari\,\ Madhya\ Pradesh";
$areanames{en}->{9176474} = "Ghughari\,\ Madhya\ Pradesh";
$areanames{en}->{9176475} = "Ghughari\,\ Madhya\ Pradesh";
$areanames{en}->{9176476} = "Ghughari\,\ Madhya\ Pradesh";
$areanames{en}->{9176477} = "Ghughari\,\ Madhya\ Pradesh";
$areanames{en}->{9176478} = "Ghughari\,\ Madhya\ Pradesh";
$areanames{en}->{9176479} = "Ghughari\,\ Madhya\ Pradesh";
$areanames{en}->{9176480} = "Mawai\,\ Madhya\ Pradesh";
$areanames{en}->{9176482} = "Mawai\,\ Madhya\ Pradesh";
$areanames{en}->{9176483} = "Mawai\,\ Madhya\ Pradesh";
$areanames{en}->{9176484} = "Mawai\,\ Madhya\ Pradesh";
$areanames{en}->{9176485} = "Mawai\,\ Madhya\ Pradesh";
$areanames{en}->{9176486} = "Mawai\,\ Madhya\ Pradesh";
$areanames{en}->{9176487} = "Mawai\,\ Madhya\ Pradesh";
$areanames{en}->{9176488} = "Mawai\,\ Madhya\ Pradesh";
$areanames{en}->{9176489} = "Mawai\,\ Madhya\ Pradesh";
$areanames{en}->{9176490} = "Kakaiya\,\ Madhya\ Pradesh";
$areanames{en}->{9176492} = "Kakaiya\,\ Madhya\ Pradesh";
$areanames{en}->{9176493} = "Kakaiya\,\ Madhya\ Pradesh";
$areanames{en}->{9176494} = "Kakaiya\,\ Madhya\ Pradesh";
$areanames{en}->{9176495} = "Kakaiya\,\ Madhya\ Pradesh";
$areanames{en}->{9176496} = "Kakaiya\,\ Madhya\ Pradesh";
$areanames{en}->{9176497} = "Kakaiya\,\ Madhya\ Pradesh";
$areanames{en}->{9176498} = "Kakaiya\,\ Madhya\ Pradesh";
$areanames{en}->{9176499} = "Kakaiya\,\ Madhya\ Pradesh";
$areanames{en}->{9176500} = "Beohari\,\ Madhya\ Pradesh";
$areanames{en}->{9176502} = "Beohari\,\ Madhya\ Pradesh";
$areanames{en}->{9176503} = "Beohari\,\ Madhya\ Pradesh";
$areanames{en}->{9176504} = "Beohari\,\ Madhya\ Pradesh";
$areanames{en}->{9176505} = "Beohari\,\ Madhya\ Pradesh";
$areanames{en}->{9176506} = "Beohari\,\ Madhya\ Pradesh";
$areanames{en}->{9176507} = "Beohari\,\ Madhya\ Pradesh";
$areanames{en}->{9176508} = "Beohari\,\ Madhya\ Pradesh";
$areanames{en}->{9176509} = "Beohari\,\ Madhya\ Pradesh";
$areanames{en}->{9176510} = "Jaisinghnagar\,\ Madhya\ Pradesh";
$areanames{en}->{9176512} = "Jaisinghnagar\,\ Madhya\ Pradesh";
$areanames{en}->{9176513} = "Jaisinghnagar\,\ Madhya\ Pradesh";
$areanames{en}->{9176514} = "Jaisinghnagar\,\ Madhya\ Pradesh";
$areanames{en}->{9176515} = "Jaisinghnagar\,\ Madhya\ Pradesh";
$areanames{en}->{9176516} = "Jaisinghnagar\,\ Madhya\ Pradesh";
$areanames{en}->{9176517} = "Jaisinghnagar\,\ Madhya\ Pradesh";
$areanames{en}->{9176520} = "Shahdol\,\ Madhya\ Pradesh";
$areanames{en}->{9176522} = "Shahdol\,\ Madhya\ Pradesh";
$areanames{en}->{9176523} = "Shahdol\,\ Madhya\ Pradesh";
$areanames{en}->{9176524} = "Shahdol\,\ Madhya\ Pradesh";
$areanames{en}->{9176525} = "Shahdol\,\ Madhya\ Pradesh";
$areanames{en}->{9176526} = "Shahdol\,\ Madhya\ Pradesh";
$areanames{en}->{9176527} = "Shahdol\,\ Madhya\ Pradesh";
$areanames{en}->{9176528} = "Shahdol\,\ Madhya\ Pradesh";
$areanames{en}->{9176529} = "Shahdol\,\ Madhya\ Pradesh";
$areanames{en}->{9176530} = "Bandhavgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176532} = "Bandhavgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176533} = "Bandhavgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176534} = "Bandhavgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176535} = "Bandhavgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176536} = "Bandhavgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176537} = "Bandhavgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176538} = "Bandhavgarh\,\ Madhya\ Pradesh";
$areanames{en}->{9176539} = "Bandhavgarh\,\ Madhya\ Pradesh";
$areanames{en}->{917655} = "Birsinghpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176560} = "Kannodi\,\ Madhya\ Pradesh";
$areanames{en}->{9176562} = "Kannodi\,\ Madhya\ Pradesh";
$areanames{en}->{9176563} = "Kannodi\,\ Madhya\ Pradesh";
$areanames{en}->{9176564} = "Kannodi\,\ Madhya\ Pradesh";
$areanames{en}->{9176565} = "Kannodi\,\ Madhya\ Pradesh";
$areanames{en}->{9176566} = "Kannodi\,\ Madhya\ Pradesh";
$areanames{en}->{9176567} = "Kannodi\,\ Madhya\ Pradesh";
$areanames{en}->{9176568} = "Kannodi\,\ Madhya\ Pradesh";
$areanames{en}->{9176569} = "Kannodi\,\ Madhya\ Pradesh";
$areanames{en}->{9176570} = "Jaitpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176572} = "Jaitpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176573} = "Jaitpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176574} = "Jaitpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176575} = "Jaitpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176576} = "Jaitpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176577} = "Jaitpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176578} = "Jaitpur\,\ Madhya\ Pradesh";
$areanames{en}->{9176579} = "Jaitpur\,\ Madhya\ Pradesh";
$areanames{en}->{917658} = "Kotma\,\ Madhya\ Pradesh";
$areanames{en}->{917659} = "Jaithari\,\ Madhya\ Pradesh";
$areanames{en}->{917660} = "Sirmour\,\ Madhya\ Pradesh";
$areanames{en}->{917661} = "Teonthar\,\ Madhya\ Pradesh";
$areanames{en}->{917662} = "Rewa\,\ Madhya\ Pradesh";
$areanames{en}->{917663} = "Mauganj\,\ Madhya\ Pradesh";
$areanames{en}->{917664} = "Hanumana\,\ Madhya\ Pradesh";
$areanames{en}->{917670} = "Majhagwan\,\ Madhya\ Pradesh";
$areanames{en}->{917671} = "Jaitwara\,\ Madhya\ Pradesh";
$areanames{en}->{917672} = "Satna\,\ Madhya\ Pradesh";
$areanames{en}->{917673} = "Nagod\,\ Madhya\ Pradesh";
$areanames{en}->{917674} = "Maihar\,\ Madhya\ Pradesh";
$areanames{en}->{917675} = "Amarpatan\,\ Madhya\ Pradesh";
$areanames{en}->{917680} = "Niwari\,\ Madhya\ Pradesh";
$areanames{en}->{9176810} = "Jatara\,\ Madhya\ Pradesh";
$areanames{en}->{9176812} = "Jatara\,\ Madhya\ Pradesh";
$areanames{en}->{9176813} = "Jatara\,\ Madhya\ Pradesh";
$areanames{en}->{9176814} = "Jatara\,\ Madhya\ Pradesh";
$areanames{en}->{9176815} = "Jatara\,\ Madhya\ Pradesh";
$areanames{en}->{9176816} = "Jatara\,\ Madhya\ Pradesh";
$areanames{en}->{9176817} = "Jatara\,\ Madhya\ Pradesh";
$areanames{en}->{9176818} = "Jatara\,\ Madhya\ Pradesh";
$areanames{en}->{9176819} = "Jatara\,\ Madhya\ Pradesh";
$areanames{en}->{917682} = "Chhatarpur\,\ Madhya\ Pradesh";
$areanames{en}->{917683} = "Tikamgarh\,\ Madhya\ Pradesh";
$areanames{en}->{917684} = "Baldeogarh\,\ Madhya\ Pradesh";
$areanames{en}->{917685} = "Nowgaon\,\ Madhya\ Pradesh";
$areanames{en}->{917686} = "Khajuraho\,\ Madhya\ Pradesh";
$areanames{en}->{917687} = "Laundi\,\ Madhya\ Pradesh";
$areanames{en}->{917688} = "Gourihar\,\ Madhya\ Pradesh";
$areanames{en}->{917689} = "Badamalhera\,\ Madhya\ Pradesh";
$areanames{en}->{917690} = "Lakhnadon\,\ Madhya\ Pradesh";
$areanames{en}->{917691} = "Chhapara\,\ Madhya\ Pradesh";
$areanames{en}->{917692} = "Seoni\,\ Madhya\ Pradesh";
$areanames{en}->{917693} = "Ghansour\,\ Madhya\ Pradesh";
$areanames{en}->{917694} = "Keolari\,\ Madhya\ Pradesh";
$areanames{en}->{917695} = "Gopalganj\,\ Madhya\ Pradesh";
$areanames{en}->{9177000} = "Nagri\,\ Madhya\ Pradesh";
$areanames{en}->{9177002} = "Nagri\,\ Madhya\ Pradesh";
$areanames{en}->{9177003} = "Nagri\,\ Madhya\ Pradesh";
$areanames{en}->{9177004} = "Nagri\,\ Madhya\ Pradesh";
$areanames{en}->{9177005} = "Nagri\,\ Madhya\ Pradesh";
$areanames{en}->{9177006} = "Nagri\,\ Madhya\ Pradesh";
$areanames{en}->{9177007} = "Nagri\,\ Madhya\ Pradesh";
$areanames{en}->{9177008} = "Nagri\,\ Madhya\ Pradesh";
$areanames{en}->{9177009} = "Nagri\,\ Madhya\ Pradesh";
$areanames{en}->{9177010} = "Pingeshwar\,\ Madhya\ Pradesh";
$areanames{en}->{9177012} = "Pingeshwar\,\ Madhya\ Pradesh";
$areanames{en}->{9177013} = "Pingeshwar\,\ Madhya\ Pradesh";
$areanames{en}->{9177014} = "Pingeshwar\,\ Madhya\ Pradesh";
$areanames{en}->{9177015} = "Pingeshwar\,\ Madhya\ Pradesh";
$areanames{en}->{9177016} = "Pingeshwar\,\ Madhya\ Pradesh";
$areanames{en}->{9177017} = "Pingeshwar\,\ Madhya\ Pradesh";
$areanames{en}->{9177018} = "Pingeshwar\,\ Madhya\ Pradesh";
$areanames{en}->{9177019} = "Pingeshwar\,\ Madhya\ Pradesh";
$areanames{en}->{9177030} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9177032} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9177033} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9177034} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9177035} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9177036} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9177037} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9177038} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9177039} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{9177040} = "Deobhog\,\ Madhya\ Pradesh";
$areanames{en}->{9177042} = "Deobhog\,\ Madhya\ Pradesh";
$areanames{en}->{9177043} = "Deobhog\,\ Madhya\ Pradesh";
$areanames{en}->{9177044} = "Deobhog\,\ Madhya\ Pradesh";
$areanames{en}->{9177045} = "Deobhog\,\ Madhya\ Pradesh";
$areanames{en}->{9177046} = "Deobhog\,\ Madhya\ Pradesh";
$areanames{en}->{9177047} = "Deobhog\,\ Madhya\ Pradesh";
$areanames{en}->{9177048} = "Deobhog\,\ Madhya\ Pradesh";
$areanames{en}->{9177049} = "Deobhog\,\ Madhya\ Pradesh";
$areanames{en}->{9177050} = "Kurud\,\ Madhya\ Pradesh";
$areanames{en}->{9177052} = "Kurud\,\ Madhya\ Pradesh";
$areanames{en}->{9177053} = "Kurud\,\ Madhya\ Pradesh";
$areanames{en}->{9177054} = "Kurud\,\ Madhya\ Pradesh";
$areanames{en}->{9177055} = "Kurud\,\ Madhya\ Pradesh";
$areanames{en}->{9177056} = "Kurud\,\ Madhya\ Pradesh";
$areanames{en}->{9177057} = "Kurud\,\ Madhya\ Pradesh";
$areanames{en}->{9177058} = "Kurud\,\ Madhya\ Pradesh";
$areanames{en}->{9177059} = "Kurud\,\ Madhya\ Pradesh";
$areanames{en}->{9177060} = "Gariaband\,\ Madhya\ Pradesh";
$areanames{en}->{9177062} = "Gariaband\,\ Madhya\ Pradesh";
$areanames{en}->{9177063} = "Gariaband\,\ Madhya\ Pradesh";
$areanames{en}->{9177064} = "Gariaband\,\ Madhya\ Pradesh";
$areanames{en}->{9177065} = "Gariaband\,\ Madhya\ Pradesh";
$areanames{en}->{9177066} = "Gariaband\,\ Madhya\ Pradesh";
$areanames{en}->{9177067} = "Gariaband\,\ Madhya\ Pradesh";
$areanames{en}->{9177068} = "Gariaband\,\ Madhya\ Pradesh";
$areanames{en}->{9177069} = "Gariaband\,\ Madhya\ Pradesh";
$areanames{en}->{9177070} = "Bagbahera\,\ Madhya\ Pradesh";
$areanames{en}->{9177072} = "Bagbahera\,\ Madhya\ Pradesh";
$areanames{en}->{9177073} = "Bagbahera\,\ Madhya\ Pradesh";
$areanames{en}->{9177074} = "Bagbahera\,\ Madhya\ Pradesh";
$areanames{en}->{9177075} = "Bagbahera\,\ Madhya\ Pradesh";
$areanames{en}->{9177076} = "Bagbahera\,\ Madhya\ Pradesh";
$areanames{en}->{9177077} = "Bagbahera\,\ Madhya\ Pradesh";
$areanames{en}->{9177078} = "Bagbahera\,\ Madhya\ Pradesh";
$areanames{en}->{9177079} = "Bagbahera\,\ Madhya\ Pradesh";
$areanames{en}->{91771} = "Raipur\,\ Madhya\ Pradesh";
$areanames{en}->{917720} = "Arang\,\ Madhya\ Pradesh";
$areanames{en}->{917721} = "Neora\,\ Madhya\ Pradesh";
$areanames{en}->{917722} = "Dhamtari\,\ Madhya\ Pradesh";
$areanames{en}->{917723} = "Mahasamund\,\ Madhya\ Pradesh";
$areanames{en}->{917724} = "Basana\,\ Madhya\ Pradesh";
$areanames{en}->{917725} = "Saraipali\,\ Madhya\ Pradesh";
$areanames{en}->{917726} = "Bhatapara\,\ Madhya\ Pradesh";
$areanames{en}->{917727} = "Balodabazar\,\ Madhya\ Pradesh";
$areanames{en}->{917728} = "Kasdol\,\ Madhya\ Pradesh";
$areanames{en}->{917729} = "Bhilaigarh\,\ Madhya\ Pradesh";
$areanames{en}->{917730} = "Ajaigarh\,\ Madhya\ Pradesh";
$areanames{en}->{917731} = "Gunnore\,\ Madhya\ Pradesh";
$areanames{en}->{917732} = "Panna\,\ Madhya\ Pradesh";
$areanames{en}->{917733} = "Pawai\,\ Madhya\ Pradesh";
$areanames{en}->{917734} = "Shahnagar\,\ Madhya\ Pradesh";
$areanames{en}->{917740} = "Bodla\,\ Madhya\ Pradesh";
$areanames{en}->{917741} = "Kawardha\,\ Madhya\ Pradesh";
$areanames{en}->{917743} = "Chuikhadan\,\ Madhya\ Pradesh";
$areanames{en}->{917744} = "Rajandgaon\,\ Madhya\ Pradesh";
$areanames{en}->{917745} = "Chhuriakala\,\ Madhya\ Pradesh";
$areanames{en}->{917746} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{917747} = "Mohla\,\ Madhya\ Pradesh";
$areanames{en}->{917748} = "Dallirajhara\,\ Madhya\ Pradesh";
$areanames{en}->{917749} = "Balod\,\ Madhya\ Pradesh";
$areanames{en}->{917750} = "Marwahi\,\ Madhya\ Pradesh";
$areanames{en}->{917751} = "Pendra\,\ Madhya\ Pradesh";
$areanames{en}->{917752} = "Bilaspur\,\ Madhya\ Pradesh";
$areanames{en}->{917753} = "Kota\,\ Madhya\ Pradesh";
$areanames{en}->{917754} = "Pandaria\,\ Madhya\ Pradesh";
$areanames{en}->{917755} = "Mungeli\,\ Madhya\ Pradesh";
$areanames{en}->{917756} = "Lormi\,\ Madhya\ Pradesh";
$areanames{en}->{917757} = "Shakti\,\ Madhya\ Pradesh";
$areanames{en}->{917758} = "Dabhara\,\ Madhya\ Pradesh";
$areanames{en}->{917759} = "Korba\,\ Madhya\ Pradesh";
$areanames{en}->{917761} = "Tapkara\,\ Madhya\ Pradesh";
$areanames{en}->{917762} = "Raigarh\,\ Madhya\ Pradesh";
$areanames{en}->{917763} = "Jashpurnagar\,\ Madhya\ Pradesh";
$areanames{en}->{917764} = "Kunkuri\,\ Madhya\ Pradesh";
$areanames{en}->{917765} = "Pathalgaon\,\ Madhya\ Pradesh";
$areanames{en}->{917766} = "Dharamjaigarh\,\ Madhya\ Pradesh";
$areanames{en}->{917767} = "Gharghoda\,\ Madhya\ Pradesh";
$areanames{en}->{917768} = "Saranggarh\,\ Madhya\ Pradesh";
$areanames{en}->{917769} = "Bagicha\,\ Madhya\ Pradesh";
$areanames{en}->{917770} = "Kathdol\,\ Madhya\ Pradesh";
$areanames{en}->{917771} = "Manendragarh\,\ Madhya\ Pradesh";
$areanames{en}->{917772} = "Wadrainagar\,\ Madhya\ Pradesh";
$areanames{en}->{917773} = "Odgi\,\ Madhya\ Pradesh";
$areanames{en}->{917774} = "Ambikapur\,\ Madhya\ Pradesh";
$areanames{en}->{917775} = "Surajpur\,\ Madhya\ Pradesh";
$areanames{en}->{917776} = "Premnagar\,\ Madhya\ Pradesh";
$areanames{en}->{917777} = "Pratappur\,\ Madhya\ Pradesh";
$areanames{en}->{917778} = "Semaria\,\ Madhya\ Pradesh";
$areanames{en}->{917779} = "Ramchandrapur\,\ Madhya\ Pradesh";
$areanames{en}->{917781} = "Narainpur\,\ Madhya\ Pradesh";
$areanames{en}->{917782} = "Jagdalpur\,\ Madhya\ Pradesh";
$areanames{en}->{917783} = "Padamkot\,\ Madhya\ Pradesh";
$areanames{en}->{917784} = "Parasgaon\,\ Madhya\ Pradesh";
$areanames{en}->{917785} = "Makodi\,\ Madhya\ Pradesh";
$areanames{en}->{917786} = "Kondagaon\,\ Madhya\ Pradesh";
$areanames{en}->{917787} = "Jarwa\,\ Madhya\ Pradesh";
$areanames{en}->{917788} = "Luckwada\,\ Madhya\ Pradesh";
$areanames{en}->{917789} = "Bhairongarh\,\ Madhya\ Pradesh";
$areanames{en}->{917790} = "Babaichichli\,\ Madhya\ Pradesh";
$areanames{en}->{917791} = "Gadarwara\,\ Madhya\ Pradesh";
$areanames{en}->{917792} = "Narsinghpur\,\ Madhya\ Pradesh";
$areanames{en}->{917793} = "Kareli\,\ Madhya\ Pradesh";
$areanames{en}->{917794} = "Gotegaon\,\ Madhya\ Pradesh";
$areanames{en}->{917801} = "Deosar\,\ Madhya\ Pradesh";
$areanames{en}->{917802} = "Churhat\,\ Madhya\ Pradesh";
$areanames{en}->{917803} = "Majholi\,\ Madhya\ Pradesh";
$areanames{en}->{917804} = "Kusmi\,\ Madhya\ Pradesh";
$areanames{en}->{917805} = "Singrauli\,\ Madhya\ Pradesh";
$areanames{en}->{917806} = "Chitrangi\,\ Madhya\ Pradesh";
$areanames{en}->{9178080} = "\`";
$areanames{en}->{9178081} = "\`";
$areanames{en}->{9178088} = "\`";
$areanames{en}->{9178089} = "\`";
$areanames{en}->{917810} = "Uproda\,\ Madhya\ Pradesh";
$areanames{en}->{917811} = "Pasan\,\ Madhya\ Pradesh";
$areanames{en}->{917812} = "Damoh\,\ Madhya\ Pradesh";
$areanames{en}->{917813} = "Barpalli\,\ Madhya\ Pradesh";
$areanames{en}->{917815} = "Kathghora\,\ Madhya\ Pradesh";
$areanames{en}->{917816} = "Pali\,\ Madhya\ Pradesh";
$areanames{en}->{917817} = "Janjgir\,\ Madhya\ Pradesh";
$areanames{en}->{917818} = "Chandipara\,\ Madhya\ Pradesh";
$areanames{en}->{917819} = "Pandishankar\,\ Madhya\ Pradesh";
$areanames{en}->{917820} = "Khairagarh\,\ Madhya\ Pradesh";
$areanames{en}->{917821} = "Dhamda\,\ Madhya\ Pradesh";
$areanames{en}->{917822} = "Sidhi\,\ Madhya\ Pradesh";
$areanames{en}->{917823} = "Dongargarh\,\ Madhya\ Pradesh";
$areanames{en}->{917824} = "Bemetara\,\ Madhya\ Pradesh";
$areanames{en}->{917825} = "Berla\,\ Madhya\ Pradesh";
$areanames{en}->{917826} = "Patan\,\ Madhya\ Pradesh";
$areanames{en}->{917831} = "Balrampur\,\ Madhya\ Pradesh";
$areanames{en}->{917832} = "Rajpur\,\ Madhya\ Pradesh";
$areanames{en}->{917833} = "Udaipur\,\ Madhya\ Pradesh";
$areanames{en}->{917834} = "Sitapur\,\ Madhya\ Pradesh";
$areanames{en}->{917835} = "Bharathpur\,\ Madhya\ Pradesh";
$areanames{en}->{917836} = "Baikunthpur\,\ Madhya\ Pradesh";
$areanames{en}->{917840} = "Koyelibeda\,\ Madhya\ Pradesh";
$areanames{en}->{917841} = "Sarona\,\ Madhya\ Pradesh";
$areanames{en}->{917843} = "Durgakondal\,\ Madhya\ Pradesh";
$areanames{en}->{917844} = "Pakhanjur\,\ Madhya\ Pradesh";
$areanames{en}->{917846} = "Garpa\,\ Madhya\ Pradesh";
$areanames{en}->{917847} = "Antagarh\,\ Madhya\ Pradesh";
$areanames{en}->{917848} = "Keskal\,\ Madhya\ Pradesh";
$areanames{en}->{917849} = "Baderajpur\,\ Madhya\ Pradesh";
$areanames{en}->{917850} = "Bhanupratappur\,\ Madhya\ Pradesh";
$areanames{en}->{917851} = "Bhopalpatnam\,\ Madhya\ Pradesh";
$areanames{en}->{917852} = "Toynar\,\ Madhya\ Pradesh";
$areanames{en}->{917853} = "Bijapur\,\ Madhya\ Pradesh";
$areanames{en}->{917854} = "Ilamidi\,\ Madhya\ Pradesh";
$areanames{en}->{917855} = "Chingmut\,\ Madhya\ Pradesh";
$areanames{en}->{917856} = "Dantewada\,\ Madhya\ Pradesh";
$areanames{en}->{917857} = "Bacheli\,\ Madhya\ Pradesh";
$areanames{en}->{917858} = "Kuakunda\,\ Madhya\ Pradesh";
$areanames{en}->{917859} = "Lohadigundah\,\ Madhya\ Pradesh";
$areanames{en}->{917861} = "Netanar\,\ Madhya\ Pradesh";
$areanames{en}->{917862} = "Bastanar\,\ Madhya\ Pradesh";
$areanames{en}->{917863} = "Chingamut\,\ Madhya\ Pradesh";
$areanames{en}->{917864} = "Sukma\,\ Madhya\ Pradesh";
$areanames{en}->{917865} = "Gogunda\,\ Madhya\ Pradesh";
$areanames{en}->{917866} = "Konta\,\ Madhya\ Pradesh";
$areanames{en}->{917867} = "Bokaband\,\ Madhya\ Pradesh";
$areanames{en}->{917868} = "Kanker\,\ Madhya\ Pradesh";
$areanames{en}->{91788} = "Durg\,\ Madhya\ Pradesh";
$areanames{en}->{91790} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{917912} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{917913} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{917914} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{917915} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{917916} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{917917} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{91792} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{91793} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{91794} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{91795} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{91796} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{91797} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{91798} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{91799} = "Ahmedabad\ Local\,\ Gujarat";
$areanames{en}->{9180} = "Bangalore\,\ Karnataka";
$areanames{en}->{918110} = "Anekal\,\ Karnataka";
$areanames{en}->{918111} = "Hosakote\,\ Karnataka";
$areanames{en}->{918113} = "Channapatna\,\ Karnataka";
$areanames{en}->{918117} = "Kanakapura\,\ Karnataka";
$areanames{en}->{918118} = "Nelamangala\,\ Karnataka";
$areanames{en}->{918119} = "Doddaballapur\,\ Karnataka";
$areanames{en}->{918131} = "Gubbi\,\ Karnataka";
$areanames{en}->{918132} = "Kunigal\,\ Karnataka";
$areanames{en}->{918133} = "Chikkanayakanahalli\,\ Karnataka";
$areanames{en}->{918134} = "Tiptur\,\ Karnataka";
$areanames{en}->{918135} = "Sira\,\ Karnataka";
$areanames{en}->{918136} = "Pavagada\,\ Karnataka";
$areanames{en}->{918137} = "Madugiri\,\ Karnataka";
$areanames{en}->{918138} = "Koratageri\,\ Karnataka";
$areanames{en}->{918139} = "Turuvekere\,\ Karnataka";
$areanames{en}->{918150} = "Bagepalli\,\ Karnataka";
$areanames{en}->{918151} = "Malur\,\ Karnataka";
$areanames{en}->{918152} = "Kolar\,\ Karnataka";
$areanames{en}->{9181520} = "Kolar\,\ Karnatak";
$areanames{en}->{9181521} = "Kolar\,\ Karnatak";
$areanames{en}->{9181528} = "Kolar\,\ Karnatak";
$areanames{en}->{9181529} = "Kolar\,\ Karnatak";
$areanames{en}->{918153} = "Bangarpet\,\ Karnataka";
$areanames{en}->{918154} = "Chintamani\,\ Karnataka";
$areanames{en}->{918155} = "Gowribidanur\,\ Karnataka";
$areanames{en}->{918156} = "Chikkaballapur\,\ Karnataka";
$areanames{en}->{918157} = "Srinivasapur\,\ Karnataka";
$areanames{en}->{918158} = "Sidlaghatta\,\ Karnataka";
$areanames{en}->{918159} = "Mulbagal\,\ Karnataka";
$areanames{en}->{91816} = "Tumkur\,\ Karnataka";
$areanames{en}->{9181700} = "Alur\,\ Karnataka";
$areanames{en}->{9181702} = "Alur\,\ Karnataka";
$areanames{en}->{9181703} = "Alur\,\ Karnataka";
$areanames{en}->{9181704} = "Alur\,\ Karnataka";
$areanames{en}->{9181705} = "Alur\,\ Karnataka";
$areanames{en}->{9181706} = "Alur\,\ Karnataka";
$areanames{en}->{9181707} = "Alur\,\ Karnataka";
$areanames{en}->{9181708} = "Alur\,\ Karnataka";
$areanames{en}->{9181709} = "Alur\,\ Karnataka";
$areanames{en}->{9181720} = "Hassan\,\ Karnataka";
$areanames{en}->{9181722} = "Hassan\,\ Karnataka";
$areanames{en}->{9181723} = "Hassan\,\ Karnataka";
$areanames{en}->{9181724} = "Hassan\,\ Karnataka";
$areanames{en}->{9181725} = "Hassan\,\ Karnataka";
$areanames{en}->{9181726} = "Hassan\,\ Karnataka";
$areanames{en}->{9181727} = "Hassan\,\ Karnataka";
$areanames{en}->{9181728} = "Hassan\,\ Karnataka";
$areanames{en}->{9181729} = "Hassan\,\ Karnataka";
$areanames{en}->{9181730} = "Sakleshpur\,\ Karnataka";
$areanames{en}->{9181732} = "Sakleshpur\,\ Karnataka";
$areanames{en}->{9181733} = "Sakleshpur\,\ Karnataka";
$areanames{en}->{9181734} = "Sakleshpur\,\ Karnataka";
$areanames{en}->{9181735} = "Sakleshpur\,\ Karnataka";
$areanames{en}->{9181736} = "Sakleshpur\,\ Karnataka";
$areanames{en}->{9181737} = "Sakleshpur\,\ Karnataka";
$areanames{en}->{9181738} = "Sakleshpur\,\ Karnataka";
$areanames{en}->{9181739} = "Sakleshpur\,\ Karnataka";
$areanames{en}->{9181740} = "Arsikere\,\ Karnataka";
$areanames{en}->{9181742} = "Arsikere\,\ Karnataka";
$areanames{en}->{9181743} = "Arsikere\,\ Karnataka";
$areanames{en}->{9181744} = "Arsikere\,\ Karnataka";
$areanames{en}->{9181745} = "Arsikere\,\ Karnataka";
$areanames{en}->{9181746} = "Arsikere\,\ Karnataka";
$areanames{en}->{9181747} = "Arsikere\,\ Karnataka";
$areanames{en}->{9181748} = "Arsikere\,\ Karnataka";
$areanames{en}->{9181749} = "Arsikere\,\ Karnataka";
$areanames{en}->{9181750} = "Holenarasipur\,\ Karnataka";
$areanames{en}->{9181752} = "Holenarasipur\,\ Karnataka";
$areanames{en}->{9181753} = "Holenarasipur\,\ Karnataka";
$areanames{en}->{9181754} = "Holenarasipur\,\ Karnataka";
$areanames{en}->{9181755} = "Holenarasipur\,\ Karnataka";
$areanames{en}->{9181756} = "Holenarasipur\,\ Karnataka";
$areanames{en}->{9181757} = "Holenarasipur\,\ Karnataka";
$areanames{en}->{9181758} = "Holenarasipur\,\ Karnataka";
$areanames{en}->{9181759} = "Holenarasipur\,\ Karnataka";
$areanames{en}->{9181760} = "Cannarayapatna\,\ Karnataka";
$areanames{en}->{9181762} = "Cannarayapatna\,\ Karnataka";
$areanames{en}->{9181763} = "Cannarayapatna\,\ Karnataka";
$areanames{en}->{9181764} = "Cannarayapatna\,\ Karnataka";
$areanames{en}->{9181765} = "Cannarayapatna\,\ Karnataka";
$areanames{en}->{9181766} = "Cannarayapatna\,\ Karnataka";
$areanames{en}->{9181767} = "Cannarayapatna\,\ Karnataka";
$areanames{en}->{9181768} = "Cannarayapatna\,\ Karnataka";
$areanames{en}->{9181769} = "Cannarayapatna\,\ Karnataka";
$areanames{en}->{918177} = "Belur\,\ Karnataka";
$areanames{en}->{918180} = "Basavapatna\,\ Karnataka";
$areanames{en}->{918181} = "Thirthahalli\,\ Karnataka";
$areanames{en}->{918182} = "Shimoga\,\ Karnataka";
$areanames{en}->{918183} = "Sagar\,\ Karnataka";
$areanames{en}->{918184} = "Sorab\,\ Karnataka";
$areanames{en}->{918185} = "Hosanagara\,\ Karnataka";
$areanames{en}->{918186} = "Kargal\,\ Karnataka";
$areanames{en}->{918187} = "Shikaripura\,\ Karnataka";
$areanames{en}->{918188} = "Honnali\,\ Karnataka";
$areanames{en}->{918189} = "Channagiri\,\ Karnataka";
$areanames{en}->{918190} = "Tallak\,\ Karnataka";
$areanames{en}->{918191} = "Holalkere\,\ Karnataka";
$areanames{en}->{918192} = "Davangere\,\ Karnataka";
$areanames{en}->{918193} = "Hiriyur\,\ Karnataka";
$areanames{en}->{9181930} = "Hiriyur\,\ Karnataka";
$areanames{en}->{9181931} = "Hiriyur\,\ Karnataka";
$areanames{en}->{9181938} = "Hiriyur\,\ Karnataka";
$areanames{en}->{9181939} = "Hiriyur\,\ Karnataka";
$areanames{en}->{918194} = "Chitradurga\,\ Karnataka";
$areanames{en}->{918195} = "Challakere\,\ Karnataka";
$areanames{en}->{918196} = "Jagalur\,\ Karnataka";
$areanames{en}->{918198} = "Molkalmuru\,\ Karnataka";
$areanames{en}->{918199} = "Hosadurga\,\ Karnataka";
$areanames{en}->{918200} = "Udupi\,\ Karnataka";
$areanames{en}->{918202} = "Udupi\,\ Karnataka";
$areanames{en}->{918203} = "Udupi\,\ Karnataka";
$areanames{en}->{918204} = "Udupi\,\ Karnataka";
$areanames{en}->{918205} = "Udupi\,\ Karnataka";
$areanames{en}->{918206} = "Udupi\,\ Karnataka";
$areanames{en}->{918207} = "Udupi\,\ Karnataka";
$areanames{en}->{918208} = "Udupi\,\ Karnataka";
$areanames{en}->{918209} = "Udupi\,\ Karnataka";
$areanames{en}->{918210} = "Mysore\,\ Karnataka";
$areanames{en}->{918212} = "Mysore\,\ Karnataka";
$areanames{en}->{918213} = "Mysore\,\ Karnataka";
$areanames{en}->{918214} = "Mysore\,\ Karnataka";
$areanames{en}->{918215} = "Mysore\,\ Karnataka";
$areanames{en}->{918216} = "Mysore\,\ Karnataka";
$areanames{en}->{918217} = "Mysore\,\ Karnataka";
$areanames{en}->{918218} = "Mysore\,\ Karnataka";
$areanames{en}->{918219} = "Mysore\,\ Karnataka";
$areanames{en}->{9182202} = "Gundlupet\,\ Karnataka";
$areanames{en}->{9182203} = "Gundlupet\,\ Karnataka";
$areanames{en}->{9182204} = "Gundlupet\,\ Karnataka";
$areanames{en}->{9182205} = "Gundlupet\,\ Karnataka";
$areanames{en}->{9182206} = "Gundlupet\,\ Karnataka";
$areanames{en}->{9182207} = "Gundlupet\,\ Karnataka";
$areanames{en}->{918221} = "Nanjangud\,\ Karnataka";
$areanames{en}->{918222} = "Hunsur\,\ Karnataka";
$areanames{en}->{918223} = "K\.R\.Nagar\,\ Karnataka";
$areanames{en}->{918224} = "Kollegal\,\ Karnataka";
$areanames{en}->{918225} = "Cowdahalli\,\ Karnataka";
$areanames{en}->{918226} = "Chamrajnagar\,\ Karnataka";
$areanames{en}->{918227} = "T\.Narsipur\,\ Karnataka";
$areanames{en}->{918228} = "H\.D\.Kote\,\ Karnataka";
$areanames{en}->{918229} = "Gundlupet\,\ Karnataka";
$areanames{en}->{918230} = "Krishnarajapet\,\ Karnataka";
$areanames{en}->{918231} = "Malavalli\,\ Karnataka";
$areanames{en}->{918232} = "Mandya\,\ Karnataka";
$areanames{en}->{918234} = "Nagamangala\,\ Karnataka";
$areanames{en}->{918236} = "Pandavpura\,\ Karnataka";
$areanames{en}->{918240} = "Mangalore\,\ Karnataka";
$areanames{en}->{918242} = "Mangalore\,\ Karnataka";
$areanames{en}->{918243} = "Mangalore\,\ Karnataka";
$areanames{en}->{918244} = "Mangalore\,\ Karnataka";
$areanames{en}->{918245} = "Mangalore\,\ Karnataka";
$areanames{en}->{918246} = "Mangalore\,\ Karnataka";
$areanames{en}->{918247} = "Mangalore\,\ Karnataka";
$areanames{en}->{918248} = "Mangalore\,\ Karnataka";
$areanames{en}->{918249} = "Mangalore\,\ Karnataka";
$areanames{en}->{918251} = "Puttur\,\ Karnataka";
$areanames{en}->{918253} = "Hebri\,\ Karnataka";
$areanames{en}->{918254} = "Kundapur\,\ Karnataka";
$areanames{en}->{918255} = "Bantwal\,\ Karnataka";
$areanames{en}->{918256} = "Belthangady\,\ Karnataka";
$areanames{en}->{918257} = "Sullia\,\ Karnataka";
$areanames{en}->{918258} = "Karkala\,\ Karnataka";
$areanames{en}->{918259} = "Shankarnarayana\,\ Karnataka";
$areanames{en}->{918261} = "Tarikere\,\ Karnataka";
$areanames{en}->{918262} = "Chikmagalur\,\ Karnataka";
$areanames{en}->{918263} = "Mudigere\,\ Karnataka";
$areanames{en}->{918265} = "Koppa\,\ Karnataka";
$areanames{en}->{918266} = "Narsimharajapur\,\ Karnataka";
$areanames{en}->{918267} = "Kadur\,\ Karnataka";
$areanames{en}->{918272} = "Madikeri\,\ Karnataka";
$areanames{en}->{918274} = "Virajpet\,\ Karnataka";
$areanames{en}->{918276} = "Somwarpet\,\ Karnataka";
$areanames{en}->{918282} = "Bhadravati\,\ Karnataka";
$areanames{en}->{918283} = "Salkani\,\ Karnataka";
$areanames{en}->{918284} = "Haliyal\,\ Karnataka";
$areanames{en}->{918288} = "Bailhongal\,\ Karnataka";
$areanames{en}->{9182890} = "Athani\,\ Karnataka";
$areanames{en}->{9182892} = "Athani\,\ Karnataka";
$areanames{en}->{9182893} = "Athani\,\ Karnataka";
$areanames{en}->{9182894} = "Athani\,\ Karnataka";
$areanames{en}->{9182895} = "Athani\,\ Karnataka";
$areanames{en}->{9182896} = "Athani\,\ Karnataka";
$areanames{en}->{9182897} = "Athani\,\ Karnataka";
$areanames{en}->{9182898} = "Athani\,\ Karnataka";
$areanames{en}->{9182899} = "Athani\,\ Karnataka";
$areanames{en}->{918301} = "Mundagod\,\ Karnataka";
$areanames{en}->{918304} = "Kundgol\,\ Karnataka";
$areanames{en}->{918310} = "Belgaum\,\ Karnataka";
$areanames{en}->{918312} = "Belgaum\,\ Karnataka";
$areanames{en}->{918313} = "Belgaum\,\ Karnataka";
$areanames{en}->{918314} = "Belgaum\,\ Karnataka";
$areanames{en}->{918315} = "Belgaum\,\ Karnataka";
$areanames{en}->{918316} = "Belgaum\,\ Karnataka";
$areanames{en}->{918317} = "Belgaum\,\ Karnataka";
$areanames{en}->{918318} = "Belgaum\,\ Karnataka";
$areanames{en}->{918319} = "Belgaum\,\ Karnataka";
$areanames{en}->{918320} = "Goa";
$areanames{en}->{918322} = "Goa";
$areanames{en}->{918323} = "Goa";
$areanames{en}->{918324} = "Goa";
$areanames{en}->{918325} = "Goa";
$areanames{en}->{918326} = "Goa";
$areanames{en}->{918327} = "Goa";
$areanames{en}->{918328} = "Goa";
$areanames{en}->{918329} = "Goa";
$areanames{en}->{918330} = "Saundatti\,\ Karnataka";
$areanames{en}->{918331} = "Raibag\/Kudchi\,\ Karnataka";
$areanames{en}->{918332} = "Gokak\,\ Karnataka";
$areanames{en}->{918333} = "Hukkeri\/Sankeshwar\,\ Karnataka";
$areanames{en}->{918334} = "Mudalgi\,\ Karnataka";
$areanames{en}->{918335} = "Ramdurg\,\ Karnataka";
$areanames{en}->{918336} = "Khanapur\,\ Karnataka";
$areanames{en}->{918337} = "Murugod\,\ Karnataka";
$areanames{en}->{918338} = "Chikkodi\,\ Karnataka";
$areanames{en}->{918339} = "Ainapur\,\ Karnataka";
$areanames{en}->{918350} = "Mudhol\,\ Karnataka";
$areanames{en}->{918351} = "Hungund\,\ Karnataka";
$areanames{en}->{918352} = "Bijapur\,\ Karnataka";
$areanames{en}->{918353} = "Jamkhandi\,\ Karnataka";
$areanames{en}->{918354} = "Bagalkot\,\ Karnataka";
$areanames{en}->{918355} = "Bableshwar\,\ Karnataka";
$areanames{en}->{918356} = "Muddebihal\,\ Karnataka";
$areanames{en}->{918357} = "Badami\,\ Karnataka";
$areanames{en}->{918358} = "Basavanabagewadi\,\ Karnataka";
$areanames{en}->{918359} = "Indi\,\ Karnataka";
$areanames{en}->{918360} = "Hubli\,\ Karnataka";
$areanames{en}->{918362} = "Hubli\,\ Karnataka";
$areanames{en}->{918363} = "Hubli\,\ Karnataka";
$areanames{en}->{918364} = "Hubli\,\ Karnataka";
$areanames{en}->{918365} = "Hubli\,\ Karnataka";
$areanames{en}->{918366} = "Hubli\,\ Karnataka";
$areanames{en}->{918367} = "Hubli\,\ Karnataka";
$areanames{en}->{918368} = "Hubli\,\ Karnataka";
$areanames{en}->{918369} = "Hubli\,\ Karnataka";
$areanames{en}->{918370} = "Kalghatagi\,\ Karnataka";
$areanames{en}->{918371} = "Mundargi\,\ Karnataka";
$areanames{en}->{918372} = "Gadag\,\ Karnataka";
$areanames{en}->{918373} = "Ranebennur\,\ Karnataka";
$areanames{en}->{918375} = "Haveri\,\ Karnataka";
$areanames{en}->{918376} = "Hirekerur\,\ Karnataka";
$areanames{en}->{918377} = "Nargund\,\ Karnataka";
$areanames{en}->{918378} = "Savanur\,\ Karnataka";
$areanames{en}->{918379} = "Hangal\,\ Karnataka";
$areanames{en}->{918380} = "Navalgund\,\ Karnataka";
$areanames{en}->{918381} = "Ron\,\ Karnataka";
$areanames{en}->{918382} = "Karwar\,\ Karnataka";
$areanames{en}->{918383} = "Joida\,\ Karnataka";
$areanames{en}->{918384} = "Sirsi\,\ Karnataka";
$areanames{en}->{918385} = "Bhatkal\,\ Karnataka";
$areanames{en}->{918386} = "Kumta\,\ Karnataka";
$areanames{en}->{918387} = "Honnavar\,\ Karnataka";
$areanames{en}->{918388} = "Ankola\,\ Karnataka";
$areanames{en}->{918389} = "Siddapur\,\ Karnataka";
$areanames{en}->{918391} = "Kudligi\,\ Karnataka";
$areanames{en}->{918392} = "Bellary\,\ Karnataka";
$areanames{en}->{918393} = "Kurugodu\,\ Karnataka";
$areanames{en}->{918394} = "Hospet\,\ Karnataka";
$areanames{en}->{918395} = "Sandur\,\ Karnataka";
$areanames{en}->{918396} = "Siruguppa\,\ Karnataka";
$areanames{en}->{918397} = "H\.B\.Halli\,\ Karnataka";
$areanames{en}->{918398} = "Harapanahalli\,\ Karnataka";
$areanames{en}->{918399} = "Huvinahadagali\,\ Karnataka";
$areanames{en}->{918402} = "Kanigiri\,\ Andhra\ Pradesh";
$areanames{en}->{918403} = "Yerragondapalem\,\ Andhra\ Pradesh";
$areanames{en}->{918404} = "Marturu\,\ Andhra\ Pradesh";
$areanames{en}->{918405} = "Giddalur\,\ Andhra\ Pradesh";
$areanames{en}->{918406} = "Cumbum\,\ Andhra\ Pradesh";
$areanames{en}->{918407} = "Darsi\,\ Andhra\ Pradesh";
$areanames{en}->{918408} = "Donakonda\,\ Andhra\ Pradesh";
$areanames{en}->{918411} = "Tanduru\,\ Andhra\ Pradesh";
$areanames{en}->{918412} = "Pargi\,\ Andhra\ Pradesh";
$areanames{en}->{918413} = "Hyderabad\ West\/Shamshabad\,\ Andhra\ Pradesh";
$areanames{en}->{918414} = "Ibrahimpatnam\,\ Andhra\ Pradesh";
$areanames{en}->{918415} = "Hyderabad\ East\/Ghatkeswar\,\ Andhra\ Pradesh";
$areanames{en}->{918416} = "Vikrabad\,\ Andhra\ Pradesh";
$areanames{en}->{918417} = "Chevella\,\ Andhra\ Pradesh";
$areanames{en}->{918418} = "Medchal\,\ Andhra\ Pradesh";
$areanames{en}->{918419} = "Yellapur\,\ Karnataka";
$areanames{en}->{918422} = "Chadchan\,\ Karnataka";
$areanames{en}->{918424} = "Devarahippargi\,\ Karnataka";
$areanames{en}->{918425} = "Biligi\,\ Karnataka";
$areanames{en}->{918426} = "Telgi\,\ Karnataka";
$areanames{en}->{918440} = "Nimburga\,\ Karnataka";
$areanames{en}->{918441} = "Sedam\,\ Karnataka";
$areanames{en}->{918442} = "Jewargi\,\ Karnataka";
$areanames{en}->{918443} = "Shorapur\,\ Karnataka";
$areanames{en}->{918444} = "Hunsagi\,\ Karnataka";
$areanames{en}->{918450} = "Andole\/Jogipet\,\ Andhra\ Pradesh";
$areanames{en}->{918451} = "Zahirabad\,\ Andhra\ Pradesh";
$areanames{en}->{918452} = "Medak\,\ Andhra\ Pradesh";
$areanames{en}->{9184532} = "Medak\,\ Andhra\ Pradesh";
$areanames{en}->{9184533} = "Medak\,\ Andhra\ Pradesh";
$areanames{en}->{9184534} = "Medak\,\ Andhra\ Pradesh";
$areanames{en}->{9184535} = "Medak\,\ Andhra\ Pradesh";
$areanames{en}->{9184536} = "Medak\,\ Andhra\ Pradesh";
$areanames{en}->{9184537} = "Medak\,\ Andhra\ Pradesh";
$areanames{en}->{918454} = "Gajwel\,\ Andhra\ Pradesh";
$areanames{en}->{918455} = "Sangareddy\,\ Andhra\ Pradesh";
$areanames{en}->{918456} = "Narayankhed\,\ Andhra\ Pradesh";
$areanames{en}->{918457} = "Siddipet\,\ Andhra\ Pradesh";
$areanames{en}->{918458} = "Narsapur\,\ Andhra\ Pradesh";
$areanames{en}->{918461} = "Dichpalli\,\ Andhra\ Pradesh";
$areanames{en}->{918462} = "Nizamabad\,\ Andhra\ Pradesh";
$areanames{en}->{918463} = "Armoor\,\ Andhra\ Pradesh";
$areanames{en}->{918464} = "Madnur\,\ Andhra\ Pradesh";
$areanames{en}->{918465} = "Yellareddy\,\ Andhra\ Pradesh";
$areanames{en}->{918466} = "Banswada\,\ Andhra\ Pradesh";
$areanames{en}->{918467} = "Bodhan\,\ Andhra\ Pradesh";
$areanames{en}->{918468} = "Kamareddy\,\ Andhra\ Pradesh";
$areanames{en}->{918470} = "Afzalpur\,\ Karnataka";
$areanames{en}->{918471} = "Mashal\,\ Karnataka";
$areanames{en}->{918472} = "Gulbarga\,\ Karnataka";
$areanames{en}->{918473} = "Yadgiri\,\ Karnataka";
$areanames{en}->{918474} = "Chittapur\,\ Karnataka";
$areanames{en}->{918475} = "Chincholi\,\ Karnataka";
$areanames{en}->{918476} = "Wadi\,\ Karnataka";
$areanames{en}->{918477} = "Aland\,\ Karnataka";
$areanames{en}->{918478} = "Kamalapur\,\ Karnataka";
$areanames{en}->{918479} = "Shahapur\,\ Karnataka";
$areanames{en}->{918481} = "Basavakalyan\,\ Karnataka";
$areanames{en}->{918482} = "Bidar\,\ Karnataka";
$areanames{en}->{918483} = "Humnabad\,\ Karnataka";
$areanames{en}->{918484} = "Bhalki\,\ Karnataka";
$areanames{en}->{918485} = "Aurad\,\ Karnataka";
$areanames{en}->{918487} = "Shirahatti\,\ Karnataka";
$areanames{en}->{918488} = "Sindagi\,\ Karnataka";
$areanames{en}->{918490} = "Pamuru\,\ Andhra\ Pradesh";
$areanames{en}->{918491} = "Kanaganapalle\,\ Andhra\ Pradesh";
$areanames{en}->{918492} = "Kambadur\,\ Andhra\ Pradesh";
$areanames{en}->{918493} = "Madakasira\,\ Andhra\ Pradesh";
$areanames{en}->{918494} = "Kadiri\,\ Andhra\ Pradesh";
$areanames{en}->{918495} = "Rayadurg\,\ Andhra\ Pradesh";
$areanames{en}->{918496} = "Uravakonda\,\ Andhra\ Pradesh";
$areanames{en}->{918497} = "Kalyandurg\,\ Andhra\ Pradesh";
$areanames{en}->{918498} = "Nallacheruvu\/Tanakallu\,\ Andhra\ Pradesh";
$areanames{en}->{918499} = "Podili\,\ Andhra\ Pradesh";
$areanames{en}->{918501} = "Kollapur\,\ Andhra\ Pradesh";
$areanames{en}->{918502} = "Alampur\,\ Andhra\ Pradesh";
$areanames{en}->{918503} = "Makthal\,\ Andhra\ Pradesh";
$areanames{en}->{918504} = "Atmakur\,\ Andhra\ Pradesh";
$areanames{en}->{918505} = "Kodangal\,\ Andhra\ Pradesh";
$areanames{en}->{918506} = "Narayanpet\,\ Andhra\ Pradesh";
$areanames{en}->{918510} = "Koilkuntla\,\ Andhra\ Pradesh";
$areanames{en}->{918512} = "Adoni\,\ Andhra\ Pradesh";
$areanames{en}->{918513} = "Nandikotkur\,\ Andhra\ Pradesh";
$areanames{en}->{918514} = "Nandyal\,\ Andhra\ Pradesh";
$areanames{en}->{918515} = "Banaganapalle\,\ Andhra\ Pradesh";
$areanames{en}->{918516} = "Dronachalam\,\ Andhra\ Pradesh";
$areanames{en}->{918517} = "Atmakur\,\ Andhra\ Pradesh";
$areanames{en}->{918518} = "Kurnool\,\ Andhra\ Pradesh";
$areanames{en}->{918519} = "Allagadda\,\ Andhra\ Pradesh";
$areanames{en}->{918520} = "Pattikonda\,\ Andhra\ Pradesh";
$areanames{en}->{918522} = "Peapalle\,\ Andhra\ Pradesh";
$areanames{en}->{918523} = "Alur\,\ Andhra\ Pradesh";
$areanames{en}->{918524} = "Srisailam\,\ Andhra\ Pradesh";
$areanames{en}->{918525} = "Gudur\/Kodumur\,\ Andhra\ Pradesh";
$areanames{en}->{918531} = "Deodurga\,\ Karnataka";
$areanames{en}->{918532} = "Raichur\,\ Karnataka";
$areanames{en}->{918533} = "Gangavathi\,\ Karnataka";
$areanames{en}->{918534} = "Yelburga\,\ Karnataka";
$areanames{en}->{918535} = "Sindhanur\,\ Karnataka";
$areanames{en}->{918536} = "Kustagi\,\ Karnataka";
$areanames{en}->{918537} = "Lingsugur\,\ Karnataka";
$areanames{en}->{918538} = "Manvi\,\ Karnataka";
$areanames{en}->{918539} = "Koppal\,\ Karnataka";
$areanames{en}->{918540} = "Nagarkurnool\,\ Andhra\ Pradesh";
$areanames{en}->{918541} = "Achampet\,\ Andhra\ Pradesh";
$areanames{en}->{918542} = "Mahabubnagar\,\ Andhra\ Pradesh";
$areanames{en}->{918543} = "Wanaparthy\,\ Andhra\ Pradesh";
$areanames{en}->{918545} = "Amangallu\,\ Andhra\ Pradesh";
$areanames{en}->{918546} = "Gadwal\,\ Andhra\ Pradesh";
$areanames{en}->{918548} = "Shadnagar\,\ Andhra\ Pradesh";
$areanames{en}->{918549} = "Kalwakurthy\,\ Andhra\ Pradesh";
$areanames{en}->{918550} = "Yellanuru\,\ Andhra\ Pradesh";
$areanames{en}->{918551} = "Garladinne\,\ Andhra\ Pradesh";
$areanames{en}->{918552} = "Gooty\/Guntakal\,\ Andhra\ Pradesh";
$areanames{en}->{918554} = "Anantapur\,\ Andhra\ Pradesh";
$areanames{en}->{918556} = "Hindupur\,\ Andhra\ Pradesh";
$areanames{en}->{918557} = "Penukonda\,\ Andhra\ Pradesh";
$areanames{en}->{918558} = "Tadipatri\,\ Andhra\ Pradesh";
$areanames{en}->{918559} = "Dharmavaram\,\ Andhra\ Pradesh";
$areanames{en}->{918560} = "Jammalamadugu\,\ Andhra\ Pradesh";
$areanames{en}->{918561} = "Rayachoti\,\ Andhra\ Pradesh";
$areanames{en}->{918562} = "Kadapa\,\ Andhra\ Pradesh";
$areanames{en}->{918563} = "Kamalapuram\/Yerraguntala\,\ Andhra\ Pradesh";
$areanames{en}->{918564} = "Proddatur\,\ Andhra\ Pradesh";
$areanames{en}->{918565} = "Rajampeta\,\ Andhra\ Pradesh";
$areanames{en}->{918566} = "Koduru\,\ Andhra\ Pradesh";
$areanames{en}->{918567} = "Lakkireddipalli\,\ Andhra\ Pradesh";
$areanames{en}->{918568} = "Pulivendla\,\ Andhra\ Pradesh";
$areanames{en}->{918569} = "Badvel\,\ Andhra\ Pradesh";
$areanames{en}->{918570} = "Kuppam\,\ Andhra\ Pradesh";
$areanames{en}->{918571} = "Madanapalli\,\ Andhra\ Pradesh";
$areanames{en}->{918572} = "Chittoor\,\ Andhra\ Pradesh";
$areanames{en}->{918573} = "Bangarupalem\,\ Andhra\ Pradesh";
$areanames{en}->{918576} = "Satyavedu\,\ Andhra\ Pradesh";
$areanames{en}->{918577} = "Putturu\,\ Andhra\ Pradesh";
$areanames{en}->{918578} = "Srikalahasthi\,\ Andhra\ Pradesh";
$areanames{en}->{918579} = "Palmaneru\,\ Andhra\ Pradesh";
$areanames{en}->{918581} = "Punganur\,\ Andhra\ Pradesh";
$areanames{en}->{918582} = "B\.Kothakota\,\ Andhra\ Pradesh";
$areanames{en}->{918583} = "Sodam\,\ Andhra\ Pradesh";
$areanames{en}->{918584} = "Piler\,\ Andhra\ Pradesh";
$areanames{en}->{918585} = "Pakala\,\ Andhra\ Pradesh";
$areanames{en}->{918586} = "Vayalpad\,\ Andhra\ Pradesh";
$areanames{en}->{9185860} = "Vayalpad\,\ Andhra\ Pradesh";
$areanames{en}->{9185861} = "Vayalpad\,\ Andhra\ Pradesh";
$areanames{en}->{9185868} = "Vayalpad\,\ Andhra\ Pradesh";
$areanames{en}->{9185869} = "Vayalpad\,\ Andhra\ Pradesh";
$areanames{en}->{918587} = "Venkatgirikota\,\ Andhra\ Pradesh";
$areanames{en}->{918588} = "Vaimpalli\,\ Andhra\ Pradesh";
$areanames{en}->{918589} = "Siddavattam\,\ Andhra\ Pradesh";
$areanames{en}->{918592} = "Ongole\,\ Andhra\ Pradesh";
$areanames{en}->{918593} = "Medarmetla\,\ Andhra\ Pradesh";
$areanames{en}->{918594} = "Chirala\,\ Andhra\ Pradesh";
$areanames{en}->{918596} = "Markapur\,\ Andhra\ Pradesh";
$areanames{en}->{918598} = "Kandukuru\,\ Andhra\ Pradesh";
$areanames{en}->{918599} = "Ulvapadu\,\ Andhra\ Pradesh";
$areanames{en}->{918610} = "Nellore\,\ Andhra\ Pradesh";
$areanames{en}->{918612} = "Nellore\,\ Andhra\ Pradesh";
$areanames{en}->{918613} = "Nellore\,\ Andhra\ Pradesh";
$areanames{en}->{918614} = "Nellore\,\ Andhra\ Pradesh";
$areanames{en}->{918615} = "Nellore\,\ Andhra\ Pradesh";
$areanames{en}->{918616} = "Nellore\,\ Andhra\ Pradesh";
$areanames{en}->{918617} = "Nellore\,\ Andhra\ Pradesh";
$areanames{en}->{918618} = "Nellore\,\ Andhra\ Pradesh";
$areanames{en}->{918619} = "Nellore\,\ Andhra\ Pradesh";
$areanames{en}->{918620} = "Udaygiri\,\ Andhra\ Pradesh";
$areanames{en}->{918621} = "Rapur\/Podalakur\,\ Andhra\ Pradesh";
$areanames{en}->{918622} = "Kovvur\,\ Andhra\ Pradesh";
$areanames{en}->{918623} = "Sullurpet\,\ Andhra\ Pradesh";
$areanames{en}->{918624} = "Gudur\,\ Andhra\ Pradesh";
$areanames{en}->{918625} = "Venkatgiri\,\ Andhra\ Pradesh";
$areanames{en}->{918626} = "Kavali\,\ Andhra\ Pradesh";
$areanames{en}->{918627} = "Atmakur\,\ Andhra\ Pradesh";
$areanames{en}->{918628} = "Chejerla\,\ Andhra\ Pradesh";
$areanames{en}->{918629} = "Vinjamuru\,\ Andhra\ Pradesh";
$areanames{en}->{918630} = "Guntur\,\ Andhra\ Pradesh";
$areanames{en}->{918632} = "Guntur\,\ Andhra\ Pradesh";
$areanames{en}->{918633} = "Guntur\,\ Andhra\ Pradesh";
$areanames{en}->{918634} = "Guntur\,\ Andhra\ Pradesh";
$areanames{en}->{918635} = "Guntur\,\ Andhra\ Pradesh";
$areanames{en}->{918636} = "Guntur\,\ Andhra\ Pradesh";
$areanames{en}->{918637} = "Guntur\,\ Andhra\ Pradesh";
$areanames{en}->{918638} = "Guntur\,\ Andhra\ Pradesh";
$areanames{en}->{918639} = "Guntur\,\ Andhra\ Pradesh";
$areanames{en}->{918640} = "Krosuru\,\ Andhra\ Pradesh";
$areanames{en}->{918641} = "Sattenapalli\,\ Andhra\ Pradesh";
$areanames{en}->{918642} = "Guntur\ Palnad\/Macherala\,\ Andhra\ Pradesh";
$areanames{en}->{918643} = "Bapatla\,\ Andhra\ Pradesh";
$areanames{en}->{918644} = "Tenali\,\ Andhra\ Pradesh";
$areanames{en}->{918645} = "Mangalagiri\,\ Andhra\ Pradesh";
$areanames{en}->{918646} = "Vinukonda\,\ Andhra\ Pradesh";
$areanames{en}->{918647} = "Narsaraopet\,\ Andhra\ Pradesh";
$areanames{en}->{918648} = "Repalle\,\ Andhra\ Pradesh";
$areanames{en}->{918649} = "Piduguralla\,\ Andhra\ Pradesh";
$areanames{en}->{918654} = "Jaggayyapet\,\ Andhra\ Pradesh";
$areanames{en}->{918656} = "Nuzvidu\,\ Andhra\ Pradesh";
$areanames{en}->{918659} = "Mylavaram\,\ Andhra\ Pradesh";
$areanames{en}->{918660} = "Vijayawada\,\ Andhra\ Pradesh";
$areanames{en}->{918662} = "Vijayawada\,\ Andhra\ Pradesh";
$areanames{en}->{918663} = "Vijayawada\,\ Andhra\ Pradesh";
$areanames{en}->{918664} = "Vijayawada\,\ Andhra\ Pradesh";
$areanames{en}->{918665} = "Vijayawada\,\ Andhra\ Pradesh";
$areanames{en}->{918666} = "Vijayawada\,\ Andhra\ Pradesh";
$areanames{en}->{918667} = "Vijayawada\,\ Andhra\ Pradesh";
$areanames{en}->{918668} = "Vijayawada\,\ Andhra\ Pradesh";
$areanames{en}->{918669} = "Vijayawada\,\ Andhra\ Pradesh";
$areanames{en}->{918671} = "Divi\/Challapalli\,\ Andhra\ Pradesh";
$areanames{en}->{918672} = "Bandar\/Machilipatnam\,\ Andhra\ Pradesh";
$areanames{en}->{918673} = "Tirivuru\,\ Andhra\ Pradesh";
$areanames{en}->{918674} = "Gudivada\,\ Andhra\ Pradesh";
$areanames{en}->{918676} = "Vuyyuru\,\ Andhra\ Pradesh";
$areanames{en}->{918677} = "Kaikaluru\,\ Andhra\ Pradesh";
$areanames{en}->{918678} = "Nandigama\,\ Andhra\ Pradesh";
$areanames{en}->{918680} = "Nidamanur\/Hillcolony\,\ Andhra\ Pradesh";
$areanames{en}->{918681} = "Chandoor\,\ Andhra\ Pradesh";
$areanames{en}->{918682} = "Nalgonda\,\ Andhra\ Pradesh";
$areanames{en}->{918683} = "Hazurnagar\,\ Andhra\ Pradesh";
$areanames{en}->{918684} = "Suryapet\,\ Andhra\ Pradesh";
$areanames{en}->{918685} = "Bhongir\,\ Andhra\ Pradesh";
$areanames{en}->{918689} = "Miryalguda\,\ Andhra\ Pradesh";
$areanames{en}->{918691} = "Devarakonda\,\ Andhra\ Pradesh";
$areanames{en}->{918692} = "Nampalle\,\ Andhra\ Pradesh";
$areanames{en}->{918693} = "Thungaturthy\,\ Andhra\ Pradesh";
$areanames{en}->{918694} = "Ramannapet\,\ Andhra\ Pradesh";
$areanames{en}->{918700} = "Warangal\,\ Andhra\ Pradesh";
$areanames{en}->{918702} = "Warangal\,\ Andhra\ Pradesh";
$areanames{en}->{918703} = "Warangal\,\ Andhra\ Pradesh";
$areanames{en}->{918704} = "Warangal\,\ Andhra\ Pradesh";
$areanames{en}->{918705} = "Warangal\,\ Andhra\ Pradesh";
$areanames{en}->{918706} = "Warangal\,\ Andhra\ Pradesh";
$areanames{en}->{918707} = "Warangal\,\ Andhra\ Pradesh";
$areanames{en}->{918708} = "Warangal\,\ Andhra\ Pradesh";
$areanames{en}->{918709} = "Warangal\,\ Andhra\ Pradesh";
$areanames{en}->{918710} = "Cherial\,\ Andhra\ Pradesh";
$areanames{en}->{918711} = "Wardhannapet\/Ghanapur\,\ Andhra\ Pradesh";
$areanames{en}->{918713} = "Parkal\,\ Andhra\ Pradesh";
$areanames{en}->{918715} = "Mulug\,\ Andhra\ Pradesh";
$areanames{en}->{918716} = "Jangaon\,\ Andhra\ Pradesh";
$areanames{en}->{918717} = "Eturnagaram\,\ Andhra\ Pradesh";
$areanames{en}->{918718} = "Narasampet\,\ Andhra\ Pradesh";
$areanames{en}->{918719} = "Mahabubbad\,\ Andhra\ Pradesh";
$areanames{en}->{918720} = "Mahadevapur\,\ Andhra\ Pradesh";
$areanames{en}->{918721} = "Husnabad\,\ Andhra\ Pradesh";
$areanames{en}->{918723} = "Sircilla\,\ Andhra\ Pradesh";
$areanames{en}->{918724} = "Jagtial\,\ Andhra\ Pradesh";
$areanames{en}->{918725} = "Metpalli\,\ Andhra\ Pradesh";
$areanames{en}->{918727} = "Huzurabad\,\ Andhra\ Pradesh";
$areanames{en}->{918728} = "Peddapalli\,\ Andhra\ Pradesh";
$areanames{en}->{918729} = "Manthani\,\ Andhra\ Pradesh";
$areanames{en}->{918730} = "Khanapur\,\ Andhra\ Pradesh";
$areanames{en}->{918731} = "Utnor\,\ Andhra\ Pradesh";
$areanames{en}->{918732} = "Adilabad\,\ Andhra\ Pradesh";
$areanames{en}->{918733} = "Asifabad\,\ Andhra\ Pradesh";
$areanames{en}->{918734} = "Nirmal\,\ Andhra\ Pradesh";
$areanames{en}->{918735} = "Bellampalli\,\ Andhra\ Pradesh";
$areanames{en}->{918736} = "Mancherial\,\ Andhra\ Pradesh";
$areanames{en}->{918737} = "Chinnor\,\ Andhra\ Pradesh";
$areanames{en}->{918738} = "Sirpurkagaznagar\,\ Andhra\ Pradesh";
$areanames{en}->{918739} = "Jannaram\/Luxittipet\,\ Andhra\ Pradesh";
$areanames{en}->{918740} = "Aswaraopet\,\ Andhra\ Pradesh";
$areanames{en}->{918741} = "Sudhimalla\/Tekulapalli\,\ Andhra\ Pradesh";
$areanames{en}->{918742} = "Khammam\,\ Andhra\ Pradesh";
$areanames{en}->{918743} = "Bhadrachalam\,\ Andhra\ Pradesh";
$areanames{en}->{918744} = "Kothagudem\,\ Andhra\ Pradesh";
$areanames{en}->{918745} = "Yellandu\,\ Andhra\ Pradesh";
$areanames{en}->{918746} = "Bhooragamphad\/Manuguru\,\ Andhra\ Pradesh";
$areanames{en}->{918747} = "Nuguru\/Cherla\,\ Andhra\ Pradesh";
$areanames{en}->{918748} = "V\.R\.Puram\,\ Andhra\ Pradesh";
$areanames{en}->{918749} = "Madhira\,\ Andhra\ Pradesh";
$areanames{en}->{918751} = "Boath\/Echoda\,\ Andhra\ Pradesh";
$areanames{en}->{918752} = "Bhainsa\,\ Andhra\ Pradesh";
$areanames{en}->{918753} = "Outsarangapalle\,\ Andhra\ Pradesh";
$areanames{en}->{9187592} = "Outsarangapalle\,\ Andhra\ Pradesh";
$areanames{en}->{9187593} = "Outsarangapalle\,\ Andhra\ Pradesh";
$areanames{en}->{9187594} = "Outsarangapalle\,\ Andhra\ Pradesh";
$areanames{en}->{9187595} = "Outsarangapalle\,\ Andhra\ Pradesh";
$areanames{en}->{9187596} = "Outsarangapalle\,\ Andhra\ Pradesh";
$areanames{en}->{9187597} = "Outsarangapalle\,\ Andhra\ Pradesh";
$areanames{en}->{918761} = "Sathupalli\,\ Andhra\ Pradesh";
$areanames{en}->{918770} = "Tirupathi\,\ Andhra\ Pradesh";
$areanames{en}->{918772} = "Tirupathi\,\ Andhra\ Pradesh";
$areanames{en}->{918773} = "Tirupathi\,\ Andhra\ Pradesh";
$areanames{en}->{918774} = "Tirupathi\,\ Andhra\ Pradesh";
$areanames{en}->{918775} = "Tirupathi\,\ Andhra\ Pradesh";
$areanames{en}->{918776} = "Tirupathi\,\ Andhra\ Pradesh";
$areanames{en}->{918777} = "Tirupathi\,\ Andhra\ Pradesh";
$areanames{en}->{918778} = "Tirupathi\,\ Andhra\ Pradesh";
$areanames{en}->{918779} = "Tirupathi\,\ Andhra\ Pradesh";
$areanames{en}->{918780} = "Karimnagar\,\ Andhra\ Pradesh";
$areanames{en}->{918782} = "Karimnagar\,\ Andhra\ Pradesh";
$areanames{en}->{918783} = "Karimnagar\,\ Andhra\ Pradesh";
$areanames{en}->{918784} = "Karimnagar\,\ Andhra\ Pradesh";
$areanames{en}->{918785} = "Karimnagar\,\ Andhra\ Pradesh";
$areanames{en}->{918786} = "Karimnagar\,\ Andhra\ Pradesh";
$areanames{en}->{918787} = "Karimnagar\,\ Andhra\ Pradesh";
$areanames{en}->{918788} = "Karimnagar\,\ Andhra\ Pradesh";
$areanames{en}->{918789} = "Karimnagar\,\ Andhra\ Pradesh";
$areanames{en}->{918811} = "Polavaram\,\ Andhra\ Pradesh";
$areanames{en}->{918812} = "Eluru\,\ Andhra\ Pradesh";
$areanames{en}->{918813} = "Eluru\ Kovvur\/Nidadavolu\,\ Andhra\ Pradesh";
$areanames{en}->{918814} = "Eluru\ Narsapur\/Palakole\,\ Andhra\ Pradesh";
$areanames{en}->{918816} = "Bhimavaram\,\ Andhra\ Pradesh";
$areanames{en}->{918818} = "Tadepalligudem\,\ Andhra\ Pradesh";
$areanames{en}->{918819} = "Tanuku\,\ Andhra\ Pradesh";
$areanames{en}->{918821} = "Jangareddygudem\,\ Andhra\ Pradesh";
$areanames{en}->{918823} = "Chintalapudi\,\ Andhra\ Pradesh";
$areanames{en}->{918829} = "Bhimadole\,\ Andhra\ Pradesh";
$areanames{en}->{918830} = "Rajahmundri\,\ Andhra\ Pradesh";
$areanames{en}->{918832} = "Rajahmundri\,\ Andhra\ Pradesh";
$areanames{en}->{918833} = "Rajahmundri\,\ Andhra\ Pradesh";
$areanames{en}->{918834} = "Rajahmundri\,\ Andhra\ Pradesh";
$areanames{en}->{918835} = "Rajahmundri\,\ Andhra\ Pradesh";
$areanames{en}->{918836} = "Rajahmundri\,\ Andhra\ Pradesh";
$areanames{en}->{918837} = "Rajahmundri\,\ Andhra\ Pradesh";
$areanames{en}->{918838} = "Rajahmundri\,\ Andhra\ Pradesh";
$areanames{en}->{918839} = "Rajahmundri\,\ Andhra\ Pradesh";
$areanames{en}->{918840} = "Kakinada\,\ Andhra\ Pradesh";
$areanames{en}->{918842} = "Kakinada\,\ Andhra\ Pradesh";
$areanames{en}->{918843} = "Kakinada\,\ Andhra\ Pradesh";
$areanames{en}->{918844} = "Kakinada\,\ Andhra\ Pradesh";
$areanames{en}->{918845} = "Kakinada\,\ Andhra\ Pradesh";
$areanames{en}->{918846} = "Kakinada\,\ Andhra\ Pradesh";
$areanames{en}->{918847} = "Kakinada\,\ Andhra\ Pradesh";
$areanames{en}->{918848} = "Kakinada\,\ Andhra\ Pradesh";
$areanames{en}->{918849} = "Kakinada\,\ Andhra\ Pradesh";
$areanames{en}->{918852} = "Peddapuram\,\ Andhra\ Pradesh";
$areanames{en}->{918854} = "Tuni\,\ Andhra\ Pradesh";
$areanames{en}->{918855} = "Mandapeta\/Ravulapalem\,\ Andhra\ Pradesh";
$areanames{en}->{918856} = "Amalapuram\,\ Andhra\ Pradesh";
$areanames{en}->{918857} = "Ramachandrapuram\,\ Andhra\ Pradesh";
$areanames{en}->{918862} = "Razole\,\ Andhra\ Pradesh";
$areanames{en}->{918863} = "Chavitidibbalu\,\ Andhra\ Pradesh";
$areanames{en}->{918864} = "Rampachodavaram\,\ Andhra\ Pradesh";
$areanames{en}->{918865} = "Yelavaram\,\ Andhra\ Pradesh";
$areanames{en}->{918868} = "Yeleswaram\,\ Andhra\ Pradesh";
$areanames{en}->{918869} = "Pithapuram\,\ Andhra\ Pradesh";
$areanames{en}->{918910} = "Visakhapatnam\,\ Andhra\ Pradesh";
$areanames{en}->{918912} = "Visakhapatnam\,\ Andhra\ Pradesh";
$areanames{en}->{918913} = "Visakhapatnam\,\ Andhra\ Pradesh";
$areanames{en}->{918914} = "Visakhapatnam\,\ Andhra\ Pradesh";
$areanames{en}->{918915} = "Visakhapatnam\,\ Andhra\ Pradesh";
$areanames{en}->{918916} = "Visakhapatnam\,\ Andhra\ Pradesh";
$areanames{en}->{918917} = "Visakhapatnam\,\ Andhra\ Pradesh";
$areanames{en}->{918918} = "Visakhapatnam\,\ Andhra\ Pradesh";
$areanames{en}->{918919} = "Visakhapatnam\,\ Andhra\ Pradesh";
$areanames{en}->{918922} = "Vizayanagaram\,\ Andhra\ Pradesh";
$areanames{en}->{918924} = "Anakapalle\,\ Andhra\ Pradesh";
$areanames{en}->{918931} = "Yelamanchili\,\ Andhra\ Pradesh";
$areanames{en}->{918932} = "Narsipatnam\,\ Andhra\ Pradesh";
$areanames{en}->{918933} = "Bheemunipatnam\,\ Andhra\ Pradesh";
$areanames{en}->{918934} = "Chodavaram\,\ Andhra\ Pradesh";
$areanames{en}->{918935} = "Paderu\,\ Andhra\ Pradesh";
$areanames{en}->{918936} = "Araku\,\ Andhra\ Pradesh";
$areanames{en}->{918937} = "Chintapalle\,\ Andhra\ Pradesh";
$areanames{en}->{918938} = "Sileru\,\ Andhra\ Pradesh";
$areanames{en}->{918941} = "Palakonda\/Rajam\,\ Andhra\ Pradesh";
$areanames{en}->{918942} = "Srikakulam\,\ Andhra\ Pradesh";
$areanames{en}->{918944} = "Bobbili\,\ Andhra\ Pradesh";
$areanames{en}->{918945} = "Tekkali\/Palasa\,\ Andhra\ Pradesh";
$areanames{en}->{9189460} = "Pathapatnam\/Hiramandalam\,\ Andhra\ Pradesh";
$areanames{en}->{9189461} = "Pathapatnam\/Hiramandalam\,\ Andhra\ Pradesh";
$areanames{en}->{9189462} = "Pathapatnam\/Hiramandalam\,\ Andhra\ Pradesh";
$areanames{en}->{9189463} = "Pathapatnam\/Hiramandalam\,\ Andhra\ Pradesh";
$areanames{en}->{9189464} = "Pathapatnam\/Hiramandalam\,\ Andhra\ Pradesh";
$areanames{en}->{9189465} = "Pathapatnam\/Hiramandalam\,\ Andhra\ Pradesh";
$areanames{en}->{9189466} = "Pathapatnam\/Hiramandalam\,\ Andhra\ Pradesh";
$areanames{en}->{9189467} = "Pathapatnam\/Hiramandalam\,\ Andhra\ Pradesh";
$areanames{en}->{918947} = "Sompeta\,\ Andhra\ Pradesh";
$areanames{en}->{918952} = "Chepurupalli\/Garividi\,\ Andhra\ Pradesh";
$areanames{en}->{918963} = "Parvathipuram\,\ Andhra\ Pradesh";
$areanames{en}->{918964} = "Saluru\,\ Andhra\ Pradesh";
$areanames{en}->{918965} = "Gajapathinagaram\,\ Andhra\ Pradesh";
$areanames{en}->{918966} = "Srungavarapukota\/Kothavalasa\,\ Andhra\ Pradesh";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+91|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;