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
our $VERSION = 1.20210921211829;

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
                  [034]\\d|
                  1[0-35-9]|
                  2[1-9]|
                  5[0-2]
                )|
                600
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
$areanames{en} = {"5653246", "Ovalle\,\ Coquimbo",
"5653247", "Ovalle\,\ Coquimbo",
"565328", "Ovalle\,\ Coquimbo",
"5622", "Santiago\,\ Metropolitan\ Region",
"5661", "Punta\ Arenas\,\ Magallanes\ and\ Antártica\ Chilena",
"56532452", "Ovalle\,\ Coquimbo",
"56536", "Ovalle\,\ Coquimbo",
"56531", "Ovalle\,\ Coquimbo",
"5663", "Valdivia\,\ Los\ Ríos",
"565326", "Ovalle\,\ Coquimbo",
"5653248", "Ovalle\,\ Coquimbo",
"56533", "Ovalle\,\ Coquimbo",
"56532455", "Ovalle\,\ Coquimbo",
"5633", "Quillota\,\ Valparaíso",
"5651", "La\ Serena\,\ Coquimbo",
"5642", "Chillán\,\ Biobío",
"5653242", "Ovalle\,\ Coquimbo",
"56539", "Ovalle\,\ Coquimbo",
"5635", "San\ Antonio\,\ Valparaíso",
"565323", "Ovalle\,\ Coquimbo",
"5664", "Osorno\,\ Los\ Lagos",
"5665", "Puerto\ Montt\,\ Los\ Lagos",
"5634", "San\ Felipe\,\ Valparaíso",
"5672", "Rancagua\,\ O\'Higgins",
"56538", "Ovalle\,\ Coquimbo",
"56532459", "Ovalle\,\ Coquimbo",
"562198", "Santiago\,\ Metropolitan\ Region",
"56532457", "Ovalle\,\ Coquimbo",
"5653240", "Ovalle\,\ Coquimbo",
"5655", "Antofagasta",
"5653241", "Ovalle\,\ Coquimbo",
"5653243", "Ovalle\,\ Coquimbo",
"56532454", "Ovalle\,\ Coquimbo",
"5671", "Talca\,\ Maule",
"56532456", "Ovalle\,\ Coquimbo",
"5645", "Temuco\,\ Araucanía",
"565320", "Ovalle\,\ Coquimbo",
"565321", "Ovalle\,\ Coquimbo",
"56537", "Ovalle\,\ Coquimbo",
"5653249", "Ovalle\,\ Coquimbo",
"5673", "Linares\,\ Maule",
"56535", "Ovalle\,\ Coquimbo",
"565322", "Ovalle\,\ Coquimbo",
"56532458", "Ovalle\,\ Coquimbo",
"5675", "Curicó\,\ Maule",
"5623", "Santiago\,\ Metropolitan\ Region",
"5667", "Coyhaique\,\ Aisén",
"5658", "Arica\,\ Arica\ and\ Parinacota",
"56532453", "Ovalle\,\ Coquimbo",
"565327", "Ovalle\,\ Coquimbo",
"56534", "Ovalle\,\ Coquimbo",
"56211", "Santiago\,\ Metropolitan\ Region",
"5653244", "Ovalle\,\ Coquimbo",
"565325", "Ovalle\,\ Coquimbo",
"5652", "Copiapó\,\ Atacama",
"5641", "Concepción\,\ Biobío",
"5632", "Valparaíso",
"565329", "Ovalle\,\ Coquimbo",
"5643", "Los\ Angeles\,\ Biobío",
"5657", "Iquique\,\ Tarapacá",
"56530", "Ovalle\,\ Coquimbo",};
$areanames{es} = {"5658", "Arica\,\ Arica\ y\ Parinacota",
"5667", "Coihaique\,\ Aysén",
"5623", "Santiago\,\ Región\ Metropolitana",
"56211", "Santiago\,\ Región\ Metropolitana",
"562198", "Santiago\,\ Región\ Metropolitana",
"5661", "Punta\ Arenas\,\ Magallanes",
"5622", "Santiago\,\ Región\ Metropolitana",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+56|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;