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
package Number::Phone::StubCountry::LB;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190303205539;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3})',
                  'leading_digits' => '
            [13-69]|
            7(?:
              [2-57]|
              62|
              8[0-7]|
              9[04-9]
            )|
            8[02-9]
          ',
                  'format' => '$1 $2 $3'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[7-9]',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'geographic' => '
          (?:
            (?:
              [14-69]\\d|
              8[02-9]
            )\\d|
            7(?:
              [2-57]\\d|
              62|
              8[0-7]|
              9[04-9]
            )
          )\\d{4}
        ',
                'pager' => '',
                'mobile' => '
          (?:
            (?:
              3|
              81
            )\\d|
            7(?:
              [01]\\d|
              6[013-9]|
              8[89]|
              9[1-3]
            )
          )\\d{5}
        ',
                'specialrate' => '(80\\d{6})|(9[01]\\d{6})',
                'voip' => '',
                'fixed_line' => '
          (?:
            (?:
              [14-69]\\d|
              8[02-9]
            )\\d|
            7(?:
              [2-57]\\d|
              62|
              8[0-7]|
              9[04-9]
            )
          )\\d{4}
        ',
                'toll_free' => '',
                'personal_number' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+961|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;