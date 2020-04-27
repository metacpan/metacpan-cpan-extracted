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
package Number::Phone::StubCountry::CI;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120028;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[02-9]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              0[023]|
              1[02357]|
              [23][045]|
              4[03-5]
            )|
            3(?:
              0[06]|
              1[069]|
              [2-4][07]|
              5[09]|
              6[08]
            )
          )\\d{5}
        ',
                'geographic' => '
          (?:
            2(?:
              0[023]|
              1[02357]|
              [23][045]|
              4[03-5]
            )|
            3(?:
              0[06]|
              1[069]|
              [2-4][07]|
              5[09]|
              6[08]
            )
          )\\d{5}
        ',
                'mobile' => '
          (?:
            2[0-3]80|
            97[0-3]\\d
          )\\d{4}|
          (?:
            0[1-9]|
            [457]\\d|
            6[014-9]|
            8[4-9]|
            95
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{fr}->{225200} = "Plateau\,\ Abidjan";
$areanames{fr}->{225202} = "Plateau\,\ Abidjan";
$areanames{fr}->{225203} = "Plateau\,\ Abidjan";
$areanames{fr}->{225210} = "Abidjan\ \(southeast\)";
$areanames{fr}->{225212} = "Abidjan\ \(southeast\)";
$areanames{fr}->{225213} = "Abidjan\ \(southeast\)";
$areanames{fr}->{225215} = "Abidjan\ \(southeast\)";
$areanames{fr}->{225217} = "Abidjan\ \(southeast\)";
$areanames{fr}->{225220} = "Cocody\,\ Abidjan";
$areanames{fr}->{225224} = "Cocody\,\ Abidjan";
$areanames{fr}->{225225} = "Cocody\,\ Abidjan";
$areanames{fr}->{225230} = "Banco\,\ Abidjan";
$areanames{fr}->{225234} = "Banco\,\ Abidjan";
$areanames{fr}->{225235} = "Banco\,\ Abidjan";
$areanames{fr}->{22524} = "Abobo\,\ Abidjan";
$areanames{fr}->{22530} = "Yamoussoukro";
$areanames{fr}->{22531} = "Bouaké";
$areanames{fr}->{22532} = "Daloa";
$areanames{fr}->{22533} = "Man";
$areanames{fr}->{22534} = "San\-Pédro";
$areanames{fr}->{22535} = "Abengourou";
$areanames{fr}->{22536} = "Korhogo";
$areanames{en}->{225200} = "Plateau\,\ Abidjan";
$areanames{en}->{225202} = "Plateau\,\ Abidjan";
$areanames{en}->{225203} = "Plateau\,\ Abidjan";
$areanames{en}->{225210} = "Abidjan\ \(southeast\)";
$areanames{en}->{225212} = "Abidjan\ \(southeast\)";
$areanames{en}->{225213} = "Abidjan\ \(southeast\)";
$areanames{en}->{225215} = "Abidjan\ \(southeast\)";
$areanames{en}->{225217} = "Abidjan\ \(southeast\)";
$areanames{en}->{225220} = "Cocody\,\ Abidjan";
$areanames{en}->{225224} = "Cocody\,\ Abidjan";
$areanames{en}->{225225} = "Cocody\,\ Abidjan";
$areanames{en}->{225230} = "Banco\,\ Abidjan";
$areanames{en}->{225234} = "Banco\,\ Abidjan";
$areanames{en}->{225235} = "Banco\,\ Abidjan";
$areanames{en}->{22524} = "Abobo\,\ Abidjan";
$areanames{en}->{22530} = "Yamoussoukro";
$areanames{en}->{22531} = "Bouaké";
$areanames{en}->{22532} = "Daloa";
$areanames{en}->{22533} = "Man";
$areanames{en}->{22534} = "San\-Pédro";
$areanames{en}->{22535} = "Abengourou";
$areanames{en}->{22536} = "Korhogo";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+225|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;