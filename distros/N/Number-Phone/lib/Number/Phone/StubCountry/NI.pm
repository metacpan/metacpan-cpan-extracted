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
package Number::Phone::StubCountry::NI;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20221202211027;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[125-8]',
                  'pattern' => '(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '2\\d{7}',
                'geographic' => '2\\d{7}',
                'mobile' => '
          (?:
            5(?:
              5[0-7]|
              [78]\\d
            )|
            6(?:
              20|
              3[035]|
              4[045]|
              5[05]|
              77|
              8[1-9]|
              9[059]
            )|
            (?:
              7[5-8]|
              8\\d
            )\\d
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '1800\\d{4}',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+505|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;