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
package Number::Phone::StubCountry::HR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180619214156;

my $formatters = [
                {
                  'pattern' => '(1)(\\d{4})(\\d{3})',
                  'leading_digits' => '1',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '([2-5]\\d)(\\d{3})(\\d{3,4})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-5]'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9',
                  'pattern' => '(9\\d)(\\d{3})(\\d{3,4})'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '6[01]',
                  'pattern' => '(6[01])(\\d{2})(\\d{2,3})'
                },
                {
                  'pattern' => '([67]\\d)(\\d{3})(\\d{3,4})',
                  'leading_digits' => '[67]',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '(80[01])(\\d{2})(\\d{2,3})',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'leading_digits' => '80[01]'
                },
                {
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'leading_digits' => '80[01]',
                  'pattern' => '(80[01])(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'mobile' => '
          9(?:
            01\\d|
            [1259]\\d{2}|
            7(?:
              [0679]\\d|
              51
            )|
            8\\d{1,2}
          )\\d{5}
        ',
                'specialrate' => '(
          6(?:
            [01]\\d{0,2}|
            [459]\\d{2}
          )\\d{4}
        )|(
          (?:
            62\\d?|
            72
          )\\d{6}
        )',
                'geographic' => '
          1\\d{7}|
          (?:
            2[0-3]|
            3[1-5]|
            4[02-47-9]|
            5[1-3]
          )\\d{6,7}
        ',
                'pager' => '',
                'voip' => '',
                'personal_number' => '7[45]\\d{6}',
                'toll_free' => '80[01]\\d{4,6}',
                'fixed_line' => '
          1\\d{7}|
          (?:
            2[0-3]|
            3[1-5]|
            4[02-47-9]|
            5[1-3]
          )\\d{6,7}
        '
              };
my %areanames = (
  3851 => "Zagreb",
  38520 => "Dubrovnik\-Neretva",
  38521 => "Split\-Dalmatia",
  38522 => "Šibenik\-Knin",
  38523 => "Zadar",
  38531 => "Osijek\-Baranja",
  38532 => "Vukovar\-Srijem",
  38533 => "Virovitica\-Podravina",
  38534 => "Požega\-Slavonia",
  38535 => "Brod\-Posavina",
  38540 => "Međimurje",
  38542 => "Varaždin",
  38543 => "Bjelovar\-Bilogora",
  38544 => "Sisak\-Moslavina",
  38547 => "Karlovac",
  38548 => "Koprivnica\-Križevci",
  38549 => "Krapina\-Zagorje",
  38551 => "Primorsko\-goranska",
  38552 => "Istra",
  38553 => "Lika\-Senj",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+385|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;