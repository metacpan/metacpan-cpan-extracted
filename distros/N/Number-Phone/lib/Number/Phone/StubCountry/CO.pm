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
our $VERSION = 1.20200904144530;

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
$areanames{en}->{5712} = "Bogotá";
$areanames{en}->{5713} = "Bogotá";
$areanames{en}->{5714} = "Bogotá";
$areanames{en}->{5715} = "Bogotá";
$areanames{en}->{5716} = "Bogotá";
$areanames{en}->{5717} = "Bogotá";
$areanames{en}->{571820} = "Madrid";
$areanames{en}->{571821} = "Funza";
$areanames{en}->{571822} = "Funza";
$areanames{en}->{5718230} = "Subachoque";
$areanames{en}->{5718232} = "Funza";
$areanames{en}->{5718240} = "El\ Rosal";
$areanames{en}->{5718241} = "El\ Rosal";
$areanames{en}->{57182420} = "La\ Pradera";
$areanames{en}->{57182428} = "Subachoque";
$areanames{en}->{57182429} = "Subachique";
$areanames{en}->{5718243} = "Bojaca";
$areanames{en}->{5718245} = "Subachoque";
$areanames{en}->{5718246} = "Puente\ Piedra";
$areanames{en}->{5718247} = "La\ Punta";
$areanames{en}->{5718249} = "Zipacon";
$areanames{en}->{5718250} = "Madrid";
$areanames{en}->{5718251} = "Madrid";
$areanames{en}->{5718252} = "Madrid";
$areanames{en}->{5718253} = "Madrid";
$areanames{en}->{5718254} = "Madrid";
$areanames{en}->{5718255} = "Madrid";
$areanames{en}->{5718256} = "Madrid";
$areanames{en}->{5718257} = "Funza";
$areanames{en}->{571826} = "Funza";
$areanames{en}->{571827} = "Mosquera";
$areanames{en}->{5718283} = "Mosquera";
$areanames{en}->{5718288} = "Madrid";
$areanames{en}->{5718289} = "Madrid";
$areanames{en}->{571830} = "Girardot";
$areanames{en}->{571831} = "Girardot";
$areanames{en}->{571832} = "Girardot";
$areanames{en}->{571833} = "Girardot";
$areanames{en}->{5718370} = "Jerusalén";
$areanames{en}->{5718371} = "Guataqui";
$areanames{en}->{5718373} = "Beltrán";
$areanames{en}->{5718375} = "Nariño";
$areanames{en}->{5718376} = "Tocaima";
$areanames{en}->{5718381} = "Agua\ de\ Dios";
$areanames{en}->{5718383} = "Nilo";
$areanames{en}->{5718384} = "Viota";
$areanames{en}->{5718385} = "Nariño";
$areanames{en}->{5718386} = "Apulo";
$areanames{en}->{57183925} = "Nilo";
$areanames{en}->{57183926} = "Nilo";
$areanames{en}->{57183927} = "Nilo";
$areanames{en}->{57183928} = "Nilo";
$areanames{en}->{57183929} = "La\ Esmeralda";
$areanames{en}->{5718393} = "Girardot";
$areanames{en}->{5718397} = "Apulo";
$areanames{en}->{5718398} = "Apulo";
$areanames{en}->{5718402} = "San\ Antonio\ de\ Tequendama";
$areanames{en}->{5718403} = "Choachi";
$areanames{en}->{5718404} = "Fomeque";
$areanames{en}->{5718412} = "Santa\ Inés";
$areanames{en}->{5718416} = "Guaduas";
$areanames{en}->{5718417} = "Guaduas";
$areanames{en}->{5718419} = "Pandi";
$areanames{en}->{571842} = "Facatativa";
$areanames{en}->{5718430} = "Facatativa";
$areanames{en}->{5718431} = "Facatativa";
$areanames{en}->{57184330} = "Ninaima";
$areanames{en}->{57184331} = "Ninaima";
$areanames{en}->{57184332} = "Ninaima";
$areanames{en}->{57184333} = "Tobia";
$areanames{en}->{57184334} = "Tobia";
$areanames{en}->{5718434} = "Cartagenita";
$areanames{en}->{5718435} = "Cartagenita";
$areanames{en}->{5718436} = "Facatativa";
$areanames{en}->{5718437} = "Facatativa";
$areanames{en}->{5718438} = "Facatativa";
$areanames{en}->{5718439} = "Facatativa";
$areanames{en}->{5718440} = "Facatativa";
$areanames{en}->{5718441} = "Viani";
$areanames{en}->{5718442} = "Cachipay";
$areanames{en}->{5718443} = "Cachipay";
$areanames{en}->{5718444} = "Villeta";
$areanames{en}->{5718445} = "Villeta";
$areanames{en}->{5718446} = "Villeta";
$areanames{en}->{5718447} = "Villeta";
$areanames{en}->{5718449} = "La\ Peña";
$areanames{en}->{5718450} = "San\ Antonio\ de\ Tequendama";
$areanames{en}->{5718451} = "Nocaima";
$areanames{en}->{571845340} = "La\ Florida";
$areanames{en}->{571845341} = "La\ Florida";
$areanames{en}->{571845342} = "La\ Florida";
$areanames{en}->{571845343} = "La\ Florida";
$areanames{en}->{571845344} = "La\ Florida";
$areanames{en}->{571845345} = "La\ Florida";
$areanames{en}->{5718480} = "Quebradanegra";
$areanames{en}->{5718481} = "Quebradanegra";
$areanames{en}->{5718482} = "La\ Magdalena";
$areanames{en}->{57230} = "Cali";
$areanames{en}->{57231} = "Cali";
$areanames{en}->{57232} = "Cali";
$areanames{en}->{57233} = "Cali";
$areanames{en}->{57234} = "Cali";
$areanames{en}->{57235} = "Cali";
$areanames{en}->{57236} = "Cali";
$areanames{en}->{57272} = "Pasto";
$areanames{en}->{57273} = "Pasto";
$areanames{en}->{57288} = "Cali";
$areanames{en}->{57289} = "Cali";
$areanames{en}->{57290} = "Cali";
$areanames{en}->{57292} = "Cali";
$areanames{en}->{5742} = "Medellín";
$areanames{en}->{5743} = "Medellín";
$areanames{en}->{5744} = "Medellín";
$areanames{en}->{5745} = "Medellín";
$areanames{en}->{574842} = "Medellín";
$areanames{en}->{5748510} = "Medellín";
$areanames{en}->{5748511} = "Medellín";
$areanames{en}->{5748720} = "Medellín";
$areanames{en}->{5748721} = "Medellín";
$areanames{en}->{5748722} = "Medellín";
$areanames{en}->{5748723} = "Medellín";
$areanames{en}->{5748724} = "Medellín";
$areanames{en}->{5748725} = "Medellín";
$areanames{en}->{5748726} = "Medellín";
$areanames{en}->{5749092} = "Medellín";
$areanames{en}->{574911} = "Medellín";
$areanames{en}->{574913} = "Medellín";
$areanames{en}->{574917} = "Medellín";
$areanames{en}->{57492} = "Medellín";
$areanames{en}->{57532} = "Barranquilla";
$areanames{en}->{57533} = "Barranquilla";
$areanames{en}->{57534} = "Barranquilla";
$areanames{en}->{57535} = "Barranquilla";
$areanames{en}->{57536} = "Barranquilla";
$areanames{en}->{57537} = "Barranquilla";
$areanames{en}->{57538} = "Barranquilla";
$areanames{en}->{57557} = "Valledupar";
$areanames{en}->{57562951} = "Cartagena";
$areanames{en}->{57562956} = "Cartagena";
$areanames{en}->{57562957} = "Cartagena";
$areanames{en}->{57562958} = "Cartagena";
$areanames{en}->{57562959} = "Cartagena";
$areanames{en}->{57565} = "Cartagena";
$areanames{en}->{57566} = "Cartagena";
$areanames{en}->{57567} = "Cartagena";
$areanames{en}->{57568} = "Cartagena";
$areanames{en}->{576012} = "Bogotá";
$areanames{en}->{576013} = "Bogotá";
$areanames{en}->{576014} = "Bogotá";
$areanames{en}->{576015} = "Bogotá";
$areanames{en}->{576016} = "Bogotá";
$areanames{en}->{576017} = "Bogotá";
$areanames{en}->{57601820} = "Madrid";
$areanames{en}->{57601821} = "Funza";
$areanames{en}->{57601822} = "Funza";
$areanames{en}->{576018230} = "Subachoque";
$areanames{en}->{576018232} = "Funza";
$areanames{en}->{576018240} = "El\ Rosal";
$areanames{en}->{576018241} = "El\ Rosal";
$areanames{en}->{576018242} = "La\ Pradera\/Subachoque\/Subachique";
$areanames{en}->{576018243} = "Bojaca";
$areanames{en}->{576018245} = "Subachoque";
$areanames{en}->{576018246} = "Puente\ Piedra";
$areanames{en}->{576018247} = "La\ Punta";
$areanames{en}->{576018249} = "Zipacon";
$areanames{en}->{576018250} = "Madrid";
$areanames{en}->{576018251} = "Madrid";
$areanames{en}->{576018252} = "Madrid";
$areanames{en}->{576018253} = "Madrid";
$areanames{en}->{576018254} = "Madrid";
$areanames{en}->{576018255} = "Madrid";
$areanames{en}->{576018256} = "Madrid";
$areanames{en}->{576018257} = "Funza";
$areanames{en}->{57601826} = "Funza";
$areanames{en}->{57601827} = "Mosquera";
$areanames{en}->{576018283} = "Mosquera";
$areanames{en}->{576018288} = "Madrid";
$areanames{en}->{576018289} = "Madrid";
$areanames{en}->{57601830} = "Girardot";
$areanames{en}->{57601831} = "Girardot";
$areanames{en}->{57601832} = "Girardot";
$areanames{en}->{57601833} = "Girardot";
$areanames{en}->{576018370} = "Jerusalén";
$areanames{en}->{576018371} = "Guataqui";
$areanames{en}->{576018373} = "Beltrán";
$areanames{en}->{576018375} = "Nariño";
$areanames{en}->{576018376} = "Tocaima";
$areanames{en}->{576018381} = "Agua\ de\ Dios";
$areanames{en}->{576018383} = "Nilo";
$areanames{en}->{576018384} = "Viota";
$areanames{en}->{576018385} = "Nariño";
$areanames{en}->{576018386} = "Apulo";
$areanames{en}->{576018392} = "Nilo\/La\ Esmeralda";
$areanames{en}->{576018393} = "Girardot";
$areanames{en}->{576018397} = "Apulo";
$areanames{en}->{576018398} = "Apulo";
$areanames{en}->{576018402} = "San\ Antonio\ de\ Tequendama";
$areanames{en}->{576018403} = "Choachi";
$areanames{en}->{576018404} = "Fomeque";
$areanames{en}->{576018412} = "Santa\ Inés";
$areanames{en}->{576018416} = "Guaduas";
$areanames{en}->{576018417} = "Guaduas";
$areanames{en}->{576018419} = "Pandi";
$areanames{en}->{57601842} = "Facatativa";
$areanames{en}->{576018430} = "Facatativa";
$areanames{en}->{576018431} = "Facatativa";
$areanames{en}->{576018433} = "Ninaima\/Tobia";
$areanames{en}->{576018434} = "Cartagenita";
$areanames{en}->{576018435} = "Cartagenita";
$areanames{en}->{576018436} = "Facatativa";
$areanames{en}->{576018437} = "Facatativa";
$areanames{en}->{576018438} = "Facatativa";
$areanames{en}->{576018439} = "Facatativa";
$areanames{en}->{576018440} = "Facatativa";
$areanames{en}->{576018441} = "Viani";
$areanames{en}->{576018442} = "Cachipay";
$areanames{en}->{576018443} = "Cachipay";
$areanames{en}->{576018444} = "Villeta";
$areanames{en}->{576018445} = "Villeta";
$areanames{en}->{576018446} = "Villeta";
$areanames{en}->{576018447} = "Villeta";
$areanames{en}->{576018449} = "La\ Peña";
$areanames{en}->{576018450} = "San\ Antonio\ de\ Tequendama";
$areanames{en}->{576018451} = "Nocaima";
$areanames{en}->{576018453} = "La\ Florida";
$areanames{en}->{576018480} = "Quebradanegra";
$areanames{en}->{576018481} = "Quebradanegra";
$areanames{en}->{576018482} = "La\ Magdalena";
$areanames{en}->{5760230} = "Cali";
$areanames{en}->{5760231} = "Cali";
$areanames{en}->{5760232} = "Cali";
$areanames{en}->{5760233} = "Cali";
$areanames{en}->{5760234} = "Cali";
$areanames{en}->{5760235} = "Cali";
$areanames{en}->{5760236} = "Cali";
$areanames{en}->{5760272} = "Pasto";
$areanames{en}->{5760273} = "Pasto";
$areanames{en}->{5760288} = "Cali";
$areanames{en}->{5760289} = "Cali";
$areanames{en}->{5760290} = "Cali";
$areanames{en}->{5760292} = "Cali";
$areanames{en}->{576042} = "Medellín";
$areanames{en}->{576043} = "Medellín";
$areanames{en}->{576044} = "Medellín";
$areanames{en}->{576045} = "Medellín";
$areanames{en}->{57604842} = "Medellín";
$areanames{en}->{576048510} = "Medellín";
$areanames{en}->{576048511} = "Medellín";
$areanames{en}->{576048720} = "Medellín";
$areanames{en}->{576048721} = "Medellín";
$areanames{en}->{576048722} = "Medellín";
$areanames{en}->{576048723} = "Medellín";
$areanames{en}->{576048724} = "Medellín";
$areanames{en}->{576048725} = "Medellín";
$areanames{en}->{576048726} = "Medellín";
$areanames{en}->{576049092} = "Medellín";
$areanames{en}->{57604911} = "Medellín";
$areanames{en}->{57604913} = "Medellín";
$areanames{en}->{57604917} = "Medellín";
$areanames{en}->{5760492} = "Medellín";
$areanames{en}->{5760532} = "Barranquilla";
$areanames{en}->{5760533} = "Barranquilla";
$areanames{en}->{5760534} = "Barranquilla";
$areanames{en}->{5760535} = "Barranquilla";
$areanames{en}->{5760536} = "Barranquilla";
$areanames{en}->{5760537} = "Barranquilla";
$areanames{en}->{5760538} = "Barranquilla";
$areanames{en}->{5760557} = "Valledupar";
$areanames{en}->{576056295} = "Cartagena";
$areanames{en}->{5760565} = "Cartagena";
$areanames{en}->{5760566} = "Cartagena";
$areanames{en}->{5760567} = "Cartagena";
$areanames{en}->{5760568} = "Cartagena";
$areanames{en}->{5760631} = "Pereira";
$areanames{en}->{5760632} = "Pereira";
$areanames{en}->{5760633} = "Pereira";
$areanames{en}->{5760634} = "Pereira";
$areanames{en}->{5760635} = "Pereira";
$areanames{en}->{5760687} = "Manizales";
$areanames{en}->{5760688} = "Manizales";
$areanames{en}->{5760689} = "Manizales";
$areanames{en}->{5760757} = "Cucuta";
$areanames{en}->{5760758} = "Cucuta";
$areanames{en}->{5760761} = "Bucaramanga";
$areanames{en}->{5760763} = "Bucaramanga";
$areanames{en}->{5760764} = "Bucaramanga";
$areanames{en}->{5760765} = "Bucaramanga";
$areanames{en}->{5760767} = "Bucaramanga";
$areanames{en}->{5760768} = "Bucaramanga";
$areanames{en}->{5760790} = "Bucaramanga";
$areanames{en}->{5760826} = "Ibague";
$areanames{en}->{5760827} = "Ibague";
$areanames{en}->{5760866} = "Villavicencio";
$areanames{en}->{5760886} = "Neiva";
$areanames{en}->{5760887} = "Neiva";
$areanames{en}->{57631} = "Pereira";
$areanames{en}->{57632} = "Pereira";
$areanames{en}->{57633} = "Pereira";
$areanames{en}->{57634} = "Pereira";
$areanames{en}->{57635} = "Pereira";
$areanames{en}->{57687} = "Manizales";
$areanames{en}->{57688} = "Manizales";
$areanames{en}->{57689} = "Manizales";
$areanames{en}->{57757} = "Cucuta";
$areanames{en}->{57758} = "Cucuta";
$areanames{en}->{57761} = "Bucaramanga";
$areanames{en}->{57763} = "Bucaramanga";
$areanames{en}->{57764} = "Bucaramanga";
$areanames{en}->{57765} = "Bucaramanga";
$areanames{en}->{57767} = "Bucaramanga";
$areanames{en}->{57768} = "Bucaramanga";
$areanames{en}->{57790} = "Bucaramanga";
$areanames{en}->{57826} = "Ibague";
$areanames{en}->{57827} = "Ibague";
$areanames{en}->{57866} = "Villavicencio";
$areanames{en}->{57886} = "Neiva";
$areanames{en}->{57887} = "Neiva";
$areanames{es}->{5712} = "Bogotá";
$areanames{es}->{5713} = "Bogotá";
$areanames{es}->{5714} = "Bogotá";
$areanames{es}->{5715} = "Bogotá";
$areanames{es}->{5716} = "Bogotá";
$areanames{es}->{5717} = "Bogotá";
$areanames{es}->{571820} = "Madrid";
$areanames{es}->{571821} = "Funza";
$areanames{es}->{571822} = "Funza";
$areanames{es}->{5718230} = "Subachoque";
$areanames{es}->{5718232} = "Funza";
$areanames{es}->{5718240} = "El\ Rosal";
$areanames{es}->{5718241} = "El\ Rosal";
$areanames{es}->{57182420} = "La\ Pradera";
$areanames{es}->{57182428} = "Subachoque";
$areanames{es}->{57182429} = "Subachique";
$areanames{es}->{5718243} = "Bojaca";
$areanames{es}->{5718245} = "Subachoque";
$areanames{es}->{5718246} = "Puente\ Piedra";
$areanames{es}->{5718247} = "La\ Punta";
$areanames{es}->{5718249} = "Zipacon";
$areanames{es}->{5718250} = "Madrid";
$areanames{es}->{5718251} = "Madrid";
$areanames{es}->{5718252} = "Madrid";
$areanames{es}->{5718253} = "Madrid";
$areanames{es}->{5718254} = "Madrid";
$areanames{es}->{5718255} = "Madrid";
$areanames{es}->{5718256} = "Madrid";
$areanames{es}->{5718257} = "Funza";
$areanames{es}->{571826} = "Funza";
$areanames{es}->{571827} = "Mosquera";
$areanames{es}->{5718283} = "Mosquera";
$areanames{es}->{5718288} = "Madrid";
$areanames{es}->{5718289} = "Madrid";
$areanames{es}->{571830} = "Girardot";
$areanames{es}->{571831} = "Girardot";
$areanames{es}->{571832} = "Girardot";
$areanames{es}->{571833} = "Girardot";
$areanames{es}->{5718370} = "Jerusalén";
$areanames{es}->{5718371} = "Guataqui";
$areanames{es}->{5718373} = "Beltrán";
$areanames{es}->{5718375} = "Nariño";
$areanames{es}->{5718376} = "Tocaima";
$areanames{es}->{5718381} = "Agua\ de\ Dios";
$areanames{es}->{5718383} = "Nilo";
$areanames{es}->{5718384} = "Viota";
$areanames{es}->{5718385} = "Nariño";
$areanames{es}->{5718386} = "Apulo";
$areanames{es}->{57183925} = "Nilo";
$areanames{es}->{57183926} = "Nilo";
$areanames{es}->{57183927} = "Nilo";
$areanames{es}->{57183928} = "Nilo";
$areanames{es}->{57183929} = "La\ Esmeralda";
$areanames{es}->{5718393} = "Girardot";
$areanames{es}->{5718397} = "Apulo";
$areanames{es}->{5718398} = "Apulo";
$areanames{es}->{5718402} = "San\ Antonio\ de\ Tequendama";
$areanames{es}->{5718403} = "Choachi";
$areanames{es}->{5718404} = "Fomeque";
$areanames{es}->{5718412} = "Santa\ Inés";
$areanames{es}->{5718416} = "Guaduas";
$areanames{es}->{5718417} = "Guaduas";
$areanames{es}->{5718419} = "Pandi";
$areanames{es}->{571842} = "Facatativa";
$areanames{es}->{5718430} = "Facatativa";
$areanames{es}->{5718431} = "Facatativa";
$areanames{es}->{57184330} = "Ninaima";
$areanames{es}->{57184331} = "Ninaima";
$areanames{es}->{57184332} = "Ninaima";
$areanames{es}->{57184333} = "Tobia";
$areanames{es}->{57184334} = "Tobia";
$areanames{es}->{5718434} = "Cartagenita";
$areanames{es}->{5718435} = "Cartagenita";
$areanames{es}->{5718436} = "Facatativa";
$areanames{es}->{5718437} = "Facatativa";
$areanames{es}->{5718438} = "Facatativa";
$areanames{es}->{5718439} = "Facatativa";
$areanames{es}->{5718440} = "Facatativa";
$areanames{es}->{5718441} = "Viani";
$areanames{es}->{5718442} = "Cachipay";
$areanames{es}->{5718443} = "Cachipay";
$areanames{es}->{5718444} = "Villeta";
$areanames{es}->{5718445} = "Villeta";
$areanames{es}->{5718446} = "Villeta";
$areanames{es}->{5718447} = "Villeta";
$areanames{es}->{5718449} = "La\ Peña";
$areanames{es}->{5718450} = "San\ Antonio\ de\ Tequendama";
$areanames{es}->{5718451} = "Nocaima";
$areanames{es}->{571845340} = "La\ Florida";
$areanames{es}->{571845341} = "La\ Florida";
$areanames{es}->{571845342} = "La\ Florida";
$areanames{es}->{571845343} = "La\ Florida";
$areanames{es}->{571845344} = "La\ Florida";
$areanames{es}->{571845345} = "La\ Florida";
$areanames{es}->{5718480} = "Quebradanegra";
$areanames{es}->{5718481} = "Quebradanegra";
$areanames{es}->{5718482} = "La\ Magdalena";
$areanames{es}->{57230} = "Cali";
$areanames{es}->{57231} = "Cali";
$areanames{es}->{57232} = "Cali";
$areanames{es}->{57233} = "Cali";
$areanames{es}->{57234} = "Cali";
$areanames{es}->{57235} = "Cali";
$areanames{es}->{57236} = "Cali";
$areanames{es}->{57272} = "Pasto";
$areanames{es}->{57273} = "Pasto";
$areanames{es}->{57288} = "Cali";
$areanames{es}->{57289} = "Cali";
$areanames{es}->{57290} = "Cali";
$areanames{es}->{57292} = "Cali";
$areanames{es}->{5742} = "Medellín";
$areanames{es}->{5743} = "Medellín";
$areanames{es}->{5744} = "Medellín";
$areanames{es}->{5745} = "Medellín";
$areanames{es}->{574842} = "Medellín";
$areanames{es}->{5748510} = "Medellín";
$areanames{es}->{5748511} = "Medellín";
$areanames{es}->{5748720} = "Medellín";
$areanames{es}->{5748721} = "Medellín";
$areanames{es}->{5748722} = "Medellín";
$areanames{es}->{5748723} = "Medellín";
$areanames{es}->{5748724} = "Medellín";
$areanames{es}->{5748725} = "Medellín";
$areanames{es}->{5748726} = "Medellín";
$areanames{es}->{5749092} = "Medellín";
$areanames{es}->{574911} = "Medellín";
$areanames{es}->{574913} = "Medellín";
$areanames{es}->{574917} = "Medellín";
$areanames{es}->{57492} = "Medellín";
$areanames{es}->{57532} = "Barranquilla";
$areanames{es}->{57533} = "Barranquilla";
$areanames{es}->{57534} = "Barranquilla";
$areanames{es}->{57535} = "Barranquilla";
$areanames{es}->{57536} = "Barranquilla";
$areanames{es}->{57537} = "Barranquilla";
$areanames{es}->{57538} = "Barranquilla";
$areanames{es}->{57557} = "Valledupar";
$areanames{es}->{57562951} = "Cartagena";
$areanames{es}->{57562956} = "Cartagena";
$areanames{es}->{57562957} = "Cartagena";
$areanames{es}->{57562958} = "Cartagena";
$areanames{es}->{57562959} = "Cartagena";
$areanames{es}->{57565} = "Cartagena";
$areanames{es}->{57566} = "Cartagena";
$areanames{es}->{57567} = "Cartagena";
$areanames{es}->{57568} = "Cartagena";
$areanames{es}->{576012} = "Bogotá";
$areanames{es}->{576013} = "Bogotá";
$areanames{es}->{576014} = "Bogotá";
$areanames{es}->{576015} = "Bogotá";
$areanames{es}->{576016} = "Bogotá";
$areanames{es}->{576017} = "Bogotá";
$areanames{es}->{57601820} = "Madrid";
$areanames{es}->{57601821} = "Funza";
$areanames{es}->{57601822} = "Funza";
$areanames{es}->{576018230} = "Subachoque";
$areanames{es}->{576018232} = "Funza";
$areanames{es}->{576018240} = "El\ Rosal";
$areanames{es}->{576018241} = "El\ Rosal";
$areanames{es}->{576018242} = "La\ Pradera\/Subachoque\/Subachique";
$areanames{es}->{576018243} = "Bojaca";
$areanames{es}->{576018245} = "Subachoque";
$areanames{es}->{576018246} = "Puente\ Piedra";
$areanames{es}->{576018247} = "La\ Punta";
$areanames{es}->{576018249} = "Zipacon";
$areanames{es}->{576018250} = "Madrid";
$areanames{es}->{576018251} = "Madrid";
$areanames{es}->{576018252} = "Madrid";
$areanames{es}->{576018253} = "Madrid";
$areanames{es}->{576018254} = "Madrid";
$areanames{es}->{576018255} = "Madrid";
$areanames{es}->{576018256} = "Madrid";
$areanames{es}->{576018257} = "Funza";
$areanames{es}->{57601826} = "Funza";
$areanames{es}->{57601827} = "Mosquera";
$areanames{es}->{576018283} = "Mosquera";
$areanames{es}->{576018288} = "Madrid";
$areanames{es}->{576018289} = "Madrid";
$areanames{es}->{57601830} = "Girardot";
$areanames{es}->{57601831} = "Girardot";
$areanames{es}->{57601832} = "Girardot";
$areanames{es}->{57601833} = "Girardot";
$areanames{es}->{576018370} = "Jerusalén";
$areanames{es}->{576018371} = "Guataqui";
$areanames{es}->{576018373} = "Beltrán";
$areanames{es}->{576018375} = "Nariño";
$areanames{es}->{576018376} = "Tocaima";
$areanames{es}->{576018381} = "Agua\ de\ Dios";
$areanames{es}->{576018383} = "Nilo";
$areanames{es}->{576018384} = "Viota";
$areanames{es}->{576018385} = "Nariño";
$areanames{es}->{576018386} = "Apulo";
$areanames{es}->{576018392} = "Nilo\/La\ Esmeralda";
$areanames{es}->{576018393} = "Girardot";
$areanames{es}->{576018397} = "Apulo";
$areanames{es}->{576018398} = "Apulo";
$areanames{es}->{576018402} = "San\ Antonio\ de\ Tequendama";
$areanames{es}->{576018403} = "Choachi";
$areanames{es}->{576018404} = "Fomeque";
$areanames{es}->{576018412} = "Santa\ Inés";
$areanames{es}->{576018416} = "Guaduas";
$areanames{es}->{576018417} = "Guaduas";
$areanames{es}->{576018419} = "Pandi";
$areanames{es}->{57601842} = "Facatativa";
$areanames{es}->{576018430} = "Facatativa";
$areanames{es}->{576018431} = "Facatativa";
$areanames{es}->{576018433} = "Ninaima\/Tobia";
$areanames{es}->{576018434} = "Cartagenita";
$areanames{es}->{576018435} = "Cartagenita";
$areanames{es}->{576018436} = "Facatativa";
$areanames{es}->{576018437} = "Facatativa";
$areanames{es}->{576018438} = "Facatativa";
$areanames{es}->{576018439} = "Facatativa";
$areanames{es}->{576018440} = "Facatativa";
$areanames{es}->{576018441} = "Viani";
$areanames{es}->{576018442} = "Cachipay";
$areanames{es}->{576018443} = "Cachipay";
$areanames{es}->{576018444} = "Villeta";
$areanames{es}->{576018445} = "Villeta";
$areanames{es}->{576018446} = "Villeta";
$areanames{es}->{576018447} = "Villeta";
$areanames{es}->{576018449} = "La\ Peña";
$areanames{es}->{576018450} = "San\ Antonio\ de\ Tequendama";
$areanames{es}->{576018451} = "Nocaima";
$areanames{es}->{576018453} = "La\ Florida";
$areanames{es}->{576018480} = "Quebradanegra";
$areanames{es}->{576018481} = "Quebradanegra";
$areanames{es}->{576018482} = "La\ Magdalena";
$areanames{es}->{5760230} = "Cali";
$areanames{es}->{5760231} = "Cali";
$areanames{es}->{5760232} = "Cali";
$areanames{es}->{5760233} = "Cali";
$areanames{es}->{5760234} = "Cali";
$areanames{es}->{5760235} = "Cali";
$areanames{es}->{5760236} = "Cali";
$areanames{es}->{5760272} = "Pasto";
$areanames{es}->{5760273} = "Pasto";
$areanames{es}->{5760288} = "Cali";
$areanames{es}->{5760289} = "Cali";
$areanames{es}->{5760290} = "Cali";
$areanames{es}->{5760292} = "Cali";
$areanames{es}->{576042} = "Medellín";
$areanames{es}->{576043} = "Medellín";
$areanames{es}->{576044} = "Medellín";
$areanames{es}->{576045} = "Medellín";
$areanames{es}->{57604842} = "Medellín";
$areanames{es}->{576048510} = "Medellín";
$areanames{es}->{576048511} = "Medellín";
$areanames{es}->{576048720} = "Medellín";
$areanames{es}->{576048721} = "Medellín";
$areanames{es}->{576048722} = "Medellín";
$areanames{es}->{576048723} = "Medellín";
$areanames{es}->{576048724} = "Medellín";
$areanames{es}->{576048725} = "Medellín";
$areanames{es}->{576048726} = "Medellín";
$areanames{es}->{576049092} = "Medellín";
$areanames{es}->{57604911} = "Medellín";
$areanames{es}->{57604913} = "Medellín";
$areanames{es}->{57604917} = "Medellín";
$areanames{es}->{5760492} = "Medellín";
$areanames{es}->{5760532} = "Barranquilla";
$areanames{es}->{5760533} = "Barranquilla";
$areanames{es}->{5760534} = "Barranquilla";
$areanames{es}->{5760535} = "Barranquilla";
$areanames{es}->{5760536} = "Barranquilla";
$areanames{es}->{5760537} = "Barranquilla";
$areanames{es}->{5760538} = "Barranquilla";
$areanames{es}->{5760557} = "Valledupar";
$areanames{es}->{576056295} = "Cartagena";
$areanames{es}->{5760565} = "Cartagena";
$areanames{es}->{5760566} = "Cartagena";
$areanames{es}->{5760567} = "Cartagena";
$areanames{es}->{5760568} = "Cartagena";
$areanames{es}->{5760631} = "Pereira";
$areanames{es}->{5760632} = "Pereira";
$areanames{es}->{5760633} = "Pereira";
$areanames{es}->{5760634} = "Pereira";
$areanames{es}->{5760635} = "Pereira";
$areanames{es}->{5760687} = "Manizales";
$areanames{es}->{5760688} = "Manizales";
$areanames{es}->{5760689} = "Manizales";
$areanames{es}->{5760757} = "Cucuta";
$areanames{es}->{5760758} = "Cucuta";
$areanames{es}->{5760761} = "Bucaramanga";
$areanames{es}->{5760763} = "Bucaramanga";
$areanames{es}->{5760764} = "Bucaramanga";
$areanames{es}->{5760765} = "Bucaramanga";
$areanames{es}->{5760767} = "Bucaramanga";
$areanames{es}->{5760768} = "Bucaramanga";
$areanames{es}->{5760790} = "Bucaramanga";
$areanames{es}->{5760826} = "Ibague";
$areanames{es}->{5760827} = "Ibague";
$areanames{es}->{5760866} = "Villavicencio";
$areanames{es}->{5760886} = "Neiva";
$areanames{es}->{5760887} = "Neiva";
$areanames{es}->{57631} = "Pereira";
$areanames{es}->{57632} = "Pereira";
$areanames{es}->{57633} = "Pereira";
$areanames{es}->{57634} = "Pereira";
$areanames{es}->{57635} = "Pereira";
$areanames{es}->{57687} = "Manizales";
$areanames{es}->{57688} = "Manizales";
$areanames{es}->{57689} = "Manizales";
$areanames{es}->{57757} = "Cucuta";
$areanames{es}->{57758} = "Cucuta";
$areanames{es}->{57761} = "Bucaramanga";
$areanames{es}->{57763} = "Bucaramanga";
$areanames{es}->{57764} = "Bucaramanga";
$areanames{es}->{57765} = "Bucaramanga";
$areanames{es}->{57767} = "Bucaramanga";
$areanames{es}->{57768} = "Bucaramanga";
$areanames{es}->{57790} = "Bucaramanga";
$areanames{es}->{57826} = "Ibague";
$areanames{es}->{57827} = "Ibague";
$areanames{es}->{57866} = "Villavicencio";
$areanames{es}->{57886} = "Neiva";
$areanames{es}->{57887} = "Neiva";

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