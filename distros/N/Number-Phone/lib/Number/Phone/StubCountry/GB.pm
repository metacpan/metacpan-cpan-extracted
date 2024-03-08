# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20240308154351;

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
                  73[0235]
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
                    50
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
                    8[0-2]
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
                  73[0235]
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
                    50
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
                    8[0-2]
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
$areanames{en} = {"441909", "Worksop",
"442879", "Magherafelt",
"441722", "Salisbury",
"441809", "Tomdoun",
"441501", "Harthill",
"441444", "Haywards\ Heath",
"4415072", "Spilsby\ \(Horncastle\)",
"441761", "Temple\ Cloud",
"44131", "Edinburgh",
"441241", "Arbroath",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441825", "Uckfield",
"441943", "Guiseley",
"4413396", "Ballater",
"441366", "Downham\ Market",
"441947", "Whitby",
"441925", "Warrington",
"441664", "Melton\ Mowbray",
"441780", "Stamford",
"441843", "Thanet",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441873", "Abergavenny",
"4418906", "Ayton",
"441282", "Burnley",
"441977", "Pontefract",
"441337", "Ladybank",
"441254", "Blackburn",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441697", "Brampton",
"441877", "Callander",
"441389", "Dumbarton",
"441431", "Helmsdale",
"44113", "Leeds",
"441271", "Barnstaple",
"4414372", "Clynderwen\ \(Clunderwen\)",
"442826", "Northern\ Ireland",
"441474", "Gravesend",
"441428", "Haslemere",
"441357", "Strathaven",
"441234", "Bedford",
"441353", "Ely",
"441296", "Aylesbury",
"441451", "Stow\-on\-the\-Wold",
"441568", "Leominster",
"44115", "Nottingham",
"441584", "Ludlow",
"442849", "Northern\ Ireland",
"441708", "Romford",
"442890", "Belfast",
"441600", "Monmouth",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"4418518", "Stornoway",
"441363", "Crediton",
"4412292", "Barrow\-in\-Furness",
"441422", "Halifax",
"441946", "Whitehaven",
"441367", "Faringdon",
"441702", "Southend\-on\-Sea",
"441829", "Tarporley",
"441744", "St\ Helens",
"4419756", "Strathdon",
"441929", "Wareham",
"44116", "Leicester",
"441562", "Kidderminster",
"441558", "Llandeilo",
"441461", "Gretna",
"441905", "Worcester",
"441570", "Lampeter",
"441264", "Andover",
"441805", "Torrington",
"441288", "Bude",
"4414343", "Haltwhistle",
"4419642", "Hornsea",
"441641", "Strathy",
"4418471", "Thurso\/Tongue",
"441480", "Huntingdon",
"441538", "Ipstones",
"441671", "Newton\ Stewart",
"442827", "Ballymoney",
"442845", "Northern\ Ireland",
"441293", "Crawley",
"4414306", "Market\ Weighton",
"441654", "Machynlleth",
"441540", "Kingussie",
"441356", "Brechin",
"441599", "Kyle",
"441297", "Axminster",
"442823", "Northern\ Ireland",
"4417684", "Pooley\ Bridge",
"441728", "Saxmundham",
"441620", "North\ Berwick",
"441200", "Clitheroe",
"441751", "Pickering",
"441141", "Sheffield",
"441634", "Medway",
"441408", "Golspie",
"441394", "Felixstowe",
"441911", "Tyneside\/Durham\/Sunderland",
"4418510", "Great\ Bernera\/Stornoway",
"441876", "Lochmaddy",
"441698", "Motherwell",
"441790", "Spilsby",
"441878", "Lochboisdale",
"441824", "Ruthin",
"441406", "Holbeach",
"4419649", "Hornsea",
"441978", "Wrexham",
"4419644", "Patrington",
"4413398", "Aboyne",
"441749", "Shepton\ Mallet",
"441924", "Wakefield",
"441665", "Alnwick",
"4418900", "Coldstream\/Ayton",
"441830", "Kirkwhelpington",
"441726", "St\ Austell",
"441445", "Gairloch",
"441427", "Gainsborough",
"441362", "Dereham",
"441358", "Ellon",
"441563", "Kilmarnock",
"4412299", "Millom",
"441707", "Welwyn\ Garden\ City",
"441269", "Ammanford",
"4412294", "Barrow\-in\-Furness",
"441950", "Sandwick",
"441567", "Killin",
"441536", "Kettering",
"442880", "Carrickmore",
"441659", "Sanquhar",
"441594", "Lydney",
"4416861", "Newtown\/Llanidloes",
"441286", "Caernarfon",
"441235", "Abingdon",
"441475", "Greenock",
"441340", "Craigellachie\ \(Aberlour\)",
"441556", "Castle\ Douglas",
"441639", "Neath",
"441779", "Peterhead",
"442822", "Northern\ Ireland",
"4418908", "Coldstream",
"44287", "Northern\ Ireland",
"441255", "Clacton\-on\-Sea",
"441687", "Mallaig",
"4413390", "Aboyne\/Ballater",
"441948", "Whitchurch",
"441848", "Thornhill",
"441683", "Moffat",
"441292", "Ayr",
"4414345", "Haltwhistle",
"441490", "Corwen",
"441706", "Rochdale",
"44114709", "Sheffield",
"4415396", "Sedbergh",
"441566", "Launceston",
"441449", "Stowmarket",
"441298", "Buxton",
"441842", "Thetford",
"441904", "York",
"44151", "Liverpool",
"4414300", "North\ Cave\/Market\ Weighton",
"441942", "Wigan",
"442828", "Larne",
"441301", "Arrochar",
"441723", "Scarborough",
"4415074", "Alford\ \(Lincs\)",
"441727", "St\ Albans",
"441669", "Rothbury",
"441745", "Rhyl",
"4415079", "Alford\ \(Lincs\)",
"4414231", "Harrogate\/Boroughbridge",
"4419758", "Strathdon",
"44114704", "Sheffield",
"4418516", "Great\ Bernera",
"441407", "Holyhead",
"44114703", "Sheffield",
"441403", "Horsham",
"441384", "Dudley",
"441635", "Newbury",
"441352", "Mold",
"441368", "Dunbar",
"441395", "Budleigh\ Salterton",
"4414347", "Hexham",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441557", "Kirkcudbright",
"441259", "Alloa",
"441775", "Spalding",
"441553", "Kings\ Lynn",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441655", "Maybole",
"441287", "Guisborough",
"441972", "Glenborrodale",
"442844", "Downpatrick",
"4414308", "Market\ Weighton",
"441332", "Derby",
"441692", "North\ Walsham",
"441283", "Burton\-on\-Trent",
"4414379", "Haverfordwest",
"441872", "Truro",
"441981", "Wormbridge",
"441479", "Grantown\-on\-Spey",
"441239", "Cardigan",
"441522", "Lincoln",
"441969", "Leyburn",
"441250", "Blairgowrie",
"4414232", "Harrogate",
"441869", "Bicester",
"4413873", "Langholm",
"441327", "Daventry",
"441462", "Hitchin",
"441458", "Glastonbury",
"441561", "Laurencekirk",
"441323", "Eastbourne",
"4413393", "Aboyne",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441642", "Middlesbrough",
"441278", "Bridgwater",
"442885", "Ballygawley",
"442311", "Southampton",
"441580", "Cranbrook",
"441224", "Aberdeen",
"441438", "Stevenage",
"441604", "Northampton",
"442894", "Antrim",
"441306", "Dorking",
"441855", "Ballachulish",
"441992", "Lea\ Valley",
"441955", "Wick",
"441892", "Tunbridge\ Wells",
"441248", "Bangor\ \(Gwynedd\)",
"442867", "Lisnaskea",
"441672", "Marlborough",
"441499", "Inveraray",
"44114700", "Sheffield",
"4418515", "Stornoway",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441732", "Sevenoaks",
"441440", "Haverhill",
"441835", "St\ Boswells",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"4418903", "Coldstream",
"4415395", "Grange\-over\-Sands",
"441935", "Yeovil",
"441986", "Bungay",
"441375", "Grays\ Thurrock",
"441508", "Brooke",
"441795", "Sittingbourne",
"441912", "Tyneside",
"441752", "Plymouth",
"441768", "Penrith",
"441142", "Sheffield",
"441784", "Staines",
"441721", "Peebles",
"442837", "Armagh",
"441303", "Folkestone",
"441307", "Forfar",
"4413885", "Stanhope\ \(Eastgate\)",
"442889", "Fivemiletown",
"441650", "Cemmaes\ Road",
"441544", "Kington",
"441758", "Pwllheli",
"4414346", "Hexham",
"441918", "Tyneside",
"441502", "Lowestoft",
"441770", "Isle\ of\ Arran",
"441242", "Cheltenham",
"441678", "Bala",
"441624", "Isle\ of\ Man",
"441326", "Falmouth",
"4418479", "Tongue",
"44114708", "Sheffield",
"441204", "Bolton",
"4418474", "Thurso",
"441865", "Oxford",
"441349", "Dingwall",
"441630", "Market\ Drayton",
"441738", "Perth",
"4419753", "Strathdon",
"441379", "Diss",
"441939", "Wem",
"441887", "Aberfeldy",
"441799", "Saffron\ Walden",
"4416974", "Raughton\ Head",
"441983", "Isle\ of\ Wight",
"441987", "Ebbsfleet",
"441432", "Hereford",
"441531", "Ledbury",
"441883", "Caterham",
"441740", "Sedgefield",
"4416862", "Llanidloes",
"44281", "Northern\ Ireland",
"441859", "Harris",
"441260", "Congleton",
"44291", "Cardiff",
"4418517", "Stornoway",
"441528", "Laggan",
"441959", "Westerham",
"4414303", "North\ Cave",
"441495", "Pontypool",
"441452", "Gloucester",
"441484", "Huddersfield",
"442866", "Enniskillen",
"441225", "Bath",
"442868", "Kesh",
"442884", "Northern\ Ireland",
"441466", "Huntly",
"441549", "Lairg",
"441590", "Lymington",
"442895", "Belfast",
"4420", "London",
"441243", "Chichester",
"441526", "Martin",
"4418472", "Thurso",
"4419641", "Hornsea\/Patrington",
"441841", "Newquay\ \(Padstow\)",
"4418907", "Ayton",
"44141", "Glasgow",
"441646", "Milford\ Haven",
"441344", "Bracknell",
"441302", "Doncaster",
"4412291", "Barrow\-in\-Furness\/Millom",
"441503", "Looe",
"441767", "Sandy",
"441629", "Matlock",
"441763", "Royston",
"441209", "Redruth",
"4414305", "North\ Cave",
"441794", "Romsey",
"441785", "Stafford",
"441736", "Penzance",
"441920", "Ware",
"441453", "Dursley",
"4416869", "Newtown",
"441834", "Narberth",
"4416864", "Llanidloes",
"441328", "Fakenham",
"441457", "Glossop",
"441934", "Weston\-super\-Mare",
"441896", "Galashiels",
"441676", "Meriden",
"4413397", "Ballater",
"441916", "Tyneside",
"441691", "Oswestry",
"441871", "Castlebay",
"441756", "Skipton",
"441146", "Sheffield",
"441971", "Scourie",
"441489", "Bishops\ Waltham",
"441273", "Brighton",
"441882", "Kinloch\ Rannoch",
"441433", "Hathersage",
"4419755", "Alford\ \(Aberdeen\)",
"441854", "Ullapool",
"441982", "Builth\ Wells",
"441579", "Liskeard",
"441954", "Madingley",
"441277", "Brentwood",
"441380", "Devizes",
"441766", "Porthmadog",
"441506", "Bathgate",
"4414307", "Market\ Weighton",
"441647", "Moretonhampstead",
"441625", "Macclesfield",
"4418513", "Stornoway",
"441988", "Wigtown",
"441864", "Abington\ \(Crawford\)",
"441205", "Boston",
"441643", "Minehead",
"441888", "Turriff",
"441545", "Llanarth",
"441527", "Redditch",
"441361", "Duns",
"4414348", "Hexham",
"442840", "Banbridge",
"441609", "Northallerton",
"4418905", "Ayton",
"442899", "Northern\ Ireland",
"4414239", "Boroughbridge",
"441246", "Chesterfield",
"441322", "Dartford",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441467", "Inverurie",
"441463", "Inverness",
"4414234", "Boroughbridge",
"441494", "High\ Wycombe",
"4419757", "Strathdon",
"441308", "Bridport",
"44114707", "Sheffield",
"441485", "Hunstanton",
"441436", "Helensburgh",
"441276", "Camberley",
"442838", "Portadown",
"441900", "Workington",
"4413395", "Aboyne",
"441143", "Sheffield",
"441753", "Slough",
"441917", "Sunderland",
"442870", "Coleraine",
"441913", "Durham",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441757", "Selby",
"441575", "Kirriemuir",
"441673", "Market\ Rasen",
"441997", "Strathpeffer",
"441993", "Witney",
"441456", "Glenurquhart",
"441789", "Stratford\-upon\-Avon",
"441677", "Bedale",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441733", "Peterborough",
"441291", "Chepstow",
"442821", "Martinstown",
"441737", "Redhill",
"441583", "Carradale",
"441371", "Great\ Dunmow",
"441931", "Shap",
"441289", "Berwick\-upon\-Tweed",
"441473", "Ipswich",
"4412293", "Millom",
"441233", "Ashford\ \(Kent\)",
"441354", "Chatteris",
"441656", "Bridgend",
"441237", "Bideford",
"441382", "Dundee",
"441477", "Holmes\ Chapel",
"441539", "Kendal",
"44114702", "Sheffield",
"4419643", "Patrington",
"4414342", "Bellingham",
"441320", "Fort\ Augustus",
"441951", "Colonsay",
"441776", "Stranraer",
"441874", "Brecon",
"441694", "Church\ Stretton",
"441253", "Blackpool",
"441828", "Coupar\ Angus",
"441334", "St\ Andrews",
"441685", "Merthyr\ Tydfil",
"441636", "Newark\-on\-Trent",
"441257", "Coppull",
"441974", "Llanon",
"442842", "Kircubbin",
"441928", "Runcorn",
"441559", "Llandysul",
"441729", "Settle",
"441944", "West\ Heslerton",
"441667", "Nairn",
"441663", "New\ Mills",
"441902", "Wolverhampton",
"44292", "Cardiff",
"441844", "Thame",
"442881", "Newtownstewart",
"4416866", "Newtown",
"441746", "Bridgnorth",
"441409", "Holsworthy",
"441425", "Ringwood",
"441443", "Pontypridd",
"441565", "Knutsford",
"441341", "Barmouth",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"44121", "Birmingham",
"441598", "Lynton",
"44238", "Southampton",
"44114701", "Sheffield",
"441397", "Fort\ William",
"441633", "Newport",
"441637", "Newquay",
"441256", "Basingstoke",
"4415073", "Louth",
"4418478", "Thurso",
"441773", "Ripley",
"441491", "Henley\-on\-Thames",
"441592", "Kirkcaldy",
"441555", "Lanark",
"441777", "Retford",
"441689", "Orpington",
"441908", "Milton\ Keynes",
"441294", "Ardrossan",
"441653", "Malton",
"4418511", "Great\ Bernera\/Stornoway",
"441285", "Cirencester",
"441236", "Coatbridge",
"441808", "Tomatin",
"441476", "Grantham",
"442824", "Northern\ Ireland",
"4417687", "Keswick",
"441300", "Cerne\ Abbas",
"4414236", "Harrogate",
"441586", "Campbeltown",
"441535", "Keighley",
"442830", "Newry",
"441429", "Hartlepool",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441922", "Walsall",
"441446", "Barry",
"441569", "Stonehaven",
"441267", "Carmarthen",
"442848", "Northern\ Ireland",
"441709", "Rotherham",
"44280", "Northern\ Ireland",
"441822", "Tavistock",
"441263", "Cromer",
"441747", "Shaftesbury",
"441725", "Rockbourne",
"441980", "Amesbury",
"44161", "Manchester",
"441743", "Shrewsbury",
"441880", "Tarbert",
"4418470", "Thurso\/Tongue",
"441388", "Bishop\ Auckland",
"441666", "Malmesbury",
"441364", "Ashburton",
"4415242", "Hornby",
"441405", "Goole",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441875", "Tranent",
"441695", "Skelmersdale",
"441652", "Brigg",
"441668", "Bamburgh",
"441760", "Swaffham",
"441684", "Malvern",
"441386", "Evesham",
"441335", "Ashbourne",
"4416860", "Newtown\/Llanidloes",
"44247", "Coventry",
"441392", "Exeter",
"4413391", "Aboyne\/Ballater",
"442846", "Northern\ Ireland",
"441355", "East\ Kilbride",
"441299", "Bewdley",
"441597", "Llandrindod\ Wells",
"441593", "Lybster",
"441772", "Preston",
"442829", "Kilrea",
"441564", "Lapworth",
"441270", "Crewe",
"441588", "Bishops\ Castle",
"4415075", "Spilsby\ \(Horncastle\)",
"441704", "Southport",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441424", "Hastings",
"441806", "Shetland",
"4418901", "Coldstream\/Ayton",
"4419647", "Patrington",
"4416868", "Newtown",
"441450", "Hawick",
"441369", "Dunoon",
"4412297", "Millom",
"442891", "Bangor\ \(Co\.\ Down\)",
"441945", "Wisbech",
"441258", "Blandford",
"441262", "Bridlington",
"441823", "Taunton",
"441827", "Tamworth",
"441845", "Thirsk",
"441923", "Watford",
"4414238", "Harrogate",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441359", "Pakenham",
"441460", "Chard",
"441534", "Jersey",
"4414349", "Bellingham",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441295", "Banbury",
"441268", "Basildon",
"441252", "Aldershot",
"442825", "Ballymena",
"442847", "Northern\ Ireland",
"441284", "Bury\ St\ Edmunds",
"441520", "Lochcarron",
"4414344", "Bellingham",
"4418476", "Tongue",
"441879", "Scarinish",
"441481", "Guernsey",
"441582", "Luton",
"44118", "Reading",
"441554", "Llanelli",
"441748", "Richmond",
"4414377", "Haverfordwest",
"441383", "Dunfermline",
"441387", "Dumfries",
"441571", "Lochinver",
"441472", "Grimsby",
"44239", "Portsmouth",
"441926", "Warwick",
"441442", "Hemel\ Hempstead",
"441638", "Newmarket",
"441730", "Petersfield",
"441404", "Honiton",
"4417683", "Appleby",
"4414301", "North\ Cave\/Market\ Weighton",
"441398", "Dulverton",
"441778", "Bourne",
"441670", "Morpeth",
"441724", "Scunthorpe",
"441949", "Whatton",
"4412295", "Barrow\-in\-Furness",
"441140", "Sheffield",
"441903", "Worthing",
"442877", "Limavady",
"441807", "Ballindalloch",
"441750", "Selkirk",
"441910", "Tyneside\/Durham\/Sunderland",
"441803", "Torquay",
"4419645", "Hornsea",
"441621", "Maldon",
"4415077", "Louth",
"4414230", "Harrogate\/Boroughbridge",
"441899", "Biggar",
"441787", "Sudbury",
"4419646", "Patrington",
"441840", "Camelford",
"441455", "Hinckley",
"441348", "Fishguard",
"44283", "Northern\ Ireland",
"441591", "Llanwrtyd\ Wells",
"441492", "Colwyn\ Bay",
"441576", "Lockerbie",
"4419752", "Alford\ \(Aberdeen\)",
"441435", "Heathfield",
"441275", "Clevedon",
"442888", "Northern\ Ireland",
"4412296", "Barrow\-in\-Furness",
"441759", "Pocklington",
"441919", "Durham",
"4419467", "Gosforth",
"441223", "Cambridge",
"441862", "Tain",
"441858", "Market\ Harborough",
"442897", "Saintfield",
"442893", "Ballyclare",
"441603", "Norwich",
"4418475", "Thurso",
"441245", "Chelmsford",
"441227", "Canterbury",
"441529", "Sleaford",
"441962", "Winchester",
"441821", "Kinrossie",
"441469", "Killingholme",
"441546", "Lochgilphead",
"441350", "Dunkeld",
"4414302", "North\ Cave",
"441838", "Dalmally",
"441206", "Colchester",
"441324", "Falkirk",
"441626", "Newton\ Abbot",
"441938", "Welshpool",
"441690", "Betws\-y\-Coed",
"441798", "Pulborough",
"441870", "Isle\ of\ Benbecula",
"4416863", "Llanidloes",
"441505", "Johnstone",
"441970", "Aberystwyth",
"441330", "Banchory",
"441765", "Ripon",
"441372", "Esher",
"441487", "Warboys",
"441932", "Weybridge",
"4415394", "Hawkshead",
"441832", "Clopton",
"4413392", "Aboyne",
"441483", "Guildford",
"441279", "Bishops\ Stortford",
"4414233", "Boroughbridge",
"441577", "Kinross",
"441381", "Fortrose",
"441145", "Sheffield",
"441439", "Helmsley",
"441573", "Kelso",
"441915", "Sunderland",
"441792", "Swansea",
"441968", "Penicuik",
"441952", "Telford",
"441675", "Coleshill",
"441984", "Watchet\ \(Williton\)",
"441895", "Uxbridge",
"441852", "Kilmelford",
"441884", "Tiverton",
"441995", "Garstang",
"4415076", "Louth",
"44241", "Coventry",
"441786", "Stirling",
"442841", "Rostrevor",
"441360", "Killearn",
"4418519", "Great\ Bernera",
"4418514", "Great\ Bernera",
"442871", "Londonderry",
"441509", "Loughborough",
"441623", "Mansfield",
"441207", "Consett",
"442882", "Omagh",
"44286", "Northern\ Ireland",
"441769", "South\ Molton",
"441290", "Cumnock",
"441543", "Cannock",
"4414376", "Haverfordwest",
"441547", "Knighton",
"441525", "Leighton\ Buzzard",
"442820", "Ballycastle",
"441249", "Chippenham",
"4418902", "Coldstream",
"442896", "Belfast",
"441304", "Dover",
"441606", "Northwich",
"4418477", "Tongue",
"441226", "Barnsley",
"441465", "Girvan",
"441342", "East\ Grinstead",
"441274", "Bradford",
"441560", "Moscow",
"441957", "Mid\ Yell",
"4418512", "Stornoway",
"441228", "Carlisle",
"4412298", "Barrow\-in\-Furness",
"4416867", "Llanidloes",
"441857", "Sanday",
"441700", "Rothesay",
"442898", "Belfast",
"441608", "Chipping\ Norton",
"441953", "Wymondham",
"441496", "Port\ Ellen",
"441420", "Alton",
"441377", "Driffield",
"441581", "New\ Luce",
"441482", "Kingston\-upon\-Hull",
"441937", "Wetherby",
"441454", "Chipping\ Sodbury",
"442310", "Portsmouth",
"441833", "Barnard\ Castle",
"441837", "Okehampton",
"441933", "Wellingborough",
"441373", "Frome",
"441793", "Swindon",
"4419648", "Hornsea",
"4413394", "Ballater",
"441989", "Ross\-on\-Wye",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441572", "Oakham",
"44117", "Bristol",
"4413399", "Ballater",
"441889", "Rugeley",
"441797", "Rye",
"4418909", "Ayton",
"441764", "Crieff",
"4418904", "Coldstream",
"441542", "Keith",
"441788", "Rugby",
"4419640", "Hornsea\/Patrington",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441343", "Elgin",
"441866", "Kilchrenan",
"4414235", "Harrogate",
"441325", "Darlington",
"441347", "Easingwold",
"441309", "Forres",
"441661", "Prudhoe",
"442883", "Northern\ Ireland",
"441202", "Bournemouth",
"4412290", "Barrow\-in\-Furness\/Millom",
"442887", "Dungannon",
"441622", "Maidstone",
"441244", "Chester",
"441651", "Oldmeldrum",
"4418473", "Thurso",
"441400", "Honington",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441796", "Pitlochry",
"441674", "Montrose",
"441376", "Braintree",
"441985", "Warminster",
"4419754", "Alford\ \(Aberdeen\)",
"441720", "Isles\ of\ Scilly",
"441628", "Maidenhead",
"441994", "St\ Clears",
"441885", "Pencombe",
"4419759", "Alford\ \(Aberdeen\)",
"441208", "Bodmin",
"4415078", "Alford\ \(Lincs\)",
"441631", "Oban",
"441782", "Stoke\-on\-Trent",
"441144", "Sheffield",
"441754", "Skegness",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441548", "Kingsbridge",
"441914", "Tyneside",
"441493", "Great\ Yarmouth",
"441771", "Maud",
"4416865", "Newtown",
"441856", "Orkney",
"441497", "Hay\-on\-Wye",
"441305", "Dorchester",
"441464", "Insch",
"442886", "Cookstown",
"441488", "Hungerford",
"441530", "Coalville",
"4414309", "Market\ Weighton",
"4413882", "Stanhope\ \(Eastgate\)",
"441578", "Lauder",
"4414378", "Haverfordwest",
"4414304", "North\ Cave",
"441524", "Lancaster",
"441280", "Buckingham",
"441963", "Wincanton",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"442892", "Lisburn",
"441863", "Ardgay",
"4414237", "Harrogate",
"441346", "Fraserburgh",
"441967", "Strontian",
"441550", "Llandovery",
"441644", "New\ Galloway",
"44114705", "Sheffield",
"441329", "Fareham",
"4416973", "Wigton",
"441261", "Banff",};
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
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '44', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;