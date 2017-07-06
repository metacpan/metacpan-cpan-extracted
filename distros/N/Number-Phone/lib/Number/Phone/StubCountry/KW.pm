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
our $VERSION = 1.20170702164948;

my $formatters = [
                {
                  'pattern' => '(\\d{4})(\\d{3,4})',
                  'leading_digits' => '
            [16]|
            2(?:
              [0-35-9]|
              4[0-35-9]
            )|
            9[024-9]|
            52[25]
          '
                },
                {
                  'pattern' => '(\\d{3})(\\d{5})',
                  'leading_digits' => '
            244|
            5(?:
              [015]|
              6[56]
            )
          '
                }
              ];

my $validators = {
                'personal_number' => '',
                'geographic' => '
          (?:
            18\\d|
            2(?:
              [23]\\d{2}|
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
            )
          )\\d{4}
        ',
                'specialrate' => '',
                'mobile' => '
          (?:
            5(?:
              [05]\\d{2}|
              1[0-7]\\d|
              2(?:
                22|
                5[25]
              )|
              6[56]\\d
            )|
            6(?:
              0[034679]\\d|
              222|
              5[015-9]\\d|
              6\\d{2}|
              7[067]\\d|
              9[0369]\\d
            )|
            9(?:
              0[09]\\d|
              22\\d|
              4[01479]\\d|
              55\\d|
              6[0679]\\d|
              [79]\\d{2}|
              8[057-9]\\d
            )
          )\\d{4}
        ',
                'fixed_line' => '
          (?:
            18\\d|
            2(?:
              [23]\\d{2}|
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
            )
          )\\d{4}
        ',
                'toll_free' => '',
                'pager' => '',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+965|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  return $self->is_valid() ? $self : undef;
}
1;