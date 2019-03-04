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
package Number::Phone::StubCountry::RS;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190303205540;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3,9})',
                  'leading_digits' => '
            (?:
              2[389]|
              39
            )0|
            [7-9]
          ',
                  'format' => '$1 $2'
                },
                {
                  'national_rule' => '0$1',
                  'leading_digits' => '[1-36]',
                  'format' => '$1 $2',
                  'pattern' => '(\\d{2})(\\d{5,10})'
                }
              ];

my $validators = {
                'voip' => '',
                'specialrate' => '(
          (?:
            78\\d|
            90[0169]
          )\\d{3,7}
        )|(7[06]\\d{4,10})',
                'mobile' => '
          6(?:
            [0-689]|
            7\\d
          )\\d{6,7}
        ',
                'geographic' => '
          (?:
            11[1-9]\\d|
            (?:
              2[389]|
              39
            )(?:
              0[2-9]|
              [2-9]\\d
            )
          )\\d{3,8}|
          (?:
            1[02-9]|
            2[0-24-7]|
            3[0-8]
          )[2-9]\\d{4,9}
        ',
                'pager' => '',
                'personal_number' => '',
                'toll_free' => '800\\d{3,9}',
                'fixed_line' => '
          (?:
            11[1-9]\\d|
            (?:
              2[389]|
              39
            )(?:
              0[2-9]|
              [2-9]\\d
            )
          )\\d{3,8}|
          (?:
            1[02-9]|
            2[0-24-7]|
            3[0-8]
          )[2-9]\\d{4,9}
        '
              };
my %areanames = (
  38110 => "Pirot",
  38111 => "Belgrade",
  38112 => "Pozarevac",
  38113 => "Pancevo",
  38114 => "Valjevo",
  38115 => "Sabac",
  38116 => "Leskovac",
  38117 => "Vranje",
  38118 => "Nis",
  38119 => "Zajecar",
  38120 => "Novi\ Pazar",
  38121 => "Novi\ Sad",
  38122 => "Sremska\ Mitrovica",
  38123 => "Zrenjanin",
  381230 => "Kikinda",
  38124 => "Subotica",
  38125 => "Sombor",
  38126 => "Smederevo",
  38127 => "Prokuplje",
  38128 => "Kosovska\ Mitrovica",
  381280 => "Gnjilane",
  38129 => "Prizren",
  381290 => "Urosevac",
  38130 => "Bor",
  38131 => "Uzice",
  38132 => "Cacak",
  38133 => "Prijepolje",
  38134 => "Kragujevac",
  38135 => "Jagodina",
  38136 => "Kraljevo",
  38137 => "Krusevac",
  38138 => "Pristina",
  38139 => "Pec",
  381390 => "Dakovica",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+381|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;