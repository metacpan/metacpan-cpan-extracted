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
package Number::Phone::StubCountry::MM;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180410221547;

my $formatters = [
                {
                  'pattern' => '(\\d)(\\d{3})(\\d{3,4})',
                  'leading_digits' => '
            1|
            2[245]
          ',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '(2)(\\d{4})(\\d{4})',
                  'national_rule' => '0$1',
                  'leading_digits' => '251',
                  'format' => '$1 $2 $3'
                },
                {
                  'leading_digits' => '
            16|
            2
          ',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d)(\\d{2})(\\d{3})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})',
                  'national_rule' => '0$1',
                  'leading_digits' => '
            432|
            67|
            81
          ',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3,4})',
                  'leading_digits' => '[4-8]',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '(9)(\\d{3})(\\d{4,6})',
                  'leading_digits' => '
            9(?:
              2[0-4]|
              [35-9]|
              4[137-9]
            )
          ',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '(9)([34]\\d{4})(\\d{4})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            9(?:
              3[0-36]|
              4[0-57-9]
            )
          ',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '(9)(\\d{3})(\\d{3})(\\d{3})',
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '92[56]',
                  'national_rule' => '0$1'
                },
                {
                  'leading_digits' => '93',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3 $4',
                  'pattern' => '(9)(\\d{3})(\\d{3})(\\d{2})'
                }
              ];

my $validators = {
                'voip' => '1333\\d{4}',
                'toll_free' => '',
                'fixed_line' => '
          1(?:
            2\\d{1,2}|
            [35]\\d|
            4(?:
              \\d|
              2[236]|
              39
            )|
            6\\d?|
            [89][0-6]\\d
          )\\d{4}|
          2(?:
            2(?:
              000\\d{3}|
              \\d{4}
            )|
            3\\d{4}|
            4(?:
              0\\d{5}|
              26\\d{4}|
              39\\d{4}|
              \\d{4}
            )|
            5(?:
              1\\d{3,6}|
              [02-9]\\d{3,5}
            )|
            [6-9]\\d{4}
          )|
          4(?:
            2[245-8]|
            3(?:
              2(?:
                02
              )?|
              [346]|
              56?
            )|
            [46][2-6]|
            5[3-5]
          )\\d{4}|
          5(?:
            2(?:
              2(?:
                \\d{1,2}
              )?|
              [3-8]
            )|
            3[2-68]|
            4(?:
              21?|
              [4-8]
            )|
            5[23]|
            6[2-4]|
            7[2-8]|
            8[24-7]|
            9[2-7]
          )\\d{4}|
          6(?:
            0[23]|
            1(?:
              2(?:
                0|
                4\\d
              )?|
              [356]
            )|
            2[2-6]|
            3[24-6]|
            4(?:
              2(?:
                4\\d
              )?|
              [3-6]
            )|
            5[2-4]|
            6[2-8]|
            7(?:
              [2367]|
              4(?:
                \\d|
                39
              )|
              5\\d?|
              8[145]\\d
            )|
            8[245]|
            9(?:
              20?|
              4
            )
          )\\d{4}|
          7(?:
            [04][24-8]|
            1(?:
              20?|
              [3-7]
            )|
            22|
            3[2-4]|
            5[2-7]
          )\\d{4}|
          8(?:
            1(?:
              2\\d{1,2}|
              [3-689]\\d
            )|
            2(?:
              2\\d|
              3(?:
                \\d|
                20
              )|
              [4-8]\\d
            )|
            3[24]\\d|
            4[24-7]\\d|
            5[245]\\d|
            6[23]\\d
          )\\d{3}
        ',
                'personal_number' => '',
                'pager' => '',
                'specialrate' => '',
                'mobile' => '
          17[01]\\d{4}|
          9(?:
            2(?:
              [0-4]|
              5\\d{2}|
              6[0-5]\\d
            )|
            3(?:
              [0-36]|
              4[069]
            )\\d|
            4(?:
              0[0-4]\\d|
              [1379]\\d|
              2\\d{2}|
              4[0-589]\\d|
              5\\d{2}|
              88
            )|
            5[0-6]|
            6(?:
              1\\d|
              9\\d{2}|
              \\d
            )|
            7(?:
              3|
              5[0-2]|
              [6-9]\\d
            )\\d|
            8(?:
              \\d|
              9\\d{2}
            )|
            9(?:
              1\\d|
              [5-7]\\d{2}|
              [089]
            )
          )\\d{5}
        ',
                'geographic' => '
          1(?:
            2\\d{1,2}|
            [35]\\d|
            4(?:
              \\d|
              2[236]|
              39
            )|
            6\\d?|
            [89][0-6]\\d
          )\\d{4}|
          2(?:
            2(?:
              000\\d{3}|
              \\d{4}
            )|
            3\\d{4}|
            4(?:
              0\\d{5}|
              26\\d{4}|
              39\\d{4}|
              \\d{4}
            )|
            5(?:
              1\\d{3,6}|
              [02-9]\\d{3,5}
            )|
            [6-9]\\d{4}
          )|
          4(?:
            2[245-8]|
            3(?:
              2(?:
                02
              )?|
              [346]|
              56?
            )|
            [46][2-6]|
            5[3-5]
          )\\d{4}|
          5(?:
            2(?:
              2(?:
                \\d{1,2}
              )?|
              [3-8]
            )|
            3[2-68]|
            4(?:
              21?|
              [4-8]
            )|
            5[23]|
            6[2-4]|
            7[2-8]|
            8[24-7]|
            9[2-7]
          )\\d{4}|
          6(?:
            0[23]|
            1(?:
              2(?:
                0|
                4\\d
              )?|
              [356]
            )|
            2[2-6]|
            3[24-6]|
            4(?:
              2(?:
                4\\d
              )?|
              [3-6]
            )|
            5[2-4]|
            6[2-8]|
            7(?:
              [2367]|
              4(?:
                \\d|
                39
              )|
              5\\d?|
              8[145]\\d
            )|
            8[245]|
            9(?:
              20?|
              4
            )
          )\\d{4}|
          7(?:
            [04][24-8]|
            1(?:
              20?|
              [3-7]
            )|
            22|
            3[2-4]|
            5[2-7]
          )\\d{4}|
          8(?:
            1(?:
              2\\d{1,2}|
              [3-689]\\d
            )|
            2(?:
              2\\d|
              3(?:
                \\d|
                20
              )|
              [4-8]\\d
            )|
            3[24]\\d|
            4[24-7]\\d|
            5[245]\\d|
            6[23]\\d
          )\\d{3}
        '
              };
