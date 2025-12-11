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
package Number::Phone::StubCountry::SR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20251210153525;

my $formatters = [
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '56',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '[2-5]',
                  'pattern' => '(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '[6-9]',
                  'pattern' => '(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2[1-3]|
            3[0-7]|
            4\\d|
            5[2-58]
          )\\d{4}
        ',
                'geographic' => '
          (?:
            2[1-3]|
            3[0-7]|
            4\\d|
            5[2-58]
          )\\d{4}
        ',
                'mobile' => '
          (?:
            6[08]|
            7[124-7]|
            8[1-9]
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(90\\d{5})',
                'toll_free' => '80\\d{5}',
                'voip' => '56\\d{4}'
              };
my $timezones = {
               '' => [
                       'America/Paramaribo'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+597|\D)//g;
      my $self = bless({ country_code => '597', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;