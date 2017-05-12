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
package Number::Phone::StubCountry::CL;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173053;

my $formatters = [
                {
                  'pattern' => '(\\d)(\\d{4})(\\d{4})',
                  'leading_digits' => '2[23]'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})',
                  'leading_digits' => '
            [357]|
            4[1-35]|
            6[13-57]
          '
                },
                {
                  'leading_digits' => '9',
                  'pattern' => '(9)(\\d{4})(\\d{4})'
                },
                {
                  'pattern' => '(44)(\\d{3})(\\d{4})',
                  'leading_digits' => '44'
                },
                {
                  'leading_digits' => '
            60|
            8
          ',
                  'pattern' => '([68]00)(\\d{3})(\\d{3,4})'
                },
                {
                  'pattern' => '(600)(\\d{3})(\\d{2})(\\d{3})',
                  'leading_digits' => '60'
                },
                {
                  'pattern' => '(1230)(\\d{3})(\\d{4})',
                  'leading_digits' => '1'
                },
                {
                  'leading_digits' => '219',
                  'pattern' => '(\\d{5})(\\d{4})'
                },
                {
                  'leading_digits' => '[1-9]',
                  'pattern' => '(\\d{4,5})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            1962\\d{4}|
            2\\d{7}|
            32[0-2467]\\d{5}
          )|
          (?:
            3[2-5]|
            [47][1-35]|
            5[1-3578]|
            6[13-57]
          )\\d{7}
        ',
                'voip' => '44\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'geographic' => '
          2(?:
            1962\\d{4}|
            2\\d{7}|
            32[0-2467]\\d{5}
          )|
          (?:
            3[2-5]|
            [47][1-35]|
            5[1-3578]|
            6[13-57]
          )\\d{7}
        ',
                'toll_free' => '
          800\\d{6}|
          1230\\d{7}
        ',
                'mobile' => '9[3-9]\\d{7}',
                'specialrate' => '(600\\d{7,8})'
              };
my %areanames = (
  5622 => "Santiago\,\ Metropolitan\ Region",
  5623 => "Santiago\,\ Metropolitan\ Region",
  5632 => "Valparaíso",
  5633 => "Quillota\,\ Valparaíso",
  5634 => "San\ Felipe\,\ Valparaíso",
  5635 => "San\ Antonio\,\ Valparaíso",
  5641 => "Concepción\,\ Biobío",
  5642 => "Chillán\,\ Biobío",
  5643 => "Los\ Angeles\,\ Biobío",
  5645 => "Temuco\,\ Araucanía",
  5651 => "La\ Serena\,\ Coquimbo",
  5652 => "Copiapó\,\ Atacama",
  5653 => "Ovalle\,\ Coquimbo",
  5655 => "Antofagasta",
  5657 => "Iquique\,\ Tarapacá",
  5658 => "Arica\,\ Arica\ and\ Parinacota",
  5661 => "Punta\ Arenas\,\ Magallanes\ and\ Antártica\ Chilena",
  5663 => "Valdivia\,\ Los\ Ríos",
  5664 => "Osorno\,\ Los\ Lagos",
  5665 => "Puerto\ Montt\,\ Los\ Lagos",
  5667 => "Coyhaique\,\ Aisén",
  5671 => "Talca\,\ Maule",
  5672 => "Rancagua\,\ O\'Higgins",
  5673 => "Linares\,\ Maule",
  5675 => "Curicó\,\ Maule",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+56|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;