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
package Number::Phone::StubCountry::PH;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20181205223704;

my $formatters = [
                {
                  'pattern' => '(\\d)(\\d{5})',
                  'leading_digits' => '2',
                  'format' => '$1 $2',
                  'national_rule' => '(0$1)'
                },
                {
                  'pattern' => '(\\d)(\\d{3})(\\d{4})',
                  'national_rule' => '(0$1)',
                  'leading_digits' => '2',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '(\\d{4})(\\d{4,6})',
                  'national_rule' => '(0$1)',
                  'format' => '$1 $2',
                  'leading_digits' => '
            3(?:
              230|
              397|
              461
            )|
            4(?:
              2(?:
                35|
                [46]4|
                51
              )|
              396|
              4(?:
                22|
                63
              )|
              59[347]|
              76[15]
            )|
            5(?:
              221|
              446
            )|
            642[23]|
            8(?:
              622|
              8(?:
                [24]2|
                5[13]
              )
            )
          '
                },
                {
                  'national_rule' => '(0$1)',
                  'leading_digits' => '
            3(?:
              [23568]|
              4(?:
                [0-57-9]|
                6[02-8]
              )
            )|
            4(?:
              2(?:
                [0-689]|
                7[0-8]
              )|
              [3-8]|
              9(?:
                [0-246-9]|
                3[1-9]|
                5[0-57-9]
              )
            )|
            [5-7]|
            8(?:
              [2-7]|
              8(?:
                [0-24-9]|
                3[0-35-9]
              )
            )
          ',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(\\d{5})(\\d{4})',
                  'national_rule' => '(0$1)',
                  'leading_digits' => '
            [34]|
            88
          ',
                  'format' => '$1 $2'
                },
                {
                  'national_rule' => '0$1',
                  'leading_digits' => '[89]',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(\\d{4})(\\d{3})(\\d{4})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1'
                },
                {
                  'pattern' => '(\\d{4})(\\d{1,2})(\\d{3})(\\d{4})',
                  'leading_digits' => '1',
                  'format' => '$1 $2 $3 $4'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2\\d(?:
              \\d{2}
            )?|
            (?:
              3[2-68]|
              4[2-9]|
              5[2-6]|
              6[2-58]|
              7[24578]
            )\\d{3}|
            88(?:
              22\\d\\d|
              42
            )
          )\\d{4}|
          8[2-8]\\d{7}
        ',
                'personal_number' => '',
                'specialrate' => '',
                'geographic' => '
          (?:
            2\\d(?:
              \\d{2}
            )?|
            (?:
              3[2-68]|
              4[2-9]|
              5[2-6]|
              6[2-58]|
              7[24578]
            )\\d{3}|
            88(?:
              22\\d\\d|
              42
            )
          )\\d{4}|
          8[2-8]\\d{7}
        ',
                'toll_free' => '1800\\d{7,9}',
                'voip' => '',
                'mobile' => '
          (?:
            81[37]|
            9(?:
              0[5-9]|
              1[024-9]|
              2[0-35-9]|
              3[02-9]|
              4[235-9]|
              5[056]|
              6[5-7]|
              7[3-79]|
              89|
              9[4-9]
            )
          )\\d{7}
        ',
                'pager' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+63|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;