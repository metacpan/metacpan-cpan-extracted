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
our $VERSION = 1.20210602223259;

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
$areanames{en} = {"57533", "Barranquilla",
"57182428", "Subachoque",
"5718255", "Madrid",
"571832", "Girardot",
"57764", "Bucaramanga",
"5718250", "Madrid",
"5718252", "Madrid",
"57562958", "Cartagena",
"57183926", "Nilo",
"5718417", "Guaduas",
"5745", "Medellín",
"57536", "Barranquilla",
"57635", "Pereira",
"5718450", "San\ Antonio\ de\ Tequendama",
"5718431", "Facatativa",
"571821", "Funza",
"5744", "Medellín",
"5718430", "Facatativa",
"57182420", "La\ Pradera",
"57184333", "Tobia",
"571845341", "La\ Florida",
"5718451", "Nocaima",
"571826", "Funza",
"571833", "Girardot",
"5718253", "Madrid",
"5718447", "Villeta",
"57272", "Pasto",
"57289", "Cali",
"57631", "Pereira",
"57233", "Cali",
"5742", "Medellín",
"5718435", "Cartagenita",
"5718398", "Apulo",
"5718232", "Funza",
"57292", "Cali",
"5718251", "Madrid",
"5718230", "Subachoque",
"5718439", "Facatativa",
"571820", "Madrid",
"57236", "Cali",
"5718247", "La\ Punta",
"5718249", "Zipacon",
"5718445", "Villeta",
"5718386", "Apulo",
"5718437", "Facatativa",
"57273", "Pasto",
"5718371", "Guataqui",
"57232", "Cali",
"5748721", "Medellín",
"5718442", "Cachipay",
"5718440", "Facatativa",
"57887", "Neiva",
"5748510", "Medellín",
"57234", "Cali",
"571830", "Girardot",
"5718402", "San\ Antonio\ de\ Tequendama",
"5718245", "Subachoque",
"5718449", "La\ Peña",
"571845345", "La\ Florida",
"5743", "Medellín",
"5718373", "Beltrán",
"5718288", "Madrid",
"5718240", "El\ Rosal",
"5748723", "Medellín",
"5718384", "Viota",
"57184332", "Ninaima",
"5718241", "El\ Rosal",
"57288", "Cali",
"571827", "Mosquera",
"571822", "Funza",
"57826", "Ibague",
"5718257", "Funza",
"5718419", "Pandi",
"5718443", "Cachipay",
"57532", "Barranquilla",
"5748511", "Medellín",
"5718412", "Santa\ Inés",
"571831", "Girardot",
"5749092", "Medellín",
"57763", "Bucaramanga",
"5718441", "Viani",
"5718375", "Nariño",
"57184334", "Tobia",
"5718403", "Choachi",
"5748725", "Medellín",
"57534", "Barranquilla",
"57562957", "Cartagena",
"5748720", "Medellín",
"5718243", "Bojaca",
"5718370", "Jerusalén",
"57183929", "La\ Esmeralda",
"571842", "Facatativa",
"57866", "Villavicencio",
"57566", "Cartagena",
"57184330", "Ninaima",
"5748722", "Medellín",
"5718246", "Puente\ Piedra",
"57568", "Cartagena",
"57567", "Cartagena",
"5718444", "Villeta",
"5718438", "Facatativa",
"57290", "Cali",
"57827", "Ibague",
"5718404", "Fomeque",
"5718446", "Villeta",
"5718385", "Nariño",
"574842", "Medellín",
"57492", "Medellín",
"57767", "Bucaramanga",
"574913", "Medellín",
"57768", "Bucaramanga",
"57235", "Cali",
"5718376", "Tocaima",
"5748726", "Medellín",
"5718381", "Agua\ de\ Dios",
"571845340", "La\ Florida",
"57689", "Manizales",
"57557", "Valledupar",
"5718416", "Guaduas",
"57633", "Pereira",
"57231", "Cali",
"57886", "Neiva",
"57562959", "Cartagena",
"57758", "Cucuta",
"57183927", "Nilo",
"57535", "Barranquilla",
"57757", "Cucuta",
"57182429", "Subachique",
"574917", "Medellín",
"5718383", "Nilo",
"57562951", "Cartagena",
"5713", "Bogotá",
"57790", "Bucaramanga",
"5748724", "Medellín",
"5718393", "Girardot",
"57183928", "Nilo",
"57562956", "Cartagena",
"57632", "Pereira",
"57765", "Bucaramanga",
"5712", "Bogotá",
"5714", "Bogotá",
"5718254", "Madrid",
"574911", "Medellín",
"5718256", "Madrid",
"5717", "Bogotá",
"57634", "Pereira",
"57183925", "Nilo",
"5718283", "Mosquera",
"5716", "Bogotá",
"571845342", "La\ Florida",
"5718481", "Quebradanegra",
"57565", "Cartagena",
"571845343", "La\ Florida",
"57687", "Manizales",
"57688", "Manizales",
"5718480", "Quebradanegra",
"5718482", "La\ Magdalena",
"5718434", "Cartagenita",
"57184331", "Ninaima",
"57537", "Barranquilla",
"57538", "Barranquilla",
"571845344", "La\ Florida",
"5718289", "Madrid",
"57761", "Bucaramanga",
"57230", "Cali",
"5715", "Bogotá",
"5718397", "Apulo",
"5718436", "Facatativa",};
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