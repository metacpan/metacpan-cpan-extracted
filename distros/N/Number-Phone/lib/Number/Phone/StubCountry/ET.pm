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
package Number::Phone::StubCountry::ET;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120029;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[1-59]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          116671\\d{3}|
          (?:
            11(?:
              1(?:
                1[124]|
                2[2-7]|
                3[1-5]|
                5[5-8]|
                8[6-8]
              )|
              2(?:
                13|
                3[6-8]|
                5[89]|
                7[05-9]|
                8[2-6]
              )|
              3(?:
                2[01]|
                3[0-289]|
                4[1289]|
                7[1-4]|
                87
              )|
              4(?:
                1[69]|
                3[2-49]|
                4[0-3]|
                6[5-8]
              )|
              5(?:
                1[578]|
                44|
                5[0-4]
              )|
              6(?:
                1[78]|
                2[69]|
                39|
                4[5-7]|
                5[1-5]|
                6[0-59]|
                8[015-8]
              )
            )|
            2(?:
              2(?:
                11[1-9]|
                22[0-7]|
                33\\d|
                44[1467]|
                66[1-68]
              )|
              5(?:
                11[124-6]|
                33[2-8]|
                44[1467]|
                55[14]|
                66[1-3679]|
                77[124-79]|
                880
              )
            )|
            3(?:
              3(?:
                11[0-46-8]|
                (?:
                  22|
                  55
                )[0-6]|
                33[0134689]|
                44[04]|
                66[01467]
              )|
              4(?:
                44[0-8]|
                55[0-69]|
                66[0-3]|
                77[1-5]
              )
            )|
            4(?:
              6(?:
                119|
                22[0-24-7]|
                33[1-5]|
                44[13-69]|
                55[14-689]|
                660|
                88[1-4]
              )|
              7(?:
                (?:
                  11|
                  22
                )[1-9]|
                33[13-7]|
                44[13-6]|
                55[1-689]
              )
            )|
            5(?:
              7(?:
                227|
                55[05]|
                (?:
                  66|
                  77
                )[14-8]
              )|
              8(?:
                11[149]|
                22[013-79]|
                33[0-68]|
                44[013-8]|
                550|
                66[1-5]|
                77\\d
              )
            )
          )\\d{4}
        ',
                'geographic' => '
          116671\\d{3}|
          (?:
            11(?:
              1(?:
                1[124]|
                2[2-7]|
                3[1-5]|
                5[5-8]|
                8[6-8]
              )|
              2(?:
                13|
                3[6-8]|
                5[89]|
                7[05-9]|
                8[2-6]
              )|
              3(?:
                2[01]|
                3[0-289]|
                4[1289]|
                7[1-4]|
                87
              )|
              4(?:
                1[69]|
                3[2-49]|
                4[0-3]|
                6[5-8]
              )|
              5(?:
                1[578]|
                44|
                5[0-4]
              )|
              6(?:
                1[78]|
                2[69]|
                39|
                4[5-7]|
                5[1-5]|
                6[0-59]|
                8[015-8]
              )
            )|
            2(?:
              2(?:
                11[1-9]|
                22[0-7]|
                33\\d|
                44[1467]|
                66[1-68]
              )|
              5(?:
                11[124-6]|
                33[2-8]|
                44[1467]|
                55[14]|
                66[1-3679]|
                77[124-79]|
                880
              )
            )|
            3(?:
              3(?:
                11[0-46-8]|
                (?:
                  22|
                  55
                )[0-6]|
                33[0134689]|
                44[04]|
                66[01467]
              )|
              4(?:
                44[0-8]|
                55[0-69]|
                66[0-3]|
                77[1-5]
              )
            )|
            4(?:
              6(?:
                119|
                22[0-24-7]|
                33[1-5]|
                44[13-69]|
                55[14-689]|
                660|
                88[1-4]
              )|
              7(?:
                (?:
                  11|
                  22
                )[1-9]|
                33[13-7]|
                44[13-6]|
                55[1-689]
              )
            )|
            5(?:
              7(?:
                227|
                55[05]|
                (?:
                  66|
                  77
                )[14-8]
              )|
              8(?:
                11[149]|
                22[013-79]|
                33[0-68]|
                44[013-8]|
                550|
                66[1-5]|
                77\\d
              )
            )
          )\\d{4}
        ',
                'mobile' => '9\\d{8}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{25111111} = "Arada\ I\,\ Addis\ Ababa";
