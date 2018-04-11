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
package Number::Phone::StubCountry::UA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180410221547;

my $formatters = [
                {
                  'pattern' => '([3-9]\\d)(\\d{3})(\\d{4})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [38]9|
            4(?:
              [45][0-5]|
              87
            )|
            5(?:
              0|
              6(?:
                3[14-7]|
                7
              )|
              7[37]
            )|
            6[36-8]|
            7|
            9[1-9]
          ',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '([3-689]\\d{2})(\\d{3})(\\d{3})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            3(?:
              [1-46-8]2[013-9]|
              52
            )|
            4(?:
              [1378]2|
              62[013-9]
            )|
            5(?:
              [12457]2|
              6[24]
            )|
            6(?:
              [12][29]|
              [49]2|
              5[24]
            )|
            8[0-8]|
            90
          ',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '([3-6]\\d{3})(\\d{5})',
                  'format' => '$1 $2',
                  'national_rule' => '0$1',
                  'leading_digits' => '
            3(?:
              [1-46-8](?:
                [013-9]|
                22
              )|
              5[013-9]
            )|
            4(?:
              [137][013-9]|
              [45][6-9]|
              6(?:
                [013-9]|
                22
              )|
              8[4-6]
            )|
            5(?:
              [1245][013-9]|
              3|
              6(?:
                [015689]|
                3[02389]
              )|
              7[4-6]
            )|
            6(?:
              [12][13-8]|
              [49][013-9]|
              5[0135-9]
            )
          '
                }
              ];

my $validators = {
                'voip' => '89[1-579]\\d{6}',
                'toll_free' => '800\\d{6}',
                'fixed_line' => '
          (?:
            3[1-8]|
            4[13-8]|
            5[1-7]|
            6[12459]
          )\\d{7}
        ',
                'personal_number' => '',
                'pager' => '',
                'mobile' => '
          (?:
            39|
            50|
            6[36-8]|
            7[1-3]|
            9[1-9]
          )\\d{7}
        ',
                'specialrate' => '(900[2-49]\\d{5})',
                'geographic' => '
          (?:
            3[1-8]|
            4[13-8]|
            5[1-7]|
            6[12459]
          )\\d{7}
        '
              };
my %areanames = (
  38031 => "Zakarpattia",
  38032 => "Lviv",
  38033 => "Volyn",
  38034 => "Ivano\-Frankivsk",
  38035 => "Ternopil",
  38036 => "Rivne",
  38037 => "Chernivtsi",
  38038 => "Khmelnytskyi",
  38041 => "Zhytomyr",
  38043 => "Vinnytsia",
  38044 => "Kyiv\ city",
  38045 => "Kyiv",
  38046 => "Chernihiv",
  38047 => "Cherkasy",
  38048 => "Odesa",
  38051 => "Mykolayiv",
  38052 => "Kirovohrad",
  38053 => "Poltava",
  38054 => "Sumy",
  38055 => "Kherson",
  38056 => "Dnipropetrovsk",
  38057 => "Kharkiv",
  38061 => "Zaporizhzhia",
  38062 => "Donetsk",
  38064 => "Luhansk",
  38065 => "Crimea",
  38069 => "Sevastopol\ city",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+380|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;