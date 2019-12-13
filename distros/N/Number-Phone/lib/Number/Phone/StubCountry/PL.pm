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
package Number::Phone::StubCountry::PL;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20191211212303;

my $formatters = [
                {
                  'format' => '$1',
                  'leading_digits' => '19',
                  'pattern' => '(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            11|
            64
          ',
                  'pattern' => '(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            (?:
              1[2-8]|
              2[2-69]|
              3[2-4]|
              4[1-468]|
              5[24-689]|
              6[1-3578]|
              7[14-7]|
              8[1-79]|
              9[145]
            )19
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '64',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2,3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            39|
            45|
            5[0137]|
            6[0469]|
            7[02389]|
            8[08]
          ',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            1[2-8]|
            [2-8]|
            9[145]
          ',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1[2-8]|
            2[2-69]|
            3[2-4]|
            4[1-468]|
            5[24-689]|
            6[1-3578]|
            7[14-7]|
            8[1-79]|
            9[145]
          )(?:
            [02-9]\\d{6}|
            1(?:
              [0-8]\\d{5}|
              9\\d{3}(?:
                \\d{2}
              )?
            )
          )
        ',
                'geographic' => '
          (?:
            1[2-8]|
            2[2-69]|
            3[2-4]|
            4[1-468]|
            5[24-689]|
            6[1-3578]|
            7[14-7]|
            8[1-79]|
            9[145]
          )(?:
            [02-9]\\d{6}|
            1(?:
              [0-8]\\d{5}|
              9\\d{3}(?:
                \\d{2}
              )?
            )
          )
        ',
                'mobile' => '
          (?:
            45|
            5[0137]|
            6[069]|
            7[2389]|
            88
          )\\d{7}
        ',
                'pager' => '64\\d{4,7}',
                'personal_number' => '',
                'specialrate' => '(801\\d{6})|(70[01346-8]\\d{6})|(804\\d{6})',
                'toll_free' => '800\\d{6}',
                'voip' => '39\\d{7}'
              };
my %areanames = ();
$areanames{pl}->{4812} = "Kraków";
$areanames{pl}->{4813} = "Krosno";
$areanames{pl}->{4814} = "Tarnów";
$areanames{pl}->{4815} = "Tarnobrzeg";
$areanames{pl}->{4816} = "Przemyśl";
$areanames{pl}->{4817} = "Rzeszów";
$areanames{pl}->{4818} = "Nowy\ Sącz";
$areanames{pl}->{4822} = "Warszawa";
$areanames{pl}->{4823} = "Ciechanów";
$areanames{pl}->{4824} = "Płock";
$areanames{pl}->{4825} = "Siedlce";
$areanames{pl}->{4829} = "Ostrołęka";
$areanames{pl}->{4832} = "Katowice";
$areanames{pl}->{4833} = "Bielsko\-Biała";
$areanames{pl}->{4834} = "Częstochowa";
$areanames{pl}->{4841} = "Kielce";
$areanames{pl}->{4842} = "Łódź";
$areanames{pl}->{4843} = "Sieradz";
$areanames{pl}->{4844} = "Piotrków\ Trybunalski";
$areanames{pl}->{4846} = "Skierniewice";
$areanames{pl}->{4848} = "Radom";
$areanames{pl}->{4852} = "Bydgoszcz";
$areanames{pl}->{4854} = "Włocławek";
$areanames{pl}->{4855} = "Elbląg";
$areanames{pl}->{4856} = "Toruń";
$areanames{pl}->{4858} = "Gdańsk";
$areanames{pl}->{4859} = "Słupsk";
$areanames{pl}->{4861} = "Poznań";
$areanames{pl}->{4862} = "Kalisz";
$areanames{pl}->{4863} = "Konin";
$areanames{pl}->{4865} = "Leszno";
$areanames{pl}->{4867} = "Piła";
$areanames{pl}->{4868} = "Zielona\ Góra";
$areanames{pl}->{4871} = "Wrocław";
$areanames{pl}->{4874} = "Wałbrzych";
$areanames{pl}->{4875} = "Jelenia\ Góra";
$areanames{pl}->{4876} = "Legnica";
$areanames{pl}->{4877} = "Opole";
$areanames{pl}->{4881} = "Lublin";
$areanames{pl}->{4882} = "Chełm";
$areanames{pl}->{4883} = "Biała\ Podlaska";
$areanames{pl}->{4884} = "Zamość";
$areanames{pl}->{4885} = "Białystok";
$areanames{pl}->{4886} = "Łomża";
$areanames{pl}->{4887} = "Suwałki";
$areanames{pl}->{4889} = "Olsztyn";
$areanames{pl}->{4891} = "Szczecin";
$areanames{pl}->{4894} = "Koszalin";
$areanames{pl}->{4895} = "Gorzów\ Wielkopolski";
$areanames{en}->{4812} = "Kraków";
$areanames{en}->{4813} = "Krosno";
$areanames{en}->{4814} = "Tarnów";
$areanames{en}->{4815} = "Tarnobrzeg";
$areanames{en}->{4816} = "Przemyśl";
$areanames{en}->{4817} = "Rzeszów";
$areanames{en}->{4818} = "Nowy\ Sącz";
$areanames{en}->{4822} = "Warsaw";
$areanames{en}->{4823} = "Ciechanów";
$areanames{en}->{4824} = "Plock";
$areanames{en}->{4825} = "Siedlce";
$areanames{en}->{4829} = "Ostrolęka";
$areanames{en}->{4832} = "Katowice";
$areanames{en}->{4833} = "Bielsko\-Biala";
$areanames{en}->{4834} = "Częstochowa";
$areanames{en}->{4841} = "Kielce";
$areanames{en}->{4842} = "Lódź";
$areanames{en}->{4843} = "Sieradz";
$areanames{en}->{4844} = "Piotrków\ Trybunalski";
$areanames{en}->{4846} = "Skierniewice";
$areanames{en}->{4848} = "Radom";
$areanames{en}->{4852} = "Bydgoszcz";
$areanames{en}->{4854} = "Wloclawek";
$areanames{en}->{4855} = "Elbląg";
$areanames{en}->{4856} = "Toruń";
$areanames{en}->{4858} = "Gdańsk";
$areanames{en}->{4859} = "Slupsk";
$areanames{en}->{4861} = "Poznań";
$areanames{en}->{4862} = "Kalisz";
$areanames{en}->{4863} = "Konin";
$areanames{en}->{4865} = "Leszno";
$areanames{en}->{4867} = "Pila";
$areanames{en}->{4868} = "Zielona\ Góra";
$areanames{en}->{4871} = "Wroclaw";
$areanames{en}->{4874} = "Walbrzych";
$areanames{en}->{4875} = "Jelenia\ Góra";
$areanames{en}->{4876} = "Legnica";
$areanames{en}->{4877} = "Opole";
$areanames{en}->{4881} = "Lublin";
$areanames{en}->{4882} = "Chelm";
$areanames{en}->{4883} = "Biala\ Podlaska";
$areanames{en}->{4884} = "Zamość";
$areanames{en}->{4885} = "Bialystok";
$areanames{en}->{4886} = "Lomża";
$areanames{en}->{4887} = "Suwalki";
$areanames{en}->{4889} = "Olsztyn";
$areanames{en}->{4891} = "Szczecin";
$areanames{en}->{4894} = "Koszalin";
$areanames{en}->{4895} = "Gorzów\ Wielkopolski";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+48|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;