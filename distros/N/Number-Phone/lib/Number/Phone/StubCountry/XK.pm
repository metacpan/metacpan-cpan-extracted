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
package Number::Phone::StubCountry::XK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120032;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[89]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-4]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[23]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2[89]|
            39
          )0\\d{6}|
          [23][89]\\d{6}
        ',
                'geographic' => '
          (?:
            2[89]|
            39
          )0\\d{6}|
          [23][89]\\d{6}
        ',
                'mobile' => '4[3-9]\\d{6}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(900\\d{5})',
                'toll_free' => '800\\d{5}',
                'voip' => ''
              };
my %areanames = ();
$areanames{sq}->{38328} = "Mitrovicë";
$areanames{sq}->{383280} = "Gjilan";
$areanames{sq}->{38329} = "Prizren";
$areanames{sq}->{383290} = "Ferizaj";
$areanames{sq}->{38338} = "Prishtinë";
$areanames{sq}->{38339} = "Pejë";
$areanames{sq}->{383390} = "Gjakovë";
$areanames{sr}->{38328} = "Косовска\ Митровица";
$areanames{sr}->{383280} = "Гњилане";
$areanames{sr}->{38329} = "Призрен";
$areanames{sr}->{383290} = "Урошевац";
$areanames{sr}->{38338} = "Приштина";
$areanames{sr}->{38339} = "Пећ";
$areanames{sr}->{383390} = "Ђаковица";
$areanames{en}->{38328} = "Mitrovica";
$areanames{en}->{383280} = "Gjilan";
$areanames{en}->{38329} = "Prizren";
$areanames{en}->{383290} = "Ferizaj";
$areanames{en}->{38338} = "Prishtina";
$areanames{en}->{38339} = "Peja";
$areanames{en}->{383390} = "Gjakova";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+383|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;