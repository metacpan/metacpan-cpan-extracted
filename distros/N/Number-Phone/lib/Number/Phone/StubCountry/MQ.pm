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
package Number::Phone::StubCountry::MQ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180619214156;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3 $4'
                }
              ];

my $validators = {
                'personal_number' => '',
                'voip' => '',
                'fixed_line' => '
          596(?:
            0[0-7]|
            10|
            2[7-9]|
            3[05-9]|
            4[0-46-8]|
            [5-7]\\d|
            8[09]|
            9[4-8]
          )\\d{4}
        ',
                'toll_free' => '',
                'pager' => '',
                'geographic' => '
          596(?:
            0[0-7]|
            10|
            2[7-9]|
            3[05-9]|
            4[0-46-8]|
            [5-7]\\d|
            8[09]|
            9[4-8]
          )\\d{4}
        ',
                'specialrate' => '',
                'mobile' => '
          69(?:
            6(?:
              [0-47-9]\\d|
              5[0-6]|
              6[0-4]
            )|
            727
          )\\d{4}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+596|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;