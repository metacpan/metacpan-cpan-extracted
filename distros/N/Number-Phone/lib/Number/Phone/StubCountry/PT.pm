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
package Number::Phone::StubCountry::PT;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20191211212303;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2[12]',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[236-9]',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            [12]\\d|
            [35][1-689]|
            4[1-59]|
            6[1-35689]|
            7[1-9]|
            8[1-69]|
            9[1256]
          )\\d{6}
        ',
                'geographic' => '
          2(?:
            [12]\\d|
            [35][1-689]|
            4[1-59]|
            6[1-35689]|
            7[1-9]|
            8[1-69]|
            9[1256]
          )\\d{6}
        ',
                'mobile' => '
          6[356]9230\\d{3}|
          (?:
            6[036]93|
            9(?:
              [1-36]\\d\\d|
              480
            )
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '884[0-4689]\\d{5}',
                'specialrate' => '(
          80(?:
            8\\d|
            9[1579]
          )\\d{5}
        )|(
          (?:
            6(?:
              0[178]|
              4[68]
            )\\d|
            76(?:
              0[1-57]|
              1[2-47]|
              2[237]
            )
          )\\d{5}
        )|(
          70(?:
            7\\d|
            8[17]
          )\\d{5}
        )',
                'toll_free' => '80[02]\\d{6}',
                'voip' => '30\\d{7}'
              };
my %areanames = ();
$areanames{pt}->{35121} = "Lisboa";
$areanames{pt}->{35122} = "Porto";
$areanames{pt}->{351231} = "Mealhada";
$areanames{pt}->{351232} = "Viseu";
$areanames{pt}->{351233} = "Figueira\ da\ Foz";
$areanames{pt}->{351234} = "Aveiro";
$areanames{pt}->{351235} = "Arganil";
$areanames{pt}->{351236} = "Pombal";
$areanames{pt}->{351238} = "Seia";
$areanames{pt}->{351239} = "Coimbra";
$areanames{pt}->{351241} = "Abrantes";
$areanames{pt}->{351242} = "Ponte\ de\ Sôr";
$areanames{pt}->{351243} = "Santarém";
$areanames{pt}->{351244} = "Leiria";
$areanames{pt}->{351245} = "Portalegre";
$areanames{pt}->{351249} = "Torres\ Novas";
$areanames{pt}->{351251} = "Valença";
$areanames{pt}->{351252} = "V\.\ N\.\ de\ Famalicão";
$areanames{pt}->{351253} = "Braga";
$areanames{pt}->{351254} = "Peso\ da\ Régua";
$areanames{pt}->{351255} = "Penafiel";
$areanames{pt}->{351256} = "S\.\ João\ da\ Madeira";
$areanames{pt}->{351258} = "Viana\ do\ Castelo";
$areanames{pt}->{351259} = "Vila\ Real";
$areanames{pt}->{351261} = "Torres\ Vedras";
$areanames{pt}->{351262} = "Caldas\ da\ Rainha";
$areanames{pt}->{351263} = "Vila\ Franca\ de\ Xira";
$areanames{pt}->{351265} = "Setúbal";
$areanames{pt}->{351266} = "Évora";
$areanames{pt}->{351268} = "Estremoz";
$areanames{pt}->{351269} = "Santiago\ do\ Cacém";
$areanames{pt}->{351271} = "Guarda";
$areanames{pt}->{351272} = "Castelo\ Branco";
$areanames{pt}->{351273} = "Bragança";
$areanames{pt}->{351274} = "Proença\-a\-Nova";
$areanames{pt}->{351275} = "Covilhã";
$areanames{pt}->{351276} = "Chaves";
$areanames{pt}->{351277} = "Idanha\-a\-Nova";
$areanames{pt}->{351278} = "Mirandela";
$areanames{pt}->{351279} = "Moncorvo";
$areanames{pt}->{351281} = "Tavira";
$areanames{pt}->{351282} = "Portimão";
$areanames{pt}->{351283} = "Odemira";
$areanames{pt}->{351284} = "Beja";
$areanames{pt}->{351285} = "Moura";
$areanames{pt}->{351286} = "Castro\ Verde";
$areanames{pt}->{351289} = "Faro";
$areanames{pt}->{351291} = "Funchal";
$areanames{pt}->{351292} = "Horta";
$areanames{pt}->{351295} = "Angra\ do\ Heroísmo";
$areanames{pt}->{351296} = "Ponta\ Delgada";
$areanames{en}->{35121} = "Lisbon";
$areanames{en}->{35122} = "Porto";
$areanames{en}->{351231} = "Mealhada";
$areanames{en}->{351232} = "Viseu";
$areanames{en}->{351233} = "Figueira\ da\ Foz";
$areanames{en}->{351234} = "Aveiro";
$areanames{en}->{351235} = "Arganil";
$areanames{en}->{351236} = "Pombal";
$areanames{en}->{351238} = "Seia";
$areanames{en}->{351239} = "Coimbra";
$areanames{en}->{351241} = "Abrantes";
$areanames{en}->{351242} = "Ponte\ de\ Sôr";
$areanames{en}->{351243} = "Santarém";
$areanames{en}->{351244} = "Leiria";
$areanames{en}->{351245} = "Portalegre";
$areanames{en}->{351249} = "Torres\ Novas";
$areanames{en}->{351251} = "Valença";
$areanames{en}->{351252} = "V\.\ N\.\ de\ Famalicão";
$areanames{en}->{351253} = "Braga";
$areanames{en}->{351254} = "Peso\ da\ Régua";
$areanames{en}->{351255} = "Penafiel";
$areanames{en}->{351256} = "S\.\ João\ da\ Madeira";
$areanames{en}->{351258} = "Viana\ do\ Castelo";
$areanames{en}->{351259} = "Vila\ Real";
$areanames{en}->{351261} = "Torres\ Vedras";
$areanames{en}->{351262} = "Caldas\ da\ Rainha";
$areanames{en}->{351263} = "Vila\ Franca\ de\ Xira";
$areanames{en}->{351265} = "Setúbal";
$areanames{en}->{351266} = "Évora";
$areanames{en}->{351268} = "Estremoz";
$areanames{en}->{351269} = "Santiago\ do\ Cacém";
$areanames{en}->{351271} = "Guarda";
$areanames{en}->{351272} = "Castelo\ Branco";
$areanames{en}->{351273} = "Bragança";
$areanames{en}->{351274} = "Proença\-a\-Nova";
$areanames{en}->{351275} = "Covilhã";
$areanames{en}->{351276} = "Chaves";
$areanames{en}->{351277} = "Idanha\-a\-Nova";
$areanames{en}->{351278} = "Mirandela";
$areanames{en}->{351279} = "Moncorvo";
$areanames{en}->{351281} = "Tavira";
$areanames{en}->{351282} = "Portimão";
$areanames{en}->{351283} = "Odemira";
$areanames{en}->{351284} = "Beja";
$areanames{en}->{351285} = "Moura";
$areanames{en}->{351286} = "Castro\ Verde";
$areanames{en}->{351289} = "Faro";
$areanames{en}->{351291} = "Funchal";
$areanames{en}->{351292} = "Horta";
$areanames{en}->{351295} = "Angra\ do\ Heroísmo";
$areanames{en}->{351296} = "Ponta\ Delgada";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+351|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;