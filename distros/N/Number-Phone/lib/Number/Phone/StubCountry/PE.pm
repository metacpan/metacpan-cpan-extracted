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
package Number::Phone::StubCountry::PE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190611222641;

my $formatters = [
                {
                  'leading_digits' => '80',
                  'national_rule' => '(0$1)',
                  'format' => '$1 $2',
                  'pattern' => '(\\d{3})(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d)(\\d{7})',
                  'leading_digits' => '1'
                },
                {
                  'format' => '$1 $2',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{6})',
                  'leading_digits' => '[4-8]'
                },
                {
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})',
                  'leading_digits' => '9'
                }
              ];

my $validators = {
                'personal_number' => '80[24]\\d{5}',
                'toll_free' => '800\\d{5}',
                'mobile' => '9\\d{8}',
                'pager' => '',
                'voip' => '',
                'fixed_line' => '
          19(?:
            [02-68]\\d|
            1[035-9]|
            7[0-689]|
            9[1-9]
          )\\d{4}|
          (?:
            1[0-8]|
            4[1-4]|
            5[1-46]|
            6[1-7]|
            7[2-46]|
            8[2-4]
          )\\d{6}
        ',
                'geographic' => '
          19(?:
            [02-68]\\d|
            1[035-9]|
            7[0-689]|
            9[1-9]
          )\\d{4}|
          (?:
            1[0-8]|
            4[1-4]|
            5[1-46]|
            6[1-7]|
            7[2-46]|
            8[2-4]
          )\\d{6}
        ',
                'specialrate' => '(801\\d{5})|(805\\d{5})'
              };
my %areanames = (
  511 => "Lima\/Callao",
  5141 => "Amazonas",
  5142 => "San\ Martín",
  5143 => "Ancash",
  5144 => "La\ Libertad",
  5151 => "Puno",
  5152 => "Tacna",
  5153 => "Moquegua",
  5154 => "Arequipa",
  5156 => "Ica",
  5161 => "Ucayali",
  5162 => "Huánuco",
  5163 => "Pasco",
  5164 => "Junín",
  5165 => "Loreto",
  5166 => "Ayacucho",
  5167 => "Huancavelica",
  5172 => "Tumbes",
  5173 => "Piura",
  5174 => "Lambayeque",
  5176 => "Cajamarca",
  5182 => "Madre\ de\ Dios",
  5183 => "Apurímac",
  5184 => "Cusco",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+51|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;