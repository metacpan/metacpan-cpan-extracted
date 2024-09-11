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
package Number::Phone::StubCountry::RO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240910191017;

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
                  'leading_digits' => '[236-9]',
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
          (?:
            630|
            702
          )0\\d{5}|
          (?:
            6(?:
              00|
              2\\d
            )|
            7(?:
              0[013-9]|
              1[0-3]|
              [2-7]\\d|
              8[03-8]|
              9[0-39]
            )
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
$areanames{en} = {"40344", "Prahova",
"40254", "Hunedoara",
"40364", "Cluj",
"40334", "Bacău",
"40233", "Neamț",
"40243", "Ialomița",
"40263", "Bistrița\-Năsăud",
"40353", "Gorj",
"40251", "Dolj",
"40361", "Satu\ Mare",
"40341", "Constanța",
"40331", "Botoșani",
"4021", "Bucharest\ and\ Ilfov\ County",
"40348", "Argeș",
"40368", "Brașov",
"40258", "Alba",
"40230", "Suceava",
"40237", "Vrancea",
"40235", "Vaslui",
"40240", "Tulcea",
"40338", "Buzău",
"40350", "Vâlcea",
"40260", "Sălaj",
"40357", "Arad",
"40267", "Covasna",
"40245", "Dâmbovița",
"40355", "Caraș\-Severin",
"40265", "Mureș",
"40247", "Teleorman",
"40346", "Giurgiu",
"40366", "Harghita",
"40256", "Timiș",
"40359", "Bihor",
"40269", "Sibiu",
"40232", "Iași",
"40249", "Olt",
"40336", "Galați",
"40239", "Brăila",
"40352", "Mehedinți",
"40262", "Maramureș",
"40242", "Călărași",
"40234", "Bacău",
"40354", "Hunedoara",
"40264", "Cluj",
"40244", "Prahova",
"40363", "Bistrița\-Năsăud",
"40253", "Gorj",
"40343", "Ialomița",
"40333", "Neamț",
"4031", "Bucharest\ and\ Ilfov\ County",
"40231", "Botoșani",
"40241", "Constanța",
"40351", "Dolj",
"40261", "Satu\ Mare",
"40365", "Mureș",
"40347", "Teleorman",
"40255", "Caraș\-Severin",
"40367", "Covasna",
"40345", "Dâmbovița",
"40257", "Arad",
"40360", "Sălaj",
"40238", "Buzău",
"40250", "Vâlcea",
"40340", "Tulcea",
"40335", "Vaslui",
"40337", "Vrancea",
"40358", "Alba",
"40268", "Brașov",
"40330", "Suceava",
"40248", "Argeș",
"40342", "Călărași",
"40252", "Mehedinți",
"40362", "Maramureș",
"40339", "Brăila",
"40236", "Galați",
"40349", "Olt",
"40369", "Sibiu",
"40259", "Bihor",
"40332", "Iași",
"40266", "Harghita",
"40356", "Timiș",
"40246", "Giurgiu",};
$areanames{ro} = {"4021", "București\ și\ județul\ Ilfov",
"4031", "București\ și\ județul\ Ilfov",};
my $timezones = {
               '' => [
                       'Europe/Bucharest'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+40|\D)//g;
      my $self = bless({ country_code => '40', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '40', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;