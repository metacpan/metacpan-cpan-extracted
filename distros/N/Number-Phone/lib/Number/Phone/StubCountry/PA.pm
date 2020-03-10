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
package Number::Phone::StubCountry::PA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200309202348;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '[1-57-9]',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '6',
                  'pattern' => '(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1(?:
              0\\d|
              1[479]|
              2[37]|
              3[0137]|
              4[17]|
              5[05]|
              6[58]|
              7[0167]|
              8[258]|
              9[139]
            )|
            2(?:
              [0235-79]\\d|
              1[0-7]|
              4[013-9]|
              8[026-9]
            )|
            3(?:
              [089]\\d|
              1[014-7]|
              2[0-5]|
              33|
              4[0-79]|
              55|
              6[068]|
              7[03-8]
            )|
            4(?:
              00|
              3[0-579]|
              4\\d|
              7[0-57-9]
            )|
            5(?:
              [01]\\d|
              2[0-7]|
              [56]0|
              79
            )|
            7(?:
              0[09]|
              2[0-26-8]|
              3[03]|
              4[04]|
              5[05-9]|
              6[056]|
              7[0-24-9]|
              8[6-9]|
              90
            )|
            8(?:
              09|
              2[89]|
              3\\d|
              4[0-24-689]|
              5[014]|
              8[02]
            )|
            9(?:
              0[5-9]|
              1[0135-8]|
              2[036-9]|
              3[35-79]|
              40|
              5[0457-9]|
              6[05-9]|
              7[04-9]|
              8[35-8]|
              9\\d
            )
          )\\d{4}
        ',
                'geographic' => '
          (?:
            1(?:
              0\\d|
              1[479]|
              2[37]|
              3[0137]|
              4[17]|
              5[05]|
              6[58]|
              7[0167]|
              8[258]|
              9[139]
            )|
            2(?:
              [0235-79]\\d|
              1[0-7]|
              4[013-9]|
              8[026-9]
            )|
            3(?:
              [089]\\d|
              1[014-7]|
              2[0-5]|
              33|
              4[0-79]|
              55|
              6[068]|
              7[03-8]
            )|
            4(?:
              00|
              3[0-579]|
              4\\d|
              7[0-57-9]
            )|
            5(?:
              [01]\\d|
              2[0-7]|
              [56]0|
              79
            )|
            7(?:
              0[09]|
              2[0-26-8]|
              3[03]|
              4[04]|
              5[05-9]|
              6[056]|
              7[0-24-9]|
              8[6-9]|
              90
            )|
            8(?:
              09|
              2[89]|
              3\\d|
              4[0-24-689]|
              5[014]|
              8[02]
            )|
            9(?:
              0[5-9]|
              1[0135-8]|
              2[036-9]|
              3[35-79]|
              40|
              5[0457-9]|
              6[05-9]|
              7[04-9]|
              8[35-8]|
              9\\d
            )
          )\\d{4}
        ',
                'mobile' => '
          (?:
            1[16]1|
            21[89]|
            6(?:
              [02-9]\\d|
              1[0-6]
            )\\d|
            8(?:
              1[01]|
              7[23]
            )
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          (?:
            8(?:
              22|
              55|
              60|
              7[78]|
              86
            )|
            9(?:
              00|
              81
            )
          )\\d{4}
        )',
                'toll_free' => '800\\d{4}',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+507|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;