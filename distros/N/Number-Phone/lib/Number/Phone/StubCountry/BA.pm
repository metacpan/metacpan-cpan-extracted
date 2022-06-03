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
package Number::Phone::StubCountry::BA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220601185315;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'intl_format' => 'NA',
                  'leading_digits' => '[2-9]',
                  'pattern' => '(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            6[1-3]|
            [7-9]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2-$3',
                  'leading_digits' => '
            [3-5]|
            6[56]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '6',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            3(?:
              [05-79][2-9]|
              1[4579]|
              [23][24-9]|
              4[2-4689]|
              8[2457-9]
            )|
            49[2-579]|
            5(?:
              0[2-49]|
              [13][2-9]|
              [268][2-4679]|
              4[4689]|
              5[2-79]|
              7[2-69]|
              9[2-4689]
            )
          )\\d{5}
        ',
                'geographic' => '
          (?:
            3(?:
              [05-79][2-9]|
              1[4579]|
              [23][24-9]|
              4[2-4689]|
              8[2457-9]
            )|
            49[2-579]|
            5(?:
              0[2-49]|
              [13][2-9]|
              [268][2-4679]|
              4[4689]|
              5[2-79]|
              7[2-69]|
              9[2-4689]
            )
          )\\d{5}
        ',
                'mobile' => '
          6040\\d{5}|
          6(?:
            03|
            [1-356]|
            44|
            7\\d
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(8[12]\\d{6})|(9[0246]\\d{6})|(
          703[235]0\\d{3}|
          70(?:
            2[0-5]|
            3[0146]|
            [56]0
          )\\d{4}
        )',
                'toll_free' => '8[08]\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{sr} = {"38735", "Тузлански\ кантон",
"38732", "Зеничко\-добојски\ кантон",
"38751", "Бања\ Лука",
"38733", "Сарајевски\ кантон",
"38734", "Кантон\ 10",
"38755", "Бијељина",
"38753", "Добој",
"38754", "Шамац",
"38731", "Посавски\ кантон",
"38756", "Зворник",
"38752", "Приједор",
"38758", "Фоча",
"3874", "Брчко\ Дистрикт",
"38737", "Унско\-сански\ кантон",
"38730", "Средњoбосански\ кантон",
"38759", "Требиње",
"38738", "Босанско\-подрињски\ кантон\ Горажде",
"38750", "Мркоњић\ Град",
"38757", "Источно\ Сарајево",};
$areanames{hr} = {"38731", "Županija\ Posavska",
"38735", "Tuzlanska\ županija",
"38736", "Hercegovačko\-neretvanska\ županija",
"38732", "Zeničko\-dobojska\ županija",
"38733", "Sarajevska\ županija",
"38734", "Hercegbosanska\ županija",
"38738", "Bosansko\-podrinjska\ županija\ Goražde",
"38739", "Županija\ Zapadnohercegovačka",
"38730", "Županija\ Središnja\ Bosna",
"38737", "Unsko\-sanska\ županija",};
$areanames{en} = {"38756", "Zvornik",
"38752", "Prijedor",
"38731", "Posavina\ Canton",
"38753", "Doboj",
"38754", "Šamac",
"38755", "Bijeljina",
"38734", "Canton\ 10",
"38733", "Sarajevo\ Canton",
"38736", "Herzegovina\-Neretva\ Canton",
"38751", "Banja\ Luka",
"38732", "Zenica\-Doboj\ Canton",
"38735", "Tuzla\ Canton",
"38757", "East\ Sarajevo",
"38750", "Mrkonjić\ Grad",
"38739", "West\ Herzegovina\ Canton",
"38738", "Bosnian\-Podrinje\ Canton\ Goražde",
"38759", "Trebinje",
"38730", "Central\ Bosnia\ Canton",
"38737", "Una\-Sana\ Canton",
"3874", "Brčko\ District",
"38758", "Foča",};
$areanames{bs} = {"38737", "Unsko\-sanski\ kanton",
"3874", "Brčko\ Distrikt",
"38730", "Srednjobosanski\ kanton",
"38738", "Bosansko\-podrinjski\ kanton\ Goražde",
"38739", "Zapadnohercegovački\ kanton",
"38757", "Istočno\ Sarajevo",
"38735", "Tuzlanski\ kanton",
"38734", "kanton\ 10",
"38733", "Kanton\ Sarajevo",
"38732", "Zeničko\-dobojski\ kanton",
"38736", "Hercegovačko\-neretvanski\ kanton",
"38731", "Posavski\ kanton",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+387|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;