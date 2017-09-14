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
package Number::Phone::StubCountry::MU;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113148;

my $formatters = [
                {
                  'leading_digits' => '[2-46-9]',
                  'pattern' => '([2-46-9]\\d{2})(\\d{4})'
                },
                {
                  'pattern' => '(5\\d{3})(\\d{4})',
                  'leading_digits' => '5'
                }
              ];

my $validators = {
                'personal_number' => '',
                'geographic' => '
          (?:
            2(?:
              [03478]\\d|
              1[0-7]|
              6[1-69]
            )|
            4(?:
              [013568]\\d|
              2[4-7]
            )|
            5(?:
              44\\d|
              471
            )|
            6\\d{2}|
            8(?:
              14|
              3[129]
            )
          )\\d{4}
        ',
                'pager' => '',
                'toll_free' => '80[012]\\d{4}',
                'mobile' => '
          5(?:
            2[59]\\d|
            4(?:
              2[1-389]|
              4\\d|
              7[1-9]|
              9\\d
            )|
            7\\d{2}|
            8(?:
              [0-25689]\\d|
              4[3479]|
              7[15-8]
            )|
            9[0-8]\\d
          )\\d{4}
        ',
                'specialrate' => '(30\\d{5})',
                'fixed_line' => '
          (?:
            2(?:
              [03478]\\d|
              1[0-7]|
              6[1-69]
            )|
            4(?:
              [013568]\\d|
              2[4-7]
            )|
            5(?:
              44\\d|
              471
            )|
            6\\d{2}|
            8(?:
              14|
              3[129]
            )
          )\\d{4}
        ',
                'voip' => '
          3(?:
            20|
            9\\d
          )\\d{4}
        '
              };
my %areanames = (
  2302 => "North\ Region",
  2304 => "Central\ Region",
  2306 => "South\ Region",
  230814 => "Agalega",
  23083 => "Rodrigues",
  23087 => "Rodrigues",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+230|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;