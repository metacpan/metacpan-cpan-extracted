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
package Number::Phone::StubCountry::UY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210309172133;

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
                  'leading_digits' => '[24]',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '4',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2\\d|
            4[2-7]
          )\\d{6}
        ',
                'geographic' => '
          (?:
            2\\d|
            4[2-7]
          )\\d{6}
        ',
                'mobile' => '9[1-9]\\d{6}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(90[0-8]\\d{4})',
                'toll_free' => '
          (?:
            4\\d{5}|
            80[05]
          )\\d{4}|
          405\\d{4}
        ',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"598464", "Melo\/Cerro\ Largo",
"5984365", "Durazno",
"5984360", "Durazno",
"598477", "Artigas",
"598456", "Fray\ Bentos\/Rio\ Negro",
"5984361", "Durazno",
"5984367", "Durazno",
"598434", "San\ Jose\ de\ Mayo",
"598445", "Treinta\ y\ Tres",
"598452", "Colonia\ del\ Scaramento",
"598462", "Rivera",
"598472", "Paysandu",
"5984364", "Trinidad\/Flores",
"5984366", "Durazno",
"5984363", "Durazno",
"5984368", "Durazno",
"5984369", "Durazno",
"598473", "Salto",
"598453", "Mercedes\/Soriano",
"5982", "Montevideo",
"598463", "Tacuarembo",
"59842", "San\ Carlos",
"598444", "Minas\/Lavalleja",
"598447", "Rocha",
"5984362", "Durazno",
"598433", "Canelones",
"598435", "Florida",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+598|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;