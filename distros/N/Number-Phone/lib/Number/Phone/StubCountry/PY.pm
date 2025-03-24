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
package Number::Phone::StubCountry::PY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250323211835;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[2-9]0',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3,6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [26]1|
            3[289]|
            4[1246-8]|
            7[1-3]|
            8[1-36]
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            2[279]|
            3[13-5]|
            4[359]|
            5|
            6(?:
              [34]|
              7[1-46-8]
            )|
            7[46-8]|
            85
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{3})(\\d{4,5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            2[14-68]|
            3[26-9]|
            4[1246-8]|
            6(?:
              1|
              75
            )|
            7[1-35]|
            8[1-36]
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '87',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            9(?:
              [5-79]|
              8[1-7]
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{6})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-8]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            [26]1|
            3[289]|
            4[1246-8]|
            7[1-3]|
            8[1-36]
          )\\d{5,7}|
          (?:
            2(?:
              2[4-68]|
              [4-68]\\d|
              7[15]|
              9[1-5]
            )|
            3(?:
              18|
              3[167]|
              4[2357]|
              51|
              [67]\\d
            )|
            4(?:
              3[12]|
              5[13]|
              9[1-47]
            )|
            5(?:
              [1-4]\\d|
              5[02-4]
            )|
            6(?:
              3[1-3]|
              44|
              7[1-8]
            )|
            7(?:
              4[0-4]|
              5\\d|
              6[1-578]|
              75|
              8[0-8]
            )|
            858
          )\\d{5,6}
        ',
                'geographic' => '
          (?:
            [26]1|
            3[289]|
            4[1246-8]|
            7[1-3]|
            8[1-36]
          )\\d{5,7}|
          (?:
            2(?:
              2[4-68]|
              [4-68]\\d|
              7[15]|
              9[1-5]
            )|
            3(?:
              18|
              3[167]|
              4[2357]|
              51|
              [67]\\d
            )|
            4(?:
              3[12]|
              5[13]|
              9[1-47]
            )|
            5(?:
              [1-4]\\d|
              5[02-4]
            )|
            6(?:
              3[1-3]|
              44|
              7[1-8]
            )|
            7(?:
              4[0-4]|
              5\\d|
              6[1-578]|
              75|
              8[0-8]
            )|
            858
          )\\d{5,6}
        ',
                'mobile' => '
          9(?:
            51|
            6[129]|
            7[1-6]|
            8[1-7]|
            9[1-5]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '([2-9]0\\d{4,7})',
                'toll_free' => '9800\\d{5,7}',
                'voip' => '8700[0-4]\\d{4}'
              };
my %areanames = ();
$areanames{en} = {"59521", "Fernando\ De\ La\ Mora\,\ Lambare\,\ Limpio\,\ Luque\,\ Mariano\ Roque\ Alonso\,\ San\ Antonio\,\ Valle\ Pucu\ and\ Villa\ Elisa",
"59564", "Cargil",
"59582", "San\ Ignacio\ \/\ Misiones",
"595676", "Naranjal",
"595554", "Itape",
"59531", "Concepcion",
"595345", "Corpus\ Christi",
"59532", "Horqueta",
"595764", "Maria\ Auxiliadora",
"59581", "San\ Juan\ Bautista\ \/\ Misiones",
"595671", "Mayor\ Otano",
"595768", "Pirapo",
"59573", "San\ Cosme",
"595783", "San\ Miguel\ \/\ Misiones",
"595451", "Colonia\ Volendam",
"59525", "Villeta",
"595780", "Alberdi",
"59535", "Valle\ Mi",
"59539", "Yby\ Ja\'U",
"59585", "Santa\ Rosa\ \/\ Misiones",
"59548", "Curuguaty",
"595678", "Santa\ Rosa\ Del\ Monday",
"595761", "Colonia\ Fram",
"595674", "Juan\ E\.\ O\ Leary",
"59542", "San\ Pedro\ Del\ Ycua\ Mandyju",
"595275", "Ypane",
"595294", "Itaugua",
"595677", "San\ Alberto",
"595785", "Paso\ De\ Patria",
"595631", "Hernandarias",
"59541", "Itacurubi\ Del\ Rosario",
"59538", "Bella\ Vista\ Norte",
"595767", "Bella\ Vista\ Sur",
"595291", "Aregua",
"59528", "Capiata",
"595782", "Santiago",
"595741", "Coronel\ Bogado",
"595673", "Santa\ Rita",
"59571", "Capitan\ Miranda",
"59572", "Ayolas",
"595295", "Jose\ Augusto\ Saldivar",
"595632", "Colonia\ Yguazu",
"595784", "San\ Juan\ Neembucu",
"59533", "Loreto",
"59575", "Hoenau",
"59561", "Presidente\ Franco",
"595292", "Nueva\ Italia",
"59524", "Ita",
"595763", "La\ Paz",
"595271", "Benjamin\ \ Aceval",
"595550", "Mauricio\ Jose\ Troche",
"595742", "San\ Pedro\ Del\ Parana",
"595553", "Tebicuary",
"59547", "Puente\ Kyha",
"59583", "Villa\ Florida",
"595781", "Santa\ María\ \/\ Misiones",
"595453", "Capiibary",
"59546", "Salto\ Del\ Guaira",
"595633", "Cedrales",
"595672", "Kressburgo",
"595552", "Paso\ Yobay",
"595743", "General\ Artigas",
"59526", "Villa\ Hayes",
"595740", "General\ \ Delgado",
"59537", "Capitan\ Bado",
"59536", "Pedro\ Juan\ Caballero",
"595675", "Juan\ Leon\ Mallorquin",
"595787", "General\ \ Diaz",
"59544", "Villa\ Del\ Rosario",
"59543", "San\ Estanislao",
"59586", "Pilar",
"595762", "Carmen\ Del\ Parana",
"595293", "Guarambare",};
my $timezones = {
               '' => [
                       'America/Asuncion'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+595|\D)//g;
      my $self = bless({ country_code => '595', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '595', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;