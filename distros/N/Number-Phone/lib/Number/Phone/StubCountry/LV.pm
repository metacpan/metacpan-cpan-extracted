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
our $VERSION = 1.20210309172132;

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
$areanames{en} = {"371633", "Kuldiga",
"371630", "Jelgava",
"371631", "Tukums",
"371682", "Valmiera",
"371635", "Ventspils",
"371646", "Rēzekne",
"371647", "Valka",
"371644", "Gulbene",
"371639", "Bauska",
"37169", "Riga",
"371642", "Valmiera",
"371655", "Ogre",
"371650", "Ogre",
"371653", "Preiļi",
"371686", "Jelgava",
"37162", "Valmiera",
"371651", "Aizkraukle",
"371648", "Madona",
"371684", "Liepāja",
"371659", "Cēsis",
"371645", "Balvi",
"371652", "Jēkabpils",
"371636", "Ventspils",
"37166", "Riga",
"371640", "Limbaži",
"371643", "Alūksne",
"371641", "Cēsis",
"37167", "Riga",
"371658", "Daugavpils",
"371649", "Aizkraukle",
"371637", "Dobele",
"371634", "Liepaja",
"371638", "Saldus",
"37161", "Jūrmala",
"371632", "Talsi",
"371656", "Krāslava",
"371683", "Jēkabpils",
"371654", "Daugavpils",
"371657", "Ludza",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+371|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;