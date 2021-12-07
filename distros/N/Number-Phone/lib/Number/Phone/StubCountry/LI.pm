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
our $VERSION = 1.20211206222446;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [2379]|
            8(?:
              0(?:
                02|
                9
              )|
              7
            )
          ',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '69',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '6',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              01|
              1[27]|
              2[02]|
              3\\d|
              6[02-578]|
              96
            )|
            3(?:
              [24]0|
              33|
              7[0135-7]|
              8[048]|
              9[0269]
            )
          )\\d{4}
        ',
                'geographic' => '
          (?:
            2(?:
              01|
              1[27]|
              2[02]|
              3\\d|
              6[02-578]|
              96
            )|
            3(?:
              [24]0|
              33|
              7[0135-7]|
              8[048]|
              9[0269]
            )
          )\\d{4}
        ',
                'mobile' => '
          (?:
            6(?:
              4(?:
                5[4-9]|
                [6-9]\\d
              )|
              5[0-4]\\d|
              6(?:
                [0245]\\d|
                [17]0|
                3[7-9]
              )
            )\\d|
            7(?:
              [37-9]\\d|
              42|
              56
            )
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          90(?:
            02[258]|
            1(?:
              23|
              3[14]
            )|
            66[136]
          )\\d\\d
        )|(
          870(?:
            28|
            87
          )\\d\\d
        )',
                'toll_free' => '
          8002[28]\\d\\d|
          80(?:
            05\\d|
            9
          )\\d{4}
        ',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+423|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0|(1001))//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;