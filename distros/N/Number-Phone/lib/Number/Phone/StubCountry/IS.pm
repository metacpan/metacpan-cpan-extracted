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
package Number::Phone::StubCountry::IS;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113148;

my $formatters = [
                {
                  'leading_digits' => '[4-9]',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(3\\d{2})(\\d{3})(\\d{3})',
                  'leading_digits' => '3'
                }
              ];

my $validators = {
                'pager' => '',
                'geographic' => '
          (?:
            4(?:
              1[0-24-69]|
              2[0-7]|
              [37][0-8]|
              4[0-245]|
              5[0-68]|
              6\\d|
              8[0-36-8]
            )|
            5(?:
              05|
              [156]\\d|
              2[02578]|
              3[0-79]|
              4[03-7]|
              7[0-2578]|
              8[0-35-9]|
              9[013-689]
            )|
            87[23]
          )\\d{4}
        ',
                'personal_number' => '',
                'voip' => '49\\d{5}',
                'mobile' => '
          38[589]\\d{6}|
          (?:
            6(?:
              1[1-8]|
              2[0-6]|
              3[027-9]|
              4[014679]|
              5[0159]|
              [67][0-69]|
              9\\d
            )|
            7(?:
              5[057]|
              [6-8]\\d
            )|
            8(?:
              2[0-59]|
              3[0-4]|
              [469]\\d|
              5[1-9]|
              88
            )
          )\\d{4}
        ',
                'toll_free' => '800\\d{4}',
                'specialrate' => '(90\\d{5})|(809\\d{4})',
                'fixed_line' => '
          (?:
            4(?:
              1[0-24-69]|
              2[0-7]|
              [37][0-8]|
              4[0-245]|
              5[0-68]|
              6\\d|
              8[0-36-8]
            )|
            5(?:
              05|
              [156]\\d|
              2[02578]|
              3[0-79]|
              4[03-7]|
              7[0-2578]|
              8[0-35-9]|
              9[013-689]
            )|
            87[23]
          )\\d{4}
        '
              };
my %areanames = (
  354421 => "Keflavík",
  354462 => "Akureyri",
  354551 => "Reykjavík\/Vesturbær\/Miðbærinn",
  354552 => "Reykjavík\/Vesturbær\/Miðbærinn",
  354561 => "Reykjavík\/Vesturbær\/Miðbærinn",
  354562 => "Reykjavík\/Vesturbær\/Miðbærinn",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+354|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;