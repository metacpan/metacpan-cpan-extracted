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
package Number::Phone::StubCountry::HN;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120030;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '[237-9]',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'intl_format' => 'NA',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{3})(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            2(?:
              0[0139]|
              1[1-36]|
              [23]\\d|
              4[04-6]|
              5[57]|
              6[24]|
              7[0135689]|
              8[01346-9]|
              9[0-2]
            )|
            4(?:
              07|
              2[3-59]|
              3[13-689]|
              4[0-68]|
              5[1-35]
            )|
            5(?:
              0[78]|
              16|
              4[03-5]|
              5\\d|
              6[014-6]|
              74|
              80
            )|
            6(?:
              [056]\\d|
              17|
              2[07]|
              3[04]|
              4[0-378]|
              [78][0-8]|
              9[01]
            )|
            7(?:
              6[46-9]|
              7[02-9]|
              8[034]|
              91
            )|
            8(?:
              79|
              8[0-357-9]|
              9[1-57-9]
            )
          )\\d{4}
        ',
                'geographic' => '
          2(?:
            2(?:
              0[0139]|
              1[1-36]|
              [23]\\d|
              4[04-6]|
              5[57]|
              6[24]|
              7[0135689]|
              8[01346-9]|
              9[0-2]
            )|
            4(?:
              07|
              2[3-59]|
              3[13-689]|
              4[0-68]|
              5[1-35]
            )|
            5(?:
              0[78]|
              16|
              4[03-5]|
              5\\d|
              6[014-6]|
              74|
              80
            )|
            6(?:
              [056]\\d|
              17|
              2[07]|
              3[04]|
              4[0-378]|
              [78][0-8]|
              9[01]
            )|
            7(?:
              6[46-9]|
              7[02-9]|
              8[034]|
              91
            )|
            8(?:
              79|
              8[0-357-9]|
              9[1-57-9]
            )
          )\\d{4}
        ',
                'mobile' => '[37-9]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '8002\\d{7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{5042200} = "Polo\ Paz";
$areanames{en}->{5042201} = "Polo\ Paz";
$areanames{en}->{5042203} = "Polo\ Paz";
$areanames{en}->{5042209} = "Res\.\ Centro\ América\,\ Tegucigalpa";
$areanames{en}->{5042211} = "El\ Picacho";
$areanames{en}->{5042212} = "Rdsi\ Tegucigalpa\ \(Pri3\)";
$areanames{en}->{5042213} = "Telef\.\ Inalámbrica\ Tegucig\.";
$areanames{en}->{5042216} = "Rdsi\ Tegucigalpa\ \(Pri3\)";
$areanames{en}->{5042220} = "Principal";
$areanames{en}->{5042221} = "Almendros";
$areanames{en}->{5042222} = "Principal";
$areanames{en}->{5042223} = "Polo\ Paz";
$areanames{en}->{5042224} = "Cerro\ Grande";
$areanames{en}->{5042225} = "La\ Granja";
$areanames{en}->{5042226} = "Loarque";
$areanames{en}->{5042227} = "Res\.\ Centro\ América\,\ Tegucigalpa";
$areanames{en}->{5042228} = "Kennedy\,\ Tegucigalpa";
$areanames{en}->{5042229} = "El\ Ocotal";
$areanames{en}->{5042230} = "Kennedy\,\ Tegucigalpa";
$areanames{en}->{5042231} = "Miraflores";
$areanames{en}->{5042232} = "Miraflores";
$areanames{en}->{5042233} = "Toncontín";
$areanames{en}->{5042234} = "Toncontín";
$areanames{en}->{5042235} = "Miraflores";
$areanames{en}->{5042236} = "Almendros";
$areanames{en}->{5042237} = "Principal";
$areanames{en}->{5042238} = "Principal";
$areanames{en}->{5042239} = "Miraflores";
$areanames{en}->{5042240} = "Kennedy\,\ Tegucigalpa";
$areanames{en}->{5042244} = "Tegucigalpa";
$areanames{en}->{5042245} = "La\ Vega\,\ Tegucigalpa";
$areanames{en}->{5042246} = "La\ Vega\,\ Tegucigalpa";
$areanames{en}->{5042255} = "El\ Hato";
$areanames{en}->{5042257} = "Prados\ Universitarios";
$areanames{en}->{5042290} = "Toncontin";
$areanames{en}->{5042291} = "Toncontin";
$areanames{en}->{504240} = "Roatán\,\ Bay\ Islands";
$areanames{en}->{5042423} = "La\ Ceiba";
$areanames{en}->{5042424} = "Sabá";
$areanames{en}->{5042425} = "Utila\,\ Bay\ Islands";
$areanames{en}->{5042429} = "San\ Alejo\/Mesapa";
$areanames{en}->{5042431} = "San\ Francisco\,\ Atlántida";
$areanames{en}->{5042433} = "Arenal";
$areanames{en}->{5042434} = "Trujillo";
$areanames{en}->{5042435} = "Oakridge";
$areanames{en}->{5042436} = "La\ Masica";
$areanames{en}->{5042438} = "Bonito\ Oriental";
$areanames{en}->{5042440} = "La\ Ceiba";
$areanames{en}->{5042442} = "La\ Ceiba";
$areanames{en}->{5042443} = "La\ Ceiba";
$areanames{en}->{5042444} = "Tocoa\,\ Colón";
$areanames{en}->{5042445} = "Coxin\ Hole\,\ Roatán";
$areanames{en}->{5042446} = "Olanchito";
$areanames{en}->{5042448} = "Tela";
$areanames{en}->{5042451} = "Sonaguera";
$areanames{en}->{5042452} = "Coyoles\ Central";
$areanames{en}->{5042453} = "Guanaja";
$areanames{en}->{5042455} = "French\ Harbour";
$areanames{en}->{504251} = "San\ Pedro\ Sula\,\ Cortés";
$areanames{en}->{5042540} = "San\ Pedro\ Sula\,\ Cortés";
$areanames{en}->{5042543} = "Inalámbrica\ Sps";
$areanames{en}->{5042544} = "Rdsi\ San\ Pedro\ Sula";
$areanames{en}->{5042545} = "San\ Pedro\ Sula\,\ Cortés";
$areanames{en}->{5042550} = "San\ Pedro\ Sula\,\ Cortés";
$areanames{en}->{5042551} = "Monte\ Prieto";
$areanames{en}->{5042552} = "San\ Pedro\ Sula\,\ Cortés";
$areanames{en}->{5042553} = "San\ Pedro\ Sula\,\ Cortés";
$areanames{en}->{5042554} = "Monte\ Prieto";
$areanames{en}->{5042555} = "Rivera\ Hernandez\,\ San\ Pedro\ Sula";
$areanames{en}->{5042556} = "La\ Puerta";
$areanames{en}->{5042557} = "San\ Pedro\ Sula\,\ Cortés";
$areanames{en}->{5042558} = "San\ Pedro\ Sula\,\ Cortés";
$areanames{en}->{5042559} = "Col\.\ Satélite";
$areanames{en}->{5042564} = "San\ Pedro\ Sula\,\ Cortés";
$areanames{en}->{5042565} = "Chamelecón";
$areanames{en}->{5042566} = "Jardines\ Del\ Valle";
$areanames{en}->{504257} = "Búfalo";
$areanames{en}->{504261} = "Choloma\,\ Cortés";
$areanames{en}->{5042640} = "C\.\ Comunitarios";
$areanames{en}->{5042641} = "C\.\ Comunitarios";
$areanames{en}->{5042642} = "C\.\ Comunitarios";
$areanames{en}->{5042643} = "Santa\ Bárbara";
$areanames{en}->{5042647} = "Progreso";
$areanames{en}->{5042648} = "Progreso\/Santa\ Cruz";
$areanames{en}->{5042650} = "San\ Manuel\/Rio\ Lindo";
$areanames{en}->{5042651} = "Cucuyagua\/Copán";
$areanames{en}->{5042652} = "Agua\ Caliente";
$areanames{en}->{5042653} = "Nueva\ Ocotepeque";
$areanames{en}->{5042654} = "Santa\ Cruz";
$areanames{en}->{5042655} = "Lepaera\/Corquín";
$areanames{en}->{5042656} = "Gracias\/S\.R\.Copán";
$areanames{en}->{5042657} = "El\ Naranjo\ Sta\ Bárbara";
$areanames{en}->{5042658} = "Macueliso\ Omoa\/Trascerros";
$areanames{en}->{5042659} = "El\ Mochito\/Quimistán";
$areanames{en}->{5042670} = "Villa\ Nueva";
$areanames{en}->{5042671} = "Yoro";
$areanames{en}->{5042672} = "Cofradía";
$areanames{en}->{5042673} = "Potrerillos";
$areanames{en}->{5042674} = "Sulaco\/Los\ Orcones";
$areanames{en}->{5042675} = "Villa\ Nueva";
$areanames{en}->{5042678} = "Potrerillos";
$areanames{en}->{504268} = "La\ Lima";
$areanames{en}->{5042690} = "El\ Negrito";
$areanames{en}->{5042691} = "Morazán";
$areanames{en}->{5042764} = "Amarat\/Marcala";
$areanames{en}->{5042766} = "Valle\ De\ Ángeles";
$areanames{en}->{5042767} = "Ojojona";
$areanames{en}->{5042768} = "Sabana\ Grande";
$areanames{en}->{5042769} = "Guaimaca";
$areanames{en}->{5042770} = "Comayagua";
$areanames{en}->{5042772} = "Comayagua";
$areanames{en}->{5042773} = "Siguatepeque";
$areanames{en}->{5042774} = "La\ Paz";
$areanames{en}->{5042775} = "Talanga";
$areanames{en}->{5042776} = "Zamorano";
$areanames{en}->{5042777} = "Proyecto\ Ala";
$areanames{en}->{5042778} = "Centros\ Comunitarios";
$areanames{en}->{5042779} = "Santa\ Lucía";
$areanames{en}->{5042780} = "Choluteca";
$areanames{en}->{5042783} = "La\ Esperanza";
$areanames{en}->{5042784} = "La\ Libertad";
$areanames{en}->{504287} = "Choluteca";
$areanames{en}->{5042880} = "Choluteca";
$areanames{en}->{5042881} = "San\ Lorenzo";
$areanames{en}->{5042882} = "Choluteca";
$areanames{en}->{5042883} = "Danli";
$areanames{en}->{5042885} = "Juticalpa";
$areanames{en}->{5042887} = "Proyecto\ Ala";
$areanames{en}->{5042888} = "S\.\ Marcos\/Proy\.\ Ala";
$areanames{en}->{5042889} = "Campamento";
$areanames{en}->{5042891} = "S\.\ Franc\.\ De\ La\ Paz";
$areanames{en}->{5042892} = "Yuscarán";
$areanames{en}->{5042893} = "El\ Paraíso";
$areanames{en}->{5042894} = "Amatillo\/Goascorán";
$areanames{en}->{5042895} = "Nacaome\/Amapala";
$areanames{en}->{5042897} = "San\ Fco\.\ De\ Becerra";
$areanames{en}->{5042898} = "Domsat";
$areanames{en}->{5042899} = "Catacamas";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+504|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;