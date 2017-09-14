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
package Number::Phone::StubCountry::LA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113148;

my $formatters = [
                {
                  'leading_digits' => '20',
                  'pattern' => '(20)(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'leading_digits' => '
            2[13]|
            3[14]|
            [4-8]
          ',
                  'pattern' => '([2-8]\\d)(\\d{3})(\\d{3})'
                },
                {
                  'leading_digits' => '30',
                  'pattern' => '(30)(\\d{2})(\\d{2})(\\d{3})'
                }
              ];

my $validators = {
                'personal_number' => '',
                'geographic' => '
          (?:
            2[13]|
            3(?:
              0\\d|
              [14]
            )|
            [5-7][14]|
            41|
            8[1468]
          )\\d{6}
        ',
                'pager' => '',
                'mobile' => '
          20(?:
            2[2389]|
            5[24-689]|
            7[6-8]|
            9[125-9]
          )\\d{6}
        ',
                'toll_free' => '',
                'fixed_line' => '
          (?:
            2[13]|
            3(?:
              0\\d|
              [14]
            )|
            [5-7][14]|
            41|
            8[1468]
          )\\d{6}
        ',
                'specialrate' => '',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+856|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;