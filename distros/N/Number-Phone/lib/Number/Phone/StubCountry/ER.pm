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
package Number::Phone::StubCountry::ER;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250605193635;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[178]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1(?:
              1[12568]|
              [24]0|
              55|
              6[146]
            )|
            8\\d\\d
          )\\d{4}
        ',
                'geographic' => '
          (?:
            1(?:
              1[12568]|
              [24]0|
              55|
              6[146]
            )|
            8\\d\\d
          )\\d{4}
        ',
                'mobile' => '
          (?:
            17[1-3]|
            7\\d\\d
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
                       'Africa/Asmera'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+291|\D)//g;
      my $self = bless({ country_code => '291', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '291', number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;