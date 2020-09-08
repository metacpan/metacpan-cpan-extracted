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
package Number::Phone::StubCountry::LV;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200904144534;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [269]|
            8[01]
          ',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '6\\d{7}',
                'geographic' => '6\\d{7}',
                'mobile' => '2\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(81\\d{6})|(90\\d{6})',
                'toll_free' => '80\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{37161} = "Jūrmala";
$areanames{en}->{37162} = "Valmiera";
$areanames{en}->{371630} = "Jelgava";
$areanames{en}->{371631} = "Tukums";
$areanames{en}->{371632} = "Talsi";
$areanames{en}->{371633} = "Kuldiga";
$areanames{en}->{371634} = "Liepaja";
$areanames{en}->{371635} = "Ventspils";
$areanames{en}->{371636} = "Ventspils";
$areanames{en}->{371637} = "Dobele";
$areanames{en}->{371638} = "Saldus";
$areanames{en}->{371639} = "Bauska";
$areanames{en}->{371640} = "Limbaži";
$areanames{en}->{371641} = "Cēsis";
$areanames{en}->{371642} = "Valmiera";
$areanames{en}->{371643} = "Alūksne";
$areanames{en}->{371644} = "Gulbene";
$areanames{en}->{371645} = "Balvi";
$areanames{en}->{371646} = "Rēzekne";
$areanames{en}->{371647} = "Valka";
$areanames{en}->{371648} = "Madona";
$areanames{en}->{371649} = "Aizkraukle";
$areanames{en}->{371650} = "Ogre";
$areanames{en}->{371651} = "Aizkraukle";
$areanames{en}->{371652} = "Jēkabpils";
$areanames{en}->{371653} = "Preiļi";
$areanames{en}->{371654} = "Daugavpils";
$areanames{en}->{371655} = "Ogre";
$areanames{en}->{371656} = "Krāslava";
$areanames{en}->{371657} = "Ludza";
$areanames{en}->{371658} = "Daugavpils";
$areanames{en}->{371659} = "Cēsis";
$areanames{en}->{37166} = "Riga";
$areanames{en}->{37167} = "Riga";
$areanames{en}->{371682} = "Valmiera";
$areanames{en}->{371683} = "Jēkabpils";
$areanames{en}->{371684} = "Liepāja";
$areanames{en}->{371686} = "Jelgava";
$areanames{en}->{37169} = "Riga";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+371|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;