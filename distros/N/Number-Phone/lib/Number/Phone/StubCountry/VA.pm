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
package Number::Phone::StubCountry::VA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250913135859;

my $formatters = [];

my $validators = {
                'fixed_line' => '06698\\d{1,6}',
                'geographic' => '06698\\d{1,6}',
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
$areanames{it} = {"390775", "Frosinone",
"390473", "Merano",
"3902", "Milano",
"390533", "Comacchio",
"390463", "Cles",
"390742", "Foligno",
"390765", "Poggio\ Mirteto",
"390438", "Conegliano",
"390578", "Chianciano\ Terme",
"390123", "Lanzo\ Torinese",
"390184", "Sanremo",
"390833", "Gallipoli",
"390543", "Forlì",
"390732", "Fabriano",
"390545", "Lugo",
"390835", "Matera",
"390982", "Paola",
"390572", "Montecatini\ Terme",
"390125", "Ivrea",
"390773", "Latina",
"390535", "Mirandola",
"390971", "Potenza",
"390465", "Tione\ di\ Trento",
"390763", "Orvieto",
"390442", "Legnago",
"390872", "Lanciano",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390771", "Formia",
"390524", "Fidenza",
"390973", "Lagonegro",
"390761", "Viterbo",
"390332", "Varese",
"390883", "Andria",
"390375", "Casalmaggiore",
"390365", "Salò",
"390782", "Lanusei",
"390144", "Acqui\ Terme",
"390885", "Cerignola",
"390373", "Crema",
"390363", "Treviglio",
"390932", "Ragusa",
"39010", "Genova",
"390121", "Pinerolo",
"390429", "Este",
"390471", "Bolzano",
"390585", "Massa",
"390975", "Sala\ Consilina",
"390965", "Reggio\ di\ Calabria",
"390942", "Taormina",
"390789", "Olbia",
"390584", "Viareggio",
"390974", "Vallo\ della\ Lucania",
"390964", "Locri",
"390428", "Tarvisio",
"390143", "Novi\ Ligure",
"3906698", "Città\ del\ Vaticano",
"390884", "Manfredonia",
"390376", "Mantova",
"390722", "Urbino",
"390374", "Soresina",
"390364", "Breno",
"390172", "Savigliano",
"390525", "Fornovo\ di\ Taro",
"390976", "Muro\ Lucano",
"390547", "Cesena",
"390966", "Palmi",
"390124", "Rivarolo\ Canavese",
"390776", "Cassino",
"390474", "Brunico",
"390534", "Porretta\ Terme",
"390766", "Civitavecchia",
"390377", "Codogno",
"390464", "Rovereto",
"390322", "Arona",
"39041", "Venezia",
"390544", "Ravenna",
"390836", "Maglie",
"390546", "Faenza",
"390967", "Soverato",
"390587", "Pontedera",
"390774", "Tivoli",
"390536", "Sassuolo",
"390439", "Feltre",
"390185", "Rapallo",
"390163", "Borgosesia",
"390173", "Alba",
"390423", "Montebelluna",
"390934", "Caltanissetta",
"390346", "Clusone",
"390737", "Camerino",
"390828", "Battipaglia",
"390437", "Belluno",
"390522", "Reggio\ nell\'Emilia",
"390921", "Cefalù",
"390784", "Nuoro",
"390344", "Menaggio",
"390165", "Aosta",
"390142", "Casale\ Monferrato",
"390175", "Saluzzo",
"390564", "Grosseto",
"390923", "Trapani",
"39081", "Napoli",
"390434", "Pordenone",
"390736", "Ascoli\ Piceno",
"390984", "Cosenza",
"390721", "Pesaro",
"390864", "Sulmona",
"390386", "Ostiglia",
"390746", "Rieti",
"39055", "Firenze",
"390384", "Mortara",
"390323", "Baveno",
"390744", "Terni",
"39019", "Savona",
"390182", "Albenga",
"390549", "Repubblica\ di\ San\ Marino",
"390566", "Follonica",
"390925", "Sciacca",
"390436", "Cortina\ d\'Ampezzo",
"390421", "San\ Donà\ di\ Piave",
"390735", "San\ Benedetto\ del\ Tronto",
"390924", "Alcamo",
"390433", "Tolmezzo",
"390781", "Iglesias",
"390573", "Pistoia",
"390983", "Rossano",
"390863", "Avezzano",
"390385", "Stradella",
"390873", "Vasto",
"390331", "Busto\ Arsizio",
"390122", "Susa",
"390472", "Bressanone",
"390427", "Spilimbergo",
"390941", "Patti",
"390383", "Voghera",
"390875", "Termoli",
"390445", "Schio",
"390324", "Domodossola",
"390462", "Cavalese",
"390743", "Spoleto",
"390542", "Imola",
"390565", "Piombino",
"390435", "Pieve\ di\ Cadore",
"390985", "Scalea",
"390931", "Siracusa",
"390588", "Volterra",
"390731", "Jesi",
"390785", "Macomer",
"390968", "Lamezia\ Terme",
"390345", "San\ Pellegrino\ Terme",
"390424", "Bassano\ del\ Grappa",
"390933", "Caltagirone",
"390362", "Seregno",
"390174", "Mondovì",
"390381", "Vigevano",
"39011", "Torino",
"390861", "Teramo",
"390972", "Melfi",
"3906", "Roma",
"390871", "Chieti",
"390166", "Saint\-Vincent",
"390882", "San\ Severo",
"390431", "Cervignano\ del\ Friuli",
"390343", "Chiavenna",
"390981", "Castrovillari",
"390571", "Empoli",
"390426", "Adria",
"390935", "Enna",};
$areanames{en} = {"39015", "Biella",
"39011", "Turin",
"39045", "Verona",
"39041", "Venice",
"390322", "Novara",
"390776", "Frosinone",
"390731", "Ancona",
"390362", "Cremona\/Monza",
"390933", "Caltanissetta",
"390424", "Vicenza",
"390372", "Cremona",
"390183", "Imperia",
"39080", "Bari",
"390783", "Oristano",
"390426", "Rovigo",
"390343", "Sondrio",
"390882", "Foggia",
"390185", "Genoa",
"39089", "Salerno",
"390521", "Parma",
"390774", "Rome",
"390166", "Aosta\ Valley",
"390962", "Crotone",
"39050", "Pisa",
"39059", "Modena",
"3906", "Rome",
"390141", "Asti",
"390922", "Agrigento",
"39071", "Ancona",
"39075", "Perugia",
"390376", "Mantua",
"390884", "Foggia",
"39095", "Catania",
"390823", "Caserta",
"39091", "Palermo",
"3906698", "Vatican\ City",
"390523", "Piacenza",
"390974", "Salerno",
"390924", "Trapani",
"390735", "Ascoli\ Piceno",
"390341", "Lecco",
"390789", "Sassari",
"390733", "Macerata",
"390575", "Arezzo",
"390565", "Livorno",
"390832", "Lecce",
"39035", "Bergamo",
"39031", "Como",
"390586", "Livorno",
"390445", "Vicenza",
"390324", "Verbano\-Cusio\-Ossola",
"390532", "Ferrara",
"390865", "Isernia",
"390422", "Treviso",
"390364", "Brescia",
"390122", "Turin",
"390825", "Avellino",
"390874", "Campobasso",
"39051", "Bologna",
"390444", "Vicenza",
"39055", "Florence",
"390342", "Sondrio",
"390365", "Brescia",
"39079", "Sassari",
"39070", "Cagliari",
"390883", "Andria\ Barletta\ Trani",
"39048", "Gorizia",
"390824", "Benevento",
"39085", "Pescara",
"39081", "Naples",
"390574", "Prato",
"390963", "Vibo\ Valentia",
"390583", "Lucca",
"390461", "Trento",
"390171", "Cuneo",
"390942", "Catania",
"390965", "Reggio\ Calabria",
"390471", "Bolzano\/Bozen",
"390975", "Potenza",
"390585", "Massa\-Carrara",
"390161", "Vercelli",
"39033", "Varese",
"390734", "Fermo",
"390925", "Agrigento",
"390421", "Venice",
"390549", "San\ Marino",
"390363", "Bergamo",
"39010", "Genoa",
"39049", "Padova",
"390373", "Cremona",
"390831", "Brindisi",
"390541", "Rimini",
"39040", "Trieste",
"390187", "La\ Spezia",
"390321", "Novara",
"390737", "Macerata",
"39013", "Alessandria",
"390732", "Ancona",
"390371", "Lodi",
"390543", "Forlì\-Cesena",
"390934", "Caltanissetta\ and\ Enna",
"390346", "Bergamo",
"390423", "Treviso",
"390382", "Pavia",
"39039", "Monza",
"3902", "Milan",
"39030", "Brescia",
"390961", "Catanzaro",
"390862", "L\'Aquila",
"390165", "Aosta\ Valley",
"390921", "Palermo",
"390425", "Rovigo",
"390344", "Como",
"390125", "Turin",
"39099", "Taranto",
"390432", "Udine",
"390545", "Ravenna",
"390881", "Foggia",
"39090", "Messina",
"390577", "Siena",
"390522", "Reggio\ Emilia",};
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