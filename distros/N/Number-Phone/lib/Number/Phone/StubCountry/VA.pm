# automatically generated file, don't edit



# Copyright 2026 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20260610205505;

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
$areanames{it} = {"390533", "Comacchio",
"390774", "Tivoli",
"390585", "Massa",
"390163", "Borgosesia",
"390828", "Battipaglia",
"390544", "Ravenna",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390125", "Ivrea",
"390427", "Spilimbergo",
"390782", "Lanusei",
"390973", "Lagonegro",
"390971", "Potenza",
"390428", "Tarvisio",
"390983", "Rossano",
"390981", "Castrovillari",
"390365", "Salò",
"390935", "Enna",
"390547", "Cesena",
"39010", "Genova",
"390323", "Baveno",
"390542", "Imola",
"390424", "Bassano\ del\ Grappa",
"390784", "Nuoro",
"390721", "Pesaro",
"39019", "Savona",
"390765", "Poggio\ Mirteto",
"390377", "Codogno",
"39011", "Torino",
"390435", "Pieve\ di\ Cadore",
"390883", "Andria",
"390835", "Matera",
"390384", "Mortara",
"390345", "San\ Pellegrino\ Terme",
"390924", "Alcamo",
"390871", "Chieti",
"390873", "Vasto",
"390374", "Soresina",
"3906698", "Città\ del\ Vaticano",
"390976", "Muro\ Lucano",
"390564", "Grosseto",
"390536", "Sassuolo",
"390473", "Merano",
"390471", "Bolzano",
"390143", "Novi\ Ligure",
"390166", "Saint\-Vincent",
"39055", "Firenze",
"390386", "Ostiglia",
"390984", "Cosenza",
"390324", "Domodossola",
"390421", "San\ Donà\ di\ Piave",
"390423", "Montebelluna",
"390972", "Melfi",
"390465", "Tione\ di\ Trento",
"390735", "San\ Benedetto\ del\ Tronto",
"390781", "Iglesias",
"390543", "Forlì",
"390322", "Arona",
"390566", "Follonica",
"390771", "Formia",
"390773", "Latina",
"390534", "Porretta\ Terme",
"390982", "Paola",
"390376", "Mantova",
"390974", "Vallo\ della\ Lucania",
"3906", "Roma",
"390722", "Urbino",
"390373", "Crema",
"390474", "Brunico",
"390144", "Acqui\ Terme",
"390776", "Cassino",
"390546", "Faenza",
"390185", "Rapallo",
"390882", "San\ Severo",
"390525", "Fornovo\ di\ Taro",
"390872", "Lanciano",
"390426", "Adria",
"390445", "Schio",
"390175", "Saluzzo",
"390439", "Feltre",
"390884", "Manfredonia",
"390383", "Voghera",
"390381", "Vigevano",
"390965", "Reggio\ di\ Calabria",
"390923", "Trapani",
"390921", "Cefalù",
"390472", "Bressanone",
"390142", "Casale\ Monferrato",
"390864", "Sulmona",
"390346", "Clusone",
"390985", "Scalea",
"390933", "Caltagirone",
"390931", "Siracusa",
"390363", "Treviglio",
"390836", "Maglie",
"390429", "Este",
"390436", "Cortina\ d\'Ampezzo",
"390571", "Empoli",
"390573", "Pistoia",
"390789", "Olbia",
"390464", "Rovereto",
"390766", "Civitavecchia",
"390743", "Spoleto",
"390549", "Repubblica\ di\ San\ Marino",
"390165", "Aosta",
"390535", "Mirandola",
"390942", "Taormina",
"390121", "Pinerolo",
"390123", "Lanzo\ Torinese",
"390462", "Cavalese",
"390732", "Fabriano",
"390975", "Sala\ Consilina",
"390737", "Camerino",
"390172", "Savigliano",
"390442", "Legnago",
"390875", "Termoli",
"390967", "Soverato",
"390184", "Sanremo",
"390524", "Fidenza",
"390968", "Lamezia\ Terme",
"390332", "Varese",
"390761", "Viterbo",
"390763", "Orvieto",
"390746", "Rieti",
"390174", "Mondovì",
"390431", "Cervignano\ del\ Friuli",
"390433", "Tolmezzo",
"390964", "Locri",
"390885", "Cerignola",
"390833", "Gallipoli",
"390343", "Chiavenna",
"390522", "Reggio\ nell\'Emilia",
"390182", "Albenga",
"390545", "Lugo",
"390584", "Viareggio",
"390775", "Frosinone",
"390362", "Seregno",
"390932", "Ragusa",
"390124", "Rivarolo\ Canavese",
"390572", "Montecatini\ Terme",
"390578", "Chianciano\ Terme",
"390742", "Foligno",
"390122", "Susa",
"390966", "Palmi",
"390941", "Patti",
"390863", "Avezzano",
"390861", "Teramo",
"390364", "Breno",
"390934", "Caltanissetta",
"390587", "Pontedera",
"390588", "Volterra",
"390463", "Cles",
"390744", "Terni",
"390731", "Jesi",
"390785", "Macomer",
"390434", "Pordenone",
"390736", "Ascoli\ Piceno",
"390173", "Alba",
"390344", "Menaggio",
"390385", "Stradella",
"390331", "Busto\ Arsizio",
"3902", "Milano",
"390925", "Sciacca",
"390438", "Conegliano",
"390437", "Belluno",
"39081", "Napoli",
"390375", "Casalmaggiore",
"39041", "Venezia",
"390565", "Piombino",};
$areanames{en} = {"390975", "Potenza",
"390737", "Macerata",
"390575", "Arezzo",
"39033", "Varese",
"39013", "Alessandria",
"390732", "Ancona",
"390424", "Vicenza",
"390321", "Novara",
"39010", "Genoa",
"39079", "Sassari",
"390942", "Catania",
"390824", "Benevento",
"39030", "Brescia",
"390862", "L\'Aquila",
"390583", "Lucca",
"39071", "Ancona",
"390365", "Brescia",
"390549", "San\ Marino",
"390165", "Aosta\ Valley",
"390734", "Fermo",
"390422", "Treviso",
"390789", "Sassari",
"39045", "Verona",
"390125", "Turin",
"39085", "Pescara",
"390933", "Caltanissetta",
"390363", "Bergamo",
"390161", "Vercelli",
"390774", "Rome",
"390346", "Bergamo",
"390585", "Massa\-Carrara",
"39095", "Catania",
"39055", "Florence",
"390382", "Pavia",
"390831", "Brindisi",
"390187", "La\ Spezia",
"390922", "Agrigento",
"390166", "Aosta\ Valley",
"390471", "Bolzano\/Bozen",
"390141", "Asti",
"390341", "Lecco",
"390522", "Reggio\ Emilia",
"390343", "Sondrio",
"390444", "Vicenza",
"3906698", "Vatican\ City",
"390924", "Trapani",
"390962", "Crotone",
"390881", "Foggia",
"390883", "Andria\ Barletta\ Trani",
"390586", "Livorno",
"39011", "Turin",
"39031", "Como",
"39039", "Monza",
"39070", "Cagliari",
"390372", "Cremona",
"390376", "Mantua",
"390461", "Trento",
"3906", "Rome",
"390574", "Prato",
"390731", "Ancona",
"390733", "Macerata",
"390974", "Salerno",
"390425", "Rovigo",
"39035", "Bergamo",
"39015", "Biella",
"390825", "Avellino",
"390541", "Rimini",
"390322", "Novara",
"390543", "Forlì\-Cesena",
"390122", "Turin",
"390364", "Brescia",
"390934", "Caltanissetta\ and\ Enna",
"39048", "Gorizia",
"39051", "Bologna",
"390577", "Siena",
"390783", "Oristano",
"390735", "Ascoli\ Piceno",
"39091", "Palermo",
"39040", "Trieste",
"390423", "Treviso",
"390421", "Venice",
"39059", "Modena",
"39099", "Taranto",
"390532", "Ferrara",
"390362", "Cremona\/Monza",
"39080", "Bari",
"390324", "Verbano\-Cusio\-Ossola",
"390823", "Caserta",
"390545", "Ravenna",
"390865", "Isernia",
"39049", "Padova",
"390832", "Lecce",
"39090", "Messina",
"390342", "Sondrio",
"390523", "Piacenza",
"390521", "Parma",
"390921", "Palermo",
"39050", "Pisa",
"39041", "Venice",
"390965", "Reggio\ Calabria",
"390183", "Imperia",
"390884", "Foggia",
"390565", "Livorno",
"390445", "Vicenza",
"39081", "Naples",
"390432", "Udine",
"39089", "Salerno",
"390426", "Rovigo",
"390882", "Foggia",
"3902", "Milan",
"390925", "Agrigento",
"390776", "Frosinone",
"390344", "Como",
"390961", "Catanzaro",
"390963", "Vibo\ Valentia",
"390185", "Genoa",
"390371", "Lodi",
"390373", "Cremona",
"390171", "Cuneo",
"390874", "Campobasso",
"39075", "Perugia",};
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