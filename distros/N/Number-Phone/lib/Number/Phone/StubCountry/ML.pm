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
package Number::Phone::StubCountry::ML;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'leading_digits' => '[246-9]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'pattern' => '(\\d{4})',
                  'leading_digits' => '
            67|
            74
          '
                }
              ];

my $validators = {
                'toll_free' => '80\\d{6}',
                'geographic' => '
          (?:
            2(?:
              0(?:
                2\\d|
                7[0-8]
              )|
              1(?:
                2[5-7]|
                [3-689]\\d
              )
            )|
            44[1239]\\d
          )\\d{4}
        ',
                'personal_number' => '',
                'mobile' => '
          (?:
            2(?:
              079|
              17\\d
            )|
            [679]\\d{3}|
            8[239]\\d{2}
          )\\d{4}
        ',
                'specialrate' => '',
                'fixed_line' => '
          (?:
            2(?:
              0(?:
                2\\d|
                7[0-8]
              )|
              1(?:
                2[5-7]|
                [3-689]\\d
              )
            )|
            44[1239]\\d
          )\\d{4}
        ',
                'pager' => '',
                'voip' => ''
              };
my %areanames = (
  223202 => "Bamako",
  2232070 => "Bamako",
  2232071 => "Bamako",
  2232072 => "Bamako",
  2232073 => "Bamako",
  2232074 => "Bamako",
  2232075 => "Bamako",
  2232076 => "Bamako",
  2232077 => "Bamako",
  2232078 => "Bamako",
  2232126 => "Koulikoro",
  2232127 => "Koulikoro",
  223214 => "Mopti",
  223215 => "Kayes",
  223216 => "Sikasso",
  223218 => "Gao\ and\ Kidal",
  223219 => "Tombouctou",
  223442 => "Bamako",
  223443 => "Bamako",
  223449 => "Bamako",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+223|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;