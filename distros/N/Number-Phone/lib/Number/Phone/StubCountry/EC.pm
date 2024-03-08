# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::EC;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240308154351;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'intl_format' => 'NA',
                  'leading_digits' => '[2-7]',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2-$3',
                  'intl_format' => '$1-$2-$3',
                  'leading_digits' => '[2-7]',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{3,4})'
                }
              ];

my $validators = {
                'fixed_line' => '[2-7][2-7]\\d{6}',
                'geographic' => '[2-7][2-7]\\d{6}',
                'mobile' => '
          964[0-2]\\d{5}|
          9(?:
            39|
            [57][89]|
            6[0-36-9]|
            [89]\\d
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '
          1800\\d{7}|
          1[78]00\\d{6}
        ',
                'voip' => '[2-7]890\\d{4}'
              };
my %areanames = ();
$areanames{en} = {"59344", "Guayas",
"59326", "Carchi\/Imbabura\/Esmeraldas\/Sucumbíos\/Napo\/Orellana",
"59322", "Pichincha",
"59345", "Manabí\/Los\ Ríos\/Galápagos",
"59323", "Cotopaxi\/Tungurahua\/Chimborazo\/Bolívar\/Pastaza",
"59327", "Azuay\/Cañar\/Morona\ Santiago",
"59347", "Loja\/El\ Oro\/Zamora\ Chinchipe",};
my $timezones = {
               '' => [
                       'America/Guayaquil',
                       'Pacific/Galapagos'
                     ],
               '1' => [
                        'America/Guayaquil',
                        'Pacific/Galapagos'
                      ],
               '2' => [
                        'America/Guayaquil'
                      ],
               '3' => [
                        'America/Guayaquil'
                      ],
               '4' => [
                        'America/Guayaquil'
                      ],
               '5' => [
                        'America/Guayaquil'
                      ],
               '52' => [
                         'America/Guayaquil',
                         'Pacific/Galapagos'
                       ],
               '6' => [
                        'America/Guayaquil'
                      ],
               '7' => [
                        'America/Guayaquil'
                      ],
               '9' => [
                        'America/Guayaquil'
                      ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+593|\D)//g;
      my $self = bless({ country_code => '593', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '593', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;