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
package Number::Phone::StubCountry::IT;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220601185318;

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
            [38]
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
$areanames{it} = {"39041", "Venezia",
"390345", "San\ Pellegrino\ Terme",
"390185", "Rapallo",
"390883", "Andria",
"390964", "Locri",
"390322", "Arona",
"39081", "Napoli",
"390462", "Cavalese",
"39055", "Firenze",
"390421", "San\ Donà\ di\ Piave",
"390346", "Clusone",
"39010", "Genova",
"390731", "Jesi",
"390982", "Paola",
"390471", "Bolzano",
"390565", "Piombino",
"390884", "Manfredonia",
"390566", "Follonica",
"390785", "Macomer",
"390871", "Chieti",
"390975", "Sala\ Consilina",
"390386", "Ostiglia",
"390331", "Busto\ Arsizio",
"390573", "Pistoia",
"390934", "Caltanissetta",
"390524", "Fidenza",
"390122", "Susa",
"390976", "Muro\ Lucano",
"390385", "Stradella",
"390172", "Savigliano",
"390933", "Caltagirone",
"390761", "Viterbo",
"390722", "Urbino",
"390535", "Mirandola",
"390536", "Sassuolo",
"390925", "Sciacca",
"390746", "Rieti",
"390942", "Taormina",
"390924", "Alcamo",
"390143", "Novi\ Ligure",
"390362", "Seregno",
"390383", "Voghera",
"390861", "Teramo",
"390534", "Porretta\ Terme",
"390973", "Lagonegro",
"390744", "Terni",
"390445", "Schio",
"390923", "Trapani",
"390542", "Imola",
"390144", "Acqui\ Terme",
"390384", "Mortara",
"390472", "Bressanone",
"390732", "Fabriano",
"390981", "Castrovillari",
"390525", "Fornovo\ di\ Taro",
"390743", "Spoleto",
"390872", "Lanciano",
"390935", "Enna",
"390968", "Lamezia\ Terme",
"390533", "Comacchio",
"390974", "Vallo\ della\ Lucania",
"390967", "Soverato",
"39011", "Torino",
"390784", "Nuoro",
"390332", "Varese",
"390831", "Brindisi",
"390789", "Olbia",
"390564", "Grosseto",
"390343", "Chiavenna",
"390771", "Formia",
"390885", "Cerignola",
"390431", "Cervignano\ del\ Friuli",
"390578", "Chianciano\ Terme",
"390121", "Pinerolo",
"390721", "Pesaro",
"390966", "Palmi",
"390965", "Reggio\ di\ Calabria",
"390941", "Patti",
"390344", "Menaggio",
"3906698", "Città\ del\ Vaticano",
"390184", "Sanremo",
"390163", "Borgosesia",
"390182", "Albenga",
"390584", "Viareggio",
"390437", "Belluno",
"390438", "Conegliano",
"390571", "Empoli",
"390465", "Tione\ di\ Trento",
"390376", "Mantova",
"390985", "Scalea",
"390375", "Casalmaggiore",
"390763", "Orvieto",
"390931", "Siracusa",
"390782", "Lanusei",
"390436", "Cortina\ d\'Ampezzo",
"390776", "Cassino",
"390972", "Melfi",
"390835", "Matera",
"390423", "Montebelluna",
"390544", "Ravenna",
"390142", "Casale\ Monferrato",
"390836", "Maglie",
"390775", "Frosinone",
"390363", "Treviglio",
"390474", "Brunico",
"390549", "Repubblica\ di\ San\ Marino",
"3906", "Roma",
"390125", "Ivrea",
"390435", "Pieve\ di\ Cadore",
"390424", "Bassano\ del\ Grappa",
"390742", "Foligno",
"390873", "Vasto",
"390175", "Saluzzo",
"390429", "Este",
"390543", "Forlì",
"390377", "Codogno",
"390364", "Breno",
"390473", "Merano",
"390773", "Latina",
"390365", "Salò",
"390426", "Adria",
"390123", "Lanzo\ Torinese",
"390433", "Tolmezzo",
"390572", "Montecatini\ Terme",
"390174", "Mondovì",
"390442", "Legnago",
"390833", "Gallipoli",
"390124", "Rivarolo\ Canavese",
"390522", "Reggio\ nell\'Emilia",
"390735", "San\ Benedetto\ del\ Tronto",
"390434", "Pordenone",
"390774", "Tivoli",
"390545", "Lugo",
"390439", "Feltre",
"390546", "Faenza",
"390588", "Volterra",
"390736", "Ascoli\ Piceno",
"390173", "Alba",
"390932", "Ragusa",
"390875", "Termoli",
"390781", "Iglesias",
"390587", "Pontedera",
"390166", "Saint\-Vincent",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390971", "Potenza",
"390374", "Soresina",
"390828", "Battipaglia",
"390463", "Cles",
"390323", "Baveno",
"390984", "Cosenza",
"390427", "Spilimbergo",
"39019", "Savona",
"390381", "Vigevano",
"390863", "Avezzano",
"390428", "Tarvisio",
"390165", "Aosta",
"390882", "San\ Severo",
"390547", "Cesena",
"390765", "Poggio\ Mirteto",
"390373", "Crema",
"390464", "Rovereto",
"390737", "Camerino",
"390864", "Sulmona",
"390921", "Cefalù",
"390585", "Massa",
"390766", "Civitavecchia",
"390324", "Domodossola",
"3902", "Milano",
"390983", "Rossano",};
$areanames{en} = {"390322", "Novara",
"390865", "Isernia",
"390342", "Sondrio",
"390185", "Genoa",
"390883", "Andria\ Barletta\ Trani",
"39089", "Salerno",
"39041", "Venice",
"390862", "L\'Aquila",
"39010", "Genoa",
"390421", "Venice",
"39055", "Florence",
"390346", "Bergamo",
"39081", "Naples",
"39049", "Padova",
"390541", "Rimini",
"390521", "Parma",
"39045", "Verona",
"390884", "Foggia",
"390471", "Bolzano\/Bozen",
"390565", "Livorno",
"390376", "Mantua",
"390731", "Ancona",
"39070", "Cagliari",
"39059", "Modena",
"390583", "Lucca",
"390963", "Vibo\ Valentia",
"39085", "Pescara",
"390372", "Cremona",
"39051", "Bologna",
"39090", "Messina",
"390187", "La\ Spezia",
"390423", "Treviso",
"390776", "Frosinone",
"390934", "Caltanissetta\ and\ Enna",
"39030", "Brescia",
"390874", "Campobasso",
"390832", "Lecce",
"390975", "Potenza",
"390161", "Vercelli",
"390823", "Caserta",
"390734", "Fermo",
"390549", "San\ Marino",
"3906", "Rome",
"390125", "Turin",
"390382", "Pavia",
"390432", "Udine",
"390122", "Turin",
"390363", "Bergamo",
"390881", "Foggia",
"390444", "Vicenza",
"390424", "Vicenza",
"390574", "Prato",
"390532", "Ferrara",
"390933", "Caltanissetta",
"390922", "Agrigento",
"390543", "Forlì\-Cesena",
"390523", "Piacenza",
"390942", "Catania",
"390364", "Brescia",
"390961", "Catanzaro",
"390824", "Benevento",
"390733", "Macerata",
"390925", "Agrigento",
"39039", "Monza",
"390924", "Trapani",
"390825", "Avellino",
"390362", "Cremona\/Monza",
"390426", "Rovigo",
"390321", "Novara",
"390341", "Lecco",
"390365", "Brescia",
"390445", "Vicenza",
"39031", "Como",
"390425", "Rovigo",
"390461", "Trento",
"390575", "Arezzo",
"390422", "Treviso",
"39013", "Alessandria",
"390774", "Rome",
"390732", "Ancona",
"390545", "Ravenna",
"390522", "Reggio\ Emilia",
"390735", "Ascoli\ Piceno",
"390974", "Salerno",
"390371", "Lodi",
"39035", "Bergamo",
"39080", "Bari",
"390789", "Sassari",
"39011", "Turin",
"39095", "Catania",
"390166", "Aosta\ Valley",
"390141", "Asti",
"390882", "Foggia",
"39040", "Trieste",
"390165", "Aosta\ Valley",
"390183", "Imperia",
"39075", "Perugia",
"390343", "Sondrio",
"390577", "Siena",
"390171", "Cuneo",
"39050", "Pisa",
"39091", "Palermo",
"39079", "Sassari",
"390586", "Livorno",
"390783", "Oristano",
"39015", "Biella",
"390737", "Macerata",
"390373", "Cremona",
"39071", "Ancona",
"3902", "Milan",
"3906698", "Vatican\ City",
"39099", "Taranto",
"390962", "Crotone",
"390324", "Verbano\-Cusio\-Ossola",
"390344", "Como",
"390921", "Palermo",
"39048", "Gorizia",
"390585", "Massa\-Carrara",
"39033", "Varese",
"390965", "Reggio\ Calabria",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;