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
package Number::Phone::StubCountry::NA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200606132001;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '88',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '6',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '87',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          6(?:
            1(?:
              [02-4]\\d\\d|
              17
            )|
            2(?:
              17|
              54\\d|
              69|
              70
            )|
            3(?:
              17|
              2[0237]\\d|
              34|
              6[289]|
              7[01]|
              81
            )|
            4(?:
              17|
              (?:
                27|
                41|
                5[25]
              )\\d|
              69|
              7[01]
            )|
            5(?:
              17|
              2[236-8]\\d|
              69|
              7[01]
            )|
            6(?:
              17|
              26\\d|
              38|
              42|
              69|
              7[01]
            )|
            7(?:
              17|
              (?:
                2[2-4]|
                30
              )\\d|
              6[89]|
              7[01]
            )
          )\\d{4}|
          6(?:
            1(?:
              2[2-7]|
              3[01378]|
              4[0-4]|
              69|
              7[014]
            )|
            25[0-46-8]|
            32\\d|
            4(?:
              2[0-27]|
              4[016]|
              5[0-357]
            )|
            52[02-9]|
            62[56]|
            7(?:
              2[2-69]|
              3[013]
            )
          )\\d{4}
        ',
                'geographic' => '
          6(?:
            1(?:
              [02-4]\\d\\d|
              17
            )|
            2(?:
              17|
              54\\d|
              69|
              70
            )|
            3(?:
              17|
              2[0237]\\d|
              34|
              6[289]|
              7[01]|
              81
            )|
            4(?:
              17|
              (?:
                27|
                41|
                5[25]
              )\\d|
              69|
              7[01]
            )|
            5(?:
              17|
              2[236-8]\\d|
              69|
              7[01]
            )|
            6(?:
              17|
              26\\d|
              38|
              42|
              69|
              7[01]
            )|
            7(?:
              17|
              (?:
                2[2-4]|
                30
              )\\d|
              6[89]|
              7[01]
            )
          )\\d{4}|
          6(?:
            1(?:
              2[2-7]|
              3[01378]|
              4[0-4]|
              69|
              7[014]
            )|
            25[0-46-8]|
            32\\d|
            4(?:
              2[0-27]|
              4[016]|
              5[0-357]
            )|
            52[02-9]|
            62[56]|
            7(?:
              2[2-69]|
              3[013]
            )
          )\\d{4}
        ',
                'mobile' => '
          (?:
            60|
            8[1245]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(8701\\d{5})',
                'toll_free' => '80\\d{7}',
                'voip' => '
          8(?:
            3\\d\\d|
            86
          )\\d{5}
        '
              };
