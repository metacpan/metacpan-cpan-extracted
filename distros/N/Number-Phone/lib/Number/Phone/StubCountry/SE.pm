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
package Number::Phone::StubCountry::SE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200904144535;

my $formatters = [
                {
                  'format' => '$1-$2 $3',
                  'intl_format' => '$1 $2 $3',
                  'leading_digits' => '20',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2,3})(\\d{2})'
                },
                {
                  'format' => '$1-$2',
                  'intl_format' => '$1 $2',
                  'leading_digits' => '
            9(?:
              00|
              39|
              44
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1-$2 $3',
                  'intl_format' => '$1 $2 $3',
                  'leading_digits' => '
            [12][136]|
            3[356]|
            4[0246]|
            6[03]|
            90[1-9]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})'
                },
                {
                  'format' => '$1-$2 $3 $4',
                  'intl_format' => '$1 $2 $3 $4',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{2,3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1-$2 $3',
                  'intl_format' => '$1 $2 $3',
                  'leading_digits' => '
            1[2457]|
            2(?:
              [247-9]|
              5[0138]
            )|
            3[0247-9]|
            4[1357-9]|
            5[0-35-9]|
            6(?:
              [125689]|
              4[02-57]|
              7[0-2]
            )|
            9(?:
              [125-8]|
              3[02-5]|
              4[0-3]
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2,3})(\\d{2})'
                },
                {
                  'format' => '$1-$2 $3',
                  'intl_format' => '$1 $2 $3',
                  'leading_digits' => '
            9(?:
              00|
              39|
              44
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2,3})(\\d{3})'
                },
                {
                  'format' => '$1-$2 $3 $4',
                  'intl_format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            1[13689]|
            2[0136]|
            3[1356]|
            4[0246]|
            54|
            6[03]|
            90[1-9]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2,3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1-$2 $3 $4',
                  'intl_format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            10|
            7
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1-$2 $3 $4',
                  'intl_format' => '$1 $2 $3 $4',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3})(\\d{2})'
                },
                {
                  'format' => '$1-$2 $3 $4',
                  'intl_format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            [13-5]|
            2(?:
              [247-9]|
              5[0138]
            )|
            6(?:
              [124-689]|
              7[0-2]
            )|
            9(?:
              [125-8]|
              3[02-5]|
              4[0-3]
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1-$2 $3 $4',
                  'intl_format' => '$1 $2 $3 $4',
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1-$2 $3 $4 $5',
                  'intl_format' => '$1 $2 $3 $4 $5',
                  'leading_digits' => '[26]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            (?:
              [12][136]|
              3[356]|
              4[0246]|
              6[03]|
              8\\d
            )\\d|
            90[1-9]
          )\\d{4,6}|
          (?:
            1(?:
              2[0-35]|
              4[0-4]|
              5[0-25-9]|
              7[13-6]|
              [89]\\d
            )|
            2(?:
              2[0-7]|
              4[0136-8]|
              5[0138]|
              7[018]|
              8[01]|
              9[0-57]
            )|
            3(?:
              0[0-4]|
              1\\d|
              2[0-25]|
              4[056]|
              7[0-2]|
              8[0-3]|
              9[023]
            )|
            4(?:
              1[013-8]|
              3[0135]|
              5[14-79]|
              7[0-246-9]|
              8[0156]|
              9[0-689]
            )|
            5(?:
              0[0-6]|
              [15][0-5]|
              2[0-68]|
              3[0-4]|
              4\\d|
              6[03-5]|
              7[013]|
              8[0-79]|
              9[01]
            )|
            6(?:
              1[1-3]|
              2[0-4]|
              4[02-57]|
              5[0-37]|
              6[0-3]|
              7[0-2]|
              8[0247]|
              9[0-356]
            )|
            9(?:
              1[0-68]|
              2\\d|
              3[02-5]|
              4[0-3]|
              5[0-4]|
              [68][01]|
              7[0135-8]
            )
          )\\d{5,6}
        ',
                'geographic' => '
          (?:
            (?:
              [12][136]|
              3[356]|
              4[0246]|
              6[03]|
              8\\d
            )\\d|
            90[1-9]
          )\\d{4,6}|
          (?:
            1(?:
              2[0-35]|
              4[0-4]|
              5[0-25-9]|
              7[13-6]|
              [89]\\d
            )|
            2(?:
              2[0-7]|
              4[0136-8]|
              5[0138]|
              7[018]|
              8[01]|
              9[0-57]
            )|
            3(?:
              0[0-4]|
              1\\d|
              2[0-25]|
              4[056]|
              7[0-2]|
              8[0-3]|
              9[023]
            )|
            4(?:
              1[013-8]|
              3[0135]|
              5[14-79]|
              7[0-246-9]|
              8[0156]|
              9[0-689]
            )|
            5(?:
              0[0-6]|
              [15][0-5]|
              2[0-68]|
              3[0-4]|
              4\\d|
              6[03-5]|
              7[013]|
              8[0-79]|
              9[01]
            )|
            6(?:
              1[1-3]|
              2[0-4]|
              4[02-57]|
              5[0-37]|
              6[0-3]|
              7[0-2]|
              8[0247]|
              9[0-356]
            )|
            9(?:
              1[0-68]|
              2\\d|
              3[02-5]|
              4[0-3]|
              5[0-4]|
              [68][01]|
              7[0135-8]
            )
          )\\d{5,6}
        ',
                'mobile' => '7[02369]\\d{7}',
                'pager' => '74[02-9]\\d{6}',
                'personal_number' => '75[1-8]\\d{6}',
                'specialrate' => '(77[0-7]\\d{6})|(
          649\\d{6}|
          9(?:
            00|
            39|
            44
          )[1-8]\\d{3,6}
        )|(10[1-8]\\d{6})',
                'toll_free' => '20\\d{4,7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{4611} = "Norrköping";
