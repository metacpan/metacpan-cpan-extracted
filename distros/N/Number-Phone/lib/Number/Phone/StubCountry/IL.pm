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
package Number::Phone::StubCountry::IL;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20251210153523;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '125',
                  'pattern' => '(\\d{4})(\\d{3})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '121',
                  'pattern' => '(\\d{4})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '[2-489]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '[57]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '12',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '159',
                  'pattern' => '(\\d{4})(\\d{6})'
                },
                {
                  'format' => '$1-$2-$3-$4',
                  'leading_digits' => '1[7-9]',
                  'pattern' => '(\\d)(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1-$2 $3-$4',
                  'leading_digits' => '15',
                  'pattern' => '(\\d{3})(\\d{1,2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          153\\d{8,9}|
          29[1-9]\\d{5}|
          (?:
            2[0-8]|
            [3489]\\d
          )\\d{6}
        ',
                'geographic' => '
          153\\d{8,9}|
          29[1-9]\\d{5}|
          (?:
            2[0-8]|
            [3489]\\d
          )\\d{6}
        ',
                'mobile' => '
          55(?:
            4(?:
              0[0-2]|
              [16]0
            )|
            57[0-289]
          )\\d{4}|
          5(?:
            (?:
              [0-2][02-9]|
              [36]\\d|
              [49][2-9]|
              8[3-7]
            )\\d|
            5(?:
              01|
              2\\d|
              3[0-3]|
              4[3-5]|
              5[0-25689]|
              6[6-8]|
              7[0-267]|
              8[7-9]|
              9[1-9]
            )
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(1700\\d{6})|(
          1212\\d{4}|
          1(?:
            200|
            9(?:
              0[0-2]|
              19
            )
          )\\d{6}
        )|(1599\\d{6})',
                'toll_free' => '
          1(?:
            255|
            80[019]\\d{3}
          )\\d{3}
        ',
                'voip' => '
          7(?:
            38(?:
              [05]\\d|
              8[0138]
            )|
            8(?:
              33|
              55|
              77|
              81
            )\\d
          )\\d{4}|
          7(?:
            18|
            2[23]|
            3[237]|
            47|
            6[258]|
            7\\d|
            82|
            9[2-9]
          )\\d{6}
        '
              };
my %areanames = ();
$areanames{en} = {"9724", "Haifa\ and\ North\ Regions",
"9729", "Hasharon",
"9723", "Tel\ Aviv",
"9722", "Jerusalem",
"9728", "Hashfela\ and\ South\ Regions",};
$areanames{iw} = {"9728", "השפלה\ והדרום",
"9722", "ירושלים",
"9723", "תל\ אביב\-יפו\ והמרכז",
"9724", "חיפה\ והצפון",
"9729", "השרון",};
my $timezones = {
               '' => [
                       'Asia/Jerusalem'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+972|\D)//g;
      my $self = bless({ country_code => '972', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '972', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;