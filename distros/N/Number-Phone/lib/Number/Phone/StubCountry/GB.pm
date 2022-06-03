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
our $VERSION = 1.20220601185318;

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
                    1[0-27-9]
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
                    1[0-27-9]
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
$areanames{en} = {"441572", "Oakham",
"4413399", "Ballater",
"441833", "Barnard\ Castle",
"441366", "Downham\ Market",
"441224", "Aberdeen",
"4414232", "Harrogate",
"441773", "Ripley",
"441842", "Thetford",
"441309", "Forres",
"441997", "Strathpeffer",
"441304", "Dover",
"441950", "Sandwick",
"441337", "Ladybank",
"441580", "Cranbrook",
"441670", "Morpeth",
"442843", "Newcastle\ \(Co\.\ Down\)",
"4418473", "Thurso",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441723", "Scarborough",
"441476", "Grantham",
"441677", "Bedale",
"441330", "Banchory",
"441957", "Mid\ Yell",
"441620", "North\ Berwick",
"442898", "Belfast",
"441268", "Basildon",
"441522", "Lincoln",
"441279", "Bishops\ Stortford",
"441408", "Golspie",
"441274", "Bradford",
"441502", "Lowestoft",
"441428", "Haslemere",
"4415073", "Louth",
"4418470", "Thurso\/Tongue",
"441379", "Diss",
"441368", "Dunbar",
"441600", "Monmouth",
"442889", "Fivemiletown",
"441639", "Neath",
"441329", "Fareham",
"4419646", "Patrington",
"441406", "Holbeach",
"4413397", "Ballater",
"441962", "Winchester",
"441634", "Medway",
"442884", "Northern\ Ireland",
"441324", "Falkirk",
"442896", "Belfast",
"441765", "Ripon",
"441209", "Redruth",
"441464", "Insch",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"44286", "Northern\ Ireland",
"441237", "Bideford",
"441204", "Bolton",
"441469", "Killingholme",
"441866", "Kilchrenan",
"4412295", "Barrow\-in\-Furness",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441623", "Mansfield",
"442847", "Northern\ Ireland",
"441993", "Witney",
"441777", "Retford",
"441720", "Isles\ of\ Scilly",
"441837", "Okehampton",
"441809", "Tomdoun",
"441342", "East\ Grinstead",
"4418515", "Stornoway",
"4419753", "Strathdon",
"44118", "Reading",
"44151", "Liverpool",
"441948", "Whitchurch",
"441931", "Shap",
"441830", "Kirkwhelpington",
"441782", "Stoke\-on\-Trent",
"441673", "Market\ Rasen",
"442840", "Banbridge",
"441953", "Wymondham",
"441583", "Carradale",
"441727", "St\ Albans",
"441985", "Warminster",
"441555", "Lanark",
"441770", "Isle\ of\ Arran",
"441544", "Kington",
"441291", "Chepstow",
"441707", "Welwyn\ Garden\ City",
"441549", "Lairg",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441435", "Heathfield",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"4416974", "Raughton\ Head",
"441665", "Alnwick",
"441874", "Brecon",
"441481", "Guernsey",
"441879", "Scarinish",
"44247", "Coventry",
"441824", "Ruthin",
"441233", "Ashford\ \(Kent\)",
"441829", "Tarporley",
"441603", "Norwich",
"4417687", "Keswick",
"4414342", "Bellingham",
"441946", "Whitehaven",
"441242", "Cheltenham",
"441700", "Rothesay",
"441797", "Rye",
"441888", "Turriff",
"441653", "Malton",
"441750", "Selkirk",
"441461", "Gretna",
"441575", "Kirriemuir",
"4413885", "Stanhope\ \(Eastgate\)",
"4415242", "Hornby",
"441685", "Merthyr\ Tydfil",
"441918", "Tyneside",
"441631", "Oban",
"442881", "Newtownstewart",
"4418907", "Ayton",
"441845", "Thirsk",
"441371", "Great\ Dunmow",
"4414236", "Harrogate",
"44238", "Southampton",
"441923", "Watford",
"441790", "Spilsby",
"441525", "Leighton\ Buzzard",
"441757", "Selby",
"441271", "Barnstaple",
"4412291", "Barrow\-in\-Furness\/Millom",
"441903", "Worthing",
"441505", "Johnstone",
"4412298", "Barrow\-in\-Furness",
"441646", "Milford\ Haven",
"441899", "Biggar",
"441916", "Tyneside",
"4419642", "Hornsea",
"4418518", "Stornoway",
"4418511", "Great\ Bernera\/Stornoway",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441301", "Arrochar",
"441854", "Ullapool",
"441563", "Kilmarnock",
"4418514", "Great\ Bernera",
"441859", "Harris",
"441440", "Haverhill",
"4412294", "Barrow\-in\-Furness",
"4418909", "Ayton",
"44116", "Leicester",
"441259", "Alloa",
"442828", "Larne",
"441388", "Bishop\ Auckland",
"441592", "Kirkcaldy",
"441254", "Blackburn",
"442310", "Portsmouth",
"441456", "Glenurquhart",
"441690", "Betws\-y\-Coed",
"441793", "Swindon",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441977", "Pontefract",
"441821", "Kinrossie",
"441920", "Ware",
"441697", "Brampton",
"441489", "Bishops\ Waltham",
"441753", "Slough",
"44291", "Cardiff",
"441484", "Huddersfield",
"441650", "Cemmaes\ Road",
"4414300", "North\ Cave\/Market\ Weighton",
"441785", "Stafford",
"441496", "Port\ Ellen",
"441871", "Castlebay",
"441970", "Aberystwyth",
"441286", "Caernarfon",
"441294", "Ardrossan",
"441748", "Richmond",
"441982", "Builth\ Wells",
"4416869", "Newtown",
"441538", "Ipstones",
"441299", "Bewdley",
"441432", "Hereford",
"441560", "Moscow",
"4414373", "Clynderwen\ \(Clunderwen\)",
"4414346", "Hexham",
"441458", "Glastonbury",
"441394", "Felixstowe",
"4416867", "Llanidloes",
"441939", "Wem",
"441386", "Evesham",
"442826", "Northern\ Ireland",
"441934", "Weston\-super\-Mare",
"441443", "Pontypridd",
"441536", "Kettering",
"441359", "Pakenham",
"441746", "Bridgnorth",
"441354", "Chatteris",
"441900", "Workington",
"441288", "Bude",
"441567", "Killin",
"441245", "Chelmsford",
"4414303", "North\ Cave",
"441400", "Honington",
"441260", "Congleton",
"442890", "Belfast",
"4416860", "Newtown\/Llanidloes",
"441628", "Maidenhead",
"441341", "Barmouth",
"441825", "Uckfield",
"4414309", "Market\ Weighton",
"441352", "Mold",
"441669", "Rothbury",
"441392", "Exeter",
"441588", "Bishops\ Castle",
"441678", "Bala",
"441932", "Weybridge",
"441664", "Melton\ Mowbray",
"441875", "Tranent",
"441236", "Coatbridge",
"4414379", "Haverfordwest",
"441943", "Guiseley",
"441407", "Holyhead",
"441606", "Northwich",
"441545", "Llanarth",
"44283", "Northern\ Ireland",
"441439", "Helmsley",
"442897", "Saintfield",
"441267", "Carmarthen",
"4414377", "Haverfordwest",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441292", "Ayr",
"44241", "Coventry",
"441427", "Gainsborough",
"441984", "Watchet\ \(Williton\)",
"441554", "Llanelli",
"441863", "Ardgay",
"441626", "Newton\ Abbot",
"441989", "Ross\-on\-Wye",
"441559", "Llandysul",
"441367", "Faringdon",
"4414235", "Harrogate",
"4416863", "Llanidloes",
"441482", "Kingston\-upon\-Hull",
"441608", "Chipping\ Norton",
"441805", "Torrington",
"441360", "Killearn",
"441241", "Arbroath",
"441599", "Kyle",
"441420", "Alton",
"4414307", "Market\ Weighton",
"441477", "Holmes\ Chapel",
"441594", "Lydney",
"441252", "Aldershot",
"441676", "Meriden",
"441586", "Campbeltown",
"441769", "South\ Molton",
"441205", "Boston",
"441778", "Bourne",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"442848", "Northern\ Ireland",
"441764", "Crieff",
"441571", "Lochinver",
"441465", "Girvan",
"441325", "Darlington",
"442885", "Ballygawley",
"441635", "Newbury",
"4418903", "Coldstream",
"441852", "Kilmelford",
"441706", "Rochdale",
"441841", "Newquay\ \(Padstow\)",
"441838", "Dalmally",
"441375", "Grays\ Thurrock",
"442893", "Ballyclare",
"441263", "Cromer",
"441892", "Tunbridge\ Wells",
"441947", "Whitby",
"441403", "Horsham",
"4414345", "Haltwhistle",
"441728", "Saxmundham",
"4418900", "Coldstream\/Ayton",
"441363", "Crediton",
"441708", "Romford",
"441275", "Clevedon",
"4412292", "Barrow\-in\-Furness",
"441501", "Harthill",
"4419648", "Hornsea",
"442846", "Northern\ Ireland",
"4418512", "Stornoway",
"441776", "Stranraer",
"4419641", "Hornsea\/Patrington",
"441305", "Dorchester",
"4419644", "Patrington",
"441726", "St\ Austell",
"441473", "Ipswich",
"441225", "Bath",
"441917", "Sunderland",
"44292", "Cardiff",
"441591", "Llanwrtyd\ Wells",
"441249", "Chippenham",
"441798", "Pulborough",
"441887", "Aberfeldy",
"441244", "Chester",
"44131", "Edinburgh",
"441822", "Tavistock",
"441446", "Barry",
"4419757", "Strathdon",
"441355", "East\ Kilbride",
"441647", "Moretonhampstead",
"442823", "Northern\ Ireland",
"4419645", "Hornsea",
"441383", "Dunfermline",
"441743", "Shrewsbury",
"441872", "Truro",
"441935", "Yeovil",
"441395", "Budleigh\ Salterton",
"441542", "Keith",
"441758", "Pwllheli",
"441910", "Tyneside\/Durham\/Sunderland",
"441880", "Tarbert",
"441732", "Sevenoaks",
"441981", "Wormbridge",
"44113", "Leeds",
"4414344", "Bellingham",
"4413882", "Stanhope\ \(Eastgate\)",
"441431", "Helmsdale",
"441295", "Banbury",
"441485", "Hunstanton",
"441796", "Pitlochry",
"441784", "Staines",
"441661", "Prudhoe",
"441453", "Dursley",
"441789", "Stratford\-upon\-Avon",
"441349", "Dingwall",
"441493", "Great\ Yarmouth",
"44121", "Birmingham",
"441344", "Bracknell",
"441756", "Skipton",
"441255", "Clacton\-on\-Sea",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"4414348", "Hexham",
"4417683", "Appleby",
"441283", "Burton\-on\-Trent",
"4419759", "Alford\ \(Aberdeen\)",
"441643", "Minehead",
"442870", "Coleraine",
"441462", "Hitchin",
"441530", "Coalville",
"442827", "Ballymoney",
"441387", "Dumfries",
"441202", "Bournemouth",
"441740", "Sedgefield",
"4414238", "Harrogate",
"441969", "Leyburn",
"4418477", "Tongue",
"441978", "Wrexham",
"441883", "Caterham",
"441322", "Dartford",
"442882", "Omagh",
"4414231", "Harrogate\/Boroughbridge",
"441913", "Durham",
"441855", "Ballachulish",
"441566", "Launceston",
"441895", "Uxbridge",
"441928", "Runcorn",
"4415079", "Alford\ \(Lincs\)",
"441372", "Esher",
"4414234", "Boroughbridge",
"441698", "Motherwell",
"441380", "Devizes",
"442820", "Ballycastle",
"442877", "Limavady",
"441509", "Loughborough",
"441747", "Shaftesbury",
"4413390", "Aboyne\/Ballater",
"441457", "Glossop",
"441524", "Lancaster",
"4415077", "Louth",
"441529", "Sleaford",
"441490", "Corwen",
"441656", "Bridgend",
"441280", "Buckingham",
"441908", "Milton\ Keynes",
"4418516", "Great\ Bernera",
"441844", "Thame",
"441287", "Guisborough",
"441302", "Doncaster",
"4413393", "Aboyne",
"441450", "Hawick",
"441684", "Malvern",
"441761", "Temple\ Cloud",
"441926", "Warwick",
"441579", "Liskeard",
"4418479", "Tongue",
"4412296", "Barrow\-in\-Furness",
"441568", "Leominster",
"441497", "Hay\-on\-Wye",
"441689", "Orpington",
"441729", "Settle",
"441724", "Scunthorpe",
"441425", "Ringwood",
"441273", "Brighton",
"441834", "Narberth",
"441807", "Ballindalloch",
"441223", "Cambridge",
"4413395", "Aboyne",
"4419756", "Strathdon",
"441303", "Folkestone",
"441779", "Peterhead",
"441768", "Penrith",
"442844", "Downpatrick",
"441561", "Laurencekirk",
"441475", "Greenock",
"4419467", "Gosforth",
"442849", "Northern\ Ireland",
"441633", "Newport",
"442883", "Northern\ Ireland",
"441323", "Eastbourne",
"441912", "Tyneside",
"441540", "Kingussie",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441730", "Petersfield",
"441882", "Kinloch\ Rannoch",
"441651", "Oldmeldrum",
"44281", "Northern\ Ireland",
"4416861", "Newtown\/Llanidloes",
"441827", "Tamworth",
"441971", "Scourie",
"441870", "Isle\ of\ Benbecula",
"4416868", "Newtown",
"441642", "Middlesbrough",
"441463", "Inverness",
"441877", "Callander",
"4416864", "Llanidloes",
"442311", "Southampton",
"441766", "Porthmadog",
"441691", "Oswestry",
"441709", "Rotherham",
"441547", "Knighton",
"441373", "Frome",
"442895", "Belfast",
"441737", "Redhill",
"441704", "Southport",
"441405", "Goole",
"4414302", "North\ Cave",
"441452", "Gloucester",
"4419640", "Hornsea\/Patrington",
"441438", "Stevenage",
"441277", "Brentwood",
"4418908", "Coldstream",
"441959", "Westerham",
"441668", "Bamburgh",
"4418901", "Coldstream\/Ayton",
"441865", "Oxford",
"441674", "Montrose",
"441300", "Cerne\ Abbas",
"441954", "Madingley",
"441584", "Ludlow",
"441994", "St\ Clears",
"441629", "Matlock",
"441282", "Burnley",
"441986", "Bungay",
"441556", "Castle\ Douglas",
"4418476", "Tongue",
"441624", "Isle\ of\ Man",
"441307", "Forfar",
"441334", "St\ Andrews",
"4418904", "Coldstream",
"4412299", "Millom",
"4418519", "Great\ Bernera",
"441803", "Torquay",
"441270", "Crewe",
"441492", "Colwyn\ Bay",
"441227", "Canterbury",
"4412297", "Millom",
"442822", "Northern\ Ireland",
"441382", "Dundee",
"441598", "Lynton",
"441467", "Inverurie",
"441239", "Cardigan",
"441823", "Taunton",
"441666", "Malmesbury",
"4413873", "Langholm",
"441207", "Consett",
"441234", "Bedford",
"441609", "Northallerton",
"441436", "Helensburgh",
"4419643", "Patrington",
"441327", "Daventry",
"442887", "Dungannon",
"441637", "Newquay",
"441604", "Northampton",
"4418517", "Stornoway",
"441733", "Peterborough",
"441945", "Wisbech",
"441543", "Cannock",
"441377", "Driffield",
"442880", "Carrickmore",
"441320", "Fort\ Augustus",
"441630", "Market\ Drayton",
"4415396", "Sedbergh",
"441460", "Chard",
"441751", "Pickering",
"441200", "Clitheroe",
"441873", "Abergavenny",
"441988", "Wigtown",
"4415076", "Louth",
"441558", "Llandeilo",
"44114", "Sheffield",
"441422", "Halifax",
"442867", "Lisnaskea",
"441297", "Axminster",
"441250", "Blairgowrie",
"441508", "Brooke",
"441576", "Lockerbie",
"441929", "Wareham",
"441694", "Church\ Stretton",
"441924", "Wakefield",
"441487", "Warboys",
"441362", "Dereham",
"4419752", "Alford\ \(Aberdeen\)",
"441526", "Martin",
"441968", "Penicuik",
"441659", "Sanquhar",
"441974", "Llanon",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441480", "Huntingdon",
"441654", "Machynlleth",
"441290", "Cumnock",
"441472", "Grimsby",
"441257", "Coppull",
"441564", "Lapworth",
"441885", "Pencombe",
"441771", "Maud",
"4417684", "Pooley\ Bridge",
"4414306", "Market\ Weighton",
"442841", "Rostrevor",
"442838", "Portadown",
"441915", "Sunderland",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441569", "Stonehaven",
"441578", "Lauder",
"441506", "Bathgate",
"4418905", "Ayton",
"441848", "Thornhill",
"441357", "Strathaven",
"441909", "Worksop",
"441397", "Fort\ William",
"441937", "Wetherby",
"441904", "York",
"441350", "Dunkeld",
"441721", "Peebles",
"4414343", "Haltwhistle",
"441262", "Bridlington",
"442892", "Lisburn",
"4414376", "Haverfordwest",
"441528", "Laggan",
"441483", "Guildford",
"441759", "Pocklington",
"441455", "Hinckley",
"441346", "Fraserburgh",
"441754", "Skegness",
"441862", "Tain",
"44141", "Glasgow",
"4416865", "Newtown",
"4414233", "Boroughbridge",
"441293", "Crawley",
"4418472", "Thurso",
"441253", "Blackpool",
"441285", "Cirencester",
"441794", "Romsey",
"441248", "Bangor\ \(Gwynedd\)",
"441495", "Pontypool",
"441786", "Stirling",
"441799", "Saffron\ Walden",
"4414230", "Harrogate\/Boroughbridge",
"441353", "Ely",
"4415072", "Spilsby\ \(Horncastle\)",
"442825", "Ballymena",
"4413394", "Ballater",
"441857", "Sanday",
"441348", "Fishguard",
"441621", "Maldon",
"441951", "Colonsay",
"441581", "New\ Luce",
"441671", "Newton\ Stewart",
"4413391", "Aboyne\/Ballater",
"441942", "Wigan",
"441788", "Rugby",
"4413398", "Aboyne",
"441246", "Chesterfield",
"441933", "Wellingborough",
"441745", "Rhyl",
"441444", "Haywards\ Heath",
"441535", "Keighley",
"441449", "Stowmarket",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441663", "New\ Mills",
"441442", "Hemel\ Hempstead",
"441451", "Stow\-on\-the\-Wold",
"441760", "Swaffham",
"441949", "Whatton",
"4418471", "Thurso\/Tongue",
"441944", "West\ Heslerton",
"4414237", "Harrogate",
"441433", "Hathersage",
"4418478", "Thurso",
"441546", "Lochgilphead",
"4418474", "Thurso",
"4418906", "Ayton",
"441736", "Penzance",
"441808", "Tomatin",
"441491", "Henley\-on\-Thames",
"441876", "Lochmaddy",
"4414305", "North\ Cave",
"441235", "Abingdon",
"441767", "Sandy",
"441792", "Swansea",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441381", "Fortrose",
"442821", "Martinstown",
"4415078", "Alford\ \(Lincs\)",
"441625", "Macclesfield",
"441593", "Lybster",
"441335", "Ashbourne",
"441995", "Garstang",
"441828", "Coupar\ Angus",
"441675", "Coleshill",
"441864", "Abington\ \(Crawford\)",
"441955", "Wick",
"441869", "Bicester",
"4413392", "Aboyne",
"441878", "Lochboisdale",
"441983", "Isle\ of\ Wight",
"441553", "Kings\ Lynn",
"4415074", "Alford\ \(Lincs\)",
"441806", "Shetland",
"441738", "Perth",
"4414239", "Boroughbridge",
"44115", "Nottingham",
"442871", "Londonderry",
"4415394", "Hawkshead",
"441531", "Ledbury",
"441548", "Kingsbridge",
"441752", "Plymouth",
"441278", "Bridgwater",
"442899", "Northern\ Ireland",
"441269", "Ammanford",
"441404", "Honiton",
"44280", "Northern\ Ireland",
"441326", "Falmouth",
"442886", "Cookstown",
"441636", "Newark\-on\-Trent",
"441264", "Andover",
"442894", "Antrim",
"441409", "Holsworthy",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441466", "Huntly",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441667", "Nairn",
"441902", "Wolverhampton",
"4414349", "Bellingham",
"441206", "Colchester",
"4419758", "Strathdon",
"441763", "Royston",
"4419754", "Alford\ \(Aberdeen\)",
"441308", "Bridport",
"441228", "Carlisle",
"441562", "Kidderminster",
"441376", "Braintree",
"441980", "Amesbury",
"441550", "Llandovery",
"441775", "Spalding",
"441208", "Bodmin",
"441474", "Gravesend",
"441597", "Llandrindod\ Wells",
"44287", "Northern\ Ireland",
"441479", "Grantown\-on\-Spey",
"442845", "Northern\ Ireland",
"441911", "Tyneside\/Durham\/Sunderland",
"442888", "Northern\ Ireland",
"441638", "Newmarket",
"441641", "Strathy",
"441328", "Fakenham",
"441972", "Glenborrodale",
"441835", "St\ Boswells",
"441652", "Brigg",
"441276", "Camberley",
"441369", "Dunoon",
"441692", "North\ Walsham",
"441922", "Walsall",
"441364", "Ashburton",
"4416973", "Wigton",
"441226", "Barnsley",
"4416866", "Newtown",
"4414347", "Hexham",
"441725", "Rockbourne",
"441557", "Kirkcudbright",
"441424", "Hastings",
"4420", "London",
"441987", "Ebbsfleet",
"441306", "Dorking",
"441429", "Hartlepool",
"441590", "Lymington",
"441534", "Jersey",
"441749", "Shepton\ Mallet",
"4418510", "Great\ Bernera\/Stornoway",
"441298", "Buxton",
"442868", "Kesh",
"441744", "St\ Helens",
"441539", "Kendal",
"441356", "Brechin",
"441445", "Gairloch",
"442879", "Magherafelt",
"4418902", "Coldstream",
"441488", "Hungerford",
"4412290", "Barrow\-in\-Furness\/Millom",
"441243", "Chichester",
"441967", "Strontian",
"4419649", "Hornsea",
"441384", "Dudley",
"442824", "Northern\ Ireland",
"441258", "Blandford",
"442829", "Kilrea",
"441389", "Dumbarton",
"441577", "Kinross",
"441343", "Elgin",
"442837", "Armagh",
"441687", "Mallaig",
"441520", "Lochcarron",
"441499", "Inveraray",
"4412293", "Millom",
"441795", "Sittingbourne",
"441494", "High\ Wycombe",
"441358", "Ellon",
"441992", "Lea\ Valley",
"441284", "Bury\ St\ Edmunds",
"442866", "Enniskillen",
"441296", "Aylesbury",
"4418513", "Stornoway",
"4419755", "Alford\ \(Aberdeen\)",
"441289", "Berwick\-upon\-Tweed",
"441332", "Derby",
"441622", "Maidstone",
"4413396", "Ballater",
"4419647", "Patrington",
"441938", "Welshpool",
"441840", "Camelford",
"441672", "Marlborough",
"441256", "Basingstoke",
"441952", "Telford",
"441398", "Dulverton",
"441582", "Luton",
"441527", "Redditch",
"442830", "Newry",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441454", "Chipping\ Sodbury",
"441570", "Lampeter",
"4415075", "Spilsby\ \(Horncastle\)",
"441856", "Orkney",
"441702", "Southend\-on\-Sea",
"4415395", "Grange\-over\-Sands",
"441905", "Worcester",
"441361", "Duns",
"441503", "Looe",
"441644", "New\ Galloway",
"441963", "Wincanton",
"441914", "Tyneside",
"441889", "Rugeley",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441896", "Galashiels",
"441919", "Durham",
"441565", "Knutsford",
"441884", "Tiverton",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"4414304", "North\ Cave",
"442842", "Kircubbin",
"441772", "Preston",
"44239", "Portsmouth",
"441843", "Thanet",
"4414378", "Haverfordwest",
"44117", "Bristol",
"44161", "Manchester",
"441832", "Clopton",
"441780", "Stamford",
"4418475", "Thurso",
"441655", "Maybole",
"4416862", "Llanidloes",
"441573", "Kelso",
"441347", "Easingwold",
"441858", "Market\ Harborough",
"441683", "Moffat",
"441925", "Warrington",
"441787", "Sudbury",
"441695", "Skelmersdale",
"441340", "Craigellachie\ \(Aberlour\)",
"441261", "Banff",
"442891", "Bangor\ \(Co\.\ Down\)",
"4414301", "North\ Cave\/Market\ Weighton",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441722", "Salisbury",
"4414308", "Market\ Weighton",};

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