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
our $VERSION = 1.20220305001842;

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
$areanames{en} = {"441778", "Bourne",
"4412180", "Birmingham",
"441728", "Saxmundham",
"441864", "Abington\ \(Crawford\)",
"441397", "Fort\ William",
"4414302", "North\ Cave",
"441992", "Lea\ Valley",
"4419756", "Strathdon",
"441782", "Stoke\-on\-Trent",
"441879", "Scarinish",
"441829", "Tarporley",
"441494", "High\ Wycombe",
"441871", "Castlebay",
"44147983", "Boat\ of\ Garten",
"441821", "Kinrossie",
"441529", "Sleaford",
"441579", "Liskeard",
"442887", "Dungannon",
"441284", "Bury\ St\ Edmunds",
"441455", "Hinckley",
"441912", "Tyneside",
"4414307", "Market\ Weighton",
"441790", "Spilsby",
"441571", "Lochinver",
"441564", "Lapworth",
"4414346", "Hexham",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441980", "Amesbury",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441563", "Kilmarnock",
"441328", "Fakenham",
"441431", "Helmsdale",
"441797", "Rye",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"4414377", "Haverfordwest",
"441689", "Orpington",
"441439", "Helmsley",
"442880", "Carrickmore",
"441382", "Dundee",
"4414305", "North\ Cave",
"441296", "Aylesbury",
"441283", "Burton\-on\-Trent",
"441987", "Ebbsfleet",
"4414303", "North\ Cave",
"441852", "Kilmelford",
"44147984", "Carrbridge",
"4418476", "Tongue",
"441636", "Newark\-on\-Trent",
"441493", "Great\ Yarmouth",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441908", "Milton\ Keynes",
"442892", "Lisburn",
"441863", "Ardgay",
"441216", "Birmingham",
"4418901", "Coldstream\/Ayton",
"441495", "Pontypool",
"4416868", "Newtown",
"4417684", "Pooley\ Bridge",
"4413885", "Stanhope\ \(Eastgate\)",
"441963", "Wincanton",
"441267", "Carmarthen",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441750", "Selkirk",
"441709", "Rotherham",
"442879", "Magherafelt",
"442829", "Kilrea",
"441766", "Porthmadog",
"441620", "North\ Berwick",
"441670", "Morpeth",
"441865", "Oxford",
"441808", "Tomatin",
"442871", "Londonderry",
"442821", "Martinstown",
"441249", "Chippenham",
"441887", "Aberfeldy",
"441952", "Telford",
"441565", "Knutsford",
"441357", "Strathaven",
"44115", "Nottingham",
"441508", "Brooke",
"441241", "Arbroath",
"4418474", "Thurso",
"441285", "Cirencester",
"441454", "Chipping\ Sodbury",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441698", "Motherwell",
"441643", "Minehead",
"441592", "Kirkcaldy",
"442310", "Portsmouth",
"441142", "Sheffield",
"441453", "Dursley",
"441301", "Arrochar",
"441350", "Dunkeld",
"441309", "Forres",
"441880", "Tarbert",
"441644", "New\ Galloway",
"441366", "Downham\ Market",
"4413882", "Stanhope\ \(Eastgate\)",
"4414344", "Bellingham",
"4418470", "Thurso\/Tongue",
"441462", "Hitchin",
"441929", "Wareham",
"4419754", "Alford\ \(Aberdeen\)",
"441757", "Selby",
"441971", "Scourie",
"441260", "Congleton",
"441256", "Basingstoke",
"441892", "Tunbridge\ Wells",
"441677", "Bedale",
"441580", "Cranbrook",
"441496", "Port\ Ellen",
"441483", "Guildford",
"442828", "Larne",
"441633", "Newport",
"441809", "Tomdoun",
"441380", "Devizes",
"441765", "Ripon",
"442882", "Omagh",
"441866", "Kilchrenan",
"441708", "Romford",
"4418513", "Stornoway",
"441239", "Cardigan",
"4418515", "Stornoway",
"441917", "Sunderland",
"441213", "Birmingham",
"4415072", "Spilsby\ \(Horncastle\)",
"4416866", "Newtown",
"4419641", "Hornsea\/Patrington",
"441691", "Oswestry",
"441566", "Launceston",
"4412299", "Millom",
"441787", "Sudbury",
"442890", "Belfast",
"441293", "Crawley",
"441997", "Strathpeffer",
"441286", "Caernarfon",
"4415077", "Louth",
"441248", "Bangor\ \(Gwynedd\)",
"441392", "Exeter",
"441501", "Harthill",
"441509", "Loughborough",
"441550", "Llandovery",
"441294", "Ardrossan",
"442897", "Saintfield",
"4418512", "Stornoway",
"441780", "Stamford",
"4415075", "Spilsby\ \(Horncastle\)",
"4415073", "Louth",
"441557", "Kirkcudbright",
"441308", "Bridport",
"44247", "Coventry",
"4416973", "Wigton",
"441857", "Sanday",
"441982", "Builth\ Wells",
"4418517", "Stornoway",
"441387", "Dumfries",
"44118", "Reading",
"441214", "Birmingham",
"441910", "Tyneside\/Durham\/Sunderland",
"441255", "Clacton\-on\-Sea",
"441978", "Wrexham",
"441928", "Runcorn",
"441484", "Huddersfield",
"441792", "Swansea",
"441634", "Medway",
"441764", "Crieff",
"441651", "Oldmeldrum",
"441878", "Lochboisdale",
"441828", "Coupar\ Angus",
"441659", "Sanquhar",
"441600", "Monmouth",
"4414348", "Hexham",
"441352", "Mold",
"442866", "Enniskillen",
"441957", "Mid\ Yell",
"441779", "Peterhead",
"441729", "Settle",
"4414232", "Harrogate",
"441253", "Blackpool",
"441882", "Kinloch\ Rannoch",
"441140", "Sheffield",
"441721", "Peebles",
"441771", "Maud",
"441590", "Lymington",
"441582", "Luton",
"441456", "Glenurquhart",
"4416860", "Newtown\/Llanidloes",
"4419758", "Strathdon",
"441262", "Bridlington",
"441363", "Crediton",
"441528", "Laggan",
"441578", "Lauder",
"4414237", "Harrogate",
"441460", "Chard",
"441364", "Ashburton",
"4414235", "Harrogate",
"4414233", "Boroughbridge",
"4416864", "Llanidloes",
"4419467", "Gosforth",
"441622", "Maidstone",
"441672", "Marlborough",
"441467", "Inverurie",
"441752", "Plymouth",
"441295", "Banbury",
"441379", "Diss",
"441329", "Fareham",
"441438", "Stevenage",
"441371", "Great\ Dunmow",
"441646", "Milford\ Haven",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441635", "Newbury",
"441254", "Blackburn",
"441485", "Hunstanton",
"4413399", "Ballater",
"441763", "Royston",
"441449", "Stowmarket",
"441597", "Llandrindod\ Wells",
"441215", "Birmingham",
"441950", "Sandwick",
"4418478", "Thurso",
"441909", "Worksop",
"441534", "Jersey",
"4418907", "Ayton",
"441744", "St\ Helens",
"441702", "Southend\-on\-Sea",
"441320", "Fort\ Augustus",
"441473", "Ipswich",
"441204", "Bolton",
"4418902", "Coldstream",
"441226", "Barnsley",
"441276", "Camberley",
"4413398", "Aboyne",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441951", "Colonsay",
"441440", "Haverhill",
"441834", "Narberth",
"441900", "Workington",
"441343", "Elgin",
"441398", "Dulverton",
"441242", "Cheltenham",
"441959", "Westerham",
"4418479", "Tongue",
"441777", "Retford",
"441727", "St\ Albans",
"441833", "Barnard\ Castle",
"441344", "Bracknell",
"441609", "Northallerton",
"441650", "Cemmaes\ Road",
"441141", "Sheffield",
"441302", "Doncaster",
"441770", "Isle\ of\ Arran",
"441720", "Isles\ of\ Scilly",
"441591", "Llanwrtyd\ Wells",
"441935", "Yeovil",
"441666", "Malmesbury",
"4414349", "Bellingham",
"4414301", "North\ Cave\/Market\ Weighton",
"441599", "Kyle",
"441406", "Holbeach",
"4419759", "Alford\ \(Aberdeen\)",
"441988", "Wigtown",
"441424", "Hastings",
"441474", "Gravesend",
"441899", "Biggar",
"441946", "Whitehaven",
"44117", "Bristol",
"441461", "Gretna",
"4418903", "Coldstream",
"4418905", "Ayton",
"4415396", "Sedbergh",
"441743", "Shrewsbury",
"441972", "Glenborrodale",
"441922", "Walsall",
"441469", "Killingholme",
"441798", "Pulborough",
"441327", "Daventry",
"441377", "Driffield",
"441697", "Brampton",
"441789", "Stratford\-upon\-Avon",
"441872", "Truro",
"441822", "Tavistock",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441535", "Keighley",
"4415394", "Hawkshead",
"441358", "Ellon",
"441745", "Rhyl",
"441888", "Turriff",
"441835", "St\ Boswells",
"441807", "Ballindalloch",
"441736", "Penzance",
"441546", "Lochgilphead",
"441588", "Bishops\ Castle",
"441933", "Wellingborough",
"441237", "Bideford",
"441205", "Boston",
"441919", "Durham",
"441911", "Tyneside\/Durham\/Sunderland",
"441268", "Basildon",
"4413873", "Langholm",
"441522", "Lincoln",
"441572", "Oakham",
"441934", "Weston\-super\-Mare",
"441381", "Fortrose",
"441678", "Bala",
"441628", "Maidenhead",
"441859", "Harris",
"441389", "Dumbarton",
"441432", "Hereford",
"441758", "Pwllheli",
"4412298", "Barrow\-in\-Furness",
"442891", "Bangor\ \(Co\.\ Down\)",
"441690", "Betws\-y\-Coed",
"441559", "Llandysul",
"441425", "Ringwood",
"441475", "Greenock",
"441403", "Horsham",
"441772", "Preston",
"441722", "Salisbury",
"442311", "Southampton",
"44241", "Coventry",
"441889", "Rugeley",
"441943", "Guiseley",
"4413390", "Aboyne\/Ballater",
"441300", "Cerne\ Abbas",
"442844", "Downpatrick",
"441359", "Pakenham",
"441536", "Kettering",
"4418511", "Great\ Bernera\/Stornoway",
"441652", "Brigg",
"441788", "Rugby",
"441845", "Thirsk",
"441746", "Bridgnorth",
"441970", "Aberystwyth",
"441920", "Ware",
"441261", "Banff",
"441918", "Tyneside",
"441707", "Welwyn\ Garden\ City",
"4419645", "Hornsea",
"441545", "Llanarth",
"4419643", "Patrington",
"441269", "Ammanford",
"441206", "Colchester",
"441663", "New\ Mills",
"441581", "New\ Luce",
"442827", "Ballymoney",
"442877", "Limavady",
"441224", "Aberdeen",
"441274", "Bradford",
"441664", "Melton\ Mowbray",
"4412296", "Barrow\-in\-Furness",
"441751", "Pickering",
"4416869", "Newtown",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441322", "Dartford",
"441372", "Esher",
"441700", "Rothesay",
"441273", "Brighton",
"441977", "Pontefract",
"441759", "Pocklington",
"441223", "Cambridge",
"441629", "Matlock",
"442870", "Coleraine",
"4419647", "Patrington",
"442820", "Ballycastle",
"441388", "Bishop\ Auckland",
"441671", "Newton\ Stewart",
"441621", "Maldon",
"441346", "Fraserburgh",
"441858", "Market\ Harborough",
"441902", "Wolverhampton",
"4413394", "Ballater",
"441335", "Ashbourne",
"441307", "Forfar",
"441442", "Hemel\ Hempstead",
"441558", "Llandeilo",
"441404", "Honiton",
"442898", "Belfast",
"4419642", "Hornsea",
"441944", "West\ Heslerton",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441476", "Grantham",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"442881", "Newtownstewart",
"442889", "Fivemiletown",
"44141", "Glasgow",
"441577", "Kinross",
"441527", "Redditch",
"4413396", "Ballater",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441844", "Thame",
"441502", "Lowestoft",
"4412294", "Barrow\-in\-Furness",
"441225", "Bath",
"441275", "Clevedon",
"441692", "North\ Walsham",
"441827", "Tamworth",
"441877", "Callander",
"441544", "Kington",
"441733", "Peterborough",
"4412290", "Barrow\-in\-Furness\/Millom",
"441598", "Lynton",
"4414231", "Harrogate\/Boroughbridge",
"441543", "Cannock",
"441870", "Isle\ of\ Benbecula",
"441665", "Alnwick",
"441608", "Chipping\ Norton",
"441687", "Mallaig",
"441570", "Lampeter",
"441520", "Lochcarron",
"441405", "Goole",
"441799", "Saffron\ Walden",
"441945", "Wisbech",
"441981", "Wormbridge",
"441334", "St\ Andrews",
"441989", "Ross\-on\-Wye",
"441843", "Thanet",
"4415074", "Alford\ \(Lincs\)",
"441539", "Kendal",
"441360", "Killearn",
"441995", "Garstang",
"441463", "Inverness",
"441531", "Ledbury",
"441749", "Shepton\ Mallet",
"4416974", "Raughton\ Head",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441848", "Thornhill",
"441785", "Stafford",
"441356", "Brechin",
"441738", "Perth",
"441209", "Redruth",
"4413391", "Aboyne\/Ballater",
"441915", "Sunderland",
"441250", "Blairgowrie",
"441767", "Sandy",
"441143", "Sheffield",
"441452", "Gloucester",
"441593", "Lybster",
"441586", "Campbeltown",
"441548", "Kingsbridge",
"441954", "Madingley",
"4418510", "Great\ Bernera\/Stornoway",
"4414378", "Haverfordwest",
"441603", "Norwich",
"441676", "Meriden",
"441626", "Newton\ Abbot",
"441341", "Barmouth",
"441760", "Swaffham",
"441257", "Coppull",
"441953", "Wymondham",
"441604", "Northampton",
"441349", "Dingwall",
"4414308", "Market\ Weighton",
"441642", "Middlesbrough",
"4418514", "Great\ Bernera",
"441855", "Ballachulish",
"441144", "Sheffield",
"441594", "Lydney",
"441756", "Skipton",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"4414236", "Harrogate",
"44116", "Leicester",
"441367", "Faringdon",
"441555", "Lanark",
"441962", "Winchester",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441479", "Grantown\-on\-Spey",
"441429", "Hartlepool",
"441464", "Insch",
"442895", "Belfast",
"441290", "Cumnock",
"4416863", "Llanidloes",
"4416865", "Newtown",
"4414234", "Boroughbridge",
"441784", "Staines",
"441492", "Colwyn\ Bay",
"441553", "Kings\ Lynn",
"441862", "Tain",
"442886", "Cookstown",
"442893", "Ballyclare",
"441994", "St\ Clears",
"441562", "Kidderminster",
"441210", "Birmingham",
"441955", "Wick",
"441228", "Carlisle",
"441278", "Bridgwater",
"441914", "Tyneside",
"44147982", "Nethy\ Bridge",
"441480", "Huntingdon",
"44161", "Manchester",
"441630", "Market\ Drayton",
"441383", "Dunfermline",
"4418516", "Great\ Bernera",
"441282", "Burnley",
"441913", "Durham",
"441217", "Birmingham",
"441939", "Wem",
"441931", "Shap",
"441384", "Dudley",
"441145", "Sheffield",
"441854", "Ullapool",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441668", "Bamburgh",
"4416862", "Llanidloes",
"441637", "Newquay",
"441487", "Warboys",
"441408", "Golspie",
"4414230", "Harrogate\/Boroughbridge",
"441948", "Whitchurch",
"441465", "Girvan",
"4415076", "Louth",
"4419649", "Hornsea",
"442894", "Antrim",
"441993", "Witney",
"441297", "Axminster",
"4412291", "Barrow\-in\-Furness\/Millom",
"441986", "Bungay",
"4416867", "Llanidloes",
"441796", "Pitlochry",
"441895", "Uxbridge",
"441554", "Llanelli",
"442841", "Rostrevor",
"441354", "Chatteris",
"441884", "Tiverton",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"4414304", "North\ Cave",
"442885", "Ballygawley",
"441457", "Glossop",
"4418518", "Stornoway",
"441673", "Market\ Rasen",
"442838", "Portadown",
"441623", "Mansfield",
"441264", "Andover",
"442867", "Lisnaskea",
"441271", "Barnstaple",
"441395", "Budleigh\ Salterton",
"441753", "Slough",
"441279", "Bishops\ Stortford",
"441584", "Ludlow",
"441669", "Rothbury",
"4415078", "Alford\ \(Lincs\)",
"441661", "Prudhoe",
"441754", "Skegness",
"441583", "Carradale",
"441938", "Welshpool",
"441624", "Isle\ of\ Man",
"441674", "Montrose",
"441606", "Northwich",
"441263", "Cromer",
"441967", "Strontian",
"441362", "Dereham",
"441647", "Moretonhampstead",
"441466", "Huntly",
"441985", "Warminster",
"441450", "Hawick",
"4414300", "North\ Cave\/Market\ Weighton",
"441409", "Holsworthy",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441795", "Sittingbourne",
"441353", "Ely",
"441949", "Whatton",
"441896", "Galashiels",
"441883", "Caterham",
"441252", "Aldershot",
"4418477", "Tongue",
"441841", "Newquay\ \(Padstow\)",
"441287", "Guisborough",
"441983", "Isle\ of\ Wight",
"4414345", "Haltwhistle",
"441538", "Ipstones",
"4414343", "Haltwhistle",
"441885", "Pencombe",
"441748", "Richmond",
"441567", "Killin",
"441793", "Swindon",
"441355", "East\ Kilbride",
"441786", "Stirling",
"4414376", "Haverfordwest",
"441916", "Tyneside",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441838", "Dalmally",
"4419753", "Strathdon",
"4415242", "Hornby",
"4419755", "Alford\ \(Aberdeen\)",
"4418472", "Thurso",
"441394", "Felixstowe",
"4418909", "Ayton",
"441208", "Bodmin",
"4417687", "Keswick",
"441497", "Hay\-on\-Wye",
"441549", "Lairg",
"4414238", "Harrogate",
"441625", "Macclesfield",
"441675", "Coleshill",
"4414342", "Bellingham",
"4417683", "Appleby",
"44292", "Cardiff",
"4419757", "Strathdon",
"441490", "Corwen",
"441856", "Orkney",
"441348", "Fishguard",
"441292", "Ayr",
"441386", "Evesham",
"441280", "Buckingham",
"441482", "Kingston\-upon\-Hull",
"4414347", "Hexham",
"441556", "Castle\ Douglas",
"441794", "Romsey",
"441560", "Moscow",
"4414306", "Market\ Weighton",
"441212", "Birmingham",
"441984", "Watchet\ \(Williton\)",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441428", "Haslemere",
"4419752", "Alford\ \(Aberdeen\)",
"4418475", "Thurso",
"4418473", "Thurso",
"442896", "Belfast",
"442825", "Ballymena",
"441869", "Bicester",
"4414239", "Boroughbridge",
"441236", "Coatbridge",
"4419640", "Hornsea\/Patrington",
"441547", "Knighton",
"441499", "Inveraray",
"441874", "Brecon",
"441824", "Ruthin",
"441768", "Penrith",
"441806", "Shetland",
"441737", "Redhill",
"441491", "Henley\-on\-Thames",
"441289", "Berwick\-upon\-Tweed",
"441524", "Lancaster",
"4413393", "Aboyne",
"4413395", "Aboyne",
"441506", "Bathgate",
"44131", "Edinburgh",
"441330", "Banchory",
"441245", "Chelmsford",
"441569", "Stonehaven",
"441561", "Laurencekirk",
"441433", "Hathersage",
"441683", "Moffat",
"441684", "Malvern",
"441840", "Camelford",
"44113", "Leeds",
"4413397", "Ballater",
"441573", "Kelso",
"441368", "Dunbar",
"441932", "Weybridge",
"441337", "Ladybank",
"441305", "Dorchester",
"441823", "Taunton",
"441873", "Abergavenny",
"4419644", "Patrington",
"441730", "Petersfield",
"4418908", "Coldstream",
"441925", "Warrington",
"441258", "Blandford",
"4413392", "Aboyne",
"441540", "Kingussie",
"441825", "Uckfield",
"441875", "Tranent",
"441726", "St\ Austell",
"441776", "Stranraer",
"441704", "Southport",
"4415079", "Alford\ \(Lincs\)",
"4416861", "Newtown\/Llanidloes",
"4419646", "Patrington",
"441227", "Canterbury",
"44147981", "Aviemore",
"441277", "Brentwood",
"441923", "Watford",
"441656", "Bridgend",
"4412297", "Millom",
"44239", "Portsmouth",
"441244", "Chester",
"4420", "London",
"441832", "Clopton",
"441525", "Leighton\ Buzzard",
"441575", "Kirriemuir",
"441400", "Honington",
"4412292", "Barrow\-in\-Furness",
"441303", "Folkestone",
"441451", "Stow\-on\-the\-Wold",
"441202", "Bournemouth",
"441376", "Braintree",
"441326", "Falmouth",
"441641", "Strathy",
"441304", "Dover",
"442840", "Banbridge",
"441298", "Buxton",
"441342", "East\ Grinstead",
"441243", "Chichester",
"441947", "Whitby",
"4418519", "Great\ Bernera",
"441685", "Merthyr\ Tydfil",
"441435", "Heathfield",
"441407", "Holyhead",
"441488", "Hungerford",
"441974", "Llanon",
"441924", "Wakefield",
"441446", "Barry",
"4412295", "Barrow\-in\-Furness",
"4412293", "Millom",
"441638", "Newmarket",
"441667", "Nairn",
"441472", "Grimsby",
"441422", "Halifax",
"44147986", "Cairngorm",
"441969", "Leyburn",
"441270", "Crewe",
"441876", "Lochmaddy",
"441725", "Rockbourne",
"441775", "Spalding",
"442868", "Kesh",
"441842", "Thetford",
"441655", "Maybole",
"442837", "Armagh",
"441234", "Bedford",
"441458", "Glastonbury",
"441542", "Keith",
"441732", "Sevenoaks",
"441694", "Church\ Stretton",
"4419648", "Hornsea",
"441576", "Lockerbie",
"441526", "Martin",
"4418904", "Coldstream",
"441325", "Darlington",
"441375", "Grays\ Thurrock",
"441299", "Bewdley",
"441291", "Chepstow",
"441503", "Looe",
"4418900", "Coldstream\/Ayton",
"441436", "Helensburgh",
"441211", "Birmingham",
"441968", "Penicuik",
"441445", "Gairloch",
"441332", "Derby",
"441937", "Wetherby",
"441233", "Ashford\ \(Kent\)",
"441905", "Worcester",
"441639", "Neath",
"441489", "Bishops\ Waltham",
"442830", "Newry",
"44281", "Northern\ Ireland",
"44147985", "Dulnain\ Bridge",
"441481", "Guernsey",
"441631", "Oban",
"441803", "Torquay",
"441443", "Pontypridd",
"44291", "Cardiff",
"441769", "South\ Molton",
"441235", "Abingdon",
"441340", "Craigellachie\ \(Aberlour\)",
"441207", "Consett",
"441903", "Worthing",
"441761", "Temple\ Cloud",
"441654", "Machynlleth",
"441724", "Scunthorpe",
"442842", "Kircubbin",
"4414309", "Market\ Weighton",
"441837", "Okehampton",
"441805", "Torrington",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441706", "Rochdale",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441323", "Eastbourne",
"441373", "Frome",
"441568", "Leominster",
"441747", "Shaftesbury",
"441420", "Alton",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441505", "Johnstone",
"441246", "Chesterfield",
"441288", "Bude",
"441695", "Skelmersdale",
"441369", "Dunoon",
"441477", "Holmes\ Chapel",
"441427", "Gainsborough",
"44151", "Liverpool",
"441530", "Coalville",
"441740", "Sedgefield",
"441361", "Duns",
"4418906", "Ayton",
"441324", "Falkirk",
"4415395", "Grange\-over\-Sands",
"441306", "Dorking",
"441942", "Wigan",
"441723", "Scarborough",
"441773", "Ripley",
"441259", "Alloa",
"441347", "Easingwold",
"441200", "Clitheroe",
"441444", "Haywards\ Heath",
"441830", "Kirkwhelpington",
"441926", "Warwick",
"4418471", "Thurso\/Tongue",
"44238", "Southampton",
"441904", "York",
"4414379", "Haverfordwest",
"441653", "Malton",};

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