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
package Number::Phone::StubCountry::CO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240308154350;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '6',
                  'national_rule' => '($1)',
                  'pattern' => '(\\d{3})(\\d{7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            3[0-357]|
            91
          ',
                  'pattern' => '(\\d{3})(\\d{7})'
                },
                {
                  'format' => '$1-$2-$3',
                  'intl_format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{7})'
                }
              ];

my $validators = {
                'fixed_line' => '
          601055(?:
            [0-4]\\d|
            50
          )\\d\\d|
          6010(?:
            [0-4]\\d|
            5[0-4]
          )\\d{4}|
          60(?:
            [124-7][2-9]|
            8[1-9]
          )\\d{6}
        ',
                'geographic' => '
          601055(?:
            [0-4]\\d|
            50
          )\\d\\d|
          6010(?:
            [0-4]\\d|
            5[0-4]
          )\\d{4}|
          60(?:
            [124-7][2-9]|
            8[1-9]
          )\\d{6}
        ',
                'mobile' => '
          333301[0-5]\\d{3}|
          3333(?:
            00|
            2[5-9]|
            [3-9]\\d
          )\\d{4}|
          (?:
            3(?:
              24[1-9]|
              3(?:
                00|
                3[0-24-9]
              )
            )|
            9101
          )\\d{6}|
          3(?:
            0[0-5]|
            1\\d|
            2[0-3]|
            5[01]|
            70
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          19(?:
            0[01]|
            4[78]
          )\\d{7}
        )',
                'toll_free' => '1800\\d{7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{es} = {};
$areanames{en} = {"576018373", "Beltrán",
"5760230", "Cali",
"576018444", "Villeta",
"5760758", "Cucuta",
"57601831", "Girardot",
"5760538", "Barranquilla",
"576014", "Bogotá",
"5760289", "Cali",
"576018453", "La\ Florida",
"5760827", "Ibague",
"5760292", "Cali",
"576018434", "Cartagenita",
"5760533", "Barranquilla",
"576018376", "Tocaima",
"576018384", "Viota",
"5760557", "Valledupar",
"576018451", "Nocaima",
"576018450", "San\ Antonio\ de\ Tequendama",
"5760765", "Bucaramanga",
"5760534", "Barranquilla",
"57604917", "Medellín",
"57601833", "Girardot",
"576018371", "Guataqui",
"5760536", "Barranquilla",
"576015", "Bogotá",
"576048724", "Medellín",
"5760288", "Cali",
"576018370", "Jerusalén",
"5760635", "Pereira",
"576018255", "Madrid",
"576042", "Medellín",
"57601826", "Funza",
"57601822", "Funza",
"576048720", "Medellín",
"576018436", "Facatativa",
"57604913", "Medellín",
"576018442", "Cachipay",
"5760234", "Cali",
"576018482", "La\ Magdalena",
"576018447", "Villeta",
"576018393", "Girardot",
"57601820", "Madrid",
"5760236", "Cali",
"576018397", "Apulo",
"576018443", "Cachipay",
"576048721", "Medellín",
"576018392", "Nilo\/La\ Esmeralda",
"5760826", "Ibague",
"576010", "Cundinamarca",
"576048510", "Medellín",
"5760231", "Cali",
"576018437", "Facatativa",
"5760492", "Medellín",
"576018446", "Villeta",
"576018381", "Agua\ de\ Dios",
"576018289", "Madrid",
"5760866", "Villavicencio",
"576048511", "Medellín",
"576018433", "Ninaima\/Tobia",
"576018249", "Zipacon",
"5760537", "Barranquilla",
"5760757", "Cucuta",
"576018383", "Nilo",
"5760273", "Pasto",
"576048726", "Medellín",
"5760632", "Pereira",
"576018245", "Subachoque",
"576018430", "Facatativa",
"576018417", "Guaduas",
"576049092", "Medellín",
"57604842", "Medellín",
"576018431", "Facatativa",
"576056295", "Cartagena",
"576018438", "Facatativa",
"5760233", "Cali",
"5760565", "Cartagena",
"576018412", "Santa\ Inés",
"576018440", "Facatativa",
"576048722", "Medellín",
"576017", "Bogotá",
"576018398", "Apulo",
"576018480", "Quebradanegra",
"576018416", "Guaduas",
"57604911", "Medellín",
"576048723", "Medellín",
"576018481", "Quebradanegra",
"576013", "Bogotá",
"576018441", "Viani",
"576018386", "Apulo",
"5760566", "Cartagena",
"57601842", "Facatativa",
"5760532", "Barranquilla",
"5760637", "Eje\ Cafetero",
"576018250", "Madrid",
"5760689", "Manizales",
"576043", "Medellín",
"576018375", "Nariño",
"5760767", "Bucaramanga",
"576018251", "Madrid",
"57601821", "Funza",
"576018252", "Madrid",
"5760886", "Neiva",
"5760235", "Cali",
"5760688", "Manizales",
"576018257", "Funza",
"57601832", "Girardot",
"576018253", "Madrid",
"576018403", "Choachi",
"5760568", "Cartagena",
"576018256", "Madrid",
"576018402", "San\ Antonio\ de\ Tequendama",
"576016", "Bogotá",
"576018241", "El\ Rosal",
"576018288", "Madrid",
"5760764", "Bucaramanga",
"576018419", "Pandi",
"576018240", "El\ Rosal",
"576018435", "Cartagenita",
"5760631", "Pereira",
"5760687", "Manizales",
"5760790", "Bucaramanga",
"5760535", "Barranquilla",
"576012", "Bogotá",
"5760636", "Eje\ Cafetero",
"57601827", "Mosquera",
"576045", "Medellín",
"5760761", "Bucaramanga",
"576018445", "Villeta",
"576018230", "Subachoque",
"5760634", "Pereira",
"57601830", "Girardot",
"5760567", "Cartagena",
"576044", "Medellín",
"5760290", "Cali",
"5760763", "Bucaramanga",
"5760638", "Eje\ Cafetero",
"576018449", "La\ Peña",
"576018254", "Madrid",
"576048725", "Medellín",
"576018246", "Puente\ Piedra",
"576018232", "Funza",
"576018404", "Fomeque",
"576018243", "Bojaca",
"576018439", "Facatativa",
"5760768", "Bucaramanga",
"5760633", "Pereira",
"5760272", "Pasto",
"576018385", "Nariño",
"576018283", "Mosquera",
"576018242", "La\ Pradera\/Subachoque\/Subachique",
"5760887", "Neiva",
"5760232", "Cali",
"576018247", "La\ Punta",};
my $timezones = {
               '' => [
                       'America/Bogota'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+57|\D)//g;
      my $self = bless({ country_code => '57', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0([3579]|4(?:[14]4|56))?)//;
      $self = bless({ country_code => '57', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;