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
our $VERSION = 1.20210309172131;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '9003',
                  'pattern' => '(\\d{3})(\\d{2,5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [2-7]|
            8[1-4]|
            9(?:
              0[1-9]|
              [1-8]
            )
          ',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '9',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              [13-9]\\d|
              2[013-9]
            )\\d|
            3(?:
              (?:
                [1569][0-24-9]|
                4[0-246-9]|
                7[0-24-69]
              )\\d|
              8(?:
                4[0-6]|
                5[0-5]|
                9\\d
              )
            )|
            58(?:
              0[1-8]|
              1[2-9]
            )
          )\\d{4}
        ',
                'geographic' => '
          (?:
            2(?:
              [13-9]\\d|
              2[013-9]
            )\\d|
            3(?:
              (?:
                [1569][0-24-9]|
                4[0-246-9]|
                7[0-24-69]
              )\\d|
              8(?:
                4[0-6]|
                5[0-5]|
                9\\d
              )
            )|
            58(?:
              0[1-8]|
              1[2-9]
            )
          )\\d{4}
        ',
                'mobile' => '
          (?:
            46(?:
              0[0-7]|
              1[0-6]|
              4[0-57-9]|
              5[0-8]|
              6[0-4]
            )|
            5730|
            6(?:
              26[013-7]|
              66[0-3]
            )|
            70(?:
              7[1-5]|
              8[0-4]
            )|
            848[015-9]|
            929[03-9]
          )\\d{4}|
          (?:
            46[23]|
            5(?:
              [1-59][0-46-9]|
              6[0-4689]|
              7[0-2469]
            )|
            6(?:
              0[1-9]|
              [13-59]\\d|
              [268][0-57-9]|
              7[0-79]
            )|
            849|
            9(?:
              0[1-9]|
              1[02-9]|
              [2358][0-8]|
              [467]\\d
            )
          )\\d{5}
        ',
                'pager' => '
          7(?:
            1(?:
              0[0-38]|
              1[0-3679]|
              3[013]|
              69|
              9[0136]
            )|
            2(?:
              [02389]\\d|
              1[18]|
              7[27-9]
            )|
            3(?:
              [0-38]\\d|
              7[0-369]|
              9[2357-9]
            )|
            47\\d|
            5(?:
              [178]\\d|
              5[0-5]
            )|
            6(?:
              0[0-7]|
              2[236-9]|
              [35]\\d
            )|
            7(?:
              [27]\\d|
              8[7-9]
            )|
            8(?:
              [23689]\\d|
              7[1-9]
            )|
            9(?:
              [025]\\d|
              6[0-246-8]|
              7[0-36-9]|
              8[238]
            )
          )\\d{4}
        ',
                'personal_number' => '
          8(?:
            1[0-4679]\\d|
            2(?:
              [0-36]\\d|
              7[0-4]
            )|
            3(?:
              [034]\\d|
              2[09]|
              70
            )
          )\\d{4}
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