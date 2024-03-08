# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20240308154351;

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
$areanames{en} = {"441497", "Hay\-on\-Wye",
"441856", "Orkney",
"4416865", "Newtown",
"441771", "Maud",
"441493", "Great\ Yarmouth",
"441914", "Tyneside",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441754", "Skegness",
"441548", "Kingsbridge",
"441631", "Oban",
"441782", "Stoke\-on\-Trent",
"441144", "Sheffield",
"4415078", "Alford\ \(Lincs\)",
"441885", "Pencombe",
"4419759", "Alford\ \(Aberdeen\)",
"441994", "St\ Clears",
"441208", "Bodmin",
"441720", "Isles\ of\ Scilly",
"4419754", "Alford\ \(Aberdeen\)",
"441628", "Maidenhead",
"441376", "Braintree",
"441674", "Montrose",
"441985", "Warminster",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441796", "Pitlochry",
"441400", "Honington",
"4418473", "Thurso",
"441651", "Oldmeldrum",
"441261", "Banff",
"4416973", "Wigton",
"441329", "Fareham",
"44114705", "Sheffield",
"4414237", "Harrogate",
"441550", "Llandovery",
"441967", "Strontian",
"441644", "New\ Galloway",
"441346", "Fraserburgh",
"441863", "Ardgay",
"442892", "Lisburn",
"441963", "Wincanton",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"4414304", "North\ Cave",
"441524", "Lancaster",
"441280", "Buckingham",
"441578", "Lauder",
"4414378", "Haverfordwest",
"4414309", "Market\ Weighton",
"4413882", "Stanhope\ \(Eastgate\)",
"441488", "Hungerford",
"441530", "Coalville",
"442886", "Cookstown",
"441464", "Insch",
"441305", "Dorchester",
"4413399", "Ballater",
"441797", "Rye",
"441889", "Rugeley",
"44117", "Bristol",
"441989", "Ross\-on\-Wye",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441572", "Oakham",
"4413394", "Ballater",
"4419648", "Hornsea",
"441793", "Swindon",
"441933", "Wellingborough",
"441373", "Frome",
"441837", "Okehampton",
"441454", "Chipping\ Sodbury",
"442310", "Portsmouth",
"441833", "Barnard\ Castle",
"441581", "New\ Luce",
"441482", "Kingston\-upon\-Hull",
"441377", "Driffield",
"441937", "Wetherby",
"441420", "Alton",
"441953", "Wymondham",
"441496", "Port\ Ellen",
"441857", "Sanday",
"4416867", "Llanidloes",
"441700", "Rothesay",
"441608", "Chipping\ Norton",
"442898", "Belfast",
"4412298", "Barrow\-in\-Furness",
"441228", "Carlisle",
"441274", "Bradford",
"4418512", "Stornoway",
"441957", "Mid\ Yell",
"441560", "Moscow",
"441244", "Chester",
"442887", "Dungannon",
"4412290", "Barrow\-in\-Furness\/Millom",
"441622", "Maidstone",
"441202", "Bournemouth",
"442883", "Northern\ Ireland",
"441661", "Prudhoe",
"441309", "Forres",
"4414235", "Harrogate",
"441325", "Darlington",
"441347", "Easingwold",
"441866", "Kilchrenan",
"441343", "Elgin",
"441788", "Rugby",
"4419640", "Hornsea\/Patrington",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441764", "Crieff",
"441542", "Keith",
"4418904", "Coldstream",
"4418909", "Ayton",
"4418514", "Great\ Bernera",
"4418519", "Great\ Bernera",
"441360", "Killearn",
"44241", "Coventry",
"441786", "Stirling",
"442841", "Rostrevor",
"441995", "Garstang",
"441884", "Tiverton",
"4415076", "Louth",
"441852", "Kilmelford",
"441675", "Coleshill",
"441895", "Uxbridge",
"441984", "Watchet\ \(Williton\)",
"441968", "Penicuik",
"441952", "Telford",
"441792", "Swansea",
"441915", "Sunderland",
"441573", "Kelso",
"441381", "Fortrose",
"441577", "Kinross",
"441439", "Helmsley",
"441145", "Sheffield",
"4414233", "Boroughbridge",
"441279", "Bishops\ Stortford",
"441483", "Guildford",
"441832", "Clopton",
"4413392", "Aboyne",
"4415394", "Hawkshead",
"441487", "Warboys",
"441372", "Esher",
"441932", "Weybridge",
"441465", "Girvan",
"441342", "East\ Grinstead",
"441226", "Barnsley",
"4418477", "Tongue",
"441606", "Northwich",
"441304", "Dover",
"442896", "Belfast",
"4418902", "Coldstream",
"441249", "Chippenham",
"442820", "Ballycastle",
"4414376", "Haverfordwest",
"441525", "Leighton\ Buzzard",
"441547", "Knighton",
"441543", "Cannock",
"441290", "Cumnock",
"442882", "Omagh",
"44286", "Northern\ Ireland",
"441769", "South\ Molton",
"441623", "Mansfield",
"441207", "Consett",
"441509", "Loughborough",
"442871", "Londonderry",
"441919", "Durham",
"442888", "Northern\ Ireland",
"441275", "Clevedon",
"4412296", "Barrow\-in\-Furness",
"441759", "Pocklington",
"441435", "Heathfield",
"4419752", "Alford\ \(Aberdeen\)",
"441576", "Lockerbie",
"441591", "Llanwrtyd\ Wells",
"441492", "Colwyn\ Bay",
"44283", "Northern\ Ireland",
"441455", "Hinckley",
"441348", "Fishguard",
"441840", "Camelford",
"441787", "Sudbury",
"441899", "Biggar",
"4419646", "Patrington",
"441765", "Ripon",
"441970", "Aberystwyth",
"441330", "Banchory",
"441505", "Johnstone",
"4416863", "Llanidloes",
"441690", "Betws\-y\-Coed",
"441870", "Isle\ of\ Benbecula",
"441798", "Pulborough",
"441938", "Welshpool",
"441626", "Newton\ Abbot",
"441324", "Falkirk",
"441838", "Dalmally",
"4414302", "North\ Cave",
"441206", "Colchester",
"441350", "Dunkeld",
"441546", "Lochgilphead",
"441469", "Killingholme",
"441821", "Kinrossie",
"441529", "Sleaford",
"441962", "Winchester",
"441603", "Norwich",
"442893", "Ballyclare",
"441245", "Chelmsford",
"441227", "Canterbury",
"4418475", "Thurso",
"441862", "Tain",
"441858", "Market\ Harborough",
"441223", "Cambridge",
"442897", "Saintfield",
"4419467", "Gosforth",
"441472", "Grimsby",
"441571", "Lochinver",
"441387", "Dumfries",
"44239", "Portsmouth",
"4414377", "Haverfordwest",
"441383", "Dunfermline",
"441554", "Llanelli",
"441748", "Richmond",
"44118", "Reading",
"441481", "Guernsey",
"441582", "Luton",
"4418476", "Tongue",
"441879", "Scarinish",
"441520", "Lochcarron",
"441284", "Bury\ St\ Edmunds",
"4414344", "Bellingham",
"441268", "Basildon",
"441252", "Aldershot",
"442825", "Ballymena",
"442847", "Northern\ Ireland",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441295", "Banbury",
"4414349", "Bellingham",
"441534", "Jersey",
"441460", "Chard",
"441359", "Pakenham",
"4414238", "Harrogate",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"4414230", "Harrogate\/Boroughbridge",
"4415077", "Louth",
"441621", "Maldon",
"441803", "Torquay",
"441910", "Tyneside\/Durham\/Sunderland",
"4419645", "Hornsea",
"442877", "Limavady",
"441750", "Selkirk",
"441807", "Ballindalloch",
"441140", "Sheffield",
"441903", "Worthing",
"4412295", "Barrow\-in\-Furness",
"441949", "Whatton",
"441724", "Scunthorpe",
"441778", "Bourne",
"441670", "Morpeth",
"441398", "Dulverton",
"4414301", "North\ Cave\/Market\ Weighton",
"4417683", "Appleby",
"441404", "Honiton",
"441638", "Newmarket",
"441730", "Petersfield",
"441926", "Warwick",
"441442", "Hemel\ Hempstead",
"442829", "Kilrea",
"441772", "Preston",
"441593", "Lybster",
"441597", "Llandrindod\ Wells",
"441299", "Bewdley",
"441355", "East\ Kilbride",
"442846", "Northern\ Ireland",
"44247", "Coventry",
"4413391", "Aboyne\/Ballater",
"441392", "Exeter",
"4416860", "Newtown\/Llanidloes",
"441386", "Evesham",
"441335", "Ashbourne",
"441684", "Malvern",
"441652", "Brigg",
"441668", "Bamburgh",
"441760", "Swaffham",
"441875", "Tranent",
"441695", "Skelmersdale",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441923", "Watford",
"441827", "Tamworth",
"441845", "Thirsk",
"441823", "Taunton",
"441258", "Blandford",
"441262", "Bridlington",
"441945", "Wisbech",
"4412297", "Millom",
"442891", "Bangor\ \(Co\.\ Down\)",
"441369", "Dunoon",
"441450", "Hawick",
"4416868", "Newtown",
"4418901", "Coldstream\/Ayton",
"4419647", "Patrington",
"441806", "Shetland",
"441424", "Hastings",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441704", "Southport",
"441588", "Bishops\ Castle",
"4415075", "Spilsby\ \(Horncastle\)",
"441564", "Lapworth",
"441270", "Crewe",
"442830", "Newry",
"441586", "Campbeltown",
"441535", "Keighley",
"441300", "Cerne\ Abbas",
"4414236", "Harrogate",
"4417687", "Keswick",
"441476", "Grantham",
"442824", "Northern\ Ireland",
"4418511", "Great\ Bernera\/Stornoway",
"441236", "Coatbridge",
"441285", "Cirencester",
"441808", "Tomatin",
"441653", "Malton",
"441908", "Milton\ Keynes",
"441294", "Ardrossan",
"441777", "Retford",
"441689", "Orpington",
"441555", "Lanark",
"441592", "Kirkcaldy",
"441491", "Henley\-on\-Thames",
"4418478", "Thurso",
"441773", "Ripley",
"4415073", "Louth",
"441637", "Newquay",
"441256", "Basingstoke",
"441633", "Newport",
"44114701", "Sheffield",
"44238", "Southampton",
"441397", "Fort\ William",
"4415242", "Hornby",
"441405", "Goole",
"441364", "Ashburton",
"441666", "Malmesbury",
"441388", "Bishop\ Auckland",
"441743", "Shrewsbury",
"441880", "Tarbert",
"4418470", "Thurso\/Tongue",
"44161", "Manchester",
"441980", "Amesbury",
"441725", "Rockbourne",
"441747", "Shaftesbury",
"441709", "Rotherham",
"441263", "Cromer",
"441822", "Tavistock",
"44280", "Northern\ Ireland",
"441267", "Carmarthen",
"442848", "Northern\ Ireland",
"441922", "Walsall",
"441446", "Barry",
"441569", "Stonehaven",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441429", "Hartlepool",
"441928", "Runcorn",
"441559", "Llandysul",
"441636", "Newark\-on\-Trent",
"441685", "Merthyr\ Tydfil",
"441257", "Coppull",
"441334", "St\ Andrews",
"442842", "Kircubbin",
"441974", "Llanon",
"441828", "Coupar\ Angus",
"441253", "Blackpool",
"441874", "Brecon",
"441694", "Church\ Stretton",
"441776", "Stranraer",
"441320", "Fort\ Augustus",
"441951", "Colonsay",
"4419643", "Patrington",
"4414342", "Bellingham",
"44114702", "Sheffield",
"441477", "Holmes\ Chapel",
"441382", "Dundee",
"441539", "Kendal",
"441656", "Bridgend",
"441237", "Bideford",
"441354", "Chatteris",
"441233", "Ashford\ \(Kent\)",
"441473", "Ipswich",
"4412293", "Millom",
"441289", "Berwick\-upon\-Tweed",
"441371", "Great\ Dunmow",
"441931", "Shap",
"441583", "Carradale",
"44121", "Birmingham",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441598", "Lynton",
"441565", "Knutsford",
"441341", "Barmouth",
"441443", "Pontypridd",
"441425", "Ringwood",
"441409", "Holsworthy",
"442881", "Newtownstewart",
"4416866", "Newtown",
"441746", "Bridgnorth",
"441902", "Wolverhampton",
"44292", "Cardiff",
"441844", "Thame",
"441663", "New\ Mills",
"441944", "West\ Heslerton",
"441667", "Nairn",
"441729", "Settle",
"4414234", "Boroughbridge",
"441463", "Inverness",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441322", "Dartford",
"441467", "Inverurie",
"441246", "Chesterfield",
"4414239", "Boroughbridge",
"442899", "Northern\ Ireland",
"4418905", "Ayton",
"441609", "Northallerton",
"4414348", "Hexham",
"442840", "Banbridge",
"441545", "Llanarth",
"441527", "Redditch",
"441361", "Duns",
"441205", "Boston",
"441888", "Turriff",
"441643", "Minehead",
"441864", "Abington\ \(Crawford\)",
"441988", "Wigtown",
"4418513", "Stornoway",
"441647", "Moretonhampstead",
"441625", "Macclesfield",
"4414307", "Market\ Weighton",
"441506", "Bathgate",
"441766", "Porthmadog",
"441380", "Devizes",
"442821", "Martinstown",
"441737", "Redhill",
"441733", "Peterborough",
"441291", "Chepstow",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441789", "Stratford\-upon\-Avon",
"441677", "Bedale",
"441993", "Witney",
"441456", "Glenurquhart",
"441997", "Strathpeffer",
"441673", "Market\ Rasen",
"441575", "Kirriemuir",
"442870", "Coleraine",
"441757", "Selby",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441913", "Durham",
"441917", "Sunderland",
"441753", "Slough",
"441900", "Workington",
"4413395", "Aboyne",
"441143", "Sheffield",
"442838", "Portadown",
"441276", "Camberley",
"441485", "Hunstanton",
"441436", "Helensburgh",
"44114707", "Sheffield",
"441308", "Bridport",
"4419757", "Strathdon",
"441494", "High\ Wycombe",
"4414305", "North\ Cave",
"441763", "Royston",
"441209", "Redruth",
"441767", "Sandy",
"441629", "Matlock",
"441503", "Looe",
"4412291", "Barrow\-in\-Furness\/Millom",
"441302", "Doncaster",
"441344", "Bracknell",
"441646", "Milford\ Haven",
"441841", "Newquay\ \(Padstow\)",
"4419641", "Hornsea\/Patrington",
"44141", "Glasgow",
"4418907", "Ayton",
"441526", "Martin",
"4418472", "Thurso",
"4420", "London",
"442895", "Belfast",
"441243", "Chichester",
"441590", "Lymington",
"442884", "Northern\ Ireland",
"441466", "Huntly",
"441549", "Lairg",
"441225", "Bath",
"442868", "Kesh",
"441954", "Madingley",
"441277", "Brentwood",
"441982", "Builth\ Wells",
"441579", "Liskeard",
"441433", "Hathersage",
"4419755", "Alford\ \(Aberdeen\)",
"441854", "Ullapool",
"441273", "Brighton",
"441882", "Kinloch\ Rannoch",
"441971", "Scourie",
"441489", "Bishops\ Waltham",
"441146", "Sheffield",
"441756", "Skipton",
"441691", "Oswestry",
"441916", "Tyneside",
"441871", "Castlebay",
"4413397", "Ballater",
"441896", "Galashiels",
"441934", "Weston\-super\-Mare",
"441676", "Meriden",
"441328", "Fakenham",
"4416864", "Llanidloes",
"441457", "Glossop",
"4416869", "Newtown",
"441453", "Dursley",
"441834", "Narberth",
"441920", "Ware",
"441785", "Stafford",
"441736", "Penzance",
"441794", "Romsey",
"4419753", "Strathdon",
"441630", "Market\ Drayton",
"441738", "Perth",
"441349", "Dingwall",
"441865", "Oxford",
"441204", "Bolton",
"44114708", "Sheffield",
"4418474", "Thurso",
"441326", "Falmouth",
"441624", "Isle\ of\ Man",
"4418479", "Tongue",
"441242", "Cheltenham",
"441770", "Isle\ of\ Arran",
"441678", "Bala",
"441502", "Lowestoft",
"441918", "Tyneside",
"442889", "Fivemiletown",
"441650", "Cemmaes\ Road",
"441544", "Kington",
"441758", "Pwllheli",
"4414346", "Hexham",
"441307", "Forfar",
"4413885", "Stanhope\ \(Eastgate\)",
"441303", "Folkestone",
"441721", "Peebles",
"442837", "Armagh",
"441484", "Huddersfield",
"442866", "Enniskillen",
"441452", "Gloucester",
"441495", "Pontypool",
"4414303", "North\ Cave",
"441528", "Laggan",
"441959", "Westerham",
"44291", "Cardiff",
"441260", "Congleton",
"4418517", "Stornoway",
"441859", "Harris",
"4416862", "Llanidloes",
"44281", "Northern\ Ireland",
"441883", "Caterham",
"441740", "Sedgefield",
"441987", "Ebbsfleet",
"441531", "Ledbury",
"441432", "Hereford",
"441983", "Isle\ of\ Wight",
"4416974", "Raughton\ Head",
"441799", "Saffron\ Walden",
"441887", "Aberfeldy",
"441379", "Diss",
"441939", "Wem",
"442894", "Antrim",
"441306", "Dorking",
"441604", "Northampton",
"441224", "Aberdeen",
"441580", "Cranbrook",
"441438", "Stevenage",
"441642", "Middlesbrough",
"442311", "Southampton",
"441278", "Bridgwater",
"442885", "Ballygawley",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"4413393", "Aboyne",
"441323", "Eastbourne",
"441327", "Daventry",
"441458", "Glastonbury",
"441561", "Laurencekirk",
"441462", "Hitchin",
"4413873", "Langholm",
"441869", "Bicester",
"4414232", "Harrogate",
"441250", "Blairgowrie",
"441522", "Lincoln",
"441969", "Leyburn",
"441142", "Sheffield",
"441784", "Staines",
"441752", "Plymouth",
"441768", "Penrith",
"441912", "Tyneside",
"441795", "Sittingbourne",
"441508", "Brooke",
"441986", "Bungay",
"441935", "Yeovil",
"441375", "Grays\ Thurrock",
"4415395", "Grange\-over\-Sands",
"4418903", "Coldstream",
"441835", "St\ Boswells",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441440", "Haverhill",
"441732", "Sevenoaks",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"4418515", "Stornoway",
"44114700", "Sheffield",
"441499", "Inveraray",
"441248", "Bangor\ \(Gwynedd\)",
"441892", "Tunbridge\ Wells",
"441672", "Marlborough",
"442867", "Lisnaskea",
"441955", "Wick",
"441992", "Lea\ Valley",
"441855", "Ballachulish",
"441403", "Horsham",
"44114703", "Sheffield",
"441407", "Holyhead",
"4418516", "Great\ Bernera",
"4414231", "Harrogate\/Boroughbridge",
"4419758", "Strathdon",
"44114704", "Sheffield",
"441727", "St\ Albans",
"441669", "Rothbury",
"441745", "Rhyl",
"4415079", "Alford\ \(Lincs\)",
"4415074", "Alford\ \(Lincs\)",
"441723", "Scarborough",
"441301", "Arrochar",
"442828", "Larne",
"4414300", "North\ Cave\/Market\ Weighton",
"441942", "Wigan",
"441842", "Thetford",
"441298", "Buxton",
"441904", "York",
"44151", "Liverpool",
"44114709", "Sheffield",
"4415396", "Sedbergh",
"441566", "Launceston",
"441449", "Stowmarket",
"441706", "Rochdale",
"441490", "Corwen",
"441239", "Cardigan",
"441479", "Grantown\-on\-Spey",
"441981", "Wormbridge",
"4414379", "Haverfordwest",
"441283", "Burton\-on\-Trent",
"441692", "North\ Walsham",
"441872", "Truro",
"442844", "Downpatrick",
"441972", "Glenborrodale",
"441332", "Derby",
"4414308", "Market\ Weighton",
"4414374", "Clynderwen\ \(Clunderwen\)",
"441287", "Guisborough",
"441655", "Maybole",
"441553", "Kings\ Lynn",
"441259", "Alloa",
"441775", "Spalding",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"441557", "Kirkcudbright",
"4414347", "Hexham",
"441395", "Budleigh\ Salterton",
"441368", "Dunbar",
"441352", "Mold",
"441635", "Newbury",
"441384", "Dudley",
"4412294", "Barrow\-in\-Furness",
"441567", "Killin",
"441950", "Sandwick",
"441269", "Ammanford",
"441707", "Welwyn\ Garden\ City",
"4412299", "Millom",
"441563", "Kilmarnock",
"441445", "Gairloch",
"441427", "Gainsborough",
"441358", "Ellon",
"441362", "Dereham",
"441726", "St\ Austell",
"441830", "Kirkwhelpington",
"4418900", "Coldstream\/Ayton",
"441665", "Alnwick",
"441749", "Shepton\ Mallet",
"441924", "Wakefield",
"441978", "Wrexham",
"4419644", "Patrington",
"4413398", "Aboyne",
"441824", "Ruthin",
"441406", "Holbeach",
"4419649", "Hornsea",
"441698", "Motherwell",
"441878", "Lochboisdale",
"441790", "Spilsby",
"441683", "Moffat",
"441292", "Ayr",
"441848", "Thornhill",
"4414345", "Haltwhistle",
"4413390", "Aboyne\/Ballater",
"441948", "Whitchurch",
"441779", "Peterhead",
"442822", "Northern\ Ireland",
"4418908", "Coldstream",
"44287", "Northern\ Ireland",
"441687", "Mallaig",
"441255", "Clacton\-on\-Sea",
"441639", "Neath",
"441556", "Castle\ Douglas",
"441340", "Craigellachie\ \(Aberlour\)",
"441475", "Greenock",
"441286", "Caernarfon",
"441235", "Abingdon",
"441594", "Lydney",
"4416861", "Newtown\/Llanidloes",
"441659", "Sanquhar",
"442880", "Carrickmore",
"441536", "Kettering",
"441480", "Huntingdon",
"441538", "Ipstones",
"441641", "Strathy",
"4418471", "Thurso\/Tongue",
"4414343", "Haltwhistle",
"4419642", "Hornsea",
"441805", "Torrington",
"441288", "Bude",
"441570", "Lampeter",
"441264", "Andover",
"441905", "Worcester",
"441744", "St\ Helens",
"4419756", "Strathdon",
"441929", "Wareham",
"441558", "Llandeilo",
"441562", "Kidderminster",
"441461", "Gretna",
"44116", "Leicester",
"441702", "Southend\-on\-Sea",
"441829", "Tarporley",
"441422", "Halifax",
"441367", "Faringdon",
"441946", "Whitehaven",
"4412292", "Barrow\-in\-Furness",
"441363", "Crediton",
"4418518", "Stornoway",
"441394", "Felixstowe",
"441911", "Tyneside\/Durham\/Sunderland",
"4418510", "Great\ Bernera\/Stornoway",
"441876", "Lochmaddy",
"441408", "Golspie",
"441141", "Sheffield",
"441634", "Medway",
"441751", "Pickering",
"441200", "Clitheroe",
"441728", "Saxmundham",
"441620", "North\ Berwick",
"4417684", "Pooley\ Bridge",
"441297", "Axminster",
"442823", "Northern\ Ireland",
"441599", "Kyle",
"4414306", "Market\ Weighton",
"441356", "Brechin",
"441540", "Kingussie",
"441654", "Machynlleth",
"442827", "Ballymoney",
"442845", "Northern\ Ireland",
"441293", "Crawley",
"441671", "Newton\ Stewart",
"441780", "Stamford",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"441843", "Thanet",
"4413396", "Ballater",
"441925", "Warrington",
"441947", "Whitby",
"441664", "Melton\ Mowbray",
"441366", "Downham\ Market",
"441943", "Guiseley",
"441825", "Uckfield",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441241", "Arbroath",
"44131", "Edinburgh",
"441444", "Haywards\ Heath",
"441761", "Temple\ Cloud",
"4415072", "Spilsby\ \(Horncastle\)",
"441501", "Harthill",
"442879", "Magherafelt",
"441722", "Salisbury",
"441809", "Tomdoun",
"441909", "Worksop",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"441708", "Romford",
"441600", "Monmouth",
"442890", "Belfast",
"442849", "Northern\ Ireland",
"441584", "Ludlow",
"44115", "Nottingham",
"441568", "Leominster",
"441451", "Stow\-on\-the\-Wold",
"441296", "Aylesbury",
"441353", "Ely",
"441428", "Haslemere",
"441234", "Bedford",
"441357", "Strathaven",
"442826", "Northern\ Ireland",
"441474", "Gravesend",
"4414372", "Clynderwen\ \(Clunderwen\)",
"441271", "Barnstaple",
"441389", "Dumbarton",
"44113", "Leeds",
"441431", "Helmsdale",
"441697", "Brampton",
"441877", "Callander",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441977", "Pontefract",
"441254", "Blackburn",
"441337", "Ladybank",
"441873", "Abergavenny",
"441282", "Burnley",
"4418906", "Ayton",};
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
      $number =~ s/^(?:([0-24-8]\d{5})$|0)//;
      $self = bless({ country_code => '44', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;