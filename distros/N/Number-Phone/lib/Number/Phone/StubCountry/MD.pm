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
our $VERSION = 1.20200511123715;

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
$areanames{ru}->{373210} = "Григориополь";
$areanames{ru}->{373215} = "Дубэсарь";
$areanames{ru}->{373216} = "Каменка";
$areanames{ru}->{373219} = "Днестровск";
$areanames{ru}->{37322} = "Кишинэу";
$areanames{ru}->{373230} = "Сорока";
$areanames{ru}->{373231} = "Бэлць";
$areanames{ru}->{373235} = "Орхей";
$areanames{ru}->{373236} = "Унгень";
$areanames{ru}->{373237} = "Стрэшень";
$areanames{ru}->{373241} = "Чимишлия";
$areanames{ru}->{373242} = "Штефан\ Водэ";
$areanames{ru}->{373243} = "Кэушень";
$areanames{ru}->{373244} = "Кэлэрашь";
$areanames{ru}->{373246} = "Единец";
$areanames{ru}->{373247} = "Бричень";
$areanames{ru}->{373248} = "Криулень";
$areanames{ru}->{373249} = "Глодень";
$areanames{ru}->{373250} = "Флорешть";
$areanames{ru}->{373251} = "Дондушень";
$areanames{ru}->{373252} = "Дрокия";
$areanames{ru}->{373254} = "Резина";
$areanames{ru}->{373256} = "Рышкань";
$areanames{ru}->{373258} = "Теленешть";
$areanames{ru}->{373259} = "Фэлешть";
$areanames{ru}->{373262} = "Сынжерей";
$areanames{ru}->{373263} = "Леова";
$areanames{ru}->{373264} = "Ниспорень";
$areanames{ru}->{373265} = "Анений\ Ной";
$areanames{ru}->{373268} = "Яловень";
$areanames{ru}->{373269} = "Хынчешть";
$areanames{ru}->{373271} = "Окница";
$areanames{ru}->{373272} = "Шолдэнешть";
$areanames{ru}->{373273} = "Кантемир";
$areanames{ru}->{373291} = "Чадыр\-Лунга";
$areanames{ru}->{373293} = "Вулкэнешть";
$areanames{ru}->{373294} = "Тараклия";
$areanames{ru}->{373297} = "Басарабяска";
$areanames{ru}->{373298} = "Комрат";
$areanames{ru}->{373299} = "Кагул";
$areanames{ru}->{37353} = "Тираспол";
$areanames{ru}->{373552} = "Бендер";
$areanames{ru}->{373555} = "Рыбница";
$areanames{ru}->{373557} = "Слобозия";
$areanames{ro}->{373210} = "Grigoriopol";
$areanames{ro}->{373215} = "Dubăsari";
$areanames{ro}->{373216} = "Camenca";
$areanames{ro}->{373219} = "Dnestrovsk";
$areanames{ro}->{37322} = "Chişinău";
$areanames{ro}->{373230} = "Soroca";
$areanames{ro}->{373231} = "Bălţi";
$areanames{ro}->{373235} = "Orhei";
$areanames{ro}->{373236} = "Ungheni";
$areanames{ro}->{373237} = "Străşeni";
$areanames{ro}->{373241} = "Cimişlia";
$areanames{ro}->{373242} = "Ştefan\ Vodă";
$areanames{ro}->{373243} = "Căuşeni";
$areanames{ro}->{373244} = "Călăraşi";
$areanames{ro}->{373246} = "Edineţ";
$areanames{ro}->{373247} = "Briceni";
$areanames{ro}->{373248} = "Criuleni";
$areanames{ro}->{373249} = "Glodeni";
$areanames{ro}->{373250} = "Floreşti";
$areanames{ro}->{373251} = "Donduşeni";
$areanames{ro}->{373252} = "Drochia";
$areanames{ro}->{373254} = "Rezina";
$areanames{ro}->{373256} = "Rîşcani";
$areanames{ro}->{373258} = "Teleneşti";
$areanames{ro}->{373259} = "Făleşti";
$areanames{ro}->{373262} = "Sîngerei";
$areanames{ro}->{373263} = "Leova";
$areanames{ro}->{373264} = "Nisporeni";
$areanames{ro}->{373265} = "Anenii\ Noi";
$areanames{ro}->{373268} = "Ialoveni";
$areanames{ro}->{373269} = "Hînceşti";
$areanames{ro}->{373271} = "Ocniţa";
$areanames{ro}->{373272} = "Şoldăneşti";
$areanames{ro}->{373273} = "Cantemir";
$areanames{ro}->{373291} = "Ceadîr\ Lunga";
$areanames{ro}->{373293} = "Vulcăneşti";
$areanames{ro}->{373294} = "Taraclia";
$areanames{ro}->{373297} = "Basarabeasca";
$areanames{ro}->{373298} = "Comrat";
$areanames{ro}->{373299} = "Cahul";
$areanames{ro}->{37353} = "Tiraspol";
$areanames{ro}->{373552} = "Bender";
$areanames{ro}->{373555} = "Rîbniţa";
$areanames{ro}->{373557} = "Slobozia";
$areanames{en}->{373210} = "Grigoriopol";
$areanames{en}->{373215} = "Dubasari";
$areanames{en}->{373216} = "Camenca";
$areanames{en}->{373219} = "Dnestrovsk";
$areanames{en}->{37322} = "Chisinau";
$areanames{en}->{373230} = "Soroca";
$areanames{en}->{373231} = "Balţi";
$areanames{en}->{373235} = "Orhei";
$areanames{en}->{373236} = "Ungheni";
$areanames{en}->{373237} = "Straseni";
$areanames{en}->{373241} = "Cimislia";
$areanames{en}->{373242} = "Stefan\ Voda";
$areanames{en}->{373243} = "Causeni";
$areanames{en}->{373244} = "Calarasi";
$areanames{en}->{373246} = "Edineţ";
$areanames{en}->{373247} = "Briceni";
$areanames{en}->{373248} = "Criuleni";
$areanames{en}->{373249} = "Glodeni";
$areanames{en}->{373250} = "Floresti";
$areanames{en}->{373251} = "Donduseni";
$areanames{en}->{373252} = "Drochia";
$areanames{en}->{373254} = "Rezina";
$areanames{en}->{373256} = "Riscani";
$areanames{en}->{373258} = "Telenesti";
$areanames{en}->{373259} = "Falesti";
$areanames{en}->{373262} = "Singerei";
$areanames{en}->{373263} = "Leova";
$areanames{en}->{373264} = "Nisporeni";
$areanames{en}->{373265} = "Anenii\ Noi";
$areanames{en}->{373268} = "Ialoveni";
$areanames{en}->{373269} = "Hincesti";
$areanames{en}->{373271} = "Ocniţa";
$areanames{en}->{373272} = "Soldanesti";
$areanames{en}->{373273} = "Cantemir";
$areanames{en}->{373291} = "Ceadir\ Lunga";
$areanames{en}->{373293} = "Vulcanesti";
$areanames{en}->{373294} = "Taraclia";
$areanames{en}->{373297} = "Basarabeasca";
$areanames{en}->{373298} = "Comrat";
$areanames{en}->{373299} = "Cahul";
$areanames{en}->{37353} = "Tiraspol";
$areanames{en}->{373552} = "Bender";
$areanames{en}->{373555} = "Ribnita";
$areanames{en}->{373557} = "Slobozia";

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