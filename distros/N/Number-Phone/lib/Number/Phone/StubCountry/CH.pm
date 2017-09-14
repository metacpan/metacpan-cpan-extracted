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
package Number::Phone::StubCountry::CH;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113147;

my $formatters = [
                {
                  'pattern' => '([2-9]\\d)(\\d{3})(\\d{2})(\\d{2})',
                  'leading_digits' => '
            [2-7]|
            [89]1
          '
                },
                {
                  'pattern' => '([89]\\d{2})(\\d{3})(\\d{3})',
                  'leading_digits' => '
            8[047]|
            90
          '
                },
                {
                  'leading_digits' => '860',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'voip' => '',
                'toll_free' => '800\\d{6}',
                'mobile' => '7[5-9]\\d{7}',
                'specialrate' => '(84[0248]\\d{6})|(90[016]\\d{6})|(5[18]\\d{7})',
                'fixed_line' => '
          (?:
            2[12467]|
            3[1-4]|
            4[134]|
            5[256]|
            6[12]|
            [7-9]1
          )\\d{7}
        ',
                'pager' => '74[0248]\\d{6}',
                'geographic' => '
          (?:
            2[12467]|
            3[1-4]|
            4[134]|
            5[256]|
            6[12]|
            [7-9]1
          )\\d{7}
        ',
                'personal_number' => '878\\d{6}'
              };
my %areanames = (
  4121 => "Lausanne",
  4122 => "Geneva",
  4124 => "Yverdon\/Aigle",
  4126 => "Fribourg",
  4127 => "Sion",
  4131 => "Berne",
  4132 => "Bienne\/Neuchâtel\/Soleure\/Jura",
  4133 => "Thun",
  4134 => "Burgdorf\/Langnau\ i\.E\.",
  4141 => "Lucerne",
  4143 => "Zurich",
  4144 => "Zurich",
  4152 => "Winterthur",
  4155 => "Rapperswil",
  4156 => "Baden",
  4161 => "Basel",
  4162 => "Olten",
  4171 => "St\.\ Gallen",
  4181 => "Chur",
  4191 => "Bellinzona",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+41|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;