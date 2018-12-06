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
package Number::Phone::StubCountry::KW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20181205223704;

my $formatters = [
                {
                  'pattern' => '(\\d{4})(\\d{3,4})',
                  'leading_digits' => '
            [169]|
            2(?:
              [235]|
              4[1-35-9]
            )|
            52
          ',
                  'format' => '$1 $2'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[25]',
                  'pattern' => '(\\d{3})(\\d{5})'
                }
              ];

my $validators = {
                'voip' => '',
                'mobile' => '
          (?:
            5(?:
              (?:
                [05]\\d|
                1[0-7]|
                6[56]
              )\\d|
              2(?:
                22|
                5[25]
              )
            )|
            6(?:
              (?:
                0[034679]|
                5[015-9]|
                6\\d
              )\\d|
              222|
              7(?:
                0[013-9]|
                [67]\\d
              )|
              9(?:
                [069]\\d|
                3[039]
              )
            )|
            9(?:
              (?:
                0[09]|
                22|
                4[01479]|
                55|
                6[0679]|
                8[057-9]|
                9\\d
              )\\d|
              11[01]|
              7(?:
                02|
                [1-9]\\d
              )
            )
          )\\d{4}
        ',
                'pager' => '',
                'fixed_line' => '
          2(?:
            [23]\\d\\d|
            4(?:
              [1-35-9]\\d|
              44
            )|
            5(?:
              0[034]|
              [2-46]\\d|
              5[1-3]|
              7[1-7]
            )
          )\\d{4}
        ',
                'personal_number' => '',
                'specialrate' => '',
                'geographic' => '
          2(?:
            [23]\\d\\d|
            4(?:
              [1-35-9]\\d|
              44
            )|
            5(?:
              0[034]|
              [2-46]\\d|
              5[1-3]|
              7[1-7]
            )
          )\\d{4}
        ',
                'toll_free' => '18\\d{5}'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+965|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;