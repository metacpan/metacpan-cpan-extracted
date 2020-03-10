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
our $VERSION = 1.20200309202349;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '202',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d)(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[258]0',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [23568]|
            4(?:
              0[2-48]|
              [1-47-9]
            )|
            (?:
              400|
              7
            )[1-9]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3,4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[49]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '7',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4,5})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2[2-8]\\d|
            370|
            55[01]|
            7[1-9]
          )\\d{6}|
          4(?:
            (?:
              0(?:
                0[1-9]|
                [2-48]\\d
              )|
              1[023]\\d
            )\\d{4,5}|
            (?:
              [239]\\d\\d|
              4(?:
                0[56]|
                12|
                49
              )
            )\\d{5}
          )|
          6(?:
            [01]\\d{7}|
            4(?:
              0[56]|
              12|
              24|
              4[09]
            )\\d{4,5}
          )|
          8(?:
            (?:
              2(?:
                3\\d|
                4[0-269]|
                [578]0|
                66
              )|
              36[24-9]|
              90\\d\\d
            )\\d{4}|
            4(?:
              0[56]|
              12|
              24|
              4[09]
            )\\d{4,5}
          )|
          (?:
            2(?:
              2(?:
                0\\d\\d|
                4(?:
                  0[68]|
                  [249]0|
                  3[0-467]|
                  5[0-25-9]|
                  6[0235689]
                )
              )|
              (?:
                3(?:
                  [09]\\d|
                  1[0-4]
                )|
                (?:
                  4\\d|
                  5[0-49]|
                  6[0-29]|
                  7[0-5]
                )\\d
              )\\d
            )|
            (?:
              (?:
                3[2-9]|
                5[2-8]|
                6[0-35-79]|
                8[7-9]
              )\\d\\d|
              4(?:
                2(?:
                  [089]\\d|
                  7[1-9]
                )|
                (?:
                  3[0-4]|
                  [78]\\d|
                  9[01]
                )\\d
              )
            )\\d
          )\\d{3}
        ',
                'geographic' => '
          (?:
            2[2-8]\\d|
            370|
            55[01]|
            7[1-9]
          )\\d{6}|
          4(?:
            (?:
              0(?:
                0[1-9]|
                [2-48]\\d
              )|
              1[023]\\d
            )\\d{4,5}|
            (?:
              [239]\\d\\d|
              4(?:
                0[56]|
                12|
                49
              )
            )\\d{5}
          )|
          6(?:
            [01]\\d{7}|
            4(?:
              0[56]|
              12|
              24|
              4[09]
            )\\d{4,5}
          )|
          8(?:
            (?:
              2(?:
                3\\d|
                4[0-269]|
                [578]0|
                66
              )|
              36[24-9]|
              90\\d\\d
            )\\d{4}|
            4(?:
              0[56]|
              12|
              24|
              4[09]
            )\\d{4,5}
          )|
          (?:
            2(?:
              2(?:
                0\\d\\d|
                4(?:
                  0[68]|
                  [249]0|
                  3[0-467]|
                  5[0-25-9]|
                  6[0235689]
                )
              )|
              (?:
                3(?:
                  [09]\\d|
                  1[0-4]
                )|
                (?:
                  4\\d|
                  5[0-49]|
                  6[0-29]|
                  7[0-5]
                )\\d
              )\\d
            )|
            (?:
              (?:
                3[2-9]|
                5[2-8]|
                6[0-35-79]|
                8[7-9]
              )\\d\\d|
              4(?:
                2(?:
                  [089]\\d|
                  7[1-9]
                )|
                (?:
                  3[0-4]|
                  [78]\\d|
                  9[01]
                )\\d
              )
            )\\d
          )\\d{3}
        ',
                'mobile' => '
          (?:
            40001[0-2]|
            9[0-8]\\d{4}
          )\\d{3}
        ',
                'pager' => '',
                'personal_number' => '99\\d{7}',
                'specialrate' => '(
          20(?:
            [013-9]\\d\\d|
            2
          )\\d{4}
        )|(50[0-46-9]\\d{6})',
                'toll_free' => '
          80[0-79]\\d{6}|
          800\\d{5}
        ',
                'voip' => '
          7010(?:
            [0-2679]\\d|
            3[0-7]|
            8[0-5]
          )\\d{5}|
          70\\d{8}
        '
              };
