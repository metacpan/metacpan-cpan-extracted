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
package Number::Phone::StubCountry::CW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190303205538;

my $formatters = [
                {
                  'leading_digits' => '[3467]',
                  'format' => '$1 $2',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9[4-8]',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'voip' => '',
                'specialrate' => '(60[0-2]\\d{4})',
                'pager' => '955\\d{5}',
                'geographic' => '
          9(?:
            4(?:
              3[0-5]|
              4[14]|
              6\\d
            )|
            50\\d|
            7(?:
              2[014]|
              3[02-9]|
              4[4-9]|
              6[357]|
              77|
              8[7-9]
            )|
            8(?:
              3[39]|
              [46]\\d|
              7[01]|
              8[57-9]
            )
          )\\d{4}
        ',
                'mobile' => '
          953[01]\\d{4}|
          9(?:
            5[12467]|
            6[5-9]
          )\\d{5}
        ',
                'personal_number' => '',
                'toll_free' => '',
                'fixed_line' => '
          9(?:
            4(?:
              3[0-5]|
              4[14]|
              6\\d
            )|
            50\\d|
            7(?:
              2[014]|
              3[02-9]|
              4[4-9]|
              6[357]|
              77|
              8[7-9]
            )|
            8(?:
              3[39]|
              [46]\\d|
              7[01]|
              8[57-9]
            )
          )\\d{4}
        '
              };
my %areanames = (
  599318 => "St\.\ Eustatius",
  599416 => "Saba",
  59971 => "Bonaire",
  59975 => "Bonaire",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+599|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;