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
package Number::Phone::StubCountry::RS;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230307181422;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            (?:
              2[389]|
              39
            )0|
            [7-9]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3,9})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[1-36]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{5,10})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            11[1-9]\\d|
            (?:
              2[389]|
              39
            )(?:
              0[2-9]|
              [2-9]\\d
            )
          )\\d{3,8}|
          (?:
            1[02-9]|
            2[0-24-7]|
            3[0-8]
          )[2-9]\\d{4,9}
        ',
                'geographic' => '
          (?:
            11[1-9]\\d|
            (?:
              2[389]|
              39
            )(?:
              0[2-9]|
              [2-9]\\d
            )
          )\\d{3,8}|
          (?:
            1[02-9]|
            2[0-24-7]|
            3[0-8]
          )[2-9]\\d{4,9}
        ',
                'mobile' => '
          6(?:
            [0-689]|
            7\\d
          )\\d{6,7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          (?:
            78\\d|
            90[0169]
          )\\d{3,7}
        )|(7[06]\\d{4,10})',
                'toll_free' => '800\\d{3,9}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"38119", "Zajecar",
"38130", "Bor",
"38128", "Kosovska\ Mitrovica",
"38114", "Valjevo",
"38137", "Krusevac",
"38125", "Sombor",
"38121", "Novi\ Sad",
"38122", "Sremska\ Mitrovica",
"38120", "Novi\ Pazar",
"38138", "Pristina",
"38116", "Leskovac",
"38113", "Pancevo",
"381280", "Gnjilane",
"38135", "Jagodina",
"38131", "Uzice",
"38132", "Cacak",
"38127", "Prokuplje",
"38111", "Belgrade",
"38112", "Pozarevac",
"38115", "Sabac",
"38129", "Prizren",
"38133", "Prijepolje",
"38136", "Kraljevo",
"38118", "Nis",
"381390", "Dakovica",
"38124", "Subotica",
"381230", "Kikinda",
"38117", "Vranje",
"38126", "Smederevo",
"38134", "Kragujevac",
"381290", "Urosevac",
"38110", "Pirot",
"38139", "Pec",
"38123", "Zrenjanin",};
$areanames{sr} = {"38110", "Пирот",
"381290", "Урошевац",
"38134", "Крагујевац",
"38126", "Смедерево",
"38123", "Зрењанин",
"38139", "Пећ",
"38117", "Врање",
"38133", "Пријепоље",
"38129", "Призрен",
"381230", "Кикинда",
"38124", "Суботица",
"381390", "Ђаковица",
"38118", "Ниш",
"38136", "Краљево",
"38115", "Шабац",
"38112", "Пожаревац",
"38111", "Београд",
"38132", "Чачак",
"38131", "Ужице",
"38135", "Јагодина",
"38127", "Прокупље",
"38116", "Лесковац",
"38138", "Приштина",
"38120", "Нови\ Пазар",
"381280", "Гњилане",
"38113", "Панчево",
"38137", "Крушевац",
"38122", "Сремска\ Митровица",
"38121", "Нови\ Сад",
"38125", "Сомбор",
"38119", "Зајечар",
"38114", "Ваљево",
"38128", "Косовска\ Митровица",
"38130", "Бор",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+381|\D)//g;
      my $self = bless({ country_code => '381', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '381', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;