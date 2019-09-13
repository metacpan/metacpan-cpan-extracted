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
our $VERSION = 1.20190912215423;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '
            31[5-7]|
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
            4(?:
              31\\d\\d|
              [46]23
            )|
            5(?:
              222|
              32[37]
            )
          )\\d{3}(?:
            \\d{2}
          )?|
          (?:
            3(?:
              42[47]|
              529|
              823
            )|
            4(?:
              027|
              525|
              658
            )|
            (?:
              56|
              73
            )2|
            6257|
            9[35]1
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
                6[01367]|
                7[15]|
                8[014-9]
              )
            )|
            3(?:
              0(?:
                2[025-79]|
                3[2-4]
              )|
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
            8(?:
              4[12]|
              [5-7]2
            )|
            9(?:
              [024]2|
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
                25|
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
              32[569]|
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
              0|
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
            4(?:
              31\\d\\d|
              [46]23
            )|
            5(?:
              222|
              32[37]
            )
          )\\d{3}(?:
            \\d{2}
          )?|
          (?:
            3(?:
              42[47]|
              529|
              823
            )|
            4(?:
              027|
              525|
              658
            )|
            (?:
              56|
              73
            )2|
            6257|
            9[35]1
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
                6[01367]|
                7[15]|
                8[014-9]
              )
            )|
            3(?:
              0(?:
                2[025-79]|
                3[2-4]
              )|
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
            8(?:
              4[12]|
              [5-7]2
            )|
            9(?:
              [024]2|
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
                25|
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
              32[569]|
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
              0|
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
$areanames{en}->{88030208} = "Banskhali\,\ Chittagong";
$areanames{en}->{88030228} = "Fatikchari\,\ Chittagong";
$areanames{en}->{880302356} = "Hathazari\,\ Chittagong";
$areanames{en}->{88030238} = "Hathazari\,\ Chittagong";
$areanames{en}->{880302456} = "Mirsharai\,\ Chittagong";
$areanames{en}->{88030248} = "Mirsari\,\ Chittagong";
$areanames{en}->{88030258} = "Rangunia\,\ Chittagong";
$areanames{en}->{88030268} = "Rauzan\,\ Chittagong";
$areanames{en}->{88030278} = "Snadwip\,\ Chittagong";
$areanames{en}->{880302856} = "Barabkunda\,\ Chittagong";
$areanames{en}->{88030288} = "Sitakunda\,\ Chittagong";
$areanames{en}->{88030298} = "Anwara\,\ Chittagong";
$areanames{en}->{88030328} = "Boalkhali\,\ Chittagong";
$areanames{en}->{88030338} = "Chandanaish\,\ Chittagong";
$areanames{en}->{88030348} = "Lohagara\,\ Chittagong";
$areanames{en}->{88030352} = "Potia\,\ Chittagong";
$areanames{en}->{88030353} = "Potia\,\ Chittagong";
$areanames{en}->{88030354} = "Potia\,\ Chittagong";
$areanames{en}->{88030355} = "Potia\,\ Chittagong";
$areanames{en}->{88030358} = "Potiya\,\ Chittagong";
$areanames{en}->{88030362} = "Satkania\,\ Chittagong";
$areanames{en}->{88030363} = "Satkania\,\ Chittagong";
$areanames{en}->{88030368} = "Satkhania\,\ Chittagong";
$areanames{en}->{8803161} = "Chittagong";
$areanames{en}->{8803162} = "Chittagong";
$areanames{en}->{8803163} = "Chittagong";
$areanames{en}->{8803165} = "Chittagong";
$areanames{en}->{8803167} = "Chittagong";
$areanames{en}->{8803168} = "Chittagong";
$areanames{en}->{8803171} = "Chittagong";
$areanames{en}->{8803172} = "Chittagong";
$areanames{en}->{8803174} = "Chittagong";
$areanames{en}->{8803175} = "Chittagong";
$areanames{en}->{88032151} = "Noakhali";
$areanames{en}->{88032152} = "Noakhali";
$areanames{en}->{88032153} = "Noakhali";
$areanames{en}->{88032161} = "Noakhali";
$areanames{en}->{88032162} = "Noakhali";
$areanames{en}->{88032163} = "Noakhali";
$areanames{en}->{88032175} = "Chatkhil\,\ Noakhali";
$areanames{en}->{88032218} = "Begamgonj\,\ Noakhali";
$areanames{en}->{88032228} = "Chatkhil\,\ Noakhali";
$areanames{en}->{880322356} = "Companiganj\ \(B\.Hat\)\,\ Noakhali";
$areanames{en}->{88032238} = "Companigonj\,\ Noakhali";
$areanames{en}->{88032242} = "Hatiya\ \(Oshkhali\)\,\ Noakhali";
$areanames{en}->{88032243} = "Hatiya\ \(Oshkhali\)\,\ Noakhali";
$areanames{en}->{880322556} = "Shenbag\,\ Noakhali";
$areanames{en}->{88032258} = "Senbag\,\ Noakhali";
$areanames{en}->{88033160} = "Feni";
$areanames{en}->{88033161} = "Feni";
$areanames{en}->{88033162} = "Feni";
$areanames{en}->{88033163} = "Feni";
$areanames{en}->{88033173} = "Feni";
$areanames{en}->{88033174} = "Feni";
$areanames{en}->{88033176} = "Sonagazi\,\ Feni";
$areanames{en}->{88033178} = "Chagalnaiya\,\ Feni";
$areanames{en}->{88033179} = "Daganbhuyan\,\ Feni";
$areanames{en}->{88033228} = "Chhagalnaiya\,\ Feni";
$areanames{en}->{88033238} = "Dagonbhuya\,\ Feni";
$areanames{en}->{880332456} = "Parshuram\,\ Feni";
$areanames{en}->{88033248} = "Parsuram\,\ Feni";
$areanames{en}->{88033258} = "Sonagazi\,\ Feni";
$areanames{en}->{88033268} = "Fulgazi\,\ Feni";
$areanames{en}->{88034158} = "Eidgaon\,\ Cox\'s\ bazar";
$areanames{en}->{88034162} = "Cox\'s\ bazar";
$areanames{en}->{88034163} = "Cox\'s\ bazar";
$areanames{en}->{88034164} = "Cox\'s\ bazar";
$areanames{en}->{880342256} = "Chokoria\,\ Cox\'s\ bazar";
$areanames{en}->{88034228} = "Chakaria\,\ Cox\'s\ bazar";
$areanames{en}->{88034242} = "Moheshkhali\,\ Cox\'s\ bazar";
$areanames{en}->{88034243} = "Moheshkhali\,\ Cox\'s\ bazar";
$areanames{en}->{880342556} = "Ramu\,\ Cox\'s\ bazar";
$areanames{en}->{88034272} = "Ukhiya\,\ Cox\'s\ bazar";
$areanames{en}->{88034273} = "Ukhiya\,\ Cox\'s\ bazar";
$areanames{en}->{88035161} = "Rangamati";
$areanames{en}->{88035162} = "Rangamati";
$areanames{en}->{88035163} = "Rangamati";
$areanames{en}->{88035292} = "Kaptai\,\ Rangamati";
$areanames{en}->{88035293} = "Kaptai\,\ Rangamati";
$areanames{en}->{88035294} = "Kaptai\,\ Rangamati";
$areanames{en}->{88036162} = "Bandarban";
$areanames{en}->{88036163} = "Bandarban";
$areanames{en}->{88036189} = "Bandarban";
$areanames{en}->{88037161} = "Khagrachari";
$areanames{en}->{88037162} = "Khagrachari";
$areanames{en}->{88038155} = "Laximpur";
$areanames{en}->{88038158} = "Laximpur";
$areanames{en}->{88038161} = "Laximpur";
$areanames{en}->{88038162} = "Laximpur";
$areanames{en}->{88038175} = "Ramganj\,\ Laximpur";
$areanames{en}->{880382256} = "Raipura\,\ Laximpur";
$areanames{en}->{88038232} = "Ramgati\ \(Alexender\)\,\ Laximpur";
$areanames{en}->{88038233} = "Ramgati\ \(Alexender\)\,\ Laximpur";
$areanames{en}->{88038248} = "Ramgonj\,\ Laximpur";
$areanames{en}->{88040208} = "Rupsha\,\ Khulna";
$areanames{en}->{88040272} = "Paikgacha\,\ Khulna";
$areanames{en}->{88040273} = "Paikgacha\,\ Khulna";
$areanames{en}->{88040274} = "Paikgacha\,\ Khulna";
$areanames{en}->{88040298} = "Terokhada\,\ Khulna";
$areanames{en}->{880403356} = "Dighalia\,\ Khulna";
$areanames{en}->{8804172} = "Khulna";
$areanames{en}->{8804173} = "Khulna";
$areanames{en}->{8804176} = "Khulna";
$areanames{en}->{8804177} = "Khulna";
$areanames{en}->{8804178} = "Khulna";
$areanames{en}->{8804180} = "Khulna";
$areanames{en}->{8804181} = "Khulna";
$areanames{en}->{8804186} = "Khulna";
$areanames{en}->{88042175} = "Sharsa\ \(Benapol\)\,\ Jessore";
$areanames{en}->{88042222} = "Abhaynagar\ \(Noapara\)\,\ Jessore";
$areanames{en}->{88042223} = "Abhaynagar\ \(Noapara\)\,\ Jessore";
$areanames{en}->{88042228} = "Abhynagar\,\ Jessore";
$areanames{en}->{88042238} = "Bagerphara\,\ Jessore";
$areanames{en}->{88042248} = "Chaugacha\,\ Jessore";
$areanames{en}->{88042252} = "Jhikargacha\,\ Jessore";
$areanames{en}->{88042253} = "Jhikargacha\,\ Jessore";
$areanames{en}->{88042254} = "Jhikargacha\,\ Jessore";
$areanames{en}->{88042255} = "Jhikargacha\,\ Jessore";
$areanames{en}->{88042258} = "Jhikargacha\,\ Jessore";
$areanames{en}->{880422656} = "Keshobpur\,\ Jessore";
$areanames{en}->{88042268} = "Keshobpur\,\ Jessore";
$areanames{en}->{880422778} = "Manirampur\,\ Jessore";
$areanames{en}->{88042278} = "Monirampur\,\ Jessore";
$areanames{en}->{88042288} = "Sharsa\,\ Jessore";
$areanames{en}->{88043121} = "Barisal";
$areanames{en}->{88043208} = "Banaripara\,\ Barisal";
$areanames{en}->{880432256} = "Goarnadi\,\ Barisal";
$areanames{en}->{88043228} = "Gournadi\,\ Barisal";
$areanames{en}->{880432356} = "Agailjhara\,\ Barisal";
$areanames{en}->{88043238} = "Agailjhara\,\ Barisal";
$areanames{en}->{88043248} = "Hizla\,\ Barisal";
$areanames{en}->{88043258} = "Mehendigonj\,\ Barisal";
$areanames{en}->{880432675} = "Muladi\,\ Barisal";
$areanames{en}->{88043268} = "Muladi\,\ Barisal";
$areanames{en}->{880432773} = "Babugonj\,\ Barisal";
$areanames{en}->{88043278} = "Babugonj\,\ Barisal";
$areanames{en}->{880432874} = "Bakergonj\,\ Barisal";
$areanames{en}->{88043288} = "Bakergonj\,\ Barisal";
$areanames{en}->{88043298} = "Uzirpur\,\ Barisal";
$areanames{en}->{880433256} = "Banaripara\,\ Barisal";
$areanames{en}->{88044162} = "Patuakhali";
$areanames{en}->{88044163} = "Patuakhali";
$areanames{en}->{88044164} = "Patuakhali";
$areanames{en}->{880442256} = "Baufal\,\ Patuakhali";
$areanames{en}->{880442356} = "Dashmina\,\ Patuakhali";
$areanames{en}->{880442456} = "Golachipa\,\ Patuakhali";
$areanames{en}->{88044252} = "Khepupara\,\ Patuakhali";
$areanames{en}->{88044253} = "Khepupara\,\ Patuakhali";
$areanames{en}->{880442675} = "Mirjagonj\ \(RSU\)\,\ Patuakhali";
$areanames{en}->{880445575} = "Pathorghata\,\ Barguna";
$areanames{en}->{88044862} = "Barguna";
$areanames{en}->{88044863} = "Barguna";
$areanames{en}->{88045161} = "Jhinaidah";
$areanames{en}->{88045162} = "Jhinaidah";
$areanames{en}->{88045163} = "Jhinaidah";
$areanames{en}->{88045164} = "Jhinaidah";
$areanames{en}->{88045174} = "Horinakunda\,\ Jhinaidah";
$areanames{en}->{88045189} = "Jhinaidah";
$areanames{en}->{88045238} = "Kaligonj\,\ Jhinaidah";
$areanames{en}->{88045252} = "Moheshpur";
$areanames{en}->{88045253} = "Moheshpur";
$areanames{en}->{88046162} = "Pirojpur";
$areanames{en}->{88046163} = "Pirojpur";
$areanames{en}->{88046232} = "Bhandaria\,\ Pirojpur";
$areanames{en}->{88046233} = "Bhandaria\,\ Pirojpur";
$areanames{en}->{880462456} = "Kaokhali\,\ Pirojpur";
$areanames{en}->{88046248} = "Kawkhali\,\ Bagerhat";
$areanames{en}->{880462575} = "Mothbaria\,\ Pirojpur";
$areanames{en}->{880462674} = "Nazirpur\,\ Pirojpur";
$areanames{en}->{88046268} = "Nazirpur\,\ Bagerhat";
$areanames{en}->{88046278} = "Swarupkhati\,\ Bagerhat";
$areanames{en}->{88046532} = "Fakirhat\,\ Bagerhat";
$areanames{en}->{88046533} = "Fakirhat\,\ Bagerhat";
$areanames{en}->{88046534} = "Fakirhat\,\ Bagerhat";
$areanames{en}->{88046535} = "Fakirhat\,\ Bagerhat";
$areanames{en}->{88046538} = "Fakirhat\,\ Bagerhat";
$areanames{en}->{88046548} = "Kachua\,\ Bagerhat";
$areanames{en}->{880465556} = "Mollarhat\,\ Bagerhat";
$areanames{en}->{88046558} = "Mollarhat\,\ Bagerhat";
$areanames{en}->{880465656} = "Morelganj\,\ Bagerhat";
$areanames{en}->{880465756} = "Rampal\,\ Bagerhat";
$areanames{en}->{88046578} = "Rampal\,\ Bagerhat";
$areanames{en}->{88046582} = "Mongla\,\ Bagerhat";
$areanames{en}->{88046583} = "Mongla\,\ Bagerhat";
$areanames{en}->{88046584} = "Mongla\,\ Bagerhat";
$areanames{en}->{88046585} = "Mongla\,\ Bagerhat";
$areanames{en}->{88046627} = "Mongla\,\ Bagerhat";
$areanames{en}->{88046861} = "Bagerhat";
$areanames{en}->{88046862} = "Bagerhat";
$areanames{en}->{88046863} = "Bagerhat";
$areanames{en}->{88046875} = "Mongla\ Port\,\ Bagerhat";
$areanames{en}->{88047162} = "Satkhira";
$areanames{en}->{88047163} = "Satkhira";
$areanames{en}->{88047164} = "Satkhira";
$areanames{en}->{88047165} = "Satkhira";
$areanames{en}->{88047166} = "Satkhira";
$areanames{en}->{88048162} = "Narail";
$areanames{en}->{88048163} = "Narail";
$areanames{en}->{88048189} = "Narail";
$areanames{en}->{880482356} = "Lohagara\,\ Narail";
$areanames{en}->{880485456} = "Sreepur\,\ Magura";
$areanames{en}->{88048862} = "Magura";
$areanames{en}->{88048863} = "Magura";
$areanames{en}->{88048875} = "Mohammadpur\,\ Magura";
$areanames{en}->{88048889} = "Magura";
$areanames{en}->{88049155} = "Bhola";
$areanames{en}->{88049158} = "Bhola";
$areanames{en}->{88049161} = "Bhola";
$areanames{en}->{88049162} = "Bhola";
$areanames{en}->{880492256} = "Borhanuddin\,\ Bhola";
$areanames{en}->{880492456} = "Daulatkhan\,\ Bhola";
$areanames{en}->{880492575} = "Lalmohan\,\ Bhola";
$areanames{en}->{880495374} = "Nalcity\,\ Jhalakati";
$areanames{en}->{88049538} = "Nalcity\,\ Jhalokhati";
$areanames{en}->{88049862} = "Jhalakati";
$areanames{en}->{88049863} = "Jhalakati";
$areanames{en}->{88049889} = "Jhalakati";
$areanames{en}->{88050208} = "Sibgonj\ \(Mokamtala\)";
$areanames{en}->{880502356} = "Dhunat\,\ Bogra";
$areanames{en}->{88050248} = "Dhupchachia";
$areanames{en}->{880502856} = "Shariakandi\,\ Bogra";
$areanames{en}->{88050298} = "Sherpur";
$areanames{en}->{8805161} = "Bogra";
$areanames{en}->{8805162} = "Bogra";
$areanames{en}->{8805163} = "Bogra";
$areanames{en}->{8805164} = "Bogra";
$areanames{en}->{8805165} = "Bogra";
$areanames{en}->{8805166} = "Bogra";
$areanames{en}->{8805167} = "Bogra";
$areanames{en}->{8805168} = "Bogra";
$areanames{en}->{8805171} = "Bogra";
$areanames{en}->{8805172} = "Bogra";
$areanames{en}->{8805173} = "Bogra";
$areanames{en}->{8805175} = "Gabtali\,\ Bogra";
$areanames{en}->{8805176} = "Nandigram\,\ Bogra";
$areanames{en}->{8805177} = "Sherpur\,\ Bogra";
$areanames{en}->{8805189} = "Bogra";
$areanames{en}->{88052161} = "Rangpur";
$areanames{en}->{88052167} = "Rangpur";
$areanames{en}->{88052168} = "Rangpur";
$areanames{en}->{88052169} = "Rangpur";
$areanames{en}->{88052222} = "Badarganj\,\ Rangpur";
$areanames{en}->{88052223} = "Badarganj\,\ Rangpur";
$areanames{en}->{88052248} = "Haragacha";
$areanames{en}->{880522556} = "Mithapukur\,\ Rangpur";
$areanames{en}->{88052258} = "Mithapukur";
$areanames{en}->{88052278} = "Pirgonj";
$areanames{en}->{88053161} = "Dianjpur";
$areanames{en}->{88053162} = "Dianjpur";
$areanames{en}->{88053163} = "Dianjpur";
$areanames{en}->{88053164} = "Dianjpur";
$areanames{en}->{88053165} = "Dianjpur";
$areanames{en}->{88053166} = "Dianjpur";
$areanames{en}->{88053174} = "Parbitipur\,\ Dianjpur";
$areanames{en}->{88053175} = "Hakimpur\ \(Hili\)\,\ Dianjpur";
$areanames{en}->{88053189} = "Dianjpur";
$areanames{en}->{88053232} = "Birganj\,\ Dianjpur";
$areanames{en}->{88053233} = "Birganj\,\ Dianjpur";
$areanames{en}->{88053234} = "Birganj\,\ Dianjpur";
$areanames{en}->{88053235} = "Birganj\,\ Dianjpur";
$areanames{en}->{88053236} = "Birganj\,\ Dianjpur";
$areanames{en}->{88053238} = "Birgonj\/Gobindagonj";
$areanames{en}->{88053258} = "Shetabgonj";
$areanames{en}->{880532656} = "Chrirbandar\,\ Dianjpur";
$areanames{en}->{88053272} = "Fulbari\,\ Dianjpur";
$areanames{en}->{88053273} = "Fulbari\,\ Dianjpur";
$areanames{en}->{88053298} = "Bangla\ hili";
$areanames{en}->{88054161} = "Gaibandha";
$areanames{en}->{88054162} = "Gaibandha";
$areanames{en}->{88054175} = "Gabindaganj\,\ Gaibandha";
$areanames{en}->{88054189} = "Gaibandha";
$areanames{en}->{88054248} = "Palashbari";
$areanames{en}->{880542656} = "Saghata\ \(Bonarpara\)\,\ Gaibandha";
$areanames{en}->{88055161} = "Nilphamari";
$areanames{en}->{88055162} = "Nilphamari";
$areanames{en}->{88055175} = "Domar\,\ Nilphamari";
$areanames{en}->{88055189} = "Nilphamari";
$areanames{en}->{88055262} = "Saidpur\,\ Nilphamari";
$areanames{en}->{88055268} = "Syedpur";
$areanames{en}->{88056152} = "Thakurgoan";
$areanames{en}->{88056161} = "Thakurgoan";
$areanames{en}->{88056189} = "Thakurgoan";
$areanames{en}->{880565356} = "Boda\,\ Panchagar";
$areanames{en}->{88056861} = "Panchagar";
$areanames{en}->{88056862} = "Panchagar";
$areanames{en}->{88056875} = "Tetulia\,\ Panchagar";
$areanames{en}->{88056889} = "Panchagar";
$areanames{en}->{88057162} = "Jhinaidah\,\ Joypurhat";
$areanames{en}->{88057163} = "Jhinaidah\,\ Joypurhat";
$areanames{en}->{88057175} = "Panchbibi\,\ Joypurhat";
$areanames{en}->{88057189} = "Jhinaidah\,\ Joypurhat";
$areanames{en}->{88057248} = "Panchbibi";
$areanames{en}->{88058161} = "Kurigram";
$areanames{en}->{88058162} = "Kurigram";
$areanames{en}->{88058189} = "Kurigram";
$areanames{en}->{88058268} = "Nageswari";
$areanames{en}->{88059161} = "Lalmonirhat";
$areanames{en}->{88059162} = "Lalmonirhat";
$areanames{en}->{88059189} = "Lalmonirhat";
$areanames{en}->{88060155} = "Shariatpur";
$areanames{en}->{88060159} = "Naria\,\ Shariatpur";
$areanames{en}->{88060161} = "Shariatpur";
$areanames{en}->{880602356} = "Damudda\,\ Shariatpur";
$areanames{en}->{880602475} = "GoshairHat\,\ Shariatpur";
$areanames{en}->{88060248} = "Goshairhat\,\ Sariatpur";
$areanames{en}->{88062228} = "Dhamrai";
$areanames{en}->{88062238} = "Dohar";
$areanames{en}->{88062248} = "Keranigonj";
$areanames{en}->{88062258} = "Nowabgonj";
$areanames{en}->{880625356} = "Monahardi\,\ Narsingdi";
$areanames{en}->{88062538} = "Monohordi";
$areanames{en}->{88062548} = "Palash";
$areanames{en}->{880625556} = "Raipura\,\ Narsingdi";
$areanames{en}->{88062572} = "Madhabdi\,\ Narsingdi";
$areanames{en}->{88062573} = "Madhabdi\,\ Narsingdi";
$areanames{en}->{88062574} = "Madhabdi\,\ Narsingdi";
$areanames{en}->{88062575} = "Madhabdi\,\ Narsingdi";
$areanames{en}->{88062576} = "Madhabdi\,\ Narsingdi";
$areanames{en}->{88062577} = "Madhabdi\,\ Narsingdi";
$areanames{en}->{88062579} = "Madhabdi\,\ Narsingdi";
$areanames{en}->{88062862} = "Narsingdi";
$areanames{en}->{88062863} = "Narsingdi";
$areanames{en}->{88062864} = "Narsingdi";
$areanames{en}->{88062874} = "Palash\ \(Ghorasal\)\,\ Narsingdi";
$areanames{en}->{88062875} = "Shibpur\,\ Narsingdi";
$areanames{en}->{88063161} = "Faridpur";
$areanames{en}->{88063162} = "Faridpur";
$areanames{en}->{88063163} = "Faridpur";
$areanames{en}->{88063164} = "Faridpur";
$areanames{en}->{88063165} = "Faridpur";
$areanames{en}->{88063166} = "Faridpur";
$areanames{en}->{88063167} = "Faridpur";
$areanames{en}->{88063189} = "Faridpur";
$areanames{en}->{880632356} = "Bhanga\,\ Faridpur";
$areanames{en}->{880632456} = "Boalmari\,\ Faridpur";
$areanames{en}->{880632756} = "Nagarkanda\,\ Faridpur";
$areanames{en}->{880632875} = "Sadarpur\ \(J\.Monjil\)\,\ Faridpur";
$areanames{en}->{88064165} = "Rajbari";
$areanames{en}->{88064189} = "Rajbari";
$areanames{en}->{880642356} = "Goalanda\,\ Rajbari";
$areanames{en}->{880642475} = "Pangsha\,\ Rajbari";
$areanames{en}->{88065161} = "Maninganj";
$areanames{en}->{88065163} = "Maninganj";
$areanames{en}->{88065171} = "Singair\,\ Maninganj";
$areanames{en}->{88065174} = "Daulatpur\,\ Maninganj";
$areanames{en}->{88065175} = "Shibalaya\,\ Maninganj";
$areanames{en}->{88065189} = "Maninganj";
$areanames{en}->{88065248} = "Zitka";
$areanames{en}->{88065278} = "Singair";
$areanames{en}->{88066155} = "Madaripur";
$areanames{en}->{88066156} = "Madaripur";
$areanames{en}->{88066161} = "Madaripur";
$areanames{en}->{88066162} = "Madaripur";
$areanames{en}->{88066228} = "Kalkini\,\ Madaripur";
$areanames{en}->{880662356} = "Rajoir\,\ Madaripur";
$areanames{en}->{880662456} = "Shibchar\,\ Madaripur";
$areanames{en}->{880665256} = "Kashiani\,\ Gopalgonj";
$areanames{en}->{880665356} = "Kotalipara\,\ Gopalgonj";
$areanames{en}->{88066538} = "Kotalipara\,\ Gopalgonj";
$areanames{en}->{880665456} = "Moksudpur\,\ Gopalgonj";
$areanames{en}->{880665556} = "Tungipara\,\ Gopalgonj";
$areanames{en}->{880665559} = "Tungipara\,\ Gopalgonj";
$areanames{en}->{88066558} = "Tongipara\,\ Gopalgonj";
$areanames{en}->{88066855} = "Gopalgonj";
$areanames{en}->{88066857} = "Gopalgonj";
$areanames{en}->{88066858} = "Gopalgonj";
$areanames{en}->{88066861} = "Gopalgonj";
$areanames{en}->{880672256} = "Araihazar\,\ Narayanganj";
$areanames{en}->{88067228} = "Arihazar";
$areanames{en}->{88067238} = "Sonargaon";
$areanames{en}->{88067248} = "Bandar";
$areanames{en}->{880672556} = "Rupganj\,\ Narayanganj";
$areanames{en}->{88067258} = "Rupgonj";
$areanames{en}->{880682251} = "Kaliakoir\,\ Gazipur";
$areanames{en}->{880682351} = "Kaliganj\,\ Gazipur";
$areanames{en}->{880682451} = "Kapashia\,\ Gazipur";
$areanames{en}->{880682551} = "Sreepur\,\ Gazipur";
$areanames{en}->{880682552} = "Sreepur\,\ Gazipur";
$areanames{en}->{88069161} = "Munsigonj";
$areanames{en}->{88069162} = "Munsigonj";
$areanames{en}->{88069163} = "Munsigonj";
$areanames{en}->{88069174} = "Tongibari\,\ Munsigonj";
$areanames{en}->{88069189} = "Munsigonj";
$areanames{en}->{88069228} = "Gazaria";
$areanames{en}->{880692356} = "Lohajang\,\ Munsigonj";
$areanames{en}->{88069248} = "Sirajdikhan";
$areanames{en}->{88069258} = "Sreenagar";
$areanames{en}->{88069268} = "Tongibari";
$areanames{en}->{88070222} = "Bheramara\,\ Kushtia";
$areanames{en}->{88070223} = "Bheramara\,\ Kushtia";
$areanames{en}->{88072175} = "Rajshahi";
$areanames{en}->{88072176} = "Rajshahi";
$areanames{en}->{88072177} = "Rajshahi";
$areanames{en}->{88072180} = "Rajshahi";
$areanames{en}->{88072181} = "Rajshahi";
$areanames{en}->{88072186} = "Rajshahi";
$areanames{en}->{88073162} = "Pabna";
$areanames{en}->{88073163} = "Pabna";
$areanames{en}->{88073164} = "Pabna";
$areanames{en}->{88073165} = "Pabna";
$areanames{en}->{88073166} = "Pabna";
$areanames{en}->{88073175} = "Bera\,\ Pabna";
$areanames{en}->{88073189} = "Pabna";
$areanames{en}->{88073238} = "Bera\,\ Pabna";
$areanames{en}->{880732456} = "Chatmohar\,\ Pabna";
$areanames{en}->{88073248} = "Chatmohar\,\ Pabna";
$areanames{en}->{88073258} = "Faridpur\,\ Pabna";
$areanames{en}->{880732663} = "Ishwardi\,\ Pabna";
$areanames{en}->{880732756} = "Shathiya\,\ Pabna";
$areanames{en}->{88073278} = "Sathia\,\ Pabna";
$areanames{en}->{88073288} = "Bhangura\,\ Pabna";
$areanames{en}->{880732956} = "Sujanagar\,\ Pabna";
$areanames{en}->{88074152} = "Nagoan";
$areanames{en}->{88074153} = "Nagoan";
$areanames{en}->{88074155} = "Santahar\,\ Nagoan";
$areanames{en}->{88074161} = "Nagoan";
$areanames{en}->{88074162} = "Nagoan";
$areanames{en}->{88074163} = "Nagoan";
$areanames{en}->{88074169} = "Santahar\,\ Nagoan";
$areanames{en}->{88074189} = "Nagoan";
$areanames{en}->{88075162} = "Sirajganj";
$areanames{en}->{88075163} = "Sirajganj";
$areanames{en}->{88075172} = "Sirajganj";
$areanames{en}->{88075173} = "Sirajganj";
$areanames{en}->{88075189} = "Sirajganj";
$areanames{en}->{88076162} = "Chuadanga";
$areanames{en}->{88076163} = "Chuadanga";
$areanames{en}->{88076164} = "Chuadanga";
$areanames{en}->{88076189} = "Chuadanga";
$areanames{en}->{88076222} = "Alamdanga\,\ Chuadanga";
$areanames{en}->{88076223} = "Alamdanga\,\ Chuadanga";
$areanames{en}->{880772474} = "Gurudashpur\,\ Natore";
$areanames{en}->{88078155} = "Chapai\ Nobabganj";
$areanames{en}->{88078156} = "Chapai\ Nobabganj";
$areanames{en}->{88078160} = "Chapai\ Nobabganj";
$areanames{en}->{88078161} = "Chapai\ Nobabganj";
$areanames{en}->{88078162} = "Chapai\ Nobabganj";
$areanames{en}->{88078174} = "Rahanpur\,\ Chapai\ Nobabganj";
$areanames{en}->{88078175} = "Shibganj\,\ Chapai\ Nobabganj";
$areanames{en}->{88078189} = "Chapai\ Nobabganj";
$areanames{en}->{88079162} = "Meherpur";
$areanames{en}->{88079163} = "Meherpur";
$areanames{en}->{880802056} = "Chauddagram\,\ Comilla";
$areanames{en}->{88080208} = "Chauddagram\,\ Comilla";
$areanames{en}->{880802256} = "Chandina\,\ Comilla";
$areanames{en}->{88080228} = "Chandiana\,\ Comilla";
$areanames{en}->{88080233} = "Daudkandi\,\ Comilla";
$areanames{en}->{88080234} = "Daudkandi\,\ Comilla";
$areanames{en}->{88080238} = "Daudkandi\,\ Comilla";
$areanames{en}->{88080248} = "Debidwar\,\ Comilla";
$areanames{en}->{88080258} = "Homna\,\ Comilla";
$areanames{en}->{880802656} = "Muradnagar\,\ Comilla";
$areanames{en}->{88080268} = "Muradnagar\,\ Comilla";
$areanames{en}->{88080278} = "Barura\,\ Comilla";
$areanames{en}->{88080288} = "Brahmanpara\,\ Comilla";
$areanames{en}->{880802956} = "Burichang\,\ Comilla";
$areanames{en}->{88080298} = "Burichang\,\ Comilla";
$areanames{en}->{88080322} = "Laksham\,\ Comilla";
$areanames{en}->{88080323} = "Laksham\,\ Comilla";
$areanames{en}->{88080324} = "Laksham\,\ Comilla";
$areanames{en}->{88080325} = "Laksham\,\ Comilla";
$areanames{en}->{88080328} = "Laksham\,\ Comilla";
$areanames{en}->{88080338} = "Nangalcoat\,\ Comilla";
$areanames{en}->{8808154} = "Homna\,\ Comilla";
$areanames{en}->{880816} = "Comilla";
$areanames{en}->{8808171} = "Comilla";
$areanames{en}->{8808172} = "Comilla";
$areanames{en}->{8808173} = "Comilla";
$areanames{en}->{8808174} = "Comilla";
$areanames{en}->{8808175} = "Comilla";
$areanames{en}->{8808176} = "Comilla";
$areanames{en}->{8808177} = "Comilla";
$areanames{en}->{88082171} = "Sylhet\ MEA";
$areanames{en}->{88082172} = "Sylhet\ MEA";
$areanames{en}->{88082176} = "Sylhet\ MEA";
$areanames{en}->{88083152} = "Habiganj";
$areanames{en}->{88083153} = "Habiganj";
$areanames{en}->{88083161} = "Habiganj";
$areanames{en}->{88083162} = "Habiganj";
$areanames{en}->{88083163} = "Habiganj";
$areanames{en}->{88083258} = "Chunarughat";
$areanames{en}->{88083278} = "Madabpur";
$areanames{en}->{880832856} = "Nabiganj\,\ Habiganj";
$areanames{en}->{88083288} = "Nabigonj";
$areanames{en}->{88084163} = "Chandpur";
$areanames{en}->{88084164} = "Chandpur";
$areanames{en}->{88084165} = "Chandpur";
$areanames{en}->{88084242} = "Hajiganj\,\ Chandpur";
$areanames{en}->{88084243} = "Hajiganj\,\ Chandpur";
$areanames{en}->{88084244} = "Hajiganj\,\ Chandpur";
$areanames{en}->{88084245} = "Hajiganj\,\ Chandpur";
$areanames{en}->{88084248} = "Hajigonj\,\ Chandpur";
$areanames{en}->{880842556} = "Kochua\,\ Chandpur";
$areanames{en}->{88084258} = "Kachua\,\ Chandpur";
$areanames{en}->{880842656} = "Matlab\,\ Chandpur";
$areanames{en}->{88084268} = "Matlab\,\ Chandpur";
$areanames{en}->{880842756} = "Shaharasti\,\ Chandpur";
$areanames{en}->{88084278} = "Shahrasti\,\ Chandpur";
$areanames{en}->{88085152} = "Brahmanbaria";
$areanames{en}->{88085153} = "Brahmanbaria";
$areanames{en}->{88085154} = "Brahmanbaria";
$areanames{en}->{88085161} = "Brahmanbaria";
$areanames{en}->{88085162} = "Brahmanbaria";
$areanames{en}->{88085163} = "Brahmanbaria";
$areanames{en}->{88085175} = "Nabinagar\,\ Brahmanbaria";
$areanames{en}->{880852256} = "Akhaura\,\ Brahmanbaria";
$areanames{en}->{88085228} = "Akhaura\,\ Brahmanbaria";
$areanames{en}->{880852356} = "Bancharampur\,\ Brahmanbaria";
$areanames{en}->{88085238} = "Bancharampur\,\ Brahmanbaria";
$areanames{en}->{880852473} = "Kashba\,\ Brahmanbaria";
$areanames{en}->{88085248} = "Quashba\,\ Brahmanbaria";
$areanames{en}->{88085258} = "Nabinagar\,\ Brahmanbaria";
$areanames{en}->{88085268} = "Nasirnagar\,\ Brahmanbaria";
$areanames{en}->{88085278} = "Sarail\,\ Brahmanbaria";
$areanames{en}->{88085282} = "Ashuganj\,\ Brahmanbaria";
$areanames{en}->{88085283} = "Ashuganj\,\ Brahmanbaria";
$areanames{en}->{88085284} = "Ashuganj\,\ Brahmanbaria";
$areanames{en}->{88085285} = "Ashuganj\,\ Brahmanbaria";
$areanames{en}->{88086152} = "Maulavibazar";
$areanames{en}->{88086153} = "Maulavibazar";
$areanames{en}->{88086154} = "Maulavibazar";
$areanames{en}->{88086161} = "Maulavibazar";
$areanames{en}->{88086175} = "Rajnagar\,\ Maulavibazar";
$areanames{en}->{88086189} = "Maulavibazar";
$areanames{en}->{880862256} = "Baralekha\,\ Maulavibazar";
$areanames{en}->{88086228} = "Baralekha";
$areanames{en}->{88086238} = "Komalgonj";
$areanames{en}->{880862456} = "Kulaura\,\ Maulavibazar";
$areanames{en}->{88086248} = "Kulaura";
$areanames{en}->{88086258} = "Rajnagar";
$areanames{en}->{88086262} = "Sreemongal\,\ Maulavibazar";
$areanames{en}->{88086263} = "Sreemongal\,\ Maulavibazar";
$areanames{en}->{88086264} = "Sreemongal\,\ Maulavibazar";
$areanames{en}->{88086265} = "Sreemongal\,\ Maulavibazar";
$areanames{en}->{88086266} = "Sreemongal\,\ Maulavibazar";
$areanames{en}->{88086267} = "Sreemongal\,\ Maulavibazar";
$areanames{en}->{88086268} = "Sreemongal";
$areanames{en}->{88086269} = "Sreemongal\,\ Maulavibazar";
$areanames{en}->{88087155} = "Sunamganj";
$areanames{en}->{88087156} = "Sunamganj";
$areanames{en}->{88087161} = "Sunamganj";
$areanames{en}->{88087162} = "Sunamganj";
$areanames{en}->{88087163} = "Sunamganj";
$areanames{en}->{880872356} = "Chattak\,\ Sunamganj";
$areanames{en}->{88087238} = "Chatak";
$areanames{en}->{880872575} = "Dharmapasha\,\ Sunamganj";
$areanames{en}->{880872756} = "Jaganathpur\,\ Sunamganj";
$areanames{en}->{88087278} = "Jagonnathpur";
$areanames{en}->{88090208} = "Phulpur";
$areanames{en}->{880902256} = "Bhaluka\,\ Mymensingh";
$areanames{en}->{88090248} = "Gouripur";
$areanames{en}->{880902556} = "Gafargaon\,\ Mymensingh";
$areanames{en}->{88090258} = "Goforgaon";
$areanames{en}->{880902756} = "Iswarganj\,\ Mymensingh";
$areanames{en}->{88090278} = "Ishwargonj";
$areanames{en}->{88090288} = "Muktagacha";
$areanames{en}->{8809151} = "Mymensingh";
$areanames{en}->{8809152} = "Mymensingh";
$areanames{en}->{8809153} = "Mymensingh";
$areanames{en}->{8809154} = "Mymensingh";
$areanames{en}->{8809155} = "Mymensingh";
$areanames{en}->{8809156} = "Mymensingh";
$areanames{en}->{8809161} = "Mymensingh";
$areanames{en}->{8809162} = "Mymensingh";
$areanames{en}->{8809163} = "Mymensingh";
$areanames{en}->{8809164} = "Mymensingh";
$areanames{en}->{8809175} = "Muktagacha\,\ Mymensingh";
$areanames{en}->{8809189} = "Mymensingh";
$areanames{en}->{88092153} = "Tangail";
$areanames{en}->{88092154} = "Tangail";
$areanames{en}->{88092155} = "Tangail";
$areanames{en}->{88092158} = "Tangail";
$areanames{en}->{88092161} = "Tangail";
$areanames{en}->{88092162} = "Tangail";
$areanames{en}->{880922256} = "Bashail\,\ Tangail";
$areanames{en}->{88092238} = "Bhuapur";
$areanames{en}->{880922556} = "Ghatail\,\ Tangail";
$areanames{en}->{88092258} = "Ghatail";
$areanames{en}->{88092268} = "Gopalpur";
$areanames{en}->{880922774} = "Kalihati\,\ Tangail";
$areanames{en}->{88092278} = "Elenga\/Kalihati";
$areanames{en}->{880922856} = "Modhupur\,\ Tangail";
$areanames{en}->{88092288} = "Modhupur";
$areanames{en}->{88092298} = "Mirzapur";
$areanames{en}->{88093161} = "Sherpur";
$areanames{en}->{88093173} = "Nalitabari\,\ Sherpur";
$areanames{en}->{88093175} = "Nakla\,\ Sherpur";
$areanames{en}->{88093189} = "Sherpur";
$areanames{en}->{88094155} = "Kishoreganj";
$areanames{en}->{88094156} = "Kishoreganj";
$areanames{en}->{88094161} = "Kishoreganj";
$areanames{en}->{88094162} = "Kishoreganj";
$areanames{en}->{88094175} = "Tarail\,\ Kishoreganj";
$areanames{en}->{88094232} = "Bajitpur\,\ Kishoreganj";
$areanames{en}->{88094233} = "Bajitpur\,\ Kishoreganj";
$areanames{en}->{88094242} = "Bhairabbazar\,\ Kishoreganj";
$areanames{en}->{88094243} = "Bhairabbazar\,\ Kishoreganj";
$areanames{en}->{88094244} = "Bhairabbazar\,\ Kishoreganj";
$areanames{en}->{88094245} = "Bhairabbazar\,\ Kishoreganj";
$areanames{en}->{88094246} = "Bhairabbazar\,\ Kishoreganj";
$areanames{en}->{88094247} = "Bhairabbazar\,\ Kishoreganj";
$areanames{en}->{88094248} = "Bhairabbazar\,\ Kishoreganj";
$areanames{en}->{88094249} = "Bhairabbazar\,\ Kishoreganj";
$areanames{en}->{880942656} = "Itna\,\ Kishoreganj";
$areanames{en}->{88094288} = "Kotiadhi";
$areanames{en}->{88095161} = "Netrokona";
$areanames{en}->{88095162} = "Netrokona";
$areanames{en}->{88095189} = "Netrokona";
$areanames{en}->{88098162} = "Jamalpur";
$areanames{en}->{88098163} = "Jamalpur";
$areanames{en}->{88098164} = "Jamalpur";
$areanames{en}->{88098165} = "Jamalpur";
$areanames{en}->{88098174} = "Islampur\,\ Jamalpur";
$areanames{en}->{88098175} = "Dewanganj\,\ Jamalpur";
$areanames{en}->{88098189} = "Jamalpur";

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