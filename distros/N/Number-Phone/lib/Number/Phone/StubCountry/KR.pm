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
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'pattern' => '(\\d{5})(\\d{3,4})(\\d{4})',
                  'leading_digits' => '00798'
                },
                {
                  'leading_digits' => '00798',
                  'pattern' => '(\\d{5})(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})',
                  'leading_digits' => '
            1(?:
              0|
              1[19]|
              [69]9|
              5(?:
                44|
                59|
                8
              )
            )|
            [57]0
          '
                },
                {
                  'pattern' => '(\\d{2})(\\d{3,4})(\\d{4})',
                  'leading_digits' => '
            1(?:
              [01]|
              5(?:
                [1-3]|
                4[56]
              )|
              6[2-8]|
              [7-9]
            )|
            [68]0|
            [3-6][1-9][1-9]
          '
                },
                {
                  'leading_digits' => '1312',
                  'pattern' => '(\\d{3})(\\d)(\\d{4})'
                },
                {
                  'leading_digits' => '131[13-9]',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{4})'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})',
                  'leading_digits' => '13[2-9]'
                },
                {
                  'leading_digits' => '30',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(\\d)(\\d{3,4})(\\d{4})',
                  'leading_digits' => '2[1-9]'
                },
                {
                  'pattern' => '(\\d)(\\d{3,4})',
                  'leading_digits' => '21[0-46-9]'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3,4})',
                  'leading_digits' => '
            [3-6][1-9]1(?:
              [0-46-9]
            )
          '
                },
                {
                  'pattern' => '(\\d{4})(\\d{4})',
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
            )
          '
                }
              ];

my $validators = {
                'toll_free' => '
          (?:
            00798\\d{0,2}|
            80
          )\\d{7}
        ',
                'personal_number' => '50\\d{8}',
                'geographic' => '
          (?:
            2|
            3[1-3]|
            [46][1-4]|
            5[1-5]
          )(?:
            1\\d{2,3}|
            [1-9]\\d{6,7}
          )
        ',
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
                'fixed_line' => '
          (?:
            2|
            3[1-3]|
            [46][1-4]|
            5[1-5]
          )(?:
            1\\d{2,3}|
            [1-9]\\d{6,7}
          )
        ',
                'voip' => '70\\d{8}',
                'pager' => '15\\d{7,8}'
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
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;