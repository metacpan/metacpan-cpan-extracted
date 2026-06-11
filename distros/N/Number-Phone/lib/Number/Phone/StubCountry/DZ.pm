# automatically generated file, don't edit



# Copyright 2026 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::DZ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20260610205502;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[1-4]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[5-8]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          9619\\d{5}|
          (?:
            [1-3]\\d|
            4[013-689]
          )\\d{6}
        ',
                'geographic' => '
          9619\\d{5}|
          (?:
            [1-3]\\d|
            4[013-689]
          )\\d{6}
        ',
                'mobile' => '
          5(?:
            4[0-29]|
            6[0-4]
          )\\d{6}|
          (?:
            55|
            6\\d|
            7[7-9]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(80[12]1\\d{5})|(80[3-689]1\\d{5})',
                'toll_free' => '800\\d{6}',
                'voip' => '98[23]\\d{6}'
              };
my %areanames = ();
$areanames{en} = {"21322", "Algiers",
"21329", "Ghardaia\/Illizi\/Tamanrasset",
"21341", "Oran",
"21327", "Chlef",
"21338", "Annaba\/Skikda",
"21326", "Bouira\/Tizi\ Ouzou",
"21325", "Blida\/Médéa",
"21334", "Béjaïa\/Jijel",
"21321", "Algiers",
"21333", "Batna\/Beskra",
"21349", "Adrar\/Béchar\/Tindouf",
"21344", "Blida",
"21343", "Tlemcen",
"21337", "Tebessa",
"21332", "El\ Oued",
"21339", "Skikda",
"21328", "Algiers",
"21335", "Bordj\ Bou\ Arreridj",
"21324", "Boumerdès\/Tipaza",
"21331", "Constantine",
"21323", "Algiers",};
my $timezones = {
               '' => [
                       'Europe/Paris'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+213|\D)//g;
      my $self = bless({ country_code => '213', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '213', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;