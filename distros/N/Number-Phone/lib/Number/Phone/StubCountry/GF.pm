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
package Number::Phone::StubCountry::GF;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20241212130805;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            [5-7]|
            9[47]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[89]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          594(?:
            [02-49]\\d|
            1[0-5]|
            5[6-9]|
            6[0-3]|
            80
          )\\d{4}
        ',
                'geographic' => '
          594(?:
            [02-49]\\d|
            1[0-5]|
            5[6-9]|
            6[0-3]|
            80
          )\\d{4}
        ',
                'mobile' => '
          (?:
            694(?:
              [0-249]\\d|
              3[0-8]
            )|
            7093[0-3]
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '80[0-5]\\d{6}',
                'voip' => '
          9(?:
            (?:
              396|
              76\\d
            )\\d|
            476[0-5]
          )\\d{4}
        '
              };
my $timezones = {
               '' => [
                       'America/Cayenne'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+594|\D)//g;
      my $self = bless({ country_code => '594', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '594', number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;