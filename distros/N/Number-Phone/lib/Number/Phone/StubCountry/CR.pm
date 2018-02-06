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
our $VERSION = 1.20180203200234;

my $formatters = [
                {
                  'leading_digits' => '
            [24-7]|
            8[3-9]
          ',
                  'pattern' => '(\\d{4})(\\d{4})',
                  'format' => '$1 $2'
                },
                {
                  'format' => '$1-$2-$3',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})',
                  'leading_digits' => '[89]0'
                }
              ];

my $validators = {
                'voip' => '
          210[0-6]\\d{4}|
          4\\d{7}|
          5100\\d{4}
        ',
                'pager' => '',
                'geographic' => '
          2(?:
            [024-7]\\d{2}|
            1(?:
              0[7-9]|
              [1-9]\\d
            )
          )\\d{4}
        ',
                'fixed_line' => '
          2(?:
            [024-7]\\d{2}|
            1(?:
              0[7-9]|
              [1-9]\\d
            )
          )\\d{4}
        ',
                'specialrate' => '(90[059]\\d{7})',
                'toll_free' => '800\\d{7}',
                'personal_number' => '',
                'mobile' => '
          5(?:
            0[01]|
            7[0-3]
          )\\d{5}|
          6(?:
            [0-4]\\d{3}|
            500[01]
          )\\d{3}|
          (?:
            7[0-3]|
            8[3-9]
          )\\d{6}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+506|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      {
        no warnings 'uninitialized';
        $number =~ s/^(?:(19(?:0[012468]|1[09]|20|66|77|99)))//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;