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
package Number::Phone::StubCountry::AW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250913135855;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[25-9]',
                  'pattern' => '(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          5(?:
            2\\d|
            8[1-9]
          )\\d{4}
        ',
                'geographic' => '
          5(?:
            2\\d|
            8[1-9]
          )\\d{4}
        ',
                'mobile' => '
          (?:
            290|
            5[69]\\d|
            6(?:
              [03]0|
              22|
              4[0-2]|
              [69]\\d
            )|
            7(?:
              [34]\\d|
              7[07]
            )|
            9(?:
              6[45]|
              9[4-8]
            )
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(900\\d{4})',
                'toll_free' => '800\\d{4}',
                'voip' => '
          (?:
            28\\d|
            501
          )\\d{4}
        '
              };
my $timezones = {
               '' => [
                       'America/Aruba'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+297|\D)//g;
      my $self = bless({ country_code => '297', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;