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
package Number::Phone::StubCountry::MD;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220307120120;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[89]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            22|
            3
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[25-7]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            (?:
              2[1-9]|
              3[1-79]
            )\\d|
            5(?:
              33|
              5[257]
            )
          )\\d{5}
        ',
                'geographic' => '
          (?:
            (?:
              2[1-9]|
              3[1-79]
            )\\d|
            5(?:
              33|
              5[257]
            )
          )\\d{5}
        ',
                'mobile' => '
          562\\d{5}|
          (?:
            6\\d|
            7[16-9]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(808\\d{5})|(90[056]\\d{5})|(803\\d{5})',
                'toll_free' => '800\\d{5}',
                'voip' => '3[08]\\d{6}'
              };
my %areanames = ();
$areanames{en} = {"373236", "Ungheni",
"373249", "Glodeni",
"373216", "Camenca",
"373244", "Calarasi",
"373241", "Cimislia",
"373237", "Straseni",
"373254", "Rezina",
"373251", "Donduseni",
"373259", "Falesti",
"373273", "Cantemir",
"373271", "Ocniţa",
"373248", "Criuleni",
"373552", "Bender",
"373219", "Dnestrovsk",
"373246", "Edineţ",
"373247", "Briceni",
"373231", "Balţi",
"373262", "Singerei",
"373235", "Orhei",
"373215", "Dubasari",
"373243", "Causeni",
"373256", "Riscani",
"373258", "Telenesti",
"373297", "Basarabeasca",
"373268", "Ialoveni",
"373298", "Comrat",
"373252", "Drochia",
"37353", "Tiraspol",
"37322", "Chisinau",
"373242", "Stefan\ Voda",
"373250", "Floresti",
"373263", "Leova",
"373293", "Vulcanesti",
"373557", "Slobozia",
"373269", "Hincesti",
"373555", "Ribnita",
"373294", "Taraclia",
"373291", "Ceadir\ Lunga",
"373264", "Nisporeni",
"373299", "Cahul",
"373210", "Grigoriopol",
"373230", "Soroca",
"373265", "Anenii\ Noi",
"373272", "Soldanesti",};
$areanames{ro} = {"373251", "Donduşeni",
"373259", "Făleşti",
"373237", "Străşeni",
"373244", "Călăraşi",
"373241", "Cimişlia",
"373243", "Căuşeni",
"373262", "Sîngerei",
"373215", "Dubăsari",
"373258", "Teleneşti",
"373256", "Rîşcani",
"373231", "Bălţi",
"373250", "Floreşti",
"373242", "Ştefan\ Vodă",
"373293", "Vulcăneşti",
"37322", "Chişinău",
"373272", "Şoldăneşti",
"373291", "Ceadîr\ Lunga",
"373555", "Rîbniţa",
"373269", "Hînceşti",};
$areanames{ru} = {"373258", "Теленешть",
"373256", "Рышкань",
"373215", "Дубэсарь",
"373235", "Орхей",
"373262", "Сынжерей",
"373243", "Кэушень",
"373247", "Бричень",
"373231", "Бэлць",
"373271", "Окница",
"373246", "Единец",
"373219", "Днестровск",
"373552", "Бендер",
"373248", "Криулень",
"373273", "Кантемир",
"373259", "Фэлешть",
"373251", "Дондушень",
"373254", "Резина",
"373241", "Чимишлия",
"373244", "Кэлэрашь",
"373237", "Стрэшень",
"373216", "Каменка",
"373249", "Глодень",
"373236", "Унгень",
"373272", "Шолдэнешть",
"373265", "Анений\ Ной",
"373264", "Ниспорень",
"373230", "Сорока",
"373210", "Григориополь",
"373299", "Кагул",
"373555", "Рыбница",
"373269", "Хынчешть",
"373291", "Чадыр\-Лунга",
"373294", "Тараклия",
"373293", "Вулкэнешть",
"373557", "Слобозия",
"373242", "Штефан\ Водэ",
"373263", "Леова",
"373250", "Флорешть",
"373298", "Комрат",
"373252", "Дрокия",
"37353", "Тираспол",
"37322", "Кишинэу",
"373297", "Басарабяска",
"373268", "Яловень",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+373|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;