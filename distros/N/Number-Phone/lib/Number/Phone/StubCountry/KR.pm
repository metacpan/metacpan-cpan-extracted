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
our $VERSION = 1.20200511123714;

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
              9[0-5]
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
$areanames{ko}->{822} = "서울";
$areanames{ko}->{8231} = "경기";
$areanames{ko}->{8232} = "인천";
$areanames{ko}->{8233} = "강원";
$areanames{ko}->{8241} = "충남";
$areanames{ko}->{8242} = "대전";
$areanames{ko}->{8243} = "충북";
$areanames{ko}->{8244} = "세종";
$areanames{ko}->{8251} = "부산";
$areanames{ko}->{8252} = "울산";
$areanames{ko}->{8253} = "대구";
$areanames{ko}->{8254} = "경북";
$areanames{ko}->{8255} = "경남";
$areanames{ko}->{8261} = "전남";
$areanames{ko}->{8262} = "광주";
$areanames{ko}->{8263} = "전북";
$areanames{ko}->{8264} = "제주";
$areanames{en}->{822} = "Seoul";
$areanames{en}->{8231} = "Gyeonggi";
$areanames{en}->{8232} = "Incheon";
$areanames{en}->{8233} = "Gangwon";
$areanames{en}->{8241} = "Chungnam";
$areanames{en}->{8242} = "Daejeon";
$areanames{en}->{8243} = "Chungbuk";
$areanames{en}->{8244} = "Sejong\ City";
$areanames{en}->{8251} = "Busan";
$areanames{en}->{8252} = "Ulsan";
$areanames{en}->{8253} = "Daegu";
$areanames{en}->{8254} = "Gyeongbuk";
$areanames{en}->{8255} = "Gyeongnam";
$areanames{en}->{8261} = "Jeonnam";
$areanames{en}->{8262} = "Gwangju";
$areanames{en}->{8263} = "Jeonbuk";
$areanames{en}->{8264} = "Jeju";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+82|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0(8(?:[1-46-8]|5\d\d))?)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;