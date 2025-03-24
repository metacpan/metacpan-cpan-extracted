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
our $VERSION = 1.20250323211829;

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
$areanames{en} = {"441246", "Chesterfield",
"441561", "Laurencekirk",
"441267", "Carmarthen",
"441239", "Cardigan",
"441483", "Guildford",
"441382", "Dundee",
"441480", "Huntingdon",
"4413881", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"441946", "Whitehaven",
"441967", "Strontian",
"441939", "Wem",
"4418476", "Tongue",
"441691", "Oswestry",
"441848", "Thornhill",
"441885", "Pencombe",
"441651", "Oldmeldrum",
"4414307", "Market\ Weighton",
"441376", "Braintree",
"441688", "Isle\ of\ Mull\ \-\ Tobermory",
"4419751", "Alford\ \(Aberdeen\)\/Strathdon",
"441837", "Okehampton",
"441869", "Bicester",
"442822", "Northern\ Ireland",
"441141", "Sheffield",
"441727", "St\ Albans",
"441962", "Winchester",
"441224", "Aberdeen",
"441481", "Guernsey",
"441387", "Dumfries",
"441563", "Kilmarnock",
"441924", "Wakefield",
"441560", "Moscow",
"441262", "Bridlington",
"441394", "Felixstowe",
"441650", "Cemmaes\ Road",
"4413873", "Langholm",
"441653", "Malton",
"441690", "Betws\-y\-Coed",
"441354", "Chatteris",
"4418471", "Thurso\/Tongue",
"4412299", "Millom",
"44141", "Glasgow",
"441832", "Clopton",
"441528", "Laggan",
"441406", "Holbeach",
"441722", "Salisbury",
"441458", "Glastonbury",
"441335", "Ashbourne",
"4414375", "Clynderwen\ \(Clunderwen\)",
"441140", "Sheffield",
"441143", "Sheffield",
"441764", "Crieff",
"442827", "Ballymoney",
"4419756", "Strathdon",
"4418909", "Ayton",
"442890", "Belfast",
"441751", "Pickering",
"442893", "Ballyclare",
"441576", "Lockerbie",
"4414236", "Harrogate",
"442310", "Portsmouth",
"442879", "Magherafelt",
"44283", "Northern\ Ireland",
"441280", "Buckingham",
"441582", "Luton",
"441283", "Burton\-on\-Trent",
"441467", "Inverurie",
"441439", "Helmsley",
"441361", "Duns",
"441983", "Isle\ of\ Wight",
"441980", "Amesbury",
"441446", "Barry",
"441874", "Brecon",
"4414304", "North\ Cave",
"441745", "Rhyl",
"4414349", "Bellingham",
"441788", "Rugby",
"44116", "Leicester",
"4414231", "Harrogate\/Boroughbridge",
"4416865", "Newtown",
"441896", "Galashiels",
"441328", "Fakenham",
"441206", "Colchester",
"441753", "Slough",
"44114701", "Sheffield",
"442891", "Bangor\ \(Co\.\ Down\)",
"441750", "Selkirk",
"4418519", "Great\ Bernera",
"4415079", "Alford\ \(Lincs\)",
"441793", "Swindon",
"441790", "Spilsby",
"44238", "Southampton",
"441856", "Orkney",
"441298", "Buxton",
"442311", "Southampton",
"441808", "Tomatin",
"441535", "Keighley",
"441258", "Blandford",
"441981", "Wormbridge",
"441622", "Maidstone",
"441779", "Peterhead",
"441462", "Hitchin",
"441360", "Killearn",
"441363", "Crediton",
"441664", "Melton\ Mowbray",
"441424", "Hastings",
"44121", "Birmingham",
"4414302", "North\ Cave",
"442845", "Northern\ Ireland",
"441554", "Llanelli",
"442888", "Northern\ Ireland",
"441594", "Lydney",
"441698", "Motherwell",
"441841", "Newquay\ \(Padstow\)",
"44287", "Northern\ Ireland",
"442867", "Lisnaskea",
"441724", "Scunthorpe",
"442846", "Northern\ Ireland",
"4415396", "Sedbergh",
"441479", "Grantown\-on\-Spey",
"441834", "Narberth",
"441568", "Leominster",
"441606", "Northwich",
"441493", "Great\ Yarmouth",
"441392", "Exeter",
"441490", "Corwen",
"44161", "Manchester",
"4419643", "Patrington",
"441536", "Kettering",
"441453", "Dursley",
"441549", "Lairg",
"441450", "Hawick",
"441352", "Mold",
"4414308", "Market\ Weighton",
"441895", "Uxbridge",
"4418515", "Stornoway",
"441205", "Boston",
"441520", "Lochcarron",
"4416869", "Newtown",
"441905", "Worcester",
"4415075", "Spilsby\ \(Horncastle\)",
"441264", "Andover",
"441681", "Isle\ of\ Mull\ \-\ Fionnphort",
"441922", "Walsall",
"441855", "Ballachulish",
"441767", "Sandy",
"441309", "Forres",
"4414345", "Haltwhistle",
"441746", "Bridgnorth",
"442824", "Northern\ Ireland",
"441843", "Thanet",
"441840", "Camelford",
"441488", "Hungerford",
"441829", "Tarporley",
"441919", "Durham",
"441445", "Gairloch",
"441451", "Stow\-on\-the\-Wold",
"441357", "Strathaven",
"441491", "Henley\-on\-Thames",
"44114707", "Sheffield",
"441397", "Fort\ William",
"4418905", "Ayton",
"441680", "Isle\ of\ Mull\ \-\ Craignure",
"441683", "Moffat",
"441227", "Canterbury",
"441575", "Kirriemuir",
"441384", "Dudley",
"441250", "Blairgowrie",
"441349", "Dingwall",
"441253", "Blackpool",
"441706", "Rochdale",
"441993", "Witney",
"441877", "Callander",
"441953", "Wymondham",
"441950", "Sandwick",
"441290", "Cumnock",
"441592", "Kirkcaldy",
"4414379", "Haverfordwest",
"441293", "Crawley",
"441803", "Torquay",
"441464", "Insch",
"441798", "Pulborough",
"441624", "Isle\ of\ Man",
"441323", "Eastbourne",
"441422", "Halifax",
"441320", "Fort\ Augustus",
"441405", "Goole",
"441758", "Pwllheli",
"442880", "Carrickmore",
"442883", "Northern\ Ireland",
"4413396", "Ballater",
"441279", "Bishops\ Stortford",
"4412295", "Barrow\-in\-Furness",
"441368", "Dunbar",
"441597", "Llandrindod\ Wells",
"441291", "Chepstow",
"441951", "Colonsay",
"441872", "Truro",
"441557", "Kirkcudbright",
"442898", "Belfast",
"441667", "Nairn",
"441584", "Ludlow",
"441639", "Neath",
"441375", "Grays\ Thurrock",
"441646", "Milford\ Haven",
"441427", "Gainsborough",
"441780", "Stamford",
"44239", "Portsmouth",
"441886", "Bromyard\ \(Knightwick\/Leigh\ Sinton\)",
"441509", "Loughborough",
"442881", "Newtownstewart",
"4413391", "Aboyne\/Ballater",
"4414300", "North\ Cave\/Market\ Weighton",
"441245", "Chelmsford",
"44281", "Northern\ Ireland",
"441988", "Wigtown",
"441945", "Wisbech",
"44292", "Cardiff",
"441288", "Bude",
"441571", "Lochinver",
"441525", "Leighton\ Buzzard",
"441277", "Brentwood",
"441756", "Skipton",
"441502", "Lowestoft",
"441200", "Clitheroe",
"441977", "Pontefract",
"441900", "Workington",
"441903", "Worthing",
"441796", "Pitlochry",
"4419757", "Strathdon",
"441495", "Pontypool",
"4418903", "Coldstream",
"441708", "Romford",
"4413390", "Aboyne\/Ballater",
"4414301", "North\ Cave\/Market\ Weighton",
"441455", "Hinckley",
"441366", "Downham\ Market",
"4414343", "Haltwhistle",
"44247", "Coventry",
"441347", "Easingwold",
"4414232", "Harrogate",
"441879", "Scarinish",
"4419645", "Hornsea",
"441685", "Merthyr\ Tydfil",
"441972", "Glenborrodale",
"441573", "Kelso",
"442896", "Belfast",
"441570", "Lampeter",
"4414306", "Market\ Weighton",
"4418513", "Stornoway",
"4415073", "Louth",
"441286", "Caernarfon",
"4418477", "Tongue",
"441599", "Kyle",
"441443", "Pontypridd",
"441986", "Bungay",
"441559", "Llandysul",
"441440", "Haverhill",
"441342", "East\ Grinstead",
"4414234", "Boroughbridge",
"441429", "Hartlepool",
"441637", "Newquay",
"44291", "Cardiff",
"441669", "Rothbury",
"441888", "Turriff",
"441845", "Thirsk",
"4419754", "Alford\ \(Aberdeen\)",
"441547", "Knighton",
"441241", "Arbroath",
"441608", "Chipping\ Norton",
"441566", "Launceston",
"441656", "Bridgend",
"441934", "Weston\-super\-Mare",
"442885", "Ballygawley",
"442848", "Northern\ Ireland",
"441234", "Bedford",
"442837", "Armagh",
"441302", "Doncaster",
"441400", "Honington",
"441732", "Sevenoaks",
"441403", "Horsham",
"441477", "Holmes\ Chapel",
"441325", "Darlington",
"441371", "Great\ Dunmow",
"4418472", "Thurso",
"441912", "Tyneside",
"441995", "Garstang",
"441538", "Ipstones",
"441255", "Clacton\-on\-Sea",
"441864", "Abington\ \(Crawford\)",
"441295", "Banbury",
"44117", "Bristol",
"441805", "Torrington",
"441146", "Sheffield",
"441822", "Tavistock",
"441955", "Wick",
"4419752", "Alford\ \(Aberdeen\)",
"441542", "Keith",
"441359", "Pakenham",
"441243", "Chichester",
"441943", "Guiseley",
"4412293", "Millom",
"44241", "Coventry",
"441929", "Wareham",
"441785", "Stafford",
"441748", "Richmond",
"4413398", "Aboyne",
"4413882", "Stanhope\ \(Eastgate\)",
"441472", "Grimsby",
"441373", "Frome",
"441307", "Forfar",
"441769", "South\ Molton",
"441737", "Redhill",
"441674", "Montrose",
"441827", "Tamworth",
"4418474", "Thurso",
"4414237", "Harrogate",
"441917", "Sunderland",
"4419758", "Strathdon",
"44286", "Northern\ Ireland",
"442877", "Limavady",
"441772", "Preston",
"441629", "Matlock",
"441469", "Killingholme",
"441643", "Minehead",
"441578", "Lauder",
"44113", "Leeds",
"4413392", "Aboyne",
"441344", "Bracknell",
"4414373", "Clynderwen\ \(Clunderwen\)",
"441786", "Stirling",
"4414230", "Harrogate\/Boroughbridge",
"441883", "Caterham",
"441880", "Tarbert",
"441974", "Llanon",
"4417687", "Keswick",
"441274", "Bradford",
"441485", "Hunstanton",
"441700", "Rothesay",
"441333", "Peat\ Inn\ \(Leven\ \(Fife\)\)",
"441432", "Hereford",
"441330", "Banchory",
"441256", "Basingstoke",
"441777", "Retford",
"441296", "Aylesbury",
"441806", "Shetland",
"441145", "Sheffield",
"441634", "Medway",
"441858", "Market\ Harborough",
"441908", "Milton\ Keynes",
"4413394", "Ballater",
"441208", "Bodmin",
"441326", "Falmouth",
"441641", "Strathy",
"441655", "Maybole",
"442886", "Cookstown",
"441695", "Skelmersdale",
"44114702", "Sheffield",
"4418478", "Thurso",
"441565", "Knutsford",
"441743", "Shrewsbury",
"441740", "Sedgefield",
"442841", "Rostrevor",
"441285", "Cirencester",
"441474", "Gravesend",
"441948", "Whitchurch",
"441729", "Settle",
"441985", "Warminster",
"441672", "Marlborough",
"441248", "Bangor\ \(Gwynedd\)",
"441237", "Bideford",
"441269", "Ammanford",
"441531", "Ledbury",
"4417684", "Pooley\ Bridge",
"4416863", "Llanidloes",
"441937", "Wetherby",
"441969", "Leyburn",
"4418470", "Thurso\/Tongue",
"441544", "Kington",
"4419649", "Hornsea",
"442895", "Belfast",
"441862", "Tain",
"442840", "Banbridge",
"4419750", "Alford\ \(Aberdeen\)\/Strathdon",
"442843", "Newcastle\ \(Co\.\ Down\)",
"441914", "Tyneside",
"4413397", "Ballater",
"441824", "Ruthin",
"441603", "Norwich",
"441600", "Monmouth",
"441677", "Bedale",
"442829", "Kilrea",
"441304", "Dover",
"441389", "Dumbarton",
"4413880", "Bishop\ Auckland\/Stanhope\ \(Eastgate\)",
"4416974", "Raughton\ Head",
"441496", "Port\ Ellen",
"441932", "Weybridge",
"4414238", "Harrogate",
"441456", "Glenurquhart",
"441530", "Coalville",
"4415242", "Hornby",
"441526", "Martin",
"441408", "Golspie",
"4415394", "Hawkshead",
"441795", "Sittingbourne",
"441236", "Coatbridge",
"4412294", "Barrow\-in\-Furness",
"441728", "Saxmundham",
"4415077", "Louth",
"441353", "Ely",
"441452", "Gloucester",
"441249", "Chippenham",
"441350", "Dunkeld",
"441694", "Church\ Stretton",
"441654", "Machynlleth",
"441492", "Colwyn\ Bay",
"441949", "Whatton",
"4418517", "Stornoway",
"441687", "Mallaig",
"441923", "Watford",
"441564", "Lapworth",
"441920", "Ware",
"441838", "Dalmally",
"441505", "Johnstone",
"441522", "Lincoln",
"441223", "Cambridge",
"441379", "Diss",
"441635", "Newbury",
"441760", "Swaffham",
"441144", "Sheffield",
"441763", "Royston",
"441866", "Kilchrenan",
"4416860", "Newtown\/Llanidloes",
"441968", "Penicuik",
"4418473", "Thurso",
"441268", "Basildon",
"442828", "Larne",
"4412292", "Barrow\-in\-Furness",
"441497", "Hay\-on\-Wye",
"4419753", "Strathdon",
"441457", "Glossop",
"4418907", "Ayton",
"441527", "Redditch",
"441275", "Clevedon",
"441484", "Huddersfield",
"4414378", "Haverfordwest",
"44115", "Nottingham",
"44280", "Northern\ Ireland",
"441842", "Thetford",
"441409", "Holsworthy",
"441761", "Temple\ Cloud",
"441676", "Meriden",
"441388", "Bishop\ Auckland",
"4414347", "Hexham",
"441787", "Sudbury",
"442882", "Omagh",
"441579", "Liskeard",
"441628", "Maidenhead",
"4414370", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"441794", "Romsey",
"4415074", "Alford\ \(Lincs\)",
"4412297", "Millom",
"441754", "Skegness",
"4418514", "Great\ Bernera",
"4418902", "Coldstream",
"4414233", "Boroughbridge",
"441825", "Uckfield",
"441952", "Telford",
"441871", "Castlebay",
"441590", "Lymington",
"441292", "Ayr",
"441593", "Lybster",
"441449", "Stowmarket",
"441252", "Aldershot",
"441550", "Llandovery",
"441553", "Kings\ Lynn",
"441915", "Sunderland",
"4414342", "Bellingham",
"441436", "Helensburgh",
"441992", "Lea\ Valley",
"441420", "Alton",
"441322", "Dartford",
"441305", "Dorchester",
"441663", "New\ Mills",
"441364", "Ashburton",
"441209", "Redruth",
"442887", "Dungannon",
"441899", "Biggar",
"441859", "Harris",
"441782", "Stoke\-on\-Trent",
"441909", "Worksop",
"4415072", "Spilsby\ \(Horncastle\)",
"441588", "Bishops\ Castle",
"442894", "Antrim",
"4418904", "Coldstream",
"441545", "Llanarth",
"4418512", "Stornoway",
"441997", "Strathpeffer",
"441776", "Stranraer",
"441257", "Coppull",
"441297", "Axminster",
"441807", "Ballindalloch",
"4414309", "Market\ Weighton",
"441591", "Llanwrtyd\ Wells",
"4414344", "Bellingham",
"441870", "Isle\ of\ Benbecula",
"441873", "Abergavenny",
"441957", "Mid\ Yell",
"4416868", "Newtown",
"441984", "Watchet\ \(Williton\)",
"441661", "Prudhoe",
"441284", "Bury\ St\ Edmunds",
"441475", "Greenock",
"441327", "Daventry",
"442849", "Northern\ Ireland",
"441476", "Grantham",
"441844", "Thame",
"441609", "Northallerton",
"4415078", "Alford\ \(Lincs\)",
"4419646", "Patrington",
"441721", "Peebles",
"441775", "Spalding",
"442820", "Ballycastle",
"442823", "Northern\ Ireland",
"4414305", "North\ Cave",
"4418518", "Stornoway",
"441383", "Dunfermline",
"441380", "Devizes",
"441482", "Kingston\-upon\-Hull",
"441546", "Lochgilphead",
"441261", "Banff",
"4416973", "Wigton",
"441567", "Killin",
"4416862", "Llanidloes",
"441684", "Malvern",
"441539", "Kendal",
"441697", "Brampton",
"442868", "Kesh",
"441749", "Shepton\ Mallet",
"441306", "Dorking",
"441228", "Carlisle",
"4412290", "Barrow\-in\-Furness\/Millom",
"4414377", "Haverfordwest",
"4419641", "Hornsea\/Patrington",
"441736", "Penzance",
"44114708", "Sheffield",
"441833", "Barnard\ Castle",
"441830", "Kirkwhelpington",
"441928", "Runcorn",
"441142", "Sheffield",
"441398", "Dulverton",
"442821", "Martinstown",
"441723", "Scarborough",
"441720", "Isles\ of\ Scilly",
"441916", "Tyneside",
"4418908", "Coldstream",
"441435", "Heathfield",
"441358", "Ellon",
"441263", "Cromer",
"441260", "Congleton",
"441562", "Kidderminster",
"441963", "Wincanton",
"4416864", "Llanidloes",
"441524", "Lancaster",
"4417683", "Appleby",
"441381", "Fortrose",
"441487", "Warboys",
"4414348", "Hexham",
"441454", "Chipping\ Sodbury",
"441692", "North\ Walsham",
"44131", "Edinburgh",
"44118", "Reading",
"441652", "Brigg",
"441494", "High\ Wycombe",
"441768", "Penrith",
"441367", "Faringdon",
"441461", "Gretna",
"441709", "Rotherham",
"4412298", "Barrow\-in\-Furness",
"441675", "Coleshill",
"441346", "Fraserburgh",
"441621", "Maldon",
"441982", "Builth\ Wells",
"441580", "Cranbrook",
"441282", "Burnley",
"441583", "Carradale",
"4413393", "Aboyne",
"4414372", "Clynderwen\ \(Clunderwen\)",
"4418900", "Coldstream\/Ayton",
"442892", "Lisburn",
"441757", "Selby",
"441276", "Camberley",
"4414340", "Bellingham\/Haltwhistle\/Hexham",
"441797", "Rye",
"441878", "Lochboisdale",
"4420", "London",
"441784", "Staines",
"441287", "Guisborough",
"441581", "New\ Luce",
"441324", "Falkirk",
"441620", "North\ Berwick",
"441987", "Ebbsfleet",
"441623", "Mansfield",
"441362", "Dereham",
"441460", "Chard",
"441463", "Inverness",
"4414374", "Clynderwen\ \(Clunderwen\)",
"4415070", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441294", "Ardrossan",
"441954", "Madingley",
"441636", "Newark\-on\-Trent",
"44151", "Liverpool",
"441994", "St\ Clears",
"441865", "Oxford",
"441254", "Blackburn",
"4418510", "Great\ Bernera\/Stornoway",
"441792", "Swansea",
"441428", "Haslemere",
"441506", "Bathgate",
"442897", "Saintfield",
"441889", "Rugeley",
"441668", "Bamburgh",
"441752", "Plymouth",
"441235", "Abingdon",
"441558", "Llandeilo",
"441935", "Yeovil",
"4416867", "Llanidloes",
"441598", "Lynton",
"442884", "Northern\ Ireland",
"441759", "Pocklington",
"441882", "Kinloch\ Rannoch",
"441799", "Saffron\ Walden",
"4414346", "Hexham",
"44114703", "Sheffield",
"441348", "Fishguard",
"441770", "Isle\ of\ Arran",
"4418906", "Ayton",
"441773", "Ripley",
"441707", "Welwyn\ Garden\ City",
"441431", "Helmsdale",
"441369", "Dunoon",
"441337", "Ladybank",
"441876", "Lochmaddy",
"442871", "Londonderry",
"442825", "Ballymena",
"4414239", "Boroughbridge",
"441978", "Wrexham",
"441444", "Haywards\ Heath",
"4418511", "Great\ Bernera\/Stornoway",
"441642", "Middlesbrough",
"4415071", "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)",
"441278", "Bridgwater",
"44114709", "Sheffield",
"4419467", "Gosforth",
"4414341", "Bellingham\/Haltwhistle\/Hexham",
"441638", "Newmarket",
"441887", "Aberfeldy",
"442899", "Northern\ Ireland",
"441904", "York",
"441854", "Ullapool",
"441204", "Bolton",
"4415395", "Grange\-over\-Sands",
"4418516", "Great\ Bernera",
"442870", "Coleraine",
"441289", "Berwick\-upon\-Tweed",
"441433", "Hathersage",
"441702", "Southend\-on\-Sea",
"441332", "Derby",
"4419648", "Hornsea",
"441556", "Castle\ Douglas",
"441989", "Ross\-on\-Wye",
"4415076", "Louth",
"441771", "Maud",
"441725", "Rockbourne",
"441666", "Malmesbury",
"441647", "Moretonhampstead",
"4418901", "Coldstream\/Ayton",
"441508", "Brooke",
"441835", "St\ Boswells",
"4414303", "North\ Cave",
"441931", "Shap",
"44114704", "Sheffield",
"441569", "Stonehaven",
"441944", "West\ Heslerton",
"441478", "Isle\ of\ Skye\ \-\ Portree",
"441659", "Sanquhar",
"442838", "Portadown",
"441244", "Chester",
"442866", "Enniskillen",
"442847", "Northern\ Ireland",
"4418479", "Tongue",
"4419640", "Hornsea\/Patrington",
"4412291", "Barrow\-in\-Furness\/Millom",
"441673", "Market\ Rasen",
"441670", "Morpeth",
"441548", "Kingsbridge",
"441918", "Tyneside",
"441356", "Brechin",
"441233", "Ashford\ \(Kent\)",
"441489", "Bishops\ Waltham",
"441933", "Wellingborough",
"441828", "Coupar\ Angus",
"441926", "Warwick",
"441308", "Bridport",
"441226", "Barnsley",
"4419759", "Alford\ \(Aberdeen\)",
"441738", "Perth",
"441766", "Porthmadog",
"441747", "Shaftesbury",
"442842", "Kircubbin",
"441863", "Ardgay",
"441404", "Honiton",
"4413395", "Aboyne",
"441465", "Girvan",
"4412296", "Barrow\-in\-Furness",
"441625", "Macclesfield",
"441671", "Newton\ Stewart",
"4413399", "Ballater",
"441466", "Huntly",
"441341", "Barmouth",
"441626", "Newton\ Abbot",
"4413885", "Stanhope\ \(Eastgate\)",
"441630", "Market\ Drayton",
"441765", "Ripon",
"441633", "Newport",
"441334", "St\ Andrews",
"441704", "Southport",
"441789", "Stratford\-upon\-Avon",
"441971", "Scourie",
"441925", "Warrington",
"441852", "Kilmelford",
"441902", "Wolverhampton",
"441271", "Barnstaple",
"441225", "Bath",
"441577", "Kinross",
"4414376", "Haverfordwest",
"441503", "Looe",
"441202", "Bournemouth",
"4419755", "Alford\ \(Aberdeen\)",
"441892", "Tunbridge\ Wells",
"441438", "Stevenage",
"441355", "East\ Kilbride",
"441395", "Budleigh\ Salterton",
"441343", "Elgin",
"441259", "Alloa",
"441442", "Hemel\ Hempstead",
"441340", "Craigellachie\ \(Aberlour\)",
"441959", "Westerham",
"441586", "Campbeltown",
"441809", "Tomdoun",
"441644", "New\ Galloway",
"441299", "Bewdley",
"441329", "Fareham",
"4418475", "Thurso",
"441631", "Oban",
"441501", "Harthill",
"441207", "Consett",
"442889", "Fivemiletown",
"441273", "Brighton",
"441270", "Crewe",
"441572", "Oakham",
"441970", "Aberystwyth",
"441857", "Sanday",
"441884", "Tiverton",
"441778", "Bourne",
"44114700", "Sheffield",
"4414371", "Haverfordwest\/Clynderwen\ \(Clunderwen\)",
"4419647", "Patrington",
"441300", "Cerne\ Abbas",
"441733", "Peterborough",
"441303", "Folkestone",
"441665", "Alnwick",
"441730", "Petersfield",
"441377", "Driffield",
"441471", "Isle\ of\ Skye\ \-\ Broadford",
"441425", "Ringwood",
"441604", "Northampton",
"441595", "Lerwick\,\ Foula\ \&\ Fair\ Isle",
"4416866", "Newtown",
"441823", "Taunton",
"441938", "Welshpool",
"441910", "Tyneside\/Durham\/Sunderland",
"441913", "Durham",
"441555", "Lanark",
"442844", "Downpatrick",
"441726", "St\ Austell",
"441947", "Whitby",
"4419642", "Hornsea",
"441689", "Orpington",
"441534", "Jersey",
"442830", "Newry",
"4416861", "Newtown\/Llanidloes",
"4414235", "Harrogate",
"441372", "Esher",
"441470", "Isle\ of\ Skye\ \-\ Edinbane",
"441473", "Ipswich",
"441407", "Holyhead",
"441301", "Arrochar",
"441911", "Tyneside\/Durham\/Sunderland",
"441821", "Kinrossie",
"441875", "Tranent",
"442826", "Northern\ Ireland",
"441744", "St\ Helens",
"441499", "Inveraray",
"441942", "Wigan",
"441386", "Evesham",
"4419644", "Patrington",
"441678", "Bala",
"441242", "Cheltenham",
"441540", "Kingussie",
"441543", "Cannock",
"44114705", "Sheffield",
"441529", "Sleaford",};
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