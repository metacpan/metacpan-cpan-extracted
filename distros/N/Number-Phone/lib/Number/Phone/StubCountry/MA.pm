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
package Number::Phone::StubCountry::MA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210204173826;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '
            5(?:
              29|
              38
            )[89]0
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{5})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '5[45]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '
            5(?:
              2(?:
                [2-49]|
                8[235-9]
              )|
              3[5-9]|
              9
            )|
            892
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4})(\\d{5})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{7})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '[5-7]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{6})'
                }
              ];

my $validators = {
                'fixed_line' => '
          5(?:
            29(?:
              [189][05]|
              2[29]|
              3[01]
            )|
            38[89][05]
          )\\d{4}|
          5(?:
            2(?:
              [015-7]\\d|
              2[02-9]|
              3[0-578]|
              4[02-46-8]|
              8[0235-7]|
              90
            )|
            3(?:
              [0-47]\\d|
              5[02-9]|
              6[02-8]|
              80|
              9[3-9]
            )|
            (?:
              4[067]|
              5[03]
            )\\d
          )\\d{5}
        ',
                'geographic' => '
          5(?:
            29(?:
              [189][05]|
              2[29]|
              3[01]
            )|
            38[89][05]
          )\\d{4}|
          5(?:
            2(?:
              [015-7]\\d|
              2[02-9]|
              3[0-578]|
              4[02-46-8]|
              8[0235-7]|
              90
            )|
            3(?:
              [0-47]\\d|
              5[02-9]|
              6[02-8]|
              80|
              9[3-9]
            )|
            (?:
              4[067]|
              5[03]
            )\\d
          )\\d{5}
        ',
                'mobile' => '
          (?:
            6(?:
              [0-79]\\d|
              8[0-247-9]
            )|
            7(?:
              0[0-8]|
              6[1267]|
              7[0-37]
            )
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(89\\d{7})',
                'toll_free' => '80\\d{7}',
                'voip' => '
          592(?:
            4[0-2]|
            93
          )\\d{4}
        '
              };
my %areanames = ();
$areanames{en} = {"2125243", "Marrakech",
"2125234", "Settai",
"2125365", "Oujda",
"2125287", "Guelmim\/Tan\ Tan",
"21252990", "Agadir\ area",
"2125362", "Berkane",
"2125358", "Ifrane",
"2125237", "Settat",
"2125355", "Meknès",
"2125352", "Taza",
"2125368", "Figuig",
"2125393", "Tangier",
"2125375", "Khémisset",
"2125286", "Tiznit",
"2125372", "Rabat",
"2125399", "Al\ Hoceima\/Larache\/Tangier",
"2125378", "Salé",
"2125353", "Midelt",
"2125248", "Ouarzazate",
"2125395", "Larache",
"2125363", "Nador",
"2125398", "Al\ Hoceima\/Chefchaouen",
"2125242", "El\ Kelaa\ des\ Sraghna",
"2125379", "Souk\ Larbaa",
"21252980", "Marrakech\ area",
"2125359", "Fès",
"2125373", "Kénitra",
"2125290", "Casablanca",
"212522", "Casablanca",
"2125366", "Figuig\/Oujda",
"212525", "Southern\ Morocco",
"2125377", "Rabat",
"21253880", "Tangier\ area",
"2125374", "Ouazzane",
"2125356", "Fès",
"2125380", "Rabat\ area",
"212531", "Tangier\/Al\ Hoceima\/Larache\/Tètouan\/Chefchaouen",
"2125285", "Oulad\ Teima\/Taroudant",
"2125367", "Bouarfa\/Oujda",
"2125354", "Meknès",
"2125376", "Rabat\/Témara",
"2125282", "Agadir\/Ait\ Meloul\/Inezgane",
"2125357", "Goulmima",
"2125235", "Oued\ Zem",
"212520", "Casablanca",
"2125288", "Agadir\/Es\-Semara\/Tarfaya",
"2125232", "Mohammedia",
"2125396", "Fnideq\/Martil\/Mdiq",
"2125246", "El\ Youssoufia\/Safi",
"2125289", "Dakhla\/Laayoune",
"212530", "Rabat\/Kènitra",
"2125244", "Marrakech",
"2125233", "El\ Jedida\/Mohammedia",
"212532", "Fès\/Errachidia\/Meknès\/Nador\/Oujda\/Taza",
"2125397", "Tétouan",
"21253890", "Fès\/Meknès\ areas",
"2125247", "Essaouira",
"212521", "Casablanca\/Central\ Morocco",
"2125283", "Inezgane\/Taroudant",
"2125394", "Asilah",};
$areanames{fr} = {"21252990", "Agadir\ et\ alentours",
"2125234", "Settat",
"2125393", "Tanger",
"2125399", "Tanger\/Larache\/Al\ Hoceima",
"21252980", "Marrakech\ et\ alentours",
"212525", "Maroc\ Sud",
"2125366", "Oujda\/Figuig",
"21253880", "Tanger\ et\ alentours",
"2125380", "Rabat\ et\ alentours",
"212531", "Tanger\/Tétouan\/Larache\/Al\ Hoceima\/Cherfchaouen",
"2125285", "Taroudannt\/Oulad\ Teima",
"2125367", "Oujda\/Bouarfa",
"2125282", "Agadir\/Inezgane\/Ait\ Melou",
"2125288", "Es\-Semara\/Agadir\/Tarfaya",
"2125246", "Safi\/El\ Youssoufia",
"212530", "Rabat\/Kénitra",
"2125289", "Laayoune\/Dakhla",
"212532", "Fès\/Oujda\/Meknès\/Taza\/Nador\/Errachidia",
"2125233", "Mohammedia\/El\ Jadida",
"21253890", "Fès\/Maknès\ et\ alentours",
"2125283", "Inezgane\/Taroudannt",
"212521", "Casablanca\/Maroc\ Central",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+212|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;