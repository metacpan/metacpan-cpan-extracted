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
our $VERSION = 1.20220903144940;

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
                  [0-5]\\d\\d|
                  69[7-9]|
                  70[01359]
                )|
                (?:
                  5[0-26-9]|
                  [78][0-49]
                )\\d\\d|
                6(?:
                  [0-4]\\d\\d|
                  50[0-79]
                )
              )|
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
                )\\d\\d|
                1(?:
                  [0-7]\\d\\d|
                  8(?:
                    [02]\\d|
                    1[0-26-9]
                  )
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
              )\\d\\d
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
                  [0-5]\\d\\d|
                  69[7-9]|
                  70[01359]
                )|
                (?:
                  5[0-26-9]|
                  [78][0-49]
                )\\d\\d|
                6(?:
                  [0-4]\\d\\d|
                  50[0-79]
                )
              )|
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
                )\\d\\d|
                1(?:
                  [0-7]\\d\\d|
                  8(?:
                    [02]\\d|
                    1[0-26-9]
                  )
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
              )\\d\\d
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
$areanames{en} = {"441830", "Kirkwhelpington",
"441902", "Wolverhampton",
"441467", "Inverurie",
"441237", "Bideford",
"441895", "Uxbridge",
"441743", "Shrewsbury",
"441202", "Bournemouth",
"441406", "Holbeach",
"441309", "Forres",
"441581", "New\ Luce",
"441360", "Killearn",
"442868", "Kesh",
"441937", "Wetherby",
"441666", "Malmesbury",
"442877", "Limavady",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441834", "Narberth",
"441549", "Lairg",
"441757", "Selby",
"4415395", "Grange\-over\-Sands",
"4418477", "Tongue",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441863", "Ardgay",
"441364", "Ashburton",
"441873", "Abergavenny",
"441796", "Pitlochry",
"441784", "Staines",
"4418518", "Stornoway",
"44280", "Northern\ Ireland",
"4418906", "Ayton",
"44151", "Liverpool",
"441938", "Welshpool",
"441676", "Meriden",
"4417687", "Keswick",
"442867", "Lisnaskea",
"441724", "Scunthorpe",
"441780", "Stamford",
"441758", "Pwllheli",
"4416865", "Newtown",
"4412296", "Barrow\-in\-Furness",
"441477", "Holmes\ Chapel",
"441720", "Isles\ of\ Scilly",
"441608", "Chipping\ Norton",
"4418514", "Great\ Bernera",
"441805", "Torrington",
"441283", "Burton\-on\-Trent",
"441424", "Hastings",
"441689", "Orpington",
"441992", "Lea\ Valley",
"441923", "Watford",
"441983", "Isle\ of\ Wight",
"441768", "Penrith",
"441917", "Sunderland",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441629", "Matlock",
"441496", "Port\ Ellen",
"441484", "Huddersfield",
"441292", "Ayr",
"441223", "Cambridge",
"4416869", "Newtown",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441420", "Alton",
"441777", "Retford",
"441387", "Dumfries",
"4418471", "Thurso\/Tongue",
"441458", "Glastonbury",
"441327", "Daventry",
"441697", "Brampton",
"441641", "Strathy",
"441848", "Thornhill",
"441480", "Huntingdon",
"441572", "Oakham",
"441562", "Kidderminster",
"441944", "West\ Heslerton",
"4419640", "Hornsea\/Patrington",
"441354", "Chatteris",
"441536", "Kettering",
"442896", "Belfast",
"442884", "Northern\ Ireland",
"441443", "Pontypridd",
"4413396", "Ballater",
"441706", "Rochdale",
"441244", "Chester",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441918", "Tyneside",
"441767", "Sandy",
"442824", "Northern\ Ireland",
"441656", "Bridgend",
"4418512", "Stornoway",
"441350", "Dunkeld",
"441778", "Bourne",
"441388", "Bishop\ Auckland",
"442880", "Carrickmore",
"441525", "Leighton\ Buzzard",
"442820", "Ballycastle",
"441457", "Glossop",
"4419753", "Strathdon",
"441698", "Motherwell",
"441328", "Fakenham",
"4414300", "North\ Cave\/Market\ Weighton",
"441945", "Wisbech",
"4412297", "Millom",
"441558", "Llandeilo",
"4414234", "Boroughbridge",
"441361", "Duns",
"441355", "East\ Kilbride",
"442885", "Ballygawley",
"441580", "Cranbrook",
"441276", "Camberley",
"441472", "Grimsby",
"441245", "Chelmsford",
"442825", "Ballymena",
"441520", "Lochcarron",
"441879", "Scarinish",
"441638", "Newmarket",
"4418907", "Ayton",
"441208", "Bodmin",
"441584", "Ludlow",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441524", "Lancaster",
"4414238", "Harrogate",
"44283", "Northern\ Ireland",
"441908", "Milton\ Keynes",
"4413391", "Aboyne\/Ballater",
"441557", "Kirkcudbright",
"441303", "Folkestone",
"4415074", "Alford\ \(Lincs\)",
"441425", "Ringwood",
"4418476", "Tongue",
"441749", "Shepton\ Mallet",
"4419643", "Patrington",
"44113", "Leeds",
"441752", "Plymouth",
"4414343", "Haltwhistle",
"441485", "Hunstanton",
"441637", "Newquay",
"441721", "Peebles",
"441932", "Weybridge",
"441207", "Consett",
"441869", "Bicester",
"441462", "Hitchin",
"4415078", "Alford\ \(Lincs\)",
"441436", "Helensburgh",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441371", "Great\ Dunmow",
"441543", "Cannock",
"4414303", "North\ Cave",
"441785", "Stafford",
"441375", "Grays\ Thurrock",
"441644", "New\ Galloway",
"441842", "Thetford",
"4412291", "Barrow\-in\-Furness\/Millom",
"441578", "Lauder",
"441452", "Gloucester",
"441256", "Basingstoke",
"441859", "Harris",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441449", "Stowmarket",
"441725", "Rockbourne",
"441346", "Fraserburgh",
"4418901", "Coldstream\/Ayton",
"4414378", "Haverfordwest",
"4414232", "Harrogate",
"441506", "Bathgate",
"441298", "Buxton",
"441481", "Guernsey",
"441736", "Penzance",
"441567", "Killin",
"4413397", "Ballater",
"44281", "Northern\ Ireland",
"441989", "Ross\-on\-Wye",
"441577", "Kinross",
"441623", "Mansfield",
"441692", "North\ Walsham",
"441322", "Dartford",
"442849", "Northern\ Ireland",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441772", "Preston",
"441683", "Moffat",
"441382", "Dundee",
"441289", "Berwick\-upon\-Tweed",
"441929", "Wareham",
"441835", "St\ Boswells",
"4415072", "Spilsby\ \(Horncastle\)",
"441297", "Axminster",
"441241", "Arbroath",
"44141", "Glasgow",
"442821", "Martinstown",
"441912", "Tyneside",
"442881", "Newtownstewart",
"441997", "Strathpeffer",
"441568", "Leominster",
"441209", "Redruth",
"441603", "Norwich",
"441302", "Doncaster",
"441495", "Pontypool",
"4418470", "Thurso\/Tongue",
"4413393", "Aboyne",
"441260", "Congleton",
"441909", "Worksop",
"441753", "Slough",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441806", "Shetland",
"441337", "Ladybank",
"441933", "Wellingborough",
"441264", "Andover",
"441559", "Llandysul",
"441747", "Shaftesbury",
"441233", "Ashford\ \(Kent\)",
"441463", "Inverness",
"441639", "Neath",
"441542", "Keith",
"4419756", "Strathdon",
"4414379", "Haverfordwest",
"4415075", "Spilsby\ \(Horncastle\)",
"441878", "Lochboisdale",
"441671", "Newton\ Stewart",
"4414301", "North\ Cave\/Market\ Weighton",
"441661", "Prudhoe",
"441655", "Maybole",
"441974", "Llanon",
"441473", "Ipswich",
"441590", "Lymington",
"442895", "Belfast",
"441274", "Bradford",
"442830", "Newry",
"441535", "Keighley",
"441970", "Aberystwyth",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441526", "Martin",
"441748", "Richmond",
"441270", "Crewe",
"4419641", "Hornsea\/Patrington",
"441586", "Campbeltown",
"441594", "Lydney",
"4414235", "Harrogate",
"441877", "Callander",
"441824", "Ruthin",
"441323", "Eastbourne",
"441622", "Maidstone",
"441405", "Goole",
"441392", "Exeter",
"441299", "Bewdley",
"441884", "Tiverton",
"441773", "Ripley",
"441383", "Dunfermline",
"441896", "Galashiels",
"4418903", "Coldstream",
"441227", "Canterbury",
"442847", "Northern\ Ireland",
"441531", "Ledbury",
"4414239", "Boroughbridge",
"441913", "Durham",
"442891", "Bangor\ \(Co\.\ Down\)",
"441579", "Liskeard",
"441987", "Ebbsfleet",
"441880", "Tarbert",
"441651", "Oldmeldrum",
"441858", "Market\ Harborough",
"441665", "Alnwick",
"4412293", "Millom",
"441287", "Guisborough",
"441954", "Madingley",
"4414307", "Market\ Weighton",
"441344", "Bracknell",
"441675", "Coleshill",
"441843", "Thanet",
"441453", "Dursley",
"441569", "Stonehaven",
"441254", "Blackburn",
"441730", "Petersfield",
"441795", "Sittingbourne",
"441646", "Milford\ Haven",
"441228", "Carlisle",
"441340", "Craigellachie\ \(Aberlour\)",
"4414347", "Hexham",
"441950", "Sandwick",
"442848", "Northern\ Ireland",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441763", "Royston",
"4415079", "Alford\ \(Lincs\)",
"441988", "Wigtown",
"4419647", "Patrington",
"441928", "Runcorn",
"441250", "Blairgowrie",
"441857", "Sanday",
"441288", "Bude",
"441491", "Henley\-on\-Thames",
"441955", "Wick",
"441548", "Kingsbridge",
"441726", "St\ Austell",
"441872", "Truro",
"4418515", "Stornoway",
"441674", "Montrose",
"4416864", "Llanidloes",
"441261", "Banff",
"441255", "Clacton\-on\-Sea",
"441431", "Helmsdale",
"4418900", "Coldstream\/Ayton",
"441376", "Braintree",
"441786", "Stirling",
"441794", "Romsey",
"441479", "Grantown\-on\-Spey",
"441670", "Morpeth",
"4412290", "Barrow\-in\-Furness\/Millom",
"4416868", "Newtown",
"441505", "Johnstone",
"441790", "Spilsby",
"441308", "Bridport",
"441547", "Knighton",
"441903", "Worthing",
"441759", "Pocklington",
"442879", "Magherafelt",
"441404", "Honiton",
"441825", "Uckfield",
"4419757", "Strathdon",
"4415394", "Hawkshead",
"441591", "Llanwrtyd\ Wells",
"4419467", "Gosforth",
"441609", "Northallerton",
"441885", "Pencombe",
"441633", "Newport",
"441332", "Derby",
"441469", "Killingholme",
"441366", "Downham\ Market",
"441239", "Cardigan",
"441400", "Honington",
"441271", "Barnstaple",
"441939", "Wem",
"441862", "Tain",
"441664", "Melton\ Mowbray",
"441553", "Kings\ Lynn",
"441971", "Scourie",
"441307", "Forfar",
"441654", "Machynlleth",
"441852", "Kilmelford",
"441563", "Kilmarnock",
"4419646", "Patrington",
"441442", "Hemel\ Hempstead",
"441246", "Chesterfield",
"442826", "Northern\ Ireland",
"4413390", "Aboyne\/Ballater",
"4418473", "Thurso",
"442886", "Cookstown",
"442894", "Antrim",
"4414346", "Hexham",
"441275", "Clevedon",
"441704", "Southport",
"441946", "Whitehaven",
"441534", "Jersey",
"441356", "Brechin",
"441650", "Cemmaes\ Road",
"4416862", "Llanidloes",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441821", "Kinrossie",
"441628", "Maidenhead",
"441398", "Dulverton",
"441700", "Rothesay",
"44241", "Coventry",
"4414306", "Market\ Weighton",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"442890", "Belfast",
"441530", "Coalville",
"441769", "South\ Molton",
"441501", "Harthill",
"441779", "Peterhead",
"441389", "Dumbarton",
"4416973", "Wigton",
"441494", "High\ Wycombe",
"441282", "Burnley",
"441993", "Witney",
"441922", "Walsall",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441982", "Builth\ Wells",
"4418519", "Great\ Bernera",
"441293", "Crawley",
"441329", "Fareham",
"442842", "Kircubbin",
"4413873", "Langholm",
"4417683", "Appleby",
"441490", "Corwen",
"44118", "Reading",
"441687", "Mallaig",
"441435", "Heathfield",
"441397", "Fort\ William",
"441573", "Kelso",
"441951", "Colonsay",
"441341", "Barmouth",
"441919", "Durham",
"441456", "Glenurquhart",
"441252", "Aldershot",
"441949", "Whatton",
"441359", "Pakenham",
"442889", "Fivemiletown",
"44292", "Cardiff",
"441952", "Telford",
"441249", "Chippenham",
"441875", "Tranent",
"442829", "Kilrea",
"441342", "East\ Grinstead",
"441643", "Minehead",
"441732", "Sevenoaks",
"4418511", "Great\ Bernera\/Stornoway",
"441766", "Porthmadog",
"44115", "Nottingham",
"441502", "Lowestoft",
"442841", "Rostrevor",
"442897", "Saintfield",
"4414376", "Haverfordwest",
"4419759", "Alford\ \(Aberdeen\)",
"441981", "Wormbridge",
"441707", "Welwyn\ Garden\ City",
"441429", "Hartlepool",
"441745", "Rhyl",
"441684", "Malvern",
"441326", "Falmouth",
"441882", "Kinloch\ Rannoch",
"4418472", "Thurso",
"441394", "Felixstowe",
"441624", "Isle\ of\ Man",
"441822", "Tavistock",
"441386", "Evesham",
"441776", "Stranraer",
"4413882", "Stanhope\ \(Eastgate\)",
"441489", "Bishops\ Waltham",
"44121", "Birmingham",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441916", "Tyneside",
"441865", "Oxford",
"4416863", "Llanidloes",
"441497", "Hay\-on\-Wye",
"441335", "Ashbourne",
"441538", "Ipstones",
"442898", "Belfast",
"441708", "Romford",
"441620", "North\ Berwick",
"441379", "Diss",
"441789", "Stratford\-upon\-Avon",
"441476", "Grantham",
"4417684", "Pooley\ Bridge",
"441668", "Bamburgh",
"441855", "Ballachulish",
"441972", "Glenborrodale",
"441445", "Gairloch",
"441729", "Settle",
"44117", "Bristol",
"441408", "Golspie",
"4418517", "Stornoway",
"4416974", "Raughton\ Head",
"441592", "Kirkcaldy",
"4414236", "Harrogate",
"441677", "Bedale",
"442866", "Enniskillen",
"441797", "Rye",
"441583", "Carradale",
"44286", "Northern\ Ireland",
"441985", "Warminster",
"44287", "Northern\ Ireland",
"441606", "Northwich",
"441225", "Bath",
"441540", "Kingussie",
"442845", "Northern\ Ireland",
"441667", "Nairn",
"441803", "Torquay",
"441285", "Cirencester",
"441304", "Dover",
"441925", "Warrington",
"441756", "Skipton",
"44116", "Leicester",
"4418478", "Thurso",
"441407", "Holyhead",
"4419755", "Alford\ \(Aberdeen\)",
"4418474", "Thurso",
"441962", "Winchester",
"441544", "Kington",
"4415076", "Louth",
"441678", "Bala",
"441871", "Castlebay",
"441300", "Cerne\ Abbas",
"441798", "Pulborough",
"441262", "Bridlington",
"441466", "Huntly",
"441236", "Coatbridge",
"441432", "Hereford",
"441369", "Dunoon",
"441984", "Watchet\ \(Williton\)",
"441483", "Guildford",
"441224", "Aberdeen",
"441899", "Biggar",
"442844", "Downpatrick",
"441508", "Brooke",
"441284", "Bury\ St\ Edmunds",
"441492", "Colwyn\ Bay",
"441305", "Dorchester",
"441296", "Aylesbury",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441738", "Perth",
"441924", "Wakefield",
"441980", "Amesbury",
"441827", "Tamworth",
"441545", "Llanarth",
"442840", "Banbridge",
"441348", "Fishguard",
"44161", "Manchester",
"441280", "Buckingham",
"441576", "Lockerbie",
"441258", "Blandford",
"441920", "Ware",
"441887", "Aberfeldy",
"442892", "Lisburn",
"442823", "Northern\ Ireland",
"4414345", "Haltwhistle",
"441702", "Southend\-on\-Sea",
"441243", "Chichester",
"44239", "Portsmouth",
"441566", "Launceston",
"4414377", "Haverfordwest",
"441854", "Ullapool",
"441353", "Ely",
"441652", "Brigg",
"4413398", "Aboyne",
"441943", "Guiseley",
"4419645", "Hornsea",
"441444", "Haywards\ Heath",
"441737", "Redhill",
"4418902", "Coldstream",
"442883", "Northern\ Ireland",
"4414231", "Harrogate\/Boroughbridge",
"441828", "Coupar\ Angus",
"4413394", "Ballater",
"441621", "Maldon",
"4414305", "North\ Cave",
"441957", "Mid\ Yell",
"441347", "Easingwold",
"441257", "Coppull",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441888", "Turriff",
"441440", "Haverhill",
"4412292", "Barrow\-in\-Furness",
"441267", "Carmarthen",
"441809", "Tomdoun",
"4419649", "Hornsea",
"4415242", "Hornby",
"441744", "St\ Helens",
"441685", "Merthyr\ Tydfil",
"4414349", "Bellingham",
"442838", "Portadown",
"441967", "Strontian",
"441330", "Banchory",
"441206", "Colchester",
"441625", "Macclesfield",
"441395", "Budleigh\ Salterton",
"4415077", "Louth",
"441598", "Lynton",
"441740", "Sedgefield",
"441363", "Crediton",
"441864", "Abington\ \(Crawford\)",
"441636", "Newark\-on\-Trent",
"441978", "Wrexham",
"441833", "Barnard\ Castle",
"441556", "Castle\ Douglas",
"441334", "St\ Andrews",
"4414309", "Market\ Weighton",
"441278", "Bridgwater",
"441268", "Basildon",
"4413392", "Aboyne",
"441438", "Stevenage",
"441723", "Scarborough",
"441792", "Swansea",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"4418908", "Coldstream",
"441968", "Penicuik",
"442837", "Armagh",
"441672", "Marlborough",
"441373", "Frome",
"441874", "Brecon",
"4418516", "Great\ Bernera",
"4412294", "Barrow\-in\-Furness",
"4414237", "Harrogate",
"441597", "Llandrindod\ Wells",
"4416860", "Newtown\/Llanidloes",
"4412298", "Barrow\-in\-Furness",
"441301", "Arrochar",
"441977", "Pontefract",
"441870", "Isle\ of\ Benbecula",
"441529", "Sleaford",
"4418904", "Coldstream",
"441277", "Brentwood",
"441446", "Barry",
"441242", "Cheltenham",
"441959", "Westerham",
"442893", "Ballyclare",
"442822", "Northern\ Ireland",
"441349", "Dingwall",
"441911", "Tyneside\/Durham\/Sunderland",
"441856", "Orkney",
"4414348", "Hexham",
"441942", "Wigan",
"441259", "Alloa",
"44238", "Southampton",
"441564", "Lapworth",
"441352", "Mold",
"441653", "Malton",
"4414304", "North\ Cave",
"442882", "Omagh",
"4413395", "Aboyne",
"441475", "Greenock",
"4419648", "Hornsea",
"441691", "Oswestry",
"44114", "Sheffield",
"4415073", "Louth",
"4419644", "Patrington",
"441647", "Moretonhampstead",
"4414308", "Market\ Weighton",
"44291", "Cardiff",
"441560", "Moscow",
"441509", "Loughborough",
"441381", "Fortrose",
"441771", "Maud",
"4414344", "Bellingham",
"441926", "Warwick",
"441761", "Temple\ Cloud",
"441829", "Tarporley",
"441570", "Lampeter",
"441294", "Ardrossan",
"441482", "Kingston\-upon\-Hull",
"441286", "Caernarfon",
"441422", "Halifax",
"441493", "Great\ Yarmouth",
"441226", "Barnsley",
"442846", "Northern\ Ireland",
"441889", "Rugeley",
"4418909", "Ayton",
"442311", "Southampton",
"441986", "Bungay",
"441994", "St\ Clears",
"4414233", "Boroughbridge",
"441465", "Girvan",
"441451", "Stow\-on\-the\-Wold",
"441235", "Abingdon",
"441841", "Newquay\ \(Padstow\)",
"441290", "Cumnock",
"44131", "Edinburgh",
"4412299", "Millom",
"441935", "Yeovil",
"4418905", "Ayton",
"441793", "Swindon",
"441722", "Salisbury",
"441876", "Lochmaddy",
"441931", "Shap",
"4419642", "Hornsea",
"441673", "Market\ Rasen",
"441782", "Stoke\-on\-Trent",
"441372", "Esher",
"441845", "Thirsk",
"4418510", "Great\ Bernera\/Stornoway",
"441279", "Bishops\ Stortford",
"441527", "Redditch",
"441455", "Hinckley",
"441461", "Gretna",
"4414342", "Bellingham",
"4416866", "Newtown",
"4412295", "Barrow\-in\-Furness",
"441808", "Tomatin",
"442871", "Londonderry",
"441599", "Kyle",
"4414302", "North\ Cave",
"441751", "Pickering",
"441765", "Ripon",
"441775", "Spalding",
"441204", "Bolton",
"441588", "Bishops\ Castle",
"441550", "Llandovery",
"44247", "Coventry",
"4413399", "Ballater",
"441904", "York",
"441630", "Market\ Drayton",
"441528", "Laggan",
"441746", "Bridgnorth",
"441695", "Skelmersdale",
"441403", "Horsham",
"441325", "Darlington",
"4415396", "Sedbergh",
"441200", "Clitheroe",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441807", "Ballindalloch",
"441554", "Llanelli",
"441269", "Ammanford",
"441439", "Helmsley",
"441362", "Dereham",
"441663", "New\ Mills",
"441866", "Kilchrenan",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441832", "Clopton",
"441634", "Medway",
"441900", "Workington",
"441969", "Leyburn",
"441915", "Sunderland",
"441384", "Dudley",
"441205", "Boston",
"441883", "Caterham",
"441626", "Newton\ Abbot",
"441499", "Inveraray",
"441905", "Worcester",
"441910", "Tyneside\/Durham\/Sunderland",
"4418513", "Stornoway",
"441324", "Falkirk",
"441694", "Church\ Stretton",
"441892", "Tunbridge\ Wells",
"441823", "Taunton",
"442888", "Northern\ Ireland",
"441770", "Isle\ of\ Arran",
"441380", "Devizes",
"441561", "Laurencekirk",
"441555", "Lanark",
"441427", "Gainsborough",
"441948", "Whitchurch",
"441358", "Ellon",
"4419752", "Alford\ \(Aberdeen\)",
"441635", "Newbury",
"441487", "Warboys",
"441248", "Bangor\ \(Gwynedd\)",
"441690", "Betws\-y\-Coed",
"441320", "Fort\ Augustus",
"4420", "London",
"441914", "Tyneside",
"442828", "Larne",
"441659", "Sanquhar",
"442310", "Portsmouth",
"441253", "Blackpool",
"4418479", "Tongue",
"441844", "Thame",
"441642", "Middlesbrough",
"441343", "Elgin",
"442899", "Northern\ Ireland",
"441571", "Lochinver",
"441953", "Wymondham",
"441709", "Rotherham",
"4416861", "Newtown\/Llanidloes",
"441760", "Swaffham",
"441454", "Chipping\ Sodbury",
"441539", "Kendal",
"442887", "Dungannon",
"441733", "Peterborough",
"441947", "Whitby",
"441428", "Haslemere",
"441503", "Looe",
"441357", "Strathaven",
"441291", "Chepstow",
"441488", "Hungerford",
"441840", "Camelford",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441450", "Hawick",
"441764", "Crieff",
"442827", "Ballymoney",
"4413885", "Stanhope\ \(Eastgate\)",
"441754", "Skegness",
"441460", "Chard",
"441409", "Holsworthy",
"441306", "Dorking",
"441837", "Okehampton",
"441295", "Banbury",
"441604", "Northampton",
"4419754", "Alford\ \(Aberdeen\)",
"441367", "Faringdon",
"4418475", "Thurso",
"441995", "Garstang",
"441750", "Selkirk",
"441464", "Insch",
"4419758", "Strathdon",
"441234", "Bedford",
"441788", "Rugby",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441575", "Kirriemuir",
"442870", "Coleraine",
"441963", "Wincanton",
"441546", "Lochgilphead",
"441934", "Weston\-super\-Mare",
"441600", "Monmouth",
"441728", "Saxmundham",
"441669", "Rothbury",
"441433", "Hathersage",
"441263", "Cromer",
"441273", "Brighton",
"441838", "Dalmally",
"441631", "Oban",
"441565", "Knutsford",
"441368", "Dunbar",
"4416867", "Llanidloes",
"441799", "Saffron\ Walden",
"441474", "Gravesend",
"441593", "Lybster",
"441522", "Lincoln",
"441377", "Driffield",
"441787", "Sudbury",
"4414230", "Harrogate\/Boroughbridge",
"441727", "St\ Albans",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441582", "Luton",};

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