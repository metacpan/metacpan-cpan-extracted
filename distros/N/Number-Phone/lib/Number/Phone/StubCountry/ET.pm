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
package Number::Phone::StubCountry::ET;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20231210185945;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[1-579]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          11667[01]\\d{3}|
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
                1[578]|
                2[69]|
                39|
                4[5-7]|
                5[0-5]|
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
          11667[01]\\d{3}|
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
                1[578]|
                2[69]|
                39|
                4[5-7]|
                5[0-5]|
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
                'mobile' => '
          700[1-9]\\d{5}|
          (?:
            7(?:
              0[1-9]|
              1[0-8]|
              22|
              77|
              86|
              99
            )|
            9\\d\\d
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"251116860", "Sendafa\,\ Addis\ Ababa",
"25111275", "Addis\ Ketema\ II\,\ Addis\ Ababa",
"25111238", "Jeldu\,\ Addis\ Ababa",
"25111237", "Holeta\ Gent\,\ Addis\ Ababa",
"25122335", "Iteya\,\ South\-East\ Region",
"25122224", "Awash\,\ South\-East\ Region",
"251112580", "Ginchi\,\ Addis\ Ababa",
"25111626", "Bole\ Michael\,\ Addis\ Ababa",
"25111187", "Goha\ Tsion\,\ Addis\ Ababa",
"25111124", "Sidist\ Kilo\ III\,\ Addis\ Ababa",
"25111188", "Chancho\,\ Addis\ Ababa",
"25111467", "Keira\ IV\,\ Addis\ Ababa",
"25111468", "Keria\ V\,\ Addis\ Ababa",
"25158444", "Addis\ Zemen\,\ North\-West\ Region",
"251113320", "Gunchire\,\ Addis\ Ababa",
"25111433", "Debre\ Zeit\,\ Addis\ Ababa",
"25134773", "Edaga\-Hamus\,\ North\ Region",
"25147221", "Agaro\,\ South\-West\ Region",
"25158773", "Denbecha\,\ North\-West\ Region",
"25134444", "Shire\ Endasselassie\,\ North\ Region",
"25158223", "Durbette\/Abcheklite\,\ North\-West\ Region",
"25133222", "Hayk\,\ North\-East\ Region",
"25111114", "French\ Legasion\,\ Addis\ Ababa",
"25125332", "Bedeno\,\ East\ Region",
"25147336", "Aman\,\ South\-West\ Region",
"25122668", "Dolomena\,\ South\-East\ Region",
"25111440", "Nifas\ Silk\ III\,\ Addis\ Ababa",
"25133223", "Mille\,\ North\-East\ Region",
"25125333", "Deder\,\ East\ Region",
"25125779", "Chinagson\,\ East\ Region",
"25133339", "Manda\,\ North\-East\ Region",
"25158772", "Lumame\,\ North\-West\ Region",
"25122111", "Nazreth\ I\,\ South\-East\ Region",
"25111432", "Dukem\,\ Addis\ Ababa",
"25133444", "Ansokia\,\ North\-East\ Region",
"25125661", "Alemaya\,\ East\ Region",
"25134772", "Inticho\,\ North\ Region",
"25133666", "Semera\,\ North\-East\ Region",
"25146446", "Yabello\,\ South\ Region",
"25133110", "Kabe\,\ North\-East\ Region",
"25157775", "Assosa\,\ West\ Region",
"25146227", "Chuko\,\ South\ Region",
"25111320", "Old\ Airport\ I\,\ Addis\ Ababa",
"25111655", "Central\ \&\ North\ Addis\ Ababa\ Zones",
"25111669", "Bole\ VI\,\ Addis\ Ababa",
"25147114", "Assendabo\,\ South\-West\ Region",
"25157777", "Billa\,\ West\ Region",
"25157778", "Guliso\,\ West\ Region",
"25146884", "Arbaminch\,\ South\ Region",
"25146225", "Yirgalem\,\ South\ Region",
"25125776", "Godie\,\ East\ Region",
"25133336", "Lalibela\,\ North\-East\ Region",
"25122220", "Wonji\,\ South\-East\ Region",
"25122113", "Wolenchiti\,\ South\-East\ Region",
"25147222", "Ghembo\,\ South\-West\ Region",
"25146334", "Shakiso\,\ South\ Region",
"25133221", "Bistima\,\ North\-East\ Region",
"25146449", "Dolo\ Odo\,\ South\ Region",
"251113310", "Endibir\,\ Addis\ Ababa",
"25157664", "Fincha\,\ West\ Region",
"251111330", "Deber\ Tsige\,\ Addis\ Ababa",
"25158114", "Azezo\,\ North\-West\ Region",
"25133555", "Assayta\,\ North\-East\ Region",
"25134440", "Mekele\ I\,\ North\ Region",
"25125447", "Hurso\,\ East\ Region",
"25146551", "Wollayta\,\ South\ Region",
"25125554", "Assebot\,\ East\ Region",
"251466", "Kebado\,\ South\ Region",
"25158440", "Ebinat\,\ North\-West\ Region",
"25111465", "Keria\ II\,\ Addis\ Ababa",
"25133114", "Akesta\,\ North\-East\ Region",
"251111320", "Alem\ Ketema\,\ Addis\ Ababa",
"25122441", "Abomsa\,\ South\-East\ Region",
"25134555", "Rama\,\ North\ Region",
"25122665", "Robe\,\ South\-East\ Region",
"25133440", "Sekota\,\ North\-East\ Region",
"25111348", "Jimmaber\ \(Ayer\ Tena\)\,\ Addis\ Ababa",
"25111629", "Gerji\,\ Addis\ Ababa",
"25125115", "Artshek\,\ East\ Region",
"251112820", "Guder\,\ Addis\ Ababa",
"25158336", "Delgi\,\ North\-West\ Region",
"25111277", "Addis\ Ketema\ IV\,\ Addis\ Ababa",
"25111278", "Addis\ Ketema\ VI\,\ Addis\ Ababa",
"25122338", "Sagure\,\ South\-East\ Region",
"25122337", "Kersa\,\ South\-East\ Region",
"25147558", "Macha\,\ South\-West\ Region",
"25134771", "Adwa\,\ North\ Region",
"25125662", "Aweday\,\ East\ Region",
"25147444", "Darimu\,\ South\-West\ Region",
"25158221", "Dangla\,\ North\-West\ Region",
"25122112", "Nazreth\ II\,\ South\-East\ Region",
"25111681", "Debre\ Birehan\,\ Addis\ Ababa",
"25158771", "Debre\-Markos\ I\,\ North\-West\ Region",
"25147223", "Dedo\,\ South\-West\ Region",
"25122334", "Huruta\,\ South\-East\ Region",
"251113870", "Alem\ Gena\,\ Addis\ Ababa",
"25111662", "Bole\ III\,\ Addis\ Ababa",
"25111125", "Sidist\ Kilo\ Rss\ I\,\ Addis\ Ababa",
"25122225", "Melkasa\,\ South\-East\ Region",
"25147554", "Gore\,\ South\-West\ Region",
"25146220", "Awassa\ I\,\ South\ Region",
"25147226", "Yebu\,\ South\-West\ Region",
"25134445", "Adigrat\,\ North\ Region",
"25133117", "Tenta\,\ North\-East\ Region",
"25158445", "Nefas\ Mewcha\,\ North\-West\ Region",
"25133118", "Senbete\,\ North\-East\ Region",
"25111372", "Old\ Airport\ III\,\ Addis\ Ababa",
"25158661", "Motta\,\ North\-West\ Region",
"25111439", "Kaliti\,\ Addis\ Ababa",
"25158779", "Jiga\,\ North\-West\ Region",
"25133550", "Logia\,\ North\-East\ Region",
"25158333", "Chilga\,\ North\-West\ Region",
"25125772", "Gursum\,\ East\ Region",
"25134661", "Endabaguna\,\ North\ Region",
"25158229", "Tilili\,\ North\-West\ Region",
"251572", "Ghedo\,\ West\ Region",
"25147331", "Bonga\,\ South\-West\ Region",
"25111283", "Addis\ Alem\,\ Addis\ Ababa",
"25125666", "Harar\ I\,\ East\ Region",
"25111554", "Filwha\ VII\,\ Addis\ Ababa",
"25122116", "Modjo\,\ South\-East\ Region",
"25157667", "Arjo\,\ West\ Region",
"25157668", "Sire\,\ West\ Region",
"25133333", "Mersa\,\ North\-East\ Region",
"25158332", "Maksegnit\,\ North\-West\ Region",
"25134550", "Shiraro\,\ North\ Region",
"25146441", "Ziway\,\ South\ Region",
"251113390", "Teji\,\ Addis\ Ababa",
"25125444", "Miesso\,\ East\ Region",
"25133661", "Epheson\,\ North\-East\ Region",
"25111373", "Old\ Airport\ IV\,\ Addis\ Ababa",
"25111156", "Arada\ IV\,\ Addis\ Ababa",
"25111654", "West\ Addis\ Ababa\ Zone",
"25111663", "Bole\ IV\,\ Addis\ Ababa",
"251112860", "Enchini\,\ Addis\ Ababa",
"25157774", "Nedjo\,\ West\ Region",
"25147115", "Omonada\,\ South\-West\ Region",
"25146559", "Boditi\,\ South\ Region",
"25133331", "Woldia\,\ North\-East\ Region",
"25122119", "Nazreth\,\ South\-East\ Region",
"25146224", "Aleta\ Wondo\,\ South\ Region",
"25111131", "Kuyu\,\ Addis\ Ababa",
"25134662", "Mai\-Tebri\,\ North\ Region",
"25125771", "Degahabur\,\ East\ Region",
"25158662", "Keraniyo\,\ North\-West\ Region",
"25111371", "Old\ Airport\ II\,\ Addis\ Ababa",
"25146443", "Hagere\ Mariam\,\ South\ Region",
"25125669", "Kebribeyah\,\ East\ Region",
"25147118", "Shebe\,\ South\-West\ Region",
"25147117", "Sekoru\,\ South\-West\ Region",
"25122330", "Sire\,\ South\-East\ Region",
"25125336", "Kersa\,\ East\ Region",
"25133226", "Jama\,\ North\-East\ Region",
"25146335", "Kibre\-Mengist\,\ South\ Region",
"25111270", "Asko\,\ Addis\ Ababa",
"25133554", "Kemise\,\ North\-East\ Region",
"25157665", "Backo\,\ West\ Region",
"25111661", "Bole\ II\,\ Addis\ Ababa",
"25146556", "Alaba\ Kulito\,\ South\ Region",
"25134554", "A\.\ Selam\,\ North\ Region",
"25134448", "Humera\,\ North\ Region",
"25122446", "Gobesa\,\ South\-East\ Region",
"25134447", "Senkata\,\ North\ Region",
"25158447", "Mekane\-Eyesus\,\ North\-West\ Region",
"25158448", "Teda\,\ North\-West\ Region",
"25125114", "Shinile\,\ East\ Region",
"25111550", "Filwoha\ IV\,\ Addis\ Ababa",
"25111646", "Yeka\ II\,\ Addis\ Ababa",
"25122664", "Ghinir\,\ South\-East\ Region",
"25158663", "Debre\-work\,\ North\-West\ Region",
"25147333", "Yayo\,\ South\-West\ Region",
"25134663", "Waja\,\ North\ Region",
"25147229", "Ghembe\,\ South\-West\ Region",
"25158331", "Metema\,\ North\-West\ Region",
"25111127", "Addisu\ Gebeya\,\ Addis\ Ababa",
"25158776", "Dejen\,\ North\-West\ Region",
"25158226", "Bahirdar\ II\,\ North\-West\ Region",
"25122227", "Agarfa\,\ South\-East\ Region",
"25111650", "Addis\ Ababa",
"25147445", "Bedele\,\ South\-West\ Region",
"25122339", "Diksis\,\ South\-East\ Region",
"25133111", "Dessie\ I\,\ North\-East\ Region",
"25157550", "Ejaji\,\ West\ Region",
"25122223", "Arerti\,\ South\-East\ Region",
"25147112", "Jimma\ II\,\ South\-West\ Region",
"25111279", "Kolfe\,\ Addis\ Ababa",
"25111466", "Keria\ III\,\ Addis\ Ababa",
"25134556", "Adi\ Daero\,\ North\ Region",
"25111618", "Bole\ I\,\ Addis\ Ababa",
"25122444", "Ticho\,\ South\-East\ Region",
"25111123", "Sidist\ Kilo\ II\,\ Addis\ Ababa",
"25147337", "Chora\,\ South\-West\ Region",
"25122666", "Dodolla\,\ South\-East\ Region",
"25125116", "Melka\ Jeldu\,\ East\ Region",
"25147559", "Abebo\,\ South\-West\ Region",
"25111518", "Addis\ Ababa\ Region",
"251116880", "Enwari\,\ Addis\ Ababa",
"25111517", "Sheraton\/DID\,\ Addis\ Ababa",
"251116870", "Sheno\,\ Addis\ Ababa",
"25158335", "Kola\-Deba\,\ North\-West\ Region",
"25111236", "Hagere\ Hiwot\,\ Addis\ Ababa",
"25147441", "Metu\,\ South\-West\ Region",
"25158443", "Hamusit\,\ North\-West\ Region",
"25111434", "Akaki\,\ Addis\ Ababa",
"25111321", "Mekanisa\,\ Addis\ Ababa",
"25134774", "Alemata\,\ North\ Region",
"25158774", "Bure\,\ North\-West\ Region",
"25111349", "Keranyo\,\ Addis\ Ababa",
"25134443", "Wukro\,\ North\ Region",
"25158224", "Gimjabetmariam\,\ North\-West\ Region",
"25146881", "Arba\ Minch\,\ South\ Region",
"2511121", "Addis\ Ketema\ I\,\ Addis\ Ababa",
"25125775", "Jigiga\,\ East\ Region",
"25111135", "Fitche\,\ Addis\ Ababa",
"25146226", "Leku\,\ South\ Region",
"25133224", "Wuchale\,\ North\-East\ Region",
"25125334", "Grawa\,\ East\ Region",
"25111112", "Arada\ II\,\ Addis\ Ababa",
"25146331", "Dilla\,\ South\ Region",
"25134442", "Quiha\,\ North\ Region",
"25111419", "Hana\ Mariam\,\ Addis\ Ababa",
"25111122", "Sidist\ Kilo\ I\,\ Addis\ Ababa",
"25157661", "Nekemte\,\ West\ Region",
"25133556", "Dupti\,\ North\-East\ Region",
"25147113", "Serbo\,\ South\-West\ Region",
"25158111", "Gonder\,\ North\-West\ Region",
"25125551", "Asebe\ Teferi\,\ East\ Region",
"25133667", "Decheotto\,\ North\-East\ Region",
"25146554", "Durame\,\ South\ Region",
"25122114", "Melkawarer\,\ South\-East\ Region",
"25146333", "Wonago\,\ South\ Region",
"251116640", "Bole\ V\,\ Addis\ Ababa",
"25111416", "Keira\ I\,\ Addis\ Ababa",
"25146445", "Negele\ Borena\,\ South\ Region",
"25146883", "Buii\,\ South\ Region",
"25125446", "Erer\,\ East\ Region",
"25111680", "Debre\ Sina\,\ Addis\ Ababa",
"25158770", "Mankusa\,\ North\-West\ Region",
"25157776", "Mendi\,\ West\ Region",
"25158220", "Bahir\-Dar\ I\,\ North\-West\ Region",
"25133338", "Bure\,\ North\-East\ Region",
"25125777", "Teferi\ Ber\,\ East\ Region",
"25111443", "Nifas\ Silk\ II\,\ Addis\ Ababa",
"251113420", "Tullu\ Bollo\,\ Addis\ Ababa",
"251111340", "Muke\ Turi\,\ Addis\ Ababa",
"25133112", "Dessie\ II\,\ North\-East\ Region",
"25147111", "Jimma\ I\,\ South\-West\ Region",
"25134559", "Mekele\,\ North\ Region",
"25111515", "Filwoha\ II\,\ Addis\ Ababa",
"25158338", "Adet\,\ North\-West\ Region",
"25122336", "Assasa\,\ South\-East\ Region",
"25133220", "Mekana\ Selam\,\ North\-East\ Region",
"25111276", "Addis\ Ketema\ III\,\ Addis\ Ababa",
"25122221", "Shoa\,\ South\-East\ Region",
"25133113", "Kobo\ Robit\,\ North\-East\ Region",
"25147556", "Tepi\,\ South\-West\ Region",
"25111442", "Nifas\ Silk\ I\,\ Addis\ Ababa",
"25158441", "Debre\-Tabour\,\ North\-West\ Region",
"25147443", "Dembi\,\ South\-West\ Region",
"25111111", "Arada\ I\,\ Addis\ Ababa",
"25134441", "Mekele\ II\,\ North\ Region",
"25147224", "Limmu\ Genet\,\ South\-West\ Region",
"25146332", "Yirga\-Chefe\,\ South\ Region",
"25147335", "Mizan\ Teferi\,\ South\-West\ Region",
"2511154", "ECA\,\ Addis\ Ababa",
"25146882", "Kibet\,\ South\ Region",
"25158665", "Bichena\,\ North\-West\ Region",
"25147228", "Atnago\,\ South\-West\ Region",
"25133660", "Majate\,\ North\-East\ Region",
"25134551", "Korem\,\ North\ Region",
"25147553", "Jikawo\,\ South\-West\ Region",
"25111259", "Shegole\,\ Addis\ Ababa",
"25133116", "Wore\-Ilu\,\ North\-East\ Region",
"25111645", "Yeka\ I\,\ Addis\ Ababa",
"25122333", "Dera\,\ South\-East\ Region",
"25125111", "Dire\ Dawa\ I\,\ East\ Region",
"25122661", "Bale\ Goba\,\ South\-East\ Region",
"25111652", "South\ Addis\ Ababa\ Zone",
"25158334", "Chewahit\,\ North\-West\ Region",
"251585", "Pawe\,\ North\-West\ Region",
"25158225", "Chagni\/Metekel\,\ North\-West\ Region",
"25158775", "Finote\-Selam\,\ North\-West\ Region",
"25111330", "Wolkite\,\ Addis\ Ababa",
"25111685", "Mehal\ Meda\,\ Addis\ Ababa",
"25111552", "Filwha\ VI\,\ Addis\ Ababa",
"25134775", "Axum\,\ North\ Region",
"25147446", "Hurumu\,\ South\-West\ Region",
"25125774", "Kabri\ Dehar\,\ East\ Region",
"25146221", "Awassa\ II\,\ South\ Region",
"25111158", "Arada\ VI\,\ Addis\ Ababa",
"25133334", "Kobo\,\ North\-East\ Region",
"25111157", "Arada\ V\,\ Addis\ Ababa",
"25111374", "Old\ Airport\ V\,\ Addis\ Ababa",
"25111284", "Burayu\,\ Addis\ Ababa",
"25111553", "Filwha\ V\,\ Addis\ Ababa",
"25133225", "Elidar\,\ North\-East\ Region",
"25125335", "Chelenko\,\ East\ Region",
"25125667", "Harar\ II\,\ East\ Region",
"25134660", "Adi\ Gudem\,\ North\ Region",
"25147552", "Itang\,\ South\-West\ Region",
"25133551", "Kombolcha\,\ North\-East\ Region",
"25157666", "Shambu\,\ West\ Region",
"25122118", "Meki\,\ South\-East\ Region",
"25111653", "South\-West\ Addis\ Ababa\ Zone",
"251461", "Shasemene",
"25147119", "Jimma\,\ South\-West\ Region",
"25146555", "Hossena\,\ South\ Region",
"25122332", "Bokoji\,\ South\-East\ Region",
"251116650", "Civil\ Aviation\,\ Addis\ Ababa",
"25111551", "Filwoha\ III\,\ Addis\ Ababa",
"25122115", "Alem\ Tena\,\ South\-East\ Region",
"25157555", "Dembidolo\,\ West\ Region",
"25133664", "Shoa\ Robit\,\ North\-East\ Region",
"25146558", "Enseno\,\ South\ Region",
"25125441", "Hirna\,\ East\ Region",
"25146444", "Moyale\,\ South\ Region",
"25122662", "Gessera\,\ South\-East\ Region",
"25111155", "Arada\ III\,\ Addis\ Ababa",
"25111651", "East\ Addis\ Ababa\ Zone",
"25158119", "Gilgel\ Beles\,\ North\-West\ Region",
"25157771", "Ghimbi\,\ West\ Region",
"25125112", "Dire\ Dawa\ II\,\ East\ Region",
"251112850", "Wolenkomi\,\ Addis\ Ababa",
"25147116", "Seka\,\ South\-West\ Region",
"25158330", "Merawi\,\ North\-West\ Region",
"25133553", "Bati\,\ North\-East\ Region",
"251113380", "Sebeta\,\ Addis\ Ababa",
"25125338", "Kombolocha\,\ East\ Region",
"25134552", "Betemariam\,\ North\ Region",
"25125337", "Kobo\,\ East\ Region",
"25122331", "Asela\,\ South\-East\ Region",
"25122663", "Adaba\,\ South\-East\ Region",
"251111860", "Sululta\,\ Addis\ Ababa",
"25158227", "Enjibara\ Kosober\,\ North\-West\ Region",
"25158777", "Amanuel\,\ North\-West\ Region",
"25158778", "Debre\ Markos\ II\,\ North\-West\ Region",
"25147551", "Gambela\,\ South\-West\ Region",
"25133552", "Harbu\,\ North\-East\ Region",
"25133330", "Sirinka\,\ North\-East\ Region",
"25122226", "Metehara\,\ South\-East\ Region",
"25134446", "Abi\ Adi\,\ North\ Region",
"25122447", "Goro\,\ South\-East\ Region",
"25147225", "Haro\,\ South\-West\ Region",
"25111660", "Kotebe\,\ Addis\ Ababa",
"25158446", "Worota\,\ North\-West\ Region",
"25111647", "Yeka\ Rss\ III\,\ Addis\ Ababa",
"25158664", "Gunde\-woin\,\ North\-West\ Region",
"25147334", "Maji\,\ South\-West\ Region",
"25146222", "Wonda\ Basha\,\ South\ Region",
"25111341", "Ghion\,\ Addis\ Ababa",
"251258", "Kelafo\,\ East\ Region",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+251|\D)//g;
      my $self = bless({ country_code => '251', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '251', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;