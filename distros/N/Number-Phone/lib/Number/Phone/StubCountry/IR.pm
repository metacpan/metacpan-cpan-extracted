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
package Number::Phone::StubCountry::IR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120030;

my $formatters = [
                {
                  'format' => '$1',
                  'leading_digits' => '96',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4,5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            (?:
              1[137]|
              2[13-68]|
              3[1458]|
              4[145]|
              5[1468]|
              6[16]|
              7[1467]|
              8[13467]
            )[12689]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4,5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[1-8]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1[137]|
            2[13-68]|
            3[1458]|
            4[145]|
            5[1468]|
            6[16]|
            7[1467]|
            8[13467]
          )(?:
            [03-57]\\d{7}|
            [16]\\d{3}(?:
              \\d{4}
            )?|
            [289]\\d{3}(?:
              \\d(?:
                \\d{3}
              )?
            )?
          )|
          94(?:
            000[09]|
            2(?:
              121|
              [2689]0\\d
            )|
            30[0-2]\\d|
            4(?:
              111|
              40\\d
            )
          )\\d{4}
        ',
                'geographic' => '
          (?:
            1[137]|
            2[13-68]|
            3[1458]|
            4[145]|
            5[1468]|
            6[16]|
            7[1467]|
            8[13467]
          )(?:
            [03-57]\\d{7}|
            [16]\\d{3}(?:
              \\d{4}
            )?|
            [289]\\d{3}(?:
              \\d(?:
                \\d{3}
              )?
            )?
          )|
          94(?:
            000[09]|
            2(?:
              121|
              [2689]0\\d
            )|
            30[0-2]\\d|
            4(?:
              111|
              40\\d
            )
          )\\d{4}
        ',
                'mobile' => '
          9(?:
            (?:
              0(?:
                [1-35]\\d|
                44
              )|
              (?:
                [13]\\d|
                2[0-2]
              )\\d
            )\\d|
            9(?:
              (?:
                [0-2]\\d|
                4[45]
              )\\d|
              5[15]0|
              8(?:
                1\\d|
                88
              )|
              9(?:
                0[013]|
                1[0134]|
                21|
                77|
                9[6-9]
              )
            )
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          96(?:
            0[12]|
            2[16-8]|
            3(?:
              08|
              [14]5|
              [23]|
              66
            )|
            4(?:
              0|
              80
            )|
            5[01]|
            6[89]|
            86|
            9[19]
          )
        )',
                'toll_free' => '',
                'voip' => '993\\d{7}'
              };
my %areanames = ();
$areanames{en}->{9811} = "Mazandaran";
$areanames{en}->{9813} = "Gilan";
$areanames{en}->{9817} = "Golestan";
$areanames{en}->{9821} = "Tehran\ province";
$areanames{en}->{9823} = "Semnan\ province";
$areanames{en}->{9824} = "Zanjan\ province";
$areanames{en}->{9825} = "Qom\ province";
$areanames{en}->{9826} = "Alborz";
$areanames{en}->{9828} = "Qazvin\ province";
$areanames{en}->{9831} = "Isfahan\ province";
$areanames{en}->{9834} = "Kerman\ province";
$areanames{en}->{9835} = "Yazd\ province";
$areanames{en}->{9838} = "Chahar\-mahal\ and\ Bakhtiari";
$areanames{en}->{9841} = "East\ Azarbaijan";
$areanames{en}->{9844} = "West\ Azarbaijan";
$areanames{en}->{9845} = "Ardabil\ province";
$areanames{en}->{9851} = "Razavi\ Khorasan";
$areanames{en}->{9854} = "Sistan\ and\ Baluchestan";
$areanames{en}->{9856} = "South\ Khorasan";
$areanames{en}->{9858} = "North\ Khorasan";
$areanames{en}->{9861} = "Khuzestan";
$areanames{en}->{9866} = "Lorestan";
$areanames{en}->{9871} = "Fars";
$areanames{en}->{9874} = "Kohgiluyeh\ and\ Boyer\-Ahmad";
$areanames{en}->{9876} = "Hormozgan";
$areanames{en}->{9877} = "Bushehr\ province";
$areanames{en}->{9881} = "Hamadan\ province";
$areanames{en}->{9883} = "Kermanshah\ province";
$areanames{en}->{9884} = "Ilam\ province";
$areanames{en}->{9886} = "Markazi";
$areanames{en}->{9887} = "Kurdistan";
$areanames{fa}->{9811} = "مازندران";
$areanames{fa}->{9813} = "گیلان";
$areanames{fa}->{9817} = "گلستان";
$areanames{fa}->{9821} = "استان\ تهران";
$areanames{fa}->{9823} = "استان\ سمنان";
$areanames{fa}->{9824} = "استان\ زنجان";
$areanames{fa}->{9825} = "استان\ قم";
$areanames{fa}->{9826} = "البرز";
$areanames{fa}->{9828} = "استان\ قزوین";
$areanames{fa}->{9831} = "استان\ اصفهان";
$areanames{fa}->{9834} = "استان\ کرمان";
$areanames{fa}->{9835} = "استان\ یزد";
$areanames{fa}->{9838} = "چهارمحال\ و\ بختیاری";
$areanames{fa}->{9841} = "آذربایجان\ شرقی";
$areanames{fa}->{9844} = "آذربایجان\ غربی";
$areanames{fa}->{9845} = "استان\ اردبیل";
$areanames{fa}->{9851} = "خراسان\ رضوی";
$areanames{fa}->{9854} = "سیستان\ و\ بلوچستان";
$areanames{fa}->{9856} = "خراسان\ جنوبی";
$areanames{fa}->{9858} = "خراسان\ شمالی";
$areanames{fa}->{9861} = "خوزستان";
$areanames{fa}->{9866} = "لرستان";
$areanames{fa}->{9871} = "فارس";
$areanames{fa}->{9874} = "کهگیلویه\ و\ بویراحمد";
$areanames{fa}->{9876} = "هرمزگان";
$areanames{fa}->{9877} = "استان\ بوشهر";
$areanames{fa}->{9881} = "استان\ همدان";
$areanames{fa}->{9883} = "استان\ کرمانشاه";
$areanames{fa}->{9884} = "استان\ ایلام";
$areanames{fa}->{9886} = "مرکزی";
$areanames{fa}->{9887} = "کردستان";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+98|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;