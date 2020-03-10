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
package Number::Phone::StubCountry::RO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200309202348;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '2[3-6]\\d9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            219|
            31
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[23]1',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[237-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          [23][13-6]\\d{7}|
          (?:
            2(?:
              19\\d|
              [3-6]\\d9
            )|
            31\\d\\d
          )\\d\\d
        ',
                'geographic' => '
          [23][13-6]\\d{7}|
          (?:
            2(?:
              19\\d|
              [3-6]\\d9
            )|
            31\\d\\d
          )\\d\\d
        ',
                'mobile' => '
          7[01]20\\d{5}|
          7(?:
            0[013-9]|
            1[01]|
            [2-7]\\d|
            8[03-8]|
            9[09]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(801\\d{6})|(90[0136]\\d{6})|(
          (?:
            37\\d|
            80[578]
          )\\d{6}
        )',
                'toll_free' => '800\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{ro}->{4021} = "București\ și\ județul\ Ilfov";
$areanames{ro}->{40230} = "Suceava";
$areanames{ro}->{40231} = "Botoșani";
$areanames{ro}->{40232} = "Iași";
$areanames{ro}->{40233} = "Neamț";
$areanames{ro}->{40234} = "Bacău";
$areanames{ro}->{40235} = "Vaslui";
$areanames{ro}->{40236} = "Galați";
$areanames{ro}->{40237} = "Vrancea";
$areanames{ro}->{40238} = "Buzău";
$areanames{ro}->{40239} = "Brăila";
$areanames{ro}->{40240} = "Tulcea";
$areanames{ro}->{40241} = "Constanța";
$areanames{ro}->{40242} = "Călărași";
$areanames{ro}->{40243} = "Ialomița";
$areanames{ro}->{40244} = "Prahova";
$areanames{ro}->{40245} = "Dâmbovița";
$areanames{ro}->{40246} = "Giurgiu";
$areanames{ro}->{40247} = "Teleorman";
$areanames{ro}->{40248} = "Argeș";
$areanames{ro}->{40249} = "Olt";
$areanames{ro}->{40250} = "Vâlcea";
$areanames{ro}->{40251} = "Dolj";
$areanames{ro}->{40252} = "Mehedinți";
$areanames{ro}->{40253} = "Gorj";
$areanames{ro}->{40254} = "Hunedoara";
$areanames{ro}->{40255} = "Caraș\-Severin";
$areanames{ro}->{40256} = "Timiș";
$areanames{ro}->{40257} = "Arad";
$areanames{ro}->{40258} = "Alba";
$areanames{ro}->{40259} = "Bihor";
$areanames{ro}->{40260} = "Sălaj";
$areanames{ro}->{40261} = "Satu\ Mare";
$areanames{ro}->{40262} = "Maramureș";
$areanames{ro}->{40263} = "Bistrița\-Năsăud";
$areanames{ro}->{40264} = "Cluj";
$areanames{ro}->{40265} = "Mureș";
$areanames{ro}->{40266} = "Harghita";
$areanames{ro}->{40267} = "Covasna";
$areanames{ro}->{40268} = "Brașov";
$areanames{ro}->{40269} = "Sibiu";
$areanames{ro}->{4031} = "București\ și\ județul\ Ilfov";
$areanames{ro}->{40330} = "Suceava";
$areanames{ro}->{40331} = "Botoșani";
$areanames{ro}->{40332} = "Iași";
$areanames{ro}->{40333} = "Neamț";
$areanames{ro}->{40334} = "Bacău";
$areanames{ro}->{40335} = "Vaslui";
$areanames{ro}->{40336} = "Galați";
$areanames{ro}->{40337} = "Vrancea";
$areanames{ro}->{40338} = "Buzău";
$areanames{ro}->{40339} = "Brăila";
$areanames{ro}->{40340} = "Tulcea";
$areanames{ro}->{40341} = "Constanța";
$areanames{ro}->{40342} = "Călărași";
$areanames{ro}->{40343} = "Ialomița";
$areanames{ro}->{40344} = "Prahova";
$areanames{ro}->{40345} = "Dâmbovița";
$areanames{ro}->{40346} = "Giurgiu";
$areanames{ro}->{40347} = "Teleorman";
$areanames{ro}->{40348} = "Argeș";
$areanames{ro}->{40349} = "Olt";
$areanames{ro}->{40350} = "Vâlcea";
$areanames{ro}->{40351} = "Dolj";
$areanames{ro}->{40352} = "Mehedinți";
$areanames{ro}->{40353} = "Gorj";
$areanames{ro}->{40354} = "Hunedoara";
$areanames{ro}->{40355} = "Caraș\-Severin";
$areanames{ro}->{40356} = "Timiș";
$areanames{ro}->{40357} = "Arad";
$areanames{ro}->{40358} = "Alba";
$areanames{ro}->{40359} = "Bihor";
$areanames{ro}->{40360} = "Sălaj";
$areanames{ro}->{40361} = "Satu\ Mare";
$areanames{ro}->{40362} = "Maramureș";
$areanames{ro}->{40363} = "Bistrița\-Năsăud";
$areanames{ro}->{40364} = "Cluj";
$areanames{ro}->{40365} = "Mureș";
$areanames{ro}->{40366} = "Harghita";
$areanames{ro}->{40367} = "Covasna";
$areanames{ro}->{40368} = "Brașov";
$areanames{ro}->{40369} = "Sibiu";
$areanames{en}->{4021} = "Bucharest\ and\ Ilfov\ County";
$areanames{en}->{40230} = "Suceava";
$areanames{en}->{40231} = "Botoșani";
$areanames{en}->{40232} = "Iași";
$areanames{en}->{40233} = "Neamț";
$areanames{en}->{40234} = "Bacău";
$areanames{en}->{40235} = "Vaslui";
$areanames{en}->{40236} = "Galați";
$areanames{en}->{40237} = "Vrancea";
$areanames{en}->{40238} = "Buzău";
$areanames{en}->{40239} = "Brăila";
$areanames{en}->{40240} = "Tulcea";
$areanames{en}->{40241} = "Constanța";
$areanames{en}->{40242} = "Călărași";
$areanames{en}->{40243} = "Ialomița";
$areanames{en}->{40244} = "Prahova";
$areanames{en}->{40245} = "Dâmbovița";
$areanames{en}->{40246} = "Giurgiu";
$areanames{en}->{40247} = "Teleorman";
$areanames{en}->{40248} = "Argeș";
$areanames{en}->{40249} = "Olt";
$areanames{en}->{40250} = "Vâlcea";
$areanames{en}->{40251} = "Dolj";
$areanames{en}->{40252} = "Mehedinți";
$areanames{en}->{40253} = "Gorj";
$areanames{en}->{40254} = "Hunedoara";
$areanames{en}->{40255} = "Caraș\-Severin";
$areanames{en}->{40256} = "Timiș";
$areanames{en}->{40257} = "Arad";
$areanames{en}->{40258} = "Alba";
$areanames{en}->{40259} = "Bihor";
$areanames{en}->{40260} = "Sălaj";
$areanames{en}->{40261} = "Satu\ Mare";
$areanames{en}->{40262} = "Maramureș";
$areanames{en}->{40263} = "Bistrița\-Năsăud";
$areanames{en}->{40264} = "Cluj";
$areanames{en}->{40265} = "Mureș";
$areanames{en}->{40266} = "Harghita";
$areanames{en}->{40267} = "Covasna";
$areanames{en}->{40268} = "Brașov";
$areanames{en}->{40269} = "Sibiu";
$areanames{en}->{4031} = "Bucharest\ and\ Ilfov\ County";
$areanames{en}->{40330} = "Suceava";
$areanames{en}->{40331} = "Botoșani";
$areanames{en}->{40332} = "Iași";
$areanames{en}->{40333} = "Neamț";
$areanames{en}->{40334} = "Bacău";
$areanames{en}->{40335} = "Vaslui";
$areanames{en}->{40336} = "Galați";
$areanames{en}->{40337} = "Vrancea";
$areanames{en}->{40338} = "Buzău";
$areanames{en}->{40339} = "Brăila";
$areanames{en}->{40340} = "Tulcea";
$areanames{en}->{40341} = "Constanța";
$areanames{en}->{40342} = "Călărași";
$areanames{en}->{40343} = "Ialomița";
$areanames{en}->{40344} = "Prahova";
$areanames{en}->{40345} = "Dâmbovița";
$areanames{en}->{40346} = "Giurgiu";
$areanames{en}->{40347} = "Teleorman";
$areanames{en}->{40348} = "Argeș";
$areanames{en}->{40349} = "Olt";
$areanames{en}->{40350} = "Vâlcea";
$areanames{en}->{40351} = "Dolj";
$areanames{en}->{40352} = "Mehedinți";
$areanames{en}->{40353} = "Gorj";
$areanames{en}->{40354} = "Hunedoara";
$areanames{en}->{40355} = "Caraș\-Severin";
$areanames{en}->{40356} = "Timiș";
$areanames{en}->{40357} = "Arad";
$areanames{en}->{40358} = "Alba";
$areanames{en}->{40359} = "Bihor";
$areanames{en}->{40360} = "Sălaj";
$areanames{en}->{40361} = "Satu\ Mare";
$areanames{en}->{40362} = "Maramureș";
$areanames{en}->{40363} = "Bistrița\-Năsăud";
$areanames{en}->{40364} = "Cluj";
$areanames{en}->{40365} = "Mureș";
$areanames{en}->{40366} = "Harghita";
$areanames{en}->{40367} = "Covasna";
$areanames{en}->{40368} = "Brașov";
$areanames{en}->{40369} = "Sibiu";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+40|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;