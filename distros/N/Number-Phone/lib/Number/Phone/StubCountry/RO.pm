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
our $VERSION = 1.20190611222641;

my $formatters = [
                {
                  'leading_digits' => '2[3-6]\\d9',
                  'pattern' => '(\\d{3})(\\d{3})',
                  'format' => '$1 $2',
                  'national_rule' => '0$1'
                },
                {
                  'leading_digits' => '
            219|
            31
          ',
                  'pattern' => '(\\d{2})(\\d{4})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[23]1'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[237-9]'
                }
              ];

my $validators = {
                'mobile' => '
          7120\\d{5}|
          7(?:
            [02-7]\\d|
            1[01]|
            8[03-8]|
            99
          )\\d{6}
        ',
                'toll_free' => '800\\d{6}',
                'personal_number' => '',
                'pager' => '',
                'voip' => '',
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
                'specialrate' => '(801\\d{6})|(90[036]\\d{6})|(37\\d{7})'
              };
my %areanames = (
  4021 => "Bucharest\ and\ Ilfov\ County",
  40230 => "Suceava",
  40231 => "Botoșani",
  40232 => "Iași",
  40233 => "Neamț",
  40234 => "Bacău",
  40235 => "Vaslui",
  40236 => "Galați",
  40237 => "Vrancea",
  40238 => "Buzău",
  40239 => "Brăila",
  40240 => "Tulcea",
  40241 => "Constanța",
  40242 => "Călărași",
  40243 => "Ialomița",
  40244 => "Prahova",
  40245 => "Dâmbovița",
  40246 => "Giurgiu",
  40247 => "Teleorman",
  40248 => "Argeș",
  40249 => "Olt",
  40250 => "Vâlcea",
  40251 => "Dolj",
  40252 => "Mehedinți",
  40253 => "Gorj",
  40254 => "Hunedoara",
  40255 => "Caraș\-Severin",
  40256 => "Timiș",
  40257 => "Arad",
  40258 => "Alba",
  40259 => "Bihor",
  40260 => "Sălaj",
  40261 => "Satu\ Mare",
  40262 => "Maramureș",
  40263 => "Bistrița\-Năsăud",
  40264 => "Cluj",
  40265 => "Mureș",
  40266 => "Harghita",
  40267 => "Covasna",
  40268 => "Brașov",
  40269 => "Sibiu",
  4031 => "Bucharest\ and\ Ilfov\ County",
  40330 => "Suceava",
  40331 => "Botoșani",
  40332 => "Iași",
  40333 => "Neamț",
  40334 => "Bacău",
  40335 => "Vaslui",
  40336 => "Galați",
  40337 => "Vrancea",
  40338 => "Buzău",
  40339 => "Brăila",
  40340 => "Tulcea",
  40341 => "Constanța",
  40342 => "Călărași",
  40343 => "Ialomița",
  40344 => "Prahova",
  40345 => "Dâmbovița",
  40346 => "Giurgiu",
  40347 => "Teleorman",
  40348 => "Argeș",
  40349 => "Olt",
  40350 => "Vâlcea",
  40351 => "Dolj",
  40352 => "Mehedinți",
  40353 => "Gorj",
  40354 => "Hunedoara",
  40355 => "Caraș\-Severin",
  40356 => "Timiș",
  40357 => "Arad",
  40358 => "Alba",
  40359 => "Bihor",
  40360 => "Sălaj",
  40361 => "Satu\ Mare",
  40362 => "Maramureș",
  40363 => "Bistrița\-Năsăud",
  40364 => "Cluj",
  40365 => "Mureș",
  40366 => "Harghita",
  40367 => "Covasna",
  40368 => "Brașov",
  40369 => "Sibiu",
);
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