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
package Number::Phone::StubCountry::BQ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210204173823;

my $formatters = [];

my $validators = {
                'fixed_line' => '
          (?:
            318[023]|
            41(?:
              6[023]|
              70
            )|
            7(?:
              1[578]|
              2[05]|
              50
            )\\d
          )\\d{3}
        ',
                'geographic' => '
          (?:
            318[023]|
            41(?:
              6[023]|
              70
            )|
            7(?:
              1[578]|
              2[05]|
              50
            )\\d
          )\\d{3}
        ',
                'mobile' => '
          (?:
            31(?:
              8[14-8]|
              9[14578]
            )|
            416[14-9]|
            7(?:
              0[01]|
              7[07]|
              8\\d|
              9[056]
            )\\d
          )\\d{3}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"5994162", "Saba",
"59971", "Bonaire",
"5993182", "St\.\ Eustatius",
"59975", "Bonaire",
"5993180", "St\.\ Eustatius",
"5993183", "St\.\ Eustatius",
"5994163", "Saba",
"59972", "Bonaire",
"599417", "Saba",
"5994160", "Saba",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+599|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;