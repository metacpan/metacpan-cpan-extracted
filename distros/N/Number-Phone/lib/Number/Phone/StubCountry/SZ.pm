# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::SZ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250913135859;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[0237]',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '9',
                  'pattern' => '(\\d{5})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '[23][2-5]\\d{6}',
                'geographic' => '[23][2-5]\\d{6}',
                'mobile' => '7[5-9]\\d{6}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(900\\d{6})',
                'toll_free' => '0800\\d{4}',
                'voip' => '70\\d{6}'
              };
my %areanames = ();
$areanames{en} = {"2682207", "Nhlangano\,\ Shiselweni\ district",
"26833", "Lubombo",
"2682482", "Siphocosini\,\ Hhohho\ district",
"2682364", "Big\ Bend\,\ Lubombo\ district",
"2682404", "Mbabane\,\ Hhohho\ district",
"2682467", "Mhlambanyatsi\,\ Hhohho\ district",
"26835", "Manzini",
"2682442", "Ngwenya\,\ Hhohho\ district",
"26832", "Shiselweni",
"2682227", "Hluthi\,\ Shiselweni\ district",
"2682518", "Matsapha\,\ Manzini\ district",
"2682382", "Simunye\,\ Lubombo\ district",
"2682333", "Mpaka\,\ Lubombo\ district",
"26834", "Hhohho",
"2682383", "Simunye\,\ Lubombo\ district",
"2682517", "Matsapha\,\ Manzini\ district",
"2682217", "Hlathikulu\,\ Shiselweni\ district",
"2682343", "Siteki\,\ Lubombo\ district",
"2682528", "Malkerns\,\ Manzini\ district",
"2682237", "Mahamba\,\ Shiselweni\ district",
"2682406", "Mbabane\,\ Hhohho\ district",
"2682363", "Big\ Bend\,\ Lubombo\ district",
"2682472", "Mahwalala\,\ Hhohho\ district",
"2682505", "Manzini",
"2682312", "Mhlume\,\ Lubombo\ district",
"2682422", "Sidwashini\,\ Hhohho\ district",
"2682313", "Mhlume\,\ Lubombo\ district",
"2682405", "Mbabane\,\ Hhohho\ district",
"2682303", "Nsoko\,\ Lubombo\ district",
"2682538", "Mankayane\,\ Manzini\ district",
"2682373", "Maphiveni\,\ Lubombo\ district",
"2682416", "Lobamba\,\ Hhohho\ district",
"2682437", "Pigg\'s\ Peak\,\ Hhohho\ district",
"2682506", "Manzini",
"2682323", "Tshaneni\,\ Lubombo\ district",
"2682453", "Bhunya\,\ Hhohho\ district",
"2682322", "Tshaneni\,\ Lubombo\ district",
"2682452", "Bhunya\,\ Hhohho\ district",
"2682344", "Siphofaneni\,\ Lubombo\ district",
"2682548", "Ludzeludze\,\ Manzini\ district",};
my $timezones = {
               '' => [
                       'Africa/Mbabane'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+268|\D)//g;
      my $self = bless({ country_code => '268', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;