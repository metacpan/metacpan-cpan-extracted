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
our $VERSION = 1.20210204173826;

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
                4(?:
                  [0-5]\\d\\d|
                  69[7-9]
                )|
                (?:
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
                4(?:
                  [0-5]\\d\\d|
                  69[7-9]
                )|
                (?:
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
$areanames{en} = {"4416863", "Llanidloes",
"441985", "Warminster",
"441651", "Oldmeldrum",
"441986", "Bungay",
"4418479", "Tongue",
"4418517", "Stornoway",
"441461", "Gretna",
"441283", "Burton\-on\-Trent",
"4414349", "Bellingham",
"441348", "Fishguard",
"441721", "Peebles",
"441736", "Penzance",
"4413392", "Aboyne",
"442837", "Armagh",
"4414309", "Market\ Weighton",
"4419648", "Hornsea",
"441808", "Tomatin",
"442830", "Newry",
"4414379", "Haverfordwest",
"441208", "Bodmin",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441395", "Budleigh\ Salterton",
"441883", "Caterham",
"4419758", "Strathdon",
"441282", "Burnley",
"442870", "Coleraine",
"441775", "Spalding",
"442877", "Limavady",
"441384", "Dudley",
"44291", "Cardiff",
"441776", "Stranraer",
"441380", "Devizes",
"441387", "Dumfries",
"442866", "Enniskillen",
"441424", "Hastings",
"441458", "Glastonbury",
"441764", "Crieff",
"441882", "Kinloch\ Rannoch",
"441760", "Swaffham",
"441427", "Gainsborough",
"441767", "Sandy",
"441420", "Alton",
"4418511", "Great\ Bernera\/Stornoway",
"441598", "Lynton",
"441289", "Berwick\-upon\-Tweed",
"441997", "Strathpeffer",
"441546", "Lochgilphead",
"441889", "Rugeley",
"441994", "St\ Clears",
"441668", "Bamburgh",
"441545", "Llanarth",
"4418900", "Coldstream\/Ayton",
"4416973", "Wigton",
"4414301", "North\ Cave\/Market\ Weighton",
"441360", "Killearn",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441367", "Faringdon",
"4413390", "Aboyne\/Ballater",
"441262", "Bridlington",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"4416974", "Raughton\ Head",
"441364", "Ashburton",
"441953", "Wymondham",
"441376", "Braintree",
"441862", "Tain",
"441780", "Stamford",
"442885", "Ballygawley",
"441787", "Sudbury",
"441375", "Grays\ Thurrock",
"442311", "Southampton",
"442886", "Cookstown",
"441784", "Staines",
"4415072", "Spilsby\ \(Horncastle\)",
"441603", "Norwich",
"441256", "Basingstoke",
"441269", "Ammanford",
"441255", "Clacton\-on\-Sea",
"441538", "Ipstones",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441855", "Ballachulish",
"441934", "Weston\-super\-Mare",
"4418471", "Thurso\/Tongue",
"441856", "Orkney",
"441869", "Bicester",
"441937", "Wetherby",
"441959", "Westerham",
"4414377", "Haverfordwest",
"441406", "Holbeach",
"4414307", "Market\ Weighton",
"441578", "Lauder",
"4414347", "Hexham",
"441405", "Goole",
"4418519", "Great\ Bernera",
"441977", "Pontefract",
"441644", "New\ Galloway",
"4418902", "Coldstream",
"441970", "Aberystwyth",
"441974", "Llanon",
"4414235", "Harrogate",
"441647", "Moretonhampstead",
"441529", "Sleaford",
"442890", "Belfast",
"441795", "Sittingbourne",
"442897", "Saintfield",
"441481", "Guernsey",
"441796", "Pitlochry",
"441263", "Cromer",
"441952", "Telford",
"442894", "Antrim",
"441609", "Northallerton",
"4418477", "Tongue",
"4416864", "Llanidloes",
"441863", "Ardgay",
"441522", "Lincoln",
"441335", "Ashbourne",
"441748", "Richmond",
"441377", "Driffield",
"441233", "Ashford\ \(Kent\)",
"441491", "Henley\-on\-Thames",
"441786", "Stirling",
"442887", "Dungannon",
"442880", "Carrickmore",
"441785", "Stafford",
"441359", "Pakenham",
"441872", "Truro",
"441366", "Downham\ Market",
"441833", "Barnard\ Castle",
"4415075", "Spilsby\ \(Horncastle\)",
"441279", "Bishops\ Stortford",
"441854", "Ullapool",
"441828", "Coupar\ Angus",
"441935", "Yeovil",
"441857", "Sanday",
"441443", "Pontypridd",
"441257", "Coppull",
"441250", "Blairgowrie",
"441254", "Blackburn",
"441228", "Carlisle",
"441879", "Scarinish",
"4412299", "Millom",
"441352", "Mold",
"441568", "Leominster",
"441646", "Milford\ Haven",
"441442", "Hemel\ Hempstead",
"441239", "Cardigan",
"441407", "Holyhead",
"4418905", "Ayton",
"441400", "Honington",
"441967", "Strontian",
"441404", "Honiton",
"441353", "Ely",
"4414232", "Harrogate",
"441698", "Motherwell",
"441449", "Stowmarket",
"441334", "St\ Andrews",
"4416866", "Newtown",
"441330", "Banchory",
"441273", "Brighton",
"441337", "Ladybank",
"441794", "Romsey",
"441873", "Abergavenny",
"442896", "Belfast",
"441832", "Clopton",
"441797", "Rye",
"441790", "Spilsby",
"442895", "Belfast",
"4417683", "Appleby",
"441299", "Bewdley",
"441753", "Slough",
"441588", "Bishops\ Castle",
"4417684", "Pooley\ Bridge",
"441638", "Newmarket",
"4412291", "Barrow\-in\-Furness\/Millom",
"441984", "Watchet\ \(Williton\)",
"441899", "Biggar",
"441980", "Amesbury",
"441503", "Looe",
"441987", "Ebbsfleet",
"4415242", "Hornby",
"4413395", "Aboyne",
"441397", "Fort\ William",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441623", "Mansfield",
"441394", "Felixstowe",
"441292", "Ayr",
"441730", "Petersfield",
"441737", "Redhill",
"441892", "Tunbridge\ Wells",
"442821", "Martinstown",
"441425", "Ringwood",
"442867", "Lisnaskea",
"441211", "Birmingham",
"4412180", "Birmingham",
"441765", "Ripon",
"441431", "Helmsdale",
"441759", "Pocklington",
"441622", "Maidstone",
"441766", "Porthmadog",
"441293", "Crawley",
"441918", "Tyneside",
"441509", "Loughborough",
"4412297", "Millom",
"441777", "Retford",
"441770", "Isle\ of\ Arran",
"441386", "Evesham",
"441241", "Arbroath",
"441547", "Knighton",
"441540", "Kingussie",
"441752", "Plymouth",
"441629", "Matlock",
"441544", "Kington",
"441995", "Garstang",
"4414230", "Harrogate\/Boroughbridge",
"441948", "Whitchurch",
"441301", "Arrochar",
"441841", "Newquay\ \(Padstow\)",
"441502", "Lowestoft",
"441678", "Bala",
"441793", "Swindon",
"441259", "Alloa",
"441874", "Brecon",
"441870", "Isle\ of\ Benbecula",
"4418473", "Thurso",
"441877", "Callander",
"442882", "Omagh",
"44147983", "Boat\ of\ Garten",
"441270", "Crewe",
"441865", "Oxford",
"441571", "Lochinver",
"4416869", "Newtown",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441277", "Brentwood",
"441372", "Esher",
"441866", "Kilchrenan",
"441274", "Bradford",
"441859", "Harris",
"441350", "Dunkeld",
"4420", "London",
"441357", "Strathaven",
"441252", "Aldershot",
"4418514", "Great\ Bernera",
"441403", "Horsham",
"441963", "Wincanton",
"441354", "Chatteris",
"441328", "Fakenham",
"4414343", "Haltwhistle",
"441852", "Kilmelford",
"441379", "Diss",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441488", "Hungerford",
"442889", "Fivemiletown",
"4414303", "North\ Cave",
"4412296", "Barrow\-in\-Furness",
"441606", "Northwich",
"441253", "Blackpool",
"441962", "Winchester",
"441799", "Saffron\ Walden",
"4415394", "Hawkshead",
"4414238", "Harrogate",
"441440", "Haverhill",
"441444", "Haywards\ Heath",
"441969", "Leyburn",
"441837", "Okehampton",
"441792", "Swansea",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441830", "Kirkwhelpington",
"441409", "Holsworthy",
"44292", "Cardiff",
"441834", "Narberth",
"441955", "Wick",
"441234", "Bedford",
"441525", "Leighton\ Buzzard",
"441332", "Derby",
"441237", "Bideford",
"441531", "Ledbury",
"441526", "Martin",
"441373", "Frome",
"441451", "Stow\-on\-the\-Wold",
"441982", "Builth\ Wells",
"44281", "Northern\ Ireland",
"441543", "Cannock",
"441773", "Ripley",
"4419645", "Hornsea",
"441989", "Ross\-on\-Wye",
"441661", "Prudhoe",
"441732", "Sevenoaks",
"441290", "Cumnock",
"4419755", "Alford\ \(Aberdeen\)",
"441591", "Llanwrtyd\ Wells",
"441297", "Axminster",
"441392", "Exeter",
"441294", "Ardrossan",
"4416861", "Newtown\/Llanidloes",
"441772", "Preston",
"441285", "Cirencester",
"4414344", "Bellingham",
"441286", "Caernarfon",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441733", "Peterborough",
"4414304", "North\ Cave",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441620", "North\ Berwick",
"441549", "Lairg",
"4418513", "Stornoway",
"441624", "Isle\ of\ Man",
"441885", "Pencombe",
"441983", "Isle\ of\ Wight",
"44247", "Coventry",
"441779", "Peterhead",
"441754", "Skegness",
"441728", "Saxmundham",
"441341", "Barmouth",
"441908", "Milton\ Keynes",
"441750", "Selkirk",
"4416867", "Llanidloes",
"441542", "Keith",
"4418474", "Thurso",
"441757", "Selby",
"441911", "Tyneside\/Durham\/Sunderland",
"441993", "Witney",
"441438", "Stevenage",
"4419642", "Hornsea",
"441308", "Bridport",
"441763", "Royston",
"441296", "Aylesbury",
"441848", "Thornhill",
"441295", "Banbury",
"441671", "Newton\ Stewart",
"44147982", "Nethy\ Bridge",
"4413398", "Aboyne",
"4412293", "Millom",
"441248", "Bangor\ \(Gwynedd\)",
"441383", "Dunfermline",
"4419752", "Alford\ \(Aberdeen\)",
"441895", "Uxbridge",
"441896", "Galashiels",
"441887", "Aberfeldy",
"441631", "Oban",
"441626", "Newton\ Abbot",
"441422", "Halifax",
"441880", "Tarbert",
"441884", "Tiverton",
"441625", "Macclesfield",
"4414376", "Haverfordwest",
"441284", "Bury\ St\ Edmunds",
"4414306", "Market\ Weighton",
"441382", "Dundee",
"4414346", "Hexham",
"441581", "New\ Luce",
"441287", "Guisborough",
"441141", "Sheffield",
"441280", "Buckingham",
"4418476", "Tongue",
"441992", "Lea\ Valley",
"442828", "Larne",
"441769", "South\ Molton",
"441756", "Skipton",
"441429", "Hartlepool",
"442879", "Magherafelt",
"441506", "Bathgate",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441505", "Johnstone",
"441389", "Dumbarton",
"441864", "Abington\ \(Crawford\)",
"4417687", "Keswick",
"441276", "Camberley",
"441939", "Wem",
"441782", "Stoke\-on\-Trent",
"4419640", "Hornsea\/Patrington",
"441275", "Clevedon",
"441691", "Oswestry",
"441267", "Carmarthen",
"441561", "Laurencekirk",
"4415078", "Alford\ \(Lincs\)",
"441260", "Congleton",
"441875", "Tranent",
"441264", "Andover",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441876", "Lochmaddy",
"441362", "Dereham",
"442893", "Ballyclare",
"441643", "Minehead",
"441789", "Stratford\-upon\-Avon",
"441932", "Weybridge",
"442841", "Rostrevor",
"4418516", "Great\ Bernera",
"441369", "Dunoon",
"441356", "Brechin",
"441355", "East\ Kilbride",
"4419467", "Gosforth",
"441446", "Barry",
"441642", "Middlesbrough",
"441933", "Wellingborough",
"441972", "Glenborrodale",
"441445", "Gairloch",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"44131", "Edinburgh",
"441604", "Northampton",
"4415396", "Sedbergh",
"4418908", "Coldstream",
"4412294", "Barrow\-in\-Furness",
"441600", "Monmouth",
"441235", "Abingdon",
"441558", "Llandeilo",
"441524", "Lancaster",
"44147984", "Carrbridge",
"441527", "Redditch",
"441236", "Coatbridge",
"441520", "Lochcarron",
"441950", "Sandwick",
"441821", "Kinrossie",
"441957", "Mid\ Yell",
"441835", "St\ Boswells",
"441928", "Runcorn",
"442892", "Lisburn",
"441954", "Madingley",
"441363", "Crediton",
"441708", "Romford",
"441467", "Inverurie",
"442825", "Ballymena",
"441143", "Sheffield",
"441900", "Workington",
"441720", "Isles\ of\ Scilly",
"441583", "Carradale",
"4414234", "Boroughbridge",
"441460", "Chard",
"441727", "St\ Albans",
"441464", "Insch",
"44116", "Leicester",
"441904", "York",
"441724", "Scunthorpe",
"441758", "Pwllheli",
"4418906", "Ayton",
"441508", "Brooke",
"441919", "Durham",
"441476", "Grantham",
"441672", "Marlborough",
"441633", "Newport",
"441942", "Wigan",
"441475", "Greenock",
"441654", "Machynlleth",
"441628", "Maidenhead",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"4416865", "Newtown",
"441650", "Cemmaes\ Road",
"4419641", "Hornsea\/Patrington",
"441949", "Whatton",
"441912", "Tyneside",
"441845", "Thirsk",
"441306", "Dorking",
"441298", "Buxton",
"441305", "Dorchester",
"441246", "Chesterfield",
"441639", "Neath",
"4415076", "Louth",
"441913", "Durham",
"441245", "Chelmsford",
"441582", "Luton",
"4419757", "Strathdon",
"441142", "Sheffield",
"442871", "Londonderry",
"441381", "Fortrose",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441435", "Heathfield",
"441673", "Market\ Rasen",
"4419647", "Patrington",
"441216", "Birmingham",
"441436", "Helensburgh",
"4418518", "Stornoway",
"441761", "Temple\ Cloud",
"441943", "Guiseley",
"441215", "Birmingham",
"441556", "Castle\ Douglas",
"441569", "Stonehaven",
"442842", "Kircubbin",
"441555", "Lanark",
"4419759", "Alford\ \(Aberdeen\)",
"441838", "Dalmally",
"441925", "Warrington",
"4414348", "Hexham",
"4414308", "Market\ Weighton",
"4419649", "Hornsea",
"4414378", "Haverfordwest",
"441926", "Warwick",
"441931", "Shap",
"441706", "Rochdale",
"441361", "Duns",
"441562", "Kidderminster",
"441823", "Taunton",
"4418478", "Thurso",
"441223", "Cambridge",
"441496", "Port\ Ellen",
"441692", "North\ Walsham",
"442310", "Portsmouth",
"441495", "Pontypool",
"4413882", "Stanhope\ \(Eastgate\)",
"441484", "Huddersfield",
"44118", "Reading",
"442891", "Bangor\ \(Co\.\ Down\)",
"441487", "Warboys",
"441822", "Tavistock",
"441563", "Kilmarnock",
"441480", "Huntingdon",
"441324", "Falkirk",
"441358", "Ellon",
"441320", "Fort\ Augustus",
"441327", "Daventry",
"4413396", "Ballater",
"44151", "Liverpool",
"441278", "Bridgwater",
"441829", "Tarporley",
"442843", "Newcastle\ \(Co\.\ Down\)",
"4414233", "Boroughbridge",
"441971", "Scourie",
"441641", "Strathy",
"441878", "Lochboisdale",
"441579", "Liskeard",
"4416860", "Newtown\/Llanidloes",
"441704", "Southport",
"441924", "Wakefield",
"441700", "Rothesay",
"441920", "Ware",
"441707", "Welwyn\ Garden\ City",
"441557", "Kirkcudbright",
"441550", "Llandovery",
"441528", "Laggan",
"441554", "Llanelli",
"44241", "Coventry",
"441490", "Corwen",
"441371", "Great\ Dunmow",
"441497", "Hay\-on\-Wye",
"441608", "Chipping\ Norton",
"442881", "Newtownstewart",
"44147985", "Dulnain\ Bridge",
"441572", "Oakham",
"441494", "High\ Wycombe",
"4415073", "Louth",
"44147986", "Cairngorm",
"441683", "Moffat",
"441749", "Shepton\ Mallet",
"4413885", "Stanhope\ \(Eastgate\)",
"441325", "Darlington",
"441326", "Falmouth",
"441573", "Kelso",
"441485", "Hunstanton",
"441268", "Basildon",
"441539", "Kendal",
"441743", "Shrewsbury",
"441689", "Orpington",
"4413394", "Ballater",
"4418903", "Coldstream",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441477", "Holmes\ Chapel",
"4413393", "Aboyne",
"4412298", "Barrow\-in\-Furness",
"4418904", "Coldstream",
"441592", "Kirkcaldy",
"441474", "Gravesend",
"44117", "Bristol",
"441466", "Huntly",
"441726", "St\ Austell",
"4414236", "Harrogate",
"442827", "Ballymoney",
"441465", "Girvan",
"441725", "Rockbourne",
"441905", "Worcester",
"442820", "Ballycastle",
"441599", "Kyle",
"441803", "Torquay",
"441288", "Bude",
"441343", "Elgin",
"4416862", "Llanidloes",
"441655", "Maybole",
"441888", "Turriff",
"441656", "Bridgend",
"441452", "Gloucester",
"441981", "Wormbridge",
"441669", "Rothbury",
"4415074", "Alford\ \(Lincs\)",
"441244", "Chester",
"441342", "East\ Grinstead",
"441844", "Thame",
"441300", "Cerne\ Abbas",
"441307", "Forfar",
"441202", "Bournemouth",
"441453", "Dursley",
"441840", "Camelford",
"441304", "Dover",
"44161", "Manchester",
"441210", "Birmingham",
"441349", "Dingwall",
"44113", "Leeds",
"441217", "Birmingham",
"441809", "Tomdoun",
"441214", "Birmingham",
"441593", "Lybster",
"441663", "New\ Mills",
"441209", "Redruth",
"441771", "Maud",
"441744", "St\ Helens",
"4414237", "Harrogate",
"441740", "Sedgefield",
"441747", "Shaftesbury",
"441499", "Inveraray",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441702", "Southend\-on\-Sea",
"442898", "Belfast",
"441922", "Walsall",
"4414305", "North\ Cave",
"4414345", "Haltwhistle",
"441978", "Wrexham",
"4418475", "Thurso",
"441566", "Launceston",
"441559", "Llandysul",
"441565", "Knutsford",
"441871", "Castlebay",
"4412290", "Barrow\-in\-Furness\/Millom",
"441570", "Lampeter",
"441271", "Barnstaple",
"441577", "Kinross",
"441695", "Skelmersdale",
"441709", "Rotherham",
"441929", "Wareham",
"441492", "Colwyn\ Bay",
"441687", "Mallaig",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441825", "Uckfield",
"441684", "Malvern",
"44147981", "Aviemore",
"4414231", "Harrogate\/Boroughbridge",
"441938", "Welshpool",
"441225", "Bath",
"441534", "Jersey",
"441226", "Barnsley",
"441530", "Coalville",
"441493", "Great\ Yarmouth",
"441788", "Rugby",
"4419754", "Alford\ \(Aberdeen\)",
"441553", "Kings\ Lynn",
"441368", "Dunbar",
"441923", "Watford",
"4419644", "Patrington",
"441664", "Melton\ Mowbray",
"4412292", "Barrow\-in\-Furness",
"441667", "Nairn",
"4419643", "Patrington",
"441590", "Lymington",
"441433", "Hathersage",
"441597", "Llandrindod\ Wells",
"441675", "Coleshill",
"441291", "Chepstow",
"4415395", "Grange\-over\-Sands",
"441946", "Whitehaven",
"4419753", "Strathdon",
"441676", "Meriden",
"441472", "Grimsby",
"441594", "Lydney",
"441945", "Wisbech",
"441213", "Birmingham",
"441457", "Glossop",
"441843", "Thanet",
"4416868", "Newtown",
"441450", "Hawick",
"441454", "Chipping\ Sodbury",
"441428", "Haslemere",
"44115", "Nottingham",
"441303", "Folkestone",
"441768", "Penrith",
"442829", "Kilrea",
"441479", "Grantown\-on\-Spey",
"441916", "Tyneside",
"441915", "Sunderland",
"441243", "Chichester",
"441388", "Bishop\ Auckland",
"441842", "Thetford",
"441207", "Consett",
"441501", "Harthill",
"441200", "Clitheroe",
"441204", "Bolton",
"44239", "Portsmouth",
"441302", "Doncaster",
"441340", "Craigellachie\ \(Aberlour\)",
"441347", "Easingwold",
"441242", "Cheltenham",
"441807", "Ballindalloch",
"442838", "Portadown",
"441751", "Pickering",
"441439", "Helmsley",
"441344", "Bracknell",
"441145", "Sheffield",
"441309", "Forres",
"4414239", "Boroughbridge",
"441586", "Campbeltown",
"441621", "Maldon",
"441636", "Newark\-on\-Trent",
"441432", "Hereford",
"4418515", "Stornoway",
"441249", "Chippenham",
"441635", "Newbury",
"441212", "Birmingham",
"441473", "Ipswich",
"441947", "Whitby",
"4412295", "Barrow\-in\-Furness",
"441674", "Montrose",
"441670", "Morpeth",
"4418470", "Thurso\/Tongue",
"441944", "West\ Heslerton",
"441677", "Bedale",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441665", "Alnwick",
"441548", "Kingsbridge",
"441462", "Hitchin",
"441666", "Malmesbury",
"441902", "Wolverhampton",
"441722", "Salisbury",
"441659", "Sanquhar",
"441917", "Sunderland",
"441910", "Tyneside\/Durham\/Sunderland",
"4415079", "Alford\ \(Lincs\)",
"44238", "Southampton",
"441914", "Tyneside",
"441778", "Bourne",
"441909", "Worksop",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441456", "Glenurquhart",
"442868", "Kesh",
"441729", "Settle",
"441652", "Brigg",
"441469", "Killingholme",
"4413391", "Aboyne\/Ballater",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441455", "Hinckley",
"4414300", "North\ Cave\/Market\ Weighton",
"441805", "Torrington",
"441346", "Fraserburgh",
"441738", "Perth",
"441806", "Shetland",
"441653", "Malton",
"441398", "Dulverton",
"441206", "Colchester",
"44141", "Glasgow",
"441205", "Boston",
"441637", "Newquay",
"441630", "Market\ Drayton",
"441634", "Medway",
"4418909", "Ayton",
"441988", "Wigtown",
"441584", "Ludlow",
"4413397", "Ballater",
"441144", "Sheffield",
"4418512", "Stornoway",
"441463", "Inverness",
"441580", "Cranbrook",
"441723", "Scarborough",
"441903", "Worthing",
"441140", "Sheffield",
"4418907", "Ayton",
"441798", "Pulborough",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"4414302", "North\ Cave",
"4414372", "Clynderwen\ \(Clunderwen\)",
"442840", "Banbridge",
"441745", "Rhyl",
"442844", "Downpatrick",
"4414342", "Bellingham",
"4413873", "Langholm",
"441746", "Bridgnorth",
"4413399", "Ballater",
"441408", "Golspie",
"4418472", "Thurso",
"441576", "Lockerbie",
"441323", "Eastbourne",
"441968", "Penicuik",
"441694", "Church\ Stretton",
"441690", "Betws\-y\-Coed",
"441697", "Brampton",
"441575", "Kirriemuir",
"441261", "Banff",
"441567", "Killin",
"441483", "Guildford",
"441560", "Moscow",
"441564", "Lapworth",
"441224", "Aberdeen",
"441258", "Blandford",
"441535", "Keighley",
"441322", "Dartford",
"4418901", "Coldstream\/Ayton",
"4415077", "Louth",
"441536", "Kettering",
"441227", "Canterbury",
"441482", "Kingston\-upon\-Hull",
"441827", "Tamworth",
"441951", "Colonsay",
"441685", "Merthyr\ Tydfil",
"441858", "Market\ Harborough",
"441824", "Ruthin",
"4418510", "Great\ Bernera\/Stornoway",
"4419646", "Patrington",
"441329", "Fareham",
"4419756", "Strathdon",
"441489", "Bishops\ Waltham",};

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