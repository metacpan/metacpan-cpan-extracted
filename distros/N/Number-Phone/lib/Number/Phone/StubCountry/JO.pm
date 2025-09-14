# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::JO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250913135858;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [2356]|
            87
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[89]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{5,6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '70',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{7})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '7',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          87(?:
            000|
            90[01]
          )\\d{3}|
          (?:
            2(?:
              6(?:
                2[0-35-9]|
                3[0-578]|
                4[24-7]|
                5[0-24-8]|
                [6-8][023]|
                9[0-3]
              )|
              7(?:
                0[1-79]|
                10|
                2[014-7]|
                3[0-689]|
                4[019]|
                5[0-3578]
              )
            )|
            32(?:
              0[1-69]|
              1[1-35-7]|
              2[024-7]|
              3\\d|
              4[0-3]|
              [5-7][023]
            )|
            53(?:
              0[0-3]|
              [13][023]|
              2[0-59]|
              49|
              5[0-35-9]|
              6[15]|
              7[45]|
              8[1-6]|
              9[0-36-9]
            )|
            6(?:
              2(?:
                [05]0|
                22
              )|
              3(?:
                00|
                33
              )|
              4(?:
                0[0-25]|
                1[2-7]|
                2[0569]|
                [38][07-9]|
                4[025689]|
                6[0-589]|
                7\\d|
                9[0-2]
              )|
              5(?:
                [01][056]|
                2[034]|
                3[0-57-9]|
                4[178]|
                5[0-69]|
                6[0-35-9]|
                7[1-379]|
                8[0-68]|
                9[0239]
              )
            )|
            87(?:
              20|
              7[078]|
              99
            )
          )\\d{4}
        ',
                'geographic' => '
          87(?:
            000|
            90[01]
          )\\d{3}|
          (?:
            2(?:
              6(?:
                2[0-35-9]|
                3[0-578]|
                4[24-7]|
                5[0-24-8]|
                [6-8][023]|
                9[0-3]
              )|
              7(?:
                0[1-79]|
                10|
                2[014-7]|
                3[0-689]|
                4[019]|
                5[0-3578]
              )
            )|
            32(?:
              0[1-69]|
              1[1-35-7]|
              2[024-7]|
              3\\d|
              4[0-3]|
              [5-7][023]
            )|
            53(?:
              0[0-3]|
              [13][023]|
              2[0-59]|
              49|
              5[0-35-9]|
              6[15]|
              7[45]|
              8[1-6]|
              9[0-36-9]
            )|
            6(?:
              2(?:
                [05]0|
                22
              )|
              3(?:
                00|
                33
              )|
              4(?:
                0[0-25]|
                1[2-7]|
                2[0569]|
                [38][07-9]|
                4[025689]|
                6[0-589]|
                7\\d|
                9[0-2]
              )|
              5(?:
                [01][056]|
                2[034]|
                3[0-57-9]|
                4[178]|
                5[0-69]|
                6[0-35-9]|
                7[1-379]|
                8[0-68]|
                9[0239]
              )
            )|
            87(?:
              20|
              7[078]|
              99
            )
          )\\d{4}
        ',
                'mobile' => '
          7(?:
            [78][0-25-9]|
            9\\d
          )\\d{6}
        ',
                'pager' => '
          74(?:
            66|
            77
          )\\d{5}
        ',
                'personal_number' => '70\\d{7}',
                'specialrate' => '(85\\d{6})|(9\\d{7})|(
          8(?:
            10|
            8\\d
          )\\d{5}
        )',
                'toll_free' => '80\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"96264", "Amman",
"962539", "Zarqa",
"962535", "Balqa",
"962262", "Mafraq",
"962531", "Madaba",
"962267", "Jarash",
"962536", "Zarqa",
"962269", "Irbid",
"9623262", "Southern\ Region",
"962324", "Aqaba",
"96263", "Amman",
"962265", "Irbid",
"962532", "Madaba",
"96265", "Amman",
"962323", "Karak",
"962537", "Zarqa",
"962266", "Mafraq",
"962530", "Zarqa",
"962321", "Ma\’an",
"962325", "Maan",
"962264", "Ajloun",
"962622", "Greater\ Amman",
"9623260", "Tafileh",
"962263", "Jarash",
"962268", "Ajloun",
"962620", "Amman",
"962322", "Tafileh",
"962647", "Greater\ Amman",
"962625", "Amman",
"962534", "Balqa",
"962320", "Aqaba",
"962533", "Balqa",
"962538", "Zarqa",
"96227", "Irbid",
"962327", "Karak",};
my $timezones = {
               '' => [
                       'Asia/Amman'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+962|\D)//g;
      my $self = bless({ country_code => '962', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '962', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;