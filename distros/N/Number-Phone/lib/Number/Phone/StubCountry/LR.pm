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
package Number::Phone::StubCountry::LR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250323211831;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            4[67]|
            [56]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-578]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '2\\d{7}',
                'geographic' => '2\\d{7}',
                'mobile' => '
          (?:
            (?:
              (?:
                22|
                33
              )0|
              555|
              (?:
                77|
                88
              )\\d
            )\\d|
            4(?:
              240|
              [67]
            )
          )\\d{5}|
          [56]\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          332(?:
            02|
            [34]\\d
          )\\d{4}
        )',
                'toll_free' => '',
                'voip' => ''
              };
my $timezones = {
               '' => [
                       'Atlantic/Reykjavik'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+231|\D)//g;
      my $self = bless({ country_code => '231', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '231', number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;