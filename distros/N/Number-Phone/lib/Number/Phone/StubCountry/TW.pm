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
package Number::Phone::StubCountry::TW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20231210185946;

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
$areanames{zh} = {"886402", "台中\、彰化",
"88647", "台中\、彰化",
"886823", "金门",
"8864009", "台中\、彰化",
"88657", "嘉义\、云林",
"88676", "高雄",
"88680", "屏东",
"886825", "金门",
"88687", "屏东",
"8868230", "屏东",
"88655", "嘉义\、云林",
"8864008", "台中\、彰化",
"88671", "高雄",
"886824", "金门",
"88684", "屏东",
"886826", "乌丘",
"886828", "金门",
"8864003", "台中\、彰化",
"88672", "高雄",
"88654", "嘉义\、云林",
"88673", "高雄",
"88644", "台中\、彰化",
"8862", "台北",
"88689", "台东",
"8864004", "台中\、彰化",
"88678", "高雄",
"88649", "南投",
"88683", "马祖",
"88652", "嘉义\、云林",
"88642", "台中\、彰化",
"8864007", "台中\、彰化",
"88653", "嘉义\、云林",
"8866", "台南\、澎湖",
"8864001", "台中\、彰化",
"886403", "台中\、彰化",
"8864005", "台中\、彰化",
"88674", "高雄",
"88643", "台中\、彰化",
"88658", "嘉义\、云林",
"886404", "台中\、彰化",
"88648", "台中\、彰化",
"88688", "屏东",
"8864006", "台中\、彰化",
"88679", "高雄",
"8863", "桃园\、新竹\、花莲\、宜兰",
"88677", "高雄",
"88656", "嘉义\、云林",
"886408", "台中\、彰化",
"88637", "苗栗",
"886827", "金门",
"88675", "高雄",
"8864002", "台中\、彰化",
"88641", "台中\、彰化",};
$areanames{en} = {"88657", "Chiayi\/Yunlin",
"88647", "Taichung\/Changhua",
"886402", "Taichung\/Changhua",
"886823", "Kinmen",
"8864009", "Taichung\/Changhua",
"88680", "Pingtung",
"886825", "Kinmen",
"88687", "Pingtung",
"88676", "Kaohsiung",
"8864008", "Taichung\/Changhua",
"88655", "Chiayi\/Yunlin",
"88671", "Kaohsiung",
"886824", "Kinmen",
"886826", "Wuqiu",
"886828", "Kinmen",
"8864003", "Taichung\/Changhua",
"88672", "Kaohsiung",
"88684", "Pingtung",
"88644", "Taichung\/Changhua",
"88673", "Kaohsiung",
"8862", "Taipei",
"88654", "Chiayi\/Yunlin",
"88678", "Kaohsiung",
"88689", "Taitung",
"8864004", "Taichung\/Changhua",
"88649", "Nantou",
"88642", "Taichung\/Changhua",
"8864007", "Taichung\/Changhua",
"88683", "Matsu",
"88652", "Chiayi\/Yunlin",
"8864005", "Taichung\/Changhua",
"88674", "Kaohsiung",
"88643", "Taichung\/Changhua",
"88653", "Chiayi\/Yunlin",
"8866", "Tainan\/Penghu",
"8864001", "Taichung\/Changhua",
"886403", "Taichung\/Changhua",
"88648", "Taichung\/Changhua",
"88658", "Chiayi\/Yunlin",
"886404", "Taichung\/Changhua",
"8864006", "Taichung\/Changhua",
"88679", "Kaohsiung",
"88688", "Pingtung",
"8863", "Taoyuan\/Hsinchu\/Yilan\/Hualien",
"88677", "Kaohsiung",
"88656", "Chiayi\/Yunlin",
"886408", "Taichung\/Changhua",
"88675", "Kaohsiung",
"88637", "Miaoli",
"886827", "Kinmen",
"8864002", "Taichung\/Changhua",
"88641", "Taichung\/Changhua",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+886|\D)//g;
      my $self = bless({ country_code => '886', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '886', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;