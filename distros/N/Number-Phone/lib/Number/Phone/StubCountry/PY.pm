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
our $VERSION = 1.20200309202348;

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
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{6})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-8]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
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
                'toll_free' => '',
                'voip' => '8700[0-4]\\d{4}'
              };
my %areanames = ();
$areanames{en}->{59521} = "Fernando\ De\ La\ Mora\,\ Lambare\,\ Limpio\,\ Luque\,\ Mariano\ Roque\ Alonso\,\ San\ Antonio\,\ Valle\ Pucu\ and\ Villa\ Elisa";
$areanames{en}->{59524} = "Ita";
$areanames{en}->{59525} = "Villeta";
$areanames{en}->{59526} = "Villa\ Hayes";
$areanames{en}->{595271} = "Benjamin\ \ Aceval";
$areanames{en}->{595275} = "Ypane";
$areanames{en}->{59528} = "Capiata";
$areanames{en}->{595291} = "Aregua";
$areanames{en}->{595292} = "Nueva\ Italia";
$areanames{en}->{595293} = "Guarambare";
$areanames{en}->{595294} = "Itaugua";
$areanames{en}->{595295} = "Jose\ Augusto\ Saldivar";
$areanames{en}->{59531} = "Concepcion";
$areanames{en}->{59532} = "Horqueta";
$areanames{en}->{59533} = "Loreto";
$areanames{en}->{595345} = "Corpus\ Christi";
$areanames{en}->{59535} = "Valle\ Mi";
$areanames{en}->{59536} = "Pedro\ Juan\ Caballero";
$areanames{en}->{59537} = "Capitan\ Bado";
$areanames{en}->{59538} = "Bella\ Vista\ Norte";
$areanames{en}->{59539} = "Yby\ Ja\'U";
$areanames{en}->{59541} = "Itacurubi\ Del\ Rosario";
$areanames{en}->{59542} = "San\ Pedro\ Del\ Ycua\ Mandyju";
$areanames{en}->{59543} = "San\ Estanislao";
$areanames{en}->{59544} = "Villa\ Del\ Rosario";
$areanames{en}->{595451} = "Colonia\ Volendam";
$areanames{en}->{595453} = "Capiibary";
$areanames{en}->{59546} = "Salto\ Del\ Guaira";
$areanames{en}->{59547} = "Puente\ Kyha";
$areanames{en}->{59548} = "Curuguaty";
$areanames{en}->{595550} = "Mauricio\ Jose\ Troche";
$areanames{en}->{595552} = "Paso\ Yobay";
$areanames{en}->{595553} = "Tebicuary";
$areanames{en}->{595554} = "Itape";
$areanames{en}->{59561} = "Presidente\ Franco";
$areanames{en}->{595631} = "Hernandarias";
$areanames{en}->{595632} = "Colonia\ Yguazu";
$areanames{en}->{595633} = "Cedrales";
$areanames{en}->{59564} = "Cargil";
$areanames{en}->{595671} = "Mayor\ Otano";
$areanames{en}->{595672} = "Kressburgo";
$areanames{en}->{595673} = "Santa\ Rita";
$areanames{en}->{595674} = "Juan\ E\.\ O\ Leary";
$areanames{en}->{595675} = "Juan\ Leon\ Mallorquin";
$areanames{en}->{595676} = "Naranjal";
$areanames{en}->{595677} = "San\ Alberto";
$areanames{en}->{595678} = "Santa\ Rosa\ Del\ Monday";
$areanames{en}->{59571} = "Capitan\ Miranda";
$areanames{en}->{59572} = "Ayolas";
$areanames{en}->{59573} = "San\ Cosme";
$areanames{en}->{595740} = "General\ \ Delgado";
$areanames{en}->{595741} = "Coronel\ Bogado";
$areanames{en}->{595742} = "San\ Pedro\ Del\ Parana";
$areanames{en}->{595743} = "General\ Artigas";
$areanames{en}->{59575} = "Hoenau";
$areanames{en}->{595761} = "Colonia\ Fram";
$areanames{en}->{595762} = "Carmen\ Del\ Parana";
$areanames{en}->{595763} = "La\ Paz";
$areanames{en}->{595764} = "Maria\ Auxiliadora";
$areanames{en}->{595767} = "Bella\ Vista\ Sur";
$areanames{en}->{595768} = "Pirapo";
$areanames{en}->{595780} = "Alberdi";
$areanames{en}->{595781} = "Santa\ María\ \/\ Misiones";
$areanames{en}->{595782} = "Santiago";
$areanames{en}->{595783} = "San\ Miguel\ \/\ Misiones";
$areanames{en}->{595784} = "San\ Juan\ Neembucu";
$areanames{en}->{595785} = "Paso\ De\ Patria";
$areanames{en}->{595787} = "General\ \ Diaz";
$areanames{en}->{59581} = "San\ Juan\ Bautista\ \/\ Misiones";
$areanames{en}->{59582} = "San\ Ignacio\ \/\ Misiones";
$areanames{en}->{59583} = "Villa\ Florida";
$areanames{en}->{59585} = "Santa\ Rosa\ \/\ Misiones";
$areanames{en}->{59586} = "Pilar";

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