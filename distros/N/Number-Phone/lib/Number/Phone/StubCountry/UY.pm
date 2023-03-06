# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::UY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230305170054;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            405|
            8|
            90
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[124]',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '4',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1(?:
              770|
              987
            )|
            (?:
              2\\d|
              4[2-7]
            )\\d\\d
          )\\d{4}
        ',
                'geographic' => '
          (?:
            1(?:
              770|
              987
            )|
            (?:
              2\\d|
              4[2-7]
            )\\d\\d
          )\\d{4}
        ',
                'mobile' => '9[1-9]\\d{6}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(90[0-8]\\d{4})',
                'toll_free' => '
          (?:
            (?:
              0004|
              4
            )\\d{5}|
            80[05]
          )\\d{4}|
          405\\d{4}
        ',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"598462", "Rivera",
"598452", "Colonia\ del\ Scaramento",
"598472", "Paysandu",
"598433", "Canelones",
"5984369", "Durazno",
"598464", "Melo\/Cerro\ Largo",
"5984363", "Durazno",
"5984364", "Trinidad\/Flores",
"5982", "Montevideo",
"5984361", "Durazno",
"598477", "Artigas",
"598434", "San\ Jose\ de\ Mayo",
"5984367", "Durazno",
"5984360", "Durazno",
"598435", "Florida",
"5984368", "Durazno",
"598473", "Salto",
"598445", "Treinta\ y\ Tres",
"598463", "Tacuarembo",
"598444", "Minas\/Lavalleja",
"598456", "Fray\ Bentos\/Rio\ Negro",
"5984366", "Durazno",
"5984362", "Durazno",
"598447", "Rocha",
"598453", "Mercedes\/Soriano",
"5984365", "Durazno",
"59842", "San\ Carlos",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+598|\D)//g;
      my $self = bless({ country_code => '598', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '598', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;