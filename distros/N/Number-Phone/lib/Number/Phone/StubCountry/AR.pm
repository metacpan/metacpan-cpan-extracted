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
package Number::Phone::StubCountry::AR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170702164946;

my $formatters = [
                {
                  'pattern' => '([68]\\d{2})(\\d{3})(\\d{4})',
                  'leading_digits' => '[68]'
                },
                {
                  'pattern' => '(\\d{2})(\\d{4})',
                  'leading_digits' => '[2-9]'
                },
                {
                  'pattern' => '(\\d{3})(\\d{4})',
                  'leading_digits' => '[2-9]'
                },
                {
                  'pattern' => '(\\d{4})(\\d{4})',
                  'leading_digits' => '[2-9]'
                },
                {
                  'leading_digits' => '911',
                  'pattern' => '(9)(11)(\\d{4})(\\d{4})'
                },
                {
                  'pattern' => '(9)(\\d{3})(\\d{3})(\\d{4})',
                  'leading_digits' => '
            9(?:
              2(?:
                2(?:
                  0[013-9]|
                  [13]
                )|
                3(?:
                  0[013-9]|
                  [67]
                )|
                49|
                6(?:
                  [0136]|
                  4[0-59]
                )|
                8|
                9(?:
                  [19]|
                  44|
                  7[013-9]|
                  8[14]
                )
              )|
              3(?:
                36|
                4(?:
                  [12]|
                  3(?:
                    4|
                    5[014]|
                    6[1239]
                   )|
                  [58]4
                )|
                5(?:
                  1|
                  3[0-24-689]|
                  8[46]
                )|
                6|
                7[069]|
                8(?:
                  [01]|
                  34|
                  [578][45]
                )
              )
            )
          '
                },
                {
                  'pattern' => '(9)(\\d{4})(\\d{2})(\\d{4})',
                  'leading_digits' => '9[23]'
                },
                {
                  'pattern' => '(11)(\\d{4})(\\d{4})',
                  'leading_digits' => '1'
                },
                {
                  'leading_digits' => '
              2(?:
                2(?:
                  0[013-9]|
                  [13]
                )|
                3(?:
                  0[013-9]|
                  [67]
                )|
                49|
                6(?:
                  [0136]|
                  4[0-59]
                )|
                8|
                9(?:
                  [19]|
                  44|
                  7[013-9]|
                  8[14]
                )
              )|
              3(?:
                36|
                4(?:
                  [12]|
                  3(?:
                    4|
                    5[014]|
                    6[1239]
                   )|
                  [58]4
                )|
                5(?:
                  1|
                  3[0-24-689]|
                  8[46]
                )|
                6|
                7[069]|
                8(?:
                  [01]|
                  34|
                  [578][45]
                )
              )
          ',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(\\d{4})(\\d{2})(\\d{4})',
                  'leading_digits' => '[23]'
                },
                {
                  'pattern' => '(\\d{3})',
                  'leading_digits' => '
            1[012]|
            911
          '
                }
              ];

