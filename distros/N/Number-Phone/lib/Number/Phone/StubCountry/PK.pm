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
package Number::Phone::StubCountry::PK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20181205223704;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[89]0',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{2})'
                },
                {
                  'leading_digits' => '1',
                  'format' => '$1 $2',
                  'pattern' => '(\\d{4})(\\d{5})'
                },
                {
                  'leading_digits' => '
            (?:
              2[125]|
              4[0-246-9]|
              5[1-35-7]|
              6[1-8]|
              7[14]|
              8[16]|
              91
            )[2-9]
          ',
                  'format' => '$1 $2',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{7,8})'
                },
                {
                  'pattern' => '(\\d{3})(\\d{6,7})',
                  'national_rule' => '(0$1)',
                  'format' => '$1 $2',
                  'leading_digits' => '
            (?:
              2(?:
                3[2358]|
                4[2-4]|
                9[2-8]
              )|
              45[3479]|
              54[2-467]|
              60[468]|
              72[236]|
              8(?:
                2[2-689]|
                3[23578]|
                4[3478]|
                5[2356]
              )
            )[2-9]|
            9(?:
              2(?:
                2[2-9]|
                [3-8]
              )|
              (?:
                3[27-9]|
                4[2-6]|
                6[3569]
              )[2-9]|
              9(?:
                [25-7][2-9]|
                8
              )
            )
          '
                },
                {
                  'pattern' => '(\\d{5})(\\d{5})',
                  'national_rule' => '(0$1)',
                  'format' => '$1 $2',
                  'leading_digits' => '58'
                },
                {
                  'pattern' => '(\\d{3})(\\d{7})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2',
                  'leading_digits' => '3'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})(\\d{3})',
                  'national_rule' => '(0$1)',
                  'leading_digits' => '
            2[125]|
            4[0-246-9]|
            5[1-35-7]|
            6[1-8]|
            7[14]|
            8[16]|
            91
          ',
                  'format' => '$1 $2 $3 $4'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})(\\d{3})',
                  'national_rule' => '(0$1)',
                  'leading_digits' => '[24-9]',
                  'format' => '$1 $2 $3 $4'
                }
              ];

my $validators = {
                'mobile' => '
          3(?:
            [014]\\d|
            2[0-5]|
            3[0-7]|
            55|
            64
          )\\d{7}
        ',
                'pager' => '',
                'voip' => '',
                'geographic' => '
          2(?:
            (?:
              1[2-9]\\d|
              [25][2-9]
            )\\d{6}|
            (?:
              3[2358]|
              4[2-4]|
              9[2-8]
            )[2-9]\\d{5,6}
          )|
          4(?:
            (?:
              [0146-9][2-9]|
              2[2-9]\\d
            )\\d{6}|
            5[3479][2-9]\\d{5,6}
          )|
          5(?:
            (?:
              [1-35-7][2-9]|
              8[126]\\d
            )\\d{6}|
            4[2-467][2-9]\\d{5,6}
          )|
          6(?:
            0[468][2-9]\\d{5,6}|
            [1-8][2-9]\\d{6}
          )|
          7(?:
            [14][2-9]\\d{6}|
            2[236][2-9]\\d{5,6}
          )|
          8(?:
            [16][2-9]\\d{6}|
            (?:
              2[2-689]|
              3[23578]|
              4[3478]|
              5[2356]
            )[2-9]\\d{5,6}
          )|
          9(?:
            1[2-9]\\d{6}|
            (?:
              2[2-8]|
              3[27-9]|
              4[2-6]|
              6[3569]|
              9[25-8]
            )[2-9]\\d{5,6}
          )
        ',
                'toll_free' => '800\\d{5}',
                'fixed_line' => '
          2(?:
            (?:
              1[2-9]\\d|
              [25][2-9]
            )\\d{6}|
            (?:
              3[2358]|
              4[2-4]|
              9[2-8]
            )[2-9]\\d{5,6}
          )|
          4(?:
            (?:
              [0146-9][2-9]|
              2[2-9]\\d
            )\\d{6}|
            5[3479][2-9]\\d{5,6}
          )|
          5(?:
            (?:
              [1-35-7][2-9]|
              8[126]\\d
            )\\d{6}|
            4[2-467][2-9]\\d{5,6}
          )|
          6(?:
            0[468][2-9]\\d{5,6}|
            [1-8][2-9]\\d{6}
          )|
          7(?:
            [14][2-9]\\d{6}|
            2[236][2-9]\\d{5,6}
          )|
          8(?:
            [16][2-9]\\d{6}|
            (?:
              2[2-689]|
              3[23578]|
              4[3478]|
              5[2356]
            )[2-9]\\d{5,6}
          )|
          9(?:
            1[2-9]\\d{6}|
            (?:
              2[2-8]|
              3[27-9]|
              4[2-6]|
              6[3569]|
              9[25-8]
            )[2-9]\\d{5,6}
          )
        ',
                'personal_number' => '122\\d{6}',
                'specialrate' => '(900\\d{5})|(
          (?:
            2(?:
              [125]|
              3[2358]|
              4[2-4]|
              9[2-8]
            )|
            4(?:
              [0-246-9]|
              5[3479]
            )|
            5(?:
              [1-35-7]|
              4[2-467]
            )|
            6(?:
              0[468]|
              [1-8]
            )|
            7(?:
              [14]|
              2[236]
            )|
            8(?:
              [16]|
              2[2-689]|
              3[23578]|
              4[3478]|
              5[2356]
            )|
            9(?:
              1|
              22|
              3[27-9]|
              4[2-6]|
              6[3569]|
              9[2-7]
            )
          )111\\d{6}
        )'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+92|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;