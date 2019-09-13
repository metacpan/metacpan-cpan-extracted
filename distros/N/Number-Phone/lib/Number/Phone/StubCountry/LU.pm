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
package Number::Phone::StubCountry::LU;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215427;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            2(?:
              0[2-689]|
              [2-9]
            )|
            [3-57]|
            8(?:
              0[2-9]|
              [13-9]
            )|
            9(?:
              0[89]|
              [2-579]
            )
          ',
                  'pattern' => '(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            2(?:
              0[2-689]|
              [2-9]
            )|
            [3-57]|
            8(?:
              0[2-9]|
              [13-9]
            )|
            9(?:
              0[89]|
              [2-579]
            )
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '20[2-689]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            2(?:
              [0367]|
              4[3-8]
            )
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{1,2})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            80[01]|
            90[015]
          ',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '20',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '6',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4 $5',
                  'leading_digits' => '
            2(?:
              [0367]|
              4[3-8]
            )
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})(\\d{1,2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            [3-57]|
            8[13-9]|
            9(?:
              0[89]|
              [2-579]
            )|
            (?:
              2|
              80
            )[2-9]
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{1,5})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            35[013-9]|
            80[2-9]|
            90[89]
          )\\d{1,8}|
          (?:
            2[2-9]|
            3[0-46-9]|
            [457]\\d|
            8[13-9]|
            9[2-579]
          )\\d{2,9}
        ',
                'geographic' => '
          (?:
            35[013-9]|
            80[2-9]|
            90[89]
          )\\d{1,8}|
          (?:
            2[2-9]|
            3[0-46-9]|
            [457]\\d|
            8[13-9]|
            9[2-579]
          )\\d{2,9}
        ',
                'mobile' => '
          6(?:
            [269][18]|
            5[158]|
            7[189]|
            81
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(801\\d{5})|(90[015]\\d{5})',
                'toll_free' => '800\\d{5}',
                'voip' => '
          20(?:
            1\\d{5}|
            [2-689]\\d{1,7}
          )
        '
              };
