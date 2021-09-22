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
package Number::Phone::StubCountry::CO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210921211831;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [146][2-9]|
            [2578]
          ',
                  'national_rule' => '($1)',
                  'pattern' => '(\\d)(\\d{7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '6',
                  'national_rule' => '($1)',
                  'pattern' => '(\\d{3})(\\d{7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[39]',
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
          60[124-8][2-9]\\d{6}|
          [124-8][2-9]\\d{6}
        ',
                'geographic' => '
          60[124-8][2-9]\\d{6}|
          [124-8][2-9]\\d{6}
        ',
                'mobile' => '
          3333(?:
            0(?:
              0\\d|
              1[0-5]
            )|
            [4-9]\\d\\d
          )\\d{3}|
          (?:
            3(?:
              24[2-6]|
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
$areanames{en} = {"576018243", "Bojaca",
"5760288", "Cali",
"5748511", "Medellín",
"5760231", "Cali",
"5760230", "Cali",
"5748510", "Medellín",
"576018257", "Funza",
"57562951", "Cartagena",
"5718384", "Viota",
"576048725", "Medellín",
"57183929", "La\ Esmeralda",
"5760535", "Barranquilla",
"576016", "Bogotá",
"57182428", "Subachoque",
"576048723", "Medellín",
"576018381", "Agua\ de\ Dios",
"571845344", "La\ Florida",
"576018403", "Choachi",
"57183927", "Nilo",
"576018283", "Mosquera",
"576018245", "Subachoque",
"5748722", "Medellín",
"57757", "Cucuta",
"57292", "Cali",
"57566", "Cartagena",
"5718438", "Facatativa",
"5760768", "Bucaramanga",
"5760235", "Cali",
"5718481", "Quebradanegra",
"5718249", "Zipacon",
"5718449", "La\ Peña",
"5718480", "Quebradanegra",
"571822", "Funza",
"571842", "Facatativa",
"57273", "Pasto",
"5760767", "Bucaramanga",
"5718437", "Facatativa",
"576048510", "Medellín",
"57562959", "Cartagena",
"5742", "Medellín",
"5718436", "Facatativa",
"57230", "Cali",
"576018416", "Guaduas",
"5760634", "Pereira",
"5718404", "Fomeque",
"574913", "Medellín",
"57183925", "Nilo",
"57562957", "Cartagena",
"576018397", "Apulo",
"5749092", "Medellín",
"5760635", "Pereira",
"57565", "Cartagena",
"5718373", "Beltrán",
"576018442", "Cachipay",
"5760757", "Cucuta",
"5760234", "Cali",
"576018288", "Madrid",
"57272", "Pasto",
"576018482", "La\ Magdalena",
"571832", "Girardot",
"576018430", "Facatativa",
"5718381", "Agua\ de\ Dios",
"5718393", "Girardot",
"5760758", "Cucuta",
"576012", "Bogotá",
"5760534", "Barranquilla",
"5718412", "Santa\ Inés",
"576018385", "Nariño",
"5760631", "Pereira",
"57184332", "Ninaima",
"571826", "Funza",
"5717", "Bogotá",
"576014", "Bogotá",
"5760688", "Manizales",
"5744", "Medellín",
"5760790", "Bucaramanga",
"576018241", "El\ Rosal",
"576015", "Bogotá",
"576018480", "Quebradanegra",
"5760687", "Manizales",
"57184330", "Ninaima",
"576018440", "Facatativa",
"576018383", "Nilo",
"576048721", "Medellín",
"5718385", "Nariño",
"5748723", "Medellín",
"57768", "Bucaramanga",
"576018449", "La\ Peña",
"57290", "Cali",
"5718398", "Apulo",
"5718376", "Tocaima",
"57289", "Cali",
"57687", "Manizales",
"57601842", "Facatativa",
"5718254", "Madrid",
"57235", "Cali",
"5718232", "Funza",
"5713", "Bogotá",
"576018392", "Nilo\/La\ Esmeralda",
"576018453", "La\ Florida",
"57288", "Cali",
"5718444", "Villeta",
"576018384", "Viota",
"571845341", "La\ Florida",
"576018447", "Villeta",
"5718397", "Apulo",
"57601826", "Funza",
"57538", "Barranquilla",
"576048726", "Medellín",
"57234", "Cali",
"57232", "Cali",
"576018370", "Jerusalén",
"576018439", "Facatativa",
"57631", "Pereira",
"5715", "Bogotá",
"5760568", "Cartagena",
"57790", "Bucaramanga",
"576018246", "Puente\ Piedra",
"576018437", "Facatativa",
"5760566", "Cartagena",
"5760567", "Cartagena",
"571820", "Madrid",
"5748726", "Medellín",
"576056295", "Cartagena",
"5760557", "Valledupar",
"571830", "Girardot",
"5718416", "Guaduas",
"57236", "Cali",
"57567", "Cartagena",
"5718451", "Nocaima",
"5718251", "Madrid",
"5718450", "San\ Antonio\ de\ Tequendama",
"57604911", "Medellín",
"5718417", "Guaduas",
"5718250", "Madrid",
"574911", "Medellín",
"576018386", "Apulo",
"5718440", "Facatativa",
"5718240", "El\ Rosal",
"5718289", "Madrid",
"5718441", "Viani",
"5718241", "El\ Rosal",
"5760290", "Cali",
"57601833", "Girardot",
"576018252", "Madrid",
"576043", "Medellín",
"57233", "Cali",
"57761", "Bucaramanga",
"576018250", "Madrid",
"57184331", "Ninaima",
"5718255", "Madrid",
"5718245", "Subachoque",
"5718445", "Villeta",
"571845345", "La\ Florida",
"576018404", "Fomeque",
"57604917", "Medellín",
"5760763", "Bucaramanga",
"576048724", "Medellín",
"571845343", "La\ Florida",
"576018451", "Nocaima",
"574917", "Medellín",
"576018375", "Nariño",
"576018412", "Santa\ Inés",
"5760761", "Bucaramanga",
"5760536", "Barranquilla",
"5718230", "Subachoque",
"5718430", "Facatativa",
"5718431", "Facatativa",
"576018434", "Cartagenita",
"5760537", "Barranquilla",
"57492", "Medellín",
"5718288", "Madrid",
"576018393", "Girardot",
"576045", "Medellín",
"5718419", "Pandi",
"571827", "Mosquera",
"576018373", "Beltrán",
"5760827", "Ibague",
"57767", "Bucaramanga",
"5760826", "Ibague",
"576044", "Medellín",
"5760538", "Barranquilla",
"571821", "Funza",
"57536", "Barranquilla",
"576042", "Medellín",
"576018444", "Villeta",
"576018450", "San\ Antonio\ de\ Tequendama",
"57601830", "Girardot",
"5718435", "Cartagenita",
"5760765", "Bucaramanga",
"576018251", "Madrid",
"5718243", "Bojaca",
"5718443", "Cachipay",
"57826", "Ibague",
"5760273", "Pasto",
"5760236", "Cali",
"57533", "Barranquilla",
"57601832", "Girardot",
"5718253", "Madrid",
"57532", "Barranquilla",
"57534", "Barranquilla",
"576018255", "Madrid",
"57562956", "Cartagena",
"571845340", "La\ Florida",
"5760492", "Medellín",
"57601820", "Madrid",
"5760292", "Cali",
"576018249", "Zipacon",
"5718442", "Cachipay",
"576018247", "La\ Punta",
"5760866", "Villavicencio",
"576018289", "Madrid",
"5760272", "Pasto",
"576018398", "Apulo",
"5718252", "Madrid",
"57601822", "Funza",
"5760764", "Bucaramanga",
"576018253", "Madrid",
"576018436", "Facatativa",
"5718434", "Cartagenita",
"5743", "Medellín",
"57562958", "Cartagena",
"571831", "Girardot",
"576017", "Bogotá",
"5718386", "Apulo",
"5745", "Medellín",
"57887", "Neiva",
"57866", "Villavicencio",
"57183926", "Nilo",
"571845342", "La\ Florida",
"576018371", "Guataqui",
"57535", "Barranquilla",
"57183928", "Nilo",
"57758", "Cucuta",
"576018446", "Villeta",
"57182429", "Subachique",
"5748720", "Medellín",
"5748721", "Medellín",
"576018431", "Facatativa",
"576018242", "La\ Pradera\/Subachoque\/Subachique",
"57184333", "Tobia",
"576018402", "San\ Antonio\ de\ Tequendama",
"5718375", "Nariño",
"576048722", "Medellín",
"57765", "Bucaramanga",
"5760232", "Cali",
"5760633", "Pereira",
"5718403", "Choachi",
"576018230", "Subachoque",
"5714", "Bogotá",
"5760565", "Cartagena",
"576018438", "Facatativa",
"576013", "Bogotá",
"57568", "Cartagena",
"5748725", "Medellín",
"5760689", "Manizales",
"57764", "Bucaramanga",
"576018232", "Funza",
"5718383", "Nilo",
"576018441", "Viani",
"57184334", "Tobia",
"5716", "Bogotá",
"576048720", "Medellín",
"5760532", "Barranquilla",
"571833", "Girardot",
"576018376", "Tocaima",
"57633", "Pereira",
"57604913", "Medellín",
"57886", "Neiva",
"5718370", "Jerusalén",
"5718371", "Guataqui",
"57601831", "Girardot",
"5718482", "La\ Magdalena",
"576018240", "El\ Rosal",
"576018481", "Quebradanegra",
"576018254", "Madrid",
"57557", "Valledupar",
"5760289", "Cali",
"5760887", "Neiva",
"576018443", "Cachipay",
"5760533", "Barranquilla",
"5760886", "Neiva",
"576018419", "Pandi",
"576018445", "Villeta",
"57182420", "La\ Pradera",
"576018417", "Guaduas",
"57634", "Pereira",
"57632", "Pereira",
"5748724", "Medellín",
"57601821", "Funza",
"57763", "Bucaramanga",
"5718283", "Mosquera",
"57231", "Cali",
"574842", "Medellín",
"57827", "Ibague",
"5718439", "Facatativa",
"57635", "Pereira",
"576048511", "Medellín",
"57604842", "Medellín",
"57601827", "Mosquera",
"57688", "Manizales",
"576018433", "Ninaima\/Tobia",
"576049092", "Medellín",
"576018256", "Madrid",
"5718446", "Villeta",
"5718246", "Puente\ Piedra",
"576018435", "Cartagenita",
"5718247", "La\ Punta",
"5718447", "Villeta",
"5718256", "Madrid",
"57537", "Barranquilla",
"5760233", "Cali",
"57689", "Manizales",
"5712", "Bogotá",
"5718257", "Funza",
"5718402", "San\ Antonio\ de\ Tequendama",
"5760632", "Pereira",};
$areanames{es} = {};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+57|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0([3579]|4(?:[14]4|56))?)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;