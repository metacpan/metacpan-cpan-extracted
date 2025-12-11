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
package Number::Phone::StubCountry::TD;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20251210153525;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[236-9]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          22(?:
            [37-9]0|
            5[0-5]|
            6[89]
          )\\d{4}
        ',
                'geographic' => '
          22(?:
            [37-9]0|
            5[0-5]|
            6[89]
          )\\d{4}
        ',
                'mobile' => '
          (?:
            30|
            [69]\\d|
            77|
            8[5-7]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my $timezones = {
               '' => [
                       'Africa/Ndjamena'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+235|\D)//g;
      my $self = bless({ country_code => '235', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;