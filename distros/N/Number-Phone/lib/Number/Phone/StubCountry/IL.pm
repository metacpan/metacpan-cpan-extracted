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
package Number::Phone::StubCountry::IL;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113148;

my $formatters = [
                {
                  'leading_digits' => '[2-489]',
                  'pattern' => '([2-489])(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '([57]\\d)(\\d{3})(\\d{4})',
                  'leading_digits' => '[57]'
                },
                {
                  'pattern' => '(153)(\\d{1,2})(\\d{3})(\\d{4})',
                  'leading_digits' => '153'
                },
                {
                  'pattern' => '(1)([7-9]\\d{2})(\\d{3})(\\d{3})',
                  'leading_digits' => '1[7-9]'
                },
                {
                  'pattern' => '(1255)(\\d{3})',
                  'leading_digits' => '125'
                },
                {
                  'leading_digits' => '120',
                  'pattern' => '(1200)(\\d{3})(\\d{3})'
                },
                {
                  'leading_digits' => '121',
                  'pattern' => '(1212)(\\d{2})(\\d{2})'
                },
                {
                  'pattern' => '(1599)(\\d{6})',
                  'leading_digits' => '1599'
                },
                {
                  'pattern' => '(151)(\\d{1,2})(\\d{3})(\\d{4})',
                  'leading_digits' => '151'
                },
                {
                  'leading_digits' => '[2-689]',
                  'pattern' => '(\\d{4})'
                }
              ];

my $validators = {
                'voip' => '
          7(?:
            18\\d|
            2[23]\\d|
            3[237]\\d|
            47\\d|
            6[58]\\d|
            7\\d{2}|
            8(?:
              2\\d|
              33|
              55|
              77|
              81
            )|
            9[2579]\\d
          )\\d{5}
        ',
                'fixed_line' => '
          (?:
            153\\d{1,2}|
            [2-489]
          )\\d{7}
        ',
                'specialrate' => '(1700\\d{6})|(
          1(?:
            212|
            (?:
              9(?:
                0[01]|
                19
              )|
              200
            )\\d{2}
          )\\d{4}
        )|(
          [2-689]\\d{3}|
          1599\\d{6}
        )',
                'toll_free' => '
          1(?:
            80[019]\\d{3}|
            255
          )\\d{3}
        ',
                'mobile' => '
          5(?:
            [0-47-9]\\d{2}|
            5(?:
              01|
              2[23]|
              3[2-4]|
              4[45]|
              5[5689]|
              6[6-8]|
              7[0178]|
              8[6-9]|
              9[2-9]
            )|
            6[2-9]\\d
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'geographic' => '
          (?:
            153\\d{1,2}|
            [2-489]
          )\\d{7}
        '
              };
my %areanames = (
  9722 => "Jerusalem",
  9723 => "Tel\ Aviv",
  9724 => "Haifa\ and\ North\ Regions",
  9728 => "Hashfela\ and\ South\ Regions",
  9729 => "Hasharon",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+972|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;