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
package Number::Phone::StubCountry::LB;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220601185319;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [13-69]|
            7(?:
              [2-57]|
              62|
              8[0-7]|
              9[04-9]
            )|
            8[02-9]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[27-9]',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          7(?:
            62|
            8[0-7]|
            9[04-9]
          )\\d{4}|
          (?:
            [14-69]\\d|
            2(?:
              [14-69]\\d|
              [78][1-9]
            )|
            7[2-57]|
            8[02-9]
          )\\d{5}
        ',
                'geographic' => '
          7(?:
            62|
            8[0-7]|
            9[04-9]
          )\\d{4}|
          (?:
            [14-69]\\d|
            2(?:
              [14-69]\\d|
              [78][1-9]
            )|
            7[2-57]|
            8[02-9]
          )\\d{5}
        ',
                'mobile' => '
          793(?:
            [01]\\d|
            2[0-4]
          )\\d{3}|
          (?:
            (?:
              3|
              81
            )\\d|
            7(?:
              [01]\\d|
              6[013-9]|
              8[89]|
              9[12]
            )
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(80\\d{6})|(9[01]\\d{6})',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"96121", "Beirut",
"96129", "Jbeil\ \&\ Keserwan",
"96128", "Bekaa",
"96126", "North\ Lebanon",
"96124", "Metn",
"96127", "South\ Lebanon",
"96125", "Chouf",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+961|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;