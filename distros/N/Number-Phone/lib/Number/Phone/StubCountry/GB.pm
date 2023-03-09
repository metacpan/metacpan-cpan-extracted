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
our $VERSION = 1.20230307181420;

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
$areanames{en} = {"441727", "St\ Albans",
"441495", "Pontypool",
"441400", "Honington",
"441323", "Eastbourne",
"441968", "Penicuik",
"4420", "London",
"442841", "Rostrevor",
"441340", "Craigellachie\ \(Aberlour\)",
"4413397", "Ballater",
"4414231", "Harrogate\/Boroughbridge",
"441775", "Spalding",
"4414379", "Haverfordwest",
"441748", "Richmond",
"441646", "Milford\ Haven",
"441922", "Walsall",
"442823", "Northern\ Ireland",
"4416869", "Newtown",
"441341", "Barmouth",
"442840", "Banbridge",
"441807", "Ballindalloch",
"4415073", "Louth",
"441429", "Hartlepool",
"441546", "Lochgilphead",
"4418471", "Thurso\/Tongue",
"441650", "Cemmaes\ Road",
"441624", "Isle\ of\ Man",
"441461", "Gretna",
"441476", "Grantham",
"441290", "Cumnock",
"4412294", "Barrow\-in\-Furness",
"441598", "Lynton",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441205", "Boston",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441842", "Thetford",
"441580", "Cranbrook",
"441288", "Bude",
"441698", "Motherwell",
"441258", "Blandford",
"441796", "Pitlochry",
"441550", "Llandovery",
"442886", "Cookstown",
"441524", "Lancaster",
"441291", "Chepstow",
"441985", "Warminster",
"441460", "Chard",
"441651", "Oldmeldrum",
"441915", "Sunderland",
"44113", "Leeds",
"441955", "Wick",
"441934", "Weston\-super\-Mare",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"4413390", "Aboyne\/Ballater",
"441581", "New\ Luce",
"441356", "Brechin",
"441239", "Cardigan",
"441386", "Evesham",
"441908", "Milton\ Keynes",
"4418513", "Stornoway",
"44292", "Cardiff",
"441969", "Leyburn",
"4418519", "Great\ Bernera",
"4418907", "Ayton",
"44151", "Liverpool",
"44161", "Manchester",
"441841", "Newquay\ \(Padstow\)",
"441264", "Andover",
"441307", "Forfar",
"441462", "Hitchin",
"441823", "Taunton",
"4414346", "Hexham",
"441582", "Luton",
"441428", "Haslemere",
"441840", "Camelford",
"441494", "High\ Wycombe",
"4419758", "Strathdon",
"441292", "Ayr",
"441749", "Shepton\ Mallet",
"441652", "Brigg",
"441943", "Guiseley",
"4415079", "Alford\ \(Lincs\)",
"4415396", "Sedbergh",
"441259", "Alloa",
"4416863", "Llanidloes",
"441531", "Ledbury",
"441273", "Brighton",
"442842", "Kircubbin",
"4418478", "Thurso",
"441289", "Berwick\-upon\-Tweed",
"44118", "Reading",
"441984", "Watchet\ \(Williton\)",
"4419642", "Hornsea",
"441631", "Oban",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441856", "Orkney",
"442867", "Lisnaskea",
"441935", "Yeovil",
"441954", "Madingley",
"44115", "Nottingham",
"441920", "Ware",
"441914", "Tyneside",
"4414302", "North\ Cave",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441599", "Kyle",
"441909", "Worksop",
"4414238", "Harrogate",
"441342", "East\ Grinstead",
"441677", "Bedale",
"441525", "Leighton\ Buzzard",
"441530", "Coalville",
"441763", "Royston",
"441577", "Kinross",
"441625", "Macclesfield",
"441630", "Market\ Drayton",
"4418900", "Coldstream\/Ayton",
"441367", "Faringdon",
"441204", "Bolton",
"441469", "Killingholme",
"441947", "Whitby",
"4415077", "Louth",
"441736", "Penzance",
"441638", "Newmarket",
"441277", "Brentwood",
"441538", "Ipstones",
"441962", "Winchester",
"441225", "Bath",
"4419755", "Alford\ \(Aberdeen\)",
"441604", "Northampton",
"441299", "Bewdley",
"441928", "Runcorn",
"441659", "Sanquhar",
"441673", "Market\ Rasen",
"4413393", "Aboyne",
"441689", "Orpington",
"441896", "Galashiels",
"441767", "Sandy",
"441573", "Kelso",
"4418510", "Great\ Bernera\/Stornoway",
"441363", "Crediton",
"441559", "Llandysul",
"441994", "St\ Clears",
"441592", "Kirkcaldy",
"4414235", "Harrogate",
"441443", "Pontypridd",
"4418909", "Ayton",
"441848", "Thornhill",
"4418517", "Stornoway",
"441435", "Heathfield",
"441454", "Chipping\ Sodbury",
"441420", "Alton",
"441303", "Folkestone",
"441282", "Burnley",
"442849", "Northern\ Ireland",
"441692", "North\ Walsham",
"441484", "Huddersfield",
"441707", "Welwyn\ Garden\ City",
"441252", "Aldershot",
"4414304", "North\ Cave",
"441564", "Lapworth",
"441409", "Holsworthy",
"4419644", "Patrington",
"4418475", "Thurso",
"441827", "Tamworth",
"441349", "Dingwall",
"441875", "Tranent",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"44121", "Birmingham",
"441664", "Melton\ Mowbray",
"441902", "Wolverhampton",
"4416860", "Newtown\/Llanidloes",
"441691", "Oswestry",
"441900", "Workington",
"441539", "Kendal",
"441995", "Garstang",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441639", "Neath",
"441863", "Ardgay",
"441591", "Llanwrtyd\ Wells",
"441224", "Aberdeen",
"441558", "Llandeilo",
"441250", "Blairgowrie",
"441690", "Betws\-y\-Coed",
"441280", "Buckingham",
"441588", "Bishops\ Castle",
"441422", "Halifax",
"442896", "Belfast",
"441786", "Stirling",
"441505", "Johnstone",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441590", "Lymington",
"441756", "Skipton",
"441298", "Buxton",
"441929", "Wareham",
"4418903", "Coldstream",
"441874", "Brecon",
"441665", "Alnwick",
"441246", "Chesterfield",
"441723", "Scarborough",
"441327", "Daventry",
"442848", "Northern\ Ireland",
"441375", "Grays\ Thurrock",
"441565", "Knutsford",
"4413399", "Ballater",
"441740", "Sedgefield",
"441455", "Hinckley",
"4414377", "Haverfordwest",
"441485", "Hunstanton",
"441348", "Fishguard",
"442827", "Ballymoney",
"441408", "Golspie",
"4416867", "Llanidloes",
"441803", "Torquay",
"4412292", "Barrow\-in\-Furness",
"441382", "Dundee",
"441997", "Strathpeffer",
"44281", "Northern\ Ireland",
"441764", "Crieff",
"441352", "Mold",
"4416974", "Raughton\ Head",
"441832", "Clopton",
"441953", "Wymondham",
"441913", "Durham",
"441792", "Swansea",
"441249", "Chippenham",
"4412295", "Barrow\-in\-Furness",
"44131", "Edinburgh",
"442882", "Omagh",
"441983", "Isle\ of\ Wight",
"441274", "Bradford",
"441944", "West\ Heslerton",
"44114", "Sheffield",
"441472", "Grimsby",
"441542", "Keith",
"441330", "Banchory",
"441325", "Darlington",
"441667", "Nairn",
"441493", "Great\ Yarmouth",
"442311", "Southampton",
"441789", "Stratford\-upon\-Avon",
"441824", "Ruthin",
"4414301", "North\ Cave\/Market\ Weighton",
"442899", "Northern\ Ireland",
"441567", "Killin",
"441773", "Ripley",
"441880", "Tarbert",
"441759", "Pocklington",
"441377", "Driffield",
"441642", "Middlesbrough",
"4419641", "Hornsea\/Patrington",
"441926", "Warwick",
"442825", "Ballymena",
"441704", "Southport",
"442830", "Newry",
"441487", "Warboys",
"4413396", "Ballater",
"441536", "Kettering",
"441457", "Glossop",
"441263", "Cromer",
"441738", "Perth",
"442310", "Portsmouth",
"441636", "Newark\-on\-Trent",
"442877", "Limavady",
"441275", "Clevedon",
"441641", "Strathy",
"441406", "Holbeach",
"441945", "Wisbech",
"4414232", "Harrogate",
"44247", "Coventry",
"441933", "Wellingborough",
"441346", "Fraserburgh",
"441227", "Canterbury",
"4414308", "Market\ Weighton",
"441882", "Kinloch\ Rannoch",
"4419648", "Hornsea",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"44238", "Southampton",
"441852", "Kilmelford",
"44283", "Northern\ Ireland",
"442846", "Northern\ Ireland",
"4418472", "Thurso",
"441978", "Wrexham",
"441332", "Derby",
"441623", "Mansfield",
"441765", "Ripon",
"441248", "Bangor\ \(Gwynedd\)",
"441540", "Kingussie",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441296", "Aylesbury",
"441758", "Pwllheli",
"4419752", "Alford\ \(Aberdeen\)",
"441656", "Bridgend",
"441788", "Rugby",
"442898", "Belfast",
"441899", "Biggar",
"441586", "Campbeltown",
"442824", "Northern\ Ireland",
"441790", "Spilsby",
"441556", "Castle\ Douglas",
"442880", "Carrickmore",
"441381", "Fortrose",
"4414347", "Hexham",
"441830", "Kirkwhelpington",
"441466", "Huntly",
"441825", "Uckfield",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441398", "Dulverton",
"441324", "Falkirk",
"441350", "Dunkeld",
"441380", "Devizes",
"442881", "Newtownstewart",
"4418906", "Ayton",
"441877", "Callander",
"4414305", "North\ Cave",
"441388", "Bishop\ Auckland",
"441445", "Gairloch",
"441358", "Ellon",
"4418474", "Thurso",
"4419645", "Hornsea",
"442891", "Bangor\ \(Co\.\ Down\)",
"441305", "Dorchester",
"441433", "Hathersage",
"441751", "Pickering",
"4414349", "Bellingham",
"441838", "Dalmally",
"442888", "Northern\ Ireland",
"441798", "Pulborough",
"441256", "Basingstoke",
"4414234", "Boroughbridge",
"441286", "Caernarfon",
"442890", "Belfast",
"441859", "Harris",
"441780", "Stamford",
"441873", "Abergavenny",
"441750", "Selkirk",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"4418516", "Great\ Bernera",
"441724", "Scunthorpe",
"441889", "Rugeley",
"44239", "Portsmouth",
"441548", "Kingsbridge",
"441970", "Aberystwyth",
"441892", "Tunbridge\ Wells",
"441937", "Wetherby",
"441223", "Cambridge",
"441746", "Bridgnorth",
"441527", "Redditch",
"441675", "Coleshill",
"441241", "Arbroath",
"441864", "Abington\ \(Crawford\)",
"441971", "Scourie",
"441732", "Sevenoaks",
"4417684", "Pooley\ Bridge",
"4412291", "Barrow\-in\-Furness\/Millom",
"4415076", "Louth",
"4419754", "Alford\ \(Aberdeen\)",
"441575", "Kirriemuir",
"4416866", "Newtown",
"4412298", "Barrow\-in\-Furness",
"441497", "Hay\-on\-Wye",
"441725", "Rockbourne",
"441663", "New\ Mills",
"441730", "Petersfield",
"441359", "Pakenham",
"441563", "Kilmarnock",
"441777", "Retford",
"441236", "Coatbridge",
"4414376", "Haverfordwest",
"441389", "Dumbarton",
"442838", "Portadown",
"441373", "Frome",
"441483", "Guildford",
"441479", "Grantown\-on\-Spey",
"441888", "Turriff",
"441453", "Dursley",
"441267", "Carmarthen",
"441304", "Dover",
"441858", "Market\ Harborough",
"441444", "Haywards\ Heath",
"441972", "Glenborrodale",
"441805", "Torrington",
"442889", "Fivemiletown",
"441242", "Cheltenham",
"441799", "Saffron\ Walden",
"441752", "Plymouth",
"441364", "Ashburton",
"441207", "Consett",
"441993", "Witney",
"442892", "Lisburn",
"441782", "Stoke\-on\-Trent",
"441674", "Montrose",
"441865", "Oxford",
"441549", "Lairg",
"441957", "Mid\ Yell",
"441603", "Norwich",
"441917", "Sunderland",
"4414343", "Haltwhistle",
"441392", "Exeter",
"441987", "Ebbsfleet",
"441503", "Looe",
"441474", "Gravesend",
"441728", "Saxmundham",
"441942", "Wigan",
"4418476", "Tongue",
"441626", "Newton\ Abbot",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441309", "Forres",
"4412293", "Millom",
"441967", "Strontian",
"442820", "Ballycastle",
"4419647", "Patrington",
"441449", "Stowmarket",
"441794", "Romsey",
"442884", "Northern\ Ireland",
"441526", "Martin",
"4414307", "Market\ Weighton",
"441855", "Ballachulish",
"441834", "Narberth",
"4414236", "Harrogate",
"441747", "Shaftesbury",
"441885", "Pencombe",
"441343", "Elgin",
"441808", "Tomatin",
"4418514", "Great\ Bernera",
"441403", "Horsham",
"441320", "Fort\ Augustus",
"442821", "Martinstown",
"441335", "Ashbourne",
"441354", "Chatteris",
"441384", "Dudley",
"441597", "Llandrindod\ Wells",
"4418902", "Coldstream",
"441287", "Guisborough",
"441697", "Brampton",
"441702", "Southend\-on\-Sea",
"441463", "Inverness",
"441257", "Coppull",
"441644", "New\ Galloway",
"4419640", "Hornsea\/Patrington",
"4414348", "Hexham",
"441553", "Kings\ Lynn",
"441369", "Dunoon",
"441579", "Liskeard",
"441822", "Tavistock",
"441583", "Carradale",
"4414300", "North\ Cave\/Market\ Weighton",
"4419756", "Strathdon",
"441683", "Moffat",
"441653", "Malton",
"4415074", "Alford\ \(Lincs\)",
"441544", "Kington",
"441293", "Crawley",
"441355", "East\ Kilbride",
"441334", "St\ Andrews",
"441843", "Thanet",
"4416864", "Llanidloes",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441835", "St\ Boswells",
"441854", "Ullapool",
"441308", "Bridport",
"441986", "Bungay",
"441729", "Settle",
"441884", "Tiverton",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441916", "Tyneside",
"441700", "Rothesay",
"441809", "Tomdoun",
"442885", "Ballygawley",
"441795", "Sittingbourne",
"441427", "Gainsborough",
"441475", "Greenock",
"441821", "Kinrossie",
"441206", "Colchester",
"441869", "Bicester",
"441760", "Swaffham",
"441322", "Dartford",
"441633", "Newport",
"441545", "Llanarth",
"441271", "Barnstaple",
"4413392", "Aboyne",
"442868", "Kesh",
"441923", "Watford",
"441776", "Stranraer",
"441237", "Bideford",
"441761", "Temple\ Cloud",
"441678", "Bala",
"442822", "Northern\ Ireland",
"441496", "Port\ Ellen",
"441578", "Lauder",
"441270", "Crewe",
"4412299", "Millom",
"4413882", "Stanhope\ \(Eastgate\)",
"441368", "Dunbar",
"441360", "Killearn",
"441722", "Salisbury",
"441948", "Whitchurch",
"4413873", "Langholm",
"441278", "Bridgwater",
"441570", "Lampeter",
"441637", "Newquay",
"441670", "Morpeth",
"441456", "Glenurquhart",
"441376", "Braintree",
"441361", "Duns",
"4419643", "Patrington",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441233", "Ashford\ \(Kent\)",
"4414303", "North\ Cave",
"441571", "Lochinver",
"441566", "Launceston",
"441245", "Chelmsford",
"441666", "Malmesbury",
"441671", "Newton\ Stewart",
"4416862", "Llanidloes",
"441768", "Penrith",
"4412297", "Millom",
"4419467", "Gosforth",
"441785", "Stafford",
"441506", "Bathgate",
"442895", "Belfast",
"4412290", "Barrow\-in\-Furness\/Millom",
"441301", "Arrochar",
"441329", "Fareham",
"441606", "Northwich",
"441862", "Tain",
"441708", "Romford",
"441395", "Budleigh\ Salterton",
"4413394", "Ballater",
"441300", "Cerne\ Abbas",
"441828", "Coupar\ Angus",
"441440", "Haverhill",
"442829", "Kilrea",
"441593", "Lybster",
"441244", "Chester",
"441876", "Lochmaddy",
"441974", "Llanon",
"44117", "Bristol",
"441442", "Hemel\ Hempstead",
"4418512", "Stornoway",
"441283", "Burton\-on\-Trent",
"441279", "Bishops\ Stortford",
"441302", "Doncaster",
"441467", "Inverurie",
"441253", "Blackpool",
"44280", "Northern\ Ireland",
"441949", "Whatton",
"441557", "Kirkcudbright",
"441436", "Helensburgh",
"4415395", "Grange\-over\-Sands",
"441769", "South\ Molton",
"441687", "Mallaig",
"441297", "Axminster",
"441903", "Worthing",
"4414345", "Haltwhistle",
"441895", "Uxbridge",
"4415072", "Spilsby\ \(Horncastle\)",
"441709", "Rotherham",
"441328", "Fakenham",
"442847", "Northern\ Ireland",
"441394", "Felixstowe",
"4419649", "Hornsea",
"441963", "Wincanton",
"441721", "Peebles",
"4414309", "Market\ Weighton",
"441743", "Shrewsbury",
"441226", "Barnsley",
"441347", "Easingwold",
"441672", "Marlborough",
"442828", "Larne",
"441407", "Holyhead",
"441572", "Oakham",
"442894", "Antrim",
"44286", "Northern\ Ireland",
"441784", "Staines",
"441829", "Tarporley",
"4418904", "Coldstream",
"441754", "Skegness",
"441362", "Dereham",
"441720", "Isles\ of\ Scilly",
"4418470", "Thurso\/Tongue",
"4419757", "Strathdon",
"4417687", "Keswick",
"441980", "Amesbury",
"441465", "Girvan",
"441950", "Sandwick",
"441924", "Wakefield",
"441910", "Tyneside\/Durham\/Sunderland",
"4414342", "Bellingham",
"4415075", "Spilsby\ \(Horncastle\)",
"441608", "Chipping\ Norton",
"441706", "Rochdale",
"4414230", "Harrogate\/Boroughbridge",
"441555", "Lanark",
"441534", "Jersey",
"441655", "Maybole",
"441634", "Medway",
"441981", "Wormbridge",
"441295", "Banbury",
"4418908", "Coldstream",
"441685", "Merthyr\ Tydfil",
"441911", "Tyneside\/Durham\/Sunderland",
"441508", "Brooke",
"441951", "Colonsay",
"441200", "Clitheroe",
"442845", "Northern\ Ireland",
"441439", "Helmsley",
"44291", "Cardiff",
"441668", "Bamburgh",
"441771", "Maud",
"441766", "Porthmadog",
"4416973", "Wigton",
"4413391", "Aboyne\/Ballater",
"4414237", "Harrogate",
"441491", "Henley\-on\-Thames",
"441260", "Congleton",
"4418515", "Stornoway",
"441932", "Weybridge",
"441568", "Leominster",
"441883", "Caterham",
"441522", "Lincoln",
"441488", "Hungerford",
"441879", "Scarinish",
"4419646", "Patrington",
"4414306", "Market\ Weighton",
"441770", "Isle\ of\ Arran",
"441458", "Glastonbury",
"441261", "Banff",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441737", "Redhill",
"441844", "Thame",
"441490", "Corwen",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"4418477", "Tongue",
"441276", "Camberley",
"441946", "Whitehaven",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441622", "Maidstone",
"441405", "Goole",
"441654", "Machynlleth",
"441635", "Newbury",
"441620", "North\ Berwick",
"441543", "Cannock",
"441294", "Ardrossan",
"441492", "Colwyn\ Bay",
"441684", "Malvern",
"441931", "Shap",
"441772", "Preston",
"441584", "Ludlow",
"442826", "Northern\ Ireland",
"441643", "Minehead",
"441554", "Llanelli",
"441535", "Keighley",
"441228", "Carlisle",
"441520", "Lochcarron",
"4413398", "Aboyne",
"441621", "Maldon",
"441464", "Insch",
"441509", "Loughborough",
"441925", "Warrington",
"441262", "Bridlington",
"441326", "Falmouth",
"441977", "Pontefract",
"441609", "Northallerton",
"441379", "Diss",
"441845", "Thirsk",
"441757", "Selby",
"441202", "Bournemouth",
"441383", "Dunfermline",
"4418901", "Coldstream\/Ayton",
"442897", "Saintfield",
"441787", "Sudbury",
"441404", "Honiton",
"441353", "Ely",
"441569", "Stonehaven",
"441669", "Rothbury",
"441344", "Bracknell",
"441833", "Barnard\ Castle",
"441438", "Stevenage",
"441793", "Swindon",
"442883", "Northern\ Ireland",
"441952", "Telford",
"442879", "Magherafelt",
"441912", "Tyneside",
"4416865", "Newtown",
"441397", "Fort\ William",
"441982", "Builth\ Wells",
"442844", "Downpatrick",
"441473", "Ipswich",
"441878", "Lochboisdale",
"441489", "Bishops\ Waltham",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441387", "Dumfries",
"441992", "Lea\ Valley",
"4413395", "Aboyne",
"441870", "Isle\ of\ Benbecula",
"4418511", "Great\ Bernera\/Stornoway",
"441431", "Helmsdale",
"441753", "Slough",
"441779", "Peterhead",
"441357", "Strathaven",
"442893", "Ballyclare",
"441499", "Inveraray",
"441837", "Okehampton",
"441744", "St\ Helens",
"441425", "Ringwood",
"4413885", "Stanhope\ \(Eastgate\)",
"441866", "Kilchrenan",
"441797", "Rye",
"441871", "Castlebay",
"442887", "Dungannon",
"44116", "Leicester",
"441269", "Ammanford",
"4419753", "Strathdon",
"441477", "Holmes\ Chapel",
"441502", "Lowestoft",
"4417683", "Appleby",
"441547", "Knighton",
"44141", "Glasgow",
"441904", "York",
"4418473", "Thurso",
"441806", "Shetland",
"4412296", "Barrow\-in\-Furness",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"4416868", "Newtown",
"44287", "Northern\ Ireland",
"441938", "Welshpool",
"441562", "Kidderminster",
"441209", "Redruth",
"441372", "Esher",
"441647", "Moretonhampstead",
"4414378", "Haverfordwest",
"441528", "Laggan",
"4414233", "Boroughbridge",
"441254", "Blackburn",
"441235", "Abingdon",
"441694", "Church\ Stretton",
"441482", "Kingston\-upon\-Hull",
"441284", "Bury\ St\ Edmunds",
"441452", "Gloucester",
"441989", "Ross\-on\-Wye",
"441594", "Lydney",
"441243", "Chichester",
"441726", "St\ Austell",
"441919", "Durham",
"441628", "Maidenhead",
"441959", "Westerham",
"441371", "Great\ Dunmow",
"442870", "Coleraine",
"441366", "Downham\ Market",
"441576", "Lockerbie",
"441561", "Laurencekirk",
"441450", "Hawick",
"441424", "Hastings",
"441778", "Bourne",
"441661", "Prudhoe",
"4418905", "Ayton",
"441676", "Meriden",
"4414239", "Boroughbridge",
"441480", "Huntingdon",
"442837", "Armagh",
"442866", "Enniskillen",
"4414344", "Bellingham",
"441887", "Aberfeldy",
"4415242", "Hornby",
"442871", "Londonderry",
"441560", "Moscow",
"441268", "Basildon",
"441745", "Rhyl",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441857", "Sanday",
"4418479", "Tongue",
"441451", "Stow\-on\-the\-Wold",
"441733", "Peterborough",
"441337", "Ladybank",
"4415078", "Alford\ \(Lincs\)",
"441481", "Guernsey",
"4416861", "Newtown\/Llanidloes",
"441208", "Bodmin",
"44241", "Coventry",
"4419759", "Alford\ \(Aberdeen\)",
"4415394", "Hawkshead",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441939", "Wem",
"441255", "Clacton\-on\-Sea",
"441234", "Bedford",
"441695", "Skelmersdale",
"441285", "Cirencester",
"441600", "Monmouth",
"441432", "Hereford",
"441918", "Tyneside",
"441629", "Matlock",
"441501", "Harthill",
"441988", "Wigtown",
"441306", "Dorking",
"4418518", "Stornoway",
"441446", "Barry",
"441905", "Worcester",
"441529", "Sleaford",
"441872", "Truro",};

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