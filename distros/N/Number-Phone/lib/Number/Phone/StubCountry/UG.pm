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
package Number::Phone::StubCountry::UG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20181205223705;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{7})',
                  'format' => '$1 $2',
                  'leading_digits' => '
            3|
            4(?:
              [0-5]|
              6[0-36-9]
            )
          ',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '(\\d{4})(\\d{5})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2',
                  'leading_digits' => '2024'
                },
                {
                  'pattern' => '(\\d{3})(\\d{6})',
                  'leading_digits' => '[247-9]',
                  'format' => '$1 $2',
                  'national_rule' => '0$1'
                }
              ];

my $validators = {
                'geographic' => '
          (?:
            20(?:
              (?:
                (?:
                  [0147]\\d|
                  5[0-4]|
                  8[0-2]
                )\\d|
                2(?:
                  40|
                  [5-9]\\d
                )|
                3(?:
                  0[0-4]|
                  [2367]\\d
                )
              )\\d|
              6(?:
                00[0-2]|
                30[0-4]|
                [5-9]\\d\\d
              )
            )|
            [34]\\d{5}
          )\\d{3}
        ',
                'toll_free' => '800[1-3]\\d{5}',
                'fixed_line' => '
          (?:
            20(?:
              (?:
                (?:
                  [0147]\\d|
                  5[0-4]|
                  8[0-2]
                )\\d|
                2(?:
                  40|
                  [5-9]\\d
                )|
                3(?:
                  0[0-4]|
                  [2367]\\d
                )
              )\\d|
              6(?:
                00[0-2]|
                30[0-4]|
                [5-9]\\d\\d
              )
            )|
            [34]\\d{5}
          )\\d{3}
        ',
                'personal_number' => '',
                'specialrate' => '(90[1-3]\\d{6})',
                'mobile' => '
          7(?:
            (?:
              [0157-9]\\d|
              30|
              4[0-4]
            )\\d|
            2(?:
              [03]\\d|
              60
            )
          )\\d{5}
        ',
                'pager' => '',
                'voip' => ''
              };
my %areanames = (
  25641 => "Kampala",
  25643 => "Jinja",
  25645 => "Mbale",
  25646 => "Mityana",
  256464 => "Mubende",
  256465 => "Masindi",
  256471 => "Gulu",
  256473 => "Lira",
  256476 => "Arua",
  256481 => "Masaka",
  256483 => "Fort\ Portal",
  256485 => "Mbarara",
  256486 => "Kabale\/Rukungiri\/Kisoro",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+256|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;