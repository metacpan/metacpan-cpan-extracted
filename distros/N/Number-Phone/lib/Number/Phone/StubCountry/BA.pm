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
package Number::Phone::StubCountry::BA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180203200232;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2-$3',
                  'leading_digits' => '[3-5]',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            6[1-356]|
            [7-9]
          ',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{3})',
                  'leading_digits' => '6[047]',
                  'national_rule' => '0$1'
                }
              ];

my $validators = {
                'pager' => '',
                'voip' => '',
                'personal_number' => '',
                'mobile' => '
          6(?:
            0(?:
              3\\d|
              40
            )|
            [1-356]\\d|
            44[0-6]|
            71[137]
          )\\d{5}
        ',
                'specialrate' => '(8[12]\\d{6})|(9[0246]\\d{6})|(
          70(?:
            3[0146]|
            [56]0
          )\\d{4}
        )',
                'fixed_line' => '
          (?:
            3(?:
              [05679][2-9]|
              1[4579]|
              [23][24-9]|
              4[2-4689]|
              8[2457-9]
            )|
            49[2-579]|
            5(?:
              0[2-49]|
              [13][2-9]|
              [268][2-4679]|
              4[4689]|
              5[2-79]|
              7[2-69]|
              9[2-4689]
            )
          )\\d{5}
        ',
                'toll_free' => '8[08]\\d{6}',
                'geographic' => '
          (?:
            3(?:
              [05679][2-9]|
              1[4579]|
              [23][24-9]|
              4[2-4689]|
              8[2457-9]
            )|
            49[2-579]|
            5(?:
              0[2-49]|
              [13][2-9]|
              [268][2-4679]|
              4[4689]|
              5[2-79]|
              7[2-69]|
              9[2-4689]
            )
          )\\d{5}
        '
              };
my %areanames = (
  38730 => "Central\ Bosnia\ Canton",
  38731 => "Posavina\ Canton",
  38732 => "Zenica\-Doboj\ Canton",
  38733 => "Sarajevo\ Canton",
  38734 => "Canton\ 10",
  38735 => "Tuzla\ Canton",
  38736 => "Herzegovina\-Neretva\ Canton",
  38737 => "Una\-Sana\ Canton",
  38738 => "Bosnian\-Podrinje\ Canton\ Goražde",
  38739 => "West\ Herzegovina\ Canton",
  38749 => "Brčko\ District",
  38750 => "Mrkonjić\ Grad",
  38751 => "Banja\ Luka",
  38752 => "Prijedor",
  38753 => "Doboj",
  38754 => "Šamac",
  38755 => "Bijeljina",
  38756 => "Zvornik",
  38757 => "East\ Sarajevo",
  38758 => "Foča",
  38759 => "Trebinje",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+387|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      {
        no warnings 'uninitialized';
        $number =~ s/^(?:0)//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;