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
our $VERSION = 1.20210204173825;

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
          3(?:
            24[2-6]|
            3(?:
              00|
              3[0-24-9]
            )
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
$areanames{en} = {"5718289", "Madrid",
"57758", "Cucuta",
"5745", "Medellín",
"574911", "Medellín",
"57633", "Pereira",
"57236", "Cali",
"5717", "Bogotá",
"5718247", "La\ Punta",
"5718444", "Villeta",
"571821", "Funza",
"57763", "Bucaramanga",
"5718283", "Mosquera",
"5718256", "Madrid",
"5718447", "Villeta",
"5718480", "Quebradanegra",
"5718381", "Agua\ de\ Dios",
"5718404", "Fomeque",
"57184331", "Ninaima",
"57688", "Manizales",
"571842", "Facatativa",
"57562959", "Cartagena",
"57492", "Medellín",
"57183925", "Nilo",
"57289", "Cali",
"571822", "Funza",
"574917", "Medellín",
"5742", "Medellín",
"57562956", "Cartagena",
"5718431", "Facatativa",
"571827", "Mosquera",
"57183929", "La\ Esmeralda",
"57768", "Bucaramanga",
"5718417", "Guaduas",
"571820", "Madrid",
"5718438", "Facatativa",
"5718232", "Funza",
"57534", "Barranquilla",
"57183926", "Nilo",
"5718376", "Tocaima",
"5748724", "Medellín",
"5743", "Medellín",
"57532", "Barranquilla",
"57273", "Pasto",
"5718402", "San\ Antonio\ de\ Tequendama",
"57757", "Cucuta",
"571845345", "La\ Florida",
"57635", "Pereira",
"57866", "Villavicencio",
"57184333", "Tobia",
"57183928", "Nilo",
"5749092", "Medellín",
"57886", "Neiva",
"5718442", "Cachipay",
"57562951", "Cartagena",
"5718255", "Madrid",
"574913", "Medellín",
"5718370", "Jerusalén",
"5718384", "Viota",
"5714", "Bogotá",
"57562958", "Cartagena",
"5718373", "Beltrán",
"5718241", "El\ Rosal",
"57232", "Cali",
"57765", "Bucaramanga",
"57230", "Cali",
"57234", "Cali",
"57826", "Ibague",
"5718441", "Viani",
"5748722", "Medellín",
"5718434", "Cartagenita",
"57536", "Barranquilla",
"5718412", "Santa\ Inés",
"5718393", "Girardot",
"5718437", "Facatativa",
"57566", "Cartagena",
"57687", "Manizales",
"5748511", "Medellín",
"57182420", "La\ Pradera",
"5748721", "Medellín",
"5718450", "San\ Antonio\ de\ Tequendama",
"57790", "Bucaramanga",
"57231", "Cali",
"5718250", "Madrid",
"5718375", "Nariño",
"57184332", "Ninaima",
"5718253", "Madrid",
"57767", "Bucaramanga",
"571845344", "La\ Florida",
"571845341", "La\ Florida",
"5718246", "Puente\ Piedra",
"5718257", "Funza",
"571845340", "La\ Florida",
"57292", "Cali",
"5718439", "Facatativa",
"571830", "Girardot",
"5718254", "Madrid",
"5718385", "Nariño",
"5718446", "Villeta",
"57562957", "Cartagena",
"57272", "Pasto",
"57533", "Barranquilla",
"57761", "Bucaramanga",
"57290", "Cali",
"57631", "Pereira",
"5718430", "Facatativa",
"5718230", "Subachoque",
"57183927", "Nilo",
"571832", "Girardot",
"5718397", "Apulo",
"5718383", "Nilo",
"5718416", "Guaduas",
"57568", "Cartagena",
"571831", "Girardot",
"571826", "Funza",
"5718481", "Quebradanegra",
"5748726", "Medellín",
"57764", "Bucaramanga",
"57235", "Cali",
"57538", "Barranquilla",
"57184334", "Tobia",
"57634", "Pereira",
"5718482", "La\ Magdalena",
"5718288", "Madrid",
"5744", "Medellín",
"5718435", "Cartagenita",
"57184330", "Ninaima",
"57182429", "Subachique",
"57632", "Pereira",
"57887", "Neiva",
"5718398", "Apulo",
"5718245", "Subachoque",
"5712", "Bogotá",
"57535", "Barranquilla",
"5718251", "Madrid",
"57182428", "Subachoque",
"5718386", "Apulo",
"5718445", "Villeta",
"574842", "Medellín",
"57288", "Cali",
"57565", "Cartagena",
"5718451", "Nocaima",
"5748720", "Medellín",
"57689", "Manizales",
"571845342", "La\ Florida",
"5748723", "Medellín",
"5748510", "Medellín",
"5713", "Bogotá",
"57557", "Valledupar",
"571845343", "La\ Florida",
"5718252", "Madrid",
"5716", "Bogotá",
"57827", "Ibague",
"5718419", "Pandi",
"5718440", "Facatativa",
"5715", "Bogotá",
"5718443", "Cachipay",
"57537", "Barranquilla",
"57233", "Cali",
"5748725", "Medellín",
"5718243", "Bojaca",
"5718240", "El\ Rosal",
"5718403", "Choachi",
"57567", "Cartagena",
"5718371", "Guataqui",
"5718449", "La\ Peña",
"5718436", "Facatativa",
"571833", "Girardot",
"5718249", "Zipacon",};

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