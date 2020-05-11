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
our $VERSION = 1.20200511123715;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '80',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{3})(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '1',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d)(\\d{7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[4-8]',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{6})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            (?:
              4[34]|
              5[14]
            )[0-8]\\d|
            7(?:
              173|
              3[0-8]\\d
            )|
            8(?:
              10[05689]|
              6(?:
                0[06-9]|
                1[6-9]|
                29
              )|
              7(?:
                0[569]|
                [56]0
              )
            )
          )\\d{4}|
          (?:
            1[0-8]|
            4[12]|
            5[236]|
            6[1-7]|
            7[246]|
            8[2-4]
          )\\d{6}
        ',
                'geographic' => '
          (?:
            (?:
              4[34]|
              5[14]
            )[0-8]\\d|
            7(?:
              173|
              3[0-8]\\d
            )|
            8(?:
              10[05689]|
              6(?:
                0[06-9]|
                1[6-9]|
                29
              )|
              7(?:
                0[569]|
                [56]0
              )
            )
          )\\d{4}|
          (?:
            1[0-8]|
            4[12]|
            5[236]|
            6[1-7]|
            7[246]|
            8[2-4]
          )\\d{6}
        ',
                'mobile' => '9\\d{8}',
                'pager' => '',
                'personal_number' => '80[24]\\d{5}',
                'specialrate' => '(801\\d{5})|(805\\d{5})',
                'toll_free' => '800\\d{5}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{511} = "Lima\/Callao";
$areanames{en}->{5141} = "Amazonas";
$areanames{en}->{5142} = "San\ Martín";
$areanames{en}->{5143} = "Ancash";
$areanames{en}->{5144} = "La\ Libertad";
$areanames{en}->{5151} = "Puno";
$areanames{en}->{5152} = "Tacna";
$areanames{en}->{5153} = "Moquegua";
$areanames{en}->{5154} = "Arequipa";
$areanames{en}->{5156} = "Ica";
$areanames{en}->{5161} = "Ucayali";
$areanames{en}->{5162} = "Huánuco";
$areanames{en}->{5163} = "Pasco";
$areanames{en}->{5164} = "Junín";
$areanames{en}->{5165} = "Loreto";
$areanames{en}->{5166} = "Ayacucho";
$areanames{en}->{5167} = "Huancavelica";
$areanames{en}->{5172} = "Tumbes";
$areanames{en}->{5173} = "Piura";
$areanames{en}->{5174} = "Lambayeque";
$areanames{en}->{5176} = "Cajamarca";
$areanames{en}->{5182} = "Madre\ de\ Dios";
$areanames{en}->{5183} = "Apurímac";
$areanames{en}->{5184} = "Cusco";

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