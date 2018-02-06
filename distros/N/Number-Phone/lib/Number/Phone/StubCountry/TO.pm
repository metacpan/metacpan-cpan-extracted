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
package Number::Phone::StubCountry::TO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180203200236;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{3})',
                  'leading_digits' => '
            [1-6]|
            7[0-4]|
            8[05]
          ',
                  'format' => '$1-$2'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            7[5-9]|
            8[47-9]
          ',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'pattern' => '(\\d{4})(\\d{3})'
                }
              ];

my $validators = {
                'pager' => '',
                'voip' => '',
                'mobile' => '
          (?:
            7[578]|
            8[47-9]
          )\\d{5}
        ',
                'personal_number' => '',
                'geographic' => '
          (?:
            2\\d|
            3[1-8]|
            4[1-4]|
            [56]0|
            7[0149]|
            8[05]
          )\\d{3}
        ',
                'toll_free' => '0800\\d{3}',
                'specialrate' => '',
                'fixed_line' => '
          (?:
            2\\d|
            3[1-8]|
            4[1-4]|
            [56]0|
            7[0149]|
            8[05]
          )\\d{3}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+676|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  return $self->is_valid() ? $self : undef;
}
1;