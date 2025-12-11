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
package Number::Phone::StubCountry::LV;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20251210153524;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [2679]|
            8[01]
          ',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '6\\d{7}',
                'geographic' => '6\\d{7}',
                'mobile' => '
          2333[0-8]\\d{3}|
          2(?:
            [0-24-9]\\d\\d|
            3(?:
              0[07]|
              [14-9]\\d|
              2[02-9]|
              3[0-24-9]
            )
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(81\\d{6})|(90\\d{6})',
                'toll_free' => '80\\d{6}',
                'voip' => ''
              };
my $timezones = {
               '' => [
                       'Europe/Bucharest'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+371|\D)//g;
      my $self = bless({ country_code => '371', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;