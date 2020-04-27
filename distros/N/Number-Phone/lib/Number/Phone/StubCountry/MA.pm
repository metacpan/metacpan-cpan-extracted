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
our $VERSION = 1.20200427120031;

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
              0[016-8]|
              6[1267]|
              7[0-27]
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
$areanames{fr}->{212520} = "Casablanca";
$areanames{fr}->{212521} = "Casablanca\/Maroc\ Central";
$areanames{fr}->{212522} = "Casablanca";
$areanames{fr}->{2125232} = "Mohammedia";
$areanames{fr}->{2125233} = "Mohammedia\/El\ Jadida";
$areanames{fr}->{2125234} = "Settat";
$areanames{fr}->{2125235} = "Oued\ Zem";
$areanames{fr}->{2125237} = "Settat";
$areanames{fr}->{2125242} = "El\ Kelaa\ des\ Sraghna";
$areanames{fr}->{2125243} = "Marrakech";
$areanames{fr}->{2125244} = "Marrakech";
$areanames{fr}->{2125246} = "Safi\/El\ Youssoufia";
$areanames{fr}->{2125247} = "Essaouira";
$areanames{fr}->{2125248} = "Ouarzazate";
$areanames{fr}->{212525} = "Maroc\ Sud";
$areanames{fr}->{2125282} = "Agadir\/Inezgane\/Ait\ Melou";
$areanames{fr}->{2125283} = "Inezgane\/Taroudannt";
$areanames{fr}->{2125285} = "Taroudannt\/Oulad\ Teima";
$areanames{fr}->{2125286} = "Tiznit";
$areanames{fr}->{2125287} = "Guelmim\/Tan\ Tan";
$areanames{fr}->{2125288} = "Es\-Semara\/Agadir\/Tarfaya";
$areanames{fr}->{2125289} = "Laayoune\/Dakhla";
$areanames{fr}->{2125290} = "Casablanca";
$areanames{fr}->{21252980} = "Marrakech\ et\ alentours";
$areanames{fr}->{21252990} = "Agadir\ et\ alentours";
$areanames{fr}->{212530} = "Rabat\/Kénitra";
$areanames{fr}->{212531} = "Tanger\/Tétouan\/Larache\/Al\ Hoceima\/Cherfchaouen";
$areanames{fr}->{212532} = "Fès\/Oujda\/Meknès\/Taza\/Nador\/Errachidia";
$areanames{fr}->{2125352} = "Taza";
$areanames{fr}->{2125353} = "Midelt";
$areanames{fr}->{2125354} = "Meknès";
$areanames{fr}->{2125355} = "Meknès";
$areanames{fr}->{2125356} = "Fès";
$areanames{fr}->{2125357} = "Goulmima";
$areanames{fr}->{2125358} = "Ifrane";
$areanames{fr}->{2125359} = "Fès";
$areanames{fr}->{2125362} = "Berkane";
$areanames{fr}->{2125363} = "Nador";
$areanames{fr}->{2125365} = "Oujda";
$areanames{fr}->{2125366} = "Oujda\/Figuig";
$areanames{fr}->{2125367} = "Oujda\/Bouarfa";
$areanames{fr}->{2125368} = "Figuig";
$areanames{fr}->{2125372} = "Rabat";
$areanames{fr}->{2125373} = "Kénitra";
$areanames{fr}->{2125374} = "Ouazzane";
$areanames{fr}->{2125375} = "Khémisset";
$areanames{fr}->{2125376} = "Rabat\/Témara";
$areanames{fr}->{2125377} = "Rabat";
$areanames{fr}->{2125378} = "Salé";
$areanames{fr}->{2125379} = "Souk\ Larbaa";
$areanames{fr}->{2125380} = "Rabat\ et\ alentours";
$areanames{fr}->{21253880} = "Tanger\ et\ alentours";
$areanames{fr}->{21253890} = "Fès\/Maknès\ et\ alentours";
$areanames{fr}->{2125393} = "Tanger";
$areanames{fr}->{2125394} = "Asilah";
$areanames{fr}->{2125395} = "Larache";
$areanames{fr}->{2125396} = "Fnideq\/Martil\/Mdiq";
$areanames{fr}->{2125397} = "Tétouan";
$areanames{fr}->{2125398} = "Al\ Hoceima\/Chefchaouen";
$areanames{fr}->{2125399} = "Tanger\/Larache\/Al\ Hoceima";
$areanames{en}->{212520} = "Casablanca";
$areanames{en}->{212521} = "Casablanca\/Central\ Morocco";
$areanames{en}->{212522} = "Casablanca";
$areanames{en}->{2125232} = "Mohammedia";
$areanames{en}->{2125233} = "El\ Jedida\/Mohammedia";
$areanames{en}->{2125234} = "Settai";
$areanames{en}->{2125235} = "Oued\ Zem";
$areanames{en}->{2125237} = "Settat";
$areanames{en}->{2125242} = "El\ Kelaa\ des\ Sraghna";
$areanames{en}->{2125243} = "Marrakech";
$areanames{en}->{2125244} = "Marrakech";
$areanames{en}->{2125246} = "El\ Youssoufia\/Safi";
$areanames{en}->{2125247} = "Essaouira";
$areanames{en}->{2125248} = "Ouarzazate";
$areanames{en}->{212525} = "Southern\ Morocco";
$areanames{en}->{2125282} = "Agadir\/Ait\ Meloul\/Inezgane";
$areanames{en}->{2125283} = "Inezgane\/Taroudant";
$areanames{en}->{2125285} = "Oulad\ Teima\/Taroudant";
$areanames{en}->{2125286} = "Tiznit";
$areanames{en}->{2125287} = "Guelmim\/Tan\ Tan";
$areanames{en}->{2125288} = "Agadir\/Es\-Semara\/Tarfaya";
$areanames{en}->{2125289} = "Dakhla\/Laayoune";
$areanames{en}->{2125290} = "Casablanca";
$areanames{en}->{21252980} = "Marrakech\ area";
$areanames{en}->{21252990} = "Agadir\ area";
$areanames{en}->{212530} = "Rabat\/Kènitra";
$areanames{en}->{212531} = "Tangier\/Al\ Hoceima\/Larache\/Tètouan\/Chefchaouen";
$areanames{en}->{212532} = "Fès\/Errachidia\/Meknès\/Nador\/Oujda\/Taza";
$areanames{en}->{2125352} = "Taza";
$areanames{en}->{2125353} = "Midelt";
$areanames{en}->{2125354} = "Meknès";
$areanames{en}->{2125355} = "Meknès";
$areanames{en}->{2125356} = "Fès";
$areanames{en}->{2125357} = "Goulmima";
$areanames{en}->{2125358} = "Ifrane";
$areanames{en}->{2125359} = "Fès";
$areanames{en}->{2125362} = "Berkane";
$areanames{en}->{2125363} = "Nador";
$areanames{en}->{2125365} = "Oujda";
$areanames{en}->{2125366} = "Figuig\/Oujda";
$areanames{en}->{2125367} = "Bouarfa\/Oujda";
$areanames{en}->{2125368} = "Figuig";
$areanames{en}->{2125372} = "Rabat";
$areanames{en}->{2125373} = "Kénitra";
$areanames{en}->{2125374} = "Ouazzane";
$areanames{en}->{2125375} = "Khémisset";
$areanames{en}->{2125376} = "Rabat\/Témara";
$areanames{en}->{2125377} = "Rabat";
$areanames{en}->{2125378} = "Salé";
$areanames{en}->{2125379} = "Souk\ Larbaa";
$areanames{en}->{2125380} = "Rabat\ area";
$areanames{en}->{21253880} = "Tangier\ area";
$areanames{en}->{21253890} = "Fès\/Meknès\ areas";
$areanames{en}->{2125393} = "Tangier";
$areanames{en}->{2125394} = "Asilah";
$areanames{en}->{2125395} = "Larache";
$areanames{en}->{2125396} = "Fnideq\/Martil\/Mdiq";
$areanames{en}->{2125397} = "Tétouan";
$areanames{en}->{2125398} = "Al\ Hoceima\/Chefchaouen";
$areanames{en}->{2125399} = "Al\ Hoceima\/Larache\/Tangier";

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