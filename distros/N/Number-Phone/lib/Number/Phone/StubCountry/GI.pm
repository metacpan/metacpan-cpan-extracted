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
package Number::Phone::StubCountry::GI;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240910191015;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '2',
                  'pattern' => '(\\d{3})(\\d{5})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2190[0-2]\\d{3}|
          2(?:
            0(?:
              [02]\\d|
              3[01]
            )|
            16[24-9]|
            2[2-5]\\d
          )\\d{4}
        ',
                'geographic' => '
          2190[0-2]\\d{3}|
          2(?:
            0(?:
              [02]\\d|
              3[01]
            )|
            16[24-9]|
            2[2-5]\\d
          )\\d{4}
        ',
                'mobile' => '
          5251[0-4]\\d{3}|
          (?:
            5(?:
              [146-8]\\d\\d|
              250
            )|
            60(?:
              1[01]|
              6\\d
            )
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my $timezones = {
               '' => [
                       'Europe/Gibraltar'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+350|\D)//g;
      my $self = bless({ country_code => '350', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;