$areanames{en}->{25111112} = "Arada\ II\,\ Addis\ Ababa";
$areanames{en}->{25111114} = "French\ Legasion\,\ Addis\ Ababa";
$areanames{en}->{25111122} = "Sidist\ Kilo\ I\,\ Addis\ Ababa";
$areanames{en}->{25111123} = "Sidist\ Kilo\ II\,\ Addis\ Ababa";
$areanames{en}->{25111124} = "Sidist\ Kilo\ III\,\ Addis\ Ababa";
$areanames{en}->{25111125} = "Sidist\ Kilo\ Rss\ I\,\ Addis\ Ababa";
$areanames{en}->{25111127} = "Addisu\ Gebeya\,\ Addis\ Ababa";
$areanames{en}->{25111131} = "Kuyu\,\ Addis\ Ababa";
$areanames{en}->{251111320} = "Alem\ Ketema\,\ Addis\ Ababa";
$areanames{en}->{251111330} = "Deber\ Tsige\,\ Addis\ Ababa";
$areanames{en}->{251111340} = "Muke\ Turi\,\ Addis\ Ababa";
$areanames{en}->{25111135} = "Fitche\,\ Addis\ Ababa";
$areanames{en}->{25111155} = "Arada\ III\,\ Addis\ Ababa";
$areanames{en}->{25111156} = "Arada\ IV\,\ Addis\ Ababa";
$areanames{en}->{25111157} = "Arada\ V\,\ Addis\ Ababa";
$areanames{en}->{25111158} = "Arada\ VI\,\ Addis\ Ababa";
$areanames{en}->{251111860} = "Sululta\,\ Addis\ Ababa";
$areanames{en}->{25111187} = "Goha\ Tsion\,\ Addis\ Ababa";
$areanames{en}->{25111188} = "Chancho\,\ Addis\ Ababa";
$areanames{en}->{2511121} = "Addis\ Ketema\ I\,\ Addis\ Ababa";
$areanames{en}->{25111236} = "Hagere\ Hiwot\,\ Addis\ Ababa";
$areanames{en}->{25111237} = "Holeta\ Gent\,\ Addis\ Ababa";
$areanames{en}->{25111238} = "Jeldu\,\ Addis\ Ababa";
$areanames{en}->{251112580} = "Ginchi\,\ Addis\ Ababa";
$areanames{en}->{25111259} = "Shegole\,\ Addis\ Ababa";
$areanames{en}->{25111270} = "Asko\,\ Addis\ Ababa";
$areanames{en}->{25111275} = "Addis\ Ketema\ II\,\ Addis\ Ababa";
$areanames{en}->{25111276} = "Addis\ Ketema\ III\,\ Addis\ Ababa";
$areanames{en}->{25111277} = "Addis\ Ketema\ IV\,\ Addis\ Ababa";
$areanames{en}->{25111278} = "Addis\ Ketema\ VI\,\ Addis\ Ababa";
$areanames{en}->{25111279} = "Kolfe\,\ Addis\ Ababa";
$areanames{en}->{251112820} = "Guder\,\ Addis\ Ababa";
$areanames{en}->{25111283} = "Addis\ Alem\,\ Addis\ Ababa";
$areanames{en}->{25111284} = "Burayu\,\ Addis\ Ababa";
$areanames{en}->{251112850} = "Wolenkomi\,\ Addis\ Ababa";
$areanames{en}->{251112860} = "Enchini\,\ Addis\ Ababa";
$areanames{en}->{25111320} = "Old\ Airport\ I\,\ Addis\ Ababa";
$areanames{en}->{25111321} = "Mekanisa\,\ Addis\ Ababa";
$areanames{en}->{25111330} = "Wolkite\,\ Addis\ Ababa";
$areanames{en}->{251113310} = "Endibir\,\ Addis\ Ababa";
$areanames{en}->{251113320} = "Gunchire\,\ Addis\ Ababa";
$areanames{en}->{251113380} = "Sebeta\,\ Addis\ Ababa";
$areanames{en}->{251113390} = "Teji\,\ Addis\ Ababa";
$areanames{en}->{25111341} = "Ghion\,\ Addis\ Ababa";
$areanames{en}->{251113420} = "Tullu\ Bollo\,\ Addis\ Ababa";
$areanames{en}->{25111348} = "Jimmaber\ \(Ayer\ Tena\)\,\ Addis\ Ababa";
$areanames{en}->{25111349} = "Keranyo\,\ Addis\ Ababa";
$areanames{en}->{25111371} = "Old\ Airport\ II\,\ Addis\ Ababa";
$areanames{en}->{25111372} = "Old\ Airport\ III\,\ Addis\ Ababa";
$areanames{en}->{25111373} = "Old\ Airport\ IV\,\ Addis\ Ababa";
$areanames{en}->{25111374} = "Old\ Airport\ V\,\ Addis\ Ababa";
$areanames{en}->{251113870} = "Alem\ Gena\,\ Addis\ Ababa";
$areanames{en}->{25111416} = "Keira\ I\,\ Addis\ Ababa";
$areanames{en}->{25111419} = "Hana\ Mariam\,\ Addis\ Ababa";
$areanames{en}->{25111432} = "Dukem\,\ Addis\ Ababa";
$areanames{en}->{25111433} = "Debre\ Zeit\,\ Addis\ Ababa";
$areanames{en}->{25111434} = "Akaki\,\ Addis\ Ababa";
$areanames{en}->{25111439} = "Kaliti\,\ Addis\ Ababa";
$areanames{en}->{25111440} = "Nifas\ Silk\ III\,\ Addis\ Ababa";
$areanames{en}->{25111442} = "Nifas\ Silk\ I\,\ Addis\ Ababa";
$areanames{en}->{25111443} = "Nifas\ Silk\ II\,\ Addis\ Ababa";
$areanames{en}->{25111465} = "Keria\ II\,\ Addis\ Ababa";
$areanames{en}->{25111466} = "Keria\ III\,\ Addis\ Ababa";
$areanames{en}->{25111467} = "Keira\ IV\,\ Addis\ Ababa";
$areanames{en}->{25111468} = "Keria\ V\,\ Addis\ Ababa";
$areanames{en}->{25111515} = "Filwoha\ II\,\ Addis\ Ababa";
$areanames{en}->{25111517} = "Sheraton\/DID\,\ Addis\ Ababa";
$areanames{en}->{25111518} = "Addis\ Ababa\ Region";
$areanames{en}->{2511154} = "ECA\,\ Addis\ Ababa";
$areanames{en}->{25111550} = "Filwoha\ IV\,\ Addis\ Ababa";
$areanames{en}->{25111551} = "Filwoha\ III\,\ Addis\ Ababa";
$areanames{en}->{25111552} = "Filwha\ VI\,\ Addis\ Ababa";
$areanames{en}->{25111553} = "Filwha\ V\,\ Addis\ Ababa";
$areanames{en}->{25111554} = "Filwha\ VII\,\ Addis\ Ababa";
$areanames{en}->{25111618} = "Bole\ I\,\ Addis\ Ababa";
$areanames{en}->{25111626} = "Bole\ Michael\,\ Addis\ Ababa";
$areanames{en}->{25111629} = "Gerji\,\ Addis\ Ababa";
$areanames{en}->{25111645} = "Yeka\ I\,\ Addis\ Ababa";
$areanames{en}->{25111646} = "Yeka\ II\,\ Addis\ Ababa";
$areanames{en}->{25111647} = "Yeka\ Rss\ III\,\ Addis\ Ababa";
$areanames{en}->{25111651} = "East\ Addis\ Ababa\ Zone";
$areanames{en}->{25111652} = "South\ Addis\ Ababa\ Zone";
$areanames{en}->{25111653} = "South\-West\ Addis\ Ababa\ Zone";
$areanames{en}->{25111654} = "West\ Addis\ Ababa\ Zone";
$areanames{en}->{25111655} = "Central\ \&\ North\ Addis\ Ababa\ Zones";
$areanames{en}->{25111660} = "Kotebe\,\ Addis\ Ababa";
$areanames{en}->{25111661} = "Bole\ II\,\ Addis\ Ababa";
$areanames{en}->{25111662} = "Bole\ III\,\ Addis\ Ababa";
$areanames{en}->{25111663} = "Bole\ IV\,\ Addis\ Ababa";
$areanames{en}->{251116640} = "Bole\ V\,\ Addis\ Ababa";
$areanames{en}->{251116650} = "Civil\ Aviation\,\ Addis\ Ababa";
$areanames{en}->{25111669} = "Bole\ VI\,\ Addis\ Ababa";
$areanames{en}->{25111680} = "Debre\ Sina\,\ Addis\ Ababa";
$areanames{en}->{25111681} = "Debre\ Birehan\,\ Addis\ Ababa";
$areanames{en}->{25111685} = "Mehal\ Meda\,\ Addis\ Ababa";
$areanames{en}->{251116860} = "Sendafa\,\ Addis\ Ababa";
$areanames{en}->{251116870} = "Sheno\,\ Addis\ Ababa";
$areanames{en}->{251116880} = "Enwari\,\ Addis\ Ababa";
$areanames{en}->{25122111} = "Nazreth\ I\,\ South\-East\ Region";
$areanames{en}->{25122112} = "Nazreth\ II\,\ South\-East\ Region";
$areanames{en}->{25122113} = "Wolenchiti\,\ South\-East\ Region";
$areanames{en}->{25122114} = "Melkawarer\,\ South\-East\ Region";
$areanames{en}->{25122115} = "Alem\ Tena\,\ South\-East\ Region";
$areanames{en}->{25122116} = "Modjo\,\ South\-East\ Region";
$areanames{en}->{25122118} = "Meki\,\ South\-East\ Region";
$areanames{en}->{25122119} = "Nazreth\,\ South\-East\ Region";
$areanames{en}->{25122220} = "Wonji\,\ South\-East\ Region";
$areanames{en}->{25122221} = "Shoa\,\ South\-East\ Region";
$areanames{en}->{25122223} = "Arerti\,\ South\-East\ Region";
$areanames{en}->{25122224} = "Awash\,\ South\-East\ Region";
$areanames{en}->{25122225} = "Melkasa\,\ South\-East\ Region";
$areanames{en}->{25122226} = "Metehara\,\ South\-East\ Region";
$areanames{en}->{25122227} = "Agarfa\,\ South\-East\ Region";
$areanames{en}->{25122330} = "Sire\,\ South\-East\ Region";
$areanames{en}->{25122331} = "Asela\,\ South\-East\ Region";
$areanames{en}->{25122332} = "Bokoji\,\ South\-East\ Region";
$areanames{en}->{25122333} = "Dera\,\ South\-East\ Region";
$areanames{en}->{25122334} = "Huruta\,\ South\-East\ Region";
$areanames{en}->{25122335} = "Iteya\,\ South\-East\ Region";
$areanames{en}->{25122336} = "Assasa\,\ South\-East\ Region";
$areanames{en}->{25122337} = "Kersa\,\ South\-East\ Region";
$areanames{en}->{25122338} = "Sagure\,\ South\-East\ Region";
$areanames{en}->{25122339} = "Diksis\,\ South\-East\ Region";
$areanames{en}->{25122441} = "Abomsa\,\ South\-East\ Region";
$areanames{en}->{25122444} = "Ticho\,\ South\-East\ Region";
$areanames{en}->{25122446} = "Gobesa\,\ South\-East\ Region";
$areanames{en}->{25122447} = "Goro\,\ South\-East\ Region";
$areanames{en}->{25122661} = "Bale\ Goba\,\ South\-East\ Region";
$areanames{en}->{25122662} = "Gessera\,\ South\-East\ Region";
$areanames{en}->{25122663} = "Adaba\,\ South\-East\ Region";
$areanames{en}->{25122664} = "Ghinir\,\ South\-East\ Region";
$areanames{en}->{25122665} = "Robe\,\ South\-East\ Region";
$areanames{en}->{25122666} = "Dodolla\,\ South\-East\ Region";
$areanames{en}->{25122668} = "Dolomena\,\ South\-East\ Region";
$areanames{en}->{25125111} = "Dire\ Dawa\ I\,\ East\ Region";
$areanames{en}->{25125112} = "Dire\ Dawa\ II\,\ East\ Region";
$areanames{en}->{25125114} = "Shinile\,\ East\ Region";
$areanames{en}->{25125115} = "Artshek\,\ East\ Region";
$areanames{en}->{25125116} = "Melka\ Jeldu\,\ East\ Region";
$areanames{en}->{25125332} = "Bedeno\,\ East\ Region";
$areanames{en}->{25125333} = "Deder\,\ East\ Region";
$areanames{en}->{25125334} = "Grawa\,\ East\ Region";
$areanames{en}->{25125335} = "Chelenko\,\ East\ Region";
$areanames{en}->{25125336} = "Kersa\,\ East\ Region";
$areanames{en}->{25125337} = "Kobo\,\ East\ Region";
$areanames{en}->{25125338} = "Kombolocha\,\ East\ Region";
$areanames{en}->{25125441} = "Hirna\,\ East\ Region";
$areanames{en}->{25125444} = "Miesso\,\ East\ Region";
$areanames{en}->{25125446} = "Erer\,\ East\ Region";
$areanames{en}->{25125447} = "Hurso\,\ East\ Region";
$areanames{en}->{25125551} = "Asebe\ Teferi\,\ East\ Region";
$areanames{en}->{25125554} = "Assebot\,\ East\ Region";
$areanames{en}->{25125661} = "Alemaya\,\ East\ Region";
$areanames{en}->{25125662} = "Aweday\,\ East\ Region";
$areanames{en}->{25125666} = "Harar\ I\,\ East\ Region";
$areanames{en}->{25125667} = "Harar\ II\,\ East\ Region";
$areanames{en}->{25125669} = "Kebribeyah\,\ East\ Region";
$areanames{en}->{25125771} = "Degahabur\,\ East\ Region";
$areanames{en}->{25125772} = "Gursum\,\ East\ Region";
$areanames{en}->{25125774} = "Kabri\ Dehar\,\ East\ Region";
$areanames{en}->{25125775} = "Jigiga\,\ East\ Region";
$areanames{en}->{25125776} = "Godie\,\ East\ Region";
$areanames{en}->{25125777} = "Teferi\ Ber\,\ East\ Region";
$areanames{en}->{25125779} = "Chinagson\,\ East\ Region";
$areanames{en}->{251258} = "Kelafo\,\ East\ Region";
$areanames{en}->{25133110} = "Kabe\,\ North\-East\ Region";
$areanames{en}->{25133111} = "Dessie\ I\,\ North\-East\ Region";
$areanames{en}->{25133112} = "Dessie\ II\,\ North\-East\ Region";
$areanames{en}->{25133113} = "Kobo\ Robit\,\ North\-East\ Region";
$areanames{en}->{25133114} = "Akesta\,\ North\-East\ Region";
$areanames{en}->{25133116} = "Wore\-Ilu\,\ North\-East\ Region";
$areanames{en}->{25133117} = "Tenta\,\ North\-East\ Region";
$areanames{en}->{25133118} = "Senbete\,\ North\-East\ Region";
$areanames{en}->{25133220} = "Mekana\ Selam\,\ North\-East\ Region";
$areanames{en}->{25133221} = "Bistima\,\ North\-East\ Region";
$areanames{en}->{25133222} = "Hayk\,\ North\-East\ Region";
$areanames{en}->{25133223} = "Mille\,\ North\-East\ Region";
$areanames{en}->{25133224} = "Wuchale\,\ North\-East\ Region";
$areanames{en}->{25133225} = "Elidar\,\ North\-East\ Region";
$areanames{en}->{25133226} = "Jama\,\ North\-East\ Region";
$areanames{en}->{25133330} = "Sirinka\,\ North\-East\ Region";
$areanames{en}->{25133331} = "Woldia\,\ North\-East\ Region";
$areanames{en}->{25133333} = "Mersa\,\ North\-East\ Region";
$areanames{en}->{25133334} = "Kobo\,\ North\-East\ Region";
$areanames{en}->{25133336} = "Lalibela\,\ North\-East\ Region";
$areanames{en}->{25133338} = "Bure\,\ North\-East\ Region";
$areanames{en}->{25133339} = "Manda\,\ North\-East\ Region";
$areanames{en}->{25133440} = "Sekota\,\ North\-East\ Region";
$areanames{en}->{25133444} = "Ansokia\,\ North\-East\ Region";
$areanames{en}->{25133550} = "Logia\,\ North\-East\ Region";
$areanames{en}->{25133551} = "Kombolcha\,\ North\-East\ Region";
$areanames{en}->{25133552} = "Harbu\,\ North\-East\ Region";
$areanames{en}->{25133553} = "Bati\,\ North\-East\ Region";
$areanames{en}->{25133554} = "Kemise\,\ North\-East\ Region";
$areanames{en}->{25133555} = "Assayta\,\ North\-East\ Region";
$areanames{en}->{25133556} = "Dupti\,\ North\-East\ Region";
$areanames{en}->{25133660} = "Majate\,\ North\-East\ Region";
$areanames{en}->{25133661} = "Epheson\,\ North\-East\ Region";
$areanames{en}->{25133664} = "Shoa\ Robit\,\ North\-East\ Region";
$areanames{en}->{25133666} = "Semera\,\ North\-East\ Region";
$areanames{en}->{25133667} = "Decheotto\,\ North\-East\ Region";
$areanames{en}->{25134440} = "Mekele\ I\,\ North\ Region";
$areanames{en}->{25134441} = "Mekele\ II\,\ North\ Region";
$areanames{en}->{25134442} = "Quiha\,\ North\ Region";
$areanames{en}->{25134443} = "Wukro\,\ North\ Region";
$areanames{en}->{25134444} = "Shire\ Endasselassie\,\ North\ Region";
$areanames{en}->{25134445} = "Adigrat\,\ North\ Region";
$areanames{en}->{25134446} = "Abi\ Adi\,\ North\ Region";
$areanames{en}->{25134447} = "Senkata\,\ North\ Region";
$areanames{en}->{25134448} = "Humera\,\ North\ Region";
$areanames{en}->{25134550} = "Shiraro\,\ North\ Region";
$areanames{en}->{25134551} = "Korem\,\ North\ Region";
$areanames{en}->{25134552} = "Betemariam\,\ North\ Region";
$areanames{en}->{25134554} = "A\.\ Selam\,\ North\ Region";
$areanames{en}->{25134555} = "Rama\,\ North\ Region";
$areanames{en}->{25134556} = "Adi\ Daero\,\ North\ Region";
$areanames{en}->{25134559} = "Mekele\,\ North\ Region";
$areanames{en}->{25134660} = "Adi\ Gudem\,\ North\ Region";
$areanames{en}->{25134661} = "Endabaguna\,\ North\ Region";
$areanames{en}->{25134662} = "Mai\-Tebri\,\ North\ Region";
$areanames{en}->{25134663} = "Waja\,\ North\ Region";
$areanames{en}->{25134771} = "Adwa\,\ North\ Region";
$areanames{en}->{25134772} = "Inticho\,\ North\ Region";
$areanames{en}->{25134773} = "Edaga\-Hamus\,\ North\ Region";
$areanames{en}->{25134774} = "Alemata\,\ North\ Region";
$areanames{en}->{25134775} = "Axum\,\ North\ Region";
$areanames{en}->{251461} = "Shasemene";
$areanames{en}->{25146220} = "Awassa\ I\,\ South\ Region";
$areanames{en}->{25146221} = "Awassa\ II\,\ South\ Region";
$areanames{en}->{25146222} = "Wonda\ Basha\,\ South\ Region";
$areanames{en}->{25146224} = "Aleta\ Wondo\,\ South\ Region";
$areanames{en}->{25146225} = "Yirgalem\,\ South\ Region";
$areanames{en}->{25146226} = "Leku\,\ South\ Region";
$areanames{en}->{25146227} = "Chuko\,\ South\ Region";
$areanames{en}->{25146331} = "Dilla\,\ South\ Region";
$areanames{en}->{25146332} = "Yirga\-Chefe\,\ South\ Region";
$areanames{en}->{25146333} = "Wonago\,\ South\ Region";
$areanames{en}->{25146334} = "Shakiso\,\ South\ Region";
$areanames{en}->{25146335} = "Kibre\-Mengist\,\ South\ Region";
$areanames{en}->{25146441} = "Ziway\,\ South\ Region";
$areanames{en}->{25146443} = "Hagere\ Mariam\,\ South\ Region";
$areanames{en}->{25146444} = "Moyale\,\ South\ Region";
$areanames{en}->{25146445} = "Negele\ Borena\,\ South\ Region";
$areanames{en}->{25146446} = "Yabello\,\ South\ Region";
$areanames{en}->{25146449} = "Dolo\ Odo\,\ South\ Region";
$areanames{en}->{25146551} = "Wollayta\,\ South\ Region";
$areanames{en}->{25146554} = "Durame\,\ South\ Region";
$areanames{en}->{25146555} = "Hossena\,\ South\ Region";
$areanames{en}->{25146556} = "Alaba\ Kulito\,\ South\ Region";
$areanames{en}->{25146558} = "Enseno\,\ South\ Region";
$areanames{en}->{25146559} = "Boditi\,\ South\ Region";
$areanames{en}->{251466} = "Kebado\,\ South\ Region";
$areanames{en}->{25146881} = "Arba\ Minch\,\ South\ Region";
$areanames{en}->{25146882} = "Kibet\,\ South\ Region";
$areanames{en}->{25146883} = "Buii\,\ South\ Region";
$areanames{en}->{25146884} = "Arbaminch\,\ South\ Region";
$areanames{en}->{25147111} = "Jimma\ I\,\ South\-West\ Region";
$areanames{en}->{25147112} = "Jimma\ II\,\ South\-West\ Region";
$areanames{en}->{25147113} = "Serbo\,\ South\-West\ Region";
$areanames{en}->{25147114} = "Assendabo\,\ South\-West\ Region";
$areanames{en}->{25147115} = "Omonada\,\ South\-West\ Region";
$areanames{en}->{25147116} = "Seka\,\ South\-West\ Region";
$areanames{en}->{25147117} = "Sekoru\,\ South\-West\ Region";
$areanames{en}->{25147118} = "Shebe\,\ South\-West\ Region";
$areanames{en}->{25147119} = "Jimma\,\ South\-West\ Region";
$areanames{en}->{25147221} = "Agaro\,\ South\-West\ Region";
$areanames{en}->{25147222} = "Ghembo\,\ South\-West\ Region";
$areanames{en}->{25147223} = "Dedo\,\ South\-West\ Region";
$areanames{en}->{25147224} = "Limmu\ Genet\,\ South\-West\ Region";
$areanames{en}->{25147225} = "Haro\,\ South\-West\ Region";
$areanames{en}->{25147226} = "Yebu\,\ South\-West\ Region";
$areanames{en}->{25147228} = "Atnago\,\ South\-West\ Region";
$areanames{en}->{25147229} = "Ghembe\,\ South\-West\ Region";
$areanames{en}->{25147331} = "Bonga\,\ South\-West\ Region";
$areanames{en}->{25147333} = "Yayo\,\ South\-West\ Region";
$areanames{en}->{25147334} = "Maji\,\ South\-West\ Region";
$areanames{en}->{25147335} = "Mizan\ Teferi\,\ South\-West\ Region";
$areanames{en}->{25147336} = "Aman\,\ South\-West\ Region";
$areanames{en}->{25147337} = "Chora\,\ South\-West\ Region";
$areanames{en}->{25147441} = "Metu\,\ South\-West\ Region";
$areanames{en}->{25147443} = "Dembi\,\ South\-West\ Region";
$areanames{en}->{25147444} = "Darimu\,\ South\-West\ Region";
$areanames{en}->{25147445} = "Bedele\,\ South\-West\ Region";
$areanames{en}->{25147446} = "Hurumu\,\ South\-West\ Region";
$areanames{en}->{25147551} = "Gambela\,\ South\-West\ Region";
$areanames{en}->{25147552} = "Itang\,\ South\-West\ Region";
$areanames{en}->{25147553} = "Jikawo\,\ South\-West\ Region";
$areanames{en}->{25147554} = "Gore\,\ South\-West\ Region";
$areanames{en}->{25147556} = "Tepi\,\ South\-West\ Region";
$areanames{en}->{25147558} = "Macha\,\ South\-West\ Region";
$areanames{en}->{25147559} = "Abebo\,\ South\-West\ Region";
$areanames{en}->{251572} = "Ghedo\,\ West\ Region";
$areanames{en}->{25157550} = "Ejaji\,\ West\ Region";
$areanames{en}->{25157555} = "Dembidolo\,\ West\ Region";
$areanames{en}->{25157661} = "Nekemte\,\ West\ Region";
$areanames{en}->{25157664} = "Fincha\,\ West\ Region";
$areanames{en}->{25157665} = "Backo\,\ West\ Region";
$areanames{en}->{25157666} = "Shambu\,\ West\ Region";
$areanames{en}->{25157667} = "Arjo\,\ West\ Region";
$areanames{en}->{25157668} = "Sire\,\ West\ Region";
$areanames{en}->{25157771} = "Ghimbi\,\ West\ Region";
$areanames{en}->{25157774} = "Nedjo\,\ West\ Region";
$areanames{en}->{25157775} = "Assosa\,\ West\ Region";
$areanames{en}->{25157776} = "Mendi\,\ West\ Region";
$areanames{en}->{25157777} = "Billa\,\ West\ Region";
$areanames{en}->{25157778} = "Guliso\,\ West\ Region";
$areanames{en}->{25158111} = "Gonder\,\ North\-West\ Region";
$areanames{en}->{25158114} = "Azezo\,\ North\-West\ Region";
$areanames{en}->{25158119} = "Gilgel\ Beles\,\ North\-West\ Region";
$areanames{en}->{25158220} = "Bahir\-Dar\ I\,\ North\-West\ Region";
$areanames{en}->{25158221} = "Dangla\,\ North\-West\ Region";
$areanames{en}->{25158223} = "Durbette\/Abcheklite\,\ North\-West\ Region";
$areanames{en}->{25158224} = "Gimjabetmariam\,\ North\-West\ Region";
$areanames{en}->{25158225} = "Chagni\/Metekel\,\ North\-West\ Region";
$areanames{en}->{25158226} = "Bahirdar\ II\,\ North\-West\ Region";
$areanames{en}->{25158227} = "Enjibara\ Kosober\,\ North\-West\ Region";
$areanames{en}->{25158229} = "Tilili\,\ North\-West\ Region";
$areanames{en}->{25158330} = "Merawi\,\ North\-West\ Region";
$areanames{en}->{25158331} = "Metema\,\ North\-West\ Region";
$areanames{en}->{25158332} = "Maksegnit\,\ North\-West\ Region";
$areanames{en}->{25158333} = "Chilga\,\ North\-West\ Region";
$areanames{en}->{25158334} = "Chewahit\,\ North\-West\ Region";
$areanames{en}->{25158335} = "Kola\-Deba\,\ North\-West\ Region";
$areanames{en}->{25158336} = "Delgi\,\ North\-West\ Region";
$areanames{en}->{25158338} = "Adet\,\ North\-West\ Region";
$areanames{en}->{25158440} = "Ebinat\,\ North\-West\ Region";
$areanames{en}->{25158441} = "Debre\-Tabour\,\ North\-West\ Region";
$areanames{en}->{25158443} = "Hamusit\,\ North\-West\ Region";
$areanames{en}->{25158444} = "Addis\ Zemen\,\ North\-West\ Region";
$areanames{en}->{25158445} = "Nefas\ Mewcha\,\ North\-West\ Region";
$areanames{en}->{25158446} = "Worota\,\ North\-West\ Region";
$areanames{en}->{25158447} = "Mekane\-Eyesus\,\ North\-West\ Region";
$areanames{en}->{25158448} = "Teda\,\ North\-West\ Region";
$areanames{en}->{251585} = "Pawe\,\ North\-West\ Region";
$areanames{en}->{25158661} = "Motta\,\ North\-West\ Region";
$areanames{en}->{25158662} = "Keraniyo\,\ North\-West\ Region";
$areanames{en}->{25158663} = "Debre\-work\,\ North\-West\ Region";
$areanames{en}->{25158664} = "Gunde\-woin\,\ North\-West\ Region";
$areanames{en}->{25158665} = "Bichena\,\ North\-West\ Region";
$areanames{en}->{25158770} = "Mankusa\,\ North\-West\ Region";
$areanames{en}->{25158771} = "Debre\-Markos\ I\,\ North\-West\ Region";
$areanames{en}->{25158772} = "Lumame\,\ North\-West\ Region";
$areanames{en}->{25158773} = "Denbecha\,\ North\-West\ Region";
$areanames{en}->{25158774} = "Bure\,\ North\-West\ Region";
$areanames{en}->{25158775} = "Finote\-Selam\,\ North\-West\ Region";
$areanames{en}->{25158776} = "Dejen\,\ North\-West\ Region";
$areanames{en}->{25158777} = "Amanuel\,\ North\-West\ Region";
$areanames{en}->{25158778} = "Debre\ Markos\ II\,\ North\-West\ Region";
$areanames{en}->{25158779} = "Jiga\,\ North\-West\ Region";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+251|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;