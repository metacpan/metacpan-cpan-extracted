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
package Number::Phone::StubCountry::IT;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250913135858;

my $formatters = [
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '
            1(?:
              0|
              9(?:
                2[2-9]|
                [46]
              )
            )
          ',
                  'pattern' => '(\\d{4,5})'
                },
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '
            1(?:
              1|
              92
            )
          ',
                  'pattern' => '(\\d{6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '0[26]',
                  'pattern' => '(\\d{2})(\\d{4,6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            0[13-57-9][0159]|
            8(?:
              03|
              4[17]|
              9(?:
                2|
                3[04]|
                [45][0-4]
              )
            )
          ',
                  'pattern' => '(\\d{3})(\\d{3,6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            0(?:
              [13-579][2-46-8]|
              8[236-8]
            )
          ',
                  'pattern' => '(\\d{4})(\\d{2,6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '894',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            0[26]|
            5
          ',
                  'pattern' => '(\\d{2})(\\d{3,4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            1(?:
              44|
              [679]
            )|
            [378]|
            43
          ',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            0[13-57-9][0159]|
            14
          ',
                  'pattern' => '(\\d{3})(\\d{3,4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '0[26]',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[03]',
                  'pattern' => '(\\d{3})(\\d{4})(\\d{4,5})'
                }
              ];

my $validators = {
                'fixed_line' => '
          0(?:
            669[0-79]\\d{1,6}|
            831\\d{2,8}
          )|
          0(?:
            1(?:
              [0159]\\d|
              [27][1-5]|
              31|
              4[1-4]|
              6[1356]|
              8[2-57]
            )|
            2\\d\\d|
            3(?:
              [0159]\\d|
              2[1-4]|
              3[12]|
              [48][1-6]|
              6[2-59]|
              7[1-7]
            )|
            4(?:
              [0159]\\d|
              [23][1-9]|
              4[245]|
              6[1-5]|
              7[1-4]|
              81
            )|
            5(?:
              [0159]\\d|
              2[1-5]|
              3[2-6]|
              4[1-79]|
              6[4-6]|
              7[1-578]|
              8[3-8]
            )|
            6(?:
              [0-57-9]\\d|
              6[0-8]
            )|
            7(?:
              [0159]\\d|
              2[12]|
              3[1-7]|
              4[2-46]|
              6[13569]|
              7[13-6]|
              8[1-59]
            )|
            8(?:
              [0159]\\d|
              2[3-578]|
              3[2356]|
              [6-8][1-5]
            )|
            9(?:
              [0159]\\d|
              [238][1-5]|
              4[12]|
              6[1-8]|
              7[1-6]
            )
          )\\d{2,7}
        ',
                'geographic' => '
          0(?:
            669[0-79]\\d{1,6}|
            831\\d{2,8}
          )|
          0(?:
            1(?:
              [0159]\\d|
              [27][1-5]|
              31|
              4[1-4]|
              6[1356]|
              8[2-57]
            )|
            2\\d\\d|
            3(?:
              [0159]\\d|
              2[1-4]|
              3[12]|
              [48][1-6]|
              6[2-59]|
              7[1-7]
            )|
            4(?:
              [0159]\\d|
              [23][1-9]|
              4[245]|
              6[1-5]|
              7[1-4]|
              81
            )|
            5(?:
              [0159]\\d|
              2[1-5]|
              3[2-6]|
              4[1-79]|
              6[4-6]|
              7[1-578]|
              8[3-8]
            )|
            6(?:
              [0-57-9]\\d|
              6[0-8]
            )|
            7(?:
              [0159]\\d|
              2[12]|
              3[1-7]|
              4[2-46]|
              6[13569]|
              7[13-6]|
              8[1-59]
            )|
            8(?:
              [0159]\\d|
              2[3-578]|
              3[2356]|
              [6-8][1-5]
            )|
            9(?:
              [0159]\\d|
              [238][1-5]|
              4[12]|
              6[1-8]|
              7[1-6]
            )
          )\\d{2,7}
        ',
                'mobile' => '
          3[2-9]\\d{7,8}|
          (?:
            31|
            43
          )\\d{8}
        ',
                'pager' => '',
                'personal_number' => '
          1(?:
            78\\d|
            99
          )\\d{6}
        ',
                'specialrate' => '(
          84(?:
            [08]\\d{3}|
            [17]
          )\\d{3}
        )|(
          (?:
            0878\\d{3}|
            89(?:
              2\\d|
              3[04]|
              4(?:
                [0-4]|
                [5-9]\\d\\d
              )|
              5[0-4]
            )
          )\\d\\d|
          (?:
            1(?:
              44|
              6[346]
            )|
            89(?:
              38|
              5[5-9]|
              9
            )
          )\\d{6}
        )',
                'toll_free' => '
          80(?:
            0\\d{3}|
            3
          )\\d{3}
        ',
                'voip' => '55\\d{8}'
              };
