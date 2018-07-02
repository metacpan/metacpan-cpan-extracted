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
package Number::Phone::StubCountry::SK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180619214157;

my $formatters = [
                {
                  'pattern' => '(2)(1[67])(\\d{3,4})',
                  'leading_digits' => '21[67]',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3'
                },
                {
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'leading_digits' => '[3-5]',
                  'pattern' => '([3-5]\\d)(\\d{2})(\\d{2,3})'
                },
                {
                  'pattern' => '(2)(\\d{3})(\\d{3})(\\d{2})',
                  'format' => '$1/$2 $3 $4',
                  'national_rule' => '0$1',
                  'leading_digits' => '2'
                },
                {
                  'pattern' => '([3-5]\\d)(\\d{3})(\\d{2})(\\d{2})',
                  'leading_digits' => '[3-5]',
                  'format' => '$1/$2 $3 $4',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '([689]\\d{2})(\\d{3})(\\d{3})',
                  'leading_digits' => '[689]',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '(9090)(\\d{3})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2',
                  'leading_digits' => '9090'
                }
              ];

my $validators = {
                'geographic' => '
          2(?:
            1(?:
              6\\d{3,4}|
              7\\d{3}
            )|
            [2-9]\\d{7}
          )|
          [3-5][1-8](?:
            1(?:
              6\\d{2,3}|
              7\\d{3}
            )|
            \\d{7}
          )
        ',
                'pager' => '9090\\d{3}',
                'toll_free' => '800\\d{6}',
                'fixed_line' => '
          2(?:
            1(?:
              6\\d{3,4}|
              7\\d{3}
            )|
            [2-9]\\d{7}
          )|
          [3-5][1-8](?:
            1(?:
              6\\d{2,3}|
              7\\d{3}
            )|
            \\d{7}
          )
        ',
                'voip' => '
          6(?:
            02|
            5[0-4]|
            9[0-6]
          )\\d{6}
        ',
                'personal_number' => '',
                'mobile' => '
          9(?:
            0(?:
              [1-8]\\d|
              9[1-9]
            )|
            (?:
              1[0-24-9]|
              [45]\\d
            )\\d
          )\\d{5}
        ',
                'specialrate' => '(8[5-9]\\d{7})|(
          9(?:
            [78]\\d{7}|
            00\\d{6}
          )
        )|(96\\d{7})'
              };
my %areanames = (
  4212 => "Bratislava",
  42131 => "Dunajská\ Streda",
  42132 => "Trenčín",
  42133 => "Trnava",
  42134 => "Senica",
  42135 => "Nové\ Zámky",
  42136 => "Levice",
  42137 => "Nitra",
  42138 => "Topoľčany",
  42141 => "Žilina",
  42142 => "Považská\ Bystrica",
  42143 => "Martin",
  42144 => "Liptovský\ Mikuláš",
  42145 => "Zvolen",
  42146 => "Prievidza",
  42147 => "Lučenec",
  42148 => "Banská\ Bystrica",
  42151 => "Prešov",
  42152 => "Poprad",
  42153 => "Spišská\ Nová\ Ves",
  42154 => "Bardejov",
  42155 => "Košice",
  42156 => "Michalovce",
  42157 => "Humenné",
  42158 => "Rožňava",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+421|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;