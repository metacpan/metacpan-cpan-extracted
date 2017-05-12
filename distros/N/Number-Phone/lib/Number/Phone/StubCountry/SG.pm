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
package Number::Phone::StubCountry::SG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'leading_digits' => '
            [369]|
            8[1-9]
          ',
                  'pattern' => '([3689]\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(1[89]00)(\\d{3})(\\d{4})',
                  'leading_digits' => '1[89]'
                },
                {
                  'leading_digits' => '70',
                  'pattern' => '(7000)(\\d{4})(\\d{3})'
                },
                {
                  'pattern' => '(800)(\\d{3})(\\d{4})',
                  'leading_digits' => '80'
                }
              ];

my $validators = {
                'specialrate' => '(1900\\d{7})|(7000\\d{7})',
                'mobile' => '
          (?:
            8[1-8]|
            9[0-8]
          )\\d{6}
        ',
                'toll_free' => '1?800\\d{7}',
                'personal_number' => '',
                'geographic' => '6[1-9]\\d{6}',
                'voip' => '3[12]\\d{6}',
                'pager' => '',
                'fixed_line' => '6[1-9]\\d{6}'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+65|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  return $self->is_valid() ? $self : undef;
}
1;