my %areanames = ();
$areanames{zh}->{8862} = "台北";
$areanames{zh}->{8863} = "桃园\、新竹\、花莲\、宜兰";
$areanames{zh}->{88637} = "苗栗";
$areanames{zh}->{8864001} = "台中\、彰化";
$areanames{zh}->{8864002} = "台中\、彰化";
$areanames{zh}->{8864003} = "台中\、彰化";
$areanames{zh}->{8864004} = "台中\、彰化";
$areanames{zh}->{8864005} = "台中\、彰化";
$areanames{zh}->{8864006} = "台中\、彰化";
$areanames{zh}->{8864007} = "台中\、彰化";
$areanames{zh}->{8864008} = "台中\、彰化";
$areanames{zh}->{8864009} = "台中\、彰化";
$areanames{zh}->{886402} = "台中\、彰化";
$areanames{zh}->{886403} = "台中\、彰化";
$areanames{zh}->{886404} = "台中\、彰化";
$areanames{zh}->{886408} = "台中\、彰化";
$areanames{zh}->{88641} = "台中\、彰化";
$areanames{zh}->{88642} = "台中\、彰化";
$areanames{zh}->{88643} = "台中\、彰化";
$areanames{zh}->{88644} = "台中\、彰化";
$areanames{zh}->{88647} = "台中\、彰化";
$areanames{zh}->{88648} = "台中\、彰化";
$areanames{zh}->{88649} = "南投";
$areanames{zh}->{88652} = "嘉义\、云林";
$areanames{zh}->{88653} = "嘉义\、云林";
$areanames{zh}->{88654} = "嘉义\、云林";
$areanames{zh}->{88655} = "嘉义\、云林";
$areanames{zh}->{88656} = "嘉义\、云林";
$areanames{zh}->{88657} = "嘉义\、云林";
$areanames{zh}->{88658} = "嘉义\、云林";
$areanames{zh}->{8866} = "台南\、澎湖";
$areanames{zh}->{88671} = "高雄";
$areanames{zh}->{88672} = "高雄";
$areanames{zh}->{88673} = "高雄";
$areanames{zh}->{88674} = "高雄";
$areanames{zh}->{88675} = "高雄";
$areanames{zh}->{88676} = "高雄";
$areanames{zh}->{88677} = "高雄";
$areanames{zh}->{88678} = "高雄";
$areanames{zh}->{88679} = "高雄";
$areanames{zh}->{88680} = "屏东";
$areanames{zh}->{886823} = "金门";
$areanames{zh}->{8868230} = "屏东";
$areanames{zh}->{886824} = "金门";
$areanames{zh}->{886825} = "金门";
$areanames{zh}->{886826} = "乌丘";
$areanames{zh}->{886827} = "金门";
$areanames{zh}->{886828} = "金门";
$areanames{zh}->{88683} = "马祖";
$areanames{zh}->{88684} = "屏东";
$areanames{zh}->{88687} = "屏东";
$areanames{zh}->{88688} = "屏东";
$areanames{zh}->{88689} = "台东";
$areanames{en}->{8862} = "Taipei";
$areanames{en}->{8863} = "Taoyuan\/Hsinchu\/Yilan\/Hualien";
$areanames{en}->{88637} = "Miaoli";
$areanames{en}->{8864001} = "Taichung\/Changhua";
$areanames{en}->{8864002} = "Taichung\/Changhua";
$areanames{en}->{8864003} = "Taichung\/Changhua";
$areanames{en}->{8864004} = "Taichung\/Changhua";
$areanames{en}->{8864005} = "Taichung\/Changhua";
$areanames{en}->{8864006} = "Taichung\/Changhua";
$areanames{en}->{8864007} = "Taichung\/Changhua";
$areanames{en}->{8864008} = "Taichung\/Changhua";
$areanames{en}->{8864009} = "Taichung\/Changhua";
$areanames{en}->{886402} = "Taichung\/Changhua";
$areanames{en}->{886403} = "Taichung\/Changhua";
$areanames{en}->{886404} = "Taichung\/Changhua";
$areanames{en}->{886408} = "Taichung\/Changhua";
$areanames{en}->{88641} = "Taichung\/Changhua";
$areanames{en}->{88642} = "Taichung\/Changhua";
$areanames{en}->{88643} = "Taichung\/Changhua";
$areanames{en}->{88644} = "Taichung\/Changhua";
$areanames{en}->{88647} = "Taichung\/Changhua";
$areanames{en}->{88648} = "Taichung\/Changhua";
$areanames{en}->{88649} = "Nantou";
$areanames{en}->{88652} = "Chiayi\/Yunlin";
$areanames{en}->{88653} = "Chiayi\/Yunlin";
$areanames{en}->{88654} = "Chiayi\/Yunlin";
$areanames{en}->{88655} = "Chiayi\/Yunlin";
$areanames{en}->{88656} = "Chiayi\/Yunlin";
$areanames{en}->{88657} = "Chiayi\/Yunlin";
$areanames{en}->{88658} = "Chiayi\/Yunlin";
$areanames{en}->{8866} = "Tainan\/Penghu";
$areanames{en}->{88671} = "Kaohsiung";
$areanames{en}->{88672} = "Kaohsiung";
$areanames{en}->{88673} = "Kaohsiung";
$areanames{en}->{88674} = "Kaohsiung";
$areanames{en}->{88675} = "Kaohsiung";
$areanames{en}->{88676} = "Kaohsiung";
$areanames{en}->{88677} = "Kaohsiung";
$areanames{en}->{88678} = "Kaohsiung";
$areanames{en}->{88679} = "Kaohsiung";
$areanames{en}->{88680} = "Pingtung";
$areanames{en}->{886823} = "Kinmen";
$areanames{en}->{886824} = "Kinmen";
$areanames{en}->{886825} = "Kinmen";
$areanames{en}->{886826} = "Wuqiu";
$areanames{en}->{886827} = "Kinmen";
$areanames{en}->{886828} = "Kinmen";
$areanames{en}->{88683} = "Matsu";
$areanames{en}->{88684} = "Pingtung";
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