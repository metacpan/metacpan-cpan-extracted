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
our $VERSION = 1.20190912215428;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '202',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d)(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [25][2-8]|
            [346]|
            7[1-9]|
            8[237-9]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3,4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[258]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '7',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          24\\d{6,7}|
          (?:
            6412|
            8(?:
              2(?:
                3\\d|
                66
              )|
              36[24-9]
            )
          )\\d{4}|
          (?:
            2[235-8]\\d|
            3[2-9]|
            4(?:
              [239]\\d|
              [78]
            )|
            5[2-8]|
            6[235-79]|
            7[1-9]|
            8[7-9]
          )\\d{6}
        ',
                'geographic' => '
          24\\d{6,7}|
          (?:
            6412|
            8(?:
              2(?:
                3\\d|
                66
              )|
              36[24-9]
            )
          )\\d{4}|
          (?:
            2[235-8]\\d|
            3[2-9]|
            4(?:
              [239]\\d|
              [78]
            )|
            5[2-8]|
            6[235-79]|
            7[1-9]|
            8[7-9]
          )\\d{6}
        ',
                'mobile' => '9[0-8]\\d{7}',
                'pager' => '',
                'personal_number' => '99\\d{7}',
                'specialrate' => '(
          20(?:
            [013-9]\\d\\d|
            2
          )\\d{4}
        )|(50[0-46-9]\\d{6})',
                'toll_free' => '80[0-79]\\d{6}',
                'voip' => '70\\d{8}'
              };
my %areanames = ();
$areanames{zh}->{8862} = "台北";
$areanames{zh}->{8863} = "桃园\、新竹\、花莲\、宜兰";
$areanames{zh}->{88637} = "苗栗";
$areanames{zh}->{88642} = "台中\、彰化";
$areanames{zh}->{88643} = "台中\、彰化";
$areanames{zh}->{88647} = "台中\、彰化";
$areanames{zh}->{88648} = "台中\、彰化";
$areanames{zh}->{88649} = "南投";
$areanames{zh}->{8865} = "嘉义\、云林";
$areanames{zh}->{8866} = "台南\、澎湖";
$areanames{zh}->{8867} = "高雄";
$areanames{zh}->{88680} = "屏东";
$areanames{zh}->{886823} = "金门";
$areanames{zh}->{886826} = "乌丘";
$areanames{zh}->{88683} = "马祖";
$areanames{zh}->{88687} = "屏东";
$areanames{zh}->{88688} = "屏东";
$areanames{zh}->{88689} = "台东";
$areanames{en}->{8862} = "Taipei";
$areanames{en}->{8863} = "Taoyuan\/Hsinchu\/Yilan\/Hualien";
$areanames{en}->{88637} = "Miaoli";
$areanames{en}->{88642} = "Taichung\/Changhua";
$areanames{en}->{88643} = "Taichung\/Changhua";
$areanames{en}->{88647} = "Taichung\/Changhua";
$areanames{en}->{88648} = "Taichung\/Changhua";
$areanames{en}->{88649} = "Nantou";
$areanames{en}->{8865} = "Chiayi\/Yunlin";
$areanames{en}->{8866} = "Tainan\/Penghu";
$areanames{en}->{8867} = "Kaohsiung";
$areanames{en}->{88680} = "Pingtung";
$areanames{en}->{886823} = "Kinmen";
$areanames{en}->{886826} = "Wuqiu";
$areanames{en}->{88683} = "Matsu";
$areanames{en}->{88687} = "Pingtung";
$areanames{en}->{88688} = "Pingtung";
$areanames{en}->{88689} = "Taitung";

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