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
package Number::Phone::StubCountry::JE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250913135858;

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
                'fixed_line' => '1534[0-24-8]\\d{5}',
                'geographic' => '1534[0-24-8]\\d{5}',
                'mobile' => '
          7(?:
            (?:
              (?:
                50|
                82
              )9|
              937
            )\\d|
            7(?:
              00[378]|
              97\\d
            )
          )\\d{5}
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
                'personal_number' => '701511\\d{4}',
                'specialrate' => '(
          (?:
            8(?:
              4(?:
                4(?:
                  4(?:
                    05|
                    42|
                    69
                  )|
                  703
                )|
                5(?:
                  041|
                  800
                )
              )|
              7(?:
                0002|
                1206
              )
            )|
            90(?:
              066[59]|
              1810|
              71(?:
                07|
                55
              )
            )
          )\\d{4}
        )|(
          (?:
            3(?:
              0(?:
                07(?:
                  35|
                  81
                )|
                8901
              )|
              3\\d{4}|
              4(?:
                4(?:
                  4(?:
                    05|
                    42|
                    69
                  )|
                  703
                )|
                5(?:
                  041|
                  800
                )
              )|
              7(?:
                0002|
                1206
              )
            )|
            55\\d{4}
          )\\d{4}
        )',
                'toll_free' => '
          80(?:
            07(?:
              35|
              81
            )|
            8901
          )\\d{4}
        ',
                'voip' => '56\\d{8}'
              };
