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
package Number::Phone::StubCountry::LT;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230903131448;

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
$areanames{en} = {"370349", "Jonava",
"37037", "Kaunas",
"370340", "Ukmergė",
"370381", "Anykščiai",
"370346", "Kaišiadorys",
"370343", "Marijampolė",
"370422", "Radviliškis",
"370459", "Kupiškis",
"370450", "Biržai",
"370385", "Zarasai",
"370458", "Rokiškis",
"370383", "Molėtai",
"370386", "Ignalina\/Visaginas",
"370345", "Šakiai",
"370451", "Pasvalys",
"370427", "Kelmė",
"370389", "Utena",
"370380", "Šalčininkai",
"370382", "Širvintos",
"370425", "Akmenė",
"370347", "Kėdainiai",
"370421", "Pakruojis",
"370387", "Švenčionys",
"370428", "Raseiniai",
"370426", "Joniškis",
"370342", "Vilkaviškis",
"370469", "Neringa",
"370460", "Palanga",
"370315", "Alytus",
"37045", "Panevėžys",
"370522", "Vilnius",
"370447", "Jurbarkas",
"370318", "Lazdijai",
"370527", "Vilnius",
"370310", "Varėna",
"370319", "Birštonas\/Prienai",
"370313", "Druskininkai",
"370440", "Skuodas",
"370521", "Vilnius",
"370449", "Šilalė",
"370524", "Vilnius",
"370448", "Plungė",
"370525", "Vilnius",
"370446", "Tauragė",
"370443", "Mažeikiai",
"37046", "Klaipėda",
"370526", "Vilnius",
"370523", "Vilnius",
"370445", "Kretinga",
"37041", "Šiauliai",
"370444", "Telšiai",
"370528", "Trakai",
"370441", "Šilutė",
"370520", "Vilnius",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+370|\D)//g;
      my $self = bless({ country_code => '370', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:[08])//;
      $self = bless({ country_code => '370', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;