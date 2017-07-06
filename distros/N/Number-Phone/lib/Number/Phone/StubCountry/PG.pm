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
package Number::Phone::StubCountry::PG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170702164948;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{4})',
                  'leading_digits' => '
            [13-689]|
            27
          '
                },
                {
                  'pattern' => '(\\d{4})(\\d{4})',
                  'leading_digits' => '
            20|
            7
          '
                }
              ];

my $validators = {
                'voip' => '
          2(?:
            0[0-47]|
            7[568]
          )\\d{4}
        ',
                'toll_free' => '180\\d{4}',
                'pager' => '',
                'fixed_line' => '
          (?:
            3[0-2]\\d|
            4[257]\\d|
            5[34]\\d|
            64[1-9]|
            77(?:
              [0-24]\\d|
              30
            )|
            85[02-46-9]|
            9[78]\\d
          )\\d{4}
        ',
                'mobile' => '
          7(?:
            [0-689]\\d|
            75
          )\\d{5}
        ',
                'geographic' => '
          (?:
            3[0-2]\\d|
            4[257]\\d|
            5[34]\\d|
            64[1-9]|
            77(?:
              [0-24]\\d|
              30
            )|
            85[02-46-9]|
            9[78]\\d
          )\\d{4}
        ',
                'specialrate' => '',
                'personal_number' => ''
              };
my %areanames = (
  6753 => "NCD",
  67542 => "Madang",
  67545 => "Sepik",
  67547 => "Morobe",
  67553 => "Highlands",
  67554 => "Highlands",
  67562 => "Oro",
  67564 => "MP\/Gulf\/Tabubil\/Kiunga",
  6759 => "Islands",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+675|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;