my %areanames = (
  951422 => "Yangon",
  951423 => "Yangon",
  951426 => "Yangon",
  951439 => "Yangon",
  951550 => "Bahan",
  951551 => "Bahan",
  951552 => "Bahan",
  951553 => "Bahan",
  951680 => "Bayintnaung",
  951681 => "Bayintnaung",
  951682 => "Bayintnaung",
  951683 => "Bayintnaung",
  951684 => "Bayintnaung",
  951685 => "Bayintnaung",
  951686 => "Bayintnaung",
  951687 => "Bayintnaung",
  951688 => "Bayintnaung",
  9522000 => "Mingalar\ Mandalay",
  952426 => "Mandalay",
  952439 => "Mandalay",
  95256 => "Amarapura",
  9543202 => "Rakhine",
  954353 => "Buthidaung",
  9543565 => "Palatwa",
  95522221 => "Bago",
  95522222 => "Bago",
  95522223 => "Bago",
  95522224 => "Bago",
  95522230 => "Oathar\ Myothit",
  955645 => "Tandar",
  9561200 => "Chauk",
  956124620 => "Chauk",
  956124621 => "Chauk",
  956124622 => "Chauk",
  956124623 => "Chauk",
  956124624 => "Chauk",
  956124640 => "Bagan",
  956124641 => "Bagan",
  956124642 => "Bagan",
  956124643 => "Bagan",
  956124644 => "Bagan",
  956260 => "Kanma",
  956323 => "Magway",
  956324 => "Magway",
  95642487 => "Shawpin",
  956525 => "Ngape",
  9567439 => "Naypyidaw",
  9567550 => "Naypyidaw",
  9569200 => "Aunglan",
  956940 => "Sinpaungwae",
  95712032 => "Ohbotaung",
  95812820 => "Moenae",
  95812821 => "Moenae",
  95812822 => "Moenae",
  95812823 => "Moenae",
  95812824 => "Moenae",
  958130 => "Pinlon",
  958131 => "Loilem",
  958141 => "Naungtayar",
  958149 => "Sesin",
  9582320 => "Manton",
  958238 => "Tantyan",
  958521 => "Pyinoolwin",
  958522 => "Pyinoolwin",
  958523 => "Pyinoolwin",
  958528 => "Pyinoolwin",
  958529 => "Padaythar\ Myothit",
  958540 => "Ohn\ Chaw",
  958620 => "Mogoke",
  958621 => "Mogoke",
  958625 => "Kyatpyin",
  958630 => "Thabeikkyin",
  958635 => "Sintkuu",
  958639 => "Letpanhla",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+95|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;