# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20230903131447;

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
                  70[0-79]
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
                  [0-5]\\d\\d|
                  69[7-9]|
                  70[0-79]
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
$areanames{en} = {"441842", "Thetford",
"4414307", "Market\ Weighton",
"441334", "St\ Andrews",
"441697", "Brampton",
"441644", "New\ Galloway",
"442310", "Portsmouth",
"441931", "Shap",
"441304", "Dover",
"441278", "Bridgwater",
"441584", "Ludlow",
"442824", "Northern\ Ireland",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441830", "Kirkwhelpington",
"4414349", "Bellingham",
"441476", "Grantham",
"441275", "Clevedon",
"441263", "Cromer",
"441995", "Garstang",
"441387", "Dumfries",
"442871", "Londonderry",
"441204", "Bolton",
"4414378", "Haverfordwest",
"442894", "Antrim",
"442847", "Northern\ Ireland",
"441562", "Kidderminster",
"4419648", "Hornsea",
"4414237", "Harrogate",
"441918", "Tyneside",
"441928", "Runcorn",
"441666", "Malmesbury",
"441375", "Grays\ Thurrock",
"44292", "Cardiff",
"44291", "Cardiff",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441915", "Sunderland",
"441363", "Crediton",
"441287", "Guisborough",
"4412290", "Barrow\-in\-Furness\/Millom",
"441925", "Warrington",
"4419641", "Hornsea\/Patrington",
"441234", "Bedford",
"441823", "Taunton",
"441765", "Ripon",
"4418513", "Stornoway",
"441757", "Selby",
"441773", "Ripley",
"4419755", "Alford\ \(Aberdeen\)",
"441768", "Penrith",
"4419754", "Alford\ \(Aberdeen\)",
"441569", "Stonehaven",
"441806", "Shetland",
"441262", "Bridlington",
"441384", "Dudley",
"441945", "Wisbech",
"441899", "Biggar",
"4419649", "Hornsea",
"441307", "Forfar",
"442827", "Ballymoney",
"4414379", "Haverfordwest",
"4415073", "Louth",
"441948", "Whitchurch",
"441981", "Wormbridge",
"4413873", "Langholm",
"441880", "Tarbert",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"4414302", "North\ Cave",
"4416973", "Wigton",
"441461", "Gretna",
"441534", "Jersey",
"441269", "Ammanford",
"441337", "Ladybank",
"441843", "Thanet",
"441694", "Church\ Stretton",
"441647", "Moretonhampstead",
"441892", "Tunbridge\ Wells",
"442866", "Enniskillen",
"4413882", "Stanhope\ \(Eastgate\)",
"441671", "Newton\ Stewart",
"441369", "Dunoon",
"441237", "Bideford",
"4417683", "Appleby",
"441822", "Tavistock",
"441624", "Isle\ of\ Man",
"441754", "Skegness",
"441772", "Preston",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441779", "Peterhead",
"441362", "Dereham",
"441829", "Tarporley",
"441284", "Bury\ St\ Edmunds",
"441578", "Lauder",
"44114700", "Sheffield",
"4414232", "Harrogate",
"441207", "Consett",
"44141", "Glasgow",
"442897", "Saintfield",
"4414348", "Hexham",
"441950", "Sandwick",
"442844", "Downpatrick",
"4419756", "Strathdon",
"441563", "Kilmarnock",
"441575", "Kirriemuir",
"441944", "West\ Heslerton",
"441505", "Johnstone",
"441732", "Sevenoaks",
"441997", "Strathpeffer",
"441253", "Blackpool",
"44238", "Southampton",
"4417687", "Keswick",
"441277", "Brentwood",
"441591", "Llanwrtyd\ Wells",
"441631", "Oban",
"441508", "Brooke",
"4418512", "Stornoway",
"441388", "Bishop\ Auckland",
"441341", "Barmouth",
"441796", "Pitlochry",
"441709", "Rotherham",
"441535", "Keighley",
"441702", "Southend\-on\-Sea",
"4412298", "Barrow\-in\-Furness",
"441740", "Sedgefield",
"441698", "Motherwell",
"441538", "Ipstones",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"4419640", "Hornsea\/Patrington",
"4418906", "Ayton",
"4412291", "Barrow\-in\-Furness\/Millom",
"441695", "Skelmersdale",
"441758", "Pwllheli",
"4415077", "Louth",
"441628", "Maidenhead",
"441559", "Llandysul",
"441442", "Hemel\ Hempstead",
"441493", "Great\ Yarmouth",
"441400", "Honington",
"441625", "Macclesfield",
"441767", "Sandy",
"441917", "Sunderland",
"441285", "Cirencester",
"441449", "Stowmarket",
"441353", "Ely",
"442881", "Newtownstewart",
"442848", "Northern\ Ireland",
"441377", "Driffield",
"441726", "St\ Austell",
"441288", "Bude",
"441241", "Arbroath",
"441143", "Sheffield",
"442845", "Northern\ Ireland",
"44114704", "Sheffield",
"441876", "Lochmaddy",
"441656", "Bridgend",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441259", "Alloa",
"441422", "Halifax",
"441782", "Stoke\-on\-Trent",
"441335", "Ashbourne",
"4414233", "Boroughbridge",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441790", "Spilsby",
"441451", "Stow\-on\-the\-Wold",
"441746", "Bridgnorth",
"442825", "Ballymena",
"441305", "Dorchester",
"44114702", "Sheffield",
"441789", "Stratford\-upon\-Avon",
"441733", "Peterborough",
"441947", "Whitby",
"4418904", "Coldstream",
"4418517", "Stornoway",
"441994", "St\ Clears",
"441252", "Aldershot",
"442828", "Larne",
"441588", "Bishops\ Castle",
"441429", "Hartlepool",
"4418905", "Ayton",
"441274", "Bradford",
"441308", "Bridport",
"441291", "Chepstow",
"441577", "Kinross",
"441142", "Sheffield",
"441553", "Kings\ Lynn",
"441971", "Scourie",
"441205", "Boston",
"442895", "Belfast",
"441924", "Wakefield",
"441406", "Holbeach",
"441914", "Tyneside",
"441352", "Mold",
"4414303", "North\ Cave",
"442898", "Belfast",
"441208", "Bodmin",
"441499", "Inveraray",
"441443", "Pontypridd",
"441359", "Pakenham",
"4415072", "Spilsby\ \(Horncastle\)",
"441492", "Colwyn\ Bay",
"441764", "Crieff",
"441235", "Abingdon",
"4412299", "Millom",
"441436", "Helensburgh",
"441480", "Huntingdon",
"441870", "Isle\ of\ Benbecula",
"441650", "Cemmaes\ Road",
"441720", "Isles\ of\ Scilly",
"441933", "Wellingborough",
"441747", "Shaftesbury",
"441989", "Ross\-on\-Wye",
"4418519", "Great\ Bernera",
"441794", "Romsey",
"4415395", "Grange\-over\-Sands",
"441462", "Hitchin",
"441808", "Tomatin",
"4415394", "Hawkshead",
"44131", "Edinburgh",
"44280", "Northern\ Ireland",
"441946", "Whitehaven",
"4414300", "North\ Cave\/Market\ Weighton",
"441805", "Torrington",
"4418475", "Thurso",
"441903", "Worthing",
"441270", "Crewe",
"4418474", "Thurso",
"441838", "Dalmally",
"4413396", "Ballater",
"441261", "Banff",
"4415078", "Alford\ \(Lincs\)",
"442868", "Kesh",
"44283", "Northern\ Ireland",
"441469", "Killingholme",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441982", "Builth\ Wells",
"4416866", "Newtown",
"441835", "St\ Boswells",
"4412297", "Millom",
"4414343", "Haltwhistle",
"441920", "Ware",
"441910", "Tyneside\/Durham\/Sunderland",
"441361", "Duns",
"4414230", "Harrogate\/Boroughbridge",
"441859", "Harris",
"441724", "Scunthorpe",
"441576", "Lockerbie",
"441484", "Huddersfield",
"441852", "Kilmelford",
"441672", "Marlborough",
"441654", "Machynlleth",
"441874", "Brecon",
"441760", "Swaffham",
"44121", "Birmingham",
"441407", "Holyhead",
"441821", "Kinrossie",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441771", "Maud",
"44114703", "Sheffield",
"4415396", "Sedbergh",
"441939", "Wem",
"441983", "Isle\ of\ Wight",
"441902", "Wolverhampton",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"4413394", "Ballater",
"442879", "Magherafelt",
"4418476", "Tongue",
"441888", "Turriff",
"441841", "Newquay\ \(Padstow\)",
"441909", "Worksop",
"4413395", "Aboyne",
"441276", "Camberley",
"441744", "St\ Helens",
"441932", "Weybridge",
"441475", "Greenock",
"4416864", "Llanidloes",
"441885", "Pencombe",
"441797", "Rye",
"441463", "Inverness",
"4416865", "Newtown",
"44151", "Liverpool",
"44247", "Coventry",
"441668", "Bamburgh",
"441926", "Warwick",
"441404", "Honiton",
"441916", "Tyneside",
"4418511", "Great\ Bernera\/Stornoway",
"441376", "Braintree",
"441665", "Alnwick",
"441727", "St\ Albans",
"441487", "Warboys",
"44115", "Nottingham",
"441673", "Market\ Rasen",
"4418518", "Stornoway",
"441877", "Callander",
"441561", "Laurencekirk",
"441955", "Wick",
"4412292", "Barrow\-in\-Furness",
"441570", "Lampeter",
"441967", "Strontian",
"4414373", "Clynderwen\ \(Clunderwen\)",
"4415079", "Alford\ \(Lincs\)",
"44114709", "Sheffield",
"441766", "Porthmadog",
"4419643", "Patrington",
"441837", "Okehampton",
"441343", "Elgin",
"441689", "Orpington",
"441392", "Exeter",
"441633", "Newport",
"441380", "Devizes",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441646", "Milford\ Haven",
"441593", "Lybster",
"441542", "Keith",
"442867", "Lisnaskea",
"4419647", "Patrington",
"4414238", "Harrogate",
"441807", "Ballindalloch",
"441549", "Lairg",
"441603", "Norwich",
"441690", "Betws\-y\-Coed",
"4414377", "Haverfordwest",
"441748", "Richmond",
"441306", "Dorking",
"441586", "Campbeltown",
"441530", "Coalville",
"4414231", "Harrogate\/Boroughbridge",
"442826", "Northern\ Ireland",
"441884", "Tiverton",
"441452", "Gloucester",
"441745", "Rhyl",
"4414342", "Bellingham",
"441474", "Gravesend",
"441750", "Selkirk",
"441491", "Henley\-on\-Thames",
"441620", "North\ Berwick",
"441405", "Goole",
"441206", "Colchester",
"442896", "Belfast",
"441329", "Fareham",
"441862", "Tain",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441299", "Bewdley",
"441408", "Golspie",
"441664", "Melton\ Mowbray",
"441322", "Dartford",
"441141", "Sheffield",
"441869", "Bicester",
"441243", "Chichester",
"441292", "Ayr",
"441954", "Madingley",
"4414308", "Market\ Weighton",
"4419467", "Gosforth",
"4420", "London",
"441972", "Glenborrodale",
"441435", "Heathfield",
"442840", "Banbridge",
"441236", "Coatbridge",
"441280", "Buckingham",
"442883", "Northern\ Ireland",
"441438", "Stevenage",
"4414301", "North\ Cave\/Market\ Weighton",
"4419642", "Hornsea",
"441887", "Aberfeldy",
"441453", "Dursley",
"441349", "Dingwall",
"441795", "Sittingbourne",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441683", "Moffat",
"441477", "Holmes\ Chapel",
"441639", "Neath",
"441599", "Kyle",
"441798", "Pulborough",
"441330", "Banchory",
"4414347", "Hexham",
"441386", "Evesham",
"4412293", "Millom",
"441506", "Bathgate",
"441592", "Kirkcaldy",
"441543", "Cannock",
"441609", "Northallerton",
"4418510", "Great\ Bernera\/Stornoway",
"4414309", "Market\ Weighton",
"441223", "Cambridge",
"441342", "East\ Grinstead",
"441834", "Narberth",
"441300", "Cerne\ Abbas",
"442820", "Ballycastle",
"441580", "Cranbrook",
"441536", "Kettering",
"441968", "Penicuik",
"441626", "Newton\ Abbot",
"441756", "Skipton",
"442882", "Omagh",
"441522", "Lincoln",
"441323", "Eastbourne",
"441242", "Cheltenham",
"441293", "Crawley",
"442890", "Belfast",
"441957", "Mid\ Yell",
"441200", "Clitheroe",
"441655", "Maybole",
"441875", "Tranent",
"441485", "Hunstanton",
"442846", "Northern\ Ireland",
"44116", "Leicester",
"441249", "Chippenham",
"441863", "Ardgay",
"44287", "Northern\ Ireland",
"441725", "Rockbourne",
"441667", "Nairn",
"441878", "Lochboisdale",
"442889", "Fivemiletown",
"441488", "Hungerford",
"441529", "Sleaford",
"4414239", "Boroughbridge",
"441286", "Caernarfon",
"441728", "Saxmundham",
"441250", "Blairgowrie",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"4413398", "Aboyne",
"441501", "Harthill",
"4416861", "Newtown\/Llanidloes",
"441638", "Newmarket",
"4415076", "Louth",
"442877", "Limavady",
"441381", "Fortrose",
"441348", "Fishguard",
"441706", "Rochdale",
"441598", "Lynton",
"441984", "Watchet\ \(Williton\)",
"441635", "Newbury",
"4416868", "Newtown",
"4413391", "Aboyne\/Ballater",
"441799", "Saffron\ Walden",
"441937", "Wetherby",
"441743", "Shrewsbury",
"441792", "Swansea",
"441608", "Chipping\ Norton",
"441531", "Ledbury",
"441464", "Insch",
"4415242", "Hornby",
"441780", "Stamford",
"441736", "Penzance",
"441691", "Oswestry",
"441420", "Alton",
"441969", "Leyburn",
"441722", "Salisbury",
"441556", "Castle\ Douglas",
"441482", "Kingston\-upon\-Hull",
"441854", "Ullapool",
"441674", "Montrose",
"441652", "Brigg",
"441872", "Truro",
"441621", "Maldon",
"441403", "Horsham",
"4418479", "Tongue",
"441751", "Pickering",
"441490", "Corwen",
"441446", "Barry",
"442885", "Ballygawley",
"441350", "Dunkeld",
"441525", "Leighton\ Buzzard",
"4419753", "Strathdon",
"441248", "Bangor\ \(Gwynedd\)",
"441489", "Bishops\ Waltham",
"441528", "Laggan",
"442888", "Northern\ Ireland",
"442841", "Rostrevor",
"441433", "Hathersage",
"4418907", "Ayton",
"4418514", "Great\ Bernera",
"441659", "Sanquhar",
"441879", "Scarinish",
"441962", "Winchester",
"441729", "Settle",
"4418515", "Stornoway",
"441140", "Sheffield",
"441245", "Chelmsford",
"4418478", "Thurso",
"441641", "Strathy",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441458", "Glastonbury",
"4415074", "Alford\ \(Lincs\)",
"441256", "Basingstoke",
"4415075", "Spilsby\ \(Horncastle\)",
"441934", "Weston\-super\-Mare",
"441685", "Merthyr\ Tydfil",
"4418471", "Thurso\/Tongue",
"441793", "Swindon",
"441455", "Hinckley",
"441700", "Rothesay",
"441467", "Inverurie",
"442821", "Martinstown",
"441548", "Kingsbridge",
"441581", "New\ Luce",
"44239", "Portsmouth",
"441301", "Arrochar",
"441749", "Shepton\ Mallet",
"441395", "Budleigh\ Salterton",
"441987", "Ebbsfleet",
"441225", "Bath",
"441904", "York",
"441545", "Llanarth",
"441730", "Petersfield",
"441786", "Stirling",
"4416974", "Raughton\ Head",
"441398", "Dulverton",
"441228", "Carlisle",
"441432", "Hereford",
"442891", "Bangor\ \(Co\.\ Down\)",
"4416869", "Newtown",
"441295", "Banbury",
"441963", "Wincanton",
"441550", "Llandovery",
"441325", "Darlington",
"4417684", "Pooley\ Bridge",
"4413399", "Ballater",
"44114707", "Sheffield",
"441978", "Wrexham",
"4418902", "Coldstream",
"441496", "Port\ Ellen",
"441298", "Buxton",
"441409", "Holsworthy",
"441328", "Fakenham",
"441356", "Brechin",
"441440", "Haverhill",
"441723", "Scarborough",
"441865", "Oxford",
"441146", "Sheffield",
"441483", "Guildford",
"442838", "Portadown",
"441439", "Helmsley",
"441677", "Bedale",
"4418516", "Great\ Bernera",
"441857", "Sanday",
"44286", "Northern\ Ireland",
"44117", "Bristol",
"441873", "Abergavenny",
"441653", "Malton",
"441803", "Torquay",
"4414236", "Harrogate",
"441938", "Welshpool",
"441882", "Kinloch\ Rannoch",
"441454", "Chipping\ Sodbury",
"441684", "Malvern",
"441935", "Yeovil",
"441472", "Grimsby",
"4419752", "Alford\ \(Aberdeen\)",
"44113", "Leeds",
"441224", "Aberdeen",
"441889", "Rugeley",
"441833", "Barnard\ Castle",
"441347", "Easingwold",
"441394", "Felixstowe",
"441637", "Newquay",
"441479", "Grantown\-on\-Spey",
"441908", "Milton\ Keynes",
"441260", "Congleton",
"441271", "Barnstaple",
"441597", "Llandrindod\ Wells",
"441905", "Worcester",
"441544", "Kington",
"441324", "Falkirk",
"441294", "Ardrossan",
"441669", "Rothbury",
"441952", "Telford",
"441974", "Llanon",
"4414306", "Market\ Weighton",
"441911", "Tyneside\/Durham\/Sunderland",
"441360", "Killearn",
"441371", "Great\ Dunmow",
"442887", "Dungannon",
"441527", "Redditch",
"441770", "Isle\ of\ Arran",
"441761", "Temple\ Cloud",
"4416860", "Newtown\/Llanidloes",
"441959", "Westerham",
"441566", "Launceston",
"441864", "Abington\ \(Crawford\)",
"4413390", "Aboyne\/Ballater",
"4414235", "Harrogate",
"441988", "Wigtown",
"441896", "Galashiels",
"441594", "Lydney",
"441809", "Tomdoun",
"4414234", "Boroughbridge",
"441547", "Knighton",
"441227", "Canterbury",
"441344", "Bracknell",
"441832", "Clopton",
"441397", "Fort\ William",
"441985", "Warminster",
"441634", "Medway",
"4413885", "Stanhope\ \(Eastgate\)",
"441465", "Girvan",
"441883", "Caterham",
"4418903", "Coldstream",
"44118", "Reading",
"441457", "Glossop",
"441687", "Mallaig",
"441473", "Ipswich",
"441604", "Northampton",
"4419757", "Strathdon",
"441840", "Camelford",
"4414304", "North\ Cave",
"441855", "Ballachulish",
"441675", "Coleshill",
"4414305", "North\ Cave",
"441663", "New\ Mills",
"441858", "Market\ Harborough",
"441678", "Bala",
"442837", "Armagh",
"441366", "Downham\ Market",
"442884", "Northern\ Ireland",
"441776", "Stranraer",
"441524", "Lancaster",
"441327", "Daventry",
"441244", "Chester",
"4418470", "Thurso\/Tongue",
"441297", "Axminster",
"441571", "Lochinver",
"441953", "Wymondham",
"441977", "Pontefract",
"441560", "Moscow",
"441302", "Doncaster",
"441582", "Luton",
"441258", "Blandford",
"442822", "Northern\ Ireland",
"441340", "Craigellachie\ \(Aberlour\)",
"4419759", "Alford\ \(Aberdeen\)",
"441456", "Glenurquhart",
"441630", "Market\ Drayton",
"441590", "Lymington",
"441255", "Clacton\-on\-Sea",
"441267", "Carmarthen",
"441383", "Dunfermline",
"441503", "Looe",
"441844", "Thame",
"441332", "Derby",
"441642", "Middlesbrough",
"441785", "Stafford",
"44241", "Coventry",
"441546", "Lochgilphead",
"441600", "Monmouth",
"441425", "Ringwood",
"441226", "Barnsley",
"4418473", "Thurso",
"441788", "Rugby",
"441309", "Forres",
"441428", "Haslemere",
"442829", "Kilrea",
"441827", "Tamworth",
"441623", "Mansfield",
"441495", "Pontypool",
"441753", "Slough",
"441777", "Retford",
"441326", "Falmouth",
"4414345", "Haltwhistle",
"441296", "Aylesbury",
"441209", "Redruth",
"4414344", "Bellingham",
"442899", "Northern\ Ireland",
"441202", "Bournemouth",
"442892", "Lisburn",
"4414376", "Haverfordwest",
"441431", "Helmsdale",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441358", "Ellon",
"441564", "Lapworth",
"441145", "Sheffield",
"441866", "Kilchrenan",
"4418900", "Coldstream\/Ayton",
"4419646", "Patrington",
"441355", "East\ Kilbride",
"441520", "Lochcarron",
"442880", "Carrickmore",
"441239", "Cardigan",
"441367", "Faringdon",
"441283", "Burton\-on\-Trent",
"441450", "Hawick",
"441346", "Fraserburgh",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441636", "Newark\-on\-Trent",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441389", "Dumbarton",
"441692", "North\ Walsham",
"441643", "Minehead",
"441509", "Loughborough",
"441708", "Romford",
"441540", "Kingussie",
"441606", "Northwich",
"441264", "Andover",
"4416863", "Llanidloes",
"441382", "Dundee",
"441502", "Lowestoft",
"441303", "Folkestone",
"441583", "Carradale",
"441539", "Kendal",
"442823", "Northern\ Ireland",
"4413393", "Aboyne",
"441738", "Perth",
"441759", "Pocklington",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441364", "Ashburton",
"441558", "Llandeilo",
"441282", "Burnley",
"441629", "Matlock",
"4419758", "Strathdon",
"442893", "Ballyclare",
"442842", "Kircubbin",
"4414346", "Hexham",
"441970", "Aberystwyth",
"441567", "Killin",
"441320", "Fort\ Augustus",
"441555", "Lanark",
"441290", "Cumnock",
"4419644", "Patrington",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441246", "Chesterfield",
"441721", "Peebles",
"441871", "Castlebay",
"441651", "Oldmeldrum",
"4419645", "Hornsea",
"4414374", "Clynderwen\ \(Clunderwen\)",
"442849", "Northern\ Ireland",
"441481", "Guernsey",
"441233", "Ashford\ \(Kent\)",
"441824", "Ruthin",
"441289", "Berwick\-upon\-Tweed",
"441622", "Maidstone",
"441752", "Plymouth",
"442886", "Cookstown",
"442830", "Newry",
"441445", "Gairloch",
"441526", "Martin",
"441704", "Southport",
"4418901", "Coldstream\/Ayton",
"441986", "Bungay",
"4412296", "Barrow\-in\-Furness",
"44114705", "Sheffield",
"441427", "Gainsborough",
"442311", "Southampton",
"441787", "Sudbury",
"441949", "Whatton",
"441895", "Uxbridge",
"4418908", "Coldstream",
"442870", "Coleraine",
"441942", "Wigan",
"441993", "Witney",
"441257", "Coppull",
"441900", "Workington",
"441273", "Brighton",
"441268", "Basildon",
"441466", "Huntly",
"441923", "Watford",
"441913", "Durham",
"441357", "Strathaven",
"441373", "Frome",
"4418472", "Thurso",
"441572", "Oakham",
"441368", "Dunbar",
"441554", "Llanelli",
"441676", "Meriden",
"441856", "Orkney",
"44114701", "Sheffield",
"441778", "Bourne",
"4413397", "Ballater",
"441579", "Liskeard",
"441828", "Coupar\ Angus",
"441444", "Haywards\ Heath",
"441775", "Spalding",
"4416867", "Llanidloes",
"441497", "Hay\-on\-Wye",
"44281", "Northern\ Ireland",
"441763", "Royston",
"441825", "Uckfield",
"4412294", "Barrow\-in\-Furness",
"441980", "Amesbury",
"44161", "Manchester",
"4412295", "Barrow\-in\-Furness",
"441737", "Redhill",
"441943", "Guiseley",
"441992", "Lea\ Valley",
"441254", "Blackburn",
"441424", "Hastings",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441279", "Bishops\ Stortford",
"441784", "Staines",
"441845", "Thirsk",
"441460", "Chard",
"441707", "Welwyn\ Garden\ City",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441848", "Thornhill",
"4418909", "Ayton",
"441379", "Diss",
"441494", "High\ Wycombe",
"4413392", "Aboyne",
"441929", "Wareham",
"441919", "Durham",
"441670", "Morpeth",
"4416862", "Llanidloes",
"441661", "Prudhoe",
"441573", "Kelso",
"441557", "Kirkcudbright",
"441144", "Sheffield",
"4418477", "Tongue",
"441565", "Knutsford",
"441951", "Colonsay",
"441922", "Walsall",
"441769", "South\ Molton",
"441912", "Tyneside",
"441354", "Chatteris",
"441568", "Leominster",
"441372", "Esher",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+44|\D)//g;
      my $self = bless({ country_code => '44', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '44', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;