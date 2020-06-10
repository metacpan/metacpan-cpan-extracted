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
package Number::Phone::StubCountry::BD;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200606131956;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '
            31[5-8]|
            [459]1
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4,6})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '
            3(?:
              [67]|
              8[013-9]
            )|
            4(?:
              6[168]|
              7|
              [89][18]
            )|
            5(?:
              6[128]|
              9
            )|
            6(?:
              28|
              4[14]|
              5
            )|
            7[2-589]|
            8(?:
              0[014-9]|
              [12]
            )|
            9[358]|
            (?:
              3[2-5]|
              4[235]|
              5[2-578]|
              6[0389]|
              76|
              8[3-7]|
              9[24]
            )1|
            (?:
              44|
              66
            )[01346-9]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3,7})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '[13-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4})(\\d{3,6})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '2',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{7,8})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            4(?:
              31\\d\\d|
              423
            )|
            5222
          )\\d{3}(?:
            \\d{2}
          )?|
          8332[6-9]\\d\\d|
          (?:
            3(?:
              03[56]|
              224
            )|
            4(?:
              22[25]|
              653
            )
          )\\d{3,4}|
          (?:
            3(?:
              42[47]|
              529|
              823
            )|
            4(?:
              027|
              525|
              65(?:
                28|
                8
              )
            )|
            562|
            6257|
            7(?:
              1(?:
                5[3-5]|
                6[12]|
                7[156]|
                89
              )|
              22[589]56|
              32|
              42675|
              52(?:
                [25689](?:
                  56|
                  8
                )|
                [347]8
              )|
              71(?:
                6[1267]|
                75|
                89
              )|
              92374
            )|
            82(?:
              2[59]|
              32
            )56|
            9(?:
              03[23]56|
              23(?:
                256|
                373
              )|
              31|
              5(?:
                1|
                2[4589]56
              )
            )
          )\\d{3}|
          (?:
            3(?:
              02[348]|
              22[35]|
              324|
              422
            )|
            4(?:
              22[67]|
              32[236-9]|
              6(?:
                2[46]|
                5[57]
              )|
              953
            )|
            5526|
            6(?:
              024|
              6655
            )|
            81
          )\\d{4,5}|
          (?:
            2(?:
              7(?:
                1[0-267]|
                2[0-289]|
                3[0-29]|
                4[01]|
                5[1-3]|
                6[013]|
                7[0178]|
                91
              )|
              8(?:
                0[125]|
                1[1-6]|
                2[0157-9]|
                3[1-69]|
                41|
                6[1-35]|
                7[1-5]|
                8[1-8]|
                9[0-6]
              )|
              9(?:
                0[0-2]|
                1[0-4]|
                2[568]|
                3[3-6]|
                5[5-7]|
                6[0136-9]|
                7[0-7]|
                8[014-9]
              )
            )|
            3(?:
              0(?:
                2[025-79]|
                3[2-4]
              )|
              181|
              22[12]|
              32[2356]|
              824
            )|
            4(?:
              02[09]|
              22[348]|
              32[045]|
              523|
              6(?:
                27|
                54
              )
            )|
            666(?:
              22|
              53
            )|
            7(?:
              22[57-9]|
              42[56]|
              82[35]
            )8|
            8(?:
              0[124-9]|
              2(?:
                181|
                2[02-4679]8
              )|
              4[12]|
              [5-7]2
            )|
            9(?:
              [04]2|
              2(?:
                2|
                328
              )|
              81
            )
          )\\d{4}|
          (?:
            2[45]\\d\\d|
            3(?:
              1(?:
                2[5-7]|
                [5-7]
              )|
              425|
              822
            )|
            4(?:
              033|
              1\\d|
              [257]1|
              332|
              4(?:
                2[246]|
                5[25]
              )|
              6(?:
                2[35]|
                56|
                62
              )|
              8(?:
                23|
                54
              )|
              92[2-5]
            )|
            5(?:
              02[03489]|
              22[457]|
              32[35-79]|
              42[46]|
              6(?:
                [18]|
                53
              )|
              724|
              826
            )|
            6(?:
              023|
              2(?:
                2[2-5]|
                5[3-5]|
                8
              )|
              32[3478]|
              42[34]|
              52[47]|
              6(?:
                [18]|
                6(?:
                  2[34]|
                  5[24]
                )
              )|
              [78]2[2-5]|
              92[2-6]
            )|
            7(?:
              02|
              21\\d|
              [3-589]1|
              6[12]|
              72[24]
            )|
            8(?:
              217|
              3[12]|
              [5-7]1
            )|
            9[24]1
          )\\d{5}|
          (?:
            (?:
              3[2-8]|
              5[2-57-9]|
              6[03-589]
            )1|
            4[4689][18]
          )\\d{5}|
          [59]1\\d{5}
        ',
                'geographic' => '
          (?:
            4(?:
              31\\d\\d|
              423
            )|
            5222
          )\\d{3}(?:
            \\d{2}
          )?|
          8332[6-9]\\d\\d|
          (?:
            3(?:
              03[56]|
              224
            )|
            4(?:
              22[25]|
              653
            )
          )\\d{3,4}|
          (?:
            3(?:
              42[47]|
              529|
              823
            )|
            4(?:
              027|
              525|
              65(?:
                28|
                8
              )
            )|
            562|
            6257|
            7(?:
              1(?:
                5[3-5]|
                6[12]|
                7[156]|
                89
              )|
              22[589]56|
              32|
              42675|
              52(?:
                [25689](?:
                  56|
                  8
                )|
                [347]8
              )|
              71(?:
                6[1267]|
                75|
                89
              )|
              92374
            )|
            82(?:
              2[59]|
              32
            )56|
            9(?:
              03[23]56|
              23(?:
                256|
                373
              )|
              31|
              5(?:
                1|
                2[4589]56
              )
            )
          )\\d{3}|
          (?:
            3(?:
              02[348]|
              22[35]|
              324|
              422
            )|
            4(?:
              22[67]|
              32[236-9]|
              6(?:
                2[46]|
                5[57]
              )|
              953
            )|
            5526|
            6(?:
              024|
              6655
            )|
            81
          )\\d{4,5}|
          (?:
            2(?:
              7(?:
                1[0-267]|
                2[0-289]|
                3[0-29]|
                4[01]|
                5[1-3]|
                6[013]|
                7[0178]|
                91
              )|
              8(?:
                0[125]|
                1[1-6]|
                2[0157-9]|
                3[1-69]|
                41|
                6[1-35]|
                7[1-5]|
                8[1-8]|
                9[0-6]
              )|
              9(?:
                0[0-2]|
                1[0-4]|
                2[568]|
                3[3-6]|
                5[5-7]|
                6[0136-9]|
                7[0-7]|
                8[014-9]
              )
            )|
            3(?:
              0(?:
                2[025-79]|
                3[2-4]
              )|
              181|
              22[12]|
              32[2356]|
              824
            )|
            4(?:
              02[09]|
              22[348]|
              32[045]|
              523|
              6(?:
                27|
                54
              )
            )|
            666(?:
              22|
              53
            )|
            7(?:
              22[57-9]|
              42[56]|
              82[35]
            )8|
            8(?:
              0[124-9]|
              2(?:
                181|
                2[02-4679]8
              )|
              4[12]|
              [5-7]2
            )|
            9(?:
              [04]2|
              2(?:
                2|
                328
              )|
              81
            )
          )\\d{4}|
          (?:
            2[45]\\d\\d|
            3(?:
              1(?:
                2[5-7]|
                [5-7]
              )|
              425|
              822
            )|
            4(?:
              033|
              1\\d|
              [257]1|
              332|
              4(?:
                2[246]|
                5[25]
              )|
              6(?:
                2[35]|
                56|
                62
              )|
              8(?:
                23|
                54
              )|
              92[2-5]
            )|
            5(?:
              02[03489]|
              22[457]|
              32[35-79]|
              42[46]|
              6(?:
                [18]|
                53
              )|
              724|
              826
            )|
            6(?:
              023|
              2(?:
                2[2-5]|
                5[3-5]|
                8
              )|
              32[3478]|
              42[34]|
              52[47]|
              6(?:
                [18]|
                6(?:
                  2[34]|
                  5[24]
                )
              )|
              [78]2[2-5]|
              92[2-6]
            )|
            7(?:
              02|
              21\\d|
              [3-589]1|
              6[12]|
              72[24]
            )|
            8(?:
              217|
              3[12]|
              [5-7]1
            )|
            9[24]1
          )\\d{5}|
          (?:
            (?:
              3[2-8]|
              5[2-57-9]|
              6[03-589]
            )1|
            4[4689][18]
          )\\d{5}|
          [59]1\\d{5}
        ',
                'mobile' => '
          (?:
            1[13-9]\\d|
            644
          )\\d{7}|
          (?:
            3[78]|
            44|
            66
          )[02-9]\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '80[03]\\d{7}',
                'voip' => '
          96(?:
            0[469]|
            1[0-47]|
            3[389]|
            6[69]|
            7[78]
          )\\d{6}
        '
              };
