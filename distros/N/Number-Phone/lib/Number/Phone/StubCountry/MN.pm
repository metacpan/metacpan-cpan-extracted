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
package Number::Phone::StubCountry::MN;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170702164948;

my $formatters = [
                {
                  'pattern' => '([12]\\d)(\\d{2})(\\d{4})',
                  'leading_digits' => '[12]1'
                },
                {
                  'pattern' => '([12]2\\d)(\\d{5,6})',
                  'leading_digits' => '[12]2[1-3]'
                },
                {
                  'pattern' => '([12]\\d{3})(\\d{5})',
                  'leading_digits' => '
            [12](?:
              27|
              [3-5]\\d
            )2
          '
                },
                {
                  'leading_digits' => '[57-9]',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'pattern' => '([12]\\d{4})(\\d{4,5})',
                  'leading_digits' => '
            [12](?:
              27|
              [3-5]\\d
            )[4-9]
          '
                }
              ];

my $validators = {
                'fixed_line' => '
          [12](?:
            1\\d|
            2(?:
              [1-3]\\d?|
              7\\d
            )|
            3[2-8]\\d{1,2}|
            4[2-68]\\d{1,2}|
            5[1-4689]\\d{1,2}
          )\\d{5}|
          5[0568]\\d{6}
        ',
                'mobile' => '
          (?:
            8(?:
              [05689]\\d|
              3[01]
            )|
            9[013-9]\\d
          )\\d{5}
        ',
                'voip' => '7[05-8]\\d{6}',
                'toll_free' => '',
                'pager' => '',
                'geographic' => '
          [12](?:
            1\\d|
            2(?:
              [1-3]\\d?|
              7\\d
            )|
            3[2-8]\\d{1,2}|
            4[2-68]\\d{1,2}|
            5[1-4689]\\d{1,2}
          )\\d{5}|
          5[0568]\\d{6}
        ',
                'specialrate' => '',
                'personal_number' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+976|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;