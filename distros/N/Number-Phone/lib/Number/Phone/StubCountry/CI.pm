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
our $VERSION = 1.20170702164946;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
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
                'specialrate' => '',
                'personal_number' => '',
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
                'mobile' => '
          (?:
            0[1-9]|
            4\\d|
            5[14-9]|
            6[015-79]|
            [78][4-9]
          )\\d{6}
        ',
                'voip' => '',
                'pager' => '',
                'toll_free' => ''
              };
my %areanames = (
  22520 => "Plateau",
  22521 => "Abidjan",
  22522 => "Cocody",
  22523 => "Banco",
  22524 => "Abobo",
  22530 => "Yamoussoukro",
  22531 => "Bouaké",
  22532 => "Daloa",
  22533 => "Man",
  22534 => "San\ Pedro",
  22535 => "Abengourou",
  22536 => "Korhogo",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+225|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;