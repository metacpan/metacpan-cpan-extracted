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
package Number::Phone::StubCountry::MD;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230903131448;

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
$areanames{ru} = {"373271", "Окница",
"373252", "Дрокия",
"373263", "Леова",
"373210", "Григориополь",
"373219", "Днестровск",
"373269", "Хынчешть",
"373268", "Яловень",
"373216", "Каменка",
"373215", "Дубэсарь",
"373264", "Ниспорень",
"373273", "Кантемир",
"373265", "Анений\ Ной",
"373254", "Резина",
"373251", "Дондушень",
"373272", "Шолдэнешть",
"373262", "Сынжерей",
"373256", "Рышкань",
"373250", "Флорешть",
"373259", "Фэлешть",
"373258", "Теленешть",
"373230", "Сорока",
"37353", "Тираспол",
"373244", "Кэлэрашь",
"373236", "Унгень",
"373552", "Бендер",
"373297", "Басарабяска",
"373241", "Чимишлия",
"37322", "Кишинэу",
"373249", "Глодень",
"373248", "Криулень",
"373235", "Орхей",
"373243", "Кэушень",
"373246", "Единец",
"373557", "Слобозия",
"373231", "Бэлць",
"373298", "Комрат",
"373555", "Рыбница",
"373299", "Кагул",
"373242", "Штефан\ Водэ",
"373237", "Стрэшень",
"373293", "Вулкэнешть",
"373291", "Чадыр\-Лунга",
"373247", "Бричень",
"373294", "Тараклия",};
$areanames{ro} = {"373231", "Bălţi",
"373243", "Căuşeni",
"37322", "Chişinău",
"373241", "Cimişlia",
"373244", "Călăraşi",
"373291", "Ceadîr\ Lunga",
"373555", "Rîbniţa",
"373293", "Vulcăneşti",
"373242", "Ştefan\ Vodă",
"373237", "Străşeni",
"373215", "Dubăsari",
"373269", "Hînceşti",
"373256", "Rîşcani",
"373262", "Sîngerei",
"373258", "Teleneşti",
"373250", "Floreşti",
"373259", "Făleşti",
"373251", "Donduşeni",
"373272", "Şoldăneşti",};
$areanames{en} = {"373299", "Cahul",
"373298", "Comrat",
"373555", "Ribnita",
"373293", "Vulcanesti",
"373237", "Straseni",
"373242", "Stefan\ Voda",
"373294", "Taraclia",
"373247", "Briceni",
"373291", "Ceadir\ Lunga",
"37353", "Tiraspol",
"373230", "Soroca",
"37322", "Chisinau",
"373241", "Cimislia",
"373297", "Basarabeasca",
"373552", "Bender",
"373236", "Ungheni",
"373244", "Calarasi",
"373235", "Orhei",
"373248", "Criuleni",
"373249", "Glodeni",
"373231", "Balţi",
"373557", "Slobozia",
"373246", "Edineţ",
"373243", "Causeni",
"373272", "Soldanesti",
"373251", "Donduseni",
"373254", "Rezina",
"373256", "Riscani",
"373262", "Singerei",
"373258", "Telenesti",
"373259", "Falesti",
"373250", "Floresti",
"373219", "Dnestrovsk",
"373210", "Grigoriopol",
"373263", "Leova",
"373252", "Drochia",
"373271", "Ocniţa",
"373216", "Camenca",
"373268", "Ialoveni",
"373269", "Hincesti",
"373273", "Cantemir",
"373264", "Nisporeni",
"373215", "Dubasari",
"373265", "Anenii\ Noi",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+373|\D)//g;
      my $self = bless({ country_code => '373', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '373', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;