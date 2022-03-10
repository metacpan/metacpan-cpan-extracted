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
our $VERSION = 1.20220307120119;

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
$areanames{en} = {"39081", "Naples",
"390882", "Foggia",
"390874", "Campobasso",
"390965", "Reggio\ Calabria",
"390532", "Ferrara",
"39041", "Venice",
"390565", "Livorno",
"390362", "Cremona\/Monza",
"390471", "Bolzano\/Bozen",
"39050", "Pisa",
"390862", "L\'Aquila",
"390382", "Pavia",
"390961", "Catanzaro",
"390346", "Bergamo",
"39033", "Varese",
"390171", "Cuneo",
"39031", "Como",
"39011", "Turin",
"390585", "Massa\-Carrara",
"390371", "Lodi",
"39013", "Alessandria",
"39090", "Messina",
"39079", "Sassari",
"390373", "Cremona",
"390963", "Vibo\ Valentia",
"3906", "Rome",
"390583", "Lucca",
"39049", "Padova",
"390737", "Macerata",
"39089", "Salerno",
"390543", "Forlì\-Cesena",
"39039", "Monza",
"390423", "Treviso",
"390733", "Macerata",
"390823", "Caserta",
"3906698", "Vatican\ City",
"390125", "Turin",
"390734", "Fermo",
"39055", "Florence",
"390824", "Benevento",
"390522", "Reggio\ Emilia",
"390731", "Ancona",
"39071", "Ancona",
"390421", "Venice",
"390424", "Vicenza",
"390545", "Ravenna",
"39095", "Catania",
"390774", "Rome",
"390922", "Agrigento",
"390342", "Sondrio",
"390425", "Rovigo",
"390541", "Rimini",
"390324", "Verbano\-Cusio\-Ossola",
"390321", "Novara",
"390825", "Avellino",
"390735", "Ascoli\ Piceno",
"390166", "Aosta\ Valley",
"390549", "San\ Marino",
"390523", "Piacenza",
"390343", "Sondrio",
"390783", "Oristano",
"39059", "Modena",
"39099", "Taranto",
"39070", "Cagliari",
"390322", "Novara",
"39035", "Bergamo",
"390942", "Catania",
"390444", "Vicenza",
"39015", "Biella",
"390122", "Turin",
"390925", "Agrigento",
"390586", "Livorno",
"390141", "Asti",
"390422", "Treviso",
"39045", "Verona",
"390376", "Mantua",
"390921", "Palermo",
"390924", "Trapani",
"390344", "Como",
"390341", "Lecco",
"39085", "Pescara",
"390445", "Vicenza",
"390789", "Sassari",
"390521", "Parma",
"390732", "Ancona",
"390575", "Arezzo",
"390962", "Crotone",
"39040", "Trieste",
"390776", "Frosinone",
"390372", "Cremona",
"390426", "Rovigo",
"390461", "Trento",
"390365", "Brescia",
"39080", "Bari",
"390165", "Aosta\ Valley",
"390975", "Potenza",
"390974", "Salerno",
"39030", "Brescia",
"39075", "Perugia",
"390832", "Lecce",
"390865", "Isernia",
"390161", "Vercelli",
"390364", "Brescia",
"39091", "Palermo",
"39010", "Genoa",
"39051", "Bologna",
"390185", "Genoa",
"390432", "Udine",
"390884", "Foggia",
"39048", "Gorizia",
"390881", "Foggia",
"390934", "Caltanissetta\ and\ Enna",
"390574", "Prato",
"390933", "Caltanissetta",
"390883", "Andria\ Barletta\ Trani",
"390187", "La\ Spezia",
"390363", "Bergamo",
"390183", "Imperia",
"3902", "Milan",
"390577", "Siena",};
$areanames{it} = {"390743", "Spoleto",
"390573", "Pistoia",
"390533", "Comacchio",
"390364", "Breno",
"390982", "Paola",
"390472", "Bressanone",
"39010", "Genova",
"390974", "Vallo\ della\ Lucania",
"390722", "Urbino",
"390872", "Lanciano",
"390571", "Empoli",
"390934", "Caltanissetta",
"390884", "Manfredonia",
"390464", "Rovereto",
"390184", "Sanremo",
"390384", "Mortara",
"390172", "Savigliano",
"390864", "Sulmona",
"390535", "Mirandola",
"390332", "Varese",
"390921", "Cefalù",
"390966", "Palmi",
"390344", "Menaggio",
"390781", "Iglesias",
"390144", "Acqui\ Terme",
"390376", "Mantova",
"390765", "Poggio\ Mirteto",
"390524", "Fidenza",
"390789", "Olbia",
"390761", "Viterbo",
"390836", "Maglie",
"390942", "Taormina",
"390785", "Macomer",
"390436", "Cortina\ d\'Ampezzo",
"390925", "Sciacca",
"390763", "Orvieto",
"390923", "Trapani",
"390775", "Frosinone",
"390166", "Saint\-Vincent",
"390735", "San\ Benedetto\ del\ Tronto",
"390442", "Legnago",
"390976", "Muro\ Lucano",
"390549", "Repubblica\ di\ San\ Marino",
"390121", "Pinerolo",
"390429", "Este",
"390125", "Ivrea",
"390731", "Jesi",
"390522", "Reggio\ nell\'Emilia",
"390771", "Formia",
"390386", "Ostiglia",
"390142", "Casale\ Monferrato",
"390545", "Lugo",
"390421", "San\ Donà\ di\ Piave",
"390423", "Montebelluna",
"39019", "Savona",
"390773", "Latina",
"390323", "Baveno",
"390123", "Lanzo\ Torinese",
"390543", "Forlì",
"390968", "Lamezia\ Terme",
"390377", "Codogno",
"390967", "Soverato",
"390437", "Belluno",
"390438", "Conegliano",
"390374", "Soresina",
"390585", "Massa",
"390462", "Cavalese",
"390182", "Albenga",
"390346", "Clusone",
"390964", "Locri",
"390174", "Mondovì",
"390932", "Ragusa",
"390434", "Pordenone",
"390882", "San\ Severo",
"390362", "Seregno",
"390984", "Cosenza",
"390474", "Brunico",
"390972", "Melfi",
"390565", "Piombino",
"390863", "Avezzano",
"390578", "Chianciano\ Terme",
"390383", "Voghera",
"390463", "Cles",
"3902", "Milano",
"390883", "Andria",
"390933", "Caltagirone",
"390163", "Borgosesia",
"390973", "Lagonegro",
"390363", "Treviglio",
"390534", "Porretta\ Terme",
"390971", "Potenza",
"390931", "Siracusa",
"390385", "Stradella",
"390465", "Tione\ di\ Trento",
"390185", "Rapallo",
"390546", "Faenza",
"390885", "Cerignola",
"390426", "Adria",
"390744", "Terni",
"390935", "Enna",
"390381", "Vigevano",
"390776", "Cassino",
"390165", "Aosta",
"390736", "Ascoli\ Piceno",
"390975", "Sala\ Consilina",
"390861", "Teramo",
"390365", "Salò",
"390924", "Alcamo",
"390784", "Nuoro",
"390566", "Follonica",
"390732", "Fabriano",
"390445", "Schio",
"390525", "Fornovo\ di\ Taro",
"390122", "Susa",
"390322", "Arona",
"390542", "Imola",
"390345", "San\ Pellegrino\ Terme",
"390143", "Novi\ Ligure",
"390343", "Chiavenna",
"390544", "Ravenna",
"390124", "Rivarolo\ Canavese",
"390536", "Sassuolo",
"390324", "Domodossola",
"390941", "Patti",
"39055", "Firenze",
"390774", "Tivoli",
"390782", "Lanusei",
"390746", "Rieti",
"390424", "Bassano\ del\ Grappa",
"390547", "Cesena",
"3906698", "Città\ del\ Vaticano",
"390428", "Tarvisio",
"390737", "Camerino",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390828", "Battipaglia",
"390427", "Spilimbergo",
"390833", "Gallipoli",
"3906", "Roma",
"390473", "Merano",
"390983", "Rossano",
"390433", "Tolmezzo",
"390873", "Vasto",
"390173", "Alba",
"390587", "Pontedera",
"390373", "Crema",
"390588", "Volterra",
"390564", "Grosseto",
"390835", "Matera",
"390985", "Scalea",
"390331", "Busto\ Arsizio",
"39011", "Torino",
"390435", "Pieve\ di\ Cadore",
"390742", "Foligno",
"390875", "Termoli",
"390175", "Saluzzo",
"390871", "Chieti",
"390965", "Reggio\ di\ Calabria",
"390572", "Montecatini\ Terme",
"390431", "Cervignano\ del\ Friuli",
"39081", "Napoli",
"390584", "Viareggio",
"390375", "Casalmaggiore",
"390981", "Castrovillari",
"390471", "Bolzano",
"390831", "Brindisi",
"39041", "Venezia",
"390721", "Pesaro",
"390766", "Civitavecchia",
"390439", "Feltre",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;