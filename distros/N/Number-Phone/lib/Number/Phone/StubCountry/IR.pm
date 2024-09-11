# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20240910191016;

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
            (?:
              12\\d|
              30[0-2]
            )\\d|
            2(?:
              121|
              [2689]0\\d
            )|
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
            (?:
              12\\d|
              30[0-2]
            )\\d|
            2(?:
              121|
              [2689]0\\d
            )|
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
                [0-35]\\d|
                4[4-6]
              )|
              (?:
                [13]\\d|
                2[0-3]
              )\\d
            )\\d|
            9(?:
              [0-46]\\d\\d|
              5[15]0|
              8(?:
                [12]\\d|
                88
              )|
              9(?:
                0[0-3]|
                [19]\\d|
                21|
                69|
                77|
                8[7-9]
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
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"9877", "Bushehr\ province",
"9856", "South\ Khorasan",
"9811", "Mazandaran",
"9861", "Khuzestan",
"9854", "Sistan\ and\ Baluchestan",
"9838", "Chahar\-mahal\ and\ Bakhtiari",
"9866", "Lorestan",
"9851", "Razavi\ Khorasan",
"9828", "Qazvin\ province",
"9813", "Gilan",
"9821", "Tehran\ province",
"9844", "West\ Azarbaijan",
"9845", "Ardabil\ province",
"9831", "Isfahan\ province",
"9858", "North\ Khorasan",
"9823", "Semnan\ province",
"9834", "Kerman\ province",
"9825", "Qom\ province",
"9826", "Alborz",
"9835", "Yazd\ province",
"9824", "Zanjan\ province",
"9841", "East\ Azarbaijan",
"9887", "Kurdistan",
"9876", "Hormozgan",
"9874", "Kohgiluyeh\ and\ Boyer\-Ahmad",
"9871", "Fars",
"9817", "Golestan",
"9881", "Hamadan\ province",
"9884", "Ilam\ province",
"9886", "Markazi",
"9883", "Kermanshah\ province",};
$areanames{fa} = {"9871", "فارس",
"9817", "گلستان",
"9874", "کهگیلویه\ و\ بویراحمد",
"9876", "هرمزگان",
"9886", "مرکزی",
"9884", "استان\ ایلام",
"9883", "استان\ کرمانشاه",
"9881", "استان\ همدان",
"9851", "خراسان\ رضوی",
"9866", "لرستان",
"9838", "چهارمحال\ و\ بختیاری",
"9813", "گیلان",
"9828", "استان\ قزوین",
"9877", "استان\ بوشهر",
"9854", "سیستان\ و\ بلوچستان",
"9811", "مازندران",
"9861", "خوزستان",
"9856", "خراسان\ جنوبی",
"9825", "استان\ قم",
"9834", "استان\ کرمان",
"9823", "استان\ سمنان",
"9887", "کردستان",
"9841", "آذربایجان\ شرقی",
"9824", "استان\ زنجان",
"9826", "البرز",
"9835", "استان\ یزد",
"9844", "آذربایجان\ غربی",
"9821", "استان\ تهران",
"9858", "خراسان\ شمالی",
"9831", "استان\ اصفهان",
"9845", "استان\ اردبیل",};
my $timezones = {
               '' => [
                       'Asia/Tehran'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+98|\D)//g;
      my $self = bless({ country_code => '98', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '98', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;