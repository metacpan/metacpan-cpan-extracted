# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20230903131448;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2[12]',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            16|
            [236-9]
          ',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            [12]\\d|
            3[1-689]|
            4[1-59]|
            [57][1-9]|
            6[1-35689]|
            8[1-69]|
            9[1256]
          )\\d{6}
        ',
                'geographic' => '
          2(?:
            [12]\\d|
            3[1-689]|
            4[1-59]|
            [57][1-9]|
            6[1-35689]|
            8[1-69]|
            9[1256]
          )\\d{6}
        ',
                'mobile' => '
          6(?:
            [06]92(?:
              30|
              9\\d
            )|
            [35]92(?:
              3[03]|
              9\\d
            )
          )\\d{3}|
          (?:
            (?:
              16|
              6[0356]
            )93|
            9(?:
              [1-36]\\d\\d|
              480
            )
          )\\d{5}
        ',
                'pager' => '6222\\d{5}',
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
            38[01]|
            596|
            (?:
              7\\d|
              8[17]
            )\\d
          )\\d{4}
        )',
                'toll_free' => '80[02]\\d{6}',
                'voip' => '30\\d{7}'
              };
my %areanames = ();
$areanames{en} = {"351255", "Penafiel",
"351272", "Castelo\ Branco",
"351251", "Valença",
"351254", "Peso\ da\ Régua",
"351258", "Viana\ do\ Castelo",
"351259", "Vila\ Real",
"351277", "Idanha\-a\-Nova",
"351253", "Braga",
"351256", "S\.\ João\ da\ Madeira",
"351262", "Caldas\ da\ Rainha",
"351268", "Estremoz",
"351275", "Covilhã",
"351269", "Santiago\ do\ Cacém",
"351274", "Proença\-a\-Nova",
"351263", "Vila\ Franca\ de\ Xira",
"351266", "Évora",
"351252", "V\.\ N\.\ de\ Famalicão",
"351271", "Guarda",
"351279", "Moncorvo",
"351265", "Setúbal",
"351278", "Mirandela",
"351273", "Bragança",
"351276", "Chaves",
"351261", "Torres\ Vedras",
"351257", "Braga",
"351296", "Ponta\ Delgada",
"351242", "Ponte\ de\ Sôr",
"351232", "Viseu",
"351291", "Funchal",
"351295", "Angra\ do\ Heroísmo",
"351282", "Portimão",
"351241", "Abrantes",
"35122", "Porto",
"35121", "Lisbon",
"351236", "Pombal",
"351233", "Figueira\ da\ Foz",
"351289", "Faro",
"351244", "Leiria",
"351238", "Seia",
"351245", "Portalegre",
"351239", "Coimbra",
"351286", "Castro\ Verde",
"351283", "Odemira",
"351292", "Horta",
"351285", "Moura",
"351231", "Mealhada",
"351234", "Aveiro",
"351243", "Santarém",
"351235", "Arganil",
"351281", "Tavira",
"351284", "Beja",
"351249", "Torres\ Novas",};
$areanames{pt} = {"35121", "Lisboa",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+351|\D)//g;
      my $self = bless({ country_code => '351', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;