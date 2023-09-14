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
package Number::Phone::StubCountry::IT;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230903131447;

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
            [378]
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
          3[1-9]\\d{8}|
          3[2-9]\\d{7}
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
$areanames{en} = {"390363", "Bergamo",
"390371", "Lodi",
"390862", "L\'Aquila",
"390925", "Agrigento",
"39079", "Sassari",
"39033", "Varese",
"39070", "Cagliari",
"390921", "Palermo",
"3906698", "Vatican\ City",
"3906", "Rome",
"390974", "Salerno",
"390373", "Cremona",
"390187", "La\ Spezia",
"39045", "Verona",
"390324", "Verbano\-Cusio\-Ossola",
"390365", "Brescia",
"390962", "Crotone",
"390523", "Piacenza",
"390825", "Avellino",
"390444", "Vicenza",
"39039", "Monza",
"390185", "Genoa",
"390574", "Prato",
"39030", "Brescia",
"390521", "Parma",
"390874", "Campobasso",
"390183", "Imperia",
"390141", "Asti",
"390322", "Novara",
"390823", "Caserta",
"39011", "Turin",
"390882", "Foggia",
"39085", "Pescara",
"39031", "Como",
"390341", "Lecco",
"390122", "Turin",
"39010", "Genoa",
"390933", "Caltanissetta",
"390732", "Ancona",
"390343", "Sondrio",
"39055", "Florence",
"390884", "Foggia",
"390783", "Oristano",
"390161", "Vercelli",
"39048", "Gorizia",
"39095", "Catania",
"390165", "Aosta\ Valley",
"39071", "Ancona",
"390423", "Treviso",
"390586", "Livorno",
"390425", "Rovigo",
"390171", "Cuneo",
"39013", "Alessandria",
"390734", "Fermo",
"390942", "Catania",
"390549", "San\ Marino",
"390421", "Venice",
"39015", "Biella",
"39050", "Pisa",
"39059", "Modena",
"390961", "Catanzaro",
"390924", "Trapani",
"390965", "Reggio\ Calabria",
"390963", "Vibo\ Valentia",
"390364", "Brescia",
"390376", "Mantua",
"390522", "Reggio\ Emilia",
"390975", "Potenza",
"390577", "Siena",
"390432", "Udine",
"39089", "Salerno",
"390321", "Novara",
"39080", "Bari",
"390372", "Cremona",
"390445", "Vicenza",
"390774", "Rome",
"390575", "Arezzo",
"390922", "Agrigento",
"390824", "Benevento",
"39041", "Venice",
"390865", "Isernia",
"390362", "Cremona\/Monza",
"390565", "Livorno",
"390776", "Frosinone",
"39099", "Taranto",
"39090", "Messina",
"390934", "Caltanissetta\ and\ Enna",
"390832", "Lecce",
"39049", "Padova",
"390737", "Macerata",
"390344", "Como",
"39040", "Trieste",
"39075", "Perugia",
"390532", "Ferrara",
"39091", "Palermo",
"390346", "Bergamo",
"390422", "Treviso",
"390471", "Bolzano\/Bozen",
"390125", "Turin",
"390541", "Rimini",
"3902", "Milan",
"39051", "Bologna",
"390881", "Foggia",
"390789", "Sassari",
"390545", "Ravenna",
"390342", "Sondrio",
"390426", "Rovigo",
"390733", "Macerata",
"390583", "Lucca",
"390883", "Andria\ Barletta\ Trani",
"390585", "Massa\-Carrara",
"390382", "Pavia",
"390166", "Aosta\ Valley",
"39035", "Bergamo",
"390461", "Trento",
"390543", "Forlì\-Cesena",
"390735", "Ascoli\ Piceno",
"390424", "Vicenza",
"39081", "Naples",
"390731", "Ancona",};
$areanames{it} = {"390975", "Sala\ Consilina",
"390376", "Mantova",
"390364", "Breno",
"390182", "Albenga",
"390721", "Pesaro",
"390434", "Pordenone",
"390578", "Chianciano\ Terme",
"390967", "Soverato",
"390871", "Chieti",
"390362", "Seregno",
"39041", "Venezia",
"390445", "Schio",
"390184", "Sanremo",
"390774", "Tivoli",
"390873", "Vasto",
"390766", "Civitavecchia",
"390439", "Feltre",
"390331", "Busto\ Arsizio",
"390346", "Clusone",
"390384", "Mortara",
"390983", "Rossano",
"390587", "Pontedera",
"390934", "Caltanissetta",
"390742", "Foligno",
"390981", "Castrovillari",
"390836", "Maglie",
"390735", "San\ Benedetto\ del\ Tronto",
"390534", "Porretta\ Terme",
"390885", "Cerignola",
"390932", "Ragusa",
"390545", "Lugo",
"390744", "Terni",
"390426", "Adria",
"390125", "Ivrea",
"390463", "Cles",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390722", "Urbino",
"390872", "Lanciano",
"3906", "Roma",
"390375", "Casalmaggiore",
"390437", "Belluno",
"390925", "Sciacca",
"390976", "Muro\ Lucano",
"390363", "Treviglio",
"390964", "Locri",
"39011", "Torino",
"390431", "Cervignano\ del\ Friuli",
"390564", "Grosseto",
"390765", "Poggio\ Mirteto",
"390525", "Fornovo\ di\ Taro",
"390773", "Latina",
"390433", "Tolmezzo",
"390771", "Formia",
"39019", "Savona",
"390933", "Caltagirone",
"39055", "Firenze",
"390381", "Vigevano",
"390462", "Cavalese",
"390931", "Siracusa",
"390345", "San\ Pellegrino\ Terme",
"390984", "Cosenza",
"390383", "Voghera",
"390785", "Macomer",
"390175", "Saluzzo",
"390584", "Viareggio",
"390743", "Spoleto",
"390332", "Varese",
"390163", "Borgosesia",
"390546", "Faenza",
"390464", "Rovereto",
"390736", "Ascoli\ Piceno",
"390428", "Tarvisio",
"390835", "Matera",
"390533", "Comacchio",
"390982", "Paola",
"390142", "Casale\ Monferrato",
"390968", "Lamezia\ Terme",
"390522", "Reggio\ nell\'Emilia",
"390971", "Potenza",
"390965", "Reggio\ di\ Calabria",
"390323", "Baveno",
"390924", "Alcamo",
"390374", "Soresina",
"390973", "Lagonegro",
"390144", "Acqui\ Terme",
"390573", "Pistoia",
"390875", "Termoli",
"390524", "Fidenza",
"390776", "Cassino",
"390565", "Piombino",
"390863", "Avezzano",
"390571", "Empoli",
"390436", "Cortina\ d\'Ampezzo",
"390861", "Teramo",
"390941", "Patti",
"390547", "Cesena",
"390172", "Savigliano",
"390782", "Lanusei",
"390985", "Scalea",
"390737", "Camerino",
"390344", "Menaggio",
"390386", "Ostiglia",
"390123", "Lanzo\ Torinese",
"390731", "Jesi",
"390465", "Tione\ di\ Trento",
"390746", "Rieti",
"390424", "Bassano\ del\ Grappa",
"39081", "Napoli",
"390166", "Saint\-Vincent",
"390543", "Forlì",
"390473", "Merano",
"390784", "Nuoro",
"390174", "Mondovì",
"390883", "Andria",
"390585", "Massa",
"390789", "Olbia",
"390121", "Pinerolo",
"3902", "Milano",
"390536", "Sassuolo",
"390471", "Bolzano",
"390429", "Este",
"390588", "Volterra",
"390365", "Salò",
"390923", "Trapani",
"390324", "Domodossola",
"390974", "Vallo\ della\ Lucania",
"390373", "Crema",
"390966", "Palmi",
"3906698", "Città\ del\ Vaticano",
"390921", "Cefalù",
"390442", "Legnago",
"390572", "Montecatini\ Terme",
"390322", "Arona",
"390972", "Melfi",
"390761", "Viterbo",
"390377", "Codogno",
"390828", "Battipaglia",
"390435", "Pieve\ di\ Cadore",
"390143", "Novi\ Ligure",
"390566", "Follonica",
"390775", "Frosinone",
"390185", "Rapallo",
"390438", "Conegliano",
"390763", "Orvieto",
"390864", "Sulmona",
"390385", "Stradella",
"39010", "Genova",
"390732", "Fabriano",
"390343", "Chiavenna",
"390122", "Susa",
"390427", "Spilimbergo",
"390542", "Imola",
"390935", "Enna",
"390472", "Bressanone",
"390882", "San\ Severo",
"390549", "Repubblica\ di\ San\ Marino",
"390421", "San\ Donà\ di\ Piave",
"390833", "Gallipoli",
"390942", "Taormina",
"390535", "Mirandola",
"390781", "Iglesias",
"390831", "Brindisi",
"390124", "Rivarolo\ Canavese",
"390165", "Aosta",
"390423", "Montebelluna",
"390544", "Ravenna",
"390474", "Brunico",
"390884", "Manfredonia",
"390173", "Alba",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ country_code => '39', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;