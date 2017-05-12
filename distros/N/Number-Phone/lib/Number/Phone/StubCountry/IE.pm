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
package Number::Phone::StubCountry::IE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'leading_digits' => '1',
                  'pattern' => '(1)(\\d{3,4})(\\d{4})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{5})',
                  'leading_digits' => '
            2[24-9]|
            47|
            58|
            6[237-9]|
            9[35-9]
          '
                },
                {
                  'leading_digits' => '
            40[24]|
            50[45]
          ',
                  'pattern' => '(\\d{3})(\\d{5})'
                },
                {
                  'leading_digits' => '48',
                  'pattern' => '(48)(\\d{4})(\\d{4})'
                },
                {
                  'pattern' => '(818)(\\d{3})(\\d{3})',
                  'leading_digits' => '81'
                },
                {
                  'leading_digits' => '
            [24-69]|
            7[14]
          ',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'pattern' => '([78]\\d)(\\d{3,4})(\\d{4})',
                  'leading_digits' => '
            76|
            8[35-9]
          '
                },
                {
                  'pattern' => '(700)(\\d{3})(\\d{3})',
                  'leading_digits' => '70'
                },
                {
                  'leading_digits' => '
            1(?:
              8[059]0|
              5
            )
          ',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'voip' => '76\\d{7}',
                'pager' => '',
                'fixed_line' => '
          1\\d{7,8}|
          2(?:
            1\\d{6,7}|
            3\\d{7}|
            [24-9]\\d{5}
          )|
          4(?:
            0[24]\\d{5}|
            [1-469]\\d{7}|
            5\\d{6}|
            7\\d{5}|
            8[0-46-9]\\d{7}
          )|
          5(?:
            0[45]\\d{5}|
            1\\d{6}|
            [23679]\\d{7}|
            8\\d{5}
          )|
          6(?:
            1\\d{6}|
            [237-9]\\d{5}|
            [4-6]\\d{7}
          )|
          7[14]\\d{7}|
          9(?:
            1\\d{6}|
            [04]\\d{7}|
            [35-9]\\d{5}
          )
        ',
                'mobile' => '
          8(?:
            22\\d{6}|
            [35-9]\\d{7}
          )
        ',
                'specialrate' => '(18[59]0\\d{6})|(
          15(?:
            1[2-8]|
            [2-8]0|
            9[089]
          )\\d{6}
        )|(818\\d{6})',
                'toll_free' => '1800\\d{6}',
                'personal_number' => '700\\d{6}',
                'geographic' => '
          1\\d{7,8}|
          2(?:
            1\\d{6,7}|
            3\\d{7}|
            [24-9]\\d{5}
          )|
          4(?:
            0[24]\\d{5}|
            [1-469]\\d{7}|
            5\\d{6}|
            7\\d{5}|
            8[0-46-9]\\d{7}
          )|
          5(?:
            0[45]\\d{5}|
            1\\d{6}|
            [23679]\\d{7}|
            8\\d{5}
          )|
          6(?:
            1\\d{6}|
            [237-9]\\d{5}|
            [4-6]\\d{7}
          )|
          7[14]\\d{7}|
          9(?:
            1\\d{6}|
            [04]\\d{7}|
            [35-9]\\d{5}
          )
        '
              };
my %areanames = (
  3531 => "Dublin",
  35321 => "Cork\/Kinsale\/Coachford",
  35322 => "Mallow",
  35323 => "Bandon",
  35324 => "Youghal",
  35325 => "Fermoy",
  35326 => "Macroom",
  35327 => "Bantry",
  35328 => "Skibbereen",
  35329 => "Kanturk",
  353402 => "Arklow",
  353404 => "Wicklow",
  35341 => "Drogheda\/Ardee",
  35342 => "Dundalk\/Carrickmacross\/Castleblaney",
  35343 => "Longford\/Granard",
  35344 => "Mullingar\/Castlepollard\/Tyrrellspass",
  35345 => "Naas\/Kildare\/Curragh",
  35346 => "Navan\/Kells\/Trim\/Edenderry\/Enfield",
  35347 => "Monaghan\/Clones",
  35349 => "Cavan\/Cootehill\/Oldcastle\/Belturbet",
  353504 => "Thurles",
  353505 => "Roscrea",
  35351 => "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
  35352 => "Clonmel\/Cahir\/Killenaule",
  35353 => "Wexford\/Enniscorthy\/Ferns\/Gorey",
  35356 => "Kilkenny\/Castlecomer\/Freshford",
  35357 => "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
  35358 => "Dungarvan",
  35359 => "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
  35361 => "Limerick\/Scariff",
  35362 => "Tipperary\/Cashel",
  35363 => "Charleville",
  35364 => "Killarney\/Rathmore",
  35365 => "Ennis\/Ennistymon\/Kilrush",
  35366 => "Tralee\/Dingle\/Killorglin\/Cahersiveen",
  35367 => "Nenagh",
  35368 => "Listowel",
  35369 => "Newcastle\ West",
  35371 => "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
  35374 => "Letterkenny\/Donegal\/Dungloe\/Buncrana",
  35390 => "Athlone\/Ballinasloe\/Portumna\/Roscommon",
  35391 => "Galway\/Gort\/Loughrea",
  35393 => "Tuam",
  35394 => "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
  35395 => "Clifden",
  35396 => "Ballina",
  35397 => "Belmullet",
  35398 => "Westport",
  35399 => "Kilronan",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+353|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;