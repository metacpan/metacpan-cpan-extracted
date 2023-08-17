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
our $VERSION = 1.20230614174403;

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
                    8[0-2]
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
                    8[0-2]
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
$areanames{en} = {"441588", "Bishops\ Castle",
"441565", "Knutsford",
"441554", "Llanelli",
"441770", "Isle\ of\ Arran",
"4419646", "Patrington",
"4414234", "Boroughbridge",
"441765", "Ripon",
"441788", "Rugby",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441754", "Skegness",
"441397", "Fort\ William",
"441570", "Lampeter",
"441463", "Inverness",
"441209", "Redruth",
"4413885", "Stanhope\ \(Eastgate\)",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441678", "Bala",
"441563", "Kilmarnock",
"441488", "Hungerford",
"441244", "Chester",
"4419467", "Gosforth",
"441465", "Girvan",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441262", "Bridlington",
"441389", "Dumbarton",
"441454", "Chipping\ Sodbury",
"441986", "Bungay",
"441763", "Royston",
"44113", "Leeds",
"441793", "Swindon",
"441495", "Pontypool",
"441292", "Ayr",
"4419757", "Strathdon",
"441937", "Wetherby",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441406", "Holbeach",
"441233", "Ashford\ \(Kent\)",
"4415073", "Louth",
"441593", "Lybster",
"441908", "Milton\ Keynes",
"441732", "Sevenoaks",
"441424", "Hastings",
"4418909", "Ayton",
"441367", "Faringdon",
"441493", "Great\ Yarmouth",
"441506", "Bathgate",
"441795", "Sittingbourne",
"442847", "Northern\ Ireland",
"4416974", "Raughton\ Head",
"441524", "Lancaster",
"4413393", "Aboyne",
"442871", "Londonderry",
"44283", "Northern\ Ireland",
"441889", "Rugeley",
"441706", "Rochdale",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441301", "Arrochar",
"441235", "Abingdon",
"441724", "Scunthorpe",
"441432", "Hereford",
"441989", "Ross\-on\-Wye",
"441492", "Colwyn\ Bay",
"441295", "Banbury",
"441535", "Keighley",
"4413882", "Stanhope\ \(Eastgate\)",
"441386", "Evesham",
"4418474", "Thurso",
"441224", "Aberdeen",
"441581", "New\ Luce",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441433", "Hathersage",
"441206", "Colchester",
"44131", "Edinburgh",
"441481", "Guernsey",
"4413390", "Aboyne\/Ballater",
"441792", "Swansea",
"441837", "Okehampton",
"441647", "Moretonhampstead",
"441808", "Tomatin",
"441293", "Crawley",
"441997", "Strathpeffer",
"441592", "Kirkcaldy",
"441435", "Heathfield",
"441733", "Peterborough",
"441671", "Newton\ Stewart",
"4413873", "Langholm",
"4418907", "Ayton",
"44116", "Leicester",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441562", "Kidderminster",
"4414344", "Bellingham",
"442827", "Ballymoney",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"44239", "Portsmouth",
"441709", "Rotherham",
"4417683", "Appleby",
"441544", "Kington",
"441263", "Cromer",
"441967", "Strontian",
"441744", "St\ Helens",
"441509", "Loughborough",
"441270", "Crewe",
"441337", "Ladybank",
"441308", "Bridport",
"441409", "Holsworthy",
"44286", "Northern\ Ireland",
"4419759", "Alford\ \(Aberdeen\)",
"442880", "Carrickmore",
"441254", "Blackburn",
"4416864", "Llanidloes",
"441462", "Hitchin",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441444", "Haywards\ Heath",
"441288", "Bude",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441547", "Knighton",
"4416865", "Newtown",
"442824", "Northern\ Ireland",
"441376", "Braintree",
"441843", "Thanet",
"441771", "Maud",
"441633", "Newport",
"441322", "Dartford",
"442895", "Belfast",
"441692", "North\ Walsham",
"441747", "Shaftesbury",
"441955", "Wick",
"441571", "Lochinver",
"441942", "Wigan",
"4412290", "Barrow\-in\-Furness\/Millom",
"4414231", "Harrogate\/Boroughbridge",
"4419648", "Hornsea",
"441845", "Thirsk",
"441635", "Newbury",
"441852", "Kilmelford",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441334", "St\ Andrews",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441257", "Coppull",
"4414300", "North\ Cave\/Market\ Weighton",
"4414345", "Haltwhistle",
"441953", "Wymondham",
"442893", "Ballyclare",
"441876", "Lochmaddy",
"441343", "Elgin",
"441822", "Tavistock",
"441227", "Canterbury",
"441923", "Watford",
"4414232", "Harrogate",
"441994", "St\ Clears",
"441352", "Mold",
"442888", "Northern\ Ireland",
"4418510", "Great\ Bernera\/Stornoway",
"441280", "Buckingham",
"441834", "Narberth",
"4418475", "Thurso",
"441644", "New\ Galloway",
"442870", "Coleraine",
"441925", "Warrington",
"441278", "Bridgwater",
"441300", "Cerne\ Abbas",
"441609", "Northallerton",
"441912", "Tyneside",
"441353", "Ely",
"441780", "Stamford",
"4418471", "Thurso\/Tongue",
"441825", "Uckfield",
"44241", "Coventry",
"441578", "Lauder",
"441663", "New\ Mills",
"441580", "Cranbrook",
"441427", "Gainsborough",
"441778", "Bourne",
"4414342", "Bellingham",
"441913", "Durham",
"441934", "Weston\-super\-Mare",
"4418513", "Stornoway",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441480", "Huntingdon",
"441665", "Alnwick",
"441527", "Redditch",
"442844", "Downpatrick",
"441654", "Machynlleth",
"4416862", "Llanidloes",
"441364", "Ashburton",
"441823", "Taunton",
"441342", "East\ Grinstead",
"441355", "East\ Kilbride",
"441915", "Sunderland",
"441727", "St\ Albans",
"441670", "Morpeth",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441922", "Walsall",
"441379", "Diss",
"4418472", "Thurso",
"441606", "Northwich",
"441325", "Darlington",
"441900", "Workington",
"441624", "Isle\ of\ Man",
"441557", "Kirkcudbright",
"441952", "Telford",
"4412293", "Millom",
"441394", "Felixstowe",
"441945", "Wisbech",
"442892", "Lisburn",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441695", "Skelmersdale",
"441757", "Selby",
"441271", "Barnstaple",
"4416861", "Newtown\/Llanidloes",
"441864", "Abington\ \(Crawford\)",
"441323", "Eastbourne",
"441842", "Thetford",
"441855", "Ballachulish",
"4414235", "Harrogate",
"4414303", "North\ Cave",
"442881", "Newtownstewart",
"441457", "Glossop",
"441943", "Guiseley",
"441879", "Scarinish",
"441294", "Ardrossan",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441534", "Jersey",
"4414348", "Hexham",
"441980", "Amesbury",
"441225", "Bath",
"441422", "Halifax",
"44161", "Manchester",
"441978", "Wrexham",
"441476", "Grantham",
"4419645", "Hornsea",
"442867", "Lisnaskea",
"441522", "Lincoln",
"44291", "Cardiff",
"441576", "Lockerbie",
"441347", "Easingwold",
"441371", "Great\ Dunmow",
"441722", "Salisbury",
"4416868", "Newtown",
"441223", "Cambridge",
"441776", "Stranraer",
"44115", "Nottingham",
"441700", "Rothesay",
"441545", "Llanarth",
"4413399", "Ballater",
"4418478", "Thurso",
"441957", "Mid\ Yell",
"441443", "Pontypridd",
"4417687", "Keswick",
"441253", "Blackpool",
"442897", "Saintfield",
"441745", "Rhyl",
"441752", "Plymouth",
"4418903", "Coldstream",
"441543", "Cannock",
"441608", "Chipping\ Norton",
"441400", "Honington",
"441279", "Bishops\ Stortford",
"4415079", "Alford\ \(Lincs\)",
"441637", "Newquay",
"441743", "Shrewsbury",
"441871", "Castlebay",
"442889", "Fivemiletown",
"441255", "Clacton\-on\-Sea",
"441242", "Cheltenham",
"441445", "Gairloch",
"441264", "Andover",
"441452", "Gloucester",
"441564", "Lapworth",
"441971", "Scourie",
"441555", "Lanark",
"441779", "Peterhead",
"441542", "Keith",
"44114", "Sheffield",
"441327", "Daventry",
"441697", "Brampton",
"4418900", "Coldstream\/Ayton",
"441764", "Crieff",
"441579", "Liskeard",
"441947", "Whitby",
"441453", "Dursley",
"441243", "Chichester",
"441857", "Sanday",
"442837", "Armagh",
"441479", "Grantown\-on\-Spey",
"441553", "Kings\ Lynn",
"441200", "Clitheroe",
"441252", "Aldershot",
"4419642", "Hornsea",
"441464", "Insch",
"441245", "Chelmsford",
"441442", "Hemel\ Hempstead",
"441455", "Hinckley",
"441753", "Slough",
"441380", "Devizes",
"441689", "Orpington",
"441494", "High\ Wycombe",
"4419753", "Strathdon",
"4414238", "Harrogate",
"4415077", "Louth",
"442886", "Cookstown",
"441827", "Tamworth",
"441276", "Camberley",
"441723", "Scarborough",
"441425", "Ringwood",
"44281", "Northern\ Ireland",
"441878", "Lochboisdale",
"441357", "Strathaven",
"441667", "Nairn",
"441794", "Romsey",
"44292", "Cardiff",
"4414376", "Haverfordwest",
"441525", "Leighton\ Buzzard",
"4419641", "Hornsea\/Patrington",
"4413397", "Ballater",
"441594", "Lydney",
"441234", "Bedford",
"441880", "Tarbert",
"441725", "Rockbourne",
"441917", "Sunderland",
"441497", "Hay\-on\-Wye",
"441363", "Crediton",
"441824", "Ruthin",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441653", "Malton",
"441806", "Shetland",
"441789", "Stratford\-upon\-Avon",
"441981", "Wormbridge",
"441895", "Uxbridge",
"4416866", "Newtown",
"441935", "Yeovil",
"441797", "Rye",
"441664", "Melton\ Mowbray",
"4414346", "Hexham",
"441832", "Clopton",
"441642", "Middlesbrough",
"442845", "Northern\ Ireland",
"441655", "Maybole",
"441388", "Bishop\ Auckland",
"441992", "Lea\ Valley",
"441489", "Bishops\ Waltham",
"441354", "Chatteris",
"441237", "Bideford",
"441597", "Llandrindod\ Wells",
"441933", "Wellingborough",
"441914", "Tyneside",
"4418517", "Stornoway",
"441208", "Bodmin",
"4420", "London",
"441909", "Worksop",
"441863", "Ardgay",
"441324", "Falkirk",
"44121", "Birmingham",
"441567", "Killin",
"4412297", "Millom",
"441306", "Dorking",
"441625", "Macclesfield",
"442822", "Northern\ Ireland",
"441944", "West\ Heslerton",
"441501", "Harthill",
"441395", "Budleigh\ Salterton",
"441962", "Winchester",
"441767", "Sandy",
"441694", "Church\ Stretton",
"441286", "Caernarfon",
"4414307", "Market\ Weighton",
"441623", "Mansfield",
"441332", "Derby",
"441888", "Turriff",
"441865", "Oxford",
"441854", "Ullapool",
"441870", "Isle\ of\ Benbecula",
"441467", "Inverurie",
"4418476", "Tongue",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441622", "Maidstone",
"44141", "Glasgow",
"442825", "Ballymena",
"441970", "Aberystwyth",
"441676", "Meriden",
"442894", "Antrim",
"441954", "Madingley",
"441392", "Exeter",
"441988", "Wigtown",
"4418519", "Great\ Bernera",
"441862", "Tain",
"441844", "Thame",
"441634", "Medway",
"441586", "Campbeltown",
"442823", "Northern\ Ireland",
"441335", "Ashbourne",
"441963", "Wincanton",
"441809", "Tomdoun",
"44151", "Liverpool",
"441786", "Stirling",
"441267", "Carmarthen",
"441381", "Fortrose",
"4414378", "Haverfordwest",
"441508", "Brooke",
"441833", "Barnard\ Castle",
"4415242", "Hornby",
"441643", "Minehead",
"4414309", "Market\ Weighton",
"441993", "Witney",
"441297", "Axminster",
"441708", "Romford",
"441932", "Weybridge",
"441892", "Tunbridge\ Wells",
"441737", "Redhill",
"4414236", "Harrogate",
"441362", "Dereham",
"4419644", "Patrington",
"441289", "Berwick\-upon\-Tweed",
"441995", "Garstang",
"441344", "Bracknell",
"441835", "St\ Boswells",
"441652", "Brigg",
"442842", "Kircubbin",
"4412299", "Millom",
"441924", "Wakefield",
"441408", "Golspie",
"441600", "Monmouth",
"441309", "Forres",
"442879", "Magherafelt",
"441748", "Richmond",
"441548", "Kingsbridge",
"4413394", "Ballater",
"4416973", "Wigton",
"441603", "Norwich",
"441856", "Orkney",
"4418515", "Stornoway",
"4418470", "Thurso\/Tongue",
"441284", "Bury\ St\ Edmunds",
"441830", "Kirkwhelpington",
"441349", "Dingwall",
"441258", "Blandford",
"441946", "Whitehaven",
"4415074", "Alford\ \(Lincs\)",
"441721", "Peebles",
"441929", "Wareham",
"441304", "Dover",
"441372", "Esher",
"441326", "Falmouth",
"442820", "Ballycastle",
"4416860", "Newtown\/Llanidloes",
"441228", "Carlisle",
"441916", "Tyneside",
"442899", "Northern\ Ireland",
"4412295", "Barrow\-in\-Furness",
"441356", "Brechin",
"441959", "Westerham",
"441666", "Malmesbury",
"441751", "Pickering",
"441277", "Brentwood",
"441330", "Banchory",
"441639", "Neath",
"4414233", "Boroughbridge",
"441872", "Truro",
"4419758", "Strathdon",
"44247", "Coventry",
"4414305", "North\ Cave",
"441451", "Stow\-on\-the\-Wold",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"442887", "Dungannon",
"441241", "Arbroath",
"441972", "Glenborrodale",
"441428", "Haslemere",
"441904", "York",
"441620", "North\ Berwick",
"441329", "Fareham",
"4416863", "Llanidloes",
"441926", "Warwick",
"441777", "Retford",
"4418512", "Stornoway",
"442866", "Enniskillen",
"441873", "Abergavenny",
"441949", "Whatton",
"4414301", "North\ Cave\/Market\ Weighton",
"441346", "Fraserburgh",
"441577", "Kinross",
"441728", "Saxmundham",
"441477", "Holmes\ Chapel",
"441859", "Harris",
"441528", "Laggan",
"4417684", "Pooley\ Bridge",
"4414343", "Haltwhistle",
"441687", "Mallaig",
"4414230", "Harrogate\/Boroughbridge",
"441875", "Tranent",
"4412291", "Barrow\-in\-Furness\/Millom",
"441829", "Tarporley",
"441758", "Pwllheli",
"441784", "Staines",
"4418511", "Great\ Bernera\/Stornoway",
"442310", "Portsmouth",
"441373", "Frome",
"4414302", "North\ Cave",
"4415396", "Sedbergh",
"441558", "Llandeilo",
"441636", "Newark\-on\-Trent",
"441584", "Ludlow",
"4418908", "Coldstream",
"441669", "Rothbury",
"441360", "Killearn",
"441650", "Cemmaes\ Road",
"442896", "Belfast",
"442840", "Banbridge",
"441458", "Glastonbury",
"4418473", "Thurso",
"441248", "Bangor\ \(Gwynedd\)",
"441484", "Huddersfield",
"441359", "Pakenham",
"441919", "Durham",
"441674", "Montrose",
"4412292", "Barrow\-in\-Furness",
"441375", "Grays\ Thurrock",
"4413391", "Aboyne\/Ballater",
"4419647", "Patrington",
"441787", "Sudbury",
"441982", "Builth\ Wells",
"441499", "Inveraray",
"441398", "Dulverton",
"441628", "Maidenhead",
"441420", "Alton",
"441883", "Caterham",
"441641", "Strathy",
"441520", "Lochcarron",
"441487", "Warboys",
"441799", "Saffron\ Walden",
"441720", "Isles\ of\ Scilly",
"441885", "Pencombe",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441599", "Kyle",
"441239", "Cardigan",
"441677", "Bedale",
"4413392", "Aboyne",
"441569", "Stonehaven",
"441938", "Welshpool",
"441702", "Southend\-on\-Sea",
"441550", "Llandovery",
"442821", "Martinstown",
"441436", "Helensburgh",
"441769", "South\ Molton",
"441502", "Lowestoft",
"4419756", "Strathdon",
"441750", "Selkirk",
"441383", "Dunfermline",
"441205", "Boston",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441474", "Gravesend",
"44280", "Northern\ Ireland",
"441736", "Penzance",
"441469", "Killingholme",
"441368", "Dunbar",
"441450", "Hawick",
"4415072", "Spilsby\ \(Horncastle\)",
"442848", "Northern\ Ireland",
"441296", "Aylesbury",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441684", "Malvern",
"441536", "Kettering",
"441621", "Maldon",
"441540", "Kingussie",
"441403", "Horsham",
"441236", "Coatbridge",
"4414304", "North\ Cave",
"441740", "Sedgefield",
"441796", "Pitlochry",
"441505", "Johnstone",
"4419649", "Hornsea",
"441274", "Bradford",
"441202", "Bournemouth",
"441405", "Goole",
"4412294", "Barrow\-in\-Furness",
"441503", "Looe",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441838", "Dalmally",
"441496", "Port\ Ellen",
"441440", "Haverhill",
"442884", "Northern\ Ireland",
"441250", "Blairgowrie",
"441382", "Dundee",
"441269", "Ammanford",
"441807", "Ballindalloch",
"441968", "Penicuik",
"441985", "Warminster",
"441299", "Bewdley",
"441539", "Kendal",
"441466", "Huntly",
"442311", "Southampton",
"4418906", "Ayton",
"441931", "Shap",
"4415075", "Spilsby\ \(Horncastle\)",
"442828", "Larne",
"4418514", "Great\ Bernera",
"441361", "Duns",
"441287", "Guisborough",
"441651", "Oldmeldrum",
"442841", "Rostrevor",
"441766", "Porthmadog",
"441983", "Isle\ of\ Wight",
"4413395", "Aboyne",
"441439", "Helmsley",
"442877", "Limavady",
"441566", "Launceston",
"441882", "Kinloch\ Rannoch",
"441307", "Forfar",
"441905", "Worcester",
"441320", "Fort\ Augustus",
"441629", "Matlock",
"441690", "Betws\-y\-Coed",
"441646", "Milford\ Haven",
"4416867", "Llanidloes",
"442830", "Newry",
"4418904", "Coldstream",
"441598", "Lynton",
"441207", "Consett",
"441869", "Bicester",
"441903", "Worthing",
"4414347", "Hexham",
"441261", "Banff",
"4418516", "Great\ Bernera",
"441798", "Pulborough",
"441874", "Brecon",
"441387", "Dumfries",
"4412296", "Barrow\-in\-Furness",
"441483", "Guildford",
"441291", "Chepstow",
"441531", "Ledbury",
"441768", "Penrith",
"441785", "Stafford",
"4414239", "Boroughbridge",
"441899", "Biggar",
"441673", "Market\ Rasen",
"441939", "Wem",
"441568", "Leominster",
"441350", "Dunkeld",
"442849", "Northern\ Ireland",
"441659", "Sanquhar",
"4414306", "Market\ Weighton",
"441369", "Dunoon",
"441282", "Burnley",
"441485", "Hunstanton",
"441583", "Carradale",
"441675", "Coleshill",
"4418477", "Tongue",
"441431", "Helmsdale",
"441910", "Tyneside\/Durham\/Sunderland",
"441302", "Doncaster",
"441887", "Aberfeldy",
"442826", "Northern\ Ireland",
"441782", "Stoke\-on\-Trent",
"441491", "Henley\-on\-Thames",
"441987", "Ebbsfleet",
"4414349", "Bellingham",
"441283", "Burton\-on\-Trent",
"441866", "Kilchrenan",
"441582", "Luton",
"44118", "Reading",
"441303", "Folkestone",
"441268", "Basildon",
"441285", "Cirencester",
"441482", "Kingston\-upon\-Hull",
"441340", "Craigellachie\ \(Aberlour\)",
"441305", "Dorchester",
"441591", "Llanwrtyd\ Wells",
"441626", "Newton\ Abbot",
"4419754", "Alford\ \(Aberdeen\)",
"4416869", "Newtown",
"441920", "Ware",
"441604", "Northampton",
"441672", "Marlborough",
"4415395", "Grange\-over\-Sands",
"441707", "Welwyn\ Garden\ City",
"442829", "Kilrea",
"441974", "Llanon",
"441738", "Perth",
"441902", "Wolverhampton",
"441561", "Laurencekirk",
"4418479", "Tongue",
"441366", "Downham\ Market",
"4413398", "Aboyne",
"441950", "Sandwick",
"441538", "Ipstones",
"441298", "Buxton",
"441803", "Torquay",
"441969", "Leyburn",
"442890", "Belfast",
"441761", "Temple\ Cloud",
"442846", "Northern\ Ireland",
"441656", "Bridgend",
"441407", "Holyhead",
"441438", "Stevenage",
"4415078", "Alford\ \(Lincs\)",
"4414237", "Harrogate",
"44238", "Southampton",
"441630", "Market\ Drayton",
"441896", "Galashiels",
"441840", "Camelford",
"441805", "Torrington",
"441461", "Gretna",
"441977", "Pontefract",
"441726", "St\ Austell",
"441273", "Brighton",
"441704", "Southport",
"441772", "Preston",
"441549", "Lairg",
"44117", "Bristol",
"441691", "Oswestry",
"441526", "Martin",
"442883", "Northern\ Ireland",
"441572", "Oakham",
"441749", "Shepton\ Mallet",
"4418518", "Stornoway",
"44287", "Northern\ Ireland",
"441275", "Clevedon",
"441928", "Runcorn",
"441404", "Honiton",
"441472", "Grimsby",
"4418901", "Coldstream\/Ayton",
"441260", "Congleton",
"442868", "Kesh",
"442885", "Ballygawley",
"4415394", "Hawkshead",
"441259", "Alloa",
"441348", "Fishguard",
"441449", "Stowmarket",
"441984", "Watchet\ \(Williton\)",
"4414379", "Haverfordwest",
"4414308", "Market\ Weighton",
"441530", "Coalville",
"441821", "Kinrossie",
"4419755", "Alford\ \(Aberdeen\)",
"441290", "Cumnock",
"441246", "Chesterfield",
"442898", "Belfast",
"441456", "Glenurquhart",
"4419640", "Hornsea\/Patrington",
"441730", "Petersfield",
"4412298", "Barrow\-in\-Furness",
"441756", "Skipton",
"441661", "Prudhoe",
"4418902", "Coldstream",
"441911", "Tyneside\/Durham\/Sunderland",
"441638", "Newmarket",
"441848", "Thornhill",
"441556", "Castle\ Douglas",
"441256", "Basingstoke",
"441446", "Barry",
"441490", "Corwen",
"441698", "Motherwell",
"441948", "Whitchurch",
"441328", "Fakenham",
"441429", "Hartlepool",
"4419643", "Patrington",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441790", "Spilsby",
"441746", "Bridgnorth",
"441341", "Barmouth",
"441529", "Sleaford",
"441858", "Market\ Harborough",
"442838", "Portadown",
"441377", "Driffield",
"441884", "Tiverton",
"441546", "Lochgilphead",
"441590", "Lymington",
"441729", "Settle",
"4415076", "Louth",
"441559", "Llandysul",
"441775", "Spalding",
"441473", "Ipswich",
"441560", "Moscow",
"441683", "Moffat",
"441951", "Colonsay",
"441575", "Kirriemuir",
"441759", "Pocklington",
"441828", "Coupar\ Angus",
"442891", "Bangor\ \(Co\.\ Down\)",
"441760", "Swaffham",
"4418905", "Ayton",
"441204", "Bolton",
"4419752", "Alford\ \(Aberdeen\)",
"4414377", "Haverfordwest",
"441475", "Greenock",
"441773", "Ripley",
"441841", "Newquay\ \(Padstow\)",
"441631", "Oban",
"441226", "Barnsley",
"441918", "Tyneside",
"441358", "Ellon",
"441249", "Chippenham",
"441877", "Callander",
"441384", "Dudley",
"441573", "Kelso",
"441460", "Chard",
"441685", "Merthyr\ Tydfil",
"441668", "Bamburgh",
"4413396", "Ballater",
"442882", "Omagh",};

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