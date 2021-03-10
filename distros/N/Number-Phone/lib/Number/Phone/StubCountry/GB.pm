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
our $VERSION = 1.20210309172131;

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
                  73[03]
                )|
                4(?:
                  [0-5]\\d\\d|
                  69[7-9]
                )|
                (?:
                  5[0-26-9]|
                  6[0-4]|
                  [78][0-49]
                )\\d\\d
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
                    8[02]
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
                  73[03]
                )|
                4(?:
                  [0-5]\\d\\d|
                  69[7-9]
                )|
                (?:
                  5[0-26-9]|
                  6[0-4]|
                  [78][0-49]
                )\\d\\d
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
                    8[02]
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
$areanames{en} = {"441556", "Castle\ Douglas",
"44147981", "Aviemore",
"441356", "Brechin",
"4416973", "Wigton",
"441757", "Selby",
"441499", "Inveraray",
"441764", "Crieff",
"441895", "Uxbridge",
"441654", "Machynlleth",
"441667", "Nairn",
"441141", "Sheffield",
"441440", "Haverhill",
"441352", "Mold",
"441140", "Sheffield",
"4412293", "Millom",
"441900", "Workington",
"441959", "Westerham",
"441473", "Ipswich",
"442838", "Portadown",
"441475", "Greenock",
"441216", "Birmingham",
"4419467", "Gosforth",
"441588", "Bishops\ Castle",
"4419755", "Alford\ \(Aberdeen\)",
"441848", "Thornhill",
"441733", "Peterborough",
"441388", "Bishop\ Auckland",
"441879", "Scarinish",
"441212", "Birmingham",
"441204", "Bolton",
"4414347", "Hexham",
"441244", "Chester",
"441808", "Tomatin",
"441837", "Okehampton",
"441568", "Leominster",
"441720", "Isles\ of\ Scilly",
"441721", "Peebles",
"44115", "Nottingham",
"441368", "Dunbar",
"4412180", "Birmingham",
"441797", "Rye",
"4413885", "Stanhope\ \(Eastgate\)",
"441400", "Honington",
"4414349", "Bellingham",
"441236", "Coatbridge",
"4419642", "Hornsea",
"441784", "Staines",
"441392", "Exeter",
"441855", "Ballachulish",
"441694", "Church\ Stretton",
"442829", "Kilrea",
"441592", "Kirkcaldy",
"441687", "Mallaig",
"4412290", "Barrow\-in\-Furness\/Millom",
"44147982", "Nethy\ Bridge",
"441825", "Uckfield",
"4417687", "Keswick",
"441823", "Taunton",
"441672", "Marlborough",
"4416869", "Newtown",
"441938", "Welshpool",
"4413393", "Aboyne",
"441676", "Meriden",
"441269", "Ammanford",
"441429", "Hartlepool",
"441750", "Selkirk",
"441751", "Pickering",
"4416867", "Llanidloes",
"441709", "Rotherham",
"441661", "Prudhoe",
"441407", "Holyhead",
"441438", "Stevenage",
"441790", "Spilsby",
"441918", "Tyneside",
"441929", "Wareham",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441778", "Bourne",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441749", "Shepton\ Mallet",
"441522", "Lincoln",
"44247", "Coventry",
"441830", "Kirkwhelpington",
"441322", "Dartford",
"441624", "Isle\ of\ Man",
"4413390", "Aboyne\/Ballater",
"441526", "Martin",
"441289", "Berwick\-upon\-Tweed",
"441947", "Whitby",
"441727", "St\ Albans",
"442840", "Banbridge",
"441326", "Falmouth",
"442841", "Rostrevor",
"441489", "Bishops\ Waltham",
"441566", "Launceston",
"441366", "Downham\ Market",
"441754", "Skegness",
"441767", "Sandy",
"441543", "Cannock",
"441883", "Caterham",
"441545", "Llanarth",
"441562", "Kidderminster",
"4419753", "Strathdon",
"441885", "Pencombe",
"441343", "Elgin",
"441664", "Melton\ Mowbray",
"441806", "Shetland",
"441362", "Dereham",
"441633", "Newport",
"441635", "Newbury",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441570", "Lampeter",
"441969", "Leyburn",
"441571", "Lochinver",
"441371", "Great\ Dunmow",
"441398", "Dulverton",
"4412295", "Barrow\-in\-Furness",
"44118", "Reading",
"441207", "Consett",
"441598", "Lynton",
"441620", "North\ Berwick",
"4414377", "Haverfordwest",
"441621", "Maldon",
"441989", "Ross\-on\-Wye",
"441834", "Narberth",
"442844", "Downpatrick",
"441558", "Llandeilo",
"441358", "Ellon",
"44116", "Leicester",
"441469", "Killingholme",
"441794", "Romsey",
"441586", "Campbeltown",
"441303", "Folkestone",
"441305", "Dorchester",
"4414379", "Haverfordwest",
"441503", "Looe",
"441386", "Evesham",
"441505", "Johnstone",
"441787", "Sudbury",
"441863", "Ardgay",
"441697", "Brampton",
"441842", "Thetford",
"441865", "Oxford",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441582", "Luton",
"4419648", "Hornsea",
"441684", "Malvern",
"441382", "Dundee",
"441377", "Driffield",
"44151", "Liverpool",
"441776", "Stranraer",
"441577", "Kinross",
"441912", "Tyneside",
"44131", "Edinburgh",
"4414237", "Harrogate",
"441432", "Hereford",
"441904", "York",
"441772", "Preston",
"4418479", "Tongue",
"441200", "Clitheroe",
"441259", "Alloa",
"441436", "Helensburgh",
"441916", "Tyneside",
"441761", "Temple\ Cloud",
"4415395", "Grange\-over\-Sands",
"441760", "Swaffham",
"441528", "Laggan",
"4414239", "Boroughbridge",
"4413395", "Aboyne",
"441328", "Fakenham",
"441444", "Haywards\ Heath",
"441609", "Northallerton",
"441144", "Sheffield",
"441650", "Cemmaes\ Road",
"441651", "Oldmeldrum",
"4418477", "Tongue",
"4419646", "Patrington",
"4419644", "Patrington",
"441678", "Bala",
"441780", "Stamford",
"4414309", "Market\ Weighton",
"441932", "Weybridge",
"441404", "Honiton",
"4419641", "Hornsea\/Patrington",
"441275", "Clevedon",
"441690", "Betws\-y\-Coed",
"441691", "Oswestry",
"441273", "Brighton",
"442889", "Fivemiletown",
"441241", "Arbroath",
"4414307", "Market\ Weighton",
"441944", "West\ Heslerton",
"441724", "Scunthorpe",
"441539", "Kendal",
"441299", "Bewdley",
"441977", "Pontefract",
"44147986", "Cairngorm",
"441288", "Bude",
"442870", "Coleraine",
"441795", "Sittingbourne",
"442871", "Londonderry",
"441793", "Swindon",
"44113", "Leeds",
"441304", "Dover",
"441685", "Merthyr\ Tydfil",
"4415242", "Hornby",
"442898", "Belfast",
"441683", "Moffat",
"4417684", "Pooley\ Bridge",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441857", "Sanday",
"441606", "Northwich",
"441864", "Abington\ \(Crawford\)",
"441835", "St\ Boswells",
"441748", "Richmond",
"4416861", "Newtown\/Llanidloes",
"441833", "Barnard\ Castle",
"441779", "Peterhead",
"441252", "Aldershot",
"441928", "Runcorn",
"44147983", "Boat\ of\ Garten",
"442866", "Enniskillen",
"4416864", "Llanidloes",
"441919", "Durham",
"441439", "Helmsley",
"441256", "Basingstoke",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441292", "Ayr",
"441477", "Holmes\ Chapel",
"441821", "Kinrossie",
"441332", "Derby",
"44147984", "Carrbridge",
"441634", "Medway",
"44141", "Glasgow",
"442886", "Cookstown",
"4416866", "Newtown",
"441296", "Aylesbury",
"441536", "Kettering",
"441737", "Redhill",
"441708", "Romford",
"442882", "Omagh",
"441753", "Slough",
"441646", "Milford\ Haven",
"441268", "Basildon",
"441428", "Haslemere",
"4414348", "Hexham",
"441939", "Wem",
"441642", "Middlesbrough",
"441665", "Alnwick",
"441344", "Bracknell",
"441663", "New\ Mills",
"4415073", "Louth",
"441544", "Kington",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441884", "Tiverton",
"4418472", "Thurso",
"4418905", "Ayton",
"4416868", "Newtown",
"442828", "Larne",
"441725", "Rockbourne",
"441723", "Scarborough",
"441943", "Guiseley",
"441962", "Winchester",
"441945", "Wisbech",
"441458", "Glastonbury",
"441405", "Goole",
"441369", "Dunoon",
"442877", "Limavady",
"441403", "Horsham",
"44281", "Northern\ Ireland",
"441569", "Stonehaven",
"4414346", "Hexham",
"441971", "Scourie",
"441970", "Aberystwyth",
"441274", "Bradford",
"4414232", "Harrogate",
"441809", "Tomdoun",
"441482", "Kingston\-upon\-Hull",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441389", "Dumbarton",
"441878", "Lochboisdale",
"441226", "Barnsley",
"441466", "Huntly",
"4414344", "Bellingham",
"4414302", "North\ Cave",
"441445", "Gairloch",
"441462", "Hitchin",
"441145", "Sheffield",
"441443", "Pontypridd",
"441143", "Sheffield",
"441903", "Worthing",
"441905", "Worcester",
"441986", "Bungay",
"441827", "Tamworth",
"4418515", "Stornoway",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441730", "Petersfield",
"441982", "Builth\ Wells",
"4414306", "Market\ Weighton",
"441974", "Llanon",
"441785", "Stafford",
"441538", "Ipstones",
"441298", "Buxton",
"441706", "Rochdale",
"4414231", "Harrogate\/Boroughbridge",
"441307", "Forfar",
"441270", "Crewe",
"441854", "Ullapool",
"441695", "Skelmersdale",
"441702", "Southend\-on\-Sea",
"441271", "Barnstaple",
"4414234", "Boroughbridge",
"441243", "Chichester",
"4418474", "Thurso",
"441245", "Chelmsford",
"441422", "Halifax",
"441262", "Bridlington",
"4418471", "Thurso\/Tongue",
"442896", "Belfast",
"441474", "Gravesend",
"441608", "Chipping\ Norton",
"441637", "Newquay",
"441282", "Burnley",
"4419647", "Patrington",
"441329", "Fareham",
"4418476", "Tongue",
"442892", "Lisburn",
"441205", "Boston",
"441286", "Caernarfon",
"441529", "Sleaford",
"4415075", "Spilsby\ \(Horncastle\)",
"4414236", "Harrogate",
"441763", "Royston",
"441765", "Ripon",
"441258", "Blandford",
"441922", "Walsall",
"4414378", "Haverfordwest",
"4414301", "North\ Cave\/Market\ Weighton",
"441746", "Bridgnorth",
"441655", "Maybole",
"441653", "Malton",
"441347", "Easingwold",
"4419649", "Hornsea",
"441547", "Knighton",
"442868", "Kesh",
"441926", "Warwick",
"4414342", "Bellingham",
"441887", "Aberfeldy",
"4414304", "North\ Cave",
"441872", "Truro",
"441623", "Mansfield",
"442311", "Southampton",
"442310", "Portsmouth",
"441625", "Macclesfield",
"4418478", "Thurso",
"441876", "Lochmaddy",
"4416862", "Llanidloes",
"441952", "Telford",
"441228", "Carlisle",
"441301", "Arrochar",
"4418903", "Coldstream",
"441496", "Port\ Ellen",
"441300", "Cerne\ Abbas",
"4414238", "Harrogate",
"441359", "Pakenham",
"441501", "Harthill",
"4414376", "Haverfordwest",
"441559", "Llandysul",
"4418510", "Great\ Bernera\/Stornoway",
"441277", "Brentwood",
"441492", "Colwyn\ Bay",
"441988", "Wigtown",
"4418900", "Coldstream\/Ayton",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441239", "Cardigan",
"441599", "Kyle",
"4414308", "Market\ Weighton",
"441456", "Glenurquhart",
"4418513", "Stornoway",
"441540", "Kingussie",
"441880", "Tarbert",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441340", "Craigellachie\ \(Aberlour\)",
"441452", "Gloucester",
"441341", "Barmouth",
"441968", "Penicuik",
"441630", "Market\ Drayton",
"441575", "Kirriemuir",
"441631", "Oban",
"441573", "Kelso",
"441824", "Ruthin",
"441375", "Grays\ Thurrock",
"441373", "Frome",
"441992", "Lea\ Valley",
"441488", "Hungerford",
"4414230", "Harrogate\/Boroughbridge",
"4414303", "North\ Cave",
"442842", "Kircubbin",
"4418518", "Stornoway",
"441768", "Penrith",
"441832", "Clopton",
"441520", "Lochcarron",
"441253", "Blackpool",
"441255", "Clacton\-on\-Sea",
"441320", "Fort\ Augustus",
"441208", "Bodmin",
"441237", "Bideford",
"441597", "Llandrindod\ Wells",
"441384", "Dudley",
"441397", "Fort\ William",
"441796", "Pitlochry",
"441844", "Thame",
"441584", "Ludlow",
"4418470", "Thurso\/Tongue",
"441792", "Swansea",
"441603", "Norwich",
"441756", "Skipton",
"441357", "Strathaven",
"441643", "Minehead",
"441364", "Ashburton",
"441557", "Kirkcudbright",
"441564", "Lapworth",
"4418473", "Thurso",
"441279", "Bishops\ Stortford",
"441752", "Plymouth",
"441666", "Malmesbury",
"4413873", "Langholm",
"441248", "Bangor\ \(Gwynedd\)",
"441217", "Birmingham",
"4418908", "Coldstream",
"4414233", "Boroughbridge",
"4414300", "North\ Cave\/Market\ Weighton",
"441698", "Motherwell",
"442885", "Ballygawley",
"4416865", "Newtown",
"441670", "Morpeth",
"441295", "Banbury",
"441535", "Keighley",
"441788", "Rugby",
"441671", "Newton\ Stewart",
"441293", "Crawley",
"441335", "Ashbourne",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441406", "Holbeach",
"441485", "Hunstanton",
"441590", "Lymington",
"4414345", "Haltwhistle",
"441483", "Guildford",
"441591", "Llanwrtyd\ Wells",
"441934", "Weston\-super\-Mare",
"441578", "Lauder",
"441349", "Dingwall",
"441889", "Rugeley",
"441549", "Lairg",
"441722", "Salisbury",
"4418906", "Ayton",
"4418511", "Great\ Bernera\/Stornoway",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441963", "Wincanton",
"4415072", "Spilsby\ \(Horncastle\)",
"441942", "Wigan",
"441639", "Neath",
"441327", "Daventry",
"4418514", "Great\ Bernera",
"441726", "St\ Austell",
"441527", "Redditch",
"441946", "Whitehaven",
"441983", "Isle\ of\ Wight",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"4418901", "Coldstream\/Ayton",
"4418516", "Great\ Bernera",
"441211", "Birmingham",
"441985", "Warminster",
"441210", "Birmingham",
"441914", "Tyneside",
"441902", "Wolverhampton",
"44161", "Manchester",
"4419759", "Alford\ \(Aberdeen\)",
"4418904", "Coldstream",
"441677", "Bedale",
"441550", "Llandovery",
"441509", "Loughborough",
"441442", "Hemel\ Hempstead",
"441350", "Dunkeld",
"441225", "Bath",
"441465", "Girvan",
"441142", "Sheffield",
"441223", "Cambridge",
"441309", "Forres",
"441463", "Inverness",
"441628", "Maidenhead",
"441869", "Bicester",
"441446", "Barry",
"4419757", "Strathdon",
"4415074", "Alford\ \(Lincs\)",
"441668", "Bamburgh",
"441246", "Chesterfield",
"441829", "Tarporley",
"441758", "Pwllheli",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"4418512", "Stornoway",
"441263", "Cromer",
"441242", "Cheltenham",
"441425", "Ringwood",
"441234", "Bedford",
"441594", "Lydney",
"4414305", "North\ Cave",
"441786", "Stirling",
"441387", "Dumfries",
"441394", "Felixstowe",
"4416860", "Newtown\/Llanidloes",
"441692", "North\ Walsham",
"442837", "Armagh",
"441782", "Stoke\-on\-Trent",
"441931", "Shap",
"441652", "Brigg",
"441766", "Porthmadog",
"4414235", "Harrogate",
"441354", "Chatteris",
"442879", "Magherafelt",
"441367", "Faringdon",
"4416863", "Llanidloes",
"4413399", "Ballater",
"441554", "Llanelli",
"441567", "Killin",
"441743", "Shrewsbury",
"441656", "Bridgend",
"441745", "Rhyl",
"441838", "Dalmally",
"441807", "Ballindalloch",
"441925", "Warrington",
"441923", "Watford",
"442893", "Ballyclare",
"441214", "Birmingham",
"442895", "Belfast",
"441770", "Isle\ of\ Arran",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441771", "Maud",
"441202", "Bournemouth",
"4413397", "Ballater",
"4417683", "Appleby",
"44147985", "Dulnain\ Bridge",
"441206", "Colchester",
"4418902", "Coldstream",
"4418475", "Thurso",
"441283", "Burton\-on\-Trent",
"441431", "Helmsdale",
"441910", "Tyneside\/Durham\/Sunderland",
"4415076", "Louth",
"441798", "Pulborough",
"441911", "Tyneside\/Durham\/Sunderland",
"441285", "Cirencester",
"441581", "New\ Luce",
"441840", "Camelford",
"441493", "Great\ Yarmouth",
"441580", "Cranbrook",
"441841", "Newquay\ \(Padstow\)",
"441495", "Pontypool",
"441381", "Fortrose",
"441380", "Devizes",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441899", "Biggar",
"441908", "Milton\ Keynes",
"441937", "Wetherby",
"44292", "Cardiff",
"442830", "Newry",
"44117", "Bristol",
"441626", "Newton\ Abbot",
"441479", "Grantown\-on\-Spey",
"4414343", "Haltwhistle",
"441953", "Wymondham",
"441955", "Wick",
"441875", "Tranent",
"441324", "Falkirk",
"441622", "Maidstone",
"441873", "Abergavenny",
"441524", "Lancaster",
"4415078", "Alford\ \(Lincs\)",
"441995", "Garstang",
"441576", "Lockerbie",
"441993", "Witney",
"441777", "Retford",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441376", "Braintree",
"441917", "Sunderland",
"441572", "Oakham",
"441408", "Golspie",
"441372", "Esher",
"441674", "Montrose",
"4412299", "Millom",
"441561", "Laurencekirk",
"441560", "Moscow",
"441728", "Saxmundham",
"441455", "Hinckley",
"441361", "Duns",
"441948", "Whitchurch",
"441360", "Killearn",
"441453", "Dursley",
"4412297", "Millom",
"442825", "Ballymena",
"441859", "Harris",
"441732", "Sevenoaks",
"442887", "Dungannon",
"441980", "Amesbury",
"441476", "Grantham",
"441981", "Wormbridge",
"441215", "Birmingham",
"4418519", "Great\ Bernera",
"442894", "Antrim",
"441629", "Matlock",
"441213", "Birmingham",
"441308", "Bridport",
"441337", "Ladybank",
"4419756", "Strathdon",
"441736", "Penzance",
"441284", "Bury\ St\ Edmunds",
"441508", "Brooke",
"441297", "Axminster",
"441472", "Grimsby",
"441553", "Kings\ Lynn",
"441555", "Lanark",
"4418517", "Stornoway",
"441647", "Moretonhampstead",
"441353", "Ely",
"441892", "Tunbridge\ Wells",
"441355", "East\ Kilbride",
"441461", "Gretna",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441460", "Chard",
"441924", "Wakefield",
"441744", "St\ Helens",
"441896", "Galashiels",
"441395", "Budleigh\ Salterton",
"441852", "Kilmelford",
"441704", "Southport",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441235", "Abingdon",
"4418907", "Ayton",
"441481", "Guernsey",
"441593", "Lybster",
"441233", "Ashford\ \(Kent\)",
"441480", "Huntingdon",
"441856", "Orkney",
"441638", "Newmarket",
"4413392", "Aboyne",
"441972", "Glenborrodale",
"441888", "Turriff",
"4418909", "Ayton",
"442867", "Lisnaskea",
"441379", "Diss",
"441548", "Kingsbridge",
"441579", "Liskeard",
"441348", "Fishguard",
"4419754", "Alford\ \(Aberdeen\)",
"441424", "Hastings",
"441257", "Coppull",
"441264", "Andover",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441227", "Canterbury",
"441454", "Chipping\ Sodbury",
"441467", "Inverurie",
"441641", "Strathy",
"441789", "Stratford\-upon\-Avon",
"44239", "Portsmouth",
"441987", "Ebbsfleet",
"441249", "Chippenham",
"441994", "St\ Clears",
"442881", "Newtownstewart",
"442880", "Carrickmore",
"441278", "Bridgwater",
"441673", "Market\ Rasen",
"441822", "Tavistock",
"441675", "Coleshill",
"441530", "Coalville",
"441290", "Cumnock",
"441291", "Chepstow",
"441531", "Ledbury",
"4419643", "Patrington",
"441330", "Banchory",
"441967", "Strontian",
"441954", "Madingley",
"4412292", "Barrow\-in\-Furness",
"441525", "Leighton\ Buzzard",
"4419758", "Strathdon",
"441325", "Darlington",
"441250", "Blairgowrie",
"4419640", "Hornsea\/Patrington",
"441874", "Brecon",
"441209", "Redruth",
"441323", "Eastbourne",
"441487", "Warboys",
"441769", "South\ Molton",
"441494", "High\ Wycombe",
"441659", "Sanquhar",
"441600", "Monmouth",
"441636", "Newark\-on\-Trent",
"441858", "Market\ Harborough",
"442897", "Saintfield",
"441334", "St\ Andrews",
"441949", "Whatton",
"441287", "Guisborough",
"441294", "Ardrossan",
"441534", "Jersey",
"4412296", "Barrow\-in\-Furness",
"441729", "Settle",
"441978", "Wrexham",
"441563", "Kilmarnock",
"441542", "Keith",
"441565", "Knutsford",
"441882", "Kinloch\ Rannoch",
"441409", "Holsworthy",
"441644", "New\ Galloway",
"441363", "Crediton",
"441342", "East\ Grinstead",
"441450", "Hawick",
"441451", "Stow\-on\-the\-Wold",
"44241", "Coventry",
"441546", "Lochgilphead",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"442820", "Ballycastle",
"441346", "Fraserburgh",
"442821", "Martinstown",
"441803", "Torquay",
"441747", "Shaftesbury",
"441805", "Torrington",
"441843", "Thanet",
"441490", "Corwen",
"441306", "Dorking",
"441583", "Carradale",
"441491", "Henley\-on\-Thames",
"441845", "Thirsk",
"441862", "Tain",
"441738", "Perth",
"441707", "Welwyn\ Garden\ City",
"441506", "Bathgate",
"441383", "Dunfermline",
"4413398", "Aboyne",
"4420", "London",
"441604", "Northampton",
"441449", "Stowmarket",
"441866", "Kilchrenan",
"441302", "Doncaster",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441502", "Lowestoft",
"4412294", "Barrow\-in\-Furness",
"441951", "Colonsay",
"441950", "Sandwick",
"441909", "Worksop",
"4416974", "Raughton\ Head",
"441427", "Gainsborough",
"441870", "Isle\ of\ Benbecula",
"441254", "Blackburn",
"44291", "Cardiff",
"4412291", "Barrow\-in\-Furness\/Millom",
"441267", "Carmarthen",
"441871", "Castlebay",
"441224", "Aberdeen",
"44238", "Southampton",
"441457", "Glossop",
"441799", "Saffron\ Walden",
"441464", "Insch",
"4415396", "Sedbergh",
"4413396", "Ballater",
"441740", "Sedgefield",
"4413882", "Stanhope\ \(Eastgate\)",
"4415077", "Louth",
"442827", "Ballymoney",
"441689", "Orpington",
"441920", "Ware",
"4419645", "Hornsea",
"441775", "Spalding",
"442890", "Belfast",
"442891", "Bangor\ \(Co\.\ Down\)",
"441773", "Ripley",
"441984", "Watchet\ \(Williton\)",
"441997", "Strathpeffer",
"4415079", "Alford\ \(Lincs\)",
"441915", "Sunderland",
"441433", "Hathersage",
"441280", "Buckingham",
"441435", "Heathfield",
"441913", "Durham",
"4419752", "Alford\ \(Aberdeen\)",
"441957", "Mid\ Yell",
"441420", "Alton",
"441877", "Callander",
"441261", "Banff",
"441260", "Congleton",
"4412298", "Barrow\-in\-Furness",
"441484", "Huddersfield",
"4413391", "Aboyne\/Ballater",
"441700", "Rothesay",
"441497", "Hay\-on\-Wye",
"441759", "Pocklington",
"4413394", "Ballater",
"441828", "Coupar\ Angus",
"441669", "Rothbury",
"441935", "Yeovil",
"441276", "Camberley",
"4415394", "Hawkshead",
"441933", "Wellingborough",};

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