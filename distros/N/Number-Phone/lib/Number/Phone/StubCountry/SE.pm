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
package Number::Phone::StubCountry::SE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250913135859;

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
              44|
              9
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
          99[1-59]\\d{4}(?:
            \\d{3}
          )?|
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
$areanames{sv} = {};
$areanames{en} = {"46523", "Lysekil",
"46224", "Sala\-Heby",
"46479", "Osby",
"4621", "Västerås",
"46660", "Örnsköldsvik",
"46418", "Landskrona\-Svalöv",
"46322", "Alingsås\-Vårgårda",
"46692", "Liden",
"46611", "Härnösand",
"46223", "Fagersta\-Norberg",
"46524", "Munkedal",
"4635", "Halmstad",
"46345", "Hyltebruk\-Torup",
"46565", "Sunne",
"46371", "Gislaved\-Anderstorp",
"46916", "Jörn",
"46942", "Dorotea",
"46510", "Lidköping",
"46304", "Orust\-Tjörn",
"46909", "Umeå",
"46502", "Tidaholm",
"46380", "Nässjö",
"46410", "Trelleborg",
"46176", "Norrtälje",
"46303", "Kungälv",
"46921", "Boden",
"46925", "Lakaträsk",
"46932", "Bjurholm",
"46514", "Grästorp",
"46383", "Vetlanda",
"46158", "Gnesta",
"46528", "Färgelanda",
"46300", "Kungsbacka",
"46413", "Eslöv\-Höör",
"46582", "Hallsberg",
"46642", "Lit",
"46141", "Motala",
"46513", "Herrljunga",
"4642", "Helsingborg\-Höganäs",
"46414", "Simrishamn",
"46346", "Falkenberg",
"4618", "Uppsala",
"46122", "Finspång",
"46552", "Deje",
"46621", "Junsele",
"46960", "Arvidsjaur",
"46220", "Hallstahammar\-Surahammar",
"46915", "Bastuträsk",
"46911", "Piteå",
"46927", "Övertorneå",
"46672", "Gäddede",
"46926", "Överkalix",
"46171", "Enköping",
"46175", "Hallstavik\-Rimbo",
"46520", "Trollhättan",
"46150", "Katrineholm",
"46663", "Husum",
"46499", "Mönsterås",
"46670", "Strömsund",
"46901", "Umeå",
"46693", "Bräcke\-Gällö",
"46905", "Umeå",
"46496", "Mariannelund",
"46297", "Ockelbo\-Hamrånge",
"46258", "Furudal",
"46929", "Älvsbyn",
"46152", "Strängnäs",
"46522", "Uddevalla",
"46651", "Ljusdal",
"46241", "Gagnef\-Floda",
"4631", "Gothenburg",
"46973", "Porjus",
"46222", "Skinnskatteberg",
"46943", "Fredrika",
"46571", "Charlottenberg\-Åmotfors",
"46280", "Malung",
"46120", "Åtvidaberg",
"46550", "Kristinehamn",
"46480", "Kalmar",
"46504", "Tibro",
"46930", "Nordmaling",
"46471", "Emmaboda",
"46271", "Alfta\-Edsbyn",
"46302", "Lerum",
"46580", "Kopparberg",
"46250", "Mora\-Orsa",
"46640", "Krokom",
"46503", "Hjo",
"46657", "Los",
"46247", "Leksand\-Insjön",
"46253", "Idre\-Särna",
"46643", "Hallen\-Oviken",
"46583", "Askersund",
"46554", "Kil",
"46246", "Svärdsjö\-Enviken",
"4611", "Norrköping",
"46500", "Skövde",
"46495", "Hultsfred\-Virserum",
"46491", "Oskarshamn\-Högsby",
"46933", "Vindeln",
"46382", "Sävsjö",
"46906", "Umeå",
"46295", "Örbyhus\-Dannemora",
"46291", "Hedesunda\-Österfärnebo",
"46907", "Umeå",
"46553", "Molkom",
"46584", "Laxå",
"46123", "Valdemarsvik",
"46644", "Hammerdal",
"46687", "Svenstavik",
"46454", "Karlshamn\-Olofström",
"46978", "Pajala",
"46940", "Vilhelmina",
"46934", "Robertsfors",
"46512", "Vara\-Nossebro",
"46591", "Hällefors\-Grythyttan",
"46435", "Klippan\-Perstorp",
"46431", "Ängelholm\-Båstad",
"46970", "Gällivare",
"46951", "Storuman",
"4663", "Östersund",
"4640", "Malmö",
"46531", "Bengtsfors",
"46662", "Björna",
"46320", "Kinna",
"46476", "Älmhult",
"46690", "Ånge",
"46477", "Tingsryd",
"46981", "Vittangi",
"46696", "Hammarstrand",
"46935", "Vännäs",
"46493", "Gamleby",
"46470", "Växjö",
"46248", "Rättvik",
"46270", "Söderhamn",
"4644", "Kristianstad",
"46293", "Tierp\-Söderfors",
"46251", "Älvdalen",
"46585", "Fjugesta\-Svartå",
"46645", "Föllinge",
"46581", "Lindesberg",
"46908", "Umeå",
"46451", "Hässleholm",
"46455", "Karlskrona",
"46142", "Mjölby\-Skänninge\-Boxholm",
"46494", "Kisa",
"4654", "Karlstad",
"46294", "Karlholmsbruk\-Skärplinge",
"46570", "Arvika",
"468", "Stockholm",
"46976", "Vuollerim",
"46551", "Gullspång",
"46121", "Söderköping",
"46125", "Vikbolandet",
"46555", "Grums",
"46281", "Vansbro",
"46622", "Näsåker",
"46977", "Korpilombolo",
"46485", "Öland",
"46481", "Nybro",
"46392", "Mullsjö",
"46953", "Malå",
"46433", "Markaryd\-Strömsnäsbruk",
"46912", "Byske",
"46534", "Ed",
"4636", "Jönköping\-Huskvarna",
"46680", "Sveg",
"46671", "Hoting",
"46954", "Tärnaby",
"46478", "Lessebo",
"46278", "Bollnäs",
"46506", "Töreboda\-Hova",
"46240", "Ludvika\-Smedjebacken",
"46650", "Hudiksvall",
"46533", "Säffle",
"46498", "Gotland",
"46586", "Karlskoga\-Degerfors",
"46457", "Ronneby",
"46530", "Mellerud",
"46684", "Hede\-Funäsdalen",
"46653", "Delsbo",
"46243", "Borlänge",
"46647", "Åre\-Järpen",
"46587", "Nora",
"46456", "Sölvesborg\-Bromölla",
"46325", "Svenljunga\-Tranemo",
"46321", "Ulricehamn",
"46903", "Umeå",
"46691", "Torpshammar",
"46695", "Stugun",
"46980", "Kiruna",
"46612", "Kramfors",
"46971", "Jokkmokk",
"46430", "Laholm",
"46975", "Hakkas",
"46486", "Torsås",
"46904", "Umeå",
"46950", "Lycksele",
"46372", "Ljungby",
"46941", "Åsele",
"46474", "Åseda\-Lenhovda",
"4623", "Falun",
"46573", "Årjäng",
"46590", "Filipstad",
"4660", "Sundsvall\-Timrå",
"46501", "Mariestad",
"46505", "Karlsborg",
"46490", "Västervik",
"46290", "Hofors\-Storvik",
"46159", "Mariefred",
"4616", "Eskilstuna\-Torshälla",
"46922", "Haparanda",
"4619", "Örebro\-Kumla",
"46526", "Strömstad",
"46156", "Trosa\-Vagnhärad",
"46624", "Backe",
"46143", "Vadstena",
"46157", "Flen\-Malmköping",
"46381", "Eksjö",
"46492", "Vimmerby",
"46415", "Hörby",
"46292", "Tärnsjö\-Östervåla",
"46411", "Ystad",
"46920", "Luleå",
"46560", "Torsby",
"46226", "Avesta\-Krylbo",
"46393", "Vaggeryd",
"46370", "Värnamo",
"46227", "Kungsör",
"46144", "Ödeshög",
"46623", "Ramsele",
"46515", "Falköping",
"46511", "Skara\-Götene",
"46913", "Lövånger",
"4613", "Linköping",
"46952", "Sorsele",
"46340", "Varberg",
"46174", "Alunda",
"46532", "Åmål",
"46914", "Burträsk",
"46661", "Bredbyn",
"46928", "Harads",
"46459", "Ryd",
"4646", "Lund",
"46173", "Öregrund\-Östhammar",
"4626", "Gävle\-Sandviken",
"46589", "Arboga",
"46902", "Umeå",
"46417", "Tomelilla",
"46613", "Ullånger",
"46416", "Sjöbo",
"46151", "Vingåker",
"46521", "Vänersborg",
"46525", "Grebbestad",
"46155", "Nyköping\-Oxelösund",
"46652", "Bergsjö",
"46961", "Arjeplog",
"46221", "Köping",
"46225", "Hedemora\-Säter",
"46910", "Skellefteå",
"46682", "Rätan",
"46918", "Norsjö",
"46924", "Råneå",
"46563", "Hagfors\-Munkfors",
"46620", "Sollefteå",
"46390", "Gränna",
"46472", "Alvesta\-Rydaholm",
"46923", "Kalix",
"46301", "Hindås",
"46564", "Sysslebäck",
"4633", "Borås",
"46140", "Tranås",};
my $timezones = {
               '' => [
                       'Europe/Stockholm'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+46|\D)//g;
      my $self = bless({ country_code => '46', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '46', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;