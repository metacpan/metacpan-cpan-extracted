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
package Number::Phone::StubCountry::SE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20241212130807;

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
$areanames{en} = {"46511", "Skara\-Götene",
"46932", "Bjurholm",
"46144", "Ödeshög",
"4646", "Lund",
"46510", "Lidköping",
"4618", "Uppsala",
"46278", "Bollnäs",
"46925", "Lakaträsk",
"4631", "Gothenburg",
"4654", "Karlstad",
"46530", "Mellerud",
"46456", "Sölvesborg\-Bromölla",
"46976", "Vuollerim",
"46942", "Dorotea",
"46372", "Ljungby",
"46346", "Falkenberg",
"46912", "Byske",
"46923", "Kalix",
"46531", "Bengtsfors",
"46927", "Övertorneå",
"46621", "Junsele",
"46393", "Vaggeryd",
"4633", "Borås",
"46340", "Varberg",
"46971", "Jokkmokk",
"46692", "Liden",
"46451", "Hässleholm",
"46253", "Idre\-Särna",
"46584", "Laxå",
"46970", "Gällivare",
"46620", "Sollefteå",
"46918", "Norsjö",
"46563", "Hagfors\-Munkfors",
"46914", "Burträsk",
"4621", "Västerås",
"46433", "Markaryd\-Strömsnäsbruk",
"4660", "Sundsvall\-Timrå",
"46582", "Hallsberg",
"46125", "Vikbolandet",
"46553", "Molkom",
"46415", "Hörby",
"46295", "Örbyhus\-Dannemora",
"46905", "Umeå",
"46589", "Arboga",
"46687", "Svenstavik",
"46652", "Bergsjö",
"46413", "Eslöv\-Höör",
"46297", "Ockelbo\-Hamrånge",
"46240", "Ludvika\-Smedjebacken",
"46491", "Oskarshamn\-Högsby",
"46417", "Tomelilla",
"46293", "Tierp\-Söderfors",
"4623", "Falun",
"46903", "Umeå",
"46907", "Umeå",
"46382", "Sävsjö",
"46176", "Norrtälje",
"46934", "Robertsfors",
"46142", "Mjölby\-Skänninge\-Boxholm",
"46123", "Valdemarsvik",
"46555", "Grums",
"46241", "Gagnef\-Floda",
"46490", "Västervik",
"46171", "Enköping",
"46565", "Sunne",
"46980", "Kiruna",
"46496", "Mariannelund",
"46435", "Klippan\-Perstorp",
"46246", "Svärdsjö\-Enviken",
"46662", "Björna",
"46981", "Vittangi",
"46477", "Tingsryd",
"46303", "Kungälv",
"46271", "Alfta\-Edsbyn",
"46953", "Malå",
"46661", "Bredbyn",
"46660", "Örnsköldsvik",
"46505", "Karlsborg",
"46270", "Söderhamn",
"46380", "Nässjö",
"4613", "Linköping",
"46140", "Tranås",
"46499", "Mönsterås",
"46650", "Hudiksvall",
"46514", "Grästorp",
"46651", "Ljusdal",
"46492", "Vimmerby",
"46141", "Motala",
"46227", "Kungsör",
"46381", "Eksjö",
"46223", "Fagersta\-Norberg",
"46580", "Kopparberg",
"46978", "Pajala",
"46225", "Hedemora\-Säter",
"46624", "Backe",
"46454", "Karlshamn\-Olofström",
"46581", "Lindesberg",
"4642", "Helsingborg\-Höganäs",
"46503", "Hjo",
"46534", "Ed",
"46586", "Karlskoga\-Degerfors",
"4611", "Norrköping",
"468", "Stockholm",
"46690", "Ånge",
"46280", "Malung",
"46647", "Åre\-Järpen",
"46643", "Hallen\-Oviken",
"46916", "Jörn",
"46525", "Grebbestad",
"46459", "Ryd",
"46157", "Flen\-Malmköping",
"46622", "Näsåker",
"46691", "Torpshammar",
"46281", "Vansbro",
"46613", "Ullånger",
"46940", "Vilhelmina",
"46911", "Piteå",
"46371", "Gislaved\-Anderstorp",
"46532", "Åmål",
"46696", "Hammarstrand",
"46370", "Värnamo",
"46941", "Åsele",
"46910", "Skellefteå",
"46571", "Charlottenberg\-Åmotfors",
"46174", "Alunda",
"46570", "Arvika",
"46930", "Nordmaling",
"46485", "Öland",
"46498", "Gotland",
"46325", "Svenljunga\-Tranemo",
"46494", "Kisa",
"46645", "Föllinge",
"46248", "Rättvik",
"46512", "Vara\-Nossebro",
"4640", "Malmö",
"46155", "Nyköping\-Oxelösund",
"46523", "Lysekil",
"4644", "Kristianstad",
"46430", "Laholm",
"46560", "Torsby",
"4635", "Halmstad",
"46175", "Hallstavik\-Rimbo",
"46502", "Tidaholm",
"46431", "Ängelholm\-Båstad",
"46158", "Gnesta",
"4636", "Jönköping\-Huskvarna",
"46551", "Gullspång",
"46550", "Kristinehamn",
"46644", "Hammerdal",
"46495", "Hultsfred\-Virserum",
"46120", "Åtvidaberg",
"46901", "Umeå",
"46411", "Ystad",
"46291", "Hedesunda\-Österfärnebo",
"46493", "Gamleby",
"46524", "Munkedal",
"46222", "Skinnskatteberg",
"46528", "Färgelanda",
"46410", "Trelleborg",
"46243", "Borlänge",
"46680", "Sveg",
"46247", "Leksand\-Insjön",
"46290", "Hofors\-Storvik",
"46121", "Söderköping",
"46173", "Öregrund\-Östhammar",
"46479", "Osby",
"46416", "Sjöbo",
"46906", "Umeå",
"46302", "Lerum",
"46472", "Alvesta\-Rydaholm",
"46952", "Sorsele",
"46513", "Herrljunga",
"46591", "Hällefors\-Grythyttan",
"4626", "Gävle\-Sandviken",
"46345", "Hyltebruk\-Torup",
"46224", "Sala\-Heby",
"46522", "Uddevalla",
"46975", "Hakkas",
"46590", "Filipstad",
"46455", "Karlskrona",
"46478", "Lessebo",
"46304", "Orust\-Tjörn",
"46474", "Åseda\-Lenhovda",
"46954", "Tärnaby",
"46670", "Strömsund",
"46920", "Luleå",
"46504", "Tibro",
"46921", "Boden",
"46533", "Säffle",
"46671", "Hoting",
"46973", "Porjus",
"46977", "Korpilombolo",
"46623", "Ramsele",
"46457", "Ronneby",
"46159", "Mariefred",
"46322", "Alingsås\-Vårgårda",
"46612", "Kramfors",
"46251", "Älvdalen",
"46642", "Lit",
"46250", "Mora\-Orsa",
"46926", "Överkalix",
"46515", "Falköping",
"46390", "Gränna",
"46152", "Strängnäs",
"46480", "Kalmar",
"46320", "Kinna",
"46151", "Vingåker",
"46935", "Vännäs",
"46392", "Mullsjö",
"46150", "Katrineholm",
"4663", "Östersund",
"46693", "Bräcke\-Gällö",
"46481", "Nybro",
"46321", "Ulricehamn",
"46640", "Krokom",
"46611", "Härnösand",
"46554", "Kil",
"46156", "Trosa\-Vagnhärad",
"46564", "Sysslebäck",
"46913", "Lövånger",
"46672", "Gäddede",
"46922", "Haparanda",
"46486", "Torsås",
"46943", "Fredrika",
"46929", "Älvsbyn",
"46573", "Årjäng",
"46915", "Bastuträsk",
"46526", "Strömstad",
"46520", "Trollhättan",
"46695", "Stugun",
"46418", "Landskrona\-Svalöv",
"46908", "Umeå",
"4616", "Eskilstuna\-Torshälla",
"46904", "Umeå",
"46414", "Simrishamn",
"46684", "Hede\-Funäsdalen",
"46294", "Karlholmsbruk\-Skärplinge",
"46933", "Vindeln",
"46521", "Vänersborg",
"46301", "Hindås",
"46471", "Emmaboda",
"46663", "Husum",
"46951", "Storuman",
"46950", "Lycksele",
"46226", "Avesta\-Krylbo",
"46300", "Kungsbacka",
"46470", "Växjö",
"46909", "Umeå",
"46220", "Hallstahammar\-Surahammar",
"46122", "Finspång",
"46585", "Fjugesta\-Svartå",
"46960", "Arvidsjaur",
"46476", "Älmhult",
"46653", "Delsbo",
"46292", "Tärnsjö\-Östervåla",
"46682", "Rätan",
"46657", "Los",
"46902", "Umeå",
"46961", "Arjeplog",
"46383", "Vetlanda",
"46221", "Köping",
"46143", "Vadstena",
"46258", "Furudal",
"46506", "Töreboda\-Hova",
"46583", "Askersund",
"46552", "Deje",
"46587", "Nora",
"46501", "Mariestad",
"46924", "Råneå",
"46928", "Harads",
"4619", "Örebro\-Kumla",
"46500", "Skövde",};
$areanames{sv} = {};
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