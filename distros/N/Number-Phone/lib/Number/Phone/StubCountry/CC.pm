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
package Number::Phone::StubCountry::CC;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170702164946;

my $formatters = [];

my $validators = {
                'voip' => '550\\d{6}',
                'pager' => '',
                'toll_free' => '
          180(?:
            0\\d{3}|
            2
          )\\d{3}
        ',
                'fixed_line' => '89162\\d{4}',
                'mobile' => '
          14(?:
            5\\d|
            71
          )\\d{5}|
          4(?:
            [0-2]\\d|
            3[0-57-9]|
            4[47-9]|
            5[0-25-9]|
            6[6-9]|
            7[02-9]|
            8[147-9]|
            9[017-9]
          )\\d{6}
        ',
                'geographic' => '89162\\d{4}',
                'specialrate' => '(
          13(?:
            00\\d{2}
          )?\\d{4}
        )|(190[0126]\\d{6})',
                'personal_number' => '500\\d{6}'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+61|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;