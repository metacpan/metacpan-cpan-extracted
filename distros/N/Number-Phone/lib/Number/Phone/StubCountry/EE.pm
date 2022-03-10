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
package Number::Phone::StubCountry::EE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220307120117;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [369]|
            4[3-8]|
            5(?:
              [02]|
              1(?:
                [0-8]|
                95
              )|
              5[0-478]|
              6(?:
                4[0-4]|
                5[1-589]
              )
            )|
            7[1-9]|
            88
          ',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [45]|
            8(?:
              00[1-9]|
              [1-49]
            )
          ',
                  'pattern' => '(\\d{4})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '7',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            3[23589]|
            4[3-8]|
            6\\d|
            7[1-9]|
            88
          )\\d{5}
        ',
                'geographic' => '
          (?:
            3[23589]|
            4[3-8]|
            6\\d|
            7[1-9]|
            88
          )\\d{5}
        ',
                'mobile' => '
          (?:
            5\\d{5}|
            8(?:
              1(?:
                0(?:
                  000|
                  [3-9]\\d\\d
                )|
                (?:
                  1(?:
                    0[236]|
                    1\\d
                  )|
                  (?:
                    23|
                    [3-79]\\d
                  )\\d
                )\\d
              )|
              2(?:
                0(?:
                  000|
                  (?:
                    19|
                    [24-7]\\d
                  )\\d
                )|
                (?:
                  (?:
                    [124-6]\\d|
                    3[5-9]
                  )\\d|
                  7(?:
                    [679]\\d|
                    8[13-9]
                  )|
                  8(?:
                    [2-6]\\d|
                    7[01]
                  )
                )\\d
              )|
              [349]\\d{4}
            )
          )\\d\\d|
          5(?:
            (?:
              [02]\\d|
              5[0-478]
            )\\d|
            1(?:
              [0-8]\\d|
              95
            )|
            6(?:
              4[0-4]|
              5[1-589]
            )
          )\\d{3}
        ',
                'pager' => '',
                'personal_number' => '70[0-2]\\d{5}',
                'specialrate' => '(
          (?:
            40\\d\\d|
            900
          )\\d{4}
        )',
                'toll_free' => '
          800(?:
            (?:
              0\\d\\d|
              1
            )\\d|
            [2-9]
          )\\d{3}
        ',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"37233", "Kohtla\-Järve",
"37248", "Rapla",
"37278", "Võru",
"37245", "Kuressaare",
"37275", "Tartu",
"3726", "Tallinn\/Harju\ County",
"37232", "Rakvere",
"37274", "Tartu",
"37246", "Kärdla",
"37244", "Pärnu",
"37276", "Valga",
"37273", "Tartu",
"37238", "Paide",
"37243", "Viljandi",
"37247", "Haapsalu",
"37277", "Jõgeva",
"37279", "Põlva",
"37235", "Narva\/Sillamäe",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+372|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;