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
package Number::Phone::StubCountry::FM;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20251210153522;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[389]',
                  'pattern' => '(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          31(?:
            00[67]|
            208|
            309
          )\\d\\d|
          (?:
            3(?:
              [2357]0[1-9]|
              602|
              804|
              905
            )|
            (?:
              820|
              9[2-6]\\d
            )\\d
          )\\d{3}
        ',
                'geographic' => '
          31(?:
            00[67]|
            208|
            309
          )\\d\\d|
          (?:
            3(?:
              [2357]0[1-9]|
              602|
              804|
              905
            )|
            (?:
              820|
              9[2-6]\\d
            )\\d
          )\\d{3}
        ',
                'mobile' => '
          31(?:
            00[67]|
            208|
            309
          )\\d\\d|
          (?:
            3(?:
              [2357]0[1-9]|
              602|
              804|
              905
            )|
            (?:
              820|
              9[2-7]\\d
            )\\d
          )\\d{3}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my $timezones = {
               '' => [
                       'Pacific/Kosrae',
                       'Pacific/Ponape',
                       'Pacific/Truk'
                     ],
               '3' => [
                        'Pacific/Truk'
                      ],
               '32' => [
                         'Pacific/Ponape'
                       ],
               '37' => [
                         'Pacific/Kosrae'
                       ],
               '8' => [
                        'Pacific/Kosrae',
                        'Pacific/Ponape',
                        'Pacific/Truk'
                      ],
               '9' => [
                        'Pacific/Kosrae',
                        'Pacific/Ponape',
                        'Pacific/Truk'
                      ],
               '920' => [
                          'Pacific/Ponape'
                        ],
               '921' => [
                          'Pacific/Ponape'
                        ],
               '924' => [
                          'Pacific/Ponape'
                        ],
               '926' => [
                          'Pacific/Ponape'
                        ],
               '933' => [
                          'Pacific/Truk'
                        ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+691|\D)//g;
      my $self = bless({ country_code => '691', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;