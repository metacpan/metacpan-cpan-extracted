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
our $VERSION = 1.20210602223300;

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
            1[4679]|
            [38]
          ',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '0[13-57-9][0159]',
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
            0878\\d\\d|
            89(?:
              2|
              4[5-9]\\d
            )
          )\\d{3}|
          89[45][0-4]\\d\\d|
          (?:
            1(?:
              44|
              6[346]
            )|
            89(?:
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
$areanames{en} = {"390774", "Rome",
"390373", "Cremona",
"390185", "Genoa",
"390776", "Frosinone",
"39033", "Varese",
"39089", "Salerno",
"390549", "San\ Marino",
"390974", "Salerno",
"390187", "La\ Spezia",
"390825", "Avellino",
"39085", "Pescara",
"390372", "Cremona",
"390823", "Caserta",
"390382", "Pavia",
"390471", "Bolzano\/Bozen",
"390574", "Prato",
"39081", "Naples",
"390586", "Livorno",
"39013", "Alessandria",
"390183", "Imperia",
"390583", "Lucca",
"390975", "Potenza",
"390824", "Benevento",
"390371", "Lodi",
"390577", "Siena",
"390865", "Isernia",
"390376", "Mantua",
"390832", "Lecce",
"390171", "Cuneo",
"390783", "Oristano",
"390862", "L\'Aquila",
"390585", "Massa\-Carrara",
"390575", "Arezzo",
"39080", "Bari",
"3906698", "Vatican\ City",
"39015", "Biella",
"390541", "Rimini",
"390125", "Turin",
"390565", "Livorno",
"390882", "Foggia",
"390733", "Macerata",
"39031", "Como",
"390444", "Vicenza",
"390963", "Vibo\ Valentia",
"390532", "Ferrara",
"39048", "Gorizia",
"390364", "Brescia",
"390343", "Sondrio",
"390161", "Vercelli",
"390521", "Parma",
"390426", "Rovigo",
"39050", "Pisa",
"390924", "Trapani",
"390122", "Turin",
"390933", "Caltanissetta",
"390424", "Vicenza",
"390732", "Ancona",
"390883", "Andria\ Barletta\ Trani",
"390421", "Venice",
"390737", "Macerata",
"390322", "Novara",
"390921", "Palermo",
"39040", "Trieste",
"390962", "Crotone",
"390789", "Sassari",
"39039", "Monza",
"39090", "Messina",
"3902", "Milan",
"390166", "Aosta\ Valley",
"39070", "Cagliari",
"390342", "Sondrio",
"39011", "Turin",
"390965", "Reggio\ Calabria",
"390735", "Ascoli\ Piceno",
"39035", "Bergamo",
"390432", "Udine",
"3906", "Rome",
"390523", "Piacenza",
"390365", "Brescia",
"39079", "Sassari",
"390942", "Catania",
"390341", "Lecco",
"390884", "Foggia",
"390874", "Campobasso",
"39045", "Verona",
"39051", "Bologna",
"390925", "Agrigento",
"39095", "Catania",
"390425", "Rovigo",
"390422", "Treviso",
"390731", "Ancona",
"390922", "Agrigento",
"390321", "Novara",
"39075", "Perugia",
"390543", "Forlì\-Cesena",
"390445", "Vicenza",
"390362", "Cremona\/Monza",
"390961", "Catanzaro",
"39049", "Padova",
"390461", "Trento",
"39030", "Brescia",
"39099", "Taranto",
"390522", "Reggio\ Emilia",
"39010", "Genoa",
"39071", "Ancona",
"390324", "Verbano\-Cusio\-Ossola",
"390734", "Fermo",
"390545", "Ravenna",
"39059", "Modena",
"390934", "Caltanissetta\ and\ Enna",
"390423", "Treviso",
"390881", "Foggia",
"390165", "Aosta\ Valley",
"390346", "Bergamo",
"39091", "Palermo",
"390363", "Bergamo",
"390344", "Como",
"39055", "Florence",
"39041", "Venice",
"390141", "Asti",};
$areanames{it} = {"390124", "Rivarolo\ Canavese",
"390731", "Jesi",
"390543", "Forlì",
"390445", "Schio",
"390362", "Seregno",
"390365", "Salò",
"390534", "Porretta\ Terme",
"390442", "Legnago",
"390536", "Sassuolo",
"390144", "Acqui\ Terme",
"390931", "Siracusa",
"390884", "Manfredonia",
"390923", "Trapani",
"390871", "Chieti",
"390934", "Caltanissetta",
"390547", "Cesena",
"390346", "Clusone",
"390165", "Aosta",
"390344", "Menaggio",
"39055", "Firenze",
"39041", "Venezia",
"390743", "Spoleto",
"390464", "Rovereto",
"390121", "Pinerolo",
"390324", "Domodossola",
"390736", "Ascoli\ Piceno",
"390343", "Chiavenna",
"390744", "Terni",
"390746", "Rieti",
"390924", "Alcamo",
"390933", "Caltagirone",
"390565", "Piombino",
"390323", "Baveno",
"390463", "Cles",
"390941", "Patti",
"390965", "Reggio\ di\ Calabria",
"390544", "Ravenna",
"3906", "Roma",
"390331", "Busto\ Arsizio",
"390123", "Lanzo\ Torinese",
"390721", "Pesaro",
"390546", "Faenza",
"390435", "Pieve\ di\ Cadore",
"390737", "Camerino",
"390921", "Cefalù",
"390873", "Vasto",
"390883", "Andria",
"390143", "Novi\ Ligure",
"390765", "Poggio\ Mirteto",
"390533", "Comacchio",
"3902", "Milano",
"390524", "Fidenza",
"390785", "Macomer",
"390775", "Frosinone",
"390982", "Paola",
"390972", "Melfi",
"390863", "Avezzano",
"390975", "Sala\ Consilina",
"390985", "Scalea",
"390782", "Lanusei",
"390835", "Matera",
"390473", "Merano",
"390585", "Massa",
"390572", "Montecatini\ Terme",
"390549", "Repubblica\ di\ San\ Marino",
"390172", "Savigliano",
"390474", "Brunico",
"390182", "Albenga",
"390185", "Rapallo",
"390175", "Saluzzo",
"390861", "Teramo",
"390864", "Sulmona",
"390375", "Casalmaggiore",
"390385", "Stradella",
"390471", "Bolzano",
"39081", "Napoli",
"390427", "Spilimbergo",
"390566", "Follonica",
"390564", "Grosseto",
"390742", "Foligno",
"390761", "Viterbo",
"390163", "Borgosesia",
"390942", "Taormina",
"390332", "Varese",
"390722", "Urbino",
"390431", "Cervignano\ del\ Friuli",
"390925", "Sciacca",
"390423", "Montebelluna",
"390434", "Pordenone",
"390436", "Cortina\ d\'Ampezzo",
"390542", "Imola",
"390766", "Civitavecchia",
"390363", "Treviglio",
"390525", "Fornovo\ di\ Taro",
"390828", "Battipaglia",
"390522", "Reggio\ nell\'Emilia",
"390966", "Palmi",
"390964", "Locri",
"39010", "Genova",
"390545", "Lugo",
"390364", "Breno",
"39019", "Savona",
"390535", "Mirandola",
"390763", "Orvieto",
"390875", "Termoli",
"390885", "Cerignola",
"390426", "Adria",
"390424", "Bassano\ del\ Grappa",
"390433", "Tolmezzo",
"390122", "Susa",
"390125", "Ivrea",
"3906698", "Città\ del\ Vaticano",
"390588", "Volterra",
"390882", "San\ Severo",
"390578", "Chianciano\ Terme",
"390872", "Lanciano",
"390142", "Casale\ Monferrato",
"39011", "Torino",
"390465", "Tione\ di\ Trento",
"390735", "San\ Benedetto\ del\ Tronto",
"390437", "Belluno",
"390932", "Ragusa",
"390935", "Enna",
"390322", "Arona",
"390421", "San\ Donà\ di\ Piave",
"390732", "Fabriano",
"390967", "Soverato",
"390462", "Cavalese",
"390789", "Olbia",
"390345", "San\ Pellegrino\ Terme",
"390166", "Saint\-Vincent",
"390381", "Vigevano",
"390472", "Bressanone",
"390184", "Sanremo",
"390174", "Mondovì",
"390439", "Feltre",
"390438", "Conegliano",
"390573", "Pistoia",
"390968", "Lamezia\ Terme",
"390833", "Gallipoli",
"390973", "Lagonegro",
"390983", "Rossano",
"390587", "Pontedera",
"390386", "Ostiglia",
"390376", "Mantova",
"390374", "Soresina",
"390773", "Latina",
"390384", "Mortara",
"390571", "Empoli",
"390974", "Vallo\ della\ Lucania",
"390831", "Brindisi",
"390984", "Cosenza",
"390976", "Muro\ Lucano",
"390784", "Nuoro",
"390373", "Crema",
"390774", "Tivoli",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390383", "Voghera",
"390776", "Cassino",
"390428", "Tarvisio",
"390429", "Este",
"390771", "Formia",
"390173", "Alba",
"390781", "Iglesias",
"390377", "Codogno",
"390981", "Castrovillari",
"390971", "Potenza",
"390836", "Maglie",
"390584", "Viareggio",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;