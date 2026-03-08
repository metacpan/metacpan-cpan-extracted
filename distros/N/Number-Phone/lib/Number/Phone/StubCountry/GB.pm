# automatically generated file, don't edit



# Copyright 2026 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::GB;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20260306161712;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '8001111',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '845464',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '800',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            1(?:
              3873|
              5(?:
                242|
                39[4-6]
              )|
              (?:
                697|
                768
              )[347]|
              9467
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{5})(\\d{4,5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            1(?:
              [2-69][02-9]|
              [78]
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4})(\\d{5,6})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [25]|
            7(?:
              0|
              6(?:
                [03-9]|
                2[356]
              )
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '7',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4})(\\d{6})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[1389]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1(?:
              1(?:
                3(?:
                  [0-58]\\d\\d|
                  73[0-5]
                )|
                4(?:
                  (?:
                    [0-5]\\d|
                    70
                  )\\d|
                  69[7-9]
                )|
                (?:
                  (?:
                    5[0-26-9]|
                    [78][0-49]
                  )\\d|
                  6(?:
                    [0-4]\\d|
                    5[01]
                  )
                )\\d
              )|
              (?:
                2(?:
                  (?:
                    0[024-9]|
                    2[3-9]|
                    3[3-79]|
                    4[1-689]|
                    [58][02-9]|
                    6[0-47-9]|
                    7[013-9]|
                    9\\d
                  )\\d|
                  1(?:
                    [0-7]\\d|
                    8[0-3]
                  )
                )|
                (?:
                  3(?:
                    0\\d|
                    1[0-8]|
                    [25][02-9]|
                    3[02-579]|
                    [468][0-46-9]|
                    7[1-35-79]|
                    9[2-578]
                  )|
                  4(?:
                    0[03-9]|
                    [137]\\d|
                    [28][02-57-9]|
                    4[02-69]|
                    5[0-8]|
                    [69][0-79]
                  )|
                  5(?:
                    0[1-35-9]|
                    [16]\\d|
                    2[024-9]|
                    3[015689]|
                    4[02-9]|
                    5[03-9]|
                    7[0-35-9]|
                    8[0-468]|
                    9[0-57-9]
                  )|
                  6(?:
                    0[034689]|
                    1\\d|
                    2[0-35689]|
                    [38][013-9]|
                    4[1-467]|
                    5[0-69]|
                    6[13-9]|
                    7[0-8]|
                    9[0-24578]
                  )|
                  7(?:
                    0[0246-9]|
                    2\\d|
                    3[0236-8]|
                    4[03-9]|
                    5[0-46-9]|
                    6[013-9]|
                    7[0-35-9]|
                    8[024-9]|
                    9[02-9]
                  )|
                  8(?:
                    0[35-9]|
                    2[1-57-9]|
                    3[02-578]|
                    4[0-578]|
                    5[124-9]|
                    6[2-69]|
                    7\\d|
                    8[02-9]|
                    9[02569]
                  )|
                  9(?:
                    0[02-589]|
                    [18]\\d|
                    2[02-689]|
                    3[1-57-9]|
                    4[2-9]|
                    5[0-579]|
                    6[2-47-9]|
                    7[0-24578]|
                    9[2-57]
                  )
                )\\d
              )\\d
            )|
            2(?:
              0[013478]|
              3[0189]|
              4[017]|
              8[0-46-9]|
              9[0-2]
            )\\d{3}
          )\\d{4}|
          1(?:
            2(?:
              0(?:
                46[1-4]|
                87[2-9]
              )|
              545[1-79]|
              76(?:
                2\\d|
                3[1-8]|
                6[1-6]
              )|
              9(?:
                7(?:
                  2[0-4]|
                  3[2-5]
                )|
                8(?:
                  2[2-8]|
                  7[0-47-9]|
                  8[3-5]
                )
              )
            )|
            3(?:
              6(?:
                38[2-5]|
                47[23]
              )|
              8(?:
                47[04-9]|
                64[0157-9]
              )
            )|
            4(?:
              044[1-7]|
              20(?:
                2[23]|
                8\\d
              )|
              6(?:
                0(?:
                  30|
                  5[2-57]|
                  6[1-8]|
                  7[2-8]
                )|
                140
              )|
              8(?:
                052|
                87[1-3]
              )
            )|
            5(?:
              2(?:
                4(?:
                  3[2-79]|
                  6\\d
                )|
                76\\d
              )|
              6(?:
                26[06-9]|
                686
              )
            )|
            6(?:
              06(?:
                4\\d|
                7[4-79]
              )|
              295[5-7]|
              35[34]\\d|
              47(?:
                24|
                61
              )|
              59(?:
                5[08]|
                6[67]|
                74
              )|
              9(?:
                55[0-4]|
                77[23]
              )
            )|
            7(?:
              26(?:
                6[13-9]|
                7[0-7]
              )|
              (?:
                442|
                688
              )\\d|
              50(?:
                2[0-3]|
                [3-68]2|
                76
              )
            )|
            8(?:
              27[56]\\d|
              37(?:
                5[2-5]|
                8[239]
              )|
              843[2-58]
            )|
            9(?:
              0(?:
                0(?:
                  6[1-8]|
                  85
                )|
                52\\d
              )|
              3583|
              4(?:
                66[1-8]|
                9(?:
                  2[01]|
                  81
                )
              )|
              63(?:
                23|
                3[1-4]
              )|
              9561
            )
          )\\d{3}
        ',
                'geographic' => '
          (?:
            1(?:
              1(?:
                3(?:
                  [0-58]\\d\\d|
                  73[0-5]
                )|
                4(?:
                  (?:
                    [0-5]\\d|
                    70
                  )\\d|
                  69[7-9]
                )|
                (?:
                  (?:
                    5[0-26-9]|
                    [78][0-49]
                  )\\d|
                  6(?:
                    [0-4]\\d|
                    5[01]
                  )
                )\\d
              )|
              (?:
                2(?:
                  (?:
                    0[024-9]|
                    2[3-9]|
                    3[3-79]|
                    4[1-689]|
                    [58][02-9]|
                    6[0-47-9]|
                    7[013-9]|
                    9\\d
                  )\\d|
                  1(?:
                    [0-7]\\d|
                    8[0-3]
                  )
                )|
                (?:
                  3(?:
                    0\\d|
                    1[0-8]|
                    [25][02-9]|
                    3[02-579]|
                    [468][0-46-9]|
                    7[1-35-79]|
                    9[2-578]
                  )|
                  4(?:
                    0[03-9]|
                    [137]\\d|
                    [28][02-57-9]|
                    4[02-69]|
                    5[0-8]|
                    [69][0-79]
                  )|
                  5(?:
                    0[1-35-9]|
                    [16]\\d|
                    2[024-9]|
                    3[015689]|
                    4[02-9]|
                    5[03-9]|
                    7[0-35-9]|
                    8[0-468]|
                    9[0-57-9]
                  )|
                  6(?:
                    0[034689]|
                    1\\d|
                    2[0-35689]|
                    [38][013-9]|
                    4[1-467]|
                    5[0-69]|
                    6[13-9]|
                    7[0-8]|
                    9[0-24578]
                  )|
                  7(?:
                    0[0246-9]|
                    2\\d|
                    3[0236-8]|
                    4[03-9]|
                    5[0-46-9]|
                    6[013-9]|
                    7[0-35-9]|
                    8[024-9]|
                    9[02-9]
                  )|
                  8(?:
                    0[35-9]|
                    2[1-57-9]|
                    3[02-578]|
                    4[0-578]|
                    5[124-9]|
                    6[2-69]|
                    7\\d|
                    8[02-9]|
                    9[02569]
                  )|
                  9(?:
                    0[02-589]|
                    [18]\\d|
                    2[02-689]|
                    3[1-57-9]|
                    4[2-9]|
                    5[0-579]|
                    6[2-47-9]|
                    7[0-24578]|
                    9[2-57]
                  )
                )\\d
              )\\d
            )|
            2(?:
              0[013478]|
              3[0189]|
              4[017]|
              8[0-46-9]|
              9[0-2]
            )\\d{3}
          )\\d{4}|
          1(?:
            2(?:
              0(?:
                46[1-4]|
                87[2-9]
              )|
              545[1-79]|
              76(?:
                2\\d|
                3[1-8]|
                6[1-6]
              )|
              9(?:
                7(?:
                  2[0-4]|
                  3[2-5]
                )|
                8(?:
                  2[2-8]|
                  7[0-47-9]|
                  8[3-5]
                )
              )
            )|
            3(?:
              6(?:
                38[2-5]|
                47[23]
              )|
              8(?:
                47[04-9]|
                64[0157-9]
              )
            )|
            4(?:
              044[1-7]|
              20(?:
                2[23]|
                8\\d
              )|
              6(?:
                0(?:
                  30|
                  5[2-57]|
                  6[1-8]|
                  7[2-8]
                )|
                140
              )|
              8(?:
                052|
                87[1-3]
              )
            )|
            5(?:
              2(?:
                4(?:
                  3[2-79]|
                  6\\d
                )|
                76\\d
              )|
              6(?:
                26[06-9]|
                686
              )
            )|
            6(?:
              06(?:
                4\\d|
                7[4-79]
              )|
              295[5-7]|
              35[34]\\d|
              47(?:
                24|
                61
              )|
              59(?:
                5[08]|
                6[67]|
                74
              )|
              9(?:
                55[0-4]|
                77[23]
              )
            )|
            7(?:
              26(?:
                6[13-9]|
                7[0-7]
              )|
              (?:
                442|
                688
              )\\d|
              50(?:
                2[0-3]|
                [3-68]2|
                76
              )
            )|
            8(?:
              27[56]\\d|
              37(?:
                5[2-5]|
                8[239]
              )|
              843[2-58]
            )|
            9(?:
              0(?:
                0(?:
                  6[1-8]|
                  85
                )|
                52\\d
              )|
              3583|
              4(?:
                66[1-8]|
                9(?:
                  2[01]|
                  81
                )
              )|
              63(?:
                23|
                3[1-4]
              )|
              9561
            )
          )\\d{3}
        ',
                'mobile' => '
          7(?:
            457[0-57-9]|
            700[01]|
            911[028]
          )\\d{5}|
          7(?:
            [1-3]\\d\\d|
            4(?:
              [0-46-9]\\d|
              5[0-689]
            )|
            5(?:
              0[0-8]|
              [13-9]\\d|
              2[0-35-9]
            )|
            7(?:
              0[1-9]|
              [1-7]\\d|
              8[02-9]|
              9[0-689]
            )|
            8(?:
              [014-9]\\d|
              [23][0-8]
            )|
            9(?:
              [024-9]\\d|
              1[02-9]|
              3[0-689]
            )
          )\\d{6}
        ',
                'pager' => '
          76(?:
            464|
            652
          )\\d{5}|
          76(?:
            0[0-28]|
            2[356]|
            34|
            4[01347]|
            5[49]|
            6[0-369]|
            77|
            8[14]|
            9[139]
          )\\d{6}
        ',
                'personal_number' => '70\\d{8}',
                'specialrate' => '(
          (?:
            8(?:
              4[2-5]|
              7[0-3]
            )|
            9(?:
              [01]\\d|
              8[2-49]
            )
          )\\d{7}|
          845464\\d
        )|(
          (?:
            3[0347]|
            55
          )\\d{8}
        )',
                'toll_free' => '
          80[08]\\d{7}|
          800\\d{6}|
          8001111
        ',
                'voip' => '56\\d{8}'
              };
