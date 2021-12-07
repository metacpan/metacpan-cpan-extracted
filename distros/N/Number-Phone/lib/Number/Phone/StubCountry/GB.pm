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
our $VERSION = 1.20211206222445;

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
                  70[0359]
                )|
                (?:
                  5[0-26-9]|
                  [78][0-49]
                )\\d\\d|
                6(?:
                  [0-4]\\d\\d|
                  50[0-24-69]
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
                    1[0-278]
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
                  70[0359]
                )|
                (?:
                  5[0-26-9]|
                  [78][0-49]
                )\\d\\d|
                6(?:
                  [0-4]\\d\\d|
                  50[0-24-69]
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
                    1[0-278]
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
$areanames{en} = {"441872", "Truro",
"441527", "Redditch",
"441772", "Preston",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441743", "Shrewsbury",
"441369", "Dunoon",
"441843", "Thanet",
"441451", "Stow\-on\-the\-Wold",
"441479", "Grantown\-on\-Spey",
"441202", "Bournemouth",
"4413397", "Ballater",
"441745", "Rhyl",
"441141", "Sheffield",
"441845", "Thirsk",
"441959", "Westerham",
"441971", "Scourie",
"441626", "Newton\ Abbot",
"441997", "Strathpeffer",
"4413399", "Ballater",
"441581", "New\ Luce",
"441695", "Skelmersdale",
"441652", "Brigg",
"441328", "Fakenham",
"442882", "Omagh",
"4419754", "Alford\ \(Aberdeen\)",
"441542", "Keith",
"4417687", "Keswick",
"441573", "Kelso",
"4415395", "Grange\-over\-Sands",
"4418905", "Ayton",
"441621", "Maldon",
"4412290", "Barrow\-in\-Furness\/Millom",
"4414308", "Market\ Weighton",
"442841", "Rostrevor",
"441768", "Penrith",
"441575", "Kirriemuir",
"441350", "Dunkeld",
"441586", "Campbeltown",
"441838", "Dalmally",
"441738", "Perth",
"441634", "Medway",
"441729", "Settle",
"441288", "Bude",
"441829", "Tarporley",
"441664", "Melton\ Mowbray",
"441985", "Warminster",
"441422", "Halifax",
"4413396", "Ballater",
"442311", "Southampton",
"441456", "Glenurquhart",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441983", "Isle\ of\ Wight",
"441687", "Mallaig",
"442877", "Limavady",
"441237", "Bideford",
"4414309", "Market\ Weighton",
"441366", "Downham\ Market",
"441212", "Birmingham",
"441485", "Hunstanton",
"441922", "Walsall",
"441267", "Carmarthen",
"441476", "Grantham",
"441668", "Bamburgh",
"441821", "Kinrossie",
"441721", "Peebles",
"441638", "Newmarket",
"441284", "Bury\ St\ Edmunds",
"441483", "Guildford",
"44141", "Glasgow",
"441834", "Narberth",
"441629", "Matlock",
"441303", "Folkestone",
"441592", "Kirkcaldy",
"441460", "Chard",
"441864", "Abington\ \(Crawford\)",
"441555", "Lanark",
"441764", "Crieff",
"4414307", "Market\ Weighton",
"441305", "Dorchester",
"442891", "Bangor\ \(Co\.\ Down\)",
"441787", "Sudbury",
"441553", "Kings\ Lynn",
"441887", "Aberfeldy",
"441497", "Hay\-on\-Wye",
"441672", "Marlborough",
"441324", "Falkirk",
"441947", "Whitby",
"442896", "Belfast",
"4412295", "Barrow\-in\-Furness",
"441643", "Minehead",
"4418900", "Coldstream\/Ayton",
"4414306", "Market\ Weighton",
"442825", "Ballymena",
"441726", "St\ Austell",
"441290", "Cumnock",
"441793", "Swindon",
"441951", "Colonsay",
"4415072", "Spilsby\ \(Horncastle\)",
"441752", "Plymouth",
"441895", "Uxbridge",
"441852", "Kilmelford",
"441795", "Sittingbourne",
"4413398", "Aboyne",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441361", "Duns",
"441346", "Fraserburgh",
"4414302", "North\ Cave",
"441694", "Church\ Stretton",
"441520", "Lochcarron",
"4418510", "Great\ Bernera\/Stornoway",
"442828", "Larne",
"441382", "Dundee",
"441844", "Thame",
"441440", "Haverhill",
"4414345", "Haltwhistle",
"441744", "St\ Helens",
"441279", "Bishops\ Stortford",
"441809", "Tomdoun",
"441709", "Rotherham",
"441798", "Pulborough",
"4418470", "Thurso\/Tongue",
"4415076", "Louth",
"441967", "Strontian",
"441663", "New\ Mills",
"441912", "Tyneside",
"441488", "Hungerford",
"441937", "Wetherby",
"441633", "Newport",
"441256", "Basingstoke",
"4419640", "Hornsea\/Patrington",
"441357", "Strathaven",
"441665", "Alnwick",
"441984", "Watchet\ \(Williton\)",
"4414378", "Haverfordwest",
"4415077", "Louth",
"441635", "Newbury",
"4415079", "Alford\ \(Lincs\)",
"4416863", "Llanidloes",
"441558", "Llandeilo",
"441606", "Northwich",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441308", "Bridport",
"441341", "Barmouth",
"44118", "Reading",
"441763", "Royston",
"441349", "Dingwall",
"441260", "Congleton",
"4414379", "Haverfordwest",
"441863", "Ardgay",
"441733", "Peterborough",
"441304", "Dover",
"442870", "Coleraine",
"441833", "Barnard\ Castle",
"4418515", "Stornoway",
"441765", "Ripon",
"441554", "Llanelli",
"441865", "Oxford",
"441835", "St\ Boswells",
"441578", "Lauder",
"441377", "Driffield",
"441285", "Cirencester",
"441276", "Camberley",
"4413392", "Aboyne",
"441467", "Inverurie",
"442866", "Enniskillen",
"441806", "Shetland",
"441706", "Rochdale",
"4418475", "Thurso",
"441988", "Wigtown",
"441880", "Tarbert",
"441484", "Huddersfield",
"441283", "Burton\-on\-Trent",
"441780", "Stamford",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"4415078", "Alford\ \(Lincs\)",
"4414377", "Haverfordwest",
"441902", "Wolverhampton",
"441794", "Romsey",
"441562", "Kidderminster",
"4419645", "Hornsea",
"441490", "Corwen",
"441271", "Barnstaple",
"4414233", "Boroughbridge",
"441259", "Alloa",
"4414376", "Haverfordwest",
"441848", "Thornhill",
"441748", "Richmond",
"441644", "New\ Galloway",
"441323", "Eastbourne",
"441609", "Northallerton",
"441297", "Axminster",
"441698", "Motherwell",
"441325", "Darlington",
"441463", "Inverness",
"441373", "Frome",
"4413395", "Aboyne",
"441264", "Andover",
"441342", "East\ Grinstead",
"441433", "Hathersage",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"4418472", "Thurso",
"441234", "Bedford",
"441300", "Cerne\ Abbas",
"441465", "Girvan",
"441287", "Guisborough",
"441386", "Evesham",
"441375", "Grays\ Thurrock",
"441550", "Llandovery",
"441435", "Heathfield",
"441767", "Sandy",
"441837", "Okehampton",
"441406", "Holbeach",
"4418512", "Stornoway",
"441737", "Redhill",
"441784", "Staines",
"441884", "Tiverton",
"441480", "Huntingdon",
"4415396", "Sedbergh",
"441911", "Tyneside\/Durham\/Sunderland",
"4412298", "Barrow\-in\-Furness",
"4414300", "North\ Cave\/Market\ Weighton",
"4418906", "Ayton",
"441944", "West\ Heslerton",
"441569", "Stonehaven",
"441909", "Worksop",
"441226", "Barnsley",
"441494", "High\ Wycombe",
"441327", "Daventry",
"441916", "Tyneside",
"441293", "Crawley",
"441539", "Kendal",
"441790", "Spilsby",
"441252", "Aldershot",
"4418907", "Ayton",
"441295", "Banbury",
"441381", "Fortrose",
"4418909", "Ayton",
"442820", "Ballycastle",
"4419642", "Hornsea",
"441528", "Laggan",
"44147986", "Cairngorm",
"4414342", "Bellingham",
"441690", "Betws\-y\-Coed",
"441524", "Lancaster",
"441389", "Dumbarton",
"4413390", "Aboyne\/Ballater",
"441243", "Chichester",
"441740", "Sedgefield",
"4420", "London",
"441840", "Camelford",
"441444", "Haywards\ Heath",
"4414305", "North\ Cave",
"441702", "Southend\-on\-Sea",
"441409", "Holsworthy",
"441994", "St\ Clears",
"441245", "Chelmsford",
"441561", "Laurencekirk",
"441948", "Whitchurch",
"441531", "Ledbury",
"4418908", "Coldstream",
"4412296", "Barrow\-in\-Furness",
"441566", "Launceston",
"4419753", "Strathdon",
"441788", "Rugby",
"441919", "Durham",
"441536", "Kettering",
"441888", "Turriff",
"441980", "Amesbury",
"4412297", "Millom",
"4412299", "Millom",
"441667", "Nairn",
"441570", "Lampeter",
"441355", "East\ Kilbride",
"441392", "Exeter",
"441963", "Wincanton",
"441503", "Looe",
"441637", "Newquay",
"441933", "Wellingborough",
"441353", "Ely",
"441684", "Malvern",
"441505", "Johnstone",
"441935", "Yeovil",
"441268", "Basildon",
"4413873", "Langholm",
"441307", "Forfar",
"441206", "Colchester",
"441929", "Wareham",
"441885", "Pencombe",
"441876", "Lochmaddy",
"4414349", "Bellingham",
"441785", "Stafford",
"441776", "Stranraer",
"441883", "Caterham",
"441557", "Kirkcudbright",
"441280", "Buckingham",
"441730", "Petersfield",
"441599", "Kyle",
"441233", "Ashford\ \(Kent\)",
"441358", "Ellon",
"441830", "Kirkwhelpington",
"442842", "Kircubbin",
"441760", "Swaffham",
"441263", "Cromer",
"4415242", "Hornby",
"441464", "Insch",
"441622", "Maidstone",
"441235", "Abingdon",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441968", "Penicuik",
"442886", "Cookstown",
"4414347", "Hexham",
"441487", "Warboys",
"441938", "Welshpool",
"441508", "Brooke",
"4419648", "Hornsea",
"441656", "Bridgend",
"441320", "Fort\ Augustus",
"442881", "Newtownstewart",
"441797", "Rye",
"4415075", "Spilsby\ \(Horncastle\)",
"441651", "Oldmeldrum",
"441546", "Lochgilphead",
"441582", "Luton",
"4414346", "Hexham",
"4414234", "Boroughbridge",
"4418478", "Thurso",
"4414231", "Harrogate\/Boroughbridge",
"441972", "Glenborrodale",
"441294", "Ardrossan",
"441142", "Sheffield",
"441493", "Great\ Yarmouth",
"441647", "Moretonhampstead",
"442827", "Ballymoney",
"441943", "Guiseley",
"4412292", "Barrow\-in\-Furness",
"441452", "Gloucester",
"441248", "Bangor\ \(Gwynedd\)",
"441495", "Pontypool",
"441759", "Pocklington",
"441771", "Maud",
"4418518", "Stornoway",
"441871", "Castlebay",
"441945", "Wisbech",
"441859", "Harris",
"4418479", "Tongue",
"441216", "Birmingham",
"441993", "Witney",
"441362", "Dereham",
"441697", "Brampton",
"441472", "Grimsby",
"441209", "Redruth",
"441926", "Warwick",
"441443", "Pontypridd",
"441879", "Scarinish",
"441332", "Derby",
"441244", "Chester",
"441751", "Pickering",
"441779", "Peterhead",
"441995", "Garstang",
"441952", "Telford",
"441445", "Gairloch",
"441298", "Buxton",
"4418517", "Stornoway",
"4418519", "Great\ Bernera",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441747", "Shaftesbury",
"441525", "Leighton\ Buzzard",
"442889", "Fivemiletown",
"4418477", "Tongue",
"441659", "Sanquhar",
"441671", "Newton\ Stewart",
"4419646", "Patrington",
"441934", "Weston\-super\-Mare",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"442892", "Lisburn",
"441676", "Meriden",
"441685", "Merthyr\ Tydfil",
"441549", "Lairg",
"4414348", "Hexham",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441591", "Llanwrtyd\ Wells",
"441683", "Moffat",
"4416861", "Newtown\/Llanidloes",
"4419647", "Patrington",
"441354", "Chatteris",
"441987", "Ebbsfleet",
"4418476", "Tongue",
"441438", "Stevenage",
"4419649", "Hornsea",
"44113", "Leeds",
"441429", "Hartlepool",
"441630", "Market\ Drayton",
"4416864", "Llanidloes",
"44161", "Manchester",
"441722", "Salisbury",
"44147984", "Carrbridge",
"44116", "Leicester",
"441822", "Tavistock",
"4418902", "Coldstream",
"441577", "Kinross",
"441211", "Birmingham",
"441756", "Skipton",
"4418516", "Great\ Bernera",
"441856", "Orkney",
"4419755", "Alford\ \(Aberdeen\)",
"441431", "Helmsdale",
"4416862", "Llanidloes",
"441359", "Pakenham",
"441371", "Great\ Dunmow",
"4415394", "Hawkshead",
"4418904", "Coldstream",
"441598", "Lynton",
"441461", "Gretna",
"441509", "Loughborough",
"441939", "Wem",
"441544", "Kington",
"442890", "Belfast",
"441969", "Leyburn",
"4413882", "Stanhope\ \(Eastgate\)",
"441225", "Bath",
"441915", "Sunderland",
"441928", "Runcorn",
"4418901", "Coldstream\/Ayton",
"441397", "Fort\ William",
"441720", "Isles\ of\ Scilly",
"441223", "Cambridge",
"441424", "Hastings",
"441296", "Aylesbury",
"441913", "Durham",
"44147983", "Boat\ of\ Garten",
"441291", "Chepstow",
"441405", "Goole",
"441950", "Sandwick",
"441204", "Bolton",
"441330", "Banchory",
"44131", "Edinburgh",
"441858", "Market\ Harborough",
"441403", "Horsham",
"44147982", "Nethy\ Bridge",
"441758", "Pwllheli",
"441360", "Killearn",
"441249", "Chippenham",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441874", "Brecon",
"441678", "Bala",
"441654", "Machynlleth",
"4414303", "North\ Cave",
"441383", "Dunfermline",
"441707", "Welwyn\ Garden\ City",
"441436", "Helensburgh",
"442867", "Lisnaskea",
"441807", "Ballindalloch",
"441277", "Brentwood",
"441466", "Huntly",
"442837", "Armagh",
"441376", "Braintree",
"441356", "Brechin",
"441580", "Cranbrook",
"4412294", "Barrow\-in\-Furness",
"441257", "Coppull",
"441506", "Bathgate",
"441322", "Dartford",
"441674", "Montrose",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"4417683", "Appleby",
"441905", "Worcester",
"441778", "Bourne",
"441535", "Keighley",
"441878", "Lochboisdale",
"441208", "Bodmin",
"441854", "Ullapool",
"441450", "Hawick",
"441565", "Knutsford",
"441241", "Arbroath",
"441754", "Skegness",
"4412291", "Barrow\-in\-Furness\/Millom",
"441903", "Worthing",
"441299", "Bewdley",
"441140", "Sheffield",
"441970", "Aberystwyth",
"4414232", "Harrogate",
"441563", "Kilmarnock",
"441282", "Burnley",
"4413393", "Aboyne",
"441428", "Haslemere",
"44247", "Coventry",
"441924", "Wakefield",
"441214", "Birmingham",
"441246", "Chesterfield",
"441347", "Easingwold",
"442310", "Portsmouth",
"441548", "Kingsbridge",
"441931", "Shap",
"441501", "Harthill",
"442840", "Banbridge",
"441439", "Helmsley",
"441620", "North\ Berwick",
"441862", "Tain",
"441594", "Lydney",
"441732", "Sevenoaks",
"441469", "Killingholme",
"441832", "Clopton",
"441379", "Diss",
"4419467", "Gosforth",
"441982", "Builth\ Wells",
"441425", "Ringwood",
"4414237", "Harrogate",
"442897", "Saintfield",
"441946", "Whitehaven",
"441914", "Tyneside",
"441496", "Port\ Ellen",
"441224", "Aberdeen",
"441689", "Orpington",
"441261", "Banff",
"441545", "Llanarth",
"442871", "Londonderry",
"4414239", "Boroughbridge",
"441543", "Cannock",
"441572", "Oakham",
"441827", "Tamworth",
"441727", "St\ Albans",
"441384", "Dudley",
"441957", "Mid\ Yell",
"441653", "Malton",
"441692", "North\ Walsham",
"441477", "Holmes\ Chapel",
"441367", "Faringdon",
"4416868", "Newtown",
"441655", "Maybole",
"441236", "Coatbridge",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441337", "Ladybank",
"442885", "Ballygawley",
"441529", "Sleaford",
"441875", "Tranent",
"4414344", "Bellingham",
"441538", "Ipstones",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441908", "Milton\ Keynes",
"441775", "Spalding",
"441786", "Stirling",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441491", "Henley\-on\-Thames",
"441568", "Leominster",
"4414236", "Harrogate",
"441205", "Boston",
"441449", "Stowmarket",
"44281", "Northern\ Ireland",
"442830", "Newry",
"441873", "Abergavenny",
"441773", "Ripley",
"441270", "Crewe",
"441404", "Honiton",
"441700", "Rothesay",
"441842", "Thetford",
"441408", "Golspie",
"441250", "Blairgowrie",
"441753", "Slough",
"4415073", "Louth",
"4416869", "Newtown",
"4419644", "Patrington",
"441892", "Tunbridge\ Wells",
"441564", "Lapworth",
"441792", "Swansea",
"441949", "Whatton",
"441855", "Ballachulish",
"441534", "Jersey",
"441904", "York",
"441499", "Inveraray",
"441675", "Coleshill",
"441457", "Glossop",
"4419641", "Hornsea\/Patrington",
"441673", "Market\ Rasen",
"4416867", "Llanidloes",
"44239", "Portsmouth",
"441977", "Pontefract",
"441388", "Bishop\ Auckland",
"441600", "Monmouth",
"441642", "Middlesbrough",
"4416974", "Raughton\ Head",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"4418514", "Great\ Bernera",
"441269", "Ammanford",
"4418471", "Thurso\/Tongue",
"441340", "Craigellachie\ \(Aberlour\)",
"441302", "Doncaster",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"4416866", "Newtown",
"441239", "Cardigan",
"441593", "Lybster",
"442879", "Magherafelt",
"441526", "Martin",
"441918", "Tyneside",
"441889", "Rugeley",
"441789", "Stratford\-upon\-Avon",
"441228", "Carlisle",
"441215", "Birmingham",
"441482", "Kingston\-upon\-Hull",
"441925", "Warrington",
"4414238", "Harrogate",
"4418474", "Thurso",
"441446", "Barry",
"4418511", "Great\ Bernera\/Stornoway",
"441213", "Birmingham",
"441923", "Watford",
"441708", "Romford",
"441841", "Newquay\ \(Padstow\)",
"441145", "Sheffield",
"441986", "Bungay",
"4412293", "Millom",
"441453", "Dursley",
"442868", "Kesh",
"441808", "Tomatin",
"441254", "Blackburn",
"441278", "Bridgwater",
"442838", "Portadown",
"441143", "Sheffield",
"4419757", "Strathdon",
"44291", "Cardiff",
"441455", "Hinckley",
"4417684", "Pooley\ Bridge",
"441492", "Colwyn\ Bay",
"441677", "Bedale",
"441560", "Moscow",
"441900", "Workington",
"441899", "Biggar",
"441799", "Saffron\ Walden",
"441942", "Wigan",
"441530", "Coalville",
"44151", "Liverpool",
"441583", "Carradale",
"441857", "Sanday",
"441757", "Selby",
"4419759", "Alford\ \(Aberdeen\)",
"441691", "Oswestry",
"442829", "Kilrea",
"441576", "Lockerbie",
"441604", "Northampton",
"441398", "Dulverton",
"4413394", "Ballater",
"441559", "Llandysul",
"441571", "Lochinver",
"44238", "Southampton",
"441625", "Macclesfield",
"441344", "Bracknell",
"44147981", "Aviemore",
"441262", "Bridlington",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441623", "Mansfield",
"441309", "Forres",
"441217", "Birmingham",
"441489", "Bishops\ Waltham",
"441882", "Kinloch\ Rannoch",
"441782", "Stoke\-on\-Trent",
"441746", "Bridgnorth",
"441981", "Wormbridge",
"4419756", "Strathdon",
"4413391", "Aboyne\/Ballater",
"441597", "Llandrindod\ Wells",
"4418903", "Coldstream",
"441989", "Ross\-on\-Wye",
"441725", "Rockbourne",
"441825", "Uckfield",
"441547", "Knighton",
"441481", "Guernsey",
"441723", "Scarborough",
"441896", "Galashiels",
"441796", "Pitlochry",
"441910", "Tyneside\/Durham\/Sunderland",
"441823", "Taunton",
"442895", "Belfast",
"441301", "Arrochar",
"441348", "Fishguard",
"4412180", "Birmingham",
"441579", "Liskeard",
"442893", "Ballyclare",
"441646", "Milford\ Haven",
"441394", "Felixstowe",
"441427", "Gainsborough",
"441641", "Strathy",
"442821", "Martinstown",
"441380", "Devizes",
"441556", "Castle\ Douglas",
"441608", "Chipping\ Norton",
"441777", "Retford",
"441522", "Lincoln",
"441877", "Callander",
"4414301", "North\ Cave\/Market\ Weighton",
"441207", "Consett",
"441306", "Dorking",
"441475", "Greenock",
"4414304", "North\ Cave",
"441953", "Wymondham",
"442887", "Dungannon",
"441335", "Ashbourne",
"441992", "Lea\ Valley",
"441749", "Shepton\ Mallet",
"441363", "Crediton",
"441274", "Bradford",
"441955", "Wick",
"44241", "Coventry",
"441473", "Ipswich",
"4419758", "Strathdon",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441704", "Southport",
"441442", "Hemel\ Hempstead",
"441400", "Honington",
"441258", "Blandford",
"4419643", "Patrington",
"4415074", "Alford\ \(Lincs\)",
"441584", "Ludlow",
"441329", "Fareham",
"441603", "Norwich",
"441670", "Morpeth",
"441567", "Killin",
"4414235", "Harrogate",
"44117", "Bristol",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441368", "Dunbar",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441253", "Blackpool",
"441750", "Selkirk",
"441454", "Chipping\ Sodbury",
"441636", "Newark\-on\-Trent",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441255", "Clacton\-on\-Sea",
"441144", "Sheffield",
"441292", "Ayr",
"441666", "Malmesbury",
"441974", "Llanon",
"4416860", "Newtown\/Llanidloes",
"441631", "Oban",
"4418513", "Stornoway",
"441661", "Prudhoe",
"441828", "Coupar\ Angus",
"4416973", "Wigton",
"441289", "Berwick\-upon\-Tweed",
"441728", "Saxmundham",
"441210", "Birmingham",
"441920", "Ware",
"442898", "Belfast",
"4418473", "Thurso",
"441624", "Isle\ of\ Man",
"441462", "Hitchin",
"441590", "Lymington",
"442844", "Downpatrick",
"441372", "Esher",
"441432", "Hereford",
"441343", "Elgin",
"441769", "South\ Molton",
"441869", "Bicester",
"441352", "Mold",
"4414230", "Harrogate\/Boroughbridge",
"441395", "Budleigh\ Salterton",
"441628", "Maidenhead",
"441761", "Temple\ Cloud",
"441326", "Falmouth",
"441917", "Sunderland",
"441962", "Winchester",
"441227", "Canterbury",
"442894", "Antrim",
"441502", "Lowestoft",
"441540", "Kingussie",
"441932", "Weybridge",
"4416865", "Newtown",
"4419752", "Alford\ \(Aberdeen\)",
"441420", "Alton",
"441824", "Ruthin",
"441639", "Neath",
"441724", "Scunthorpe",
"44147985", "Dulnain\ Bridge",
"4413885", "Stanhope\ \(Eastgate\)",
"441669", "Rothbury",
"441805", "Torrington",
"441978", "Wrexham",
"441387", "Dumfries",
"441954", "Madingley",
"441275", "Clevedon",
"441286", "Caernarfon",
"441803", "Torquay",
"441242", "Cheltenham",
"441200", "Clitheroe",
"441334", "St\ Andrews",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441458", "Glastonbury",
"44292", "Cardiff",
"441474", "Gravesend",
"441870", "Isle\ of\ Benbecula",
"441364", "Ashburton",
"441770", "Isle\ of\ Arran",
"441273", "Brighton",
"442880", "Carrickmore",
"44115", "Nottingham",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441650", "Cemmaes\ Road",
"4414343", "Haltwhistle",
"441407", "Holyhead",
"441736", "Penzance",
"441588", "Bishops\ Castle",
"441766", "Porthmadog",
"441866", "Kilchrenan",};

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