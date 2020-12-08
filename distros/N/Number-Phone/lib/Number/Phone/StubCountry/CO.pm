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
our $VERSION = 1.20201204215956;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [14][2-9]|
            [25-8]
          ',
                  'national_rule' => '($1)',
                  'pattern' => '(\\d)(\\d{7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '3',
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
                'fixed_line' => '[124-8][2-9]\\d{6}',
                'geographic' => '[124-8][2-9]\\d{6}',
                'mobile' => '
          3333(?:
            0(?:
              0\\d|
              1[0-5]
            )|
            [4-9]\\d\\d
          )\\d{3}|
          33(?:
            00|
            3[0-24-9]
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
$areanames{en} = {"57183925", "Nilo",
"57758", "Cucuta",
"57533", "Barranquilla",
"5718435", "Cartagenita",
"5718371", "Guataqui",
"57632", "Pereira",
"5718443", "Cachipay",
"571845342", "La\ Florida",
"571832", "Girardot",
"57562959", "Cartagena",
"5742", "Medellín",
"57492", "Medellín",
"5718385", "Nariño",
"5748510", "Medellín",
"571845343", "La\ Florida",
"57562956", "Cartagena",
"5718370", "Jerusalén",
"57234", "Cali",
"5718245", "Subachoque",
"5716", "Bogotá",
"5718255", "Madrid",
"5748511", "Medellín",
"57687", "Manizales",
"5748725", "Medellín",
"57183928", "Nilo",
"57763", "Bucaramanga",
"5718383", "Nilo",
"57183927", "Nilo",
"57184332", "Ninaima",
"5718445", "Villeta",
"5718402", "San\ Antonio\ de\ Tequendama",
"57568", "Cartagena",
"57232", "Cali",
"574917", "Medellín",
"5748723", "Medellín",
"5749092", "Medellín",
"571830", "Girardot",
"5718397", "Apulo",
"5718482", "La\ Magdalena",
"57761", "Bucaramanga",
"57634", "Pereira",
"5718253", "Madrid",
"5718243", "Bojaca",
"5718419", "Pandi",
"5718386", "Apulo",
"57230", "Cali",
"5713", "Bogotá",
"57233", "Cali",
"5718442", "Cachipay",
"5718283", "Mosquera",
"5718436", "Facatativa",
"5715", "Bogotá",
"5748726", "Medellín",
"5718398", "Apulo",
"57289", "Cali",
"57534", "Barranquilla",
"5718256", "Madrid",
"57768", "Bucaramanga",
"5718246", "Puente\ Piedra",
"57866", "Villavicencio",
"571842", "Facatativa",
"57562951", "Cartagena",
"57231", "Cali",
"571820", "Madrid",
"5718232", "Funza",
"57184333", "Tobia",
"571822", "Funza",
"5718446", "Villeta",
"5718403", "Choachi",
"57532", "Barranquilla",
"57633", "Pereira",
"5744", "Medellín",
"57182429", "Subachique",
"57764", "Bucaramanga",
"5718252", "Madrid",
"57631", "Pereira",
"5718417", "Guaduas",
"574911", "Medellín",
"57538", "Barranquilla",
"57184331", "Ninaima",
"5748722", "Medellín",
"571833", "Girardot",
"57689", "Manizales",
"5718393", "Girardot",
"5718412", "Santa\ Inés",
"57235", "Cali",
"5712", "Bogotá",
"571845340", "La\ Florida",
"57273", "Pasto",
"5717", "Bogotá",
"5718247", "La\ Punta",
"571845344", "La\ Florida",
"5718257", "Funza",
"57182428", "Subachoque",
"5718437", "Facatativa",
"57767", "Bucaramanga",
"574913", "Medellín",
"5718288", "Madrid",
"571831", "Girardot",
"57565", "Cartagena",
"57292", "Cali",
"571827", "Mosquera",
"57635", "Pereira",
"57536", "Barranquilla",
"5718404", "Fomeque",
"5718480", "Quebradanegra",
"57182420", "La\ Pradera",
"5718376", "Tocaima",
"571826", "Funza",
"5718416", "Guaduas",
"5718447", "Villeta",
"57557", "Valledupar",
"57537", "Barranquilla",
"571845345", "La\ Florida",
"5718481", "Quebradanegra",
"5718289", "Madrid",
"5743", "Medellín",
"57757", "Cucuta",
"57886", "Neiva",
"57826", "Ibague",
"57790", "Bucaramanga",
"5718444", "Villeta",
"5745", "Medellín",
"57183929", "La\ Esmeralda",
"57535", "Barranquilla",
"5718373", "Beltrán",
"5718230", "Subachoque",
"5718249", "Zipacon",
"5718451", "Nocaima",
"5718441", "Viani",
"57183926", "Nilo",
"5718450", "San\ Antonio\ de\ Tequendama",
"574842", "Medellín",
"5718440", "Facatativa",
"57887", "Neiva",
"5718439", "Facatativa",
"57688", "Manizales",
"57827", "Ibague",
"57562958", "Cartagena",
"5718434", "Cartagenita",
"5718375", "Nariño",
"5718431", "Facatativa",
"57562957", "Cartagena",
"57272", "Pasto",
"5718250", "Madrid",
"5718240", "El\ Rosal",
"57236", "Cali",
"57567", "Cartagena",
"5718381", "Agua\ de\ Dios",
"5714", "Bogotá",
"57765", "Bucaramanga",
"5748720", "Medellín",
"5718384", "Viota",
"5718251", "Madrid",
"5718241", "El\ Rosal",
"5718430", "Facatativa",
"57566", "Cartagena",
"57290", "Cali",
"5718449", "La\ Peña",
"57184330", "Ninaima",
"57184334", "Tobia",
"5718254", "Madrid",
"57288", "Cali",
"571821", "Funza",
"5748721", "Medellín",
"5718438", "Facatativa",
"571845341", "La\ Florida",
"5748724", "Medellín",};

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