$areanames{en}->{46120} = "Åtvidaberg";
$areanames{en}->{46121} = "Söderköping";
$areanames{en}->{46122} = "Finspång";
$areanames{en}->{46123} = "Valdemarsvik";
$areanames{en}->{46125} = "Vikbolandet";
$areanames{en}->{4613} = "Linköping";
$areanames{en}->{46140} = "Tranås";
$areanames{en}->{46141} = "Motala";
$areanames{en}->{46142} = "Mjölby\-Skänninge\-Boxholm";
$areanames{en}->{46143} = "Vadstena";
$areanames{en}->{46144} = "Ödeshög";
$areanames{en}->{46150} = "Katrineholm";
$areanames{en}->{46151} = "Vingåker";
$areanames{en}->{46152} = "Strängnäs";
$areanames{en}->{46155} = "Nyköping\-Oxelösund";
$areanames{en}->{46156} = "Trosa\-Vagnhärad";
$areanames{en}->{46157} = "Flen\-Malmköping";
$areanames{en}->{46158} = "Gnesta";
$areanames{en}->{46159} = "Mariefred";
$areanames{en}->{4616} = "Eskilstuna\-Torshälla";
$areanames{en}->{46171} = "Enköping";
$areanames{en}->{46173} = "Öregrund\-Östhammar";
$areanames{en}->{46174} = "Alunda";
$areanames{en}->{46175} = "Hallstavik\-Rimbo";
$areanames{en}->{46176} = "Norrtälje";
$areanames{en}->{4618} = "Uppsala";
$areanames{en}->{4619} = "Örebro\-Kumla";
$areanames{en}->{4621} = "Västerås";
$areanames{en}->{46220} = "Hallstahammar\-Surahammar";
$areanames{en}->{46221} = "Köping";
$areanames{en}->{46222} = "Skinnskatteberg";
$areanames{en}->{46223} = "Fagersta\-Norberg";
$areanames{en}->{46224} = "Sala\-Heby";
$areanames{en}->{46225} = "Hedemora\-Säter";
$areanames{en}->{46226} = "Avesta\-Krylbo";
$areanames{en}->{46227} = "Kungsör";
$areanames{en}->{4623} = "Falun";
$areanames{en}->{46240} = "Ludvika\-Smedjebacken";
$areanames{en}->{46241} = "Gagnef\-Floda";
$areanames{en}->{46243} = "Borlänge";
$areanames{en}->{46246} = "Svärdsjö\-Enviken";
$areanames{en}->{46247} = "Leksand\-Insjön";
$areanames{en}->{46248} = "Rättvik";
$areanames{en}->{46250} = "Mora\-Orsa";
$areanames{en}->{46251} = "Älvdalen";
$areanames{en}->{46253} = "Idre\-Särna";
$areanames{en}->{46258} = "Furudal";
$areanames{en}->{4626} = "Gävle\-Sandviken";
$areanames{en}->{46270} = "Söderhamn";
$areanames{en}->{46271} = "Alfta\-Edsbyn";
$areanames{en}->{46278} = "Bollnäs";
$areanames{en}->{46280} = "Malung";
$areanames{en}->{46281} = "Vansbro";
$areanames{en}->{46290} = "Hofors\-Storvik";
$areanames{en}->{46291} = "Hedesunda\-Österfärnebo";
$areanames{en}->{46292} = "Tärnsjö\-Östervåla";
$areanames{en}->{46293} = "Tierp\-Söderfors";
$areanames{en}->{46294} = "Karlholmsbruk\-Skärplinge";
$areanames{en}->{46295} = "Örbyhus\-Dannemora";
$areanames{en}->{46297} = "Ockelbo\-Hamrånge";
$areanames{en}->{46300} = "Kungsbacka";
$areanames{en}->{46301} = "Hindås";
$areanames{en}->{46302} = "Lerum";
$areanames{en}->{46303} = "Kungälv";
$areanames{en}->{46304} = "Orust\-Tjörn";
$areanames{en}->{4631} = "Gothenburg";
$areanames{en}->{46320} = "Kinna";
$areanames{en}->{46321} = "Ulricehamn";
$areanames{en}->{46322} = "Alingsås\-Vårgårda";
$areanames{en}->{46325} = "Svenljunga\-Tranemo";
$areanames{en}->{4633} = "Borås";
$areanames{en}->{46340} = "Varberg";
$areanames{en}->{46345} = "Hyltebruk\-Torup";
$areanames{en}->{46346} = "Falkenberg";
$areanames{en}->{4635} = "Halmstad";
$areanames{en}->{4636} = "Jönköping\-Huskvarna";
$areanames{en}->{46370} = "Värnamo";
$areanames{en}->{46371} = "Gislaved\-Anderstorp";
$areanames{en}->{46372} = "Ljungby";
$areanames{en}->{46380} = "Nässjö";
$areanames{en}->{46381} = "Eksjö";
$areanames{en}->{46382} = "Sävsjö";
$areanames{en}->{46383} = "Vetlanda";
$areanames{en}->{46390} = "Gränna";
$areanames{en}->{46392} = "Mullsjö";
$areanames{en}->{46393} = "Vaggeryd";
$areanames{en}->{4640} = "Malmö";
$areanames{en}->{46410} = "Trelleborg";
$areanames{en}->{46411} = "Ystad";
$areanames{en}->{46413} = "Eslöv\-Höör";
$areanames{en}->{46414} = "Simrishamn";
$areanames{en}->{46415} = "Hörby";
$areanames{en}->{46416} = "Sjöbo";
$areanames{en}->{46417} = "Tomelilla";
$areanames{en}->{46418} = "Landskrona\-Svalöv";
$areanames{en}->{4642} = "Helsingborg\-Höganäs";
$areanames{en}->{46430} = "Laholm";
$areanames{en}->{46431} = "Ängelholm\-Båstad";
$areanames{en}->{46433} = "Markaryd\-Strömsnäsbruk";
$areanames{en}->{46435} = "Klippan\-Perstorp";
$areanames{en}->{4644} = "Kristianstad";
$areanames{en}->{46451} = "Hässleholm";
$areanames{en}->{46454} = "Karlshamn\-Olofström";
$areanames{en}->{46455} = "Karlskrona";
$areanames{en}->{46456} = "Sölvesborg\-Bromölla";
$areanames{en}->{46457} = "Ronneby";
$areanames{en}->{46459} = "Ryd";
$areanames{en}->{4646} = "Lund";
$areanames{en}->{46470} = "Växjö";
$areanames{en}->{46471} = "Emmaboda";
$areanames{en}->{46472} = "Alvesta\-Rydaholm";
$areanames{en}->{46474} = "Åseda\-Lenhovda";
$areanames{en}->{46476} = "Älmhult";
$areanames{en}->{46477} = "Tingsryd";
$areanames{en}->{46478} = "Lessebo";
$areanames{en}->{46479} = "Osby";
$areanames{en}->{46480} = "Kalmar";
$areanames{en}->{46481} = "Nybro";
$areanames{en}->{46485} = "Öland";
$areanames{en}->{46486} = "Torsås";
$areanames{en}->{46490} = "Västervik";
$areanames{en}->{46491} = "Oskarshamn\-Högsby";
$areanames{en}->{46492} = "Vimmerby";
$areanames{en}->{46493} = "Gamleby";
$areanames{en}->{46494} = "Kisa";
$areanames{en}->{46495} = "Hultsfred\-Virserum";
$areanames{en}->{46496} = "Mariannelund";
$areanames{en}->{46498} = "Gotland";
$areanames{en}->{46499} = "Mönsterås";
$areanames{en}->{46500} = "Skövde";
$areanames{en}->{46501} = "Mariestad";
$areanames{en}->{46502} = "Tidaholm";
$areanames{en}->{46503} = "Hjo";
$areanames{en}->{46504} = "Tibro";
$areanames{en}->{46505} = "Karlsborg";
$areanames{en}->{46506} = "Töreboda\-Hova";
$areanames{en}->{46510} = "Lidköping";
$areanames{en}->{46511} = "Skara\-Götene";
$areanames{en}->{46512} = "Vara\-Nossebro";
$areanames{en}->{46513} = "Herrljunga";
$areanames{en}->{46514} = "Grästorp";
$areanames{en}->{46515} = "Falköping";
$areanames{en}->{46520} = "Trollhättan";
$areanames{en}->{46521} = "Vänersborg";
$areanames{en}->{46522} = "Uddevalla";
$areanames{en}->{46523} = "Lysekil";
$areanames{en}->{46524} = "Munkedal";
$areanames{en}->{46525} = "Grebbestad";
$areanames{en}->{46526} = "Strömstad";
$areanames{en}->{46528} = "Färgelanda";
$areanames{en}->{46530} = "Mellerud";
$areanames{en}->{46531} = "Bengtsfors";
$areanames{en}->{46532} = "Åmål";
$areanames{en}->{46533} = "Säffle";
$areanames{en}->{46534} = "Ed";
$areanames{en}->{4654} = "Karlstad";
$areanames{en}->{46550} = "Kristinehamn";
$areanames{en}->{46551} = "Gullspång";
$areanames{en}->{46552} = "Deje";
$areanames{en}->{46553} = "Molkom";
$areanames{en}->{46554} = "Kil";
$areanames{en}->{46555} = "Grums";
$areanames{en}->{46560} = "Torsby";
$areanames{en}->{46563} = "Hagfors\-Munkfors";
$areanames{en}->{46564} = "Sysslebäck";
$areanames{en}->{46565} = "Sunne";
$areanames{en}->{46570} = "Arvika";
$areanames{en}->{46571} = "Charlottenberg\-Åmotfors";
$areanames{en}->{46573} = "Årjäng";
$areanames{en}->{46580} = "Kopparberg";
$areanames{en}->{46581} = "Lindesberg";
$areanames{en}->{46582} = "Hallsberg";
$areanames{en}->{46583} = "Askersund";
$areanames{en}->{46584} = "Laxå";
$areanames{en}->{46585} = "Fjugesta\-Svartå";
$areanames{en}->{46586} = "Karlskoga\-Degerfors";
$areanames{en}->{46587} = "Nora";
$areanames{en}->{46589} = "Arboga";
$areanames{en}->{46590} = "Filipstad";
$areanames{en}->{46591} = "Hällefors\-Grythyttan";
$areanames{en}->{4660} = "Sundsvall\-Timrå";
$areanames{en}->{46611} = "Härnösand";
$areanames{en}->{46612} = "Kramfors";
$areanames{en}->{46613} = "Ullånger";
$areanames{en}->{46620} = "Sollefteå";
$areanames{en}->{46621} = "Junsele";
$areanames{en}->{46622} = "Näsåker";
$areanames{en}->{46623} = "Ramsele";
$areanames{en}->{46624} = "Backe";
$areanames{en}->{4663} = "Östersund";
$areanames{en}->{46640} = "Krokom";
$areanames{en}->{46642} = "Lit";
$areanames{en}->{46643} = "Hallen\-Oviken";
$areanames{en}->{46644} = "Hammerdal";
$areanames{en}->{46645} = "Föllinge";
$areanames{en}->{46647} = "Åre\-Järpen";
$areanames{en}->{46650} = "Hudiksvall";
$areanames{en}->{46651} = "Ljusdal";
$areanames{en}->{46652} = "Bergsjö";
$areanames{en}->{46653} = "Delsbo";
$areanames{en}->{46657} = "Los";
$areanames{en}->{46660} = "Örnsköldsvik";
$areanames{en}->{46661} = "Bredbyn";
$areanames{en}->{46662} = "Björna";
$areanames{en}->{46663} = "Husum";
$areanames{en}->{46670} = "Strömsund";
$areanames{en}->{46671} = "Hoting";
$areanames{en}->{46672} = "Gäddede";
$areanames{en}->{46680} = "Sveg";
$areanames{en}->{46682} = "Rätan";
$areanames{en}->{46684} = "Hede\-Funäsdalen";
$areanames{en}->{46687} = "Svenstavik";
$areanames{en}->{46690} = "Ånge";
$areanames{en}->{46691} = "Torpshammar";
$areanames{en}->{46692} = "Liden";
$areanames{en}->{46693} = "Bräcke\-Gällö";
$areanames{en}->{46695} = "Stugun";
$areanames{en}->{46696} = "Hammarstrand";
$areanames{en}->{468} = "Stockholm";
$areanames{en}->{46901} = "Umeå";
$areanames{en}->{46902} = "Umeå";
$areanames{en}->{46903} = "Umeå";
$areanames{en}->{46904} = "Umeå";
$areanames{en}->{46905} = "Umeå";
$areanames{en}->{46906} = "Umeå";
$areanames{en}->{46907} = "Umeå";
$areanames{en}->{46908} = "Umeå";
$areanames{en}->{46909} = "Umeå";
$areanames{en}->{46910} = "Skellefteå";
$areanames{en}->{46911} = "Piteå";
$areanames{en}->{46912} = "Byske";
$areanames{en}->{46913} = "Lövånger";
$areanames{en}->{46914} = "Burträsk";
$areanames{en}->{46915} = "Bastuträsk";
$areanames{en}->{46916} = "Jörn";
$areanames{en}->{46918} = "Norsjö";
$areanames{en}->{46920} = "Luleå";
$areanames{en}->{46921} = "Boden";
$areanames{en}->{46922} = "Haparanda";
$areanames{en}->{46923} = "Kalix";
$areanames{en}->{46924} = "Råneå";
$areanames{en}->{46925} = "Lakaträsk";
$areanames{en}->{46926} = "Överkalix";
$areanames{en}->{46927} = "Övertorneå";
$areanames{en}->{46928} = "Harads";
$areanames{en}->{46929} = "Älvsbyn";
$areanames{en}->{46930} = "Nordmaling";
$areanames{en}->{46932} = "Bjurholm";
$areanames{en}->{46933} = "Vindeln";
$areanames{en}->{46934} = "Robertsfors";
$areanames{en}->{46935} = "Vännäs";
$areanames{en}->{46940} = "Vilhelmina";
$areanames{en}->{46941} = "Åsele";
$areanames{en}->{46942} = "Dorotea";
$areanames{en}->{46943} = "Fredrika";
$areanames{en}->{46950} = "Lycksele";
$areanames{en}->{46951} = "Storuman";
$areanames{en}->{46952} = "Sorsele";
$areanames{en}->{46953} = "Malå";
$areanames{en}->{46954} = "Tärnaby";
$areanames{en}->{46960} = "Arvidsjaur";
$areanames{en}->{46961} = "Arjeplog";
$areanames{en}->{46970} = "Gällivare";
$areanames{en}->{46971} = "Jokkmokk";
$areanames{en}->{46973} = "Porjus";
$areanames{en}->{46975} = "Hakkas";
$areanames{en}->{46976} = "Vuollerim";
$areanames{en}->{46977} = "Korpilombolo";
$areanames{en}->{46978} = "Pajala";
$areanames{en}->{46980} = "Kiruna";
$areanames{en}->{46981} = "Vittangi";
$areanames{sv}->{4611} = "Norrköping";
$areanames{sv}->{46120} = "Åtvidaberg";
$areanames{sv}->{46121} = "Söderköping";
$areanames{sv}->{46122} = "Finspång";
$areanames{sv}->{46123} = "Valdemarsvik";
$areanames{sv}->{46125} = "Vikbolandet";
$areanames{sv}->{4613} = "Linköping";
$areanames{sv}->{46140} = "Tranås";
$areanames{sv}->{46141} = "Motala";
$areanames{sv}->{46142} = "Mjölby\-Skänninge\-Boxholm";
$areanames{sv}->{46143} = "Vadstena";
$areanames{sv}->{46144} = "Ödeshög";
$areanames{sv}->{46150} = "Katrineholm";
$areanames{sv}->{46151} = "Vingåker";
$areanames{sv}->{46152} = "Strängnäs";
$areanames{sv}->{46155} = "Nyköping\-Oxelösund";
$areanames{sv}->{46156} = "Trosa\-Vagnhärad";
$areanames{sv}->{46157} = "Flen\-Malmköping";
$areanames{sv}->{46158} = "Gnesta";
$areanames{sv}->{46159} = "Mariefred";
$areanames{sv}->{4616} = "Eskilstuna\-Torshälla";
$areanames{sv}->{46171} = "Enköping";
$areanames{sv}->{46173} = "Öregrund\-Östhammar";
$areanames{sv}->{46174} = "Alunda";
$areanames{sv}->{46175} = "Hallstavik\-Rimbo";
$areanames{sv}->{46176} = "Norrtälje";
$areanames{sv}->{4618} = "Uppsala";
$areanames{sv}->{4619} = "Örebro\-Kumla";
$areanames{sv}->{4621} = "Västerås";
$areanames{sv}->{46220} = "Hallstahammar\-Surahammar";
$areanames{sv}->{46221} = "Köping";
$areanames{sv}->{46222} = "Skinnskatteberg";
$areanames{sv}->{46223} = "Fagersta\-Norberg";
$areanames{sv}->{46224} = "Sala\-Heby";
$areanames{sv}->{46225} = "Hedemora\-Säter";
$areanames{sv}->{46226} = "Avesta\-Krylbo";
$areanames{sv}->{46227} = "Kungsör";
$areanames{sv}->{4623} = "Falun";
$areanames{sv}->{46240} = "Ludvika\-Smedjebacken";
$areanames{sv}->{46241} = "Gagnef\-Floda";
$areanames{sv}->{46243} = "Borlänge";
$areanames{sv}->{46246} = "Svärdsjö\-Enviken";
$areanames{sv}->{46247} = "Leksand\-Insjön";
$areanames{sv}->{46248} = "Rättvik";
$areanames{sv}->{46250} = "Mora\-Orsa";
$areanames{sv}->{46251} = "Älvdalen";
$areanames{sv}->{46253} = "Idre\-Särna";
$areanames{sv}->{46258} = "Furudal";
$areanames{sv}->{4626} = "Gävle\-Sandviken";
$areanames{sv}->{46270} = "Söderhamn";
$areanames{sv}->{46271} = "Alfta\-Edsbyn";
$areanames{sv}->{46278} = "Bollnäs";
$areanames{sv}->{46280} = "Malung";
$areanames{sv}->{46281} = "Vansbro";
$areanames{sv}->{46290} = "Hofors\-Storvik";
$areanames{sv}->{46291} = "Hedesunda\-Österfärnebo";
$areanames{sv}->{46292} = "Tärnsjö\-Östervåla";
$areanames{sv}->{46293} = "Tierp\-Söderfors";
$areanames{sv}->{46294} = "Karlholmsbruk\-Skärplinge";
$areanames{sv}->{46295} = "Örbyhus\-Dannemora";
$areanames{sv}->{46297} = "Ockelbo\-Hamrånge";
$areanames{sv}->{46300} = "Kungsbacka";
$areanames{sv}->{46301} = "Hindås";
$areanames{sv}->{46302} = "Lerum";
$areanames{sv}->{46303} = "Kungälv";
$areanames{sv}->{46304} = "Orust\-Tjörn";
$areanames{sv}->{4631} = "Gothenburg";
$areanames{sv}->{46320} = "Kinna";
$areanames{sv}->{46321} = "Ulricehamn";
$areanames{sv}->{46322} = "Alingsås\-Vårgårda";
$areanames{sv}->{46325} = "Svenljunga\-Tranemo";
$areanames{sv}->{4633} = "Borås";
$areanames{sv}->{46340} = "Varberg";
$areanames{sv}->{46345} = "Hyltebruk\-Torup";
$areanames{sv}->{46346} = "Falkenberg";
$areanames{sv}->{4635} = "Halmstad";
$areanames{sv}->{4636} = "Jönköping\-Huskvarna";
$areanames{sv}->{46370} = "Värnamo";
$areanames{sv}->{46371} = "Gislaved\-Anderstorp";
$areanames{sv}->{46372} = "Ljungby";
$areanames{sv}->{46380} = "Nässjö";
$areanames{sv}->{46381} = "Eksjö";
$areanames{sv}->{46382} = "Sävsjö";
$areanames{sv}->{46383} = "Vetlanda";
$areanames{sv}->{46390} = "Gränna";
$areanames{sv}->{46392} = "Mullsjö";
$areanames{sv}->{46393} = "Vaggeryd";
$areanames{sv}->{4640} = "Malmö";
$areanames{sv}->{46410} = "Trelleborg";
$areanames{sv}->{46411} = "Ystad";
$areanames{sv}->{46413} = "Eslöv\-Höör";
$areanames{sv}->{46414} = "Simrishamn";
$areanames{sv}->{46415} = "Hörby";
$areanames{sv}->{46416} = "Sjöbo";
$areanames{sv}->{46417} = "Tomelilla";
$areanames{sv}->{46418} = "Landskrona\-Svalöv";
$areanames{sv}->{4642} = "Helsingborg\-Höganäs";
$areanames{sv}->{46430} = "Laholm";
$areanames{sv}->{46431} = "Ängelholm\-Båstad";
$areanames{sv}->{46433} = "Markaryd\-Strömsnäsbruk";
$areanames{sv}->{46435} = "Klippan\-Perstorp";
$areanames{sv}->{4644} = "Kristianstad";
$areanames{sv}->{46451} = "Hässleholm";
$areanames{sv}->{46454} = "Karlshamn\-Olofström";
$areanames{sv}->{46455} = "Karlskrona";
$areanames{sv}->{46456} = "Sölvesborg\-Bromölla";
$areanames{sv}->{46457} = "Ronneby";
$areanames{sv}->{46459} = "Ryd";
$areanames{sv}->{4646} = "Lund";
$areanames{sv}->{46470} = "Växjö";
$areanames{sv}->{46471} = "Emmaboda";
$areanames{sv}->{46472} = "Alvesta\-Rydaholm";
$areanames{sv}->{46474} = "Åseda\-Lenhovda";
$areanames{sv}->{46476} = "Älmhult";
$areanames{sv}->{46477} = "Tingsryd";
$areanames{sv}->{46478} = "Lessebo";
$areanames{sv}->{46479} = "Osby";
$areanames{sv}->{46480} = "Kalmar";
$areanames{sv}->{46481} = "Nybro";
$areanames{sv}->{46485} = "Öland";
$areanames{sv}->{46486} = "Torsås";
$areanames{sv}->{46490} = "Västervik";
$areanames{sv}->{46491} = "Oskarshamn\-Högsby";
$areanames{sv}->{46492} = "Vimmerby";
$areanames{sv}->{46493} = "Gamleby";
$areanames{sv}->{46494} = "Kisa";
$areanames{sv}->{46495} = "Hultsfred\-Virserum";
$areanames{sv}->{46496} = "Mariannelund";
$areanames{sv}->{46498} = "Gotland";
$areanames{sv}->{46499} = "Mönsterås";
$areanames{sv}->{46500} = "Skövde";
$areanames{sv}->{46501} = "Mariestad";
$areanames{sv}->{46502} = "Tidaholm";
$areanames{sv}->{46503} = "Hjo";
$areanames{sv}->{46504} = "Tibro";
$areanames{sv}->{46505} = "Karlsborg";
$areanames{sv}->{46506} = "Töreboda\-Hova";
$areanames{sv}->{46510} = "Lidköping";
$areanames{sv}->{46511} = "Skara\-Götene";
$areanames{sv}->{46512} = "Vara\-Nossebro";
$areanames{sv}->{46513} = "Herrljunga";
$areanames{sv}->{46514} = "Grästorp";
$areanames{sv}->{46515} = "Falköping";
$areanames{sv}->{46520} = "Trollhättan";
$areanames{sv}->{46521} = "Vänersborg";
$areanames{sv}->{46522} = "Uddevalla";
$areanames{sv}->{46523} = "Lysekil";
$areanames{sv}->{46524} = "Munkedal";
$areanames{sv}->{46525} = "Grebbestad";
$areanames{sv}->{46526} = "Strömstad";
$areanames{sv}->{46528} = "Färgelanda";
$areanames{sv}->{46530} = "Mellerud";
$areanames{sv}->{46531} = "Bengtsfors";
$areanames{sv}->{46532} = "Åmål";
$areanames{sv}->{46533} = "Säffle";
$areanames{sv}->{46534} = "Ed";
$areanames{sv}->{4654} = "Karlstad";
$areanames{sv}->{46550} = "Kristinehamn";
$areanames{sv}->{46551} = "Gullspång";
$areanames{sv}->{46552} = "Deje";
$areanames{sv}->{46553} = "Molkom";
$areanames{sv}->{46554} = "Kil";
$areanames{sv}->{46555} = "Grums";
$areanames{sv}->{46560} = "Torsby";
$areanames{sv}->{46563} = "Hagfors\-Munkfors";
$areanames{sv}->{46564} = "Sysslebäck";
$areanames{sv}->{46565} = "Sunne";
$areanames{sv}->{46570} = "Arvika";
$areanames{sv}->{46571} = "Charlottenberg\-Åmotfors";
$areanames{sv}->{46573} = "Årjäng";
$areanames{sv}->{46580} = "Kopparberg";
$areanames{sv}->{46581} = "Lindesberg";
$areanames{sv}->{46582} = "Hallsberg";
$areanames{sv}->{46583} = "Askersund";
$areanames{sv}->{46584} = "Laxå";
$areanames{sv}->{46585} = "Fjugesta\-Svartå";
$areanames{sv}->{46586} = "Karlskoga\-Degerfors";
$areanames{sv}->{46587} = "Nora";
$areanames{sv}->{46589} = "Arboga";
$areanames{sv}->{46590} = "Filipstad";
$areanames{sv}->{46591} = "Hällefors\-Grythyttan";
$areanames{sv}->{4660} = "Sundsvall\-Timrå";
$areanames{sv}->{46611} = "Härnösand";
$areanames{sv}->{46612} = "Kramfors";
$areanames{sv}->{46613} = "Ullånger";
$areanames{sv}->{46620} = "Sollefteå";
$areanames{sv}->{46621} = "Junsele";
$areanames{sv}->{46622} = "Näsåker";
$areanames{sv}->{46623} = "Ramsele";
$areanames{sv}->{46624} = "Backe";
$areanames{sv}->{4663} = "Östersund";
$areanames{sv}->{46640} = "Krokom";
$areanames{sv}->{46642} = "Lit";
$areanames{sv}->{46643} = "Hallen\-Oviken";
$areanames{sv}->{46644} = "Hammerdal";
$areanames{sv}->{46645} = "Föllinge";
$areanames{sv}->{46647} = "Åre\-Järpen";
$areanames{sv}->{46650} = "Hudiksvall";
$areanames{sv}->{46651} = "Ljusdal";
$areanames{sv}->{46652} = "Bergsjö";
$areanames{sv}->{46653} = "Delsbo";
$areanames{sv}->{46657} = "Los";
$areanames{sv}->{46660} = "Örnsköldsvik";
$areanames{sv}->{46661} = "Bredbyn";
$areanames{sv}->{46662} = "Björna";
$areanames{sv}->{46663} = "Husum";
$areanames{sv}->{46670} = "Strömsund";
$areanames{sv}->{46671} = "Hoting";
$areanames{sv}->{46672} = "Gäddede";
$areanames{sv}->{46680} = "Sveg";
$areanames{sv}->{46682} = "Rätan";
$areanames{sv}->{46684} = "Hede\-Funäsdalen";
$areanames{sv}->{46687} = "Svenstavik";
$areanames{sv}->{46690} = "Ånge";
$areanames{sv}->{46691} = "Torpshammar";
$areanames{sv}->{46692} = "Liden";
$areanames{sv}->{46693} = "Bräcke\-Gällö";
$areanames{sv}->{46695} = "Stugun";
$areanames{sv}->{46696} = "Hammarstrand";
$areanames{sv}->{468} = "Stockholm";
$areanames{sv}->{46901} = "Umeå";
$areanames{sv}->{46902} = "Umeå";
$areanames{sv}->{46903} = "Umeå";
$areanames{sv}->{46904} = "Umeå";
$areanames{sv}->{46905} = "Umeå";
$areanames{sv}->{46906} = "Umeå";
$areanames{sv}->{46907} = "Umeå";
$areanames{sv}->{46908} = "Umeå";
$areanames{sv}->{46909} = "Umeå";
$areanames{sv}->{46910} = "Skellefteå";
$areanames{sv}->{46911} = "Piteå";
$areanames{sv}->{46912} = "Byske";
$areanames{sv}->{46913} = "Lövånger";
$areanames{sv}->{46914} = "Burträsk";
$areanames{sv}->{46915} = "Bastuträsk";
$areanames{sv}->{46916} = "Jörn";
$areanames{sv}->{46918} = "Norsjö";
$areanames{sv}->{46920} = "Luleå";
$areanames{sv}->{46921} = "Boden";
$areanames{sv}->{46922} = "Haparanda";
$areanames{sv}->{46923} = "Kalix";
$areanames{sv}->{46924} = "Råneå";
$areanames{sv}->{46925} = "Lakaträsk";
$areanames{sv}->{46926} = "Överkalix";
$areanames{sv}->{46927} = "Övertorneå";
$areanames{sv}->{46928} = "Harads";
$areanames{sv}->{46929} = "Älvsbyn";
$areanames{sv}->{46930} = "Nordmaling";
$areanames{sv}->{46932} = "Bjurholm";
$areanames{sv}->{46933} = "Vindeln";
$areanames{sv}->{46934} = "Robertsfors";
$areanames{sv}->{46935} = "Vännäs";
$areanames{sv}->{46940} = "Vilhelmina";
$areanames{sv}->{46941} = "Åsele";
$areanames{sv}->{46942} = "Dorotea";
$areanames{sv}->{46943} = "Fredrika";
$areanames{sv}->{46950} = "Lycksele";
$areanames{sv}->{46951} = "Storuman";
$areanames{sv}->{46952} = "Sorsele";
$areanames{sv}->{46953} = "Malå";
$areanames{sv}->{46954} = "Tärnaby";
$areanames{sv}->{46960} = "Arvidsjaur";
$areanames{sv}->{46961} = "Arjeplog";
$areanames{sv}->{46970} = "Gällivare";
$areanames{sv}->{46971} = "Jokkmokk";
$areanames{sv}->{46973} = "Porjus";
$areanames{sv}->{46975} = "Hakkas";
$areanames{sv}->{46976} = "Vuollerim";
$areanames{sv}->{46977} = "Korpilombolo";
$areanames{sv}->{46978} = "Pajala";
$areanames{sv}->{46980} = "Kiruna";
$areanames{sv}->{46981} = "Vittangi";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+46|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;