my %areanames = ();
$areanames{en} = {"390733", "Macerata",
"390575", "Arezzo",
"390832", "Lecce",
"390565", "Livorno",
"39031", "Como",
"39035", "Bergamo",
"390586", "Livorno",
"390445", "Vicenza",
"390324", "Verbano\-Cusio\-Ossola",
"390865", "Isernia",
"390532", "Ferrara",
"390364", "Brescia",
"390422", "Treviso",
"390825", "Avellino",
"390122", "Turin",
"390884", "Foggia",
"390376", "Mantua",
"39091", "Palermo",
"390823", "Caserta",
"39095", "Catania",
"3906698", "Vatican\ City",
"390523", "Piacenza",
"390974", "Salerno",
"390924", "Trapani",
"390735", "Ascoli\ Piceno",
"390341", "Lecco",
"390789", "Sassari",
"390783", "Oristano",
"39080", "Bari",
"390343", "Sondrio",
"390426", "Rovigo",
"390185", "Genoa",
"39089", "Salerno",
"390882", "Foggia",
"390774", "Rome",
"390521", "Parma",
"390166", "Aosta\ Valley",
"390962", "Crotone",
"39050", "Pisa",
"390141", "Asti",
"3906", "Rome",
"39059", "Modena",
"390922", "Agrigento",
"39075", "Perugia",
"39071", "Ancona",
"39011", "Turin",
"39015", "Biella",
"39041", "Venice",
"39045", "Verona",
"390322", "Novara",
"390776", "Frosinone",
"390731", "Ancona",
"390424", "Vicenza",
"390362", "Cremona\/Monza",
"390933", "Caltanissetta",
"390372", "Cremona",
"390183", "Imperia",
"390961", "Catanzaro",
"390165", "Aosta\ Valley",
"390862", "L\'Aquila",
"390921", "Palermo",
"390425", "Rovigo",
"390344", "Como",
"390125", "Turin",
"39099", "Taranto",
"390432", "Udine",
"390881", "Foggia",
"390545", "Ravenna",
"39090", "Messina",
"390522", "Reggio\ Emilia",
"390577", "Siena",
"390321", "Novara",
"390737", "Macerata",
"39013", "Alessandria",
"390732", "Ancona",
"390543", "Forlì\-Cesena",
"390371", "Lodi",
"390423", "Treviso",
"390934", "Caltanissetta\ and\ Enna",
"390346", "Bergamo",
"39039", "Monza",
"390382", "Pavia",
"3902", "Milan",
"39030", "Brescia",
"390461", "Trento",
"390965", "Reggio\ Calabria",
"390942", "Catania",
"390171", "Cuneo",
"390471", "Bolzano\/Bozen",
"39033", "Varese",
"390161", "Vercelli",
"390975", "Potenza",
"390585", "Massa\-Carrara",
"390925", "Agrigento",
"390734", "Fermo",
"390421", "Venice",
"390549", "San\ Marino",
"390363", "Bergamo",
"39049", "Padova",
"39010", "Genoa",
"390373", "Cremona",
"390831", "Brindisi",
"39040", "Trieste",
"390541", "Rimini",
"390187", "La\ Spezia",
"390874", "Campobasso",
"39055", "Florence",
"390444", "Vicenza",
"39051", "Bologna",
"390365", "Brescia",
"390342", "Sondrio",
"39079", "Sassari",
"39070", "Cagliari",
"390883", "Andria\ Barletta\ Trani",
"390824", "Benevento",
"39048", "Gorizia",
"39081", "Naples",
"39085", "Pescara",
"390574", "Prato",
"390963", "Vibo\ Valentia",
"390583", "Lucca",};
$areanames{it} = {"3906698", "Città\ del\ Vaticano",
"390143", "Novi\ Ligure",
"390722", "Urbino",
"390376", "Mantova",
"390884", "Manfredonia",
"390789", "Olbia",
"390428", "Tarvisio",
"390964", "Locri",
"390974", "Vallo\ della\ Lucania",
"390584", "Viareggio",
"390966", "Palmi",
"390547", "Cesena",
"390976", "Muro\ Lucano",
"390525", "Fornovo\ di\ Taro",
"390364", "Breno",
"390374", "Soresina",
"390172", "Savigliano",
"390544", "Ravenna",
"39041", "Venezia",
"390124", "Rivarolo\ Canavese",
"390322", "Arona",
"390766", "Civitavecchia",
"390464", "Rovereto",
"390377", "Codogno",
"390534", "Porretta\ Terme",
"390776", "Cassino",
"390474", "Brunico",
"390536", "Sassuolo",
"390774", "Tivoli",
"390185", "Rapallo",
"390439", "Feltre",
"390587", "Pontedera",
"390967", "Soverato",
"390836", "Maglie",
"390546", "Faenza",
"390732", "Fabriano",
"390833", "Gallipoli",
"390543", "Forlì",
"390578", "Chianciano\ Terme",
"390438", "Conegliano",
"390765", "Poggio\ Mirteto",
"390742", "Foligno",
"390463", "Cles",
"390533", "Comacchio",
"390473", "Merano",
"3902", "Milano",
"390775", "Frosinone",
"390184", "Sanremo",
"390123", "Lanzo\ Torinese",
"390125", "Ivrea",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390872", "Lanciano",
"390763", "Orvieto",
"390442", "Legnago",
"390465", "Tione\ di\ Trento",
"390971", "Potenza",
"390535", "Mirandola",
"390773", "Latina",
"390982", "Paola",
"390572", "Montecatini\ Terme",
"390545", "Lugo",
"390835", "Matera",
"390782", "Lanusei",
"390365", "Salò",
"390375", "Casalmaggiore",
"390883", "Andria",
"390144", "Acqui\ Terme",
"390332", "Varese",
"390761", "Viterbo",
"390973", "Lagonegro",
"390524", "Fidenza",
"390771", "Formia",
"390429", "Este",
"390121", "Pinerolo",
"390942", "Taormina",
"390965", "Reggio\ di\ Calabria",
"390975", "Sala\ Consilina",
"390585", "Massa",
"390471", "Bolzano",
"39010", "Genova",
"390363", "Treviglio",
"390932", "Ragusa",
"390373", "Crema",
"390885", "Cerignola",
"390331", "Busto\ Arsizio",
"390873", "Vasto",
"390385", "Stradella",
"390863", "Avezzano",
"390983", "Rossano",
"390573", "Pistoia",
"390433", "Tolmezzo",
"390781", "Iglesias",
"390924", "Alcamo",
"390735", "San\ Benedetto\ del\ Tronto",
"390931", "Siracusa",
"390985", "Scalea",
"390435", "Pieve\ di\ Cadore",
"390565", "Piombino",
"390542", "Imola",
"390122", "Susa",
"390743", "Spoleto",
"390462", "Cavalese",
"390445", "Schio",
"390324", "Domodossola",
"390875", "Termoli",
"390383", "Voghera",
"390941", "Patti",
"390427", "Spilimbergo",
"390472", "Bressanone",
"390381", "Vigevano",
"39011", "Torino",
"390362", "Seregno",
"390933", "Caltagirone",
"390968", "Lamezia\ Terme",
"390424", "Bassano\ del\ Grappa",
"390345", "San\ Pellegrino\ Terme",
"390785", "Macomer",
"390731", "Jesi",
"390588", "Volterra",
"390174", "Mondovì",
"390166", "Saint\-Vincent",
"390426", "Adria",
"390935", "Enna",
"390571", "Empoli",
"390981", "Castrovillari",
"390343", "Chiavenna",
"390431", "Cervignano\ del\ Friuli",
"390882", "San\ Severo",
"390871", "Chieti",
"390972", "Melfi",
"3906", "Roma",
"390861", "Teramo",
"390828", "Battipaglia",
"390737", "Camerino",
"390173", "Alba",
"390163", "Borgosesia",
"390346", "Clusone",
"390934", "Caltanissetta",
"390423", "Montebelluna",
"390344", "Menaggio",
"390784", "Nuoro",
"390921", "Cefalù",
"390175", "Saluzzo",
"390142", "Casale\ Monferrato",
"390165", "Aosta",
"390522", "Reggio\ nell\'Emilia",
"390437", "Belluno",
"390746", "Rieti",
"39055", "Firenze",
"390386", "Ostiglia",
"390864", "Sulmona",
"390721", "Pesaro",
"390984", "Cosenza",
"390434", "Pordenone",
"390736", "Ascoli\ Piceno",
"390923", "Trapani",
"39081", "Napoli",
"390564", "Grosseto",
"390421", "San\ Donà\ di\ Piave",
"390925", "Sciacca",
"390436", "Cortina\ d\'Ampezzo",
"390566", "Follonica",
"390744", "Terni",
"390323", "Baveno",
"390384", "Mortara",
"390549", "Repubblica\ di\ San\ Marino",
"390182", "Albenga",
"39019", "Savona",};
my $timezones = {
               '' => [
                       'Europe/Rome',
                       'Europe/Vatican'
                     ],
               '0' => [
                        'Europe/Rome'
                      ],
               '06698' => [
                            'Europe/Vatican'
                          ],
               '0878' => [
                           'Europe/Rome',
                           'Europe/Vatican'
                         ],
               '1' => [
                        'Europe/Rome',
                        'Europe/Vatican'
                      ],
               '3' => [
                        'Europe/Rome',
                        'Europe/Vatican'
                      ],
               '4' => [
                        'Europe/Rome'
                      ],
               '5' => [
                        'Europe/Rome',
                        'Europe/Vatican'
                      ],
               '7' => [
                        'Europe/Rome'
                      ],
               '8' => [
                        'Europe/Rome',
                        'Europe/Vatican'
                      ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ country_code => '39', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;