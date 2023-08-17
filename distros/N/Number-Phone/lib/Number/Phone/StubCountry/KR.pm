# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20230614174403;

my $formatters = [
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '1[016-9]114',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{5})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '
            (?:
              3[1-3]|
              [46][1-4]|
              5[1-5]
            )1
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3,4})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '2',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3,4})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '
            60|
            8
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '
            [1346]|
            5[1-5]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3,4})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '[57]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'intl_format' => 'NA',
                  'leading_digits' => '0030',
                  'pattern' => '(\\d{5})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '5',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{5})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'intl_format' => 'NA',
                  'pattern' => '(\\d{5})(\\d{3,4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'intl_format' => 'NA',
                  'pattern' => '(\\d{5})(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2|
            3[1-3]|
            [46][1-4]|
            5[1-5]
          )[1-9]\\d{6,7}|
          (?:
            3[1-3]|
            [46][1-4]|
            5[1-5]
          )1\\d{2,3}
        ',
                'geographic' => '
          (?:
            2|
            3[1-3]|
            [46][1-4]|
            5[1-5]
          )[1-9]\\d{6,7}|
          (?:
            3[1-3]|
            [46][1-4]|
            5[1-5]
          )1\\d{2,3}
        ',
                'mobile' => '
          1(?:
            05(?:
              [0-8]\\d|
              9[0-6]
            )|
            22[13]\\d
          )\\d{4,5}|
          1(?:
            0[1-46-9]|
            [16-9]\\d|
            2[013-9]
          )\\d{6,7}
        ',
                'pager' => '15\\d{7,8}',
                'personal_number' => '50\\d{8,9}',
                'specialrate' => '(60[2-9]\\d{6})|(
          1(?:
            5(?:
              22|
              33|
              44|
              66|
              77|
              88|
              99
            )|
            6(?:
              [07]0|
              44|
              6[168]|
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
                'toll_free' => '
          00(?:
            308\\d{6,7}|
            798\\d{7,9}
          )|
          (?:
            00368|
            80
          )\\d{7}
        ',
                'voip' => '70\\d{8}'
              };
my %areanames = ();
$areanames{ko} = {"8232", "인천",
"8263", "전북",
"8255", "경남",
"8231", "경기",
"8243", "충북",
"8253", "대구",
"822", "서울",
"8261", "전남",
"8242", "대전",
"8254", "경북",
"8241", "충남",
"8262", "광주",
"8233", "강원",
"8264", "제주",
"8251", "부산",
"8252", "울산",
"8244", "세종",};
$areanames{en} = {"8255", "Gyeongnam",
"8263", "Jeonbuk",
"8232", "Incheon",
"8243", "Chungbuk",
"8231", "Gyeonggi",
"822", "Seoul",
"8253", "Daegu",
"8254", "Gyeongbuk",
"8261", "Jeonnam",
"8242", "Daejeon",
"8233", "Gangwon",
"8262", "Gwangju",
"8241", "Chungnam",
"8251", "Busan",
"8264", "Jeju",
"8244", "Sejong\ City",
"8252", "Ulsan",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+82|\D)//g;
      my $self = bless({ country_code => '82', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0(8(?:[1-46-8]|5\d\d))?)//;
      $self = bless({ country_code => '82', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;