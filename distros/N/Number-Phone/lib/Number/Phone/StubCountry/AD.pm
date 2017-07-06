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
package Number::Phone::StubCountry::AD;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170702164946;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{3})',
                  'leading_digits' => '
            [137-9]|
            6[0-8]
          '
                },
                {
                  'leading_digits' => '180[02]',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'leading_digits' => '690',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'specialrate' => '([19]\\d{5})',
                'geographic' => '[78]\\d{5}',
                'personal_number' => '',
                'mobile' => '
          (?:
            3\\d|
            6(?:
              [0-8]|
              90\\d{2}
            )
          )\\d{4}
        ',
                'fixed_line' => '[78]\\d{5}',
                'voip' => '',
                'toll_free' => '180[02]\\d{4}',
                'pager' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+376|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  return $self->is_valid() ? $self : undef;
}
1;