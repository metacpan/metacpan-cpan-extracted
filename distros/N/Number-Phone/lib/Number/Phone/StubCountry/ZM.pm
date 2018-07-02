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
package Number::Phone::StubCountry::ZM;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180619214157;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{4})',
                  'national_rule' => '$1',
                  'format' => '$1 $2'
                },
                {
                  'national_rule' => '$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[1-8]',
                  'pattern' => '([1-8])(\\d{2})(\\d{4})'
                },
                {
                  'leading_digits' => '[29]',
                  'format' => '$1 $2',
                  'national_rule' => '0$1',
                  'pattern' => '([29]\\d)(\\d{7})'
                },
                {
                  'pattern' => '(800)(\\d{3})(\\d{3})',
                  'leading_digits' => '800',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3'
                }
              ];

my $validators = {
                'pager' => '',
                'geographic' => '21[1-8]\\d{6}',
                'fixed_line' => '21[1-8]\\d{6}',
                'toll_free' => '800\\d{6}',
                'personal_number' => '',
                'voip' => '',
                'mobile' => '9[4-9]\\d{7}',
                'specialrate' => ''
              };
my %areanames = (
  260211 => "Lusaka\ Province",
  260212 => "Ndola\/Copperbelt\ and\ Luapula\ Provinces",
  260213 => "Livingstone\/Southern\ Province",
  260214 => "Kasama\/Northern\ Province",
  260215 => "Kabwe\/Central\ Province",
  260216 => "Chipata\/Eastern\ Province",
  260217 => "Solwezi\/Western\ Province",
  260218 => "Mongu\/North\-Western\ Province",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+260|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;