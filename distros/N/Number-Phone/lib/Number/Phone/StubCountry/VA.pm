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
our $VERSION = 1.20240607153922;

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
$areanames{it} = {"39055", "Firenze",
"390345", "San\ Pellegrino\ Terme",
"39011", "Torino",
"390428", "Tarvisio",
"390362", "Seregno",
"390565", "Piombino",
"390863", "Avezzano",
"390542", "Imola",
"390789", "Olbia",
"390123", "Lanzo\ Torinese",
"390375", "Casalmaggiore",
"390383", "Voghera",
"390578", "Chianciano\ Terme",
"390836", "Maglie",
"390882", "San\ Severo",
"390572", "Montecatini\ Terme",
"390781", "Iglesias",
"390584", "Viareggio",
"390424", "Bassano\ del\ Grappa",
"390544", "Ravenna",
"390924", "Alcamo",
"390546", "Faenza",
"390426", "Adria",
"390364", "Breno",
"390343", "Chiavenna",
"390534", "Porretta\ Terme",
"390872", "Lanciano",
"390884", "Manfredonia",
"390731", "Jesi",
"390771", "Formia",
"390536", "Sassuolo",
"390377", "Codogno",
"390588", "Volterra",
"390125", "Ivrea",
"390373", "Crema",
"390385", "Stradella",
"390722", "Urbino",
"390761", "Viterbo",
"390564", "Grosseto",
"390923", "Trapani",
"390547", "Cesena",
"390427", "Spilimbergo",
"390543", "Forlì",
"390423", "Montebelluna",
"390566", "Follonica",
"390344", "Menaggio",
"390346", "Clusone",
"390363", "Treviglio",
"39041", "Venezia",
"390883", "Andria",
"390533", "Comacchio",
"390875", "Termoli",
"390981", "Castrovillari",
"390585", "Massa",
"390835", "Matera",
"390573", "Pistoia",
"390122", "Susa",
"390374", "Soresina",
"390376", "Mantova",
"390365", "Salò",
"390941", "Patti",
"390545", "Lugo",
"390925", "Sciacca",
"390439", "Feltre",
"390864", "Sulmona",
"390386", "Ostiglia",
"390384", "Mortara",
"390124", "Rivarolo\ Canavese",
"390332", "Varese",
"390885", "Cerignola",
"390535", "Mirandola",
"390873", "Vasto",
"390931", "Siracusa",
"390833", "Gallipoli",
"390971", "Potenza",
"390471", "Bolzano",
"390587", "Pontedera",
"390431", "Cervignano\ del\ Friuli",
"390785", "Macomer",
"390773", "Latina",
"390972", "Melfi",
"390984", "Cosenza",
"390932", "Ragusa",
"390737", "Camerino",
"390472", "Bressanone",
"390166", "Saint\-Vincent",
"390143", "Novi\ Ligure",
"390438", "Conegliano",
"390331", "Busto\ Arsizio",
"390465", "Tione\ di\ Trento",
"390942", "Taormina",
"390766", "Civitavecchia",
"390743", "Spoleto",
"390965", "Reggio\ di\ Calabria",
"390442", "Legnago",
"390522", "Reggio\ nell\'Emilia",
"390173", "Alba",
"390185", "Rapallo",
"3902", "Milano",
"390121", "Pinerolo",
"390381", "Vigevano",
"390434", "Pordenone",
"39019", "Savona",
"390474", "Brunico",
"390976", "Muro\ Lucano",
"390974", "Vallo\ della\ Lucania",
"390982", "Paola",
"390775", "Frosinone",
"390934", "Caltanissetta",
"390436", "Cortina\ d\'Ampezzo",
"390735", "San\ Benedetto\ del\ Tronto",
"390828", "Battipaglia",
"390175", "Saluzzo",
"390323", "Baveno",
"390861", "Teramo",
"390524", "Fidenza",
"390721", "Pesaro",
"390463", "Cles",
"390967", "Soverato",
"390142", "Casale\ Monferrato",
"390165", "Aosta",
"390831", "Brindisi",
"390784", "Nuoro",
"390985", "Scalea",
"390437", "Belluno",
"390973", "Lagonegro",
"390732", "Fabriano",
"390871", "Chieti",
"390933", "Caltagirone",
"390433", "Tolmezzo",
"390473", "Merano",
"390184", "Sanremo",
"390172", "Savigliano",
"390324", "Domodossola",
"390464", "Rovereto",
"390966", "Palmi",
"390742", "Foligno",
"3906", "Roma",
"390964", "Locri",
"390765", "Poggio\ Mirteto",
"390736", "Ascoli\ Piceno",
"390435", "Pieve\ di\ Cadore",
"3906698", "Città\ del\ Vaticano",
"390776", "Cassino",
"39081", "Napoli",
"390983", "Rossano",
"390549", "Repubblica\ di\ San\ Marino",
"390975", "Sala\ Consilina",
"390429", "Este",
"390774", "Tivoli",
"39010", "Genova",
"390782", "Lanusei",
"390571", "Empoli",
"390935", "Enna",
"390163", "Borgosesia",
"390144", "Acqui\ Terme",
"390763", "Orvieto",
"390525", "Fornovo\ di\ Taro",
"390445", "Schio",
"390921", "Cefalù",
"390746", "Rieti",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390744", "Terni",
"390462", "Cavalese",
"390421", "San\ Donà\ di\ Piave",
"390968", "Lamezia\ Terme",
"390182", "Albenga",
"390322", "Arona",
"390174", "Mondovì",};
$areanames{en} = {"390324", "Verbano\-Cusio\-Ossola",
"390577", "Siena",
"39041", "Venice",
"390883", "Andria\ Barletta\ Trani",
"39091", "Palermo",
"390585", "Massa\-Carrara",
"39075", "Perugia",
"390382", "Pavia",
"390161", "Vercelli",
"390122", "Turin",
"390825", "Avellino",
"390523", "Piacenza",
"390376", "Mantua",
"3906", "Rome",
"39030", "Brescia",
"390862", "L\'Aquila",
"390423", "Treviso",
"390165", "Aosta\ Valley",
"390543", "Forlì\-Cesena",
"39089", "Salerno",
"390344", "Como",
"39051", "Bologna",
"390933", "Caltanissetta",
"390732", "Ancona",
"390363", "Bergamo",
"39015", "Biella",
"390346", "Bergamo",
"390823", "Caserta",
"390921", "Palermo",
"390962", "Crotone",
"390445", "Vicenza",
"390421", "Venice",
"390372", "Cremona",
"390541", "Rimini",
"39099", "Taranto",
"390583", "Lucca",
"390575", "Arezzo",
"39070", "Cagliari",
"390471", "Bolzano\/Bozen",
"390322", "Novara",
"39049", "Padova",
"3906698", "Vatican\ City",
"390776", "Frosinone",
"39048", "Gorizia",
"390365", "Brescia",
"390774", "Rome",
"39010", "Genoa",
"39081", "Naples",
"390549", "San\ Marino",
"390342", "Sondrio",
"390975", "Potenza",
"390881", "Foggia",
"390734", "Fermo",
"39059", "Modena",
"390545", "Ravenna",
"390425", "Rovigo",
"39035", "Bergamo",
"390521", "Parma",
"390925", "Agrigento",
"390942", "Catania",
"390824", "Benevento",
"390522", "Reggio\ Emilia",
"390965", "Reggio\ Calabria",
"39045", "Verona",
"390586", "Livorno",
"390185", "Genoa",
"3902", "Milan",
"39013", "Alessandria",
"390532", "Ferrara",
"390874", "Campobasso",
"390882", "Foggia",
"39071", "Ancona",
"39095", "Catania",
"390341", "Lecco",
"39055", "Florence",
"390733", "Macerata",
"39080", "Bari",
"390432", "Udine",
"39011", "Turin",
"390321", "Novara",
"390362", "Cremona\/Monza",
"390737", "Macerata",
"390961", "Catanzaro",
"390922", "Agrigento",
"390166", "Aosta\ Valley",
"390565", "Livorno",
"39039", "Monza",
"390789", "Sassari",
"390371", "Lodi",
"390461", "Trento",
"390422", "Treviso",
"39079", "Sassari",
"390187", "La\ Spezia",
"390731", "Ancona",
"390884", "Foggia",
"390832", "Lecce",
"390574", "Prato",
"39040", "Trieste",
"390183", "Imperia",
"39090", "Messina",
"390963", "Vibo\ Valentia",
"390444", "Vicenza",
"390141", "Asti",
"390373", "Cremona",
"390125", "Turin",
"39033", "Varese",
"39031", "Como",
"390424", "Vicenza",
"390426", "Rovigo",
"390924", "Trapani",
"390865", "Isernia",
"39050", "Pisa",
"390171", "Cuneo",
"390364", "Brescia",
"390783", "Oristano",
"390974", "Salerno",
"390343", "Sondrio",
"39085", "Pescara",
"390735", "Ascoli\ Piceno",
"390934", "Caltanissetta\ and\ Enna",};
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