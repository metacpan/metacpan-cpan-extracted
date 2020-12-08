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
package Number::Phone::StubCountry::GB;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20201204215956;

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
                  73[03]
                )|
                (?:
                  4[0-5]|
                  5[0-26-9]|
                  6[0-4]|
                  [78][0-49]
                )\\d\\d
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
                    8[02]
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
                  73[03]
                )|
                (?:
                  4[0-5]|
                  5[0-26-9]|
                  6[0-4]|
                  [78][0-49]
                )\\d\\d
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
                    8[02]
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
            0[0-2]|
            2[356]|
            34|
            4[01347]|
            5[49]|
            6[0-369]|
            77|
            81|
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
$areanames{en} = {"441635", "Newbury",
"441344", "Bracknell",
"4418905", "Ayton",
"441427", "Gainsborough",
"441332", "Derby",
"441544", "Kington",
"4413882", "Stanhope\ \(Eastgate\)",
"441453", "Dursley",
"441292", "Ayr",
"441249", "Chippenham",
"441217", "Birmingham",
"4418472", "Thurso",
"441472", "Grimsby",
"441792", "Swansea",
"441749", "Shepton\ Mallet",
"441875", "Tranent",
"441258", "Blandford",
"4416864", "Llanidloes",
"441758", "Pwllheli",
"4418903", "Coldstream",
"441274", "Bradford",
"441494", "High\ Wycombe",
"4414348", "Hexham",
"441676", "Meriden",
"441439", "Helmsley",
"4412180", "Birmingham",
"441968", "Penicuik",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441579", "Liskeard",
"441379", "Diss",
"441667", "Nairn",
"442310", "Portsmouth",
"442881", "Newtownstewart",
"441580", "Cranbrook",
"4418510", "Great\ Bernera\/Stornoway",
"441380", "Devizes",
"4414347", "Hexham",
"441255", "Clacton\-on\-Sea",
"441878", "Lochboisdale",
"4414304", "North\ Cave",
"441854", "Ullapool",
"44281", "Northern\ Ireland",
"441929", "Wareham",
"4419753", "Strathdon",
"441600", "Monmouth",
"441638", "Newmarket",
"4419755", "Alford\ \(Aberdeen\)",
"441287", "Guisborough",
"441937", "Wetherby",
"441643", "Minehead",
"441787", "Sudbury",
"442893", "Ballyclare",
"441594", "Lydney",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"4417684", "Pooley\ Bridge",
"441394", "Felixstowe",
"441539", "Kendal",
"44147985", "Dulnain\ Bridge",
"441636", "Newark\-on\-Trent",
"441799", "Saffron\ Walden",
"441720", "Isles\ of\ Scilly",
"441479", "Grantown\-on\-Spey",
"441242", "Cheltenham",
"441299", "Bewdley",
"441501", "Harthill",
"441984", "Watchet\ \(Williton\)",
"441835", "St\ Boswells",
"4414346", "Hexham",
"4418513", "Stornoway",
"441234", "Bedford",
"441301", "Arrochar",
"441432", "Hereford",
"441327", "Daventry",
"441444", "Haywards\ Heath",
"441527", "Redditch",
"442867", "Lisnaskea",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441876", "Lochmaddy",
"4418515", "Stornoway",
"441372", "Esher",
"441353", "Ely",
"441675", "Coleshill",
"441572", "Oakham",
"441553", "Kings\ Lynn",
"441256", "Basingstoke",
"441756", "Skipton",
"441977", "Pontefract",
"441678", "Bala",
"441654", "Machynlleth",
"441903", "Worthing",
"44116", "Leicester",
"441922", "Walsall",
"44161", "Manchester",
"441843", "Thanet",
"441480", "Huntingdon",
"441951", "Colonsay",
"441838", "Dalmally",
"4412294", "Barrow\-in\-Furness",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441761", "Temple\ Cloud",
"441261", "Banff",
"4414232", "Harrogate",
"4418900", "Coldstream\/Ayton",
"441914", "Tyneside",
"442838", "Portadown",
"441707", "Welwyn\ Garden\ City",
"441207", "Consett",
"441773", "Ripley",
"441752", "Plymouth",
"441493", "Great\ Yarmouth",
"441273", "Brighton",
"441252", "Aldershot",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"4415078", "Alford\ \(Lincs\)",
"441926", "Warwick",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441962", "Winchester",
"441543", "Cannock",
"4419646", "Patrington",
"441538", "Ipstones",
"44141", "Glasgow",
"441343", "Elgin",
"441798", "Pulborough",
"441454", "Chipping\ Sodbury",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441298", "Buxton",
"441300", "Cerne\ Abbas",
"441721", "Peebles",
"44241", "Coventry",
"441795", "Sittingbourne",
"441295", "Banbury",
"441475", "Greenock",
"4414375", "Clynderwen\ \(Clunderwen\)",
"44147982", "Nethy\ Bridge",
"441481", "Guernsey",
"441950", "Sandwick",
"441335", "Ashbourne",
"442894", "Antrim",
"441644", "New\ Galloway",
"441760", "Swaffham",
"441246", "Chesterfield",
"441535", "Keighley",
"441260", "Congleton",
"441746", "Bridgnorth",
"441567", "Killin",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441367", "Faringdon",
"441827", "Tamworth",
"441436", "Helensburgh",
"4412292", "Barrow\-in\-Furness",
"4415077", "Louth",
"4413399", "Ballater",
"441576", "Lockerbie",
"4414234", "Boroughbridge",
"442827", "Ballymoney",
"4415242", "Hornby",
"441376", "Braintree",
"441872", "Truro",
"441259", "Alloa",
"441880", "Tarbert",
"441443", "Pontypridd",
"44131", "Edinburgh",
"441759", "Pocklington",
"441925", "Warrington",
"44151", "Liverpool",
"4419641", "Hornsea\/Patrington",
"4416974", "Raughton\ Head",
"441438", "Stevenage",
"441969", "Leyburn",
"441578", "Lauder",
"441554", "Llanelli",
"4419648", "Hornsea",
"442880", "Carrickmore",
"442311", "Southampton",
"4418474", "Thurso",
"441400", "Honington",
"44147984", "Carrbridge",
"441354", "Chatteris",
"4416862", "Llanidloes",
"4415076", "Louth",
"441593", "Lybster",
"441983", "Isle\ of\ Wight",
"441733", "Peterborough",
"441233", "Ashford\ \(Kent\)",
"441248", "Bangor\ \(Gwynedd\)",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441748", "Richmond",
"441467", "Inverurie",
"441832", "Clopton",
"441245", "Chelmsford",
"441536", "Kettering",
"441745", "Rhyl",
"441844", "Thame",
"441639", "Neath",
"441796", "Pitlochry",
"441913", "Durham",
"441476", "Grantham",
"441296", "Aylesbury",
"4414302", "North\ Cave",
"441694", "Church\ Stretton",
"442844", "Downpatrick",
"441575", "Kirriemuir",
"441381", "Fortrose",
"441672", "Marlborough",
"441904", "York",
"441653", "Malton",
"442879", "Magherafelt",
"441375", "Grays\ Thurrock",
"441581", "New\ Luce",
"44238", "Southampton",
"4419647", "Patrington",
"441879", "Scarinish",
"441928", "Runcorn",
"441435", "Heathfield",
"441634", "Medway",
"441986", "Bungay",
"441620", "North\ Berwick",
"442892", "Lisburn",
"441736", "Penzance",
"441642", "Middlesbrough",
"4412295", "Barrow\-in\-Furness",
"441545", "Llanarth",
"441236", "Coatbridge",
"4414349", "Bellingham",
"44118", "Reading",
"441892", "Tunbridge\ Wells",
"441874", "Brecon",
"4412293", "Millom",
"441775", "Spalding",
"441858", "Market\ Harborough",
"441495", "Pontypool",
"441275", "Clevedon",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441931", "Shap",
"4416860", "Newtown\/Llanidloes",
"441909", "Worksop",
"441446", "Barry",
"441460", "Chard",
"4414300", "North\ Cave\/Market\ Weighton",
"441559", "Llandysul",
"441211", "Birmingham",
"4417683", "Appleby",
"441359", "Pakenham",
"441778", "Bourne",
"441254", "Blackburn",
"441278", "Bridgwater",
"4418514", "Great\ Bernera",
"441855", "Ballachulish",
"441754", "Skegness",
"441656", "Bridgend",
"441407", "Holyhead",
"441916", "Tyneside",
"441793", "Swindon",
"442887", "Dungannon",
"441661", "Prudhoe",
"441293", "Crawley",
"441473", "Ipswich",
"441452", "Gloucester",
"441348", "Fishguard",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441887", "Aberfeldy",
"441548", "Kingsbridge",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441692", "North\ Walsham",
"442820", "Ballycastle",
"442842", "Kircubbin",
"441918", "Tyneside",
"441395", "Budleigh\ Salterton",
"4419754", "Alford\ \(Aberdeen\)",
"441971", "Scourie",
"441899", "Biggar",
"441842", "Thetford",
"441360", "Killearn",
"441346", "Fraserburgh",
"4414303", "North\ Cave",
"441985", "Warminster",
"441834", "Narberth",
"441560", "Moscow",
"441546", "Lochgilphead",
"441235", "Abingdon",
"441923", "Watford",
"441267", "Carmarthen",
"441767", "Sandy",
"441445", "Gairloch",
"441776", "Stranraer",
"441957", "Mid\ Yell",
"441276", "Camberley",
"441496", "Port\ Ellen",
"4414305", "North\ Cave",
"441674", "Montrose",
"441902", "Wolverhampton",
"4416865", "Newtown",
"441352", "Mold",
"441373", "Frome",
"441856", "Orkney",
"441307", "Forfar",
"441573", "Kelso",
"441655", "Maybole",
"441433", "Hathersage",
"441243", "Chichester",
"441687", "Mallaig",
"441743", "Shrewsbury",
"4418904", "Coldstream",
"441988", "Wigtown",
"441738", "Perth",
"4420", "London",
"4416863", "Llanidloes",
"441598", "Lynton",
"441200", "Clitheroe",
"441398", "Dulverton",
"441915", "Sunderland",
"4412290", "Barrow\-in\-Furness\/Millom",
"441700", "Rothesay",
"441807", "Ballindalloch",
"441556", "Castle\ Douglas",
"441852", "Kilmelford",
"441873", "Abergavenny",
"441356", "Brechin",
"4419752", "Alford\ \(Aberdeen\)",
"441487", "Warboys",
"441659", "Sanquhar",
"442898", "Belfast",
"441919", "Durham",
"441947", "Whitby",
"441633", "Newport",
"442821", "Martinstown",
"4413397", "Ballater",
"441561", "Laurencekirk",
"441455", "Hinckley",
"4415079", "Alford\ \(Lincs\)",
"441821", "Kinrossie",
"441970", "Aberystwyth",
"441361", "Duns",
"4416973", "Wigton",
"441895", "Uxbridge",
"441458", "Glastonbury",
"441794", "Romsey",
"441474", "Gravesend",
"441294", "Ardrossan",
"441989", "Ross\-on\-Wye",
"441239", "Cardigan",
"4413391", "Aboyne\/Ballater",
"441520", "Lochcarron",
"441542", "Keith",
"441599", "Kyle",
"441334", "St\ Andrews",
"442895", "Belfast",
"4418473", "Thurso",
"4413398", "Aboyne",
"441320", "Fort\ Augustus",
"441342", "East\ Grinstead",
"441534", "Jersey",
"4414230", "Harrogate\/Boroughbridge",
"441963", "Wincanton",
"441227", "Canterbury",
"4418902", "Coldstream",
"441727", "St\ Albans",
"4413885", "Stanhope\ \(Eastgate\)",
"441253", "Blackpool",
"4418475", "Thurso",
"441449", "Stowmarket",
"441492", "Colwyn\ Bay",
"441753", "Slough",
"441772", "Preston",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441780", "Stamford",
"441280", "Buckingham",
"441859", "Harris",
"4418470", "Thurso\/Tongue",
"441924", "Wakefield",
"441652", "Brigg",
"441673", "Market\ Rasen",
"4414235", "Harrogate",
"441908", "Milton\ Keynes",
"441461", "Gretna",
"441555", "Lanark",
"441355", "East\ Kilbride",
"441621", "Maldon",
"441456", "Glenurquhart",
"441997", "Strathpeffer",
"441912", "Tyneside",
"441698", "Motherwell",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441833", "Barnard\ Castle",
"4419649", "Hornsea",
"441387", "Dumfries",
"4414233", "Boroughbridge",
"441848", "Thornhill",
"441646", "Milford\ Haven",
"441732", "Sevenoaks",
"442896", "Belfast",
"441982", "Builth\ Wells",
"441244", "Chester",
"441744", "St\ Helens",
"441845", "Thirsk",
"441896", "Galashiels",
"441392", "Exeter",
"441349", "Dingwall",
"4418512", "Stornoway",
"441695", "Skelmersdale",
"441549", "Lairg",
"441592", "Kirkcaldy",
"441210", "Birmingham",
"441558", "Llandeilo",
"441905", "Worcester",
"4413396", "Ballater",
"441358", "Ellon",
"4415396", "Sedbergh",
"441779", "Peterhead",
"441279", "Bishops\ Stortford",
"441442", "Hemel\ Hempstead",
"441499", "Inveraray",
"441420", "Alton",
"441241", "Arbroath",
"441502", "Lowestoft",
"441357", "Strathaven",
"441302", "Doncaster",
"441557", "Kirkcudbright",
"441806", "Shetland",
"44147983", "Boat\ of\ Garten",
"441863", "Ardgay",
"441323", "Eastbourne",
"4416869", "Newtown",
"441371", "Great\ Dunmow",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"442889", "Fivemiletown",
"441946", "Whitehaven",
"441571", "Lochinver",
"441409", "Holsworthy",
"4418517", "Stornoway",
"441889", "Rugeley",
"441250", "Blairgowrie",
"441431", "Helmsdale",
"441750", "Selkirk",
"441995", "Garstang",
"44114", "Sheffield",
"4419756", "Strathdon",
"441870", "Isle\ of\ Benbecula",
"4418906", "Ayton",
"441697", "Brampton",
"4418518", "Stornoway",
"441588", "Bishops\ Castle",
"44292", "Cardiff",
"4418511", "Great\ Bernera\/Stornoway",
"442870", "Coleraine",
"441388", "Bishop\ Auckland",
"441464", "Insch",
"441726", "St\ Austell",
"441262", "Bridlington",
"441630", "Market\ Drayton",
"441226", "Barnsley",
"441624", "Isle\ of\ Man",
"4414309", "Market\ Weighton",
"441952", "Telford",
"441608", "Chipping\ Norton",
"441728", "Saxmundham",
"441228", "Carlisle",
"441309", "Forres",
"441485", "Hunstanton",
"441663", "New\ Mills",
"441509", "Loughborough",
"441291", "Chepstow",
"4419758", "Strathdon",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"4418907", "Ayton",
"441531", "Ledbury",
"441606", "Northwich",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441204", "Bolton",
"44247", "Coventry",
"441704", "Southport",
"441805", "Torrington",
"441689", "Orpington",
"442882", "Omagh",
"441457", "Glossop",
"441213", "Birmingham",
"441586", "Campbeltown",
"4413873", "Langholm",
"441945", "Wisbech",
"441386", "Evesham",
"441882", "Kinloch\ Rannoch",
"441948", "Whitchurch",
"441933", "Wellingborough",
"441647", "Moretonhampstead",
"4413392", "Aboyne",
"442897", "Saintfield",
"441283", "Burton\-on\-Trent",
"4414345", "Haltwhistle",
"4412299", "Millom",
"441670", "Morpeth",
"4419757", "Strathdon",
"441769", "South\ Molton",
"441808", "Tomatin",
"4418901", "Coldstream\/Ayton",
"441269", "Ammanford",
"442830", "Newry",
"441824", "Ruthin",
"441725", "Rockbourne",
"441364", "Ashburton",
"4418908", "Coldstream",
"441488", "Hungerford",
"441225", "Bath",
"4414343", "Haltwhistle",
"441564", "Lapworth",
"441830", "Kirkwhelpington",
"4418516", "Great\ Bernera",
"441959", "Westerham",
"441237", "Bideford",
"441987", "Ebbsfleet",
"4414376", "Haverfordwest",
"441737", "Redhill",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441397", "Fort\ William",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441597", "Llandrindod\ Wells",
"441729", "Settle",
"441790", "Spilsby",
"441308", "Bridport",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441290", "Cumnock",
"441508", "Brooke",
"441955", "Wick",
"441524", "Lancaster",
"441330", "Banchory",
"441324", "Falkirk",
"441765", "Ripon",
"441530", "Coalville",
"441864", "Abington\ \(Crawford\)",
"4415394", "Hawkshead",
"441623", "Mansfield",
"4419643", "Patrington",
"4413394", "Ballater",
"441768", "Penrith",
"441809", "Tomdoun",
"4414239", "Boroughbridge",
"441268", "Basildon",
"441489", "Bishops\ Waltham",
"441305", "Dorchester",
"441974", "Llanon",
"441505", "Johnstone",
"442886", "Cookstown",
"441917", "Sunderland",
"441992", "Lea\ Valley",
"441949", "Whatton",
"4419645", "Hornsea",
"441406", "Holbeach",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441671", "Newton\ Stewart",
"441382", "Dundee",
"441463", "Inverness",
"441685", "Merthyr\ Tydfil",
"441582", "Luton",
"441570", "Lampeter",
"441214", "Birmingham",
"441408", "Golspie",
"441547", "Knighton",
"441888", "Turriff",
"441424", "Hastings",
"441347", "Easingwold",
"4419640", "Hornsea\/Patrington",
"441751", "Pickering",
"44115", "Nottingham",
"441664", "Melton\ Mowbray",
"4418479", "Tongue",
"441766", "Porthmadog",
"441740", "Sedgefield",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441722", "Salisbury",
"4414378", "Haverfordwest",
"441497", "Hay\-on\-Wye",
"441277", "Brentwood",
"441777", "Retford",
"441306", "Dorking",
"4415073", "Louth",
"441857", "Sanday",
"441631", "Oban",
"441506", "Bathgate",
"441563", "Kilmarnock",
"4414377", "Haverfordwest",
"441609", "Northallerton",
"441482", "Kingston\-upon\-Hull",
"441363", "Crediton",
"441823", "Taunton",
"441784", "Staines",
"441885", "Pencombe",
"441934", "Weston\-super\-Mare",
"441284", "Bury\ St\ Edmunds",
"441871", "Castlebay",
"4415075", "Spilsby\ \(Horncastle\)",
"441920", "Ware",
"441942", "Wigan",
"442885", "Ballygawley",
"441389", "Dumbarton",
"441405", "Goole",
"442871", "Londonderry",
"441972", "Glenborrodale",
"441841", "Newquay\ \(Padstow\)",
"441604", "Northampton",
"441953", "Wymondham",
"4419642", "Hornsea",
"441206", "Colchester",
"441706", "Rochdale",
"441691", "Oswestry",
"442841", "Rostrevor",
"44147981", "Aviemore",
"441763", "Royston",
"441263", "Cromer",
"441628", "Maidenhead",
"441584", "Ludlow",
"4416861", "Newtown\/Llanidloes",
"441384", "Dudley",
"4414307", "Market\ Weighton",
"441939", "Wem",
"441789", "Stratford\-upon\-Avon",
"4414344", "Bellingham",
"441289", "Berwick\-upon\-Tweed",
"441994", "St\ Clears",
"4416868", "Newtown",
"441770", "Isle\ of\ Arran",
"4412296", "Barrow\-in\-Furness",
"441429", "Hartlepool",
"441270", "Crewe",
"441490", "Corwen",
"4414308", "Market\ Weighton",
"441683", "Moffat",
"4414301", "North\ Cave\/Market\ Weighton",
"441747", "Shaftesbury",
"4416867", "Llanidloes",
"441465", "Girvan",
"44147986", "Cairngorm",
"441366", "Downham\ Market",
"441322", "Dartford",
"441862", "Tain",
"441340", "Craigellachie\ \(Aberlour\)",
"441566", "Launceston",
"441625", "Macclesfield",
"441522", "Lincoln",
"4418519", "Great\ Bernera",
"441540", "Kingussie",
"441669", "Rothbury",
"441503", "Looe",
"441377", "Driffield",
"441303", "Folkestone",
"441577", "Kinross",
"441368", "Dunbar",
"441828", "Coupar\ Angus",
"441484", "Huddersfield",
"441568", "Leominster",
"4415072", "Spilsby\ \(Horncastle\)",
"4416866", "Newtown",
"4412297", "Millom",
"442828", "Larne",
"441205", "Boston",
"441910", "Tyneside\/Durham\/Sunderland",
"442891", "Bangor\ \(Co\.\ Down\)",
"441641", "Strathy",
"4419759", "Alford\ \(Aberdeen\)",
"441650", "Cemmaes\ Road",
"441944", "West\ Heslerton",
"441282", "Burnley",
"441782", "Stoke\-on\-Trent",
"441932", "Weybridge",
"441440", "Haverhill",
"441883", "Caterham",
"441422", "Halifax",
"441337", "Ladybank",
"441466", "Huntly",
"441403", "Horsham",
"4418909", "Ayton",
"441212", "Birmingham",
"441297", "Axminster",
"441477", "Holmes\ Chapel",
"441797", "Rye",
"441590", "Lymington",
"441529", "Sleaford",
"442825", "Ballymena",
"441869", "Bicester",
"4412291", "Barrow\-in\-Furness\/Millom",
"441208", "Bodmin",
"441329", "Fareham",
"441708", "Romford",
"441825", "Uckfield",
"441724", "Scunthorpe",
"4412298", "Barrow\-in\-Furness",
"441224", "Aberdeen",
"441730", "Petersfield",
"441980", "Amesbury",
"4414306", "Market\ Weighton",
"441451", "Stow\-on\-the\-Wold",
"441565", "Knutsford",
"441626", "Newton\ Abbot",
"4417687", "Keswick",
"441462", "Hitchin",
"441383", "Dunfermline",
"441837", "Okehampton",
"441651", "Oldmeldrum",
"441583", "Carradale",
"4415074", "Alford\ \(Lincs\)",
"4414237", "Harrogate",
"442837", "Armagh",
"441993", "Witney",
"441216", "Birmingham",
"44291", "Cardiff",
"441369", "Dunoon",
"441829", "Tarporley",
"441677", "Bedale",
"441569", "Stonehaven",
"441978", "Wrexham",
"441954", "Madingley",
"441603", "Norwich",
"441525", "Leighton\ Buzzard",
"441666", "Malmesbury",
"441911", "Tyneside\/Durham\/Sunderland",
"442890", "Belfast",
"441622", "Maidstone",
"4418476", "Tongue",
"442829", "Kilrea",
"441764", "Crieff",
"441325", "Darlington",
"441865", "Oxford",
"441264", "Andover",
"441528", "Laggan",
"441591", "Llanwrtyd\ Wells",
"441209", "Redruth",
"441328", "Fakenham",
"441709", "Rotherham",
"44239", "Portsmouth",
"441981", "Wormbridge",
"441450", "Hawick",
"441304", "Dover",
"4413390", "Aboyne\/Ballater",
"442868", "Kesh",
"4414238", "Harrogate",
"44113", "Leeds",
"441786", "Stirling",
"4414231", "Harrogate\/Boroughbridge",
"441286", "Caernarfon",
"441684", "Malvern",
"441215", "Birmingham",
"4418478", "Thurso",
"441900", "Workington",
"4413393", "Aboyne",
"4419644", "Patrington",
"441469", "Killingholme",
"4414379", "Haverfordwest",
"441938", "Welshpool",
"441788", "Rugby",
"4419467", "Gosforth",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441425", "Ringwood",
"441288", "Bude",
"441943", "Guiseley",
"441637", "Newquay",
"4418471", "Thurso\/Tongue",
"4415395", "Grange\-over\-Sands",
"441665", "Alnwick",
"441526", "Martin",
"441562", "Kidderminster",
"4413395", "Aboyne",
"441866", "Kilchrenan",
"442877", "Limavady",
"441326", "Falmouth",
"441822", "Tavistock",
"441483", "Guildford",
"441362", "Dereham",
"441840", "Camelford",
"441803", "Torquay",
"4414342", "Bellingham",
"441690", "Betws\-y\-Coed",
"441629", "Matlock",
"442840", "Banbridge",
"442866", "Enniskillen",
"441877", "Callander",
"441702", "Southend\-on\-Sea",
"441202", "Bournemouth",
"441757", "Selby",
"441257", "Coppull",
"441341", "Barmouth",
"441668", "Bamburgh",
"44117", "Bristol",
"441723", "Scarborough",
"4414236", "Harrogate",
"441967", "Strontian",
"441223", "Cambridge",
"441785", "Stafford",
"4418477", "Tongue",
"441884", "Tiverton",
"441935", "Yeovil",
"441428", "Haslemere",
"441285", "Cirencester",
"441771", "Maud",
"441491", "Henley\-on\-Thames",
"441271", "Barnstaple",
"441550", "Llandovery",
"441404", "Honiton",
"441350", "Dunkeld",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+44|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;