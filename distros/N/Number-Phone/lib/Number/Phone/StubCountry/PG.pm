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
our $VERSION = 1.20190611222641;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{4})',
                  'format' => '$1 $2',
                  'leading_digits' => '
            18|
            [2-69]|
            85
          '
                },
                {
                  'format' => '$1 $2',
                  'pattern' => '(\\d{4})(\\d{4})',
                  'leading_digits' => '[78]'
                }
              ];

my $validators = {
                'geographic' => '
          (?:
            64[1-9]|
            7730|
            85[02-46-9]
          )\\d{4}|
          (?:
            3[0-2]|
            4[257]|
            5[34]|
            77[0-24]|
            9[78]
          )\\d{5}
        ',
                'specialrate' => '',
                'fixed_line' => '
          (?:
            64[1-9]|
            7730|
            85[02-46-9]
          )\\d{4}|
          (?:
            3[0-2]|
            4[257]|
            5[34]|
            77[0-24]|
            9[78]
          )\\d{5}
        ',
                'voip' => '
          2(?:
            0[0-47]|
            7[568]
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'toll_free' => '180\\d{4}',
                'mobile' => '
          775\\d{5}|
          (?:
            7[0-689]|
            81
          )\\d{6}
        '
              };
my %areanames = (
  6753 => "NCD",
  67542 => "Madang",
  67545 => "Sepik",
  67547 => "Morobe",
  6755 => "Highlands",
  6756 => "MP\/Gulf\/Tabubil\/Kiunga",
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