my %areanames = ();
$areanames{en}->{26461} = "Windhoek";
$areanames{en}->{264621730} = "Babi\-Babi";
$areanames{en}->{264621732} = "Buitepos";
$areanames{en}->{264621734} = "Drimiopsis";
$areanames{en}->{264621735} = "Eland";
$areanames{en}->{264621737} = "Friedental";
$areanames{en}->{264621738} = "Gobabis";
$areanames{en}->{264621739} = "Gobabis";
$areanames{en}->{264621740} = "Gobabis";
$areanames{en}->{264621741} = "Groot\–Aub";
$areanames{en}->{264621743} = "Hochland";
$areanames{en}->{264621746} = "Many\ Hills";
$areanames{en}->{264621747} = "Namib\ Grens";
$areanames{en}->{264621748} = "Nina";
$areanames{en}->{264621750} = "Okahandja";
$areanames{en}->{264621751} = "Okahandja";
$areanames{en}->{264621752} = "Okahandja";
$areanames{en}->{264621754} = "Ombotozu";
$areanames{en}->{264621755} = "Omitara";
$areanames{en}->{264621756} = "Otjihase";
$areanames{en}->{264621759} = "Otjozondu";
$areanames{en}->{264621760} = "Plessisplaas";
$areanames{en}->{264621761} = "Rehoboth";
$areanames{en}->{264621762} = "Rehoboth";
$areanames{en}->{264621763} = "Rehoboth";
$areanames{en}->{264621766} = "Sandveld";
$areanames{en}->{264621767} = "Seeis";
$areanames{en}->{264621768} = "Spatzenfeld";
$areanames{en}->{264621769} = "Steinhausen";
$areanames{en}->{264621770} = "Summerdown";
$areanames{en}->{264621771} = "Hosea\ Kutako\ INT\ Airport";
$areanames{en}->{264621772} = "Witvlei";
$areanames{en}->{26462500} = "Okahandja";
$areanames{en}->{26462501} = "Okahandja";
$areanames{en}->{26462502} = "Okahandja";
$areanames{en}->{26462503} = "Okahandja\/Ovitoto\/Wilhelmstal";
$areanames{en}->{26462504} = "Okahandja";
$areanames{en}->{26462505} = "Okahandja";
$areanames{en}->{264625180} = "Otjozondu";
$areanames{en}->{264625181} = "Otjozondu";
$areanames{en}->{264625183} = "Ombotozu";
$areanames{en}->{264625184} = "Ombotozu";
$areanames{en}->{26462519} = "Okandjatu";
$areanames{en}->{26462522} = "Rehoboth";
$areanames{en}->{26462523} = "Rehoboth";
$areanames{en}->{26462524} = "Rehoboth";
$areanames{en}->{26462525} = "Rehoboth";
$areanames{en}->{264625390} = "Klein\ Aub";
$areanames{en}->{264625391} = "Klein\ Aub";
$areanames{en}->{264625392} = "Rietoog";
$areanames{en}->{264625393} = "Rietoog";
$areanames{en}->{26462540} = "Neudamm\/Hosea\ Kutako\ INT\ Airport";
$areanames{en}->{264625410} = "Otjihase";
$areanames{en}->{264625411} = "Otjihase";
$areanames{en}->{264625420} = "Groot\–Aub";
$areanames{en}->{264625421} = "Groot\–Aub";
$areanames{en}->{264625430} = "Hosea\ Kutako\ INT\ Airport";
$areanames{en}->{264625434} = "Hosea\ Kutako\ INT\ Airport";
$areanames{en}->{264625435} = "Hosea\ Kutako\ INT\ Airport";
$areanames{en}->{26462549} = "Hochfeld";
$areanames{en}->{264625600} = "Seeis";
$areanames{en}->{264625601} = "Seeis";
$areanames{en}->{264625602} = "Omitara";
$areanames{en}->{264625603} = "Omitara";
$areanames{en}->{264625604} = "Buitepos";
$areanames{en}->{264625605} = "Otjiwa";
$areanames{en}->{264625606} = "Otjiwa";
$areanames{en}->{264625607} = "Otjiwa";
$areanames{en}->{264625608} = "Otjiwa";
$areanames{en}->{264625609} = "Otjiwa";
$areanames{en}->{264625610} = "Otjiwa";
$areanames{en}->{264625611} = "Otjiwa";
$areanames{en}->{264625612} = "Otjiwa";
$areanames{en}->{264625613} = "Otjiwa";
$areanames{en}->{264625614} = "Steinhausen";
$areanames{en}->{264625615} = "Steinhausen";
$areanames{en}->{264625616} = "Summerdown";
$areanames{en}->{264625617} = "Summerdown";
$areanames{en}->{264625618} = "Summerdown";
$areanames{en}->{26462562} = "Gobabis";
$areanames{en}->{26462563} = "Gobabis";
$areanames{en}->{26462564} = "Gobabis";
$areanames{en}->{26462565} = "Gobabis";
$areanames{en}->{26462566} = "Gobabis";
$areanames{en}->{264625672} = "Epukiro";
$areanames{en}->{264625673} = "Epukiro";
$areanames{en}->{264625674} = "Epukiro";
$areanames{en}->{264625675} = "Otjinene";
$areanames{en}->{264625676} = "Otjinene";
$areanames{en}->{264625677} = "Otjinene";
$areanames{en}->{264625678} = "Otjinene";
$areanames{en}->{264625679} = "Otjinene";
$areanames{en}->{264625680} = "Drimiopsis";
$areanames{en}->{264625681} = "Drimiopsis";
$areanames{en}->{264625682} = "Plessisplaas";
$areanames{en}->{264625683} = "Plessisplaas";
$areanames{en}->{264625684} = "Sandveld";
$areanames{en}->{264625685} = "Sandveld";
$areanames{en}->{264625686} = "Epukiro";
$areanames{en}->{264625687} = "Epukiro";
$areanames{en}->{264625688} = "Epukiro";
$areanames{en}->{264625689} = "Babi\-Babi";
$areanames{en}->{264625690} = "Babi\-Babi";
$areanames{en}->{264625691} = "Leonardville";
$areanames{en}->{264625692} = "Leonardville";
$areanames{en}->{264625693} = "Leonardville";
$areanames{en}->{264625694} = "Leonardville";
$areanames{en}->{264625695} = "Leonardville";
$areanames{en}->{264625696} = "Leonardville";
$areanames{en}->{264625697} = "Blumfelde";
$areanames{en}->{264625698} = "Blumfelde";
$areanames{en}->{264625700} = "Witvlei";
$areanames{en}->{264625701} = "Witvlei";
$areanames{en}->{264625702} = "Witvlei";
$areanames{en}->{264625703} = "Witvlei";
$areanames{en}->{264625704} = "Witvlei";
$areanames{en}->{264625709} = "Witvlei";
$areanames{en}->{264625715} = "Eland";
$areanames{en}->{264625716} = "Eland";
$areanames{en}->{264625717} = "Spatzenfeld";
$areanames{en}->{264625718} = "Spatzenfeld";
$areanames{en}->{264625720} = "Namib\ Grens";
$areanames{en}->{264625721} = "Friedental";
$areanames{en}->{264625722} = "Hochland";
$areanames{en}->{264625723} = "Many\ Hills";
$areanames{en}->{26462573} = "Dordabis";
$areanames{en}->{264625731} = "Nina";
$areanames{en}->{264625733} = "Nouas";
$areanames{en}->{26462577} = "Gobabis";
$areanames{en}->{264625800} = "Epukiro";
$areanames{en}->{264625801} = "Epukiro";
$areanames{en}->{264625802} = "Epukiro";
$areanames{en}->{264625803} = "Epukiro";
$areanames{en}->{264625804} = "Eland";
$areanames{en}->{264625805} = "Drimiopsis";
$areanames{en}->{264625806} = "Summerdown";
$areanames{en}->{264625807} = "Plessisplaas";
$areanames{en}->{264625808} = "Otjinene";
$areanames{en}->{264625809} = "Otjiwa";
$areanames{en}->{264625810} = "Leonardville";
$areanames{en}->{264625811} = "Leonardville";
$areanames{en}->{264625812} = "Blumfelde";
$areanames{en}->{264625813} = "Blumfelde";
$areanames{en}->{264625814} = "Nouas";
$areanames{en}->{264625815} = "Nouas";
$areanames{en}->{264625816} = "Nina";
$areanames{en}->{264625817} = "Nina";
$areanames{en}->{264625818} = "Dordabis";
$areanames{en}->{264625819} = "Dordabis";
$areanames{en}->{26462692} = "Central";
$areanames{en}->{264627024} = "Hosea\ Kutako\ INT\ Airport";
$areanames{en}->{264627025} = "Hosea\ Kutako\ INT\ Airport";
$areanames{en}->{264631701} = "Aminuis";
$areanames{en}->{264631702} = "Aminuis";
$areanames{en}->{264631703} = "Aranos";
$areanames{en}->{264631704} = "Ariamsvlei";
$areanames{en}->{264631706} = "Asab";
$areanames{en}->{264631709} = "Bethanie";
$areanames{en}->{264631710} = "Bethanie";
$areanames{en}->{264631711} = "Bralano";
$areanames{en}->{264631712} = "Bulwana";
$areanames{en}->{264631713} = "Dawiab";
$areanames{en}->{264631714} = "Deurstamp";
$areanames{en}->{264631715} = "Feldschuhorn";
$areanames{en}->{264631717} = "Gibeon";
$areanames{en}->{264631718} = "Goageb";
$areanames{en}->{264631719} = "Gochas";
$areanames{en}->{264631720} = "Grenslyn";
$areanames{en}->{264631722} = "Guibis";
$areanames{en}->{264631723} = "Hamab";
$areanames{en}->{264631724} = "Helmeringhausen";
$areanames{en}->{264631725} = "Hoachanas";
$areanames{en}->{264631727} = "Kalahariplaas";
$areanames{en}->{264631728} = "Kalkrand";
$areanames{en}->{264631729} = "Kalkrand";
$areanames{en}->{264631730} = "Karasburg";
$areanames{en}->{264631731} = "Karasburg";
$areanames{en}->{264631732} = "Karasburg";
$areanames{en}->{264631733} = "Karasburg";
$areanames{en}->{264631734} = "Karasburg";
$areanames{en}->{264631735} = "Keetmanshoop";
$areanames{en}->{264631736} = "Keetmanshoop";
$areanames{en}->{264631737} = "Keetmanshoop";
$areanames{en}->{264631738} = "Keetmanshoop";
$areanames{en}->{264631739} = "Keetmanshoop";
$areanames{en}->{264631740} = "Klein\ Karas";
$areanames{en}->{264631743} = "Lorelei";
$areanames{en}->{264631744} = "Luderitz";
$areanames{en}->{264631745} = "Luderitz";
$areanames{en}->{264631746} = "Luderitz";
$areanames{en}->{264631747} = "Luderitz";
$areanames{en}->{264631748} = "Luderitz";
$areanames{en}->{264631749} = "Maltahohe";
$areanames{en}->{264631750} = "Maltahohe";
$areanames{en}->{264631751} = "Mariental";
$areanames{en}->{264631752} = "Mariental";
$areanames{en}->{264631753} = "Mariental";
$areanames{en}->{264631754} = "Mariental";
$areanames{en}->{264631755} = "Mariental";
$areanames{en}->{264631759} = "Noordoewer";
$areanames{en}->{264631760} = "Noordoewer";
$areanames{en}->{264631762} = "Oamseb";
$areanames{en}->{264631763} = "Oranjemund";
$areanames{en}->{264631764} = "Oranjemund";
$areanames{en}->{264631765} = "Oranjemund";
$areanames{en}->{264631766} = "Oranjemund";
$areanames{en}->{264631767} = "Oranjemund";
$areanames{en}->{264631769} = "Rosh\ Pinah";
$areanames{en}->{264631770} = "Rosh\ Pinah";
$areanames{en}->{264631771} = "Schilp";
$areanames{en}->{264631772} = "Seeheim";
$areanames{en}->{264631774} = "Stampriet";
$areanames{en}->{264631775} = "Stinkdoring";
$areanames{en}->{264631776} = "Tses";
$areanames{en}->{264631777} = "Tsumispark";
$areanames{en}->{264631778} = "Uhabis";
$areanames{en}->{264631779} = "Warmbad";
$areanames{en}->{26463200} = "Luderitz";
$areanames{en}->{26463201} = "Luderitz";
$areanames{en}->{26463202} = "Luderitz";
$areanames{en}->{26463203} = "Luderitz";
$areanames{en}->{26463204} = "Luderitz";
$areanames{en}->{26463207} = "Luderitz";
$areanames{en}->{26463210} = "Luderitz";
$areanames{en}->{26463220} = "Keetmanshoop";
$areanames{en}->{26463221} = "Keetmanshoop";
$areanames{en}->{26463222} = "Keetmanshoop";
$areanames{en}->{26463223} = "Keetmanshoop";
$areanames{en}->{26463224} = "Keetmanshoop";
$areanames{en}->{264632260} = "Keetmanshoop";
$areanames{en}->{264632261} = "Keetmanshoop";
$areanames{en}->{264632264} = "Deurstamp";
$areanames{en}->{264632267} = "Feldschuhorn";
$areanames{en}->{26463227} = "Keetmanshoop";
$areanames{en}->{26463228} = "Keetmanshoop";
$areanames{en}->{26463229} = "Keetmanshoop";
$areanames{en}->{264632300} = "Oranjemund";
$areanames{en}->{264632307} = "Oranjemund";
$areanames{en}->{264632308} = "Oranjemund";
$areanames{en}->{264632309} = "Oranjemund";
$areanames{en}->{26463232} = "Oranjemund";
$areanames{en}->{26463233} = "Oranjemund";
$areanames{en}->{26463234} = "Oranjemund";
$areanames{en}->{26463235} = "Oranjemund";
$areanames{en}->{26463236} = "Oranjemund";
$areanames{en}->{26463237} = "Oranjemund";
$areanames{en}->{264632380} = "Oranjemund";
$areanames{en}->{264632381} = "Oranjemund";
$areanames{en}->{264632382} = "Luderitz";
$areanames{en}->{264632383} = "Luderitz";
$areanames{en}->{264632384} = "Oranjemund";
$areanames{en}->{264632385} = "Oranjemund";
$areanames{en}->{264632386} = "Oranjemund";
$areanames{en}->{264632387} = "Oranjemund";
$areanames{en}->{264632389} = "Luderitz\ \-\ Elizabeth\ Bay";
$areanames{en}->{26463239} = "Oranjemund";
$areanames{en}->{264632403} = "Mariental";
$areanames{en}->{264632404} = "Mariental";
$areanames{en}->{264632405} = "Mariental";
$areanames{en}->{264632406} = "Mariental";
$areanames{en}->{264632407} = "Mariental";
$areanames{en}->{264632408} = "Mariental";
$areanames{en}->{264632409} = "Mariental";
$areanames{en}->{26463241} = "Mariental";
$areanames{en}->{26463242} = "Mariental";
$areanames{en}->{26463243} = "Mariental";
$areanames{en}->{26463244} = "Mariental";
$areanames{en}->{26463246} = "Mariental";
$areanames{en}->{26463247} = "Mariental";
$areanames{en}->{26463248} = "Mariental";
$areanames{en}->{264632492} = "Mariental";
$areanames{en}->{264632500} = "Gochas";
$areanames{en}->{264632501} = "Gochas";
$areanames{en}->{264632502} = "Gochas";
$areanames{en}->{264632505} = "Seeheim";
$areanames{en}->{264632507} = "Narubis";
$areanames{en}->{26463251} = "Gibeon";
$areanames{en}->{264632520} = "Grenslyn";
$areanames{en}->{264632522} = "Asab";
$areanames{en}->{264632523} = "Asab";
$areanames{en}->{264632524} = "Bulwana";
$areanames{en}->{26463257} = "Tses";
$areanames{en}->{264632580} = "Aus";
$areanames{en}->{264632581} = "Aus";
$areanames{en}->{264632583} = "Guibis";
$areanames{en}->{264632589} = "Aus";
$areanames{en}->{26463260} = "Stampriet";
$areanames{en}->{264632610} = "Oamseb";
$areanames{en}->{264632611} = "Oamseb";
$areanames{en}->{26463262} = "Grunau";
$areanames{en}->{26463264} = "Kalkrand";
$areanames{en}->{264632650} = "Schilp";
$areanames{en}->{264632651} = "Schilp";
$areanames{en}->{264632653} = "Hoachanas";
$areanames{en}->{264632654} = "Hoachanas";
$areanames{en}->{264632655} = "Tsumispark";
$areanames{en}->{264632656} = "Tsumispark";
$areanames{en}->{264632657} = "Tsumispark";
$areanames{en}->{264632660} = "Klein\ Karas";
$areanames{en}->{264632690} = "Warmbad";
$areanames{en}->{264632691} = "Warmbad";
$areanames{en}->{264632693} = "Hamab";
$areanames{en}->{264632696} = "Stinkdoring";
$areanames{en}->{264632699} = "Uhabis";
$areanames{en}->{26463270} = "Karasburg";
$areanames{en}->{264632711} = "Karasburg";
$areanames{en}->{264632712} = "Karasburg";
$areanames{en}->{264632714} = "Karasburg";
$areanames{en}->{264632718} = "Karasburg";
$areanames{en}->{264632719} = "Karasburg";
$areanames{en}->{26463272} = "Aranos";
$areanames{en}->{264632730} = "Aminuis";
$areanames{en}->{264632731} = "Aminuis";
$areanames{en}->{264632732} = "Aminuis";
$areanames{en}->{264632733} = "Aminuis";
$areanames{en}->{26463274} = "Rosh\ Pinah";
$areanames{en}->{264632750} = "Kalahariplaas";
$areanames{en}->{264632752} = "Bralano";
$areanames{en}->{264632753} = "Bralano";
$areanames{en}->{264632754} = "Bralano";
$areanames{en}->{264632768} = "Aranos";
$areanames{en}->{264632769} = "Aranos";
$areanames{en}->{264632800} = "Ariamsvlei";
$areanames{en}->{264632801} = "Ariamsvlei";
$areanames{en}->{264632803} = "Dawiab";
$areanames{en}->{264632805} = "Aroab";
$areanames{en}->{264632806} = "Aroab";
$areanames{en}->{264632807} = "Aroab";
$areanames{en}->{264632808} = "Kais";
$areanames{en}->{264632809} = "Ariamsvlei";
$areanames{en}->{264632810} = "Köes";
$areanames{en}->{264632811} = "Gaibis";
$areanames{en}->{264632812} = "Deurstamp";
$areanames{en}->{264632830} = "Bethanie";
$areanames{en}->{264632831} = "Bethanie";
$areanames{en}->{264632833} = "Helmeringhausen";
$areanames{en}->{264632835} = "Goageb";
$areanames{en}->{264632837} = "Lorelei";
$areanames{en}->{264632839} = "Bethanie";
$areanames{en}->{264632849} = "Bethanie";
$areanames{en}->{264632900} = "Rosh\ Pinah";
$areanames{en}->{264632901} = "Rosh\ Pinah";
$areanames{en}->{264632902} = "Rosh\ Pinah";
$areanames{en}->{26463293} = "Maltahohe\/Solitaire";
$areanames{en}->{264632942} = "Kumakams";
$areanames{en}->{264632950} = "Namgorab";
$areanames{en}->{26463297} = "Noordoewer";
$areanames{en}->{26463345} = "Mariental";
$areanames{en}->{26463626} = "Helmeringhausen";
$areanames{en}->{26463683} = "Keetmanshoop";
$areanames{en}->{26463693} = "South";
$areanames{en}->{264637034} = "Keetmanshoop";
$areanames{en}->{264637035} = "Luderitz";
$areanames{en}->{264637100} = "Keetmanshoop";
$areanames{en}->{264637130} = "Keetmanshoop";
$areanames{en}->{264637180} = "Keetmanshoop";
$areanames{en}->{264637181} = "Keetmanshoop";
$areanames{en}->{264637182} = "Keetmanshoop";
$areanames{en}->{264637183} = "Keetmanshoop";
$areanames{en}->{264637184} = "Keetmanshoop";
$areanames{en}->{264637185} = "Keetmanshoop";
$areanames{en}->{264637190} = "Keetmanshoop";
$areanames{en}->{264637191} = "Keetmanshoop";
$areanames{en}->{264637192} = "Keetmanshoop";
$areanames{en}->{26463811} = "Keetmanshoop";
$areanames{en}->{264641700} = "Arandis";
$areanames{en}->{264641701} = "Arandis";
$areanames{en}->{264641702} = "Henties\ Bay";
$areanames{en}->{264641703} = "Henties\ Bay";
$areanames{en}->{264641704} = "Henties\ Bay";
$areanames{en}->{264641705} = "Henties\ Bay";
$areanames{en}->{264641706} = "Henties\ Bay";
$areanames{en}->{264641707} = "Karibib";
$areanames{en}->{264641708} = "Karibib";
$areanames{en}->{264641709} = "Langstrand";
$areanames{en}->{264641710} = "Langstrand";
$areanames{en}->{264641711} = "Langstrand";
$areanames{en}->{264641712} = "Leoburn";
$areanames{en}->{264641713} = "Omaruru";
$areanames{en}->{264641714} = "Omaruru";
$areanames{en}->{264641715} = "Omaruru";
$areanames{en}->{264641716} = "Omaruru";
$areanames{en}->{264641717} = "Omaruru";
$areanames{en}->{264641718} = "Omaruru";
$areanames{en}->{264641721} = "Rössing\ Mine";
$areanames{en}->{264641722} = "Rössing\ Mine";
$areanames{en}->{264641723} = "Swakopmund";
$areanames{en}->{264641724} = "Swakopmund";
$areanames{en}->{264641725} = "Swakopmund";
$areanames{en}->{264641726} = "Swakopmund";
$areanames{en}->{264641727} = "Swakopmund";
$areanames{en}->{264641728} = "Swakopmund";
$areanames{en}->{264641729} = "Swakopmund";
$areanames{en}->{26464173} = "Swakopmund";
$areanames{en}->{264641741} = "Swakopmund";
$areanames{en}->{264641742} = "Swakopmund";
$areanames{en}->{264641743} = "Tsaobis";
$areanames{en}->{264641746} = "Usakos";
$areanames{en}->{264641747} = "Usakos";
$areanames{en}->{264641748} = "Usakos";
$areanames{en}->{264641749} = "Usakos";
$areanames{en}->{26464175} = "Walvis\ Bay";
$areanames{en}->{26464176} = "Walvis\ Bay";
$areanames{en}->{2646420} = "Walvis\ Bay";
$areanames{en}->{26464210} = "Walvis\ Bay";
$areanames{en}->{264642110} = "Langstrand";
$areanames{en}->{264642111} = "Langstrand";
$areanames{en}->{264642112} = "Langstrand";
$areanames{en}->{264642118} = "Walvis\ Bay";
$areanames{en}->{264642119} = "Walvis\ Bay";
$areanames{en}->{26464219} = "Walvis\ Bay";
$areanames{en}->{26464220} = "Walvis\ Bay";
$areanames{en}->{26464221} = "Walvis\ Bay";
$areanames{en}->{26464270} = "Walvis\ Bay";
$areanames{en}->{26464271} = "Walvis\ Bay";
$areanames{en}->{26464272} = "Walvis\ Bay";
$areanames{en}->{26464273} = "Walvis\ Bay";
$areanames{en}->{26464274} = "Walvis\ Bay";
$areanames{en}->{26464275} = "Walvis\ Bay";
$areanames{en}->{26464276} = "Walvis\ Bay";
$areanames{en}->{26464400} = "Swakopmund";
$areanames{en}->{26464401} = "Swakopmund";
$areanames{en}->{26464402} = "Swakopmund";
$areanames{en}->{26464403} = "Swakopmund";
$areanames{en}->{26464404} = "Swakopmund";
$areanames{en}->{26464405} = "Swakopmund";
$areanames{en}->{26464406} = "Swakopmund";
$areanames{en}->{26464407} = "Swakopmund";
$areanames{en}->{2646441} = "Swakopmund";
$areanames{en}->{26464461} = "Swakopmund";
$areanames{en}->{26464462} = "Swakopmund";
$areanames{en}->{26464463} = "Swakopmund";
$areanames{en}->{26464464} = "Swakopmund";
$areanames{en}->{264644650} = "Swakopmund";
$areanames{en}->{26464500} = "Henties\ Bay";
$areanames{en}->{26464501} = "Henties\ Bay";
$areanames{en}->{26464502} = "Henties\ Bay";
$areanames{en}->{26464504} = "Uis";
$areanames{en}->{26464510} = "Arandis";
$areanames{en}->{26464511} = "Arandis";
$areanames{en}->{26464512} = "Arandis";
$areanames{en}->{26464520} = "Rössing\ Mine";
$areanames{en}->{264645212} = "Rössing\ Mine";
$areanames{en}->{264645213} = "Rössing\ Mine";
$areanames{en}->{264645214} = "Rössing\ Mine";
$areanames{en}->{264645219} = "Rössing\ Mine";
$areanames{en}->{264645220} = "Rössing\ Mine";
$areanames{en}->{264645221} = "Rössing\ Mine";
$areanames{en}->{26464530} = "Usakos";
$areanames{en}->{264645315} = "Usakos";
$areanames{en}->{264645316} = "Usakos";
$areanames{en}->{264645317} = "Usakos";
$areanames{en}->{264645318} = "Usakos";
$areanames{en}->{264645319} = "Usakos";
$areanames{en}->{26464550} = "Karibib";
$areanames{en}->{264645508} = "Tsaobis\/Karibib";
$areanames{en}->{26464551} = "Otjimbingwe";
$areanames{en}->{264645520} = "Karibib";
$areanames{en}->{264645521} = "Karibib";
$areanames{en}->{264645537} = "Karibib";
$areanames{en}->{264645539} = "Karibib";
$areanames{en}->{26464570} = "Omaruru";
$areanames{en}->{264645710} = "Omaruru";
$areanames{en}->{264645711} = "Omaruru";
$areanames{en}->{264645712} = "Omaruru";
$areanames{en}->{264645713} = "Omaruru";
$areanames{en}->{264645714} = "Omaruru";
$areanames{en}->{26464572} = "Omaruru";
$areanames{en}->{26464573} = "Omaruru";
$areanames{en}->{26464694} = "Central";
$areanames{en}->{264647026} = "Walvis\ Bay";
$areanames{en}->{264647027} = "Walvis\ Bay";
$areanames{en}->{264647028} = "Swakopmund";
$areanames{en}->{264647100} = "Walvis\ Bay";
$areanames{en}->{264647130} = "Walvis\ Bay";
$areanames{en}->{264647162} = "Swakopmund";
$areanames{en}->{264647165} = "Walvis\ Bay";
$areanames{en}->{264647172} = "Swakopmund";
$areanames{en}->{264651701} = "Anamulenge";
$areanames{en}->{264651702} = "Blue\ Sodalite\ Mine";
$areanames{en}->{264651703} = "Edundja";
$areanames{en}->{264651704} = "Edundja";
$areanames{en}->{264651705} = "Eenhana";
$areanames{en}->{264651706} = "Eenhana";
$areanames{en}->{264651707} = "Ehomba";
$areanames{en}->{264651708} = "Elim";
$areanames{en}->{264651709} = "Elim";
$areanames{en}->{264651710} = "Endola";
$areanames{en}->{264651711} = "Etanga";
$areanames{en}->{264651712} = "Etunda";
$areanames{en}->{264651713} = "Etunda";
$areanames{en}->{264651714} = "Haiyandja";
$areanames{en}->{264651715} = "Kaoko\ Otavi";
$areanames{en}->{264651716} = "Kunene\ River\ Lodge";
$areanames{en}->{264651717} = "Mahenene";
$areanames{en}->{264651719} = "Ombombo";
$areanames{en}->{264651720} = "Odibo";
$areanames{en}->{264651721} = "Ogongo";
$areanames{en}->{264651722} = "Ohandungu";
$areanames{en}->{264651723} = "Ohangwena";
$areanames{en}->{264651724} = "Ohangwena";
$areanames{en}->{264651725} = "Ohangwena";
$areanames{en}->{264651726} = "Ohangwena";
$areanames{en}->{264651727} = "Okahao";
$areanames{en}->{264651728} = "Okalongo";
$areanames{en}->{264651729} = "Okangwati";
$areanames{en}->{264651730} = "Okatope";
$areanames{en}->{264651731} = "Okorosave";
$areanames{en}->{264651732} = "Oluno";
$areanames{en}->{264651733} = "Oluno";
$areanames{en}->{264651734} = "Oluno";
$areanames{en}->{264651735} = "Omafu";
$areanames{en}->{264651736} = "Ombalantu";
$areanames{en}->{264651737} = "Ombalantu";
$areanames{en}->{264651738} = "Ombalantu";
$areanames{en}->{264651739} = "Omungwelume";
$areanames{en}->{264651740} = "Omutsewonime";
$areanames{en}->{264651741} = "Onandjokwe";
$areanames{en}->{264651742} = "Onathinge";
$areanames{en}->{264651743} = "Ondangwa";
$areanames{en}->{264651744} = "Ondangwa";
$areanames{en}->{264651745} = "Ondangwa";
$areanames{en}->{264651746} = "Ondangwa";
$areanames{en}->{264651747} = "Ondangwa";
$areanames{en}->{264651748} = "Ondobe";
$areanames{en}->{264651749} = "Onuno";
$areanames{en}->{264651751} = "Onesi";
$areanames{en}->{264651752} = "Ongenga";
$areanames{en}->{264651753} = "Ongha";
$areanames{en}->{264651754} = "Ongha";
$areanames{en}->{264651756} = "Ongwediva";
$areanames{en}->{264651757} = "Ongwediva";
$areanames{en}->{264651759} = "Ondundu";
$areanames{en}->{264651760} = "Opuwo";
$areanames{en}->{264651761} = "Opuwo";
$areanames{en}->{264651762} = "Orumana";
$areanames{en}->{264651763} = "Oshakati";
$areanames{en}->{264651764} = "Oshakati";
$areanames{en}->{264651765} = "Oshakati";
$areanames{en}->{264651766} = "Oshakati";
$areanames{en}->{264651767} = "Oshakati";
$areanames{en}->{264651768} = "Oshifo";
$areanames{en}->{264651769} = "Oshigambo";
$areanames{en}->{264651770} = "Oshikango";
$areanames{en}->{264651771} = "Oshikuku";
$areanames{en}->{264651772} = "Oshitayi";
$areanames{en}->{264651773} = "Otjondeka";
$areanames{en}->{264651774} = "Otwani";
$areanames{en}->{264651775} = "Panosa";
$areanames{en}->{264651776} = "Ruacana";
$areanames{en}->{264651777} = "Ruacana";
$areanames{en}->{264651778} = "Sesfontein";
$areanames{en}->{264651781} = "Tsandi";
$areanames{en}->{264651782} = "Tsandi";
$areanames{en}->{264651783} = "Warmquelle";
$areanames{en}->{2646520} = "Oshakati";
$areanames{en}->{26465200} = "Ombalantu";
$areanames{en}->{26465220} = "Oshakati";
$areanames{en}->{26465221} = "Oshakati";
$areanames{en}->{26465222} = "Oshakati";
$areanames{en}->{26465223} = "Oshakati";
$areanames{en}->{26465224} = "Oshakati";
$areanames{en}->{26465225} = "Oshakati";
$areanames{en}->{26465226} = "Oshakati";
$areanames{en}->{26465227} = "Oshakati";
$areanames{en}->{264652290} = "Oshakati";
$areanames{en}->{26465230} = "Ongwediva";
$areanames{en}->{26465231} = "Ongwediva";
$areanames{en}->{264652320} = "Ongwediva";
$areanames{en}->{264652321} = "Ongwediva";
$areanames{en}->{264652324} = "Ongwediva";
$areanames{en}->{264652325} = "Ongwediva";
$areanames{en}->{264652327} = "Ongwediva";
$areanames{en}->{264652328} = "Ongwediva";
$areanames{en}->{264652329} = "Ongwediva";
$areanames{en}->{26465233} = "Ongwediva";
$areanames{en}->{26465234} = "Ongwediva";
$areanames{en}->{26465240} = "Ondangwa";
$areanames{en}->{26465241} = "Ondangwa";
$areanames{en}->{26465242} = "Ondangwa";
$areanames{en}->{26465243} = "Ondangwa";
$areanames{en}->{264652440} = "Omuthiya";
$areanames{en}->{264652441} = "Omuthiya";
$areanames{en}->{264652446} = "Omuthiya";
$areanames{en}->{264652447} = "Omuthiya";
$areanames{en}->{264652448} = "Omuthiya";
$areanames{en}->{264652449} = "Omuthiya";
$areanames{en}->{264652450} = "Oshitayi";
$areanames{en}->{264652451} = "Oshitayi";
$areanames{en}->{264652452} = "Haiyandja";
$areanames{en}->{264652453} = "Haiyandja";
$areanames{en}->{264652454} = "Ongha";
$areanames{en}->{264652455} = "Ongha";
$areanames{en}->{264652456} = "Oluno";
$areanames{en}->{264652457} = "Oluno";
$areanames{en}->{264652458} = "Oluno";
$areanames{en}->{264652459} = "Oluno";
$areanames{en}->{264652460} = "Oluno";
$areanames{en}->{264652461} = "Oluno";
$areanames{en}->{264652462} = "Oluno";
$areanames{en}->{264652463} = "Oluno";
$areanames{en}->{264652464} = "Oluno";
$areanames{en}->{264652481} = "Onandjokwe";
$areanames{en}->{264652482} = "Onandjokwe";
$areanames{en}->{264652483} = "Onandjokwe";
$areanames{en}->{264652488} = "Onathinge";
$areanames{en}->{264652489} = "Onathinge";
$areanames{en}->{264652490} = "Onathinge";
$areanames{en}->{264652491} = "Onathinge";
$areanames{en}->{264652492} = "Onathinge";
$areanames{en}->{264652493} = "Onathinge";
$areanames{en}->{264652494} = "Onathinge";
$areanames{en}->{264652503} = "Anamulenge";
$areanames{en}->{264652504} = "Anamulenge";
$areanames{en}->{264652507} = "Ombalantu";
$areanames{en}->{264652508} = "Ombalantu";
$areanames{en}->{264652509} = "Ombalantu";
$areanames{en}->{26465251} = "Ombalantu";
$areanames{en}->{264652520} = "Okahao";
$areanames{en}->{264652521} = "Okahao";
$areanames{en}->{264652522} = "Okahao";
$areanames{en}->{264652523} = "Okahao";
$areanames{en}->{264652524} = "Okahao";
$areanames{en}->{264652525} = "Okahao";
$areanames{en}->{264652526} = "Okahao";
$areanames{en}->{264652531} = "Okahao";
$areanames{en}->{264652532} = "Okahao";
$areanames{en}->{264652535} = "Okalongo";
$areanames{en}->{264652536} = "Okalongo";
$areanames{en}->{264652537} = "Okalongo";
$areanames{en}->{264652545} = "Oshikuku";
$areanames{en}->{264652546} = "Oshikuku";
$areanames{en}->{264652547} = "Oshikuku";
$areanames{en}->{264652560} = "Etilyasa";
$areanames{en}->{264652562} = "Onaanda";
$areanames{en}->{264652565} = "Elim";
$areanames{en}->{264652566} = "Elim";
$areanames{en}->{264652567} = "Elim";
$areanames{en}->{264652570} = "Ogongo";
$areanames{en}->{264652571} = "Ogongo";
$areanames{en}->{264652572} = "Ogongo";
$areanames{en}->{264652580} = "Tsandi";
$areanames{en}->{264652581} = "Tsandi";
$areanames{en}->{264652582} = "Tsandi";
$areanames{en}->{264652587} = "Onesi";
$areanames{en}->{264652588} = "Onesi";
$areanames{en}->{264652589} = "Onesi";
$areanames{en}->{264652590} = "Mahenene";
$areanames{en}->{264652591} = "Mahenene";
$areanames{en}->{264652595} = "Etunda";
$areanames{en}->{264652596} = "Etunda";
$areanames{en}->{264652598} = "Eunda";
$areanames{en}->{264652600} = "Ohangwena";
$areanames{en}->{264652601} = "Ohangwena";
$areanames{en}->{264652620} = "Onuno";
$areanames{en}->{264652621} = "Onuno";
$areanames{en}->{264652622} = "Okatope";
$areanames{en}->{264652623} = "Okatope";
$areanames{en}->{264652624} = "Ondobe";
$areanames{en}->{264652625} = "Ondobe";
$areanames{en}->{264652628} = "Ongha";
$areanames{en}->{264652629} = "Ongha";
$areanames{en}->{264652630} = "Eenhana";
$areanames{en}->{264652631} = "Eenhana";
$areanames{en}->{264652632} = "Eenhana";
$areanames{en}->{264652633} = "Eenhana";
$areanames{en}->{264652634} = "Eenhana";
$areanames{en}->{264652635} = "Eenhana";
$areanames{en}->{264652636} = "Eenhana";
$areanames{en}->{264652640} = "Eenhana";
$areanames{en}->{264652641} = "Eenhana";
$areanames{en}->{264652642} = "Eenhana";
$areanames{en}->{264652643} = "Eenhana";
$areanames{en}->{264652644} = "Oshigambo";
$areanames{en}->{264652645} = "Oshigambo";
$areanames{en}->{264652646} = "Oshikango";
$areanames{en}->{264652647} = "Oshikango";
$areanames{en}->{264652648} = "Oshikango";
$areanames{en}->{264652649} = "Oshikango";
$areanames{en}->{264652650} = "Oshikango";
$areanames{en}->{264652651} = "Oshikango";
$areanames{en}->{264652652} = "Oshikango";
$areanames{en}->{264652653} = "Oshikango";
$areanames{en}->{264652654} = "Oshikango";
$areanames{en}->{264652655} = "Oshikango";
$areanames{en}->{264652657} = "Oshikango";
$areanames{en}->{264652663} = "Oshikango";
$areanames{en}->{264652664} = "Oshikango";
$areanames{en}->{264652665} = "Oshikango";
$areanames{en}->{264652666} = "Omafu";
$areanames{en}->{264652667} = "Omafu";
$areanames{en}->{264652675} = "Omafu";
$areanames{en}->{264652676} = "Odibo";
$areanames{en}->{264652677} = "Odibo";
$areanames{en}->{264652681} = "Edundja";
$areanames{en}->{264652682} = "Edundja";
$areanames{en}->{264652683} = "Ongenga";
$areanames{en}->{264652688} = "Endola";
$areanames{en}->{264652689} = "Endola";
$areanames{en}->{264652690} = "Omungwelume";
$areanames{en}->{264652691} = "Omungwelume";
$areanames{en}->{264652692} = "Omungwelume";
$areanames{en}->{264652700} = "Ruacana";
$areanames{en}->{264652701} = "Ruacana";
$areanames{en}->{264652702} = "Ruacana";
$areanames{en}->{264652710} = "Etoto";
$areanames{en}->{264652714} = "Ruacana";
$areanames{en}->{264652715} = "Ruacana";
$areanames{en}->{264652716} = "Ruacana";
$areanames{en}->{264652717} = "Ruacana";
$areanames{en}->{264652718} = "Ruacana";
$areanames{en}->{264652719} = "Ruacana";
$areanames{en}->{264652720} = "Oshifo";
$areanames{en}->{264652721} = "Oshifo";
$areanames{en}->{264652725} = "Oshifo";
$areanames{en}->{264652728} = "Opuwo";
$areanames{en}->{264652729} = "Opuwo";
$areanames{en}->{26465273} = "Opuwo";
$areanames{en}->{264652736} = "Otjerunda";
$areanames{en}->{264652740} = "Ehomba";
$areanames{en}->{264652741} = "Sodalite";
$areanames{en}->{264652742} = "Panosa";
$areanames{en}->{264652743} = "Kunene\ River\ Lodge";
$areanames{en}->{264652744} = "Etanga";
$areanames{en}->{264652745} = "Okangwati";
$areanames{en}->{264652746} = "Ohandungu";
$areanames{en}->{264652747} = "Kaoko\ Otavi";
$areanames{en}->{264652748} = "Okorosave";
$areanames{en}->{264652749} = "Orumana";
$areanames{en}->{264652750} = "Otwani";
$areanames{en}->{264652751} = "Otjondeka";
$areanames{en}->{264652752} = "Ombombo";
$areanames{en}->{264652753} = "Warmquelle";
$areanames{en}->{264652755} = "Sesfontein";
$areanames{en}->{264652762} = "Kowares";
$areanames{en}->{264652764} = "Otjitjekwa";
$areanames{en}->{264652766} = "Oruvandjai";
$areanames{en}->{264652800} = "Ondangwa";
$areanames{en}->{264652801} = "Ondangwa";
$areanames{en}->{264652822} = "Ondangwa";
$areanames{en}->{264652850} = "Omutsewonime";
$areanames{en}->{264652853} = "Okashana";
$areanames{en}->{264652856} = "Onyaanya";
$areanames{en}->{264652860} = "Okapuku";
$areanames{en}->{264652863} = "Onankali";
$areanames{en}->{264652866} = "Okatope";
$areanames{en}->{264652870} = "Oniingo";
$areanames{en}->{264652880} = "Omundaungilo";
$areanames{en}->{264652882} = "Oshuli";
$areanames{en}->{264652884} = "Okongo";
$areanames{en}->{264652885} = "Okongo";
$areanames{en}->{264652886} = "Ekoka";
$areanames{en}->{264652888} = "Epembe";
$areanames{en}->{264652890} = "Okankolo";
$areanames{en}->{264652892} = "Omuntele";
$areanames{en}->{264652894} = "Oshikunde";
$areanames{en}->{264652896} = "Onyuulaye";
$areanames{en}->{26465290} = "Eenhana";
$areanames{en}->{26465695} = "North";
$areanames{en}->{264657031} = "Ondangwa";
$areanames{en}->{264657032} = "Oshakati";
$areanames{en}->{264657100} = "Oshakati";
$areanames{en}->{264657130} = "Oshakati";
$areanames{en}->{264657142} = "Oshakati";
$areanames{en}->{264657145} = "Oshakati";
$areanames{en}->{264657152} = "Oshakati";
$areanames{en}->{264657165} = "Oshakati";
$areanames{en}->{264661701} = "Bagani";
$areanames{en}->{264661702} = "Bagani";
$areanames{en}->{264661703} = "Bukalo";
$areanames{en}->{264661704} = "Bunia";
$areanames{en}->{264661705} = "Hakasembe";
$areanames{en}->{264661706} = "K\.\ Murangi";
$areanames{en}->{264661707} = "Kahenge";
$areanames{en}->{264661708} = "Katima\-Mulilo";
$areanames{en}->{264661709} = "Katima\-Mulilo";
$areanames{en}->{264661710} = "Katima\-Mulilo";
$areanames{en}->{264661711} = "Kongola";
$areanames{en}->{264661712} = "Mpacha";
$areanames{en}->{264661713} = "Marangi";
$areanames{en}->{264661714} = "Mashare";
$areanames{en}->{264661715} = "Matava";
$areanames{en}->{264661716} = "Muveke";
$areanames{en}->{264661717} = "Nkurenkuru";
$areanames{en}->{264661718} = "Nakayale\/Nkurenkuru";
$areanames{en}->{264661719} = "Nzinze";
$areanames{en}->{264661720} = "Omega";
$areanames{en}->{264661721} = "Rundu";
$areanames{en}->{264661722} = "Rundu";
$areanames{en}->{264661723} = "Rundu";
$areanames{en}->{264661724} = "Rundu";
$areanames{en}->{264661725} = "Rupara";
$areanames{en}->{264661726} = "Ruuga";
$areanames{en}->{264661727} = "Sikono";
$areanames{en}->{264661728} = "Nyangana";
$areanames{en}->{264662500} = "Nakayale\/Omega";
$areanames{en}->{264662501} = "Nakayale";
$areanames{en}->{264662502} = "Mpacha\/Ngoma";
$areanames{en}->{264662504} = "Kongola";
$areanames{en}->{264662506} = "Ngoma";
$areanames{en}->{264662508} = "Ngoma";
$areanames{en}->{26466251} = "Katima\-Mulilo";
$areanames{en}->{26466252} = "Katima\-Mulilo";
$areanames{en}->{26466253} = "Katima\-Mulilo";
$areanames{en}->{26466254} = "Katima\-Mulilo";
$areanames{en}->{26466255} = "Rundu";
$areanames{en}->{26466256} = "Rundu";
$areanames{en}->{264662570} = "Sikono";
$areanames{en}->{264662571} = "Ruuga";
$areanames{en}->{264662572} = "Hakasembe";
$areanames{en}->{264662573} = "Bunia";
$areanames{en}->{264662574} = "Matava";
$areanames{en}->{264662575} = "Nzinze";
$areanames{en}->{264662576} = "Rupara";
$areanames{en}->{264662577} = "Muveke";
$areanames{en}->{264662578} = "Marangi";
$areanames{en}->{264662579} = "Kahenge";
$areanames{en}->{264662580} = "Nkurenkuru";
$areanames{en}->{264662581} = "Nkurenkuru";
$areanames{en}->{264662582} = "Nyangana";
$areanames{en}->{264662586} = "Mashare";
$areanames{en}->{264662587} = "Mashare";
$areanames{en}->{264662588} = "Nyangana";
$areanames{en}->{264662589} = "Rundu";
$areanames{en}->{264662590} = "Bagani";
$areanames{en}->{264662591} = "Bagani";
$areanames{en}->{264662592} = "Bagani";
$areanames{en}->{264662593} = "Bagani";
$areanames{en}->{264662596} = "Sambyu";
$areanames{en}->{264662597} = "Sambyu";
$areanames{en}->{264662599} = "Muhembo";
$areanames{en}->{264662600} = "Mpungu";
$areanames{en}->{26466261} = "Katima\-Mulilo";
$areanames{en}->{264662627} = "Katima\-Mulilo";
$areanames{en}->{26466263} = "Katima\-Mulilo";
$areanames{en}->{264662640} = "Nyangana";
$areanames{en}->{26466265} = "Rundu";
$areanames{en}->{26466266} = "Rundu";
$areanames{en}->{264662670} = "Rundu";
$areanames{en}->{264662671} = "Rundu";
$areanames{en}->{264662672} = "Rundu";
$areanames{en}->{264662673} = "Rundu";
$areanames{en}->{264662674} = "Rundu";
$areanames{en}->{26466268} = "Katima\-Mulilo";
$areanames{en}->{26466269} = "Rundu";
$areanames{en}->{26466381} = "Maltahohe";
$areanames{en}->{26466385} = "Namgorab";
$areanames{en}->{26466423} = "Kalahariplaas";
$areanames{en}->{26466696} = "North\ East";
$areanames{en}->{264667030} = "Rundu";
$areanames{en}->{264667143} = "Rundu";
$areanames{en}->{264667145} = "Katima\-Mulilo";
$areanames{en}->{264667153} = "Rundu";
$areanames{en}->{264671700} = "Andara";
$areanames{en}->{264671740} = "Abenab";
$areanames{en}->{264671741} = "Anker";
$areanames{en}->{264671742} = "Sorris\-Sorris";
$areanames{en}->{264671743} = "Biermanskool";
$areanames{en}->{264671745} = "Halali";
$areanames{en}->{264671746} = "Horabe";
$areanames{en}->{264671747} = "Kalkfeld";
$areanames{en}->{264671748} = "Kamanjab";
$areanames{en}->{264671749} = "Khorixas";
$areanames{en}->{264671751} = "Khorixas";
$areanames{en}->{264671753} = "Kombat";
$areanames{en}->{264671754} = "Lindequest";
$areanames{en}->{264671756} = "Maroelaboom";
$areanames{en}->{264671757} = "Etosha\ Rurtel";
$areanames{en}->{264671759} = "Okakarara";
$areanames{en}->{264671760} = "Okakarara";
$areanames{en}->{264671762} = "Okaputa";
$areanames{en}->{264671763} = "Okaukuejo";
$areanames{en}->{264671764} = "Okorusu";
$areanames{en}->{264671765} = "Omatjene";
$areanames{en}->{264671766} = "Etosha\ Rurtel";
$areanames{en}->{264671767} = "Etosha\ Rurtel";
$areanames{en}->{264671768} = "Etosha\ Rurtel";
$areanames{en}->{264671770} = "Otavi";
$areanames{en}->{264671771} = "Otavi";
$areanames{en}->{264671773} = "Otjiwarongo";
$areanames{en}->{264671774} = "Otjiwarongo";
$areanames{en}->{264671775} = "Otjiwarongo";
$areanames{en}->{264671776} = "Otjiwarongo";
$areanames{en}->{264671777} = "Otjiwarongo";
$areanames{en}->{264671778} = "Outjo";
$areanames{en}->{264671779} = "Outjo";
$areanames{en}->{264671782} = "Toshari";
$areanames{en}->{264671783} = "Tsumeb";
$areanames{en}->{264671784} = "Tsumeb";
$areanames{en}->{264671785} = "Tsumeb";
$areanames{en}->{264671786} = "Tsumeb";
$areanames{en}->{264671787} = "Tsumeb";
$areanames{en}->{264671789} = "Uchab";
$areanames{en}->{264671790} = "Uib";
$areanames{en}->{264671791} = "Waterberg\ Plateau\ Park";
$areanames{en}->{264671792} = "Waterberg\ Plateau\ Park";
$areanames{en}->{264671793} = "Waterberg\ Plateau\ Park";
$areanames{en}->{264671794} = "Epupa";
$areanames{en}->{264671797} = "Grootfontein";
$areanames{en}->{264671798} = "Grootfontein";
$areanames{en}->{264671799} = "Grootfontein";
$areanames{en}->{26467220} = "Tsumeb";
$areanames{en}->{26467221} = "Tsumeb";
$areanames{en}->{26467222} = "Tsumeb";
$areanames{en}->{26467223} = "Tsumeb";
$areanames{en}->{26467224} = "Tsumeb";
$areanames{en}->{264672290} = "Etosha\ Rurtel";
$areanames{en}->{264672291} = "Etosha\ Rurtel";
$areanames{en}->{264672292} = "Etosha\ Rurtel\/Lindequest";
$areanames{en}->{264672293} = "Etosha\ Rurtel\/Namutoni";
$areanames{en}->{264672294} = "Etosha\ Rurtel\/Halali";
$areanames{en}->{264672295} = "Etosha\ Rurtel\/Ombika";
$areanames{en}->{264672296} = "Etosha\ Rurtel\/Ongava";
$areanames{en}->{264672297} = "Etosha\ Rurtel";
$areanames{en}->{264672298} = "Etosha\ Rurtel\/Okaukuejo";
$areanames{en}->{264672299} = "Mokuti";
$areanames{en}->{26467230} = "Oshivello";
$areanames{en}->{264672310} = "Kombat";
$areanames{en}->{264672311} = "Kombat";
$areanames{en}->{264672312} = "Kombat";
$areanames{en}->{264672315} = "Rietfontein";
$areanames{en}->{264672316} = "Rietfontein";
$areanames{en}->{264672320} = "Abenab";
$areanames{en}->{264672323} = "Horabe";
$areanames{en}->{264672326} = "Maroelaboom";
$areanames{en}->{264672327} = "Maroelaboom";
$areanames{en}->{264672329} = "Coblenz";
$areanames{en}->{26467234} = "Otavi";
$areanames{en}->{264672350} = "Uib";
$areanames{en}->{264672357} = "Otavi";
$areanames{en}->{264672358} = "Otavi";
$areanames{en}->{264672359} = "Otavi";
$areanames{en}->{26467240} = "Grootfontein";
$areanames{en}->{26467241} = "Grootfontein";
$areanames{en}->{26467242} = "Grootfontein";
$areanames{en}->{26467243} = "Grootfontein";
$areanames{en}->{264672440} = "Tsumkwe";
$areanames{en}->{264672441} = "Tsumkwe";
$areanames{en}->{264672450} = "Mangetti\ duin";
$areanames{en}->{264672455} = "Gam";
$areanames{en}->{26467248} = "Grootfontein";
$areanames{en}->{264672491} = "Grootfontein";
$areanames{en}->{264672492} = "Grootfontein";
$areanames{en}->{264672493} = "Grootfontein";
$areanames{en}->{264672494} = "Grootfontein";
$areanames{en}->{264672583} = "Andara";
$areanames{en}->{264672584} = "Andara";
$areanames{en}->{264672615} = "Uchab";
$areanames{en}->{264672616} = "Uchab";
$areanames{en}->{264672617} = "Uchab";
$areanames{en}->{264672900} = "Kalkfeld";
$areanames{en}->{264672901} = "Kalkfeld";
$areanames{en}->{264672902} = "Kalkfeld";
$areanames{en}->{264672903} = "Epupa";
$areanames{en}->{264672982} = "Tsumeb";
$areanames{en}->{26467300} = "Otjiwarongo";
$areanames{en}->{26467301} = "Otjiwarongo";
$areanames{en}->{26467302} = "Otjiwarongo";
$areanames{en}->{26467303} = "Otjiwarongo";
$areanames{en}->{26467304} = "Otjiwarongo";
$areanames{en}->{264673050} = "Waterberg\ Plateau\ Park";
$areanames{en}->{264673051} = "Waterberg\ Plateau\ Park";
$areanames{en}->{264673052} = "Otjiwarongo";
$areanames{en}->{264673053} = "Otjiwarongo";
$areanames{en}->{264673054} = "Okorusu";
$areanames{en}->{264673055} = "Okorusu";
$areanames{en}->{264673060} = "Otjiwarongo";
$areanames{en}->{264673061} = "Otjiwarongo";
$areanames{en}->{264673062} = "Klein\ Waterberg";
$areanames{en}->{264673063} = "Klein\ Waterberg";
$areanames{en}->{264673064} = "Klein\ Waterberg";
$areanames{en}->{264673065} = "Klein\ Waterberg";
$areanames{en}->{264673066} = "Klein\ Waterberg";
$areanames{en}->{264673067} = "Klein\ Waterberg";
$areanames{en}->{264673068} = "Omatjene";
$areanames{en}->{26467307} = "Otjiwarongo";
$areanames{en}->{26467308} = "Otjiwarongo";
$areanames{en}->{264673090} = "Okaputa";
$areanames{en}->{264673091} = "Okaputa";
$areanames{en}->{26467312} = "Outjo";
$areanames{en}->{26467313} = "Outjo";
$areanames{en}->{264673167} = "Okakarara";
$areanames{en}->{264673168} = "Okakarara";
$areanames{en}->{264673169} = "Okakarara";
$areanames{en}->{26467317} = "Okakarara";
$areanames{en}->{264673180} = "Okamatapati";
$areanames{en}->{264673181} = "Okamatapati";
$areanames{en}->{26467330} = "Kamanjab";
$areanames{en}->{26467331} = "Kamanjab\/Khorixas";
$areanames{en}->{264673320} = "Khorixas";
$areanames{en}->{264673321} = "Khorixas";
$areanames{en}->{264673322} = "Sorris\-Sorris";
$areanames{en}->{264673323} = "Sorris\-Sorris";
$areanames{en}->{264673324} = "Sorris\-Sorris";
$areanames{en}->{264673325} = "Sorris\-Sorris";
$areanames{en}->{264673326} = "Kamanjab";
$areanames{en}->{264673327} = "Kamanjab";
$areanames{en}->{264673328} = "Kamanjab";
$areanames{en}->{264673329} = "Kamanjab";
$areanames{en}->{264673330} = "Anker";
$areanames{en}->{264673331} = "Kamanjab";
$areanames{en}->{264673332} = "Biermanskool";
$areanames{en}->{264673333} = "Biermanskool";
$areanames{en}->{264673334} = "Toshari";
$areanames{en}->{264673335} = "Toshari";
$areanames{en}->{264673336} = "Kamanjab";
$areanames{en}->{264673337} = "Kamanjab";
$areanames{en}->{264673338} = "Kamanjab";
$areanames{en}->{264673339} = "Kamanjab";
$areanames{en}->{26467334} = "Kamanjab";
$areanames{en}->{26467335} = "Kamanjab\/Khorixas";
$areanames{en}->{26467697} = "North";
$areanames{en}->{264677029} = "Grootfontein";
$areanames{en}->{264677140} = "Grootfontein";
$areanames{en}->{264677141} = "Grootfontein";
$areanames{en}->{264677145} = "Grootfontein";
$areanames{en}->{264677150} = "Grootfontein";
$areanames{en}->{264677151} = "Grootfontein";
$areanames{en}->{264677163} = "Otjiwarongo";
$areanames{en}->{264677165} = "Anker\/Braunfels\/Fransfontein";
$areanames{en}->{264677166} = "Kamanjab\/Otavi";
$areanames{en}->{264677173} = "Otjiwarongo";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+264|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;