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
our $VERSION = 1.20180619214156;

my $formatters = [
                {
                  'leading_digits' => '[2-489]',
                  'national_rule' => '0$1',
                  'format' => '$1-$2-$3',
                  'pattern' => '([2-489])(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '([57]\\d)(\\d{3})(\\d{4})',
                  'format' => '$1-$2-$3',
                  'national_rule' => '0$1',
                  'leading_digits' => '[57]'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '153',
                  'pattern' => '(153)(\\d{1,2})(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(1)([7-9]\\d{2})(\\d{3})(\\d{3})',
                  'format' => '$1-$2-$3-$4',
                  'leading_digits' => '1[7-9]'
                },
                {
                  'pattern' => '(1255)(\\d{3})',
                  'leading_digits' => '1255',
                  'format' => '$1-$2'
                },
                {
                  'leading_digits' => '1200',
                  'format' => '$1-$2-$3',
                  'pattern' => '(1200)(\\d{3})(\\d{3})'
                },
                {
                  'pattern' => '(1212)(\\d{2})(\\d{2})',
                  'format' => '$1-$2-$3',
                  'leading_digits' => '1212'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '1599',
                  'pattern' => '(1599)(\\d{6})'
                },
                {
                  'format' => '$1-$2 $3-$4',
                  'leading_digits' => '151',
                  'pattern' => '(151)(\\d{1,2})(\\d{3})(\\d{4})'
                },
                {
                  'leading_digits' => '[2-689]',
                  'format' => '*$1',
                  'pattern' => '(\\d{4})'
                }
              ];

my $validators = {
                'mobile' => '
          5(?:
            [0-489][2-9]\\d|
            5(?:
              01|
              2[2-5]|
              3[23]|
              4[45]|
              5[015689]|
              6[6-8]|
              7[0-267]|
              8[7-9]|
              9[1-9]
            )|
            6\\d{2}
          )\\d{5}
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
                'pager' => '',
                'geographic' => '
          (?:
            153\\d{1,2}|
            [2-489]
          )\\d{7}
        ',
                'fixed_line' => '
          (?:
            153\\d{1,2}|
            [2-489]
          )\\d{7}
        ',
                'toll_free' => '
          1(?:
            80[019]\\d{3}|
            255
          )\\d{3}
        ',
                'personal_number' => '',
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
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;