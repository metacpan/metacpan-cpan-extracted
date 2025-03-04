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
package Number::Phone::StubCountry::IT;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20241212130805;

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
                  'leading_digits' => '3',
                  'pattern' => '(\\d{3})(\\d{4})(\\d{4,5})'
                }
              ];

my $validators = {
                'fixed_line' => '
          0669[0-79]\\d{1,6}|
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
              3[1-356]|
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
          0669[0-79]\\d{1,6}|
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
              3[1-356]|
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
$areanames{en} = {"390543", "Forlì\-Cesena",
"390376", "Mantua",
"39085", "Pescara",
"390424", "Vicenza",
"390532", "Ferrara",
"390962", "Crotone",
"390735", "Ascoli\ Piceno",
"39039", "Monza",
"390583", "Lucca",
"390541", "Rimini",
"390874", "Campobasso",
"390432", "Udine",
"390925", "Agrigento",
"390865", "Isernia",
"390141", "Asti",
"390183", "Imperia",
"390731", "Ancona",
"390545", "Ravenna",
"390324", "Verbano\-Cusio\-Ossola",
"390789", "Sassari",
"390585", "Massa\-Carrara",
"39049", "Padova",
"390733", "Macerata",
"39071", "Ancona",
"390372", "Cremona",
"39059", "Modena",
"390341", "Lecco",
"390921", "Palermo",
"390343", "Sondrio",
"390185", "Genoa",
"390445", "Vicenza",
"39070", "Cagliari",
"390577", "Siena",
"3902", "Milan",
"390924", "Trapani",
"39075", "Perugia",
"39048", "Gorizia",
"390344", "Como",
"390321", "Novara",
"390125", "Turin",
"390425", "Rovigo",
"390774", "Rome",
"390734", "Fermo",
"39099", "Taranto",
"390523", "Piacenza",
"390362", "Cremona\/Monza",
"390882", "Foggia",
"390444", "Vicenza",
"390521", "Parma",
"39080", "Bari",
"390421", "Venice",
"390423", "Treviso",
"390166", "Aosta\ Valley",
"39081", "Naples",
"390187", "La\ Spezia",
"39035", "Bergamo",
"390942", "Catania",
"390322", "Novara",
"39089", "Salerno",
"390933", "Caltanissetta",
"39091", "Palermo",
"39013", "Alessandria",
"390365", "Brescia",
"390161", "Vercelli",
"3906698", "Vatican\ City",
"390461", "Trento",
"390426", "Rovigo",
"39090", "Messina",
"390122", "Turin",
"39045", "Verona",
"390574", "Prato",
"390824", "Benevento",
"390422", "Treviso",
"39015", "Biella",
"390565", "Livorno",
"390975", "Potenza",
"390832", "Lecce",
"390522", "Reggio\ Emilia",
"390737", "Macerata",
"390363", "Bergamo",
"390883", "Andria\ Barletta\ Trani",
"390881", "Foggia",
"390165", "Aosta\ Valley",
"39033", "Varese",
"39055", "Florence",
"39079", "Sassari",
"390171", "Cuneo",
"390364", "Brescia",
"390884", "Foggia",
"39051", "Bologna",
"39050", "Pisa",
"390471", "Bolzano\/Bozen",
"390776", "Frosinone",
"39040", "Trieste",
"39011", "Turin",
"390961", "Catanzaro",
"390549", "San\ Marino",
"390823", "Caserta",
"390346", "Bergamo",
"390963", "Vibo\ Valentia",
"39041", "Venice",
"39010", "Genoa",
"390373", "Cremona",
"390862", "L\'Aquila",
"390382", "Pavia",
"390922", "Agrigento",
"39095", "Catania",
"390342", "Sondrio",
"390371", "Lodi",
"390586", "Livorno",
"39030", "Brescia",
"3906", "Rome",
"390965", "Reggio\ Calabria",
"390575", "Arezzo",
"390825", "Avellino",
"390783", "Oristano",
"390974", "Salerno",
"390934", "Caltanissetta\ and\ Enna",
"39031", "Como",
"390732", "Ancona",};
$areanames{it} = {"390383", "Voghera",
"390863", "Avezzano",
"390921", "Cefalù",
"390966", "Palmi",
"390343", "Chiavenna",
"390731", "Jesi",
"390436", "Cortina\ d\'Ampezzo",
"390771", "Formia",
"390545", "Lugo",
"390742", "Foligno",
"390984", "Cosenza",
"390782", "Lanusei",
"390789", "Olbia",
"390585", "Massa",
"390524", "Fidenza",
"390925", "Sciacca",
"390143", "Novi\ Ligure",
"390376", "Mantova",
"390572", "Montecatini\ Terme",
"390735", "San\ Benedetto\ del\ Tronto",
"390775", "Frosinone",
"390544", "Ravenna",
"390123", "Lanzo\ Torinese",
"390985", "Scalea",
"390423", "Montebelluna",
"390763", "Orvieto",
"390584", "Viareggio",
"390362", "Seregno",
"390882", "San\ Severo",
"390871", "Chieti",
"390566", "Follonica",
"390831", "Brindisi",
"390981", "Castrovillari",
"390588", "Volterra",
"390941", "Patti",
"390323", "Baveno",
"390774", "Tivoli",
"390972", "Melfi",
"390932", "Ragusa",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390875", "Termoli",
"390525", "Fornovo\ di\ Taro",
"390835", "Matera",
"3902", "Milano",
"390924", "Alcamo",
"390462", "Cavalese",
"390722", "Urbino",
"390434", "Pordenone",
"390474", "Brunico",
"390363", "Treviglio",
"390883", "Andria",
"390174", "Mondovì",
"390122", "Susa",
"390964", "Locri",
"390429", "Este",
"390565", "Piombino",
"390374", "Soresina",
"390438", "Conegliano",
"390463", "Cles",
"390163", "Borgosesia",
"390836", "Maglie",
"390322", "Arona",
"390968", "Lamezia\ Terme",
"390973", "Lagonegro",
"390933", "Caltagirone",
"3906", "Roma",
"390743", "Spoleto",
"390965", "Reggio\ di\ Calabria",
"390564", "Grosseto",
"390427", "Spilimbergo",
"390435", "Pieve\ di\ Cadore",
"390546", "Faenza",
"390331", "Busto\ Arsizio",
"390175", "Saluzzo",
"390573", "Pistoia",
"390533", "Comacchio",
"390375", "Casalmaggiore",
"390142", "Casale\ Monferrato",
"390442", "Legnago",
"390182", "Albenga",
"390736", "Ascoli\ Piceno",
"390471", "Bolzano",
"390431", "Cervignano\ del\ Friuli",
"390776", "Cassino",
"390332", "Varese",
"390923", "Trapani",
"390536", "Sassuolo",
"390861", "Teramo",
"390381", "Vigevano",
"390185", "Rapallo",
"390445", "Schio",
"39019", "Savona",
"390324", "Domodossola",
"390428", "Tarvisio",
"390773", "Latina",
"390472", "Bressanone",
"390439", "Feltre",
"390385", "Stradella",
"390746", "Rieti",
"390345", "San\ Pellegrino\ Terme",
"390172", "Savigliano",
"390543", "Forlì",
"390124", "Rivarolo\ Canavese",
"390424", "Bassano\ del\ Grappa",
"390761", "Viterbo",
"390421", "San\ Donà\ di\ Piave",
"390377", "Codogno",
"390166", "Saint\-Vincent",
"390121", "Pinerolo",
"39081", "Napoli",
"390833", "Gallipoli",
"390873", "Vasto",
"390144", "Acqui\ Terme",
"390184", "Sanremo",
"390976", "Muro\ Lucano",
"390125", "Ivrea",
"390765", "Poggio\ Mirteto",
"390437", "Belluno",
"390983", "Rossano",
"390967", "Soverato",
"390864", "Sulmona",
"390384", "Mortara",
"390344", "Menaggio",
"390522", "Reggio\ nell\'Emilia",
"390872", "Lanciano",
"390465", "Tione\ di\ Trento",
"390737", "Camerino",
"390165", "Aosta",
"39055", "Firenze",
"390534", "Porretta\ Terme",
"390935", "Enna",
"390975", "Sala\ Consilina",
"390885", "Cerignola",
"390365", "Salò",
"390587", "Pontedera",
"3906698", "Città\ del\ Vaticano",
"390766", "Civitavecchia",
"390721", "Pesaro",
"390426", "Adria",
"390547", "Cesena",
"390931", "Siracusa",
"390971", "Potenza",
"390942", "Taormina",
"390744", "Terni",
"390784", "Nuoro",
"390982", "Paola",
"390578", "Chianciano\ Terme",
"390828", "Battipaglia",
"390781", "Iglesias",
"390535", "Mirandola",
"390974", "Vallo\ della\ Lucania",
"390934", "Caltanissetta",
"390732", "Fabriano",
"390373", "Crema",
"390464", "Rovereto",
"39011", "Torino",
"390542", "Imola",
"390386", "Ostiglia",
"390571", "Empoli",
"390549", "Repubblica\ di\ San\ Marino",
"390785", "Macomer",
"390346", "Clusone",
"39010", "Genova",
"39041", "Venezia",
"390433", "Tolmezzo",
"390473", "Merano",
"390364", "Breno",
"390884", "Manfredonia",
"390173", "Alba",};
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