# automatically generated file, don't edit



# Copyright 2011 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::CR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210602223259;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [2-7]|
            8[3-9]
          ',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '[89]',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          210[7-9]\\d{4}|
          2(?:
            [024-7]\\d|
            1[1-9]
          )\\d{5}
        ',
                'geographic' => '
          210[7-9]\\d{4}|
          2(?:
            [024-7]\\d|
            1[1-9]
          )\\d{5}
        ',
                'mobile' => '
          (?:
            3005\\d|
            6500[01]
          )\\d{3}|
          (?:
            5[07]|
            6[0-4]|
            7[0-3]|
            8[3-9]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(90[059]\\d{7})',
                'toll_free' => '800\\d{7}',
                'voip' => '
          (?:
            210[0-6]|
            4\\d{3}|
            5100
          )\\d{4}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+506|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:(19(?:0[0-2468]|1[09]|20|66|77|99)))//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;