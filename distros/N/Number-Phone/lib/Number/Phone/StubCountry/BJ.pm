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
our $VERSION = 1.20200511123711;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[25689]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            02|
            1[037]|
            2[45]|
            3[68]
          )\\d{5}
        ',
                'geographic' => '
          2(?:
            02|
            1[037]|
            2[45]|
            3[68]
          )\\d{5}
        ',
                'mobile' => '
          (?:
            51|
            6\\d|
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
$areanames{fr}->{2292021} = "Ongala";
$areanames{fr}->{2292022} = "Kandiévé";
$areanames{fr}->{2292024} = "Sèmè";
$areanames{fr}->{2292025} = "Pobè\/Kétou";
$areanames{fr}->{2292026} = "Sakété\/Igolo";
$areanames{fr}->{2292027} = "Adjohoun";
$areanames{fr}->{2292029} = "Départements\ Ouémé\/Plateau";
$areanames{fr}->{2292130} = "Cadjehoun";
$areanames{fr}->{2292131} = "Ganhi";
$areanames{fr}->{2292132} = "Jéricho";
$areanames{fr}->{2292133} = "Akpakpa";
$areanames{fr}->{2292134} = "Ouidah";
$areanames{fr}->{2292135} = "Godomey";
$areanames{fr}->{2292136} = "Abomey\-Calaci";
$areanames{fr}->{2292137} = "Allada";
$areanames{fr}->{2292138} = "Kouhounou";
$areanames{fr}->{2292139} = "Départements\ Littoral\/Atlantique";
$areanames{fr}->{2292241} = "Lokossa";
$areanames{fr}->{2292243} = "Come";
$areanames{fr}->{2292246} = "Dogbo";
$areanames{fr}->{2292249} = "Départements\ Mono\/Couffo\/Zou\/Collines";
$areanames{fr}->{2292250} = "Abomey";
$areanames{fr}->{2292251} = "Bohicon";
$areanames{fr}->{2292252} = "Covè";
$areanames{fr}->{2292253} = "Dassa\-Zoumé";
$areanames{fr}->{2292254} = "Savalou";
$areanames{fr}->{2292255} = "Savè";
$areanames{fr}->{2292259} = "Départements\ Mono\/Couffo\/Zou\/Collines";
$areanames{fr}->{2292361} = "Parakou";
$areanames{fr}->{2292362} = "Nikki\/Ndali";
$areanames{fr}->{2292363} = "Kandi\/Gogounou\/Ségbana";
$areanames{fr}->{2292365} = "Banikoara";
$areanames{fr}->{2292367} = "Malanville";
$areanames{fr}->{2292380} = "Djougou";
$areanames{fr}->{2292382} = "Natitingou";
$areanames{fr}->{2292383} = "Tanguiéta";
$areanames{en}->{2292021} = "Ongala";
$areanames{en}->{2292022} = "Kandiévé";
$areanames{en}->{2292024} = "Sèmè";
$areanames{en}->{2292025} = "Pobè\/Kétou";
$areanames{en}->{2292026} = "Sakété\/Igolo";
$areanames{en}->{2292027} = "Adjohoun";
$areanames{en}->{2292029} = "Ouémé\/Plateau\ departments";
$areanames{en}->{2292130} = "Cadjehoun";
$areanames{en}->{2292131} = "Ganhi";
$areanames{en}->{2292132} = "Jéricho";
$areanames{en}->{2292133} = "Akpakpa";
$areanames{en}->{2292134} = "Ouidah";
$areanames{en}->{2292135} = "Godomey";
$areanames{en}->{2292136} = "Abomey\-Calaci";
$areanames{en}->{2292137} = "Allada";
$areanames{en}->{2292138} = "Kouhounou";
$areanames{en}->{2292139} = "Littoral\/Atlantique\ departments";
$areanames{en}->{2292241} = "Lokossa";
$areanames{en}->{2292243} = "Come";
$areanames{en}->{2292246} = "Dogbo";
$areanames{en}->{2292249} = "Mono\/Kouffo\/Zou\/Collines\ departments";
$areanames{en}->{2292250} = "Abomey";
$areanames{en}->{2292251} = "Bohicon";
$areanames{en}->{2292252} = "Covè";
$areanames{en}->{2292253} = "Dassa\-Zoumé";
$areanames{en}->{2292254} = "Savalou";
$areanames{en}->{2292255} = "Savè";
$areanames{en}->{2292259} = "Mono\/Kouffo\/Zou\/Collines\ departments";
$areanames{en}->{2292361} = "Parakou";
$areanames{en}->{2292362} = "Nikki\/Ndali";
$areanames{en}->{2292363} = "Kandi\/Gogounou\/Ségbana";
$areanames{en}->{2292365} = "Banikoara";
$areanames{en}->{2292367} = "Malanville";
$areanames{en}->{2292380} = "Djougou";
$areanames{en}->{2292382} = "Natitingou";
$areanames{en}->{2292383} = "Tanguiéta";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+229|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;