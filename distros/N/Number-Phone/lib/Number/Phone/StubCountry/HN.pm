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
package Number::Phone::StubCountry::HN;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170702164948;

my $formatters = [
                {
                  'pattern' => '(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'toll_free' => '',
                'pager' => '',
                'voip' => '',
                'mobile' => '[37-9]\\d{7}',
                'fixed_line' => '
          2(?:
            2(?:
              0[019]|
              1[1-36]|
              [23]\\d|
              4[04-6]|
              5[57]|
              7[01389]|
              8[0146-9]|
              9[012]
            )|
            4(?:
              07|
              2[3-59]|
              3[13-689]|
              4[0-68]|
              5[1-35]
            )|
            5(?:
              16|
              4[03-5]|
              5\\d|
              6[4-6]|
              74
            )|
            6(?:
              [056]\\d|
              17|
              3[04]|
              4[0-378]|
              [78][0-8]|
              9[01]
            )|
            7(?:
              6[46-9]|
              7[02-9]|
              8[034]
            )|
            8(?:
              79|
              8[0-35789]|
              9[1-57-9]
            )
          )\\d{4}
        ',
                'personal_number' => '',
                'specialrate' => '',
                'geographic' => '
          2(?:
            2(?:
              0[019]|
              1[1-36]|
              [23]\\d|
              4[04-6]|
              5[57]|
              7[01389]|
              8[0146-9]|
              9[012]
            )|
            4(?:
              07|
              2[3-59]|
              3[13-689]|
              4[0-68]|
              5[1-35]
            )|
            5(?:
              16|
              4[03-5]|
              5\\d|
              6[4-6]|
              74
            )|
            6(?:
              [056]\\d|
              17|
              3[04]|
              4[0-378]|
              [78][0-8]|
              9[01]
            )|
            7(?:
              6[46-9]|
              7[02-9]|
              8[034]
            )|
            8(?:
              79|
              8[0-35789]|
              9[1-57-9]
            )
          )\\d{4}
        '
              };
my %areanames = (
  5042244 => "Tegucigalpa",
  5042407 => "Roatan\,\ Bay\ Islands",
  5042516 => "San\ Pedro\ Sula\,\ Cortés",
  5042540 => "San\ Pedro\ Sula\,\ Cortés",
  5042564 => "San\ Pedro\ Sula\,\ Cortés",
  5042617 => "Choloma\,\ Cortés",
  5042780 => "Choluteca",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+504|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;