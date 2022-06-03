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
our $VERSION = 1.20220601185319;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            18|
            [2-69]|
            85
          ',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[78]',
                  'pattern' => '(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            (?:
              3[0-2]|
              4[257]|
              5[34]|
              9[78]
            )\\d|
            64[1-9]|
            85[02-46-9]
          )\\d{4}
        ',
                'geographic' => '
          (?:
            (?:
              3[0-2]|
              4[257]|
              5[34]|
              9[78]
            )\\d|
            64[1-9]|
            85[02-46-9]
          )\\d{4}
        ',
                'mobile' => '
          (?:
            7\\d|
            8[128]
          )\\d{6}
        ',
                'pager' => '27[01]\\d{4}',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '180\\d{4}',
                'voip' => '
          2(?:
            0[0-47]|
            7[568]
          )\\d{4}
        '
              };
my %areanames = ();
$areanames{en} = {"67545", "Sepik",
"6756", "MP\/Gulf\/Tabubil\/Kiunga",
"67547", "Morobe",
"67542", "Madang",
"6753", "NCD",
"6759", "Islands",
"6755", "Highlands",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+675|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;