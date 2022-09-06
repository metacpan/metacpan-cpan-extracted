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
package Number::Phone::StubCountry::PY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220903144943;

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
              8[1-6]
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
            [78][1-6]|
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
$areanames{en} = {"59572", "Ayolas",
"595743", "General\ Artigas",
"595673", "Santa\ Rita",
"595782", "Santiago",
"59547", "Puente\ Kyha",
"595768", "Pirapo",
"595275", "Ypane",
"59544", "Villa\ Del\ Rosario",
"59539", "Yby\ Ja\'U",
"59585", "Santa\ Rosa\ \/\ Misiones",
"59525", "Villeta",
"595292", "Nueva\ Italia",
"59524", "Ita",
"595785", "Paso\ De\ Patria",
"595345", "Corpus\ Christi",
"595674", "Juan\ E\.\ O\ Leary",
"59535", "Valle\ Mi",
"59537", "Capitan\ Bado",
"595295", "Jose\ Augusto\ Saldivar",
"59561", "Presidente\ Franco",
"59571", "Capitan\ Miranda",
"595552", "Paso\ Yobay",
"595671", "Mayor\ Otano",
"59573", "San\ Cosme",
"595741", "Coronel\ Bogado",
"595740", "General\ \ Delgado",
"595632", "Colonia\ Yguazu",
"595677", "San\ Alberto",
"595762", "Carmen\ Del\ Parana",
"59548", "Curuguaty",
"59532", "Horqueta",
"595672", "Kressburgo",
"595783", "San\ Miguel\ \/\ Misiones",
"595742", "San\ Pedro\ Del\ Parana",
"595767", "Bella\ Vista\ Sur",
"595293", "Guarambare",
"59528", "Capiata",
"595676", "Naranjal",
"595784", "San\ Juan\ Neembucu",
"595761", "Colonia\ Fram",
"595675", "Juan\ Leon\ Mallorquin",
"59582", "San\ Ignacio\ \/\ Misiones",
"59575", "Hoenau",
"59542", "San\ Pedro\ Del\ Ycua\ Mandyju",
"595294", "Itaugua",
"595453", "Capiibary",
"595550", "Mauricio\ Jose\ Troche",
"59564", "Cargil",
"59538", "Bella\ Vista\ Norte",
"595631", "Hernandarias",
"59536", "Pedro\ Juan\ Caballero",
"59531", "Concepcion",
"595291", "Aregua",
"595781", "Santa\ María\ \/\ Misiones",
"595764", "Maria\ Auxiliadora",
"59533", "Loreto",
"595553", "Tebicuary",
"59581", "San\ Juan\ Bautista\ \/\ Misiones",
"59521", "Fernando\ De\ La\ Mora\,\ Lambare\,\ Limpio\,\ Luque\,\ Mariano\ Roque\ Alonso\,\ San\ Antonio\,\ Valle\ Pucu\ and\ Villa\ Elisa",
"595633", "Cedrales",
"59543", "San\ Estanislao",
"595451", "Colonia\ Volendam",
"59586", "Pilar",
"59526", "Villa\ Hayes",
"595780", "Alberdi",
"595787", "General\ \ Diaz",
"59583", "Villa\ Florida",
"59541", "Itacurubi\ Del\ Rosario",
"595763", "La\ Paz",
"595554", "Itape",
"595271", "Benjamin\ \ Aceval",
"59546", "Salto\ Del\ Guaira",
"595678", "Santa\ Rosa\ Del\ Monday",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+595|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;