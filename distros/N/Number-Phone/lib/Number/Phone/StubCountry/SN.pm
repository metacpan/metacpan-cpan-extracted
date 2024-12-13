# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::SN;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20241212130807;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[379]',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          3(?:
            0(?:
              1[0-2]|
              80
            )|
            282|
            3(?:
              8[1-9]|
              9[3-9]
            )|
            611
          )\\d{5}
        ',
                'geographic' => '
          3(?:
            0(?:
              1[0-2]|
              80
            )|
            282|
            3(?:
              8[1-9]|
              9[3-9]
            )|
            611
          )\\d{5}
        ',
                'mobile' => '
          7(?:
            (?:
              [06-8]\\d|
              [19]0|
              21
            )\\d|
            5(?:
              0[01]|
              [19]0|
              2[25]|
              3[36]|
              [4-7]\\d|
              8[35]
            )
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(81[02468]\\d{6})|(88[4689]\\d{6})',
                'toll_free' => '800\\d{6}',
                'voip' => '
          (?:
            3(?:
              392|
              9[01]\\d
            )\\d|
            93(?:
              3[13]0|
              929
            )
          )\\d{4}
        '
              };
my %areanames = ();
$areanames{en} = {"2213399", "Outside\ Dakar",
"2213394", "Outside\ Dakar",
"2213395", "Outside\ Dakar",
"221338", "Dakar",
"2213396", "Outside\ Dakar",
"2213398", "Outside\ Dakar",
"2213397", "Outside\ Dakar",
"2213393", "Outside\ Dakar",};
my $timezones = {
               '' => [
                       'Africa/Dakar'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+221|\D)//g;
      my $self = bless({ country_code => '221', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;