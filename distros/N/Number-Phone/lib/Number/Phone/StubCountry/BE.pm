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
package Number::Phone::StubCountry::BE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190611222638;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})',
                  'leading_digits' => '
            (?:
              80|
              9
            )0
          '
                },
                {
                  'leading_digits' => '
            [239]|
            4[23]
          ',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3 $4',
                  'pattern' => '(\\d)(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'leading_digits' => '[15-8]',
                  'format' => '$1 $2 $3 $4',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3 $4',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})',
                  'leading_digits' => '4'
                }
              ];

my $validators = {
                'pager' => '',
                'personal_number' => '',
                'toll_free' => '800[1-9]\\d{4}',
                'mobile' => '
          4(?:
            5[56]|
            6[0135-8]|
            [79]\\d|
            8[3-9]
          )\\d{6}
        ',
                'specialrate' => '(7879\\d{4})|(
          (?:
            70(?:
              2[0-57]|
              3[0457]|
              44|
              69|
              7[0579]
            )|
            90(?:
              0[0-35-8]|
              1[36]|
              2[0-3568]|
              3[0135689]|
              4[2-68]|
              5[1-68]|
              6[0-378]|
              7[23568]|
              9[34679]
            )
          )\\d{4}
        )|(
          78(?:
            0[57]|
            1[0458]|
            2[25]|
            3[5-8]|
            48|
            [56]0|
            7[078]
          )\\d{4}
        )',
                'geographic' => '
          80[2-8]\\d{5}|
          (?:
            1[0-69]|
            [23][2-8]|
            4[23]|
            5\\d|
            6[013-57-9]|
            71|
            8[1-79]|
            9[2-4]
          )\\d{6}
        ',
                'voip' => '',
                'fixed_line' => '
          80[2-8]\\d{5}|
          (?:
            1[0-69]|
            [23][2-8]|
            4[23]|
            5\\d|
            6[013-57-9]|
            71|
            8[1-79]|
            9[2-4]
          )\\d{6}
        '
              };
my %areanames = (
  3210 => "Wavre",
  3211 => "Hasselt",
  3212 => "Tongeren",
  3213 => "Diest",
  3214 => "Herentals",
  3215 => "Mechelen",
  3216 => "Leuven",
  3219 => "Waremme",
  322 => "Brussels",
  323 => "Antwerp",
  3242 => "Liège",
  3243 => "Liège",
  3250 => "Bruges",
  3251 => "Roeselare",
  3252 => "Dendermonde",
  3253 => "Aalst",
  3254 => "Ninove",
  3255 => "Ronse",
  3256 => "Kortrijk",
  3257 => "Ypres",
  3258 => "Veurne",
  3259 => "Ostend",
  3260 => "Chimay",
  3261 => "Libramont\-Chevigny",
  3263 => "Arlon",
  3264 => "La\ Louvière",
  3265 => "Mons",
  3267 => "Nivelles",
  3268 => "Ath",
  3269 => "Tournai",
  3271 => "Charleroi",
  3280 => "Stavelot",
  3281 => "Namur",
  3282 => "Dinant",
  3283 => "Ciney",
  3284 => "Marche\-en\-Famenne",
  3285 => "Huy",
  3286 => "Durbuy",
  3287 => "Verviers",
  3289 => "Genk",
  329 => "Ghent",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+32|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;