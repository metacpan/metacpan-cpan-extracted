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
package Number::Phone::StubCountry::TM;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170702164949;

my $formatters = [
                {
                  'leading_digits' => '12',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{6})',
                  'leading_digits' => '6'
                },
                {
                  'pattern' => '(\\d{3})(\\d)(\\d{2})(\\d{2})',
                  'leading_digits' => '
              13|
              [2-5]
            '
                }
              ];

my $validators = {
                'geographic' => '
          (?:
            1(?:
              2\\d|
              3[1-9]
            )|
            2(?:
              22|
              4[0-35-8]
            )|
            3(?:
              22|
              4[03-9]
            )|
            4(?:
              22|
              3[128]|
              4\\d|
              6[15]
            )|
            5(?:
              22|
              5[7-9]|
              6[014-689]
            )
          )\\d{5}
        ',
                'specialrate' => '',
                'personal_number' => '',
                'mobile' => '6[1-9]\\d{6}',
                'fixed_line' => '
          (?:
            1(?:
              2\\d|
              3[1-9]
            )|
            2(?:
              22|
              4[0-35-8]
            )|
            3(?:
              22|
              4[03-9]
            )|
            4(?:
              22|
              3[128]|
              4\\d|
              6[15]
            )|
            5(?:
              22|
              5[7-9]|
              6[014-689]
            )
          )\\d{5}
        ',
                'voip' => '',
                'toll_free' => '',
                'pager' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+993|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^8)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;