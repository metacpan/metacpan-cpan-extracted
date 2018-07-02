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
package Number::Phone::StubCountry::LI;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180619214156;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[237-9]'
                },
                {
                  'leading_digits' => '6[56]',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '697',
                  'pattern' => '(69)(7\\d{2})(\\d{4})'
                }
              ];

my $validators = {
                'specialrate' => '(
          90(?:
            02[258]|
            1(?:
              23|
              3[14]
            )|
            66[136]
          )\\d{2}
        )|(
          870(?:
            28|
            87
          )\\d{2}
        )',
                'mobile' => '
          6(?:
            5(?:
              09|
              1\\d|
              20
            )|
            6(?:
              0[0-6]|
              10|
              2[06-9]|
              39
            )
          )\\d{5}|
          7(?:
            [37-9]\\d|
            42|
            56
          )\\d{4}
        ',
                'fixed_line' => '
          (?:
            2(?:
              01|
              1[27]|
              3\\d|
              6[02-578]|
              96
            )|
            3(?:
              7[0135-7]|
              8[048]|
              9[0269]
            )
          )\\d{4}
        ',
                'toll_free' => '
          80(?:
            02[28]|
            9\\d{2}
          )\\d{2}
        ',
                'personal_number' => '',
                'voip' => '',
                'pager' => '',
                'geographic' => '
          (?:
            2(?:
              01|
              1[27]|
              3\\d|
              6[02-578]|
              96
            )|
            3(?:
              7[0135-7]|
              8[048]|
              9[0269]
            )
          )\\d{4}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+423|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0|10(?:01|20|66))//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;