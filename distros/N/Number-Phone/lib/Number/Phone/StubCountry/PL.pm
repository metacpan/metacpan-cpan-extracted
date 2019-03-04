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
our $VERSION = 1.20190303205540;

my $formatters = [
                {
                  'pattern' => '(\\d{5})',
                  'format' => '$1',
                  'leading_digits' => '19'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})',
                  'leading_digits' => '
            11|
            64
          ',
                  'format' => '$1 $2'
                },
                {
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})',
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
          '
                },
                {
                  'leading_digits' => '64',
                  'format' => '$1 $2 $3',
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
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})(\\d{2})',
                  'leading_digits' => '
            1[2-8]|
            [2-8]|
            9[145]
          ',
                  'format' => '$1 $2 $3 $4'
                }
              ];

my $validators = {
                'toll_free' => '800\\d{6}',
                'personal_number' => '',
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
                'specialrate' => '(801\\d{6})|(70[01346-8]\\d{6})|(804\\d{6})',
                'voip' => '39\\d{7}',
                'pager' => '64\\d{4,7}',
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
        '
              };
my %areanames = (
  4812 => "Kraków",
  4813 => "Krosno",
  4814 => "Tarnów",
  4815 => "Tarnobrzeg",
  4816 => "Przemyśl",
  4817 => "Rzeszów",
  4818 => "Nowy\ Sącz",
  4822 => "Warsaw",
  4823 => "Ciechanów",
  4824 => "Plock",
  4825 => "Siedlce",
  4829 => "Ostrolęka",
  4832 => "Katowice",
  4833 => "Bielsko\-Biala",
  4834 => "Częstochowa",
  4841 => "Kielce",
  4842 => "Lódź",
  4843 => "Sieradz",
  4844 => "Piotrków\ Trybunalski",
  4846 => "Skierniewice",
  4848 => "Radom",
  4852 => "Bydgoszcz",
  4854 => "Wloclawek",
  4855 => "Elbląg",
  4856 => "Toruń",
  4858 => "Gdańsk",
  4859 => "Slupsk",
  4861 => "Poznań",
  4862 => "Kalisz",
  4863 => "Konin",
  4865 => "Leszno",
  4867 => "Pila",
  4868 => "Zielona\ Góra",
  4871 => "Wroclaw",
  4874 => "Walbrzych",
  4875 => "Jelenia\ Góra",
  4876 => "Legnica",
  4877 => "Opole",
  4881 => "Lublin",
  4882 => "Chelm",
  4883 => "Biala\ Podlaska",
  4884 => "Zamość",
  4885 => "Bialystok",
  4886 => "Lomża",
  4887 => "Suwalki",
  4889 => "Olsztyn",
  4891 => "Szczecin",
  4894 => "Koszalin",
  4895 => "Gorzów\ Wielkopolski",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+48|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;