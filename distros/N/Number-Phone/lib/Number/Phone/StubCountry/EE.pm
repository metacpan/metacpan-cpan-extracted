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
our $VERSION = 1.20180410221546;

my $formatters = [
                {
                  'pattern' => '([3-79]\\d{2})(\\d{4})',
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
            7[1-9]
          ',
                  'format' => '$1 $2'
                },
                {
                  'pattern' => '(70)(\\d{2})(\\d{4})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '70'
                },
                {
                  'pattern' => '(8000)(\\d{3})(\\d{3})',
                  'leading_digits' => '8000',
                  'format' => '$1 $2 $3'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            40|
            5|
            8(?:
              00[1-9]|
              [1-5]
            )
          ',
                  'pattern' => '([458]\\d{3})(\\d{3,4})'
                }
              ];

my $validators = {
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
            5\\d|
            8[1-5]
          )\\d{6}|
          5(?:
            [02]\\d{2}|
            1(?:
              [0-8]\\d|
              95
            )|
            5[0-478]\\d|
            64[0-4]|
            65[1-589]
          )\\d{3}
        ',
                'specialrate' => '(
          (?:
            40\\d{2}|
            900
          )\\d{4}
        )',
                'pager' => '',
                'personal_number' => '70[0-2]\\d{5}',
                'fixed_line' => '
          (?:
            3[23589]|
            4[3-8]|
            6\\d|
            7[1-9]|
            88
          )\\d{5}
        ',
                'toll_free' => '
          800(?:
            0\\d{3}|
            1\\d|
            [2-9]
          )\\d{3}
        ',
                'voip' => ''
              };
my %areanames = (
  37232 => "Rakvere",
  37233 => "Kohtla\-Järve",
  37235 => "Narva\/Sillamäe",
  37238 => "Paide",
  37243 => "Viljandi",
  37244 => "Pärnu",
  37245 => "Kuressaare",
  37246 => "Kärdla",
  37247 => "Haapsalu",
  37248 => "Rapla",
  3726 => "Tallinn\/Harju\ County",
  37273 => "Tartu",
  37274 => "Tartu",
  37275 => "Tartu",
  37276 => "Valga",
  37277 => "Jõgeva",
  37278 => "Võru",
  37279 => "Põlva",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+372|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;