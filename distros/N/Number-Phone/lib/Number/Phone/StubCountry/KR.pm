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
package Number::Phone::StubCountry::KR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180410221547;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{3,4})',
                  'format' => '$1-$2',
                  'leading_digits' => '
            (?:
              3[1-3]|
              [46][1-4]|
              5[1-5]
            )1
          ',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '(\\d{4})(\\d{4})',
                  'format' => '$1-$2',
                  'leading_digits' => '
            1(?:
              5(?:
                22|
                44|
                66|
                77|
                88|
                99
              )|
              6(?:
                [07]0|
                44|
                6[16]|
                88
              )|
              8(?:
                00|
                33|
                55|
                77|
                99
              )
            )
          ',
                  'national_rule' => '$1'
                },
                {
                  'pattern' => '(\\d{5})',
                  'format' => '$1',
                  'leading_digits' => '1[016-9]114',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '(\\d)(\\d{3,4})(\\d{4})',
                  'format' => '$1-$2-$3',
                  'national_rule' => '0$1',
                  'leading_digits' => '2[1-9]'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})',
                  'leading_digits' => '
            60[2-9]|
            80
          ',
                  'national_rule' => '0$1',
                  'format' => '$1-$2-$3'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3,4})(\\d{4})',
                  'format' => '$1-$2-$3',
                  'national_rule' => '0$1',
                  'leading_digits' => '
            1[0-25-9]|
            (?:
              3[1-3]|
              [46][1-4]|
              5[1-5]
            )[1-9]
          '
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '[57]0',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'intl_format' => 'NA',
                  'leading_digits' => '00308',
                  'national_rule' => '$1',
                  'pattern' => '(\\d{5})(\\d{3})(\\d{3})'
                },
                {
                  'pattern' => '(\\d{5})(\\d{3,4})(\\d{4})',
                  'format' => '$1 $2 $3',
                  'intl_format' => 'NA',
                  'leading_digits' => '
            00(?:
              36|
              79
            )8
          ',
                  'national_rule' => '$1'
                },
                {
                  'pattern' => '(\\d{5})(\\d{2})(\\d{3})(\\d{4})',
                  'intl_format' => 'NA',
                  'format' => '$1 $2 $3 $4',
                  'national_rule' => '$1',
                  'leading_digits' => '00798'
                }
              ];

my $validators = {
                'personal_number' => '50\\d{8}',
                'pager' => '15\\d{7,8}',
                'specialrate' => '(60[2-9]\\d{6})|(
          1(?:
            5(?:
              22|
              44|
              66|
              77|
              88|
              99
            )|
            6(?:
              00|
              44|
              6[16]|
              70|
              88
            )|
            8(?:
              00|
              33|
              55|
              77|
              99
            )
          )\\d{4}
        )',
                'mobile' => '1[0-26-9]\\d{7,8}',
                'geographic' => '
          2[1-9]\\d{6,7}|
          (?:
            3[1-3]|
            [46][1-4]|
            5[1-5]
          )(?:
            1\\d{2,3}|
            [1-9]\\d{6,7}
          )
        ',
                'voip' => '70\\d{8}',
                'toll_free' => '
          (?:
            00(?:
              3(?:
                08|
                68\\d
              )|
              798\\d{1,3}
            )|
            80\\d
          )\\d{6}
        ',
                'fixed_line' => '
          2[1-9]\\d{6,7}|
          (?:
            3[1-3]|
            [46][1-4]|
            5[1-5]
          )(?:
            1\\d{2,3}|
            [1-9]\\d{6,7}
          )
        '
              };
my %areanames = (
  822 => "Seoul",
  8231 => "Gyeonggi",
  8232 => "Incheon",
  8233 => "Gangwon",
  8241 => "Chungnam",
  8242 => "Daejeon",
  8243 => "Chungbuk",
  8244 => "Sejong\ City",
  8251 => "Busan",
  8252 => "Ulsan",
  8253 => "Daegu",
  8254 => "Gyeongbuk",
  8255 => "Gyeongnam",
  8261 => "Jeonnam",
  8262 => "Gwangju",
  8263 => "Jeonbuk",
  8264 => "Jeju",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+82|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0(8[1-46-8]|85\d{2})?)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;