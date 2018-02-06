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
package Number::Phone::StubCountry::HK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180203200234;

my $formatters = [
                {
                  'leading_digits' => '
            [2-7]|
            [89](?:
              0[1-9]|
              [1-9]
            )
          ',
                  'pattern' => '(\\d{4})(\\d{4})',
                  'format' => '$1 $2'
                },
                {
                  'pattern' => '(800)(\\d{3})(\\d{3})',
                  'leading_digits' => '800',
                  'format' => '$1 $2 $3'
                },
                {
                  'leading_digits' => '900',
                  'pattern' => '(900)(\\d{2})(\\d{3})(\\d{3})',
                  'format' => '$1 $2 $3 $4'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '900',
                  'pattern' => '(900)(\\d{2,5})'
                }
              ];

my $validators = {
                'mobile' => '
          (?:
            46(?:
              0[0-6]|
              4[07-9]
            )|
            5(?:
              [1-59][0-46-9]\\d|
              6[0-4689]\\d|
              7(?:
                [0-2469]\\d|
                30
              )
            )|
            6(?:
              0[1-9]\\d|
              [1459]\\d{2}|
              2(?:
                [0-57-9]\\d|
                6[01]
              )|
              [368][0-57-9]\\d|
              7[0-79]\\d
            )|
            9(?:
              0[1-9]\\d|
              1[02-9]\\d|
              2(?:
                [0-8]\\d|
                9[03-9]
              )|
              [358][0-8]\\d|
              [467]\\d{2}
            )
          )\\d{4}
        ',
                'personal_number' => '
          8(?:
            1[0-4679]|
            2[0-367]|
            3[02-47]
          )\\d{5}
        ',
                'fixed_line' => '
          (?:
            2(?:
              [13-8]\\d|
              2[013-9]|
              9[0-24-9]
            )|
            3(?:
              [1569][0-24-9]|
              4[0-246-9]|
              7[0-24-69]|
              89
            )|
            58[01]
          )\\d{5}
        ',
                'specialrate' => '(
          900(?:
            [0-24-9]\\d{7}|
            3\\d{1,4}
          )
        )|(
          30(?:
            0[1-9]|
            [15-7]\\d|
            2[047]|
            89
          )\\d{4}
        )',
                'toll_free' => '800\\d{6}',
                'geographic' => '
          (?:
            2(?:
              [13-8]\\d|
              2[013-9]|
              9[0-24-9]
            )|
            3(?:
              [1569][0-24-9]|
              4[0-246-9]|
              7[0-24-69]|
              89
            )|
            58[01]
          )\\d{5}
        ',
                'pager' => '
          7(?:
            1[0-369]|
            [23][0-37-9]|
            47|
            5[1578]|
            6[0235]|
            7[278]|
            8[236-9]|
            9[025-9]
          )\\d{5}
        ',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+852|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  return $self->is_valid() ? $self : undef;
}
1;