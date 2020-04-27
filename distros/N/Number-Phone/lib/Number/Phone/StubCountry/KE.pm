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
package Number::Phone::StubCountry::KE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120030;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[24-6]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{5,7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[17]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{6})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[89]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            4[245]|
            5[1-79]|
            6[01457-9]
          )\\d{5,7}|
          (?:
            4[136]|
            5[08]|
            62
          )\\d{7}|
          (?:
            [24]0|
            66
          )\\d{6,7}
        ',
                'geographic' => '
          (?:
            4[245]|
            5[1-79]|
            6[01457-9]
          )\\d{5,7}|
          (?:
            4[136]|
            5[08]|
            62
          )\\d{7}|
          (?:
            [24]0|
            66
          )\\d{6,7}
        ',
                'mobile' => '
          (?:
            1(?:
              0[0-2]|
              1[01]
            )|
            7\\d\\d
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(900[02-9]\\d{5})',
                'toll_free' => '800[24-8]\\d{5,6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{2542} = "Nairobi";
$areanames{en}->{25440} = "Kwale\/Ukunda\/Msambweni\/Lungalunga";
$areanames{en}->{25441} = "Mombasa\/Mariakani\/Kilifi";
$areanames{en}->{25442} = "Malindi\/Lamu\/Garsen";
$areanames{en}->{25443} = "Voi\/Wundanyi\/Mwatate\/Taveta";
$areanames{en}->{25444} = "Machakos\/Makueni\/Mwingi\/Kitui";
$areanames{en}->{25445} = "Kajiado\/Ngong\/Loitokitok\/Athi\ River";
$areanames{en}->{25446} = "Garissa\/Hola\/Wajir\/Mandera";
$areanames{en}->{25450} = "Naivasha\/Narok\/Gilgil";
$areanames{en}->{25451} = "Nakuru\/Njoro\/Molo";
$areanames{en}->{25452} = "Kericho\/Bomet";
$areanames{en}->{25453} = "Eldoret\/Turbo\/Kapsabet\/Iten\/Kabarnet";
$areanames{en}->{25454} = "Kitale\/Moi\'s\ Bridge\/Kapenguria\/Lodwar";
$areanames{en}->{25455} = "Bungoma\/Busia";
$areanames{en}->{25456} = "Kakamega\/Mbale\/Butere\/Mumias\/Vihiga";
$areanames{en}->{25457} = "Kisumu\/Siaya\/Maseno";
$areanames{en}->{25458} = "Kisii\/Kilgoris\/Oyugis\/Nyamira";
$areanames{en}->{25459} = "Homabay\/Migori";
$areanames{en}->{25460} = "Muranga\/Kerugoya";
$areanames{en}->{25461} = "Nyeri\/Karatina";
$areanames{en}->{25462} = "Nanyuki";
$areanames{en}->{25464} = "Meru\/Maua\/Chuka";
$areanames{en}->{25465} = "Nyahururu\/Maralal";
$areanames{en}->{25466} = "Thika\/Ruiru";
$areanames{en}->{25467} = "Kiambu\/Kikuyu";
$areanames{en}->{25468} = "Embu";
$areanames{en}->{25469} = "Marsabit\/Moyale";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+254|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;