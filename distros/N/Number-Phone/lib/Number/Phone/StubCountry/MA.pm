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
package Number::Phone::StubCountry::MA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180619214156;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'format' => '$1-$2',
                  'leading_digits' => '
            5(?:
              2[015-7]|
              3[0-4]
            )|
            [67]
          ',
                  'pattern' => '([5-7]\\d{2})(\\d{6})'
                },
                {
                  'format' => '$1-$2',
                  'national_rule' => '0$1',
                  'leading_digits' => '
            5(?:
              2(?:
                [2-48]|
                9[0-7]
              )|
              3(?:
                [5-79]|
                8[0-7]
              )|
              924
            )|
            892
          ',
                  'pattern' => '([58]\\d{3})(\\d{5})'
                },
                {
                  'pattern' => '(5\\d{4})(\\d{4})',
                  'leading_digits' => '
            5(?:
              29|
              38
            )[89]
          ',
                  'format' => '$1-$2',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '([5]\\d{2})(\\d{2})(\\d{2})(\\d{2})',
                  'leading_digits' => '
            5(?:
              4[067]|
              5[03]
            )
          ',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3 $4'
                },
                {
                  'leading_digits' => '
            8(?:
              0|
              9[013-9]
            )
          ',
                  'format' => '$1-$2',
                  'national_rule' => '0$1',
                  'pattern' => '(8[09])(\\d{7})'
                }
              ];

my $validators = {
                'mobile' => '
          (?:
            6(?:
              [0-79]\\d|
              8[0-247-9]
            )|
            7(?:
              0[067]|
              6[1267]|
              7[017]
            )
          )\\d{6}
        ',
                'specialrate' => '(89\\d{7})',
                'pager' => '',
                'geographic' => '
          5(?:
            2(?:
              [015-79]\\d|
              2[02-9]|
              3[2-57]|
              4[2-8]|
              8[235-7]
            )\\d|
            3(?:
              [0-48]\\d|
              [57][2-9]|
              6[2-8]|
              9[3-9]
            )\\d|
            4[067]\\d{2}|
            5[03]\\d{2}
          )\\d{4}
        ',
                'personal_number' => '',
                'voip' => '5924[01]\\d{4}',
                'fixed_line' => '
          5(?:
            2(?:
              [015-79]\\d|
              2[02-9]|
              3[2-57]|
              4[2-8]|
              8[235-7]
            )\\d|
            3(?:
              [0-48]\\d|
              [57][2-9]|
              6[2-8]|
              9[3-9]
            )\\d|
            4[067]\\d{2}|
            5[03]\\d{2}
          )\\d{4}
        ',
                'toll_free' => '80\\d{7}'
              };
my %areanames = (
  212520 => "Casablanca",
  212521 => "Casablanca\/Central\ Morocco",
  2125220 => "Casablanca",
  2125222 => "Casablanca",
  2125223 => "Casablanca",
  2125224 => "Casablanca",
  2125225 => "Casablanca",
  2125226 => "Casablanca",
  2125227 => "Casablanca",
  2125228 => "Casablanca",
  2125229 => "Casablanca",
  2125232 => "Mohammedia",
  2125233 => "El\ Jedida\/Mohammedia",
  2125234 => "Settai",
  2125235 => "Oued\ Zem",
  2125237 => "Settat",
  2125242 => "El\ Kelaa\ des\ Sraghna",
  2125243 => "Marrakech",
  2125244 => "Marrakech",
  2125246 => "El\ Youssoufia\/Safi",
  2125247 => "Essaouira",
  2125248 => "Ouarzazate",
  212525 => "Southern\ Morocco",
  2125282 => "Agadir\/Ait\ Meloul\/Inezgane",
  2125283 => "Inezgane\/Taroudant",
  2125285 => "Oulad\ Teima\/Taroudant",
  2125286 => "Tiznit",
  2125287 => "Guelmim\/Tan\ Tan",
  2125288 => "Agadir\/Es\-Semara\/Tarfaya",
  2125289 => "Dakhla\/Laayoune",
  2125290 => "Casablanca",
  21252980 => "Marrakech\ area",
  21252990 => "Agadir\ area",
  212530 => "Rabat\/Kènitra",
  212531 => "Tangier\/Al\ Hoceima\/Larache\/Tètouan\/Chefchaouen",
  212532 => "Fès\/Errachidia\/Meknès\/Nador\/Oujda\/Taza",
  2125352 => "Taza",
  2125353 => "Midelt",
  2125354 => "Meknès",
  2125355 => "Meknès",
  2125356 => "Fès",
  2125357 => "Goulmima",
  2125358 => "Ifrane",
  2125359 => "Fès",
  2125362 => "Berkane",
  2125363 => "Nador",
  2125365 => "Oujda",
  2125366 => "Figuig\/Oujda",
  2125367 => "Bouarfa\/Oujda",
  2125368 => "Figuig",
  2125372 => "Rabat",
  2125373 => "Kénitra",
  2125374 => "Ouazzane",
  2125375 => "Khémisset",
  2125376 => "Rabat\/Témara",
  2125377 => "Rabat",
  2125378 => "Salé",
  2125379 => "Souk\ Larbaa",
  2125380 => "Rabat\ area",
  21253880 => "Tangier\ area",
  21253890 => "Fès\/Meknès\ areas",
  2125393 => "Tangier",
  2125394 => "Asilah",
  2125395 => "Larache",
  2125396 => "Fnideq\/Martil\/Mdiq",
  2125397 => "Tétouan",
  2125398 => "Al\ Hoceima\/Chefchaouen",
  2125399 => "Al\ Hoceima\/Larache\/Tangier",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+212|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;