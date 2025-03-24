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
package Number::Phone::StubCountry::DK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250323211826;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[2-9]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              [0-59][1-9]|
              [6-8]\\d
            )|
            3(?:
              [0-3][1-9]|
              4[13]|
              5[1-58]|
              6[1347-9]|
              7\\d|
              8[1-8]|
              9[1-79]
            )|
            4(?:
              [0-25][1-9]|
              [34][2-9]|
              6[13-579]|
              7[13579]|
              8[1-47]|
              9[127]
            )|
            5(?:
              [0-36][1-9]|
              4[146-9]|
              5[3-57-9]|
              7[568]|
              8[1-358]|
              9[1-69]
            )|
            6(?:
              [0135][1-9]|
              2[1-68]|
              4[2-8]|
              6[1689]|
              [78]\\d|
              9[15689]
            )|
            7(?:
              [0-69][1-9]|
              7[3-9]|
              8[147]
            )|
            8(?:
              [16-9][1-9]|
              2[1-58]
            )|
            9(?:
              [1-47-9][1-9]|
              6\\d
            )
          )\\d{5}
        ',
                'geographic' => '
          (?:
            2(?:
              [0-59][1-9]|
              [6-8]\\d
            )|
            3(?:
              [0-3][1-9]|
              4[13]|
              5[1-58]|
              6[1347-9]|
              7\\d|
              8[1-8]|
              9[1-79]
            )|
            4(?:
              [0-25][1-9]|
              [34][2-9]|
              6[13-579]|
              7[13579]|
              8[1-47]|
              9[127]
            )|
            5(?:
              [0-36][1-9]|
              4[146-9]|
              5[3-57-9]|
              7[568]|
              8[1-358]|
              9[1-69]
            )|
            6(?:
              [0135][1-9]|
              2[1-68]|
              4[2-8]|
              6[1689]|
              [78]\\d|
              9[15689]
            )|
            7(?:
              [0-69][1-9]|
              7[3-9]|
              8[147]
            )|
            8(?:
              [16-9][1-9]|
              2[1-58]
            )|
            9(?:
              [1-47-9][1-9]|
              6\\d
            )
          )\\d{5}
        ',
                'mobile' => '
          (?:
            2[6-8]|
            37|
            6[78]|
            96
          )\\d{6}|
          (?:
            2[0-59]|
            3[0-689]|
            [457]\\d|
            6[0-69]|
            8[126-9]|
            9[1-47-9]
          )[1-9]\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(90\\d{6})',
                'toll_free' => '80\\d{6}',
                'voip' => ''
              };
my $timezones = {
               '' => [
                       'Europe/Copenhagen'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+45|\D)//g;
      my $self = bless({ country_code => '45', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;