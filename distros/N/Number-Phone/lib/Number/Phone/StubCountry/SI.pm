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
package Number::Phone::StubCountry::SI;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'pattern' => '(\\d)(\\d{3})(\\d{2})(\\d{2})',
                  'leading_digits' => '
            [12]|
            3[24-8]|
            4[24-8]|
            5[2-8]|
            7[3-8]
          '
                },
                {
                  'pattern' => '([3-7]\\d)(\\d{3})(\\d{3})',
                  'leading_digits' => '
            [37][01]|
            4[0139]|
            51|
            6
          '
                },
                {
                  'pattern' => '([89][09])(\\d{3,6})',
                  'leading_digits' => '[89][09]'
                },
                {
                  'leading_digits' => '
            59|
            8[1-3]
          ',
                  'pattern' => '([58]\\d{2})(\\d{5})'
                }
              ];

my $validators = {
                'specialrate' => '(
          90\\d{4,6}|
          89[1-3]\\d{2,5}
        )',
                'mobile' => '
          (?:
            [37][01]|
            4[0139]|
            51|
            6[48]
          )\\d{6}
        ',
                'geographic' => '
          (?:
            1\\d|
            [25][2-8]|
            3[24-8]|
            4[24-8]|
            7[3-8]
          )\\d{6}
        ',
                'personal_number' => '',
                'toll_free' => '80\\d{4,6}',
                'pager' => '',
                'voip' => '
          (?:
            59|
            8[1-3]
          )\\d{6}
        ',
                'fixed_line' => '
          (?:
            1\\d|
            [25][2-8]|
            3[24-8]|
            4[24-8]|
            7[3-8]
          )\\d{6}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+386|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;