my $validators = {
                'geographic' => '
          11\\d{8}|
          (?:
            2(?:
              2(?:
                [013]\\d|
                2[13-79]|
                4[1-6]|
                5[2457]|
                6[124-8]|
                7[1-4]|
                8[13-6]|
                9[1267]
              )|
              3(?:
                1[467]|
                2[03-6]|
                3[13-8]|
                [49][2-6]|
                5[2-8]|
                [067]\\d
              )|
              4(?:
                7[3-8]|
                9\\d
              )|
              6(?:
                [01346]\\d|
                2[24-6]|
                5[15-8]
              )|
              80\\d|
              9(?:
                [0124789]\\d|
                3[1-6]|
                5[234]|
                6[2-46]
              )
            )|
            3(?:
              3(?:
                2[79]|
                6\\d|
                8[2578]
              )|
              4(?:
                [78]\\d|
                0[0124-9]|
                [1-35]\\d|
                4[24-7]|
                6[02-9]|
                9[123678]
              )|
              5(?:
                [138]\\d|
                2[1245]|
                4[1-9]|
                6[2-4]|
                7[1-6]
              )|
              6[24]\\d|
              7(?:
                [0469]\\d|
                1[1568]|
                2[013-9]|
                3[145]|
                5[14-8]|
                7[2-57]|
                8[0-24-9]
              )|
              8(?:
                [013578]\\d|
                2[15-7]|
                4[13-6]|
                6[1-357-9]|
                9[124]
              )
            )|
            670\\d
          )\\d{6}
        ',
                'specialrate' => '(60[04579]\\d{7})|(810\\d{7})',
                'personal_number' => '',
                'voip' => '',
                'pager' => '',
                'toll_free' => '800\\d{7}',
                'fixed_line' => '
          11\\d{8}|
          (?:
            2(?:
              2(?:
                [013]\\d|
                2[13-79]|
                4[1-6]|
                5[2457]|
                6[124-8]|
                7[1-4]|
                8[13-6]|
                9[1267]
              )|
              3(?:
                1[467]|
                2[03-6]|
                3[13-8]|
                [49][2-6]|
                5[2-8]|
                [067]\\d
              )|
              4(?:
                7[3-8]|
                9\\d
              )|
              6(?:
                [01346]\\d|
                2[24-6]|
                5[15-8]
              )|
              80\\d|
              9(?:
                [0124789]\\d|
                3[1-6]|
                5[234]|
                6[2-46]
              )
            )|
            3(?:
              3(?:
                2[79]|
                6\\d|
                8[2578]
              )|
              4(?:
                [78]\\d|
                0[0124-9]|
                [1-35]\\d|
                4[24-7]|
                6[02-9]|
                9[123678]
              )|
              5(?:
                [138]\\d|
                2[1245]|
                4[1-9]|
                6[2-4]|
                7[1-6]
              )|
              6[24]\\d|
              7(?:
                [0469]\\d|
                1[1568]|
                2[013-9]|
                3[145]|
                5[14-8]|
                7[2-57]|
                8[0-24-9]
              )|
              8(?:
                [013578]\\d|
                2[15-7]|
                4[13-6]|
                6[1-357-9]|
                9[124]
              )
            )|
            670\\d
          )\\d{6}
        ',
                'mobile' => '
          675\\d{7}|
          9(?:
            11[2-9]\\d{7}|
            (?:
              2(?:
                2[013]|
                3[067]|
                49|
                6[01346]|
                80|
                9[147-9]
              )|
              3(?:
                36|
                4[12358]|
                5[138]|
                6[24]|
                7[069]|
                8[013578]
              )
            )[2-9]\\d{6}|
            \\d{4}[2-9]\\d{5}
          )
        '
              };
