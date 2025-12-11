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
package Number::Phone::StubCountry::BJ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20251210153518;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4 $5',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '012\\d{7}',
                'geographic' => '012\\d{7}',
                'mobile' => '
          01(?:
            2[5-9]|
            [4-69]\\d
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(81\\d{6})',
                'toll_free' => '',
                'voip' => '857[58]\\d{4}'
              };
my %areanames = ();
$areanames{en} = {"229012383", "Tanguiéta",
"229012021", "Ongala",
"229012246", "Dogbo",
"229012259", "Mono\/Kouffo\/Zou\/Collines\ departments",
"229012025", "Pobè\/Kétou",
"229012130", "Cadjehoun",
"229012362", "Nikki\/Ndali",
"229012024", "Sèmè",
"229012243", "Come",
"229012241", "Lokossa",
"229012132", "Jéricho",
"229012026", "Sakété\/Igolo",
"2290124", "Tanguiéta",
"229012251", "Bohicon",
"229012253", "Dassa\-Zoumé",
"229012255", "Savè",
"229012029", "Ouémé\/Plateau\ departments",
"229012027", "Adjohoun",
"229012254", "Savalou",
"229012249", "Mono\/Kouffo\/Zou\/Collines\ departments",
"229012252", "Covè",
"229012138", "Kouhounou",
"229012250", "Abomey",
"229012137", "Allada",
"229012139", "Littoral\/Atlantique\ departments",
"229012367", "Malanville",
"229012022", "Kandiévé",
"229012382", "Natitingou",
"229012136", "Abomey\-Calaci",
"229012134", "Ouidah",
"229012363", "Kandi\/Gogounou\/Ségbana",
"229012135", "Godomey",
"229012380", "Djougou",
"229012361", "Parakou",
"229012133", "Akpakpa",
"229012365", "Banikoara",
"229012131", "Ganhi",};
$areanames{fr} = {};
my $timezones = {
               '' => [
                       'Africa/Porto-Novo'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+229|\D)//g;
      my $self = bless({ country_code => '229', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;