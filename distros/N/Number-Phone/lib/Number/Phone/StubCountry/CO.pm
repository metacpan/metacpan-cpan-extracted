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
our $VERSION = 1.20211206222444;

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
$areanames{en} = {"5743", "Medellín",
"5760631", "Pereira",
"5760768", "Bucaramanga",
"57631", "Pereira",
"57601827", "Mosquera",
"5760565", "Cartagena",
"576018453", "La\ Florida",
"576018288", "Madrid",
"5760536", "Barranquilla",
"5760273", "Pasto",
"57272", "Pasto",
"5760567", "Cartagena",
"574911", "Medellín",
"5718370", "Jerusalén",
"574913", "Medellín",
"57562959", "Cartagena",
"576018240", "El\ Rosal",
"5718255", "Madrid",
"576048726", "Medellín",
"576018441", "Viani",
"5748725", "Medellín",
"5718442", "Cachipay",
"5718450", "San\ Antonio\ de\ Tequendama",
"576018430", "Facatativa",
"57230", "Cali",
"5718257", "Funza",
"576018444", "Villeta",
"57562957", "Cartagena",
"57790", "Bucaramanga",
"576018447", "Villeta",
"57290", "Cali",
"57537", "Barranquilla",
"5760292", "Cali",
"5760634", "Pereira",
"5718383", "Nilo",
"571821", "Funza",
"5718430", "Facatativa",
"5760534", "Barranquilla",
"5760763", "Bucaramanga",
"576018445", "Villeta",
"57562951", "Cartagena",
"5760288", "Cali",
"57182429", "Subachique",
"57764", "Bucaramanga",
"571826", "Funza",
"576018250", "Madrid",
"5718404", "Fomeque",
"5718373", "Beltrán",
"5745", "Medellín",
"571832", "Girardot",
"57183928", "Nilo",
"57538", "Barranquilla",
"5718256", "Madrid",
"5718438", "Facatativa",
"5748721", "Medellín",
"5748726", "Medellín",
"576018443", "Cachipay",
"57601826", "Funza",
"5718251", "Madrid",
"57184330", "Ninaima",
"5718254", "Madrid",
"57289", "Cali",
"5748724", "Medellín",
"5760758", "Cucuta",
"5760537", "Barranquilla",
"57562956", "Cartagena",
"576048722", "Medellín",
"57233", "Cali",
"5714", "Bogotá",
"57557", "Valledupar",
"5760566", "Cartagena",
"57601822", "Funza",
"57601821", "Funza",
"5760557", "Valledupar",
"57236", "Cali",
"57235", "Cali",
"576018451", "Nocaima",
"5760635", "Pereira",
"5760535", "Barranquilla",
"576018449", "La\ Peña",
"5718386", "Apulo",
"576048724", "Medellín",
"5713", "Bogotá",
"576042", "Medellín",
"5718375", "Nariño",
"5718419", "Pandi",
"576018283", "Mosquera",
"5718439", "Facatativa",
"5718381", "Agua\ de\ Dios",
"5760757", "Cucuta",
"5760538", "Barranquilla",
"5760761", "Bucaramanga",
"57183929", "La\ Esmeralda",
"576048511", "Medellín",
"576018446", "Villeta",
"57182428", "Subachoque",
"571820", "Madrid",
"576048721", "Medellín",
"5760289", "Cali",
"57183927", "Nilo",
"576018289", "Madrid",
"57758", "Cucuta",
"5718435", "Cartagenita",
"57184333", "Tobia",
"576013", "Bogotá",
"57231", "Cali",
"5718230", "Subachoque",
"5760492", "Medellín",
"5718437", "Facatativa",
"57182420", "La\ Pradera",
"5718384", "Viota",
"5760633", "Pereira",
"5760533", "Barranquilla",
"5760764", "Bucaramanga",
"5748720", "Medellín",
"576015", "Bogotá",
"571845340", "La\ Florida",
"5718417", "Guaduas",
"5718250", "Madrid",
"576018370", "Jerusalén",
"5718403", "Choachi",
"57689", "Manizales",
"57562958", "Cartagena",
"576018480", "Quebradanegra",
"5760232", "Cali",
"57184331", "Ninaima",
"57533", "Barranquilla",
"57184332", "Ninaima",
"5718451", "Nocaima",
"57757", "Cucuta",
"57535", "Barranquilla",
"57536", "Barranquilla",
"57604842", "Medellín",
"5715", "Bogotá",
"57601820", "Madrid",
"5718482", "La\ Magdalena",
"57635", "Pereira",
"576016", "Bogotá",
"5718436", "Facatativa",
"5718431", "Facatativa",
"5718416", "Guaduas",
"57633", "Pereira",
"576018442", "Cachipay",
"576044", "Medellín",
"5718434", "Cartagenita",
"5748723", "Medellín",
"5760767", "Bucaramanga",
"576048723", "Medellín",
"5760866", "Villavicencio",
"5760790", "Bucaramanga",
"5718253", "Madrid",
"576018232", "Funza",
"5718376", "Tocaima",
"5718385", "Nariño",
"5744", "Medellín",
"5760765", "Bucaramanga",
"576048725", "Medellín",
"5760568", "Cartagena",
"5718371", "Guataqui",
"57183926", "Nilo",
"57273", "Pasto",
"571845345", "La\ Florida",
"576018375", "Nariño",
"576018438", "Facatativa",
"5760290", "Cali",
"5718412", "Santa\ Inés",
"576017", "Bogotá",
"5718481", "Quebradanegra",
"5718247", "La\ Punta",
"5718288", "Madrid",
"57761", "Bucaramanga",
"5718440", "Facatativa",
"5718393", "Girardot",
"5760236", "Cali",
"576018481", "Quebradanegra",
"57827", "Ibague",
"57601831", "Girardot",
"5760231", "Cali",
"576018373", "Beltrán",
"57601832", "Girardot",
"571845343", "La\ Florida",
"5718245", "Subachoque",
"5760887", "Neiva",
"571833", "Girardot",
"576018256", "Madrid",
"5760234", "Cali",
"576018386", "Apulo",
"576018416", "Guaduas",
"576018404", "Fomeque",
"5718398", "Apulo",
"5718283", "Mosquera",
"571831", "Girardot",
"5718249", "Zipacon",
"576018393", "Girardot",
"5716", "Bogotá",
"57767", "Bucaramanga",
"5748510", "Medellín",
"57688", "Manizales",
"57183925", "Nilo",
"576056295", "Cartagena",
"576018242", "La\ Pradera\/Subachoque\/Subachique",
"571822", "Funza",
"576018403", "Choachi",
"5718443", "Cachipay",
"57534", "Barranquilla",
"5760886", "Neiva",
"576018436", "Facatativa",
"576048720", "Medellín",
"57886", "Neiva",
"57687", "Manizales",
"574842", "Medellín",
"576018397", "Apulo",
"57634", "Pereira",
"5760688", "Manizales",
"576048510", "Medellín",
"5712", "Bogotá",
"57768", "Bucaramanga",
"5760272", "Pasto",
"576018412", "Santa\ Inés",
"57232", "Cali",
"5718241", "El\ Rosal",
"5760235", "Cali",
"5718246", "Puente\ Piedra",
"571845341", "La\ Florida",
"576018371", "Guataqui",
"576018252", "Madrid",
"571845344", "La\ Florida",
"57292", "Cali",
"57601833", "Girardot",
"576018246", "Puente\ Piedra",
"57565", "Cartagena",
"57184334", "Tobia",
"57566", "Cartagena",
"576018384", "Viota",
"5718240", "El\ Rosal",
"576018254", "Madrid",
"5760827", "Ibague",
"5760689", "Manizales",
"576018417", "Guaduas",
"5718252", "Madrid",
"576014", "Bogotá",
"5718445", "Villeta",
"576018257", "Funza",
"5748722", "Medellín",
"576018433", "Ninaima\/Tobia",
"571830", "Girardot",
"57866", "Villavicencio",
"57567", "Cartagena",
"57288", "Cali",
"576018435", "Cartagenita",
"576049092", "Medellín",
"5718232", "Funza",
"57601842", "Facatativa",
"571827", "Mosquera",
"576018251", "Madrid",
"576018381", "Agua\ de\ Dios",
"5718447", "Villeta",
"576018249", "Zipacon",
"571845342", "La\ Florida",
"576018245", "Subachoque",
"57492", "Medellín",
"5718449", "La\ Peña",
"5760233", "Cali",
"576018439", "Facatativa",
"5718402", "San\ Antonio\ de\ Tequendama",
"57604917", "Medellín",
"576018450", "San\ Antonio\ de\ Tequendama",
"57604913", "Medellín",
"576018392", "Nilo\/La\ Esmeralda",
"576018243", "Bojaca",
"576018398", "Apulo",
"57887", "Neiva",
"57601830", "Girardot",
"5760687", "Manizales",
"574917", "Medellín",
"57765", "Bucaramanga",
"5749092", "Medellín",
"576018419", "Pandi",
"576018402", "San\ Antonio\ de\ Tequendama",
"5718444", "Villeta",
"5718397", "Apulo",
"576018241", "El\ Rosal",
"57763", "Bucaramanga",
"57632", "Pereira",
"5718289", "Madrid",
"576018230", "Subachoque",
"571842", "Facatativa",
"5718243", "Bojaca",
"576018376", "Tocaima",
"57532", "Barranquilla",
"576012", "Bogotá",
"576018247", "La\ Punta",
"5742", "Medellín",
"5760532", "Barranquilla",
"57604911", "Medellín",
"5748511", "Medellín",
"5760632", "Pereira",
"576018482", "La\ Magdalena",
"57826", "Ibague",
"576045", "Medellín",
"5760826", "Ibague",
"576018434", "Cartagenita",
"57568", "Cartagena",
"576018383", "Nilo",
"576018437", "Facatativa",
"576018253", "Madrid",
"5718480", "Quebradanegra",
"576018255", "Madrid",
"57234", "Cali",
"576043", "Medellín",
"576018385", "Nariño",
"5717", "Bogotá",
"5718441", "Viani",
"576018431", "Facatativa",
"5718446", "Villeta",
"5760230", "Cali",
"576018440", "Facatativa",};
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