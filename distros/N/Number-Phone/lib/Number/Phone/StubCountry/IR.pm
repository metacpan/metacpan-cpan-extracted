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
our $VERSION = 1.20181205223703;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'leading_digits' => '96',
                  'format' => '$1',
                  'pattern' => '(\\d{4,5})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{4,5})',
                  'national_rule' => '0$1',
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
                  'format' => '$1 $2'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[1-8]',
                  'national_rule' => '0$1'
                }
              ];

my $validators = {
                'toll_free' => '',
                'geographic' => '
          (?:
            (?:
              1[137]|
              2[13-68]|
              3[1458]|
              4[145]|
              5[1468]|
              6[16]|
              7[1467]|
              8[13467]
            )\\d{4}|
            94(?:
              (?:
                000|
                (?:
                  11|
                  2\\d
                )\\d|
                30[01]
              )\\d|
              4(?:
                111|
                40\\d
              )
            )
          )\\d{4}|
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
            [16]|
            [289]\\d?
          )\\d{3}
        ',
                'fixed_line' => '
          (?:
            (?:
              1[137]|
              2[13-68]|
              3[1458]|
              4[145]|
              5[1468]|
              6[16]|
              7[1467]|
              8[13467]
            )\\d{4}|
            94(?:
              (?:
                000|
                (?:
                  11|
                  2\\d
                )\\d|
                30[01]
              )\\d|
              4(?:
                111|
                40\\d
              )
            )
          )\\d{4}|
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
            [16]|
            [289]\\d?
          )\\d{3}
        ',
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
                'personal_number' => '',
                'pager' => '',
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
                [01]\\d|
                44
              )\\d|
              510|
              8(?:
                1[01]|
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
                'voip' => '993\\d{7}'
              };
my %areanames = (
  9811 => "Mazandaran",
  9813 => "Gilan",
  9817 => "Golestan",
  9821 => "Tehran\ province",
  9823 => "Semnan\ province",
  9824 => "Zanjan\ province",
  9825 => "Qom\ province",
  9826 => "Alborz",
  9828 => "Qazvin\ province",
  9831 => "Isfahan\ province",
  9834 => "Kerman\ province",
  9835 => "Yazd\ province",
  9838 => "Chahar\-mahal\ and\ Bakhtiari",
  9841 => "East\ Azarbaijan",
  9844 => "West\ Azarbaijan",
  9845 => "Ardabil\ province",
  9851 => "Razavi\ Khorasan",
  9854 => "Sistan\ and\ Baluchestan",
  9856 => "South\ Khorasan",
  9858 => "North\ Khorasan",
  9861 => "Khuzestan",
  9866 => "Lorestan",
  9871 => "Fars",
  9874 => "Kohgiluyeh\ and\ Boyer\-Ahmad",
  9876 => "Hormozgan",
  9877 => "Bushehr\ province",
  9881 => "Hamadan\ province",
  9883 => "Kermanshah\ province",
  9884 => "Ilam\ province",
  9886 => "Markazi",
  9887 => "Kurdistan",
);
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