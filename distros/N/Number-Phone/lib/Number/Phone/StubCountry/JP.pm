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
package Number::Phone::StubCountry::JP;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200606132000;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'intl_format' => 'NA',
                  'leading_digits' => '00777[01]',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '
            (?:
              12|
              57|
              99
            )0
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '
            1(?:
              267|
              3(?:
                7[247]|
                9[278]
              )|
              466|
              5(?:
                47|
                58|
                64
              )|
              6(?:
                3[245]|
                48|
                5[4-68]
              )
            )|
            499[2468]|
            5(?:
              769|
              979[2-69]
            )|
            7468|
            8(?:
              3(?:
                8[78]|
                96[2457-9]
              )|
              477|
              51[24]|
              636[457-9]
            )|
            9(?:
              496|
              802|
              9(?:
                1[23]|
                69
              )
            )|
            1(?:
              45|
              58
            )[67]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4})(\\d)(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '60',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '
            [36]|
            4(?:
              2(?:
                0|
                9[02-69]
              )|
              7(?:
                0[019]|
                1
              )
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '
            1(?:
              1|
              5(?:
                4[018]|
                5[017]
              )|
              77|
              88|
              9[69]
            )|
            2(?:
              2[127]|
              3[0-269]|
              4[59]|
              5(?:
                [0468][01]|
                [1-3]|
                5[0-69]|
                7[015-9]|
                9(?:
                  17|
                  99
                )
              )|
              6(?:
                2|
                4[016-9]
              )|
              7(?:
                [1-35]|
                8[0189]
              )|
              8(?:
                [16]|
                3[0134]|
                9[0-5]
              )|
              9(?:
                [028]|
                17|
                3[015-9]
              )
            )|
            4(?:
              2(?:
                [13-79]|
                2[01]|
                8[014-6]
              )|
              3[0-57]|
              [45]|
              6[248]|
              7[2-47]|
              9[29]
            )|
            5(?:
              2|
              3[045]|
              4[0-369]|
              5[29]|
              8[02389]|
              9[0-3]
            )|
            7(?:
              2[02-46-9]|
              34|
              [58]|
              6[0249]|
              7[57]|
              9(?:
                [23]|
                4[0-59]|
                5[01569]|
                6[0167]
              )
            )|
            8(?:
              2(?:
                [1258]|
                4[0-39]|
                9(?:
                  [019]|
                  4[1-3]|
                  6(?:
                    [0-47-9]|
                    5[01346-9]
                  )
                )
              )|
              3(?:
                [29]|
                7(?:
                  [017-9]|
                  6[6-8]
                )
              )|
              49|
              6(?:
                [0-24]|
                36[23]|
                5(?:
                  [0-389]|
                  5[23]
                )|
                6(?:
                  [01]|
                  9[178]
                )|
                72|
                9[0145]
              )|
              7[0-468]|
              8[68]
            )|
            9(?:
              4[15]|
              5[138]|
              6[1-3]|
              7[156]|
              8[189]|
              9(?:
                [1289]|
                3(?:
                  31|
                  4[357]
                )|
                4[0178]
              )
            )|
            (?:
              223|
              8699
            )[014-9]|
            (?:
              48|
              829(?:
                2|
                66
              )|
              9[23]
            )[1-9]|
            (?:
              47[59]|
              59[89]|
              8(?:
                68|
                9
              )
            )[019]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '
            [14]|
            [29][2-9]|
            5[3-9]|
            7[2-4679]|
            8(?:
              [246-9]|
              3(?:
                [3-6][2-9]|
                7|
                8[2-5]
              )|
              5[2-9]
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'intl_format' => 'NA',
                  'leading_digits' => '007',
                  'pattern' => '(\\d{4})(\\d{2})(\\d{3,4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'intl_format' => 'NA',
                  'leading_digits' => '008',
                  'pattern' => '(\\d{4})(\\d{2})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '800',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '
            [2579]|
            80
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'intl_format' => 'NA',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'intl_format' => 'NA',
                  'pattern' => '(\\d{4})(\\d{4})(\\d{4,5})'
                },
                {
                  'format' => '$1-$2-$3',
                  'intl_format' => 'NA',
                  'pattern' => '(\\d{4})(\\d{5})(\\d{5,6})'
                },
                {
                  'format' => '$1-$2-$3',
                  'intl_format' => 'NA',
                  'pattern' => '(\\d{4})(\\d{6})(\\d{6,7})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1(?:
              1[235-8]|
              2[3-6]|
              3[3-9]|
              4[2-6]|
              [58][2-8]|
              6[2-7]|
              7[2-9]|
              9[1-9]
            )|
            (?:
              2[2-9]|
              [36][1-9]
            )\\d|
            4(?:
              [2-578]\\d|
              6[02-8]|
              9[2-59]
            )|
            5(?:
              [2-589]\\d|
              6[1-9]|
              7[2-8]
            )|
            7(?:
              [25-9]\\d|
              3[4-9]|
              4[02-9]
            )|
            8(?:
              [2679]\\d|
              3[2-9]|
              4[5-9]|
              5[1-9]|
              8[03-9]
            )|
            9(?:
              [2-58]\\d|
              [679][1-9]
            )
          )\\d{6}
        ',
                'geographic' => '
          (?:
            1(?:
              1[235-8]|
              2[3-6]|
              3[3-9]|
              4[2-6]|
              [58][2-8]|
              6[2-7]|
              7[2-9]|
              9[1-9]
            )|
            (?:
              2[2-9]|
              [36][1-9]
            )\\d|
            4(?:
              [2-578]\\d|
              6[02-8]|
              9[2-59]
            )|
            5(?:
              [2-589]\\d|
              6[1-9]|
              7[2-8]
            )|
            7(?:
              [25-9]\\d|
              3[4-9]|
              4[02-9]
            )|
            8(?:
              [2679]\\d|
              3[2-9]|
              4[5-9]|
              5[1-9]|
              8[03-9]
            )|
            9(?:
              [2-58]\\d|
              [679][1-9]
            )
          )\\d{6}
        ',
                'mobile' => '[7-9]0[1-9]\\d{7}',
                'pager' => '20\\d{8}',
                'personal_number' => '60\\d{7}',
                'specialrate' => '(990\\d{6})|(570\\d{6})',
                'toll_free' => '
          00(?:
            (?:
              37|
              66
            )\\d{6,13}|
            (?:
              777(?:
                [01]|
                (?:
                  5|
                  8\\d
                )\\d
              )|
              882[1245]\\d\\d
            )\\d\\d
          )|
          (?:
            120|
            800\\d
          )\\d{6}
        ',
                'voip' => '50[1-9]\\d{7}'
              };
