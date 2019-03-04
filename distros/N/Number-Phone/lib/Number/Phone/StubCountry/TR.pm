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
package Number::Phone::StubCountry::TR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190303205540;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '444',
                  'pattern' => '(\\d{3})(\\d)(\\d{3})',
                  'intl_format' => 'NA'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})',
                  'leading_digits' => '
            512|
            8[0589]|
            90
          ',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1'
                },
                {
                  'leading_digits' => '
            5(?:
              [0-59]|
              6161
            )
          ',
                  'format' => '$1 $2 $3 $4',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{2})(\\d{2})',
                  'national_rule' => '0$1'
                },
                {
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{2})(\\d{2})',
                  'leading_digits' => '
            [24][1-8]|
            3[1-9]
          ',
                  'format' => '$1 $2 $3 $4'
                }
              ];

my $validators = {
                'pager' => '512\\d{7}',
                'geographic' => '
          (?:
            2(?:
              [13][26]|
              [28][2468]|
              [45][268]|
              [67][246]
            )|
            3(?:
              [13][28]|
              [24-6][2468]|
              [78][02468]|
              92
            )|
            4(?:
              [16][246]|
              [23578][2468]|
              4[26]
            )
          )\\d{7}
        ',
                'mobile' => '
          56161\\d{5}|
          5(?:
            0[15-7]|
            1[06]|
            24|
            [34]\\d|
            5[1-59]|
            9[46]
          )\\d{7}
        ',
                'voip' => '',
                'specialrate' => '(
          (?:
            8[89]8|
            900
          )\\d{7}
        )|(
          (?:
            444|
            850\\d{3}
          )\\d{4}
        )',
                'fixed_line' => '
          (?:
            2(?:
              [13][26]|
              [28][2468]|
              [45][268]|
              [67][246]
            )|
            3(?:
              [13][28]|
              [24-6][2468]|
              [78][02468]|
              92
            )|
            4(?:
              [16][246]|
              [23578][2468]|
              4[26]
            )
          )\\d{7}
        ',
                'personal_number' => '
          592(?:
            21[12]|
            461
          )\\d{4}
        ',
                'toll_free' => '800\\d{7}'
              };
my %areanames = (
  90212 => "Istanbul\ \(Europe\)",
  90216 => "Istanbul\ \(Anatolia\)",
  90222 => "Esksehir",
  90224 => "Bursa",
  90226 => "Yalova",
  90228 => "Bilecik",
  90232 => "Izmir",
  90236 => "Manisa",
  90242 => "Antalya",
  90246 => "Isparta",
  90248 => "Burdur",
  90252 => "Mugla",
  90256 => "Aydin",
  90258 => "Denizli",
  90262 => "Kocaeli",
  90264 => "Sakarya",
  90266 => "Balikesir",
  90272 => "Afyon",
  90274 => "Kutahya",
  90276 => "Usak",
  90282 => "Tekirdag",
  90284 => "Edirne",
  90286 => "Canakkale",
  90288 => "Kirklareli",
  90312 => "Ankara",
  90318 => "Kirikkale",
  90322 => "Adana",
  90324 => "Icel",
  90326 => "Hatay",
  90328 => "Osmaniye",
  90332 => "Konya",
  90338 => "Karaman",
  90342 => "Gaziantep",
  90344 => "K\.\ Maras",
  90346 => "Sivas",
  90348 => "Kilis",
  90352 => "Kayseri",
  90354 => "Yozgat",
  90356 => "Tokat",
  90358 => "Amasya",
  90362 => "Samsun",
  90364 => "Corum",
  90366 => "Kastamonu",
  90368 => "Sinop",
  90370 => "Karabuk",
  90372 => "Zongdulak",
  90374 => "Bolu",
  90376 => "Cankiri",
  90378 => "Bartin",
  90380 => "Duzce",
  90382 => "Aksaray",
  90384 => "Nevsehir",
  90386 => "Kirsehir",
  90388 => "Nigde",
  90412 => "Diyarbakir",
  90414 => "Sanliurfa",
  90416 => "Adiyaman",
  90422 => "Malatya",
  90424 => "Elazig",
  90426 => "Bingol",
  90428 => "Tuniceli",
  90432 => "Van",
  90434 => "Bitlis",
  90436 => "Mus",
  90438 => "Hakkari",
  90442 => "Erzurum",
  90446 => "Erzincan",
  90452 => "Ordu",
  90454 => "Giresun",
  90456 => "Gumushane",
  90458 => "Bayburt",
  90462 => "Trabzon",
  90464 => "Rize",
  90466 => "Artvin",
  90472 => "Agri",
  90474 => "Kars",
  90476 => "Igdir",
  90478 => "Ardahan",
  90482 => "Mardin",
  90484 => "Stirt",
  90486 => "Sirnak",
  90488 => "Batman",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+90|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;