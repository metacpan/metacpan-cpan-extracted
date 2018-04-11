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
package Number::Phone::StubCountry::NZ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180410221547;

my $formatters = [
                {
                  'pattern' => '(\\d)(\\d{3})(\\d{4})',
                  'format' => '$1-$2 $3',
                  'leading_digits' => '
            240|
            [346]|
            7[2-57-9]|
            9[1-9]
          ',
                  'national_rule' => '0$1'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '21',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,5})',
                  'national_rule' => '0$1',
                  'leading_digits' => '
            2(?:
              1[1-9]|
              [69]|
              7[0-35-9]
            )|
            70|
            86
          ',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '(2\\d)(\\d{3,4})(\\d{4})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2[028]',
                  'national_rule' => '0$1'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '90',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            2(?:
              10|
              74
            )|
            5|
            [89]0
          ',
                  'national_rule' => '0$1'
                }
              ];

my $validators = {
                'toll_free' => '
          508\\d{6,7}|
          80\\d{6,8}
        ',
                'fixed_line' => '
          (?:
            3[2-79]|
            [49][2-9]|
            6[235-9]|
            7[2-57-9]
          )\\d{6}|
          24099\\d{3}
        ',
                'voip' => '',
                'specialrate' => '(90\\d{6,7})',
                'mobile' => '
          2(?:
            [028]\\d{7,8}|
            1\\d{6,8}|
            [79]\\d{7}
          )
        ',
                'geographic' => '
          (?:
            3[2-79]|
            [49][2-9]|
            6[235-9]|
            7[2-57-9]
          )\\d{6}|
          24099\\d{3}
        ',
                'personal_number' => '70\\d{7}',
                'pager' => '[28]6\\d{6,7}'
              };
my %areanames = (
  642409 => "Scott\ Base",
  643 => "South\ Island",
  64320 => "Gore\/Edendale",
  64321 => "Invercargill\/Stewart\ Island\/Rakiura",
  64322 => "Otautau",
  64323 => "Riverton\/Winton",
  64324 => "Tokanui\/Lumsden\/Te\ Anau",
  64330 => "Ashburton\/Akaroa\/Chatham\ Islands",
  64331 => "Rangiora\/Amberley\/Culverden\/Darfield\/Cheviot\/Kaikoura",
  64332 => "Christchurch",
  64333 => "Christchurch",
  64334 => "Christchurch\/Rolleston",
  64335 => "Christchurch",
  64337 => "Christchurch",
  64338 => "Christchurch",
  643409 => "Queenstown",
  64341 => "Balclutha\/Milton",
  64343 => "Oamaru\/Mount\ Cook\/Twizel\/Kurow",
  64344 => "Queenstown\/Cromwell\/Alexandra\/Wanaka\/Ranfurly\/Roxburgh",
  64345 => "Dunedin\/Queenstown",
  64346 => "Dunedin\/Palmerston",
  64347 => "Dunedin",
  64348 => "Dunedin\/Lawrence\/Mosgiel",
  64352 => "Murchison\/Takaka\/Motueka",
  64354 => "Nelson",
  64357 => "Blenheim",
  64361 => "Timaru",
  64368 => "Timaru\/Waimate\/Fairlie",
  64369 => "Geraldine",
  64373 => "Greymouth",
  64375 => "Hokitika\/Franz\ Josef\ Glacier\/Fox\ Glacier\/Haast",
  64376 => "Greymouth",
  64378 => "Westport",
  64390 => "Ashburton",
  64394 => "Christchurch\/Invercargill",
  64395 => "Dunedin\/Timaru",
  64396 => "Christchurch",
  64397 => "Christchurch",
  64398 => "Christchurch\/Blenheim\/Nelson",
  64423 => "Wellington\/Porirua\/Tawa",
  64429 => "Paraparaumu",
  6443 => "Wellington",
  6444 => "Wellington",
  6445 => "Wellington\/Hutt\ Valley",
  64480 => "Wellington",
  6449 => "Wellington",
  64490 => "Paraparaumu",
  64627 => "Hawera",
  64630 => "Featherston",
  64632 => "Palmerston\ North\/Marton",
  64634 => "Wanganui",
  64635 => "Palmerston\ North\ City",
  64636 => "Levin",
  64637 => "Masterton\/Dannevirke\/Pahiatua",
  64638 => "Taihape\/Ohakune\/Waiouru",
  64675 => "New\ Plymouth\/Mokau",
  64676 => "New\ Plymouth\/Opunake\/Stratford",
  64683 => "Napier\/Wairoa",
  64684 => "Napier\ City",
  64685 => "Waipukurau",
  64686 => "Gisborne\/Ruatoria",
  64687 => "Napier\/Hastings",
  64694 => "Masterton\/Levin",
  64695 => "Palmerston\ North\/New\ Plymouth",
  64696 => "Wanganui\/New\ Plymouth",
  64697 => "Napier",
  64698 => "Gisborne",
  64730 => "Whakatane",
  64731 => "Whakatane\/Opotiki",
  64732 => "Whakatane",
  64733 => "Rotorua\/Taupo",
  64734 => "Rotorua",
  64735 => "Rotorua",
  64736 => "Rotorua",
  64737 => "Taupo",
  64738 => "Taupo",
  64754 => "Tauranga",
  64757 => "Tauranga",
  64782 => "Hamilton\/Huntly",
  64783 => "Hamilton",
  64784 => "Hamilton",
  64785 => "Hamilton",
  64786 => "Paeroa\/Waihi\/Thames\/Whangamata",
  64787 => "Te\ Awamutu\/Otorohanga\/Te\ Kuiti",
  64788 => "Matamata\/Putaruru\/Morrinsville",
  64789 => "Taumarunui",
  64790 => "Taupo",
  64792 => "Rotorua\/Whakatane\/Tauranga",
  64793 => "Tauranga",
  64795 => "Hamilton",
  64796 => "Hamilton",
  6492 => "Auckland",
  64923 => "Pukekohe",
  6493 => "Auckland\/Waiheke\ Island",
  64940 => "Kaikohe\/Kaitaia\/Kawakawa",
  64941 => "Auckland",
  64942 => "Helensville\/Warkworth\/Hibiscus\ Coast\/Great\ Barrier\ Island",
  64943 => "Whangarei\/Maungaturoto",
  64944 => "Auckland",
  64947 => "Auckland",
  64948 => "Auckland",
  6495 => "Auckland",
  6496 => "Auckland",
  6498 => "Auckland",
  6499 => "Auckland",
  64990 => "Warkworth",
  64998 => "Whangarei",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+64|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;