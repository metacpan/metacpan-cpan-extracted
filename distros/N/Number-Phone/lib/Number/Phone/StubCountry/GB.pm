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
our $VERSION = 1.20230305170052;

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
                  70[0-579]
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
                    1[0-246-9]
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
                  70[0-579]
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
                    1[0-246-9]
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
$areanames{en} = {"441335", "Ashbourne",
"442823", "Northern\ Ireland",
"441452", "Gloucester",
"4418519", "Great\ Bernera",
"441665", "Alnwick",
"44131", "Edinburgh",
"4419754", "Alford\ \(Aberdeen\)",
"441282", "Burnley",
"441505", "Johnstone",
"441809", "Tomdoun",
"441299", "Bewdley",
"4419648", "Hornsea",
"441634", "Medway",
"442879", "Magherafelt",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441407", "Holyhead",
"441787", "Sudbury",
"441793", "Swindon",
"441364", "Ashburton",
"441554", "Llanelli",
"441935", "Yeovil",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441929", "Wareham",
"441420", "Alton",
"441885", "Pencombe",
"441592", "Kirkcaldy",
"441730", "Petersfield",
"441260", "Congleton",
"441373", "Frome",
"4412297", "Millom",
"4416861", "Newtown\/Llanidloes",
"4416973", "Wigton",
"441761", "Temple\ Cloud",
"441286", "Caernarfon",
"441913", "Durham",
"441408", "Golspie",
"441788", "Rugby",
"441844", "Thame",
"441746", "Bridgnorth",
"441456", "Glenurquhart",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441543", "Cannock",
"441248", "Bangor\ \(Gwynedd\)",
"441329", "Fareham",
"441623", "Mansfield",
"44117", "Bristol",
"441494", "High\ Wycombe",
"441670", "Morpeth",
"441269", "Ammanford",
"441621", "Maldon",
"441308", "Bridport",
"4414236", "Harrogate",
"441827", "Tamworth",
"441538", "Ipstones",
"441356", "Brechin",
"441233", "Ashford\ \(Kent\)",
"4412294", "Barrow\-in\-Furness",
"441566", "Launceston",
"4413391", "Aboyne\/Ballater",
"441763", "Royston",
"441920", "Ware",
"441394", "Felixstowe",
"441911", "Tyneside\/Durham\/Sunderland",
"441872", "Truro",
"441606", "Northwich",
"441971", "Scourie",
"4414345", "Haltwhistle",
"441429", "Hartlepool",
"441320", "Fort\ Augustus",
"441994", "St\ Clears",
"441371", "Great\ Dunmow",
"441580", "Cranbrook",
"4414301", "North\ Cave\/Market\ Weighton",
"441908", "Milton\ Keynes",
"441695", "Skelmersdale",
"441473", "Ipswich",
"442895", "Belfast",
"441224", "Aberdeen",
"4415073", "Louth",
"441275", "Clevedon",
"4414235", "Harrogate",
"441952", "Telford",
"441307", "Forfar",
"441828", "Coupar\ Angus",
"4419649", "Hornsea",
"441464", "Insch",
"4414346", "Hexham",
"441435", "Heathfield",
"441876", "Lochmaddy",
"441352", "Mold",
"4419757", "Strathdon",
"441562", "Kidderminster",
"442821", "Martinstown",
"4418518", "Stornoway",
"442870", "Coleraine",
"441725", "Rockbourne",
"44141", "Glasgow",
"441290", "Cumnock",
"442844", "Downpatrick",
"441903", "Worthing",
"441865", "Oxford",
"441450", "Hawick",
"441959", "Westerham",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441740", "Sedgefield",
"441280", "Buckingham",
"4416974", "Raughton\ Head",
"442885", "Ballygawley",
"441736", "Penzance",
"441768", "Penrith",
"4419640", "Hornsea\/Patrington",
"4415396", "Sedbergh",
"441653", "Malton",
"441834", "Narberth",
"441359", "Pakenham",
"441569", "Stonehaven",
"441241", "Arbroath",
"441609", "Northallerton",
"441303", "Folkestone",
"4418471", "Thurso\/Tongue",
"441422", "Halifax",
"441879", "Scarinish",
"44291", "Cardiff",
"441984", "Watchet\ \(Williton\)",
"441590", "Lymington",
"441685", "Merthyr\ Tydfil",
"441732", "Sevenoaks",
"441477", "Holmes\ Chapel",
"4419753", "Strathdon",
"441262", "Bridlington",
"441945", "Wisbech",
"441823", "Taunton",
"4415395", "Grange\-over\-Sands",
"441524", "Lancaster",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441644", "New\ Galloway",
"441767", "Sandy",
"441237", "Bideford",
"441575", "Kirriemuir",
"4415077", "Louth",
"441384", "Dudley",
"441296", "Aylesbury",
"4414377", "Haverfordwest",
"441806", "Shetland",
"441672", "Marlborough",
"441798", "Pulborough",
"4414232", "Harrogate",
"441917", "Sunderland",
"441977", "Pontefract",
"441254", "Blackburn",
"4415074", "Alford\ \(Lincs\)",
"441599", "Kyle",
"441547", "Knighton",
"44241", "Coventry",
"441870", "Isle\ of\ Benbecula",
"44247", "Coventry",
"441704", "Southport",
"441484", "Huddersfield",
"441858", "Market\ Harborough",
"441821", "Kinrossie",
"441922", "Walsall",
"441322", "Dartford",
"441582", "Luton",
"441205", "Boston",
"441895", "Uxbridge",
"441377", "Driffield",
"442828", "Larne",
"441445", "Gairloch",
"441289", "Berwick\-upon\-Tweed",
"441301", "Arrochar",
"441857", "Sanday",
"441628", "Maidenhead",
"441651", "Oldmeldrum",
"442311", "Southampton",
"441243", "Chichester",
"441548", "Kingsbridge",
"441918", "Tyneside",
"441586", "Campbeltown",
"441797", "Rye",
"441978", "Wrexham",
"441950", "Sandwick",
"441749", "Shepton\ Mallet",
"4412293", "Millom",
"441403", "Horsham",
"4420", "London",
"4414342", "Bellingham",
"441531", "Ledbury",
"441326", "Falmouth",
"441600", "Monmouth",
"4418901", "Coldstream\/Ayton",
"442827", "Ballymoney",
"441926", "Warwick",
"441350", "Dunkeld",
"441560", "Moscow",
"441292", "Ayr",
"4418510", "Great\ Bernera\/Stornoway",
"441676", "Meriden",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"44113", "Leeds",
"4414306", "Market\ Weighton",
"441969", "Leyburn",
"441855", "Ballachulish",
"44286", "Northern\ Ireland",
"441460", "Chard",
"441271", "Barnstaple",
"4412299", "Millom",
"441795", "Sittingbourne",
"441933", "Wellingborough",
"442891", "Bangor\ \(Co\.\ Down\)",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441256", "Basingstoke",
"441639", "Neath",
"441721", "Peebles",
"441294", "Ardrossan",
"441758", "Pwllheli",
"441770", "Isle\ of\ Arran",
"442825", "Ballymena",
"4414231", "Harrogate\/Boroughbridge",
"441369", "Dunoon",
"4417683", "Appleby",
"441706", "Rochdale",
"441559", "Llandysul",
"4413396", "Ballater",
"441663", "New\ Mills",
"441503", "Looe",
"441208", "Bodmin",
"441431", "Helmsdale",
"441915", "Sunderland",
"4418902", "Coldstream",
"441482", "Kingston\-upon\-Hull",
"4414305", "North\ Cave",
"441702", "Southend\-on\-Sea",
"441924", "Wakefield",
"441674", "Montrose",
"441625", "Macclesfield",
"441252", "Aldershot",
"4419644", "Patrington",
"441545", "Llanarth",
"4419758", "Strathdon",
"441207", "Consett",
"441691", "Oswestry",
"441883", "Caterham",
"441499", "Inveraray",
"441757", "Selby",
"441324", "Falkirk",
"4413395", "Aboyne",
"4418517", "Stornoway",
"441584", "Ludlow",
"441375", "Grays\ Thurrock",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"4416865", "Newtown",
"442830", "Newry",
"4418514", "Great\ Bernera",
"441264", "Andover",
"441347", "Easingwold",
"441424", "Hastings",
"4413885", "Stanhope\ \(Eastgate\)",
"441982", "Builth\ Wells",
"441687", "Mallaig",
"4418472", "Thurso",
"4419759", "Alford\ \(Aberdeen\)",
"441475", "Greenock",
"441522", "Lincoln",
"44121", "Birmingham",
"441642", "Middlesbrough",
"441947", "Whitby",
"441490", "Corwen",
"442846", "Northern\ Ireland",
"4419647", "Patrington",
"441382", "Dundee",
"441577", "Kinross",
"441235", "Abingdon",
"442888", "Northern\ Ireland",
"441840", "Camelford",
"441765", "Ripon",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441501", "Harthill",
"441433", "Hathersage",
"4416866", "Newtown",
"441348", "Fishguard",
"441661", "Prudhoe",
"441723", "Scarborough",
"442842", "Kircubbin",
"441469", "Killingholme",
"441386", "Evesham",
"441526", "Martin",
"441646", "Milford\ Haven",
"441931", "Shap",
"441832", "Clopton",
"442893", "Ballyclare",
"441360", "Killearn",
"4412298", "Barrow\-in\-Furness",
"441550", "Llandovery",
"442887", "Dungannon",
"441273", "Brighton",
"441578", "Lauder",
"441986", "Bungay",
"441948", "Whitchurch",
"441779", "Peterhead",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441630", "Market\ Drayton",
"441277", "Brentwood",
"441954", "Madingley",
"441535", "Keighley",
"442883", "Northern\ Ireland",
"4418905", "Ayton",
"4414302", "North\ Cave",
"442897", "Saintfield",
"4414378", "Haverfordwest",
"441462", "Hitchin",
"4415079", "Alford\ \(Lincs\)",
"442849", "Northern\ Ireland",
"44151", "Liverpool",
"441655", "Maybole",
"441305", "Dorchester",
"4419643", "Patrington",
"441905", "Worcester",
"441698", "Motherwell",
"441772", "Preston",
"441863", "Ardgay",
"4413392", "Aboyne",
"441604", "Northampton",
"441354", "Chatteris",
"441564", "Lapworth",
"441727", "St\ Albans",
"441825", "Uckfield",
"4418906", "Ayton",
"441943", "Guiseley",
"441392", "Exeter",
"441989", "Ross\-on\-Wye",
"441874", "Brecon",
"441480", "Huntingdon",
"441700", "Rothesay",
"441776", "Stranraer",
"442898", "Belfast",
"441573", "Kelso",
"441278", "Bridgwater",
"44114", "Sheffield",
"441250", "Blairgowrie",
"441728", "Saxmundham",
"441751", "Pickering",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441226", "Barnsley",
"441466", "Huntly",
"441992", "Lea\ Valley",
"441438", "Stevenage",
"441389", "Dumbarton",
"441683", "Moffat",
"4417684", "Pooley\ Bridge",
"441343", "Elgin",
"441529", "Sleaford",
"441697", "Brampton",
"441636", "Newark\-on\-Trent",
"441668", "Bamburgh",
"441887", "Aberfeldy",
"441341", "Barmouth",
"441259", "Alloa",
"4417687", "Keswick",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441508", "Brooke",
"441980", "Amesbury",
"441366", "Downham\ Market",
"441556", "Castle\ Douglas",
"441709", "Rotherham",
"441489", "Bishops\ Waltham",
"441443", "Pontypridd",
"4418476", "Tongue",
"441594", "Lydney",
"441753", "Slough",
"441571", "Lochinver",
"441520", "Lochcarron",
"441380", "Devizes",
"442867", "Lisnaskea",
"441492", "Colwyn\ Bay",
"441938", "Welshpool",
"441842", "Thetford",
"4416862", "Llanidloes",
"441284", "Bury\ St\ Edmunds",
"4418513", "Stornoway",
"441337", "Ladybank",
"4413882", "Stanhope\ \(Eastgate\)",
"441962", "Winchester",
"442840", "Banbridge",
"441496", "Port\ Ellen",
"4418475", "Thurso",
"441888", "Turriff",
"441667", "Nairn",
"441744", "St\ Helens",
"441454", "Chipping\ Sodbury",
"4412290", "Barrow\-in\-Furness\/Millom",
"441830", "Kirkwhelpington",
"441245", "Chelmsford",
"441362", "Dereham",
"4415078", "Alford\ \(Lincs\)",
"441937", "Wetherby",
"4414379", "Haverfordwest",
"442868", "Kesh",
"442881", "Newtownstewart",
"441405", "Goole",
"441785", "Stafford",
"441472", "Grimsby",
"441829", "Tarporley",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441737", "Redhill",
"44292", "Cardiff",
"441985", "Warminster",
"441267", "Carmarthen",
"441591", "Llanwrtyd\ Wells",
"441427", "Gainsborough",
"441344", "Bracknell",
"441684", "Malvern",
"441873", "Abergavenny",
"441944", "West\ Heslerton",
"441525", "Leighton\ Buzzard",
"4418477", "Tongue",
"441539", "Kendal",
"441864", "Abington\ \(Crawford\)",
"442845", "Northern\ Ireland",
"441428", "Haslemere",
"441451", "Stow\-on\-the\-Wold",
"441268", "Basildon",
"441563", "Kilmarnock",
"441353", "Ely",
"441236", "Coatbridge",
"441659", "Sanquhar",
"441766", "Porthmadog",
"441738", "Perth",
"441309", "Forres",
"4413393", "Aboyne",
"441603", "Norwich",
"441909", "Worksop",
"4414303", "North\ Cave",
"441400", "Honington",
"44280", "Northern\ Ireland",
"441780", "Stamford",
"442884", "Northern\ Ireland",
"441953", "Wymondham",
"4418904", "Coldstream",
"44115", "Nottingham",
"4419642", "Hornsea",
"441476", "Grantham",
"441835", "St\ Boswells",
"441300", "Cerne\ Abbas",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441792", "Swansea",
"441678", "Bala",
"442310", "Portsmouth",
"441650", "Cemmaes\ Road",
"441928", "Runcorn",
"441951", "Colonsay",
"441852", "Kilmelford",
"441530", "Coalville",
"4418907", "Ayton",
"441376", "Braintree",
"4418512", "Stornoway",
"441916", "Tyneside",
"441588", "Bishops\ Castle",
"441283", "Burton\-on\-Trent",
"442877", "Limavady",
"441249", "Chippenham",
"4416863", "Llanidloes",
"441561", "Laurencekirk",
"441328", "Fakenham",
"441807", "Ballindalloch",
"441297", "Axminster",
"441743", "Shrewsbury",
"4418474", "Thurso",
"442822", "Northern\ Ireland",
"441453", "Dursley",
"441546", "Lochgilphead",
"441900", "Workington",
"441409", "Holsworthy",
"441789", "Stratford\-upon\-Avon",
"441626", "Newton\ Abbot",
"441542", "Keith",
"441255", "Clacton\-on\-Sea",
"441622", "Maidstone",
"442826", "Northern\ Ireland",
"441677", "Bedale",
"4414230", "Harrogate\/Boroughbridge",
"441485", "Hunstanton",
"441871", "Castlebay",
"441972", "Glenborrodale",
"441912", "Tyneside",
"441372", "Esher",
"441204", "Bolton",
"4413873", "Langholm",
"441856", "Orkney",
"441327", "Daventry",
"441808", "Tomatin",
"441444", "Haywards\ Heath",
"441754", "Skegness",
"441298", "Buxton",
"441593", "Lybster",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441796", "Pitlochry",
"4415242", "Hornby",
"441458", "Glastonbury",
"441919", "Durham",
"441748", "Richmond",
"44287", "Northern\ Ireland",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441884", "Tiverton",
"44281", "Northern\ Ireland",
"441246", "Chesterfield",
"441288", "Bude",
"441583", "Carradale",
"441406", "Holbeach",
"441786", "Stirling",
"441629", "Matlock",
"441597", "Llandrindod\ Wells",
"441549", "Lairg",
"4413394", "Ballater",
"441323", "Eastbourne",
"441261", "Banff",
"4412291", "Barrow\-in\-Furness\/Millom",
"4416867", "Llanidloes",
"4414304", "North\ Cave",
"441845", "Thirsk",
"441923", "Watford",
"441760", "Swaffham",
"4414239", "Boroughbridge",
"4418903", "Coldstream",
"4419467", "Gosforth",
"441495", "Pontypool",
"4419645", "Hornsea",
"441379", "Diss",
"441673", "Market\ Rasen",
"441598", "Lynton",
"441293", "Crawley",
"441803", "Torquay",
"441334", "St\ Andrews",
"441287", "Guisborough",
"441859", "Harris",
"441799", "Saffron\ Walden",
"441457", "Glossop",
"441747", "Shaftesbury",
"441664", "Melton\ Mowbray",
"441782", "Stoke\-on\-Trent",
"441635", "Newbury",
"442829", "Kilrea",
"441934", "Weston\-super\-Mare",
"441555", "Lanark",
"4414349", "Bellingham",
"44161", "Manchester",
"4419646", "Patrington",
"441242", "Cheltenham",
"441790", "Spilsby",
"441274", "Bradford",
"441957", "Mid\ Yell",
"441302", "Doncaster",
"441652", "Brigg",
"441225", "Bath",
"4414348", "Hexham",
"442894", "Antrim",
"441878", "Lochboisdale",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441465", "Girvan",
"4418516", "Great\ Bernera",
"442871", "Londonderry",
"442820", "Ballycastle",
"441775", "Spalding",
"441724", "Scunthorpe",
"441291", "Chepstow",
"441567", "Killin",
"441902", "Wolverhampton",
"441357", "Strathaven",
"441620", "North\ Berwick",
"441540", "Kingussie",
"441671", "Newton\ Stewart",
"441877", "Callander",
"4414307", "Market\ Weighton",
"441395", "Budleigh\ Salterton",
"441970", "Aberystwyth",
"4414238", "Harrogate",
"441910", "Tyneside\/Durham\/Sunderland",
"441822", "Tavistock",
"441479", "Grantown\-on\-Spey",
"4418515", "Stornoway",
"441568", "Leominster",
"441263", "Cromer",
"441358", "Ellon",
"441536", "Kettering",
"441608", "Chipping\ Norton",
"441581", "New\ Luce",
"4413397", "Ballater",
"441995", "Garstang",
"4416864", "Llanidloes",
"441733", "Peterborough",
"441656", "Bridgend",
"4418473", "Thurso",
"441239", "Cardigan",
"441694", "Church\ Stretton",
"441769", "South\ Molton",
"441306", "Dorking",
"441875", "Tranent",
"441436", "Helensburgh",
"441481", "Guernsey",
"441824", "Ruthin",
"441689", "Orpington",
"441726", "St\ Austell",
"441383", "Dunfermline",
"4418908", "Coldstream",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441349", "Dingwall",
"4415394", "Hawkshead",
"441228", "Carlisle",
"441643", "Minehead",
"441397", "Fort\ William",
"441750", "Selkirk",
"441949", "Whatton",
"441997", "Strathpeffer",
"442896", "Belfast",
"441440", "Haverhill",
"441778", "Bourne",
"441692", "North\ Walsham",
"441983", "Isle\ of\ Wight",
"441276", "Camberley",
"441200", "Clitheroe",
"4419752", "Alford\ \(Aberdeen\)",
"44118", "Reading",
"4418479", "Tongue",
"441579", "Liskeard",
"441227", "Canterbury",
"441398", "Dulverton",
"441869", "Bicester",
"441534", "Jersey",
"441955", "Wick",
"4414300", "North\ Cave\/Market\ Weighton",
"441304", "Dover",
"441833", "Barnard\ Castle",
"441654", "Machynlleth",
"4414376", "Haverfordwest",
"442892", "Lisburn",
"441467", "Inverurie",
"442889", "Fivemiletown",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441722", "Salisbury",
"441904", "York",
"4413390", "Aboyne\/Ballater",
"441565", "Knutsford",
"441355", "East\ Kilbride",
"441432", "Hereford",
"441777", "Retford",
"441502", "Lowestoft",
"442866", "Enniskillen",
"441285", "Cirencester",
"441967", "Strontian",
"442838", "Portadown",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"442841", "Rostrevor",
"441455", "Hinckley",
"441745", "Rhyl",
"441332", "Derby",
"4416860", "Newtown\/Llanidloes",
"441932", "Weybridge",
"441244", "Chester",
"4415076", "Louth",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441637", "Newquay",
"4414343", "Haltwhistle",
"441848", "Thornhill",
"441404", "Honiton",
"441784", "Staines",
"4412292", "Barrow\-in\-Furness",
"441557", "Kirkcudbright",
"441367", "Faringdon",
"442880", "Carrickmore",
"441340", "Craigellachie\ \(Aberlour\)",
"4418478", "Thurso",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"44239", "Portsmouth",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441981", "Wormbridge",
"441882", "Kinloch\ Rannoch",
"442837", "Armagh",
"441968", "Penicuik",
"441253", "Blackpool",
"441558", "Llandeilo",
"441368", "Dunbar",
"441641", "Strathy",
"4415075", "Spilsby\ \(Horncastle\)",
"441570", "Lampeter",
"4414233", "Boroughbridge",
"441209", "Redruth",
"4418909", "Ayton",
"441899", "Biggar",
"441381", "Fortrose",
"441483", "Guildford",
"441666", "Malmesbury",
"441638", "Newmarket",
"441759", "Pocklington",
"441506", "Bathgate",
"441497", "Hay\-on\-Wye",
"441449", "Stowmarket",
"441925", "Warrington",
"4414347", "Hexham",
"441843", "Thanet",
"4418511", "Great\ Bernera\/Stornoway",
"441889", "Rugeley",
"441257", "Coppull",
"441974", "Llanon",
"441914", "Tyneside",
"441544", "Kington",
"441493", "Great\ Yarmouth",
"441624", "Isle\ of\ Man",
"441675", "Coleshill",
"441487", "Warboys",
"441707", "Welwyn\ Garden\ City",
"4418900", "Coldstream\/Ayton",
"441442", "Hemel\ Hempstead",
"441752", "Plymouth",
"441690", "Betws\-y\-Coed",
"441892", "Tunbridge\ Wells",
"4419756", "Strathdon",
"441202", "Bournemouth",
"44238", "Southampton",
"441325", "Darlington",
"441633", "Newport",
"441854", "Ullapool",
"441708", "Romford",
"441488", "Hungerford",
"441896", "Galashiels",
"441461", "Gretna",
"441206", "Colchester",
"441669", "Rothbury",
"4414237", "Harrogate",
"441270", "Crewe",
"441553", "Kings\ Lynn",
"441258", "Blandford",
"441363", "Crediton",
"441794", "Romsey",
"4414372", "Clynderwen\ \(Clunderwen\)",
"442890", "Belfast",
"441446", "Barry",
"4414308", "Market\ Weighton",
"441509", "Loughborough",
"441756", "Skipton",
"441805", "Torrington",
"442824", "Northern\ Ireland",
"441295", "Banbury",
"4413398", "Aboyne",
"4416869", "Newtown",
"441771", "Maud",
"441720", "Isles\ of\ Scilly",
"441963", "Wincanton",
"4419755", "Alford\ \(Aberdeen\)",
"44116", "Leicester",
"44283", "Northern\ Ireland",
"441939", "Wem",
"442899", "Northern\ Ireland",
"442847", "Northern\ Ireland",
"441946", "Whitehaven",
"441279", "Bishops\ Stortford",
"441773", "Ripley",
"4416868", "Newtown",
"441862", "Tain",
"4413399", "Ballater",
"441988", "Wigtown",
"441576", "Lockerbie",
"441330", "Banchory",
"441439", "Helmsley",
"441388", "Bishop\ Auckland",
"4414234", "Boroughbridge",
"4414309", "Market\ Weighton",
"4415072", "Spilsby\ \(Horncastle\)",
"441528", "Laggan",
"441223", "Cambridge",
"441361", "Duns",
"441463", "Inverness",
"441837", "Okehampton",
"441729", "Settle",
"4412296", "Barrow\-in\-Furness",
"442882", "Omagh",
"441631", "Oban",
"441346", "Fraserburgh",
"4418470", "Thurso\/Tongue",
"441987", "Ebbsfleet",
"442886", "Cookstown",
"441342", "East\ Grinstead",
"441993", "Witney",
"441474", "Gravesend",
"441880", "Tarbert",
"4419641", "Hornsea\/Patrington",
"441425", "Ringwood",
"442848", "Northern\ Ireland",
"441572", "Oakham",
"441838", "Dalmally",
"441491", "Henley\-on\-Thames",
"441866", "Kilchrenan",
"441764", "Crieff",
"441647", "Moretonhampstead",
"4414344", "Bellingham",
"441527", "Redditch",
"441387", "Dumfries",
"4412295", "Barrow\-in\-Furness",
"441234", "Bedford",
"441942", "Wigan",
"441841", "Newquay\ \(Padstow\)",};

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