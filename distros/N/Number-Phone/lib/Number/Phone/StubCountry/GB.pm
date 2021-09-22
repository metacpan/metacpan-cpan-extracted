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
our $VERSION = 1.20210921211831;

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
                  50[02459]
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
                  50[02459]
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
$areanames{en} = {"441970", "Aberystwyth",
"441302", "Doncaster",
"441340", "Craigellachie\ \(Aberlour\)",
"441505", "Johnstone",
"4412290", "Barrow\-in\-Furness\/Millom",
"441407", "Holyhead",
"441409", "Holsworthy",
"4418909", "Ayton",
"441671", "Newton\ Stewart",
"441568", "Leominster",
"441952", "Telford",
"4413397", "Ballater",
"4412295", "Barrow\-in\-Furness",
"4419754", "Alford\ \(Aberdeen\)",
"442877", "Limavady",
"442896", "Belfast",
"441922", "Walsall",
"441746", "Bridgnorth",
"4413398", "Aboyne",
"441663", "New\ Mills",
"442311", "Southampton",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441869", "Bicester",
"442879", "Magherafelt",
"442885", "Ballygawley",
"441381", "Fortrose",
"441530", "Coalville",
"441209", "Redruth",
"441962", "Winchester",
"441558", "Llandeilo",
"441306", "Dorking",
"441827", "Tamworth",
"441207", "Consett",
"4420", "London",
"441623", "Mansfield",
"441829", "Tarporley",
"4417684", "Pooley\ Bridge",
"441926", "Warwick",
"442892", "Lisburn",
"441653", "Malton",
"441700", "Rothesay",
"441859", "Harris",
"441591", "Llanwrtyd\ Wells",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441528", "Laggan",
"4416973", "Wigton",
"441857", "Sanday",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441212", "Birmingham",
"441904", "York",
"441566", "Launceston",
"441570", "Lampeter",
"441629", "Matlock",
"441787", "Sudbury",
"4413392", "Aboyne",
"4414230", "Harrogate\/Boroughbridge",
"4419645", "Hornsea",
"441905", "Worcester",
"44115", "Nottingham",
"441823", "Taunton",
"441355", "East\ Kilbride",
"441789", "Stratford\-upon\-Avon",
"4418471", "Thurso\/Tongue",
"441968", "Penicuik",
"441354", "Chatteris",
"441325", "Darlington",
"442821", "Martinstown",
"4414235", "Harrogate",
"441522", "Lincoln",
"441324", "Falkirk",
"4419640", "Hornsea\/Patrington",
"441748", "Richmond",
"442898", "Belfast",
"4416864", "Llanidloes",
"441659", "Sanquhar",
"441280", "Buckingham",
"4414343", "Haltwhistle",
"441871", "Castlebay",
"4418474", "Thurso",
"441364", "Ashburton",
"441216", "Birmingham",
"441403", "Horsham",
"441562", "Kidderminster",
"441308", "Bridport",
"441556", "Castle\ Douglas",
"441631", "Oban",
"44116", "Leicester",
"441669", "Rothbury",
"4416861", "Newtown\/Llanidloes",
"441526", "Martin",
"441480", "Huntingdon",
"442837", "Armagh",
"441863", "Ardgay",
"441775", "Spalding",
"441241", "Arbroath",
"441690", "Betws\-y\-Coed",
"441667", "Nairn",
"441928", "Runcorn",
"441638", "Newmarket",
"441386", "Evesham",
"441289", "Berwick\-upon\-Tweed",
"441650", "Cemmaes\ Road",
"4418903", "Coldstream",
"441301", "Arrochar",
"441832", "Clopton",
"441672", "Marlborough",
"441951", "Colonsay",
"4413390", "Aboyne\/Ballater",
"4414232", "Harrogate",
"442868", "Kesh",
"441878", "Lochboisdale",
"441287", "Guisborough",
"441474", "Gravesend",
"4412298", "Barrow\-in\-Furness",
"441577", "Kinross",
"441248", "Bangor\ \(Gwynedd\)",
"441475", "Greenock",
"441780", "Stamford",
"4419642", "Hornsea",
"4412297", "Millom",
"441620", "North\ Berwick",
"441579", "Liskeard",
"4413395", "Aboyne",
"441845", "Thirsk",
"441487", "Warboys",
"442830", "Newry",
"441584", "Ludlow",
"441382", "Dundee",
"441844", "Thame",
"441489", "Bishops\ Waltham",
"441697", "Brampton",
"441676", "Meriden",
"441592", "Kirkcaldy",
"441394", "Felixstowe",
"442891", "Bangor\ \(Co\.\ Down\)",
"441395", "Budleigh\ Salterton",
"441937", "Wetherby",
"441343", "Elgin",
"44141", "Glasgow",
"441275", "Clevedon",
"441939", "Wem",
"442828", "Larne",
"441274", "Bradford",
"442870", "Coleraine",
"441483", "Guildford",
"442866", "Enniskillen",
"441876", "Lochmaddy",
"4419648", "Hornsea",
"441211", "Birmingham",
"4415074", "Alford\ \(Lincs\)",
"441899", "Biggar",
"4412292", "Barrow\-in\-Furness",
"4414301", "North\ Cave\/Market\ Weighton",
"4419647", "Patrington",
"441644", "New\ Galloway",
"441388", "Bishop\ Auckland",
"441636", "Newark\-on\-Trent",
"441442", "Hemel\ Hempstead",
"441400", "Honington",
"4418516", "Great\ Bernera",
"441347", "Easingwold",
"4414238", "Harrogate",
"441933", "Wellingborough",
"441977", "Pontefract",
"441598", "Lynton",
"441246", "Chesterfield",
"441235", "Abingdon",
"441349", "Dingwall",
"441234", "Bedford",
"4414237", "Harrogate",
"441678", "Bala",
"441985", "Warminster",
"441561", "Laurencekirk",
"4414304", "North\ Cave",
"441707", "Welwyn\ Garden\ City",
"441872", "Truro",
"441984", "Watchet\ \(Williton\)",
"4415242", "Hornby",
"4414349", "Bellingham",
"441283", "Burton\-on\-Trent",
"441709", "Rotherham",
"441838", "Dalmally",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441992", "Lea\ Valley",
"441435", "Heathfield",
"441446", "Barry",
"441573", "Kelso",
"441242", "Cheltenham",
"441200", "Clitheroe",
"441539", "Kendal",
"441141", "Sheffield",
"441320", "Fort\ Augustus",
"441983", "Isle\ of\ Wight",
"4416869", "Newtown",
"441285", "Cirencester",
"441284", "Bury\ St\ Edmunds",
"441756", "Skipton",
"4415073", "Louth",
"441496", "Port\ Ellen",
"441477", "Holmes\ Chapel",
"441433", "Hathersage",
"441575", "Kirriemuir",
"4413396", "Ballater",
"441900", "Workington",
"441372", "Esher",
"441726", "St\ Austell",
"441942", "Wigan",
"441292", "Ayr",
"441479", "Grantown\-on\-Spey",
"44239", "Portsmouth",
"441350", "Dunkeld",
"441484", "Huddersfield",
"441766", "Porthmadog",
"441770", "Isle\ of\ Arran",
"441485", "Hunstanton",
"441752", "Plymouth",
"441643", "Minehead",
"441695", "Skelmersdale",
"441911", "Tyneside\/Durham\/Sunderland",
"441694", "Church\ Stretton",
"441946", "Whitehaven",
"441722", "Salisbury",
"441360", "Killearn",
"441935", "Yeovil",
"441376", "Braintree",
"44151", "Liverpool",
"441397", "Fort\ William",
"441934", "Weston\-super\-Mare",
"441279", "Bishops\ Stortford",
"4414303", "North\ Cave",
"441492", "Colwyn\ Bay",
"44247", "Coventry",
"441548", "Kingsbridge",
"441233", "Ashford\ \(Kent\)",
"441277", "Brentwood",
"441888", "Turriff",
"4418479", "Tongue",
"441296", "Aylesbury",
"441758", "Pwllheli",
"441730", "Petersfield",
"441895", "Uxbridge",
"441583", "Carradale",
"441843", "Thanet",
"441647", "Moretonhampstead",
"441261", "Banff",
"4419759", "Alford\ \(Aberdeen\)",
"44147986", "Cairngorm",
"4418510", "Great\ Bernera\/Stornoway",
"441451", "Stow\-on\-the\-Wold",
"442841", "Rostrevor",
"4418904", "Coldstream",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441974", "Llanon",
"441542", "Keith",
"441882", "Kinloch\ Rannoch",
"441344", "Bracknell",
"441239", "Cardigan",
"441728", "Saxmundham",
"4418515", "Stornoway",
"441273", "Brighton",
"441237", "Bideford",
"441987", "Ebbsfleet",
"441461", "Gretna",
"441704", "Southport",
"4414379", "Haverfordwest",
"441768", "Penrith",
"441989", "Ross\-on\-Wye",
"441298", "Buxton",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441535", "Keighley",
"441546", "Lochgilphead",
"442880", "Carrickmore",
"441473", "Ipswich",
"441534", "Jersey",
"441332", "Derby",
"4418901", "Coldstream\/Ayton",
"441439", "Helmsley",
"441948", "Whitchurch",
"441405", "Goole",
"441363", "Crediton",
"441404", "Honiton",
"4418512", "Stornoway",
"441761", "Temple\ Cloud",
"441142", "Sheffield",
"441509", "Loughborough",
"4416863", "Llanidloes",
"441916", "Tyneside",
"441258", "Blandford",
"441773", "Ripley",
"441737", "Redhill",
"441371", "Great\ Dunmow",
"441865", "Oxford",
"441228", "Carlisle",
"441864", "Abington\ \(Crawford\)",
"4412296", "Barrow\-in\-Furness",
"441808", "Tomatin",
"4415079", "Alford\ \(Lincs\)",
"441291", "Chepstow",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441825", "Uckfield",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441458", "Glastonbury",
"441903", "Worthing",
"441824", "Ruthin",
"442887", "Dungannon",
"441268", "Basildon",
"441912", "Tyneside",
"441204", "Bolton",
"442889", "Fivemiletown",
"441751", "Pickering",
"441205", "Boston",
"441353", "Ely",
"44281", "Northern\ Ireland",
"441980", "Amesbury",
"441491", "Henley\-on\-Thames",
"4414344", "Bellingham",
"441721", "Peebles",
"4418473", "Thurso",
"441323", "Eastbourne",
"441855", "Ballachulish",
"4415394", "Hawkshead",
"441428", "Haslemere",
"441606", "Northwich",
"441798", "Pulborough",
"441854", "Ullapool",
"4414309", "Market\ Weighton",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441784", "Staines",
"4419753", "Strathdon",
"441256", "Basingstoke",
"441918", "Tyneside",
"441359", "Pakenham",
"441785", "Stafford",
"441466", "Huntly",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"4419646", "Patrington",
"441909", "Worksop",
"441452", "Gloucester",
"441624", "Isle\ of\ Man",
"441357", "Strathaven",
"441625", "Macclesfield",
"441262", "Bridlington",
"441422", "Halifax",
"441654", "Machynlleth",
"441792", "Swansea",
"442842", "Kircubbin",
"441806", "Shetland",
"441655", "Maybole",
"4418517", "Stornoway",
"441327", "Daventry",
"441226", "Barnsley",
"441329", "Fareham",
"4414236", "Harrogate",
"4418518", "Stornoway",
"441503", "Looe",
"441462", "Hitchin",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441252", "Aldershot",
"441367", "Faringdon",
"4416974", "Raughton\ Head",
"441270", "Crewe",
"441456", "Glenurquhart",
"441369", "Dunoon",
"441777", "Retford",
"441733", "Peterborough",
"441580", "Cranbrook",
"441796", "Pitlochry",
"441840", "Camelford",
"441608", "Chipping\ Norton",
"441664", "Melton\ Mowbray",
"441779", "Peterhead",
"4417683", "Appleby",
"441665", "Alnwick",
"441223", "Cambridge",
"4414347", "Hexham",
"441778", "Bourne",
"441609", "Northallerton",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441924", "Wakefield",
"4414348", "Hexham",
"441803", "Torquay",
"441925", "Warrington",
"441732", "Sevenoaks",
"441954", "Madingley",
"441368", "Dunbar",
"441955", "Wick",
"441305", "Dorchester",
"441253", "Blackpool",
"441502", "Lowestoft",
"441880", "Tarbert",
"441463", "Inverness",
"442886", "Cookstown",
"441540", "Kingussie",
"44291", "Cardiff",
"441304", "Dover",
"441328", "Fakenham",
"4419649", "Hornsea",
"441271", "Barnstaple",
"441745", "Rhyl",
"441736", "Penzance",
"442895", "Belfast",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441793", "Swindon",
"442894", "Antrim",
"441744", "St\ Helens",
"441263", "Cromer",
"441908", "Milton\ Keynes",
"441453", "Dursley",
"441917", "Sunderland",
"4414239", "Boroughbridge",
"441358", "Ellon",
"442882", "Omagh",
"441506", "Bathgate",
"441330", "Banchory",
"441581", "New\ Luce",
"441841", "Newquay\ \(Padstow\)",
"441919", "Durham",
"441799", "Saffron\ Walden",
"4412180", "Birmingham",
"441429", "Hartlepool",
"441322", "Dartford",
"441760", "Swaffham",
"441776", "Stranraer",
"441524", "Lancaster",
"4418511", "Great\ Bernera\/Stornoway",
"441797", "Rye",
"441427", "Gainsborough",
"441525", "Leighton\ Buzzard",
"4414342", "Bellingham",
"441352", "Mold",
"441554", "Llanelli",
"441267", "Carmarthen",
"441641", "Strathy",
"441290", "Cumnock",
"441913", "Durham",
"441555", "Lanark",
"441457", "Glossop",
"4414306", "Market\ Weighton",
"441215", "Birmingham",
"441269", "Ammanford",
"441366", "Downham\ Market",
"441214", "Birmingham",
"441902", "Wolverhampton",
"4418514", "Great\ Bernera",
"441227", "Canterbury",
"441603", "Norwich",
"441750", "Selkirk",
"441809", "Tomdoun",
"441738", "Perth",
"441431", "Helmsdale",
"4418905", "Ayton",
"441807", "Ballindalloch",
"4413882", "Stanhope\ \(Eastgate\)",
"441772", "Preston",
"441326", "Falmouth",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441259", "Alloa",
"4415076", "Louth",
"4412299", "Millom",
"4413393", "Aboyne",
"441469", "Killingholme",
"441508", "Brooke",
"441356", "Brechin",
"441143", "Sheffield",
"4418900", "Coldstream\/Ayton",
"441257", "Coppull",
"441564", "Lapworth",
"441362", "Dereham",
"441720", "Isles\ of\ Scilly",
"441490", "Corwen",
"441981", "Wormbridge",
"441467", "Inverurie",
"441565", "Knutsford",
"441450", "Hawick",
"441379", "Diss",
"4414376", "Haverfordwest",
"4415395", "Grange\-over\-Sands",
"441949", "Whatton",
"441260", "Congleton",
"441276", "Camberley",
"441438", "Stevenage",
"441297", "Axminster",
"441377", "Driffield",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441947", "Whitby",
"441299", "Bewdley",
"4414345", "Haltwhistle",
"441472", "Grimsby",
"441675", "Coleshill",
"441988", "Wigtown",
"441674", "Montrose",
"441769", "South\ Molton",
"441420", "Alton",
"441834", "Narberth",
"441501", "Harthill",
"441767", "Sandy",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"442840", "Banbridge",
"441586", "Campbeltown",
"441790", "Spilsby",
"441835", "St\ Boswells",
"4419756", "Strathdon",
"441499", "Inveraray",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441729", "Settle",
"441687", "Mallaig",
"441497", "Hay\-on\-Wye",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"4419643", "Patrington",
"441883", "Caterham",
"441460", "Chard",
"441543", "Cannock",
"441476", "Grantham",
"441392", "Exeter",
"441594", "Lydney",
"441727", "St\ Albans",
"441250", "Blairgowrie",
"441689", "Orpington",
"4413885", "Stanhope\ \(Eastgate\)",
"44118", "Reading",
"44161", "Manchester",
"441757", "Selby",
"4418902", "Coldstream",
"441842", "Thetford",
"441384", "Dudley",
"441582", "Luton",
"441759", "Pocklington",
"4414233", "Boroughbridge",
"442881", "Newtownstewart",
"441549", "Lairg",
"441889", "Rugeley",
"441398", "Dulverton",
"441683", "Moffat",
"441493", "Great\ Yarmouth",
"441436", "Helensburgh",
"441547", "Knighton",
"441278", "Bridgwater",
"441445", "Gairloch",
"441887", "Aberfeldy",
"441140", "Sheffield",
"442825", "Ballymena",
"441723", "Scarborough",
"441444", "Haywards\ Heath",
"441848", "Thornhill",
"441588", "Bishops\ Castle",
"441642", "Middlesbrough",
"441753", "Slough",
"441600", "Monmouth",
"4418476", "Tongue",
"441986", "Bungay",
"441910", "Tyneside\/Durham\/Sunderland",
"441244", "Chester",
"44147985", "Dulnain\ Bridge",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441245", "Chelmsford",
"441236", "Coatbridge",
"4418907", "Ayton",
"441293", "Crawley",
"441943", "Guiseley",
"44147981", "Aviemore",
"441373", "Frome",
"441337", "Ladybank",
"441771", "Maud",
"441995", "Garstang",
"441432", "Hereford",
"4418908", "Coldstream",
"4416866", "Newtown",
"441994", "St\ Clears",
"441635", "Newbury",
"441646", "Milford\ Haven",
"441634", "Medway",
"4413399", "Ballater",
"4412293", "Millom",
"441982", "Builth\ Wells",
"441874", "Brecon",
"441763", "Royston",
"441361", "Duns",
"441875", "Tranent",
"441295", "Banbury",
"44117", "Bristol",
"4414346", "Hexham",
"441243", "Chichester",
"441538", "Ipstones",
"441294", "Ardrossan",
"4414302", "North\ Cave",
"4412291", "Barrow\-in\-Furness\/Millom",
"441550", "Llandovery",
"441944", "West\ Heslerton",
"441572", "Oakham",
"441210", "Birmingham",
"441993", "Witney",
"441375", "Grays\ Thurrock",
"442871", "Londonderry",
"4415396", "Sedbergh",
"441945", "Wisbech",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441282", "Burnley",
"44238", "Southampton",
"441708", "Romford",
"441677", "Bedale",
"441633", "Newport",
"441837", "Okehampton",
"441873", "Abergavenny",
"441765", "Ripon",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441764", "Crieff",
"441520", "Lochcarron",
"441348", "Fishguard",
"4415072", "Spilsby\ \(Horncastle\)",
"441978", "Wrexham",
"441685", "Merthyr\ Tydfil",
"441599", "Kyle",
"441684", "Malvern",
"441725", "Rockbourne",
"441932", "Weybridge",
"441494", "High\ Wycombe",
"441560", "Moscow",
"4419755", "Alford\ \(Aberdeen\)",
"441724", "Scunthorpe",
"4412294", "Barrow\-in\-Furness",
"44131", "Edinburgh",
"441443", "Pontypridd",
"441576", "Lockerbie",
"441597", "Llandrindod\ Wells",
"441495", "Pontypool",
"441389", "Dumbarton",
"441692", "North\ Walsham",
"441754", "Skegness",
"441286", "Caernarfon",
"441387", "Dumfries",
"441821", "Kinrossie",
"4418519", "Great\ Bernera",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441482", "Kingston\-upon\-Hull",
"441938", "Welshpool",
"442829", "Kilrea",
"4414231", "Harrogate\/Boroughbridge",
"441950", "Sandwick",
"441449", "Stowmarket",
"441884", "Tiverton",
"441342", "East\ Grinstead",
"4418470", "Thurso\/Tongue",
"441300", "Cerne\ Abbas",
"441972", "Glenborrodale",
"441544", "Kington",
"441651", "Oldmeldrum",
"442827", "Ballymoney",
"441536", "Kettering",
"441545", "Llanarth",
"44147984", "Carrbridge",
"441885", "Pencombe",
"441593", "Lybster",
"441621", "Maldon",
"4414307", "Market\ Weighton",
"4419641", "Hornsea\/Patrington",
"441488", "Hungerford",
"441698", "Motherwell",
"441383", "Dunfermline",
"4418475", "Thurso",
"441892", "Tunbridge\ Wells",
"4414308", "Market\ Weighton",
"441920", "Ware",
"44147983", "Boat\ of\ Garten",
"441706", "Rochdale",
"441661", "Prudhoe",
"4416865", "Newtown",
"44113", "Leeds",
"441578", "Lauder",
"441249", "Chippenham",
"4414234", "Boroughbridge",
"441334", "St\ Andrews",
"441997", "Strathpeffer",
"441346", "Fraserburgh",
"441335", "Ashbourne",
"441879", "Scarinish",
"4416860", "Newtown\/Llanidloes",
"4415077", "Louth",
"441637", "Newquay",
"441673", "Market\ Rasen",
"442867", "Lisnaskea",
"441877", "Callander",
"441833", "Barnard\ Castle",
"441288", "Bude",
"4415078", "Alford\ \(Lincs\)",
"442890", "Belfast",
"441702", "Southend\-on\-Sea",
"441896", "Galashiels",
"441740", "Sedgefield",
"4419644", "Patrington",
"441639", "Neath",
"4414377", "Haverfordwest",
"441604", "Northampton",
"442838", "Portadown",
"441929", "Wareham",
"4418472", "Thurso",
"441856", "Orkney",
"4414378", "Haverfordwest",
"441862", "Tain",
"4413391", "Aboyne\/Ballater",
"441668", "Bamburgh",
"441571", "Lochinver",
"441957", "Mid\ Yell",
"441206", "Colchester",
"441309", "Forres",
"4417687", "Keswick",
"441563", "Kilmarnock",
"441440", "Haverhill",
"441144", "Sheffield",
"441959", "Westerham",
"441307", "Forfar",
"442820", "Ballycastle",
"441145", "Sheffield",
"441852", "Kilmelford",
"4419757", "Strathdon",
"441630", "Market\ Drayton",
"44292", "Cardiff",
"441749", "Shepton\ Mallet",
"4413394", "Ballater",
"44147982", "Nethy\ Bridge",
"4413873", "Langholm",
"4419758", "Strathdon",
"441866", "Kilchrenan",
"441931", "Shap",
"441870", "Isle\ of\ Benbecula",
"441747", "Shaftesbury",
"442897", "Saintfield",
"441969", "Leyburn",
"441553", "Kings\ Lynn",
"441915", "Sunderland",
"4418513", "Stornoway",
"441788", "Rugby",
"441914", "Tyneside",
"441202", "Bournemouth",
"441691", "Oswestry",
"441822", "Tavistock",
"441967", "Strontian",
"441481", "Guernsey",
"4416862", "Llanidloes",
"441628", "Maidenhead",
"441213", "Birmingham",
"441406", "Holbeach",
"441529", "Sleaford",
"441666", "Malmesbury",
"441670", "Morpeth",
"4419467", "Gosforth",
"441858", "Market\ Harborough",
"442844", "Downpatrick",
"4414300", "North\ Cave\/Market\ Weighton",
"441794", "Romsey",
"441527", "Redditch",
"441425", "Ringwood",
"441971", "Scourie",
"441795", "Sittingbourne",
"441830", "Kirkwhelpington",
"441341", "Barmouth",
"441652", "Brigg",
"442893", "Ballyclare",
"441743", "Shrewsbury",
"441424", "Hastings",
"441828", "Coupar\ Angus",
"441455", "Hinckley",
"441264", "Andover",
"442310", "Portsmouth",
"441557", "Kirkcudbright",
"4414372", "Clynderwen\ \(Clunderwen\)",
"4418477", "Tongue",
"441622", "Maidstone",
"441454", "Chipping\ Sodbury",
"441559", "Llandysul",
"44241", "Coventry",
"4414305", "North\ Cave",
"441963", "Wincanton",
"4418478", "Thurso",
"441782", "Stoke\-on\-Trent",
"441208", "Bodmin",
"441217", "Birmingham",
"441224", "Aberdeen",
"441225", "Bath",
"4416868", "Newtown",
"4418906", "Ayton",
"441923", "Watford",
"441656", "Bridgend",
"441805", "Torrington",
"441531", "Ledbury",
"441380", "Devizes",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"4416867", "Llanidloes",
"441953", "Wymondham",
"441408", "Golspie",
"4419752", "Alford\ \(Aberdeen\)",
"441626", "Newton\ Abbot",
"441569", "Stonehaven",
"441567", "Killin",
"441465", "Girvan",
"441254", "Blackburn",
"441786", "Stirling",
"441590", "Lymington",
"4415075", "Spilsby\ \(Horncastle\)",
"441255", "Clacton\-on\-Sea",
"441464", "Insch",
"441303", "Folkestone",};

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