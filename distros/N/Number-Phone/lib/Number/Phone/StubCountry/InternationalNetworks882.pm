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
package Number::Phone::StubCountry::InternationalNetworks882;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250323211839;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            16|
            342
          ',
                  'pattern' => '(\\d{2})(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '49',
                  'pattern' => '(\\d{2})(\\d{6})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            1[36]|
            9
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '3[23]',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '16',
                  'pattern' => '(\\d{2})(\\d{3,4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            10|
            23|
            3(?:
              [15]|
              4[57]
            )|
            4|
            51
          ',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '34',
                  'pattern' => '(\\d{3})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[1-35]',
                  'pattern' => '(\\d{2})(\\d{4,5})(\\d{5})'
                }
              ];

my $validators = {
                'fixed_line' => '',
                'geographic' => '',
                'mobile' => '
          342\\d{4}|
          (?:
            337|
            49
          )\\d{6}|
          (?:
            3(?:
              2|
              47|
              7\\d{3}
            )|
            50\\d{3}
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => '
          1(?:
            3(?:
              0[0347]|
              [13][0139]|
              2[035]|
              4[013568]|
              6[0459]|
              7[06]|
              8[15-8]|
              9[0689]
            )\\d{4}|
            6\\d{5,10}
          )|
          (?:
            345\\d|
            9[89]
          )\\d{6}|
          (?:
            10|
            2(?:
              3|
              85\\d
            )|
            3(?:
              [15]|
              [69]\\d\\d
            )|
            4[15-8]|
            51
          )\\d{8}
        '
              };
my $timezones = {};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+882|\D)//g;
      my $self = bless({ country_code => '882', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;