my %areanames = ();
$areanames{en} = {"4418514", "Great\ Bernera",
"441259", "Alloa",
"4414232", "Harrogate",
"441425", "Ringwood",
"441520", "Lochcarron",
"441757", "Selby",
"441556", "Castle\ Douglas",
"441144", "Sheffield",
"4414231", "Harrogate\/Boroughbridge",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441953", "Wymondham",
"441461", "Gretna",
"441931", "Shap",
"4418903", "Coldstream",
"441224", "Aberdeen",
"441879", "Scarinish",
"441915", "Sunderland",
"441377", "Driffield",
"441406", "Holbeach",
"4418477", "Tongue",
"441349", "Dingwall",
"441866", "Kilchrenan",
"4413393", "Aboyne",
"441663", "New\ Mills",
"441598", "Lynton",
"441692", "North\ Walsham",
"4419752", "Alford\ \(Aberdeen\)",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441582", "Luton",
"441785", "Stafford",
"441984", "Watchet\ \(Williton\)",
"441294", "Ardrossan",
"441569", "Stonehaven",
"44116", "Leicester",
"441824", "Ruthin",
"441279", "Bishops\ Stortford",
"441576", "Lockerbie",
"441777", "Retford",
"442884", "Northern\ Ireland",
"441749", "Shepton\ Mallet",
"441528", "Laggan",
"44114703", "Sheffield",
"441622", "Maidstone",
"441443", "Pontypridd",
"441859", "Harris",
"441357", "Strathaven",
"441495", "Pontypool",
"4418905", "Ayton",
"441590", "Lymington",
"4414374", "Clynderwen\ \(Clunderwen\)",
"4413395", "Aboyne",
"441641", "Strathy",
"441736", "Penzance",
"44151", "Liverpool",
"441506", "Bathgate",
"441707", "Welwyn\ Garden\ City",
"441910", "Tyneside\/Durham\/Sunderland",
"4416860", "Newtown\/Llanidloes",
"441209", "Redruth",
"4412290", "Barrow\-in\-Furness\/Millom",
"441271", "Barnstaple",
"441380", "Devizes",
"44114702", "Sheffield",
"4418474", "Thurso",
"441903", "Worthing",
"441561", "Laurencekirk",
"441833", "Barnard\ Castle",
"441636", "Newark\-on\-Trent",
"4418517", "Stornoway",
"441685", "Merthyr\ Tydfil",
"441788", "Rugby",
"441363", "Crediton",
"441392", "Exeter",
"441677", "Bedale",
"441420", "Alton",
"441456", "Glenurquhart",
"441525", "Leighton\ Buzzard",
"441722", "Salisbury",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"4419641", "Hornsea\/Patrington",
"441946", "Whitehaven",
"442867", "Lisnaskea",
"441388", "Bishop\ Auckland",
"4419467", "Gosforth",
"441967", "Strontian",
"44141", "Glasgow",
"442846", "Northern\ Ireland",
"4419642", "Hornsea",
"4414342", "Bellingham",
"4414377", "Haverfordwest",
"441918", "Tyneside",
"441322", "Dartford",
"441543", "Cannock",
"441490", "Corwen",
"441763", "Royston",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441792", "Swansea",
"4412296", "Barrow\-in\-Furness",
"441939", "Wem",
"441469", "Killingholme",
"441428", "Haslemere",
"441809", "Tomdoun",
"441307", "Forfar",
"441476", "Grantham",
"4413398", "Aboyne",
"441341", "Barmouth",
"441871", "Castlebay",
"4416866", "Newtown",
"441233", "Ashford\ \(Kent\)",
"441780", "Stamford",
"4418908", "Coldstream",
"441482", "Kingston\-upon\-Hull",
"4416863", "Llanidloes",
"441858", "Market\ Harborough",
"441340", "Craigellachie\ \(Aberlour\)",
"441870", "Isle\ of\ Benbecula",
"441554", "Llanelli",
"441205", "Boston",
"441146", "Sheffield",
"441952", "Telford",
"441334", "St\ Andrews",
"4412293", "Millom",
"4418519", "Great\ Bernera",
"441689", "Orpington",
"441491", "Henley\-on\-Thames",
"441226", "Barnsley",
"441568", "Leominster",
"441250", "Blairgowrie",
"441404", "Honiton",
"441278", "Bridgwater",
"441896", "Galashiels",
"441748", "Richmond",
"441864", "Abington\ \(Crawford\)",
"441529", "Sleaford",
"44247", "Coventry",
"4416865", "Newtown",
"441972", "Glenborrodale",
"441583", "Carradale",
"4420", "London",
"441623", "Mansfield",
"441986", "Bungay",
"441878", "Lochboisdale",
"441296", "Aylesbury",
"441348", "Fishguard",
"4412295", "Barrow\-in\-Furness",
"442886", "Cookstown",
"441599", "Kyle",
"441264", "Andover",
"441381", "Fortrose",
"441270", "Crewe",
"441465", "Girvan",
"441935", "Yeovil",
"441560", "Moscow",
"441258", "Blandford",
"441805", "Torrington",
"441740", "Sedgefield",
"441442", "Hemel\ Hempstead",
"4414379", "Haverfordwest",
"441911", "Tyneside\/Durham\/Sunderland",
"4415072", "Spilsby\ \(Horncastle\)",
"441938", "Welshpool",
"441255", "Clacton\-on\-Sea",
"441808", "Tomatin",
"441429", "Hartlepool",
"4418479", "Tongue",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"442838", "Portadown",
"441832", "Clopton",
"44286", "Northern\ Ireland",
"4416973", "Wigton",
"441591", "Llanwrtyd\ Wells",
"441902", "Wolverhampton",
"441634", "Medway",
"4418900", "Coldstream\/Ayton",
"441887", "Aberfeldy",
"441389", "Dumbarton",
"442827", "Ballymoney",
"441723", "Scarborough",
"4413390", "Aboyne\/Ballater",
"441875", "Tranent",
"441919", "Durham",
"441200", "Clitheroe",
"441362", "Dereham",
"441454", "Chipping\ Sodbury",
"441944", "West\ Heslerton",
"4413396", "Ballater",
"441287", "Guisborough",
"441997", "Strathpeffer",
"442844", "Downpatrick",
"441789", "Stratford\-upon\-Avon",
"4412298", "Barrow\-in\-Furness",
"442897", "Saintfield",
"441793", "Swindon",
"441460", "Chard",
"441565", "Knutsford",
"4418906", "Ayton",
"441275", "Clevedon",
"4416868", "Newtown",
"441542", "Keith",
"441745", "Rhyl",
"442830", "Newry",
"441323", "Eastbourne",
"441855", "Ballachulish",
"441499", "Inveraray",
"441474", "Gravesend",
"441208", "Bodmin",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441483", "Guildford",
"441955", "Wick",
"441621", "Maldon",
"4414237", "Harrogate",
"4414308", "Market\ Weighton",
"441360", "Killearn",
"441754", "Skegness",
"441581", "New\ Luce",
"441202", "Bournemouth",
"441768", "Penrith",
"441665", "Alnwick",
"441227", "Canterbury",
"4418472", "Thurso",
"441844", "Thame",
"4417687", "Keswick",
"4418471", "Thurso\/Tongue",
"441642", "Middlesbrough",
"4415079", "Alford\ \(Lincs\)",
"441548", "Kingsbridge",
"441913", "Durham",
"441729", "Settle",
"441830", "Kirkwhelpington",
"441383", "Dunfermline",
"441900", "Workington",
"441297", "Axminster",
"441987", "Ebbsfleet",
"441329", "Fareham",
"441244", "Chester",
"441827", "Tamworth",
"442887", "Dungannon",
"441368", "Dunbar",
"441799", "Saffron\ Walden",
"4419757", "Strathdon",
"441838", "Dalmally",
"441691", "Oswestry",
"441908", "Milton\ Keynes",
"441534", "Jersey",
"441489", "Bishops\ Waltham",
"441604", "Northampton",
"441493", "Great\ Yarmouth",
"441760", "Swaffham",
"441932", "Weybridge",
"441462", "Hitchin",
"441354", "Chatteris",
"44114709", "Sheffield",
"441445", "Gairloch",
"4419644", "Patrington",
"4414344", "Bellingham",
"441540", "Kingussie",
"4417684", "Pooley\ Bridge",
"4414305", "North\ Cave",
"441835", "St\ Boswells",
"441905", "Worcester",
"44114701", "Sheffield",
"441704", "Southport",
"441252", "Aldershot",
"4413873", "Langholm",
"441872", "Truro",
"441342", "East\ Grinstead",
"441481", "Guernsey",
"441674", "Montrose",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441978", "Wrexham",
"4414234", "Boroughbridge",
"441683", "Moffat",
"441950", "Sandwick",
"441926", "Warwick",
"4418512", "Stornoway",
"442826", "Northern\ Ireland",
"4418511", "Great\ Bernera\/Stornoway",
"4415396", "Sedbergh",
"441562", "Kidderminster",
"441765", "Ripon",
"441668", "Bamburgh",
"441593", "Lybster",
"4414303", "North\ Cave",
"441440", "Haverhill",
"441545", "Llanarth",
"441629", "Matlock",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"4413882", "Stanhope\ \(Eastgate\)",
"441286", "Caernarfon",
"44118", "Reading",
"4414372", "Clynderwen\ \(Clunderwen\)",
"442896", "Belfast",
"4419647", "Patrington",
"4414347", "Hexham",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441235", "Abingdon",
"441970", "Aberystwyth",
"441721", "Peebles",
"442870", "Coleraine",
"441852", "Kilmelford",
"4419754", "Alford\ \(Aberdeen\)",
"441654", "Machynlleth",
"441304", "Dover",
"441337", "Ladybank",
"44131", "Edinburgh",
"4415395", "Grange\-over\-Sands",
"441909", "Worksop",
"441488", "Hungerford",
"441971", "Scourie",
"441557", "Kirkcudbright",
"44114705", "Sheffield",
"441720", "Isles\ of\ Scilly",
"44292", "Cardiff",
"441756", "Skipton",
"441422", "Halifax",
"442871", "Londonderry",
"441328", "Fakenham",
"44241", "Coventry",
"441912", "Tyneside",
"441643", "Minehead",
"441407", "Holyhead",
"441376", "Braintree",
"441798", "Pulborough",
"441695", "Skelmersdale",
"441369", "Dunoon",
"4415074", "Alford\ \(Lincs\)",
"441382", "Dundee",
"4414306", "Market\ Weighton",
"441398", "Dulverton",
"441769", "South\ Molton",
"441246", "Chesterfield",
"441951", "Colonsay",
"441549", "Lairg",
"441776", "Stranraer",
"441577", "Kinross",
"441728", "Saxmundham",
"441625", "Macclesfield",
"441267", "Carmarthen",
"4414300", "North\ Cave\/Market\ Weighton",
"441480", "Huntingdon",
"441782", "Stoke\-on\-Trent",
"4414349", "Bellingham",
"4419649", "Hornsea",
"441239", "Cardigan",
"441661", "Prudhoe",
"441737", "Redhill",
"441536", "Kettering",
"441606", "Northwich",
"441320", "Fort\ Augustus",
"441356", "Brechin",
"44114708", "Sheffield",
"441803", "Torquay",
"44114700", "Sheffield",
"441463", "Inverness",
"441790", "Spilsby",
"441933", "Wellingborough",
"441492", "Colwyn\ Bay",
"441959", "Westerham",
"441761", "Temple\ Cloud",
"44161", "Manchester",
"441637", "Newquay",
"441706", "Rochdale",
"4415077", "Louth",
"441690", "Betws\-y\-Coed",
"441253", "Blackpool",
"441395", "Budleigh\ Salterton",
"441669", "Rothbury",
"441343", "Elgin",
"441676", "Meriden",
"4414239", "Boroughbridge",
"441522", "Lincoln",
"441725", "Rockbourne",
"441628", "Maidenhead",
"441457", "Glossop",
"441873", "Abergavenny",
"441884", "Tiverton",
"441924", "Wakefield",
"441588", "Bishops\ Castle",
"442824", "Northern\ Ireland",
"441325", "Darlington",
"441743", "Shrewsbury",
"441273", "Brighton",
"441592", "Kirkcaldy",
"441795", "Sittingbourne",
"441698", "Motherwell",
"441563", "Kilmarnock",
"442866", "Enniskillen",
"441947", "Whitby",
"441284", "Bury\ St\ Edmunds",
"441994", "St\ Clears",
"442879", "Magherafelt",
"442847", "Northern\ Ireland",
"441436", "Helensburgh",
"442894", "Antrim",
"441361", "Duns",
"4419759", "Alford\ \(Aberdeen\)",
"441485", "Hunstanton",
"441580", "Cranbrook",
"441656", "Bridgend",
"441620", "North\ Berwick",
"441477", "Holmes\ Chapel",
"441306", "Dorking",
"441449", "Stowmarket",
"441242", "Cheltenham",
"441458", "Glastonbury",
"441772", "Preston",
"441575", "Kirriemuir",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441786", "Stirling",
"441141", "Sheffield",
"442840", "Banbridge",
"441638", "Newmarket",
"441464", "Insch",
"441934", "Weston\-super\-Mare",
"441352", "Mold",
"441508", "Brooke",
"4418476", "Tongue",
"441496", "Port\ Ellen",
"4412294", "Barrow\-in\-Furness",
"441291", "Chepstow",
"441981", "Wormbridge",
"441821", "Kinrossie",
"4418470", "Thurso\/Tongue",
"441335", "Ashbourne",
"442881", "Newtownstewart",
"44287", "Northern\ Ireland",
"4416864", "Llanidloes",
"441204", "Bolton",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441450", "Hawick",
"441555", "Lanark",
"441752", "Plymouth",
"441372", "Esher",
"441405", "Goole",
"441916", "Tyneside",
"441842", "Thetford",
"441697", "Brampton",
"4418909", "Ayton",
"441865", "Oxford",
"441644", "New\ Galloway",
"441386", "Evesham",
"441948", "Whitchurch",
"442848", "Northern\ Ireland",
"4413399", "Ballater",
"441630", "Market\ Drayton",
"441274", "Bradford",
"441829", "Tarporley",
"441408", "Golspie",
"441564", "Lapworth",
"441989", "Ross\-on\-Wye",
"441299", "Bewdley",
"441327", "Daventry",
"441797", "Rye",
"441744", "St\ Helens",
"442889", "Fivemiletown",
"44280", "Northern\ Ireland",
"442893", "Ballyclare",
"441945", "Wisbech",
"442845", "Northern\ Ireland",
"441432", "Hereford",
"441962", "Winchester",
"441993", "Witney",
"441283", "Burton\-on\-Trent",
"441730", "Petersfield",
"4418516", "Great\ Bernera",
"441487", "Warboys",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441854", "Ullapool",
"441570", "Lampeter",
"441302", "Doncaster",
"441475", "Greenock",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441652", "Brigg",
"441260", "Congleton",
"441558", "Llandeilo",
"44114704", "Sheffield",
"441635", "Newbury",
"441738", "Perth",
"4416974", "Raughton\ Head",
"4414376", "Haverfordwest",
"4418510", "Great\ Bernera\/Stornoway",
"441254", "Blackburn",
"441702", "Southend\-on\-Sea",
"441505", "Johnstone",
"441400", "Honington",
"4412297", "Millom",
"441899", "Biggar",
"441344", "Bracknell",
"441874", "Brecon",
"441397", "Fort\ William",
"441455", "Hinckley",
"441526", "Martin",
"441268", "Basildon",
"441727", "St\ Albans",
"441550", "Llandovery",
"441578", "Lauder",
"441672", "Marlborough",
"441330", "Banchory",
"442823", "Northern\ Ireland",
"4416867", "Llanidloes",
"441883", "Caterham",
"441923", "Watford",
"441825", "Uckfield",
"441773", "Ripley",
"441295", "Banbury",
"441985", "Warminster",
"442885", "Ballygawley",
"441243", "Chichester",
"441949", "Whatton",
"441977", "Pontefract",
"4418478", "Thurso",
"4418515", "Stornoway",
"442877", "Limavady",
"441784", "Staines",
"442849", "Northern\ Ireland",
"4414301", "North\ Cave\/Market\ Weighton",
"4414302", "North\ Cave",
"441466", "Huntly",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441479", "Grantown\-on\-Spey",
"441603", "Norwich",
"441353", "Ely",
"441494", "High\ Wycombe",
"441806", "Shetland",
"4416869", "Newtown",
"441957", "Mid\ Yell",
"441639", "Neath",
"441571", "Lochinver",
"441261", "Banff",
"441753", "Slough",
"441509", "Loughborough",
"441206", "Colchester",
"4418513", "Stornoway",
"441145", "Sheffield",
"4412299", "Millom",
"441424", "Hastings",
"441895", "Uxbridge",
"4413394", "Ballater",
"441914", "Tyneside",
"441667", "Nairn",
"441225", "Bath",
"441843", "Thanet",
"441646", "Milford\ Haven",
"441373", "Frome",
"4418904", "Coldstream",
"441384", "Dudley",
"4414375", "Clynderwen\ \(Clunderwen\)",
"4413885", "Stanhope\ \(Eastgate\)",
"441276", "Camberley",
"441566", "Launceston",
"441228", "Carlisle",
"441767", "Sandy",
"441269", "Ammanford",
"441594", "Lydney",
"441547", "Knighton",
"441746", "Bridgnorth",
"441579", "Liskeard",
"4418518", "Stornoway",
"4418475", "Thurso",
"441631", "Oban",
"44117", "Bristol",
"441282", "Burnley",
"441992", "Lea\ Valley",
"441501", "Harthill",
"441433", "Hathersage",
"441963", "Wincanton",
"442892", "Lisburn",
"441237", "Bideford",
"44121", "Birmingham",
"441451", "Stow\-on\-the\-Wold",
"441653", "Malton",
"441290", "Cumnock",
"441980", "Amesbury",
"441856", "Orkney",
"441303", "Folkestone",
"442880", "Carrickmore",
"441837", "Okehampton",
"4413397", "Ballater",
"44291", "Cardiff",
"4418473", "Thurso",
"4418907", "Ayton",
"441256", "Basingstoke",
"442841", "Rostrevor",
"44115", "Nottingham",
"441559", "Llandysul",
"44238", "Southampton",
"441828", "Coupar\ Angus",
"441409", "Holsworthy",
"441346", "Fraserburgh",
"4414378", "Haverfordwest",
"441673", "Market\ Rasen",
"441876", "Lochmaddy",
"441988", "Wigtown",
"441298", "Buxton",
"441524", "Lancaster",
"441367", "Faringdon",
"442888", "Northern\ Ireland",
"441140", "Sheffield",
"441869", "Bicester",
"441922", "Walsall",
"441882", "Kinloch\ Rannoch",
"442822", "Northern\ Ireland",
"441684", "Malvern",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441928", "Runcorn",
"441888", "Turriff",
"441751", "Pickering",
"442828", "Larne",
"441439", "Helmsley",
"441969", "Leyburn",
"441584", "Ludlow",
"441573", "Kelso",
"441822", "Tavistock",
"4414236", "Harrogate",
"441982", "Builth\ Wells",
"441292", "Ayr",
"441263", "Cromer",
"441624", "Isle\ of\ Man",
"4415394", "Hawkshead",
"442882", "Omagh",
"441467", "Inverurie",
"441937", "Wetherby",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441309", "Forres",
"442837", "Armagh",
"441446", "Barry",
"44281", "Northern\ Ireland",
"441807", "Ballindalloch",
"441659", "Sanquhar",
"4415075", "Spilsby\ \(Horncastle\)",
"441841", "Newquay\ \(Padstow\)",
"441280", "Buckingham",
"441733", "Peterborough",
"441371", "Great\ Dunmow",
"442890", "Belfast",
"441553", "Kings\ Lynn",
"441709", "Rotherham",
"441142", "Sheffield",
"441207", "Consett",
"442310", "Portsmouth",
"441880", "Tarbert",
"441241", "Arbroath",
"4419756", "Strathdon",
"441920", "Ware",
"44239", "Portsmouth",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441771", "Maud",
"442820", "Ballycastle",
"4414230", "Harrogate\/Boroughbridge",
"441288", "Bude",
"442898", "Belfast",
"4415073", "Louth",
"441863", "Ardgay",
"441892", "Tunbridge\ Wells",
"441666", "Malmesbury",
"441694", "Church\ Stretton",
"441531", "Ledbury",
"441403", "Horsham",
"441647", "Moretonhampstead",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441285", "Cirencester",
"441995", "Garstang",
"4414309", "Market\ Weighton",
"442895", "Belfast",
"441943", "Guiseley",
"441249", "Chippenham",
"441277", "Brentwood",
"441766", "Porthmadog",
"441567", "Killin",
"441324", "Falkirk",
"441794", "Romsey",
"441779", "Peterhead",
"441747", "Shaftesbury",
"441546", "Lochgilphead",
"441359", "Pakenham",
"441609", "Northallerton",
"441473", "Ipswich",
"441857", "Sanday",
"4419640", "Hornsea\/Patrington",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441236", "Coatbridge",
"4415078", "Alford\ \(Lincs\)",
"44113", "Leeds",
"441671", "Newton\ Stewart",
"441539", "Kendal",
"441484", "Huddersfield",
"441257", "Coppull",
"441503", "Looe",
"441431", "Helmsdale",
"441759", "Pocklington",
"441633", "Newport",
"4414346", "Hexham",
"4419646", "Patrington",
"441925", "Warrington",
"4416861", "Newtown\/Llanidloes",
"441885", "Pencombe",
"442825", "Ballymena",
"441651", "Oldmeldrum",
"4416862", "Llanidloes",
"441301", "Arrochar",
"441379", "Diss",
"441347", "Easingwold",
"441453", "Dursley",
"441877", "Callander",
"441394", "Felixstowe",
"4412292", "Barrow\-in\-Furness",
"441366", "Downham\ Market",
"441724", "Scunthorpe",
"4412291", "Barrow\-in\-Furness\/Millom",
"441289", "Berwick\-upon\-Tweed",
"441974", "Llanon",
"442899", "Northern\ Ireland",
"441787", "Sudbury",
"441586", "Campbeltown",
"442883", "Northern\ Ireland",
"441245", "Chelmsford",
"44114707", "Sheffield",
"441650", "Cemmaes\ Road",
"441262", "Bridlington",
"441626", "Newton\ Abbot",
"441293", "Crawley",
"441983", "Isle\ of\ Wight",
"441823", "Taunton",
"441572", "Oakham",
"441775", "Spalding",
"441300", "Cerne\ Abbas",
"441678", "Bala",
"441355", "East\ Kilbride",
"4419643", "Patrington",
"4414343", "Haltwhistle",
"441708", "Romford",
"441444", "Haywards\ Heath",
"441497", "Hay\-on\-Wye",
"441732", "Sevenoaks",
"441535", "Keighley",
"4414238", "Harrogate",
"4414307", "Market\ Weighton",
"441143", "Sheffield",
"441308", "Bridport",
"441670", "Morpeth",
"441427", "Gainsborough",
"441954", "Madingley",
"441332", "Derby",
"441929", "Wareham",
"441387", "Dumfries",
"442868", "Kesh",
"4414345", "Haltwhistle",
"4419645", "Hornsea",
"441889", "Rugeley",
"442829", "Kilrea",
"441968", "Penicuik",
"441438", "Stevenage",
"441375", "Grays\ Thurrock",
"441700", "Rothesay",
"441845", "Thirsk",
"441664", "Melton\ Mowbray",
"441917", "Sunderland",
"441223", "Cambridge",
"4419758", "Strathdon",
"44283", "Northern\ Ireland",
"441862", "Tain",
"441942", "Wigan",
"441530", "Coalville",
"442842", "Kircubbin",
"441435", "Heathfield",
"441600", "Monmouth",
"441326", "Falmouth",
"4415076", "Louth",
"441848", "Thornhill",
"441350", "Dunkeld",
"441764", "Crieff",
"441796", "Pitlochry",
"441597", "Llandrindod\ Wells",
"441544", "Kington",
"4414304", "North\ Cave",
"441472", "Grimsby",
"4414235", "Harrogate",
"441770", "Isle\ of\ Arran",
"441305", "Dorchester",
"441655", "Maybole",
"442821", "Martinstown",
"4419753", "Strathdon",
"441758", "Pwllheli",
"441234", "Bedford",
"442311", "Southampton",
"441840", "Camelford",
"441358", "Ellon",
"441502", "Lowestoft",
"4418902", "Coldstream",
"441608", "Chipping\ Norton",
"4418901", "Coldstream\/Ayton",
"442891", "Bangor\ \(Co\.\ Down\)",
"441834", "Narberth",
"4413392", "Aboyne",
"441538", "Ipstones",
"4417683", "Appleby",
"4413391", "Aboyne\/Ballater",
"441904", "York",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"4414233", "Boroughbridge",
"4419755", "Alford\ \(Aberdeen\)",
"441687", "Mallaig",
"4419648", "Hornsea",
"4414348", "Hexham",
"441248", "Bangor\ \(Gwynedd\)",
"441726", "St\ Austell",
"441750", "Selkirk",
"441527", "Redditch",
"441364", "Ashburton",
"4415242", "Hornby",
"441452", "Gloucester",
"441778", "Bourne",
"441675", "Coleshill",};
my $timezones = {
               '' => [
                       'Europe/Guernsey',
                       'Europe/Isle_of_Man',
                       'Europe/Jersey',
                       'Europe/London'
                     ],
               '1' => [
                        'Europe/London'
                      ],
               '1481' => [
                           'Europe/Guernsey'
                         ],
               '1534' => [
                           'Europe/Jersey'
                         ],
               '1624' => [
                           'Europe/Isle_of_Man'
                         ],
               '2' => [
                        'Europe/London'
                      ],
               '3' => [
                        'Europe/Guernsey',
                        'Europe/Isle_of_Man',
                        'Europe/London'
                      ],
               '5' => [
                        'Europe/Guernsey',
                        'Europe/Isle_of_Man',
                        'Europe/London'
                      ],
               '70' => [
                         'Europe/Guernsey',
                         'Europe/Isle_of_Man',
                         'Europe/London'
                       ],
               '71' => [
                         'Europe/Guernsey',
                         'Europe/Isle_of_Man',
                         'Europe/London'
                       ],
               '72' => [
                         'Europe/Guernsey',
                         'Europe/Isle_of_Man',
                         'Europe/London'
                       ],
               '73' => [
                         'Europe/Guernsey',
                         'Europe/Isle_of_Man',
                         'Europe/London'
                       ],
               '74' => [
                         'Europe/Guernsey',
                         'Europe/Isle_of_Man',
                         'Europe/London'
                       ],
               '75' => [
                         'Europe/Guernsey',
                         'Europe/Isle_of_Man',
                         'Europe/London'
                       ],
               '760' => [
                          'Europe/Guernsey',
                          'Europe/Isle_of_Man',
                          'Europe/London'
                        ],
               '762' => [
                          'Europe/Guernsey',
                          'Europe/Isle_of_Man',
                          'Europe/London'
                        ],
               '763' => [
                          'Europe/Guernsey',
                          'Europe/Isle_of_Man',
                          'Europe/London'
                        ],
               '7640' => [
                           'Europe/Guernsey',
                           'Europe/Isle_of_Man',
                           'Europe/London'
                         ],
               '7641' => [
                           'Europe/Guernsey',
                           'Europe/Isle_of_Man',
                           'Europe/London'
                         ],
               '7643' => [
                           'Europe/Guernsey',
                           'Europe/Isle_of_Man',
                           'Europe/London'
                         ],
               '7644' => [
                           'Europe/Guernsey',
                           'Europe/Isle_of_Man',
                           'Europe/London'
                         ],
               '7646' => [
                           'Europe/Guernsey',
                           'Europe/Isle_of_Man',
                           'Europe/London'
                         ],
               '765' => [
                          'Europe/Guernsey',
                          'Europe/Isle_of_Man',
                          'Europe/London'
                        ],
               '766' => [
                          'Europe/Guernsey',
                          'Europe/Isle_of_Man',
                          'Europe/London'
                        ],
               '767' => [
                          'Europe/Guernsey',
                          'Europe/Isle_of_Man',
                          'Europe/London'
                        ],
               '768' => [
                          'Europe/Guernsey',
                          'Europe/Isle_of_Man',
                          'Europe/London'
                        ],
               '7693' => [
                           'Europe/Guernsey',
                           'Europe/Isle_of_Man',
                           'Europe/London'
                         ],
               '7699' => [
                           'Europe/Guernsey',
                           'Europe/Isle_of_Man',
                           'Europe/London'
                         ],
               '77' => [
                         'Europe/Guernsey',
                         'Europe/Isle_of_Man',
                         'Europe/London'
                       ],
               '78' => [
                         'Europe/Guernsey',
                         'Europe/Isle_of_Man',
                         'Europe/London'
                       ],
               '79' => [
                         'Europe/Guernsey',
                         'Europe/Isle_of_Man',
                         'Europe/London'
                       ],
               '8' => [
                        'Europe/Guernsey',
                        'Europe/Isle_of_Man',
                        'Europe/London'
                      ],
               '9' => [
                        'Europe/Guernsey',
                        'Europe/Isle_of_Man',
                        'Europe/London'
                      ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+44|\D)//g;
      my $self = bless({ country_code => '44', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0|180020)//;
      $self = bless({ country_code => '44', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;