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
our $VERSION = 1.20200511123716;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
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
                'toll_free' => '80[05]\\d{4}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{5982} = "Montevideo";
$areanames{en}->{59842} = "San\ Carlos";
$areanames{en}->{598433} = "Canelones";
$areanames{en}->{598434} = "San\ Jose\ de\ Mayo";
$areanames{en}->{598435} = "Florida";
$areanames{en}->{598436} = "Durazno";
$areanames{en}->{5984364} = "Trinidad\/Flores";
$areanames{en}->{598444} = "Minas\/Lavalleja";
$areanames{en}->{598445} = "Treinta\ y\ Tres";
$areanames{en}->{598447} = "Rocha";
$areanames{en}->{598452} = "Colonia\ del\ Scaramento";
$areanames{en}->{598453} = "Mercedes\/Soriano";
$areanames{en}->{598456} = "Fray\ Bentos\/Rio\ Negro";
$areanames{en}->{598462} = "Rivera";
$areanames{en}->{598463} = "Tacuarembo";
$areanames{en}->{598464} = "Melo\/Cerro\ Largo";
$areanames{en}->{598472} = "Paysandu";
$areanames{en}->{598473} = "Salto";
$areanames{en}->{598477} = "Artigas";

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