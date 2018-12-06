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
package Number::Phone::StubCountry::FO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20181205223703;

my $formatters = [
                {
                  'pattern' => '(\\d{6})',
                  'format' => '$1',
                  'leading_digits' => '[2-9]'
                }
              ];

my $validators = {
                'voip' => '
          (?:
            6[0-36]|
            88
          )\\d{4}
        ',
                'mobile' => '
          (?:
            [27][1-9]|
            5\\d
          )\\d{4}
        ',
                'pager' => '',
                'fixed_line' => '
          (?:
            20|
            [34]\\d|
            8[19]
          )\\d{4}
        ',
                'personal_number' => '',
                'specialrate' => '(
          90(?:
            [13-5][15-7]|
            2[125-7]|
            99
          )\\d\\d
        )',
                'geographic' => '
          (?:
            20|
            [34]\\d|
            8[19]
          )\\d{4}
        ',
                'toll_free' => '80[257-9]\\d{3}'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+298|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:(10(?:01|[12]0|88)))//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;