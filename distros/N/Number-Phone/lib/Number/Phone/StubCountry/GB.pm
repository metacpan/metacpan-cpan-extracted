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
our $VERSION = 1.20240607153920;

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
$areanames{en} = {"441544", "Kington",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441424", "Hastings",
"441779", "Peterhead",
"441559", "Llandysul",
"441668", "Bamburgh",
"441809", "Tomdoun",
"4414237", "Harrogate",
"441725", "Rockbourne",
"441246", "Chesterfield",
"441880", "Tarbert",
"441750", "Selkirk",
"441570", "Lampeter",
"4417683", "Appleby",
"4414303", "North\ Cave",
"4418906", "Ayton",
"441366", "Downham\ Market",
"441274", "Bradford",
"441582", "Luton",
"441360", "Killearn",
"442838", "Portadown",
"441872", "Truro",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441492", "Colwyn\ Bay",
"441407", "Holyhead",
"4415076", "Louth",
"441797", "Rye",
"441576", "Lockerbie",
"441756", "Skipton",
"441702", "Southend\-on\-Sea",
"441588", "Bishops\ Castle",
"441337", "Ladybank",
"4416973", "Wigton",
"441878", "Lochboisdale",
"441708", "Romford",
"441548", "Kingsbridge",
"44239", "Portsmouth",
"441428", "Haslemere",
"4419645", "Hornsea",
"441280", "Buckingham",
"441664", "Melton\ Mowbray",
"441209", "Redruth",
"441422", "Halifax",
"441542", "Keith",
"4419754", "Alford\ \(Aberdeen\)",
"4418477", "Tongue",
"441727", "St\ Albans",
"441335", "Ashbourne",
"441633", "Newport",
"441278", "Bridgwater",
"441840", "Camelford",
"441494", "High\ Wycombe",
"441286", "Caernarfon",
"44117", "Bristol",
"441704", "Southport",
"441453", "Dursley",
"441584", "Ludlow",
"441405", "Goole",
"441874", "Brecon",
"441795", "Sittingbourne",
"441646", "Milford\ Haven",
"441911", "Tyneside\/Durham\/Sunderland",
"442847", "Northern\ Ireland",
"441268", "Basildon",
"441342", "East\ Grinstead",
"44116", "Leicester",
"441864", "Abington\ \(Crawford\)",
"441348", "Fishguard",
"4414309", "Market\ Weighton",
"441262", "Bridlington",
"442885", "Ballygawley",
"4414345", "Haltwhistle",
"44114707", "Sheffield",
"4416860", "Newtown\/Llanidloes",
"441674", "Montrose",
"441384", "Dudley",
"441954", "Madingley",
"441833", "Barnard\ Castle",
"441949", "Whatton",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441535", "Keighley",
"441993", "Witney",
"4419756", "Strathdon",
"441862", "Tain",
"441923", "Watford",
"441264", "Andover",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441566", "Launceston",
"441989", "Ross\-on\-Wye",
"4415074", "Alford\ \(Lincs\)",
"441900", "Workington",
"44114708", "Sheffield",
"441344", "Bracknell",
"441359", "Pakenham",
"442845", "Northern\ Ireland",
"441609", "Northallerton",
"44141", "Glasgow",
"441678", "Bala",
"4414376", "Haverfordwest",
"441388", "Bishop\ Auckland",
"441481", "Guernsey",
"441769", "South\ Molton",
"441952", "Telford",
"441591", "Llanwrtyd\ Wells",
"441233", "Ashford\ \(Kent\)",
"441560", "Moscow",
"441672", "Marlborough",
"442887", "Dungannon",
"441382", "Dundee",
"441376", "Braintree",
"44291", "Cardiff",
"4418904", "Coldstream",
"441631", "Oban",
"441352", "Mold",
"441306", "Dorking",
"442896", "Belfast",
"441656", "Bridgend",
"441697", "Brampton",
"441988", "Wigtown",
"441358", "Ellon",
"441451", "Stow\-on\-the\-Wold",
"4414377", "Haverfordwest",
"441869", "Bicester",
"441436", "Helensburgh",
"441608", "Chipping\ Norton",
"4414234", "Boroughbridge",
"441982", "Builth\ Wells",
"441768", "Penrith",
"441389", "Dumbarton",
"441970", "Aberystwyth",
"441625", "Macclesfield",
"441323", "Eastbourne",
"441650", "Cemmaes\ Road",
"441467", "Inverurie",
"441300", "Cerne\ Abbas",
"441944", "West\ Heslerton",
"441959", "Westerham",
"442890", "Belfast",
"4416869", "Newtown",
"441733", "Peterborough",
"4419642", "Hornsea",
"441984", "Watchet\ \(Williton\)",
"4418474", "Thurso",
"441269", "Ammanford",
"442820", "Ballycastle",
"4419757", "Strathdon",
"4414348", "Hexham",
"441604", "Northampton",
"4420", "London",
"441354", "Chatteris",
"441695", "Skelmersdale",
"441349", "Dingwall",
"441465", "Girvan",
"441942", "Wigan",
"441764", "Crieff",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"442826", "Northern\ Ireland",
"441948", "Whitchurch",
"4414300", "North\ Cave\/Market\ Weighton",
"441256", "Basingstoke",
"441297", "Axminster",
"441202", "Bournemouth",
"441483", "Guildford",
"441475", "Greenock",
"4419641", "Hornsea\/Patrington",
"441935", "Yeovil",
"441593", "Lybster",
"441429", "Hartlepool",
"441554", "Llanelli",
"441895", "Uxbridge",
"441549", "Lairg",
"441146", "Sheffield",
"441208", "Bodmin",
"441740", "Sedgefield",
"441746", "Bridgnorth",
"441225", "Bath",
"44283", "Northern\ Ireland",
"441140", "Sheffield",
"44114702", "Sheffield",
"4418476", "Tongue",
"4414342", "Bellingham",
"441827", "Tamworth",
"441279", "Bishops\ Stortford",
"441250", "Blairgowrie",
"4419648", "Hornsea",
"441669", "Rothbury",
"442871", "Londonderry",
"441558", "Llandeilo",
"441778", "Bourne",
"4416863", "Llanidloes",
"441808", "Tomatin",
"441477", "Holmes\ Chapel",
"44292", "Cardiff",
"441295", "Banbury",
"441772", "Preston",
"441506", "Bathgate",
"441786", "Stirling",
"441937", "Wetherby",
"441204", "Bolton",
"4415077", "Louth",
"441856", "Orkney",
"441780", "Stamford",
"4418907", "Ayton",
"441913", "Durham",
"441879", "Scarinish",
"441227", "Canterbury",
"441709", "Rotherham",
"4414236", "Harrogate",
"441443", "Pontypridd",
"441825", "Uckfield",
"441499", "Inveraray",
"4418511", "Great\ Bernera\/Stornoway",
"441567", "Killin",
"442880", "Carrickmore",
"4412292", "Barrow\-in\-Furness",
"441263", "Cromer",
"441924", "Wakefield",
"4418903", "Coldstream",
"441530", "Coalville",
"4414306", "Market\ Weighton",
"441343", "Elgin",
"4415395", "Grange\-over\-Sands",
"441771", "Maud",
"4415073", "Louth",
"441832", "Clopton",
"441234", "Bedford",
"441992", "Lea\ Valley",
"441536", "Kettering",
"441838", "Dalmally",
"4419759", "Alford\ \(Aberdeen\)",
"441687", "Mallaig",
"441377", "Driffield",
"4418518", "Stornoway",
"4416867", "Llanidloes",
"442886", "Cookstown",
"441928", "Runcorn",
"442846", "Northern\ Ireland",
"441647", "Moretonhampstead",
"44114700", "Sheffield",
"441863", "Ardgay",
"441922", "Walsall",
"441565", "Knutsford",
"44280", "Northern\ Ireland",
"441673", "Market\ Rasen",
"441685", "Merthyr\ Tydfil",
"441383", "Dunfermline",
"441375", "Grays\ Thurrock",
"441329", "Fareham",
"4414379", "Haverfordwest",
"44113", "Leeds",
"441905", "Worcester",
"441834", "Narberth",
"441953", "Wymondham",
"441994", "St\ Clears",
"442840", "Banbridge",
"441663", "New\ Mills",
"441245", "Chelmsford",
"441726", "St\ Austell",
"4418909", "Ayton",
"4414230", "Harrogate\/Boroughbridge",
"4415079", "Alford\ \(Lincs\)",
"441919", "Durham",
"441720", "Isles\ of\ Scilly",
"441634", "Medway",
"441575", "Kirriemuir",
"441583", "Carradale",
"441873", "Abergavenny",
"4419753", "Strathdon",
"441885", "Pencombe",
"441287", "Guisborough",
"441493", "Great\ Yarmouth",
"441529", "Sleaford",
"441454", "Chipping\ Sodbury",
"441449", "Stowmarket",
"4412291", "Barrow\-in\-Furness\/Millom",
"4418512", "Stornoway",
"441330", "Banchory",
"441489", "Bishops\ Waltham",
"442868", "Kesh",
"441761", "Temple\ Cloud",
"4418470", "Thurso\/Tongue",
"441543", "Cannock",
"4413395", "Aboyne",
"441599", "Kyle",
"441845", "Thirsk",
"441367", "Faringdon",
"441790", "Spilsby",
"4416974", "Raughton\ Head",
"441400", "Honington",
"441796", "Pitlochry",
"441757", "Selby",
"441577", "Kinross",
"441887", "Aberfeldy",
"441452", "Gloucester",
"441406", "Holbeach",
"441638", "Newmarket",
"441285", "Cirencester",
"441273", "Brighton",
"441981", "Wormbridge",
"4414373", "Clynderwen\ \(Clunderwen\)",
"4414304", "North\ Cave",
"441458", "Glastonbury",
"4417684", "Pooley\ Bridge",
"44241", "Coventry",
"4412298", "Barrow\-in\-Furness",
"4413391", "Aboyne\/Ballater",
"441488", "Hungerford",
"441381", "Fortrose",
"441671", "Newton\ Stewart",
"44131", "Edinburgh",
"4412295", "Barrow\-in\-Furness",
"441598", "Lynton",
"441145", "Sheffield",
"441857", "Sanday",
"441896", "Galashiels",
"441482", "Kingston\-upon\-Hull",
"441787", "Sudbury",
"441592", "Kirkcaldy",
"441476", "Grantham",
"441951", "Colonsay",
"441255", "Clacton\-on\-Sea",
"441639", "Neath",
"4418479", "Tongue",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441914", "Tyneside",
"4416864", "Llanidloes",
"441444", "Haywards\ Heath",
"441524", "Lancaster",
"441967", "Strontian",
"4413398", "Aboyne",
"441226", "Barnsley",
"441745", "Rhyl",
"441594", "Lydney",
"441855", "Ballachulish",
"44286", "Northern\ Ireland",
"441553", "Kings\ Lynn",
"441773", "Ripley",
"441785", "Stafford",
"441505", "Johnstone",
"441484", "Huddersfield",
"441257", "Coppull",
"441803", "Torquay",
"441296", "Aylesbury",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441522", "Lincoln",
"441261", "Banff",
"441442", "Hemel\ Hempstead",
"441747", "Shaftesbury",
"441918", "Tyneside",
"44238", "Southampton",
"441290", "Cumnock",
"442311", "Southampton",
"4414239", "Boroughbridge",
"441341", "Barmouth",
"441528", "Laggan",
"441912", "Tyneside",
"4418900", "Coldstream\/Ayton",
"441929", "Wareham",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441435", "Heathfield",
"441620", "North\ Berwick",
"441271", "Barnstaple",
"441983", "Isle\ of\ Wight",
"441353", "Ely",
"441655", "Maybole",
"441394", "Felixstowe",
"442895", "Belfast",
"441603", "Norwich",
"441305", "Dorchester",
"44287", "Northern\ Ireland",
"441763", "Royston",
"4418473", "Thurso",
"441239", "Cardigan",
"441328", "Fakenham",
"441626", "Newton\ Abbot",
"442827", "Ballymoney",
"44114704", "Sheffield",
"441322", "Dartford",
"441460", "Chard",
"441738", "Perth",
"4413392", "Aboyne",
"4418515", "Stornoway",
"442897", "Saintfield",
"441307", "Forfar",
"441392", "Exeter",
"4416866", "Newtown",
"44151", "Liverpool",
"441871", "Castlebay",
"441732", "Sevenoaks",
"441581", "New\ Luce",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441398", "Dulverton",
"441977", "Pontefract",
"441491", "Henley\-on\-Thames",
"4417687", "Keswick",
"441661", "Prudhoe",
"4414307", "Market\ Weighton",
"442879", "Magherafelt",
"441324", "Falkirk",
"442825", "Ballymena",
"4414233", "Boroughbridge",
"441943", "Guiseley",
"441466", "Huntly",
"441690", "Betws\-y\-Coed",
"441259", "Alloa",
"441244", "Chester",
"441842", "Thetford",
"441546", "Lochgilphead",
"441364", "Ashburton",
"441621", "Maldon",
"441848", "Thornhill",
"441270", "Crewe",
"441282", "Burnley",
"441749", "Shepton\ Mallet",
"441754", "Skegness",
"441403", "Horsham",
"441793", "Swindon",
"441884", "Tiverton",
"441455", "Hinckley",
"44118", "Reading",
"441276", "Camberley",
"4414343", "Haltwhistle",
"441288", "Bude",
"441420", "Alton",
"441540", "Kingussie",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441635", "Newbury",
"441666", "Malmesbury",
"441700", "Rothesay",
"4419649", "Hornsea",
"4416862", "Llanidloes",
"441490", "Corwen",
"441362", "Dereham",
"441870", "Isle\ of\ Benbecula",
"441248", "Bangor\ \(Gwynedd\)",
"4413396", "Ballater",
"442867", "Lisnaskea",
"441580", "Cranbrook",
"441509", "Loughborough",
"441723", "Scarborough",
"441461", "Gretna",
"442830", "Newry",
"441242", "Cheltenham",
"441789", "Stratford\-upon\-Avon",
"441368", "Dunbar",
"441859", "Harris",
"4413882", "Stanhope\ \(Eastgate\)",
"441844", "Thame",
"441691", "Oswestry",
"441758", "Pwllheli",
"441578", "Lauder",
"441637", "Newquay",
"441888", "Turriff",
"441876", "Lochmaddy",
"441969", "Leyburn",
"441586", "Campbeltown",
"441752", "Plymouth",
"441572", "Oakham",
"441706", "Rochdale",
"441284", "Bury\ St\ Edmunds",
"441882", "Kinloch\ Rannoch",
"4415394", "Hawkshead",
"441496", "Port\ Ellen",
"441457", "Glossop",
"4412297", "Millom",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441309", "Forres",
"4416861", "Newtown\/Llanidloes",
"441950", "Sandwick",
"442899", "Northern\ Ireland",
"441644", "New\ Galloway",
"441659", "Sanquhar",
"441568", "Leominster",
"441866", "Kilchrenan",
"4414305", "North\ Cave",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441439", "Helmsley",
"4415396", "Sedbergh",
"441380", "Devizes",
"441562", "Kidderminster",
"441670", "Morpeth",
"441925", "Warrington",
"441386", "Evesham",
"441676", "Meriden",
"442877", "Limavady",
"4413394", "Ballater",
"4414349", "Bellingham",
"441372", "Esher",
"441908", "Milton\ Keynes",
"441931", "Shap",
"441235", "Abingdon",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"4416868", "Newtown",
"441837", "Okehampton",
"4418517", "Stornoway",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441902", "Wolverhampton",
"441997", "Strathpeffer",
"441821", "Kinrossie",
"4419643", "Patrington",
"441564", "Lapworth",
"44247", "Coventry",
"441642", "Middlesbrough",
"441346", "Fraserburgh",
"441340", "Craigellachie\ \(Aberlour\)",
"441904", "York",
"441237", "Bideford",
"441835", "St\ Boswells",
"441995", "Garstang",
"441291", "Chepstow",
"442310", "Portsmouth",
"441684", "Malvern",
"441260", "Congleton",
"442829", "Kilrea",
"442883", "Northern\ Ireland",
"441654", "Machynlleth",
"441395", "Budleigh\ Salterton",
"442894", "Antrim",
"441304", "Dover",
"44114701", "Sheffield",
"441974", "Llanon",
"442822", "Northern\ Ireland",
"441327", "Daventry",
"441721", "Peebles",
"442828", "Larne",
"441946", "Whitehaven",
"441463", "Inverness",
"442898", "Belfast",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441308", "Bridport",
"441972", "Glenborrodale",
"4416865", "Newtown",
"441569", "Stonehaven",
"441986", "Bungay",
"441737", "Redhill",
"441432", "Hereford",
"4418516", "Great\ Bernera",
"442892", "Lisburn",
"4413885", "Stanhope\ \(Eastgate\)",
"441356", "Brechin",
"441302", "Doncaster",
"441397", "Fort\ William",
"441978", "Wrexham",
"4414301", "North\ Cave\/Market\ Weighton",
"441438", "Stevenage",
"441652", "Brigg",
"441606", "Northwich",
"441760", "Swaffham",
"4414308", "Market\ Weighton",
"441600", "Monmouth",
"441766", "Porthmadog",
"441909", "Worksop",
"4412294", "Barrow\-in\-Furness",
"441350", "Dunkeld",
"441623", "Mansfield",
"441980", "Amesbury",
"441325", "Darlington",
"441379", "Diss",
"442824", "Northern\ Ireland",
"441689", "Orpington",
"441502", "Lowestoft",
"441776", "Stranraer",
"441556", "Castle\ Douglas",
"441597", "Llandrindod\ Wells",
"441531", "Ledbury",
"441293", "Crawley",
"441806", "Shetland",
"441852", "Kilmelford",
"441487", "Warboys",
"441782", "Stoke\-on\-Trent",
"441249", "Chippenham",
"441254", "Blackburn",
"4412296", "Barrow\-in\-Furness",
"441508", "Brooke",
"44281", "Northern\ Ireland",
"4414302", "North\ Cave",
"441858", "Market\ Harborough",
"441369", "Dunoon",
"441788", "Rugby",
"442881", "Newtownstewart",
"441144", "Sheffield",
"441962", "Winchester",
"441445", "Gairloch",
"441525", "Leighton\ Buzzard",
"441823", "Taunton",
"441889", "Rugeley",
"4418514", "Great\ Bernera",
"4419640", "Hornsea\/Patrington",
"441759", "Pocklington",
"441579", "Liskeard",
"441744", "St\ Helens",
"441968", "Penicuik",
"441915", "Sunderland",
"441770", "Isle\ of\ Arran",
"441550", "Llandovery",
"4413397", "Ballater",
"441142", "Sheffield",
"441258", "Blandford",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441933", "Wellingborough",
"441854", "Ullapool",
"441206", "Colchester",
"441252", "Aldershot",
"441784", "Staines",
"44115", "Nottingham",
"441485", "Hunstanton",
"441473", "Ipswich",
"441917", "Sunderland",
"441748", "Richmond",
"442841", "Rostrevor",
"441200", "Clitheroe",
"441527", "Redditch",
"441289", "Berwick\-upon\-Tweed",
"441223", "Cambridge",
"442848", "Northern\ Ireland",
"441926", "Warwick",
"441267", "Carmarthen",
"441865", "Oxford",
"441563", "Kilmarnock",
"442842", "Kircubbin",
"441347", "Easingwold",
"441955", "Wick",
"4418472", "Thurso",
"4414346", "Hexham",
"441534", "Jersey",
"4418510", "Great\ Bernera\/Stornoway",
"441236", "Coatbridge",
"441903", "Worthing",
"4419644", "Patrington",
"441141", "Sheffield",
"442884", "Northern\ Ireland",
"441629", "Matlock",
"441920", "Ware",
"4419755", "Alford\ \(Aberdeen\)",
"441675", "Coleshill",
"441683", "Moffat",
"441373", "Frome",
"441643", "Minehead",
"4413393", "Aboyne",
"442844", "Downpatrick",
"441830", "Kirkwhelpington",
"442870", "Coleraine",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441677", "Bedale",
"442882", "Omagh",
"441387", "Dumfries",
"441538", "Ipstones",
"4414232", "Harrogate",
"441957", "Mid\ Yell",
"441501", "Harthill",
"441469", "Killingholme",
"442888", "Northern\ Ireland",
"442866", "Enniskillen",
"441450", "Hawick",
"441667", "Nairn",
"4414238", "Harrogate",
"441899", "Biggar",
"441545", "Llanarth",
"441425", "Ringwood",
"441939", "Wem",
"441843", "Thanet",
"441630", "Market\ Drayton",
"441479", "Grantown\-on\-Spey",
"441724", "Scunthorpe",
"4418905", "Ayton",
"441408", "Golspie",
"441636", "Newark\-on\-Trent",
"441301", "Arrochar",
"441798", "Pulborough",
"442891", "Bangor\ \(Co\.\ Down\)",
"441332", "Derby",
"441651", "Oldmeldrum",
"442837", "Armagh",
"4415075", "Spilsby\ \(Horncastle\)",
"441283", "Burton\-on\-Trent",
"441971", "Scourie",
"441275", "Clevedon",
"441497", "Hay\-on\-Wye",
"441456", "Glenurquhart",
"4414231", "Harrogate\/Boroughbridge",
"441792", "Swansea",
"441707", "Welwyn\ Garden\ City",
"441431", "Helmsdale",
"441877", "Callander",
"441427", "Gainsborough",
"4413399", "Ballater",
"441547", "Knighton",
"4414344", "Bellingham",
"441722", "Salisbury",
"441243", "Chichester",
"4419646", "Patrington",
"441299", "Bewdley",
"44114703", "Sheffield",
"441728", "Saxmundham",
"442821", "Martinstown",
"441363", "Crediton",
"4418478", "Thurso",
"441665", "Alnwick",
"441495", "Pontypool",
"4418471", "Thurso\/Tongue",
"441277", "Brentwood",
"441829", "Tarporley",
"441573", "Kelso",
"441404", "Honiton",
"441753", "Slough",
"4412290", "Barrow\-in\-Furness\/Millom",
"441875", "Tranent",
"441883", "Caterham",
"441794", "Romsey",
"441334", "St\ Andrews",
"4412299", "Millom",
"441520", "Lochcarron",
"441440", "Haverhill",
"441298", "Buxton",
"441910", "Tyneside\/Durham\/Sunderland",
"441729", "Settle",
"441503", "Looe",
"441474", "Gravesend",
"441805", "Torrington",
"441292", "Ayr",
"441207", "Consett",
"441934", "Weston\-super\-Mare",
"441555", "Lanark",
"441775", "Spalding",
"441828", "Coupar\ Angus",
"441641", "Strathy",
"441916", "Tyneside",
"4418475", "Thurso",
"4413390", "Aboyne\/Ballater",
"441224", "Aberdeen",
"441963", "Wincanton",
"4419752", "Alford\ \(Aberdeen\)",
"441822", "Tavistock",
"4419647", "Patrington",
"441526", "Martin",
"441446", "Barry",
"441932", "Weybridge",
"441294", "Ardrossan",
"4418513", "Stornoway",
"441892", "Tunbridge\ Wells",
"441807", "Ballindalloch",
"441253", "Blackpool",
"441472", "Grimsby",
"441205", "Boston",
"441557", "Kirkcudbright",
"441777", "Retford",
"441938", "Welshpool",
"441143", "Sheffield",
"4418901", "Coldstream\/Ayton",
"4413873", "Langholm",
"441371", "Great\ Dunmow",
"44161", "Manchester",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"4415078", "Alford\ \(Lincs\)",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441799", "Saffron\ Walden",
"441743", "Shrewsbury",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441409", "Holsworthy",
"441561", "Laurencekirk",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441824", "Ruthin",
"4418908", "Coldstream",
"44114709", "Sheffield",
"441590", "Lymington",
"441228", "Carlisle",
"441480", "Huntingdon",
"4414235", "Harrogate",
"441698", "Motherwell",
"441987", "Ebbsfleet",
"441736", "Penzance",
"4412293", "Millom",
"44114705", "Sheffield",
"4415242", "Hornby",
"441751", "Pickering",
"441571", "Lochinver",
"4418902", "Coldstream",
"4414378", "Haverfordwest",
"441692", "North\ Walsham",
"441357", "Strathaven",
"4415072", "Spilsby\ \(Horncastle\)",
"441539", "Kendal",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441767", "Sandy",
"441241", "Arbroath",
"441945", "Wisbech",
"441462", "Hitchin",
"442823", "Northern\ Ireland",
"441624", "Isle\ of\ Man",
"441361", "Duns",
"442889", "Fivemiletown",
"441730", "Petersfield",
"442893", "Ballyclare",
"4418519", "Great\ Bernera",
"442849", "Northern\ Ireland",
"441303", "Folkestone",
"441694", "Church\ Stretton",
"4419758", "Strathdon",
"441355", "East\ Kilbride",
"441653", "Malton",
"441320", "Fort\ Augustus",
"44121", "Birmingham",
"441985", "Warminster",
"4414347", "Hexham",
"441433", "Hathersage",
"441622", "Maidstone",
"441326", "Falmouth",
"441841", "Newquay\ \(Padstow\)",
"4419467", "Gosforth",
"441628", "Maidenhead",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441464", "Insch",
"441765", "Ripon",
"441947", "Whitby",};
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