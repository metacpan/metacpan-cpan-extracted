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
our $VERSION = 1.20210921211832;

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
                [0-35]\\d|
                4[4-6]
              )|
              (?:
                [13]\\d|
                2[0-3]
              )\\d
            )\\d|
            9(?:
              (?:
                [0-3]\\d|
                4[0145]
              )\\d|
              5[15]0|
              8(?:
                1\\d|
                88
              )|
              9(?:
                0[013]|
                [19]\\d|
                21|
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
$areanames{en} = {"9861", "Khuzestan",
"9886", "Markazi",
"9845", "Ardabil\ province",
"9817", "Golestan",
"9871", "Fars",
"9831", "Isfahan\ province",
"9844", "West\ Azarbaijan",
"9887", "Kurdistan",
"9884", "Ilam\ province",
"9828", "Qazvin\ province",
"9826", "Alborz",
"9851", "Razavi\ Khorasan",
"9825", "Qom\ province",
"9824", "Zanjan\ province",
"9866", "Lorestan",
"9874", "Kohgiluyeh\ and\ Boyer\-Ahmad",
"9834", "Kerman\ province",
"9841", "East\ Azarbaijan",
"9881", "Hamadan\ province",
"9877", "Bushehr\ province",
"9811", "Mazandaran",
"9876", "Hormozgan",
"9858", "North\ Khorasan",
"9823", "Semnan\ province",
"9835", "Yazd\ province",
"9821", "Tehran\ province",
"9813", "Gilan",
"9856", "South\ Khorasan",
"9838", "Chahar\-mahal\ and\ Bakhtiari",
"9883", "Kermanshah\ province",
"9854", "Sistan\ and\ Baluchestan",};
$areanames{fa} = {"9824", "استان\ زنجان",
"9826", "البرز",
"9851", "خراسان\ رضوی",
"9825", "استان\ قم",
"9831", "استان\ اصفهان",
"9871", "فارس",
"9844", "آذربایجان\ غربی",
"9887", "کردستان",
"9828", "استان\ قزوین",
"9884", "استان\ ایلام",
"9861", "خوزستان",
"9886", "مرکزی",
"9845", "استان\ اردبیل",
"9817", "گلستان",
"9883", "استان\ کرمانشاه",
"9854", "سیستان\ و\ بلوچستان",
"9821", "استان\ تهران",
"9856", "خراسان\ جنوبی",
"9813", "گیلان",
"9838", "چهارمحال\ و\ بختیاری",
"9811", "مازندران",
"9876", "هرمزگان",
"9858", "خراسان\ شمالی",
"9823", "استان\ سمنان",
"9835", "استان\ یزد",
"9866", "لرستان",
"9834", "استان\ کرمان",
"9874", "کهگیلویه\ و\ بویراحمد",
"9841", "آذربایجان\ شرقی",
"9881", "استان\ همدان",
"9877", "استان\ بوشهر",};

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