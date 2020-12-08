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
package Number::Phone::StubCountry::EH;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20201204215956;

my $formatters = [];

my $validators = {
                'fixed_line' => '528[89]\\d{5}',
                'geographic' => '528[89]\\d{5}',
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
$areanames{fr} = {"2125380", "Rabat\ et\ alentours",
"2125399", "Tanger\/Larache\/Al\ Hoceima",
"212521", "Casablanca\/Maroc\ Central",
"2125367", "Oujda\/Bouarfa",
"2125285", "Taroudannt\/Oulad\ Teima",
"21252980", "Marrakech\ et\ alentours",
"2125234", "Settat",
"2125246", "Safi\/El\ Youssoufia",
"2125283", "Inezgane\/Taroudannt",
"21252990", "Agadir\ et\ alentours",
"2125289", "Laayoune\/Dakhla",
"212525", "Maroc\ Sud",
"212530", "Rabat\/Kénitra",
"21253880", "Tanger\ et\ alentours",
"2125366", "Oujda\/Figuig",
"212531", "Tanger\/Tétouan\/Larache\/Al\ Hoceima\/Cherfchaouen",
"2125288", "Es\-Semara\/Agadir\/Tarfaya",
"2125233", "Mohammedia\/El\ Jadida",
"21253890", "Fès\/Maknès\ et\ alentours",
"212532", "Fès\/Oujda\/Meknès\/Taza\/Nador\/Errachidia",
"2125282", "Agadir\/Inezgane\/Ait\ Melou",
"2125393", "Tanger",};
$areanames{en} = {"2125395", "Larache",
"2125376", "Rabat\/Témara",
"2125286", "Tiznit",
"21253880", "Tangier\ area",
"2125359", "Fès",
"2125237", "Settat",
"2125366", "Figuig\/Oujda",
"212525", "Southern\ Morocco",
"2125289", "Dakhla\/Laayoune",
"2125235", "Oued\ Zem",
"2125379", "Souk\ Larbaa",
"2125243", "Marrakech",
"2125397", "Tétouan",
"2125290", "Casablanca",
"212530", "Rabat\/Kènitra",
"2125356", "Fès",
"2125247", "Essaouira",
"2125362", "Berkane",
"21253890", "Fès\/Meknès\ areas",
"212532", "Fès\/Errachidia\/Meknès\/Nador\/Oujda\/Taza",
"2125282", "Agadir\/Ait\ Meloul\/Inezgane",
"2125374", "Ouazzane",
"2125358", "Ifrane",
"2125393", "Tangier",
"2125372", "Rabat",
"2125352", "Taza",
"212531", "Tangier\/Al\ Hoceima\/Larache\/Tètouan\/Chefchaouen",
"2125378", "Salé",
"2125354", "Meknès",
"2125288", "Agadir\/Es\-Semara\/Tarfaya",
"2125233", "El\ Jedida\/Mohammedia",
"2125368", "Figuig",
"2125365", "Oujda",
"2125248", "Ouarzazate",
"2125285", "Oulad\ Teima\/Taroudant",
"2125357", "Goulmima",
"212522", "Casablanca",
"21252980", "Marrakech\ area",
"2125375", "Khémisset",
"2125396", "Fnideq\/Martil\/Mdiq",
"2125380", "Rabat\ area",
"2125287", "Guelmim\/Tan\ Tan",
"2125355", "Meknès",
"2125377", "Rabat",
"2125367", "Bouarfa\/Oujda",
"212521", "Casablanca\/Central\ Morocco",
"2125244", "Marrakech",
"2125242", "El\ Kelaa\ des\ Sraghna",
"2125399", "Al\ Hoceima\/Larache\/Tangier",
"2125394", "Asilah",
"2125373", "Kénitra",
"2125283", "Inezgane\/Taroudant",
"21252990", "Agadir\ area",
"2125363", "Nador",
"2125232", "Mohammedia",
"212520", "Casablanca",
"2125234", "Settai",
"2125246", "El\ Youssoufia\/Safi",
"2125353", "Midelt",
"2125398", "Al\ Hoceima\/Chefchaouen",};

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