my %areanames = ();
$areanames{ja}->{8111} = "札幌";
$areanames{ja}->{811232} = "千歳";
$areanames{ja}->{811233} = "千歳";
$areanames{ja}->{811234} = "千歳";
$areanames{ja}->{811235} = "夕張";
$areanames{ja}->{811236} = "千歳";
$areanames{ja}->{811237} = "栗山";
$areanames{ja}->{811238} = "栗山";
$areanames{ja}->{8112390} = "夕張";
$areanames{ja}->{8112391} = "夕張";
$areanames{ja}->{8112392} = "夕張";
$areanames{ja}->{8112393} = "夕張";
$areanames{ja}->{8112394} = "夕張";
$areanames{ja}->{8112395} = "栗山";
$areanames{ja}->{8112396} = "栗山";
$areanames{ja}->{8112397} = "栗山";
$areanames{ja}->{8112398} = "栗山";
$areanames{ja}->{8112399} = "栗山";
$areanames{ja}->{81124} = "芦別";
$areanames{ja}->{81125} = "滝川";
$areanames{ja}->{81126} = "岩見沢";
$areanames{ja}->{811332} = "当別";
$areanames{ja}->{811333} = "当別";
$areanames{ja}->{811336} = "石狩";
$areanames{ja}->{811337} = "石狩";
$areanames{ja}->{81134} = "小樽";
$areanames{ja}->{811352} = "余市";
$areanames{ja}->{811353} = "余市";
$areanames{ja}->{811354} = "余市";
$areanames{ja}->{811356} = "岩内";
$areanames{ja}->{811357} = "岩内";
$areanames{ja}->{811362} = "倶知安";
$areanames{ja}->{811363} = "倶知安";
$areanames{ja}->{811364} = "倶知安";
$areanames{ja}->{811365} = "倶知安";
$areanames{ja}->{811366} = "寿都";
$areanames{ja}->{811367} = "寿都";
$areanames{ja}->{811372} = "鹿部";
$areanames{ja}->{811374} = "森";
$areanames{ja}->{811375} = "八雲";
$areanames{ja}->{811376} = "八雲";
$areanames{ja}->{811377} = "八雲";
$areanames{ja}->{811378} = "今金";
$areanames{ja}->{81138} = "函館";
$areanames{ja}->{811392} = "木古内";
$areanames{ja}->{811393} = "松前";
$areanames{ja}->{811394} = "松前";
$areanames{ja}->{811395} = "江差";
$areanames{ja}->{811396} = "江差";
$areanames{ja}->{811397} = "奥尻";
$areanames{ja}->{811398} = "熊石";
$areanames{ja}->{81142} = "伊達";
$areanames{ja}->{81143} = "室蘭";
$areanames{ja}->{81144} = "苫小牧";
$areanames{ja}->{811452} = "早来";
$areanames{ja}->{811453} = "早来";
$areanames{ja}->{811454} = "鵡川";
$areanames{ja}->{811455} = "鵡川";
$areanames{ja}->{811456} = "門別富川";
$areanames{ja}->{811457} = "門別富川";
$areanames{ja}->{811462} = "浦河";
$areanames{ja}->{811463} = "浦河";
$areanames{ja}->{811464} = "静内";
$areanames{ja}->{811465} = "静内";
$areanames{ja}->{811466} = "えりも";
$areanames{ja}->{811522} = "斜里";
$areanames{ja}->{811523} = "斜里";
$areanames{ja}->{811524} = "網走";
$areanames{ja}->{811525} = "網走";
$areanames{ja}->{811526} = "網走";
$areanames{ja}->{811527} = "美幌";
$areanames{ja}->{811528} = "美幌";
$areanames{ja}->{811532} = "根室";
$areanames{ja}->{811533} = "根室";
$areanames{ja}->{811534} = "中標津";
$areanames{ja}->{811535} = "厚岸";
$areanames{ja}->{811536} = "厚岸";
$areanames{ja}->{811537} = "中標津";
$areanames{ja}->{811538} = "根室標津";
$areanames{ja}->{811539} = "根室標津";
$areanames{ja}->{811541} = "弟子屈";
$areanames{ja}->{811542} = "釧路";
$areanames{ja}->{811543} = "釧路";
$areanames{ja}->{811544} = "釧路";
$areanames{ja}->{811545} = "釧路";
$areanames{ja}->{811546} = "釧路";
$areanames{ja}->{811547} = "白糠";
$areanames{ja}->{811548} = "弟子屈";
$areanames{ja}->{811549} = "釧路";
$areanames{ja}->{811551} = "十勝池田";
$areanames{ja}->{811552} = "帯広";
$areanames{ja}->{811553} = "帯広";
$areanames{ja}->{811554} = "帯広";
$areanames{ja}->{811555} = "帯広";
$areanames{ja}->{811556} = "帯広";
$areanames{ja}->{811557} = "十勝池田";
$areanames{ja}->{811558} = "広尾";
$areanames{ja}->{811559} = "帯広";
$areanames{ja}->{811562} = "本別";
$areanames{ja}->{811563} = "本別";
$areanames{ja}->{811564} = "上士幌";
$areanames{ja}->{811566} = "十勝清水";
$areanames{ja}->{811567} = "十勝清水";
$areanames{ja}->{81157} = "北見";
$areanames{ja}->{811582} = "紋別";
$areanames{ja}->{811583} = "紋別";
$areanames{ja}->{811584} = "遠軽";
$areanames{ja}->{811585} = "遠軽";
$areanames{ja}->{811586} = "中湧別";
$areanames{ja}->{811587} = "中湧別";
$areanames{ja}->{811588} = "興部";
$areanames{ja}->{811589} = "興部";
$areanames{ja}->{81162} = "稚内";
$areanames{ja}->{811632} = "天塩";
$areanames{ja}->{811634} = "浜頓別";
$areanames{ja}->{811635} = "浜頓別";
$areanames{ja}->{811636} = "北見枝幸";
$areanames{ja}->{811637} = "北見枝幸";
$areanames{ja}->{811638} = "利尻礼文";
$areanames{ja}->{811639} = "利尻礼文";
$areanames{ja}->{811642} = "石狩深川";
$areanames{ja}->{811643} = "石狩深川";
$areanames{ja}->{811644} = "留萌";
$areanames{ja}->{811645} = "留萌";
$areanames{ja}->{811646} = "羽幌";
$areanames{ja}->{811647} = "羽幌";
$areanames{ja}->{811648} = "焼尻";
$areanames{ja}->{811652} = "士別";
$areanames{ja}->{811653} = "士別";
$areanames{ja}->{811654} = "名寄";
$areanames{ja}->{811655} = "名寄";
$areanames{ja}->{811656} = "美深";
$areanames{ja}->{811658} = "上川";
$areanames{ja}->{81166} = "旭川";
$areanames{ja}->{81167} = "富良野";
$areanames{ja}->{81172} = "弘前";
$areanames{ja}->{811732} = "五所川原";
$areanames{ja}->{811733} = "五所川原";
$areanames{ja}->{811734} = "五所川原";
$areanames{ja}->{811735} = "五所川原";
$areanames{ja}->{811736} = "五所川原";
$areanames{ja}->{811737} = "鰺ケ沢";
$areanames{ja}->{811738} = "鰺ケ沢";
$areanames{ja}->{81174} = "蟹田";
$areanames{ja}->{811752} = "むつ";
$areanames{ja}->{811753} = "むつ";
$areanames{ja}->{811754} = "むつ";
$areanames{ja}->{811756} = "野辺地";
$areanames{ja}->{811757} = "野辺地";
$areanames{ja}->{81176} = "十和田";
$areanames{ja}->{81177} = "青森";
$areanames{ja}->{81178} = "八戸";
$areanames{ja}->{81179} = "三戸";
$areanames{ja}->{81182} = "横手";
$areanames{ja}->{81183} = "湯沢";
$areanames{ja}->{81184} = "本荘";
$areanames{ja}->{811852} = "男鹿";
$areanames{ja}->{811853} = "男鹿";
$areanames{ja}->{811854} = "男鹿";
$areanames{ja}->{811855} = "能代";
$areanames{ja}->{811856} = "能代";
$areanames{ja}->{811857} = "能代";
$areanames{ja}->{811858} = "能代";
$areanames{ja}->{811862} = "鹿角";
$areanames{ja}->{811863} = "鹿角";
$areanames{ja}->{811864} = "大館";
$areanames{ja}->{811865} = "大館";
$areanames{ja}->{811866} = "鷹巣";
$areanames{ja}->{811867} = "鷹巣";
$areanames{ja}->{811868} = "鷹巣";
$areanames{ja}->{811869} = "大館";
$areanames{ja}->{811873} = "角館";
$areanames{ja}->{811874} = "角館";
$areanames{ja}->{811875} = "角館";
$areanames{ja}->{811876} = "大曲";
$areanames{ja}->{811877} = "大曲";
$areanames{ja}->{811878} = "大曲";
$areanames{ja}->{81188} = "秋田";
$areanames{ja}->{81191} = "一関";
$areanames{ja}->{81192} = "大船渡";
$areanames{ja}->{811932} = "釜石";
$areanames{ja}->{811933} = "釜石";
$areanames{ja}->{811934} = "釜石";
$areanames{ja}->{811935} = "釜石";
$areanames{ja}->{811936} = "宮古";
$areanames{ja}->{811937} = "宮古";
$areanames{ja}->{811938} = "宮古";
$areanames{ja}->{811939} = "宮古";
$areanames{ja}->{811942} = "岩泉";
$areanames{ja}->{811943} = "岩泉";
$areanames{ja}->{811944} = "岩泉";
$areanames{ja}->{811945} = "久慈";
$areanames{ja}->{811946} = "久慈";
$areanames{ja}->{811947} = "久慈";
$areanames{ja}->{811952} = "二戸";
$areanames{ja}->{811953} = "二戸";
$areanames{ja}->{811954} = "二戸";
$areanames{ja}->{811955} = "二戸";
$areanames{ja}->{811956} = "岩手";
$areanames{ja}->{811957} = "岩手";
$areanames{ja}->{811958} = "岩手";
$areanames{ja}->{81196} = "盛岡";
$areanames{ja}->{811972} = "水沢";
$areanames{ja}->{811973} = "水沢";
$areanames{ja}->{811974} = "水沢";
$areanames{ja}->{811975} = "水沢";
$areanames{ja}->{811976} = "北上";
$areanames{ja}->{811977} = "北上";
$areanames{ja}->{811978} = "北上";
$areanames{ja}->{811982} = "花巻";
$areanames{ja}->{811983} = "花巻";
$areanames{ja}->{811984} = "花巻";
$areanames{ja}->{811986} = "遠野";
$areanames{ja}->{811987} = "遠野";
$areanames{ja}->{81199} = "盛岡";
$areanames{ja}->{81220} = "迫";
$areanames{ja}->{81222} = "仙台";
$areanames{ja}->{812230} = "仙台";
$areanames{ja}->{812232} = "岩沼";
$areanames{ja}->{812233} = "岩沼";
$areanames{ja}->{812234} = "仙台";
$areanames{ja}->{812235} = "仙台";
$areanames{ja}->{812236} = "仙台";
$areanames{ja}->{812237} = "仙台";
$areanames{ja}->{812238} = "仙台";
$areanames{ja}->{812239} = "仙台";
$areanames{ja}->{812242} = "白石";
$areanames{ja}->{812243} = "白石";
$areanames{ja}->{812244} = "白石";
$areanames{ja}->{812245} = "大河原";
$areanames{ja}->{812246} = "大河原";
$areanames{ja}->{812247} = "大河原";
$areanames{ja}->{812248} = "大河原";
$areanames{ja}->{81225} = "石巻";
$areanames{ja}->{81226} = "気仙沼";
$areanames{ja}->{81227} = "仙台";
$areanames{ja}->{81228} = "築館";
$areanames{ja}->{81229} = "古川";
$areanames{ja}->{81233} = "新庄";
$areanames{ja}->{81234} = "酒田";
$areanames{ja}->{81235} = "鶴岡";
$areanames{ja}->{81236} = "山形";
$areanames{ja}->{812372} = "村山";
$areanames{ja}->{812373} = "村山";
$areanames{ja}->{812374} = "村山";
$areanames{ja}->{812375} = "村山";
$areanames{ja}->{812376} = "寒河江";
$areanames{ja}->{812377} = "寒河江";
$areanames{ja}->{812378} = "寒河江";
$areanames{ja}->{812382} = "米沢";
$areanames{ja}->{812383} = "米沢";
$areanames{ja}->{812384} = "米沢";
$areanames{ja}->{812385} = "米沢";
$areanames{ja}->{812386} = "長井";
$areanames{ja}->{812387} = "長井";
$areanames{ja}->{812388} = "長井";
$areanames{ja}->{812389} = "米沢";
$areanames{ja}->{81240} = "磐城富岡";
$areanames{ja}->{812412} = "喜多方";
$areanames{ja}->{812413} = "喜多方";
$areanames{ja}->{812414} = "柳津";
$areanames{ja}->{812415} = "柳津";
$areanames{ja}->{812416} = "田島";
$areanames{ja}->{812417} = "会津山口";
$areanames{ja}->{812418} = "会津山口";
$areanames{ja}->{812419} = "田島";
$areanames{ja}->{8124196} = "柳津";
$areanames{ja}->{8124197} = "柳津";
$areanames{ja}->{81242} = "会津若松";
$areanames{ja}->{81243} = "二本松";
$areanames{ja}->{81244} = "原町";
$areanames{ja}->{81245} = "福島";
$areanames{ja}->{81246} = "いわき";
$areanames{ja}->{812472} = "石川";
$areanames{ja}->{812473} = "石川";
$areanames{ja}->{812474} = "石川";
$areanames{ja}->{812475} = "石川";
$areanames{ja}->{812476} = "三春";
$areanames{ja}->{812477} = "三春";
$areanames{ja}->{812478} = "三春";
$areanames{ja}->{812482} = "白河";
$areanames{ja}->{812483} = "白河";
$areanames{ja}->{812484} = "白河";
$areanames{ja}->{812485} = "白河";
$areanames{ja}->{812486} = "須賀川";
$areanames{ja}->{812487} = "須賀川";
$areanames{ja}->{812488} = "須賀川";
$areanames{ja}->{812489} = "須賀川";
$areanames{ja}->{81249} = "郡山";
$areanames{ja}->{81250} = "新津";
$areanames{ja}->{81252} = "新潟";
$areanames{ja}->{81253} = "新潟";
$areanames{ja}->{812542} = "新発田";
$areanames{ja}->{812543} = "新発田";
$areanames{ja}->{812544} = "新発田";
$areanames{ja}->{812545} = "村上";
$areanames{ja}->{812546} = "村上";
$areanames{ja}->{812547} = "村上";
$areanames{ja}->{8125480} = "村上";
$areanames{ja}->{8125481} = "村上";
$areanames{ja}->{8125482} = "村上";
$areanames{ja}->{8125483} = "村上";
$areanames{ja}->{8125484} = "村上";
$areanames{ja}->{8125485} = "津川";
$areanames{ja}->{8125486} = "津川";
$areanames{ja}->{8125487} = "津川";
$areanames{ja}->{8125488} = "津川";
$areanames{ja}->{8125489} = "津川";
$areanames{ja}->{812549} = "津川";
$areanames{ja}->{812550} = "安塚";
$areanames{ja}->{812551} = "上越";
$areanames{ja}->{812552} = "上越";
$areanames{ja}->{812553} = "上越";
$areanames{ja}->{812554} = "上越";
$areanames{ja}->{812555} = "糸魚川";
$areanames{ja}->{812556} = "糸魚川";
$areanames{ja}->{812557} = "新井";
$areanames{ja}->{812558} = "新井";
$areanames{ja}->{812559} = "安塚";
$areanames{ja}->{812560} = "糸魚川";
$areanames{ja}->{812562} = "三条";
$areanames{ja}->{812563} = "三条";
$areanames{ja}->{812564} = "三条";
$areanames{ja}->{812565} = "三条";
$areanames{ja}->{812566} = "三条";
$areanames{ja}->{812567} = "巻";
$areanames{ja}->{812568} = "巻";
$areanames{ja}->{812569} = "巻";
$areanames{ja}->{812570} = "小出";
$areanames{ja}->{812571} = "六日町";
$areanames{ja}->{812572} = "柏崎";
$areanames{ja}->{812573} = "柏崎";
$areanames{ja}->{812574} = "柏崎";
$areanames{ja}->{812575} = "十日町";
$areanames{ja}->{812576} = "十日町";
$areanames{ja}->{812577} = "六日町";
$areanames{ja}->{812578} = "六日町";
$areanames{ja}->{812579} = "小出";
$areanames{ja}->{812580} = "十日町";
$areanames{ja}->{812582} = "長岡";
$areanames{ja}->{812583} = "長岡";
$areanames{ja}->{812584} = "長岡";
$areanames{ja}->{812585} = "長岡";
$areanames{ja}->{812586} = "長岡";
$areanames{ja}->{812587} = "長岡";
$areanames{ja}->{812588} = "長岡";
$areanames{ja}->{812589} = "長岡";
$areanames{ja}->{81259} = "佐渡";
$areanames{ja}->{81260} = "阿南町";
$areanames{ja}->{812612} = "大町";
$areanames{ja}->{812613} = "大町";
$areanames{ja}->{812614} = "大町";
$areanames{ja}->{812615} = "大町";
$areanames{ja}->{812616} = "大町";
$areanames{ja}->{812617} = "大町";
$areanames{ja}->{8126177} = "長野";
$areanames{ja}->{812618} = "大町";
$areanames{ja}->{812619} = "大町";
$areanames{ja}->{81262} = "長野";
$areanames{ja}->{81263} = "松本";
$areanames{ja}->{812640} = "長野";
$areanames{ja}->{812642} = "木曾福島";
$areanames{ja}->{812643} = "木曾福島";
$areanames{ja}->{812644} = "木曾福島";
$areanames{ja}->{812645} = "木曾福島";
$areanames{ja}->{812646} = "長野";
$areanames{ja}->{812647} = "長野";
$areanames{ja}->{812648} = "長野";
$areanames{ja}->{812649} = "長野";
$areanames{ja}->{812652} = "飯田";
$areanames{ja}->{812653} = "飯田";
$areanames{ja}->{812654} = "飯田";
$areanames{ja}->{812655} = "飯田";
$areanames{ja}->{812656} = "伊那";
$areanames{ja}->{812657} = "伊那";
$areanames{ja}->{812658} = "伊那";
$areanames{ja}->{812659} = "伊那";
$areanames{ja}->{81266} = "諏訪";
$areanames{ja}->{812672} = "小諸";
$areanames{ja}->{812673} = "小諸";
$areanames{ja}->{812674} = "小諸";
$areanames{ja}->{812675} = "佐久";
$areanames{ja}->{812676} = "佐久";
$areanames{ja}->{812677} = "佐久";
$areanames{ja}->{812678} = "佐久";
$areanames{ja}->{812679} = "佐久";
$areanames{ja}->{81268} = "上田";
$areanames{ja}->{812692} = "中野";
$areanames{ja}->{812693} = "中野";
$areanames{ja}->{812694} = "中野";
$areanames{ja}->{812695} = "中野";
$areanames{ja}->{812696} = "飯山";
$areanames{ja}->{812697} = "飯山";
$areanames{ja}->{812698} = "飯山";
$areanames{ja}->{81270} = "伊勢崎";
$areanames{ja}->{81272} = "前橋";
$areanames{ja}->{81273} = "高崎";
$areanames{ja}->{812742} = "藤岡";
$areanames{ja}->{812743} = "藤岡";
$areanames{ja}->{812744} = "藤岡";
$areanames{ja}->{812745} = "藤岡";
$areanames{ja}->{812746} = "富岡";
$areanames{ja}->{812747} = "富岡";
$areanames{ja}->{812748} = "富岡";
$areanames{ja}->{81276} = "太田";
$areanames{ja}->{81277} = "桐生";
$areanames{ja}->{812780} = "前橋";
$areanames{ja}->{812782} = "沼田";
$areanames{ja}->{812783} = "沼田";
$areanames{ja}->{812784} = "沼田";
$areanames{ja}->{812785} = "沼田";
$areanames{ja}->{812786} = "沼田";
$areanames{ja}->{812787} = "沼田";
$areanames{ja}->{812788} = "前橋";
$areanames{ja}->{812789} = "前橋";
$areanames{ja}->{812792} = "渋川";
$areanames{ja}->{812793} = "渋川";
$areanames{ja}->{812794} = "渋川";
$areanames{ja}->{812795} = "渋川";
$areanames{ja}->{812796} = "渋川";
$areanames{ja}->{812797} = "渋川";
$areanames{ja}->{812798} = "長野原";
$areanames{ja}->{812799} = "長野原";
$areanames{ja}->{81280} = "古河";
$areanames{ja}->{81281} = "宇都宮";
$areanames{ja}->{81282} = "栃木";
$areanames{ja}->{812830} = "宇都宮";
$areanames{ja}->{812832} = "佐野";
$areanames{ja}->{812833} = "宇都宮";
$areanames{ja}->{812834} = "宇都宮";
$areanames{ja}->{812835} = "佐野";
$areanames{ja}->{812836} = "佐野";
$areanames{ja}->{812837} = "佐野";
$areanames{ja}->{812838} = "佐野";
$areanames{ja}->{812839} = "佐野";
$areanames{ja}->{81284} = "足利";
$areanames{ja}->{812852} = "小山";
$areanames{ja}->{812853} = "小山";
$areanames{ja}->{812854} = "小山";
$areanames{ja}->{812855} = "小山";
$areanames{ja}->{812856} = "真岡";
$areanames{ja}->{812857} = "真岡";
$areanames{ja}->{812858} = "真岡";
$areanames{ja}->{812859} = "小山";
$areanames{ja}->{81286} = "宇都宮";
$areanames{ja}->{812872} = "大田原";
$areanames{ja}->{812873} = "大田原";
$areanames{ja}->{812874} = "大田原";
$areanames{ja}->{812875} = "大田原";
$areanames{ja}->{812876} = "黒磯";
$areanames{ja}->{812877} = "黒磯";
$areanames{ja}->{812878} = "烏山";
$areanames{ja}->{812879} = "烏山";
$areanames{ja}->{8128798} = "大田原";
$areanames{ja}->{81288} = "今市";
$areanames{ja}->{812890} = "宇都宮";
$areanames{ja}->{812892} = "宇都宮";
$areanames{ja}->{812893} = "宇都宮";
$areanames{ja}->{812894} = "宇都宮";
$areanames{ja}->{812895} = "宇都宮";
$areanames{ja}->{812896} = "鹿沼";
$areanames{ja}->{812897} = "鹿沼";
$areanames{ja}->{812898} = "鹿沼";
$areanames{ja}->{812899} = "鹿沼";
$areanames{ja}->{812911} = "鉾田";
$areanames{ja}->{812913} = "鉾田";
$areanames{ja}->{812914} = "鉾田";
$areanames{ja}->{812917} = "水戸";
$areanames{ja}->{81292} = "水戸";
$areanames{ja}->{812930} = "水戸";
$areanames{ja}->{812932} = "高萩";
$areanames{ja}->{812933} = "高萩";
$areanames{ja}->{812934} = "高萩";
$areanames{ja}->{812935} = "水戸";
$areanames{ja}->{812936} = "水戸";
$areanames{ja}->{812937} = "水戸";
$areanames{ja}->{812938} = "水戸";
$areanames{ja}->{812939} = "水戸";
$areanames{ja}->{81294} = "常陸太田";
$areanames{ja}->{812955} = "常陸大宮";
$areanames{ja}->{812956} = "常陸大宮";
$areanames{ja}->{812957} = "大子";
$areanames{ja}->{812962} = "下館";
$areanames{ja}->{812963} = "下館";
$areanames{ja}->{812964} = "下館";
$areanames{ja}->{812965} = "下館";
$areanames{ja}->{812967} = "笠間";
$areanames{ja}->{812968} = "笠間";
$areanames{ja}->{812972} = "水海道";
$areanames{ja}->{812973} = "水海道";
$areanames{ja}->{812974} = "水海道";
$areanames{ja}->{812975} = "水海道";
$areanames{ja}->{812976} = "竜ケ崎";
$areanames{ja}->{812977} = "竜ケ崎";
$areanames{ja}->{812978} = "竜ケ崎";
$areanames{ja}->{812979} = "竜ケ崎";
$areanames{ja}->{81298} = "土浦";
$areanames{ja}->{812992} = "石岡";
$areanames{ja}->{812993} = "石岡";
$areanames{ja}->{812994} = "石岡";
$areanames{ja}->{812995} = "石岡";
$areanames{ja}->{812996} = "潮来";
$areanames{ja}->{812997} = "潮来";
$areanames{ja}->{812998} = "潮来";
$areanames{ja}->{812999} = "潮来";
$areanames{ja}->{813} = "東京";
$areanames{ja}->{81420} = "所沢";
$areanames{ja}->{814220} = "国分寺";
$areanames{ja}->{814222} = "武蔵野三鷹";
$areanames{ja}->{814223} = "武蔵野三鷹";
$areanames{ja}->{814224} = "武蔵野三鷹";
$areanames{ja}->{814225} = "武蔵野三鷹";
$areanames{ja}->{814226} = "武蔵野三鷹";
$areanames{ja}->{814227} = "武蔵野三鷹";
$areanames{ja}->{814228} = "武蔵野三鷹";
$areanames{ja}->{814229} = "武蔵野三鷹";
$areanames{ja}->{81423} = "国分寺";
$areanames{ja}->{81424} = "武蔵野三鷹";
$areanames{ja}->{814240} = "国分寺";
$areanames{ja}->{81425} = "立川";
$areanames{ja}->{81426} = "八王子";
$areanames{ja}->{81427} = "相模原";
$areanames{ja}->{814280} = "立川";
$areanames{ja}->{814281} = "相模原";
$areanames{ja}->{814282} = "青梅";
$areanames{ja}->{814283} = "青梅";
$areanames{ja}->{814284} = "立川";
$areanames{ja}->{814285} = "相模原";
$areanames{ja}->{814286} = "相模原";
$areanames{ja}->{814287} = "青梅";
$areanames{ja}->{814288} = "青梅";
$areanames{ja}->{814289} = "青梅";
$areanames{ja}->{81429} = "所沢";
$areanames{ja}->{814291} = "飯能";
$areanames{ja}->{814297} = "飯能";
$areanames{ja}->{814298} = "飯能";
$areanames{ja}->{81432} = "千葉";
$areanames{ja}->{81433} = "千葉";
$areanames{ja}->{81434} = "千葉";
$areanames{ja}->{81436} = "市原";
$areanames{ja}->{81438} = "木更津";
$areanames{ja}->{81439} = "木更津";
$areanames{ja}->{8144} = "川崎";
$areanames{ja}->{8145} = "横浜";
$areanames{ja}->{81460} = "小田原";
$areanames{ja}->{81462} = "厚木";
$areanames{ja}->{81463} = "平塚";
$areanames{ja}->{81464} = "厚木";
$areanames{ja}->{81465} = "小田原";
$areanames{ja}->{81466} = "藤沢";
$areanames{ja}->{81467} = "藤沢";
$areanames{ja}->{81468} = "横須賀";
$areanames{ja}->{814700} = "鴨川";
$areanames{ja}->{814701} = "鴨川";
$areanames{ja}->{814702} = "館山";
$areanames{ja}->{814703} = "館山";
$areanames{ja}->{814704} = "館山";
$areanames{ja}->{814705} = "館山";
$areanames{ja}->{814706} = "大原";
$areanames{ja}->{814707} = "大原";
$areanames{ja}->{814708} = "大原";
$areanames{ja}->{814709} = "鴨川";
$areanames{ja}->{81471} = "柏";
$areanames{ja}->{81473} = "市川";
$areanames{ja}->{81474} = "船橋";
$areanames{ja}->{814752} = "茂原";
$areanames{ja}->{814753} = "茂原";
$areanames{ja}->{814754} = "茂原";
$areanames{ja}->{814755} = "東金";
$areanames{ja}->{814756} = "東金";
$areanames{ja}->{814757} = "東金";
$areanames{ja}->{814758} = "東金";
$areanames{ja}->{81476} = "成田";
$areanames{ja}->{814770} = "市川";
$areanames{ja}->{814771} = "市川";
$areanames{ja}->{814772} = "市川";
$areanames{ja}->{814775} = "船橋";
$areanames{ja}->{814776} = "船橋";
$areanames{ja}->{814777} = "船橋";
$areanames{ja}->{81478} = "佐原";
$areanames{ja}->{814792} = "銚子";
$areanames{ja}->{814793} = "銚子";
$areanames{ja}->{814794} = "銚子";
$areanames{ja}->{814795} = "銚子";
$areanames{ja}->{8147950} = "八日市場";
$areanames{ja}->{8147955} = "八日市場";
$areanames{ja}->{8147957} = "八日市場";
$areanames{ja}->{814796} = "八日市場";
$areanames{ja}->{814797} = "八日市場";
$areanames{ja}->{814798} = "八日市場";
$areanames{ja}->{81480} = "久喜";
$areanames{ja}->{81482} = "川口";
$areanames{ja}->{81484} = "川口";
$areanames{ja}->{81485} = "熊谷";
$areanames{ja}->{81486} = "浦和";
$areanames{ja}->{81487} = "浦和";
$areanames{ja}->{81488} = "浦和";
$areanames{ja}->{81489} = "草加";
$areanames{ja}->{81492} = "川越";
$areanames{ja}->{81493} = "東松山";
$areanames{ja}->{81494} = "秩父";
$areanames{ja}->{81495} = "本庄";
$areanames{ja}->{814992} = "伊豆大島";
$areanames{ja}->{814994} = "三宅";
$areanames{ja}->{814996} = "八丈島";
$areanames{ja}->{814998} = "小笠原";
$areanames{ja}->{8152} = "名古屋";
$areanames{ja}->{81531} = "田原";
$areanames{ja}->{81532} = "豊橋";
$areanames{ja}->{81533} = "豊橋";
$areanames{ja}->{81534} = "浜松";
$areanames{ja}->{81535} = "浜松";
$areanames{ja}->{815362} = "新城";
$areanames{ja}->{815363} = "新城";
$areanames{ja}->{815366} = "設楽";
$areanames{ja}->{815367} = "設楽";
$areanames{ja}->{815368} = "設楽";
$areanames{ja}->{81537} = "掛川";
$areanames{ja}->{81538} = "磐田";
$areanames{ja}->{815392} = "浜松";
$areanames{ja}->{815393} = "浜松";
$areanames{ja}->{815394} = "浜松";
$areanames{ja}->{815395} = "浜松";
$areanames{ja}->{815396} = "浜松";
$areanames{ja}->{8153960} = "天竜";
$areanames{ja}->{8153961} = "天竜";
$areanames{ja}->{8153962} = "天竜";
$areanames{ja}->{8153963} = "天竜";
$areanames{ja}->{815397} = "浜松";
$areanames{ja}->{8153974} = "天竜";
$areanames{ja}->{8153977} = "天竜";
$areanames{ja}->{815398} = "浜松";
$areanames{ja}->{815399} = "天竜";
$areanames{ja}->{81542} = "静岡";
$areanames{ja}->{81543} = "静岡";
$areanames{ja}->{81544} = "富士宮";
$areanames{ja}->{81545} = "富士";
$areanames{ja}->{81546} = "静岡";
$areanames{ja}->{81547} = "島田";
$areanames{ja}->{81548} = "榛原";
$areanames{ja}->{81549} = "静岡";
$areanames{ja}->{81550} = "御殿場";
$areanames{ja}->{81551} = "韮崎";
$areanames{ja}->{81552} = "甲府";
$areanames{ja}->{81553} = "山梨";
$areanames{ja}->{81554} = "大月";
$areanames{ja}->{81555} = "吉田";
$areanames{ja}->{815562} = "鰍沢青柳";
$areanames{ja}->{815563} = "鰍沢青柳";
$areanames{ja}->{815564} = "鰍沢青柳";
$areanames{ja}->{815565} = "鰍沢青柳";
$areanames{ja}->{815566} = "身延";
$areanames{ja}->{81557} = "伊東";
$areanames{ja}->{815582} = "下田";
$areanames{ja}->{815583} = "下田";
$areanames{ja}->{815584} = "下田";
$areanames{ja}->{815585} = "下田";
$areanames{ja}->{815586} = "下田";
$areanames{ja}->{815587} = "修善寺大仁";
$areanames{ja}->{815588} = "修善寺大仁";
$areanames{ja}->{815589} = "修善寺大仁";
$areanames{ja}->{81559} = "沼津";
$areanames{ja}->{81561} = "瀬戸";
$areanames{ja}->{81562} = "尾張横須賀";
$areanames{ja}->{81563} = "西尾";
$areanames{ja}->{81564} = "岡崎";
$areanames{ja}->{81565} = "豊田";
$areanames{ja}->{81566} = "刈谷";
$areanames{ja}->{81567} = "津島";
$areanames{ja}->{81568} = "春日井";
$areanames{ja}->{81569} = "半田";
$areanames{ja}->{81572} = "多治見";
$areanames{ja}->{815732} = "恵那";
$areanames{ja}->{815733} = "恵那";
$areanames{ja}->{815734} = "恵那";
$areanames{ja}->{815735} = "恵那";
$areanames{ja}->{815736} = "中津川";
$areanames{ja}->{815737} = "中津川";
$areanames{ja}->{815738} = "中津川";
$areanames{ja}->{815742} = "美濃加茂";
$areanames{ja}->{815743} = "美濃加茂";
$areanames{ja}->{815744} = "美濃加茂";
$areanames{ja}->{815745} = "美濃加茂";
$areanames{ja}->{815746} = "美濃加茂";
$areanames{ja}->{815747} = "美濃白川";
$areanames{ja}->{815748} = "美濃白川";
$areanames{ja}->{815752} = "関";
$areanames{ja}->{815753} = "関";
$areanames{ja}->{815754} = "関";
$areanames{ja}->{815755} = "関";
$areanames{ja}->{815756} = "郡上八幡";
$areanames{ja}->{815757} = "郡上八幡";
$areanames{ja}->{815758} = "郡上八幡";
$areanames{ja}->{815762} = "下呂";
$areanames{ja}->{815763} = "下呂";
$areanames{ja}->{815764} = "下呂";
$areanames{ja}->{815765} = "下呂";
$areanames{ja}->{815766} = "下呂";
$areanames{ja}->{815767} = "下呂";
$areanames{ja}->{815768} = "下呂";
$areanames{ja}->{815769} = "荘川";
$areanames{ja}->{81577} = "高山";
$areanames{ja}->{81578} = "神岡";
$areanames{ja}->{81581} = "高富";
$areanames{ja}->{81582} = "岐阜";
$areanames{ja}->{81583} = "岐阜";
$areanames{ja}->{81584} = "大垣";
$areanames{ja}->{81585} = "揖斐川";
$areanames{ja}->{81586} = "一宮";
$areanames{ja}->{81587} = "一宮";
$areanames{ja}->{81591} = "津";
$areanames{ja}->{81592} = "津";
$areanames{ja}->{81593} = "四日市";
$areanames{ja}->{81594} = "桑名";
$areanames{ja}->{815952} = "上野";
$areanames{ja}->{815953} = "上野";
$areanames{ja}->{815954} = "上野";
$areanames{ja}->{815955} = "上野";
$areanames{ja}->{815956} = "上野";
$areanames{ja}->{815957} = "上野";
$areanames{ja}->{815958} = "亀山";
$areanames{ja}->{815959} = "亀山";
$areanames{ja}->{81596} = "伊勢";
$areanames{ja}->{815972} = "尾鷲";
$areanames{ja}->{815973} = "尾鷲";
$areanames{ja}->{815974} = "尾鷲";
$areanames{ja}->{815977} = "熊野";
$areanames{ja}->{815978} = "熊野";
$areanames{ja}->{815979} = "熊野";
$areanames{ja}->{815982} = "松阪";
$areanames{ja}->{815983} = "松阪";
$areanames{ja}->{815984} = "松阪";
$areanames{ja}->{815985} = "松阪";
$areanames{ja}->{815986} = "松阪";
$areanames{ja}->{815987} = "三瀬谷";
$areanames{ja}->{815988} = "三瀬谷";
$areanames{ja}->{815992} = "鳥羽";
$areanames{ja}->{815993} = "鳥羽";
$areanames{ja}->{815994} = "阿児";
$areanames{ja}->{815995} = "阿児";
$areanames{ja}->{815996} = "阿児";
$areanames{ja}->{815997} = "阿児";
$areanames{ja}->{815998} = "阿児";
$areanames{ja}->{815999} = "津";
$areanames{ja}->{816} = "大阪";
$areanames{ja}->{81721} = "富田林";
$areanames{ja}->{81722} = "堺";
$areanames{ja}->{81723} = "堺";
$areanames{ja}->{817230} = "寝屋川";
$areanames{ja}->{817238} = "寝屋川";
$areanames{ja}->{817239} = "寝屋川";
$areanames{ja}->{81724} = "岸和田貝塚";
$areanames{ja}->{81725} = "和泉";
$areanames{ja}->{81726} = "茨木";
$areanames{ja}->{81727} = "池田";
$areanames{ja}->{81728} = "寝屋川";
$areanames{ja}->{81729} = "八尾";
$areanames{ja}->{81734} = "和歌山";
$areanames{ja}->{817352} = "新宮";
$areanames{ja}->{817353} = "新宮";
$areanames{ja}->{817354} = "新宮";
$areanames{ja}->{817355} = "新宮";
$areanames{ja}->{817356} = "串本";
$areanames{ja}->{817357} = "串本";
$areanames{ja}->{817362} = "和歌山橋本";
$areanames{ja}->{817363} = "和歌山橋本";
$areanames{ja}->{817364} = "和歌山橋本";
$areanames{ja}->{817365} = "和歌山橋本";
$areanames{ja}->{817366} = "岩出";
$areanames{ja}->{817367} = "岩出";
$areanames{ja}->{817368} = "岩出";
$areanames{ja}->{81737} = "湯浅";
$areanames{ja}->{81738} = "御坊";
$areanames{ja}->{81739} = "田辺";
$areanames{ja}->{81740} = "今津";
$areanames{ja}->{81742} = "奈良";
$areanames{ja}->{81743} = "奈良";
$areanames{ja}->{81744} = "大和高田";
$areanames{ja}->{817452} = "大和高田";
$areanames{ja}->{817453} = "大和高田";
$areanames{ja}->{817454} = "大和高田";
$areanames{ja}->{817455} = "大和高田";
$areanames{ja}->{817456} = "大和高田";
$areanames{ja}->{817457} = "大和高田";
$areanames{ja}->{817458} = "大和榛原";
$areanames{ja}->{817459} = "大和榛原";
$areanames{ja}->{817463} = "吉野";
$areanames{ja}->{817464} = "吉野";
$areanames{ja}->{817465} = "吉野";
$areanames{ja}->{817466} = "十津川";
$areanames{ja}->{817468} = "上北山";
$areanames{ja}->{817472} = "五条";
$areanames{ja}->{817473} = "五条";
$areanames{ja}->{817474} = "五条";
$areanames{ja}->{817475} = "下市";
$areanames{ja}->{817476} = "下市";
$areanames{ja}->{817482} = "八日市";
$areanames{ja}->{817483} = "八日市";
$areanames{ja}->{817484} = "八日市";
$areanames{ja}->{817485} = "八日市";
$areanames{ja}->{817486} = "水口";
$areanames{ja}->{817487} = "水口";
$areanames{ja}->{817488} = "水口";
$areanames{ja}->{817492} = "彦根";
$areanames{ja}->{817493} = "彦根";
$areanames{ja}->{817494} = "彦根";
$areanames{ja}->{817495} = "長浜";
$areanames{ja}->{817496} = "長浜";
$areanames{ja}->{817497} = "長浜";
$areanames{ja}->{817498} = "長浜";
$areanames{ja}->{8175} = "京都";
$areanames{ja}->{817612} = "小松";
$areanames{ja}->{817613} = "小松";
$areanames{ja}->{817614} = "小松";
$areanames{ja}->{817615} = "小松";
$areanames{ja}->{817616} = "小松";
$areanames{ja}->{817617} = "加賀";
$areanames{ja}->{817618} = "加賀";
$areanames{ja}->{81762} = "金沢";
$areanames{ja}->{81763} = "福野";
$areanames{ja}->{81764} = "富山";
$areanames{ja}->{81765} = "魚津";
$areanames{ja}->{81766} = "高岡";
$areanames{ja}->{817672} = "羽咋";
$areanames{ja}->{817673} = "羽咋";
$areanames{ja}->{817674} = "羽咋";
$areanames{ja}->{817675} = "七尾";
$areanames{ja}->{817676} = "七尾";
$areanames{ja}->{817677} = "七尾";
$areanames{ja}->{817678} = "七尾";
$areanames{ja}->{817682} = "輪島";
$areanames{ja}->{817683} = "輪島";
$areanames{ja}->{817684} = "輪島";
$areanames{ja}->{817685} = "輪島";
$areanames{ja}->{817686} = "能都";
$areanames{ja}->{817687} = "能都";
$areanames{ja}->{817688} = "能都";
$areanames{ja}->{817702} = "敦賀";
$areanames{ja}->{817703} = "敦賀";
$areanames{ja}->{817704} = "敦賀";
$areanames{ja}->{817705} = "小浜";
$areanames{ja}->{817706} = "小浜";
$areanames{ja}->{817707} = "小浜";
$areanames{ja}->{817712} = "亀岡";
$areanames{ja}->{817713} = "亀岡";
$areanames{ja}->{817714} = "亀岡";
$areanames{ja}->{817715} = "亀岡";
$areanames{ja}->{817716} = "園部";
$areanames{ja}->{817717} = "園部";
$areanames{ja}->{817718} = "園部";
$areanames{ja}->{817722} = "宮津";
$areanames{ja}->{817723} = "宮津";
$areanames{ja}->{817724} = "宮津";
$areanames{ja}->{817725} = "宮津";
$areanames{ja}->{817726} = "峰山";
$areanames{ja}->{817727} = "峰山";
$areanames{ja}->{817728} = "峰山";
$areanames{ja}->{817732} = "福知山";
$areanames{ja}->{817733} = "福知山";
$areanames{ja}->{817734} = "福知山";
$areanames{ja}->{817735} = "福知山";
$areanames{ja}->{817736} = "舞鶴";
$areanames{ja}->{817737} = "舞鶴";
$areanames{ja}->{817738} = "舞鶴";
$areanames{ja}->{81774} = "宇治";
$areanames{ja}->{81775} = "大津";
$areanames{ja}->{81776} = "福井";
$areanames{ja}->{81778} = "武生";
$areanames{ja}->{81779} = "大野";
$areanames{ja}->{8178} = "神戸";
$areanames{ja}->{817902} = "福崎";
$areanames{ja}->{817903} = "福崎";
$areanames{ja}->{817904} = "福崎";
$areanames{ja}->{817905} = "福崎";
$areanames{ja}->{817906} = "播磨山崎";
$areanames{ja}->{817907} = "播磨山崎";
$areanames{ja}->{817908} = "播磨山崎";
$areanames{ja}->{817912} = "相生";
$areanames{ja}->{817914} = "相生";
$areanames{ja}->{817915} = "相生";
$areanames{ja}->{817916} = "竜野";
$areanames{ja}->{817917} = "竜野";
$areanames{ja}->{81792} = "姫路";
$areanames{ja}->{81793} = "姫路";
$areanames{ja}->{817940} = "加古川";
$areanames{ja}->{817942} = "加古川";
$areanames{ja}->{817943} = "加古川";
$areanames{ja}->{817944} = "加古川";
$areanames{ja}->{817945} = "加古川";
$areanames{ja}->{817946} = "三木";
$areanames{ja}->{817947} = "三木";
$areanames{ja}->{817948} = "三木";
$areanames{ja}->{817949} = "加古川";
$areanames{ja}->{817950} = "三田";
$areanames{ja}->{817952} = "西脇";
$areanames{ja}->{817953} = "西脇";
$areanames{ja}->{817954} = "西脇";
$areanames{ja}->{817955} = "三田";
$areanames{ja}->{817956} = "三田";
$areanames{ja}->{817957} = "丹波柏原";
$areanames{ja}->{817958} = "丹波柏原";
$areanames{ja}->{817959} = "三田";
$areanames{ja}->{817960} = "八鹿";
$areanames{ja}->{817962} = "豊岡";
$areanames{ja}->{817963} = "豊岡";
$areanames{ja}->{817964} = "豊岡";
$areanames{ja}->{817965} = "豊岡";
$areanames{ja}->{817966} = "八鹿";
$areanames{ja}->{817967} = "八鹿";
$areanames{ja}->{817968} = "浜坂";
$areanames{ja}->{817969} = "浜坂";
$areanames{ja}->{81797} = "西宮";
$areanames{ja}->{81798} = "西宮";
$areanames{ja}->{817992} = "洲本";
$areanames{ja}->{817993} = "洲本";
$areanames{ja}->{817994} = "洲本";
$areanames{ja}->{817995} = "洲本";
$areanames{ja}->{817996} = "津名";
$areanames{ja}->{817997} = "津名";
$areanames{ja}->{817998} = "津名";
$areanames{ja}->{818202} = "柳井";
$areanames{ja}->{818203} = "柳井";
$areanames{ja}->{818204} = "柳井";
$areanames{ja}->{818205} = "柳井";
$areanames{ja}->{818206} = "柳井";
$areanames{ja}->{818207} = "久賀";
$areanames{ja}->{818208} = "久賀";
$areanames{ja}->{81822} = "広島";
$areanames{ja}->{81823} = "呉";
$areanames{ja}->{818240} = "東広島";
$areanames{ja}->{818242} = "東広島";
$areanames{ja}->{818243} = "東広島";
$areanames{ja}->{818244} = "三次";
$areanames{ja}->{818245} = "三次";
$areanames{ja}->{818246} = "三次";
$areanames{ja}->{818247} = "庄原";
$areanames{ja}->{818248} = "庄原";
$areanames{ja}->{818249} = "東広島";
$areanames{ja}->{81825} = "広島";
$areanames{ja}->{818262} = "加計";
$areanames{ja}->{818263} = "加計";
$areanames{ja}->{818264} = "安芸吉田";
$areanames{ja}->{818265} = "安芸吉田";
$areanames{ja}->{818266} = "千代田";
$areanames{ja}->{818267} = "千代田";
$areanames{ja}->{818268} = "千代田";
$areanames{ja}->{81827} = "岩国";
$areanames{ja}->{81828} = "広島";
$areanames{ja}->{818290} = "広島";
$areanames{ja}->{818292} = "広島";
$areanames{ja}->{8182920} = "廿日市";
$areanames{ja}->{818293} = "廿日市";
$areanames{ja}->{818294} = "廿日市";
$areanames{ja}->{8182941} = "広島";
$areanames{ja}->{8182942} = "広島";
$areanames{ja}->{8182943} = "広島";
$areanames{ja}->{818295} = "廿日市";
$areanames{ja}->{818296} = "広島";
$areanames{ja}->{818297} = "廿日市";
$areanames{ja}->{818298} = "廿日市";
$areanames{ja}->{818299} = "広島";
$areanames{ja}->{81832} = "下関";
$areanames{ja}->{81833} = "下松";
$areanames{ja}->{81834} = "徳山";
$areanames{ja}->{81835} = "防府";
$areanames{ja}->{818360} = "小郡";
$areanames{ja}->{818362} = "宇部";
$areanames{ja}->{818363} = "宇部";
$areanames{ja}->{818364} = "宇部";
$areanames{ja}->{818365} = "宇部";
$areanames{ja}->{818366} = "宇部";
$areanames{ja}->{818367} = "宇部";
$areanames{ja}->{818368} = "宇部";
$areanames{ja}->{818369} = "宇部";
$areanames{ja}->{818372} = "長門";
$areanames{ja}->{818373} = "長門";
$areanames{ja}->{818374} = "長門";
$areanames{ja}->{818375} = "美祢";
$areanames{ja}->{818376} = "美祢";
$areanames{ja}->{8183766} = "下関";
$areanames{ja}->{8183767} = "下関";
$areanames{ja}->{8183768} = "下関";
$areanames{ja}->{818377} = "下関";
$areanames{ja}->{818378} = "下関";
$areanames{ja}->{818382} = "萩";
$areanames{ja}->{818383} = "萩";
$areanames{ja}->{818384} = "萩";
$areanames{ja}->{818385} = "萩";
$areanames{ja}->{818387} = "田万川";
$areanames{ja}->{818388} = "田万川";
$areanames{ja}->{81839} = "山口";
$areanames{ja}->{818391} = "小郡";
$areanames{ja}->{818397} = "小郡";
$areanames{ja}->{818398} = "小郡";
$areanames{ja}->{81845} = "因島";
$areanames{ja}->{818462} = "竹原";
$areanames{ja}->{818463} = "竹原";
$areanames{ja}->{818464} = "竹原";
$areanames{ja}->{818466} = "木江";
$areanames{ja}->{818467} = "木江";
$areanames{ja}->{818472} = "甲山";
$areanames{ja}->{818473} = "甲山";
$areanames{ja}->{818474} = "府中";
$areanames{ja}->{818475} = "府中";
$areanames{ja}->{818476} = "府中";
$areanames{ja}->{818477} = "東城";
$areanames{ja}->{818478} = "東城";
$areanames{ja}->{818479} = "東城";
$areanames{ja}->{81848} = "尾道";
$areanames{ja}->{81849} = "福山";
$areanames{ja}->{818490} = "尾道";
$areanames{ja}->{818493} = "尾道";
$areanames{ja}->{818512} = "西郷";
$areanames{ja}->{818514} = "海士";
$areanames{ja}->{81852} = "松江";
$areanames{ja}->{81853} = "出雲";
$areanames{ja}->{818542} = "安来";
$areanames{ja}->{818543} = "安来";
$areanames{ja}->{818544} = "木次";
$areanames{ja}->{818545} = "木次";
$areanames{ja}->{818546} = "掛合";
$areanames{ja}->{818547} = "掛合";
$areanames{ja}->{818548} = "石見大田";
$areanames{ja}->{818549} = "石見大田";
$areanames{ja}->{818552} = "浜田";
$areanames{ja}->{818553} = "浜田";
$areanames{ja}->{818554} = "浜田";
$areanames{ja}->{818555} = "江津";
$areanames{ja}->{818556} = "江津";
$areanames{ja}->{818557} = "川本";
$areanames{ja}->{818558} = "川本";
$areanames{ja}->{818559} = "川本";
$areanames{ja}->{818562} = "益田";
$areanames{ja}->{818563} = "益田";
$areanames{ja}->{818564} = "益田";
$areanames{ja}->{818565} = "益田";
$areanames{ja}->{818567} = "津和野";
$areanames{ja}->{818568} = "津和野";
$areanames{ja}->{81857} = "鳥取";
$areanames{ja}->{818582} = "倉吉";
$areanames{ja}->{818583} = "倉吉";
$areanames{ja}->{818584} = "倉吉";
$areanames{ja}->{818585} = "倉吉";
$areanames{ja}->{818586} = "倉吉";
$areanames{ja}->{818587} = "郡家";
$areanames{ja}->{818588} = "郡家";
$areanames{ja}->{818592} = "米子";
$areanames{ja}->{818593} = "米子";
$areanames{ja}->{818594} = "米子";
$areanames{ja}->{818595} = "米子";
$areanames{ja}->{818596} = "米子";
$areanames{ja}->{818597} = "根雨";
$areanames{ja}->{818598} = "根雨";
$areanames{ja}->{81862} = "岡山";
$areanames{ja}->{81863} = "玉野";
$areanames{ja}->{81864} = "倉敷";
$areanames{ja}->{818652} = "倉敷";
$areanames{ja}->{818654} = "鴨方";
$areanames{ja}->{818655} = "鴨方";
$areanames{ja}->{8186552} = "倉敷";
$areanames{ja}->{8186553} = "倉敷";
$areanames{ja}->{818656} = "笠岡";
$areanames{ja}->{818657} = "笠岡";
$areanames{ja}->{818660} = "岡山瀬戸";
$areanames{ja}->{818662} = "高梁";
$areanames{ja}->{818663} = "総社";
$areanames{ja}->{818664} = "高梁";
$areanames{ja}->{818665} = "高梁";
$areanames{ja}->{818666} = "井原";
$areanames{ja}->{818667} = "井原";
$areanames{ja}->{818668} = "井原";
$areanames{ja}->{818669} = "総社";
$areanames{ja}->{8186691} = "倉敷";
$areanames{ja}->{8186697} = "倉敷";
$areanames{ja}->{8186698} = "倉敷";
$areanames{ja}->{818672} = "福渡";
$areanames{ja}->{818673} = "福渡";
$areanames{ja}->{818674} = "久世";
$areanames{ja}->{818675} = "久世";
$areanames{ja}->{818676} = "久世";
$areanames{ja}->{818677} = "新見";
$areanames{ja}->{818678} = "新見";
$areanames{ja}->{818679} = "新見";
$areanames{ja}->{818680} = "岡山";
$areanames{ja}->{818682} = "津山";
$areanames{ja}->{818683} = "津山";
$areanames{ja}->{818684} = "津山";
$areanames{ja}->{818685} = "津山";
$areanames{ja}->{818686} = "津山";
$areanames{ja}->{818687} = "美作";
$areanames{ja}->{818688} = "美作";
$areanames{ja}->{818689} = "岡山";
$areanames{ja}->{818690} = "岡山";
$areanames{ja}->{818692} = "邑久";
$areanames{ja}->{818693} = "邑久";
$areanames{ja}->{818694} = "岡山";
$areanames{ja}->{818695} = "岡山瀬戸";
$areanames{ja}->{818696} = "備前";
$areanames{ja}->{818697} = "備前";
$areanames{ja}->{818698} = "備前";
$areanames{ja}->{8186992} = "備前";
$areanames{ja}->{8186993} = "備前";
$areanames{ja}->{8186994} = "岡山瀬戸";
$areanames{ja}->{8186995} = "岡山瀬戸";
$areanames{ja}->{8186996} = "岡山瀬戸";
$areanames{ja}->{8186997} = "岡山瀬戸";
$areanames{ja}->{8186998} = "岡山瀬戸";
$areanames{ja}->{8186999} = "岡山瀬戸";
$areanames{ja}->{81875} = "観音寺";
$areanames{ja}->{81877} = "丸亀";
$areanames{ja}->{81878} = "高松";
$areanames{ja}->{818792} = "三本松";
$areanames{ja}->{818793} = "三本松";
$areanames{ja}->{818794} = "三本松";
$areanames{ja}->{818795} = "三本松";
$areanames{ja}->{818796} = "土庄";
$areanames{ja}->{818797} = "土庄";
$areanames{ja}->{818798} = "土庄";
$areanames{ja}->{818802} = "窪川";
$areanames{ja}->{818803} = "土佐中村";
$areanames{ja}->{818804} = "土佐中村";
$areanames{ja}->{818805} = "土佐中村";
$areanames{ja}->{818806} = "宿毛";
$areanames{ja}->{818807} = "宿毛";
$areanames{ja}->{818808} = "土佐清水";
$areanames{ja}->{8188090} = "窪川";
$areanames{ja}->{8188091} = "窪川";
$areanames{ja}->{8188092} = "窪川";
$areanames{ja}->{8188093} = "窪川";
$areanames{ja}->{8188094} = "窪川";
$areanames{ja}->{8188095} = "土佐清水";
$areanames{ja}->{8188096} = "土佐清水";
$areanames{ja}->{8188097} = "土佐清水";
$areanames{ja}->{8188098} = "土佐清水";
$areanames{ja}->{8188099} = "土佐清水";
$areanames{ja}->{818832} = "鴨島";
$areanames{ja}->{818833} = "鴨島";
$areanames{ja}->{818834} = "鴨島";
$areanames{ja}->{818835} = "脇町";
$areanames{ja}->{818836} = "脇町";
$areanames{ja}->{818837} = "阿波池田";
$areanames{ja}->{818838} = "阿波池田";
$areanames{ja}->{818842} = "阿南";
$areanames{ja}->{818843} = "阿南";
$areanames{ja}->{818844} = "阿南";
$areanames{ja}->{818845} = "丹生谷";
$areanames{ja}->{818846} = "丹生谷";
$areanames{ja}->{818847} = "牟岐";
$areanames{ja}->{818848} = "牟岐";
$areanames{ja}->{81885} = "小松島";
$areanames{ja}->{81886} = "徳島";
$areanames{ja}->{818872} = "室戸";
$areanames{ja}->{818873} = "安芸";
$areanames{ja}->{818874} = "安芸";
$areanames{ja}->{818875} = "土佐山田";
$areanames{ja}->{818876} = "土佐山田";
$areanames{ja}->{818877} = "嶺北";
$areanames{ja}->{818878} = "嶺北";
$areanames{ja}->{818879} = "室戸";
$areanames{ja}->{81888} = "高知";
$areanames{ja}->{818892} = "佐川";
$areanames{ja}->{818893} = "佐川";
$areanames{ja}->{818894} = "須崎";
$areanames{ja}->{818895} = "須崎";
$areanames{ja}->{818896} = "須崎";
$areanames{ja}->{81892} = "久万";
$areanames{ja}->{81893} = "大洲";
$areanames{ja}->{818942} = "八幡浜";
$areanames{ja}->{818943} = "八幡浜";
$areanames{ja}->{818944} = "八幡浜";
$areanames{ja}->{818945} = "八幡浜";
$areanames{ja}->{818946} = "宇和";
$areanames{ja}->{818947} = "宇和";
$areanames{ja}->{818948} = "宇和";
$areanames{ja}->{818949} = "宇和";
$areanames{ja}->{818952} = "宇和島";
$areanames{ja}->{818953} = "宇和島";
$areanames{ja}->{818954} = "宇和島";
$areanames{ja}->{818955} = "宇和島";
$areanames{ja}->{818956} = "宇和島";
$areanames{ja}->{818957} = "御荘";
$areanames{ja}->{818958} = "御荘";
$areanames{ja}->{81896} = "伊予三島";
$areanames{ja}->{818972} = "新居浜";
$areanames{ja}->{818973} = "新居浜";
$areanames{ja}->{818974} = "新居浜";
$areanames{ja}->{818975} = "新居浜";
$areanames{ja}->{818976} = "新居浜";
$areanames{ja}->{818977} = "伯方";
$areanames{ja}->{818978} = "伯方";
$areanames{ja}->{81898} = "今治";
$areanames{ja}->{81899} = "松山";
$areanames{ja}->{819204} = "郷ノ浦";
$areanames{ja}->{819205} = "厳原";
$areanames{ja}->{819208} = "対馬佐賀";
$areanames{ja}->{81922} = "福岡";
$areanames{ja}->{81923} = "福岡";
$areanames{ja}->{819232} = "前原";
$areanames{ja}->{819233} = "前原";
$areanames{ja}->{81924} = "福岡";
$areanames{ja}->{81925} = "福岡";
$areanames{ja}->{81926} = "福岡";
$areanames{ja}->{81927} = "福岡";
$areanames{ja}->{81928} = "福岡";
$areanames{ja}->{81929} = "福岡";
$areanames{ja}->{81930} = "行橋";
$areanames{ja}->{81932} = "北九州";
$areanames{ja}->{81933} = "北九州";
$areanames{ja}->{81934} = "北九州";
$areanames{ja}->{81935} = "北九州";
$areanames{ja}->{81936} = "北九州";
$areanames{ja}->{81937} = "北九州";
$areanames{ja}->{81938} = "北九州";
$areanames{ja}->{81939} = "北九州";
$areanames{ja}->{81940} = "宗像";
$areanames{ja}->{81942} = "久留米";
$areanames{ja}->{819432} = "八女";
$areanames{ja}->{819433} = "八女";
$areanames{ja}->{819434} = "八女";
$areanames{ja}->{819435} = "八女";
$areanames{ja}->{819437} = "田主丸";
$areanames{ja}->{819438} = "田主丸";
$areanames{ja}->{81944} = "瀬高";
$areanames{ja}->{81946} = "甘木";
$areanames{ja}->{81947} = "田川";
$areanames{ja}->{81948} = "飯塚";
$areanames{ja}->{81949} = "直方";
$areanames{ja}->{81950} = "平戸";
$areanames{ja}->{81952} = "佐賀";
$areanames{ja}->{819542} = "武雄";
$areanames{ja}->{819543} = "武雄";
$areanames{ja}->{819544} = "武雄";
$areanames{ja}->{819546} = "鹿島";
$areanames{ja}->{819547} = "鹿島";
$areanames{ja}->{819552} = "伊万里";
$areanames{ja}->{819553} = "伊万里";
$areanames{ja}->{819554} = "伊万里";
$areanames{ja}->{819555} = "唐津";
$areanames{ja}->{819556} = "唐津";
$areanames{ja}->{819557} = "唐津";
$areanames{ja}->{819558} = "唐津";
$areanames{ja}->{81956} = "佐世保";
$areanames{ja}->{819572} = "諫早";
$areanames{ja}->{819573} = "諫早";
$areanames{ja}->{819574} = "諫早";
$areanames{ja}->{819575} = "諫早";
$areanames{ja}->{819576} = "島原";
$areanames{ja}->{819577} = "島原";
$areanames{ja}->{819578} = "島原";
$areanames{ja}->{81958} = "長崎";
$areanames{ja}->{819592} = "大瀬戸";
$areanames{ja}->{819593} = "大瀬戸";
$areanames{ja}->{819594} = "有川";
$areanames{ja}->{819595} = "有川";
$areanames{ja}->{819596} = "福江";
$areanames{ja}->{819597} = "福江";
$areanames{ja}->{819598} = "福江";
$areanames{ja}->{819599} = "大瀬戸";
$areanames{ja}->{81962} = "熊本";
$areanames{ja}->{81963} = "熊本";
$areanames{ja}->{81964} = "松橋";
$areanames{ja}->{81965} = "八代";
$areanames{ja}->{819662} = "人吉";
$areanames{ja}->{819663} = "人吉";
$areanames{ja}->{819664} = "人吉";
$areanames{ja}->{819665} = "人吉";
$areanames{ja}->{819666} = "水俣";
$areanames{ja}->{819667} = "水俣";
$areanames{ja}->{819668} = "水俣";
$areanames{ja}->{819672} = "熊本一の宮";
$areanames{ja}->{819673} = "熊本一の宮";
$areanames{ja}->{819674} = "熊本一の宮";
$areanames{ja}->{819675} = "熊本一の宮";
$areanames{ja}->{819676} = "高森";
$areanames{ja}->{819677} = "矢部";
$areanames{ja}->{819678} = "矢部";
$areanames{ja}->{819679} = "高森";
$areanames{ja}->{819682} = "山鹿";
$areanames{ja}->{819683} = "山鹿";
$areanames{ja}->{819684} = "山鹿";
$areanames{ja}->{819685} = "玉名";
$areanames{ja}->{819686} = "玉名";
$areanames{ja}->{819687} = "玉名";
$areanames{ja}->{819688} = "玉名";
$areanames{ja}->{81969} = "天草";
$areanames{ja}->{819722} = "佐伯";
$areanames{ja}->{819723} = "佐伯";
$areanames{ja}->{819724} = "佐伯";
$areanames{ja}->{819725} = "佐伯";
$areanames{ja}->{819726} = "臼杵";
$areanames{ja}->{819727} = "臼杵";
$areanames{ja}->{819728} = "臼杵";
$areanames{ja}->{819732} = "日田";
$areanames{ja}->{819733} = "日田";
$areanames{ja}->{819734} = "日田";
$areanames{ja}->{819735} = "日田";
$areanames{ja}->{819737} = "玖珠";
$areanames{ja}->{819738} = "玖珠";
$areanames{ja}->{819742} = "三重";
$areanames{ja}->{819743} = "三重";
$areanames{ja}->{819744} = "三重";
$areanames{ja}->{819746} = "竹田";
$areanames{ja}->{819747} = "竹田";
$areanames{ja}->{81975} = "大分";
$areanames{ja}->{81977} = "別府";
$areanames{ja}->{819782} = "豊後高田";
$areanames{ja}->{819783} = "豊後高田";
$areanames{ja}->{819784} = "豊後高田";
$areanames{ja}->{819785} = "豊後高田";
$areanames{ja}->{819786} = "杵築";
$areanames{ja}->{819787} = "国東";
$areanames{ja}->{819788} = "国東";
$areanames{ja}->{819789} = "杵築";
$areanames{ja}->{81979} = "中津";
$areanames{ja}->{819802} = "南大東";
$areanames{ja}->{819803} = "名護";
$areanames{ja}->{819804} = "名護";
$areanames{ja}->{819805} = "名護";
$areanames{ja}->{819806} = "沖縄宮古";
$areanames{ja}->{819807} = "沖縄宮古";
$areanames{ja}->{819808} = "八重山";
$areanames{ja}->{819809} = "八重山";
$areanames{ja}->{819822} = "延岡";
$areanames{ja}->{819823} = "延岡";
$areanames{ja}->{819824} = "延岡";
$areanames{ja}->{819825} = "日向";
$areanames{ja}->{819826} = "日向";
$areanames{ja}->{819827} = "高千穂";
$areanames{ja}->{819828} = "高千穂";
$areanames{ja}->{8198290} = "延岡";
$areanames{ja}->{8198291} = "延岡";
$areanames{ja}->{8198292} = "延岡";
$areanames{ja}->{8198293} = "延岡";
$areanames{ja}->{8198294} = "延岡";
$areanames{ja}->{8198295} = "日向";
$areanames{ja}->{8198296} = "日向";
$areanames{ja}->{8198297} = "日向";
$areanames{ja}->{8198298} = "日向";
$areanames{ja}->{8198299} = "日向";
$areanames{ja}->{81983} = "高鍋";
$areanames{ja}->{81984} = "小林";
$areanames{ja}->{81985} = "宮崎";
$areanames{ja}->{81986} = "都城";
$areanames{ja}->{81987} = "日南";
$areanames{ja}->{81988} = "那覇";
$areanames{ja}->{81989} = "那覇";
$areanames{ja}->{819912} = "中之島";
$areanames{ja}->{819913} = "硫黄島";
$areanames{ja}->{81992} = "鹿児島";
$areanames{ja}->{819932} = "指宿";
$areanames{ja}->{819933} = "指宿";
$areanames{ja}->{8199331} = "鹿児島";
$areanames{ja}->{819934} = "指宿";
$areanames{ja}->{8199343} = "鹿児島";
$areanames{ja}->{8199345} = "鹿児島";
$areanames{ja}->{8199347} = "鹿児島";
$areanames{ja}->{819935} = "加世田";
$areanames{ja}->{819936} = "加世田";
$areanames{ja}->{819937} = "加世田";
$areanames{ja}->{819938} = "加世田";
$areanames{ja}->{819940} = "志布志";
$areanames{ja}->{819942} = "大根占";
$areanames{ja}->{819943} = "鹿屋";
$areanames{ja}->{819944} = "鹿屋";
$areanames{ja}->{819945} = "鹿屋";
$areanames{ja}->{819946} = "鹿屋";
$areanames{ja}->{819947} = "志布志";
$areanames{ja}->{819948} = "志布志";
$areanames{ja}->{819949} = "大根占";
$areanames{ja}->{819952} = "大口";
$areanames{ja}->{819953} = "大口";
$areanames{ja}->{819954} = "加治木";
$areanames{ja}->{819955} = "加治木";
$areanames{ja}->{819956} = "加治木";
$areanames{ja}->{819957} = "加治木";
$areanames{ja}->{819962} = "川内";
$areanames{ja}->{819963} = "川内";
$areanames{ja}->{819964} = "川内";
$areanames{ja}->{819965} = "川内";
$areanames{ja}->{819966} = "出水";
$areanames{ja}->{819967} = "出水";
$areanames{ja}->{819968} = "出水";
$areanames{ja}->{819969} = "中甑";
$areanames{ja}->{819972} = "種子島";
$areanames{ja}->{819973} = "種子島";
$areanames{ja}->{819974} = "屋久島";
$areanames{ja}->{819975} = "名瀬";
$areanames{ja}->{819976} = "名瀬";
$areanames{ja}->{819977} = "瀬戸内";
$areanames{ja}->{819978} = "徳之島";
$areanames{ja}->{819979} = "徳之島";
$areanames{ja}->{81998} = "鹿児島";
$areanames{en}->{8111} = "Sapporo\,\ Hokkaido";
$areanames{en}->{811232} = "Chitose\,\ Hokkaido";
$areanames{en}->{811233} = "Chitose\,\ Hokkaido";
$areanames{en}->{811234} = "Chitose\,\ Hokkaido";
$areanames{en}->{811235} = "Yubari\,\ Hokkaido";
$areanames{en}->{811236} = "Chitose\,\ Hokkaido";
$areanames{en}->{811237} = "Kuriyama\,\ Hokkaido";
$areanames{en}->{811238} = "Kuriyama\,\ Hokkaido";
$areanames{en}->{8112390} = "Yubari\,\ Hokkaido";
$areanames{en}->{8112391} = "Yubari\,\ Hokkaido";
$areanames{en}->{8112392} = "Yubari\,\ Hokkaido";
$areanames{en}->{8112393} = "Yubari\,\ Hokkaido";
$areanames{en}->{8112394} = "Yubari\,\ Hokkaido";
$areanames{en}->{8112395} = "Kuriyama\,\ Hokkaido";
$areanames{en}->{8112396} = "Kuriyama\,\ Hokkaido";
$areanames{en}->{8112397} = "Kuriyama\,\ Hokkaido";
$areanames{en}->{8112398} = "Kuriyama\,\ Hokkaido";
$areanames{en}->{8112399} = "Kuriyama\,\ Hokkaido";
$areanames{en}->{81124} = "Ashibetsu\,\ Hokkaido";
$areanames{en}->{81125} = "Takikawa\,\ Hokkaido";
$areanames{en}->{81126} = "Iwamizawa\,\ Hokkaido";
$areanames{en}->{811332} = "Tobetsu\,\ Hokkaido";
$areanames{en}->{811333} = "Tobetsu\,\ Hokkaido";
$areanames{en}->{811336} = "Ishikari\,\ Hokkaido";
$areanames{en}->{811337} = "Ishikari\,\ Hokkaido";
$areanames{en}->{81134} = "Otaru\,\ Hokkaido";
$areanames{en}->{811352} = "Yoichi\,\ Hokkaido";
$areanames{en}->{811353} = "Yoichi\,\ Hokkaido";
$areanames{en}->{811354} = "Yoichi\,\ Hokkaido";
$areanames{en}->{811356} = "Iwanai\,\ Hokkaido";
$areanames{en}->{811357} = "Iwanai\,\ Hokkaido";
$areanames{en}->{811362} = "Kutchan\,\ Hokkaido";
$areanames{en}->{811363} = "Kutchan\,\ Hokkaido";
$areanames{en}->{811364} = "Kutchan\,\ Hokkaido";
$areanames{en}->{811365} = "Kutchan\,\ Hokkaido";
$areanames{en}->{811366} = "Suttsu\,\ Hokkaido";
$areanames{en}->{811367} = "Suttsu\,\ Hokkaido";
$areanames{en}->{811372} = "Shikabe\,\ Hokkaido";
$areanames{en}->{811374} = "Mori\,\ Hokkaido";
$areanames{en}->{811375} = "Yakumo\,\ Hokkaido";
$areanames{en}->{811376} = "Yakumo\,\ Hokkaido";
$areanames{en}->{811377} = "Yakumo\,\ Hokkaido";
$areanames{en}->{811378} = "Imakane\,\ Hokkaido";
$areanames{en}->{81138} = "Hakodate\,\ Hokkaido";
$areanames{en}->{811392} = "Kikonai\,\ Hokkaido";
$areanames{en}->{811393} = "Matsumae\,\ Hokkaido";
$areanames{en}->{811394} = "Matsumae\,\ Hokkaido";
$areanames{en}->{811395} = "Esashi\,\ Hokkaido";
$areanames{en}->{811396} = "Esashi\,\ Hokkaido";
$areanames{en}->{811397} = "Okushiri\,\ Hokkaido";
$areanames{en}->{811398} = "Kumaishi\,\ Hokkaido";
$areanames{en}->{81142} = "Date\,\ Hokkaido";
$areanames{en}->{81143} = "Muroran\,\ Hokkaido";
$areanames{en}->{81144} = "Tomakomai\,\ Hokkaido";
$areanames{en}->{811452} = "Hayakita\,\ Hokkaido";
$areanames{en}->{811453} = "Hayakita\,\ Hokkaido";
$areanames{en}->{811454} = "Mukawa\,\ Hokkaido";
$areanames{en}->{811455} = "Mukawa\,\ Hokkaido";
$areanames{en}->{811462} = "Urakawa\,\ Hokkaido";
$areanames{en}->{811463} = "Urakawa\,\ Hokkaido";
$areanames{en}->{811464} = "Shizunai\,\ Hokkaido";
$areanames{en}->{811465} = "Shizunai\,\ Hokkaido";
$areanames{en}->{811466} = "Erimo\,\ Hokkaido";
$areanames{en}->{811522} = "Shari\,\ Hokkaido";
$areanames{en}->{811523} = "Shari\,\ Hokkaido";
$areanames{en}->{811524} = "Abashiri\,\ Hokkaido";
$areanames{en}->{811525} = "Abashiri\,\ Hokkaido";
$areanames{en}->{811526} = "Abashiri\,\ Hokkaido";
$areanames{en}->{811527} = "Bihoro\,\ Hokkaido";
$areanames{en}->{811528} = "Bihoro\,\ Hokkaido";
$areanames{en}->{811532} = "Nemuro\,\ Hokkaido";
$areanames{en}->{811533} = "Nemuro\,\ Hokkaido";
$areanames{en}->{811534} = "Nakashibetsu\,\ Hokkaido";
$areanames{en}->{811535} = "Akkeshi\,\ Hokkaido";
$areanames{en}->{811536} = "Akkeshi\,\ Hokkaido";
$areanames{en}->{811537} = "Nakashibetsu\,\ Hokkaido";
$areanames{en}->{811541} = "Teshikaga\,\ Hokkaido";
$areanames{en}->{811542} = "Kushiro\,\ Hokkaido";
$areanames{en}->{811543} = "Kushiro\,\ Hokkaido";
$areanames{en}->{811544} = "Kushiro\,\ Hokkaido";
$areanames{en}->{811545} = "Kushiro\,\ Hokkaido";
$areanames{en}->{811546} = "Kushiro\,\ Hokkaido";
$areanames{en}->{811547} = "Shiranuka\,\ Hokkaido";
$areanames{en}->{811548} = "Teshikaga\,\ Hokkaido";
$areanames{en}->{811549} = "Kushiro\,\ Hokkaido";
$areanames{en}->{811552} = "Obihiro\,\ Hokkaido";
$areanames{en}->{811553} = "Obihiro\,\ Hokkaido";
$areanames{en}->{811554} = "Obihiro\,\ Hokkaido";
$areanames{en}->{811555} = "Obihiro\,\ Hokkaido";
$areanames{en}->{811556} = "Obihiro\,\ Hokkaido";
$areanames{en}->{811558} = "Hiroo\,\ Hokkaido";
$areanames{en}->{811559} = "Obihiro\,\ Hokkaido";
$areanames{en}->{811562} = "Honbetsu\,\ Hokkaido";
$areanames{en}->{811563} = "Honbetsu\,\ Hokkaido";
$areanames{en}->{811564} = "Kamishihoro\,\ Hokkaido";
$areanames{en}->{81157} = "Kitami\,\ Hokkaido";
$areanames{en}->{811582} = "Monbetsu\,\ Hokkaido";
$areanames{en}->{811583} = "Monbetsu\,\ Hokkaido";
$areanames{en}->{811584} = "Engaru\,\ Hokkaido";
$areanames{en}->{811585} = "Engaru\,\ Hokkaido";
$areanames{en}->{811586} = "Nakayubetsu\,\ Hokkaido";
$areanames{en}->{811587} = "Nakayubetsu\,\ Hokkaido";
$areanames{en}->{811588} = "Okoppe\,\ Hokkaido";
$areanames{en}->{811589} = "Okoppe\,\ Hokkaido";
$areanames{en}->{81162} = "Wakkanai\,\ Hokkaido";
$areanames{en}->{811632} = "Teshio\,\ Hokkaido";
$areanames{en}->{811634} = "Hamatonbetsu\,\ Hokkaido";
$areanames{en}->{811635} = "Hamatonbetsu\,\ Hokkaido";
$areanames{en}->{811644} = "Rumoi\,\ Hokkaido";
$areanames{en}->{811645} = "Rumoi\,\ Hokkaido";
$areanames{en}->{811646} = "Haboro\,\ Hokkaido";
$areanames{en}->{811647} = "Haboro\,\ Hokkaido";
$areanames{en}->{811652} = "Shibetsu\,\ Hokkaido";
$areanames{en}->{811653} = "Shibetsu\,\ Hokkaido";
$areanames{en}->{811654} = "Nayoro\,\ Hokkaido";
$areanames{en}->{811655} = "Nayoro\,\ Hokkaido";
$areanames{en}->{811656} = "Bifuka\,\ Hokkaido";
$areanames{en}->{811658} = "Kamikawa\,\ Hokkaido";
$areanames{en}->{81166} = "Asahikawa\,\ Hokkaido";
$areanames{en}->{81167} = "Furano\,\ Hokkaido";
$areanames{en}->{81172} = "Hirosaki\,\ Aomori";
$areanames{en}->{811732} = "Goshogawara\,\ Aomori";
$areanames{en}->{811733} = "Goshogawara\,\ Aomori";
$areanames{en}->{811734} = "Goshogawara\,\ Aomori";
$areanames{en}->{811735} = "Goshogawara\,\ Aomori";
$areanames{en}->{811736} = "Goshogawara\,\ Aomori";
$areanames{en}->{81174} = "Kanita\,\ Aomori";
$areanames{en}->{811752} = "Mutsu\,\ Aomori";
$areanames{en}->{811753} = "Mutsu\,\ Aomori";
$areanames{en}->{811754} = "Mutsu\,\ Aomori";
$areanames{en}->{811756} = "Noheji\,\ Aomori";
$areanames{en}->{811757} = "Noheji\,\ Aomori";
$areanames{en}->{81176} = "Towada\,\ Aomori";
$areanames{en}->{81177} = "Aomori\,\ Aomori";
$areanames{en}->{81178} = "Hachinohe\,\ Aomori";
$areanames{en}->{81179} = "Sannohe\,\ Aomori";
$areanames{en}->{81182} = "Yokote\,\ Akita";
$areanames{en}->{81183} = "Yuzawa\,\ Akita";
$areanames{en}->{81184} = "Yurihonjo\,\ Akita";
$areanames{en}->{811852} = "Oga\,\ Akita";
$areanames{en}->{811853} = "Oga\,\ Akita";
$areanames{en}->{811854} = "Oga\,\ Akita";
$areanames{en}->{811855} = "Noshiro\,\ Akita";
$areanames{en}->{811856} = "Noshiro\,\ Akita";
$areanames{en}->{811857} = "Noshiro\,\ Akita";
$areanames{en}->{811858} = "Noshiro\,\ Akita";
$areanames{en}->{811862} = "Kazuno\,\ Akita";
$areanames{en}->{811863} = "Kazuno\,\ Akita";
$areanames{en}->{811864} = "Odate\,\ Akita";
$areanames{en}->{811865} = "Odate\,\ Akita";
$areanames{en}->{811866} = "Takanosu\,\ Akita";
$areanames{en}->{811867} = "Takanosu\,\ Akita";
$areanames{en}->{811868} = "Takanosu\,\ Akita";
$areanames{en}->{811869} = "Odate\,\ Akita";
$areanames{en}->{811873} = "Kakunodate\,\ Akita";
$areanames{en}->{811874} = "Kakunodate\,\ Akita";
$areanames{en}->{811875} = "Kakunodate\,\ Akita";
$areanames{en}->{811876} = "Omagari\,\ Akita";
$areanames{en}->{811877} = "Omagari\,\ Akita";
$areanames{en}->{811878} = "Omagari\,\ Akita";
$areanames{en}->{81188} = "Akita\,\ Akita";
$areanames{en}->{81191} = "Ichinoseki\,\ Iwate";
$areanames{en}->{81192} = "Ofunato\,\ Iwate";
$areanames{en}->{811932} = "Kamaishi\,\ Iwate";
$areanames{en}->{811933} = "Kamaishi\,\ Iwate";
$areanames{en}->{811934} = "Kamaishi\,\ Iwate";
$areanames{en}->{811935} = "Kamaishi\,\ Iwate";
$areanames{en}->{811936} = "Miyako\,\ Iwate";
$areanames{en}->{811937} = "Miyako\,\ Iwate";
$areanames{en}->{811938} = "Miyako\,\ Iwate";
$areanames{en}->{811939} = "Miyako\,\ Iwate";
$areanames{en}->{811942} = "Iwaizumi\,\ Iwate";
$areanames{en}->{811943} = "Iwaizumi\,\ Iwate";
$areanames{en}->{811944} = "Iwaizumi\,\ Iwate";
$areanames{en}->{811945} = "Kuji\,\ Iwate";
$areanames{en}->{811946} = "Kuji\,\ Iwate";
$areanames{en}->{811947} = "Kuji\,\ Iwate";
$areanames{en}->{811952} = "Ninohe\,\ Iwate";
$areanames{en}->{811953} = "Ninohe\,\ Iwate";
$areanames{en}->{811954} = "Ninohe\,\ Iwate";
$areanames{en}->{811955} = "Ninohe\,\ Iwate";
$areanames{en}->{811956} = "Iwate\,\ Iwate";
$areanames{en}->{811957} = "Iwate\,\ Iwate";
$areanames{en}->{811958} = "Iwate\,\ Iwate";
$areanames{en}->{81196} = "Morioka\,\ Iwate";
$areanames{en}->{811972} = "Mizusawa\,\ Iwate";
$areanames{en}->{811973} = "Mizusawa\,\ Iwate";
$areanames{en}->{811974} = "Mizusawa\,\ Iwate";
$areanames{en}->{811975} = "Mizusawa\,\ Iwate";
$areanames{en}->{811976} = "Kitakami\,\ Iwate";
$areanames{en}->{811977} = "Kitakami\,\ Iwate";
$areanames{en}->{811978} = "Kitakami\,\ Iwate";
$areanames{en}->{811982} = "Hanamaki\,\ Iwate";
$areanames{en}->{811983} = "Hanamaki\,\ Iwate";
$areanames{en}->{811984} = "Hanamaki\,\ Iwate";
$areanames{en}->{811986} = "Tono\,\ Iwate";
$areanames{en}->{811987} = "Tono\,\ Iwate";
$areanames{en}->{81199} = "Morioka\,\ Iwate";
$areanames{en}->{81222} = "Sendai\,\ Miyagi";
$areanames{en}->{812230} = "Sendai\,\ Miyagi";
$areanames{en}->{812232} = "Iwanuma\,\ Miyagi";
$areanames{en}->{812233} = "Iwanuma\,\ Miyagi";
$areanames{en}->{812234} = "Sendai\,\ Miyagi";
$areanames{en}->{812235} = "Sendai\,\ Miyagi";
$areanames{en}->{812236} = "Sendai\,\ Miyagi";
$areanames{en}->{812237} = "Sendai\,\ Miyagi";
$areanames{en}->{812238} = "Sendai\,\ Miyagi";
$areanames{en}->{812239} = "Sendai\,\ Miyagi";
$areanames{en}->{812242} = "Shiroishi\,\ Miyagi";
$areanames{en}->{812243} = "Shiroishi\,\ Miyagi";
$areanames{en}->{812244} = "Shiroishi\,\ Miyagi";
$areanames{en}->{812245} = "Ogawara\,\ Miyagi";
$areanames{en}->{812246} = "Ogawara\,\ Miyagi";
$areanames{en}->{812247} = "Ogawara\,\ Miyagi";
$areanames{en}->{812248} = "Ogawara\,\ Miyagi";
$areanames{en}->{81225} = "Ishinomaki\,\ Miyagi";
$areanames{en}->{81226} = "Kesennuma\,\ Miyagi";
$areanames{en}->{81227} = "Sendai\,\ Miyagi";
$areanames{en}->{81233} = "Shinjo\,\ Yamagata";
$areanames{en}->{81234} = "Sakata\,\ Yamagata";
$areanames{en}->{81235} = "Tsuruoka\,\ Yamagata";
$areanames{en}->{81236} = "Yamagata\,\ Yamagata";
$areanames{en}->{812372} = "Murayama\,\ Yamagata";
$areanames{en}->{812373} = "Murayama\,\ Yamagata";
$areanames{en}->{812374} = "Murayama\,\ Yamagata";
$areanames{en}->{812375} = "Murayama\,\ Yamagata";
$areanames{en}->{812376} = "Sagae\,\ Yamagata";
$areanames{en}->{812377} = "Sagae\,\ Yamagata";
$areanames{en}->{812378} = "Sagae\,\ Yamagata";
$areanames{en}->{812382} = "Yonezawa\,\ Yamagata";
$areanames{en}->{812383} = "Yonezawa\,\ Yamagata";
$areanames{en}->{812384} = "Yonezawa\,\ Yamagata";
$areanames{en}->{812385} = "Yonezawa\,\ Yamagata";
$areanames{en}->{812386} = "Nagai\,\ Yamagata";
$areanames{en}->{812387} = "Nagai\,\ Yamagata";
$areanames{en}->{812388} = "Nagai\,\ Yamagata";
$areanames{en}->{812389} = "Yonezawa\,\ Yamagata";
$areanames{en}->{812412} = "Kitakata\,\ Fukushima";
$areanames{en}->{812413} = "Kitakata\,\ Fukushima";
$areanames{en}->{812414} = "Yanaizu\,\ Fukushima";
$areanames{en}->{812415} = "Yanaizu\,\ Fukushima";
$areanames{en}->{812416} = "Tajima\,\ Fukushima";
$areanames{en}->{812419} = "Tajima\,\ Fukushima";
$areanames{en}->{8124196} = "Yanaizu\,\ Fukushima";
$areanames{en}->{8124197} = "Yanaizu\,\ Fukushima";
$areanames{en}->{81242} = "Aizuwakamatsu\,\ Fukushima";
$areanames{en}->{81243} = "Nihonmatsu\,\ Fukushima";
$areanames{en}->{81244} = "Hobara\,\ Fukushima";
$areanames{en}->{81245} = "Fukushima\,\ Fukushima";
$areanames{en}->{81246} = "Iwaki\,\ Fukushima";
$areanames{en}->{812472} = "Ishikawa\,\ Fukushima";
$areanames{en}->{812473} = "Ishikawa\,\ Fukushima";
$areanames{en}->{812474} = "Ishikawa\,\ Fukushima";
$areanames{en}->{812475} = "Ishikawa\,\ Fukushima";
$areanames{en}->{812476} = "Miharu\,\ Fukushima";
$areanames{en}->{812477} = "Miharu\,\ Fukushima";
$areanames{en}->{812478} = "Miharu\,\ Fukushima";
$areanames{en}->{812482} = "Shirakawa\,\ Fukushima";
$areanames{en}->{812483} = "Shirakawa\,\ Fukushima";
$areanames{en}->{812484} = "Shirakawa\,\ Fukushima";
$areanames{en}->{812485} = "Shirakawa\,\ Fukushima";
$areanames{en}->{812486} = "Sukagawa\,\ Fukushima";
$areanames{en}->{812487} = "Sukagawa\,\ Fukushima";
$areanames{en}->{812488} = "Sukagawa\,\ Fukushima";
$areanames{en}->{812489} = "Sukagawa\,\ Fukushima";
$areanames{en}->{81249} = "Koriyama\,\ Fukushima";
$areanames{en}->{81250} = "Niitsu\,\ Niigata";
$areanames{en}->{81252} = "Niigata\,\ Niigata";
$areanames{en}->{81253} = "Niigata\,\ Niigata";
$areanames{en}->{812542} = "Shibata\,\ Niigata";
$areanames{en}->{812543} = "Shibata\,\ Niigata";
$areanames{en}->{812544} = "Shibata\,\ Niigata";
$areanames{en}->{812545} = "Murakami\,\ Niigata";
$areanames{en}->{812546} = "Murakami\,\ Niigata";
$areanames{en}->{812547} = "Murakami\,\ Niigata";
$areanames{en}->{8125480} = "Murakami\,\ Niigata";
$areanames{en}->{8125481} = "Murakami\,\ Niigata";
$areanames{en}->{8125482} = "Murakami\,\ Niigata";
$areanames{en}->{8125483} = "Murakami\,\ Niigata";
$areanames{en}->{8125484} = "Murakami\,\ Niigata";
$areanames{en}->{8125485} = "Tsugawa\,\ Niigata";
$areanames{en}->{8125486} = "Tsugawa\,\ Niigata";
$areanames{en}->{8125487} = "Tsugawa\,\ Niigata";
$areanames{en}->{8125488} = "Tsugawa\,\ Niigata";
$areanames{en}->{8125489} = "Tsugawa\,\ Niigata";
$areanames{en}->{812549} = "Tsugawa\,\ Niigata";
$areanames{en}->{812550} = "Yasuzuka\,\ Niigata";
$areanames{en}->{812551} = "Joetsu\,\ Niigata";
$areanames{en}->{812552} = "Joetsu\,\ Niigata";
$areanames{en}->{812553} = "Joetsu\,\ Niigata";
$areanames{en}->{812554} = "Joetsu\,\ Niigata";
$areanames{en}->{812555} = "Itoigawa\,\ Niigata";
$areanames{en}->{812556} = "Itoigawa\,\ Niigata";
$areanames{en}->{812559} = "Yasuzuka\,\ Niigata";
$areanames{en}->{812560} = "Itoigawa\,\ Niigata";
$areanames{en}->{812562} = "Sanjo\,\ Niigata";
$areanames{en}->{812563} = "Sanjo\,\ Niigata";
$areanames{en}->{812564} = "Sanjo\,\ Niigata";
$areanames{en}->{812565} = "Sanjo\,\ Niigata";
$areanames{en}->{812566} = "Sanjo\,\ Niigata";
$areanames{en}->{812571} = "Muika\,\ Niigata";
$areanames{en}->{812572} = "Kashiwazaki\,\ Niigata";
$areanames{en}->{812573} = "Kashiwazaki\,\ Niigata";
$areanames{en}->{812574} = "Kashiwazaki\,\ Niigata";
$areanames{en}->{812575} = "Tokamachi\,\ Niigata";
$areanames{en}->{812576} = "Tokamachi\,\ Niigata";
$areanames{en}->{812577} = "Muika\,\ Niigata";
$areanames{en}->{812578} = "Muika\,\ Niigata";
$areanames{en}->{812580} = "Tokamachi\,\ Niigata";
$areanames{en}->{812582} = "Nagaoka\,\ Niigata";
$areanames{en}->{812583} = "Nagaoka\,\ Niigata";
$areanames{en}->{812584} = "Nagaoka\,\ Niigata";
$areanames{en}->{812585} = "Nagaoka\,\ Niigata";
$areanames{en}->{812586} = "Nagaoka\,\ Niigata";
$areanames{en}->{812587} = "Nagaoka\,\ Niigata";
$areanames{en}->{812588} = "Nagaoka\,\ Niigata";
$areanames{en}->{812589} = "Nagaoka\,\ Niigata";
$areanames{en}->{81259} = "Sado\,\ Niigata";
$areanames{en}->{81260} = "Anan\,\ Nagano";
$areanames{en}->{812612} = "Omachi\,\ Nagano";
$areanames{en}->{812613} = "Omachi\,\ Nagano";
$areanames{en}->{812614} = "Omachi\,\ Nagano";
$areanames{en}->{812615} = "Omachi\,\ Nagano";
$areanames{en}->{812616} = "Omachi\,\ Nagano";
$areanames{en}->{8126170} = "Omachi\,\ Nagano";
$areanames{en}->{8126171} = "Omachi\,\ Nagano";
$areanames{en}->{8126172} = "Omachi\,\ Nagano";
$areanames{en}->{8126173} = "Omachi\,\ Nagano";
$areanames{en}->{8126174} = "Omachi\,\ Nagano";
$areanames{en}->{8126175} = "Omachi\,\ Nagano";
$areanames{en}->{8126176} = "Omachi\,\ Nagano";
$areanames{en}->{8126178} = "Omachi\,\ Nagano";
$areanames{en}->{8126179} = "Omachi\,\ Nagano";
$areanames{en}->{812618} = "Omachi\,\ Nagano";
$areanames{en}->{812619} = "Omachi\,\ Nagano";
$areanames{en}->{81262} = "Nagano\,\ Nagano";
$areanames{en}->{81263} = "Matsumoto\,\ Nagano";
$areanames{en}->{812640} = "Nagano\,\ Nagano";
$areanames{en}->{812646} = "Nagano\,\ Nagano";
$areanames{en}->{812647} = "Nagano\,\ Nagano";
$areanames{en}->{812648} = "Nagano\,\ Nagano";
$areanames{en}->{812649} = "Nagano\,\ Nagano";
$areanames{en}->{812652} = "Iida\,\ Nagano";
$areanames{en}->{812653} = "Iida\,\ Nagano";
$areanames{en}->{812654} = "Iida\,\ Nagano";
$areanames{en}->{812655} = "Iida\,\ Nagano";
$areanames{en}->{812656} = "Ina\,\ Nagano";
$areanames{en}->{812657} = "Ina\,\ Nagano";
$areanames{en}->{812658} = "Ina\,\ Nagano";
$areanames{en}->{812659} = "Ina\,\ Nagano";
$areanames{en}->{81266} = "Suwa\,\ Nagano";
$areanames{en}->{812672} = "Komoro\,\ Nagano";
$areanames{en}->{812673} = "Komoro\,\ Nagano";
$areanames{en}->{812674} = "Komoro\,\ Nagano";
$areanames{en}->{812675} = "Saku\,\ Nagano";
$areanames{en}->{812676} = "Saku\,\ Nagano";
$areanames{en}->{812677} = "Saku\,\ Nagano";
$areanames{en}->{812678} = "Saku\,\ Nagano";
$areanames{en}->{812679} = "Saku\,\ Nagano";
$areanames{en}->{81268} = "Ueda\,\ Nagano";
$areanames{en}->{812692} = "Nakano\,\ Nagano";
$areanames{en}->{812693} = "Nakano\,\ Nagano";
$areanames{en}->{812694} = "Nakano\,\ Nagano";
$areanames{en}->{812695} = "Nakano\,\ Nagano";
$areanames{en}->{812696} = "Iiyama\,\ Nagano";
$areanames{en}->{812697} = "Iiyama\,\ Nagano";
$areanames{en}->{812698} = "Iiyama\,\ Nagano";
$areanames{en}->{81270} = "Isesaki\,\ Gunma";
$areanames{en}->{81272} = "Maebashi\,\ Gunma";
$areanames{en}->{81273} = "Takasaki\,\ Gunma";
$areanames{en}->{812742} = "Fujioka\,\ Gunma";
$areanames{en}->{812743} = "Fujioka\,\ Gunma";
$areanames{en}->{812744} = "Fujioka\,\ Gunma";
$areanames{en}->{812745} = "Fujioka\,\ Gunma";
$areanames{en}->{812746} = "Tomioka\,\ Gunma";
$areanames{en}->{812747} = "Tomioka\,\ Gunma";
$areanames{en}->{812748} = "Tomioka\,\ Gunma";
$areanames{en}->{81276} = "Ota\,\ Gunma";
$areanames{en}->{81277} = "Kiryu\,\ Gunma";
$areanames{en}->{812780} = "Maebashi\,\ Gunma";
$areanames{en}->{812782} = "Numata\,\ Gunma";
$areanames{en}->{812783} = "Numata\,\ Gunma";
$areanames{en}->{812784} = "Numata\,\ Gunma";
$areanames{en}->{812785} = "Numata\,\ Gunma";
$areanames{en}->{812786} = "Numata\,\ Gunma";
$areanames{en}->{812787} = "Numata\,\ Gunma";
$areanames{en}->{812788} = "Maebashi\,\ Gunma";
$areanames{en}->{812789} = "Maebashi\,\ Gunma";
$areanames{en}->{812792} = "Shibukawa\,\ Gunma";
$areanames{en}->{812793} = "Shibukawa\,\ Gunma";
$areanames{en}->{812794} = "Shibukawa\,\ Gunma";
$areanames{en}->{812795} = "Shibukawa\,\ Gunma";
$areanames{en}->{812796} = "Shibukawa\,\ Gunma";
$areanames{en}->{812797} = "Shibukawa\,\ Gunma";
$areanames{en}->{812798} = "Naganohara\,\ Gunma";
$areanames{en}->{812799} = "Naganohara\,\ Gunma";
$areanames{en}->{81280} = "Koga\,\ Ibaraki";
$areanames{en}->{81281} = "Utsunomiya\,\ Tochigi";
$areanames{en}->{81282} = "Tochigi\,\ Tochigi";
$areanames{en}->{812830} = "Utsunomiya\,\ Tochigi";
$areanames{en}->{812832} = "Sano\,\ Tochigi";
$areanames{en}->{812833} = "Utsunomiya\,\ Tochigi";
$areanames{en}->{812834} = "Utsunomiya\,\ Tochigi";
$areanames{en}->{812835} = "Sano\,\ Tochigi";
$areanames{en}->{812836} = "Sano\,\ Tochigi";
$areanames{en}->{812837} = "Sano\,\ Tochigi";
$areanames{en}->{812838} = "Sano\,\ Tochigi";
$areanames{en}->{812839} = "Sano\,\ Tochigi";
$areanames{en}->{81284} = "Ashikaga\,\ Tochigi";
$areanames{en}->{812852} = "Oyama\,\ Tochigi";
$areanames{en}->{812853} = "Oyama\,\ Tochigi";
$areanames{en}->{812854} = "Oyama\,\ Tochigi";
$areanames{en}->{812855} = "Oyama\,\ Tochigi";
$areanames{en}->{812856} = "Mooka\,\ Tochigi";
$areanames{en}->{812857} = "Mooka\,\ Tochigi";
$areanames{en}->{812858} = "Mooka\,\ Tochigi";
$areanames{en}->{812859} = "Oyama\,\ Tochigi";
$areanames{en}->{81286} = "Utsunomiya\,\ Tochigi";
$areanames{en}->{812872} = "Otawara\,\ Tochigi";
$areanames{en}->{812873} = "Otawara\,\ Tochigi";
$areanames{en}->{812874} = "Otawara\,\ Tochigi";
$areanames{en}->{812875} = "Otawara\,\ Tochigi";
$areanames{en}->{812876} = "Kuroiso\,\ Tochigi";
$areanames{en}->{812877} = "Kuroiso\,\ Tochigi";
$areanames{en}->{812878} = "Nasukarasuyama\,\ Tochigi";
$areanames{en}->{812879} = "Nasukarasuyama\,\ Tochigi";
$areanames{en}->{8128798} = "Otawara\,\ Tochigi";
$areanames{en}->{81288} = "Imabari\,\ Ehime";
$areanames{en}->{812890} = "Utsunomiya\,\ Tochigi";
$areanames{en}->{812892} = "Utsunomiya\,\ Tochigi";
$areanames{en}->{812893} = "Utsunomiya\,\ Tochigi";
$areanames{en}->{812894} = "Utsunomiya\,\ Tochigi";
$areanames{en}->{812895} = "Utsunomiya\,\ Tochigi";
$areanames{en}->{812896} = "Kanuma\,\ Tochigi";
$areanames{en}->{812897} = "Kanuma\,\ Tochigi";
$areanames{en}->{812898} = "Kanuma\,\ Tochigi";
$areanames{en}->{812899} = "Kanuma\,\ Tochigi";
$areanames{en}->{812911} = "Hokota\,\ Ibaraki";
$areanames{en}->{812913} = "Hokota\,\ Ibaraki";
$areanames{en}->{812914} = "Hokota\,\ Ibaraki";
$areanames{en}->{812917} = "Mito\,\ Ibaraki";
$areanames{en}->{81292} = "Mito\,\ Ibaraki";
$areanames{en}->{812930} = "Mito\,\ Ibaraki";
$areanames{en}->{812932} = "Takahagi\,\ Ibaraki";
$areanames{en}->{812933} = "Takahagi\,\ Ibaraki";
$areanames{en}->{812934} = "Takahagi\,\ Ibaraki";
$areanames{en}->{812935} = "Mito\,\ Ibaraki";
$areanames{en}->{812936} = "Mito\,\ Ibaraki";
$areanames{en}->{812937} = "Mito\,\ Ibaraki";
$areanames{en}->{812938} = "Mito\,\ Ibaraki";
$areanames{en}->{812939} = "Mito\,\ Ibaraki";
$areanames{en}->{81294} = "Hitachiota\,\ Ibaraki";
$areanames{en}->{812955} = "Hitachi\-Omiya\,\ Ibaraki";
$areanames{en}->{812956} = "Hitachi\-Omiya\,\ Ibaraki";
$areanames{en}->{812957} = "Daigo\,\ Ibaraki";
$areanames{en}->{812962} = "Shimodate\,\ Ibaraki";
$areanames{en}->{812963} = "Shimodate\,\ Ibaraki";
$areanames{en}->{812964} = "Shimodate\,\ Ibaraki";
$areanames{en}->{812965} = "Shimodate\,\ Ibaraki";
$areanames{en}->{812967} = "Kasama\,\ Ibaraki";
$areanames{en}->{812968} = "Kasama\,\ Ibaraki";
$areanames{en}->{81298} = "Tsuchiura\,\ Ibaraki";
$areanames{en}->{812992} = "Ishioka\,\ Ibaraki";
$areanames{en}->{812993} = "Ishioka\,\ Ibaraki";
$areanames{en}->{812994} = "Ishioka\,\ Ibaraki";
$areanames{en}->{812995} = "Ishioka\,\ Ibaraki";
$areanames{en}->{812996} = "Itako\,\ Ibaraki";
$areanames{en}->{812997} = "Itako\,\ Ibaraki";
$areanames{en}->{812998} = "Itako\,\ Ibaraki";
$areanames{en}->{812999} = "Itako\,\ Ibaraki";
$areanames{en}->{813} = "Tokyo";
$areanames{en}->{81420} = "Tokorozawa\,\ Saitama";
$areanames{en}->{814220} = "Kokubunji\,\ Tokyo";
$areanames{en}->{81423} = "Kokubunji\,\ Tokyo";
$areanames{en}->{814240} = "Kokubunji\,\ Tokyo";
$areanames{en}->{81425} = "Tachikawa\,\ Tokyo";
$areanames{en}->{81426} = "Hachioji\,\ Tokyo";
$areanames{en}->{81427} = "Sagamihara\,\ Kanagawa";
$areanames{en}->{814280} = "Tachikawa\,\ Tokyo";
$areanames{en}->{814281} = "Sagamihara\,\ Kanagawa";
$areanames{en}->{814282} = "Ome\,\ Tokyo";
$areanames{en}->{814283} = "Ome\,\ Tokyo";
$areanames{en}->{814284} = "Tachikawa\,\ Tokyo";
$areanames{en}->{814285} = "Sagamihara\,\ Kanagawa";
$areanames{en}->{814286} = "Sagamihara\,\ Kanagawa";
$areanames{en}->{814287} = "Ome\,\ Tokyo";
$areanames{en}->{814288} = "Ome\,\ Tokyo";
$areanames{en}->{814289} = "Ome\,\ Tokyo";
$areanames{en}->{81429} = "Tokorozawa\,\ Saitama";
$areanames{en}->{814291} = "Hanno\,\ Saitama";
$areanames{en}->{814297} = "Hanno\,\ Saitama";
$areanames{en}->{814298} = "Hanno\,\ Saitama";
$areanames{en}->{81432} = "Chiba\,\ Chiba";
$areanames{en}->{81433} = "Chiba\,\ Chiba";
$areanames{en}->{81434} = "Chiba\,\ Chiba";
$areanames{en}->{81436} = "Ichihara\,\ Chiba";
$areanames{en}->{81438} = "Kisarazu\,\ Chiba";
$areanames{en}->{81439} = "Kisarazu\,\ Chiba";
$areanames{en}->{8144} = "Kawasaki\,\ Kanagawa";
$areanames{en}->{8145} = "Yokohama\,\ Kanagawa";
$areanames{en}->{81460} = "Odawara\,\ Kanagawa";
$areanames{en}->{81462} = "Atsugi\,\ Kanagawa";
$areanames{en}->{81463} = "Hiratsuka\,\ Kanagawa";
$areanames{en}->{81464} = "Atsugi\,\ Kanagawa";
$areanames{en}->{81465} = "Odawara\,\ Kanagawa";
$areanames{en}->{81466} = "Fujisawa\,\ Kanagawa";
$areanames{en}->{81467} = "Fujisawa\,\ Kanagawa";
$areanames{en}->{81468} = "Yokosuka\,\ Kanagawa";
$areanames{en}->{814700} = "Kamogawa\,\ Chiba";
$areanames{en}->{814701} = "Kamogawa\,\ Chiba";
$areanames{en}->{814702} = "Tateyama\,\ Chiba";
$areanames{en}->{814703} = "Tateyama\,\ Chiba";
$areanames{en}->{814704} = "Tateyama\,\ Chiba";
$areanames{en}->{814705} = "Tateyama\,\ Chiba";
$areanames{en}->{814709} = "Kamogawa\,\ Chiba";
$areanames{en}->{81471} = "Kashiwa\,\ Chiba";
$areanames{en}->{81473} = "Ichikawa\,\ Chiba";
$areanames{en}->{81474} = "Funabashi\,\ Chiba";
$areanames{en}->{814752} = "Mobara\,\ Chiba";
$areanames{en}->{814753} = "Mobara\,\ Chiba";
$areanames{en}->{814754} = "Mobara\,\ Chiba";
$areanames{en}->{814755} = "Togane\,\ Chiba";
$areanames{en}->{814756} = "Togane\,\ Chiba";
$areanames{en}->{814757} = "Togane\,\ Chiba";
$areanames{en}->{814758} = "Togane\,\ Chiba";
$areanames{en}->{81476} = "Narita\,\ Chiba";
$areanames{en}->{814770} = "Ichikawa\,\ Chiba";
$areanames{en}->{814771} = "Ichikawa\,\ Chiba";
$areanames{en}->{814772} = "Ichikawa\,\ Chiba";
$areanames{en}->{814775} = "Funabashi\,\ Chiba";
$areanames{en}->{814776} = "Funabashi\,\ Chiba";
$areanames{en}->{814777} = "Funabashi\,\ Chiba";
$areanames{en}->{81478} = "Sawara\,\ Chiba";
$areanames{en}->{814792} = "Choshi\,\ Chiba";
$areanames{en}->{814793} = "Choshi\,\ Chiba";
$areanames{en}->{814794} = "Choshi\,\ Chiba";
$areanames{en}->{814795} = "Choshi\,\ Chiba";
$areanames{en}->{8147950} = "Yokaichiba\,\ Chiba";
$areanames{en}->{8147955} = "Yokaichiba\,\ Chiba";
$areanames{en}->{8147957} = "Yokaichiba\,\ Chiba";
$areanames{en}->{814796} = "Yokaichiba\,\ Chiba";
$areanames{en}->{814797} = "Yokaichiba\,\ Chiba";
$areanames{en}->{814798} = "Yokaichiba\,\ Chiba";
$areanames{en}->{81480} = "Kuki\,\ Saitama";
$areanames{en}->{81482} = "Kawaguchi\,\ Saitama";
$areanames{en}->{81484} = "Kawaguchi\,\ Saitama";
$areanames{en}->{81485} = "Kumagaya\,\ Saitama";
$areanames{en}->{81486} = "Urawa\,\ Saitama";
$areanames{en}->{81487} = "Urawa\,\ Saitama";
$areanames{en}->{81488} = "Urawa\,\ Saitama";
$areanames{en}->{81489} = "Soka\,\ Saitama";
$areanames{en}->{81492} = "Kawagoe\,\ Saitama";
$areanames{en}->{81493} = "Higashimatsuyama\,\ Saitama";
$areanames{en}->{81494} = "Chichibu\,\ Saitama";
$areanames{en}->{81495} = "Honjo\,\ Saitama";
$areanames{en}->{814998} = "Ogasawara\,\ Tokyo";
$areanames{en}->{8152} = "Nagoya\,\ Aichi";
$areanames{en}->{81531} = "Tahara\,\ Aichi";
$areanames{en}->{81532} = "Toyohashi\,\ Aichi";
$areanames{en}->{81533} = "Toyohashi\,\ Aichi";
$areanames{en}->{81534} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{81535} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{815362} = "Shinshiro\,\ Aichi";
$areanames{en}->{815363} = "Shinshiro\,\ Aichi";
$areanames{en}->{815366} = "Shitara\,\ Aichi";
$areanames{en}->{815367} = "Shitara\,\ Aichi";
$areanames{en}->{815368} = "Shitara\,\ Aichi";
$areanames{en}->{81537} = "Kakegawa\,\ Shizuoka";
$areanames{en}->{81538} = "Iwata\,\ Shizuoka";
$areanames{en}->{815392} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{815393} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{815394} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{815395} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153964} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153965} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153966} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153967} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153968} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153969} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153970} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153971} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153972} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153973} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153975} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153976} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153978} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{8153979} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{815398} = "Hamamatsu\,\ Shizuoka";
$areanames{en}->{81542} = "Shizuoka\,\ Shizuoka";
$areanames{en}->{81543} = "Shizuoka\,\ Shizuoka";
$areanames{en}->{81544} = "Fujinomiya\,\ Shizuoka";
$areanames{en}->{81545} = "Fuji\,\ Shizuoka";
$areanames{en}->{81546} = "Shizuoka\,\ Shizuoka";
$areanames{en}->{81547} = "Shimada\,\ Shizuoka";
$areanames{en}->{81548} = "Haibara\,\ Shizuoka";
$areanames{en}->{81549} = "Shizuoka\,\ Shizuoka";
$areanames{en}->{81550} = "Gotenba\,\ Shizuoka";
$areanames{en}->{81551} = "Nirasaki\,\ Yamanashi";
$areanames{en}->{81552} = "Kofu\,\ Yamanashi";
$areanames{en}->{81553} = "Yamanashi\,\ Yamanashi";
$areanames{en}->{81554} = "Otsuki\,\ Yamanashi";
$areanames{en}->{81555} = "Fujiyoshida\,\ Yamanashi";
$areanames{en}->{815566} = "Minobu\,\ Yamanashi";
$areanames{en}->{81557} = "Ito\,\ Shizuoka";
$areanames{en}->{815582} = "Shimoda\,\ Shizuoka";
$areanames{en}->{815583} = "Shimoda\,\ Shizuoka";
$areanames{en}->{815584} = "Shimoda\,\ Shizuoka";
$areanames{en}->{815585} = "Shimoda\,\ Shizuoka";
$areanames{en}->{815586} = "Shimoda\,\ Shizuoka";
$areanames{en}->{81559} = "Numazu\,\ Shizuoka";
$areanames{en}->{81561} = "Seto\,\ Aichi";
$areanames{en}->{81563} = "Nishio\,\ Aichi";
$areanames{en}->{81564} = "Okazaki\,\ Aichi";
$areanames{en}->{81565} = "Toyota\,\ Aichi";
$areanames{en}->{81566} = "Kariya\,\ Aichi";
$areanames{en}->{81567} = "Tsushima\,\ Aichi";
$areanames{en}->{81568} = "Kasugai\,\ Aichi";
$areanames{en}->{81569} = "Handa\,\ Aichi";
$areanames{en}->{81572} = "Tajimi\,\ Gifu";
$areanames{en}->{815732} = "Ena\,\ Gifu";
$areanames{en}->{815733} = "Ena\,\ Gifu";
$areanames{en}->{815734} = "Ena\,\ Gifu";
$areanames{en}->{815735} = "Ena\,\ Gifu";
$areanames{en}->{815736} = "Nakatsugawa\,\ Gifu";
$areanames{en}->{815737} = "Nakatsugawa\,\ Gifu";
$areanames{en}->{815738} = "Nakatsugawa\,\ Gifu";
$areanames{en}->{815742} = "Minokamo\,\ Gifu";
$areanames{en}->{815743} = "Minokamo\,\ Gifu";
$areanames{en}->{815744} = "Minokamo\,\ Gifu";
$areanames{en}->{815745} = "Minokamo\,\ Gifu";
$areanames{en}->{815746} = "Minokamo\,\ Gifu";
$areanames{en}->{815752} = "Sekigahara\,\ Gifu";
$areanames{en}->{815753} = "Sekigahara\,\ Gifu";
$areanames{en}->{815754} = "Sekigahara\,\ Gifu";
$areanames{en}->{815755} = "Sekigahara\,\ Gifu";
$areanames{en}->{815762} = "Gero\,\ Gifu";
$areanames{en}->{815763} = "Gero\,\ Gifu";
$areanames{en}->{815764} = "Gero\,\ Gifu";
$areanames{en}->{815765} = "Gero\,\ Gifu";
$areanames{en}->{815766} = "Gero\,\ Gifu";
$areanames{en}->{815767} = "Gero\,\ Gifu";
$areanames{en}->{815768} = "Gero\,\ Gifu";
$areanames{en}->{815769} = "Shokawa\,\ Gifu";
$areanames{en}->{81577} = "Takayama\,\ Gifu";
$areanames{en}->{81578} = "Kamioka\,\ Akita";
$areanames{en}->{81582} = "Gifu\,\ Gifu";
$areanames{en}->{81583} = "Gifu\,\ Gifu";
$areanames{en}->{81584} = "Ogaki\,\ Gifu";
$areanames{en}->{81585} = "Ibigawa\,\ Gifu";
$areanames{en}->{81586} = "Ichinomiya\,\ Aichi";
$areanames{en}->{81587} = "Ichinomiya\,\ Aichi";
$areanames{en}->{81591} = "Tsu\,\ Mie";
$areanames{en}->{81592} = "Tsu\,\ Mie";
$areanames{en}->{81593} = "Yokkaichi\,\ Mie";
$areanames{en}->{81594} = "Kuwana\,\ Mie";
$areanames{en}->{815958} = "Kameyama\,\ Mie";
$areanames{en}->{815959} = "Kameyama\,\ Mie";
$areanames{en}->{81596} = "Ise\,\ Mie";
$areanames{en}->{815972} = "Owase\,\ Mie";
$areanames{en}->{815973} = "Owase\,\ Mie";
$areanames{en}->{815974} = "Owase\,\ Mie";
$areanames{en}->{815977} = "Kumano\,\ Mie";
$areanames{en}->{815978} = "Kumano\,\ Mie";
$areanames{en}->{815979} = "Kumano\,\ Mie";
$areanames{en}->{815982} = "Matsusaka\,\ Mie";
$areanames{en}->{815983} = "Matsusaka\,\ Mie";
$areanames{en}->{815984} = "Matsusaka\,\ Mie";
$areanames{en}->{815985} = "Matsusaka\,\ Mie";
$areanames{en}->{815986} = "Matsusaka\,\ Mie";
$areanames{en}->{815992} = "Toba\,\ Mie";
$areanames{en}->{815993} = "Toba\,\ Mie";
$areanames{en}->{815994} = "Ago\,\ Mie";
$areanames{en}->{815995} = "Ago\,\ Mie";
$areanames{en}->{815996} = "Ago\,\ Mie";
$areanames{en}->{815997} = "Ago\,\ Mie";
$areanames{en}->{815998} = "Ago\,\ Mie";
$areanames{en}->{815999} = "Tsu\,\ Mie";
$areanames{en}->{816} = "Osaka\,\ Osaka";
$areanames{en}->{81721} = "Tondabayashi\,\ Osaka";
$areanames{en}->{81722} = "Sakai\,\ Osaka";
$areanames{en}->{81723} = "Sakai\,\ Osaka";
$areanames{en}->{817230} = "Neyagawa\,\ Osaka";
$areanames{en}->{817238} = "Neyagawa\,\ Osaka";
$areanames{en}->{817239} = "Neyagawa\,\ Osaka";
$areanames{en}->{81725} = "Izumi\,\ Osaka";
$areanames{en}->{81726} = "Ibaraki\,\ Osaka";
$areanames{en}->{81727} = "Ikeda\,\ Osaka";
$areanames{en}->{81728} = "Neyagawa\,\ Osaka";
$areanames{en}->{81729} = "Yao\,\ Osaka";
$areanames{en}->{81734} = "Wakayama\,\ Wakayama";
$areanames{en}->{817352} = "Shingu\,\ Fukuoka";
$areanames{en}->{817353} = "Shingu\,\ Fukuoka";
$areanames{en}->{817354} = "Shingu\,\ Fukuoka";
$areanames{en}->{817355} = "Shingu\,\ Fukuoka";
$areanames{en}->{817356} = "Kushimoto\,\ Wakayama";
$areanames{en}->{817357} = "Kushimoto\,\ Wakayama";
$areanames{en}->{817366} = "Iwade\,\ Wakayama";
$areanames{en}->{817367} = "Iwade\,\ Wakayama";
$areanames{en}->{817368} = "Iwade\,\ Wakayama";
$areanames{en}->{81737} = "Yuasa\,\ Wakayama";
$areanames{en}->{81738} = "Gobo\,\ Wakayama";
$areanames{en}->{81739} = "Tanabe\,\ Wakayama";
$areanames{en}->{81740} = "Imazu\,\ Shiga";
$areanames{en}->{81742} = "Nara\,\ Nara";
$areanames{en}->{81743} = "Nara\,\ Nara";
$areanames{en}->{81744} = "Yamatotakada\,\ Nara";
$areanames{en}->{817452} = "Yamatotakada\,\ Nara";
$areanames{en}->{817453} = "Yamatotakada\,\ Nara";
$areanames{en}->{817454} = "Yamatotakada\,\ Nara";
$areanames{en}->{817455} = "Yamatotakada\,\ Nara";
$areanames{en}->{817456} = "Yamatotakada\,\ Nara";
$areanames{en}->{817457} = "Yamatotakada\,\ Nara";
$areanames{en}->{817463} = "Yoshino\,\ Nara";
$areanames{en}->{817464} = "Yoshino\,\ Nara";
$areanames{en}->{817465} = "Yoshino\,\ Nara";
$areanames{en}->{817466} = "Totsukawa\,\ Nara";
$areanames{en}->{817468} = "Kamikitayama\,\ Nara";
$areanames{en}->{817475} = "Shimonoseki\,\ Yamaguchi";
$areanames{en}->{817476} = "Shimonoseki\,\ Yamaguchi";
$areanames{en}->{817482} = "Yokaichi\,\ Shiga";
$areanames{en}->{817483} = "Yokaichi\,\ Shiga";
$areanames{en}->{817484} = "Yokaichi\,\ Shiga";
$areanames{en}->{817485} = "Yokaichi\,\ Shiga";
$areanames{en}->{817486} = "Minakuchi\,\ Shiga";
$areanames{en}->{817487} = "Minakuchi\,\ Shiga";
$areanames{en}->{817488} = "Minakuchi\,\ Shiga";
$areanames{en}->{817492} = "Hikone\,\ Shiga";
$areanames{en}->{817493} = "Hikone\,\ Shiga";
$areanames{en}->{817494} = "Hikone\,\ Shiga";
$areanames{en}->{817495} = "Nagahama\,\ Shiga";
$areanames{en}->{817496} = "Nagahama\,\ Shiga";
$areanames{en}->{817497} = "Nagahama\,\ Shiga";
$areanames{en}->{817498} = "Nagahama\,\ Shiga";
$areanames{en}->{8175} = "Kyoto\,\ Kyoto";
$areanames{en}->{817612} = "Komatsu\,\ Ishikawa";
$areanames{en}->{817613} = "Komatsu\,\ Ishikawa";
$areanames{en}->{817614} = "Komatsu\,\ Ishikawa";
$areanames{en}->{817615} = "Komatsu\,\ Ishikawa";
$areanames{en}->{817616} = "Komatsu\,\ Ishikawa";
$areanames{en}->{817617} = "Kaga\,\ Ishikawa";
$areanames{en}->{817618} = "Kaga\,\ Ishikawa";
$areanames{en}->{81762} = "Kanazawa\,\ Ishikawa";
$areanames{en}->{81763} = "Fukuno\,\ Toyama";
$areanames{en}->{81764} = "Toyama\,\ Toyama";
$areanames{en}->{81765} = "Uozu\,\ Toyama";
$areanames{en}->{81766} = "Takaoka\,\ Toyama";
$areanames{en}->{817672} = "Hakui\,\ Ishikawa";
$areanames{en}->{817673} = "Hakui\,\ Ishikawa";
$areanames{en}->{817674} = "Hakui\,\ Ishikawa";
$areanames{en}->{817675} = "Nanao\,\ Ishikawa";
$areanames{en}->{817676} = "Nanao\,\ Ishikawa";
$areanames{en}->{817677} = "Nanao\,\ Ishikawa";
$areanames{en}->{817678} = "Nanao\,\ Ishikawa";
$areanames{en}->{817682} = "Wajima\,\ Ishikawa";
$areanames{en}->{817683} = "Wajima\,\ Ishikawa";
$areanames{en}->{817684} = "Wajima\,\ Ishikawa";
$areanames{en}->{817685} = "Wajima\,\ Ishikawa";
$areanames{en}->{817686} = "Noto\,\ Ishikawa";
$areanames{en}->{817687} = "Noto\,\ Ishikawa";
$areanames{en}->{817688} = "Noto\,\ Ishikawa";
$areanames{en}->{817702} = "Tsuruga\,\ Fukui";
$areanames{en}->{817703} = "Tsuruga\,\ Fukui";
$areanames{en}->{817704} = "Tsuruga\,\ Fukui";
$areanames{en}->{817705} = "Obama\,\ Fukui";
$areanames{en}->{817706} = "Obama\,\ Fukui";
$areanames{en}->{817707} = "Obama\,\ Fukui";
$areanames{en}->{817712} = "Kameoka\,\ Kyoto";
$areanames{en}->{817713} = "Kameoka\,\ Kyoto";
$areanames{en}->{817714} = "Kameoka\,\ Kyoto";
$areanames{en}->{817715} = "Kameoka\,\ Kyoto";
$areanames{en}->{817716} = "Sonobe\,\ Kyoto";
$areanames{en}->{817717} = "Sonobe\,\ Kyoto";
$areanames{en}->{817718} = "Sonobe\,\ Kyoto";
$areanames{en}->{817722} = "Miyazu\,\ Kyoto";
$areanames{en}->{817723} = "Miyazu\,\ Kyoto";
$areanames{en}->{817724} = "Miyazu\,\ Kyoto";
$areanames{en}->{817725} = "Miyazu\,\ Kyoto";
$areanames{en}->{817732} = "Fukuchiyama\,\ Kyoto";
$areanames{en}->{817733} = "Fukuchiyama\,\ Kyoto";
$areanames{en}->{817734} = "Fukuchiyama\,\ Kyoto";
$areanames{en}->{817735} = "Fukuchiyama\,\ Kyoto";
$areanames{en}->{817736} = "Maizuru\,\ Kyoto";
$areanames{en}->{817737} = "Maizuru\,\ Kyoto";
$areanames{en}->{817738} = "Maizuru\,\ Kyoto";
$areanames{en}->{81774} = "Uji\,\ Kyoto";
$areanames{en}->{81775} = "Otsu\,\ Shiga";
$areanames{en}->{81776} = "Fukui\,\ Fukui";
$areanames{en}->{81778} = "Takefu\,\ Fukui";
$areanames{en}->{81779} = "Ono\,\ Gifu";
$areanames{en}->{8178} = "Kobe\,\ Hyogo";
$areanames{en}->{817902} = "Fukusaki\,\ Hyogo";
$areanames{en}->{817903} = "Fukusaki\,\ Hyogo";
$areanames{en}->{817904} = "Fukusaki\,\ Hyogo";
$areanames{en}->{817905} = "Fukusaki\,\ Hyogo";
$areanames{en}->{817912} = "Aioi\,\ Hyogo";
$areanames{en}->{817914} = "Aioi\,\ Hyogo";
$areanames{en}->{817915} = "Aioi\,\ Hyogo";
$areanames{en}->{81792} = "Himeji\,\ Hyogo";
$areanames{en}->{81793} = "Himeji\,\ Hyogo";
$areanames{en}->{817940} = "Kakogawa\,\ Hyogo";
$areanames{en}->{817942} = "Kakogawa\,\ Hyogo";
$areanames{en}->{817943} = "Kakogawa\,\ Hyogo";
$areanames{en}->{817944} = "Kakogawa\,\ Hyogo";
$areanames{en}->{817945} = "Kakogawa\,\ Hyogo";
$areanames{en}->{817946} = "Miki\,\ Hyogo";
$areanames{en}->{817947} = "Miki\,\ Hyogo";
$areanames{en}->{817948} = "Miki\,\ Hyogo";
$areanames{en}->{817949} = "Kakogawa\,\ Hyogo";
$areanames{en}->{817950} = "Sanda\,\ Hyogo";
$areanames{en}->{817952} = "Nishiwaki\,\ Hyogo";
$areanames{en}->{817953} = "Nishiwaki\,\ Hyogo";
$areanames{en}->{817954} = "Nishiwaki\,\ Hyogo";
$areanames{en}->{817955} = "Sanda\,\ Hyogo";
$areanames{en}->{817956} = "Sanda\,\ Hyogo";
$areanames{en}->{817959} = "Sanda\,\ Hyogo";
$areanames{en}->{817962} = "Toyooka\,\ Hyogo";
$areanames{en}->{817963} = "Toyooka\,\ Hyogo";
$areanames{en}->{817964} = "Toyooka\,\ Hyogo";
$areanames{en}->{817965} = "Toyooka\,\ Hyogo";
$areanames{en}->{817968} = "Hamasaka\,\ Hyogo";
$areanames{en}->{817969} = "Hamasaka\,\ Hyogo";
$areanames{en}->{81797} = "Nishinomiya\,\ Hyogo";
$areanames{en}->{81798} = "Nishinomiya\,\ Hyogo";
$areanames{en}->{817992} = "Sumoto\,\ Hyogo";
$areanames{en}->{817993} = "Sumoto\,\ Hyogo";
$areanames{en}->{817994} = "Sumoto\,\ Hyogo";
$areanames{en}->{817995} = "Sumoto\,\ Hyogo";
$areanames{en}->{817996} = "Tsuna\,\ Hyogo";
$areanames{en}->{817997} = "Tsuna\,\ Hyogo";
$areanames{en}->{817998} = "Tsuna\,\ Hyogo";
$areanames{en}->{818202} = "Yanai\,\ Yamaguchi";
$areanames{en}->{818203} = "Yanai\,\ Yamaguchi";
$areanames{en}->{818204} = "Yanai\,\ Yamaguchi";
$areanames{en}->{818205} = "Yanai\,\ Yamaguchi";
$areanames{en}->{818206} = "Yanai\,\ Yamaguchi";
$areanames{en}->{81822} = "Hiroshima\,\ Hiroshima";
$areanames{en}->{81823} = "Kure\,\ Hiroshima";
$areanames{en}->{818240} = "Higashi\-ku\,\ Hiroshima";
$areanames{en}->{818242} = "Higashi\-ku\,\ Hiroshima";
$areanames{en}->{818243} = "Higashi\-ku\,\ Hiroshima";
$areanames{en}->{818244} = "Miyoshi\,\ Hiroshima";
$areanames{en}->{818245} = "Miyoshi\,\ Hiroshima";
$areanames{en}->{818246} = "Miyoshi\,\ Hiroshima";
$areanames{en}->{818247} = "Shobara\,\ Hiroshima";
$areanames{en}->{818248} = "Shobara\,\ Hiroshima";
$areanames{en}->{818249} = "Higashi\-ku\,\ Hiroshima";
$areanames{en}->{81825} = "Hiroshima\,\ Hiroshima";
$areanames{en}->{818262} = "Kake\,\ Hiroshima";
$areanames{en}->{818263} = "Kake\,\ Hiroshima";
$areanames{en}->{81827} = "Iwakuni\,\ Yamaguchi";
$areanames{en}->{81828} = "Hiroshima\,\ Hiroshima";
$areanames{en}->{818290} = "Hiroshima\,\ Hiroshima";
$areanames{en}->{818292} = "Hiroshima\,\ Hiroshima";
$areanames{en}->{8182920} = "Hatsukaichi\,\ Hiroshima";
$areanames{en}->{818293} = "Hatsukaichi\,\ Hiroshima";
$areanames{en}->{818294} = "Hatsukaichi\,\ Hiroshima";
$areanames{en}->{8182941} = "Hiroshima\,\ Hiroshima";
$areanames{en}->{8182942} = "Hiroshima\,\ Hiroshima";
$areanames{en}->{8182943} = "Hiroshima\,\ Hiroshima";
$areanames{en}->{818295} = "Hatsukaichi\,\ Hiroshima";
$areanames{en}->{818296} = "Hiroshima\,\ Hiroshima";
$areanames{en}->{818297} = "Hatsukaichi\,\ Hiroshima";
$areanames{en}->{818298} = "Hatsukaichi\,\ Hiroshima";
$areanames{en}->{818299} = "Hiroshima\,\ Hiroshima";
$areanames{en}->{81832} = "Shimonoseki\,\ Yamaguchi";
$areanames{en}->{81833} = "Kudamatsu\,\ Yamaguchi";
$areanames{en}->{81834} = "Tokuyama\,\ Yamaguchi";
$areanames{en}->{81835} = "Hofu\,\ Yamaguchi";
$areanames{en}->{818360} = "Ogori\,\ Yamaguchi";
$areanames{en}->{818362} = "Ube\,\ Yamaguchi";
$areanames{en}->{818363} = "Ube\,\ Yamaguchi";
$areanames{en}->{818364} = "Ube\,\ Yamaguchi";
$areanames{en}->{818365} = "Ube\,\ Yamaguchi";
$areanames{en}->{818366} = "Ube\,\ Yamaguchi";
$areanames{en}->{818367} = "Ube\,\ Yamaguchi";
$areanames{en}->{818368} = "Ube\,\ Yamaguchi";
$areanames{en}->{818369} = "Ube\,\ Yamaguchi";
$areanames{en}->{818372} = "Nagato\,\ Yamaguchi";
$areanames{en}->{818373} = "Nagato\,\ Yamaguchi";
$areanames{en}->{818374} = "Nagato\,\ Yamaguchi";
$areanames{en}->{818375} = "Mine\,\ Yamaguchi";
$areanames{en}->{818376} = "Mine\,\ Yamaguchi";
$areanames{en}->{8183766} = "Shimonoseki\,\ Yamaguchi";
$areanames{en}->{8183767} = "Shimonoseki\,\ Yamaguchi";
$areanames{en}->{8183768} = "Shimonoseki\,\ Yamaguchi";
$areanames{en}->{818377} = "Shimonoseki\,\ Yamaguchi";
$areanames{en}->{818378} = "Shimonoseki\,\ Yamaguchi";
$areanames{en}->{818382} = "Hagi\,\ Yamaguchi";
$areanames{en}->{818383} = "Hagi\,\ Yamaguchi";
$areanames{en}->{818384} = "Hagi\,\ Yamaguchi";
$areanames{en}->{818385} = "Hagi\,\ Yamaguchi";
$areanames{en}->{818387} = "Tamagawa\,\ Yamaguchi";
$areanames{en}->{818388} = "Tamagawa\,\ Yamaguchi";
$areanames{en}->{81839} = "Yamaguchi\,\ Yamaguchi";
$areanames{en}->{818391} = "Ogori\,\ Yamaguchi";
$areanames{en}->{818397} = "Ogori\,\ Yamaguchi";
$areanames{en}->{818398} = "Ogori\,\ Yamaguchi";
$areanames{en}->{81845} = "Innoshima\,\ Hiroshima";
$areanames{en}->{818462} = "Takehara\,\ Hiroshima";
$areanames{en}->{818463} = "Takehara\,\ Hiroshima";
$areanames{en}->{818464} = "Takehara\,\ Hiroshima";
$areanames{en}->{818466} = "Mima\,\ Tokushima";
$areanames{en}->{818467} = "Mima\,\ Tokushima";
$areanames{en}->{818474} = "Fuchu\,\ Hiroshima";
$areanames{en}->{818475} = "Fuchu\,\ Hiroshima";
$areanames{en}->{818476} = "Fuchu\,\ Hiroshima";
$areanames{en}->{818477} = "Tojo\,\ Hiroshima";
$areanames{en}->{818478} = "Tojo\,\ Hiroshima";
$areanames{en}->{818479} = "Tojo\,\ Hiroshima";
$areanames{en}->{81848} = "Onomichi\,\ Hiroshima";
$areanames{en}->{81849} = "Fukuyama\,\ Hiroshima";
$areanames{en}->{818490} = "Onomichi\,\ Hiroshima";
$areanames{en}->{818493} = "Onomichi\,\ Hiroshima";
$areanames{en}->{818512} = "Nishigo\,\ Fukushima";
$areanames{en}->{818514} = "Ama\,\ Shimane";
$areanames{en}->{81852} = "Matsue\,\ Shimane";
$areanames{en}->{81853} = "Izumo\,\ Shimane";
$areanames{en}->{818542} = "Yasugi\,\ Shimane";
$areanames{en}->{818543} = "Yasugi\,\ Shimane";
$areanames{en}->{818544} = "Kisuki\,\ Shimane";
$areanames{en}->{818545} = "Kisuki\,\ Shimane";
$areanames{en}->{818546} = "Kakeya\,\ Shimane";
$areanames{en}->{818547} = "Kakeya\,\ Shimane";
$areanames{en}->{818552} = "Hamada\,\ Shimane";
$areanames{en}->{818553} = "Hamada\,\ Shimane";
$areanames{en}->{818554} = "Hamada\,\ Shimane";
$areanames{en}->{818555} = "Gotsu\,\ Shimane";
$areanames{en}->{818556} = "Gotsu\,\ Shimane";
$areanames{en}->{818557} = "Kawamoto\,\ Shimane";
$areanames{en}->{818558} = "Kawamoto\,\ Shimane";
$areanames{en}->{818559} = "Kawamoto\,\ Shimane";
$areanames{en}->{818562} = "Masuda\,\ Shimane";
$areanames{en}->{818563} = "Masuda\,\ Shimane";
$areanames{en}->{818564} = "Masuda\,\ Shimane";
$areanames{en}->{818565} = "Masuda\,\ Shimane";
$areanames{en}->{818567} = "Tsuwano\,\ Shimane";
$areanames{en}->{818568} = "Tsuwano\,\ Shimane";
$areanames{en}->{81857} = "Tottori\,\ Tottori";
$areanames{en}->{818582} = "Kurayoshi\,\ Tottori";
$areanames{en}->{818583} = "Kurayoshi\,\ Tottori";
$areanames{en}->{818584} = "Kurayoshi\,\ Tottori";
$areanames{en}->{818585} = "Kurayoshi\,\ Tottori";
$areanames{en}->{818586} = "Kurayoshi\,\ Tottori";
$areanames{en}->{818587} = "Koge\,\ Tottori";
$areanames{en}->{818588} = "Koge\,\ Tottori";
$areanames{en}->{818592} = "Yonago\,\ Tottori";
$areanames{en}->{818593} = "Yonago\,\ Tottori";
$areanames{en}->{818594} = "Yonago\,\ Tottori";
$areanames{en}->{818595} = "Yonago\,\ Tottori";
$areanames{en}->{818596} = "Yonago\,\ Tottori";
$areanames{en}->{81862} = "Okayama\,\ Okayama";
$areanames{en}->{81863} = "Tamano\,\ Okayama";
$areanames{en}->{81864} = "Kurashiki\,\ Okayama";
$areanames{en}->{818652} = "Kurashiki\,\ Okayama";
$areanames{en}->{818654} = "Kamogata\,\ Okayama";
$areanames{en}->{818655} = "Kamogata\,\ Okayama";
$areanames{en}->{8186552} = "Kurashiki\,\ Okayama";
$areanames{en}->{8186553} = "Kurashiki\,\ Okayama";
$areanames{en}->{818656} = "Kasaoka\,\ Okayama";
$areanames{en}->{818657} = "Kasaoka\,\ Okayama";
$areanames{en}->{818660} = "Seto\,\ Okayama";
$areanames{en}->{818662} = "Takahashi\,\ Okayama";
$areanames{en}->{818663} = "Soja\,\ Okayama";
$areanames{en}->{818664} = "Takahashi\,\ Okayama";
$areanames{en}->{818665} = "Takahashi\,\ Okayama";
$areanames{en}->{818666} = "Ibara\,\ Okayama";
$areanames{en}->{818667} = "Ibara\,\ Okayama";
$areanames{en}->{818668} = "Ibara\,\ Okayama";
$areanames{en}->{818669} = "Soja\,\ Okayama";
$areanames{en}->{8186691} = "Kurashiki\,\ Okayama";
$areanames{en}->{8186697} = "Kurashiki\,\ Okayama";
$areanames{en}->{8186698} = "Kurashiki\,\ Okayama";
$areanames{en}->{818674} = "Kuse\,\ Okayama";
$areanames{en}->{818675} = "Kuse\,\ Okayama";
$areanames{en}->{818676} = "Kuse\,\ Okayama";
$areanames{en}->{818677} = "Niimi\,\ Okayama";
$areanames{en}->{818678} = "Niimi\,\ Okayama";
$areanames{en}->{818679} = "Niimi\,\ Okayama";
$areanames{en}->{818680} = "Okayama\,\ Okayama";
$areanames{en}->{818682} = "Tsuyama\,\ Okayama";
$areanames{en}->{818683} = "Tsuyama\,\ Okayama";
$areanames{en}->{818684} = "Tsuyama\,\ Okayama";
$areanames{en}->{818685} = "Tsuyama\,\ Okayama";
$areanames{en}->{818686} = "Tsuyama\,\ Okayama";
$areanames{en}->{818687} = "Mimasaka\,\ Okayama";
$areanames{en}->{818688} = "Mimasaka\,\ Okayama";
$areanames{en}->{818689} = "Okayama\,\ Okayama";
$areanames{en}->{818690} = "Okayama\,\ Okayama";
$areanames{en}->{818692} = "Oku\,\ Okayama";
$areanames{en}->{818693} = "Oku\,\ Okayama";
$areanames{en}->{818694} = "Okayama\,\ Okayama";
$areanames{en}->{818695} = "Seto\,\ Okayama";
$areanames{en}->{818696} = "Bizen\,\ Okayama";
$areanames{en}->{818697} = "Bizen\,\ Okayama";
$areanames{en}->{818698} = "Bizen\,\ Okayama";
$areanames{en}->{8186992} = "Bizen\,\ Okayama";
$areanames{en}->{8186993} = "Bizen\,\ Okayama";
$areanames{en}->{8186994} = "Seto\,\ Okayama";
$areanames{en}->{8186995} = "Seto\,\ Okayama";
$areanames{en}->{8186996} = "Seto\,\ Okayama";
$areanames{en}->{8186997} = "Seto\,\ Okayama";
$areanames{en}->{8186998} = "Seto\,\ Okayama";
$areanames{en}->{8186999} = "Seto\,\ Okayama";
$areanames{en}->{81875} = "Kan\'onji\,\ Kagawa";
$areanames{en}->{81877} = "Marugame\,\ Kagawa";
$areanames{en}->{81878} = "Takamatsu\,\ Kagawa";
$areanames{en}->{818796} = "Tonosho\,\ Kagawa";
$areanames{en}->{818797} = "Tonosho\,\ Kagawa";
$areanames{en}->{818798} = "Tonosho\,\ Kagawa";
$areanames{en}->{818806} = "Sukumo\,\ Kochi";
$areanames{en}->{818807} = "Sukumo\,\ Kochi";
$areanames{en}->{818808} = "Tosashimizu\,\ Kochi";
$areanames{en}->{8188095} = "Tosashimizu\,\ Kochi";
$areanames{en}->{8188096} = "Tosashimizu\,\ Kochi";
$areanames{en}->{8188097} = "Tosashimizu\,\ Kochi";
$areanames{en}->{8188098} = "Tosashimizu\,\ Kochi";
$areanames{en}->{8188099} = "Tosashimizu\,\ Kochi";
$areanames{en}->{818832} = "Kamojima\,\ Tokushima";
$areanames{en}->{818833} = "Kamojima\,\ Tokushima";
$areanames{en}->{818834} = "Kamojima\,\ Tokushima";
$areanames{en}->{818835} = "Mima\,\ Tokushima";
$areanames{en}->{818836} = "Mima\,\ Tokushima";
$areanames{en}->{818842} = "Anan\,\ Tokushima";
$areanames{en}->{818843} = "Anan\,\ Tokushima";
$areanames{en}->{818844} = "Anan\,\ Tokushima";
$areanames{en}->{81885} = "Komatsushima\,\ Tokushima";
$areanames{en}->{81886} = "Tokushima\,\ Tokushima";
$areanames{en}->{818872} = "Muroto\,\ Kochi";
$areanames{en}->{818873} = "Aki\,\ Kochi";
$areanames{en}->{818874} = "Aki\,\ Kochi";
$areanames{en}->{818879} = "Muroto\,\ Kochi";
$areanames{en}->{81888} = "Kochi\,\ Kochi";
$areanames{en}->{818892} = "Sakawa\,\ Kochi";
$areanames{en}->{818893} = "Sakawa\,\ Kochi";
$areanames{en}->{818894} = "Susaki\,\ Kochi";
$areanames{en}->{818895} = "Susaki\,\ Kochi";
$areanames{en}->{818896} = "Susaki\,\ Kochi";
$areanames{en}->{81892} = "Kumakogen\,\ Ehime";
$areanames{en}->{81893} = "Ozu\,\ Ehime";
$areanames{en}->{818942} = "Yawatahama\,\ Ehime";
$areanames{en}->{818943} = "Yawatahama\,\ Ehime";
$areanames{en}->{818944} = "Yawatahama\,\ Ehime";
$areanames{en}->{818945} = "Yawatahama\,\ Ehime";
$areanames{en}->{818946} = "Uwajima\,\ Ehime";
$areanames{en}->{818947} = "Uwajima\,\ Ehime";
$areanames{en}->{818948} = "Uwajima\,\ Ehime";
$areanames{en}->{818949} = "Uwajima\,\ Ehime";
$areanames{en}->{818952} = "Uwajima\,\ Ehime";
$areanames{en}->{818953} = "Uwajima\,\ Ehime";
$areanames{en}->{818954} = "Uwajima\,\ Ehime";
$areanames{en}->{818955} = "Uwajima\,\ Ehime";
$areanames{en}->{818956} = "Uwajima\,\ Ehime";
$areanames{en}->{818957} = "Misho\,\ Ehime";
$areanames{en}->{818958} = "Misho\,\ Ehime";
$areanames{en}->{81896} = "Iyomishima\,\ Ehime";
$areanames{en}->{818972} = "Niihama\,\ Ehime";
$areanames{en}->{818973} = "Niihama\,\ Ehime";
$areanames{en}->{818974} = "Niihama\,\ Ehime";
$areanames{en}->{818975} = "Niihama\,\ Ehime";
$areanames{en}->{818976} = "Niihama\,\ Ehime";
$areanames{en}->{818977} = "Hakata\,\ Ehime";
$areanames{en}->{818978} = "Hakata\,\ Ehime";
$areanames{en}->{81898} = "Imabari\,\ Ehime";
$areanames{en}->{81899} = "Matsuyama\,\ Ehime";
$areanames{en}->{81922} = "Fukuoka\,\ Fukuoka";
$areanames{en}->{81923} = "Fukuoka\,\ Fukuoka";
$areanames{en}->{819232} = "Maebaru\,\ Fukuoka";
$areanames{en}->{819233} = "Maebaru\,\ Fukuoka";
$areanames{en}->{81924} = "Fukuoka\,\ Fukuoka";
$areanames{en}->{81925} = "Fukuoka\,\ Fukuoka";
$areanames{en}->{81926} = "Fukuoka\,\ Fukuoka";
$areanames{en}->{81927} = "Fukuoka\,\ Fukuoka";
$areanames{en}->{81928} = "Fukuoka\,\ Fukuoka";
$areanames{en}->{81929} = "Fukuoka\,\ Fukuoka";
$areanames{en}->{81930} = "Yukuhashi\,\ Fukuoka";
$areanames{en}->{81932} = "Kitakyushu\,\ Fukuoka";
$areanames{en}->{81933} = "Kitakyushu\,\ Fukuoka";
$areanames{en}->{81934} = "Kitakyushu\,\ Fukuoka";
$areanames{en}->{81935} = "Kitakyushu\,\ Fukuoka";
$areanames{en}->{81936} = "Kitakyushu\,\ Fukuoka";
$areanames{en}->{81937} = "Kitakyushu\,\ Fukuoka";
$areanames{en}->{81938} = "Kitakyushu\,\ Fukuoka";
$areanames{en}->{81939} = "Kitakyushu\,\ Fukuoka";
$areanames{en}->{81940} = "Munakata\,\ Fukuoka";
$areanames{en}->{81942} = "Kurume\,\ Fukuoka";
$areanames{en}->{819432} = "Yame\,\ Fukuoka";
$areanames{en}->{819433} = "Yame\,\ Fukuoka";
$areanames{en}->{819434} = "Yame\,\ Fukuoka";
$areanames{en}->{819435} = "Yame\,\ Fukuoka";
$areanames{en}->{819437} = "Tanushimaru\,\ Fukuoka";
$areanames{en}->{819438} = "Tanushimaru\,\ Fukuoka";
$areanames{en}->{81944} = "Setaka\,\ Fukuoka";
$areanames{en}->{81946} = "Amagi\,\ Fukuoka";
$areanames{en}->{81947} = "Tagawa\,\ Fukuoka";
$areanames{en}->{81948} = "Iizuka\,\ Fukuoka";
$areanames{en}->{81949} = "Nogata\,\ Fukuoka";
$areanames{en}->{81950} = "Hirado\,\ Nagasaki";
$areanames{en}->{81952} = "Saga\,\ Saga";
$areanames{en}->{819542} = "Takeo\,\ Saga";
$areanames{en}->{819543} = "Takeo\,\ Saga";
$areanames{en}->{819544} = "Takeo\,\ Saga";
$areanames{en}->{819546} = "Kashima\,\ Saga";
$areanames{en}->{819547} = "Kashima\,\ Saga";
$areanames{en}->{819552} = "Imari\,\ Saga";
$areanames{en}->{819553} = "Imari\,\ Saga";
$areanames{en}->{819554} = "Imari\,\ Saga";
$areanames{en}->{819555} = "Karatsu\,\ Saga";
$areanames{en}->{819556} = "Karatsu\,\ Saga";
$areanames{en}->{819557} = "Karatsu\,\ Saga";
$areanames{en}->{819558} = "Karatsu\,\ Saga";
$areanames{en}->{81956} = "Sasebo\,\ Nagasaki";
$areanames{en}->{819572} = "Isahaya\,\ Nagasaki";
$areanames{en}->{819573} = "Isahaya\,\ Nagasaki";
$areanames{en}->{819574} = "Isahaya\,\ Nagasaki";
$areanames{en}->{819575} = "Isahaya\,\ Nagasaki";
$areanames{en}->{819576} = "Shimabara\,\ Nagasaki";
$areanames{en}->{819577} = "Shimabara\,\ Nagasaki";
$areanames{en}->{819578} = "Shimabara\,\ Nagasaki";
$areanames{en}->{81958} = "Nagasaki\,\ Nagasaki";
$areanames{en}->{819592} = "Oseto\,\ Nagasaki";
$areanames{en}->{819593} = "Oseto\,\ Nagasaki";
$areanames{en}->{819596} = "Fukue\,\ Nagasaki";
$areanames{en}->{819597} = "Fukue\,\ Nagasaki";
$areanames{en}->{819598} = "Fukue\,\ Nagasaki";
$areanames{en}->{819599} = "Oseto\,\ Nagasaki";
$areanames{en}->{81962} = "Kumamoto\,\ Kumamoto";
$areanames{en}->{81963} = "Kumamoto\,\ Kumamoto";
$areanames{en}->{81965} = "Yatsushiro\,\ Kumamoto";
$areanames{en}->{819662} = "Hitoyoshi\,\ Kumamoto";
$areanames{en}->{819663} = "Hitoyoshi\,\ Kumamoto";
$areanames{en}->{819664} = "Hitoyoshi\,\ Kumamoto";
$areanames{en}->{819665} = "Hitoyoshi\,\ Kumamoto";
$areanames{en}->{819666} = "Minamata\,\ Kumamoto";
$areanames{en}->{819667} = "Minamata\,\ Kumamoto";
$areanames{en}->{819668} = "Minamata\,\ Kumamoto";
$areanames{en}->{819676} = "Takamori\,\ Kumamoto";
$areanames{en}->{819679} = "Takamori\,\ Kumamoto";
$areanames{en}->{819682} = "Yamaga\,\ Kumamoto";
$areanames{en}->{819683} = "Yamaga\,\ Kumamoto";
$areanames{en}->{819684} = "Yamaga\,\ Kumamoto";
$areanames{en}->{819685} = "Tamana\,\ Kumamoto";
$areanames{en}->{819686} = "Tamana\,\ Kumamoto";
$areanames{en}->{819687} = "Tamana\,\ Kumamoto";
$areanames{en}->{819688} = "Tamana\,\ Kumamoto";
$areanames{en}->{81969} = "Amakusa\,\ Kumamoto";
$areanames{en}->{819722} = "Saiki\,\ Oita";
$areanames{en}->{819723} = "Saiki\,\ Oita";
$areanames{en}->{819724} = "Saiki\,\ Oita";
$areanames{en}->{819725} = "Saiki\,\ Oita";
$areanames{en}->{819726} = "Usuki\,\ Oita";
$areanames{en}->{819727} = "Usuki\,\ Oita";
$areanames{en}->{819728} = "Usuki\,\ Oita";
$areanames{en}->{819732} = "Hita\,\ Oita";
$areanames{en}->{819733} = "Hita\,\ Oita";
$areanames{en}->{819734} = "Hita\,\ Oita";
$areanames{en}->{819735} = "Hita\,\ Oita";
$areanames{en}->{819737} = "Kusu\,\ Oita";
$areanames{en}->{819738} = "Kusu\,\ Oita";
$areanames{en}->{819742} = "Mie\,\ Oita";
$areanames{en}->{819743} = "Mie\,\ Oita";
$areanames{en}->{819744} = "Mie\,\ Oita";
$areanames{en}->{819746} = "Taketa\,\ Oita";
$areanames{en}->{819747} = "Taketa\,\ Oita";
$areanames{en}->{81975} = "Oita\,\ Oita";
$areanames{en}->{81977} = "Beppu\,\ Oita";
$areanames{en}->{819782} = "Bungotakada\,\ Oita";
$areanames{en}->{819783} = "Bungotakada\,\ Oita";
$areanames{en}->{819784} = "Bungotakada\,\ Oita";
$areanames{en}->{819785} = "Bungotakada\,\ Oita";
$areanames{en}->{819786} = "Kitsuki\,\ Oita";
$areanames{en}->{819787} = "Kunisaki\,\ Oita";
$areanames{en}->{819788} = "Kunisaki\,\ Oita";
$areanames{en}->{819789} = "Kitsuki\,\ Oita";
$areanames{en}->{81979} = "Nakatsu\,\ Oita";
$areanames{en}->{819802} = "Minamidaito\,\ Okinawa";
$areanames{en}->{819803} = "Nago\,\ Okinawa";
$areanames{en}->{819804} = "Nago\,\ Okinawa";
$areanames{en}->{819805} = "Nago\,\ Okinawa";
$areanames{en}->{819808} = "Yaeyama\ District\,\ Okinawa";
$areanames{en}->{819809} = "Yaeyama\ District\,\ Okinawa";
$areanames{en}->{819822} = "Nobeoka\,\ Miyazaki";
$areanames{en}->{819823} = "Nobeoka\,\ Miyazaki";
$areanames{en}->{819824} = "Nobeoka\,\ Miyazaki";
$areanames{en}->{819825} = "Hyuga\,\ Miyazaki";
$areanames{en}->{819826} = "Hyuga\,\ Miyazaki";
$areanames{en}->{819827} = "Takachiho\,\ Miyazaki";
$areanames{en}->{819828} = "Takachiho\,\ Miyazaki";
$areanames{en}->{8198290} = "Nobeoka\,\ Miyazaki";
$areanames{en}->{8198291} = "Nobeoka\,\ Miyazaki";
$areanames{en}->{8198292} = "Nobeoka\,\ Miyazaki";
$areanames{en}->{8198293} = "Nobeoka\,\ Miyazaki";
$areanames{en}->{8198294} = "Nobeoka\,\ Miyazaki";
$areanames{en}->{8198295} = "Hyuga\,\ Miyazaki";
$areanames{en}->{8198296} = "Hyuga\,\ Miyazaki";
$areanames{en}->{8198297} = "Hyuga\,\ Miyazaki";
$areanames{en}->{8198298} = "Hyuga\,\ Miyazaki";
$areanames{en}->{8198299} = "Hyuga\,\ Miyazaki";
$areanames{en}->{81983} = "Takanabe\,\ Miyazaki";
$areanames{en}->{81984} = "Kobayashi\,\ Miyazaki";
$areanames{en}->{81985} = "Miyazaki\,\ Miyazaki";
$areanames{en}->{81986} = "Miyakonojo\,\ Miyazaki";
$areanames{en}->{81987} = "Nichinan\,\ Miyazaki";
$areanames{en}->{81988} = "Naha\,\ Okinawa";
$areanames{en}->{81989} = "Naha\,\ Okinawa";
$areanames{en}->{81992} = "Kagoshima\,\ Kagoshima";
$areanames{en}->{819932} = "Ibusuki\,\ Kagoshima";
$areanames{en}->{819933} = "Ibusuki\,\ Kagoshima";
$areanames{en}->{8199331} = "Kagoshima\,\ Kagoshima";
$areanames{en}->{819934} = "Ibusuki\,\ Kagoshima";
$areanames{en}->{8199343} = "Kagoshima\,\ Kagoshima";
$areanames{en}->{8199345} = "Kagoshima\,\ Kagoshima";
$areanames{en}->{8199347} = "Kagoshima\,\ Kagoshima";
$areanames{en}->{819935} = "Kaseda\,\ Kagoshima";
$areanames{en}->{819936} = "Kaseda\,\ Kagoshima";
$areanames{en}->{819937} = "Kaseda\,\ Kagoshima";
$areanames{en}->{819938} = "Kaseda\,\ Kagoshima";
$areanames{en}->{819940} = "Shibushi\,\ Kagoshima";
$areanames{en}->{819943} = "Kanoya\,\ Kagoshima";
$areanames{en}->{819944} = "Kanoya\,\ Kagoshima";
$areanames{en}->{819945} = "Kanoya\,\ Kagoshima";
$areanames{en}->{819946} = "Kanoya\,\ Kagoshima";
$areanames{en}->{819947} = "Shibushi\,\ Kagoshima";
$areanames{en}->{819948} = "Shibushi\,\ Kagoshima";
$areanames{en}->{819952} = "Okuchi\,\ Kagoshima";
$areanames{en}->{819953} = "Okuchi\,\ Kagoshima";
$areanames{en}->{819954} = "Kajiki\,\ Kagoshima";
$areanames{en}->{819955} = "Kajiki\,\ Kagoshima";
$areanames{en}->{819956} = "Kajiki\,\ Kagoshima";
$areanames{en}->{819957} = "Kajiki\,\ Kagoshima";
$areanames{en}->{819962} = "Satsumasendai\,\ Kagoshima";
$areanames{en}->{819963} = "Satsumasendai\,\ Kagoshima";
$areanames{en}->{819964} = "Satsumasendai\,\ Kagoshima";
$areanames{en}->{819965} = "Satsumasendai\,\ Kagoshima";
$areanames{en}->{819966} = "Izumi\,\ Kagoshima";
$areanames{en}->{819967} = "Izumi\,\ Kagoshima";
$areanames{en}->{819968} = "Izumi\,\ Kagoshima";
$areanames{en}->{819974} = "Yakushima\,\ Kagoshima";
$areanames{en}->{819975} = "Naze\,\ Kagoshima";
$areanames{en}->{819976} = "Naze\,\ Kagoshima";
$areanames{en}->{819977} = "Setouchi\,\ Kagoshima";
$areanames{en}->{819978} = "Tokunoshima\,\ Kagoshima";
$areanames{en}->{819979} = "Tokunoshima\,\ Kagoshima";
$areanames{en}->{81998} = "Kagoshima\,\ Kagoshima";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+81|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;