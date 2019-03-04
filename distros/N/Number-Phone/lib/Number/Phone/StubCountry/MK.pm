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
package Number::Phone::StubCountry::MK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190303205539;

my $formatters = [
                {
                  'leading_digits' => '2',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})',
                  'national_rule' => '0$1'
                },
                {
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[347]'
                },
                {
                  'leading_digits' => '[58]',
                  'format' => '$1 $2 $3 $4',
                  'pattern' => '(\\d{3})(\\d)(\\d{2})(\\d{2})',
                  'national_rule' => '0$1'
                }
              ];

my $validators = {
                'personal_number' => '',
                'toll_free' => '800\\d{5}',
                'fixed_line' => '
          (?:
            2(?:
              [23]\\d|
              5[0-24578]|
              6[01]|
              82
            )|
            3(?:
              1[3-68]|
              [23][2-68]|
              4[23568]
            )|
            4(?:
              [23][2-68]|
              4[3-68]|
              5[2568]|
              6[25-8]|
              7[24-68]|
              8[4-68]
            )
          )\\d{5}
        ',
                'voip' => '',
                'specialrate' => '(
          8(?:
            0[1-9]|
            [1-9]\\d
          )\\d{5}
        )|(5[02-9]\\d{6})',
                'geographic' => '
          (?:
            2(?:
              [23]\\d|
              5[0-24578]|
              6[01]|
              82
            )|
            3(?:
              1[3-68]|
              [23][2-68]|
              4[23568]
            )|
            4(?:
              [23][2-68]|
              4[3-68]|
              5[2568]|
              6[25-8]|
              7[24-68]|
              8[4-68]
            )
          )\\d{5}
        ',
                'pager' => '',
                'mobile' => '
          7(?:
            (?:
              [0-25-8]\\d|
              3[2-4]|
              9[23]
            )\\d|
            421
          )\\d{4}
        '
              };
my %areanames = (
  3892 => "Skopje",
  38931 => "Kumanovo\/Kriva\ Palanka\/Kratovo",
  38932 => "Stip\/Probistip\/Sveti\ Nikole\/Radovis",
  38933 => "Kocani\/Berovo\/Delcevo\/Vinica",
  38934 => "Gevgelija\/Valandovo\/Strumica\/Dojran",
  38942 => "Gostivar",
  38943 => "Veles\/Kavadarci\/Negotino",
  38944 => "Tetovo",
  38945 => "Kicevo\/Makedonski\ Brod",
  38946 => "Ohrid\/Struga\/Debar",
  38947 => "Bitola\/Demir\ Hisar\/Resen",
  38948 => "Prilep\/Krusevo",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+389|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;