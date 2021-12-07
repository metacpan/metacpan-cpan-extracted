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
our $VERSION = 1.20211206222446;

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
$areanames{ru} = {"373293", "Вулкэнешть",
"373552", "Бендер",
"37353", "Тираспол",
"373291", "Чадыр\-Лунга",
"37322", "Кишинэу",
"373273", "Кантемир",
"373236", "Унгень",
"373262", "Сынжерей",
"373249", "Глодень",
"373246", "Единец",
"373252", "Дрокия",
"373271", "Окница",
"373269", "Хынчешть",
"373210", "Григориополь",
"373256", "Рышкань",
"373259", "Фэлешть",
"373242", "Штефан\ Водэ",
"373297", "Басарабяска",
"373215", "Дубэсарь",
"373294", "Тараклия",
"373268", "Яловень",
"373258", "Теленешть",
"373248", "Криулень",
"373244", "Кэлэрашь",
"373230", "Сорока",
"373254", "Резина",
"373237", "Стрэшень",
"373264", "Ниспорень",
"373247", "Бричень",
"373250", "Флорешть",
"373219", "Днестровск",
"373216", "Каменка",
"373557", "Слобозия",
"373298", "Комрат",
"373231", "Бэлць",
"373272", "Шолдэнешть",
"373555", "Рыбница",
"373241", "Чимишлия",
"373263", "Леова",
"373251", "Дондушень",
"373243", "Кэушень",
"373265", "Анений\ Ной",
"373299", "Кагул",
"373235", "Орхей",};
$areanames{en} = {"373294", "Taraclia",
"373215", "Dubasari",
"373297", "Basarabeasca",
"373248", "Criuleni",
"373258", "Telenesti",
"373268", "Ialoveni",
"37353", "Tiraspol",
"373291", "Ceadir\ Lunga",
"37322", "Chisinau",
"373552", "Bender",
"373293", "Vulcanesti",
"373242", "Stefan\ Voda",
"373259", "Falesti",
"373256", "Riscani",
"373271", "Ocniţa",
"373210", "Grigoriopol",
"373269", "Hincesti",
"373273", "Cantemir",
"373246", "Edineţ",
"373252", "Drochia",
"373249", "Glodeni",
"373262", "Singerei",
"373236", "Ungheni",
"373251", "Donduseni",
"373243", "Causeni",
"373241", "Cimislia",
"373555", "Ribnita",
"373272", "Soldanesti",
"373231", "Balţi",
"373263", "Leova",
"373299", "Cahul",
"373235", "Orhei",
"373265", "Anenii\ Noi",
"373247", "Briceni",
"373264", "Nisporeni",
"373254", "Rezina",
"373237", "Straseni",
"373216", "Camenca",
"373219", "Dnestrovsk",
"373250", "Floresti",
"373244", "Calarasi",
"373230", "Soroca",
"373298", "Comrat",
"373557", "Slobozia",};
$areanames{ro} = {"373258", "Teleneşti",
"373215", "Dubăsari",
"373269", "Hînceşti",
"373259", "Făleşti",
"373256", "Rîşcani",
"373242", "Ştefan\ Vodă",
"373262", "Sîngerei",
"373291", "Ceadîr\ Lunga",
"37322", "Chişinău",
"373293", "Vulcăneşti",
"373251", "Donduşeni",
"373243", "Căuşeni",
"373272", "Şoldăneşti",
"373555", "Rîbniţa",
"373241", "Cimişlia",
"373231", "Bălţi",
"373237", "Străşeni",
"373250", "Floreşti",
"373244", "Călăraşi",};

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