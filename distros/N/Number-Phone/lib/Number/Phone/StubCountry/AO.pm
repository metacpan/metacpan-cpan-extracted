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
package Number::Phone::StubCountry::AO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173053;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2\\d(?:
            [26-9]\\d|
            \\d[26-9]
          )\\d{5}
        ',
                'voip' => '',
                'pager' => '',
                'personal_number' => '',
                'geographic' => '
          2\\d(?:
            [26-9]\\d|
            \\d[26-9]
          )\\d{5}
        ',
                'toll_free' => '',
                'specialrate' => '',
                'mobile' => '9[1-49]\\d{7}'
              };
my %areanames = (
  24422 => "Luanda",
  244231 => "Cabinda",
  244232 => "Zaire",
  2442321 => "Soyo",
  244233 => "Uige",
  244234 => "Bengo",
  2442348 => "Caxito",
  244235 => "Cuanza\ Norte",
  2442358 => "N\'Dalatando",
  244236 => "Cuanza\ Sul",
  2442363 => "Sumbe",
  2442364 => "Porto\ Amboim",
  244241 => "Huambo",
  244248 => "Bie",
  2442485 => "Kuito",
  244249 => "Cuando\ Cubango",
  2442498 => "Menongue",
  244251 => "Malange",
  244252 => "Lunda\ Norte",
  2442524 => "Lucapa",
  2442526 => "Dundo",
  244253 => "Lunda\ Sul",
  2442535 => "Saurimo",
  244254 => "Moxico",
  2442546 => "Luena",
  244261 => "Huila",
  2442612 => "Lubango",
  244264 => "Namibe",
  2442643 => "Tombua",
  244265 => "Cunene",
  2442652 => "Kuroka",
  2442655 => "Ondjiva",
  244272 => "Benguela",
  2442722 => "Lobito",
  2442726 => "Bela\ Vista",
  2442728 => "Baia\ Farta",
  2442729 => "Catumbela",
  2442777 => "Dama\ Universal",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+244|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;