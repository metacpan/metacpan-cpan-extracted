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
our $VERSION = 1.20210602223259;

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
                  69[7-9]|
                  70[059]
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
                  69[7-9]|
                  70[059]
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
$areanames{en} = {"441422", "Halifax",
"441543", "Cannock",
"441647", "Moretonhampstead",
"441747", "Shaftesbury",
"441559", "Llandysul",
"441947", "Whitby",
"442882", "Omagh",
"441337", "Ladybank",
"441871", "Castlebay",
"441531", "Ledbury",
"4413398", "Aboyne",
"441499", "Inveraray",
"44141", "Glasgow",
"441141", "Sheffield",
"441259", "Alloa",
"441243", "Chichester",
"4418905", "Ayton",
"441343", "Elgin",
"441359", "Pakenham",
"4419758", "Strathdon",
"441620", "North\ Berwick",
"441926", "Warwick",
"441924", "Wakefield",
"441933", "Wellingborough",
"441869", "Bicester",
"441720", "Isles\ of\ Scilly",
"441803", "Torquay",
"441726", "St\ Austell",
"441633", "Newport",
"4412294", "Barrow\-in\-Furness",
"441624", "Isle\ of\ Man",
"441920", "Ware",
"441626", "Newton\ Abbot",
"441877", "Callander",
"441724", "Scunthorpe",
"441733", "Peterborough",
"441463", "Inverness",
"441409", "Holsworthy",
"441237", "Bideford",
"441488", "Hungerford",
"441435", "Heathfield",
"441665", "Alnwick",
"44238", "Southampton",
"442828", "Larne",
"441765", "Ripon",
"441641", "Strathy",
"441250", "Blairgowrie",
"441496", "Port\ Ellen",
"441494", "High\ Wycombe",
"4413392", "Aboyne",
"441487", "Warboys",
"441285", "Cirencester",
"4413399", "Ballater",
"441254", "Blackburn",
"441256", "Basingstoke",
"441490", "Corwen",
"442827", "Ballymoney",
"441556", "Castle\ Douglas",
"442311", "Southampton",
"441702", "Southend\-on\-Sea",
"441554", "Llanelli",
"441878", "Lochboisdale",
"441572", "Oakham",
"441902", "Wolverhampton",
"441832", "Clopton",
"441538", "Ipstones",
"441550", "Llandovery",
"4413391", "Aboyne\/Ballater",
"442844", "Downpatrick",
"441992", "Lea\ Valley",
"4416867", "Llanidloes",
"441825", "Uckfield",
"441792", "Swansea",
"441692", "North\ Walsham",
"4418516", "Great\ Bernera",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"442840", "Banbridge",
"441866", "Kilchrenan",
"4419752", "Alford\ \(Aberdeen\)",
"441354", "Chatteris",
"441356", "Brechin",
"441864", "Abington\ \(Crawford\)",
"441929", "Wareham",
"442821", "Martinstown",
"441400", "Honington",
"441748", "Richmond",
"441404", "Honiton",
"441372", "Esher",
"441481", "Guernsey",
"441948", "Whitchurch",
"441406", "Holbeach",
"441629", "Matlock",
"441215", "Birmingham",
"441350", "Dunkeld",
"4419759", "Alford\ \(Aberdeen\)",
"441729", "Settle",
"44147985", "Dulnain\ Bridge",
"442890", "Belfast",
"441566", "Launceston",
"441427", "Gainsborough",
"4418512", "Stornoway",
"441564", "Lapworth",
"441642", "Middlesbrough",
"44247", "Coventry",
"441919", "Durham",
"441225", "Bath",
"441942", "Wigan",
"442894", "Antrim",
"441332", "Derby",
"442887", "Dungannon",
"4418519", "Great\ Bernera",
"441560", "Moscow",
"4415396", "Sedbergh",
"4414375", "Clynderwen\ \(Clunderwen\)",
"442896", "Belfast",
"441260", "Congleton",
"441525", "Leighton\ Buzzard",
"441798", "Pulborough",
"441698", "Motherwell",
"4415074", "Alford\ \(Lincs\)",
"441264", "Andover",
"4418511", "Great\ Bernera\/Stornoway",
"4419756", "Strathdon",
"441856", "Orkney",
"441440", "Haverhill",
"441364", "Ashburton",
"441608", "Chipping\ Norton",
"441366", "Downham\ Market",
"441854", "Ullapool",
"441708", "Romford",
"441885", "Pencombe",
"441578", "Lauder",
"441872", "Truro",
"441444", "Haywards\ Heath",
"441142", "Sheffield",
"441360", "Killearn",
"4413396", "Ballater",
"44147981", "Aviemore",
"441908", "Milton\ Keynes",
"441446", "Barry",
"441838", "Dalmally",
"4413885", "Stanhope\ \(Eastgate\)",
"441989", "Ross\-on\-Wye",
"441325", "Darlington",
"441278", "Bridgwater",
"442881", "Newtownstewart",
"441789", "Stratford\-upon\-Avon",
"441689", "Orpington",
"4418474", "Thurso",
"4414304", "North\ Cave",
"441371", "Great\ Dunmow",
"441482", "Kingston\-upon\-Hull",
"4416973", "Wigton",
"441277", "Brentwood",
"4416863", "Llanidloes",
"4419644", "Patrington",
"441269", "Ammanford",
"441475", "Greenock",
"4414344", "Bellingham",
"4414234", "Boroughbridge",
"441916", "Tyneside",
"441691", "Oswestry",
"441914", "Tyneside",
"441707", "Welwyn\ Garden\ City",
"441569", "Stonehaven",
"4418518", "Stornoway",
"4416860", "Newtown\/Llanidloes",
"441503", "Looe",
"44281", "Northern\ Ireland",
"441577", "Kinross",
"441673", "Market\ Rasen",
"441773", "Ripley",
"441910", "Tyneside\/Durham\/Sunderland",
"441837", "Okehampton",
"441571", "Lochinver",
"441955", "Wick",
"441984", "Watchet\ \(Williton\)",
"441780", "Stamford",
"441997", "Strathpeffer",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441986", "Bungay",
"441980", "Amesbury",
"441797", "Rye",
"441784", "Staines",
"441697", "Brampton",
"441786", "Stirling",
"441684", "Malvern",
"441655", "Maybole",
"441593", "Lybster",
"441428", "Haslemere",
"441843", "Thanet",
"441293", "Crawley",
"441369", "Dunoon",
"441303", "Folkestone",
"441859", "Harris",
"441449", "Stowmarket",
"441377", "Driffield",
"441453", "Dursley",
"441271", "Barnstaple",
"4415394", "Hawkshead",
"4415242", "Hornby",
"442885", "Ballygawley",
"441227", "Canterbury",
"442838", "Portadown",
"4418903", "Coldstream",
"441425", "Ringwood",
"441923", "Watford",
"441934", "Weston\-super\-Mare",
"4419754", "Alford\ \(Aberdeen\)",
"441758", "Pwllheli",
"441730", "Petersfield",
"441806", "Shetland",
"441630", "Market\ Drayton",
"441346", "Fraserburgh",
"4415076", "Louth",
"441460", "Chard",
"441344", "Bracknell",
"441527", "Redditch",
"4418900", "Coldstream\/Ayton",
"441466", "Huntly",
"441464", "Insch",
"441340", "Craigellachie\ \(Aberlour\)",
"441636", "Newark\-on\-Trent",
"4412298", "Barrow\-in\-Furness",
"441723", "Scarborough",
"441736", "Penzance",
"441634", "Medway",
"441623", "Mansfield",
"4413394", "Ballater",
"441246", "Chesterfield",
"44115", "Nottingham",
"441896", "Galashiels",
"441887", "Aberfeldy",
"441244", "Chester",
"4418476", "Tongue",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441544", "Kington",
"441546", "Lochgilphead",
"441432", "Hereford",
"441540", "Kingussie",
"441327", "Daventry",
"4414377", "Haverfordwest",
"441962", "Winchester",
"441477", "Holmes\ Chapel",
"441349", "Dingwall",
"4414346", "Hexham",
"4414236", "Harrogate",
"441809", "Tomdoun",
"441939", "Wem",
"441863", "Ardgay",
"441282", "Burnley",
"4412299", "Millom",
"441353", "Ely",
"4419646", "Patrington",
"4412292", "Barrow\-in\-Furness",
"441639", "Neath",
"441328", "Fakenham",
"441275", "Clevedon",
"4417687", "Keswick",
"441403", "Horsham",
"441469", "Killingholme",
"4414306", "Market\ Weighton",
"441835", "St\ Boswells",
"441905", "Worcester",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441575", "Kirriemuir",
"4412291", "Barrow\-in\-Furness\/Millom",
"441951", "Colonsay",
"441651", "Oldmeldrum",
"441888", "Turriff",
"441582", "Luton",
"441751", "Pickering",
"441757", "Selby",
"441549", "Lairg",
"441695", "Skelmersdale",
"441553", "Kings\ Lynn",
"441795", "Sittingbourne",
"441528", "Laggan",
"441822", "Tavistock",
"441995", "Garstang",
"441957", "Mid\ Yell",
"4420", "London",
"441212", "Birmingham",
"441493", "Great\ Yarmouth",
"441375", "Grays\ Thurrock",
"441228", "Carlisle",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"442837", "Armagh",
"441382", "Dundee",
"441253", "Blackpool",
"441249", "Chippenham",
"441899", "Biggar",
"441335", "Ashbourne",
"441945", "Wisbech",
"441745", "Rhyl",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441388", "Bishop\ Auckland",
"441661", "Prudhoe",
"4418478", "Thurso",
"441761", "Temple\ Cloud",
"442877", "Limavady",
"441431", "Helmsdale",
"44151", "Liverpool",
"441599", "Kyle",
"441299", "Bewdley",
"441309", "Forres",
"441363", "Crediton",
"441828", "Coupar\ Angus",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441522", "Lincoln",
"441443", "Pontypridd",
"441535", "Keighley",
"4414302", "North\ Cave",
"4414239", "Boroughbridge",
"4414349", "Bellingham",
"441145", "Sheffield",
"441875", "Tranent",
"4412296", "Barrow\-in\-Furness",
"4419642", "Hornsea",
"4419649", "Hornsea",
"4418907", "Ayton",
"441209", "Redruth",
"441588", "Bishops\ Castle",
"441263", "Cromer",
"441882", "Kinloch\ Rannoch",
"44131", "Edinburgh",
"4414342", "Bellingham",
"4414232", "Harrogate",
"4415078", "Alford\ \(Lincs\)",
"4414309", "Market\ Weighton",
"441767", "Sandy",
"44241", "Coventry",
"4414231", "Harrogate\/Boroughbridge",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441667", "Nairn",
"441509", "Loughborough",
"441563", "Kilmarnock",
"441288", "Bude",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"442871", "Londonderry",
"442893", "Ballyclare",
"4419641", "Hornsea\/Patrington",
"441322", "Dartford",
"4412180", "Birmingham",
"441967", "Strontian",
"4414301", "North\ Cave\/Market\ Weighton",
"441779", "Peterhead",
"441235", "Abingdon",
"441306", "Dorking",
"441768", "Penrith",
"442825", "Ballymena",
"441381", "Fortrose",
"441472", "Grimsby",
"4418471", "Thurso\/Tongue",
"441668", "Bamburgh",
"441304", "Dover",
"441287", "Guisborough",
"441844", "Thame",
"441294", "Ardrossan",
"441296", "Aylesbury",
"441450", "Hawick",
"441438", "Stevenage",
"441840", "Camelford",
"441211", "Birmingham",
"441456", "Glenurquhart",
"441290", "Cumnock",
"441454", "Chipping\ Sodbury",
"441968", "Penicuik",
"441485", "Hunstanton",
"441300", "Cerne\ Abbas",
"4416865", "Newtown",
"4418479", "Tongue",
"441983", "Isle\ of\ Wight",
"441821", "Kinrossie",
"4413873", "Langholm",
"441590", "Lymington",
"442866", "Enniskillen",
"441594", "Lydney",
"441683", "Moffat",
"4418472", "Thurso",
"441581", "New\ Luce",
"441752", "Plymouth",
"441506", "Bathgate",
"4418514", "Great\ Bernera",
"441652", "Brigg",
"441770", "Isle\ of\ Arran",
"441913", "Durham",
"441974", "Llanon",
"441670", "Morpeth",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441827", "Tamworth",
"44147982", "Nethy\ Bridge",
"441676", "Meriden",
"441970", "Aberystwyth",
"441674", "Montrose",
"441776", "Stranraer",
"441952", "Telford",
"4417683", "Appleby",
"441217", "Birmingham",
"4419648", "Hornsea",
"441200", "Clitheroe",
"4415079", "Alford\ \(Lincs\)",
"4414308", "Market\ Weighton",
"4414238", "Harrogate",
"441387", "Dumfries",
"44116", "Leicester",
"4414348", "Hexham",
"441394", "Felixstowe",
"4415072", "Spilsby\ \(Horncastle\)",
"441206", "Colchester",
"441204", "Bolton",
"441870", "Isle\ of\ Benbecula",
"441558", "Llandeilo",
"441530", "Coalville",
"441852", "Kilmelford",
"441362", "Dereham",
"441140", "Sheffield",
"441534", "Jersey",
"441144", "Sheffield",
"441442", "Hemel\ Hempstead",
"441536", "Kettering",
"441727", "St\ Albans",
"441874", "Brecon",
"441876", "Lochmaddy",
"44147986", "Cairngorm",
"441236", "Coatbridge",
"441223", "Cambridge",
"441234", "Bedford",
"44239", "Portsmouth",
"441258", "Blandford",
"441744", "St\ Helens",
"441646", "Milford\ Haven",
"441644", "New\ Galloway",
"441746", "Bridgnorth",
"441562", "Kidderminster",
"441358", "Ellon",
"441330", "Banchory",
"441334", "St\ Andrews",
"441323", "Eastbourne",
"442892", "Lisburn",
"441740", "Sedgefield",
"441944", "West\ Heslerton",
"441946", "Whitehaven",
"441408", "Golspie",
"441489", "Bishops\ Waltham",
"4418517", "Stornoway",
"441621", "Maldon",
"441721", "Peebles",
"441262", "Bridlington",
"4416866", "Newtown",
"441883", "Caterham",
"442829", "Kilrea",
"4413390", "Aboyne\/Ballater",
"441775", "Spalding",
"441675", "Coleshill",
"442310", "Portsmouth",
"441239", "Cardigan",
"441982", "Builth\ Wells",
"441505", "Johnstone",
"4412295", "Barrow\-in\-Furness",
"441782", "Stoke\-on\-Trent",
"4413393", "Aboyne",
"441395", "Budleigh\ Salterton",
"441473", "Ipswich",
"441357", "Strathaven",
"441205", "Boston",
"441879", "Scarinish",
"441539", "Kendal",
"441407", "Holyhead",
"441491", "Henley\-on\-Thames",
"441455", "Hinckley",
"4419753", "Strathdon",
"441497", "Hay\-on\-Wye",
"441484", "Huddersfield",
"442820", "Ballycastle",
"441480", "Huntingdon",
"441305", "Dorchester",
"441257", "Coppull",
"441295", "Banbury",
"441845", "Thirsk",
"441753", "Slough",
"441928", "Runcorn",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441653", "Malton",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441557", "Kirkcudbright",
"441749", "Shepton\ Mallet",
"441912", "Tyneside",
"441949", "Whatton",
"4418904", "Coldstream",
"441728", "Saxmundham",
"441953", "Wymondham",
"441628", "Maidenhead",
"442841", "Rostrevor",
"441261", "Banff",
"4416868", "Newtown",
"441922", "Walsall",
"4418510", "Great\ Bernera\/Stornoway",
"441245", "Chelmsford",
"441895", "Uxbridge",
"441857", "Sanday",
"441918", "Tyneside",
"441367", "Faringdon",
"44118", "Reading",
"441379", "Diss",
"441722", "Salisbury",
"441622", "Maidstone",
"4418513", "Stornoway",
"442891", "Bangor\ \(Co\.\ Down\)",
"44161", "Manchester",
"441799", "Saffron\ Walden",
"4417684", "Pooley\ Bridge",
"441545", "Llanarth",
"441561", "Laurencekirk",
"441763", "Royston",
"441709", "Rotherham",
"441663", "New\ Mills",
"441609", "Northallerton",
"4419645", "Hornsea",
"4419467", "Gosforth",
"441567", "Killin",
"4414305", "North\ Cave",
"441424", "Hastings",
"441433", "Hathersage",
"442880", "Carrickmore",
"442886", "Cookstown",
"441579", "Liskeard",
"4414235", "Harrogate",
"4414345", "Haltwhistle",
"442897", "Saintfield",
"441420", "Alton",
"441909", "Worksop",
"441963", "Wincanton",
"441465", "Girvan",
"441988", "Wigtown",
"441279", "Bishops\ Stortford",
"441635", "Newbury",
"441935", "Yeovil",
"441805", "Torrington",
"441267", "Carmarthen",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441361", "Duns",
"441788", "Rugby",
"4419757", "Strathdon",
"441690", "Betws\-y\-Coed",
"441987", "Ebbsfleet",
"441790", "Spilsby",
"441994", "St\ Clears",
"442842", "Kircubbin",
"4416861", "Newtown\/Llanidloes",
"441268", "Basildon",
"441583", "Carradale",
"441694", "Church\ Stretton",
"441687", "Mallaig",
"441796", "Pitlochry",
"441794", "Romsey",
"441911", "Tyneside\/Durham\/Sunderland",
"441787", "Sudbury",
"441283", "Burton\-on\-Trent",
"441862", "Tain",
"441568", "Leominster",
"4416862", "Llanidloes",
"441352", "Mold",
"4416869", "Newtown",
"442898", "Belfast",
"4418475", "Thurso",
"441376", "Braintree",
"441276", "Camberley",
"441213", "Birmingham",
"441274", "Bradford",
"441492", "Colwyn\ Bay",
"441383", "Dunfermline",
"441252", "Aldershot",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441270", "Crewe",
"441570", "Lampeter",
"4413397", "Ballater",
"441429", "Hartlepool",
"441917", "Sunderland",
"441830", "Kirkwhelpington",
"441704", "Southport",
"441858", "Market\ Harborough",
"441606", "Northwich",
"441900", "Workington",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441368", "Dunbar",
"441604", "Northampton",
"441706", "Rochdale",
"441700", "Rothesay",
"441834", "Narberth",
"441823", "Taunton",
"441904", "York",
"441981", "Wormbridge",
"441600", "Monmouth",
"441576", "Lockerbie",
"442889", "Fivemiletown",
"4415075", "Spilsby\ \(Horncastle\)",
"441880", "Tarbert",
"441631", "Oban",
"441445", "Gairloch",
"4418901", "Coldstream\/Ayton",
"441461", "Gretna",
"441341", "Barmouth",
"441855", "Ballachulish",
"441884", "Tiverton",
"441931", "Shap",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"4414307", "Market\ Weighton",
"441320", "Fort\ Augustus",
"441659", "Sanquhar",
"441547", "Knighton",
"441759", "Pocklington",
"4418909", "Ayton",
"441643", "Minehead",
"4419647", "Patrington",
"441743", "Shrewsbury",
"4418902", "Coldstream",
"441943", "Guiseley",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"4414347", "Hexham",
"441324", "Falkirk",
"4414237", "Harrogate",
"441959", "Westerham",
"441326", "Falmouth",
"441224", "Aberdeen",
"441233", "Ashford\ \(Kent\)",
"441226", "Barnsley",
"442895", "Belfast",
"441565", "Knutsford",
"441347", "Easingwold",
"44291", "Cardiff",
"441479", "Grantown\-on\-Spey",
"441520", "Lochcarron",
"441937", "Wetherby",
"441241", "Arbroath",
"441807", "Ballindalloch",
"441637", "Newquay",
"441737", "Redhill",
"441873", "Abergavenny",
"441467", "Inverurie",
"441143", "Sheffield",
"441526", "Martin",
"441524", "Lancaster",
"441348", "Fishguard",
"441785", "Stafford",
"441972", "Glenborrodale",
"441685", "Merthyr\ Tydfil",
"441654", "Machynlleth",
"441756", "Skipton",
"441754", "Skegness",
"441808", "Tomatin",
"441502", "Lowestoft",
"441950", "Sandwick",
"441938", "Welshpool",
"441656", "Bridgend",
"4413395", "Aboyne",
"441650", "Cemmaes\ Road",
"441638", "Newmarket",
"441329", "Fareham",
"4412290", "Barrow\-in\-Furness\/Millom",
"441750", "Selkirk",
"441738", "Perth",
"4415077", "Louth",
"441954", "Madingley",
"441985", "Warminster",
"441672", "Marlborough",
"4418908", "Coldstream",
"441772", "Preston",
"441483", "Guildford",
"442830", "Newry",
"441202", "Bournemouth",
"441889", "Rugeley",
"4412293", "Millom",
"441392", "Exeter",
"441842", "Thetford",
"441548", "Kingsbridge",
"441292", "Ayr",
"441474", "Gravesend",
"441302", "Doncaster",
"4415395", "Grange\-over\-Sands",
"4414376", "Haverfordwest",
"441476", "Grantham",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441529", "Sleaford",
"441452", "Gloucester",
"4418477", "Tongue",
"44113", "Leeds",
"4419755", "Alford\ \(Aberdeen\)",
"441915", "Sunderland",
"441248", "Bangor\ \(Gwynedd\)",
"441592", "Kirkcaldy",
"441625", "Macclesfield",
"442868", "Kesh",
"441725", "Rockbourne",
"4414379", "Haverfordwest",
"4418515", "Stornoway",
"44117", "Bristol",
"441389", "Dumbarton",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441892", "Tunbridge\ Wells",
"441598", "Lynton",
"441242", "Cheltenham",
"441925", "Warrington",
"441542", "Keith",
"441436", "Helensburgh",
"441298", "Buxton",
"441848", "Thornhill",
"441664", "Melton\ Mowbray",
"441308", "Bridport",
"441766", "Porthmadog",
"441764", "Crieff",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441666", "Malmesbury",
"441760", "Swaffham",
"441829", "Tarporley",
"441458", "Glastonbury",
"4414300", "North\ Cave\/Market\ Weighton",
"4419640", "Hornsea\/Patrington",
"442870", "Coleraine",
"441208", "Bodmin",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"4414230", "Harrogate\/Boroughbridge",
"441398", "Dulverton",
"441342", "East\ Grinstead",
"441978", "Wrexham",
"4414303", "North\ Cave",
"4416864", "Llanidloes",
"4419643", "Patrington",
"4413882", "Stanhope\ \(Eastgate\)",
"441508", "Brooke",
"4416974", "Raughton\ Head",
"441289", "Berwick\-upon\-Tweed",
"441932", "Weybridge",
"441732", "Sevenoaks",
"441678", "Bala",
"441462", "Hitchin",
"4414343", "Haltwhistle",
"4414233", "Boroughbridge",
"441778", "Bourne",
"441603", "Norwich",
"441669", "Rothbury",
"441769", "South\ Molton",
"441977", "Pontefract",
"441439", "Helmsley",
"44292", "Cardiff",
"441591", "Llanwrtyd\ Wells",
"44147983", "Boat\ of\ Garten",
"441573", "Kelso",
"441677", "Bedale",
"4418473", "Thurso",
"441833", "Barnard\ Castle",
"441969", "Leyburn",
"441777", "Retford",
"441824", "Ruthin",
"441903", "Worthing",
"441405", "Goole",
"441380", "Devizes",
"441214", "Birmingham",
"441273", "Brighton",
"441216", "Birmingham",
"441451", "Stow\-on\-the\-Wold",
"441291", "Chepstow",
"441210", "Birmingham",
"441841", "Newquay\ \(Padstow\)",
"441355", "East\ Kilbride",
"441207", "Consett",
"441865", "Oxford",
"4418470", "Thurso\/Tongue",
"441386", "Evesham",
"441301", "Arrochar",
"4414378", "Haverfordwest",
"441384", "Dudley",
"441397", "Fort\ William",
"441286", "Caernarfon",
"441284", "Bury\ St\ Edmunds",
"441297", "Axminster",
"44147984", "Carrbridge",
"441307", "Forfar",
"441255", "Clacton\-on\-Sea",
"441373", "Frome",
"4415073", "Louth",
"441495", "Pontypool",
"441457", "Glossop",
"441280", "Buckingham",
"441580", "Cranbrook",
"442867", "Lisnaskea",
"441993", "Witney",
"441771", "Maud",
"4418906", "Ayton",
"441671", "Newton\ Stewart",
"4412297", "Millom",
"441971", "Scourie",
"441793", "Swindon",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441555", "Lanark",
"441501", "Harthill",
"441584", "Ludlow",
"441597", "Llandrindod\ Wells",
"441586", "Campbeltown",
"442879", "Magherafelt",};

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