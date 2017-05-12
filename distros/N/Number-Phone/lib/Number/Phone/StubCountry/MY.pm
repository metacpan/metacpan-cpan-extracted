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
package Number::Phone::StubCountry::MY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'pattern' => '([4-79])(\\d{3})(\\d{4})',
                  'leading_digits' => '[4-79]'
                },
                {
                  'pattern' => '(3)(\\d{4})(\\d{4})',
                  'leading_digits' => '3'
                },
                {
                  'leading_digits' => '
            1[02-46-9][1-9]|
            8
          ',
                  'pattern' => '([18]\\d)(\\d{3})(\\d{3,4})'
                },
                {
                  'pattern' => '(1)([36-8]00)(\\d{2})(\\d{4})',
                  'leading_digits' => '1[36-8]0'
                },
                {
                  'leading_digits' => '11',
                  'pattern' => '(11)(\\d{4})(\\d{4})'
                },
                {
                  'pattern' => '(15[49])(\\d{3})(\\d{4})',
                  'leading_digits' => '15'
                }
              ];

my $validators = {
                'specialrate' => '(1600\\d{6})',
                'mobile' => '
          1(?:
            1[1-5]\\d{2}|
            [02-4679][2-9]\\d|
            59\\d{2}|
            8(?:
              1[23]|
              [2-9]\\d
            )
          )\\d{5}
        ',
                'toll_free' => '1[378]00\\d{6}',
                'geographic' => '
          (?:
            3[2-9]\\d|
            [4-9][2-9]
          )\\d{6}
        ',
                'personal_number' => '',
                'pager' => '',
                'voip' => '154\\d{7}',
                'fixed_line' => '
          (?:
            3[2-9]\\d|
            [4-9][2-9]
          )\\d{6}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+60|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;