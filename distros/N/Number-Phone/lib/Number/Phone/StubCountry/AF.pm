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
package Number::Phone::StubCountry::AF;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120026;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'intl_format' => 'NA',
                  'leading_digits' => '[1-9]',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-7]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            [25][0-8]|
            [34][0-4]|
            6[0-5]
          )[2-9]\\d{6}
        ',
                'geographic' => '
          (?:
            [25][0-8]|
            [34][0-4]|
            6[0-5]
          )[2-9]\\d{6}
        ',
                'mobile' => '7\\d{8}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{9320} = "Kabul";
$areanames{en}->{9321} = "Parwan";
$areanames{en}->{9322} = "Kapisa";
$areanames{en}->{9323} = "Bamian";
$areanames{en}->{9324} = "Wardak";
$areanames{en}->{9325} = "Logar";
$areanames{en}->{9326} = "Dorkondi";
$areanames{en}->{9327} = "Khost";
$areanames{en}->{9328} = "Panjshar";
$areanames{en}->{9330} = "Kandahar";
$areanames{en}->{9331} = "Ghazni";
$areanames{en}->{9332} = "Uruzgan";
$areanames{en}->{9333} = "Zabol";
$areanames{en}->{9334} = "Helmand";
$areanames{en}->{9340} = "Heart";
$areanames{en}->{9341} = "Badghis";
$areanames{en}->{9342} = "Ghowr";
$areanames{en}->{9343} = "Farah";
$areanames{en}->{9344} = "Nimruz";
$areanames{en}->{9350} = "Balkh";
$areanames{en}->{9351} = "Kunduz";
$areanames{en}->{9352} = "Badkhshan";
$areanames{en}->{9353} = "Takhar";
$areanames{en}->{9354} = "Jowzjan";
$areanames{en}->{9355} = "Samangan";
$areanames{en}->{9356} = "Sar\-E\ Pol";
$areanames{en}->{9357} = "Faryab";
$areanames{en}->{9358} = "Baghlan";
$areanames{en}->{9360} = "Nangarhar";
$areanames{en}->{9361} = "Nurestan";
$areanames{en}->{9362} = "Kunarha";
$areanames{en}->{9363} = "Laghman";
$areanames{en}->{9364} = "Paktia";
$areanames{en}->{9365} = "Paktika";
$areanames{fa}->{9320} = "کابل";
$areanames{fa}->{9321} = "پروان";
$areanames{fa}->{9322} = "کاپیسا";
$areanames{fa}->{9323} = "بامیان";
$areanames{fa}->{9324} = "وردک";
$areanames{fa}->{9325} = "لوگر";
$areanames{fa}->{9326} = "دایکندی";
$areanames{fa}->{9327} = "خوست";
$areanames{fa}->{9328} = "پنجشیر";
$areanames{fa}->{9330} = "قندهار";
$areanames{fa}->{9331} = "غزنی";
$areanames{fa}->{9332} = "ارزگان";
$areanames{fa}->{9333} = "زابل";
$areanames{fa}->{9334} = "هلمند";
$areanames{fa}->{9340} = "هرات";
$areanames{fa}->{9341} = "بادغیس";
$areanames{fa}->{9342} = "غور";
$areanames{fa}->{9343} = "فراه";
$areanames{fa}->{9344} = "نیمروز";
$areanames{fa}->{9350} = "بلخ";
$areanames{fa}->{9351} = "قندوز";
$areanames{fa}->{9352} = "بدخشان";
$areanames{fa}->{9353} = "تخار";
$areanames{fa}->{9354} = "جوزجان";
$areanames{fa}->{9355} = "سمنگان";
$areanames{fa}->{9356} = "سر\ پل";
$areanames{fa}->{9357} = "فاریاب";
$areanames{fa}->{9358} = "بغلان";
$areanames{fa}->{9360} = "ننگرهار";
$areanames{fa}->{9361} = "نورستان";
$areanames{fa}->{9362} = "کنرها";
$areanames{fa}->{9363} = "لغمان";
$areanames{fa}->{9364} = "پکتیا";
$areanames{fa}->{9365} = "پکتیکا";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+93|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;