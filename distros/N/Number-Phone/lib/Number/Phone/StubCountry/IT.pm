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
our $VERSION = 1.20180203200235;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            0[26]|
            55
          ',
                  'pattern' => '(\\d{2})(\\d{3,4})(\\d{4})'
                },
                {
                  'leading_digits' => '0[26]',
                  'pattern' => '(0[26])(\\d{4})(\\d{5})',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '(0[26])(\\d{4,6})',
                  'leading_digits' => '0[26]',
                  'format' => '$1 $2'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '0[13-57-9][0159]',
                  'pattern' => '(0\\d{2})(\\d{3,4})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'pattern' => '(\\d{3})(\\d{3,6})',
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
          '
                },
                {
                  'leading_digits' => '0[13-57-9][2-46-8]',
                  'pattern' => '(0\\d{3})(\\d{3})(\\d{4})',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '(0\\d{3})(\\d{2,6})',
                  'leading_digits' => '0[13-57-9][2-46-8]',
                  'format' => '$1 $2'
                },
                {
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})',
                  'leading_digits' => '
            [13]|
            8(?:
              00|
              4[08]|
              9(?:
                5[5-9]|
                9
              )
            )
          '
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '894[5-9]',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '3',
                  'pattern' => '(\\d{3})(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'pager' => '',
                'voip' => '55\\d{8}',
                'mobile' => '
          3(?:
            [12457-9]\\d{8}|
            6\\d{7,8}|
            3\\d{7,9}
          )
        ',
                'personal_number' => '
          1(?:
            78\\d|
            99
          )\\d{6}
        ',
                'specialrate' => '(
          84(?:
            [08]\\d{6}|
            [17]\\d{3}
          )
        )|(
          0878\\d{5}|
          1(?:
            44|
            6[346]
          )\\d{6}|
          89(?:
            2\\d{3}|
            4(?:
              [0-4]\\d{2}|
              [5-9]\\d{4}
            )|
            5(?:
              [0-4]\\d{2}|
              [5-9]\\d{6}
            )|
            9\\d{6}
          )
        )',
                'toll_free' => '
          80(?:
            0\\d{6}|
            3\\d{3}
          )
        ',
                'fixed_line' => '
          0(?:
            [26]\\d{4,9}|
            (?:
              1(?:
                [0159]\\d|
                [27][1-5]|
                31|
                4[1-4]|
                6[1356]|
                8[2-57]
              )|
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
              7(?:
                [0159]\\d|
                2[12]|
                3[1-7]|
                4[2346]|
                6[13569]|
                7[13-6]|
                8[1-59]
              )|
              8(?:
                [0159]\\d|
                2[34578]|
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
          )
        ',
                'geographic' => '
          0(?:
            [26]\\d{4,9}|
            (?:
              1(?:
                [0159]\\d|
                [27][1-5]|
                31|
                4[1-4]|
                6[1356]|
                8[2-57]
              )|
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
              7(?:
                [0159]\\d|
                2[12]|
                3[1-7]|
                4[2346]|
                6[13569]|
                7[13-6]|
                8[1-59]
              )|
              8(?:
                [0159]\\d|
                2[34578]|
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
          )
        '
              };
my %areanames = (
  39010 => "Genoa",
  39011 => "Turin",
  390122 => "Turin",
  390125 => "Turin",
  390131 => "Alessandria",
  390141 => "Asti",
  39015 => "Biella",
  390161 => "Vercelli",
  390165 => "Aosta\ Valley",
  390166 => "Aosta\ Valley",
  390171 => "Cuneo",
  390183 => "Imperia",
  390185 => "Genoa",
  390187 => "La\ Spezia",
  3902 => "Milan",
  39030 => "Brescia",
  39031 => "Como",
  390321 => "Novara",
  390322 => "Novara",
  390324 => "Verbano\-Cusio\-Ossola",
  390331 => "Varese",
  390332 => "Varese",
  390341 => "Lecco",
  390342 => "Sondrio",
  390343 => "Sondrio",
  390344 => "Como",
  390346 => "Bergamo",
  39035 => "Bergamo",
  390362 => "Cremona\/Monza",
  390363 => "Bergamo",
  390364 => "Brescia",
  390365 => "Brescia",
  390371 => "Lodi",
  390372 => "Cremona",
  390373 => "Cremona",
  390376 => "Mantua",
  390382 => "Pavia",
  39039 => "Monza",
  39040 => "Trieste",
  39041 => "Venice",
  390421 => "Venice",
  390422 => "Treviso",
  390423 => "Treviso",
  390424 => "Vicenza",
  390425 => "Rovigo",
  390426 => "Rovigo",
  390432 => "Udine",
  390444 => "Vicenza",
  390445 => "Vicenza",
  39045 => "Verona",
  390461 => "Trento",
  390471 => "Bolzano\/Bozen",
  390481 => "Gorizia",
  39049 => "Padova",
  39050 => "Pisa",
  39051 => "Bologna",
  390521 => "Parma",
  390522 => "Reggio\ Emilia",
  390523 => "Piacenza",
  390532 => "Ferrara",
  390541 => "Rimini",
  390543 => "Forlì\-Cesena",
  390545 => "Ravenna",
  390549 => "San\ Marino",
  39055 => "Florence",
  390565 => "Livorno",
  390574 => "Prato",
  390575 => "Arezzo",
  390577 => "Siena",
  390583 => "Lucca",
  390585 => "Massa\-Carrara",
  390586 => "Livorno",
  39059 => "Modena",
  3906 => "Rome",
  39070 => "Cagliari",
  39071 => "Ancona",
  390731 => "Ancona",
  390732 => "Ancona",
  390733 => "Macerata",
  390734 => "Fermo",
  390735 => "Ascoli\ Piceno",
  390737 => "Macerata",
  39075 => "Perugia",
  390774 => "Rome",
  390776 => "Frosinone",
  390783 => "Oristano",
  390789 => "Sassari",
  39079 => "Sassari",
  39080 => "Bari",
  39081 => "Naples",
  390823 => "Caserta",
  390824 => "Benevento",
  390825 => "Avellino",
  390832 => "Lecce",
  39085 => "Pescara",
  390862 => "L\'Aquila",
  390865 => "Isernia",
  390874 => "Campobasso",
  390881 => "Foggia",
  390882 => "Foggia",
  390883 => "Andria\ Barletta\ Trani",
  390884 => "Foggia",
  39089 => "Salerno",
  39090 => "Messina",
  39091 => "Palermo",
  390921 => "Palermo",
  390922 => "Agrigento",
  390924 => "Trapani",
  390925 => "Agrigento",
  390933 => "Caltanissetta",
  390934 => "Caltanissetta\ and\ Enna",
  390942 => "Catania",
  39095 => "Catania",
  390961 => "Catanzaro",
  390962 => "Crotone",
  390963 => "Vibo\ Valentia",
  390965 => "Reggio\ Calabria",
  390974 => "Salerno",
  390975 => "Potenza",
  39099 => "Taranto",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;