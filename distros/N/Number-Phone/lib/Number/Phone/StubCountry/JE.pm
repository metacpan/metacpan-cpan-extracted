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
our $VERSION = 1.20251210153523;

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
$areanames{en} = {"4416974", "Raughton\ Head",
"441562", "Kidderminster",
"441674", "Montrose",
"441963", "Wincanton",
"441942", "Wigan",
"441270", "Crewe",
"441540", "Kingussie",
"441524", "Lancaster",
"441469", "Killingholme",
"441726", "St\ Austell",
"441273", "Brighton",
"441892", "Tunbridge\ Wells",
"441543", "Cannock",
"441256", "Basingstoke",
"441828", "Coupar\ Angus",
"441485", "Hunstanton",
"441933", "Wellingborough",
"4415079", "Alford\ \(Lincs\)",
"4414303", "North\ Cave",
"441439", "Helmsley",
"441424", "Hastings",
"441440", "Haverhill",
"441443", "Pontypridd",
"4418512", "Stornoway",
"441569", "Stonehaven",
"441899", "Biggar",
"441462", "Hitchin",
"441327", "Daventry",
"441949", "Whatton",
"442891", "Bangor\ \(Co\.\ Down\)",
"4412291", "Barrow\-in\-Furness\/Millom",
"4418903", "Coldstream",
"442847", "Northern\ Ireland",
"441955", "Wick",
"441539", "Kendal",
"441432", "Hereford",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441843", "Thanet",
"441592", "Kirkcaldy",
"441727", "St\ Albans",
"441993", "Witney",
"441915", "Sunderland",
"441824", "Ruthin",
"4415076", "Louth",
"441840", "Camelford",
"441862", "Tain",
"4416865", "Newtown",
"441499", "Inveraray",
"441678", "Bala",
"4413882", "Stanhope\ \(Eastgate\)",
"441832", "Clopton",
"441528", "Laggan",
"441257", "Coppull",
"442846", "Northern\ Ireland",
"4414345", "Haltwhistle",
"441326", "Falmouth",
"441599", "Kyle",
"441492", "Colwyn\ Bay",
"441869", "Bicester",
"441885", "Pencombe",
"441428", "Haslemere",
"441606", "Northwich",
"4414349", "Bellingham",
"441233", "Ashford\ \(Kent\)",
"441302", "Doncaster",
"441784", "Staines",
"441634", "Medway",
"441981", "Wormbridge",
"441698", "Motherwell",
"441887", "Aberfeldy",
"441586", "Campbeltown",
"441622", "Maidstone",
"441479", "Grantown\-on\-Spey",
"441263", "Cromer",
"44121", "Birmingham",
"441260", "Congleton",
"4419641", "Hornsea\/Patrington",
"4419758", "Strathdon",
"441664", "Melton\ Mowbray",
"441970", "Aberystwyth",
"441242", "Cheltenham",
"441572", "Oakham",
"441255", "Clacton\-on\-Sea",
"441309", "Forres",
"441451", "Stow\-on\-the\-Wold",
"4416869", "Newtown",
"4414231", "Harrogate\/Boroughbridge",
"441388", "Bishop\ Auckland",
"441472", "Grimsby",
"441629", "Matlock",
"441579", "Liskeard",
"441917", "Sunderland",
"441249", "Chippenham",
"4418478", "Thurso",
"441725", "Rockbourne",
"44114709", "Sheffield",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"4413394", "Ballater",
"4419757", "Strathdon",
"441957", "Mid\ Yell",
"44114705", "Sheffield",
"441709", "Rotherham",
"441668", "Bamburgh",
"442845", "Northern\ Ireland",
"441293", "Crawley",
"441325", "Darlington",
"441872", "Truro",
"441290", "Cumnock",
"441694", "Church\ Stretton",
"441788", "Rugby",
"4414346", "Hexham",
"441638", "Newmarket",
"4415242", "Hornby",
"442883", "Northern\ Ireland",
"442880", "Carrickmore",
"441384", "Dudley",
"441487", "Warboys",
"441702", "Southend\-on\-Sea",
"4418477", "Tongue",
"4416866", "Newtown",
"442871", "Londonderry",
"441879", "Scarinish",
"441916", "Tyneside",
"4415075", "Spilsby\ \(Horncastle\)",
"441676", "Meriden",
"441743", "Shrewsbury",
"441827", "Tamworth",
"441526", "Martin",
"441724", "Scunthorpe",
"441740", "Sedgefield",
"4412298", "Barrow\-in\-Furness",
"441254", "Blackburn",
"441732", "Sevenoaks",
"441653", "Malton",
"441650", "Cemmaes\ Road",
"441769", "South\ Molton",
"441608", "Chipping\ Norton",
"441665", "Alnwick",
"441392", "Exeter",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441689", "Orpington",
"442848", "Northern\ Ireland",
"441328", "Fakenham",
"441785", "Stafford",
"44114702", "Sheffield",
"441635", "Newbury",
"441792", "Swansea",
"441527", "Redditch",
"441258", "Blandford",
"441677", "Bedale",
"441369", "Dunoon",
"441728", "Saxmundham",
"4418514", "Great\ Bernera",
"4416860", "Newtown\/Llanidloes",
"4412297", "Millom",
"442844", "Downpatrick",
"442820", "Ballycastle",
"441340", "Craigellachie\ \(Aberlour\)",
"441799", "Saffron\ Walden",
"441324", "Falkirk",
"442823", "Northern\ Ireland",
"441343", "Elgin",
"441362", "Dereham",
"441695", "Skelmersdale",
"441427", "Gainsborough",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441604", "Northampton",
"441332", "Derby",
"441200", "Clitheroe",
"441954", "Madingley",
"441809", "Tomdoun",
"44115", "Nottingham",
"441751", "Pickering",
"441786", "Stirling",
"441636", "Newark\-on\-Trent",
"441584", "Ludlow",
"4414376", "Haverfordwest",
"4414238", "Harrogate",
"441425", "Ringwood",
"441641", "Strathy",
"441697", "Brampton",
"441888", "Turriff",
"441772", "Preston",
"441666", "Malmesbury",
"4418471", "Thurso\/Tongue",
"4415394", "Hawkshead",
"441918", "Tyneside",
"441484", "Huddersfield",
"441387", "Dumfries",
"441675", "Coleshill",
"4413392", "Aboyne",
"4419648", "Hornsea",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441525", "Leighton\ Buzzard",
"441779", "Peterhead",
"4414237", "Harrogate",
"441884", "Tiverton",
"441637", "Newquay",
"441787", "Sudbury",
"441509", "Loughborough",
"4414379", "Haverfordwest",
"441379", "Diss",
"441667", "Nairn",
"441588", "Bishops\ Castle",
"441409", "Holsworthy",
"441386", "Evesham",
"4419647", "Patrington",
"441903", "Worthing",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441502", "Lowestoft",
"441900", "Workington",
"441488", "Hungerford",
"441372", "Esher",
"441914", "Tyneside",
"441825", "Uckfield",
"441142", "Sheffield",
"4418479", "Tongue",
"4416973", "Wigton",
"441925", "Warrington",
"442310", "Portsmouth",
"4416868", "Newtown",
"441357", "Strathaven",
"441803", "Torquay",
"4414304", "North\ Cave",
"441454", "Chipping\ Sodbury",
"441646", "Milford\ Haven",
"4419759", "Alford\ \(Aberdeen\)",
"441770", "Isle\ of\ Arran",
"4418904", "Coldstream",
"441661", "Prudhoe",
"441226", "Barnsley",
"441773", "Ripley",
"441858", "Market\ Harborough",
"441756", "Skipton",
"441554", "Llanelli",
"4413873", "Langholm",
"441984", "Watchet\ \(Williton\)",
"441631", "Oban",
"44118", "Reading",
"4414348", "Hexham",
"4416867", "Llanidloes",
"441373", "Frome",
"4412290", "Barrow\-in\-Furness\/Millom",
"441143", "Sheffield",
"441458", "Glastonbury",
"44239", "Portsmouth",
"441140", "Sheffield",
"441381", "Fortrose",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"44114704", "Sheffield",
"441503", "Looe",
"4418476", "Tongue",
"441356", "Brechin",
"441902", "Wolverhampton",
"441558", "Llandeilo",
"441227", "Canterbury",
"441988", "Wigtown",
"441691", "Oswestry",
"441647", "Moretonhampstead",
"4414347", "Hexham",
"441403", "Horsham",
"441400", "Honington",
"441909", "Worksop",
"4419756", "Strathdon",
"441854", "Ullapool",
"441757", "Selby",
"441659", "Sanquhar",
"442868", "Kesh",
"442894", "Antrim",
"441749", "Shepton\ Mallet",
"441225", "Bath",
"442838", "Portadown",
"441683", "Moffat",
"441733", "Peterborough",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"4415078", "Alford\ \(Lincs\)",
"441730", "Petersfield",
"441284", "Bury\ St\ Edmunds",
"441652", "Brigg",
"441763", "Royston",
"441671", "Newton\ Stewart",
"441760", "Swaffham",
"441926", "Warwick",
"44280", "Northern\ Ireland",
"4419755", "Alford\ \(Aberdeen\)",
"441330", "Banchory",
"441202", "Bournemouth",
"44114700", "Sheffield",
"442898", "Belfast",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"4413393", "Aboyne",
"442822", "Northern\ Ireland",
"441342", "East\ Grinstead",
"441360", "Killearn",
"44131", "Edinburgh",
"441363", "Crediton",
"4414230", "Harrogate\/Boroughbridge",
"4418475", "Thurso",
"441209", "Redruth",
"441355", "East\ Kilbride",
"441821", "Kinrossie",
"441793", "Swindon",
"441790", "Spilsby",
"441349", "Dingwall",
"4415077", "Louth",
"442829", "Kilrea",
"4419640", "Hornsea\/Patrington",
"441288", "Bude",
"441473", "Ipswich",
"441269", "Ammanford",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"4417687", "Keswick",
"4419649", "Hornsea",
"441358", "Ellon",
"442877", "Limavady",
"441239", "Cardigan",
"441481", "Guernsey",
"441285", "Cirencester",
"441456", "Glenurquhart",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"4414377", "Haverfordwest",
"441644", "New\ Galloway",
"441620", "North\ Berwick",
"441623", "Mansfield",
"441262", "Bridlington",
"442895", "Belfast",
"441243", "Chichester",
"441573", "Kelso",
"44286", "Northern\ Ireland",
"441972", "Glenborrodale",
"441224", "Aberdeen",
"4414239", "Boroughbridge",
"441570", "Lampeter",
"4416861", "Newtown\/Llanidloes",
"441754", "Skegness",
"441303", "Folkestone",
"441951", "Colonsay",
"441857", "Sanday",
"441300", "Cerne\ Abbas",
"441556", "Castle\ Douglas",
"441581", "New\ Luce",
"44283", "Northern\ Ireland",
"441986", "Bungay",
"441911", "Tyneside\/Durham\/Sunderland",
"441299", "Bewdley",
"4412295", "Barrow\-in\-Furness",
"441457", "Glossop",
"4418902", "Coldstream",
"442882", "Omagh",
"4419646", "Patrington",
"441700", "Rothesay",
"4419467", "Gosforth",
"4418513", "Stornoway",
"441354", "Chatteris",
"4414302", "North\ Cave",
"441870", "Isle\ of\ Benbecula",
"441292", "Ayr",
"441758", "Pwllheli",
"441873", "Abergavenny",
"4414236", "Harrogate",
"4414378", "Haverfordwest",
"441987", "Ebbsfleet",
"442889", "Fivemiletown",
"441557", "Kirkcudbright",
"441228", "Carlisle",
"441856", "Orkney",
"442837", "Armagh",
"441939", "Wem",
"441555", "Lanark",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441985", "Warminster",
"441433", "Hathersage",
"441442", "Hemel\ Hempstead",
"441969", "Leyburn",
"442867", "Lisnaskea",
"442896", "Belfast",
"44141", "Glasgow",
"441460", "Chard",
"441549", "Lairg",
"441463", "Inverness",
"441279", "Bishops\ Stortford",
"441530", "Coalville",
"441932", "Weybridge",
"441286", "Caernarfon",
"441455", "Hinckley",
"4412299", "Millom",
"441560", "Moscow",
"44151", "Liverpool",
"441962", "Winchester",
"44287", "Northern\ Ireland",
"441563", "Kilmarnock",
"441449", "Stowmarket",
"441924", "Wakefield",
"441721", "Peebles",
"441542", "Keith",
"441943", "Guiseley",
"441855", "Ballachulish",
"4414235", "Harrogate",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"44247", "Coventry",
"442841", "Rostrevor",
"442897", "Saintfield",
"441490", "Corwen",
"442866", "Enniskillen",
"441493", "Great\ Yarmouth",
"441287", "Guisborough",
"441833", "Barnard\ Castle",
"4419645", "Hornsea",
"441928", "Runcorn",
"441830", "Kirkwhelpington",
"4412296", "Barrow\-in\-Furness",
"441992", "Lea\ Valley",
"4418470", "Thurso\/Tongue",
"441590", "Lymington",
"441842", "Thetford",
"441593", "Lybster",
"441863", "Ardgay",
"441389", "Dumbarton",
"441406", "Holbeach",
"441628", "Maidenhead",
"4417684", "Pooley\ Bridge",
"441578", "Lauder",
"441335", "Ashbourne",
"441248", "Bangor\ \(Gwynedd\)",
"4415396", "Sedbergh",
"441874", "Brecon",
"4414342", "Bellingham",
"441308", "Bridport",
"441777", "Retford",
"44114707", "Sheffield",
"441692", "North\ Walsham",
"44292", "Cardiff",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441382", "Dundee",
"441704", "Southport",
"441353", "Ely",
"4413885", "Stanhope\ \(Eastgate\)",
"441807", "Ballindalloch",
"441350", "Dunkeld",
"441506", "Bathgate",
"441376", "Braintree",
"441795", "Sittingbourne",
"4416862", "Llanidloes",
"441146", "Sheffield",
"441750", "Selkirk",
"441878", "Lochboisdale",
"441304", "Dover",
"441753", "Slough",
"441782", "Stoke\-on\-Trent",
"441407", "Holyhead",
"441624", "Isle\ of\ Man",
"441643", "Minehead",
"4418515", "Stornoway",
"4418901", "Coldstream\/Ayton",
"441395", "Budleigh\ Salterton",
"4412293", "Millom",
"441223", "Cambridge",
"441776", "Stranraer",
"441244", "Chester",
"441806", "Shetland",
"441685", "Merthyr\ Tydfil",
"4414301", "North\ Cave\/Market\ Weighton",
"441789", "Stratford\-upon\-Avon",
"441639", "Neath",
"441765", "Ripon",
"441474", "Gravesend",
"441377", "Driffield",
"441708", "Romford",
"441669", "Rothbury",
"441594", "Lydney",
"441822", "Tavistock",
"441375", "Grays\ Thurrock",
"441796", "Pitlochry",
"441538", "Ipstones",
"4415072", "Spilsby\ \(Horncastle\)",
"441767", "Sandy",
"441864", "Abington\ \(Crawford\)",
"441145", "Sheffield",
"441568", "Leominster",
"441687", "Mallaig",
"441737", "Redhill",
"441948", "Whitchurch",
"441505", "Johnstone",
"441834", "Narberth",
"441829", "Tarporley",
"442821", "Martinstown",
"441397", "Fort\ William",
"441341", "Barmouth",
"44114703", "Sheffield",
"441494", "High\ Wycombe",
"441366", "Downham\ Market",
"4415395", "Grange\-over\-Sands",
"441438", "Stevenage",
"4418519", "Great\ Bernera",
"441405", "Goole",
"441564", "Lapworth",
"441766", "Porthmadog",
"441429", "Hartlepool",
"4414233", "Boroughbridge",
"441672", "Marlborough",
"441522", "Lincoln",
"441797", "Rye",
"441944", "West\ Heslerton",
"441920", "Ware",
"441838", "Dalmally",
"441923", "Watford",
"441534", "Jersey",
"441805", "Torrington",
"441736", "Penzance",
"4413390", "Aboyne\/Ballater",
"441598", "Lynton",
"441651", "Oldmeldrum",
"4419643", "Patrington",
"441422", "Halifax",
"441367", "Faringdon",
"441464", "Insch",
"441775", "Spalding",
"4418516", "Great\ Bernera",
"441529", "Sleaford",
"441337", "Ladybank",
"4420", "London",
"441882", "Kinloch\ Rannoch",
"441404", "Honiton",
"441307", "Forfar",
"441778", "Bourne",
"441876", "Lochmaddy",
"441291", "Chepstow",
"441919", "Durham",
"441577", "Kinross",
"441495", "Pontypool",
"4414307", "Market\ Weighton",
"442881", "Newtownstewart",
"44114708", "Sheffield",
"4413399", "Ballater",
"441889", "Rugeley",
"441706", "Rochdale",
"4418907", "Ayton",
"441835", "St\ Boswells",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441912", "Tyneside",
"442870", "Coleraine",
"441808", "Tomatin",
"441477", "Holmes\ Chapel",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441144", "Sheffield",
"441865", "Oxford",
"441553", "Kings\ Lynn",
"441489", "Bishops\ Waltham",
"4416864", "Llanidloes",
"441550", "Llandovery",
"4418510", "Great\ Bernera\/Stornoway",
"441306", "Dorking",
"441952", "Telford",
"441435", "Heathfield",
"441983", "Isle\ of\ Wight",
"441582", "Luton",
"4414308", "Market\ Weighton",
"441980", "Amesbury",
"441408", "Golspie",
"441626", "Newton\ Abbot",
"441261", "Banff",
"441971", "Scourie",
"441465", "Girvan",
"441576", "Lockerbie",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441877", "Callander",
"441246", "Chesterfield",
"441959", "Westerham",
"441535", "Keighley",
"441707", "Welwyn\ Garden\ City",
"441482", "Kingston\-upon\-Hull",
"441453", "Dursley",
"441450", "Hawick",
"4414344", "Bellingham",
"441565", "Knutsford",
"441476", "Grantham",
"4413396", "Ballater",
"4418908", "Coldstream",
"441508", "Brooke",
"441945", "Wisbech",
"441895", "Uxbridge",
"441738", "Perth",
"441841", "Newquay\ \(Padstow\)",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"442849", "Northern\ Ireland",
"441947", "Whitby",
"441794", "Romsey",
"441329", "Fareham",
"441567", "Killin",
"441866", "Kilchrenan",
"441768", "Penrith",
"441609", "Northallerton",
"441875", "Tranent",
"441322", "Dartford",
"442842", "Kircubbin",
"441467", "Inverurie",
"441496", "Port\ Ellen",
"441364", "Ashburton",
"44281", "Northern\ Ireland",
"442830", "Newry",
"441334", "St\ Andrews",
"441398", "Dulverton",
"441566", "Launceston",
"441764", "Crieff",
"4413395", "Aboyne",
"441475", "Greenock",
"441946", "Whitehaven",
"441271", "Barnstaple",
"441896", "Galashiels",
"44241", "Coventry",
"4419753", "Strathdon",
"441722", "Salisbury",
"441597", "Llandrindod\ Wells",
"441837", "Okehampton",
"441536", "Kettering",
"441252", "Aldershot",
"441798", "Pulborough",
"441684", "Malvern",
"441931", "Shap",
"441280", "Buckingham",
"441283", "Burton\-on\-Trent",
"441625", "Macclesfield",
"441497", "Hay\-on\-Wye",
"441466", "Huntly",
"441729", "Settle",
"441394", "Felixstowe",
"442890", "Belfast",
"4418473", "Thurso",
"441575", "Kirriemuir",
"442893", "Ballyclare",
"441245", "Chelmsford",
"441259", "Alloa",
"441305", "Dorchester",
"4415074", "Alford\ \(Lincs\)",
"441436", "Helensburgh",
"441368", "Dunbar",
"441603", "Norwich",
"4417683", "Appleby",
"4414300", "North\ Cave\/Market\ Weighton",
"441600", "Monmouth",
"441204", "Bolton",
"4418518", "Stornoway",
"441320", "Fort\ Augustus",
"441344", "Bracknell",
"442824", "Northern\ Ireland",
"442840", "Banbridge",
"441323", "Eastbourne",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441295", "Banbury",
"441491", "Henley\-on\-Thames",
"442885", "Ballygawley",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441748", "Richmond",
"441937", "Wetherby",
"4418900", "Coldstream\/Ayton",
"441277", "Brentwood",
"441547", "Knighton",
"441591", "Llanwrtyd\ Wells",
"441967", "Strontian",
"441348", "Fishguard",
"441235", "Abingdon",
"442828", "Larne",
"441289", "Berwick\-upon\-Tweed",
"441431", "Helmsdale",
"441446", "Barry",
"44291", "Cardiff",
"442892", "Lisburn",
"4418517", "Stornoway",
"441208", "Bodmin",
"441461", "Gretna",
"4412294", "Barrow\-in\-Furness",
"441250", "Blairgowrie",
"441531", "Ledbury",
"441253", "Blackpool",
"441282", "Burnley",
"441654", "Machynlleth",
"441561", "Laurencekirk",
"441546", "Lochgilphead",
"441723", "Scarborough",
"441276", "Camberley",
"442899", "Northern\ Ireland",
"441997", "Strathpeffer",
"441744", "St\ Helens",
"441720", "Isles\ of\ Scilly",
"441913", "Durham",
"441995", "Garstang",
"441910", "Tyneside\/Durham\/Sunderland",
"441845", "Thirsk",
"4418472", "Thurso",
"442886", "Cookstown",
"441904", "York",
"441859", "Harris",
"441977", "Pontefract",
"442879", "Magherafelt",
"441296", "Aylesbury",
"441871", "Castlebay",
"441267", "Carmarthen",
"441880", "Tarbert",
"4419752", "Alford\ \(Aberdeen\)",
"441883", "Caterham",
"4413391", "Aboyne\/Ballater",
"441852", "Kilmelford",
"441237", "Bideford",
"4414234", "Boroughbridge",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441545", "Llanarth",
"441908", "Milton\ Keynes",
"441275", "Clevedon",
"441935", "Yeovil",
"441559", "Llandysul",
"441483", "Guildford",
"441480", "Huntingdon",
"442887", "Dungannon",
"441989", "Ross\-on\-Wye",
"441452", "Gloucester",
"441445", "Gairloch",
"441621", "Maldon",
"4419644", "Patrington",
"441297", "Axminster",
"441241", "Arbroath",
"441571", "Lochinver",
"441301", "Arrochar",
"441953", "Wymondham",
"441236", "Coatbridge",
"441950", "Sandwick",
"441583", "Carradale",
"441580", "Cranbrook",
"441982", "Builth\ Wells",
"441206", "Colchester",
"441346", "Fraserburgh",
"4414305", "North\ Cave",
"442826", "Northern\ Ireland",
"441361", "Duns",
"4412292", "Barrow\-in\-Furness",
"4418905", "Ayton",
"441968", "Penicuik",
"4418511", "Great\ Bernera\/Stornoway",
"441548", "Kingsbridge",
"441905", "Worcester",
"441278", "Bridgwater",
"441823", "Taunton",
"441747", "Shaftesbury",
"441994", "St\ Clears",
"441844", "Thame",
"441938", "Welshpool",
"44238", "Southampton",
"441207", "Consett",
"4416863", "Llanidloes",
"441444", "Haywards\ Heath",
"441420", "Alton",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441929", "Wareham",
"442827", "Ballymoney",
"441347", "Easingwold",
"441848", "Thornhill",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441934", "Weston\-super\-Mare",
"44113", "Leeds",
"4414343", "Haltwhistle",
"441656", "Bridgend",
"44116", "Leicester",
"441761", "Temple\ Cloud",
"441673", "Market\ Rasen",
"441670", "Morpeth",
"441520", "Lochcarron",
"441544", "Kington",
"441274", "Bradford",
"441922", "Walsall",
"441746", "Bridgnorth",
"441371", "Great\ Dunmow",
"441141", "Sheffield",
"441383", "Dunfermline",
"441380", "Devizes",
"442884", "Northern\ Ireland",
"4413398", "Aboyne",
"4418906", "Ayton",
"441501", "Harthill",
"4419642", "Hornsea",
"441352", "Mold",
"442825", "Ballymena",
"441294", "Ardrossan",
"441690", "Betws\-y\-Coed",
"4414306", "Market\ Weighton",
"441268", "Basildon",
"441205", "Boston",
"44114701", "Sheffield",
"441359", "Pakenham",
"441978", "Wrexham",
"4414232", "Harrogate",
"442888", "Northern\ Ireland",
"4418909", "Ayton",
"4419754", "Alford\ \(Aberdeen\)",
"4413397", "Ballater",
"442311", "Southampton",
"441745", "Rhyl",
"441759", "Pocklington",
"441655", "Maybole",
"441642", "Middlesbrough",
"441264", "Andover",
"44161", "Manchester",
"441663", "New\ Mills",
"4418474", "Thurso",
"441771", "Maud",
"44117", "Bristol",
"441974", "Llanon",
"4415073", "Louth",
"4414309", "Market\ Weighton",
"441298", "Buxton",
"441752", "Plymouth",
"441234", "Bedford",
"441630", "Market\ Drayton",
"441780", "Stamford",
"441633", "Newport",};
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