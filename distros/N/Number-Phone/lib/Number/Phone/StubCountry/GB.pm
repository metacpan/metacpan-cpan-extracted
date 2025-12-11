# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20251210153522;

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
$areanames{en} = {"4418471", "Thurso\/Tongue",
"441772", "Preston",
"441666", "Malmesbury",
"441888", "Turriff",
"441697", "Brampton",
"441641", "Strathy",
"441425", "Ringwood",
"4414376", "Haverfordwest",
"4414238", "Harrogate",
"441584", "Ludlow",
"441786", "Stirling",
"441636", "Newark\-on\-Trent",
"441954", "Madingley",
"44115", "Nottingham",
"441751", "Pickering",
"441809", "Tomdoun",
"441779", "Peterhead",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441525", "Leighton\ Buzzard",
"4413392", "Aboyne",
"441675", "Coleshill",
"4419648", "Hornsea",
"441387", "Dumfries",
"441484", "Huddersfield",
"4415394", "Hawkshead",
"441918", "Tyneside",
"441588", "Bishops\ Castle",
"441667", "Nairn",
"441379", "Diss",
"4414379", "Haverfordwest",
"441509", "Loughborough",
"441637", "Newquay",
"441787", "Sudbury",
"4414237", "Harrogate",
"441884", "Tiverton",
"441142", "Sheffield",
"441914", "Tyneside",
"441825", "Uckfield",
"441372", "Esher",
"441488", "Hungerford",
"441502", "Lowestoft",
"441900", "Workington",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441903", "Worthing",
"4419647", "Patrington",
"441386", "Evesham",
"441409", "Holsworthy",
"441650", "Cemmaes\ Road",
"441653", "Malton",
"441732", "Sevenoaks",
"441254", "Blackburn",
"441740", "Sedgefield",
"441724", "Scunthorpe",
"4412298", "Barrow\-in\-Furness",
"441827", "Tamworth",
"441743", "Shrewsbury",
"441526", "Martin",
"441676", "Meriden",
"441785", "Stafford",
"44114702", "Sheffield",
"441635", "Newbury",
"442848", "Northern\ Ireland",
"441328", "Fakenham",
"441689", "Orpington",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441392", "Exeter",
"441665", "Alnwick",
"441769", "South\ Molton",
"441608", "Chipping\ Norton",
"4416860", "Newtown\/Llanidloes",
"4412297", "Millom",
"441728", "Saxmundham",
"4418514", "Great\ Bernera",
"441369", "Dunoon",
"441677", "Bedale",
"441258", "Blandford",
"441792", "Swansea",
"441527", "Redditch",
"441332", "Derby",
"441200", "Clitheroe",
"441604", "Northampton",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441427", "Gainsborough",
"441362", "Dereham",
"441695", "Skelmersdale",
"442823", "Northern\ Ireland",
"441343", "Elgin",
"442820", "Ballycastle",
"442844", "Downpatrick",
"441324", "Falkirk",
"441340", "Craigellachie\ \(Aberlour\)",
"441799", "Saffron\ Walden",
"441242", "Cheltenham",
"441970", "Aberystwyth",
"441572", "Oakham",
"4419758", "Strathdon",
"441664", "Melton\ Mowbray",
"44121", "Birmingham",
"4419641", "Hornsea\/Patrington",
"441260", "Congleton",
"441622", "Maidstone",
"441479", "Grantown\-on\-Spey",
"441263", "Cromer",
"441887", "Aberfeldy",
"441698", "Motherwell",
"441586", "Campbeltown",
"441784", "Staines",
"441634", "Medway",
"441981", "Wormbridge",
"441302", "Doncaster",
"4414349", "Bellingham",
"441233", "Ashford\ \(Kent\)",
"4418478", "Thurso",
"441725", "Rockbourne",
"441579", "Liskeard",
"441917", "Sunderland",
"441249", "Chippenham",
"441472", "Grimsby",
"441629", "Matlock",
"4414231", "Harrogate\/Boroughbridge",
"441388", "Bishop\ Auckland",
"4416869", "Newtown",
"441451", "Stow\-on\-the\-Wold",
"441255", "Clacton\-on\-Sea",
"441309", "Forres",
"441788", "Rugby",
"4414346", "Hexham",
"441638", "Newmarket",
"441694", "Church\ Stretton",
"441290", "Cumnock",
"442845", "Northern\ Ireland",
"441293", "Crawley",
"441872", "Truro",
"441325", "Darlington",
"441709", "Rotherham",
"441668", "Bamburgh",
"4413394", "Ballater",
"4419757", "Strathdon",
"44114705", "Sheffield",
"441957", "Mid\ Yell",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"44114709", "Sheffield",
"4415075", "Spilsby\ \(Horncastle\)",
"441879", "Scarinish",
"441916", "Tyneside",
"4416866", "Newtown",
"442871", "Londonderry",
"4418477", "Tongue",
"441702", "Southend\-on\-Sea",
"441487", "Warboys",
"442880", "Carrickmore",
"441384", "Dudley",
"442883", "Northern\ Ireland",
"4415242", "Hornby",
"441439", "Helmsley",
"4415079", "Alford\ \(Lincs\)",
"4414303", "North\ Cave",
"441485", "Hunstanton",
"441933", "Wellingborough",
"441256", "Basingstoke",
"441828", "Coupar\ Angus",
"441726", "St\ Austell",
"441273", "Brighton",
"441469", "Killingholme",
"441543", "Cannock",
"441892", "Tunbridge\ Wells",
"441270", "Crewe",
"441942", "Wigan",
"441524", "Lancaster",
"441540", "Kingussie",
"441674", "Montrose",
"441963", "Wincanton",
"4416974", "Raughton\ Head",
"441562", "Kidderminster",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441432", "Hereford",
"441955", "Wick",
"441539", "Kendal",
"441327", "Daventry",
"4418903", "Coldstream",
"442847", "Northern\ Ireland",
"4412291", "Barrow\-in\-Furness\/Millom",
"442891", "Bangor\ \(Co\.\ Down\)",
"441949", "Whatton",
"441899", "Biggar",
"441462", "Hitchin",
"441443", "Pontypridd",
"441569", "Stonehaven",
"4418512", "Stornoway",
"441440", "Haverhill",
"441424", "Hastings",
"441832", "Clopton",
"441528", "Laggan",
"441257", "Coppull",
"4413882", "Stanhope\ \(Eastgate\)",
"441678", "Bala",
"4416865", "Newtown",
"441862", "Tain",
"441499", "Inveraray",
"441993", "Witney",
"441840", "Camelford",
"441915", "Sunderland",
"4415076", "Louth",
"441824", "Ruthin",
"441592", "Kirkcaldy",
"441727", "St\ Albans",
"441843", "Thanet",
"441428", "Haslemere",
"441606", "Northwich",
"441885", "Pencombe",
"441492", "Colwyn\ Bay",
"441869", "Bicester",
"441599", "Kyle",
"442846", "Northern\ Ireland",
"441326", "Falmouth",
"4414345", "Haltwhistle",
"441549", "Lairg",
"441279", "Bishops\ Stortford",
"441463", "Inverness",
"44141", "Glasgow",
"442896", "Belfast",
"441460", "Chard",
"442867", "Lisnaskea",
"441969", "Leyburn",
"441442", "Hemel\ Hempstead",
"441985", "Warminster",
"441433", "Hathersage",
"441939", "Wem",
"442837", "Armagh",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441555", "Lanark",
"441943", "Guiseley",
"441924", "Wakefield",
"441542", "Keith",
"441721", "Peebles",
"441563", "Kilmarnock",
"441449", "Stowmarket",
"441560", "Moscow",
"4412299", "Millom",
"44287", "Northern\ Ireland",
"441962", "Winchester",
"44151", "Liverpool",
"441455", "Hinckley",
"441286", "Caernarfon",
"441530", "Coalville",
"441932", "Weybridge",
"441493", "Great\ Yarmouth",
"441490", "Corwen",
"442866", "Enniskillen",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"44247", "Coventry",
"442897", "Saintfield",
"442841", "Rostrevor",
"4414235", "Harrogate",
"441855", "Ballachulish",
"441863", "Ardgay",
"441593", "Lybster",
"441842", "Thetford",
"441992", "Lea\ Valley",
"4418470", "Thurso\/Tongue",
"441590", "Lymington",
"441928", "Runcorn",
"441830", "Kirkwhelpington",
"4412296", "Barrow\-in\-Furness",
"441833", "Barnard\ Castle",
"4419645", "Hornsea",
"441287", "Guisborough",
"441456", "Glenurquhart",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441285", "Cirencester",
"441239", "Cardigan",
"441481", "Guernsey",
"4419649", "Hornsea",
"441358", "Ellon",
"442877", "Limavady",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"4417687", "Keswick",
"441473", "Ipswich",
"441269", "Ammanford",
"441986", "Bungay",
"44283", "Northern\ Ireland",
"441581", "New\ Luce",
"441300", "Cerne\ Abbas",
"441857", "Sanday",
"441556", "Castle\ Douglas",
"441754", "Skegness",
"441303", "Folkestone",
"4416861", "Newtown\/Llanidloes",
"441951", "Colonsay",
"441972", "Glenborrodale",
"441224", "Aberdeen",
"44286", "Northern\ Ireland",
"441570", "Lampeter",
"4414239", "Boroughbridge",
"441243", "Chichester",
"442895", "Belfast",
"441573", "Kelso",
"441623", "Mansfield",
"441262", "Bridlington",
"441620", "North\ Berwick",
"441644", "New\ Galloway",
"4414377", "Haverfordwest",
"4418513", "Stornoway",
"4419467", "Gosforth",
"441354", "Chatteris",
"441700", "Rothesay",
"442882", "Omagh",
"4418902", "Coldstream",
"4419646", "Patrington",
"441457", "Glossop",
"4412295", "Barrow\-in\-Furness",
"441911", "Tyneside\/Durham\/Sunderland",
"441299", "Bewdley",
"441228", "Carlisle",
"441557", "Kirkcudbright",
"441856", "Orkney",
"4414236", "Harrogate",
"4414378", "Haverfordwest",
"442889", "Fivemiletown",
"441987", "Ebbsfleet",
"441292", "Ayr",
"441758", "Pwllheli",
"441873", "Abergavenny",
"4414302", "North\ Cave",
"441870", "Isle\ of\ Benbecula",
"441225", "Bath",
"442838", "Portadown",
"442894", "Antrim",
"441749", "Shepton\ Mallet",
"442868", "Kesh",
"441659", "Sanquhar",
"441926", "Warwick",
"441760", "Swaffham",
"441671", "Newton\ Stewart",
"441763", "Royston",
"441652", "Brigg",
"441284", "Bury\ St\ Edmunds",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441730", "Petersfield",
"4415078", "Alford\ \(Lincs\)",
"441683", "Moffat",
"441733", "Peterborough",
"4414230", "Harrogate\/Boroughbridge",
"441363", "Crediton",
"441360", "Killearn",
"44131", "Edinburgh",
"442822", "Northern\ Ireland",
"441342", "East\ Grinstead",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"442898", "Belfast",
"4413393", "Aboyne",
"441330", "Banchory",
"441202", "Bournemouth",
"44114700", "Sheffield",
"4419755", "Alford\ \(Aberdeen\)",
"44280", "Northern\ Ireland",
"441288", "Bude",
"4419640", "Hornsea\/Patrington",
"441349", "Dingwall",
"441790", "Spilsby",
"442829", "Kilrea",
"4415077", "Louth",
"441821", "Kinrossie",
"441793", "Swindon",
"441209", "Redruth",
"441355", "East\ Kilbride",
"4418475", "Thurso",
"441454", "Chipping\ Sodbury",
"4414304", "North\ Cave",
"441803", "Torquay",
"441357", "Strathaven",
"4416868", "Newtown",
"441925", "Warrington",
"442310", "Portsmouth",
"4416973", "Wigton",
"4418479", "Tongue",
"441631", "Oban",
"441984", "Watchet\ \(Williton\)",
"44118", "Reading",
"4414348", "Hexham",
"4413873", "Langholm",
"441554", "Llanelli",
"441756", "Skipton",
"441226", "Barnsley",
"441773", "Ripley",
"441661", "Prudhoe",
"441858", "Market\ Harborough",
"4418904", "Coldstream",
"441770", "Isle\ of\ Arran",
"4419759", "Alford\ \(Aberdeen\)",
"441646", "Milford\ Haven",
"4418476", "Tongue",
"441902", "Wolverhampton",
"441356", "Brechin",
"441503", "Looe",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441381", "Fortrose",
"44114704", "Sheffield",
"441140", "Sheffield",
"441458", "Glastonbury",
"441143", "Sheffield",
"44239", "Portsmouth",
"4416867", "Llanidloes",
"441373", "Frome",
"4412290", "Barrow\-in\-Furness\/Millom",
"441757", "Selby",
"4419756", "Strathdon",
"441909", "Worksop",
"441854", "Ullapool",
"441400", "Honington",
"441403", "Horsham",
"441647", "Moretonhampstead",
"4414347", "Hexham",
"441691", "Oswestry",
"441988", "Wigtown",
"441227", "Canterbury",
"441558", "Llandeilo",
"441768", "Penrith",
"441609", "Northallerton",
"441567", "Killin",
"441866", "Kilchrenan",
"441947", "Whitby",
"442849", "Northern\ Ireland",
"441329", "Fareham",
"441794", "Romsey",
"441738", "Perth",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441841", "Newquay\ \(Padstow\)",
"441398", "Dulverton",
"442830", "Newry",
"441334", "St\ Andrews",
"441364", "Ashburton",
"44281", "Northern\ Ireland",
"441496", "Port\ Ellen",
"441467", "Inverurie",
"441322", "Dartford",
"441875", "Tranent",
"442842", "Kircubbin",
"441283", "Burton\-on\-Trent",
"441280", "Buckingham",
"441931", "Shap",
"441684", "Malvern",
"441837", "Okehampton",
"441798", "Pulborough",
"441252", "Aldershot",
"441536", "Kettering",
"44241", "Coventry",
"441896", "Galashiels",
"441271", "Barnstaple",
"441722", "Salisbury",
"4419753", "Strathdon",
"441597", "Llandrindod\ Wells",
"441946", "Whitehaven",
"4413395", "Aboyne",
"441764", "Crieff",
"441475", "Greenock",
"441566", "Launceston",
"441368", "Dunbar",
"441436", "Helensburgh",
"441259", "Alloa",
"441305", "Dorchester",
"4415074", "Alford\ \(Lincs\)",
"441575", "Kirriemuir",
"442893", "Ballyclare",
"441245", "Chelmsford",
"441394", "Felixstowe",
"441729", "Settle",
"441466", "Huntly",
"4418473", "Thurso",
"442890", "Belfast",
"441497", "Hay\-on\-Wye",
"441625", "Macclesfield",
"4414307", "Market\ Weighton",
"441495", "Pontypool",
"441291", "Chepstow",
"441876", "Lochmaddy",
"441577", "Kinross",
"441919", "Durham",
"441778", "Bourne",
"441307", "Forfar",
"441404", "Honiton",
"441882", "Kinloch\ Rannoch",
"441865", "Oxford",
"441144", "Sheffield",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441477", "Holmes\ Chapel",
"441912", "Tyneside",
"441808", "Tomatin",
"442870", "Coleraine",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441835", "St\ Boswells",
"4418907", "Ayton",
"441706", "Rochdale",
"4413399", "Ballater",
"441889", "Rugeley",
"442881", "Newtownstewart",
"44114708", "Sheffield",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441576", "Lockerbie",
"441246", "Chesterfield",
"441877", "Callander",
"441465", "Girvan",
"441971", "Scourie",
"441408", "Golspie",
"441261", "Banff",
"441626", "Newton\ Abbot",
"441582", "Luton",
"4414308", "Market\ Weighton",
"441980", "Amesbury",
"441435", "Heathfield",
"441983", "Isle\ of\ Wight",
"441550", "Llandovery",
"441952", "Telford",
"441306", "Dorking",
"4418510", "Great\ Bernera\/Stornoway",
"4416864", "Llanidloes",
"441489", "Bishops\ Waltham",
"441553", "Kings\ Lynn",
"441895", "Uxbridge",
"4418908", "Coldstream",
"4413396", "Ballater",
"441945", "Wisbech",
"441508", "Brooke",
"441476", "Grantham",
"441565", "Knutsford",
"4414344", "Bellingham",
"441450", "Hawick",
"441453", "Dursley",
"441482", "Kingston\-upon\-Hull",
"441707", "Welwyn\ Garden\ City",
"441959", "Westerham",
"441535", "Keighley",
"441834", "Narberth",
"441948", "Whitchurch",
"441505", "Johnstone",
"441687", "Mallaig",
"441737", "Redhill",
"441568", "Leominster",
"441145", "Sheffield",
"441864", "Abington\ \(Crawford\)",
"441767", "Sandy",
"4415072", "Spilsby\ \(Horncastle\)",
"441375", "Grays\ Thurrock",
"441822", "Tavistock",
"441538", "Ipstones",
"441796", "Pitlochry",
"441594", "Lydney",
"441405", "Goole",
"4418519", "Great\ Bernera",
"4415395", "Grange\-over\-Sands",
"441438", "Stevenage",
"44114703", "Sheffield",
"441366", "Downham\ Market",
"441494", "High\ Wycombe",
"442821", "Martinstown",
"441341", "Barmouth",
"441397", "Fort\ William",
"441829", "Tarporley",
"441651", "Oldmeldrum",
"441598", "Lynton",
"4413390", "Aboyne\/Ballater",
"441736", "Penzance",
"441805", "Torrington",
"441534", "Jersey",
"441923", "Watford",
"441797", "Rye",
"441522", "Lincoln",
"441920", "Ware",
"441838", "Dalmally",
"441944", "West\ Heslerton",
"441429", "Hartlepool",
"441766", "Porthmadog",
"441672", "Marlborough",
"4414233", "Boroughbridge",
"441564", "Lapworth",
"4420", "London",
"441337", "Ladybank",
"441529", "Sleaford",
"441464", "Insch",
"4418516", "Great\ Bernera",
"441775", "Spalding",
"441367", "Faringdon",
"4419643", "Patrington",
"441422", "Halifax",
"441692", "North\ Walsham",
"44292", "Cardiff",
"441777", "Retford",
"44114707", "Sheffield",
"441874", "Brecon",
"4415396", "Sedbergh",
"441308", "Bridport",
"4414342", "Bellingham",
"441578", "Lauder",
"441248", "Bangor\ \(Gwynedd\)",
"441335", "Ashbourne",
"441406", "Holbeach",
"441628", "Maidenhead",
"4417684", "Pooley\ Bridge",
"441389", "Dumbarton",
"4416862", "Llanidloes",
"441146", "Sheffield",
"441376", "Braintree",
"441795", "Sittingbourne",
"441807", "Ballindalloch",
"441350", "Dunkeld",
"441506", "Bathgate",
"4413885", "Stanhope\ \(Eastgate\)",
"441704", "Southport",
"441353", "Ely",
"441382", "Dundee",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441244", "Chester",
"4412293", "Millom",
"4418901", "Coldstream\/Ayton",
"441395", "Budleigh\ Salterton",
"441776", "Stranraer",
"441223", "Cambridge",
"4418515", "Stornoway",
"441643", "Minehead",
"441624", "Isle\ of\ Man",
"441782", "Stoke\-on\-Trent",
"441407", "Holyhead",
"441878", "Lochboisdale",
"441753", "Slough",
"441304", "Dover",
"441750", "Selkirk",
"441708", "Romford",
"441669", "Rothbury",
"441377", "Driffield",
"441765", "Ripon",
"441474", "Gravesend",
"441789", "Stratford\-upon\-Avon",
"4414301", "North\ Cave\/Market\ Weighton",
"441639", "Neath",
"441685", "Merthyr\ Tydfil",
"441806", "Shetland",
"441352", "Mold",
"441501", "Harthill",
"4418906", "Ayton",
"4413398", "Aboyne",
"4419642", "Hornsea",
"441380", "Devizes",
"442884", "Northern\ Ireland",
"441383", "Dunfermline",
"441141", "Sheffield",
"441371", "Great\ Dunmow",
"4414232", "Harrogate",
"44114701", "Sheffield",
"441205", "Boston",
"441978", "Wrexham",
"441359", "Pakenham",
"441268", "Basildon",
"4414306", "Market\ Weighton",
"441690", "Betws\-y\-Coed",
"441294", "Ardrossan",
"442825", "Ballymena",
"441655", "Maybole",
"441759", "Pocklington",
"441745", "Rhyl",
"442311", "Southampton",
"4413397", "Ballater",
"4419754", "Alford\ \(Aberdeen\)",
"4418909", "Ayton",
"442888", "Northern\ Ireland",
"441633", "Newport",
"441630", "Market\ Drayton",
"441780", "Stamford",
"441234", "Bedford",
"4415073", "Louth",
"4414309", "Market\ Weighton",
"441298", "Buxton",
"441752", "Plymouth",
"44117", "Bristol",
"4418474", "Thurso",
"441771", "Maud",
"441663", "New\ Mills",
"441974", "Llanon",
"44161", "Manchester",
"441264", "Andover",
"441642", "Middlesbrough",
"441361", "Duns",
"4414305", "North\ Cave",
"441346", "Fraserburgh",
"442826", "Northern\ Ireland",
"441206", "Colchester",
"441938", "Welshpool",
"441844", "Thame",
"441747", "Shaftesbury",
"441823", "Taunton",
"441994", "St\ Clears",
"441548", "Kingsbridge",
"441905", "Worcester",
"441278", "Bridgwater",
"4418511", "Great\ Bernera\/Stornoway",
"441968", "Penicuik",
"4418905", "Ayton",
"4412292", "Barrow\-in\-Furness",
"442827", "Ballymoney",
"441929", "Wareham",
"441347", "Easingwold",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441420", "Alton",
"441444", "Haywards\ Heath",
"44238", "Southampton",
"4416863", "Llanidloes",
"441207", "Consett",
"441746", "Bridgnorth",
"441544", "Kington",
"441520", "Lochcarron",
"441274", "Bradford",
"441922", "Walsall",
"441670", "Morpeth",
"441673", "Market\ Rasen",
"44116", "Leicester",
"441761", "Temple\ Cloud",
"441656", "Bridgend",
"4414343", "Haltwhistle",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441934", "Weston\-super\-Mare",
"441848", "Thornhill",
"44113", "Leeds",
"441904", "York",
"441859", "Harris",
"442886", "Cookstown",
"4418472", "Thurso",
"441845", "Thirsk",
"441910", "Tyneside\/Durham\/Sunderland",
"441913", "Durham",
"441995", "Garstang",
"441852", "Kilmelford",
"4413391", "Aboyne\/Ballater",
"441237", "Bideford",
"441883", "Caterham",
"4419752", "Alford\ \(Aberdeen\)",
"441880", "Tarbert",
"441267", "Carmarthen",
"441871", "Castlebay",
"441296", "Aylesbury",
"442879", "Magherafelt",
"441977", "Pontefract",
"441452", "Gloucester",
"441989", "Ross\-on\-Wye",
"442887", "Dungannon",
"441480", "Huntingdon",
"441935", "Yeovil",
"441483", "Guildford",
"441559", "Llandysul",
"441908", "Milton\ Keynes",
"441545", "Llanarth",
"441275", "Clevedon",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"4414234", "Boroughbridge",
"441580", "Cranbrook",
"441982", "Builth\ Wells",
"441583", "Carradale",
"441236", "Coatbridge",
"441950", "Sandwick",
"441301", "Arrochar",
"441953", "Wymondham",
"441241", "Arbroath",
"441297", "Axminster",
"441571", "Lochinver",
"441621", "Maldon",
"4419644", "Patrington",
"441445", "Gairloch",
"441491", "Henley\-on\-Thames",
"441323", "Eastbourne",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441295", "Banbury",
"441344", "Bracknell",
"441320", "Fort\ Augustus",
"442840", "Banbridge",
"442824", "Northern\ Ireland",
"441204", "Bolton",
"4418518", "Stornoway",
"441600", "Monmouth",
"4414300", "North\ Cave\/Market\ Weighton",
"441603", "Norwich",
"4417683", "Appleby",
"441967", "Strontian",
"441277", "Brentwood",
"4418900", "Coldstream\/Ayton",
"441591", "Llanwrtyd\ Wells",
"441547", "Knighton",
"441937", "Wetherby",
"441748", "Richmond",
"442885", "Ballygawley",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441208", "Bodmin",
"4412294", "Barrow\-in\-Furness",
"441461", "Gretna",
"4418517", "Stornoway",
"442892", "Lisburn",
"44291", "Cardiff",
"441446", "Barry",
"441289", "Berwick\-upon\-Tweed",
"441431", "Helmsdale",
"441235", "Abingdon",
"441348", "Fishguard",
"442828", "Larne",
"441997", "Strathpeffer",
"442899", "Northern\ Ireland",
"441720", "Isles\ of\ Scilly",
"441744", "St\ Helens",
"441546", "Lochgilphead",
"441276", "Camberley",
"441723", "Scarborough",
"441561", "Laurencekirk",
"441654", "Machynlleth",
"441282", "Burnley",
"441531", "Ledbury",
"441253", "Blackpool",
"441250", "Blairgowrie",};
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