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
package Number::Phone::StubCountry::SO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'pattern' => '(\\d{6})',
                  'leading_digits' => '[134]'
                },
                {
                  'pattern' => '(\\d)(\\d{6})',
                  'leading_digits' => '
            2[0-79]|
            [13-5]
          '
                },
                {
                  'leading_digits' => '
            24|
            [67]
          ',
                  'pattern' => '(\\d)(\\d{7})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{4})',
                  'leading_digits' => '8[125]'
                },
                {
                  'leading_digits' => '
            15|
            28|
            6[1-35-9]|
            799|
            9[2-9]
          ',
                  'pattern' => '(\\d{2})(\\d{5,7})'
                },
                {
                  'leading_digits' => '
            3[59]|
            4[89]|
            6[24-6]|
            79|
            8[08]|
            90
          ',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'pager' => '',
                'voip' => '',
                'fixed_line' => '
          (?:
            1\\d{1,2}|
            2[0-79]\\d|
            3[0-46-8]?\\d|
            4[0-7]?\\d|
            59\\d|
            8[125]
          )\\d{4}
        ',
                'mobile' => '
          (?:
            15\\d|
            2(?:
              4\\d|
              8
            )|
            3[59]\\d{2}|
            4[89]\\d{2}|
            6[1-9]?\\d{2}|
            7(?:
             [1-8]\\d|
             9\\d{1,2}
            )|
            8[08]\\d{2}|
            9(?:
              0[67]|
              [2-9]
            )\\d
          )\\d{5}
        ',
                'specialrate' => '',
                'geographic' => '
          (?:
            1\\d{1,2}|
            2[0-79]\\d|
            3[0-46-8]?\\d|
            4[0-7]?\\d|
            59\\d|
            8[125]
          )\\d{4}
        ',
                'personal_number' => '',
                'toll_free' => ''
              };
my %areanames = (
  2521 => "Mogadishu",
  2523 => "Hargeisa",
  2524 => "Garowe",
  25251 => "Mangauno",
  25261 => "Mogadishu",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+252|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;