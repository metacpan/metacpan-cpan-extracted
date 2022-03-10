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
our $VERSION = 1.20220307120118;

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
$areanames{en} = {"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441981", "Wormbridge",
"4418474", "Thurso",
"441505", "Johnstone",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441584", "Ludlow",
"441245", "Chelmsford",
"441786", "Stirling",
"441300", "Cerne\ Abbas",
"441698", "Motherwell",
"4418902", "Coldstream",
"442837", "Armagh",
"4414235", "Harrogate",
"441292", "Ayr",
"441373", "Frome",
"442880", "Carrickmore",
"441257", "Coppull",
"441433", "Hathersage",
"4415077", "Louth",
"441873", "Abergavenny",
"441723", "Scarborough",
"441567", "Killin",
"441795", "Sittingbourne",
"441992", "Lea\ Valley",
"441738", "Perth",
"442825", "Ballymena",
"441428", "Haslemere",
"4415075", "Spilsby\ \(Horncastle\)",
"441957", "Mid\ Yell",
"442893", "Ballyclare",
"441547", "Knighton",
"441207", "Consett",
"4414237", "Harrogate",
"441635", "Newbury",
"4419646", "Patrington",
"441350", "Dunkeld",
"441497", "Hay\-on\-Wye",
"441945", "Wisbech",
"441824", "Ruthin",
"441452", "Gloucester",
"441324", "Falkirk",
"441555", "Lanark",
"4414343", "Haltwhistle",
"441576", "Lockerbie",
"4418471", "Thurso\/Tongue",
"441663", "New\ Mills",
"4414344", "Bellingham",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441767", "Sandy",
"441233", "Ashford\ \(Kent\)",
"441928", "Runcorn",
"441457", "Glossop",
"441608", "Chipping\ Norton",
"44147986", "Cairngorm",
"4413885", "Stanhope\ \(Eastgate\)",
"441492", "Colwyn\ Bay",
"441542", "Keith",
"4415396", "Sedbergh",
"4412296", "Barrow\-in\-Furness",
"441586", "Campbeltown",
"44147982", "Nethy\ Bridge",
"441202", "Bournemouth",
"441689", "Orpington",
"441215", "Birmingham",
"441952", "Telford",
"441349", "Dingwall",
"441445", "Gairloch",
"441271", "Barnstaple",
"441997", "Strathpeffer",
"4414306", "Market\ Weighton",
"441784", "Staines",
"441141", "Sheffield",
"441562", "Kidderminster",
"441902", "Wolverhampton",
"441869", "Bicester",
"441776", "Stranraer",
"441622", "Maidstone",
"441915", "Sunderland",
"441369", "Dunoon",
"44116", "Leicester",
"441465", "Girvan",
"442868", "Kesh",
"441252", "Aldershot",
"441326", "Falmouth",
"441481", "Guernsey",
"441971", "Scourie",
"441297", "Axminster",
"441643", "Minehead",
"441407", "Holyhead",
"441747", "Shaftesbury",
"441883", "Caterham",
"441933", "Wellingborough",
"442870", "Coleraine",
"4418473", "Thurso",
"441383", "Dunfermline",
"441538", "Ipstones",
"441228", "Carlisle",
"4413398", "Aboyne",
"4417684", "Pooley\ Bridge",
"441482", "Kingston\-upon\-Hull",
"441446", "Barry",
"4416869", "Newtown",
"441972", "Glenborrodale",
"441706", "Rochdale",
"441380", "Devizes",
"441244", "Chester",
"4413391", "Aboyne\/Ballater",
"441621", "Maldon",
"441880", "Tarbert",
"441561", "Laurencekirk",
"441216", "Birmingham",
"441987", "Ebbsfleet",
"441477", "Holmes\ Chapel",
"441837", "Okehampton",
"441794", "Romsey",
"4414379", "Haverfordwest",
"44247", "Coventry",
"441337", "Ladybank",
"441287", "Guisborough",
"4412292", "Barrow\-in\-Furness",
"441491", "Henley\-on\-Thames",
"4412180", "Birmingham",
"4414302", "North\ Cave",
"441678", "Bala",
"4418478", "Thurso",
"4416973", "Wigton",
"441554", "Llanelli",
"441466", "Huntly",
"441142", "Sheffield",
"4413393", "Aboyne",
"441325", "Darlington",
"441951", "Colonsay",
"441429", "Hartlepool",
"4418510", "Great\ Bernera\/Stornoway",
"441264", "Andover",
"441825", "Uckfield",
"441944", "West\ Heslerton",
"441520", "Lochcarron",
"441756", "Skipton",
"441775", "Spalding",
"441916", "Tyneside",
"441634", "Medway",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"4419642", "Hornsea",
"441796", "Pitlochry",
"441848", "Thornhill",
"4413394", "Ballater",
"4416974", "Raughton\ Head",
"441348", "Fishguard",
"441594", "Lydney",
"441277", "Brentwood",
"441353", "Ely",
"441785", "Stafford",
"441704", "Southport",
"441761", "Temple\ Cloud",
"441444", "Haywards\ Heath",
"441929", "Wareham",
"441214", "Birmingham",
"441451", "Stow\-on\-the\-Wold",
"442890", "Belfast",
"4418519", "Great\ Bernera",
"441506", "Bathgate",
"441282", "Burnley",
"4419755", "Alford\ \(Aberdeen\)",
"441246", "Chesterfield",
"441609", "Northallerton",
"4419757", "Strathdon",
"441720", "Isles\ of\ Scilly",
"441332", "Derby",
"441464", "Insch",
"441556", "Castle\ Douglas",
"441870", "Isle\ of\ Benbecula",
"441659", "Sanquhar",
"441575", "Kirriemuir",
"441636", "Newark\-on\-Trent",
"441914", "Tyneside",
"4416860", "Newtown\/Llanidloes",
"441539", "Kendal",
"441754", "Skegness",
"44151", "Liverpool",
"441472", "Grimsby",
"441982", "Builth\ Wells",
"441946", "Whitehaven",
"441832", "Clopton",
"441303", "Folkestone",
"4414348", "Hexham",
"441803", "Torquay",
"4417683", "Appleby",
"441368", "Dunbar",
"4418906", "Ayton",
"441977", "Pontefract",
"441291", "Chepstow",
"441487", "Warboys",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441335", "Ashbourne",
"441879", "Scarinish",
"441766", "Porthmadog",
"441439", "Helmsley",
"441650", "Cemmaes\ Road",
"4416861", "Newtown\/Llanidloes",
"44141", "Glasgow",
"441572", "Oakham",
"441729", "Settle",
"441254", "Blackburn",
"441241", "Arbroath",
"4413399", "Ballater",
"4419647", "Patrington",
"441624", "Isle\ of\ Man",
"441501", "Harthill",
"441379", "Diss",
"441564", "Lapworth",
"441835", "St\ Boswells",
"441456", "Glenurquhart",
"441904", "York",
"44117", "Bristol",
"441985", "Warminster",
"441530", "Coalville",
"441475", "Greenock",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"4414236", "Harrogate",
"4418514", "Great\ Bernera",
"441777", "Retford",
"4415076", "Louth",
"441494", "High\ Wycombe",
"441673", "Market\ Rasen",
"441827", "Tamworth",
"4419752", "Alford\ \(Aberdeen\)",
"441296", "Aylesbury",
"441327", "Daventry",
"442821", "Martinstown",
"442840", "Banbridge",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441782", "Stoke\-on\-Trent",
"441746", "Bridgnorth",
"4419645", "Hornsea",
"441954", "Madingley",
"441406", "Holbeach",
"44147983", "Boat\ of\ Garten",
"441261", "Banff",
"4416863", "Llanidloes",
"441600", "Monmouth",
"441920", "Ware",
"441285", "Cirencester",
"441398", "Dulverton",
"441544", "Kington",
"441631", "Oban",
"441204", "Bolton",
"44147981", "Aviemore",
"4416864", "Llanidloes",
"441343", "Elgin",
"441358", "Ellon",
"441858", "Market\ Harborough",
"441683", "Moffat",
"441591", "Llanwrtyd\ Wells",
"441994", "St\ Clears",
"441787", "Sudbury",
"441843", "Thanet",
"4413873", "Langholm",
"441145", "Sheffield",
"441256", "Basingstoke",
"441275", "Clevedon",
"441420", "Alton",
"4420", "London",
"4412295", "Barrow\-in\-Furness",
"4415395", "Grange\-over\-Sands",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441764", "Crieff",
"441322", "Dartford",
"441730", "Petersfield",
"4414305", "North\ Cave",
"441669", "Rothbury",
"441454", "Chipping\ Sodbury",
"441211", "Birmingham",
"441822", "Tavistock",
"441566", "Launceston",
"4418511", "Great\ Bernera\/Stornoway",
"441772", "Preston",
"441626", "Newton\ Abbot",
"441529", "Sleaford",
"441239", "Cardigan",
"44118", "Reading",
"441485", "Hunstanton",
"441389", "Dumbarton",
"441404", "Honiton",
"4413390", "Aboyne\/Ballater",
"441461", "Gretna",
"441744", "St\ Helens",
"4414307", "Market\ Weighton",
"4418513", "Stornoway",
"441206", "Colchester",
"4412297", "Millom",
"441911", "Tyneside\/Durham\/Sunderland",
"441546", "Lochgilphead",
"441582", "Luton",
"441751", "Pickering",
"441939", "Wem",
"4419467", "Gosforth",
"441889", "Rugeley",
"441808", "Tomatin",
"442310", "Portsmouth",
"441363", "Crediton",
"441496", "Port\ Ellen",
"441577", "Kinross",
"441690", "Betws\-y\-Coed",
"441308", "Bridport",
"441294", "Ardrossan",
"441863", "Ardgay",
"441474", "Gravesend",
"441984", "Watchet\ \(Williton\)",
"441905", "Worcester",
"441834", "Narberth",
"441565", "Knutsford",
"441797", "Rye",
"4414349", "Bellingham",
"441912", "Tyneside",
"441625", "Macclesfield",
"441581", "New\ Luce",
"441752", "Plymouth",
"441462", "Hitchin",
"441255", "Clacton\-on\-Sea",
"441276", "Camberley",
"441360", "Killearn",
"441334", "St\ Andrews",
"441438", "Stevenage",
"441878", "Lochboisdale",
"44147985", "Dulnain\ Bridge",
"441728", "Saxmundham",
"441967", "Strontian",
"442879", "Magherafelt",
"44241", "Coventry",
"441899", "Biggar",
"441557", "Kirkcudbright",
"441592", "Kirkcaldy",
"441267", "Carmarthen",
"4418470", "Thurso\/Tongue",
"441733", "Peterborough",
"441947", "Whitby",
"442898", "Belfast",
"441495", "Pontypool",
"441637", "Newquay",
"4418518", "Stornoway",
"441840", "Camelford",
"441205", "Boston",
"441771", "Maud",
"441545", "Llanarth",
"441284", "Bury\ St\ Edmunds",
"441212", "Birmingham",
"441821", "Kinrossie",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441442", "Hemel\ Hempstead",
"4413882", "Stanhope\ \(Eastgate\)",
"442827", "Ballymoney",
"441955", "Wick",
"441340", "Craigellachie\ \(Aberlour\)",
"441702", "Southend\-on\-Sea",
"441923", "Watford",
"441707", "Welwyn\ Garden\ City",
"4418479", "Tongue",
"441995", "Garstang",
"4418907", "Ayton",
"441603", "Norwich",
"441668", "Bamburgh",
"441217", "Birmingham",
"441528", "Laggan",
"4415072", "Spilsby\ \(Horncastle\)",
"442843", "Newcastle\ \(Co\.\ Down\)",
"44115", "Nottingham",
"441262", "Bridlington",
"441455", "Hinckley",
"441986", "Bungay",
"441359", "Pakenham",
"441942", "Wigan",
"441476", "Grantham",
"441670", "Morpeth",
"441765", "Ripon",
"441597", "Llandrindod\ Wells",
"4419756", "Strathdon",
"441859", "Harris",
"441274", "Bradford",
"441144", "Sheffield",
"441809", "Tomdoun",
"441286", "Caernarfon",
"441242", "Cheltenham",
"4414232", "Harrogate",
"441502", "Lowestoft",
"441962", "Winchester",
"4414378", "Haverfordwest",
"441571", "Lochinver",
"441745", "Rhyl",
"441405", "Goole",
"441309", "Forres",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441484", "Huddersfield",
"441974", "Llanon",
"441223", "Cambridge",
"4416868", "Newtown",
"44291", "Cardiff",
"441388", "Bishop\ Auckland",
"441295", "Banbury",
"442889", "Fivemiletown",
"441467", "Inverurie",
"4418905", "Ayton",
"441917", "Sunderland",
"441757", "Selby",
"441888", "Turriff",
"441653", "Malton",
"441792", "Swansea",
"441938", "Welshpool",
"4416867", "Llanidloes",
"441356", "Brechin",
"441989", "Ross\-on\-Wye",
"441479", "Grantown\-on\-Spey",
"441375", "Grays\ Thurrock",
"442838", "Portadown",
"441435", "Heathfield",
"441570", "Lampeter",
"44113", "Leeds",
"4419641", "Hornsea\/Patrington",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441856", "Orkney",
"44131", "Edinburgh",
"441697", "Brampton",
"441875", "Tranent",
"441725", "Rockbourne",
"441793", "Swindon",
"441652", "Brigg",
"441258", "Blandford",
"4414377", "Haverfordwest",
"441963", "Wincanton",
"441503", "Looe",
"441243", "Chichester",
"441568", "Leominster",
"441908", "Milton\ Keynes",
"441628", "Maidenhead",
"442842", "Kircubbin",
"442886", "Cookstown",
"441633", "Newport",
"441427", "Gainsborough",
"4414304", "North\ Cave",
"441943", "Guiseley",
"441263", "Cromer",
"441737", "Redhill",
"4415394", "Hawkshead",
"441208", "Bodmin",
"4412294", "Barrow\-in\-Furness",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441394", "Felixstowe",
"441548", "Kingsbridge",
"441553", "Kings\ Lynn",
"441806", "Shetland",
"441922", "Walsall",
"4419643", "Patrington",
"442895", "Belfast",
"441289", "Berwick\-upon\-Tweed",
"4418908", "Coldstream",
"441671", "Newton\ Stewart",
"4414346", "Hexham",
"441306", "Dorking",
"4416865", "Newtown",
"441780", "Stamford",
"4413392", "Aboyne",
"441768", "Penrith",
"44292", "Cardiff",
"441213", "Birmingham",
"4419644", "Patrington",
"441443", "Pontypridd",
"441458", "Glastonbury",
"441770", "Isle\ of\ Arran",
"441841", "Newquay\ \(Padstow\)",
"4412293", "Millom",
"441665", "Alnwick",
"441354", "Chatteris",
"441593", "Lybster",
"441235", "Abingdon",
"441525", "Leighton\ Buzzard",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441279", "Bishops\ Stortford",
"441732", "Sevenoaks",
"441320", "Fort\ Augustus",
"441341", "Barmouth",
"4418517", "Stornoway",
"441854", "Ullapool",
"4414303", "North\ Cave",
"441422", "Halifax",
"4418515", "Stornoway",
"4419759", "Alford\ \(Aberdeen\)",
"4414301", "North\ Cave\/Market\ Weighton",
"441885", "Pencombe",
"441580", "Cranbrook",
"441935", "Yeovil",
"4412291", "Barrow\-in\-Furness\/Millom",
"441298", "Buxton",
"441304", "Dover",
"441489", "Bishops\ Waltham",
"442867", "Lisnaskea",
"441361", "Duns",
"441896", "Galashiels",
"441748", "Richmond",
"441753", "Slough",
"441408", "Golspie",
"441913", "Durham",
"441692", "North\ Walsham",
"4418476", "Tongue",
"441463", "Inverness",
"441227", "Canterbury",
"441362", "Dereham",
"441259", "Alloa",
"441724", "Scunthorpe",
"441874", "Brecon",
"441460", "Chard",
"4418904", "Coldstream",
"4418472", "Thurso",
"441909", "Worksop",
"441910", "Tyneside\/Durham\/Sunderland",
"441569", "Stonehaven",
"441750", "Selkirk",
"441666", "Malmesbury",
"441862", "Tain",
"441236", "Coatbridge",
"441526", "Martin",
"441629", "Matlock",
"4415242", "Hornby",
"442311", "Southampton",
"441838", "Dalmally",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"4414308", "Market\ Weighton",
"441988", "Wigtown",
"4415079", "Alford\ \(Lincs\)",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441583", "Carradale",
"44281", "Northern\ Ireland",
"441691", "Oswestry",
"4412298", "Barrow\-in\-Furness",
"441323", "Eastbourne",
"441395", "Budleigh\ Salterton",
"441288", "Bude",
"441499", "Inveraray",
"441895", "Uxbridge",
"441677", "Bedale",
"441823", "Taunton",
"441590", "Lymington",
"441773", "Ripley",
"4414239", "Boroughbridge",
"441959", "Westerham",
"4413396", "Ballater",
"441342", "East\ Grinstead",
"441386", "Evesham",
"441700", "Rothesay",
"441440", "Haverhill",
"441549", "Lairg",
"442894", "Antrim",
"441209", "Redruth",
"441646", "Milford\ Haven",
"441210", "Birmingham",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441842", "Thetford",
"4418901", "Coldstream\/Ayton",
"4414230", "Harrogate\/Boroughbridge",
"441687", "Mallaig",
"442820", "Ballycastle",
"441278", "Bridgwater",
"442841", "Rostrevor",
"441347", "Easingwold",
"4414342", "Bellingham",
"441436", "Helensburgh",
"441769", "South\ Molton",
"441855", "Ballachulish",
"441876", "Lochmaddy",
"441550", "Llandovery",
"441672", "Marlborough",
"441726", "St\ Austell",
"441260", "Congleton",
"441524", "Lancaster",
"441234", "Bedford",
"441355", "East\ Kilbride",
"441664", "Melton\ Mowbray",
"441630", "Market\ Drayton",
"441376", "Braintree",
"441749", "Shepton\ Mallet",
"441651", "Oldmeldrum",
"441305", "Dorchester",
"44147984", "Carrbridge",
"441384", "Dudley",
"441409", "Holsworthy",
"441934", "Weston\-super\-Mare",
"441805", "Torrington",
"441884", "Tiverton",
"441644", "New\ Galloway",
"442896", "Belfast",
"441531", "Ledbury",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441790", "Spilsby",
"441573", "Kelso",
"441488", "Hungerford",
"442885", "Ballygawley",
"441978", "Wrexham",
"4419648", "Hornsea",
"441299", "Bewdley",
"441367", "Faringdon",
"4418903", "Coldstream",
"441721", "Peebles",
"441400", "Honington",
"441871", "Castlebay",
"441740", "Sedgefield",
"4414347", "Hexham",
"441431", "Helmsdale",
"441302", "Doncaster",
"442877", "Limavady",
"441371", "Great\ Dunmow",
"441926", "Warwick",
"441249", "Chippenham",
"441606", "Northwich",
"441969", "Leyburn",
"441509", "Loughborough",
"441588", "Bishops\ Castle",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"4419758", "Strathdon",
"4414233", "Boroughbridge",
"441799", "Saffron\ Walden",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441694", "Church\ Stretton",
"442882", "Omagh",
"441833", "Barnard\ Castle",
"441983", "Isle\ of\ Wight",
"441290", "Cumnock",
"441473", "Ipswich",
"441828", "Coupar\ Angus",
"4415073", "Louth",
"441778", "Bourne",
"442866", "Enniskillen",
"441283", "Burton\-on\-Trent",
"4414376", "Haverfordwest",
"441328", "Fakenham",
"442829", "Kilrea",
"4414231", "Harrogate\/Boroughbridge",
"4418900", "Coldstream\/Ayton",
"441424", "Hastings",
"441852", "Kilmelford",
"44239", "Portsmouth",
"441760", "Swaffham",
"441656", "Bridgend",
"441675", "Coleshill",
"441559", "Llandysul",
"4414345", "Haltwhistle",
"441226", "Barnsley",
"441536", "Kettering",
"4416866", "Newtown",
"442891", "Bangor\ \(Co\.\ Down\)",
"441639", "Neath",
"441397", "Fort\ William",
"441450", "Hawick",
"44161", "Manchester",
"441269", "Ammanford",
"441352", "Mold",
"441949", "Whatton",
"441143", "Sheffield",
"441357", "Strathaven",
"441490", "Corwen",
"4418477", "Tongue",
"441273", "Brighton",
"4418909", "Ayton",
"441392", "Exeter",
"441788", "Rugby",
"441892", "Tunbridge\ Wells",
"442844", "Downpatrick",
"441599", "Kyle",
"441857", "Sanday",
"441449", "Stowmarket",
"441950", "Sandwick",
"441709", "Rotherham",
"4415074", "Alford\ \(Lincs\)",
"441685", "Merthyr\ Tydfil",
"441604", "Northampton",
"441661", "Prudhoe",
"441540", "Kingussie",
"441924", "Wakefield",
"441200", "Clitheroe",
"441845", "Thirsk",
"441736", "Penzance",
"441469", "Killingholme",
"441654", "Machynlleth",
"4418516", "Great\ Bernera",
"441250", "Blairgowrie",
"442887", "Dungannon",
"441381", "Fortrose",
"441931", "Shap",
"441620", "North\ Berwick",
"441900", "Workington",
"441560", "Moscow",
"441919", "Durham",
"441641", "Strathy",
"441759", "Pocklington",
"4414234", "Boroughbridge",
"441534", "Jersey",
"441865", "Oxford",
"441224", "Aberdeen",
"441483", "Guildford",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441807", "Ballindalloch",
"441307", "Forfar",
"441578", "Lauder",
"442830", "Newry",
"4418475", "Thurso",
"441642", "Middlesbrough",
"4412290", "Barrow\-in\-Furness\/Millom",
"441798", "Pulborough",
"441932", "Weybridge",
"441882", "Kinloch\ Rannoch",
"4419649", "Hornsea",
"4413397", "Ballater",
"441346", "Fraserburgh",
"441382", "Dundee",
"441970", "Aberystwyth",
"4414300", "North\ Cave\/Market\ Weighton",
"441480", "Huntingdon",
"441903", "Worthing",
"441727", "St\ Albans",
"441563", "Kilmarnock",
"441695", "Skelmersdale",
"441877", "Callander",
"441623", "Mansfield",
"4418512", "Stornoway",
"441253", "Blackpool",
"441377", "Driffield",
"442871", "Londonderry",
"441508", "Brooke",
"441968", "Penicuik",
"441248", "Bangor\ \(Gwynedd\)",
"441543", "Cannock",
"4419754", "Alford\ \(Aberdeen\)",
"441558", "Llandeilo",
"441638", "Newmarket",
"441953", "Wymondham",
"442897", "Saintfield",
"441948", "Whitchurch",
"441268", "Basildon",
"441829", "Tarporley",
"4413395", "Aboyne",
"441779", "Peterhead",
"441522", "Lincoln",
"441866", "Kilchrenan",
"441674", "Montrose",
"441366", "Downham\ Market",
"441493", "Great\ Yarmouth",
"441270", "Crewe",
"442828", "Larne",
"441425", "Ringwood",
"441140", "Sheffield",
"441329", "Fareham",
"4417687", "Keswick",
"441453", "Dursley",
"441708", "Romford",
"4416862", "Llanidloes",
"441763", "Royston",
"441237", "Bideford",
"441527", "Redditch",
"441667", "Nairn",
"441844", "Thame",
"441925", "Warrington",
"441280", "Buckingham",
"441993", "Witney",
"442892", "Lisburn",
"441684", "Malvern",
"4419753", "Strathdon",
"441789", "Stratford\-upon\-Avon",
"4414238", "Harrogate",
"441344", "Bracknell",
"441598", "Lynton",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441980", "Amesbury",
"441864", "Abington\ \(Crawford\)",
"441225", "Bath",
"441535", "Keighley",
"441293", "Crawley",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"4419640", "Hornsea\/Patrington",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441830", "Kirkwhelpington",
"4414309", "Market\ Weighton",
"441372", "Esher",
"441872", "Truro",
"4412299", "Millom",
"4415078", "Alford\ \(Lincs\)",
"441432", "Hereford",
"441301", "Arrochar",
"441579", "Liskeard",
"441364", "Ashburton",
"441655", "Maybole",
"441330", "Banchory",
"441676", "Meriden",
"441722", "Salisbury",
"441387", "Dumfries",
"442881", "Newtownstewart",
"441937", "Wetherby",
"441887", "Aberfeldy",
"441743", "Shrewsbury",
"441647", "Moretonhampstead",
"441758", "Pwllheli",
"441403", "Horsham",
"44238", "Southampton",
"441918", "Tyneside",};

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