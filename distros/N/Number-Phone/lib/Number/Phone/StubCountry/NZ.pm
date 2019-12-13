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
our $VERSION = 1.20191211212303;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[89]0',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1-$2 $3',
                  'leading_digits' => '
            24|
            [346]|
            7[2-57-9]|
            9[2-9]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            2(?:
              10|
              74
            )|
            [59]|
            80
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2[028]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3,4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            2(?:
              [169]|
              7[0-35-9]
            )|
            7|
            86
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,5})'
                }
              ];

my $validators = {
                'fixed_line' => '
          24099\\d{3}|
          (?:
            3[2-79]|
            [49][2-9]|
            6[235-9]|
            7[2-57-9]
          )\\d{6}
        ',
                'geographic' => '
          24099\\d{3}|
          (?:
            3[2-79]|
            [49][2-9]|
            6[235-9]|
            7[2-57-9]
          )\\d{6}
        ',
                'mobile' => '
          2[0-28]\\d{8}|
          2[0-27-9]\\d{7}|
          21\\d{6}
        ',
                'pager' => '[28]6\\d{6,7}',
                'personal_number' => '70\\d{7}',
                'specialrate' => '(90\\d{6,7})',
                'toll_free' => '
          508\\d{6,7}|
          80\\d{6,8}
        ',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{6424} = "Scott\ Base";
$areanames{en}->{64320} = "Gore\/Edendale";
$areanames{en}->{64321} = "Invercargill\/Stewart\ Island\/Rakiura";
$areanames{en}->{64322} = "Otautau";
$areanames{en}->{64323} = "Riverton\/Winton";
$areanames{en}->{64324} = "Tokanui\/Lumsden\/Te\ Anau";
$areanames{en}->{64325} = "South\ Island";
$areanames{en}->{64326} = "South\ Island";
$areanames{en}->{64327} = "South\ Island";
$areanames{en}->{64328} = "South\ Island";
$areanames{en}->{64329} = "South\ Island";
$areanames{en}->{64330} = "Ashburton\/Akaroa\/Chatham\ Islands";
$areanames{en}->{64331} = "Rangiora\/Amberley\/Culverden\/Darfield\/Cheviot\/Kaikoura";
$areanames{en}->{64332} = "Christchurch";
$areanames{en}->{64333} = "Christchurch";
$areanames{en}->{64334} = "Christchurch\/Rolleston";
$areanames{en}->{64335} = "Christchurch";
$areanames{en}->{64336} = "South\ Island";
$areanames{en}->{64337} = "Christchurch";
$areanames{en}->{64338} = "Christchurch";
$areanames{en}->{64339} = "South\ Island";
$areanames{en}->{64340} = "South\ Island";
$areanames{en}->{643409} = "Queenstown";
$areanames{en}->{64341} = "Balclutha\/Milton";
$areanames{en}->{64342} = "South\ Island";
$areanames{en}->{64343} = "Oamaru\/Mount\ Cook\/Twizel\/Kurow";
$areanames{en}->{64344} = "Queenstown\/Cromwell\/Alexandra\/Wanaka\/Ranfurly\/Roxburgh";
$areanames{en}->{64345} = "Dunedin\/Queenstown";
$areanames{en}->{64346} = "Dunedin\/Palmerston";
$areanames{en}->{64347} = "Dunedin";
$areanames{en}->{64348} = "Dunedin\/Lawrence\/Mosgiel";
$areanames{en}->{64349} = "South\ Island";
$areanames{en}->{6435} = "South\ Island";
$areanames{en}->{64352} = "Murchison\/Takaka\/Motueka";
$areanames{en}->{64354} = "Nelson";
$areanames{en}->{64357} = "Blenheim";
$areanames{en}->{6436} = "South\ Island";
$areanames{en}->{64361} = "Timaru";
$areanames{en}->{64368} = "Timaru\/Waimate\/Fairlie";
$areanames{en}->{64369} = "Geraldine";
$areanames{en}->{6437} = "South\ Island";
$areanames{en}->{64373} = "Greymouth";
$areanames{en}->{64375} = "Hokitika\/Franz\ Josef\ Glacier\/Fox\ Glacier\/Haast";
$areanames{en}->{64376} = "Greymouth";
$areanames{en}->{64378} = "Westport";
$areanames{en}->{64390} = "Ashburton";
$areanames{en}->{64391} = "South\ Island";
$areanames{en}->{64392} = "South\ Island";
$areanames{en}->{64393} = "South\ Island";
$areanames{en}->{64394} = "Christchurch\/Invercargill";
$areanames{en}->{64395} = "Dunedin\/Timaru";
$areanames{en}->{64396} = "Christchurch";
$areanames{en}->{64397} = "Christchurch";
$areanames{en}->{64398} = "Christchurch\/Blenheim\/Nelson";
$areanames{en}->{64399} = "South\ Island";
$areanames{en}->{64423} = "Wellington\/Porirua\/Tawa";
$areanames{en}->{64429} = "Paraparaumu";
$areanames{en}->{6443} = "Wellington";
$areanames{en}->{6444} = "Wellington";
$areanames{en}->{6445} = "Wellington\/Hutt\ Valley";
$areanames{en}->{64480} = "Wellington";
$areanames{en}->{6449} = "Wellington";
$areanames{en}->{64490} = "Paraparaumu";
$areanames{en}->{64627} = "Hawera";
$areanames{en}->{64630} = "Featherston";
$areanames{en}->{64632} = "Palmerston\ North\/Marton";
$areanames{en}->{64634} = "Wanganui";
$areanames{en}->{64635} = "Palmerston\ North\ City";
$areanames{en}->{64636} = "Levin";
$areanames{en}->{64637} = "Masterton\/Dannevirke\/Pahiatua";
$areanames{en}->{64638} = "Taihape\/Ohakune\/Waiouru";
$areanames{en}->{64675} = "New\ Plymouth\/Mokau";
$areanames{en}->{64676} = "New\ Plymouth\/Opunake\/Stratford";
$areanames{en}->{64683} = "Napier\/Wairoa";
$areanames{en}->{64684} = "Napier\ City";
$areanames{en}->{64685} = "Waipukurau";
$areanames{en}->{64686} = "Gisborne\/Ruatoria";
$areanames{en}->{64687} = "Napier\/Hastings";
$areanames{en}->{64694} = "Masterton\/Levin";
$areanames{en}->{64695} = "Palmerston\ North\/New\ Plymouth";
$areanames{en}->{64696} = "Wanganui\/New\ Plymouth";
$areanames{en}->{64697} = "Napier";
$areanames{en}->{64698} = "Gisborne";
$areanames{en}->{64730} = "Whakatane";
$areanames{en}->{64731} = "Whakatane\/Opotiki";
$areanames{en}->{64732} = "Whakatane";
$areanames{en}->{64733} = "Rotorua\/Taupo";
$areanames{en}->{64734} = "Rotorua";
$areanames{en}->{64735} = "Rotorua";
$areanames{en}->{64736} = "Rotorua";
$areanames{en}->{64737} = "Taupo";
$areanames{en}->{64738} = "Taupo";
$areanames{en}->{64754} = "Tauranga";
$areanames{en}->{64757} = "Tauranga";
$areanames{en}->{64782} = "Hamilton\/Huntly";
$areanames{en}->{64783} = "Hamilton";
$areanames{en}->{64784} = "Hamilton";
$areanames{en}->{64785} = "Hamilton";
$areanames{en}->{64786} = "Paeroa\/Waihi\/Thames\/Whangamata";
$areanames{en}->{64787} = "Te\ Awamutu\/Otorohanga\/Te\ Kuiti";
$areanames{en}->{64788} = "Matamata\/Putaruru\/Morrinsville";
$areanames{en}->{64789} = "Taumarunui";
$areanames{en}->{64790} = "Taupo";
$areanames{en}->{64792} = "Rotorua\/Whakatane\/Tauranga";
$areanames{en}->{64793} = "Tauranga";
$areanames{en}->{64795} = "Hamilton";
$areanames{en}->{64796} = "Hamilton";
$areanames{en}->{6492} = "Auckland";
$areanames{en}->{64923} = "Pukekohe";
$areanames{en}->{6493} = "Auckland\/Waiheke\ Island";
$areanames{en}->{64940} = "Kaikohe\/Kaitaia\/Kawakawa";
$areanames{en}->{64941} = "Auckland";
$areanames{en}->{64942} = "Helensville\/Warkworth\/Hibiscus\ Coast\/Great\ Barrier\ Island";
$areanames{en}->{64943} = "Whangarei\/Maungaturoto";
$areanames{en}->{64944} = "Auckland";
$areanames{en}->{64947} = "Auckland";
$areanames{en}->{64948} = "Auckland";
$areanames{en}->{6495} = "Auckland";
$areanames{en}->{6496} = "Auckland";
$areanames{en}->{6498} = "Auckland";
$areanames{en}->{6499} = "Auckland";
$areanames{en}->{64990} = "Warkworth";
$areanames{en}->{64998} = "Whangarei";

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