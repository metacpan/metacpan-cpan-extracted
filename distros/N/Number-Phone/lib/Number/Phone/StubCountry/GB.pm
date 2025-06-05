# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20250605193635;

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
$areanames{en} = {"441454", "Chipping\ Sodbury",
"441475", "Greenock",
"441656", "Bridgend",
"4415074", "Alford\ \(Lincs\)",
"441268", "Basildon",
"441620", "North\ Berwick",
"441295", "Banbury",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441895", "Uxbridge",
"441672", "Marlborough",
"441569", "Stonehaven",
"441630", "Market\ Drayton",
"441563", "Kilmarnock",
"441916", "Tyneside",
"4413396", "Ballater",
"441997", "Strathpeffer",
"44283", "Northern\ Ireland",
"442311", "Southampton",
"441330", "Banchory",
"441277", "Brentwood",
"442897", "Saintfield",
"441497", "Hay\-on\-Wye",
"441848", "Thornhill",
"441877", "Callander",
"441248", "Bangor\ \(Gwynedd\)",
"4415394", "Hawkshead",
"441305", "Dorchester",
"441372", "Esher",
"441706", "Rochdale",
"4414349", "Bellingham",
"4418908", "Coldstream",
"441543", "Cannock",
"441789", "Stratford\-upon\-Avon",
"4420", "London",
"441501", "Harthill",
"441954", "Madingley",
"441902", "Wolverhampton",
"441388", "Bishop\ Auckland",
"441549", "Lairg",
"441356", "Brechin",
"4418479", "Tongue",
"441320", "Fort\ Augustus",
"441685", "Merthyr\ Tydfil",
"441653", "Malton",
"441824", "Ruthin",
"441522", "Lincoln",
"4412293", "Millom",
"441298", "Buxton",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441865", "Oxford",
"441659", "Sanquhar",
"442847", "Northern\ Ireland",
"441761", "Temple\ Cloud",
"441224", "Aberdeen",
"441737", "Redhill",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"4418510", "Great\ Bernera\/Stornoway",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441482", "Kingston\-upon\-Hull",
"441570", "Lampeter",
"442882", "Omagh",
"441919", "Durham",
"441599", "Kyle",
"441234", "Bedford",
"441727", "St\ Albans",
"441608", "Chipping\ Norton",
"4418515", "Stornoway",
"4413885", "Stanhope\ \(Eastgate\)",
"4414374", "Clynderwen\ \(Clunderwen\)",
"4419755", "Alford\ \(Aberdeen\)",
"4413399", "Ballater",
"441967", "Strontian",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441834", "Narberth",
"4418511", "Great\ Bernera\/Stornoway",
"441931", "Shap",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441566", "Launceston",
"441913", "Durham",
"441593", "Lybster",
"4414303", "North\ Cave",
"442867", "Lisnaskea",
"4416973", "Wigton",
"441467", "Inverurie",
"441845", "Thirsk",
"441431", "Helmsdale",
"441709", "Rotherham",
"441581", "New\ Luce",
"4414346", "Hexham",
"4414232", "Harrogate",
"441982", "Builth\ Wells",
"441308", "Bridport",
"441245", "Chelmsford",
"441546", "Lochgilphead",
"4416867", "Llanidloes",
"441947", "Whitby",
"441359", "Pakenham",
"441758", "Pwllheli",
"442821", "Martinstown",
"4418476", "Tongue",
"441978", "Wrexham",
"441353", "Ely",
"441786", "Stirling",
"442830", "Newry",
"4415077", "Louth",
"441397", "Fort\ William",
"441833", "Barnard\ Castle",
"441914", "Tyneside",
"441594", "Lydney",
"441740", "Sedgefield",
"441239", "Cardigan",
"441892", "Tunbridge\ Wells",
"441580", "Cranbrook",
"441472", "Grimsby",
"441405", "Goole",
"441292", "Ayr",
"441528", "Laggan",
"441233", "Ashford\ \(Kent\)",
"441829", "Tarporley",
"441223", "Cambridge",
"4419648", "Hornsea",
"44114701", "Sheffield",
"441538", "Ipstones",
"441654", "Machynlleth",
"441675", "Coleshill",
"441456", "Glenurquhart",
"441823", "Taunton",
"442820", "Ballycastle",
"441420", "Alton",
"441488", "Hungerford",
"442888", "Northern\ Ireland",
"441920", "Ware",
"441807", "Ballindalloch",
"441557", "Kirkcudbright",
"441302", "Doncaster",
"441988", "Wigtown",
"441375", "Grays\ Thurrock",
"441354", "Chatteris",
"441776", "Stranraer",
"4414342", "Bellingham",
"4414236", "Harrogate",
"441760", "Swaffham",
"441207", "Consett",
"441571", "Lochinver",
"441972", "Glenborrodale",
"441905", "Worcester",
"441704", "Southport",
"441752", "Plymouth",
"4418472", "Thurso",
"44114704", "Sheffield",
"441697", "Brampton",
"441862", "Tain",
"442310", "Portsmouth",
"44113", "Leeds",
"441564", "Lapworth",
"44241", "Coventry",
"441367", "Faringdon",
"44121", "Birmingham",
"441525", "Leighton\ Buzzard",
"441262", "Bridlington",
"441236", "Coatbridge",
"441408", "Golspie",
"441535", "Keighley",
"441647", "Moretonhampstead",
"441226", "Barnsley",
"441250", "Blairgowrie",
"442885", "Ballygawley",
"441453", "Dursley",
"441485", "Hunstanton",
"4414377", "Haverfordwest",
"44114702", "Sheffield",
"441678", "Bala",
"4413392", "Aboyne",
"4414301", "North\ Cave\/Market\ Weighton",
"441953", "Wymondham",
"441985", "Warminster",
"4414305", "North\ Cave",
"441621", "Maldon",
"4418513", "Stornoway",
"441242", "Cheltenham",
"4419753", "Strathdon",
"441784", "Staines",
"441773", "Ripley",
"4412290", "Barrow\-in\-Furness\/Millom",
"441842", "Thetford",
"441544", "Kington",
"441959", "Westerham",
"441790", "Spilsby",
"441347", "Easingwold",
"4414239", "Boroughbridge",
"441779", "Peterhead",
"441887", "Aberfeldy",
"4416864", "Llanidloes",
"4414300", "North\ Cave\/Market\ Weighton",
"441908", "Milton\ Keynes",
"441382", "Dundee",
"441667", "Nairn",
"441631", "Oban",
"44114709", "Sheffield",
"441287", "Guisborough",
"4412291", "Barrow\-in\-Furness\/Millom",
"44291", "Cardiff",
"4412295", "Barrow\-in\-Furness",
"441446", "Barry",
"441644", "New\ Galloway",
"442846", "Northern\ Ireland",
"441335", "Ashbourne",
"441736", "Penzance",
"441922", "Walsall",
"44280", "Northern\ Ireland",
"4414347", "Hexham",
"441300", "Cerne\ Abbas",
"441567", "Killin",
"4416866", "Newtown",
"441531", "Ledbury",
"441932", "Weybridge",
"4417683", "Appleby",
"441993", "Witney",
"441364", "Ashburton",
"441481", "Guernsey",
"442881", "Newtownstewart",
"4418477", "Tongue",
"441970", "Aberystwyth",
"441726", "St\ Austell",
"441750", "Selkirk",
"441325", "Darlington",
"442870", "Coleraine",
"441582", "Luton",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"4415072", "Spilsby\ \(Horncastle\)",
"441625", "Macclesfield",
"441981", "Wormbridge",
"441873", "Abergavenny",
"441884", "Tiverton",
"441290", "Cumnock",
"4418518", "Stornoway",
"441499", "Inveraray",
"442899", "Northern\ Ireland",
"4419758", "Strathdon",
"441279", "Bishops\ Stortford",
"441432", "Hereford",
"441879", "Scarinish",
"442866", "Enniskillen",
"441664", "Melton\ Mowbray",
"44239", "Portsmouth",
"441466", "Huntly",
"442893", "Ballyclare",
"441493", "Great\ Yarmouth",
"441273", "Brighton",
"441284", "Bury\ St\ Edmunds",
"441600", "Monmouth",
"442822", "Northern\ Ireland",
"441422", "Halifax",
"441787", "Sudbury",
"441578", "Lauder",
"441946", "Whitehaven",
"441635", "Newbury",
"441547", "Knighton",
"441344", "Bracknell",
"441840", "Camelford",
"441443", "Pontypridd",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441792", "Swansea",
"441733", "Peterborough",
"4414234", "Boroughbridge",
"442849", "Northern\ Ireland",
"441449", "Stowmarket",
"4418905", "Ayton",
"4418901", "Coldstream\/Ayton",
"441963", "Wincanton",
"441394", "Felixstowe",
"441729", "Settle",
"4419643", "Patrington",
"441917", "Sunderland",
"4416869", "Newtown",
"441597", "Llandrindod\ Wells",
"441671", "Newton\ Stewart",
"441969", "Leyburn",
"441328", "Fakenham",
"4418900", "Coldstream\/Ayton",
"44114703", "Sheffield",
"441380", "Devizes",
"441723", "Scarborough",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"44117", "Bristol",
"441469", "Killingholme",
"441876", "Lochmaddy",
"441628", "Maidenhead",
"441260", "Congleton",
"441371", "Great\ Dunmow",
"441707", "Welwyn\ Garden\ City",
"441463", "Inverness",
"441694", "Church\ Stretton",
"442896", "Belfast",
"441496", "Port\ Ellen",
"441276", "Camberley",
"441575", "Kirriemuir",
"441554", "Llanelli",
"441949", "Whatton",
"441502", "Lowestoft",
"441852", "Kilmelford",
"441357", "Strathaven",
"441943", "Guiseley",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441144", "Sheffield",
"4413397", "Ballater",
"441204", "Bolton",
"441638", "Newmarket",
"441252", "Aldershot",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441925", "Warrington",
"44287", "Northern\ Ireland",
"4412298", "Barrow\-in\-Furness",
"441261", "Banff",
"441724", "Scunthorpe",
"441237", "Bideford",
"441837", "Okehampton",
"4414344", "Bellingham",
"441765", "Ripon",
"441332", "Derby",
"441798", "Pulborough",
"441366", "Downham\ Market",
"441827", "Tamworth",
"441900", "Workington",
"441322", "Dartford",
"4418474", "Thurso",
"441646", "Milford\ Haven",
"442844", "Downpatrick",
"441444", "Haywards\ Heath",
"441935", "Yeovil",
"441227", "Canterbury",
"4414308", "Market\ Weighton",
"441944", "West\ Heslerton",
"441559", "Llandysul",
"441435", "Heathfield",
"441841", "Newquay\ \(Padstow\)",
"441143", "Sheffield",
"441809", "Tomdoun",
"441745", "Rhyl",
"4415079", "Alford\ \(Lincs\)",
"441346", "Fraserburgh",
"441553", "Kings\ Lynn",
"441400", "Honington",
"441622", "Maidstone",
"441803", "Torquay",
"441241", "Arbroath",
"441209", "Redruth",
"441258", "Blandford",
"441464", "Insch",
"441666", "Malmesbury",
"441286", "Caernarfon",
"441670", "Morpeth",
"44118", "Reading",
"441425", "Ringwood",
"442825", "Ballymena",
"4414376", "Haverfordwest",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441858", "Market\ Harborough",
"441381", "Fortrose",
"441508", "Brooke",
"442871", "Londonderry",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"4415242", "Hornby",
"441980", "Amesbury",
"441291", "Chepstow",
"441928", "Runcorn",
"441369", "Dunoon",
"4415396", "Sedbergh",
"4414237", "Harrogate",
"441768", "Penrith",
"441795", "Sittingbourne",
"441363", "Crediton",
"441994", "St\ Clears",
"4416862", "Llanidloes",
"441457", "Glossop",
"441643", "Minehead",
"441938", "Welshpool",
"441146", "Sheffield",
"4415076", "Louth",
"441748", "Richmond",
"441206", "Colchester",
"442838", "Portadown",
"441343", "Elgin",
"441438", "Stevenage",
"4419641", "Hornsea\/Patrington",
"441556", "Castle\ Douglas",
"441957", "Mid\ Yell",
"4419645", "Hornsea",
"441806", "Shetland",
"441520", "Lochcarron",
"441301", "Arrochar",
"441777", "Retford",
"441588", "Bishops\ Castle",
"441349", "Dingwall",
"4418903", "Coldstream",
"441530", "Coalville",
"441889", "Rugeley",
"441663", "New\ Mills",
"441494", "High\ Wycombe",
"442894", "Antrim",
"441283", "Burton\-on\-Trent",
"441255", "Clacton\-on\-Sea",
"441274", "Bradford",
"441480", "Huntingdon",
"441572", "Oakham",
"442880", "Carrickmore",
"441505", "Johnstone",
"441971", "Scourie",
"441669", "Rothbury",
"441883", "Caterham",
"441855", "Ballachulish",
"441874", "Brecon",
"4419640", "Hornsea\/Patrington",
"442828", "Larne",
"441428", "Haslemere",
"4414379", "Haverfordwest",
"4413394", "Ballater",
"441289", "Berwick\-upon\-Tweed",
"441751", "Pickering",
"441591", "Llanwrtyd\ Wells",
"441911", "Tyneside\/Durham\/Sunderland",
"441992", "Lea\ Valley",
"441933", "Wellingborough",
"4414306", "Market\ Weighton",
"44114705", "Sheffield",
"441939", "Wem",
"441677", "Bedale",
"441763", "Royston",
"4412296", "Barrow\-in\-Furness",
"441368", "Dunbar",
"441395", "Budleigh\ Salterton",
"441929", "Wareham",
"441796", "Pitlochry",
"441769", "South\ Molton",
"441651", "Oldmeldrum",
"441923", "Watford",
"441407", "Holyhead",
"441888", "Turriff",
"44115", "Nottingham",
"441506", "Bathgate",
"4417687", "Keswick",
"442823", "Northern\ Ireland",
"441856", "Orkney",
"441695", "Skelmersdale",
"441668", "Bamburgh",
"4414378", "Haverfordwest",
"4418473", "Thurso",
"441256", "Basingstoke",
"441288", "Bude",
"442829", "Kilrea",
"441429", "Hartlepool",
"441749", "Shepton\ Mallet",
"44114708", "Sheffield",
"441377", "Driffield",
"441555", "Lanark",
"441439", "Helmsley",
"441583", "Carradale",
"4413873", "Langholm",
"441805", "Torrington",
"441872", "Truro",
"441492", "Colwyn\ Bay",
"442892", "Lisburn",
"441743", "Shrewsbury",
"441205", "Boston",
"4414343", "Haltwhistle",
"441348", "Fishguard",
"441433", "Hathersage",
"441145", "Sheffield",
"441830", "Kirkwhelpington",
"4418904", "Coldstream",
"441334", "St\ Andrews",
"4414235", "Harrogate",
"441962", "Winchester",
"441561", "Laurencekirk",
"4414231", "Harrogate\/Boroughbridge",
"441722", "Salisbury",
"4414309", "Market\ Weighton",
"4413393", "Aboyne",
"442887", "Dungannon",
"441487", "Warboys",
"441766", "Porthmadog",
"441732", "Sevenoaks",
"441398", "Dulverton",
"4414230", "Harrogate\/Boroughbridge",
"442842", "Kircubbin",
"441442", "Hemel\ Hempstead",
"441793", "Swindon",
"4412299", "Millom",
"441324", "Falkirk",
"441770", "Isle\ of\ Arran",
"441926", "Warwick",
"441527", "Redditch",
"441950", "Sandwick",
"441799", "Saffron\ Walden",
"441259", "Alloa",
"441450", "Hawick",
"441503", "Looe",
"441624", "Isle\ of\ Man",
"442826", "Northern\ Ireland",
"4419647", "Patrington",
"441885", "Pencombe",
"441253", "Blackpool",
"441285", "Cirencester",
"441942", "Wigan",
"441509", "Loughborough",
"441698", "Motherwell",
"441859", "Harris",
"441665", "Alnwick",
"441808", "Tomatin",
"4415078", "Alford\ \(Lincs\)",
"441558", "Llandeilo",
"4413882", "Stanhope\ \(Eastgate\)",
"441586", "Campbeltown",
"4418512", "Stornoway",
"441987", "Ebbsfleet",
"4419752", "Alford\ \(Aberdeen\)",
"441746", "Bridgnorth",
"44281", "Northern\ Ireland",
"44141", "Glasgow",
"441208", "Bodmin",
"441436", "Helensburgh",
"441634", "Medway",
"441462", "Hitchin",
"441780", "Stamford",
"4416868", "Newtown",
"441323", "Eastbourne",
"4418470", "Thurso\/Tongue",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441451", "Stow\-on\-the\-Wold",
"4414345", "Haltwhistle",
"441728", "Saxmundham",
"441329", "Fareham",
"441995", "Garstang",
"441968", "Penicuik",
"441540", "Kingussie",
"441794", "Romsey",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441297", "Axminster",
"4418475", "Thurso",
"441477", "Holmes\ Chapel",
"442877", "Limavady",
"4418471", "Thurso\/Tongue",
"442848", "Northern\ Ireland",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441738", "Perth",
"441392", "Exeter",
"441692", "North\ Walsham",
"441948", "Whitchurch",
"441633", "Newport",
"4417684", "Pooley\ Bridge",
"441560", "Moscow",
"441757", "Selby",
"441576", "Lockerbie",
"441639", "Neath",
"441977", "Pontefract",
"44114700", "Sheffield",
"442895", "Belfast",
"441495", "Pontypool",
"442868", "Kesh",
"441202", "Bournemouth",
"441275", "Clevedon",
"441254", "Blackburn",
"4418516", "Great\ Bernera",
"441142", "Sheffield",
"4419756", "Strathdon",
"441629", "Matlock",
"441307", "Forfar",
"441771", "Maud",
"441623", "Mansfield",
"44292", "Cardiff",
"441951", "Colonsay",
"441854", "Ullapool",
"441875", "Tranent",
"4418907", "Ayton",
"441350", "Dunkeld",
"441725", "Rockbourne",
"441326", "Falmouth",
"441924", "Wakefield",
"441821", "Kinrossie",
"441764", "Crieff",
"4414302", "North\ Cave",
"441642", "Middlesbrough",
"441700", "Rothesay",
"441267", "Carmarthen",
"4412292", "Barrow\-in\-Furness",
"441687", "Mallaig",
"4419467", "Gosforth",
"441362", "Dereham",
"441445", "Gairloch",
"44131", "Edinburgh",
"442845", "Northern\ Ireland",
"441934", "Weston\-super\-Mare",
"441910", "Tyneside\/Durham\/Sunderland",
"441590", "Lymington",
"441744", "St\ Helens",
"441282", "Burnley",
"44161", "Manchester",
"441945", "Wisbech",
"4413390", "Aboyne\/Ballater",
"441636", "Newark\-on\-Trent",
"441579", "Liskeard",
"4419644", "Patrington",
"441387", "Dumfries",
"441584", "Ludlow",
"441573", "Kelso",
"441882", "Kinloch\ Rannoch",
"4418519", "Great\ Bernera",
"4413391", "Aboyne\/Ballater",
"4419759", "Alford\ \(Aberdeen\)",
"4413395", "Aboyne",
"441342", "East\ Grinstead",
"441278", "Bridgwater",
"442898", "Belfast",
"441465", "Girvan",
"4414233", "Boroughbridge",
"441878", "Lochboisdale",
"441650", "Cemmaes\ Road",
"442824", "Northern\ Ireland",
"441626", "Newton\ Abbot",
"441424", "Hastings",
"441264", "Andover",
"441721", "Peebles",
"441458", "Glastonbury",
"442886", "Cookstown",
"4419646", "Patrington",
"441673", "Market\ Rasen",
"441684", "Malvern",
"441825", "Uckfield",
"441690", "Betws\-y\-Coed",
"441225", "Bath",
"44151", "Liverpool",
"441864", "Abington\ \(Crawford\)",
"441937", "Wetherby",
"441536", "Kettering",
"4415075", "Spilsby\ \(Horncastle\)",
"441562", "Kidderminster",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441235", "Abingdon",
"441550", "Llandovery",
"441403", "Horsham",
"441526", "Martin",
"441200", "Clitheroe",
"441767", "Sandy",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441409", "Holsworthy",
"442841", "Rostrevor",
"441835", "St\ Boswells",
"441140", "Sheffield",
"44114707", "Sheffield",
"441844", "Thame",
"441909", "Worksop",
"441542", "Keith",
"4415395", "Grange\-over\-Sands",
"441244", "Chester",
"441782", "Stoke\-on\-Trent",
"441427", "Gainsborough",
"442827", "Ballymoney",
"441903", "Worthing",
"441379", "Diss",
"441747", "Shaftesbury",
"442837", "Armagh",
"441461", "Gretna",
"4414238", "Harrogate",
"441373", "Frome",
"441384", "Dudley",
"441778", "Bourne",
"441986", "Bungay",
"44247", "Coventry",
"4419649", "Hornsea",
"44238", "Southampton",
"4416863", "Llanidloes",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441828", "Coupar\ Angus",
"442883", "Northern\ Ireland",
"441676", "Meriden",
"441474", "Gravesend",
"441539", "Kendal",
"441483", "Guildford",
"441455", "Hinckley",
"441880", "Tarbert",
"441294", "Ardrossan",
"441592", "Kirkcaldy",
"441912", "Tyneside",
"441280", "Buckingham",
"441489", "Bishops\ Waltham",
"442889", "Fivemiletown",
"441228", "Carlisle",
"441652", "Brigg",
"4418514", "Great\ Bernera",
"441604", "Northampton",
"4414375", "Clynderwen\ \(Clunderwen\)",
"4419754", "Alford\ \(Aberdeen\)",
"441406", "Holbeach",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441838", "Dalmally",
"441340", "Craigellachie\ \(Aberlour\)",
"441797", "Rye",
"441529", "Sleaford",
"441257", "Coppull",
"4418902", "Coldstream",
"441304", "Dover",
"441352", "Mold",
"441857", "Sanday",
"4414307", "Market\ Weighton",
"441491", "Henley\-on\-Thames",
"442891", "Bangor\ \(Co\.\ Down\)",
"441360", "Killearn",
"4412297", "Millom",
"441271", "Barnstaple",
"44286", "Northern\ Ireland",
"441989", "Ross\-on\-Wye",
"441376", "Braintree",
"441702", "Southend\-on\-Sea",
"441775", "Spalding",
"441754", "Skegness",
"441974", "Llanon",
"441983", "Isle\ of\ Wight",
"441955", "Wick",
"441871", "Castlebay",
"441609", "Northallerton",
"441918", "Tyneside",
"441598", "Lynton",
"441641", "Strathy",
"441565", "Knutsford",
"441327", "Daventry",
"441603", "Norwich",
"441822", "Tavistock",
"4413398", "Aboyne",
"441524", "Lancaster",
"441490", "Corwen",
"442890", "Belfast",
"441361", "Duns",
"441270", "Crewe",
"441337", "Ladybank",
"441866", "Kilchrenan",
"442879", "Magherafelt",
"441534", "Jersey",
"441479", "Grantown\-on\-Spey",
"44116", "Leicester",
"441832", "Clopton",
"441299", "Bewdley",
"441899", "Biggar",
"441484", "Huddersfield",
"441473", "Ipswich",
"442884", "Northern\ Ireland",
"441293", "Crawley",
"441870", "Isle\ of\ Benbecula",
"441386", "Evesham",
"4418906", "Ayton",
"441785", "Stafford",
"441753", "Slough",
"441984", "Watchet\ \(Williton\)",
"441358", "Ellon",
"441759", "Pocklington",
"441545", "Llanarth",
"441637", "Newquay",
"441661", "Prudhoe",
"441303", "Folkestone",
"4415073", "Louth",
"441246", "Chesterfield",
"441708", "Romford",
"441309", "Forres",
"441341", "Barmouth",
"441915", "Sunderland",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441568", "Leominster",
"4419642", "Hornsea",
"441452", "Gloucester",
"441404", "Honiton",
"441606", "Northwich",
"4416974", "Raughton\ Head",
"441269", "Ammanford",
"441896", "Galashiels",
"4418517", "Stornoway",
"441863", "Ardgay",
"441689", "Orpington",
"4419757", "Strathdon",
"441460", "Chard",
"441263", "Cromer",
"441476", "Grantham",
"441683", "Moffat",
"441674", "Montrose",
"441655", "Maybole",
"441869", "Bicester",
"441296", "Aylesbury",
"441383", "Dunfermline",
"441355", "East\ Kilbride",
"441720", "Isles\ of\ Scilly",
"441756", "Skipton",
"4418909", "Ayton",
"441788", "Rugby",
"441577", "Kinross",
"441691", "Oswestry",
"441389", "Dumbarton",
"441548", "Kingsbridge",
"4416860", "Newtown\/Llanidloes",
"4418478", "Thurso",
"4414373", "Clynderwen\ \(Clunderwen\)",
"4414304", "North\ Cave",
"441306", "Dorking",
"441243", "Chichester",
"4412294", "Barrow\-in\-Furness",
"441772", "Preston",
"441952", "Telford",
"441904", "York",
"441249", "Chippenham",
"441730", "Petersfield",
"4414348", "Hexham",
"441843", "Thanet",
"4416861", "Newtown\/Llanidloes",
"442840", "Banbridge",
"441440", "Haverhill",
"441141", "Sheffield",
"4416865", "Newtown",};
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