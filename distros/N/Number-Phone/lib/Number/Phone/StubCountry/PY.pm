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
package Number::Phone::StubCountry::PY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170702164948;

my $formatters = [
                {
                  'leading_digits' => '
            (?:
              [26]1|
              3[289]|
              4[124678]|
              7[123]|
              8[1236]
            )
          ',
                  'pattern' => '(\\d{2})(\\d{5})'
                },
                {
                  'leading_digits' => '
            (?:
              [26]1|
              3[289]|
              4[124678]|
              7[123]|
              8[1236]
            )
          ',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3,6})',
                  'leading_digits' => '[2-9]0'
                },
                {
                  'pattern' => '(\\d{3})(\\d{6})',
                  'leading_digits' => '9[1-9]'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})',
                  'leading_digits' => '8700'
                },
                {
                  'pattern' => '(\\d{3})(\\d{4,5})',
                  'leading_digits' => '[2-8][1-9]'
                },
                {
                  'leading_digits' => '[2-8][1-9]',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'voip' => '8700[0-4]\\d{4}',
                'toll_free' => '',
                'pager' => '',
                'mobile' => '
          9(?:
            6[12]|
            [78][1-6]|
            9[1-5]
          )\\d{6}
        ',
                'fixed_line' => '
          (?:
            [26]1|
            3[289]|
            4[124678]|
            7[123]|
            8[1236]
          )\\d{5,7}|
          (?:
            2(?:
              2[4568]|
              7[15]|
              9[1-5]
            )|
            3(?:
              18|
              3[167]|
              4[2357]|
              51
            )|
            4(?:
              18|
              2[45]|
              3[12]|
              5[13]|
              64|
              71|
              9[1-47]
            )|
            5(?:
              [1-4]\\d|
              5[0234]
            )|
            6(?:
              3[1-3]|
              44|
              7[1-4678]
            )|
            7(?:
              17|
              4[0-4]|
              6[1-578]|
              75|
              8[0-8]
            )|
            858
          )\\d{5,6}
        ',
                'geographic' => '
          (?:
            [26]1|
            3[289]|
            4[124678]|
            7[123]|
            8[1236]
          )\\d{5,7}|
          (?:
            2(?:
              2[4568]|
              7[15]|
              9[1-5]
            )|
            3(?:
              18|
              3[167]|
              4[2357]|
              51
            )|
            4(?:
              18|
              2[45]|
              3[12]|
              5[13]|
              64|
              71|
              9[1-47]
            )|
            5(?:
              [1-4]\\d|
              5[0234]
            )|
            6(?:
              3[1-3]|
              44|
              7[1-4678]
            )|
            7(?:
              17|
              4[0-4]|
              6[1-578]|
              75|
              8[0-8]
            )|
            858
          )\\d{5,6}
        ',
                'specialrate' => '([2-9]0\\d{4,7})',
                'personal_number' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+595|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;