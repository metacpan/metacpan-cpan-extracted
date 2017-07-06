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
package Number::Phone::StubCountry::BJ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170702164946;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'geographic' => '
          2(?:
            02|
            1[037]|
            2[45]|
            3[68]
          )\\d{5}
        ',
                'specialrate' => '(81\\d{6})',
                'personal_number' => '',
                'voip' => '857[58]\\d{4}',
                'toll_free' => '7[3-5]\\d{2}',
                'pager' => '',
                'mobile' => '
          (?:
            6[1-8]|
            9[03-9]
          )\\d{6}
        ',
                'fixed_line' => '
          2(?:
            02|
            1[037]|
            2[45]|
            3[68]
          )\\d{5}
        '
              };
my %areanames = (
  2292021 => "Ongala",
  2292022 => "Kandiévé",
  2292024 => "Sèmè",
  2292025 => "Pobè\/Kétou",
  2292026 => "Sakété\/Igolo",
  2292027 => "Adjohoun",
  2292029 => "Ouémé\/Plateau\ departments",
  2292130 => "Cadjehoun",
  2292131 => "Ganhi",
  2292132 => "Jéricho",
  2292133 => "Akpakpa",
  2292134 => "Ouidah",
  2292135 => "Godomey",
  2292136 => "Abomey\-Calaci",
  2292137 => "Allada",
  2292138 => "Kouhounou",
  2292139 => "Littoral\/Atlantique\ departments",
  2292241 => "Lokossa",
  2292243 => "Come",
  2292246 => "Dogbo",
  2292249 => "Mono\/Kouffo\/Zou\/Collines\ departments",
  2292250 => "Abomey",
  2292251 => "Bohicon",
  2292252 => "Covè",
  2292253 => "Dassa\-Zoumé",
  2292254 => "Savalou",
  2292255 => "Savè",
  2292259 => "Mono\/Kouffo\/Zou\/Collines\ departments",
  2292361 => "Parakou",
  2292362 => "Nikki\/Ndali",
  2292363 => "Kandi\/Gogounou\/Ségbana",
  2292365 => "Banikoara",
  2292367 => "Malanville",
  2292380 => "Djougou",
  2292382 => "Natitingou",
  2292383 => "Tanguiéta",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+229|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;