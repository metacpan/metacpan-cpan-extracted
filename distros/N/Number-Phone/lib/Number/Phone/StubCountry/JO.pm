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
package Number::Phone::StubCountry::JO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190303205539;

my $formatters = [
                {
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})',
                  'leading_digits' => '
            [2356]|
            87
          ',
                  'format' => '$1 $2 $3'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2',
                  'leading_digits' => '[89]',
                  'pattern' => '(\\d{3})(\\d{5,6})'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2',
                  'leading_digits' => '70',
                  'pattern' => '(\\d{2})(\\d{7})'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '7',
                  'pattern' => '(\\d)(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'personal_number' => '70\\d{7}',
                'toll_free' => '80\\d{6}',
                'fixed_line' => '
          (?:
            2(?:
              6(?:
                2[0-35-9]|
                3[0-578]|
                4[24-7]|
                5[0-24-8]|
                [6-8][023]|
                9[0-3]
              )|
              7(?:
                0[1-79]|
                10|
                2[014-7]|
                3[0-689]|
                4[019]|
                5[0-3578]
              )
            )|
            32(?:
              0[1-69]|
              1[1-35-7]|
              2[024-7]|
              3\\d|
              4[0-3]|
              [57][023]|
              6[03]
            )|
            53(?:
              0[0-3]|
              [13][023]|
              2[0-59]|
              49|
              5[0-35-9]|
              6[15]|
              7[45]|
              8[1-6]|
              9[0-36-9]
            )|
            6(?:
              2(?:
                [05]0|
                22
              )|
              3(?:
                00|
                33
              )|
              4(?:
                0[0-25]|
                1[2-7]|
                2[0569]|
                [38][07-9]|
                4[025689]|
                6[0-589]|
                7\\d|
                9[0-2]
              )|
              5(?:
                [01][056]|
                2[034]|
                3[0-57-9]|
                4[178]|
                5[0-69]|
                6[0-35-9]|
                7[1-379]|
                8[0-68]|
                9[0239]
              )
            )|
            87(?:
              [029]0|
              7[08]
            )
          )\\d{4}
        ',
                'voip' => '',
                'specialrate' => '(85\\d{6})|(900\\d{5})|(
          8(?:
            10|
            8\\d
          )\\d{5}
        )',
                'mobile' => '
          7(?:
            55[0-49]|
            (?:
              7[025-9]|
              [89][0-25-9]
            )\\d
          )\\d{5}
        ',
                'geographic' => '
          (?:
            2(?:
              6(?:
                2[0-35-9]|
                3[0-578]|
                4[24-7]|
                5[0-24-8]|
                [6-8][023]|
                9[0-3]
              )|
              7(?:
                0[1-79]|
                10|
                2[014-7]|
                3[0-689]|
                4[019]|
                5[0-3578]
              )
            )|
            32(?:
              0[1-69]|
              1[1-35-7]|
              2[024-7]|
              3\\d|
              4[0-3]|
              [57][023]|
              6[03]
            )|
            53(?:
              0[0-3]|
              [13][023]|
              2[0-59]|
              49|
              5[0-35-9]|
              6[15]|
              7[45]|
              8[1-6]|
              9[0-36-9]
            )|
            6(?:
              2(?:
                [05]0|
                22
              )|
              3(?:
                00|
                33
              )|
              4(?:
                0[0-25]|
                1[2-7]|
                2[0569]|
                [38][07-9]|
                4[025689]|
                6[0-589]|
                7\\d|
                9[0-2]
              )|
              5(?:
                [01][056]|
                2[034]|
                3[0-57-9]|
                4[178]|
                5[0-69]|
                6[0-35-9]|
                7[1-379]|
                8[0-68]|
                9[0239]
              )
            )|
            87(?:
              [029]0|
              7[08]
            )
          )\\d{4}
        ',
                'pager' => '
          74(?:
            66|
            77
          )\\d{5}
        '
              };
my %areanames = (
  962266 => "Mafraq",
  962267 => "Jarash",
  962268 => "Ajloun",
  962269 => "Irbid",
  9623222 => "Tafileh",
  962324 => "Aqaba",
  962325 => "Maan",
  9623260 => "Tafileh",
  962327 => "Karak",
  962530 => "Zarqa",
  962531 => "Madaba",
  962533 => "Balqa",
  9626 => "Amman",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+962|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;