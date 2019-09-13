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
package Number::Phone::StubCountry::RS;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215427;

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
$areanames{sr}->{38110} = "Пирот";
$areanames{sr}->{38111} = "Београд";
$areanames{sr}->{38112} = "Пожаревац";
$areanames{sr}->{38113} = "Панчево";
$areanames{sr}->{38114} = "Ваљево";
$areanames{sr}->{38115} = "Шабац";
$areanames{sr}->{38116} = "Лесковац";
$areanames{sr}->{38117} = "Врање";
$areanames{sr}->{38118} = "Ниш";
$areanames{sr}->{38119} = "Зајечар";
$areanames{sr}->{38120} = "Нови\ Пазар";
$areanames{sr}->{38121} = "Нови\ Сад";
$areanames{sr}->{38122} = "Сремска\ Митровица";
$areanames{sr}->{38123} = "Зрењанин";
$areanames{sr}->{381230} = "Кикинда";
$areanames{sr}->{38124} = "Суботица";
$areanames{sr}->{38125} = "Сомбор";
$areanames{sr}->{38126} = "Смедерево";
$areanames{sr}->{38127} = "Прокупље";
$areanames{sr}->{38128} = "Косовска\ Митровица";
$areanames{sr}->{381280} = "Гњилане";
$areanames{sr}->{38129} = "Призрен";
$areanames{sr}->{381290} = "Урошевац";
$areanames{sr}->{38130} = "Бор";
$areanames{sr}->{38131} = "Ужице";
$areanames{sr}->{38132} = "Чачак";
$areanames{sr}->{38133} = "Пријепоље";
$areanames{sr}->{38134} = "Крагујевац";
$areanames{sr}->{38135} = "Јагодина";
$areanames{sr}->{38136} = "Краљево";
$areanames{sr}->{38137} = "Крушевац";
$areanames{sr}->{38138} = "Приштина";
$areanames{sr}->{38139} = "Пећ";
$areanames{sr}->{381390} = "Ђаковица";
$areanames{en}->{38110} = "Pirot";
$areanames{en}->{38111} = "Belgrade";
$areanames{en}->{38112} = "Pozarevac";
$areanames{en}->{38113} = "Pancevo";
$areanames{en}->{38114} = "Valjevo";
$areanames{en}->{38115} = "Sabac";
$areanames{en}->{38116} = "Leskovac";
$areanames{en}->{38117} = "Vranje";
$areanames{en}->{38118} = "Nis";
$areanames{en}->{38119} = "Zajecar";
$areanames{en}->{38120} = "Novi\ Pazar";
$areanames{en}->{38121} = "Novi\ Sad";
$areanames{en}->{38122} = "Sremska\ Mitrovica";
$areanames{en}->{38123} = "Zrenjanin";
$areanames{en}->{381230} = "Kikinda";
$areanames{en}->{38124} = "Subotica";
$areanames{en}->{38125} = "Sombor";
$areanames{en}->{38126} = "Smederevo";
$areanames{en}->{38127} = "Prokuplje";
$areanames{en}->{38128} = "Kosovska\ Mitrovica";
$areanames{en}->{381280} = "Gnjilane";
$areanames{en}->{38129} = "Prizren";
$areanames{en}->{381290} = "Urosevac";
$areanames{en}->{38130} = "Bor";
$areanames{en}->{38131} = "Uzice";
$areanames{en}->{38132} = "Cacak";
$areanames{en}->{38133} = "Prijepolje";
$areanames{en}->{38134} = "Kragujevac";
$areanames{en}->{38135} = "Jagodina";
$areanames{en}->{38136} = "Kraljevo";
$areanames{en}->{38137} = "Krusevac";
$areanames{en}->{38138} = "Pristina";
$areanames{en}->{38139} = "Pec";
$areanames{en}->{381390} = "Dakovica";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+381|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;