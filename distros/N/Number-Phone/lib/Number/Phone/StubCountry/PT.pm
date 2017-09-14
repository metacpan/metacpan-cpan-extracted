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
our $VERSION = 1.20170908113149;

my $formatters = [
                {
                  'pattern' => '(2\\d)(\\d{3})(\\d{4})',
                  'leading_digits' => '2[12]'
                },
                {
                  'pattern' => '([2-46-9]\\d{2})(\\d{3})(\\d{3})',
                  'leading_digits' => '
            2[3-9]|
            [346-9]
          '
                }
              ];

my $validators = {
                'personal_number' => '884[0-4689]\\d{5}',
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
                'pager' => '',
                'toll_free' => '80[02]\\d{6}',
                'mobile' => '
          9(?:
            [1236]\\d{2}|
            480
          )\\d{5}
        ',
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
                'specialrate' => '(
          80(?:
            8\\d|
            9[1579]
          )\\d{5}
        )|(
          6(?:
            0[178]|
            4[68]
          )\\d{6}|
          76(?:
            0[1-57]|
            1[2-47]|
            2[237]
          )\\d{5}
        )|(
          7(?:
            0(?:
              7\\d|
              8[17]
            )
          )\\d{5}
        )',
                'voip' => '30\\d{7}'
              };
my %areanames = (
  35121 => "Lisbon",
  35122 => "Porto",
  351231 => "Mealhada",
  351232 => "Viseu",
  351233 => "Figueira\ da\ Foz",
  351234 => "Aveiro",
  351235 => "Arganil",
  351236 => "Pombal",
  351238 => "Seia",
  351239 => "Coimbra",
  351241 => "Abrantes",
  351242 => "Ponte\ de\ Sôr",
  351243 => "Santarém",
  351244 => "Leiria",
  351245 => "Portalegre",
  351249 => "Torres\ Novas",
  351251 => "Valença",
  351252 => "V\.\ N\.\ de\ Famalicão",
  351253 => "Braga",
  351254 => "Peso\ da\ Régua",
  351255 => "Penafiel",
  351256 => "S\.\ João\ da\ Madeira",
  351258 => "Viana\ do\ Castelo",
  351259 => "Vila\ Real",
  351261 => "Torres\ Vedras",
  351262 => "Caldas\ da\ Rainha",
  351263 => "Vila\ Franca\ de\ Xira",
  351265 => "Setúbal",
  351266 => "Évora",
  351268 => "Estremoz",
  351269 => "Santiago\ do\ Cacém",
  351271 => "Guarda",
  351272 => "Castelo\ Branco",
  351273 => "Bragança",
  351274 => "Proença\-a\-Nova",
  351275 => "Covilhã",
  351276 => "Chaves",
  351277 => "Idanha\-a\-Nova",
  351278 => "Mirandela",
  351279 => "Moncorvo",
  351281 => "Tavira",
  351282 => "Portimão",
  351283 => "Odemira",
  351284 => "Beja",
  351285 => "Moura",
  351286 => "Castro\ Verde",
  351289 => "Faro",
  351291 => "Funchal",
  351292 => "Horta",
  351295 => "Angra\ do\ Heroísmo",
  351296 => "Ponta\ Delgada",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+351|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;