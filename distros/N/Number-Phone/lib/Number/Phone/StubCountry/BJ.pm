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
package Number::Phone::StubCountry::BJ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20241212130803;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[24-689]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4 $5',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2090\\d{4}|
          (?:
            012\\d\\d|
            2(?:
              02|
              1[037]|
              2[45]|
              3[68]|
              4\\d
            )
          )\\d{5}
        ',
                'geographic' => '
          2090\\d{4}|
          (?:
            012\\d\\d|
            2(?:
              02|
              1[037]|
              2[45]|
              3[68]|
              4\\d
            )
          )\\d{5}
        ',
                'mobile' => '
          (?:
            01(?:
              2[5-9]|
              [4-69]\\d
            )|
            4[0-8]|
            [56]\\d|
            9[013-9]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(81\\d{6})',
                'toll_free' => '',
                'voip' => '857[58]\\d{4}'
              };
my %areanames = ();
$areanames{en} = {"2292251", "Bohicon",
"2292255", "Savè",
"2292246", "Dogbo",
"2292025", "Pobè\/Kétou",
"2292021", "Ongala",
"2292363", "Kandi\/Gogounou\/Ségbana",
"2292136", "Abomey\-Calaci",
"22924", "Tanguiéta",
"2292241", "Lokossa",
"2292026", "Sakété\/Igolo",
"2292138", "Kouhounou",
"2292367", "Malanville",
"2292131", "Ganhi",
"2292135", "Godomey",
"2292362", "Nikki\/Ndali",
"2292243", "Come",
"2292024", "Sèmè",
"2292139", "Littoral\/Atlantique\ departments",
"2292022", "Kandiévé",
"2292252", "Covè",
"2292027", "Adjohoun",
"2292130", "Cadjehoun",
"2292254", "Savalou",
"2292382", "Natitingou",
"2292249", "Mono\/Kouffo\/Zou\/Collines\ departments",
"2292133", "Akpakpa",
"2292253", "Dassa\-Zoumé",
"2292380", "Djougou",
"2292137", "Allada",
"2292259", "Mono\/Kouffo\/Zou\/Collines\ departments",
"2292365", "Banikoara",
"2292361", "Parakou",
"2292132", "Jéricho",
"2292383", "Tanguiéta",
"2292250", "Abomey",
"2292029", "Ouémé\/Plateau\ departments",
"2292134", "Ouidah",};
$areanames{fr} = {"2292259", "Départements\ Mono\/Couffo\/Zou\/Collines",
"2292029", "Départements\ Ouémé\/Plateau",
"2292249", "Départements\ Mono\/Couffo\/Zou\/Collines",
"2292139", "Départements\ Littoral\/Atlantique",};
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