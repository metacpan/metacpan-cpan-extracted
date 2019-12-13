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
our $VERSION = 1.20191211212259;

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
          6040[0-4]\\d{4}|
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
          70(?:
            3[0146]|
            [56]0
          )\\d{4}
        )',
                'toll_free' => '8[08]\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{sr}->{38730} = "Средњoбосански\ кантон";
$areanames{sr}->{38731} = "Посавски\ кантон";
$areanames{sr}->{38732} = "Зеничко\-добојски\ кантон";
$areanames{sr}->{38733} = "Сарајевски\ кантон";
$areanames{sr}->{38734} = "Кантон\ 10";
$areanames{sr}->{38735} = "Тузлански\ кантон";
$areanames{sr}->{38737} = "Унско\-сански\ кантон";
$areanames{sr}->{38738} = "Босанско\-подрињски\ кантон\ Горажде";
$areanames{sr}->{3874} = "Брчко\ Дистрикт";
$areanames{sr}->{38750} = "Мркоњић\ Град";
$areanames{sr}->{38751} = "Бања\ Лука";
$areanames{sr}->{38752} = "Приједор";
$areanames{sr}->{38753} = "Добој";
$areanames{sr}->{38754} = "Шамац";
$areanames{sr}->{38755} = "Бијељина";
$areanames{sr}->{38756} = "Зворник";
$areanames{sr}->{38757} = "Источно\ Сарајево";
$areanames{sr}->{38758} = "Фоча";
$areanames{sr}->{38759} = "Требиње";
$areanames{bs}->{38730} = "Srednjobosanski\ kanton";
$areanames{bs}->{38731} = "Posavski\ kanton";
$areanames{bs}->{38732} = "Zeničko\-dobojski\ kanton";
$areanames{bs}->{38733} = "Kanton\ Sarajevo";
$areanames{bs}->{38734} = "kanton\ 10";
$areanames{bs}->{38735} = "Tuzlanski\ kanton";
$areanames{bs}->{38736} = "Hercegovačko\-neretvanski\ kanton";
$areanames{bs}->{38737} = "Unsko\-sanski\ kanton";
$areanames{bs}->{38738} = "Bosansko\-podrinjski\ kanton\ Goražde";
$areanames{bs}->{38739} = "Zapadnohercegovački\ kanton";
$areanames{bs}->{3874} = "Brčko\ Distrikt";
$areanames{bs}->{38750} = "Mrkonjić\ Grad";
$areanames{bs}->{38751} = "Banja\ Luka";
$areanames{bs}->{38752} = "Prijedor";
$areanames{bs}->{38753} = "Doboj";
$areanames{bs}->{38754} = "Šamac";
$areanames{bs}->{38755} = "Bijeljina";
$areanames{bs}->{38756} = "Zvornik";
$areanames{bs}->{38757} = "Istočno\ Sarajevo";
$areanames{bs}->{38758} = "Foča";
$areanames{bs}->{38759} = "Trebinje";
$areanames{hr}->{38730} = "Županija\ Središnja\ Bosna";
$areanames{hr}->{38731} = "Županija\ Posavska";
$areanames{hr}->{38732} = "Zeničko\-dobojska\ županija";
$areanames{hr}->{38733} = "Sarajevska\ županija";
$areanames{hr}->{38734} = "Hercegbosanska\ županija";
$areanames{hr}->{38735} = "Tuzlanska\ županija";
$areanames{hr}->{38736} = "Hercegovačko\-neretvanska\ županija";
$areanames{hr}->{38737} = "Unsko\-sanska\ županija";
$areanames{hr}->{38738} = "Bosansko\-podrinjska\ županija\ Goražde";
$areanames{hr}->{38739} = "Županija\ Zapadnohercegovačka";
$areanames{hr}->{38750} = "Mrkonjić\ Grad";
$areanames{hr}->{38751} = "Banja\ Luka";
$areanames{en}->{38730} = "Central\ Bosnia\ Canton";
$areanames{en}->{38731} = "Posavina\ Canton";
$areanames{en}->{38732} = "Zenica\-Doboj\ Canton";
$areanames{en}->{38733} = "Sarajevo\ Canton";
$areanames{en}->{38734} = "Canton\ 10";
$areanames{en}->{38735} = "Tuzla\ Canton";
$areanames{en}->{38736} = "Herzegovina\-Neretva\ Canton";
$areanames{en}->{38737} = "Una\-Sana\ Canton";
$areanames{en}->{38738} = "Bosnian\-Podrinje\ Canton\ Goražde";
$areanames{en}->{38739} = "West\ Herzegovina\ Canton";
$areanames{en}->{3874} = "Brčko\ District";
$areanames{en}->{38750} = "Mrkonjić\ Grad";
$areanames{en}->{38751} = "Banja\ Luka";
$areanames{en}->{38752} = "Prijedor";
$areanames{en}->{38753} = "Doboj";
$areanames{en}->{38754} = "Šamac";
$areanames{en}->{38755} = "Bijeljina";
$areanames{en}->{38756} = "Zvornik";
$areanames{en}->{38757} = "East\ Sarajevo";
$areanames{en}->{38758} = "Foča";
$areanames{en}->{38759} = "Trebinje";

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