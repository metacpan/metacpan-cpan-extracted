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
package Number::Phone::StubCountry::TW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180410221547;

my $formatters = [
                {
                  'leading_digits' => '202',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'pattern' => '(20)(\\d)(\\d{4})'
                },
                {
                  'pattern' => '([258]0)(\\d{3})(\\d{4})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            20[013-9]|
            50[0-46-9]|
            80[0-79]
          ',
                  'national_rule' => '0$1'
                },
                {
                  'national_rule' => '0$1',
                  'leading_digits' => '
            [25][2-8]|
            [346]|
            [78][1-9]
          ',
                  'format' => '$1 $2 $3',
                  'pattern' => '([2-8])(\\d{3,4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(9\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'pattern' => '(70)(\\d{4})(\\d{4})',
                  'national_rule' => '0$1',
                  'leading_digits' => '70',
                  'format' => '$1 $2 $3'
                }
              ];

my $validators = {
                'personal_number' => '99\\d{7}',
                'pager' => '',
                'specialrate' => '(
          20(?:
            2|
            [013-9]\\d{2}
          )\\d{4}
        )|(50[0-46-9]\\d{6})',
                'mobile' => '9[0-8]\\d{7}',
                'geographic' => '
          (?:
            2(?:
              [235-8]\\d{3}|
              4\\d{2,3}
            )|
            3[2-9]\\d{2}|
            4(?:
              [239]\\d|
              [78]
            )\\d{2}|
            5[2-8]\\d{2}|
            6[235-79]\\d{2}|
            7[1-9]\\d{2}|
            8(?:
              2(?:
                3\\d|
                66
              )|
              [7-9]\\d{2}
            )
          )\\d{4}
        ',
                'voip' => '70\\d{8}',
                'toll_free' => '80[0-79]\\d{6}',
                'fixed_line' => '
          (?:
            2(?:
              [235-8]\\d{3}|
              4\\d{2,3}
            )|
            3[2-9]\\d{2}|
            4(?:
              [239]\\d|
              [78]
            )\\d{2}|
            5[2-8]\\d{2}|
            6[235-79]\\d{2}|
            7[1-9]\\d{2}|
            8(?:
              2(?:
                3\\d|
                66
              )|
              [7-9]\\d{2}
            )
          )\\d{4}
        '
              };
my %areanames = (
  8862 => "Taipei",
  8863 => "Taoyuan\/Hsinchu\/Yilan\/Hualien",
  88637 => "Miaoli",
  8864 => "Taichung\/Changhua",
  88649 => "Nantou",
  8865 => "Chiayi\/Yunlin",
  8866 => "Tainan\/Penghu",
  8867 => "Kaohsiung",
  8868 => "Pingtung",
  88682 => "Kinmen",
  886826 => "Wuqiu",
  886836 => "Matsu",
  88689 => "Taitung",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+886|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;