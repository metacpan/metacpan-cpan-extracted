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
package Number::Phone::StubCountry::ME;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'leading_digits' => '
            [2-57-9]|
            6[036-9]
          ',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'mobile' => '
          6(?:
            00\\d|
            3[024]\\d|
            6[0-25]\\d|
            [7-9]\\d{2}
          )\\d{4}
        ',
                'specialrate' => '(
          (?:
            9(?:
              4[1568]|
              5[178]
            )
          )\\d{5}
        )|(77[1-9]\\d{5})',
                'personal_number' => '',
                'geographic' => '
          (?:
            20[2-8]|
            3(?:
              0[2-7]|
              [12][235-7]|
              3[24-7]
            )|
            4(?:
              0[2-467]|
              1[267]
            )|
            5(?:
              0[2467]|
              1[267]|
              2[2367]
            )
          )\\d{5}
        ',
                'toll_free' => '80[0-258]\\d{5}',
                'voip' => '78[1-49]\\d{5}',
                'pager' => '',
                'fixed_line' => '
          (?:
            20[2-8]|
            3(?:
              0[2-7]|
              [12][235-7]|
              3[24-7]
            )|
            4(?:
              0[2-467]|
              1[267]
            )|
            5(?:
              0[2467]|
              1[267]|
              2[2367]
            )
          )\\d{5}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+382|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;