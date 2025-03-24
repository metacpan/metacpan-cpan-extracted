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
package Number::Phone::StubCountry::VA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250323211838;

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
$areanames{en} = {"390585", "Massa\-Carrara",
"390364", "Brescia",
"390735", "Ascoli\ Piceno",
"39071", "Ancona",
"390423", "Treviso",
"390874", "Campobasso",
"390322", "Novara",
"390371", "Lodi",
"39079", "Sassari",
"390732", "Ancona",
"39075", "Perugia",
"390541", "Rimini",
"390825", "Avellino",
"390422", "Treviso",
"390125", "Turin",
"390171", "Cuneo",
"390823", "Caserta",
"390161", "Vercelli",
"390934", "Caltanissetta\ and\ Enna",
"390583", "Lucca",
"390122", "Turin",
"390471", "Bolzano\/Bozen",
"390346", "Bergamo",
"3902", "Milan",
"390425", "Rovigo",
"390733", "Macerata",
"390461", "Trento",
"390421", "Venice",
"39091", "Palermo",
"390424", "Vicenza",
"390543", "Forlì\-Cesena",
"39080", "Bari",
"39095", "Catania",
"390165", "Aosta\ Valley",
"39099", "Taranto",
"390776", "Frosinone",
"390737", "Macerata",
"390363", "Bergamo",
"390942", "Catania",
"390783", "Oristano",
"39030", "Brescia",
"390373", "Cremona",
"390865", "Isernia",
"390734", "Fermo",
"39051", "Bologna",
"39010", "Genoa",
"390545", "Ravenna",
"390321", "Novara",
"390365", "Brescia",
"390731", "Ancona",
"390362", "Cremona\/Monza",
"390933", "Caltanissetta",
"390824", "Benevento",
"390372", "Cremona",
"39055", "Florence",
"39040", "Trieste",
"390532", "Ferrara",
"390324", "Verbano\-Cusio\-Ossola",
"39059", "Modena",
"390862", "L\'Aquila",
"390922", "Agrigento",
"390444", "Vicenza",
"390523", "Piacenza",
"390141", "Asti",
"390974", "Salerno",
"390185", "Genoa",
"390883", "Andria\ Barletta\ Trani",
"390549", "San\ Marino",
"3906698", "Vatican\ City",
"390577", "Siena",
"390376", "Mantua",
"390961", "Catanzaro",
"39033", "Varese",
"390789", "Sassari",
"39070", "Cagliari",
"390925", "Agrigento",
"390522", "Reggio\ Emilia",
"390344", "Como",
"390166", "Aosta\ Valley",
"390183", "Imperia",
"39013", "Alessandria",
"390574", "Prato",
"390341", "Lecco",
"390382", "Pavia",
"390882", "Foggia",
"390187", "La\ Spezia",
"390774", "Rome",
"390565", "Livorno",
"39081", "Naples",
"390521", "Parma",
"390575", "Arezzo",
"39031", "Como",
"390426", "Rovigo",
"390884", "Foggia",
"39090", "Messina",
"39048", "Gorizia",
"39085", "Pescara",
"39039", "Monza",
"390342", "Sondrio",
"390963", "Vibo\ Valentia",
"39035", "Bergamo",
"39089", "Salerno",
"390832", "Lecce",
"390881", "Foggia",
"390965", "Reggio\ Calabria",
"39041", "Venice",
"390445", "Vicenza",
"39015", "Biella",
"390975", "Potenza",
"390921", "Palermo",
"3906", "Rome",
"39045", "Verona",
"39050", "Pisa",
"39011", "Turin",
"390924", "Trapani",
"390586", "Livorno",
"390962", "Crotone",
"39049", "Padova",
"390343", "Sondrio",
"390432", "Udine",};
$areanames{it} = {"390184", "Sanremo",
"390972", "Melfi",
"390924", "Alcamo",
"390573", "Pistoia",
"39011", "Torino",
"39019", "Savona",
"3906", "Roma",
"390921", "Cefalù",
"390975", "Sala\ Consilina",
"39041", "Venezia",
"390965", "Reggio\ di\ Calabria",
"390332", "Varese",
"390761", "Viterbo",
"390433", "Tolmezzo",
"390771", "Formia",
"390722", "Urbino",
"390429", "Este",
"390426", "Adria",
"390345", "San\ Pellegrino\ Terme",
"390835", "Matera",
"390143", "Novi\ Ligure",
"390774", "Tivoli",
"390525", "Fornovo\ di\ Taro",
"390571", "Empoli",
"390882", "San\ Severo",
"390967", "Soverato",
"390385", "Stradella",
"390923", "Trapani",
"390564", "Grosseto",
"390885", "Cerignola",
"390522", "Reggio\ nell\'Emilia",
"390773", "Latina",
"390763", "Orvieto",
"390144", "Acqui\ Terme",
"390431", "Cervignano\ del\ Friuli",
"390376", "Mantova",
"390968", "Lamezia\ Terme",
"390434", "Pordenone",
"390542", "Imola",
"390782", "Lanusei",
"390828", "Battipaglia",
"390933", "Caltagirone",
"390785", "Macomer",
"390588", "Volterra",
"390535", "Mirandola",
"390545", "Lugo",
"390373", "Crema",
"390981", "Castrovillari",
"390472", "Bressanone",
"390766", "Civitavecchia",
"390737", "Camerino",
"390363", "Treviglio",
"390776", "Cassino",
"390462", "Cavalese",
"390863", "Avezzano",
"390165", "Aosta",
"390587", "Pontedera",
"390873", "Vasto",
"390175", "Saluzzo",
"390121", "Pinerolo",
"390424", "Bassano\ del\ Grappa",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390172", "Savigliano",
"390984", "Cosenza",
"390465", "Tione\ di\ Trento",
"390124", "Rivarolo\ Canavese",
"390421", "San\ Donà\ di\ Piave",
"390931", "Siracusa",
"390941", "Patti",
"390547", "Cesena",
"390566", "Follonica",
"390934", "Caltanissetta",
"390871", "Chieti",
"390123", "Lanzo\ Torinese",
"390861", "Teramo",
"390732", "Fabriano",
"390742", "Foligno",
"390439", "Feltre",
"390436", "Cortina\ d\'Ampezzo",
"390983", "Rossano",
"390322", "Arona",
"390423", "Montebelluna",
"390735", "San\ Benedetto\ del\ Tronto",
"390864", "Sulmona",
"390364", "Breno",
"390585", "Massa",
"390374", "Soresina",
"390442", "Legnago",
"390343", "Chiavenna",
"390746", "Rieti",
"390736", "Ascoli\ Piceno",
"390833", "Gallipoli",
"390142", "Casale\ Monferrato",
"390435", "Pieve\ di\ Cadore",
"390445", "Schio",
"390572", "Montecatini\ Terme",
"390524", "Fidenza",
"390973", "Lagonegro",
"390381", "Vigevano",
"390884", "Manfredonia",
"39081", "Napoli",
"390565", "Piombino",
"390384", "Mortara",
"390831", "Brindisi",
"390437", "Belluno",
"390331", "Busto\ Arsizio",
"390765", "Poggio\ Mirteto",
"390578", "Chianciano\ Terme",
"390721", "Pesaro",
"390775", "Frosinone",
"390166", "Saint\-Vincent",
"390344", "Menaggio",
"390925", "Sciacca",
"390971", "Potenza",
"390789", "Olbia",
"390383", "Voghera",
"390536", "Sassuolo",
"390546", "Faenza",
"390549", "Repubblica\ di\ San\ Marino",
"3906698", "Città\ del\ Vaticano",
"390883", "Andria",
"390185", "Rapallo",
"390438", "Conegliano",
"390974", "Vallo\ della\ Lucania",
"390182", "Albenga",
"390964", "Locri",
"390324", "Domodossola",
"390872", "Lanciano",
"390473", "Merano",
"39055", "Firenze",
"390463", "Cles",
"390362", "Seregno",
"390731", "Jesi",
"390584", "Viareggio",
"390365", "Salò",
"390427", "Spilimbergo",
"390375", "Casalmaggiore",
"390875", "Termoli",
"390173", "Alba",
"39010", "Genova",
"390744", "Terni",
"390163", "Borgosesia",
"390942", "Taormina",
"390386", "Ostiglia",
"390932", "Ragusa",
"390428", "Tarvisio",
"390533", "Comacchio",
"390543", "Forlì",
"390935", "Enna",
"390743", "Spoleto",
"390346", "Clusone",
"3902", "Milano",
"390471", "Bolzano",
"390982", "Paola",
"390174", "Mondovì",
"390377", "Codogno",
"390836", "Maglie",
"390122", "Susa",
"390464", "Rovereto",
"390474", "Brunico",
"390125", "Ivrea",
"390985", "Scalea",
"390323", "Baveno",
"390976", "Muro\ Lucano",
"390966", "Palmi",
"390781", "Iglesias",
"390544", "Ravenna",
"390534", "Porretta\ Terme",
"390784", "Nuoro",};
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