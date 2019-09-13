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
package Number::Phone::StubCountry::IM;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215426;

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
                [04-9]|
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
                'fixed_line' => '1624[5-8]\\d{5}',
                'geographic' => '1624[5-8]\\d{5}',
                'mobile' => '
          76245[06]\\d{4}|
          7(?:
            4576|
            [59]24\\d|
            624[0-4689]
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '70\\d{8}',
                'specialrate' => '(
          8(?:
            440[49]06|
            72299\\d
          )\\d{3}|
          (?:
            8(?:
              45|
              70
            )|
            90[0167]
          )624\\d{4}
        )|(
          3440[49]06\\d{3}|
          (?:
            3(?:
              08162|
              3\\d{4}|
              45624|
              7(?:
                0624|
                2299
              )
            )|
            55\\d{4}
          )\\d{4}
        )',
                'toll_free' => '808162\\d{4}',
                'voip' => '56\\d{8}'
              };
my %areanames = ();
$areanames{en}->{44113} = "Leeds";
$areanames{en}->{44114} = "Sheffield";
$areanames{en}->{44115} = "Nottingham";
$areanames{en}->{44116} = "Leicester";
$areanames{en}->{44117} = "Bristol";
$areanames{en}->{44118} = "Reading";
$areanames{en}->{441200} = "Clitheroe";
$areanames{en}->{441202} = "Bournemouth";
$areanames{en}->{441204} = "Bolton";
$areanames{en}->{441205} = "Boston";
$areanames{en}->{441206} = "Colchester";
$areanames{en}->{441207} = "Consett";
$areanames{en}->{441208} = "Bodmin";
$areanames{en}->{441209} = "Redruth";
$areanames{en}->{44121} = "Birmingham";
$areanames{en}->{441223} = "Cambridge";
$areanames{en}->{441224} = "Aberdeen";
$areanames{en}->{441225} = "Bath";
$areanames{en}->{441226} = "Barnsley";
$areanames{en}->{441227} = "Canterbury";
$areanames{en}->{441228} = "Carlisle";
$areanames{en}->{4412290} = "Barrow\-in\-Furness\/Millom";
$areanames{en}->{4412291} = "Barrow\-in\-Furness\/Millom";
$areanames{en}->{4412292} = "Barrow\-in\-Furness";
$areanames{en}->{4412293} = "Millom";
$areanames{en}->{4412294} = "Barrow\-in\-Furness";
$areanames{en}->{4412295} = "Barrow\-in\-Furness";
$areanames{en}->{4412296} = "Barrow\-in\-Furness";
$areanames{en}->{4412297} = "Millom";
$areanames{en}->{4412298} = "Barrow\-in\-Furness";
$areanames{en}->{4412299} = "Millom";
$areanames{en}->{441233} = "Ashford\ \(Kent\)";
$areanames{en}->{441234} = "Bedford";
$areanames{en}->{441235} = "Abingdon";
$areanames{en}->{441236} = "Coatbridge";
$areanames{en}->{441237} = "Bideford";
$areanames{en}->{441239} = "Cardigan";
$areanames{en}->{441241} = "Arbroath";
$areanames{en}->{441242} = "Cheltenham";
$areanames{en}->{441243} = "Chichester";
$areanames{en}->{441244} = "Chester";
$areanames{en}->{441245} = "Chelmsford";
$areanames{en}->{441246} = "Chesterfield";
$areanames{en}->{441248} = "Bangor\ \(Gwynedd\)";
$areanames{en}->{441249} = "Chippenham";
$areanames{en}->{441250} = "Blairgowrie";
$areanames{en}->{441252} = "Aldershot";
$areanames{en}->{441253} = "Blackpool";
$areanames{en}->{441254} = "Blackburn";
$areanames{en}->{441255} = "Clacton\-on\-Sea";
$areanames{en}->{441256} = "Basingstoke";
$areanames{en}->{441257} = "Coppull";
$areanames{en}->{441258} = "Blandford";
$areanames{en}->{441259} = "Alloa";
$areanames{en}->{441260} = "Congleton";
$areanames{en}->{441261} = "Banff";
$areanames{en}->{441262} = "Bridlington";
$areanames{en}->{441263} = "Cromer";
$areanames{en}->{441264} = "Andover";
$areanames{en}->{441267} = "Carmarthen";
$areanames{en}->{441268} = "Basildon";
$areanames{en}->{441269} = "Ammanford";
$areanames{en}->{441270} = "Crewe";
$areanames{en}->{441271} = "Barnstaple";
$areanames{en}->{441273} = "Brighton";
$areanames{en}->{441274} = "Bradford";
$areanames{en}->{441275} = "Clevedon";
$areanames{en}->{441276} = "Camberley";
$areanames{en}->{441277} = "Brentwood";
$areanames{en}->{441278} = "Bridgwater";
$areanames{en}->{441279} = "Bishops\ Stortford";
$areanames{en}->{441280} = "Buckingham";
$areanames{en}->{441282} = "Burnley";
$areanames{en}->{441283} = "Burton\-on\-Trent";
$areanames{en}->{441284} = "Bury\ St\ Edmunds";
$areanames{en}->{441285} = "Cirencester";
$areanames{en}->{441286} = "Caernarfon";
$areanames{en}->{441287} = "Guisborough";
$areanames{en}->{441288} = "Bude";
$areanames{en}->{441289} = "Berwick\-upon\-Tweed";
$areanames{en}->{441290} = "Cumnock";
$areanames{en}->{441291} = "Chepstow";
$areanames{en}->{441292} = "Ayr";
$areanames{en}->{441293} = "Crawley";
$areanames{en}->{441294} = "Ardrossan";
$areanames{en}->{441295} = "Banbury";
$areanames{en}->{441296} = "Aylesbury";
$areanames{en}->{441297} = "Axminster";
$areanames{en}->{441298} = "Buxton";
$areanames{en}->{441299} = "Bewdley";
$areanames{en}->{441300} = "Cerne\ Abbas";
$areanames{en}->{441301} = "Arrochar";
$areanames{en}->{441302} = "Doncaster";
$areanames{en}->{441303} = "Folkestone";
$areanames{en}->{441304} = "Dover";
$areanames{en}->{441305} = "Dorchester";
$areanames{en}->{441306} = "Dorking";
$areanames{en}->{441307} = "Forfar";
$areanames{en}->{441308} = "Bridport";
$areanames{en}->{441309} = "Forres";
$areanames{en}->{44131} = "Edinburgh";
$areanames{en}->{441320} = "Fort\ Augustus";
$areanames{en}->{441322} = "Dartford";
$areanames{en}->{441323} = "Eastbourne";
$areanames{en}->{441324} = "Falkirk";
$areanames{en}->{441325} = "Darlington";
$areanames{en}->{441326} = "Falmouth";
$areanames{en}->{441327} = "Daventry";
$areanames{en}->{441328} = "Fakenham";
$areanames{en}->{441329} = "Fareham";
$areanames{en}->{441330} = "Banchory";
$areanames{en}->{441332} = "Derby";
$areanames{en}->{441333} = "Peat\ Inn\ \(Leven\ \(Fife\)\)";
$areanames{en}->{441334} = "St\ Andrews";
$areanames{en}->{441335} = "Ashbourne";
$areanames{en}->{441337} = "Ladybank";
$areanames{en}->{4413390} = "Aboyne\/Ballater";
$areanames{en}->{4413391} = "Aboyne\/Ballater";
$areanames{en}->{4413392} = "Aboyne";
$areanames{en}->{4413393} = "Aboyne";
$areanames{en}->{4413394} = "Ballater";
$areanames{en}->{4413395} = "Aboyne";
$areanames{en}->{4413396} = "Ballater";
$areanames{en}->{4413397} = "Ballater";
$areanames{en}->{4413398} = "Aboyne";
$areanames{en}->{4413399} = "Ballater";
$areanames{en}->{441340} = "Craigellachie\ \(Aberlour\)";
$areanames{en}->{441341} = "Barmouth";
$areanames{en}->{441342} = "East\ Grinstead";
$areanames{en}->{441343} = "Elgin";
$areanames{en}->{441344} = "Bracknell";
$areanames{en}->{441346} = "Fraserburgh";
$areanames{en}->{441347} = "Easingwold";
$areanames{en}->{441348} = "Fishguard";
$areanames{en}->{441349} = "Dingwall";
$areanames{en}->{441350} = "Dunkeld";
$areanames{en}->{441352} = "Mold";
$areanames{en}->{441353} = "Ely";
$areanames{en}->{441354} = "Chatteris";
$areanames{en}->{441355} = "East\ Kilbride";
$areanames{en}->{441356} = "Brechin";
$areanames{en}->{441357} = "Strathaven";
$areanames{en}->{441358} = "Ellon";
$areanames{en}->{441359} = "Pakenham";
$areanames{en}->{441360} = "Killearn";
$areanames{en}->{441361} = "Duns";
$areanames{en}->{441362} = "Dereham";
$areanames{en}->{441363} = "Crediton";
$areanames{en}->{441364} = "Ashburton";
$areanames{en}->{441366} = "Downham\ Market";
$areanames{en}->{441367} = "Faringdon";
$areanames{en}->{441368} = "Dunbar";
$areanames{en}->{441369} = "Dunoon";
$areanames{en}->{441371} = "Great\ Dunmow";
$areanames{en}->{441372} = "Esher";
$areanames{en}->{441373} = "Frome";
$areanames{en}->{441375} = "Grays\ Thurrock";
$areanames{en}->{441376} = "Braintree";
$areanames{en}->{441377} = "Driffield";
$areanames{en}->{441379} = "Diss";
$areanames{en}->{441380} = "Devizes";
$areanames{en}->{441381} = "Fortrose";
$areanames{en}->{441382} = "Dundee";
$areanames{en}->{441383} = "Dunfermline";
$areanames{en}->{441384} = "Dudley";
$areanames{en}->{441386} = "Evesham";
$areanames{en}->{441387} = "Dumfries";
$areanames{en}->{4413873} = "Langholm";
$areanames{en}->{441388} = "Bishop\ Auckland";
$areanames{en}->{4413880} = "Bishop\ Auckland\/Stanhope\ \(Eastgate\)";
$areanames{en}->{4413881} = "Bishop\ Auckland\/Stanhope\ \(Eastgate\)";
$areanames{en}->{4413882} = "Stanhope\ \(Eastgate\)";
$areanames{en}->{4413885} = "Stanhope\ \(Eastgate\)";
$areanames{en}->{441389} = "Dumbarton";
$areanames{en}->{441392} = "Exeter";
$areanames{en}->{441394} = "Felixstowe";
$areanames{en}->{441395} = "Budleigh\ Salterton";
$areanames{en}->{441397} = "Fort\ William";
$areanames{en}->{441398} = "Dulverton";
$areanames{en}->{441400} = "Honington";
$areanames{en}->{441403} = "Horsham";
$areanames{en}->{441404} = "Honiton";
$areanames{en}->{441405} = "Goole";
$areanames{en}->{441406} = "Holbeach";
$areanames{en}->{441407} = "Holyhead";
$areanames{en}->{441408} = "Golspie";
$areanames{en}->{441409} = "Holsworthy";
$areanames{en}->{44141} = "Glasgow";
$areanames{en}->{441420} = "Alton";
$areanames{en}->{441422} = "Halifax";
$areanames{en}->{4414230} = "Harrogate\/Boroughbridge";
$areanames{en}->{4414231} = "Harrogate\/Boroughbridge";
$areanames{en}->{4414232} = "Harrogate";
$areanames{en}->{4414233} = "Boroughbridge";
$areanames{en}->{4414234} = "Boroughbridge";
$areanames{en}->{4414235} = "Harrogate";
$areanames{en}->{4414236} = "Harrogate";
$areanames{en}->{4414237} = "Harrogate";
$areanames{en}->{4414238} = "Harrogate";
$areanames{en}->{4414239} = "Boroughbridge";
$areanames{en}->{441424} = "Hastings";
$areanames{en}->{441425} = "Ringwood";
$areanames{en}->{441427} = "Gainsborough";
$areanames{en}->{441428} = "Haslemere";
$areanames{en}->{441429} = "Hartlepool";
$areanames{en}->{4414300} = "North\ Cave\/Market\ Weighton";
$areanames{en}->{4414301} = "North\ Cave\/Market\ Weighton";
$areanames{en}->{4414302} = "North\ Cave";
$areanames{en}->{4414303} = "North\ Cave";
$areanames{en}->{4414304} = "North\ Cave";
$areanames{en}->{4414305} = "North\ Cave";
$areanames{en}->{4414306} = "Market\ Weighton";
$areanames{en}->{4414307} = "Market\ Weighton";
$areanames{en}->{4414308} = "Market\ Weighton";
$areanames{en}->{4414309} = "Market\ Weighton";
$areanames{en}->{441431} = "Helmsdale";
$areanames{en}->{441432} = "Hereford";
$areanames{en}->{441433} = "Hathersage";
$areanames{en}->{4414340} = "Bellingham\/Haltwhistle\/Hexham";
$areanames{en}->{4414341} = "Bellingham\/Haltwhistle\/Hexham";
$areanames{en}->{4414342} = "Bellingham";
$areanames{en}->{4414343} = "Haltwhistle";
$areanames{en}->{4414344} = "Bellingham";
$areanames{en}->{4414345} = "Haltwhistle";
$areanames{en}->{4414346} = "Hexham";
$areanames{en}->{4414347} = "Hexham";
$areanames{en}->{4414348} = "Hexham";
$areanames{en}->{4414349} = "Bellingham";
$areanames{en}->{441435} = "Heathfield";
$areanames{en}->{441436} = "Helensburgh";
$areanames{en}->{4414370} = "Haverfordwest\/Clynderwen\ \(Clunderwen\)";
$areanames{en}->{4414371} = "Haverfordwest\/Clynderwen\ \(Clunderwen\)";
$areanames{en}->{4414372} = "Clynderwen\ \(Clunderwen\)";
$areanames{en}->{4414373} = "Clynderwen\ \(Clunderwen\)";
$areanames{en}->{4414374} = "Clynderwen\ \(Clunderwen\)";
$areanames{en}->{4414375} = "Clynderwen\ \(Clunderwen\)";
$areanames{en}->{4414376} = "Haverfordwest";
$areanames{en}->{4414377} = "Haverfordwest";
$areanames{en}->{4414378} = "Haverfordwest";
$areanames{en}->{4414379} = "Haverfordwest";
$areanames{en}->{441438} = "Stevenage";
$areanames{en}->{441439} = "Helmsley";
$areanames{en}->{441440} = "Haverhill";
$areanames{en}->{441442} = "Hemel\ Hempstead";
$areanames{en}->{441443} = "Pontypridd";
$areanames{en}->{441444} = "Haywards\ Heath";
$areanames{en}->{441445} = "Gairloch";
$areanames{en}->{441446} = "Barry";
$areanames{en}->{441449} = "Stowmarket";
$areanames{en}->{441450} = "Hawick";
$areanames{en}->{441451} = "Stow\-on\-the\-Wold";
$areanames{en}->{441452} = "Gloucester";
$areanames{en}->{441453} = "Dursley";
$areanames{en}->{441454} = "Chipping\ Sodbury";
$areanames{en}->{441455} = "Hinckley";
$areanames{en}->{441456} = "Glenurquhart";
$areanames{en}->{441457} = "Glossop";
$areanames{en}->{441458} = "Glastonbury";
$areanames{en}->{441460} = "Chard";
$areanames{en}->{441461} = "Gretna";
$areanames{en}->{441462} = "Hitchin";
$areanames{en}->{441463} = "Inverness";
$areanames{en}->{441464} = "Insch";
$areanames{en}->{441465} = "Girvan";
$areanames{en}->{441466} = "Huntly";
$areanames{en}->{441467} = "Inverurie";
$areanames{en}->{441469} = "Killingholme";
$areanames{en}->{441470} = "Isle\ of\ Skye\ \-\ Edinbane";
$areanames{en}->{441471} = "Isle\ of\ Skye\ \-\ Broadford";
$areanames{en}->{441472} = "Grimsby";
$areanames{en}->{441473} = "Ipswich";
$areanames{en}->{441474} = "Gravesend";
$areanames{en}->{441475} = "Greenock";
$areanames{en}->{441476} = "Grantham";
$areanames{en}->{441477} = "Holmes\ Chapel";
$areanames{en}->{441478} = "Isle\ of\ Skye\ \-\ Portree";
$areanames{en}->{441479} = "Grantown\-on\-Spey";
$areanames{en}->{44147981} = "Aviemore";
$areanames{en}->{44147982} = "Nethy\ Bridge";
$areanames{en}->{44147983} = "Boat\ of\ Garten";
$areanames{en}->{44147984} = "Carrbridge";
$areanames{en}->{44147985} = "Dulnain\ Bridge";
$areanames{en}->{44147986} = "Cairngorm";
$areanames{en}->{441480} = "Huntingdon";
$areanames{en}->{441481} = "Guernsey";
$areanames{en}->{441482} = "Kingston\-upon\-Hull";
$areanames{en}->{441483} = "Guildford";
$areanames{en}->{441484} = "Huddersfield";
$areanames{en}->{441485} = "Hunstanton";
$areanames{en}->{441487} = "Warboys";
$areanames{en}->{441488} = "Hungerford";
$areanames{en}->{441489} = "Bishops\ Waltham";
$areanames{en}->{441490} = "Corwen";
$areanames{en}->{441491} = "Henley\-on\-Thames";
$areanames{en}->{441492} = "Colwyn\ Bay";
$areanames{en}->{441493} = "Great\ Yarmouth";
$areanames{en}->{441494} = "High\ Wycombe";
$areanames{en}->{441495} = "Pontypool";
$areanames{en}->{441496} = "Port\ Ellen";
$areanames{en}->{441497} = "Hay\-on\-Wye";
$areanames{en}->{441499} = "Inveraray";
$areanames{en}->{441501} = "Harthill";
$areanames{en}->{441502} = "Lowestoft";
$areanames{en}->{441503} = "Looe";
$areanames{en}->{441505} = "Johnstone";
$areanames{en}->{441506} = "Bathgate";
$areanames{en}->{4415070} = "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)";
$areanames{en}->{4415071} = "Louth\/Alford\ \(Lincs\)\/Spilsby\ \(Horncastle\)";
$areanames{en}->{4415072} = "Spilsby\ \(Horncastle\)";
$areanames{en}->{4415073} = "Louth";
$areanames{en}->{4415074} = "Alford\ \(Lincs\)";
$areanames{en}->{4415075} = "Spilsby\ \(Horncastle\)";
$areanames{en}->{4415076} = "Louth";
$areanames{en}->{4415077} = "Louth";
$areanames{en}->{4415078} = "Alford\ \(Lincs\)";
$areanames{en}->{4415079} = "Alford\ \(Lincs\)";
$areanames{en}->{441508} = "Brooke";
$areanames{en}->{441509} = "Loughborough";
$areanames{en}->{44151} = "Liverpool";
$areanames{en}->{441520} = "Lochcarron";
$areanames{en}->{441522} = "Lincoln";
$areanames{en}->{441524} = "Lancaster";
$areanames{en}->{4415242} = "Hornby";
$areanames{en}->{441525} = "Leighton\ Buzzard";
$areanames{en}->{441526} = "Martin";
$areanames{en}->{441527} = "Redditch";
$areanames{en}->{441528} = "Laggan";
$areanames{en}->{441529} = "Sleaford";
$areanames{en}->{441530} = "Coalville";
$areanames{en}->{441531} = "Ledbury";
$areanames{en}->{441534} = "Jersey";
$areanames{en}->{441535} = "Keighley";
$areanames{en}->{441536} = "Kettering";
$areanames{en}->{441538} = "Ipstones";
$areanames{en}->{441539} = "Kendal";
$areanames{en}->{4415394} = "Hawkshead";
$areanames{en}->{4415395} = "Grange\-over\-Sands";
$areanames{en}->{4415396} = "Sedbergh";
$areanames{en}->{441540} = "Kingussie";
$areanames{en}->{441542} = "Keith";
$areanames{en}->{441543} = "Cannock";
$areanames{en}->{441544} = "Kington";
$areanames{en}->{441545} = "Llanarth";
$areanames{en}->{441546} = "Lochgilphead";
$areanames{en}->{441547} = "Knighton";
$areanames{en}->{441548} = "Kingsbridge";
$areanames{en}->{441549} = "Lairg";
$areanames{en}->{441550} = "Llandovery";
$areanames{en}->{441553} = "Kings\ Lynn";
$areanames{en}->{441554} = "Llanelli";
$areanames{en}->{441555} = "Lanark";
$areanames{en}->{441556} = "Castle\ Douglas";
$areanames{en}->{441557} = "Kirkcudbright";
$areanames{en}->{441558} = "Llandeilo";
$areanames{en}->{441559} = "Llandysul";
$areanames{en}->{441560} = "Moscow";
$areanames{en}->{441561} = "Laurencekirk";
$areanames{en}->{441562} = "Kidderminster";
$areanames{en}->{441563} = "Kilmarnock";
$areanames{en}->{441564} = "Lapworth";
$areanames{en}->{441565} = "Knutsford";
$areanames{en}->{441566} = "Launceston";
$areanames{en}->{441567} = "Killin";
$areanames{en}->{441568} = "Leominster";
$areanames{en}->{441569} = "Stonehaven";
$areanames{en}->{441570} = "Lampeter";
$areanames{en}->{441571} = "Lochinver";
$areanames{en}->{441572} = "Oakham";
$areanames{en}->{441573} = "Kelso";
$areanames{en}->{441575} = "Kirriemuir";
$areanames{en}->{441576} = "Lockerbie";
$areanames{en}->{441577} = "Kinross";
$areanames{en}->{441578} = "Lauder";
$areanames{en}->{441579} = "Liskeard";
$areanames{en}->{441580} = "Cranbrook";
$areanames{en}->{441581} = "New\ Luce";
$areanames{en}->{441582} = "Luton";
$areanames{en}->{441583} = "Carradale";
$areanames{en}->{441584} = "Ludlow";
$areanames{en}->{441586} = "Campbeltown";
$areanames{en}->{441588} = "Bishops\ Castle";
$areanames{en}->{441590} = "Lymington";
$areanames{en}->{441591} = "Llanwrtyd\ Wells";
$areanames{en}->{441592} = "Kirkcaldy";
$areanames{en}->{441593} = "Lybster";
$areanames{en}->{441594} = "Lydney";
$areanames{en}->{441595} = "Lerwick\,\ Foula\ \&\ Fair\ Isle";
$areanames{en}->{441597} = "Llandrindod\ Wells";
$areanames{en}->{441598} = "Lynton";
$areanames{en}->{441599} = "Kyle";
$areanames{en}->{441600} = "Monmouth";
$areanames{en}->{441603} = "Norwich";
$areanames{en}->{441604} = "Northampton";
$areanames{en}->{441606} = "Northwich";
$areanames{en}->{441608} = "Chipping\ Norton";
$areanames{en}->{441609} = "Northallerton";
$areanames{en}->{44161} = "Manchester";
$areanames{en}->{441620} = "North\ Berwick";
$areanames{en}->{441621} = "Maldon";
$areanames{en}->{441622} = "Maidstone";
$areanames{en}->{441623} = "Mansfield";
$areanames{en}->{441624} = "Isle\ of\ Man";
$areanames{en}->{441625} = "Macclesfield";
$areanames{en}->{441626} = "Newton\ Abbot";
$areanames{en}->{441628} = "Maidenhead";
$areanames{en}->{441629} = "Matlock";
$areanames{en}->{441630} = "Market\ Drayton";
$areanames{en}->{441631} = "Oban";
$areanames{en}->{441633} = "Newport";
$areanames{en}->{441634} = "Medway";
$areanames{en}->{441635} = "Newbury";
$areanames{en}->{441636} = "Newark\-on\-Trent";
$areanames{en}->{441637} = "Newquay";
$areanames{en}->{441638} = "Newmarket";
$areanames{en}->{441639} = "Neath";
$areanames{en}->{441641} = "Strathy";
$areanames{en}->{441642} = "Middlesbrough";
$areanames{en}->{441643} = "Minehead";
$areanames{en}->{441644} = "New\ Galloway";
$areanames{en}->{441646} = "Milford\ Haven";
$areanames{en}->{441647} = "Moretonhampstead";
$areanames{en}->{441650} = "Cemmaes\ Road";
$areanames{en}->{441651} = "Oldmeldrum";
$areanames{en}->{441652} = "Brigg";
$areanames{en}->{441653} = "Malton";
$areanames{en}->{441654} = "Machynlleth";
$areanames{en}->{441655} = "Maybole";
$areanames{en}->{441656} = "Bridgend";
$areanames{en}->{441659} = "Sanquhar";
$areanames{en}->{441661} = "Prudhoe";
$areanames{en}->{441663} = "New\ Mills";
$areanames{en}->{441664} = "Melton\ Mowbray";
$areanames{en}->{441665} = "Alnwick";
$areanames{en}->{441666} = "Malmesbury";
$areanames{en}->{441667} = "Nairn";
$areanames{en}->{441668} = "Bamburgh";
$areanames{en}->{441669} = "Rothbury";
$areanames{en}->{441670} = "Morpeth";
$areanames{en}->{441671} = "Newton\ Stewart";
$areanames{en}->{441672} = "Marlborough";
$areanames{en}->{441673} = "Market\ Rasen";
$areanames{en}->{441674} = "Montrose";
$areanames{en}->{441675} = "Coleshill";
$areanames{en}->{441676} = "Meriden";
$areanames{en}->{441677} = "Bedale";
$areanames{en}->{441678} = "Bala";
$areanames{en}->{441680} = "Isle\ of\ Mull\ \-\ Craignure";
$areanames{en}->{441681} = "Isle\ of\ Mull\ \-\ Fionnphort";
$areanames{en}->{441683} = "Moffat";
$areanames{en}->{441684} = "Malvern";
$areanames{en}->{441685} = "Merthyr\ Tydfil";
$areanames{en}->{4416860} = "Newtown\/Llanidloes";
$areanames{en}->{4416861} = "Newtown\/Llanidloes";
$areanames{en}->{4416862} = "Llanidloes";
$areanames{en}->{4416863} = "Llanidloes";
$areanames{en}->{4416864} = "Llanidloes";
$areanames{en}->{4416865} = "Newtown";
$areanames{en}->{4416866} = "Newtown";
$areanames{en}->{4416867} = "Llanidloes";
$areanames{en}->{4416868} = "Newtown";
$areanames{en}->{4416869} = "Newtown";
$areanames{en}->{441687} = "Mallaig";
$areanames{en}->{441688} = "Isle\ of\ Mull\ \-\ Tobermory";
$areanames{en}->{441689} = "Orpington";
$areanames{en}->{441690} = "Betws\-y\-Coed";
$areanames{en}->{441691} = "Oswestry";
$areanames{en}->{441692} = "North\ Walsham";
$areanames{en}->{441694} = "Church\ Stretton";
$areanames{en}->{441695} = "Skelmersdale";
$areanames{en}->{441697} = "Brampton";
$areanames{en}->{4416973} = "Wigton";
$areanames{en}->{4416974} = "Raughton\ Head";
$areanames{en}->{441698} = "Motherwell";
$areanames{en}->{441700} = "Rothesay";
$areanames{en}->{441702} = "Southend\-on\-Sea";
$areanames{en}->{441704} = "Southport";
$areanames{en}->{441706} = "Rochdale";
$areanames{en}->{441707} = "Welwyn\ Garden\ City";
$areanames{en}->{441708} = "Romford";
$areanames{en}->{441709} = "Rotherham";
$areanames{en}->{441720} = "Isles\ of\ Scilly";
$areanames{en}->{441721} = "Peebles";
$areanames{en}->{441722} = "Salisbury";
$areanames{en}->{441723} = "Scarborough";
$areanames{en}->{441724} = "Scunthorpe";
$areanames{en}->{441725} = "Rockbourne";
$areanames{en}->{441726} = "St\ Austell";
$areanames{en}->{441727} = "St\ Albans";
$areanames{en}->{441728} = "Saxmundham";
$areanames{en}->{441729} = "Settle";
$areanames{en}->{441730} = "Petersfield";
$areanames{en}->{441732} = "Sevenoaks";
$areanames{en}->{441733} = "Peterborough";
$areanames{en}->{441736} = "Penzance";
$areanames{en}->{441737} = "Redhill";
$areanames{en}->{441738} = "Perth";
$areanames{en}->{441740} = "Sedgefield";
$areanames{en}->{441743} = "Shrewsbury";
$areanames{en}->{441744} = "St\ Helens";
$areanames{en}->{441745} = "Rhyl";
$areanames{en}->{441746} = "Bridgnorth";
$areanames{en}->{441747} = "Shaftesbury";
$areanames{en}->{441748} = "Richmond";
$areanames{en}->{441749} = "Shepton\ Mallet";
$areanames{en}->{441750} = "Selkirk";
$areanames{en}->{441751} = "Pickering";
$areanames{en}->{441752} = "Plymouth";
$areanames{en}->{441753} = "Slough";
$areanames{en}->{441754} = "Skegness";
$areanames{en}->{441756} = "Skipton";
$areanames{en}->{441757} = "Selby";
$areanames{en}->{441758} = "Pwllheli";
$areanames{en}->{441759} = "Pocklington";
$areanames{en}->{441760} = "Swaffham";
$areanames{en}->{441761} = "Temple\ Cloud";
$areanames{en}->{441763} = "Royston";
$areanames{en}->{441764} = "Crieff";
$areanames{en}->{441765} = "Ripon";
$areanames{en}->{441766} = "Porthmadog";
$areanames{en}->{441767} = "Sandy";
$areanames{en}->{441768} = "Penrith";
$areanames{en}->{4417683} = "Appleby";
$areanames{en}->{4417684} = "Pooley\ Bridge";
$areanames{en}->{4417687} = "Keswick";
$areanames{en}->{441769} = "South\ Molton";
$areanames{en}->{441770} = "Isle\ of\ Arran";
$areanames{en}->{441771} = "Maud";
$areanames{en}->{441772} = "Preston";
$areanames{en}->{441773} = "Ripley";
$areanames{en}->{441775} = "Spalding";
$areanames{en}->{441776} = "Stranraer";
$areanames{en}->{441777} = "Retford";
$areanames{en}->{441778} = "Bourne";
$areanames{en}->{441779} = "Peterhead";
$areanames{en}->{441780} = "Stamford";
$areanames{en}->{441782} = "Stoke\-on\-Trent";
$areanames{en}->{441784} = "Staines";
$areanames{en}->{441785} = "Stafford";
$areanames{en}->{441786} = "Stirling";
$areanames{en}->{441787} = "Sudbury";
$areanames{en}->{441788} = "Rugby";
$areanames{en}->{441789} = "Stratford\-upon\-Avon";
$areanames{en}->{441790} = "Spilsby";
$areanames{en}->{441792} = "Swansea";
$areanames{en}->{441793} = "Swindon";
$areanames{en}->{441794} = "Romsey";
$areanames{en}->{441795} = "Sittingbourne";
$areanames{en}->{441796} = "Pitlochry";
$areanames{en}->{441797} = "Rye";
$areanames{en}->{441798} = "Pulborough";
$areanames{en}->{441799} = "Saffron\ Walden";
$areanames{en}->{441803} = "Torquay";
$areanames{en}->{441805} = "Torrington";
$areanames{en}->{441806} = "Shetland";
$areanames{en}->{441807} = "Ballindalloch";
$areanames{en}->{441808} = "Tomatin";
$areanames{en}->{441809} = "Tomdoun";
$areanames{en}->{441821} = "Kinrossie";
$areanames{en}->{441822} = "Tavistock";
$areanames{en}->{441823} = "Taunton";
$areanames{en}->{441824} = "Ruthin";
$areanames{en}->{441825} = "Uckfield";
$areanames{en}->{441827} = "Tamworth";
$areanames{en}->{441828} = "Coupar\ Angus";
$areanames{en}->{441829} = "Tarporley";
$areanames{en}->{441830} = "Kirkwhelpington";
$areanames{en}->{441832} = "Clopton";
$areanames{en}->{441833} = "Barnard\ Castle";
$areanames{en}->{441834} = "Narberth";
$areanames{en}->{441835} = "St\ Boswells";
$areanames{en}->{441837} = "Okehampton";
$areanames{en}->{441838} = "Dalmally";
$areanames{en}->{441840} = "Camelford";
$areanames{en}->{441841} = "Newquay\ \(Padstow\)";
$areanames{en}->{441842} = "Thetford";
$areanames{en}->{441843} = "Thanet";
$areanames{en}->{441844} = "Thame";
$areanames{en}->{441845} = "Thirsk";
$areanames{en}->{4418470} = "Thurso\/Tongue";
$areanames{en}->{4418471} = "Thurso\/Tongue";
$areanames{en}->{4418472} = "Thurso";
$areanames{en}->{4418473} = "Thurso";
$areanames{en}->{4418474} = "Thurso";
$areanames{en}->{4418475} = "Thurso";
$areanames{en}->{4418476} = "Tongue";
$areanames{en}->{4418477} = "Tongue";
$areanames{en}->{4418478} = "Thurso";
$areanames{en}->{4418479} = "Tongue";
$areanames{en}->{441848} = "Thornhill";
$areanames{en}->{4418510} = "Great\ Bernera\/Stornoway";
$areanames{en}->{4418511} = "Great\ Bernera\/Stornoway";
$areanames{en}->{4418512} = "Stornoway";
$areanames{en}->{4418513} = "Stornoway";
$areanames{en}->{4418514} = "Great\ Bernera";
$areanames{en}->{4418515} = "Stornoway";
$areanames{en}->{4418516} = "Great\ Bernera";
$areanames{en}->{4418517} = "Stornoway";
$areanames{en}->{4418518} = "Stornoway";
$areanames{en}->{4418519} = "Great\ Bernera";
$areanames{en}->{441852} = "Kilmelford";
$areanames{en}->{441854} = "Ullapool";
$areanames{en}->{441855} = "Ballachulish";
$areanames{en}->{441856} = "Orkney";
$areanames{en}->{441857} = "Sanday";
$areanames{en}->{441858} = "Market\ Harborough";
$areanames{en}->{441859} = "Harris";
$areanames{en}->{441862} = "Tain";
$areanames{en}->{441863} = "Ardgay";
$areanames{en}->{441864} = "Abington\ \(Crawford\)";
$areanames{en}->{441865} = "Oxford";
$areanames{en}->{441866} = "Kilchrenan";
$areanames{en}->{441869} = "Bicester";
$areanames{en}->{441870} = "Isle\ of\ Benbecula";
$areanames{en}->{441871} = "Castlebay";
$areanames{en}->{441872} = "Truro";
$areanames{en}->{441873} = "Abergavenny";
$areanames{en}->{441874} = "Brecon";
$areanames{en}->{441875} = "Tranent";
$areanames{en}->{441876} = "Lochmaddy";
$areanames{en}->{441877} = "Callander";
$areanames{en}->{441878} = "Lochboisdale";
$areanames{en}->{441879} = "Scarinish";
$areanames{en}->{441880} = "Tarbert";
$areanames{en}->{441882} = "Kinloch\ Rannoch";
$areanames{en}->{441883} = "Caterham";
$areanames{en}->{441884} = "Tiverton";
$areanames{en}->{441885} = "Pencombe";
$areanames{en}->{441886} = "Bromyard\ \(Knightwick\/Leigh\ Sinton\)";
$areanames{en}->{441887} = "Aberfeldy";
$areanames{en}->{441888} = "Turriff";
$areanames{en}->{441889} = "Rugeley";
$areanames{en}->{4418900} = "Coldstream\/Ayton";
$areanames{en}->{4418901} = "Coldstream\/Ayton";
$areanames{en}->{4418902} = "Coldstream";
$areanames{en}->{4418903} = "Coldstream";
$areanames{en}->{4418904} = "Coldstream";
$areanames{en}->{4418905} = "Ayton";
$areanames{en}->{4418906} = "Ayton";
$areanames{en}->{4418907} = "Ayton";
$areanames{en}->{4418908} = "Coldstream";
$areanames{en}->{4418909} = "Ayton";
$areanames{en}->{441892} = "Tunbridge\ Wells";
$areanames{en}->{441895} = "Uxbridge";
$areanames{en}->{441896} = "Galashiels";
$areanames{en}->{441899} = "Biggar";
$areanames{en}->{441900} = "Workington";
$areanames{en}->{441902} = "Wolverhampton";
$areanames{en}->{441903} = "Worthing";
$areanames{en}->{441904} = "York";
$areanames{en}->{441905} = "Worcester";
$areanames{en}->{441908} = "Milton\ Keynes";
$areanames{en}->{441909} = "Worksop";
$areanames{en}->{441910} = "Tyneside\/Durham\/Sunderland";
$areanames{en}->{441911} = "Tyneside\/Durham\/Sunderland";
$areanames{en}->{441912} = "Tyneside";
$areanames{en}->{441913} = "Durham";
$areanames{en}->{441914} = "Tyneside";
$areanames{en}->{441915} = "Sunderland";
$areanames{en}->{441916} = "Tyneside";
$areanames{en}->{441917} = "Sunderland";
$areanames{en}->{441918} = "Tyneside";
$areanames{en}->{441919} = "Durham";
$areanames{en}->{441920} = "Ware";
$areanames{en}->{441922} = "Walsall";
$areanames{en}->{441923} = "Watford";
$areanames{en}->{441924} = "Wakefield";
$areanames{en}->{441925} = "Warrington";
$areanames{en}->{441926} = "Warwick";
$areanames{en}->{441928} = "Runcorn";
$areanames{en}->{441929} = "Wareham";
$areanames{en}->{441931} = "Shap";
$areanames{en}->{441932} = "Weybridge";
$areanames{en}->{441933} = "Wellingborough";
$areanames{en}->{441934} = "Weston\-super\-Mare";
$areanames{en}->{441935} = "Yeovil";
$areanames{en}->{441937} = "Wetherby";
$areanames{en}->{441938} = "Welshpool";
$areanames{en}->{441939} = "Wem";
$areanames{en}->{441942} = "Wigan";
$areanames{en}->{441943} = "Guiseley";
$areanames{en}->{441944} = "West\ Heslerton";
$areanames{en}->{441945} = "Wisbech";
$areanames{en}->{441946} = "Whitehaven";
$areanames{en}->{4419467} = "Gosforth";
$areanames{en}->{441947} = "Whitby";
$areanames{en}->{441948} = "Whitchurch";
$areanames{en}->{441949} = "Whatton";
$areanames{en}->{441950} = "Sandwick";
$areanames{en}->{441951} = "Colonsay";
$areanames{en}->{441952} = "Telford";
$areanames{en}->{441953} = "Wymondham";
$areanames{en}->{441954} = "Madingley";
$areanames{en}->{441955} = "Wick";
$areanames{en}->{441957} = "Mid\ Yell";
$areanames{en}->{441959} = "Westerham";
$areanames{en}->{441962} = "Winchester";
$areanames{en}->{441963} = "Wincanton";
$areanames{en}->{4419640} = "Hornsea\/Patrington";
$areanames{en}->{4419641} = "Hornsea\/Patrington";
$areanames{en}->{4419642} = "Hornsea";
$areanames{en}->{4419643} = "Patrington";
$areanames{en}->{4419644} = "Patrington";
$areanames{en}->{4419645} = "Hornsea";
$areanames{en}->{4419646} = "Patrington";
$areanames{en}->{4419647} = "Patrington";
$areanames{en}->{4419648} = "Hornsea";
$areanames{en}->{4419649} = "Hornsea";
$areanames{en}->{441967} = "Strontian";
$areanames{en}->{441968} = "Penicuik";
$areanames{en}->{441969} = "Leyburn";
$areanames{en}->{441970} = "Aberystwyth";
$areanames{en}->{441971} = "Scourie";
$areanames{en}->{441972} = "Glenborrodale";
$areanames{en}->{441974} = "Llanon";
$areanames{en}->{4419750} = "Alford\ \(Aberdeen\)\/Strathdon";
$areanames{en}->{4419751} = "Alford\ \(Aberdeen\)\/Strathdon";
$areanames{en}->{4419752} = "Alford\ \(Aberdeen\)";
$areanames{en}->{4419753} = "Strathdon";
$areanames{en}->{4419754} = "Alford\ \(Aberdeen\)";
$areanames{en}->{4419755} = "Alford\ \(Aberdeen\)";
$areanames{en}->{4419756} = "Strathdon";
$areanames{en}->{4419757} = "Strathdon";
$areanames{en}->{4419758} = "Strathdon";
$areanames{en}->{4419759} = "Alford\ \(Aberdeen\)";
$areanames{en}->{441977} = "Pontefract";
$areanames{en}->{441978} = "Wrexham";
$areanames{en}->{441980} = "Amesbury";
$areanames{en}->{441981} = "Wormbridge";
$areanames{en}->{441982} = "Builth\ Wells";
$areanames{en}->{441983} = "Isle\ of\ Wight";
$areanames{en}->{441984} = "Watchet\ \(Williton\)";
$areanames{en}->{441985} = "Warminster";
$areanames{en}->{441986} = "Bungay";
$areanames{en}->{441987} = "Ebbsfleet";
$areanames{en}->{441988} = "Wigtown";
$areanames{en}->{441989} = "Ross\-on\-Wye";
$areanames{en}->{441992} = "Lea\ Valley";
$areanames{en}->{441993} = "Witney";
$areanames{en}->{441994} = "St\ Clears";
$areanames{en}->{441995} = "Garstang";
$areanames{en}->{441997} = "Strathpeffer";
$areanames{en}->{4420} = "London";
$areanames{en}->{442310} = "Portsmouth";
$areanames{en}->{442311} = "Southampton";
$areanames{en}->{44238} = "Southampton";
$areanames{en}->{44239} = "Portsmouth";
$areanames{en}->{44241} = "Coventry";
$areanames{en}->{44247} = "Coventry";
$areanames{en}->{44281} = "Northern\ Ireland";
$areanames{en}->{442820} = "Ballycastle";
$areanames{en}->{442821} = "Martinstown";
$areanames{en}->{442825} = "Ballymena";
$areanames{en}->{442827} = "Ballymoney";
$areanames{en}->{442828} = "Larne";
$areanames{en}->{442829} = "Kilrea";
$areanames{en}->{442830} = "Newry";
$areanames{en}->{442837} = "Armagh";
$areanames{en}->{442838} = "Portadown";
$areanames{en}->{442840} = "Banbridge";
$areanames{en}->{442841} = "Rostrevor";
$areanames{en}->{442842} = "Kircubbin";
$areanames{en}->{442843} = "Newcastle\ \(Co\.\ Down\)";
$areanames{en}->{442844} = "Downpatrick";
$areanames{en}->{442866} = "Enniskillen";
$areanames{en}->{442867} = "Lisnaskea";
$areanames{en}->{442868} = "Kesh";
$areanames{en}->{442870} = "Coleraine";
$areanames{en}->{442871} = "Londonderry";
$areanames{en}->{442877} = "Limavady";
$areanames{en}->{442879} = "Magherafelt";
$areanames{en}->{442880} = "Carrickmore";
$areanames{en}->{442881} = "Newtownstewart";
$areanames{en}->{442882} = "Omagh";
$areanames{en}->{442885} = "Ballygawley";
$areanames{en}->{442886} = "Cookstown";
$areanames{en}->{442887} = "Dungannon";
$areanames{en}->{442889} = "Fivemiletown";
$areanames{en}->{442890} = "Belfast";
$areanames{en}->{442891} = "Bangor\ \(Co\.\ Down\)";
$areanames{en}->{442892} = "Lisburn";
$areanames{en}->{442893} = "Ballyclare";
$areanames{en}->{442894} = "Antrim";
$areanames{en}->{442895} = "Belfast";
$areanames{en}->{442896} = "Belfast";
$areanames{en}->{442897} = "Saintfield";
$areanames{en}->{442898} = "Belfast";
$areanames{en}->{44291} = "Cardiff";
$areanames{en}->{44292} = "Cardiff";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+44|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      my $prefix = qr/^(?:0|([5-8]\d{5})$)/;
      my @matches = $number =~ /$prefix/;
      if (defined $matches[-1]) {
        no warnings 'uninitialized';
        $number =~ s/$prefix/1624$1/;
      }
      else {
        $number =~ s/$prefix//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;