my %areanames = ();
$areanames{en} = {"441900", "Workington",
"441730", "Petersfield",
"441544", "Kington",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441356", "Brechin",
"442899", "Northern\ Ireland",
"441268", "Basildon",
"441757", "Selby",
"441740", "Sedgefield",
"441534", "Jersey",
"441671", "Newton\ Stewart",
"441598", "Lynton",
"441493", "Great\ Yarmouth",
"441989", "Ross\-on\-Wye",
"441579", "Liskeard",
"441245", "Chelmsford",
"4414232", "Harrogate",
"441887", "Aberfeldy",
"4419646", "Patrington",
"441536", "Kettering",
"441869", "Bicester",
"441354", "Chatteris",
"441235", "Abingdon",
"441546", "Lochgilphead",
"441697", "Brampton",
"441967", "Strontian",
"441722", "Salisbury",
"441777", "Retford",
"441400", "Honington",
"441376", "Braintree",
"441806", "Shetland",
"442883", "Northern\ Ireland",
"441224", "Aberdeen",
"4418904", "Coldstream",
"4416860", "Newtown\/Llanidloes",
"441651", "Oldmeldrum",
"4418515", "Stornoway",
"441349", "Dingwall",
"44114704", "Sheffield",
"4412299", "Millom",
"441663", "New\ Mills",
"441489", "Bishops\ Waltham",
"44114705", "Sheffield",
"441993", "Witney",
"441559", "Llandysul",
"441525", "Leighton\ Buzzard",
"441145", "Sheffield",
"4418511", "Great\ Bernera\/Stornoway",
"441226", "Barnsley",
"441467", "Inverurie",
"4414238", "Harrogate",
"442884", "Northern\ Ireland",
"441223", "Cambridge",
"441948", "Whitchurch",
"441342", "East\ Grinstead",
"4415395", "Grange\-over\-Sands",
"4414347", "Hexham",
"441666", "Malmesbury",
"441729", "Settle",
"441332", "Derby",
"441708", "Romford",
"441938", "Welshpool",
"441695", "Skelmersdale",
"4416974", "Raughton\ Head",
"4420", "London",
"441250", "Blairgowrie",
"441841", "Newquay\ \(Padstow\)",
"441911", "Tyneside\/Durham\/Sunderland",
"441237", "Bideford",
"4414378", "Haverfordwest",
"441664", "Melton\ Mowbray",
"441994", "St\ Clears",
"441482", "Kingston\-upon\-Hull",
"441885", "Pencombe",
"441373", "Frome",
"441803", "Torquay",
"442886", "Cookstown",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441361", "Duns",
"441543", "Cannock",
"44114701", "Sheffield",
"4412295", "Barrow\-in\-Furness",
"4413394", "Ballater",
"441496", "Port\ Ellen",
"441438", "Stevenage",
"442892", "Lisburn",
"441320", "Fort\ Augustus",
"441775", "Spalding",
"441501", "Harthill",
"441465", "Girvan",
"4418519", "Great\ Bernera",
"441609", "Northallerton",
"441862", "Tain",
"441270", "Crewe",
"4416863", "Llanidloes",
"441494", "High\ Wycombe",
"441628", "Maidenhead",
"441527", "Redditch",
"441388", "Bishop\ Auckland",
"441982", "Builth\ Wells",
"4412291", "Barrow\-in\-Furness\/Millom",
"441572", "Oakham",
"4419467", "Gosforth",
"441353", "Ely",
"442821", "Martinstown",
"441670", "Morpeth",
"4419648", "Hornsea",
"441228", "Carlisle",
"441943", "Guiseley",
"441209", "Redruth",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"4414344", "Bellingham",
"441785", "Stafford",
"441933", "Wellingborough",
"44287", "Northern\ Ireland",
"4419753", "Strathdon",
"4415075", "Spilsby\ \(Horncastle\)",
"441280", "Buckingham",
"441972", "Glenborrodale",
"441582", "Luton",
"441808", "Tomatin",
"441452", "Gloucester",
"441829", "Tarporley",
"4414300", "North\ Cave\/Market\ Weighton",
"441855", "Ballachulish",
"441637", "Newquay",
"441264", "Andover",
"441295", "Banbury",
"44116", "Leicester",
"441443", "Pontypridd",
"4413397", "Ballater",
"441548", "Kingsbridge",
"441650", "Cemmaes\ Road",
"4418475", "Thurso",
"441647", "Moretonhampstead",
"441433", "Hathersage",
"441538", "Ipstones",
"442849", "Northern\ Ireland",
"441565", "Knutsford",
"4415242", "Hornby",
"441594", "Lydney",
"441623", "Mansfield",
"4418471", "Thurso\/Tongue",
"441383", "Dunfermline",
"441875", "Tranent",
"441305", "Dorchester",
"441472", "Grimsby",
"441427", "Gainsborough",
"441358", "Ellon",
"441952", "Telford",
"441790", "Spilsby",
"441386", "Evesham",
"4414303", "North\ Cave",
"441444", "Haywards\ Heath",
"4414376", "Haverfordwest",
"441787", "Sudbury",
"441263", "Cromer",
"441769", "South\ Molton",
"4415079", "Alford\ \(Lincs\)",
"441626", "Newton\ Abbot",
"441479", "Grantown\-on\-Spey",
"441593", "Lybster",
"441857", "Sanday",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441624", "Isle\ of\ Man",
"4419642", "Hornsea",
"441925", "Warrington",
"441436", "Helensburgh",
"4414236", "Harrogate",
"441830", "Kirkwhelpington",
"441959", "Westerham",
"441910", "Tyneside\/Durham\/Sunderland",
"442842", "Kircubbin",
"441384", "Dudley",
"441446", "Barry",
"441840", "Camelford",
"441944", "West\ Heslerton",
"44292", "Cardiff",
"442888", "Northern\ Ireland",
"4418907", "Ayton",
"441360", "Killearn",
"441704", "Southport",
"441934", "Weston\-super\-Mare",
"441297", "Axminster",
"441202", "Bournemouth",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441635", "Newbury",
"441668", "Bamburgh",
"4418479", "Tongue",
"441392", "Exeter",
"442820", "Ballycastle",
"441706", "Rochdale",
"441425", "Ringwood",
"441877", "Callander",
"441822", "Tavistock",
"441307", "Forfar",
"441271", "Barnstaple",
"441946", "Whitehaven",
"441567", "Killin",
"441233", "Ashford\ \(Kent\)",
"441749", "Shepton\ Mallet",
"441377", "Driffield",
"442890", "Belfast",
"441464", "Insch",
"441928", "Runcorn",
"441322", "Dartford",
"441807", "Ballindalloch",
"441776", "Stranraer",
"441892", "Tunbridge\ Wells",
"441909", "Worksop",
"441495", "Pontypool",
"441243", "Chichester",
"441227", "Canterbury",
"441466", "Huntly",
"4413396", "Ballater",
"441980", "Amesbury",
"441570", "Lampeter",
"441821", "Kinrossie",
"4412293", "Millom",
"441340", "Craigellachie\ \(Aberlour\)",
"44114708", "Sheffield",
"441884", "Tiverton",
"441143", "Sheffield",
"441330", "Banchory",
"441694", "Church\ Stretton",
"441428", "Haslemere",
"441756", "Skipton",
"441665", "Alnwick",
"4416861", "Newtown\/Llanidloes",
"441995", "Garstang",
"441357", "Strathaven",
"441409", "Holsworthy",
"441754", "Skegness",
"441638", "Newmarket",
"442841", "Rostrevor",
"441547", "Knighton",
"4414342", "Bellingham",
"44131", "Edinburgh",
"441252", "Aldershot",
"442885", "Ballygawley",
"441550", "Llandovery",
"441480", "Huntingdon",
"4416865", "Newtown",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"4418510", "Great\ Bernera\/Stornoway",
"441497", "Hay\-on\-Wye",
"441144", "Sheffield",
"441858", "Market\ Harborough",
"441720", "Isles\ of\ Scilly",
"441883", "Caterham",
"441375", "Grays\ Thurrock",
"441805", "Torrington",
"441761", "Temple\ Cloud",
"441963", "Wincanton",
"441524", "Lancaster",
"441788", "Rugby",
"441526", "Martin",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441951", "Colonsay",
"4418906", "Ayton",
"441753", "Slough",
"441259", "Alloa",
"441146", "Sheffield",
"441225", "Bath",
"441667", "Nairn",
"441997", "Strathpeffer",
"441355", "East\ Kilbride",
"441234", "Bedford",
"4414348", "Hexham",
"441329", "Fareham",
"4418513", "Stornoway",
"44113", "Leeds",
"441878", "Lochboisdale",
"441308", "Bridport",
"441902", "Wolverhampton",
"441732", "Sevenoaks",
"4416869", "Newtown",
"441899", "Biggar",
"4419644", "Patrington",
"4414237", "Harrogate",
"441244", "Chester",
"4417683", "Appleby",
"441463", "Inverness",
"441689", "Orpington",
"441568", "Leominster",
"44280", "Northern\ Ireland",
"441773", "Ripley",
"441535", "Keighley",
"441971", "Scourie",
"441581", "New\ Luce",
"442887", "Dungannon",
"441451", "Stow\-on\-the\-Wold",
"441246", "Chesterfield",
"441298", "Buxton",
"441279", "Bishops\ Stortford",
"441545", "Llanarth",
"4412290", "Barrow\-in\-Furness\/Millom",
"4414377", "Haverfordwest",
"441236", "Coatbridge",
"441600", "Monmouth",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441597", "Llandrindod\ Wells",
"441646", "Milford\ Haven",
"442891", "Bangor\ \(Co\.\ Down\)",
"4413882", "Stanhope\ \(Eastgate\)",
"441888", "Turriff",
"441502", "Lowestoft",
"4414305", "North\ Cave",
"441636", "Newark\-on\-Trent",
"441200", "Clitheroe",
"441698", "Motherwell",
"441968", "Penicuik",
"4413398", "Aboyne",
"441424", "Hastings",
"441362", "Dereham",
"441571", "Lochinver",
"441981", "Wormbridge",
"441935", "Yeovil",
"44238", "Southampton",
"441267", "Carmarthen",
"4418902", "Coldstream",
"441758", "Pwllheli",
"442877", "Limavady",
"442822", "Northern\ Ireland",
"441634", "Medway",
"441945", "Wisbech",
"441289", "Berwick\-upon\-Tweed",
"4414301", "North\ Cave\/Market\ Weighton",
"4419759", "Alford\ \(Aberdeen\)",
"441644", "New\ Galloway",
"441873", "Abergavenny",
"441303", "Folkestone",
"4414234", "Boroughbridge",
"44281", "Northern\ Ireland",
"4419647", "Patrington",
"441659", "Sanquhar",
"441625", "Macclesfield",
"441924", "Wakefield",
"441341", "Barmouth",
"441563", "Kilmarnock",
"441481", "Guernsey",
"441435", "Heathfield",
"441926", "Warwick",
"441799", "Saffron\ Walden",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441778", "Bourne",
"441832", "Clopton",
"442830", "Newry",
"441293", "Crawley",
"441445", "Gairloch",
"441842", "Thetford",
"4418470", "Thurso\/Tongue",
"441912", "Tyneside",
"442840", "Banbridge",
"441760", "Swaffham",
"441296", "Aylesbury",
"441874", "Brecon",
"441304", "Dover",
"441652", "Brigg",
"4418908", "Coldstream",
"4419755", "Alford\ \(Aberdeen\)",
"441923", "Watford",
"44114707", "Sheffield",
"441721", "Peebles",
"441564", "Lapworth",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441248", "Bangor\ \(Gwynedd\)",
"4414309", "Market\ Weighton",
"441919", "Durham",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441947", "Whitby",
"441566", "Launceston",
"441950", "Sandwick",
"4413392", "Aboyne",
"441792", "Swansea",
"441876", "Lochmaddy",
"441294", "Ardrossan",
"4415073", "Louth",
"441306", "Dorking",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441707", "Welwyn\ Garden\ City",
"441937", "Wetherby",
"4418473", "Thurso",
"441672", "Marlborough",
"441369", "Dunoon",
"441854", "Ullapool",
"441786", "Stirling",
"441528", "Laggan",
"441387", "Dumfries",
"441509", "Loughborough",
"441633", "Newport",
"441282", "Burnley",
"4414346", "Hexham",
"441784", "Staines",
"441450", "Hawick",
"441643", "Minehead",
"441856", "Orkney",
"442829", "Kilrea",
"441580", "Cranbrook",
"441970", "Aberystwyth",
"4412292", "Barrow\-in\-Furness",
"4418476", "Tongue",
"44141", "Glasgow",
"441834", "Narberth",
"441278", "Bridgwater",
"442868", "Kesh",
"441299", "Bewdley",
"441620", "North\ Berwick",
"441380", "Devizes",
"441844", "Thame",
"441914", "Tyneside",
"44239", "Portsmouth",
"441793", "Swindon",
"441661", "Prudhoe",
"441916", "Tyneside",
"441569", "Stonehaven",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"442845", "Northern\ Ireland",
"4418518", "Stornoway",
"4414343", "Haltwhistle",
"441440", "Haverhill",
"441653", "Malton",
"442881", "Newtownstewart",
"441879", "Scarinish",
"441309", "Forres",
"441457", "Glossop",
"4419754", "Alford\ \(Aberdeen\)",
"441328", "Fakenham",
"441977", "Pontefract",
"441922", "Walsall",
"441366", "Downham\ Market",
"442311", "Southampton",
"441767", "Sandy",
"441258", "Blandford",
"4414239", "Boroughbridge",
"441283", "Burton\-on\-Trent",
"442824", "Northern\ Ireland",
"441205", "Boston",
"441506", "Bathgate",
"4416867", "Llanidloes",
"441789", "Stratford\-upon\-Avon",
"441491", "Henley\-on\-Thames",
"441642", "Middlesbrough",
"441673", "Market\ Rasen",
"4414379", "Haverfordwest",
"441395", "Budleigh\ Salterton",
"441957", "Mid\ Yell",
"442826", "Northern\ Ireland",
"441364", "Ashburton",
"441477", "Holmes\ Chapel",
"4415076", "Louth",
"441422", "Halifax",
"441700", "Rothesay",
"441859", "Harris",
"441825", "Uckfield",
"4418512", "Stornoway",
"441284", "Bury\ St\ Edmunds",
"442823", "Northern\ Ireland",
"44118", "Reading",
"441782", "Stoke\-on\-Trent",
"44247", "Coventry",
"441676", "Meriden",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441639", "Neath",
"441408", "Golspie",
"441503", "Looe",
"441531", "Ledbury",
"4414304", "North\ Cave",
"442837", "Armagh",
"441674", "Montrose",
"441455", "Hinckley",
"4412298", "Barrow\-in\-Furness",
"441852", "Kilmelford",
"441429", "Hartlepool",
"441363", "Crediton",
"442847", "Northern\ Ireland",
"441286", "Caernarfon",
"441590", "Lymington",
"44114700", "Sheffield",
"441833", "Barnard\ Castle",
"441371", "Great\ Dunmow",
"441913", "Durham",
"441207", "Consett",
"441794", "Romsey",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441765", "Ripon",
"4414231", "Harrogate\/Boroughbridge",
"441292", "Ayr",
"441843", "Thanet",
"441656", "Bridgend",
"441908", "Milton\ Keynes",
"441738", "Perth",
"441302", "Doncaster",
"441872", "Truro",
"441827", "Tamworth",
"441475", "Greenock",
"441654", "Machynlleth",
"442870", "Coleraine",
"441955", "Wick",
"441397", "Fort\ William",
"441260", "Congleton",
"441929", "Wareham",
"441796", "Pitlochry",
"441748", "Richmond",
"441562", "Kidderminster",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"4414235", "Harrogate",
"441752", "Plymouth",
"44115", "Nottingham",
"4418516", "Great\ Bernera",
"442828", "Larne",
"441381", "Fortrose",
"441335", "Ashbourne",
"441254", "Blackburn",
"441621", "Maldon",
"44286", "Northern\ Ireland",
"44114709", "Sheffield",
"441485", "Hunstanton",
"441431", "Helmsdale",
"441403", "Horsham",
"441508", "Brooke",
"441882", "Kinloch\ Rannoch",
"441529", "Sleaford",
"441555", "Lanark",
"442880", "Carrickmore",
"4418478", "Thurso",
"441368", "Dunbar",
"441962", "Winchester",
"441692", "North\ Walsham",
"441256", "Basingstoke",
"4414307", "Market\ Weighton",
"441896", "Galashiels",
"441274", "Bradford",
"441490", "Corwen",
"442895", "Belfast",
"441326", "Falmouth",
"44117", "Bristol",
"441838", "Dalmally",
"441727", "St\ Albans",
"441772", "Preston",
"4413390", "Aboyne\/Ballater",
"441918", "Tyneside",
"4415078", "Alford\ \(Lincs\)",
"4419641", "Hornsea\/Patrington",
"442310", "Portsmouth",
"441848", "Thornhill",
"441903", "Worthing",
"441733", "Peterborough",
"441575", "Kirriemuir",
"441985", "Warminster",
"441249", "Chippenham",
"441931", "Shap",
"4418903", "Coldstream",
"441684", "Malvern",
"441239", "Cardigan",
"441324", "Falkirk",
"441462", "Hitchin",
"441743", "Shrewsbury",
"441865", "Oxford",
"441276", "Camberley",
"4419645", "Hornsea",
"442866", "Enniskillen",
"4418472", "Thurso",
"441746", "Bridgnorth",
"4412296", "Barrow\-in\-Furness",
"44151", "Liverpool",
"4416973", "Wigton",
"441347", "Easingwold",
"441273", "Brighton",
"441736", "Penzance",
"441337", "Ladybank",
"441779", "Peterhead",
"441350", "Dunkeld",
"441798", "Pulborough",
"441683", "Moffat",
"441469", "Killingholme",
"4419757", "Strathdon",
"441904", "York",
"441540", "Kingussie",
"441557", "Kirkcudbright",
"441242", "Cheltenham",
"441323", "Eastbourne",
"441744", "St\ Helens",
"441487", "Warboys",
"441530", "Coalville",
"441253", "Blackpool",
"4416864", "Llanidloes",
"4419649", "Hornsea",
"441288", "Bude",
"441725", "Rockbourne",
"4418900", "Coldstream\/Ayton",
"441406", "Holbeach",
"442897", "Saintfield",
"441759", "Pocklington",
"441591", "Llanwrtyd\ Wells",
"4415396", "Sedbergh",
"441678", "Bala",
"441142", "Sheffield",
"441969", "Leyburn",
"44114702", "Sheffield",
"441404", "Honiton",
"441889", "Rugeley",
"442871", "Londonderry",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441261", "Banff",
"4413393", "Aboyne",
"4415072", "Spilsby\ \(Horncastle\)",
"441522", "Lincoln",
"441987", "Ebbsfleet",
"441577", "Kinross",
"4416868", "Newtown",
"441592", "Kirkcaldy",
"441389", "Dumbarton",
"4414349", "Bellingham",
"441766", "Porthmadog",
"441290", "Cumnock",
"441629", "Matlock",
"441367", "Faringdon",
"441474", "Gravesend",
"441655", "Maybole",
"441954", "Madingley",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441608", "Chipping\ Norton",
"442827", "Ballymoney",
"441795", "Sittingbourne",
"441439", "Helmsley",
"441262", "Bridlington",
"441870", "Isle\ of\ Benbecula",
"441764", "Crieff",
"441300", "Cerne\ Abbas",
"441476", "Grantham",
"441141", "Sheffield",
"441449", "Stowmarket",
"441560", "Moscow",
"441780", "Stamford",
"4414306", "Market\ Weighton",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441823", "Taunton",
"441584", "Ludlow",
"441974", "Llanon",
"441675", "Coleshill",
"441454", "Chipping\ Sodbury",
"4417687", "Keswick",
"441456", "Glenurquhart",
"441709", "Rotherham",
"441939", "Wem",
"441241", "Arbroath",
"441837", "Okehampton",
"4414233", "Boroughbridge",
"441728", "Saxmundham",
"4413873", "Langholm",
"441586", "Campbeltown",
"441917", "Sunderland",
"441285", "Cirencester",
"441949", "Whatton",
"4418517", "Stornoway",
"441630", "Market\ Drayton",
"441394", "Felixstowe",
"44291", "Cardiff",
"441206", "Colchester",
"441824", "Ruthin",
"441453", "Dursley",
"441558", "Llandeilo",
"441488", "Hungerford",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"44283", "Northern\ Ireland",
"441771", "Maud",
"441505", "Johnstone",
"441583", "Carradale",
"4415074", "Alford\ \(Lincs\)",
"441461", "Gretna",
"441348", "Fishguard",
"441942", "Wigan",
"4416862", "Llanidloes",
"441702", "Southend\-on\-Sea",
"441932", "Weybridge",
"441420", "Alton",
"4414345", "Haltwhistle",
"44161", "Manchester",
"441797", "Rye",
"442825", "Ballymena",
"441204", "Bolton",
"44241", "Coventry",
"441677", "Bedale",
"441622", "Maidstone",
"441953", "Wymondham",
"4414230", "Harrogate\/Boroughbridge",
"441751", "Pickering",
"442844", "Downpatrick",
"441578", "Lauder",
"441988", "Wigtown",
"441382", "Dundee",
"441473", "Ipswich",
"4419756", "Strathdon",
"441599", "Kyle",
"441763", "Royston",
"441442", "Hemel\ Hempstead",
"441691", "Oswestry",
"4418474", "Thurso",
"441845", "Thirsk",
"441287", "Guisborough",
"441915", "Sunderland",
"442846", "Northern\ Ireland",
"441269", "Ammanford",
"442898", "Belfast",
"441920", "Ware",
"441432", "Hereford",
"442879", "Magherafelt",
"441835", "St\ Boswells",
"4412297", "Millom",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"4415077", "Louth",
"441687", "Mallaig",
"441291", "Chepstow",
"441458", "Glastonbury",
"441553", "Kings\ Lynn",
"441483", "Guildford",
"441669", "Rothbury",
"441726", "St\ Austell",
"441405", "Goole",
"441372", "Esher",
"441327", "Daventry",
"441978", "Wrexham",
"441588", "Bishops\ Castle",
"441343", "Elgin",
"441724", "Scunthorpe",
"441561", "Laurencekirk",
"442867", "Lisnaskea",
"441140", "Sheffield",
"4416866", "Newtown",
"441277", "Brentwood",
"442889", "Fivemiletown",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441871", "Castlebay",
"441301", "Arrochar",
"441520", "Lochcarron",
"44114703", "Sheffield",
"4415394", "Hawkshead",
"4413391", "Aboyne\/Ballater",
"441745", "Rhyl",
"441863", "Ardgay",
"4418909", "Ayton",
"44121", "Birmingham",
"4419640", "Hornsea\/Patrington",
"441352", "Mold",
"441604", "Northampton",
"441499", "Inveraray",
"441905", "Worcester",
"441573", "Kelso",
"441983", "Isle\ of\ Wight",
"4419752", "Alford\ \(Aberdeen\)",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441768", "Penrith",
"441257", "Coppull",
"4412294", "Barrow\-in\-Furness",
"4413395", "Aboyne",
"441542", "Keith",
"4414308", "Market\ Weighton",
"441606", "Northwich",
"442893", "Ballyclare",
"4418477", "Tongue",
"442896", "Belfast",
"441325", "Darlington",
"441864", "Abington\ \(Crawford\)",
"441770", "Isle\ of\ Arran",
"441359", "Pakenham",
"441407", "Holyhead",
"441895", "Uxbridge",
"442838", "Portadown",
"441492", "Colwyn\ Bay",
"441641", "Strathy",
"441984", "Watchet\ \(Williton\)",
"441685", "Merthyr\ Tydfil",
"441631", "Oban",
"442848", "Northern\ Ireland",
"441603", "Norwich",
"441539", "Kendal",
"441576", "Lockerbie",
"441986", "Bungay",
"441549", "Lairg",
"441275", "Clevedon",
"442894", "Antrim",
"441460", "Chard",
"441866", "Kilchrenan",
"4414302", "North\ Cave",
"441737", "Redhill",
"441828", "Coupar\ Angus",
"441379", "Diss",
"441750", "Selkirk",
"441809", "Tomdoun",
"441992", "Lea\ Valley",
"441398", "Dulverton",
"441484", "Huddersfield",
"4413399", "Ballater",
"441346", "Fraserburgh",
"441747", "Shaftesbury",
"4413885", "Stanhope\ \(Eastgate\)",
"4418901", "Coldstream\/Ayton",
"441554", "Llanelli",
"4418514", "Great\ Bernera",
"441556", "Castle\ Douglas",
"442882", "Omagh",
"441344", "Bracknell",
"4419643", "Patrington",
"441723", "Scarborough",
"441880", "Tarbert",
"4419758", "Strathdon",
"441208", "Bodmin",
"441690", "Betws\-y\-Coed",
"4418905", "Ayton",
"441334", "St\ Andrews",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"4417684", "Pooley\ Bridge",
"441255", "Clacton\-on\-Sea",};
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
      $number =~ s/^(?:([0-24-8]\d{5})$|0|180020)//;
      $self = bless({ country_code => '44', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;