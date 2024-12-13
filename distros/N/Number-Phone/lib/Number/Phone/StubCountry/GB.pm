# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20241212130805;

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
$areanames{en} = {"441335", "Ashbourne",
"441327", "Daventry",
"441508", "Brooke",
"441670", "Morpeth",
"441482", "Kingston\-upon\-Hull",
"441291", "Chepstow",
"4418470", "Thurso\/Tongue",
"4416973", "Wigton",
"441736", "Penzance",
"441926", "Warwick",
"44161", "Manchester",
"441530", "Coalville",
"441869", "Bicester",
"441664", "Melton\ Mowbray",
"441427", "Gainsborough",
"441435", "Heathfield",
"4414303", "North\ Cave",
"441382", "Dundee",
"441288", "Bude",
"441650", "Cemmaes\ Road",
"441392", "Exeter",
"441876", "Lochmaddy",
"441526", "Martin",
"4418515", "Stornoway",
"441329", "Fareham",
"441334", "St\ Andrews",
"4414230", "Harrogate\/Boroughbridge",
"441298", "Buxton",
"441720", "Isles\ of\ Scilly",
"441908", "Milton\ Keynes",
"442842", "Kircubbin",
"441501", "Harthill",
"442871", "Londonderry",
"441492", "Colwyn\ Bay",
"441429", "Hartlepool",
"441665", "Alnwick",
"441880", "Tarbert",
"441843", "Thanet",
"441856", "Orkney",
"441577", "Kinross",
"441827", "Tamworth",
"441469", "Killingholme",
"441835", "St\ Boswells",
"441722", "Salisbury",
"442883", "Northern\ Ireland",
"442840", "Banbridge",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441246", "Chesterfield",
"441253", "Blackpool",
"441799", "Saffron\ Walden",
"441204", "Bolton",
"4415076", "Louth",
"441994", "St\ Clears",
"4418472", "Thurso",
"441932", "Weybridge",
"441637", "Newquay",
"441625", "Macclesfield",
"4414348", "Hexham",
"441787", "Sudbury",
"441959", "Westerham",
"441369", "Dunoon",
"441882", "Kinloch\ Rannoch",
"441754", "Skegness",
"441566", "Launceston",
"441490", "Corwen",
"4418471", "Thurso\/Tongue",
"441273", "Brighton",
"441760", "Swaffham",
"4415074", "Alford\ \(Lincs\)",
"441557", "Kirkcudbright",
"441985", "Warminster",
"4418519", "Great\ Bernera",
"441584", "Ludlow",
"441892", "Tunbridge\ Wells",
"4418908", "Coldstream",
"441376", "Braintree",
"441797", "Rye",
"441829", "Tarporley",
"441624", "Isle\ of\ Man",
"441467", "Inverurie",
"441579", "Liskeard",
"441775", "Spalding",
"4414232", "Harrogate",
"441641", "Strathy",
"441639", "Neath",
"441834", "Narberth",
"441672", "Marlborough",
"441480", "Huntingdon",
"441977", "Pontefract",
"4419647", "Patrington",
"441443", "Pontypridd",
"441456", "Glenurquhart",
"441594", "Lydney",
"441205", "Boston",
"441995", "Garstang",
"4416868", "Newtown",
"441476", "Grantham",
"442893", "Ballyclare",
"4414231", "Harrogate\/Boroughbridge",
"441984", "Watchet\ \(Williton\)",
"441652", "Brigg",
"441916", "Tyneside",
"441789", "Stratford\-upon\-Avon",
"441957", "Mid\ Yell",
"441367", "Faringdon",
"441380", "Devizes",
"441559", "Llandysul",
"441356", "Brechin",
"441343", "Elgin",
"442896", "Belfast",
"441473", "Ipswich",
"441900", "Workington",
"441728", "Saxmundham",
"441290", "Cumnock",
"441671", "Newton\ Stewart",
"441947", "Whitby",
"4412298", "Barrow\-in\-Furness",
"441642", "Middlesbrough",
"441913", "Durham",
"441745", "Rhyl",
"441549", "Lairg",
"441531", "Ledbury",
"441346", "Fraserburgh",
"441963", "Wincanton",
"441353", "Ely",
"441938", "Welshpool",
"4419644", "Patrington",
"441304", "Dover",
"441373", "Frome",
"441888", "Turriff",
"4413395", "Aboyne",
"4419646", "Patrington",
"441269", "Ammanford",
"441651", "Oldmeldrum",
"441453", "Dursley",
"441446", "Barry",
"441404", "Honiton",
"441949", "Whatton",
"441931", "Shap",
"441706", "Rochdale",
"4419759", "Alford\ \(Aberdeen\)",
"441744", "St\ Helens",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441563", "Kilmarnock",
"44281", "Northern\ Ireland",
"441305", "Dorchester",
"441538", "Ipstones",
"4414301", "North\ Cave\/Market\ Weighton",
"441276", "Camberley",
"442870", "Coleraine",
"441678", "Bala",
"44286", "Northern\ Ireland",
"441547", "Knighton",
"441721", "Peebles",
"442886", "Cookstown",
"441280", "Buckingham",
"441256", "Basingstoke",
"441243", "Chichester",
"441405", "Goole",
"4414302", "North\ Cave",
"4415077", "Louth",
"441267", "Carmarthen",
"441488", "Hungerford",
"44118", "Reading",
"441502", "Lowestoft",
"442841", "Rostrevor",
"4415396", "Sedbergh",
"441235", "Abingdon",
"441227", "Canterbury",
"442824", "Northern\ Ireland",
"4414233", "Boroughbridge",
"441609", "Northallerton",
"441873", "Abergavenny",
"441388", "Bishop\ Auckland",
"4414379", "Haverfordwest",
"441282", "Burnley",
"441761", "Temple\ Cloud",
"4415394", "Hawkshead",
"4419755", "Alford\ \(Aberdeen\)",
"441491", "Henley\-on\-Thames",
"441234", "Bedford",
"4418473", "Thurso",
"44114700", "Sheffield",
"441398", "Dulverton",
"442825", "Ballymena",
"442837", "Armagh",
"441805", "Torrington",
"441683", "Moffat",
"441902", "Wolverhampton",
"441292", "Ayr",
"441481", "Guernsey",
"4413399", "Ballater",
"442848", "Northern\ Ireland",
"4414300", "North\ Cave\/Market\ Weighton",
"441733", "Peterborough",
"44241", "Coventry",
"441768", "Penrith",
"441923", "Watford",
"441381", "Fortrose",
"441911", "Tyneside\/Durham\/Sunderland",
"441673", "Market\ Rasen",
"441442", "Hemel\ Hempstead",
"4414237", "Harrogate",
"44283", "Northern\ Ireland",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"4416869", "Newtown",
"441568", "Leominster",
"4419642", "Hornsea",
"441225", "Bath",
"441237", "Bideford",
"441342", "East\ Grinstead",
"441371", "Great\ Dunmow",
"442892", "Lisburn",
"441451", "Stow\-on\-the\-Wold",
"441604", "Northampton",
"441809", "Tomdoun",
"4418909", "Ayton",
"4419641", "Hornsea\/Patrington",
"441653", "Malton",
"441646", "Milford\ Haven",
"442829", "Kilrea",
"4420", "London",
"441248", "Bangor\ \(Gwynedd\)",
"4414306", "Market\ Weighton",
"441561", "Laurencekirk",
"4418518", "Stornoway",
"441933", "Wellingborough",
"441968", "Penicuik",
"441358", "Ellon",
"44117", "Bristol",
"4418477", "Tongue",
"441723", "Scarborough",
"442882", "Omagh",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441918", "Tyneside",
"4414349", "Bellingham",
"441252", "Aldershot",
"4416974", "Raughton\ Head",
"441239", "Cardigan",
"441241", "Arbroath",
"44115", "Nottingham",
"441458", "Glastonbury",
"441702", "Southend\-on\-Sea",
"442827", "Ballymoney",
"441883", "Caterham",
"4414304", "North\ Cave",
"441807", "Ballindalloch",
"441224", "Aberdeen",
"441840", "Camelford",
"441286", "Caernarfon",
"442880", "Carrickmore",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"4419640", "Hornsea\/Patrington",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441250", "Blairgowrie",
"441264", "Andover",
"441409", "Holsworthy",
"442867", "Lisnaskea",
"441700", "Rothesay",
"4414345", "Haltwhistle",
"441928", "Runcorn",
"4415242", "Hornby",
"441842", "Thetford",
"441747", "Shaftesbury",
"441871", "Castlebay",
"44121", "Birmingham",
"441493", "Great\ Yarmouth",
"441544", "Kington",
"441270", "Crewe",
"441945", "Wisbech",
"441506", "Bathgate",
"441763", "Royston",
"441738", "Perth",
"441309", "Forres",
"441691", "Oswestry",
"4418905", "Ayton",
"4419467", "Gosforth",
"441858", "Market\ Harborough",
"441483", "Guildford",
"441407", "Holyhead",
"441440", "Haverhill",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441296", "Aylesbury",
"441545", "Llanarth",
"441749", "Shepton\ Mallet",
"4416865", "Newtown",
"441698", "Motherwell",
"442890", "Belfast",
"441944", "West\ Heslerton",
"4415073", "Louth",
"441383", "Dunfermline",
"441878", "Lochboisdale",
"441528", "Laggan",
"441307", "Forfar",
"441340", "Craigellachie\ \(Aberlour\)",
"441903", "Worthing",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441987", "Ebbsfleet",
"441555", "Lanark",
"441293", "Crawley",
"441759", "Pocklington",
"441364", "Ashburton",
"441954", "Madingley",
"4412295", "Barrow\-in\-Furness",
"441910", "Tyneside\/Durham\/Sunderland",
"441386", "Evesham",
"441350", "Dunkeld",
"441785", "Stafford",
"44141", "Glasgow",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"4413398", "Aboyne",
"441922", "Walsall",
"441464", "Insch",
"441635", "Newbury",
"441209", "Redruth",
"441848", "Thornhill",
"441794", "Romsey",
"441597", "Llandrindod\ Wells",
"441450", "Hawick",
"441837", "Okehampton",
"441779", "Peterhead",
"441825", "Uckfield",
"441575", "Kirriemuir",
"44131", "Edinburgh",
"441732", "Sevenoaks",
"441974", "Llanon",
"44280", "Northern\ Ireland",
"441852", "Kilmelford",
"4419643", "Patrington",
"4414378", "Haverfordwest",
"441784", "Staines",
"4413873", "Langholm",
"441560", "Moscow",
"441989", "Ross\-on\-Wye",
"441757", "Selby",
"441554", "Llanelli",
"441496", "Port\ Ellen",
"441503", "Looe",
"441955", "Wick",
"441766", "Porthmadog",
"441692", "North\ Walsham",
"441207", "Consett",
"441283", "Burton\-on\-Trent",
"441997", "Strathpeffer",
"442846", "Northern\ Ireland",
"441629", "Matlock",
"441824", "Ruthin",
"441522", "Lincoln",
"441872", "Truro",
"4413885", "Stanhope\ \(Eastgate\)",
"441841", "Newquay\ \(Padstow\)",
"441777", "Retford",
"441634", "Medway",
"441465", "Girvan",
"441795", "Sittingbourne",
"441599", "Kyle",
"441864", "Abington\ \(Crawford\)",
"441669", "Rothbury",
"442881", "Newtownstewart",
"4418474", "Thurso",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441425", "Ringwood",
"441562", "Kidderminster",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441870", "Isle\ of\ Benbecula",
"4418476", "Tongue",
"441520", "Lochcarron",
"441144", "Sheffield",
"441348", "Fishguard",
"4414307", "Market\ Weighton",
"441690", "Betws\-y\-Coed",
"442898", "Belfast",
"441726", "St\ Austell",
"4415072", "Spilsby\ \(Horncastle\)",
"441242", "Cheltenham",
"441325", "Darlington",
"441337", "Ladybank",
"4419758", "Strathdon",
"441271", "Barnstaple",
"44114702", "Sheffield",
"441962", "Winchester",
"441352", "Mold",
"441667", "Nairn",
"44114708", "Sheffield",
"441424", "Hastings",
"4414234", "Boroughbridge",
"442888", "Northern\ Ireland",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441472", "Grimsby",
"441439", "Helmsley",
"441865", "Oxford",
"441258", "Blandford",
"441643", "Minehead",
"441656", "Bridgend",
"441912", "Tyneside",
"441278", "Bridgwater",
"441676", "Meriden",
"441452", "Gloucester",
"441324", "Falkirk",
"442891", "Bangor\ \(Co\.\ Down\)",
"441730", "Petersfield",
"441372", "Esher",
"441896", "Galashiels",
"441341", "Barmouth",
"441920", "Ware",
"4412299", "Millom",
"441145", "Sheffield",
"441708", "Romford",
"4414236", "Harrogate",
"441536", "Kettering",
"441489", "Bishops\ Waltham",
"441375", "Grays\ Thurrock",
"44151", "Liverpool",
"441142", "Sheffield",
"441630", "Market\ Drayton",
"442838", "Portadown",
"441397", "Fort\ William",
"441776", "Stranraer",
"442847", "Northern\ Ireland",
"441570", "Lampeter",
"441455", "Hinckley",
"441244", "Chester",
"441206", "Colchester",
"441608", "Chipping\ Norton",
"441550", "Llandovery",
"441475", "Greenock",
"441389", "Dumbarton",
"441767", "Sandy",
"441862", "Tain",
"441497", "Hay\-on\-Wye",
"441915", "Sunderland",
"441586", "Campbeltown",
"4418475", "Thurso",
"441756", "Skipton",
"441743", "Shrewsbury",
"441780", "Stamford",
"441355", "East\ Kilbride",
"441564", "Lapworth",
"441322", "Dartford",
"441454", "Chipping\ Sodbury",
"441245", "Chelmsford",
"4419753", "Strathdon",
"441970", "Aberystwyth",
"441403", "Horsham",
"441487", "Warboys",
"441460", "Chard",
"441228", "Carlisle",
"441790", "Spilsby",
"442849", "Northern\ Ireland",
"441626", "Newton\ Abbot",
"441499", "Inveraray",
"441422", "Halifax",
"4414235", "Harrogate",
"441354", "Chatteris",
"441303", "Folkestone",
"441387", "Dumfries",
"441565", "Knutsford",
"441769", "South\ Molton",
"441474", "Gravesend",
"441360", "Killearn",
"441950", "Sandwick",
"4418510", "Great\ Bernera\/Stornoway",
"441986", "Bungay",
"441914", "Tyneside",
"4416867", "Llanidloes",
"441875", "Tranent",
"441525", "Leighton\ Buzzard",
"441729", "Settle",
"441462", "Hitchin",
"441924", "Wakefield",
"441792", "Swansea",
"4414239", "Boroughbridge",
"441548", "Kingsbridge",
"441695", "Skelmersdale",
"441320", "Fort\ Augustus",
"4417684", "Pooley\ Bridge",
"441939", "Wem",
"4412296", "Barrow\-in\-Furness",
"441972", "Glenborrodale",
"441677", "Bedale",
"441684", "Malvern",
"441889", "Rugeley",
"4418907", "Ayton",
"441952", "Telford",
"441362", "Dereham",
"4412294", "Barrow\-in\-Furness",
"441268", "Basildon",
"441666", "Malmesbury",
"441233", "Ashford\ \(Kent\)",
"4419648", "Hornsea",
"441420", "Alton",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441855", "Ballachulish",
"441948", "Whitchurch",
"4414347", "Hexham",
"441899", "Biggar",
"441694", "Church\ Stretton",
"4418511", "Great\ Bernera\/Stornoway",
"441572", "Oakham",
"441822", "Tavistock",
"4418479", "Tongue",
"441727", "St\ Albans",
"441539", "Kendal",
"441524", "Lancaster",
"441874", "Brecon",
"441140", "Sheffield",
"4413393", "Aboyne",
"441925", "Warrington",
"441937", "Wetherby",
"4418512", "Stornoway",
"441436", "Helensburgh",
"441261", "Banff",
"441782", "Stoke\-on\-Trent",
"441659", "Sanquhar",
"441854", "Ullapool",
"442823", "Northern\ Ireland",
"441803", "Torquay",
"441887", "Aberfeldy",
"441685", "Merthyr\ Tydfil",
"441433", "Hathersage",
"44114701", "Sheffield",
"44116", "Leicester",
"4414344", "Bellingham",
"442826", "Northern\ Ireland",
"441844", "Thame",
"441798", "Pulborough",
"441631", "Oban",
"441806", "Shetland",
"441542", "Keith",
"441821", "Kinrossie",
"441571", "Lochinver",
"4419752", "Alford\ \(Aberdeen\)",
"441978", "Wrexham",
"4413390", "Aboyne\/Ballater",
"4415078", "Alford\ \(Lincs\)",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441368", "Dunbar",
"4414309", "Market\ Weighton",
"4414346", "Hexham",
"441262", "Bridlington",
"44239", "Portsmouth",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441971", "Scourie",
"441647", "Moretonhampstead",
"4416864", "Llanidloes",
"441942", "Wigan",
"441600", "Monmouth",
"441578", "Lauder",
"441828", "Coupar\ Angus",
"441663", "New\ Mills",
"441236", "Coatbridge",
"4418906", "Ayton",
"441638", "Newmarket",
"442830", "Newry",
"44238", "Southampton",
"441845", "Thirsk",
"44114709", "Sheffield",
"441461", "Gretna",
"4417687", "Keswick",
"4418904", "Coldstream",
"441788", "Rugby",
"4412297", "Millom",
"4416866", "Newtown",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441558", "Llandeilo",
"441361", "Duns",
"441951", "Colonsay",
"4413392", "Aboyne",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441509", "Loughborough",
"442879", "Magherafelt",
"441344", "Bracknell",
"441306", "Dorking",
"442894", "Antrim",
"441275", "Clevedon",
"441983", "Isle\ of\ Wight",
"441297", "Axminster",
"441833", "Barnard\ Castle",
"442885", "Ballygawley",
"4413391", "Aboyne\/Ballater",
"441255", "Clacton\-on\-Sea",
"441444", "Haywards\ Heath",
"441593", "Lybster",
"441406", "Holbeach",
"441289", "Berwick\-upon\-Tweed",
"4418513", "Stornoway",
"441623", "Mansfield",
"441274", "Bradford",
"442895", "Belfast",
"441540", "Kingussie",
"442877", "Limavady",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441583", "Carradale",
"441328", "Fakenham",
"4414305", "North\ Cave",
"441704", "Southport",
"441746", "Bridgnorth",
"441753", "Slough",
"441299", "Bewdley",
"441909", "Worksop",
"441141", "Sheffield",
"442866", "Enniskillen",
"441260", "Congleton",
"441773", "Ripley",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441428", "Haslemere",
"442884", "Northern\ Ireland",
"441254", "Blackburn",
"441445", "Gairloch",
"441287", "Guisborough",
"441993", "Witney",
"441633", "Newport",
"4414342", "Bellingham",
"441668", "Bamburgh",
"441449", "Stowmarket",
"44287", "Northern\ Ireland",
"441431", "Helmsdale",
"441257", "Coppull",
"441284", "Bury\ St\ Edmunds",
"441573", "Kelso",
"441823", "Taunton",
"4419754", "Alford\ \(Aberdeen\)",
"442887", "Dungannon",
"4415395", "Grange\-over\-Sands",
"441546", "Lochgilphead",
"441295", "Banbury",
"441553", "Kings\ Lynn",
"441905", "Worcester",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"4418517", "Stornoway",
"441277", "Brentwood",
"441349", "Dingwall",
"4419756", "Strathdon",
"4418478", "Thurso",
"442899", "Northern\ Ireland",
"441740", "Sedgefield",
"441707", "Welwyn\ Garden\ City",
"442822", "Northern\ Ireland",
"4418901", "Coldstream\/Ayton",
"4419649", "Hornsea",
"4416862", "Llanidloes",
"441285", "Cirencester",
"441400", "Honington",
"442889", "Fivemiletown",
"44113", "Leeds",
"441463", "Inverness",
"441438", "Stevenage",
"44292", "Cardiff",
"441793", "Swindon",
"441259", "Alloa",
"441661", "Prudhoe",
"441347", "Easingwold",
"4416861", "Newtown\/Llanidloes",
"441279", "Bishops\ Stortford",
"4418902", "Coldstream",
"4414238", "Harrogate",
"441300", "Cerne\ Abbas",
"441294", "Ardrossan",
"441904", "York",
"441946", "Whitehaven",
"441363", "Crediton",
"441953", "Wymondham",
"441505", "Johnstone",
"441709", "Rotherham",
"442897", "Saintfield",
"4413394", "Ballater",
"441758", "Pwllheli",
"44114707", "Sheffield",
"442310", "Portsmouth",
"441981", "Wormbridge",
"441323", "Eastbourne",
"441588", "Bishops\ Castle",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"44291", "Cardiff",
"441591", "Llanwrtyd\ Wells",
"441208", "Bodmin",
"441606", "Northwich",
"441644", "New\ Galloway",
"44247", "Coventry",
"441621", "Maldon",
"4413396", "Ballater",
"441778", "Bourne",
"4419645", "Hornsea",
"441302", "Doncaster",
"441581", "New\ Luce",
"4417683", "Appleby",
"441988", "Wigtown",
"441143", "Sheffield",
"441751", "Pickering",
"4414376", "Haverfordwest",
"4416860", "Newtown\/Llanidloes",
"441771", "Maud",
"441226", "Barnsley",
"441628", "Maidenhead",
"442820", "Ballycastle",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441863", "Ardgay",
"441838", "Dalmally",
"4418900", "Coldstream\/Ayton",
"4412293", "Millom",
"441598", "Lynton",
"441857", "Sanday",
"441752", "Plymouth",
"441689", "Orpington",
"441884", "Tiverton",
"441223", "Cambridge",
"4416863", "Llanidloes",
"441866", "Kilchrenan",
"441408", "Golspie",
"441582", "Luton",
"441655", "Maybole",
"4415075", "Spilsby\ \(Horncastle\)",
"441330", "Banchory",
"44114705", "Sheffield",
"441929", "Wareham",
"441675", "Coleshill",
"441724", "Scunthorpe",
"4414377", "Haverfordwest",
"441992", "Lea\ Valley",
"441697", "Brampton",
"441202", "Bournemouth",
"4412290", "Barrow\-in\-Furness\/Millom",
"441895", "Uxbridge",
"4418903", "Coldstream",
"441146", "Sheffield",
"441535", "Keighley",
"441527", "Redditch",
"441877", "Callander",
"441308", "Bridport",
"441772", "Preston",
"441934", "Weston\-super\-Mare",
"4413397", "Ballater",
"441603", "Norwich",
"441982", "Builth\ Wells",
"441687", "Mallaig",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441654", "Machynlleth",
"441859", "Harris",
"4414343", "Haltwhistle",
"442868", "Kesh",
"441885", "Pencombe",
"441748", "Richmond",
"441301", "Arrochar",
"441534", "Jersey",
"441622", "Maidstone",
"441935", "Yeovil",
"44114704", "Sheffield",
"441832", "Clopton",
"441725", "Rockbourne",
"441529", "Sleaford",
"441737", "Redhill",
"441674", "Montrose",
"441879", "Scarinish",
"441592", "Kirkcaldy",
"441326", "Falmouth",
"441967", "Strontian",
"441357", "Strathaven",
"441384", "Dudley",
"4412291", "Barrow\-in\-Furness\/Millom",
"441495", "Pontypool",
"441917", "Sunderland",
"441366", "Downham\ Market",
"441943", "Guiseley",
"441980", "Amesbury",
"441765", "Ripon",
"441569", "Stonehaven",
"441477", "Holmes\ Chapel",
"442311", "Southampton",
"441830", "Kirkwhelpington",
"441457", "Glossop",
"441484", "Huddersfield",
"441590", "Lymington",
"442845", "Northern\ Ireland",
"4412292", "Barrow\-in\-Furness",
"441395", "Budleigh\ Salterton",
"441466", "Huntly",
"441808", "Tomatin",
"441377", "Driffield",
"441620", "North\ Berwick",
"442828", "Larne",
"441796", "Pitlochry",
"441249", "Chippenham",
"441494", "High\ Wycombe",
"441556", "Castle\ Douglas",
"441543", "Cannock",
"441764", "Crieff",
"441580", "Cranbrook",
"441969", "Leyburn",
"441359", "Pakenham",
"441432", "Hereford",
"4414308", "Market\ Weighton",
"441750", "Selkirk",
"4413882", "Stanhope\ \(Eastgate\)",
"44114703", "Sheffield",
"4418516", "Great\ Bernera",
"441567", "Killin",
"441479", "Grantown\-on\-Spey",
"441919", "Durham",
"441786", "Stirling",
"4419757", "Strathdon",
"4418514", "Great\ Bernera",
"441394", "Felixstowe",
"442821", "Martinstown",
"4415079", "Alford\ \(Lincs\)",
"441636", "Newark\-on\-Trent",
"441263", "Cromer",
"441770", "Isle\ of\ Arran",
"441332", "Derby",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441485", "Hunstanton",
"441379", "Diss",
"442844", "Downpatrick",
"441576", "Lockerbie",
"441200", "Clitheroe",};
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
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '44', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;