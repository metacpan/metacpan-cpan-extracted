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
package Number::Phone::StubCountry::LT;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200309202347;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '52[0-7]',
                  'national_rule' => '(8-$1)',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[7-9]',
                  'national_rule' => '8 $1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            37|
            4(?:
              [15]|
              6[1-8]
            )
          ',
                  'national_rule' => '(8-$1)',
                  'pattern' => '(\\d{2})(\\d{6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[3-6]',
                  'national_rule' => '(8-$1)',
                  'pattern' => '(\\d{3})(\\d{5})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            3[1478]|
            4[124-6]|
            52
          )\\d{6}
        ',
                'geographic' => '
          (?:
            3[1478]|
            4[124-6]|
            52
          )\\d{6}
        ',
                'mobile' => '6\\d{7}',
                'pager' => '',
                'personal_number' => '70[05]\\d{5}',
                'specialrate' => '(808\\d{5})|(
          9(?:
            0[0239]|
            10
          )\\d{5}
        )|(70[67]\\d{5})',
                'toll_free' => '80[02]\\d{5}',
                'voip' => '[89]01\\d{5}'
              };
my %areanames = ();
$areanames{en}->{370310} = "Varėna";
$areanames{en}->{370313} = "Druskininkai";
$areanames{en}->{370315} = "Alytus";
$areanames{en}->{370318} = "Lazdijai";
$areanames{en}->{370319} = "Birštonas\/Prienai";
$areanames{en}->{370340} = "Ukmergė";
$areanames{en}->{370342} = "Vilkaviškis";
$areanames{en}->{370343} = "Marijampolė";
$areanames{en}->{370345} = "Šakiai";
$areanames{en}->{370346} = "Kaišiadorys";
$areanames{en}->{370347} = "Kėdainiai";
$areanames{en}->{370349} = "Jonava";
$areanames{en}->{37037} = "Kaunas";
$areanames{en}->{370380} = "Šalčininkai";
$areanames{en}->{370381} = "Anykščiai";
$areanames{en}->{370382} = "Širvintos";
$areanames{en}->{370383} = "Molėtai";
$areanames{en}->{370385} = "Zarasai";
$areanames{en}->{370386} = "Ignalina\/Visaginas";
$areanames{en}->{370387} = "Švenčionys";
$areanames{en}->{370389} = "Utena";
$areanames{en}->{37041} = "Šiauliai";
$areanames{en}->{370421} = "Pakruojis";
$areanames{en}->{370422} = "Radviliškis";
$areanames{en}->{370425} = "Akmenė";
$areanames{en}->{370426} = "Joniškis";
$areanames{en}->{370427} = "Kelmė";
$areanames{en}->{370428} = "Raseiniai";
$areanames{en}->{370440} = "Skuodas";
$areanames{en}->{370441} = "Šilutė";
$areanames{en}->{370443} = "Mažeikiai";
$areanames{en}->{370444} = "Telšiai";
$areanames{en}->{370445} = "Kretinga";
$areanames{en}->{370446} = "Tauragė";
$areanames{en}->{370447} = "Jurbarkas";
$areanames{en}->{370448} = "Plungė";
$areanames{en}->{370449} = "Šilalė";
$areanames{en}->{37045} = "Panevėžys";
$areanames{en}->{370450} = "Biržai";
$areanames{en}->{370451} = "Pasvalys";
$areanames{en}->{370458} = "Rokiškis";
$areanames{en}->{370459} = "Kupiškis";
$areanames{en}->{37046} = "Klaipėda";
$areanames{en}->{370460} = "Palanga";
$areanames{en}->{370469} = "Neringa";
$areanames{en}->{370520} = "Vilnius";
$areanames{en}->{370521} = "Vilnius";
$areanames{en}->{370522} = "Vilnius";
$areanames{en}->{370523} = "Vilnius";
$areanames{en}->{370524} = "Vilnius";
$areanames{en}->{370525} = "Vilnius";
$areanames{en}->{370526} = "Vilnius";
$areanames{en}->{370527} = "Vilnius";
$areanames{en}->{370528} = "Trakai";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+370|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:[08])//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;