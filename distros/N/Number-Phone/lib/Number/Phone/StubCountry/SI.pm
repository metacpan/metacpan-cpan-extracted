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
package Number::Phone::StubCountry::SI;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20181205223704;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{3,6})',
                  'format' => '$1 $2',
                  'leading_digits' => '
            8[09]|
            9
          ',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '(\\d)(\\d{3})(\\d{2})(\\d{2})',
                  'national_rule' => '(0$1)',
                  'leading_digits' => '
            [12]|
            [34][24-8]|
            5[2-8]|
            7[3-8]
          ',
                  'format' => '$1 $2 $3 $4'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [3467]|
            51
          ',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[58]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{5})'
                }
              ];

my $validators = {
                'voip' => '
          (?:
            59|
            8[1-3]
          )\\d{6}
        ',
                'pager' => '',
                'mobile' => '
          (?:
            (?:
              [37][01]|
              4[0139]|
              51
            )\\d|
            6(?:
              [48]\\d|
              5[15-7]|
              9[69]
            )
          )\\d{5}
        ',
                'specialrate' => '(
          89[1-3]\\d{2,5}|
          90\\d{4,6}
        )',
                'personal_number' => '',
                'fixed_line' => '
          (?:
            1\\d|
            [25][2-8]|
            [34][24-8]|
            7[3-8]
          )\\d{6}
        ',
                'toll_free' => '80\\d{4,6}',
                'geographic' => '
          (?:
            1\\d|
            [25][2-8]|
            [34][24-8]|
            7[3-8]
          )\\d{6}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+386|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;