my %areanames = ();
$areanames{de}->{35222} = "Luxemburg";
$areanames{de}->{35223} = "Bad\ Mondorf";
$areanames{de}->{352240} = "Luxemburg";
$areanames{de}->{352241} = "Luxemburg";
$areanames{de}->{352242} = "Luxemburg";
$areanames{de}->{3522421} = "Weicherdingen";
$areanames{de}->{3522423} = "Bad\ Mondorf";
$areanames{de}->{3522427} = "Belair\,\ Luxemburg";
$areanames{de}->{3522429} = "Luxemburg\/Kockelscheuer";
$areanames{de}->{3522430} = "Kanton\ Capellen\/Kehlen";
$areanames{de}->{3522431} = "Bartringen";
$areanames{de}->{3522432} = "Lintgen\/Kanton\ Mersch\/Steinfort";
$areanames{de}->{3522433} = "Walferdingen";
$areanames{de}->{3522434} = "Rammeldingen\/Senningerberg";
$areanames{de}->{3522435} = "Sandweiler\/Mutfort\/Roodt\-sur\-Syre";
$areanames{de}->{3522436} = "Hesperingen\/Kockelscheuer\/Roeser";
$areanames{de}->{3522437} = "Leudelingen\/Ehlingen\/Monnerich";
$areanames{de}->{3522438} = "Luxemburg";
$areanames{de}->{3522439} = "Windhof\/Steinfort";
$areanames{de}->{3522440} = "Howald";
$areanames{de}->{3522441} = "Luxemburg";
$areanames{de}->{3522442} = "Plateau\ de\ Kirchberg";
$areanames{de}->{3522443} = "Findel\/Kirchberg";
$areanames{de}->{3522444} = "Luxemburg";
$areanames{de}->{3522445} = "Diedrich";
$areanames{de}->{3522446} = "Luxemburg";
$areanames{de}->{3522447} = "Lintgen";
$areanames{de}->{3522448} = "Contern\/Foetz";
$areanames{de}->{3522449} = "Howald";
$areanames{de}->{3522450} = "Bascharage\/Petingen\/Rodingen";
$areanames{de}->{3522451} = "Düdelingen\/Bettemburg\/Livingen";
$areanames{de}->{3522452} = "Düdelingen";
$areanames{de}->{3522453} = "Esch\-sur\-Alzette";
$areanames{de}->{3522454} = "Esch\-sur\-Alzette";
$areanames{de}->{3522455} = "Esch\-sur\-Alzette\/Monnerich";
$areanames{de}->{3522456} = "Rümelingen";
$areanames{de}->{3522457} = "Esch\-sur\-Alzette\/Schifflingen";
$areanames{de}->{3522458} = "Soleuvre\/Differdingen";
$areanames{de}->{3522459} = "Soleuvre";
$areanames{de}->{352246} = "Luxemburg";
$areanames{de}->{3522467} = "Düdelingen";
$areanames{de}->{3522470} = "Luxemburg";
$areanames{de}->{3522471} = "Betzdorf";
$areanames{de}->{3522472} = "Echternach";
$areanames{de}->{3522473} = "Rosport";
$areanames{de}->{3522474} = "Wasserbillig";
$areanames{de}->{3522475} = "Distrikt\ Grevenmacher\-sur\-Moselle";
$areanames{de}->{3522476} = "Wormeldingen";
$areanames{de}->{3522477} = "Luxemburg";
$areanames{de}->{3522478} = "Junglinster";
$areanames{de}->{3522479} = "Berdorf\/Consdorf";
$areanames{de}->{3522480} = "Diekirch";
$areanames{de}->{3522481} = "Ettelbrück\/Reckange\-sur\-Mess";
$areanames{de}->{3522482} = "Luxemburg";
$areanames{de}->{3522483} = "Vianden";
$areanames{de}->{3522484} = "Han\/Lesse";
$areanames{de}->{3522485} = "Bissen\/Roost";
$areanames{de}->{3522486} = "Luxemburg";
$areanames{de}->{3522487} = "Fels";
$areanames{de}->{3522488} = "Mertzig\/Wahl";
$areanames{de}->{3522489} = "Luxemburg";
$areanames{de}->{352249} = "Luxemburg";
$areanames{de}->{3522492} = "Kanton\ Clerf\/Fischbach\/Hosingen";
$areanames{de}->{3522495} = "Wiltz";
$areanames{de}->{3522497} = "Huldingen";
$areanames{de}->{3522499} = "Ulflingen";
$areanames{de}->{35225} = "Luxemburg";
$areanames{de}->{3522621} = "Weicherdingen";
$areanames{de}->{3522622} = "Luxemburg";
$areanames{de}->{3522623} = "Bad\ Mondorf";
$areanames{de}->{3522625} = "Luxemburg";
$areanames{de}->{3522627} = "Belair\,\ Luxemburg";
$areanames{de}->{3522628} = "Luxemburg";
$areanames{de}->{3522629} = "Luxemburg\/Kockelscheuer";
$areanames{de}->{3522630} = "Kanton\ Capellen\/Kehlen";
$areanames{de}->{3522631} = "Bartringen";
$areanames{de}->{3522632} = "Lintgen\/Kanton\ Mersch\/Steinfort";
$areanames{de}->{3522633} = "Walferdingen";
$areanames{de}->{3522634} = "Rammeldingen\/Senningerberg";
$areanames{de}->{3522635} = "Sandweiler\/Mutfort\/Roodt\-sur\-Syre";
$areanames{de}->{3522636} = "Hesperingen\/Kockelscheuer\/Roeser";
$areanames{de}->{3522637} = "Leudelingen\/Ehlingen\/Monnerich";
$areanames{de}->{3522639} = "Windhof\/Steinfort";
$areanames{de}->{3522640} = "Howald";
$areanames{de}->{3522642} = "Plateau\ de\ Kirchberg";
$areanames{de}->{3522643} = "Findel\/Kirchberg";
$areanames{de}->{3522645} = "Diedrich";
$areanames{de}->{3522647} = "Lintgen";
$areanames{de}->{3522648} = "Contern\/Foetz";
$areanames{de}->{3522649} = "Howald";
$areanames{de}->{3522650} = "Bascharage\/Petingen\/Rodingen";
$areanames{de}->{3522651} = "Düdelingen\/Bettemburg\/Livingen";
$areanames{de}->{3522652} = "Düdelingen";
$areanames{de}->{3522653} = "Esch\-sur\-Alzette";
$areanames{de}->{3522654} = "Esch\-sur\-Alzette";
$areanames{de}->{3522655} = "Esch\-sur\-Alzette\/Monnerich";
$areanames{de}->{3522656} = "Rümelingen";
$areanames{de}->{3522657} = "Esch\-sur\-Alzette\/Schifflingen";
$areanames{de}->{3522658} = "Soleuvre\/Differdingen";
$areanames{de}->{3522659} = "Soleuvre";
$areanames{de}->{3522667} = "Düdelingen";
$areanames{de}->{3522671} = "Betzdorf";
$areanames{de}->{3522672} = "Echternach";
$areanames{de}->{3522673} = "Rosport";
$areanames{de}->{3522674} = "Wasserbillig";
$areanames{de}->{3522675} = "Distrikt\ Grevenmacher\-sur\-Moselle";
$areanames{de}->{3522676} = "Wormeldingen";
$areanames{de}->{3522678} = "Junglinster";
$areanames{de}->{3522679} = "Berdorf\/Consdorf";
$areanames{de}->{3522680} = "Diekirch";
$areanames{de}->{3522681} = "Ettelbrück\/Reckange\-sur\-Mess";
$areanames{de}->{3522683} = "Vianden";
$areanames{de}->{3522684} = "Han\/Lesse";
$areanames{de}->{3522685} = "Bissen\/Roost";
$areanames{de}->{3522687} = "Fels";
$areanames{de}->{3522688} = "Mertzig\/Wahl";
$areanames{de}->{3522692} = "Kanton\ Clerf\/Fischbach\/Hosingen";
$areanames{de}->{3522695} = "Wiltz";
$areanames{de}->{3522697} = "Huldingen";
$areanames{de}->{3522699} = "Ulflingen";
$areanames{de}->{3522721} = "Weicherdingen";
$areanames{de}->{3522722} = "Luxemburg";
$areanames{de}->{3522723} = "Bad\ Mondorf";
$areanames{de}->{3522725} = "Luxemburg";
$areanames{de}->{3522727} = "Belair\,\ Luxemburg";
$areanames{de}->{3522728} = "Luxemburg";
$areanames{de}->{3522729} = "Luxemburg\/Kockelscheuer";
$areanames{de}->{3522730} = "Kanton\ Capellen\/Kehlen";
$areanames{de}->{3522731} = "Bartringen";
$areanames{de}->{3522732} = "Lintgen\/Kanton\ Mersch\/Steinfort";
$areanames{de}->{3522733} = "Walferdingen";
$areanames{de}->{3522734} = "Rammeldingen\/Senningerberg";
$areanames{de}->{3522735} = "Sandweiler\/Mutfort\/Roodt\-sur\-Syre";
$areanames{de}->{3522736} = "Hesperingen\/Kockelscheuer\/Roeser";
$areanames{de}->{3522737} = "Leudelingen\/Ehlingen\/Monnerich";
$areanames{de}->{3522739} = "Windhof\/Steinfort";
$areanames{de}->{3522740} = "Howald";
$areanames{de}->{3522742} = "Plateau\ de\ Kirchberg";
$areanames{de}->{3522743} = "Findel\/Kirchberg";
$areanames{de}->{3522745} = "Diedrich";
$areanames{de}->{3522747} = "Lintgen";
$areanames{de}->{3522748} = "Contern\/Foetz";
$areanames{de}->{3522749} = "Howald";
$areanames{de}->{3522750} = "Bascharage\/Petingen\/Rodingen";
$areanames{de}->{3522751} = "Düdelingen\/Bettemburg\/Livingen";
$areanames{de}->{3522752} = "Düdelingen";
$areanames{de}->{3522753} = "Esch\-sur\-Alzette";
$areanames{de}->{3522754} = "Esch\-sur\-Alzette";
$areanames{de}->{3522755} = "Esch\-sur\-Alzette\/Monnerich";
$areanames{de}->{3522756} = "Rümelingen";
$areanames{de}->{3522757} = "Esch\-sur\-Alzette\/Schifflingen";
$areanames{de}->{3522758} = "Soleuvre\/Differdingen";
$areanames{de}->{3522759} = "Soleuvre";
$areanames{de}->{3522767} = "Düdelingen";
$areanames{de}->{3522771} = "Betzdorf";
$areanames{de}->{3522772} = "Echternach";
$areanames{de}->{3522773} = "Rosport";
$areanames{de}->{3522774} = "Wasserbillig";
$areanames{de}->{3522775} = "Distrikt\ Grevenmacher\-sur\-Moselle";
$areanames{de}->{3522776} = "Wormeldingen";
$areanames{de}->{3522778} = "Junglinster";
$areanames{de}->{3522779} = "Berdorf\/Consdorf";
$areanames{de}->{3522780} = "Diekirch";
$areanames{de}->{3522781} = "Ettelbrück\/Reckange\-sur\-Mess";
$areanames{de}->{3522783} = "Vianden";
$areanames{de}->{3522784} = "Han\/Lesse";
$areanames{de}->{3522785} = "Bissen\/Roost";
$areanames{de}->{3522787} = "Fels";
$areanames{de}->{3522788} = "Mertzig\/Wahl";
$areanames{de}->{3522792} = "Kanton\ Clerf\/Fischbach\/Hosingen";
$areanames{de}->{3522795} = "Wiltz";
$areanames{de}->{3522797} = "Huldingen";
$areanames{de}->{3522799} = "Ulflingen";
$areanames{de}->{35228} = "Luxemburg";
$areanames{de}->{35229} = "Luxemburg";
$areanames{de}->{35230} = "Kanton\ Capellen\/Kehlen";
$areanames{de}->{35231} = "Bartringen";
$areanames{de}->{35232} = "Kanton\ Mersch";
$areanames{de}->{35233} = "Walferdingen";
$areanames{de}->{35234} = "Rammeldingen\/Senningerberg";
$areanames{de}->{35235} = "Sandweiler\/Mutfort\/Roodt\-sur\-Syre";
$areanames{de}->{35236} = "Hesperingen\/Kockelscheuer\/Roeser";
$areanames{de}->{35237} = "Leudelingen\/Ehlingen\/Monnerich";
$areanames{de}->{35239} = "Windhof\/Steinfort";
$areanames{de}->{35240} = "Howald";
$areanames{de}->{35241} = "Luxemburg";
$areanames{de}->{35242} = "Plateau\ de\ Kirchberg";
$areanames{de}->{35243} = "Findel\/Kirchberg";
$areanames{de}->{35244} = "Luxemburg";
$areanames{de}->{35245} = "Diedrich";
$areanames{de}->{35246} = "Luxemburg";
$areanames{de}->{35247} = "Lintgen";
$areanames{de}->{35248} = "Contern\/Foetz";
$areanames{de}->{35249} = "Howald";
$areanames{de}->{35250} = "Bascharage\/Petingen\/Rodingen";
$areanames{de}->{35251} = "Düdelingen\/Bettemburg\/Livingen";
$areanames{de}->{35252} = "Düdelingen";
$areanames{de}->{35253} = "Esch\-sur\-Alzette";
$areanames{de}->{35254} = "Esch\-sur\-Alzette";
$areanames{de}->{35255} = "Esch\-sur\-Alzette\/Monnerich";
$areanames{de}->{35256} = "Rümelingen";
$areanames{de}->{35257} = "Esch\-sur\-Alzette\/Schifflingen";
$areanames{de}->{35258} = "Differdingen";
$areanames{de}->{35259} = "Soleuvre";
$areanames{de}->{35267} = "Düdelingen";
$areanames{de}->{35271} = "Betzdorf";
$areanames{de}->{35272} = "Echternach";
$areanames{de}->{35273} = "Rosport";
$areanames{de}->{35274} = "Wasserbillig";
$areanames{de}->{35275} = "Distrikt\ Grevenmacher";
$areanames{de}->{35276} = "Wormeldingen";
$areanames{de}->{35278} = "Junglinster";
$areanames{de}->{35279} = "Berdorf\/Consdorf";
$areanames{de}->{35280} = "Diekirch";
$areanames{de}->{35281} = "Ettelbrück";
$areanames{de}->{35283} = "Vianden";
$areanames{de}->{35284} = "Han\/Lesse";
$areanames{de}->{35285} = "Bissen\/Roost";
$areanames{de}->{35287} = "Fels";
$areanames{de}->{35288} = "Mertzig\/Wahl";
$areanames{de}->{35292} = "Kanton\ Clerf\/Fischbach\/Hosingen";
$areanames{de}->{35295} = "Wiltz";
$areanames{de}->{35297} = "Huldingen";
$areanames{de}->{35299} = "Ulflingen";
$areanames{fr}->{35222} = "Luxembourg\-Ville";
$areanames{fr}->{35223} = "Mondorf\-les\-Bains\/Bascharage\/Noerdange\/Remich";
$areanames{fr}->{352240} = "Luxembourg";
$areanames{fr}->{352241} = "Luxembourg";
$areanames{fr}->{3522420} = "Luxembourg";
$areanames{fr}->{3522421} = "Weicherdange";
$areanames{fr}->{3522422} = "Luxembourg\-Ville";
$areanames{fr}->{3522423} = "Mondorf\-les\-Bains\/Bascharage\/Noerdange\/Remich";
$areanames{fr}->{3522424} = "Luxembourg";
$areanames{fr}->{3522425} = "Luxembourg";
$areanames{fr}->{3522426} = "Luxembourg";
$areanames{fr}->{3522427} = "Belair\,\ Luxembourg";
$areanames{fr}->{3522428} = "Luxembourg\-Ville";
$areanames{fr}->{3522429} = "Luxembourg\/Kockelscheuer";
$areanames{fr}->{3522430} = "Capellen\/Kehlen";
$areanames{fr}->{3522431} = "Bertrange\/Mamer\/Munsbach\/Strassen";
$areanames{fr}->{3522432} = "Lintgen\/Mersch\/Steinfort";
$areanames{fr}->{3522433} = "Walferdange";
$areanames{fr}->{3522434} = "Rameldange\/Senningerberg";
$areanames{fr}->{3522435} = "Sandweiler\/Moutfort\/Roodt\-sur\-Syre";
$areanames{fr}->{3522436} = "Hesperange\/Kockelscheuer\/Roeser";
$areanames{fr}->{3522437} = "Leudelange\/Ehlange\/Mondercange";
$areanames{fr}->{3522438} = "Luxembourg";
$areanames{fr}->{3522439} = "Windhof\/Steinfort";
$areanames{fr}->{3522440} = "Howald";
$areanames{fr}->{3522441} = "Luxembourg";
$areanames{fr}->{3522442} = "Plateau\ de\ Kirchberg";
$areanames{fr}->{3522443} = "Findel\/Kirchberg";
$areanames{fr}->{3522444} = "Luxembourg";
$areanames{fr}->{3522445} = "Diedrich";
$areanames{fr}->{3522446} = "Luxembourg";
$areanames{fr}->{3522447} = "Lintgen";
$areanames{fr}->{3522448} = "Contern\/Foetz";
$areanames{fr}->{3522449} = "Howald";
$areanames{fr}->{3522450} = "Bascharage\/Petange\/Rodange";
$areanames{fr}->{3522451} = "Dudelange\/Bettembourg\/Livange";
$areanames{fr}->{3522452} = "Dudelange";
$areanames{fr}->{3522453} = "Esch\-sur\-Alzette";
$areanames{fr}->{3522454} = "Esch\-sur\-Alzette";
$areanames{fr}->{3522455} = "Esch\-sur\-Alzette\/Mondercange";
$areanames{fr}->{3522456} = "Rumelange";
$areanames{fr}->{3522457} = "Esch\-sur\-Alzette\/Schifflange";
$areanames{fr}->{3522458} = "Soleuvre\/Differdange";
$areanames{fr}->{3522459} = "Soleuvre";
$areanames{fr}->{352246} = "Luxembourg";
$areanames{fr}->{3522467} = "Dudelange";
$areanames{fr}->{3522470} = "Luxembourg";
$areanames{fr}->{3522471} = "Betzdorf";
$areanames{fr}->{3522472} = "Echternach";
$areanames{fr}->{3522473} = "Rosport";
$areanames{fr}->{3522474} = "Wasserbillig";
$areanames{fr}->{3522475} = "Grevenmacher\-sur\-Moselle";
$areanames{fr}->{3522476} = "Wormeldange";
$areanames{fr}->{3522477} = "Luxembourg";
$areanames{fr}->{3522478} = "Junglinster";
$areanames{fr}->{3522479} = "Berdorf\/Consdorf";
$areanames{fr}->{3522480} = "Diekirch";
$areanames{fr}->{3522481} = "Ettelbruck\/Reckange\-sur\-Mess";
$areanames{fr}->{3522482} = "Luxembourg";
$areanames{fr}->{3522483} = "Vianden";
$areanames{fr}->{3522484} = "Han\/Lesse";
$areanames{fr}->{3522485} = "Bissen\/Roost";
$areanames{fr}->{3522486} = "Luxembourg";
$areanames{fr}->{3522487} = "Larochette";
$areanames{fr}->{3522488} = "Mertzig\/Wahl";
$areanames{fr}->{3522489} = "Luxembourg";
$areanames{fr}->{352249} = "Luxembourg";
$areanames{fr}->{3522492} = "Clervaux\/Fischbach\/Hosingen";
$areanames{fr}->{3522495} = "Wiltz";
$areanames{fr}->{3522497} = "Huldange";
$areanames{fr}->{3522499} = "Troisvierges";
$areanames{fr}->{35225} = "Luxembourg";
$areanames{fr}->{3522621} = "Weicherdange";
$areanames{fr}->{3522622} = "Luxembourg\-Ville";
$areanames{fr}->{3522623} = "Mondorf\-les\-Bains\/Bascharage\/Noerdange\/Remich";
$areanames{fr}->{3522625} = "Luxembourg";
$areanames{fr}->{3522627} = "Belair\,\ Luxembourg";
$areanames{fr}->{3522628} = "Luxembourg\-Ville";
$areanames{fr}->{3522629} = "Luxembourg\/Kockelscheuer";
$areanames{fr}->{3522630} = "Capellen\/Kehlen";
$areanames{fr}->{3522631} = "Bertrange\/Mamer\/Munsbach\/Strassen";
$areanames{fr}->{3522632} = "Lintgen\/Mersch\/Steinfort";
$areanames{fr}->{3522633} = "Walferdange";
$areanames{fr}->{3522634} = "Rameldange\/Senningerberg";
$areanames{fr}->{3522635} = "Sandweiler\/Moutfort\/Roodt\-sur\-Syre";
$areanames{fr}->{3522636} = "Hesperange\/Kockelscheuer\/Roeser";
$areanames{fr}->{3522637} = "Leudelange\/Ehlange\/Mondercange";
$areanames{fr}->{3522639} = "Windhof\/Steinfort";
$areanames{fr}->{3522640} = "Howald";
$areanames{fr}->{3522642} = "Plateau\ de\ Kirchberg";
$areanames{fr}->{3522643} = "Findel\/Kirchberg";
$areanames{fr}->{3522645} = "Diedrich";
$areanames{fr}->{3522647} = "Lintgen";
$areanames{fr}->{3522648} = "Contern\/Foetz";
$areanames{fr}->{3522649} = "Howald";
$areanames{fr}->{3522650} = "Bascharage\/Petange\/Rodange";
$areanames{fr}->{3522651} = "Dudelange\/Bettembourg\/Livange";
$areanames{fr}->{3522652} = "Dudelange";
$areanames{fr}->{3522653} = "Esch\-sur\-Alzette";
$areanames{fr}->{3522654} = "Esch\-sur\-Alzette";
$areanames{fr}->{3522655} = "Esch\-sur\-Alzette\/Mondercange";
$areanames{fr}->{3522656} = "Rumelange";
$areanames{fr}->{3522657} = "Esch\-sur\-Alzette\/Schifflange";
$areanames{fr}->{3522658} = "Soleuvre\/Differdange";
$areanames{fr}->{3522659} = "Soleuvre";
$areanames{fr}->{3522667} = "Dudelange";
$areanames{fr}->{3522671} = "Betzdorf";
$areanames{fr}->{3522672} = "Echternach";
$areanames{fr}->{3522673} = "Rosport";
$areanames{fr}->{3522674} = "Wasserbillig";
$areanames{fr}->{3522675} = "Grevenmacher\-sur\-Moselle";
$areanames{fr}->{3522676} = "Wormeldange";
$areanames{fr}->{3522678} = "Junglinster";
$areanames{fr}->{3522679} = "Berdorf\/Consdorf";
$areanames{fr}->{3522680} = "Diekirch";
$areanames{fr}->{3522681} = "Ettelbruck\/Reckange\-sur\-Mess";
$areanames{fr}->{3522683} = "Vianden";
$areanames{fr}->{3522684} = "Han\/Lesse";
$areanames{fr}->{3522685} = "Bissen\/Roost";
$areanames{fr}->{3522687} = "Larochette";
$areanames{fr}->{3522688} = "Mertzig\/Wahl";
$areanames{fr}->{3522692} = "Clervaux\/Fischbach\/Hosingen";
$areanames{fr}->{3522695} = "Wiltz";
$areanames{fr}->{3522697} = "Huldange";
$areanames{fr}->{3522699} = "Troisvierges";
$areanames{fr}->{3522721} = "Weicherdange";
$areanames{fr}->{3522722} = "Luxembourg\-Ville";
$areanames{fr}->{3522723} = "Mondorf\-les\-Bains\/Bascharage\/Noerdange\/Remich";
$areanames{fr}->{3522725} = "Luxembourg";
$areanames{fr}->{3522727} = "Belair\,\ Luxembourg";
$areanames{fr}->{3522728} = "Luxembourg\-Ville";
$areanames{fr}->{3522729} = "Luxembourg\/Kockelscheuer";
$areanames{fr}->{3522730} = "Capellen\/Kehlen";
$areanames{fr}->{3522731} = "Bertrange\/Mamer\/Munsbach\/Strassen";
$areanames{fr}->{3522732} = "Lintgen\/Mersch\/Steinfort";
$areanames{fr}->{3522733} = "Walferdange";
$areanames{fr}->{3522734} = "Rameldange\/Senningerberg";
$areanames{fr}->{3522735} = "Sandweiler\/Moutfort\/Roodt\-sur\-Syre";
$areanames{fr}->{3522736} = "Hesperange\/Kockelscheuer\/Roeser";
$areanames{fr}->{3522737} = "Leudelange\/Ehlange\/Mondercange";
$areanames{fr}->{3522739} = "Windhof\/Steinfort";
$areanames{fr}->{3522740} = "Howald";
$areanames{fr}->{3522742} = "Plateau\ de\ Kirchberg";
$areanames{fr}->{3522743} = "Findel\/Kirchberg";
$areanames{fr}->{3522745} = "Diedrich";
$areanames{fr}->{3522747} = "Lintgen";
$areanames{fr}->{3522748} = "Contern\/Foetz";
$areanames{fr}->{3522749} = "Howald";
$areanames{fr}->{3522750} = "Bascharage\/Petange\/Rodange";
$areanames{fr}->{3522751} = "Dudelange\/Bettembourg\/Livange";
$areanames{fr}->{3522752} = "Dudelange";
$areanames{fr}->{3522753} = "Esch\-sur\-Alzette";
$areanames{fr}->{3522754} = "Esch\-sur\-Alzette";
$areanames{fr}->{3522755} = "Esch\-sur\-Alzette\/Mondercange";
$areanames{fr}->{3522756} = "Rumelange";
$areanames{fr}->{3522757} = "Esch\-sur\-Alzette\/Schifflange";
$areanames{fr}->{3522758} = "Soleuvre\/Differdange";
$areanames{fr}->{3522759} = "Soleuvre";
$areanames{fr}->{3522767} = "Dudelange";
$areanames{fr}->{3522771} = "Betzdorf";
$areanames{fr}->{3522772} = "Echternach";
$areanames{fr}->{3522773} = "Rosport";
$areanames{fr}->{3522774} = "Wasserbillig";
$areanames{fr}->{3522775} = "Grevenmacher\-sur\-Moselle";
$areanames{fr}->{3522776} = "Wormeldange";
$areanames{fr}->{3522778} = "Junglinster";
$areanames{fr}->{3522779} = "Berdorf\/Consdorf";
$areanames{fr}->{3522780} = "Diekirch";
$areanames{fr}->{3522781} = "Ettelbruck\/Reckange\-sur\-Mess";
$areanames{fr}->{3522783} = "Vianden";
$areanames{fr}->{3522784} = "Han\/Lesse";
$areanames{fr}->{3522785} = "Bissen\/Roost";
$areanames{fr}->{3522787} = "Larochette";
$areanames{fr}->{3522788} = "Mertzig\/Wahl";
$areanames{fr}->{3522792} = "Clervaux\/Fischbach\/Hosingen";
$areanames{fr}->{3522795} = "Wiltz";
$areanames{fr}->{3522797} = "Huldange";
$areanames{fr}->{3522799} = "Troisvierges";
$areanames{fr}->{35228} = "Luxembourg\-Ville";
$areanames{fr}->{35229} = "Luxembourg\/Kockelscheuer";
$areanames{fr}->{35230} = "Capellen\/Kehlen";
$areanames{fr}->{35231} = "Bertrange\/Mamer\/Munsbach\/Strassen";
$areanames{fr}->{35232} = "Mersch";
$areanames{fr}->{35233} = "Walferdange";
$areanames{fr}->{35234} = "Rameldange\/Senningerberg";
$areanames{fr}->{35235} = "Sandweiler\/Moutfort\/Roodt\-sur\-Syre";
$areanames{fr}->{35236} = "Hesperange\/Kockelscheuer\/Roeser";
$areanames{fr}->{35237} = "Leudelange\/Ehlange\/Mondercange";
$areanames{fr}->{35239} = "Windhof\/Steinfort";
$areanames{fr}->{35240} = "Howald";
$areanames{fr}->{35241} = "Luxembourg\-Ville";
$areanames{fr}->{35242} = "Plateau\ de\ Kirchberg";
$areanames{fr}->{35243} = "Findel\/Kirchberg";
$areanames{fr}->{35244} = "Luxembourg\-Ville";
$areanames{fr}->{35245} = "Diedrich";
$areanames{fr}->{35246} = "Luxembourg\-Ville";
$areanames{fr}->{35247} = "Lintgen";
$areanames{fr}->{35248} = "Contern\/Foetz";
$areanames{fr}->{35249} = "Howald";
$areanames{fr}->{35250} = "Bascharage\/Petange\/Rodange";
$areanames{fr}->{35251} = "Dudelange\/Bettembourg\/Livange";
$areanames{fr}->{35252} = "Dudelange";
$areanames{fr}->{35253} = "Esch\-sur\-Alzette";
$areanames{fr}->{35254} = "Esch\-sur\-Alzette";
$areanames{fr}->{35255} = "Esch\-sur\-Alzette\/Mondercange";
$areanames{fr}->{35256} = "Rumelange";
$areanames{fr}->{35257} = "Esch\-sur\-Alzette\/Schifflange";
$areanames{fr}->{35258} = "Differdange";
$areanames{fr}->{35259} = "Soleuvre";
$areanames{fr}->{35267} = "Dudelange";
$areanames{fr}->{35271} = "Betzdorf";
$areanames{fr}->{35272} = "Echternach";
$areanames{fr}->{35273} = "Rosport";
$areanames{fr}->{35274} = "Wasserbillig";
$areanames{fr}->{35275} = "Grevenmacher";
$areanames{fr}->{35276} = "Wormeldange";
$areanames{fr}->{35278} = "Junglinster";
$areanames{fr}->{35279} = "Berdorf\/Consdorf";
$areanames{fr}->{35280} = "Diekirch";
$areanames{fr}->{35281} = "Ettelbruck";
$areanames{fr}->{35283} = "Vianden";
$areanames{fr}->{35284} = "Han\/Lesse";
$areanames{fr}->{35285} = "Bissen\/Roost";
$areanames{fr}->{35287} = "Larochette";
$areanames{fr}->{35288} = "Mertzig\/Wahl";
$areanames{fr}->{35292} = "Clervaux\/Fischbach\/Hosingen";
$areanames{fr}->{35295} = "Wiltz";
$areanames{fr}->{35297} = "Huldange";
$areanames{fr}->{35299} = "Troisvierges";
$areanames{en}->{35222} = "Luxembourg\ City";
$areanames{en}->{35223} = "Mondorf\-les\-Bains\/Bascharage\/Noerdange\/Remich";
$areanames{en}->{352240} = "Luxembourg";
$areanames{en}->{352241} = "Luxembourg";
$areanames{en}->{3522420} = "Luxembourg";
$areanames{en}->{3522421} = "Weicherdange";
$areanames{en}->{3522422} = "Luxembourg\ City";
$areanames{en}->{3522423} = "Mondorf\-les\-Bains\/Bascharage\/Noerdange\/Remich";
$areanames{en}->{3522424} = "Luxembourg";
$areanames{en}->{3522425} = "Luxembourg";
$areanames{en}->{3522426} = "Luxembourg";
$areanames{en}->{3522427} = "Belair\,\ Luxembourg";
$areanames{en}->{3522428} = "Luxembourg\ City";
$areanames{en}->{3522429} = "Luxembourg\/Kockelscheuer";
$areanames{en}->{3522430} = "Capellen\/Kehlen";
$areanames{en}->{3522431} = "Bertrange\/Mamer\/Munsbach\/Strassen";
$areanames{en}->{3522432} = "Lintgen\/Mersch\/Steinfort";
$areanames{en}->{3522433} = "Walferdange";
$areanames{en}->{3522434} = "Rameldange\/Senningerberg";
$areanames{en}->{3522435} = "Sandweiler\/Moutfort\/Roodt\-sur\-Syre";
$areanames{en}->{3522436} = "Hesperange\/Kockelscheuer\/Roeser";
$areanames{en}->{3522437} = "Leudelange\/Ehlange\/Mondercange";
$areanames{en}->{3522438} = "Luxembourg";
$areanames{en}->{3522439} = "Windhof\/Steinfort";
$areanames{en}->{3522440} = "Howald";
$areanames{en}->{3522441} = "Luxembourg";
$areanames{en}->{3522442} = "Plateau\ de\ Kirchberg";
$areanames{en}->{3522443} = "Findel\/Kirchberg";
$areanames{en}->{3522444} = "Luxembourg";
$areanames{en}->{3522445} = "Diedrich";
$areanames{en}->{3522446} = "Luxembourg";
$areanames{en}->{3522447} = "Lintgen";
$areanames{en}->{3522448} = "Contern\/Foetz";
$areanames{en}->{3522449} = "Howald";
$areanames{en}->{3522450} = "Bascharage\/Petange\/Rodange";
$areanames{en}->{3522451} = "Dudelange\/Bettembourg\/Livange";
$areanames{en}->{3522452} = "Dudelange";
$areanames{en}->{3522453} = "Esch\-sur\-Alzette";
$areanames{en}->{3522454} = "Esch\-sur\-Alzette";
$areanames{en}->{3522455} = "Esch\-sur\-Alzette\/Mondercange";
$areanames{en}->{3522456} = "Rumelange";
$areanames{en}->{3522457} = "Esch\-sur\-Alzette\/Schifflange";
$areanames{en}->{3522458} = "Soleuvre\/Differdange";
$areanames{en}->{3522459} = "Soleuvre";
$areanames{en}->{352246} = "Luxembourg";
$areanames{en}->{3522467} = "Dudelange";
$areanames{en}->{3522470} = "Luxembourg";
$areanames{en}->{3522471} = "Betzdorf";
$areanames{en}->{3522472} = "Echternach";
$areanames{en}->{3522473} = "Rosport";
$areanames{en}->{3522474} = "Wasserbillig";
$areanames{en}->{3522475} = "Grevenmacher\-sur\-Moselle";
$areanames{en}->{3522476} = "Wormeldange";
$areanames{en}->{3522477} = "Luxembourg";
$areanames{en}->{3522478} = "Junglinster";
$areanames{en}->{3522479} = "Berdorf\/Consdorf";
$areanames{en}->{3522480} = "Diekirch";
$areanames{en}->{3522481} = "Ettelbruck\/Reckange\-sur\-Mess";
$areanames{en}->{3522482} = "Luxembourg";
$areanames{en}->{3522483} = "Vianden";
$areanames{en}->{3522484} = "Han\/Lesse";
$areanames{en}->{3522485} = "Bissen\/Roost";
$areanames{en}->{3522486} = "Luxembourg";
$areanames{en}->{3522487} = "Larochette";
$areanames{en}->{3522488} = "Mertzig\/Wahl";
$areanames{en}->{3522489} = "Luxembourg";
$areanames{en}->{352249} = "Luxembourg";
$areanames{en}->{3522492} = "Clervaux\/Fischbach\/Hosingen";
$areanames{en}->{3522495} = "Wiltz";
$areanames{en}->{3522497} = "Huldange";
$areanames{en}->{3522499} = "Troisvierges";
$areanames{en}->{35225} = "Luxembourg";
$areanames{en}->{3522621} = "Weicherdange";
$areanames{en}->{3522622} = "Luxembourg\ City";
$areanames{en}->{3522623} = "Mondorf\-les\-Bains\/Bascharage\/Noerdange\/Remich";
$areanames{en}->{3522625} = "Luxembourg";
$areanames{en}->{3522627} = "Belair\,\ Luxembourg";
$areanames{en}->{3522628} = "Luxembourg\ City";
$areanames{en}->{3522629} = "Luxembourg\/Kockelscheuer";
$areanames{en}->{3522630} = "Capellen\/Kehlen";
$areanames{en}->{3522631} = "Bertrange\/Mamer\/Munsbach\/Strassen";
$areanames{en}->{3522632} = "Lintgen\/Mersch\/Steinfort";
$areanames{en}->{3522633} = "Walferdange";
$areanames{en}->{3522634} = "Rameldange\/Senningerberg";
$areanames{en}->{3522635} = "Sandweiler\/Moutfort\/Roodt\-sur\-Syre";
$areanames{en}->{3522636} = "Hesperange\/Kockelscheuer\/Roeser";
$areanames{en}->{3522637} = "Leudelange\/Ehlange\/Mondercange";
$areanames{en}->{3522639} = "Windhof\/Steinfort";
$areanames{en}->{3522640} = "Howald";
$areanames{en}->{3522642} = "Plateau\ de\ Kirchberg";
$areanames{en}->{3522643} = "Findel\/Kirchberg";
$areanames{en}->{3522645} = "Diedrich";
$areanames{en}->{3522647} = "Lintgen";
$areanames{en}->{3522648} = "Contern\/Foetz";
$areanames{en}->{3522649} = "Howald";
$areanames{en}->{3522650} = "Bascharage\/Petange\/Rodange";
$areanames{en}->{3522651} = "Dudelange\/Bettembourg\/Livange";
$areanames{en}->{3522652} = "Dudelange";
$areanames{en}->{3522653} = "Esch\-sur\-Alzette";
$areanames{en}->{3522654} = "Esch\-sur\-Alzette";
$areanames{en}->{3522655} = "Esch\-sur\-Alzette\/Mondercange";
$areanames{en}->{3522656} = "Rumelange";
$areanames{en}->{3522657} = "Esch\-sur\-Alzette\/Schifflange";
$areanames{en}->{3522658} = "Soleuvre\/Differdange";
$areanames{en}->{3522659} = "Soleuvre";
$areanames{en}->{3522667} = "Dudelange";
$areanames{en}->{3522671} = "Betzdorf";
$areanames{en}->{3522672} = "Echternach";
$areanames{en}->{3522673} = "Rosport";
$areanames{en}->{3522674} = "Wasserbillig";
$areanames{en}->{3522675} = "Grevenmacher\-sur\-Moselle";
$areanames{en}->{3522676} = "Wormeldange";
$areanames{en}->{3522678} = "Junglinster";
$areanames{en}->{3522679} = "Berdorf\/Consdorf";
$areanames{en}->{3522680} = "Diekirch";
$areanames{en}->{3522681} = "Ettelbruck\/Reckange\-sur\-Mess";
$areanames{en}->{3522683} = "Vianden";
$areanames{en}->{3522684} = "Han\/Lesse";
$areanames{en}->{3522685} = "Bissen\/Roost";
$areanames{en}->{3522687} = "Larochette";
$areanames{en}->{3522688} = "Mertzig\/Wahl";
$areanames{en}->{3522692} = "Clervaux\/Fischbach\/Hosingen";
$areanames{en}->{3522695} = "Wiltz";
$areanames{en}->{3522697} = "Huldange";
$areanames{en}->{3522699} = "Troisvierges";
$areanames{en}->{3522721} = "Weicherdange";
$areanames{en}->{3522722} = "Luxembourg\ City";
$areanames{en}->{3522723} = "Mondorf\-les\-Bains\/Bascharage\/Noerdange\/Remich";
$areanames{en}->{3522725} = "Luxembourg";
$areanames{en}->{3522727} = "Belair\,\ Luxembourg";
$areanames{en}->{3522728} = "Luxembourg\ City";
$areanames{en}->{3522729} = "Luxembourg\/Kockelscheuer";
$areanames{en}->{3522730} = "Capellen\/Kehlen";
$areanames{en}->{3522731} = "Bertrange\/Mamer\/Munsbach\/Strassen";
$areanames{en}->{3522732} = "Lintgen\/Mersch\/Steinfort";
$areanames{en}->{3522733} = "Walferdange";
$areanames{en}->{3522734} = "Rameldange\/Senningerberg";
$areanames{en}->{3522735} = "Sandweiler\/Moutfort\/Roodt\-sur\-Syre";
$areanames{en}->{3522736} = "Hesperange\/Kockelscheuer\/Roeser";
$areanames{en}->{3522737} = "Leudelange\/Ehlange\/Mondercange";
$areanames{en}->{3522739} = "Windhof\/Steinfort";
$areanames{en}->{3522740} = "Howald";
$areanames{en}->{3522742} = "Plateau\ de\ Kirchberg";
$areanames{en}->{3522743} = "Findel\/Kirchberg";
$areanames{en}->{3522745} = "Diedrich";
$areanames{en}->{3522747} = "Lintgen";
$areanames{en}->{3522748} = "Contern\/Foetz";
$areanames{en}->{3522749} = "Howald";
$areanames{en}->{3522750} = "Bascharage\/Petange\/Rodange";
$areanames{en}->{3522751} = "Dudelange\/Bettembourg\/Livange";
$areanames{en}->{3522752} = "Dudelange";
$areanames{en}->{3522753} = "Esch\-sur\-Alzette";
$areanames{en}->{3522754} = "Esch\-sur\-Alzette";
$areanames{en}->{3522755} = "Esch\-sur\-Alzette\/Mondercange";
$areanames{en}->{3522756} = "Rumelange";
$areanames{en}->{3522757} = "Esch\-sur\-Alzette\/Schifflange";
$areanames{en}->{3522758} = "Soleuvre\/Differdange";
$areanames{en}->{3522759} = "Soleuvre";
$areanames{en}->{3522767} = "Dudelange";
$areanames{en}->{3522771} = "Betzdorf";
$areanames{en}->{3522772} = "Echternach";
$areanames{en}->{3522773} = "Rosport";
$areanames{en}->{3522774} = "Wasserbillig";
$areanames{en}->{3522775} = "Grevenmacher\-sur\-Moselle";
$areanames{en}->{3522776} = "Wormeldange";
$areanames{en}->{3522778} = "Junglinster";
$areanames{en}->{3522779} = "Berdorf\/Consdorf";
$areanames{en}->{3522780} = "Diekirch";
$areanames{en}->{3522781} = "Ettelbruck\/Reckange\-sur\-Mess";
$areanames{en}->{3522783} = "Vianden";
$areanames{en}->{3522784} = "Han\/Lesse";
$areanames{en}->{3522785} = "Bissen\/Roost";
$areanames{en}->{3522787} = "Larochette";
$areanames{en}->{3522788} = "Mertzig\/Wahl";
$areanames{en}->{3522792} = "Clervaux\/Fischbach\/Hosingen";
$areanames{en}->{3522795} = "Wiltz";
$areanames{en}->{3522797} = "Huldange";
$areanames{en}->{3522799} = "Troisvierges";
$areanames{en}->{35228} = "Luxembourg\ City";
$areanames{en}->{35229} = "Luxembourg\/Kockelscheuer";
$areanames{en}->{35230} = "Capellen\/Kehlen";
$areanames{en}->{35231} = "Bertrange\/Mamer\/Munsbach\/Strassen";
$areanames{en}->{35232} = "Mersch";
$areanames{en}->{35233} = "Walferdange";
$areanames{en}->{35234} = "Rameldange\/Senningerberg";
$areanames{en}->{35235} = "Sandweiler\/Moutfort\/Roodt\-sur\-Syre";
$areanames{en}->{35236} = "Hesperange\/Kockelscheuer\/Roeser";
$areanames{en}->{35237} = "Leudelange\/Ehlange\/Mondercange";
$areanames{en}->{35239} = "Windhof\/Steinfort";
$areanames{en}->{35240} = "Howald";
$areanames{en}->{35241} = "Luxembourg\ City";
$areanames{en}->{35242} = "Plateau\ de\ Kirchberg";
$areanames{en}->{35243} = "Findel\/Kirchberg";
$areanames{en}->{35244} = "Luxembourg\ City";
$areanames{en}->{35245} = "Diedrich";
$areanames{en}->{35246} = "Luxembourg\ City";
$areanames{en}->{35247} = "Lintgen";
$areanames{en}->{35248} = "Contern\/Foetz";
$areanames{en}->{35249} = "Howald";
$areanames{en}->{35250} = "Bascharage\/Petange\/Rodange";
$areanames{en}->{35251} = "Dudelange\/Bettembourg\/Livange";
$areanames{en}->{35252} = "Dudelange";
$areanames{en}->{35253} = "Esch\-sur\-Alzette";
$areanames{en}->{35254} = "Esch\-sur\-Alzette";
$areanames{en}->{35255} = "Esch\-sur\-Alzette\/Mondercange";
$areanames{en}->{35256} = "Rumelange";
$areanames{en}->{35257} = "Esch\-sur\-Alzette\/Schifflange";
$areanames{en}->{35258} = "Differdange";
$areanames{en}->{35259} = "Soleuvre";
$areanames{en}->{35267} = "Dudelange";
$areanames{en}->{35271} = "Betzdorf";
$areanames{en}->{35272} = "Echternach";
$areanames{en}->{35273} = "Rosport";
$areanames{en}->{35274} = "Wasserbillig";
$areanames{en}->{35275} = "Grevenmacher";
$areanames{en}->{35276} = "Wormeldange";
$areanames{en}->{35278} = "Junglinster";
$areanames{en}->{35279} = "Berdorf\/Consdorf";
$areanames{en}->{35280} = "Diekirch";
$areanames{en}->{35281} = "Ettelbruck";
$areanames{en}->{35283} = "Vianden";
$areanames{en}->{35284} = "Han\/Lesse";
$areanames{en}->{35285} = "Bissen\/Roost";
$areanames{en}->{35287} = "Larochette";
$areanames{en}->{35288} = "Mertzig\/Wahl";
$areanames{en}->{35292} = "Clervaux\/Fischbach\/Hosingen";
$areanames{en}->{35295} = "Wiltz";
$areanames{en}->{35297} = "Huldange";
$areanames{en}->{35299} = "Troisvierges";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+352|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:(15(?:0[06]|1[12]|[35]5|4[04]|6[26]|77|88|99)\d))//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;