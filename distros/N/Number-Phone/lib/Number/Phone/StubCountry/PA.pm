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
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{4})',
                  'leading_digits' => '[1-57-9]'
                },
                {
                  'leading_digits' => '6',
                  'pattern' => '(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'specialrate' => '(
          (?:
            779|
            8(?:
              55|
              60|
              7[78]
            )|
            9(?:
              00|
              81
            )
          )\\d{4}
        )',
                'mobile' => '
          (?:
            1[16]1|
            21[89]|
            8(?:
              1[01]|
              7[23]
            )
          )\\d{4}|
          6(?:
            [024-9]\\d|
            1[0-5]|
            3[0-24-9]
          )\\d{5}
        ',
                'toll_free' => '80[09]\\d{4}',
                'geographic' => '
          (?:
            1(?:
              0[0-8]|
              1[49]|
              2[37]|
              3[0137]|
              4[147]|
              5[05]|
              6[58]|
              7[0167]|
              8[58]|
              9[139]
            )|
            2(?:
              [0235679]\\d|
              1[0-7]|
              4[04-9]|
              8[028]
            )|
            3(?:
              [09]\\d|
              1[014-7]|
              2[0-3]|
              3[03]|
              4[03-57]|
              55|
              6[068]|
              7[06-8]|
              8[06-9]
            )|
            4(?:
              3[013-69]|
              4\\d|
              7[0-589]
            )|
            5(?:
              [01]\\d|
              2[0-7]|
              [56]0|
              79
            )|
            7(?:
              0[09]|
              2[0-267]|
              3[06]|
              [469]0|
              5[06-9]|
              7[0-24-79]|
              8[7-9]
            )|
            8(?:
              09|
              [34]\\d|
              5[0134]|
              8[02]
            )|
            9(?:
              0[6-9]|
              1[016-8]|
              2[036-8]|
              3[3679]|
              40|
              5[0489]|
              6[06-9]|
              7[046-9]|
              8[36-8]|
              9[1-9]
            )
          )\\d{4}
        ',
                'personal_number' => '',
                'pager' => '',
                'voip' => '',
                'fixed_line' => '
          (?:
            1(?:
              0[0-8]|
              1[49]|
              2[37]|
              3[0137]|
              4[147]|
              5[05]|
              6[58]|
              7[0167]|
              8[58]|
              9[139]
            )|
            2(?:
              [0235679]\\d|
              1[0-7]|
              4[04-9]|
              8[028]
            )|
            3(?:
              [09]\\d|
              1[014-7]|
              2[0-3]|
              3[03]|
              4[03-57]|
              55|
              6[068]|
              7[06-8]|
              8[06-9]
            )|
            4(?:
              3[013-69]|
              4\\d|
              7[0-589]
            )|
            5(?:
              [01]\\d|
              2[0-7]|
              [56]0|
              79
            )|
            7(?:
              0[09]|
              2[0-267]|
              3[06]|
              [469]0|
              5[06-9]|
              7[0-24-79]|
              8[7-9]
            )|
            8(?:
              09|
              [34]\\d|
              5[0134]|
              8[02]
            )|
            9(?:
              0[6-9]|
              1[016-8]|
              2[036-8]|
              3[3679]|
              40|
              5[0489]|
              6[06-9]|
              7[046-9]|
              8[36-8]|
              9[1-9]
            )
          )\\d{4}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+507|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  return $self->is_valid() ? $self : undef;
}
1;