my %areanames = ();
$areanames{en}->{8802} = "Dhaka";
$areanames{en}->{8803020} = "Banskhali";
$areanames{en}->{8803022} = "Fatikchari";
$areanames{en}->{8803023} = "Hathazari";
$areanames{en}->{8803024} = "Mirsharai\/Mirsari";
$areanames{en}->{8803025} = "Rangunia";
$areanames{en}->{8803026} = "Rauzan";
$areanames{en}->{8803027} = "Snadwip";
$areanames{en}->{8803028} = "Barabkunda\/Sitakunda";
$areanames{en}->{8803029} = "Anwara";
$areanames{en}->{8803032} = "Boalkhali";
$areanames{en}->{8803033} = "Chandanaish";
$areanames{en}->{8803034} = "Lohagara";
$areanames{en}->{8803035} = "Potia\/Potiya";
$areanames{en}->{8803036} = "Satkania\/Satkhania";
$areanames{en}->{880316} = "Chittagong";
$areanames{en}->{880317} = "Chittagong";
$areanames{en}->{880318} = "Chittagong";
$areanames{en}->{880321} = "Noakhali\/Chatkhil";
$areanames{en}->{8803221} = "Begamgonj";
$areanames{en}->{8803222} = "Chatkhil";
$areanames{en}->{8803223} = "Companiganj\ \(B\.Hat\)";
$areanames{en}->{8803224} = "Hatiya\ \(Oshkhali\)";
$areanames{en}->{8803225} = "Shenbag\/Senbag";
$areanames{en}->{880331} = "Feni\/Sonagazi\/Chagalnaiya\/Daganbhuyan";
$areanames{en}->{8803322} = "Chhagalnaiya";
$areanames{en}->{8803323} = "Dagonbhuya";
$areanames{en}->{8803324} = "Parshuram\/Parsuram";
$areanames{en}->{8803325} = "Sonagazi";
$areanames{en}->{8803326} = "Fulgazi";
$areanames{en}->{880341} = "Eidgaon\/Cox\'s\ bazar";
$areanames{en}->{8803422} = "Chokoria\/Chakaria";
$areanames{en}->{8803424} = "Moheshkhali";
$areanames{en}->{8803425} = "Ramu";
$areanames{en}->{8803427} = "Ukhiya";
$areanames{en}->{880351} = "Rangamati";
$areanames{en}->{880352} = "Kaptai";
$areanames{en}->{88036} = "Bandarban";
$areanames{en}->{880371} = "Khagrachari";
$areanames{en}->{880381} = "Laximpur\/Ramganj";
$areanames{en}->{8803822} = "Raipura";
$areanames{en}->{8803823} = "Ramgati\ \(Alexender\)";
$areanames{en}->{8803824} = "Ramgonj";
$areanames{en}->{8804020} = "Rupsha";
$areanames{en}->{8804027} = "Paikgacha";
$areanames{en}->{8804029} = "Terokhada";
$areanames{en}->{880403} = "Dighalia";
$areanames{en}->{88041} = "Khulna";
$areanames{en}->{880421} = "Sharsa\ \(Benapol\)";
$areanames{en}->{8804222} = "Abhaynagar\ \(Noapara\)";
$areanames{en}->{8804223} = "Bagerphara";
$areanames{en}->{8804224} = "Chaugacha";
$areanames{en}->{8804225} = "Jhikargacha";
$areanames{en}->{8804226} = "Keshobpur";
$areanames{en}->{8804227} = "Manirampur";
$areanames{en}->{8804228} = "Sharsa";
$areanames{en}->{880431} = "Barisal";
$areanames{en}->{8804320} = "Banaripara";
$areanames{en}->{8804322} = "Goarnadi";
$areanames{en}->{8804323} = "Agailjhara";
$areanames{en}->{8804324} = "Hizla";
$areanames{en}->{8804325} = "Mehendigonj";
$areanames{en}->{8804326} = "Muladi";
$areanames{en}->{8804327} = "Babugonj";
$areanames{en}->{8804328} = "Bakergonj";
$areanames{en}->{8804329} = "Uzirpur";
$areanames{en}->{880433} = "Banaripara";
$areanames{en}->{880441} = "Patuakhali";
$areanames{en}->{8804422} = "Baufal\/Mirjagonj";
$areanames{en}->{8804423} = "Baufal\/Mirjagonj";
$areanames{en}->{88044235} = "Dashmina\,\ Patuakhali";
$areanames{en}->{8804424} = "Baufal\/Mirjagonj";
$areanames{en}->{8804426} = "Baufal\/Mirjagonj";
$areanames{en}->{8804455} = "Pathorghata";
$areanames{en}->{88044862} = "Barguna";
$areanames{en}->{88044863} = "Barguna";
$areanames{en}->{880451} = "Jhinaidah\/Horinakunda";
$areanames{en}->{8804523} = "Kaligonj";
$areanames{en}->{8804525} = "Moheshpur";
$areanames{en}->{880461} = "Pirojpur";
$areanames{en}->{8804623} = "Bhandaria";
$areanames{en}->{8804624} = "Kaokhali\/Kawkhali";
$areanames{en}->{8804625} = "Mothbaria";
$areanames{en}->{8804626} = "Nazirpur";
$areanames{en}->{8804627} = "Swarupkhati";
$areanames{en}->{8804652} = "Bagerhat";
$areanames{en}->{8804653} = "Fakirhat";
$areanames{en}->{8804654} = "Kachua";
$areanames{en}->{8804655} = "Mollarhat";
$areanames{en}->{8804656} = "Morelganj";
$areanames{en}->{8804657} = "Rampal";
$areanames{en}->{8804658} = "Mongla\,\ Bagerhat";
$areanames{en}->{880466} = "Mongla";
$areanames{en}->{880468} = "Bagerhat\/Mongla\ Port";
$areanames{en}->{88047} = "Satkhira";
$areanames{en}->{880481} = "Narail";
$areanames{en}->{880482} = "Lohagara";
$areanames{en}->{880485} = "Sreepur";
$areanames{en}->{880488} = "Magura\/Mohammadpur";
$areanames{en}->{880491} = "Bhola";
$areanames{en}->{8804922} = "Borhanuddin";
$areanames{en}->{8804924} = "Daulatkhan";
$areanames{en}->{8804925} = "Lalmohan";
$areanames{en}->{880495} = "Nalcity";
$areanames{en}->{880498} = "Jhalakati";
$areanames{en}->{8805020} = "Sibgonj\ \(Mokamtala\)";
$areanames{en}->{8805023} = "Dhunat";
$areanames{en}->{8805024} = "Dhupchachia";
$areanames{en}->{8805028} = "Shariakandi";
$areanames{en}->{8805029} = "Sherpur";
$areanames{en}->{88051} = "Bogra\/Gabtali\/Nandigram\/Sherpur";
$areanames{en}->{880521} = "Rangpur";
$areanames{en}->{8805222} = "Badarganj";
$areanames{en}->{8805224} = "Haragacha";
$areanames{en}->{8805225} = "Mithapukur";
$areanames{en}->{8805227} = "Pirgonj";
$areanames{en}->{880531} = "Dianjpur\/Parbitipur\/Hakimpur\ \(Hili\)";
$areanames{en}->{8805323} = "Birgonj\/Gobindagonj\/Birganj";
$areanames{en}->{8805325} = "Shetabgonj";
$areanames{en}->{8805326} = "Chrirbandar";
$areanames{en}->{8805327} = "Fulbari";
$areanames{en}->{8805329} = "Bangla\ hili";
$areanames{en}->{880541} = "Gaibandha\/Gabindaganj";
$areanames{en}->{8805424} = "Palashbari";
$areanames{en}->{8805426} = "Saghata\ \(Bonarpara\)";
$areanames{en}->{880551} = "Nilphamari\/Domar";
$areanames{en}->{880552} = "Saidpur\/Syedpur";
$areanames{en}->{880561} = "Thakurgoan";
$areanames{en}->{880565} = "Boda";
$areanames{en}->{880568} = "Panchagar\/Tetulia";
$areanames{en}->{880571} = "Jhinaidah\/Panchbibi";
$areanames{en}->{880572} = "Panchbibi";
$areanames{en}->{880581} = "Kurigram";
$areanames{en}->{880582} = "Nageswari";
$areanames{en}->{88059} = "Lalmonirhat";
$areanames{en}->{880601} = "Shariatpur\ Naria";
$areanames{en}->{8806023} = "Damudda";
$areanames{en}->{8806024} = "GoshairHat";
$areanames{en}->{8806222} = "Dhamrai";
$areanames{en}->{8806223} = "Dohar";
$areanames{en}->{8806224} = "Keranigonj";
$areanames{en}->{8806225} = "Nowabgonj";
$areanames{en}->{8806253} = "Monahardi\/Monohordi";
$areanames{en}->{8806254} = "Palash";
$areanames{en}->{8806255} = "Raipura";
$areanames{en}->{8806257} = "Madhabdi";
$areanames{en}->{880628} = "Narsingdi\/Palash\ \(Ghorasal\)\/Shibpur";
$areanames{en}->{880631} = "Faridpur";
$areanames{en}->{8806323} = "Bhanga";
$areanames{en}->{8806324} = "Boalmari";
$areanames{en}->{8806327} = "Nagarkanda";
$areanames{en}->{8806328} = "Sadarpur\ \(J\.Monjil\)";
$areanames{en}->{880641} = "Rajbari";
$areanames{en}->{8806423} = "Goalanda";
$areanames{en}->{8806424} = "Pangsha";
$areanames{en}->{880651} = "Maninganj\/Singair\/Daulatpur\/Shibalaya";
$areanames{en}->{8806524} = "Zitka";
$areanames{en}->{8806527} = "Singair";
$areanames{en}->{880661} = "Madaripur";
$areanames{en}->{880668} = "Gopalgonj";
$areanames{en}->{8806722} = "Araihazar\/Arihazar";
$areanames{en}->{8806723} = "Sonargaon";
$areanames{en}->{8806724} = "Bandar";
$areanames{en}->{8806725} = "Rupganj\/Rupgonj";
$areanames{en}->{8806822} = "Kaliakoir";
$areanames{en}->{8806823} = "Kaliganj";
$areanames{en}->{8806824} = "Kapashia";
$areanames{en}->{8806825} = "Sreepur";
$areanames{en}->{880691} = "Munsigonj\/Tongibari";
$areanames{en}->{8806922} = "Gazaria";
$areanames{en}->{8806923} = "Lohajang";
$areanames{en}->{8806924} = "Sirajdikhan";
$areanames{en}->{8806925} = "Sreenagar";
$areanames{en}->{8806926} = "Tongibari";
$areanames{en}->{88070} = "Bheramara";
$areanames{en}->{88071} = "Kushtia";
$areanames{en}->{880721} = "Rajshahi";
$areanames{en}->{88072255} = "Rajshahi";
$areanames{en}->{88072258} = "Godagari";
$areanames{en}->{8807227} = "Paba";
$areanames{en}->{88072285} = "Rajshahi";
$areanames{en}->{88072288} = "Baneswar";
$areanames{en}->{88072295} = "Rajshahi";
$areanames{en}->{88072298} = "Tanore";
$areanames{en}->{880731} = "Pabna\ \ Bera";
$areanames{en}->{880732} = "Bera\/Chatmohar\/Faridpur\/Ishwardi\/Shathiya\/Sathia\/Bhangura\/Sujanagar";
$areanames{en}->{880741} = "Nagoan\/Santahar";
$areanames{en}->{8807425} = "Manda";
$areanames{en}->{88074267} = "Nagoan";
$areanames{en}->{88074268} = "Mahadevpur";
$areanames{en}->{880751} = "Sirajganj";
$areanames{en}->{88075225} = "Sirajganj";
$areanames{en}->{88075228} = "Sirajgonj";
$areanames{en}->{8807523} = "Sirajgonj";
$areanames{en}->{8807524} = "Sirajgonj";
$areanames{en}->{88075255} = "Sirajganj";
$areanames{en}->{88075258} = "Sirajgonj";
$areanames{en}->{88075265} = "Sirajganj";
$areanames{en}->{88075268} = "Sirajgonj";
$areanames{en}->{8807527} = "Sirajgonj";
$areanames{en}->{88075285} = "Sirajganj";
$areanames{en}->{88075288} = "Sirajgonj";
$areanames{en}->{88075295} = "Sirajganj";
$areanames{en}->{88075298} = "Sirajgonj";
$areanames{en}->{880761} = "Chuadanga";
$areanames{en}->{880762} = "Alamdanga";
$areanames{en}->{880771} = "Natore";
$areanames{en}->{8807724} = "Gurudashpur";
$areanames{en}->{880781} = "Rahanpur\/Shibganj\/Chapai\ Nobabganj";
$areanames{en}->{8807823} = "Rohanpur";
$areanames{en}->{8807825} = "Shibgonj";
$areanames{en}->{88079} = "Meherpur";
$areanames{en}->{880802} = "Chauddagram\/Chandina\/Chandiana\/Daudkandi\/Debidwar\/Homna\/Muradnagar\/Brahmanpara\/Barura\/Burichang";
$areanames{en}->{88081} = "Homna\/Comilla";
$areanames{en}->{8808217} = "Sylhet\ MEA";
$areanames{en}->{8808218} = "Sylhet";
$areanames{en}->{8808220} = "Kanaighat";
$areanames{en}->{8808222} = "Balagonj";
$areanames{en}->{8808223} = "Bianibazar";
$areanames{en}->{8808224} = "Biswanath";
$areanames{en}->{8808225} = "Sylhet";
$areanames{en}->{8808226} = "Fenchugonj";
$areanames{en}->{8808227} = "Golapgonj";
$areanames{en}->{88082295} = "Sylhet";
$areanames{en}->{88082298} = "Jaintapur";
$areanames{en}->{880823} = "Sylhet";
$areanames{en}->{880831} = "Habiganj";
$areanames{en}->{880832} = "Chunarughat\/Madabpur\/Nabiganj";
$areanames{en}->{880833} = "Habiganj";
$areanames{en}->{880841} = "Chandpur";
$areanames{en}->{880842} = "Hajiganj\/Kochua\/Shahrasti\/Matlab";
$areanames{en}->{880851} = "Brahmanbaria\/Nabinagar";
$areanames{en}->{880852} = "Akhaura\/Bancharampur\/Kashba\/Sarail\/Quashba\/Nabinagar\/Ashuganj";
$areanames{en}->{880861} = "Maulavibazar\/Rajnagar";
$areanames{en}->{880862} = "Baralekha\/Komalgonj\/Kulaura\/Rajnagar\/Sreemongal";
$areanames{en}->{880871} = "Sunamganj";
$areanames{en}->{880872} = "Chatak\/Dharmapasha\/Jaganathpur\/Jagonnathpur";
$areanames{en}->{880902} = "Phulpur\/Bhaluka\/Gouripur\/Gafargaon\/Goforgaon\/Iswarganj\/Ishwargonj\/Muktagacha";
$areanames{en}->{880903} = "Mymensingh";
$areanames{en}->{88091} = "Mymensingh";
$areanames{en}->{880921} = "Tangail";
$areanames{en}->{880922} = "Bashail\/Bhuapur\/Ghatail\/Gopalpur\/Kalihati\/Elenga\/Kalihati\/Modhupur\/Mirzapur";
$areanames{en}->{88092325} = "Tangail";
$areanames{en}->{88092328} = "Shakhipur";
$areanames{en}->{8809233} = "Tangail";
$areanames{en}->{88093} = "Nalitabari\/Nakla\/Sherpur";
$areanames{en}->{880941} = "Kishoreganj\/Tarail";
$areanames{en}->{880942} = "Bajitpur\/Bhairabbazar\/Itna\/Kotiadhi";
$areanames{en}->{88095} = "Netrokona";
$areanames{en}->{88098} = "Jamalpur\/Islampur\/Dewanganj";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+880|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;