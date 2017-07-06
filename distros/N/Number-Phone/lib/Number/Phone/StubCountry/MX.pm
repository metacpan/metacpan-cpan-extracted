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
package Number::Phone::StubCountry::MX;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170702164948;

my $formatters = [
                {
                  'pattern' => '([358]\\d)(\\d{4})(\\d{4})',
                  'leading_digits' => '
            33|
            55|
            81
          '
                },
                {
                  'leading_digits' => '
            [2467]|
            3[0-2457-9]|
            5[089]|
            8[02-9]|
            9[0-35-9]
          ',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(1)([358]\\d)(\\d{4})(\\d{4})',
                  'leading_digits' => '
            1(?:
              33|
              55|
              81
            )
          '
                },
                {
                  'pattern' => '(1)(\\d{3})(\\d{3})(\\d{4})',
                  'leading_digits' => '
            1(?:
              [2467]|
              3[0-2457-9]|
              5[089]|
              8[2-9]|
              9[1-35-9]
            )
          '
                }
              ];

my $validators = {
                'specialrate' => '(300\\d{7})|(900\\d{7})',
                'geographic' => '
          (?:
            33|
            55|
            81
          )\\d{8}|
          (?:
            2(?:
              0[01]|
              2[2-9]|
              3[1-35-8]|
              4[13-9]|
              7[1-689]|
              8[1-578]|
              9[467]
            )|
            3(?:
              1[1-79]|
              [2458][1-9]|
              7[1-8]|
              9[1-5]
            )|
            4(?:
              1[1-57-9]|
              [24-6][1-9]|
              [37][1-8]|
              8[1-35-9]|
              9[2-689]
            )|
            5(?:
              88|
              9[1-79]
            )|
            6(?:
              1[2-68]|
              [234][1-9]|
              5[1-3689]|
              6[12457-9]|
              7[1-7]|
              8[67]|
              9[4-8]
            )|
            7(?:
              [13467][1-9]|
              2[1-8]|
              5[13-9]|
              8[1-69]|
              9[17]
            )|
            8(?:
              2[13-689]|
              3[1-6]|
              4[124-6]|
              6[1246-9]|
              7[1-378]|
              9[12479]
            )|
            9(?:
              1[346-9]|
              2[1-4]|
              3[2-46-8]|
              5[1348]|
              [69][1-9]|
              7[12]|
              8[1-8]
            )
          )\\d{7}
        ',
                'personal_number' => '500\\d{7}',
                'voip' => '',
                'toll_free' => '
          8(?:
            00|
            88
          )\\d{7}
        ',
                'pager' => '',
                'mobile' => '
          1(?:
            (?:
              33|
              55|
              81
            )\\d{8}|
            (?:
              2(?:
                2[1-9]|
                3[1-35-8]|
                4[13-9]|
                7[1-689]|
                8[1-578]|
                9[467]
              )|
              3(?:
                1[1-79]|
                [2458][1-9]|
                7[1-8]|
                9[1-5]
              )|
              4(?:
                1[1-57-9]|
                [24-6][1-9]|
                [37][1-8]|
                8[1-35-9]|
                9[2-689]
              )|
              5(?:
                88|
                9[1-79]
              )|
              6(?:
                1[2-68]|
                [2-4][1-9]|
                5[1-3689]|
                6[12457-9]|
                7[1-7]|
                8[67]|
                9[4-8]
              )|
              7(?:
                [13467][1-9]|
                2[1-8]|
                5[13-9]|
                8[1-69]|
                9[17]
              )|
              8(?:
                2[13-689]|
                3[1-6]|
                4[124-6]|
                6[1246-9]|
                7[1-378]|
                9[12479]
              )|
              9(?:
                1[346-9]|
                2[1-4]|
                3[2-46-8]|
                5[1348]|
                [69][1-9]|
                7[12]|
                8[1-8]
              )
            )\\d{7}
          )
        ',
                'fixed_line' => '
          (?:
            33|
            55|
            81
          )\\d{8}|
          (?:
            2(?:
              0[01]|
              2[2-9]|
              3[1-35-8]|
              4[13-9]|
              7[1-689]|
              8[1-578]|
              9[467]
            )|
            3(?:
              1[1-79]|
              [2458][1-9]|
              7[1-8]|
              9[1-5]
            )|
            4(?:
              1[1-57-9]|
              [24-6][1-9]|
              [37][1-8]|
              8[1-35-9]|
              9[2-689]
            )|
            5(?:
              88|
              9[1-79]
            )|
            6(?:
              1[2-68]|
              [234][1-9]|
              5[1-3689]|
              6[12457-9]|
              7[1-7]|
              8[67]|
              9[4-8]
            )|
            7(?:
              [13467][1-9]|
              2[1-8]|
              5[13-9]|
              8[1-69]|
              9[17]
            )|
            8(?:
              2[13-689]|
              3[1-6]|
              4[124-6]|
              6[1246-9]|
              7[1-378]|
              9[12479]
            )|
            9(?:
              1[346-9]|
              2[1-4]|
              3[2-46-8]|
              5[1348]|
              [69][1-9]|
              7[12]|
              8[1-8]
            )
          )\\d{7}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+52|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^01)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;