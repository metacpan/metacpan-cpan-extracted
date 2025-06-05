# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::RE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250605193636;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[26-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          26(?:
            2\\d\\d|
            3(?:
              0\\d|
              1[0-6]
            )
          )\\d{4}
        ',
                'geographic' => '
          26(?:
            2\\d\\d|
            3(?:
              0\\d|
              1[0-6]
            )
          )\\d{4}
        ',
                'mobile' => '
          (?:
            69(?:
              2\\d\\d|
              3(?:
                [06][0-6]|
                1[0-3]|
                2[0-2]|
                3[0-39]|
                4\\d|
                5[0-5]|
                7[0-37]|
                8[0-8]|
                9[0-479]
              )
            )|
            7092[0-3]
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          8(?:
            1[019]|
            2[0156]|
            84|
            90
          )\\d{6}
        )|(89[1-37-9]\\d{6})',
                'toll_free' => '80\\d{7}',
                'voip' => '
          9(?:
            399[0-3]|
            479[0-6]|
            76(?:
              2[278]|
              3[0-37]
            )
          )\\d{4}
        '
              };
my $timezones = {
               '' => [
                       'Indian/Mayotte',
                       'Indian/Reunion'
                     ],
               '262' => [
                          'Indian/Reunion'
                        ],
               '263' => [
                          'Indian/Reunion'
                        ],
               '269' => [
                          'Indian/Mayotte'
                        ],
               '63' => [
                         'Indian/Mayotte'
                       ],
               '69' => [
                         'Indian/Reunion'
                       ],
               '7092' => [
                           'Indian/Reunion'
                         ],
               '7093' => [
                           'Indian/Mayotte'
                         ],
               '80' => [
                         'Indian/Mayotte',
                         'Indian/Reunion'
                       ],
               '81' => [
                         'Indian/Reunion'
                       ],
               '82' => [
                         'Indian/Reunion'
                       ],
               '88' => [
                         'Indian/Reunion'
                       ],
               '89' => [
                         'Indian/Reunion'
                       ],
               '9398' => [
                           'Indian/Mayotte'
                         ],
               '9399' => [
                           'Indian/Reunion'
                         ],
               '9478' => [
                           'Indian/Mayotte'
                         ],
               '9479' => [
                           'Indian/Reunion'
                         ],
               '9762' => [
                           'Indian/Reunion'
                         ],
               '9763' => [
                           'Indian/Reunion'
                         ],
               '9769' => [
                           'Indian/Mayotte'
                         ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+262|\D)//g;
      my $self = bless({ country_code => '262', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '262', number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;