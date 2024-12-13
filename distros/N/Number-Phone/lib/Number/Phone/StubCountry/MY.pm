# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::MY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20241212130806;

my $formatters = [
                {
                  'format' => '$1-$2 $3',
                  'leading_digits' => '[4-79]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1-$2 $3',
                  'leading_digits' => '
            1(?:
              [02469]|
              [37][1-9]|
              53|
              8(?:
                [1-46-9]|
                5[7-9]
              )
            )|
            8
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1-$2 $3',
                  'leading_digits' => '3',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3-$4',
                  'leading_digits' => '
            1(?:
              [367]|
              80
            )
          ',
                  'pattern' => '(\\d)(\\d{3})(\\d{2})(\\d{4})'
                },
                {
                  'format' => '$1-$2 $3',
                  'leading_digits' => '15',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1-$2 $3',
                  'leading_digits' => '1',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          4270\\d{4}|
          (?:
            3(?:
              2[0-36-9]|
              3[0-368]|
              4[0-278]|
              5[0-24-8]|
              6[0-467]|
              7[1246-9]|
              8\\d|
              9[0-57]
            )\\d|
            4(?:
              2[0-689]|
              [3-79]\\d|
              8[1-35689]
            )|
            5(?:
              2[0-589]|
              [3468]\\d|
              5[0-489]|
              7[1-9]|
              9[23]
            )|
            6(?:
              2[2-9]|
              3[1357-9]|
              [46]\\d|
              5[0-6]|
              7[0-35-9]|
              85|
              9[015-8]
            )|
            7(?:
              [2579]\\d|
              3[03-68]|
              4[0-8]|
              6[5-9]|
              8[0-35-9]
            )|
            8(?:
              [24][2-8]|
              3[2-5]|
              5[2-7]|
              6[2-589]|
              7[2-578]|
              [89][2-9]
            )|
            9(?:
              0[57]|
              13|
              [25-7]\\d|
              [3489][0-8]
            )
          )\\d{5}
        ',
                'geographic' => '
          4270\\d{4}|
          (?:
            3(?:
              2[0-36-9]|
              3[0-368]|
              4[0-278]|
              5[0-24-8]|
              6[0-467]|
              7[1246-9]|
              8\\d|
              9[0-57]
            )\\d|
            4(?:
              2[0-689]|
              [3-79]\\d|
              8[1-35689]
            )|
            5(?:
              2[0-589]|
              [3468]\\d|
              5[0-489]|
              7[1-9]|
              9[23]
            )|
            6(?:
              2[2-9]|
              3[1357-9]|
              [46]\\d|
              5[0-6]|
              7[0-35-9]|
              85|
              9[015-8]
            )|
            7(?:
              [2579]\\d|
              3[03-68]|
              4[0-8]|
              6[5-9]|
              8[0-35-9]
            )|
            8(?:
              [24][2-8]|
              3[2-5]|
              5[2-7]|
              6[2-589]|
              7[2-578]|
              [89][2-9]
            )|
            9(?:
              0[57]|
              13|
              [25-7]\\d|
              [3489][0-8]
            )
          )\\d{5}
        ',
                'mobile' => '
          1(?:
            1888[689]|
            4400|
            8(?:
              47|
              8[27]
            )[0-4]
          )\\d{4}|
          1(?:
            0(?:
              [23568]\\d|
              4[0-6]|
              7[016-9]|
              9[0-8]
            )|
            1(?:
              [1-5]\\d\\d|
              6(?:
                0[5-9]|
                [1-9]\\d
              )|
              7(?:
                [0-4]\\d|
                5[0-7]
              )
            )|
            (?:
              [269]\\d|
              [37][1-9]|
              4[235-9]
            )\\d|
            5(?:
              31|
              9\\d\\d
            )|
            8(?:
              1[23]|
              [236]\\d|
              4[06]|
              5(?:
                46|
                [7-9]
              )|
              7[016-9]|
              8[01]|
              9[0-8]
            )
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(1600\\d{6})',
                'toll_free' => '1[378]00\\d{6}',
                'voip' => '
          15(?:
            4(?:
              6[0-4]\\d|
              8(?:
                0[125]|
                [17]\\d|
                21|
                3[01]|
                4[01589]|
                5[014]|
                6[02]
              )
            )|
            6(?:
              32[0-6]|
              78\\d
            )
          )\\d{4}
        '
              };
my $timezones = {
               '' => [
                       'Asia/Kuching'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+60|\D)//g;
      my $self = bless({ country_code => '60', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '60', number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;