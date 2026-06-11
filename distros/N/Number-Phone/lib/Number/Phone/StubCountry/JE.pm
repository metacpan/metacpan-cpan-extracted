# automatically generated file, don't edit



# Copyright 2026 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20260610205503;

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
$areanames{en} = {"441806", "Shetland",
"441571", "Lochinver",
"441573", "Kelso",
"441271", "Barnstaple",
"441273", "Brighton",
"44118", "Reading",
"442867", "Lisnaskea",
"441864", "Abington\ \(Crawford\)",
"441931", "Shap",
"4418510", "Great\ Bernera\/Stornoway",
"441933", "Wellingborough",
"441325", "Darlington",
"442868", "Kesh",
"441829", "Tarporley",
"4414300", "North\ Cave\/Market\ Weighton",
"442310", "Portsmouth",
"441549", "Lairg",
"441249", "Chippenham",
"441947", "Whitby",
"441753", "Slough",
"441751", "Pickering",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441948", "Whitchurch",
"4415076", "Louth",
"4413882", "Stanhope\ \(Eastgate\)",
"441862", "Tain",
"441967", "Strontian",
"441269", "Ammanford",
"441475", "Greenock",
"441569", "Stonehaven",
"441842", "Thetford",
"441224", "Aberdeen",
"441968", "Penicuik",
"441524", "Lancaster",
"441756", "Skipton",
"441675", "Coleshill",
"4419757", "Strathdon",
"441520", "Lochcarron",
"441885", "Pencombe",
"441522", "Lincoln",
"441389", "Dumbarton",
"442847", "Northern\ Ireland",
"441458", "Glastonbury",
"441844", "Thame",
"441896", "Galashiels",
"441457", "Glossop",
"442848", "Northern\ Ireland",
"4414235", "Harrogate",
"4419758", "Strathdon",
"441803", "Torquay",
"441276", "Camberley",
"441576", "Lockerbie",
"441840", "Camelford",
"4414377", "Haverfordwest",
"442890", "Belfast",
"441578", "Lauder",
"441278", "Bridgwater",
"4417687", "Keswick",
"441277", "Brentwood",
"441902", "Wolverhampton",
"441577", "Kinross",
"441239", "Cardigan",
"441539", "Kendal",
"441656", "Bridgend",
"441775", "Spalding",
"441937", "Wetherby",
"442846", "Northern\ Ireland",
"442894", "Antrim",
"441456", "Glenurquhart",
"441938", "Welshpool",
"4416866", "Newtown",
"4414378", "Haverfordwest",
"441904", "York",
"441555", "Lanark",
"441255", "Clacton\-on\-Sea",
"4413395", "Aboyne",
"44291", "Cardiff",
"44114709", "Sheffield",
"441943", "Guiseley",
"442892", "Lisburn",
"441758", "Pwllheli",
"441900", "Workington",
"441757", "Selby",
"441963", "Wincanton",
"441834", "Narberth",
"442837", "Armagh",
"441946", "Whitehaven",
"441994", "St\ Clears",
"442838", "Portadown",
"4418511", "Great\ Bernera\/Stornoway",
"4412296", "Barrow\-in\-Furness",
"442879", "Magherafelt",
"441352", "Mold",
"441830", "Kirkwhelpington",
"442866", "Enniskillen",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441651", "Oldmeldrum",
"441653", "Malton",
"442843", "Newcastle\ \(Co\.\ Down\)",
"442841", "Rostrevor",
"441992", "Lea\ Valley",
"441451", "Stow\-on\-the\-Wold",
"441832", "Clopton",
"441453", "Dursley",
"441350", "Dunkeld",
"441807", "Ballindalloch",
"441354", "Chatteris",
"4414301", "North\ Cave\/Market\ Weighton",
"441808", "Tomatin",
"442820", "Ballycastle",
"441782", "Stoke\-on\-Trent",
"441971", "Scourie",
"4419759", "Alford\ \(Aberdeen\)",
"4415394", "Hawkshead",
"441531", "Ledbury",
"441233", "Ashford\ \(Kent\)",
"441828", "Coupar\ Angus",
"441827", "Tamworth",
"442824", "Northern\ Ireland",
"4418515", "Stornoway",
"4418906", "Ayton",
"4415242", "Hornby",
"441784", "Staines",
"441745", "Rhyl",
"4414305", "North\ Cave",
"441780", "Stamford",
"441949", "Whatton",
"441547", "Knighton",
"4414345", "Haltwhistle",
"442822", "Northern\ Ireland",
"441248", "Bangor\ \(Gwynedd\)",
"441548", "Kingsbridge",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441267", "Carmarthen",
"441567", "Killin",
"441969", "Leyburn",
"441924", "Wakefield",
"441568", "Leominster",
"441268", "Basildon",
"4417683", "Appleby",
"441920", "Ware",
"441635", "Newbury",
"442871", "Londonderry",
"441765", "Ripon",
"441435", "Heathfield",
"441659", "Sanquhar",
"441387", "Dumfries",
"442849", "Northern\ Ireland",
"441236", "Coatbridge",
"441536", "Kettering",
"4414230", "Harrogate\/Boroughbridge",
"441922", "Walsall",
"441388", "Bishop\ Auckland",
"4413391", "Aboyne\/Ballater",
"441665", "Alnwick",
"441978", "Wrexham",
"441279", "Bishops\ Stortford",
"441465", "Girvan",
"441579", "Liskeard",
"441977", "Pontefract",
"441202", "Bournemouth",
"441502", "Lowestoft",
"4419753", "Strathdon",
"441939", "Wem",
"441386", "Evesham",
"441237", "Bideford",
"441395", "Budleigh\ Salterton",
"441823", "Taunton",
"441821", "Kinrossie",
"441899", "Biggar",
"441538", "Ipstones",
"4413390", "Aboyne\/Ballater",
"441204", "Bolton",
"441955", "Wick",
"441241", "Arbroath",
"441243", "Chichester",
"441543", "Cannock",
"441566", "Launceston",
"441759", "Pocklington",
"4414231", "Harrogate\/Boroughbridge",
"441200", "Clitheroe",
"441144", "Sheffield",
"441546", "Lochgilphead",
"441870", "Isle\ of\ Benbecula",
"441246", "Chesterfield",
"441563", "Kilmarnock",
"441561", "Laurencekirk",
"441261", "Banff",
"441263", "Cromer",
"441294", "Ardrossan",
"441594", "Lydney",
"441290", "Cumnock",
"441590", "Lymington",
"441482", "Kingston\-upon\-Hull",
"441140", "Sheffield",
"4414379", "Haverfordwest",
"442877", "Limavady",
"441874", "Brecon",
"4419646", "Patrington",
"441480", "Huntingdon",
"441383", "Dunfermline",
"441592", "Kirkcaldy",
"441381", "Fortrose",
"441292", "Ayr",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441142", "Sheffield",
"441684", "Malvern",
"441305", "Dorchester",
"441872", "Truro",
"441809", "Tomdoun",
"4418476", "Tongue",
"441484", "Huddersfield",
"441445", "Gairloch",
"441957", "Mid\ Yell",
"441636", "Newark\-on\-Trent",
"441700", "Rothesay",
"441259", "Alloa",
"441559", "Llandysul",
"441436", "Helensburgh",
"441766", "Porthmadog",
"441743", "Shrewsbury",
"441704", "Southport",
"441738", "Perth",
"441667", "Nairn",
"441737", "Redhill",
"441467", "Inverurie",
"441668", "Bamburgh",
"441535", "Keighley",
"441702", "Southend\-on\-Sea",
"441235", "Abingdon",
"441779", "Peterhead",
"441398", "Dulverton",
"441397", "Fort\ William",
"4414236", "Harrogate",
"4418900", "Coldstream\/Ayton",
"441332", "Derby",
"441854", "Ullapool",
"441647", "Moretonhampstead",
"441307", "Forfar",
"441792", "Swansea",
"4419641", "Hornsea\/Patrington",
"44131", "Edinburgh",
"441308", "Bridport",
"441334", "St\ Andrews",
"4415075", "Spilsby\ \(Horncastle\)",
"441790", "Spilsby",
"441631", "Oban",
"441633", "Newport",
"441794", "Romsey",
"441761", "Temple\ Cloud",
"441330", "Banchory",
"441763", "Royston",
"441746", "Bridgnorth",
"4418471", "Thurso\/Tongue",
"441433", "Hathersage",
"44286", "Northern\ Ireland",
"441431", "Helmsdale",
"441852", "Kilmelford",
"441692", "North\ Walsham",
"441748", "Richmond",
"4412295", "Barrow\-in\-Furness",
"441951", "Colonsay",
"441953", "Wymondham",
"4419640", "Hornsea\/Patrington",
"441492", "Colwyn\ Bay",
"441747", "Shaftesbury",
"441580", "Cranbrook",
"441280", "Buckingham",
"441245", "Chelmsford",
"441545", "Llanarth",
"441584", "Ludlow",
"441284", "Bury\ St\ Edmunds",
"4418901", "Coldstream\/Ayton",
"441362", "Dereham",
"441661", "Prudhoe",
"441663", "New\ Mills",
"4418470", "Thurso\/Tongue",
"441646", "Milford\ Haven",
"441494", "High\ Wycombe",
"441306", "Dorking",
"44283", "Northern\ Ireland",
"441463", "Inverness",
"441461", "Gretna",
"441446", "Barry",
"441360", "Killearn",
"441733", "Peterborough",
"441694", "Church\ Stretton",
"441364", "Ashburton",
"441690", "Betws\-y\-Coed",
"441282", "Burnley",
"441582", "Luton",
"441329", "Fareham",
"4419467", "Gosforth",
"441490", "Corwen",
"441825", "Uckfield",
"44241", "Coventry",
"441344", "Bracknell",
"441889", "Rugeley",
"441914", "Tyneside",
"441604", "Northampton",
"4416865", "Newtown",
"441404", "Honiton",
"441301", "Arrochar",
"441303", "Folkestone",
"441400", "Honington",
"441666", "Malmesbury",
"441641", "Strathy",
"441643", "Minehead",
"4413873", "Langholm",
"441340", "Craigellachie\ \(Aberlour\)",
"441736", "Penzance",
"441910", "Tyneside\/Durham\/Sunderland",
"441600", "Monmouth",
"441466", "Huntly",
"441443", "Pontypridd",
"44114702", "Sheffield",
"441479", "Grantown\-on\-Spey",
"441565", "Knutsford",
"441912", "Tyneside",
"441342", "East\ Grinstead",
"441438", "Stevenage",
"441637", "Newquay",
"441768", "Penrith",
"441638", "Newmarket",
"4413396", "Ballater",
"441767", "Sandy",
"441622", "Maidstone",
"441257", "Coppull",
"441557", "Kirkcudbright",
"441959", "Westerham",
"441558", "Llandeilo",
"441258", "Blandford",
"441422", "Halifax",
"441476", "Grantham",
"441676", "Meriden",
"4416861", "Newtown\/Llanidloes",
"441669", "Rothbury",
"441424", "Hastings",
"44292", "Cardiff",
"441575", "Kirriemuir",
"441469", "Killingholme",
"441275", "Clevedon",
"441624", "Isle\ of\ Man",
"441935", "Yeovil",
"441777", "Retford",
"441620", "North\ Berwick",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441778", "Bourne",
"441323", "Eastbourne",
"441420", "Alton",
"441895", "Uxbridge",
"441883", "Caterham",
"4418516", "Great\ Bernera",
"441326", "Falmouth",
"4418905", "Ayton",
"441309", "Forres",
"4412291", "Barrow\-in\-Furness\/Millom",
"441372", "Esher",
"441805", "Torrington",
"441449", "Stowmarket",
"4414374", "Clynderwen\ \(Clunderwen\)",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441473", "Ipswich",
"4414346", "Hexham",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"4417684", "Pooley\ Bridge",
"441671", "Newton\ Stewart",
"441673", "Market\ Rasen",
"4414306", "Market\ Weighton",
"4419752", "Alford\ \(Aberdeen\)",
"44114700", "Sheffield",
"441553", "Kings\ Lynn",
"441253", "Blackpool",
"4412290", "Barrow\-in\-Furness\/Millom",
"4419645", "Hornsea",
"441980", "Amesbury",
"441749", "Shepton\ Mallet",
"441945", "Wisbech",
"441984", "Watchet\ \(Williton\)",
"4418475", "Thurso",
"4414372", "Clynderwen\ \(Clunderwen\)",
"44287", "Northern\ Ireland",
"441773", "Ripley",
"441771", "Maud",
"441328", "Fakenham",
"4419754", "Alford\ \(Aberdeen\)",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441982", "Builth\ Wells",
"441327", "Daventry",
"442845", "Northern\ Ireland",
"441776", "Stranraer",
"441655", "Maybole",
"442884", "Northern\ Ireland",
"441887", "Aberfeldy",
"4416860", "Newtown\/Llanidloes",
"441455", "Hinckley",
"441888", "Turriff",
"441722", "Salisbury",
"442880", "Carrickmore",
"441477", "Holmes\ Chapel",
"441678", "Bala",
"441677", "Bedale",
"442882", "Omagh",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441720", "Isles\ of\ Scilly",
"441256", "Basingstoke",
"441556", "Castle\ Douglas",
"441724", "Scunthorpe",
"441639", "Neath",
"441769", "South\ Molton",
"441439", "Helmsley",
"441903", "Worthing",
"441789", "Stratford\-upon\-Avon",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441985", "Warminster",
"441944", "West\ Heslerton",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"4415074", "Alford\ \(Lincs\)",
"441356", "Brechin",
"4412292", "Barrow\-in\-Furness",
"441942", "Wigan",
"4414233", "Boroughbridge",
"442829", "Kilrea",
"442891", "Bangor\ \(Co\.\ Down\)",
"442893", "Ballyclare",
"442885", "Ballygawley",
"44114707", "Sheffield",
"441654", "Machynlleth",
"442844", "Downpatrick",
"442896", "Belfast",
"441848", "Thornhill",
"441454", "Chipping\ Sodbury",
"441962", "Winchester",
"441353", "Ely",
"441450", "Hawick",
"44114708", "Sheffield",
"441650", "Cemmaes\ Road",
"442840", "Banbridge",
"441528", "Laggan",
"441228", "Carlisle",
"441452", "Gloucester",
"441833", "Barnard\ Castle",
"4413399", "Ballater",
"442842", "Kircubbin",
"441227", "Canterbury",
"441652", "Brigg",
"441527", "Redditch",
"441929", "Wareham",
"441993", "Witney",
"441725", "Rockbourne",
"44239", "Portsmouth",
"4416862", "Llanidloes",
"441572", "Oakham",
"4414348", "Hexham",
"441750", "Selkirk",
"441509", "Loughborough",
"441209", "Redruth",
"441908", "Milton\ Keynes",
"4418517", "Stornoway",
"442311", "Southampton",
"441892", "Tunbridge\ Wells",
"4414308", "Market\ Weighton",
"441932", "Weybridge",
"441226", "Barnsley",
"441526", "Martin",
"441754", "Skegness",
"4414347", "Hexham",
"4414239", "Boroughbridge",
"441425", "Ringwood",
"441625", "Macclesfield",
"441274", "Bradford",
"4418518", "Stornoway",
"442898", "Belfast",
"441752", "Plymouth",
"441863", "Ardgay",
"441934", "Weston\-super\-Mare",
"441270", "Crewe",
"441570", "Lampeter",
"4414307", "Market\ Weighton",
"442897", "Saintfield",
"4416864", "Llanidloes",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441866", "Kilchrenan",
"441841", "Newquay\ \(Padstow\)",
"441843", "Thanet",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441689", "Orpington",
"4415072", "Spilsby\ \(Horncastle\)",
"441357", "Strathaven",
"44281", "Northern\ Ireland",
"441489", "Bishops\ Waltham",
"441358", "Ellon",
"441837", "Okehampton",
"441997", "Strathpeffer",
"441299", "Bewdley",
"441599", "Kyle",
"441838", "Dalmally",
"441223", "Cambridge",
"4412294", "Barrow\-in\-Furness",
"441879", "Scarinish",
"441375", "Grays\ Thurrock",
"442830", "Newry",
"4413393", "Aboyne",
"441788", "Rugby",
"441503", "Looe",
"441501", "Harthill",
"441787", "Sudbury",
"441540", "Kingussie",
"441876", "Lochmaddy",
"441146", "Sheffield",
"441285", "Cirencester",
"4418472", "Thurso",
"441544", "Kington",
"441244", "Chester",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441822", "Tavistock",
"441296", "Aylesbury",
"4413398", "Aboyne",
"441495", "Pontypool",
"441695", "Skelmersdale",
"4415396", "Sedbergh",
"442828", "Larne",
"4416973", "Wigton",
"441869", "Bicester",
"4419642", "Hornsea",
"442827", "Ballymoney",
"441824", "Ruthin",
"441242", "Cheltenham",
"441542", "Keith",
"4418904", "Coldstream",
"4413397", "Ballater",
"441384", "Dudley",
"441915", "Sunderland",
"441405", "Goole",
"441562", "Kidderminster",
"441262", "Bridlington",
"4418513", "Stornoway",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441683", "Moffat",
"441380", "Devizes",
"441483", "Guildford",
"441481", "Guernsey",
"44114704", "Sheffield",
"4414343", "Haltwhistle",
"441264", "Andover",
"441928", "Runcorn",
"441564", "Lapworth",
"441143", "Sheffield",
"441141", "Sheffield",
"441593", "Lybster",
"441382", "Dundee",
"441591", "Llanwrtyd\ Wells",
"441293", "Crawley",
"441291", "Chepstow",
"441529", "Sleaford",
"441506", "Bathgate",
"441206", "Colchester",
"441871", "Castlebay",
"441873", "Abergavenny",
"4414303", "North\ Cave",
"441260", "Congleton",
"441560", "Moscow",
"441207", "Consett",
"441972", "Glenborrodale",
"441909", "Worksop",
"441208", "Bodmin",
"441508", "Brooke",
"44121", "Birmingham",
"44151", "Liverpool",
"441926", "Warwick",
"441974", "Llanon",
"441530", "Coalville",
"44247", "Coventry",
"441234", "Bedford",
"441970", "Aberystwyth",
"441534", "Jersey",
"44115", "Nottingham",
"442823", "Northern\ Ireland",
"442821", "Martinstown",
"442899", "Northern\ Ireland",
"4419755", "Alford\ \(Aberdeen\)",
"442826", "Northern\ Ireland",
"441687", "Mallaig",
"441488", "Hungerford",
"441359", "Pakenham",
"4418519", "Great\ Bernera",
"441855", "Ballachulish",
"4418474", "Thurso",
"441487", "Warboys",
"4414238", "Harrogate",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441598", "Lynton",
"4414309", "Market\ Weighton",
"441298", "Buxton",
"442870", "Coleraine",
"441335", "Ashbourne",
"441297", "Axminster",
"441597", "Llandrindod\ Wells",
"441923", "Watford",
"441795", "Sittingbourne",
"4418902", "Coldstream",
"441878", "Lochboisdale",
"441786", "Stirling",
"4414349", "Bellingham",
"4414237", "Harrogate",
"441877", "Callander",
"4419644", "Patrington",
"441429", "Hartlepool",
"4416869", "Newtown",
"441493", "Great\ Yarmouth",
"441491", "Henley\-on\-Thames",
"441664", "Melton\ Mowbray",
"441629", "Matlock",
"441691", "Oswestry",
"441464", "Insch",
"441952", "Telford",
"441346", "Fraserburgh",
"4413392", "Aboyne",
"441363", "Crediton",
"441916", "Tyneside",
"441730", "Petersfield",
"441361", "Duns",
"441460", "Chard",
"441606", "Northwich",
"4419647", "Patrington",
"441394", "Felixstowe",
"4418478", "Thurso",
"441406", "Holbeach",
"4414234", "Boroughbridge",
"441954", "Madingley",
"441462", "Hitchin",
"441205", "Boston",
"441732", "Sevenoaks",
"441505", "Johnstone",
"441283", "Burton\-on\-Trent",
"441583", "Carradale",
"441581", "New\ Luce",
"441392", "Exeter",
"44117", "Bristol",
"441708", "Romford",
"441950", "Sandwick",
"4415073", "Louth",
"4419648", "Hornsea",
"441707", "Welwyn\ Garden\ City",
"4418477", "Tongue",
"441337", "Ladybank",
"441586", "Campbeltown",
"441286", "Caernarfon",
"441145", "Sheffield",
"4412299", "Millom",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441295", "Banbury",
"441442", "Hemel\ Hempstead",
"441797", "Rye",
"441302", "Doncaster",
"441875", "Tranent",
"441798", "Pulborough",
"441642", "Middlesbrough",
"441379", "Diss",
"441603", "Norwich",
"441440", "Haverhill",
"441341", "Barmouth",
"441343", "Elgin",
"441911", "Tyneside\/Durham\/Sunderland",
"441913", "Durham",
"441366", "Downham\ Market",
"441403", "Horsham",
"441300", "Cerne\ Abbas",
"441857", "Sanday",
"441644", "New\ Galloway",
"441496", "Port\ Ellen",
"441304", "Dover",
"441685", "Merthyr\ Tydfil",
"441858", "Market\ Harborough",
"441444", "Haywards\ Heath",
"441485", "Hunstanton",
"441856", "Orkney",
"4413885", "Stanhope\ \(Eastgate\)",
"441698", "Motherwell",
"441497", "Hay\-on\-Wye",
"441697", "Brampton",
"441367", "Faringdon",
"4416863", "Llanidloes",
"441368", "Dunbar",
"442825", "Ballymena",
"44114701", "Sheffield",
"4415079", "Alford\ \(Lincs\)",
"441796", "Pitlochry",
"441744", "St\ Helens",
"441785", "Stafford",
"441989", "Ross\-on\-Wye",
"441740", "Sedgefield",
"441287", "Guisborough",
"441288", "Bude",
"441588", "Bishops\ Castle",
"44280", "Northern\ Ireland",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441760", "Swaffham",
"441630", "Market\ Drayton",
"441706", "Rochdale",
"441925", "Warrington",
"441729", "Settle",
"441793", "Swindon",
"441634", "Medway",
"4412293", "Millom",
"4414232", "Harrogate",
"4418907", "Ayton",
"4413394", "Ballater",
"441764", "Crieff",
"44141", "Glasgow",
"441347", "Easingwold",
"442889", "Fivemiletown",
"441917", "Sunderland",
"441408", "Golspie",
"441918", "Tyneside",
"44161", "Manchester",
"441348", "Fishguard",
"441407", "Holyhead",
"441608", "Chipping\ Norton",
"441432", "Hereford",
"4418908", "Coldstream",
"441427", "Gainsborough",
"441628", "Maidenhead",
"441770", "Isle\ of\ Arran",
"441252", "Aldershot",
"441428", "Haslemere",
"4416974", "Raughton\ Head",
"4412297", "Millom",
"442886", "Cookstown",
"4418903", "Coldstream",
"442895", "Belfast",
"441254", "Blackburn",
"441554", "Llanelli",
"441726", "St\ Austell",
"441905", "Worcester",
"44238", "Southampton",
"44113", "Leeds",
"441981", "Wormbridge",
"441983", "Isle\ of\ Wight",
"4412298", "Barrow\-in\-Furness",
"441709", "Rotherham",
"441250", "Blairgowrie",
"441550", "Llandovery",
"441772", "Preston",
"4419649", "Hornsea",
"441835", "St\ Boswells",
"4414344", "Bellingham",
"441986", "Bungay",
"4414376", "Haverfordwest",
"44114703", "Sheffield",
"4420", "London",
"441995", "Garstang",
"441723", "Scarborough",
"441721", "Peebles",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441799", "Saffron\ Walden",
"4416867", "Llanidloes",
"441377", "Driffield",
"4414304", "North\ Cave",
"442883", "Northern\ Ireland",
"442881", "Newtownstewart",
"4418479", "Tongue",
"4418514", "Great\ Bernera",
"441355", "East\ Kilbride",
"441859", "Harris",
"4416868", "Newtown",
"4415395", "Grange\-over\-Sands",
"441499", "Inveraray",
"4418909", "Ayton",
"441320", "Fort\ Augustus",
"441623", "Mansfield",
"441621", "Maldon",
"4414342", "Bellingham",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441369", "Dunoon",
"4419756", "Strathdon",
"4414302", "North\ Cave",
"441865", "Oxford",
"441324", "Falkirk",
"4418512", "Stornoway",
"44114705", "Sheffield",
"441376", "Braintree",
"441322", "Dartford",
"441289", "Berwick\-upon\-Tweed",
"441987", "Ebbsfleet",
"441988", "Wigtown",
"441474", "Gravesend",
"441674", "Montrose",
"441882", "Kinloch\ Rannoch",
"441525", "Leighton\ Buzzard",
"441225", "Bath",
"441670", "Morpeth",
"441727", "St\ Albans",
"4415078", "Alford\ \(Lincs\)",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"4419643", "Patrington",
"441728", "Saxmundham",
"441373", "Frome",
"441371", "Great\ Dunmow",
"441845", "Thirsk",
"441609", "Northallerton",
"441349", "Dingwall",
"442887", "Dungannon",
"441884", "Tiverton",
"441672", "Marlborough",
"441919", "Durham",
"441409", "Holsworthy",
"442888", "Northern\ Ireland",
"441472", "Grimsby",
"4415077", "Louth",
"44116", "Leicester",
"4418473", "Thurso",
"441880", "Tarbert",
"441626", "Newton\ Abbot",};
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