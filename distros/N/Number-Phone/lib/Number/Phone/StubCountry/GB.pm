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
our $VERSION = 1.20250913135857;

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
                  73[0-35]
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
                  73[0-35]
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
$areanames{en} = {"441604", "Northampton",
"4419640", "Hornsea\/Patrington",
"44121", "Birmingham",
"441352", "Mold",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"4419752", "Alford\ \(Aberdeen\)",
"441573", "Kelso",
"441983", "Isle\ of\ Wight",
"441905", "Worcester",
"441499", "Inveraray",
"4413391", "Aboyne\/Ballater",
"4418909", "Ayton",
"441863", "Ardgay",
"441745", "Rhyl",
"442893", "Ballyclare",
"4418477", "Tongue",
"441542", "Keith",
"4412294", "Barrow\-in\-Furness",
"4413395", "Aboyne",
"441257", "Coppull",
"441768", "Penrith",
"4414308", "Market\ Weighton",
"441606", "Northwich",
"441553", "Kings\ Lynn",
"441458", "Glastonbury",
"441372", "Esher",
"441588", "Bishops\ Castle",
"441978", "Wrexham",
"441327", "Daventry",
"441405", "Goole",
"441726", "St\ Austell",
"441483", "Guildford",
"441669", "Rothbury",
"4415077", "Louth",
"441687", "Mallaig",
"441291", "Chepstow",
"44114703", "Sheffield",
"441520", "Lochcarron",
"441301", "Arrochar",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"442889", "Fivemiletown",
"441871", "Castlebay",
"4415394", "Hawkshead",
"441561", "Laurencekirk",
"441343", "Elgin",
"441724", "Scunthorpe",
"4416866", "Newtown",
"441277", "Brentwood",
"441140", "Sheffield",
"442867", "Lisnaskea",
"441747", "Shaftesbury",
"4413399", "Ballater",
"441346", "Fraserburgh",
"441484", "Huddersfield",
"441554", "Llanelli",
"4418901", "Coldstream\/Ayton",
"4413885", "Stanhope\ \(Eastgate\)",
"441828", "Coupar\ Angus",
"441737", "Redhill",
"4414302", "North\ Cave",
"441992", "Lea\ Valley",
"441398", "Dulverton",
"441750", "Selkirk",
"441809", "Tomdoun",
"441379", "Diss",
"441208", "Bodmin",
"4419758", "Strathdon",
"4417684", "Pooley\ Bridge",
"441255", "Clacton\-on\-Sea",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441690", "Betws\-y\-Coed",
"4418905", "Ayton",
"441334", "St\ Andrews",
"442882", "Omagh",
"441556", "Castle\ Douglas",
"4418514", "Great\ Bernera",
"441880", "Tarbert",
"441344", "Bracknell",
"4419643", "Patrington",
"441723", "Scarborough",
"441984", "Watchet\ \(Williton\)",
"441603", "Norwich",
"442848", "Northern\ Ireland",
"441685", "Merthyr\ Tydfil",
"441631", "Oban",
"441407", "Holyhead",
"441359", "Pakenham",
"441864", "Abington\ \(Crawford\)",
"441770", "Isle\ of\ Arran",
"441325", "Darlington",
"442896", "Belfast",
"441492", "Colwyn\ Bay",
"441641", "Strathy",
"442838", "Portadown",
"441895", "Uxbridge",
"441549", "Lairg",
"441275", "Clevedon",
"441866", "Kilchrenan",
"441460", "Chard",
"442894", "Antrim",
"441539", "Kendal",
"441986", "Bungay",
"441576", "Lockerbie",
"441584", "Ludlow",
"441974", "Llanon",
"441454", "Chipping\ Sodbury",
"441675", "Coleshill",
"441823", "Taunton",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441780", "Stamford",
"4414306", "Market\ Weighton",
"441917", "Sunderland",
"441285", "Cirencester",
"441949", "Whatton",
"4418517", "Stornoway",
"441709", "Rotherham",
"441939", "Wem",
"441241", "Arbroath",
"441456", "Glenurquhart",
"4417687", "Keswick",
"441586", "Campbeltown",
"4413873", "Langholm",
"4414233", "Boroughbridge",
"441728", "Saxmundham",
"441837", "Okehampton",
"441655", "Maybole",
"441367", "Faringdon",
"441474", "Gravesend",
"441629", "Matlock",
"441766", "Porthmadog",
"441290", "Cumnock",
"441608", "Chipping\ Norton",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441954", "Madingley",
"4416868", "Newtown",
"4414349", "Bellingham",
"441389", "Dumbarton",
"441592", "Kirkcaldy",
"441449", "Stowmarket",
"441141", "Sheffield",
"441560", "Moscow",
"441262", "Bridlington",
"441439", "Helmsley",
"441795", "Sittingbourne",
"442827", "Ballymoney",
"441476", "Grantham",
"441300", "Cerne\ Abbas",
"441870", "Isle\ of\ Benbecula",
"441764", "Crieff",
"442844", "Downpatrick",
"441751", "Pickering",
"441953", "Wymondham",
"4414230", "Harrogate\/Boroughbridge",
"441599", "Kyle",
"4419756", "Strathdon",
"441473", "Ipswich",
"441988", "Wigtown",
"441578", "Lauder",
"441382", "Dundee",
"441677", "Bedale",
"44241", "Coventry",
"441622", "Maidstone",
"442879", "Magherafelt",
"441835", "St\ Boswells",
"441432", "Hereford",
"441269", "Ammanford",
"442898", "Belfast",
"441920", "Ware",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"4412297", "Millom",
"441845", "Thirsk",
"4418474", "Thurso",
"441763", "Royston",
"441442", "Hemel\ Hempstead",
"441691", "Oswestry",
"442846", "Northern\ Ireland",
"441287", "Guisborough",
"441915", "Sunderland",
"441558", "Llandeilo",
"441453", "Dursley",
"441583", "Carradale",
"4415074", "Alford\ \(Lincs\)",
"441771", "Maud",
"441505", "Johnstone",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"44283", "Northern\ Ireland",
"441488", "Hungerford",
"44291", "Cardiff",
"441206", "Colchester",
"441630", "Market\ Drayton",
"441394", "Felixstowe",
"441824", "Ruthin",
"441420", "Alton",
"441702", "Southend\-on\-Sea",
"441932", "Weybridge",
"442825", "Ballymena",
"441204", "Bolton",
"44161", "Manchester",
"4414345", "Haltwhistle",
"441797", "Rye",
"441348", "Fishguard",
"441942", "Wigan",
"441461", "Gretna",
"4416862", "Llanidloes",
"4415078", "Alford\ \(Lincs\)",
"441918", "Tyneside",
"441848", "Thornhill",
"442310", "Portsmouth",
"4419641", "Hornsea\/Patrington",
"441490", "Corwen",
"441274", "Bradford",
"441896", "Galashiels",
"441727", "St\ Albans",
"4413390", "Aboyne\/Ballater",
"441772", "Preston",
"44117", "Bristol",
"441838", "Dalmally",
"441326", "Falmouth",
"442895", "Belfast",
"441865", "Oxford",
"441324", "Falkirk",
"441462", "Hitchin",
"441743", "Shrewsbury",
"441239", "Cardigan",
"442866", "Enniskillen",
"4419645", "Hornsea",
"441276", "Camberley",
"441985", "Warminster",
"441575", "Kirriemuir",
"441249", "Chippenham",
"441931", "Shap",
"441903", "Worthing",
"441733", "Peterborough",
"441684", "Malvern",
"4418903", "Coldstream",
"441621", "Maldon",
"44114709", "Sheffield",
"44286", "Northern\ Ireland",
"442828", "Larne",
"4418516", "Great\ Bernera",
"44115", "Nottingham",
"441752", "Plymouth",
"441254", "Blackburn",
"441381", "Fortrose",
"441335", "Ashbourne",
"441256", "Basingstoke",
"441692", "North\ Walsham",
"441368", "Dunbar",
"441962", "Winchester",
"4414307", "Market\ Weighton",
"441882", "Kinloch\ Rannoch",
"441508", "Brooke",
"441403", "Horsham",
"441485", "Hunstanton",
"441431", "Helmsdale",
"4418478", "Thurso",
"442880", "Carrickmore",
"441555", "Lanark",
"441529", "Sleaford",
"441759", "Pocklington",
"442897", "Saintfield",
"4418900", "Coldstream\/Ayton",
"441725", "Rockbourne",
"441406", "Holbeach",
"441591", "Llanwrtyd\ Wells",
"4415396", "Sedbergh",
"441253", "Blackpool",
"4419649", "Hornsea",
"441288", "Bude",
"4416864", "Llanidloes",
"4413393", "Aboyne",
"441261", "Banff",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441889", "Rugeley",
"442871", "Londonderry",
"441522", "Lincoln",
"441577", "Kinross",
"441987", "Ebbsfleet",
"4415072", "Spilsby\ \(Horncastle\)",
"441142", "Sheffield",
"441969", "Leyburn",
"441678", "Bala",
"441404", "Honiton",
"44114702", "Sheffield",
"441337", "Ladybank",
"441736", "Penzance",
"441798", "Pulborough",
"441350", "Dunkeld",
"441779", "Peterhead",
"441347", "Easingwold",
"4416973", "Wigton",
"441746", "Bridgnorth",
"4412296", "Barrow\-in\-Furness",
"44151", "Liverpool",
"4418472", "Thurso",
"441273", "Brighton",
"441242", "Cheltenham",
"441557", "Kirkcudbright",
"441530", "Coalville",
"441487", "Warboys",
"441323", "Eastbourne",
"441744", "St\ Helens",
"4419757", "Strathdon",
"441683", "Moffat",
"441469", "Killingholme",
"441540", "Kingussie",
"441904", "York",
"441506", "Bathgate",
"4416867", "Llanidloes",
"441789", "Stratford\-upon\-Avon",
"441642", "Middlesbrough",
"441491", "Henley\-on\-Thames",
"441258", "Blandford",
"441767", "Sandy",
"442311", "Southampton",
"441366", "Downham\ Market",
"442824", "Northern\ Ireland",
"441205", "Boston",
"4414239", "Boroughbridge",
"441283", "Burton\-on\-Trent",
"442826", "Northern\ Ireland",
"441957", "Mid\ Yell",
"441395", "Budleigh\ Salterton",
"441825", "Uckfield",
"441700", "Rothesay",
"441859", "Harris",
"441364", "Ashburton",
"441477", "Holmes\ Chapel",
"4415076", "Louth",
"441422", "Halifax",
"4414379", "Haverfordwest",
"441673", "Market\ Rasen",
"441844", "Thame",
"441380", "Devizes",
"441661", "Prudhoe",
"441793", "Swindon",
"44239", "Portsmouth",
"441914", "Tyneside",
"44141", "Glasgow",
"441834", "Narberth",
"4418476", "Tongue",
"4412292", "Barrow\-in\-Furness",
"441620", "North\ Berwick",
"442868", "Kesh",
"441299", "Bewdley",
"441278", "Bridgwater",
"441457", "Glossop",
"441309", "Forres",
"441879", "Scarinish",
"442881", "Newtownstewart",
"441328", "Fakenham",
"441977", "Pontefract",
"441922", "Walsall",
"4419754", "Alford\ \(Aberdeen\)",
"442845", "Northern\ Ireland",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441569", "Stonehaven",
"441916", "Tyneside",
"441653", "Malton",
"441440", "Haverhill",
"4418518", "Stornoway",
"4414343", "Haltwhistle",
"441794", "Romsey",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441207", "Consett",
"441913", "Durham",
"441843", "Thanet",
"441656", "Bridgend",
"441292", "Ayr",
"441765", "Ripon",
"4414231", "Harrogate\/Boroughbridge",
"441590", "Lymington",
"441833", "Barnard\ Castle",
"441371", "Great\ Dunmow",
"44114700", "Sheffield",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441562", "Kidderminster",
"441748", "Richmond",
"4414235", "Harrogate",
"441654", "Machynlleth",
"441475", "Greenock",
"441872", "Truro",
"441827", "Tamworth",
"441908", "Milton\ Keynes",
"441738", "Perth",
"441302", "Doncaster",
"441260", "Congleton",
"441929", "Wareham",
"441796", "Pitlochry",
"442870", "Coleraine",
"441955", "Wick",
"441397", "Fort\ William",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441676", "Meriden",
"441639", "Neath",
"442823", "Northern\ Ireland",
"4418512", "Stornoway",
"441284", "Bury\ St\ Edmunds",
"441782", "Stoke\-on\-Trent",
"44247", "Coventry",
"44118", "Reading",
"441363", "Crediton",
"441286", "Caernarfon",
"442847", "Northern\ Ireland",
"441531", "Ledbury",
"4414304", "North\ Cave",
"441503", "Looe",
"441408", "Golspie",
"441429", "Hartlepool",
"4412298", "Barrow\-in\-Furness",
"441852", "Kilmelford",
"441455", "Hinckley",
"442837", "Armagh",
"441674", "Montrose",
"441625", "Macclesfield",
"4419647", "Patrington",
"441659", "Sanquhar",
"44281", "Northern\ Ireland",
"441563", "Kilmarnock",
"441341", "Barmouth",
"441924", "Wakefield",
"4414234", "Boroughbridge",
"441303", "Folkestone",
"441873", "Abergavenny",
"441842", "Thetford",
"441445", "Gairloch",
"441293", "Crawley",
"442840", "Banbridge",
"441912", "Tyneside",
"4418470", "Thurso\/Tongue",
"441832", "Clopton",
"441778", "Bourne",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441481", "Guernsey",
"441799", "Saffron\ Walden",
"441926", "Warwick",
"441435", "Heathfield",
"442830", "Newry",
"441200", "Clitheroe",
"441636", "Newark\-on\-Trent",
"4414305", "North\ Cave",
"441968", "Penicuik",
"441424", "Hastings",
"4413398", "Aboyne",
"441362", "Dereham",
"441698", "Motherwell",
"441646", "Milford\ Haven",
"441597", "Llandrindod\ Wells",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441502", "Lowestoft",
"441888", "Turriff",
"4413882", "Stanhope\ \(Eastgate\)",
"442891", "Bangor\ \(Co\.\ Down\)",
"4414301", "North\ Cave\/Market\ Weighton",
"441289", "Berwick\-upon\-Tweed",
"441945", "Wisbech",
"441644", "New\ Galloway",
"4419759", "Alford\ \(Aberdeen\)",
"44238", "Southampton",
"441571", "Lochinver",
"441981", "Wormbridge",
"441935", "Yeovil",
"442877", "Limavady",
"442822", "Northern\ Ireland",
"441634", "Medway",
"4418902", "Coldstream",
"441758", "Pwllheli",
"441267", "Carmarthen",
"441528", "Laggan",
"441387", "Dumfries",
"441786", "Stirling",
"441509", "Loughborough",
"4418473", "Thurso",
"441854", "Ullapool",
"441369", "Dunoon",
"441672", "Marlborough",
"441643", "Minehead",
"441856", "Orkney",
"441450", "Hawick",
"441580", "Cranbrook",
"441970", "Aberystwyth",
"442829", "Kilrea",
"441282", "Burnley",
"441633", "Newport",
"4414346", "Hexham",
"441784", "Staines",
"441564", "Lapworth",
"44114707", "Sheffield",
"441721", "Peebles",
"441923", "Watford",
"441248", "Bangor\ \(Gwynedd\)",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"4418908", "Coldstream",
"441652", "Brigg",
"441304", "Dover",
"441760", "Swaffham",
"441874", "Brecon",
"441296", "Aylesbury",
"4419755", "Alford\ \(Aberdeen\)",
"4413392", "Aboyne",
"441792", "Swansea",
"441950", "Sandwick",
"441707", "Welwyn\ Garden\ City",
"441937", "Wetherby",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441306", "Dorking",
"441294", "Ardrossan",
"441876", "Lochmaddy",
"4415073", "Louth",
"4414309", "Market\ Weighton",
"441566", "Launceston",
"441919", "Durham",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441947", "Whitby",
"441428", "Haslemere",
"441330", "Banchory",
"441694", "Church\ Stretton",
"4416861", "Newtown\/Llanidloes",
"441995", "Garstang",
"441409", "Holsworthy",
"441357", "Strathaven",
"441665", "Alnwick",
"441756", "Skipton",
"441884", "Tiverton",
"441340", "Craigellachie\ \(Aberlour\)",
"44114708", "Sheffield",
"4412293", "Millom",
"441143", "Sheffield",
"442885", "Ballygawley",
"441550", "Llandovery",
"4416865", "Newtown",
"4418510", "Great\ Bernera\/Stornoway",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441480", "Huntingdon",
"442841", "Rostrevor",
"441638", "Newmarket",
"441754", "Skegness",
"441252", "Aldershot",
"44131", "Edinburgh",
"4414342", "Bellingham",
"441547", "Knighton",
"441776", "Stranraer",
"441807", "Ballindalloch",
"441464", "Insch",
"442890", "Belfast",
"441928", "Runcorn",
"441377", "Driffield",
"441322", "Dartford",
"441243", "Chichester",
"441495", "Pontypool",
"441909", "Worksop",
"441892", "Tunbridge\ Wells",
"441749", "Shepton\ Mallet",
"441233", "Ashford\ \(Kent\)",
"4413396", "Ballater",
"441821", "Kinrossie",
"441980", "Amesbury",
"441570", "Lampeter",
"441227", "Canterbury",
"441466", "Huntly",
"441244", "Chester",
"4414237", "Harrogate",
"441568", "Leominster",
"441463", "Inverness",
"4417683", "Appleby",
"441689", "Orpington",
"441329", "Fareham",
"4414348", "Hexham",
"4418513", "Stornoway",
"441234", "Bedford",
"441997", "Strathpeffer",
"441355", "East\ Kilbride",
"441667", "Nairn",
"441899", "Biggar",
"4419644", "Patrington",
"441308", "Bridport",
"441732", "Sevenoaks",
"4416869", "Newtown",
"441902", "Wolverhampton",
"44113", "Leeds",
"441878", "Lochboisdale",
"441279", "Bishops\ Stortford",
"441545", "Llanarth",
"441298", "Buxton",
"441600", "Monmouth",
"4414377", "Haverfordwest",
"441236", "Coatbridge",
"4412290", "Barrow\-in\-Furness\/Millom",
"441535", "Keighley",
"441581", "New\ Luce",
"441971", "Scourie",
"441773", "Ripley",
"44280", "Northern\ Ireland",
"441246", "Chesterfield",
"441451", "Stow\-on\-the\-Wold",
"442887", "Dungannon",
"441524", "Lancaster",
"441963", "Wincanton",
"441761", "Temple\ Cloud",
"441858", "Market\ Harborough",
"441144", "Sheffield",
"441497", "Hay\-on\-Wye",
"441805", "Torrington",
"441883", "Caterham",
"441375", "Grays\ Thurrock",
"441720", "Isles\ of\ Scilly",
"441225", "Bath",
"441146", "Sheffield",
"441259", "Alloa",
"441526", "Martin",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441788", "Rugby",
"441753", "Slough",
"441951", "Colonsay",
"4418906", "Ayton",
"4418475", "Thurso",
"441647", "Moretonhampstead",
"441538", "Ipstones",
"441433", "Hathersage",
"441264", "Andover",
"441637", "Newquay",
"441650", "Cemmaes\ Road",
"4413397", "Ballater",
"441548", "Kingsbridge",
"441443", "Pontypridd",
"441295", "Banbury",
"44116", "Leicester",
"441472", "Grimsby",
"441427", "Gainsborough",
"441305", "Dorchester",
"4418471", "Thurso\/Tongue",
"441383", "Dunfermline",
"441875", "Tranent",
"441790", "Spilsby",
"441358", "Ellon",
"441952", "Telford",
"441565", "Knutsford",
"4415242", "Hornby",
"442849", "Northern\ Ireland",
"441623", "Mansfield",
"441594", "Lydney",
"44287", "Northern\ Ireland",
"4419753", "Strathdon",
"441933", "Wellingborough",
"441785", "Stafford",
"441228", "Carlisle",
"4419648", "Hornsea",
"441670", "Morpeth",
"4414344", "Bellingham",
"441209", "Redruth",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441943", "Guiseley",
"441808", "Tomatin",
"441972", "Glenborrodale",
"441582", "Luton",
"441855", "Ballachulish",
"441829", "Tarporley",
"4414300", "North\ Cave\/Market\ Weighton",
"441452", "Gloucester",
"441280", "Buckingham",
"4415075", "Spilsby\ \(Horncastle\)",
"441297", "Axminster",
"441934", "Weston\-super\-Mare",
"441704", "Southport",
"4418907", "Ayton",
"441360", "Killearn",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441202", "Bournemouth",
"441635", "Newbury",
"44292", "Cardiff",
"441944", "West\ Heslerton",
"442888", "Northern\ Ireland",
"441271", "Barnstaple",
"441567", "Killin",
"441946", "Whitehaven",
"441392", "Exeter",
"442820", "Ballycastle",
"441668", "Bamburgh",
"4418479", "Tongue",
"441307", "Forfar",
"441877", "Callander",
"441822", "Tavistock",
"441706", "Rochdale",
"441425", "Ringwood",
"4415079", "Alford\ \(Lincs\)",
"441626", "Newton\ Abbot",
"441769", "South\ Molton",
"4414376", "Haverfordwest",
"441787", "Sudbury",
"441444", "Haywards\ Heath",
"4414303", "North\ Cave",
"441386", "Evesham",
"441263", "Cromer",
"442842", "Kircubbin",
"441910", "Tyneside\/Durham\/Sunderland",
"441840", "Camelford",
"441446", "Barry",
"441384", "Dudley",
"441624", "Isle\ of\ Man",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441593", "Lybster",
"441857", "Sanday",
"441479", "Grantown\-on\-Spey",
"441830", "Kirkwhelpington",
"441959", "Westerham",
"4414236", "Harrogate",
"441436", "Helensburgh",
"4419642", "Hornsea",
"441925", "Warrington",
"4416860", "Newtown\/Llanidloes",
"441651", "Oldmeldrum",
"4418515", "Stornoway",
"441349", "Dingwall",
"441806", "Shetland",
"441376", "Braintree",
"441400", "Honington",
"441722", "Salisbury",
"441777", "Retford",
"4418904", "Coldstream",
"441224", "Aberdeen",
"442883", "Northern\ Ireland",
"441226", "Barnsley",
"441145", "Sheffield",
"4418511", "Great\ Bernera\/Stornoway",
"441467", "Inverurie",
"44114705", "Sheffield",
"441993", "Witney",
"4412299", "Millom",
"441663", "New\ Mills",
"441489", "Bishops\ Waltham",
"44114704", "Sheffield",
"441525", "Leighton\ Buzzard",
"441559", "Llandysul",
"441534", "Jersey",
"441740", "Sedgefield",
"441671", "Newton\ Stewart",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441544", "Kington",
"441730", "Petersfield",
"441900", "Workington",
"441757", "Selby",
"442899", "Northern\ Ireland",
"441268", "Basildon",
"441356", "Brechin",
"441235", "Abingdon",
"441354", "Chatteris",
"441869", "Bicester",
"441967", "Strontian",
"441697", "Brampton",
"441546", "Lochgilphead",
"441579", "Liskeard",
"441989", "Ross\-on\-Wye",
"441245", "Chelmsford",
"441493", "Great\ Yarmouth",
"441598", "Lynton",
"441536", "Kettering",
"4419646", "Patrington",
"4414232", "Harrogate",
"441887", "Aberfeldy",
"441496", "Port\ Ellen",
"4413394", "Ballater",
"4412295", "Barrow\-in\-Furness",
"441775", "Spalding",
"441501", "Harthill",
"442892", "Lisburn",
"441320", "Fort\ Augustus",
"441438", "Stevenage",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"44114701", "Sheffield",
"441543", "Cannock",
"441361", "Duns",
"441527", "Redditch",
"441388", "Bishop\ Auckland",
"441982", "Builth\ Wells",
"4412291", "Barrow\-in\-Furness\/Millom",
"441572", "Oakham",
"442821", "Martinstown",
"441353", "Ely",
"4419467", "Gosforth",
"441862", "Tain",
"441609", "Northallerton",
"441465", "Girvan",
"4418519", "Great\ Bernera",
"441628", "Maidenhead",
"4416863", "Llanidloes",
"441494", "High\ Wycombe",
"441270", "Crewe",
"441729", "Settle",
"441666", "Malmesbury",
"4414347", "Hexham",
"441332", "Derby",
"441708", "Romford",
"441938", "Welshpool",
"441223", "Cambridge",
"442884", "Northern\ Ireland",
"4414238", "Harrogate",
"4415395", "Grange\-over\-Sands",
"441948", "Whitchurch",
"441342", "East\ Grinstead",
"441803", "Torquay",
"441885", "Pencombe",
"441373", "Frome",
"441482", "Kingston\-upon\-Hull",
"442886", "Cookstown",
"441250", "Blairgowrie",
"441841", "Newquay\ \(Padstow\)",
"4416974", "Raughton\ Head",
"4420", "London",
"441695", "Skelmersdale",
"441994", "St\ Clears",
"441664", "Melton\ Mowbray",
"4414378", "Haverfordwest",
"441911", "Tyneside\/Durham\/Sunderland",
"441237", "Bideford",};
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