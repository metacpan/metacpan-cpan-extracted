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
package Number::Phone::StubCountry::BA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173053;

my $formatters = [
                {
                  'leading_digits' => '[3-5]',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'leading_digits' => '
            6[1-356]|
            [7-9]
          ',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{3})',
                  'leading_digits' => '6[047]'
                }
              ];

my $validators = {
                'pager' => '',
                'voip' => '',
                'fixed_line' => '
          (?:
            [35]\\d|
            49
          )\\d{6}
        ',
                'specialrate' => '(8[12]\\d{6})|(9[0246]\\d{6})|(70[23]\\d{5})',
                'mobile' => '
          6(?:
            03|
            44|
            71|
            [1-356]
          )\\d{6}
        ',
                'geographic' => '
          (?:
            [35]\\d|
            49
          )\\d{6}
        ',
                'personal_number' => '',
                'toll_free' => '8[08]\\d{6}'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+387|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;