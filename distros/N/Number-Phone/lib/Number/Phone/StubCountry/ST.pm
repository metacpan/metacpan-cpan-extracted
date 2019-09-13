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
package Number::Phone::StubCountry::ST;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215428;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[29]',
                  'pattern' => '(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '22\\d{5}',
                'geographic' => '22\\d{5}',
                'mobile' => '
          900[5-9]\\d{3}|
          9(?:
            0[1-9]|
            [89]\\d
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{pt}->{2392220} = "Santo\ Amaro";
$areanames{pt}->{2392221} = "Água\ Grande";
$areanames{pt}->{2392222} = "Água\ Grande";
$areanames{pt}->{2392223} = "Água\ Grande";
$areanames{pt}->{2392224} = "Água\ Grande";
$areanames{pt}->{2392225} = "Água\ Grande";
$areanames{pt}->{2392226} = "Água\ Grande";
$areanames{pt}->{2392227} = "Água\ Grande";
$areanames{pt}->{2392228} = "Água\ Grande";
$areanames{pt}->{2392231} = "Guadalupe";
$areanames{pt}->{2392233} = "Neves\,\ Santa\ Catarina";
$areanames{pt}->{239224} = "Água\ Grande";
$areanames{pt}->{2392251} = "Região\ Autonoma\ do\ Príncipe";
$areanames{pt}->{2392261} = "Angolares\,\ Porto\ Alegre";
$areanames{pt}->{2392265} = "Santana\,\ Ribeira\ Afonso";
$areanames{pt}->{2392271} = "Trindade";
$areanames{pt}->{2392272} = "Madalena";
$areanames{pt}->{239228} = "Água\ Grande";
$areanames{pt}->{239229} = "Água\ Grande";
$areanames{en}->{2392220} = "Santo\ Amaro";
$areanames{en}->{2392221} = "Água\ Grande";
$areanames{en}->{2392222} = "Água\ Grande";
$areanames{en}->{2392223} = "Água\ Grande";
$areanames{en}->{2392224} = "Água\ Grande";
$areanames{en}->{2392225} = "Água\ Grande";
$areanames{en}->{2392226} = "Água\ Grande";
$areanames{en}->{2392227} = "Água\ Grande";
$areanames{en}->{2392228} = "Água\ Grande";
$areanames{en}->{2392231} = "Guadalupe";
$areanames{en}->{2392233} = "Neves\,\ Santa\ Catarina";
$areanames{en}->{239224} = "Água\ Grande";
$areanames{en}->{2392251} = "Autonomous\ Region\ of\ Príncipe";
$areanames{en}->{2392261} = "Angolares\,\ Porto\ Alegre";
$areanames{en}->{2392265} = "Santana\,\ Ribeira\ Afonso";
$areanames{en}->{2392271} = "Trindade";
$areanames{en}->{2392272} = "Madalena";
$areanames{en}->{239228} = "Água\ Grande";
$areanames{en}->{239229} = "Água\ Grande";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+239|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;