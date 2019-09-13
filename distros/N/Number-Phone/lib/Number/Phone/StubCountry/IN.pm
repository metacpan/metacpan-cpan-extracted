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
our $VERSION = 1.20190912215426;

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
              [2-4]1|
              5[17]|
              6[13]|
              7[14]|
              80
            )|
            7(?:
              12|
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
              1(?:
                29|
                60|
                8[06]
              )|
              261|
              552|
              788[01]
            )[2-7]|
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
            )
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
              1[1358]|
              2(?:
                [2457]|
                84|
                95
              )|
              3(?:
                [2-4]|
                55
              )|
              [4-8]
            )|
            7(?:
              1(?:
                [013-8]|
                9[6-9]
              )|
              3179
            )|
            807(?:
              1|
              9[1-3]
            )|
            (?:
              1552|
              7(?:
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
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '18',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          782[0-6][2-7]\\d{5}|
          (?:
            170[24]|
            2(?:
              80[13468]|
              90\\d
            )|
            380\\d|
            4(?:
              20[24]|
              72[2-8]
            )|
            552[1-7]
          )\\d{6}|
          (?:
            342|
            674|
            788
          )(?:
            [0189][2-7]|
            [2-7]\\d
          )\\d{5}|
          (?:
            11|
            2[02]|
            33|
            4[04]|
            79|
            80
          )[2-7]\\d{7}|
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
              7[13-79]|
              8[2-479]|
              9[235-9]
            )|
            3(?:
              01|
              1[79]|
              2[1-5]|
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
              8[1-6]
            )|
            7(?:
              1[013-9]|
              2[0235-9]|
              3[2679]|
              4[1-35689]|
              5[2-46-9]|
              [67][02-9]|
              8[013-7]|
              9[0189]
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
          782[0-6][2-7]\\d{5}|
          (?:
            170[24]|
            2(?:
              80[13468]|
              90\\d
            )|
            380\\d|
            4(?:
              20[24]|
              72[2-8]
            )|
            552[1-7]
          )\\d{6}|
          (?:
            342|
            674|
            788
          )(?:
            [0189][2-7]|
            [2-7]\\d
          )\\d{5}|
          (?:
            11|
            2[02]|
            33|
            4[04]|
            79|
            80
          )[2-7]\\d{7}|
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
              7[13-79]|
              8[2-479]|
              9[235-9]
            )|
            3(?:
              01|
              1[79]|
              2[1-5]|
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
              8[1-6]
            )|
            7(?:
              1[013-9]|
              2[0235-9]|
              3[2679]|
              4[1-35689]|
              5[2-46-9]|
              [67][02-9]|
              8[013-7]|
              9[0189]
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
            6(?:
              1279|
              350[0-6]
            )|
            7(?:
              3(?:
                1(?:
                  11|
                  7[02-8]
                )|
                411
              )|
              4[47](?:
                11|
                7[02-8]
              )|
              5111|
              700[02-9]|
              88(?:
                11|
                7[02-9]
              )|
              9(?:
                313|
                79[07-9]
              )
            )|
            8(?:
              079[04-9]|
              (?:
                16|
                2[014]|
                3[126]|
                6[136]|
                7[78]|
                8[34]|
                91
              )7[02-8]
            )
          )\\d{5}|
          7(?:
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
            70[13-7]
          )[089]\\d{5}|
          (?:
            6(?:
              0(?:
                0[0-3569]|
                26|
                33
              )|
              2(?:
                [06]\\d|
                3[02589]|
                8[0-479]|
                9[0-79]
              )|
              3(?:
                0[0-79]|
                5[1-9]|
                6[0-4679]|
                7[0-24-9]|
                [89]\\d
              )|
              9(?:
                0[019]|
                13
              )
            )|
            7(?:
              0\\d\\d|
              19[0-5]|
              2(?:
                [0235-79]\\d|
                [14][017-9]|
                8[0-59]
              )|
              3(?:
                [05-8]\\d|
                1[089]|
                2[5-8]|
                3[017-9]|
                4[07-9]|
                9[016-9]
              )|
              4(?:
                0\\d|
                1[015-9]|
                [29][89]|
                39|
                [47][089]|
                8[389]
              )|
              5(?:
                [0346-8]\\d|
                1[07-9]|
                2[04-9]|
                5[017-9]|
                9[7-9]
              )|
              6(?:
                0[0-47]|
                1[0-257-9]|
                2[0-4]|
                3[19]|
                5[4589]|
                [6-9]\\d
              )|
              7(?:
                0[289]|
                [1-9]\\d
              )|
              8(?:
                [0-79]\\d|
                8[089]
              )|
              9(?:
                [089]\\d|
                7[02-8]
              )
            )|
            8(?:
              0(?:
                [01589]\\d|
                6[67]|
                7[02-8]
              )|
              1(?:
                [0-57-9]\\d|
                6[089]
              )|
              2(?:
                [014][089]|
                [235-9]\\d
              )|
              3(?:
                [03-57-9]\\d|
                [126][089]
              )|
              [45]\\d\\d|
              6(?:
                [02457-9]\\d|
                [136][089]
              )|
              7(?:
                0[07-9]|
                [1-69]\\d|
                [78][089]
              )|
              8(?:
                [0-25-9]\\d|
                3[089]|
                4[0489]
              )|
              9(?:
                [02-9]\\d|
                1[0289]
              )
            )|
            9\\d{3}
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(1860\\d{7})|(186[12]\\d{9})|(140\\d{7})',
                'toll_free' => '
          00800\\d{7}|
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
$areanames{en}->{9120} = "Pune\,\ Maharashtra";
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
$areanames{en}->{9122} = "Mumbai";
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
$areanames{en}->{912717} = "Sanand\,\ Gujarat";
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
$areanames{en}->{916111} = "Hilsa\,\ Bihar";
$areanames{en}->{916112} = "Biharsharif\,\ Bihar";
$areanames{en}->{916114} = "Jahanabad\,\ Bihar";
$areanames{en}->{916115} = "Danapur\,\ Bihar";
$areanames{en}->{91612} = "Patna\,\ Bihar";
$areanames{en}->{916132} = "Barh\,\ Bihar";
$areanames{en}->{916135} = "Bikram\,\ Bihar";
$areanames{en}->{916150} = "Hathua\,\ Bihar";
$areanames{en}->{916151} = "Sidhawalia\,\ Bihar";
$areanames{en}->{916152} = "Chapra\,\ Bihar";
$areanames{en}->{916153} = "Maharajganj\,\ Bihar";
$areanames{en}->{916154} = "Siwan\,\ Bihar";
$areanames{en}->{916155} = "Ekma\,\ Bihar";
$areanames{en}->{916156} = "Gopalganj\,\ Bihar";
$areanames{en}->{916157} = "Mairwa\,\ Bihar";
$areanames{en}->{916158} = "Sonepur\,\ Bihar";
$areanames{en}->{916159} = "Masrakh\,\ Bihar";
$areanames{en}->{916180} = "Adhaura\,\ Bihar";
$areanames{en}->{916181} = "Piro\,\ Bihar";
$areanames{en}->{916182} = "Arrah\,\ Bihar";
$areanames{en}->{916183} = "Buxar\,\ Bihar";
$areanames{en}->{916184} = "Sasaram\,\ Bihar";
$areanames{en}->{916185} = "Bikramganj\,\ Bihar";
$areanames{en}->{916186} = "Aurangabad\,\ Bihar";
$areanames{en}->{916187} = "Mohania\,\ Bihar";
$areanames{en}->{916188} = "Rohtas\,\ Bihar";
$areanames{en}->{916189} = "Bhabhua\,\ Bihar";
$areanames{en}->{91621} = "Muzaffarpur\,\ Bihar";
$areanames{en}->{916222} = "Sheohar\,\ Bihar";
$areanames{en}->{916223} = "Motipur\,\ Bihar";
$areanames{en}->{916224} = "Hajipur\,\ Bihar";
$areanames{en}->{916226} = "Sitamarhi\,\ Bihar";
$areanames{en}->{916227} = "Mahua\,\ Bihar";
$areanames{en}->{916228} = "Pupri\,\ Bihar";
$areanames{en}->{916229} = "Bidupur\,\ Bihar";
$areanames{en}->{916242} = "Benipur\,\ Bihar";
$areanames{en}->{916243} = "Begusarai\,\ Bihar";
$areanames{en}->{916244} = "Khagaria\,\ Bihar";
$areanames{en}->{916245} = "Gogri\,\ Bihar";
$areanames{en}->{916246} = "Jainagar\,\ Bihar";
$areanames{en}->{916247} = "Singhwara\,\ Bihar";
$areanames{en}->{916250} = "Dhaka\,\ Bihar";
$areanames{en}->{916251} = "Bagaha\,\ Bihar";
$areanames{en}->{916252} = "Motihari\,\ Bihar";
$areanames{en}->{916253} = "Narkatiaganj\,\ Bihar";
$areanames{en}->{916254} = "Bettiah\,\ Bihar";
$areanames{en}->{916255} = "Raxaul\,\ Bihar";
$areanames{en}->{916256} = "Ramnagar\,\ Bihar";
$areanames{en}->{916257} = "Barachakia\,\ Bihar";
$areanames{en}->{916258} = "Areraj\,\ Bihar";
$areanames{en}->{916259} = "Pakridayal\,\ Bihar";
$areanames{en}->{916271} = "Benipatti\,\ Bihar";
$areanames{en}->{916272} = "Darbhanga\,\ Bihar";
$areanames{en}->{916273} = "Jhajharpur\,\ Bihar";
$areanames{en}->{916274} = "Samastipur\,\ Bihar";
$areanames{en}->{916275} = "Rosera\,\ Bihar";
$areanames{en}->{916276} = "Madhubani\,\ Bihar";
$areanames{en}->{916277} = "Phulparas\,\ Bihar";
$areanames{en}->{916278} = "Dalsinghsarai\,\ Bihar";
$areanames{en}->{916279} = "Barauni\,\ Bihar";
$areanames{en}->{91631} = "Gaya\,\ Bihar";
$areanames{en}->{916322} = "Wazirganj\,\ Bihar";
$areanames{en}->{916323} = "Dumraon\,\ Bihar";
$areanames{en}->{916324} = "Nawada\,\ Bihar";
$areanames{en}->{916325} = "Pakribarwan\,\ Bihar";
$areanames{en}->{916326} = "Sherghati\,\ Bihar";
$areanames{en}->{916327} = "Rafiganj\,\ Bihar";
$areanames{en}->{916328} = "Daudnagar\,\ Bihar";
$areanames{en}->{916331} = "Imamganj\,\ Bihar";
$areanames{en}->{916332} = "Nabinagar\,\ Bihar";
$areanames{en}->{916336} = "Rajauli\,\ Bihar";
$areanames{en}->{916337} = "Arwal\,\ Bihar";
$areanames{en}->{916341} = "Seikhpura\,\ Bihar";
$areanames{en}->{916342} = "H\.Kharagpur\,\ Bihar";
$areanames{en}->{916344} = "Monghyr\,\ Bihar";
$areanames{en}->{916345} = "Jamui\,\ Bihar";
$areanames{en}->{916346} = "Lakhisarai\,\ Bihar";
$areanames{en}->{916347} = "Chakai\,\ Bihar";
$areanames{en}->{916348} = "Mallehpur\,\ Bihar";
$areanames{en}->{916349} = "Jhajha\,\ Bihar";
$areanames{en}->{91641} = "Bhagalpur\,\ Bihar";
$areanames{en}->{916420} = "Amarpur\,\ Bihar";
$areanames{en}->{916421} = "Naugachia\,\ Bihar";
$areanames{en}->{916422} = "Godda\,\ Bihar";
$areanames{en}->{916423} = "Maheshpur\ Raj\,\ Bihar";
$areanames{en}->{916424} = "Banka\,\ Bihar";
$areanames{en}->{916425} = "Katoria\,\ Bihar";
$areanames{en}->{916426} = "Rajmahal\,\ Bihar";
$areanames{en}->{916427} = "Kathikund\,\ Bihar";
$areanames{en}->{916428} = "Nala\,\ Bihar";
$areanames{en}->{916429} = "Kahalgaon\,\ Bihar";
$areanames{en}->{916431} = "Jharmundi\,\ Bihar";
$areanames{en}->{916432} = "Deoghar\,\ Bihar";
$areanames{en}->{916433} = "Jamtara\,\ Bihar";
$areanames{en}->{916434} = "Dumka\,\ Bihar";
$areanames{en}->{916435} = "Pakur\,\ Bihar";
$areanames{en}->{916436} = "Sahibganj\,\ Bihar";
$areanames{en}->{916437} = "Mahagama\,\ Bihar";
$areanames{en}->{916438} = "Madhupur\,\ Bihar";
$areanames{en}->{916451} = "Barsoi\,\ Bihar";
$areanames{en}->{916452} = "Katihar\,\ Bihar";
$areanames{en}->{916453} = "Araria\,\ Bihar";
$areanames{en}->{916454} = "Purnea\,\ Bihar";
$areanames{en}->{916455} = "Forbesganj\,\ Bihar";
$areanames{en}->{916457} = "Korha\,\ Bihar";
$areanames{en}->{916459} = "Thakurganj\,\ Bihar";
$areanames{en}->{916461} = "Raniganj\,\ Bihar";
$areanames{en}->{916462} = "Dhamdaha\,\ Bihar";
$areanames{en}->{916466} = "Kishanganj\,\ Bihar";
$areanames{en}->{916467} = "Banmankhi\,\ Bihar";
$areanames{en}->{916471} = "Birpur\,\ Bihar";
$areanames{en}->{916473} = "Supaul\,\ Bihar";
$areanames{en}->{916475} = "S\.Bakhtiarpur\,\ Bihar";
$areanames{en}->{916476} = "Madhepura\,\ Bihar";
$areanames{en}->{916477} = "Triveniganj\,\ Bihar";
$areanames{en}->{916478} = "Saharsa\,\ Bihar";
$areanames{en}->{916479} = "Udakishanganj\,\ Bihar";
$areanames{en}->{91651} = "Ranchi\,\ Bihar";
$areanames{en}->{916522} = "Muri\,\ Bihar";
$areanames{en}->{916523} = "Ghaghra\,\ Bihar";
$areanames{en}->{916524} = "Gumla\,\ Bihar";
$areanames{en}->{916525} = "Simdega\,\ Bihar";
$areanames{en}->{916526} = "Lohardaga\,\ Bihar";
$areanames{en}->{916527} = "Kolebira\,\ Bihar";
$areanames{en}->{916528} = "Khunti\,\ Bihar";
$areanames{en}->{916529} = "Itki\,\ Bihar";
$areanames{en}->{916530} = "Bundu\,\ Bihar";
$areanames{en}->{916531} = "Mandar\,\ Bihar";
$areanames{en}->{916532} = "Giridih\,\ Bihar";
$areanames{en}->{916533} = "Basia\,\ Bihar";
$areanames{en}->{916534} = "Jhumaritalaiya\,\ Bihar";
$areanames{en}->{916535} = "Chainpur\,\ Bihar";
$areanames{en}->{916536} = "Palkot\,\ Bihar";
$areanames{en}->{916538} = "Torpa\,\ Bihar";
$areanames{en}->{916539} = "Bolwa\,\ Bihar";
$areanames{en}->{916540} = "Govindpur\,\ Bihar";
$areanames{en}->{916541} = "Chatra\,\ Bihar";
$areanames{en}->{916542} = "Bokaro\,\ Bihar";
$areanames{en}->{916543} = "Barhi\,\ Bihar";
$areanames{en}->{916544} = "Gomia\,\ Bihar";
$areanames{en}->{916545} = "Mandu\,\ Bihar";
$areanames{en}->{916546} = "Hazaribagh\,\ Bihar";
$areanames{en}->{916547} = "Chavparan\,\ Bihar";
$areanames{en}->{916548} = "Ichak\,\ Bihar";
$areanames{en}->{916549} = "Bermo\,\ Bihar";
$areanames{en}->{916550} = "Hunterganj\,\ Bihar";
$areanames{en}->{916551} = "Barkagaon\,\ Bihar";
$areanames{en}->{916553} = "Ramgarh\,\ Bihar";
$areanames{en}->{916554} = "Rajdhanwar\,\ Bihar";
$areanames{en}->{916556} = "Tisri\,\ Bihar";
$areanames{en}->{916557} = "Bagodar\,\ Bihar";
$areanames{en}->{916558} = "Dumri\(Isribazar\)\,\ Bihar";
$areanames{en}->{916559} = "Simaria\,\ Bihar";
$areanames{en}->{916560} = "Patan\,\ Bihar";
$areanames{en}->{916561} = "Garhwa\,\ Bihar";
$areanames{en}->{916562} = "Daltonganj\,\ Bihar";
$areanames{en}->{916563} = "Bhawanathpur\,\ Bihar";
$areanames{en}->{916564} = "Nagarutari\,\ Bihar";
$areanames{en}->{916565} = "Latehar\,\ Bihar";
$areanames{en}->{916566} = "Japla\,\ Bihar";
$areanames{en}->{916567} = "Barwadih\,\ Bihar";
$areanames{en}->{916568} = "Balumath\,\ Bihar";
$areanames{en}->{916569} = "Garu\,\ Bihar";
$areanames{en}->{91657} = "Jamshedpur\,\ Bihar";
$areanames{en}->{916581} = "Bhandaria\,\ Bihar";
$areanames{en}->{916582} = "Chaibasa\,\ Bihar";
$areanames{en}->{916583} = "Kharsawa\,\ Bihar";
$areanames{en}->{916584} = "Bishrampur\,\ Bihar";
$areanames{en}->{916585} = "Ghatsila\,\ Bihar";
$areanames{en}->{916586} = "Chainpur\,\ Bihar";
$areanames{en}->{916587} = "Chakardharpur\,\ Bihar";
$areanames{en}->{916588} = "Jagarnathpur\,\ Bihar";
$areanames{en}->{916589} = "Jhinkpani\,\ Bihar";
$areanames{en}->{916591} = "Chandil\,\ Bihar";
$areanames{en}->{916593} = "Manoharpur\,\ Bihar";
$areanames{en}->{916594} = "Baharagora\,\ Bihar";
$areanames{en}->{916596} = "Noamundi\,\ Bihar";
$areanames{en}->{916597} = "Saraikela\/Adstyapur\,\ Bihar";
$areanames{en}->{91661} = "Rourkela\,\ Odisha";
$areanames{en}->{916621} = "Hemgiri\,\ Odisha";
$areanames{en}->{916622} = "Sundargarh\,\ Odisha";
$areanames{en}->{916624} = "Rajgangpur\,\ Odisha";
$areanames{en}->{916625} = "Lahunipara\,\ Odisha";
$areanames{en}->{916626} = "Banaigarh\,\ Odisha";
$areanames{en}->{91663} = "Sambalpur\,\ Odisha";
$areanames{en}->{916640} = "Bagdihi\,\ Odisha";
$areanames{en}->{916641} = "Deodgarh\,\ Odisha";
$areanames{en}->{916642} = "Kuchinda\,\ Odisha";
$areanames{en}->{916643} = "Barkot\,\ Odisha";
$areanames{en}->{916644} = "Rairakhol\,\ Odisha";
$areanames{en}->{916645} = "Jharsuguda\,\ Odisha";
$areanames{en}->{916646} = "Bargarh\,\ Odisha";
$areanames{en}->{916647} = "Naktideul\,\ Odisha";
$areanames{en}->{916648} = "Patnagarh\,\ Odisha";
$areanames{en}->{916649} = "Jamankira\,\ Odisha";
$areanames{en}->{916651} = "Birmaharajpur\,\ Odisha";
$areanames{en}->{916652} = "Balangir\,\ Odisha";
$areanames{en}->{916653} = "Dunguripali\,\ Odisha";
$areanames{en}->{916654} = "Sonapur\,\ Odisha";
$areanames{en}->{916655} = "Titlagarh\,\ Odisha";
$areanames{en}->{916657} = "Kantabhanji\,\ Odisha";
$areanames{en}->{916670} = "Bhawanipatna\,\ Odisha";
$areanames{en}->{916671} = "Rajkhariar\,\ Odisha";
$areanames{en}->{916672} = "Dharamgarh\,\ Odisha";
$areanames{en}->{916673} = "Jayapatna\,\ Odisha";
$areanames{en}->{916675} = "T\.Rampur\,\ Odisha";
$areanames{en}->{916676} = "M\.Rampur\,\ Odisha";
$areanames{en}->{916677} = "Narlaroad\,\ Odisha";
$areanames{en}->{916678} = "Nowparatan\,\ Odisha";
$areanames{en}->{916679} = "Komana\,\ Odisha";
$areanames{en}->{916681} = "Jujumura\,\ Odisha";
$areanames{en}->{916682} = "Attabira\,\ Odisha";
$areanames{en}->{916683} = "Padmapur\,\ Odisha";
$areanames{en}->{916684} = "Paikamal\,\ Odisha";
$areanames{en}->{916685} = "Sohela\,\ Odisha";
$areanames{en}->{91671} = "Cuttack\,\ Odisha";
$areanames{en}->{916721} = "Narsinghpur\,\ Odisha";
$areanames{en}->{916722} = "Pardip\,\ Odisha";
$areanames{en}->{916723} = "Athgarh\,\ Odisha";
$areanames{en}->{916724} = "Jagatsinghpur\,\ Odisha";
$areanames{en}->{916725} = "Dhanmandal\,\ Odisha";
$areanames{en}->{916726} = "Jajapur\ Road\,\ Odisha";
$areanames{en}->{916727} = "Kendrapara\,\ Odisha";
$areanames{en}->{916728} = "Jajapur\ Town\,\ Odisha";
$areanames{en}->{916729} = "Pattamundai\,\ Odisha";
$areanames{en}->{916731} = "Anandapur\,\ Odisha";
$areanames{en}->{916732} = "Hindol\,\ Odisha";
$areanames{en}->{916733} = "Ghatgaon\,\ Odisha";
$areanames{en}->{916735} = "Telkoi\,\ Odisha";
$areanames{en}->{91674} = "Bhubaneshwar\,\ Odisha";
$areanames{en}->{916752} = "Puri\,\ Odisha";
$areanames{en}->{916753} = "Nayagarh\,\ Odisha";
$areanames{en}->{916755} = "Khurda\,\ Odisha";
$areanames{en}->{916756} = "Balugaon\,\ Odisha";
$areanames{en}->{916757} = "Daspalla\,\ Odisha";
$areanames{en}->{916758} = "Nimapara\,\ Odisha";
$areanames{en}->{916760} = "Talcher\,\ Odisha";
$areanames{en}->{916761} = "Chhendipada\,\ Odisha";
$areanames{en}->{916762} = "Dhenkanal\,\ Odisha";
$areanames{en}->{916763} = "Athmallik\,\ Odisha";
$areanames{en}->{916764} = "Anugul\,\ Odisha";
$areanames{en}->{916765} = "Palla\ Hara\,\ Odisha";
$areanames{en}->{916766} = "Keonjhar\,\ Odisha";
$areanames{en}->{916767} = "Barbil\,\ Odisha";
$areanames{en}->{916768} = "Parajang\,\ Odisha";
$areanames{en}->{916769} = "Kamakhyanagar\,\ Odisha";
$areanames{en}->{916781} = "Basta\,\ Odisha";
$areanames{en}->{916782} = "Balasore\,\ Odisha";
$areanames{en}->{916784} = "Bhadrak\,\ Odisha";
$areanames{en}->{916786} = "Chandbali\,\ Odisha";
$areanames{en}->{916788} = "Soro\,\ Odisha";
$areanames{en}->{916791} = "Bangiriposi\,\ Odisha";
$areanames{en}->{916792} = "Baripada\,\ Odisha";
$areanames{en}->{916793} = "Betanati\,\ Odisha";
$areanames{en}->{916794} = "Rairangpur\,\ Odisha";
$areanames{en}->{916795} = "Udala\,\ Odisha";
$areanames{en}->{916796} = "Karanjia\,\ Odisha";
$areanames{en}->{916797} = "Jashipur\,\ Odisha";
$areanames{en}->{91680} = "Berhampur\,\ Odisha";
$areanames{en}->{916810} = "Khalikote\,\ Odisha";
$areanames{en}->{916811} = "Chhatrapur\,\ Odisha";
$areanames{en}->{916814} = "Digapahandi\,\ Odisha";
$areanames{en}->{916815} = "Parlakhemundi\,\ Odisha";
$areanames{en}->{916816} = "Mohana\,\ Odisha";
$areanames{en}->{916817} = "R\.Udayigiri\,\ Odisha";
$areanames{en}->{916818} = "Buguda\,\ Odisha";
$areanames{en}->{916819} = "Surada\,\ Odisha";
$areanames{en}->{916821} = "Bhanjanagar\,\ Odisha";
$areanames{en}->{916822} = "Aska\,\ Odisha";
$areanames{en}->{916840} = "Tumudibandha\,\ Odisha";
$areanames{en}->{916841} = "Boudh\,\ Odisha";
$areanames{en}->{916842} = "Phulbani\,\ Odisha";
$areanames{en}->{916843} = "Puruna\ Katak\,\ Odisha";
$areanames{en}->{916844} = "Kantamal\,\ Odisha";
$areanames{en}->{916845} = "Phiringia\,\ Odisha";
$areanames{en}->{916846} = "Baliguda\,\ Odisha";
$areanames{en}->{916847} = "G\.Udayagiri\,\ Odisha";
$areanames{en}->{916848} = "Kotagarh\,\ Odisha";
$areanames{en}->{916849} = "Daringbadi\,\ Odisha";
$areanames{en}->{916850} = "Kalimela\,\ Odisha";
$areanames{en}->{916852} = "Koraput\,\ Odisha";
$areanames{en}->{916853} = "Sunabeda\,\ Odisha";
$areanames{en}->{916854} = "Jeypore\,\ Odisha";
$areanames{en}->{916855} = "Laxmipur\,\ Odisha";
$areanames{en}->{916856} = "Rayagada\,\ Odisha";
$areanames{en}->{916857} = "Gunupur\,\ Odisha";
$areanames{en}->{916858} = "Nowrangapur\,\ Odisha";
$areanames{en}->{916859} = "Motu\,\ Odisha";
$areanames{en}->{916860} = "Boriguma\,\ Odisha";
$areanames{en}->{916861} = "Malkangiri\,\ Odisha";
$areanames{en}->{916862} = "Gudari\,\ Odisha";
$areanames{en}->{916863} = "Bisam\ Cuttack\,\ Odisha";
$areanames{en}->{916864} = "Mathili\,\ Odisha";
$areanames{en}->{916865} = "Kashipur\,\ Odisha";
$areanames{en}->{916866} = "Umerkote\,\ Odisha";
$areanames{en}->{916867} = "Jharigan\,\ Odisha";
$areanames{en}->{916868} = "Nandapur\,\ Odisha";
$areanames{en}->{916869} = "Papadhandi\,\ Odisha";
$areanames{en}->{917100} = "Kuhi\,\ Maharashtra";
$areanames{en}->{917102} = "Parseoni\,\ Maharashtra";
$areanames{en}->{917103} = "Butibori\,\ Maharashtra";
$areanames{en}->{917104} = "Hingua\,\ Maharashtra";
$areanames{en}->{917105} = "Narkhed\,\ Maharashtra";
$areanames{en}->{917106} = "Bhiwapur\,\ Maharashtra";
$areanames{en}->{917109} = "Kamptee\,\ Maharashtra";
$areanames{en}->{917112} = "Katol\,\ Maharashtra";
$areanames{en}->{917113} = "Saoner\,\ Maharashtra";
$areanames{en}->{917114} = "Ramtek\,\ Maharashtra";
$areanames{en}->{917115} = "Mouda\,\ Maharashtra";
$areanames{en}->{917116} = "Umrer\,\ Maharashtra";
$areanames{en}->{917118} = "Kalmeshwar\,\ Maharashtra";
$areanames{en}->{91712} = "Nagpur\,\ Maharashtra";
$areanames{en}->{917131} = "Sironcha\,\ Maharashtra";
$areanames{en}->{917132} = "Gadchiroli\,\ Maharashtra";
$areanames{en}->{917133} = "Aheri\,\ Maharashtra";
$areanames{en}->{917134} = "Bhamregadh\,\ Maharashtra";
$areanames{en}->{917135} = "Chamorshi\,\ Maharashtra";
$areanames{en}->{917136} = "Etapalli\,\ Maharashtra";
$areanames{en}->{917137} = "Desaiganj\,\ Maharashtra";
$areanames{en}->{917138} = "Dhanora\,\ Maharashtra";
$areanames{en}->{917139} = "Kurkheda\,\ Maharashtra";
$areanames{en}->{917141} = "Betul\,\ Madhya\ Pradesh";
$areanames{en}->{917142} = "Bhimpur\,\ Madhya\ Pradesh";
$areanames{en}->{917143} = "Bhainsdehi\,\ Madhya\ Pradesh";
$areanames{en}->{917144} = "Atner\,\ Madhya\ Pradesh";
$areanames{en}->{917145} = "Chicholi\,\ Madhya\ Pradesh";
$areanames{en}->{917146} = "Ghorandogri\,\ Madhya\ Pradesh";
$areanames{en}->{917147} = "Multai\,\ Madhya\ Pradesh";
$areanames{en}->{917148} = "Prabha\ Pattan\,\ Madhya\ Pradesh";
$areanames{en}->{917149} = "Tamia\,\ Madhya\ Pradesh";
$areanames{en}->{917151} = "Samudrapur\,\ Maharashtra";
$areanames{en}->{917152} = "Wardha\,\ Maharashtra";
$areanames{en}->{917153} = "Hinganghat\,\ Maharashtra";
$areanames{en}->{917155} = "Seloo\,\ Maharashtra";
$areanames{en}->{917156} = "Talegaokarangal\,\ Maharashtra";
$areanames{en}->{917157} = "Arvi\,\ Maharashtra";
$areanames{en}->{917158} = "Deoli\,\ Maharashtra";
$areanames{en}->{917160} = "Jamai\,\ Madhya\ Pradesh";
$areanames{en}->{917161} = "Parasia\,\ Madhya\ Pradesh";
$areanames{en}->{917162} = "Chhindwara\,\ Madhya\ Pradesh";
$areanames{en}->{917164} = "Pandhurna\,\ Madhya\ Pradesh";
$areanames{en}->{917165} = "Saunsar\,\ Madhya\ Pradesh";
$areanames{en}->{917166} = "Chaurai\,\ Madhya\ Pradesh";
$areanames{en}->{917167} = "Amarwada\,\ Madhya\ Pradesh";
$areanames{en}->{917168} = "Harrai\,\ Madhya\ Pradesh";
$areanames{en}->{917169} = "Batkakhapa\,\ Madhya\ Pradesh";
$areanames{en}->{917170} = "Chumur\,\ Maharashtra";
$areanames{en}->{917171} = "Gond\ Pipri\,\ Maharashtra";
$areanames{en}->{917172} = "Chandrapur\,\ Maharashtra";
$areanames{en}->{917173} = "Rajura\,\ Maharashtra";
$areanames{en}->{917174} = "Mul\,\ Maharashtra";
$areanames{en}->{917175} = "Bhadrawati\,\ Maharashtra";
$areanames{en}->{917176} = "Warora\,\ Maharashtra";
$areanames{en}->{917177} = "Brahmapuri\,\ Maharashtra";
$areanames{en}->{917178} = "Sinderwahi\,\ Maharashtra";
$areanames{en}->{917179} = "Nagbhir\,\ Maharashtra";
$areanames{en}->{917180} = "Salekasa\,\ Maharashtra";
$areanames{en}->{917181} = "Lakhandur\,\ Maharashtra";
$areanames{en}->{917182} = "Gondia\,\ Maharashtra";
$areanames{en}->{917183} = "Tumsar\,\ Maharashtra";
$areanames{en}->{917184} = "Bhandara\,\ Maharashtra";
$areanames{en}->{917185} = "Pauni\,\ Maharashtra";
$areanames{en}->{917186} = "Sakoli\,\ Maharashtra";
$areanames{en}->{917187} = "Goregaon\,\ Maharashtra";
$areanames{en}->{917189} = "Amagaon\,\ Maharashtra";
$areanames{en}->{917196} = "Arjuni\ Morgaon\,\ Maharashtra";
$areanames{en}->{917197} = "Mohadi\,\ Maharashtra";
$areanames{en}->{917198} = "Tirora\,\ Maharashtra";
$areanames{en}->{917199} = "Deori\,\ Maharashtra";
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
$areanames{en}->{917286} = "Khetia\,\ Madhya\ Pradesh";
$areanames{en}->{917287} = "Gogaon\,\ Madhya\ Pradesh";
$areanames{en}->{917288} = "Bhikangaon\,\ Madhya\ Pradesh";
$areanames{en}->{917289} = "Zhirnia\,\ Madhya\ Pradesh";
$areanames{en}->{917290} = "Badwani\,\ Madhya\ Pradesh";
$areanames{en}->{917291} = "Manawar\,\ Madhya\ Pradesh";
$areanames{en}->{917292} = "Dhar\,\ Madhya\ Pradesh";
$areanames{en}->{917294} = "Dharampuri\,\ Madhya\ Pradesh";
$areanames{en}->{917295} = "Badnawar\,\ Madhya\ Pradesh";
$areanames{en}->{917296} = "Sardarpur\,\ Madhya\ Pradesh";
$areanames{en}->{917297} = "Kukshi\,\ Madhya\ Pradesh";
$areanames{en}->{91731} = "Indore\,\ Madhya\ Pradesh";
$areanames{en}->{917320} = "Pandhana\,\ Madhya\ Pradesh";
$areanames{en}->{917321} = "Sanwer\,\ Madhya\ Pradesh";
$areanames{en}->{917322} = "Depalpur\,\ Madhya\ Pradesh";
$areanames{en}->{917323} = "Punasa\,\ Madhya\ Pradesh";
$areanames{en}->{917324} = "Mhow\,\ Madhya\ Pradesh";
$areanames{en}->{917325} = "Burhanpur\,\ Madhya\ Pradesh";
$areanames{en}->{917326} = "Baldi\,\ Madhya\ Pradesh";
$areanames{en}->{917327} = "Harsud\,\ Madhya\ Pradesh";
$areanames{en}->{917328} = "Khalwa\,\ Madhya\ Pradesh";
$areanames{en}->{917329} = "Khakner\,\ Madhya\ Pradesh";
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
$areanames{en}->{917392} = "Jhabua\,\ Madhya\ Pradesh";
$areanames{en}->{917393} = "Jobat\,\ Madhya\ Pradesh";
$areanames{en}->{917394} = "Alirajpur\,\ Madhya\ Pradesh";
$areanames{en}->{917395} = "Sondhwa\,\ Madhya\ Pradesh";
$areanames{en}->{917410} = "Alot\,\ Madhya\ Pradesh";
$areanames{en}->{917412} = "Ratlam\,\ Madhya\ Pradesh";
$areanames{en}->{917413} = "Sailana\,\ Madhya\ Pradesh";
$areanames{en}->{917414} = "Jaora\,\ Madhya\ Pradesh";
$areanames{en}->{917420} = "Jawad\,\ Madhya\ Pradesh";
$areanames{en}->{917421} = "Manasa\,\ Madhya\ Pradesh";
$areanames{en}->{917422} = "Mandsaur\,\ Madhya\ Pradesh";
$areanames{en}->{917423} = "Neemuch\,\ Madhya\ Pradesh";
$areanames{en}->{917424} = "Malhargarh\,\ Madhya\ Pradesh";
$areanames{en}->{917425} = "Garoth\,\ Madhya\ Pradesh";
$areanames{en}->{917426} = "Sitamau\,\ Madhya\ Pradesh";
$areanames{en}->{917427} = "Bhanpura\,\ Madhya\ Pradesh";
$areanames{en}->{917430} = "Khanpur\,\ Rajasthan";
$areanames{en}->{917431} = "Aklera\,\ Rajasthan";
$areanames{en}->{917432} = "Jhalawar\,\ Rajasthan";
$areanames{en}->{917433} = "Pachpahar\/Bhawanimandi\,\ Rajasthan";
$areanames{en}->{917434} = "Pirawa\/Raipur\,\ Rajasthan";
$areanames{en}->{917435} = "Gangdhar\,\ Rajasthan";
$areanames{en}->{917436} = "Hindoli\,\ Rajasthan";
$areanames{en}->{917437} = "Nainwa\,\ Rajasthan";
$areanames{en}->{917438} = "Keshoraipatan\/Patan\,\ Rajasthan";
$areanames{en}->{91744} = "Ladpura\/Kota\,\ Rajasthan";
$areanames{en}->{917450} = "Sangod\,\ Rajasthan";
$areanames{en}->{917451} = "Atru\,\ Rajasthan";
$areanames{en}->{917452} = "Chhabra\,\ Rajasthan";
$areanames{en}->{917453} = "Baran\,\ Rajasthan";
$areanames{en}->{917454} = "Chhipaborad\,\ Rajasthan";
$areanames{en}->{917455} = "Digod\/Sultanpur\,\ Rajasthan";
$areanames{en}->{917456} = "Kishanganj\/Bhanwargarh\,\ Rajasthan";
$areanames{en}->{917457} = "Mangrol\,\ Rajasthan";
$areanames{en}->{917458} = "Pipalda\/Sumerganj\ Mandi\,\ Rajasthan";
$areanames{en}->{917459} = "Ramganj\ Mandi\,\ Rajasthan";
$areanames{en}->{917460} = "Sahabad\,\ Rajasthan";
$areanames{en}->{917461} = "Mahuwa\,\ Rajasthan";
$areanames{en}->{917462} = "Sawaimadhopur\,\ Rajasthan";
$areanames{en}->{917463} = "Gangapur\,\ Rajasthan";
$areanames{en}->{917464} = "Karauli\,\ Rajasthan";
$areanames{en}->{917465} = "Sapotra\,\ Rajasthan";
$areanames{en}->{917466} = "Bonli\,\ Rajasthan";
$areanames{en}->{917467} = "Bamanwas\,\ Rajasthan";
$areanames{en}->{917468} = "Khandar\,\ Rajasthan";
$areanames{en}->{917469} = "Hindaun\,\ Rajasthan";
$areanames{en}->{91747} = "Bundi\,\ Rajasthan";
$areanames{en}->{917480} = "Goharganj\,\ Madhya\ Pradesh";
$areanames{en}->{917481} = "Gairatganj\,\ Madhya\ Pradesh";
$areanames{en}->{917482} = "Raisen\,\ Madhya\ Pradesh";
$areanames{en}->{917484} = "Silwani\,\ Madhya\ Pradesh";
$areanames{en}->{917485} = "Udaipura\,\ Madhya\ Pradesh";
$areanames{en}->{917486} = "Bareli\,\ Madhya\ Pradesh";
$areanames{en}->{917487} = "Begamganj\,\ Madhya\ Pradesh";
$areanames{en}->{917490} = "Pohari\,\ Madhya\ Pradesh";
$areanames{en}->{917491} = "Narwar\,\ Madhya\ Pradesh";
$areanames{en}->{917492} = "Shivpuri\,\ Madhya\ Pradesh";
$areanames{en}->{917493} = "Karera\,\ Madhya\ Pradesh";
$areanames{en}->{917494} = "Kolaras\,\ Madhya\ Pradesh";
$areanames{en}->{917495} = "Badarwas\,\ Madhya\ Pradesh";
$areanames{en}->{917496} = "Pichhore\,\ Madhya\ Pradesh";
$areanames{en}->{917497} = "Khaniadhana\,\ Madhya\ Pradesh";
$areanames{en}->{91751} = "Gwalior\,\ Madhya\ Pradesh";
$areanames{en}->{917521} = "Seondha\,\ Madhya\ Pradesh";
$areanames{en}->{917522} = "Datia\,\ Madhya\ Pradesh";
$areanames{en}->{917523} = "Bhander\,\ Madhya\ Pradesh";
$areanames{en}->{917524} = "Dabra\,\ Madhya\ Pradesh";
$areanames{en}->{917525} = "Bhitarwar\,\ Madhya\ Pradesh";
$areanames{en}->{917526} = "Ghatigaon\,\ Madhya\ Pradesh";
$areanames{en}->{917527} = "Mehgaon\,\ Madhya\ Pradesh";
$areanames{en}->{917528} = "Bijaypur\,\ Madhya\ Pradesh";
$areanames{en}->{917529} = "Laher\,\ Madhya\ Pradesh";
$areanames{en}->{917530} = "Sheopurkalan\,\ Madhya\ Pradesh";
$areanames{en}->{917531} = "Baroda\,\ Madhya\ Pradesh";
$areanames{en}->{917532} = "Morena\,\ Madhya\ Pradesh";
$areanames{en}->{917533} = "Karhal\,\ Madhya\ Pradesh";
$areanames{en}->{917534} = "Bhind\,\ Madhya\ Pradesh";
$areanames{en}->{917535} = "Raghunathpur\,\ Madhya\ Pradesh";
$areanames{en}->{917536} = "Sabalgarh\,\ Madhya\ Pradesh";
$areanames{en}->{917537} = "Jora\,\ Madhya\ Pradesh";
$areanames{en}->{917538} = "Ambah\,\ Madhya\ Pradesh";
$areanames{en}->{917539} = "Gohad\,\ Madhya\ Pradesh";
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
$areanames{en}->{917590} = "Lateri\,\ Madhya\ Pradesh";
$areanames{en}->{917591} = "Sironj\,\ Madhya\ Pradesh";
$areanames{en}->{917592} = "Vidisha\,\ Madhya\ Pradesh";
$areanames{en}->{917593} = "Kurwai\,\ Madhya\ Pradesh";
$areanames{en}->{917594} = "Ganjbasoda\,\ Madhya\ Pradesh";
$areanames{en}->{917595} = "Nateran\,\ Madhya\ Pradesh";
$areanames{en}->{917596} = "Gyraspur\,\ Madhya\ Pradesh";
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
$areanames{en}->{917625} = "Umariapan\,\ Madhya\ Pradesh";
$areanames{en}->{917626} = "Vijayraghogarh\,\ Madhya\ Pradesh";
$areanames{en}->{917627} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{917628} = "Karpa\,\ Madhya\ Pradesh";
$areanames{en}->{917629} = "Pushprajgarh\,\ Madhya\ Pradesh";
$areanames{en}->{917630} = "Katangi\,\ Madhya\ Pradesh";
$areanames{en}->{917632} = "Balaghat\,\ Madhya\ Pradesh";
$areanames{en}->{917633} = "Waraseoni\,\ Madhya\ Pradesh";
$areanames{en}->{917634} = "Lamta\,\ Madhya\ Pradesh";
$areanames{en}->{917635} = "Lanji\,\ Madhya\ Pradesh";
$areanames{en}->{917636} = "Baihar\,\ Madhya\ Pradesh";
$areanames{en}->{917637} = "Birsa\,\ Madhya\ Pradesh";
$areanames{en}->{917638} = "Damoh\,\ Madhya\ Pradesh";
$areanames{en}->{917640} = "Shahpur\,\ Madhya\ Pradesh";
$areanames{en}->{917641} = "Niwas\,\ Madhya\ Pradesh";
$areanames{en}->{917642} = "Mandla\,\ Madhya\ Pradesh";
$areanames{en}->{917643} = "Bijadandi\,\ Madhya\ Pradesh";
$areanames{en}->{917644} = "Dindori\,\ Madhya\ Pradesh";
$areanames{en}->{917645} = "Karanjia\,\ Madhya\ Pradesh";
$areanames{en}->{917646} = "Nainpur\,\ Madhya\ Pradesh";
$areanames{en}->{917647} = "Ghughari\,\ Madhya\ Pradesh";
$areanames{en}->{917648} = "Mawai\,\ Madhya\ Pradesh";
$areanames{en}->{917649} = "Kakaiya\,\ Madhya\ Pradesh";
$areanames{en}->{917650} = "Beohari\,\ Madhya\ Pradesh";
$areanames{en}->{917651} = "Jaisinghnagar\,\ Madhya\ Pradesh";
$areanames{en}->{917652} = "Shahdol\,\ Madhya\ Pradesh";
$areanames{en}->{917653} = "Bandhavgarh\,\ Madhya\ Pradesh";
$areanames{en}->{917655} = "Birsinghpur\,\ Madhya\ Pradesh";
$areanames{en}->{917656} = "Kannodi\,\ Madhya\ Pradesh";
$areanames{en}->{917657} = "Jaitpur\,\ Madhya\ Pradesh";
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
$areanames{en}->{917681} = "Jatara\,\ Madhya\ Pradesh";
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
$areanames{en}->{917700} = "Nagri\,\ Madhya\ Pradesh";
$areanames{en}->{917701} = "Pingeshwar\,\ Madhya\ Pradesh";
$areanames{en}->{917703} = "Manpur\,\ Madhya\ Pradesh";
$areanames{en}->{917704} = "Deobhog\,\ Madhya\ Pradesh";
$areanames{en}->{917705} = "Kurud\,\ Madhya\ Pradesh";
$areanames{en}->{917706} = "Gariaband\,\ Madhya\ Pradesh";
$areanames{en}->{917707} = "Bagbahera\,\ Madhya\ Pradesh";
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
$areanames{en}->{9179} = "Ahmedabad\ Local\,\ Gujarat";
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
$areanames{en}->{918153} = "Bangarpet\,\ Karnataka";
$areanames{en}->{918154} = "Chintamani\,\ Karnataka";
$areanames{en}->{918155} = "Gowribidanur\,\ Karnataka";
$areanames{en}->{918156} = "Chikkaballapur\,\ Karnataka";
$areanames{en}->{918157} = "Srinivasapur\,\ Karnataka";
$areanames{en}->{918158} = "Sidlaghatta\,\ Karnataka";
$areanames{en}->{918159} = "Mulbagal\,\ Karnataka";
$areanames{en}->{91816} = "Tumkur\,\ Karnataka";
$areanames{en}->{918170} = "Alur\,\ Karnataka";
$areanames{en}->{918172} = "Hassan\,\ Karnataka";
$areanames{en}->{918173} = "Sakleshpur\,\ Karnataka";
$areanames{en}->{918174} = "Arsikere\,\ Karnataka";
$areanames{en}->{918175} = "Holenarasipur\,\ Karnataka";
$areanames{en}->{918176} = "Cannarayapatna\,\ Karnataka";
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
$areanames{en}->{918194} = "Chitradurga\,\ Karnataka";
$areanames{en}->{918195} = "Challakere\,\ Karnataka";
$areanames{en}->{918196} = "Jagalur\,\ Karnataka";
$areanames{en}->{918198} = "Molkalmuru\,\ Karnataka";
$areanames{en}->{918199} = "Hosadurga\,\ Karnataka";
$areanames{en}->{91820} = "Udupi\,\ Karnataka";
$areanames{en}->{91821} = "Mysore\,\ Karnataka";
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
$areanames{en}->{91824} = "Mangalore\,\ Karnataka";
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
$areanames{en}->{918289} = "Athani\,\ Karnataka";
$areanames{en}->{918301} = "Mundagod\,\ Karnataka";
$areanames{en}->{918304} = "Kundgol\,\ Karnataka";
$areanames{en}->{91831} = "Belgaum\,\ Karnataka";
$areanames{en}->{91832} = "Goa";
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
$areanames{en}->{91836} = "Hubli\,\ Karnataka";
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
$areanames{en}->{918587} = "Venkatgirikota\,\ Andhra\ Pradesh";
$areanames{en}->{918588} = "Vaimpalli\,\ Andhra\ Pradesh";
$areanames{en}->{918589} = "Siddavattam\,\ Andhra\ Pradesh";
$areanames{en}->{918592} = "Ongole\,\ Andhra\ Pradesh";
$areanames{en}->{918593} = "Medarmetla\,\ Andhra\ Pradesh";
$areanames{en}->{918594} = "Chirala\,\ Andhra\ Pradesh";
$areanames{en}->{918596} = "Markapur\,\ Andhra\ Pradesh";
$areanames{en}->{918598} = "Kandukuru\,\ Andhra\ Pradesh";
$areanames{en}->{918599} = "Ulvapadu\,\ Andhra\ Pradesh";
$areanames{en}->{91861} = "Nellore\,\ Andhra\ Pradesh";
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
$areanames{en}->{91863} = "Guntur\,\ Andhra\ Pradesh";
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
$areanames{en}->{91866} = "Vijayawada\,\ Andhra\ Pradesh";
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
$areanames{en}->{91870} = "Warangal\,\ Andhra\ Pradesh";
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
$areanames{en}->{918761} = "Sathupalli\,\ Andhra\ Pradesh";
$areanames{en}->{91877} = "Tirupathi\,\ Andhra\ Pradesh";
$areanames{en}->{91878} = "Karimnagar\,\ Andhra\ Pradesh";
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
$areanames{en}->{91883} = "Rajahmundri\,\ Andhra\ Pradesh";
$areanames{en}->{91884} = "Kakinada\,\ Andhra\ Pradesh";
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
$areanames{en}->{91891} = "Visakhapatnam\,\ Andhra\ Pradesh";
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
$areanames{en}->{918946} = "Pathapatnam\/Hiramandalam\,\ Andhra\ Pradesh";
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