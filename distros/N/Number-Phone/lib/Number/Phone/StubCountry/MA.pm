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
our $VERSION = 1.20201204215957;

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
$areanames{en} = {"212530", "Rabat\/Kènitra",
"2125290", "Casablanca",
"2125397", "Tétouan",
"2125356", "Fès",
"2125235", "Oued\ Zem",
"2125289", "Dakhla\/Laayoune",
"212525", "Southern\ Morocco",
"2125379", "Souk\ Larbaa",
"2125243", "Marrakech",
"2125237", "Settat",
"2125359", "Fès",
"2125366", "Figuig\/Oujda",
"2125376", "Rabat\/Témara",
"2125395", "Larache",
"21253880", "Tangier\ area",
"2125286", "Tiznit",
"2125368", "Figuig",
"2125233", "El\ Jedida\/Mohammedia",
"2125354", "Meknès",
"2125378", "Salé",
"212531", "Tangier\/Al\ Hoceima\/Larache\/Tètouan\/Chefchaouen",
"2125352", "Taza",
"2125288", "Agadir\/Es\-Semara\/Tarfaya",
"2125282", "Agadir\/Ait\ Meloul\/Inezgane",
"2125372", "Rabat",
"2125393", "Tangier",
"2125374", "Ouazzane",
"2125358", "Ifrane",
"21253890", "Fès\/Meknès\ areas",
"2125362", "Berkane",
"2125247", "Essaouira",
"212532", "Fès\/Errachidia\/Meknès\/Nador\/Oujda\/Taza",
"2125242", "El\ Kelaa\ des\ Sraghna",
"2125399", "Al\ Hoceima\/Larache\/Tangier",
"2125244", "Marrakech",
"2125367", "Bouarfa\/Oujda",
"212521", "Casablanca\/Central\ Morocco",
"2125355", "Meknès",
"2125287", "Guelmim\/Tan\ Tan",
"2125380", "Rabat\ area",
"2125377", "Rabat",
"2125357", "Goulmima",
"2125285", "Oulad\ Teima\/Taroudant",
"2125396", "Fnideq\/Martil\/Mdiq",
"2125375", "Khémisset",
"21252980", "Marrakech\ area",
"212522", "Casablanca",
"2125365", "Oujda",
"2125248", "Ouarzazate",
"2125398", "Al\ Hoceima\/Chefchaouen",
"2125353", "Midelt",
"2125234", "Settai",
"212520", "Casablanca",
"2125232", "Mohammedia",
"2125246", "El\ Youssoufia\/Safi",
"21252990", "Agadir\ area",
"2125363", "Nador",
"2125373", "Kénitra",
"2125394", "Asilah",
"2125283", "Inezgane\/Taroudant",};
$areanames{fr} = {"21252990", "Agadir\ et\ alentours",
"2125283", "Inezgane\/Taroudannt",
"2125246", "Safi\/El\ Youssoufia",
"2125234", "Settat",
"21252980", "Marrakech\ et\ alentours",
"2125285", "Taroudannt\/Oulad\ Teima",
"2125399", "Tanger\/Larache\/Al\ Hoceima",
"212521", "Casablanca\/Maroc\ Central",
"2125367", "Oujda\/Bouarfa",
"2125380", "Rabat\ et\ alentours",
"2125393", "Tanger",
"2125282", "Agadir\/Inezgane\/Ait\ Melou",
"212532", "Fès\/Oujda\/Meknès\/Taza\/Nador\/Errachidia",
"21253890", "Fès\/Maknès\ et\ alentours",
"2125233", "Mohammedia\/El\ Jadida",
"2125288", "Es\-Semara\/Agadir\/Tarfaya",
"212531", "Tanger\/Tétouan\/Larache\/Al\ Hoceima\/Cherfchaouen",
"2125366", "Oujda\/Figuig",
"21253880", "Tanger\ et\ alentours",
"212530", "Rabat\/Kénitra",
"212525", "Maroc\ Sud",
"2125289", "Laayoune\/Dakhla",};

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