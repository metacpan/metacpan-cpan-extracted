# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20240607153917;

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
$areanames{fa} = {"9354", "جوزجان",
"9350", "بلخ",
"9320", "کابل",
"9324", "وردک",
"9340", "هرات",
"9344", "نیمروز",
"9330", "قندهار",
"9334", "هلمند",
"9327", "خوست",
"9360", "ننگرهار",
"9364", "پکتیا",
"9357", "فاریاب",
"9341", "بادغیس",
"9323", "بامیان",
"9353", "تخار",
"9332", "ارزگان",
"9321", "پروان",
"9328", "پنجشیر",
"9343", "فراه",
"9365", "پکتیکا",
"9351", "قندوز",
"9358", "بغلان",
"9362", "کنرها",
"9333", "زابل",
"9355", "سمنگان",
"9352", "بدخشان",
"9361", "نورستان",
"9322", "کاپیسا",
"9325", "لوگر",
"9363", "لغمان",
"9356", "سر\ پل",
"9331", "غزنی",
"9342", "غور",
"9326", "دایکندی",};
$areanames{en} = {"9340", "Heart",
"9344", "Nimruz",
"9350", "Balkh",
"9354", "Jowzjan",
"9320", "Kabul",
"9324", "Wardak",
"9327", "Khost",
"9357", "Faryab",
"9364", "Paktia",
"9360", "Nangarhar",
"9334", "Helmand",
"9330", "Kandahar",
"9343", "Farah",
"9321", "Parwan",
"9328", "Panjshar",
"9351", "Kunduz",
"9358", "Baghlan",
"9362", "Kunarha",
"9365", "Paktika",
"9323", "Bamian",
"9341", "Badghis",
"9332", "Uruzgan",
"9353", "Takhar",
"9331", "Ghazni",
"9356", "Sar\-E\ Pol",
"9363", "Laghman",
"9326", "Dorkondi",
"9342", "Ghowr",
"9352", "Badkhshan",
"9361", "Nurestan",
"9333", "Zabol",
"9355", "Samangan",
"9325", "Logar",
"9322", "Kapisa",};
my $timezones = {
               '' => [
                       'Asia/Kabul'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+93|\D)//g;
      my $self = bless({ country_code => '93', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '93', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;