my %areanames = (
  5411 => "Buenos\ Aires",
  54220 => "Merlo",
  54221 => "La\ Plata",
  542221 => "Verónica\,\ Buenos\ Aires",
  542223 => "Coronel\ Brandsen",
  542224 => "Buenos\ Aires\ Province",
  542225 => "San\ Vicente\,\ Buenos\ Aires",
  542226 => "Cañuelas",
  542227 => "Lobos",
  542229 => "Buenos\ Aires\ Province",
  54223 => "Mar\ del\ Plata\,\ General\ Pueyrredón",
  542241 => "Buenos\ Aires\ Province",
  542243 => "General\ Belgrano\,\ Buenos\ Aires",
  542244 => "Las\ Flores",
  542245 => "Dolores\,\ Buenos\ Aires",
  542246 => "Santa\ Teresita\,\ La\ Costa",
  542252 => "San\ Clemente\ del\ Tuyú\,\ La\ Costa",
  542254 => "Pinamar\,\ Buenos\ Aires",
  542255 => "Villa\ Gesell\,\ Buenos\ Aires",
  542257 => "Mar\ de\ Ajo\,\ La\ Costa",
  542261 => "Lobería\,\ Buenos\ Aires",
  542262 => "Necochea",
  542265 => "Coronel\ Vidal\,\ Buenos\ Aires",
  542266 => "Buenos\ Aires\ Province",
  542267 => "General\ Juan\ Madariaga",
  542268 => "Maipú\,\ Buenos\ Aires",
  542271 => "San\ Miguel\ del\ Monte\,\ Buenos\ Aires",
  542272 => "Navarro\,\ Buenos\ Aires",
  542281 => "La\ Matanza",
  542283 => "Buenos\ Aires\ Province",
  542284 => "Olavarría\,\ Buenos\ Aires",
  542285 => "Laprida\,\ Buenos\ Aires",
  542286 => "General\ Lamadrid\,\ Buenos\ Aires",
  542291 => "Miramar\,\ Buenos\ Aires",
  542292 => "Buenos\ Aires\ Province",
  542296 => "Ayacucho\,\ Buenos\ Aires",
  542297 => "Buenos\ Aires\ Province",
  54230 => "Pilar\,\ Buenos\ Aires",
  542302 => "General\ Pico\,\ La\ Pampa",
  542314 => "Bolívar\,\ Buenos\ Aires",
  542316 => "Daireaux\,\ Buenos\ Aires",
  542317 => "9\ de\ Julio\,\ Buenos\ Aires",
  542320 => "José\ C\.\ Paz",
  542323 => "Luján",
  542324 => "Mercedes",
  542325 => "San\ Andrés\ de\ Giles\/Azcuénaga",
  542326 => "San\ Antonio\ de\ Areco",
  542331 => "Realicó\,\ La\ Pampa",
  542333 => "Quemú\ Quemú",
  542334 => "Eduardo\ Castex\,\ La\ Pampa",
  542335 => "Ingeniero\ Luiggi\,\ La\ Pampa",
  542336 => "Capital",
  542337 => "Buenos\ Aires\ Province",
  542342 => "Bragado",
  542344 => "Buenos\ Aires\ Province",
  542345 => "General\ Pueyrredón",
  542346 => "Chivilcoy",
  542352 => "Chacabuco",
  542353 => "General\ Arenales\,\ Buenos\ Aires",
  542354 => "Buenos\ Aires\ Province",
  542355 => "Lincoln\,\ Buenos\ Aires",
  542356 => "General\ Pinto\,\ Buenos\ Aires",
  542358 => "Buenos\ Aires\ Province",
  54236 => "Junín\,\ Buenos\ Aires",
  54237 => "Moreno",
  542392 => "Buenos\ Aires\/Trenque\ Lauquen",
  542394 => "Salliqueló\,\ Buenos\ Aires",
  542395 => "La\ Matanza",
  542396 => "Pehuajó\,\ Buenos\ Aires",
  542473 => "Colón\,\ Buenos\ Aires",
  542474 => "Buenos\ Aires\ Province",
  542475 => "Rojas\,\ Buenos\ Aires",
  542477 => "Pergamino",
  542478 => "Arrecifes\,\ Buenos\ Aires",
  54249 => "Tandil\,\ Buenos\ Aires",
  54260 => "San\ Rafael",
  54261 => "Mendoza\,\ Capital",
  542622 => "Tunuyán\,\ Mendoza",
  542625 => "General\ Alvear\,\ Mendoza",
  54263 => "San\ Martin",
  54264 => "San\ Juan\,\ Capital",
  542646 => "Valle\ Fértil",
  542656 => "Merlo\,\ San\ Luis",
  542657 => "Villa\ Mercedes\,\ General\ Pedernera",
  54266 => "San\ Luis\,\ La\ Capital",
  54280 => "Trelew\,\ Rawson",
  542901 => "Ushuaia",
  542902 => "El\ Calafate\,\ Lago\ Argentino",
  54291 => "Bahía\ Blanca",
  542920 => "Viedma\,\ Adolfo\ Alsina",
  542921 => "Coronel\ Dorrego\,\ Buenos\ Aires",
  542922 => "Coronel\ Pringles\,\ Buenos\ Aires",
  542923 => "Pigüé\,\ Buenos\ Aires",
  542924 => "Darregueira\,\ Buenos\ Aires",
  542926 => "Coronel\ Suárez\,\ Buenos\ Aires",
  542927 => "Buenos\ Aires\ Province",
  542928 => "Pedro\ Luro\,\ Buenos\ Aires",
  542931 => "Río\ Colorado\,\ Río\ Negro",
  542932 => "Punta\ Alta\,\ Buenos\ Aires",
  542934 => "San\ Antonio\ Oeste\,\ Río\ Negro",
  542936 => "Buenos\ Aires\ Province",
  54294 => "San\ Carlos\ de\ Bariloche\,\ Río\ Negro",
  542940 => "Ingeniero\ Jacobacci\,\ Río\ Negro",
  542942 => "Zapala",
  542945 => "Esquel\,\ Futaleufú",
  542946 => "Choele\ Choel\,\ Río\ Negro",
  542948 => "Chos\ Malal\,\ Neuquén",
  542952 => "General\ Acha\,\ La\ Pampa",
  542953 => "Macachín\,\ La\ Pampa",
  542954 => "Santa\ Rosa\,\ La\ Pampa",
  542962 => "Puerto\ San\ Julián\,\ Santa\ Cruz",
  542964 => "Río\ Grande",
  542966 => "Río\ Gallegos\,\ Ger\ Aike",
  54297 => "Comodoro\ Rivadavia\,\ Escalante",
  542972 => "San\ Martín\ de\ los\ Andes",
  54298 => "General\ Roca\,\ Río\ Negro",
  542982 => "Claromeco\,\ Buenos\ Aires",
  54298240 => "Orense\,\ Buenos\ Aires",
  54298242 => "Orense\,\ Buenos\ Aires",
  542982497 => "San\ Francisco\ de\ Bellocq\,\ Buenos\ Aires",
  542983 => "Tres\ Arroyos\,\ Buenos\ Aires",
  54299 => "Neuquén\,\ Confluencia",
  543327 => "López\ Camelo\,\ Buenos\ Aires",
  543329 => "Buenos\ Aires\ Province",
  54336 => "San\ Nicolás\,\ Buenos\ Aires",
  543382 => "Rufino\,\ Santa\ Fe",
  543385 => "Laboulaye\,\ Córdoba",
  543388 => "General\ Villegas\,\ Buenos\ Aires",
  543400 => "Villa\ Constitución\,\ Santa\ Fe",
  543401 => "El\ Trebol\,\ Santa\ Fe",
  543402 => "Santa\ Fe",
  543404 => "Rosario",
  543405 => "San\ Javier\,\ Santa\ Fe",
  543406 => "San\ Jorge\,\ Santa\ Fe",
  543407 => "Ramallo",
  543408 => "San\ Cristóbal\,\ Santa\ Fe",
  54341 => "Rosario",
  54342 => "Santa\ Fe\,\ La\ Capital",
  54343 => "Paraná",
  543442 => "Concepción\ del\ Uruguay\,\ Entre\ Ríos",
  543444 => "Gualeguay\,\ Entre\ Ríos",
  543445 => "Rosario\ del\ Tala\,\ Entre\ Ríos",
  543446 => "Gualeguaychú",
  543447 => "Colón",
  54345 => "Concordia\,\ Entre\ Ríos",
  543460 => "Santa\ Teresa\,\ Santa\ Fe",
  543462 => "Venado\ Tuerto\,\ General\ López",
  543463 => "Canals\,\ Córdoba",
  543464 => "Casilda\,\ Santa\ Fe",
  543465 => "Firmat\,\ Santa\ Fe",
  543467 => "San\ José\ de\ La\ Esquina\,\ Santa\ Fe",
  543469 => "Acebal\,\ Santa\ Fe",
  543471 => "Cañada\ de\ Gómez\,\ Santa\ Fe",
  543472 => "Marcos\ Juárez",
  543476 => "San\ Lorenzo\,\ Santa\ Fe",
  54348 => "Escobar\,\ Buenos\ Aires",
  543482 => "Reconquista\,\ Santa\ Fe",
  543483 => "Rosario",
  543487 => "Zárate",
  543489 => "Campana",
  543491 => "Ceres\,\ Santa\ Fe",
  543492 => "Rafaela\,\ Santa\ Fe",
  543493 => "Sunchales\,\ Santa\ Fe",
  543496 => "Esperanza\,\ Santa\ Fe",
  543498 => "San\ Justo\,\ Santa\ Fe",
  54351 => "Córdoba\,\ Capital",
  543521 => "Capital",
  543525 => "Jesús\ María\,\ Córdoba",
  54353 => "Villa\ María\,\ General\ San\ Martin",
  543541 => "Villa\ Carlos\ Paz\,\ Córdoba",
  543543 => "Córdoba\,\ Capital",
  543544 => "Villa\ Dolores\,\ Córdoba",
  543546 => "Villa\ General\ Belgrano\,\ Córdoba",
  543547 => "Alta\ Gracia\,\ Córdoba",
  543548 => "La\ Falda\,\ Córdoba",
  543549 => "Córdoba",
  543562 => "Morteros\,\ Córdoba",
  543563 => "Capital",
  543564 => "Córdoba",
  543571 => "Río\ Tercero\,\ Córdoba",
  543572 => "Capital",
  543573 => "Villa\ del\ Rosario\,\ Córdoba",
  543576 => "Córdoba",
  54358 => "Río\ Cuarto",
  54362 => "Resistencia\,\ San\ Fernando",
  54364 => "Presidencia\ Roque\ Sáenz\ Pena\,\ Chaco",
  54370 => "Formosa",
  543718 => "Clorinda\,\ Formosa",
  543725 => "Chaco",
  543731 => "Charata\,\ Chacabuco",
  543734 => "Machagai\,\ Chaco",
  543735 => "Villa\ Angela\,\ Mayor\ Luis\ Fonta",
  543743 => "Puerto\ Rico\,\ Misiones",
  543751 => "El\ Dorado\,\ Misiones",
  543754 => "Leandro\ N\.\ Alem\,\ Misiones",
  543755 => "Oberá\,\ Misiones",
  543756 => "Santo\ Tomé\,\ Corrientes",
  543757 => "Puerto\ Iguazú\,\ Misiones",
  543758 => "Apóstoles\,\ Misiones",
  54376 => "Posadas\,\ Capital",
  543772 => "Paso\ de\ Los\ Libres\,\ Corrientes\/Resistencia",
  543773 => "Mercedes\,\ Corrientes",
  543774 => "Curuzú\ Cuatiá\,\ Corrientes",
  543775 => "Monte\ Caseros\,\ Corrientes",
  543777 => "Goya\,\ Corrientes",
  54379 => "Corrientes\,\ Capital",
  54380 => "La\ Rioja",
  54381 => "San\ Miguel\ de\ Tucumán\,\ Capital",
  543825 => "Chilecito\,\ La\ Rioja",
  54383 => "Catamarca",
  543835 => "Andalgalá\,\ Catamarca",
  543844 => "Añatuya\,\ Santiago\ del\ Estero",
  54385 => "Santiago\ del\ Estero\,\ Capital",
  543863 => "Monteros\,\ Tucumán",
  543865 => "Concepción\,\ Tucumán",
  543868 => "Cafayate\,\ Salta",
  54387 => "Salta\,\ Capital",
  54388 => "San\ Salvador\ de\ Jujuy\,\ Doctor\ Manuel\ Belgrano",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+54|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;