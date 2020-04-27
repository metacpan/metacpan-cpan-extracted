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
package Number::Phone::StubCountry::CL;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120028;

my $formatters = [
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '
            1(?:
              [03-589]|
              21
            )|
            [29]0|
            78
          ',
                  'pattern' => '(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '2196',
                  'national_rule' => '($1)',
                  'pattern' => '(\\d{5})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '44',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2[1-3]',
                  'national_rule' => '($1)',
                  'pattern' => '(\\d)(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9[2-9]',
                  'pattern' => '(\\d)(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            3[2-5]|
            [47]|
            5[1-3578]|
            6[13-57]|
            8(?:
              0[1-9]|
              [1-9]
            )
          ',
                  'national_rule' => '($1)',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            60|
            8
          ',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '60',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{2})(\\d{3})'
                }
              ];

my $validators = {
                'geographic' => '
          2(?:
            1982[0-6]|
            3314[05-9]
          )\\d{3}|
          (?:
            2(?:
              1(?:
                160|
                962
              )|
              3(?:
                2\\d\\d|
                3(?:
                  0\\d|
                  1[0-35-9]|
                  2[1-9]|
                  3[0-2]|
                  40
                )
              )
            )|
            80[1-9]\\d\\d|
            9(?:
              3(?:
                [0-57-9]\\d\\d|
                6(?:
                  0[02-9]|
                  [1-9]\\d
                )
              )|
              6(?:
                [0-8]\\d\\d|
                9(?:
                  [02-79]\\d|
                  1[05-9]
                )
              )|
              7[1-9]\\d\\d|
              9(?:
                [03-9]\\d\\d|
                1(?:
                  [0235-9]\\d|
                  4[0-24-9]
                )|
                2(?:
                  [0-79]\\d|
                  8[0-46-9]
                )
              )
            )
          )\\d{4}|
          (?:
            22|
            3[2-5]|
            [47][1-35]|
            5[1-3578]|
            6[13-57]|
            8[1-9]|
            9[2458]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(600\\d{7,8})',
                'toll_free' => '
          (?:
            123|
            8
          )00\\d{6}
        ',
                'voip' => '44\\d{7}'
              };
my %areanames = ();
$areanames{es}->{56211} = "Santiago\,\ Región\ Metropolitana";
$areanames{es}->{562198} = "Santiago\,\ Región\ Metropolitana";
$areanames{es}->{5622} = "Santiago\,\ Región\ Metropolitana";
$areanames{es}->{5623} = "Santiago\,\ Región\ Metropolitana";
$areanames{es}->{5632} = "Valparaíso";
$areanames{es}->{5633} = "Quillota\,\ Valparaíso";
$areanames{es}->{5634} = "San\ Felipe\,\ Valparaíso";
$areanames{es}->{5635} = "San\ Antonio\,\ Valparaíso";
$areanames{es}->{5641} = "Concepción\,\ Biobío";
$areanames{es}->{5642} = "Chillán\,\ Biobío";
$areanames{es}->{5643} = "Los\ Angeles\,\ Biobío";
$areanames{es}->{5645} = "Temuco\,\ Araucanía";
$areanames{es}->{5651} = "La\ Serena\,\ Coquimbo";
$areanames{es}->{5652} = "Copiapó\,\ Atacama";
$areanames{es}->{56530} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56531} = "Ovalle\,\ Coquimbo";
$areanames{es}->{565320} = "Ovalle\,\ Coquimbo";
$areanames{es}->{565321} = "Ovalle\,\ Coquimbo";
$areanames{es}->{565322} = "Ovalle\,\ Coquimbo";
$areanames{es}->{565323} = "Ovalle\,\ Coquimbo";
$areanames{es}->{5653240} = "Ovalle\,\ Coquimbo";
$areanames{es}->{5653241} = "Ovalle\,\ Coquimbo";
$areanames{es}->{5653242} = "Ovalle\,\ Coquimbo";
$areanames{es}->{5653243} = "Ovalle\,\ Coquimbo";
$areanames{es}->{5653244} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56532452} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56532453} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56532454} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56532455} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56532456} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56532457} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56532458} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56532459} = "Ovalle\,\ Coquimbo";
$areanames{es}->{5653246} = "Ovalle\,\ Coquimbo";
$areanames{es}->{5653247} = "Ovalle\,\ Coquimbo";
$areanames{es}->{5653248} = "Ovalle\,\ Coquimbo";
$areanames{es}->{5653249} = "Ovalle\,\ Coquimbo";
$areanames{es}->{565325} = "Ovalle\,\ Coquimbo";
$areanames{es}->{565326} = "Ovalle\,\ Coquimbo";
$areanames{es}->{565327} = "Ovalle\,\ Coquimbo";
$areanames{es}->{565328} = "Ovalle\,\ Coquimbo";
$areanames{es}->{565329} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56533} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56534} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56535} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56536} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56537} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56538} = "Ovalle\,\ Coquimbo";
$areanames{es}->{56539} = "Ovalle\,\ Coquimbo";
$areanames{es}->{5655} = "Antofagasta";
$areanames{es}->{5657} = "Iquique\,\ Tarapacá";
$areanames{es}->{5658} = "Arica\,\ Arica\ y\ Parinacota";
$areanames{es}->{5661} = "Punta\ Arenas\,\ Magallanes";
$areanames{es}->{5663} = "Valdivia\,\ Los\ Ríos";
$areanames{es}->{5664} = "Osorno\,\ Los\ Lagos";
$areanames{es}->{5665} = "Puerto\ Montt\,\ Los\ Lagos";
$areanames{es}->{5667} = "Coihaique\,\ Aysén";
$areanames{es}->{5671} = "Talca\,\ Maule";
$areanames{es}->{5672} = "Rancagua\,\ O\'Higgins";
$areanames{es}->{5673} = "Linares\,\ Maule";
$areanames{es}->{5675} = "Curicó\,\ Maule";
$areanames{en}->{56211} = "Santiago\,\ Metropolitan\ Region";
$areanames{en}->{562198} = "Santiago\,\ Metropolitan\ Region";
$areanames{en}->{5622} = "Santiago\,\ Metropolitan\ Region";
$areanames{en}->{5623} = "Santiago\,\ Metropolitan\ Region";
$areanames{en}->{5632} = "Valparaíso";
$areanames{en}->{5633} = "Quillota\,\ Valparaíso";
$areanames{en}->{5634} = "San\ Felipe\,\ Valparaíso";
$areanames{en}->{5635} = "San\ Antonio\,\ Valparaíso";
$areanames{en}->{5641} = "Concepción\,\ Biobío";
$areanames{en}->{5642} = "Chillán\,\ Biobío";
$areanames{en}->{5643} = "Los\ Angeles\,\ Biobío";
$areanames{en}->{5645} = "Temuco\,\ Araucanía";
$areanames{en}->{5651} = "La\ Serena\,\ Coquimbo";
$areanames{en}->{5652} = "Copiapó\,\ Atacama";
$areanames{en}->{56530} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56531} = "Ovalle\,\ Coquimbo";
$areanames{en}->{565320} = "Ovalle\,\ Coquimbo";
$areanames{en}->{565321} = "Ovalle\,\ Coquimbo";
$areanames{en}->{565322} = "Ovalle\,\ Coquimbo";
$areanames{en}->{565323} = "Ovalle\,\ Coquimbo";
$areanames{en}->{5653240} = "Ovalle\,\ Coquimbo";
$areanames{en}->{5653241} = "Ovalle\,\ Coquimbo";
$areanames{en}->{5653242} = "Ovalle\,\ Coquimbo";
$areanames{en}->{5653243} = "Ovalle\,\ Coquimbo";
$areanames{en}->{5653244} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56532452} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56532453} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56532454} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56532455} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56532456} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56532457} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56532458} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56532459} = "Ovalle\,\ Coquimbo";
$areanames{en}->{5653246} = "Ovalle\,\ Coquimbo";
$areanames{en}->{5653247} = "Ovalle\,\ Coquimbo";
$areanames{en}->{5653248} = "Ovalle\,\ Coquimbo";
$areanames{en}->{5653249} = "Ovalle\,\ Coquimbo";
$areanames{en}->{565325} = "Ovalle\,\ Coquimbo";
$areanames{en}->{565326} = "Ovalle\,\ Coquimbo";
$areanames{en}->{565327} = "Ovalle\,\ Coquimbo";
$areanames{en}->{565328} = "Ovalle\,\ Coquimbo";
$areanames{en}->{565329} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56533} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56534} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56535} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56536} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56537} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56538} = "Ovalle\,\ Coquimbo";
$areanames{en}->{56539} = "Ovalle\,\ Coquimbo";
$areanames{en}->{5655} = "Antofagasta";
$areanames{en}->{5657} = "Iquique\,\ Tarapacá";
$areanames{en}->{5658} = "Arica\,\ Arica\ and\ Parinacota";
$areanames{en}->{5661} = "Punta\ Arenas\,\ Magallanes\ and\ Antártica\ Chilena";
$areanames{en}->{5663} = "Valdivia\,\ Los\ Ríos";
$areanames{en}->{5664} = "Osorno\,\ Los\ Lagos";
$areanames{en}->{5665} = "Puerto\ Montt\,\ Los\ Lagos";
$areanames{en}->{5667} = "Coyhaique\,\ Aisén";
$areanames{en}->{5671} = "Talca\,\ Maule";
$areanames{en}->{5672} = "Rancagua\,\ O\'Higgins";
$areanames{en}->{5673} = "Linares\,\ Maule";
$areanames{en}->{5675} = "Curicó\,\ Maule";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+56|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;