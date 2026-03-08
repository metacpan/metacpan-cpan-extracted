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
our $VERSION = 1.20260306161713;

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
$areanames{en} = {"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441785", "Stafford",
"441582", "Luton",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"4419752", "Alford\ \(Aberdeen\)",
"441622", "Maidstone",
"44114703", "Sheffield",
"441528", "Laggan",
"441777", "Retford",
"441576", "Lockerbie",
"442884", "Northern\ Ireland",
"441749", "Shepton\ Mallet",
"441279", "Bishops\ Stortford",
"441824", "Ruthin",
"44116", "Leicester",
"441984", "Watchet\ \(Williton\)",
"441569", "Stonehaven",
"441294", "Ardrossan",
"4414374", "Clynderwen\ \(Clunderwen\)",
"4418905", "Ayton",
"441495", "Pontypool",
"441590", "Lymington",
"441357", "Strathaven",
"441443", "Pontypridd",
"441859", "Harris",
"441641", "Strathy",
"441736", "Penzance",
"44151", "Liverpool",
"4413395", "Aboyne",
"4414231", "Harrogate\/Boroughbridge",
"441144", "Sheffield",
"441425", "Ringwood",
"441556", "Castle\ Douglas",
"441520", "Lochcarron",
"441757", "Selby",
"441259", "Alloa",
"4414232", "Harrogate",
"4418514", "Great\ Bernera",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441953", "Wymondham",
"4418903", "Coldstream",
"441931", "Shap",
"441461", "Gretna",
"441663", "New\ Mills",
"441692", "North\ Walsham",
"441598", "Lynton",
"4413393", "Aboyne",
"441866", "Kilchrenan",
"441377", "Driffield",
"441349", "Dingwall",
"441406", "Holbeach",
"4418477", "Tongue",
"441224", "Aberdeen",
"441879", "Scarinish",
"441915", "Sunderland",
"4414377", "Haverfordwest",
"442846", "Northern\ Ireland",
"44141", "Glasgow",
"441967", "Strontian",
"4419642", "Hornsea",
"4414342", "Bellingham",
"441388", "Bishop\ Auckland",
"4419467", "Gosforth",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"4419641", "Hornsea\/Patrington",
"442867", "Lisnaskea",
"441946", "Whitehaven",
"441763", "Royston",
"441490", "Corwen",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441792", "Swansea",
"441543", "Cannock",
"441918", "Tyneside",
"441322", "Dartford",
"441307", "Forfar",
"4413398", "Aboyne",
"441476", "Grantham",
"441809", "Tomdoun",
"441428", "Haslemere",
"441469", "Killingholme",
"441939", "Wem",
"4412296", "Barrow\-in\-Furness",
"441233", "Ashford\ \(Kent\)",
"441780", "Stamford",
"441482", "Kingston\-upon\-Hull",
"4418908", "Coldstream",
"4416866", "Newtown",
"441871", "Castlebay",
"441341", "Barmouth",
"441209", "Redruth",
"4416860", "Newtown\/Llanidloes",
"441910", "Tyneside\/Durham\/Sunderland",
"441707", "Welwyn\ Garden\ City",
"441506", "Bathgate",
"441636", "Newark\-on\-Trent",
"441833", "Barnard\ Castle",
"441903", "Worthing",
"4418474", "Thurso",
"441561", "Laurencekirk",
"441271", "Barnstaple",
"441380", "Devizes",
"44114702", "Sheffield",
"4412290", "Barrow\-in\-Furness\/Millom",
"441788", "Rugby",
"441685", "Merthyr\ Tydfil",
"4418517", "Stornoway",
"441456", "Glenurquhart",
"441420", "Alton",
"441722", "Salisbury",
"441525", "Leighton\ Buzzard",
"441677", "Bedale",
"441363", "Crediton",
"441392", "Exeter",
"441583", "Carradale",
"4420", "London",
"4416865", "Newtown",
"44247", "Coventry",
"441972", "Glenborrodale",
"441599", "Kyle",
"441264", "Andover",
"442886", "Cookstown",
"4412295", "Barrow\-in\-Furness",
"441348", "Fishguard",
"441623", "Mansfield",
"441296", "Aylesbury",
"441986", "Bungay",
"441878", "Lochboisdale",
"441740", "Sedgefield",
"441442", "Hemel\ Hempstead",
"441805", "Torrington",
"441935", "Yeovil",
"441465", "Girvan",
"441258", "Blandford",
"441560", "Moscow",
"441381", "Fortrose",
"441270", "Crewe",
"441911", "Tyneside\/Durham\/Sunderland",
"4414379", "Haverfordwest",
"441205", "Boston",
"441146", "Sheffield",
"441554", "Llanelli",
"441870", "Isle\ of\ Benbecula",
"441858", "Market\ Harborough",
"441340", "Craigellachie\ \(Aberlour\)",
"4416863", "Llanidloes",
"4418519", "Great\ Bernera",
"4412293", "Millom",
"441334", "St\ Andrews",
"441952", "Telford",
"441491", "Henley\-on\-Thames",
"441689", "Orpington",
"441529", "Sleaford",
"441748", "Richmond",
"441864", "Abington\ \(Crawford\)",
"441278", "Bridgwater",
"441404", "Honiton",
"441896", "Galashiels",
"441250", "Blairgowrie",
"441226", "Barnsley",
"441568", "Leominster",
"442897", "Saintfield",
"4412298", "Barrow\-in\-Furness",
"442844", "Downpatrick",
"441789", "Stratford\-upon\-Avon",
"441287", "Guisborough",
"441997", "Strathpeffer",
"441944", "West\ Heslerton",
"4413396", "Ballater",
"441323", "Eastbourne",
"441745", "Rhyl",
"441542", "Keith",
"442830", "Newry",
"441275", "Clevedon",
"4416868", "Newtown",
"441460", "Chard",
"441793", "Swindon",
"4418906", "Ayton",
"441565", "Knutsford",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441208", "Bodmin",
"441474", "Gravesend",
"441499", "Inveraray",
"441855", "Ballachulish",
"441483", "Guildford",
"442838", "Portadown",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441808", "Tomatin",
"4418479", "Tongue",
"441429", "Hartlepool",
"441938", "Welshpool",
"441255", "Clacton\-on\-Sea",
"4415072", "Spilsby\ \(Horncastle\)",
"441634", "Medway",
"441902", "Wolverhampton",
"441591", "Llanwrtyd\ Wells",
"441832", "Clopton",
"44286", "Northern\ Ireland",
"4416973", "Wigton",
"442827", "Ballymoney",
"441389", "Dumbarton",
"4418900", "Coldstream\/Ayton",
"441887", "Aberfeldy",
"441454", "Chipping\ Sodbury",
"441362", "Dereham",
"441200", "Clitheroe",
"4413390", "Aboyne\/Ballater",
"441723", "Scarborough",
"441919", "Durham",
"441875", "Tranent",
"441368", "Dunbar",
"441799", "Saffron\ Walden",
"442887", "Dungannon",
"441244", "Chester",
"441827", "Tamworth",
"441297", "Axminster",
"441987", "Ebbsfleet",
"441329", "Fareham",
"4419757", "Strathdon",
"441534", "Jersey",
"441489", "Bishops\ Waltham",
"441908", "Milton\ Keynes",
"441691", "Oswestry",
"441838", "Dalmally",
"441445", "Gairloch",
"4419644", "Patrington",
"4414344", "Bellingham",
"441540", "Kingussie",
"441760", "Swaffham",
"441493", "Great\ Yarmouth",
"441354", "Chatteris",
"44114709", "Sheffield",
"441932", "Weybridge",
"441462", "Hitchin",
"441604", "Northampton",
"441621", "Maldon",
"441955", "Wick",
"441202", "Bournemouth",
"441581", "New\ Luce",
"441360", "Killearn",
"441754", "Skegness",
"4414308", "Market\ Weighton",
"4414237", "Harrogate",
"441913", "Durham",
"441729", "Settle",
"441548", "Kingsbridge",
"4415079", "Alford\ \(Lincs\)",
"4418471", "Thurso\/Tongue",
"441642", "Middlesbrough",
"4417687", "Keswick",
"441665", "Alnwick",
"4418472", "Thurso",
"441227", "Canterbury",
"441768", "Penrith",
"441844", "Thame",
"441900", "Workington",
"441383", "Dunfermline",
"441830", "Kirkwhelpington",
"441629", "Matlock",
"441440", "Haverhill",
"441545", "Llanarth",
"4414303", "North\ Cave",
"441668", "Bamburgh",
"441562", "Kidderminster",
"441765", "Ripon",
"441593", "Lybster",
"4419647", "Patrington",
"4414347", "Hexham",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"442896", "Belfast",
"44118", "Reading",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441286", "Caernarfon",
"4413882", "Stanhope\ \(Eastgate\)",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"442870", "Coleraine",
"441721", "Peebles",
"441970", "Aberystwyth",
"441235", "Abingdon",
"441304", "Dover",
"441654", "Machynlleth",
"4419754", "Alford\ \(Aberdeen\)",
"441852", "Kilmelford",
"44114701", "Sheffield",
"441905", "Worcester",
"441835", "St\ Boswells",
"4414305", "North\ Cave",
"4417684", "Pooley\ Bridge",
"4413873", "Langholm",
"441252", "Aldershot",
"441704", "Southport",
"441674", "Montrose",
"441481", "Guernsey",
"441342", "East\ Grinstead",
"441872", "Truro",
"4415396", "Sedbergh",
"442826", "Northern\ Ireland",
"4418511", "Great\ Bernera\/Stornoway",
"441683", "Moffat",
"441926", "Warwick",
"4418512", "Stornoway",
"441950", "Sandwick",
"441978", "Wrexham",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"4414234", "Boroughbridge",
"441625", "Macclesfield",
"441267", "Carmarthen",
"441728", "Saxmundham",
"4414300", "North\ Cave\/Market\ Weighton",
"441549", "Lairg",
"441577", "Kinross",
"441776", "Stranraer",
"441951", "Colonsay",
"441246", "Chesterfield",
"441398", "Dulverton",
"441769", "South\ Molton",
"441480", "Huntingdon",
"441782", "Stoke\-on\-Trent",
"441536", "Kettering",
"441737", "Redhill",
"441661", "Prudhoe",
"4414349", "Bellingham",
"4419649", "Hornsea",
"441239", "Cardigan",
"441463", "Inverness",
"441790", "Spilsby",
"441933", "Wellingborough",
"441492", "Colwyn\ Bay",
"44114708", "Sheffield",
"441356", "Brechin",
"441320", "Fort\ Augustus",
"44114700", "Sheffield",
"441803", "Torquay",
"441606", "Northwich",
"441488", "Hungerford",
"441909", "Worksop",
"4415395", "Grange\-over\-Sands",
"44131", "Edinburgh",
"441337", "Ladybank",
"442871", "Londonderry",
"44292", "Cardiff",
"441756", "Skipton",
"44114705", "Sheffield",
"441720", "Isles\ of\ Scilly",
"441557", "Kirkcudbright",
"441422", "Halifax",
"441971", "Scourie",
"441695", "Skelmersdale",
"441798", "Pulborough",
"441369", "Dunoon",
"441407", "Holyhead",
"441643", "Minehead",
"441376", "Braintree",
"44241", "Coventry",
"441328", "Fakenham",
"441912", "Tyneside",
"4414306", "Market\ Weighton",
"4415074", "Alford\ \(Lincs\)",
"441382", "Dundee",
"441698", "Motherwell",
"441592", "Kirkcaldy",
"441795", "Sittingbourne",
"441563", "Kilmarnock",
"441273", "Brighton",
"441743", "Shrewsbury",
"441325", "Darlington",
"442894", "Antrim",
"442879", "Magherafelt",
"441436", "Helensburgh",
"442847", "Northern\ Ireland",
"441994", "St\ Clears",
"441284", "Bury\ St\ Edmunds",
"441947", "Whitby",
"442866", "Enniskillen",
"441485", "Hunstanton",
"441580", "Cranbrook",
"441361", "Duns",
"4419759", "Alford\ \(Aberdeen\)",
"441477", "Holmes\ Chapel",
"441449", "Stowmarket",
"441306", "Dorking",
"441620", "North\ Berwick",
"441656", "Bridgend",
"441637", "Newquay",
"44161", "Manchester",
"441761", "Temple\ Cloud",
"441959", "Westerham",
"441690", "Betws\-y\-Coed",
"441253", "Blackpool",
"4415077", "Louth",
"441706", "Rochdale",
"441628", "Maidenhead",
"441522", "Lincoln",
"4414239", "Boroughbridge",
"441725", "Rockbourne",
"441457", "Glossop",
"441873", "Abergavenny",
"441343", "Elgin",
"441676", "Meriden",
"441395", "Budleigh\ Salterton",
"441669", "Rothbury",
"442824", "Northern\ Ireland",
"441588", "Bishops\ Castle",
"441924", "Wakefield",
"441884", "Tiverton",
"44287", "Northern\ Ireland",
"442881", "Newtownstewart",
"441821", "Kinrossie",
"441335", "Ashbourne",
"4418470", "Thurso\/Tongue",
"441291", "Chepstow",
"441981", "Wormbridge",
"4412294", "Barrow\-in\-Furness",
"441450", "Hawick",
"441752", "Plymouth",
"441555", "Lanark",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"4416864", "Llanidloes",
"441204", "Bolton",
"4418909", "Ayton",
"441865", "Oxford",
"441644", "New\ Galloway",
"441697", "Brampton",
"441916", "Tyneside",
"441842", "Thetford",
"441372", "Esher",
"441405", "Goole",
"4413399", "Ballater",
"442848", "Northern\ Ireland",
"441630", "Market\ Drayton",
"441948", "Whitchurch",
"441386", "Evesham",
"441575", "Kirriemuir",
"441772", "Preston",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441458", "Glastonbury",
"441242", "Cheltenham",
"441786", "Stirling",
"441141", "Sheffield",
"442840", "Banbridge",
"441638", "Newmarket",
"441496", "Port\ Ellen",
"4418476", "Tongue",
"441508", "Brooke",
"441352", "Mold",
"441934", "Weston\-super\-Mare",
"441464", "Insch",
"4416974", "Raughton\ Head",
"4414376", "Haverfordwest",
"441738", "Perth",
"441635", "Newbury",
"44114704", "Sheffield",
"441702", "Southend\-on\-Sea",
"441505", "Johnstone",
"441400", "Honington",
"441254", "Blackburn",
"4418510", "Great\ Bernera\/Stornoway",
"441672", "Marlborough",
"441578", "Lauder",
"441455", "Hinckley",
"441727", "St\ Albans",
"441550", "Llandovery",
"441526", "Martin",
"441268", "Basildon",
"441874", "Brecon",
"441397", "Fort\ William",
"4412297", "Millom",
"441344", "Bracknell",
"441899", "Biggar",
"441923", "Watford",
"441883", "Caterham",
"4416867", "Llanidloes",
"442823", "Northern\ Ireland",
"441330", "Banchory",
"442889", "Fivemiletown",
"441744", "St\ Helens",
"441797", "Rye",
"441564", "Lapworth",
"441989", "Ross\-on\-Wye",
"441299", "Bewdley",
"441327", "Daventry",
"441829", "Tarporley",
"441408", "Golspie",
"441274", "Bradford",
"441432", "Hereford",
"442845", "Northern\ Ireland",
"441962", "Winchester",
"441730", "Petersfield",
"441993", "Witney",
"441283", "Burton\-on\-Trent",
"442893", "Ballyclare",
"441945", "Wisbech",
"44280", "Northern\ Ireland",
"441487", "Warboys",
"4418516", "Great\ Bernera",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441558", "Llandeilo",
"441260", "Congleton",
"441652", "Brigg",
"441302", "Doncaster",
"441570", "Lampeter",
"441475", "Greenock",
"441854", "Ullapool",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441261", "Banff",
"441571", "Lochinver",
"441639", "Neath",
"441957", "Mid\ Yell",
"4416869", "Newtown",
"4412299", "Millom",
"441424", "Hastings",
"4418513", "Stornoway",
"441206", "Colchester",
"441145", "Sheffield",
"441509", "Loughborough",
"441753", "Slough",
"441646", "Milford\ Haven",
"441373", "Frome",
"441843", "Thanet",
"441914", "Tyneside",
"441667", "Nairn",
"441225", "Bath",
"441895", "Uxbridge",
"4413394", "Ballater",
"4413885", "Stanhope\ \(Eastgate\)",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441384", "Dudley",
"4418904", "Coldstream",
"442885", "Ballygawley",
"441243", "Chichester",
"441985", "Warminster",
"441295", "Banbury",
"441825", "Uckfield",
"441773", "Ripley",
"442877", "Limavady",
"442849", "Northern\ Ireland",
"441784", "Staines",
"4418515", "Stornoway",
"4418478", "Thurso",
"441949", "Whatton",
"441977", "Pontefract",
"4414302", "North\ Cave",
"4414301", "North\ Cave\/Market\ Weighton",
"441353", "Ely",
"441806", "Shetland",
"441494", "High\ Wycombe",
"441479", "Grantown\-on\-Spey",
"441603", "Norwich",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441466", "Huntly",
"4418473", "Thurso",
"44291", "Cardiff",
"4413397", "Ballater",
"441837", "Okehampton",
"441559", "Llandysul",
"44115", "Nottingham",
"44238", "Southampton",
"442841", "Rostrevor",
"4418907", "Ayton",
"441256", "Basingstoke",
"442888", "Northern\ Ireland",
"441140", "Sheffield",
"441869", "Bicester",
"441524", "Lancaster",
"441367", "Faringdon",
"441988", "Wigtown",
"441298", "Buxton",
"441876", "Lochmaddy",
"441346", "Fraserburgh",
"441828", "Coupar\ Angus",
"441409", "Holsworthy",
"441673", "Market\ Rasen",
"4414378", "Haverfordwest",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441684", "Malvern",
"442822", "Northern\ Ireland",
"441882", "Kinloch\ Rannoch",
"441922", "Walsall",
"441746", "Bridgnorth",
"441547", "Knighton",
"44117", "Bristol",
"4418475", "Thurso",
"441631", "Oban",
"4418518", "Stornoway",
"441579", "Liskeard",
"441269", "Ammanford",
"441594", "Lydney",
"441767", "Sandy",
"441228", "Carlisle",
"441566", "Launceston",
"441276", "Camberley",
"442892", "Lisburn",
"441992", "Lea\ Valley",
"441501", "Harthill",
"441282", "Burnley",
"441433", "Hathersage",
"441963", "Wincanton",
"441451", "Stow\-on\-the\-Wold",
"44121", "Birmingham",
"441237", "Bideford",
"442880", "Carrickmore",
"441856", "Orkney",
"441303", "Folkestone",
"441653", "Malton",
"441290", "Cumnock",
"441980", "Amesbury",
"442310", "Portsmouth",
"441142", "Sheffield",
"441207", "Consett",
"441709", "Rotherham",
"441553", "Kings\ Lynn",
"442820", "Ballycastle",
"441771", "Maud",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"44239", "Portsmouth",
"441920", "Ware",
"4419756", "Strathdon",
"441241", "Arbroath",
"441880", "Tarbert",
"4415073", "Louth",
"442898", "Belfast",
"4414230", "Harrogate\/Boroughbridge",
"441288", "Bude",
"441531", "Ledbury",
"441647", "Moretonhampstead",
"441403", "Horsham",
"441694", "Church\ Stretton",
"441666", "Malmesbury",
"441863", "Ardgay",
"441892", "Tunbridge\ Wells",
"441584", "Ludlow",
"441969", "Leyburn",
"441439", "Helmsley",
"441751", "Pickering",
"442828", "Larne",
"441888", "Turriff",
"441928", "Runcorn",
"4415394", "Hawkshead",
"442882", "Omagh",
"441624", "Isle\ of\ Man",
"441292", "Ayr",
"441982", "Builth\ Wells",
"441263", "Cromer",
"441573", "Kelso",
"4414236", "Harrogate",
"441822", "Tavistock",
"441807", "Ballindalloch",
"441659", "Sanquhar",
"4415075", "Spilsby\ \(Horncastle\)",
"441446", "Barry",
"44281", "Northern\ Ireland",
"441309", "Forres",
"442837", "Armagh",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441937", "Wetherby",
"441467", "Inverurie",
"442890", "Belfast",
"441371", "Great\ Dunmow",
"441733", "Peterborough",
"441280", "Buckingham",
"441841", "Newquay\ \(Padstow\)",
"441759", "Pocklington",
"441503", "Looe",
"441431", "Helmsdale",
"441257", "Coppull",
"4419646", "Patrington",
"4414346", "Hexham",
"441633", "Newport",
"4416862", "Llanidloes",
"441301", "Arrochar",
"441651", "Oldmeldrum",
"442825", "Ballymena",
"441885", "Pencombe",
"4416861", "Newtown\/Llanidloes",
"441925", "Warrington",
"4412291", "Barrow\-in\-Furness\/Millom",
"441366", "Downham\ Market",
"441724", "Scunthorpe",
"441877", "Callander",
"441453", "Dursley",
"4412292", "Barrow\-in\-Furness",
"441394", "Felixstowe",
"441379", "Diss",
"441347", "Easingwold",
"442895", "Belfast",
"441943", "Guiseley",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441995", "Garstang",
"4414309", "Market\ Weighton",
"441285", "Cirencester",
"441779", "Peterhead",
"441546", "Lochgilphead",
"441747", "Shaftesbury",
"441794", "Romsey",
"441567", "Killin",
"441766", "Porthmadog",
"441324", "Falkirk",
"441249", "Chippenham",
"441277", "Brentwood",
"4419640", "Hornsea\/Patrington",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441609", "Northallerton",
"441473", "Ipswich",
"441857", "Sanday",
"441359", "Pakenham",
"4415078", "Alford\ \(Lincs\)",
"441484", "Huddersfield",
"441539", "Kendal",
"441671", "Newton\ Stewart",
"44113", "Leeds",
"441236", "Coatbridge",
"441427", "Gainsborough",
"441670", "Morpeth",
"441308", "Bridport",
"441143", "Sheffield",
"441332", "Derby",
"441954", "Madingley",
"441438", "Stevenage",
"441968", "Penicuik",
"442829", "Kilrea",
"442868", "Kesh",
"4419645", "Hornsea",
"4414345", "Haltwhistle",
"441889", "Rugeley",
"441929", "Wareham",
"441387", "Dumfries",
"44283", "Northern\ Ireland",
"441862", "Tain",
"4419758", "Strathdon",
"441223", "Cambridge",
"441845", "Thirsk",
"441917", "Sunderland",
"441664", "Melton\ Mowbray",
"441375", "Grays\ Thurrock",
"441700", "Rothesay",
"441586", "Campbeltown",
"441787", "Sudbury",
"442899", "Northern\ Ireland",
"441974", "Llanon",
"441289", "Berwick\-upon\-Tweed",
"441823", "Taunton",
"441678", "Bala",
"441775", "Spalding",
"441572", "Oakham",
"441300", "Cerne\ Abbas",
"441626", "Newton\ Abbot",
"441650", "Cemmaes\ Road",
"44114707", "Sheffield",
"441262", "Bridlington",
"441983", "Isle\ of\ Wight",
"441293", "Crawley",
"442883", "Northern\ Ireland",
"441245", "Chelmsford",
"441497", "Hay\-on\-Wye",
"441444", "Haywards\ Heath",
"4414343", "Haltwhistle",
"4419643", "Patrington",
"441708", "Romford",
"441355", "East\ Kilbride",
"4414307", "Market\ Weighton",
"4414238", "Harrogate",
"441732", "Sevenoaks",
"441535", "Keighley",
"442891", "Bangor\ \(Co\.\ Down\)",
"4418901", "Coldstream\/Ayton",
"4418902", "Coldstream",
"441608", "Chipping\ Norton",
"441502", "Lowestoft",
"441358", "Ellon",
"441840", "Camelford",
"4413391", "Aboyne\/Ballater",
"4417683", "Appleby",
"441904", "York",
"441538", "Ipstones",
"4413392", "Aboyne",
"441834", "Narberth",
"4419755", "Alford\ \(Aberdeen\)",
"441687", "Mallaig",
"4414233", "Boroughbridge",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441675", "Coleshill",
"441778", "Bourne",
"441750", "Selkirk",
"441527", "Redditch",
"441726", "St\ Austell",
"441452", "Gloucester",
"4415242", "Hornby",
"441364", "Ashburton",
"4419648", "Hornsea",
"4414348", "Hexham",
"441248", "Bangor\ \(Gwynedd\)",
"441530", "Coalville",
"442842", "Kircubbin",
"441435", "Heathfield",
"441942", "Wigan",
"4414304", "North\ Cave",
"441544", "Kington",
"441597", "Llandrindod\ Wells",
"441796", "Pitlochry",
"441848", "Thornhill",
"441350", "Dunkeld",
"4415076", "Louth",
"441326", "Falmouth",
"441764", "Crieff",
"441600", "Monmouth",
"442821", "Martinstown",
"441758", "Pwllheli",
"4419753", "Strathdon",
"441655", "Maybole",
"4414235", "Harrogate",
"441472", "Grimsby",
"441770", "Isle\ of\ Arran",
"441305", "Dorchester",
"442311", "Southampton",
"441234", "Bedford",};
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