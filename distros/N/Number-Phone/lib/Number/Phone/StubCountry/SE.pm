# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20231210185946;

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
$areanames{en} = {"46907", "Umeå",
"46555", "Grums",
"46524", "Munkedal",
"46492", "Vimmerby",
"46223", "Fagersta\-Norberg",
"46320", "Kinna",
"46251", "Älvdalen",
"46571", "Charlottenberg\-Åmotfors",
"46417", "Tomelilla",
"4631", "Gothenburg",
"46454", "Karlshamn\-Olofström",
"46372", "Ljungby",
"4623", "Falun",
"46290", "Hofors\-Storvik",
"46951", "Storuman",
"46171", "Enköping",
"46923", "Kalix",
"46393", "Vaggeryd",
"46975", "Hakkas",
"46580", "Kopparberg",
"46155", "Nyköping\-Oxelösund",
"46644", "Hammerdal",
"46459", "Ryd",
"46457", "Ronneby",
"4635", "Halmstad",
"46624", "Backe",
"46144", "Ödeshög",
"46414", "Simrishamn",
"46943", "Fredrika",
"46532", "Åmål",
"46671", "Hoting",
"46515", "Falköping",
"46904", "Umeå",
"46647", "Åre\-Järpen",
"46960", "Arvidsjaur",
"46503", "Hjo",
"46340", "Varberg",
"46243", "Borlänge",
"46696", "Hammarstrand",
"46680", "Sveg",
"46909", "Umeå",
"46911", "Piteå",
"46143", "Vadstena",
"46623", "Ramsele",
"46511", "Skara\-Götene",
"46477", "Tingsryd",
"46413", "Eslöv\-Höör",
"46560", "Torsby",
"46227", "Kungsör",
"46651", "Ljusdal",
"46903", "Umeå",
"4663", "Östersund",
"46915", "Bastuträsk",
"46690", "Ånge",
"46927", "Övertorneå",
"46430", "Laholm",
"46504", "Tibro",
"46300", "Kungsbacka",
"46346", "Falkenberg",
"46932", "Bjurholm",
"46523", "Lysekil",
"46611", "Härnösand",
"46980", "Kiruna",
"46224", "Sala\-Heby",
"46474", "Åseda\-Lenhovda",
"46929", "Älvsbyn",
"46660", "Örnsköldsvik",
"46551", "Gullspång",
"46271", "Alfta\-Edsbyn",
"4613", "Linköping",
"4646", "Lund",
"46590", "Filipstad",
"46971", "Jokkmokk",
"46151", "Vingåker",
"46247", "Leksand\-Insjön",
"46586", "Karlskoga\-Degerfors",
"46383", "Vetlanda",
"46924", "Råneå",
"46280", "Malung",
"46175", "Hallstavik\-Rimbo",
"46479", "Osby",
"46643", "Hallen\-Oviken",
"46123", "Valdemarsvik",
"46472", "Alvesta\-Rydaholm",
"46281", "Vansbro",
"4654", "Karlstad",
"46295", "Örbyhus\-Dannemora",
"46176", "Norrtälje",
"46493", "Gamleby",
"46591", "Hällefors\-Grythyttan",
"46970", "Gällivare",
"46585", "Fjugesta\-Svartå",
"46150", "Katrineholm",
"46222", "Skinnskatteberg",
"46392", "Mullsjö",
"46918", "Norsjö",
"46922", "Haparanda",
"46661", "Bredbyn",
"46550", "Kristinehamn",
"46270", "Söderhamn",
"46325", "Svenljunga\-Tranemo",
"46981", "Vittangi",
"46345", "Hyltebruk\-Torup",
"46301", "Hindås",
"46258", "Furudal",
"46691", "Torpshammar",
"46431", "Ängelholm\-Båstad",
"46916", "Jörn",
"46942", "Dorotea",
"46533", "Säffle",
"46650", "Hudiksvall",
"46934", "Robertsfors",
"46510", "Lidköping",
"46502", "Tidaholm",
"46278", "Bollnäs",
"46435", "Klippan\-Perstorp",
"46902", "Umeå",
"46695", "Stugun",
"46910", "Skellefteå",
"46961", "Arjeplog",
"46622", "Näsåker",
"46142", "Mjölby\-Skänninge\-Boxholm",
"4660", "Sundsvall\-Timrå",
"46534", "Ed",
"46670", "Strömsund",
"46933", "Vindeln",
"46978", "Pajala",
"46565", "Sunne",
"46158", "Gnesta",
"46156", "Trosa\-Vagnhärad",
"46976", "Vuollerim",
"46581", "Lindesberg",
"46522", "Uddevalla",
"46494", "Kisa",
"46291", "Hedesunda\-Österfärnebo",
"46950", "Lycksele",
"46321", "Ulricehamn",
"46250", "Mora\-Orsa",
"46570", "Arvika",
"46122", "Finspång",
"46642", "Lit",
"46499", "Mönsterås",
"4636", "Jönköping\-Huskvarna",
"46382", "Sävsjö",
"46928", "Harads",
"46912", "Byske",
"46563", "Hagfors\-Munkfors",
"4642", "Helsingborg\-Höganäs",
"46410", "Trelleborg",
"46140", "Tranås",
"46620", "Sollefteå",
"46935", "Vännäs",
"46303", "Kungälv",
"46506", "Töreboda\-Hova",
"46478", "Lessebo",
"46684", "Hede\-Funäsdalen",
"46297", "Ockelbo\-Hamrånge",
"46672", "Gäddede",
"46433", "Markaryd\-Strömsnäsbruk",
"46531", "Bengtsfors",
"46246", "Svärdsjö\-Enviken",
"46693", "Bräcke\-Gällö",
"46587", "Nora",
"46589", "Arboga",
"46226", "Avesta\-Krylbo",
"46248", "Rättvik",
"46663", "Husum",
"46952", "Sorsele",
"46371", "Gislaved\-Anderstorp",
"46520", "Trollhättan",
"46476", "Älmhult",
"4611", "Norrköping",
"46584", "Laxå",
"46120", "Åtvidaberg",
"46640", "Krokom",
"4644", "Kristianstad",
"46294", "Karlholmsbruk\-Skärplinge",
"46380", "Nässjö",
"46491", "Oskarshamn\-Högsby",
"46485", "Öland",
"46687", "Svenstavik",
"46926", "Överkalix",
"46526", "Strömstad",
"46470", "Växjö",
"46220", "Hallstahammar\-Surahammar",
"46456", "Sölvesborg\-Bromölla",
"4621", "Västerås",
"46152", "Strängnäs",
"46583", "Askersund",
"46495", "Hultsfred\-Virserum",
"46481", "Nybro",
"46552", "Deje",
"46908", "Umeå",
"4633", "Borås",
"46920", "Luleå",
"46390", "Gränna",
"46293", "Tierp\-Söderfors",
"46612", "Kramfors",
"46418", "Landskrona\-Svalöv",
"4640", "Malmö",
"46416", "Sjöbo",
"46564", "Sysslebäck",
"46940", "Vilhelmina",
"46906", "Umeå",
"468", "Stockholm",
"46304", "Orust\-Tjörn",
"46652", "Bergsjö",
"46240", "Ludvika\-Smedjebacken",
"46500", "Skövde",
"46528", "Färgelanda",
"46512", "Vara\-Nossebro",
"46501", "Mariestad",
"46157", "Flen\-Malmköping",
"46977", "Korpilombolo",
"46913", "Lövånger",
"46241", "Gagnef\-Floda",
"46941", "Åsele",
"4618", "Uppsala",
"46514", "Grästorp",
"46498", "Gotland",
"46905", "Umeå",
"46692", "Liden",
"46930", "Nordmaling",
"46302", "Lerum",
"46415", "Hörby",
"46953", "Malå",
"46173", "Öregrund\-Östhammar",
"46125", "Vikbolandet",
"46645", "Föllinge",
"46480", "Kalmar",
"46662", "Björna",
"46496", "Mariannelund",
"46921", "Boden",
"46221", "Köping",
"46455", "Karlskrona",
"46159", "Mariefred",
"46657", "Los",
"46554", "Kil",
"46525", "Grebbestad",
"46253", "Idre\-Särna",
"4626", "Gävle\-Sandviken",
"46573", "Årjäng",
"46471", "Emmaboda",
"46925", "Lakaträsk",
"46381", "Eksjö",
"46954", "Tärnaby",
"46174", "Alunda",
"46486", "Torsås",
"46490", "Västervik",
"46973", "Porjus",
"4616", "Eskilstuna\-Torshälla",
"46121", "Söderköping",
"46322", "Alingsås\-Vårgårda",
"46613", "Ullånger",
"46292", "Tärnsjö\-Östervåla",
"46370", "Värnamo",
"46521", "Vänersborg",
"46553", "Molkom",
"46451", "Hässleholm",
"46582", "Hallsberg",
"46225", "Hedemora\-Säter",
"46530", "Mellerud",
"46914", "Burträsk",
"46505", "Karlsborg",
"46513", "Herrljunga",
"46411", "Ystad",
"46141", "Motala",
"46621", "Junsele",
"46653", "Delsbo",
"46682", "Rätan",
"46901", "Umeå",
"4619", "Örebro\-Kumla",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+46|\D)//g;
      my $self = bless({ country_code => '46', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '46', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;