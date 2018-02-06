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
our $VERSION = 1.20180203200235;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2',
                  'pattern' => '(\\d{2})(\\d{5,7})',
                  'leading_digits' => '[24-6]'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2',
                  'leading_digits' => '7',
                  'pattern' => '(\\d{3})(\\d{6})'
                },
                {
                  'leading_digits' => '[89]',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1'
                }
              ];

my $validators = {
                'mobile' => '
          7(?:
            [0-3679]\\d|
            4[0-46-9]|
            5[0-6]|
            8[0-25-9]
          )\\d{6}
        ',
                'personal_number' => '',
                'geographic' => '
          20\\d{6,7}|
          4(?:
            0\\d{6,7}|
            [136]\\d{7}|
            [245]\\d{5,7}
          )|
          5(?:
            [08]\\d{7}|
            [1-79]\\d{5,7}
          )|
          6(?:
            [01457-9]\\d{5,7}|
            2\\d{7}|
            6\\d{6,7}
          )
        ',
                'specialrate' => '(900[02-9]\\d{5})',
                'fixed_line' => '
          20\\d{6,7}|
          4(?:
            0\\d{6,7}|
            [136]\\d{7}|
            [245]\\d{5,7}
          )|
          5(?:
            [08]\\d{7}|
            [1-79]\\d{5,7}
          )|
          6(?:
            [01457-9]\\d{5,7}|
            2\\d{7}|
            6\\d{6,7}
          )
        ',
                'toll_free' => '800[24-8]\\d{5,6}',
                'pager' => '',
                'voip' => ''
              };
my %areanames = (
  25420 => "Nairobi",
  25440 => "Kwale\/Ukunda\/Msambweni\/Lungalunga",
  25441 => "Mombasa\/Mariakani\/Kilifi",
  25442 => "Malindi\/Lamu\/Garsen",
  25443 => "Voi\/Wundanyi\/Mwatate\/Taveta",
  25444 => "Machakos\/Makueni\/Mwingi\/Kitui",
  25445 => "Kajiado\/Ngong\/Loitokitok\/Athi\ River",
  25446 => "Garissa\/Hola\/Wajir\/Mandera",
  25450 => "Naivasha\/Narok\/Gilgil",
  25451 => "Nakuru\/Njoro\/Molo",
  25452 => "Kericho\/Bomet",
  25453 => "Eldoret\/Turbo\/Kapsabet\/Iten\/Kabarnet",
  25454 => "Kitale\/Moi\'s\ Bridge\/Kapenguria\/Lodwar",
  25455 => "Bungoma\/Busia",
  25456 => "Kakamega\/Mbale\/Butere\/Mumias\/Vihiga",
  25457 => "Kisumu\/Siaya\/Maseno",
  25458 => "Kisii\/Kilgoris\/Oyugis\/Nyamira",
  25459 => "Homabay\/Migori",
  25460 => "Muranga\/Kerugoya",
  25461 => "Nyeri\/Karatina",
  25462 => "Nanyuki",
  25464 => "Meru\/Maua\/Chuka",
  25465 => "Nyahururu\/Maralal",
  25466 => "Thika\/Ruiru",
  25467 => "Kiambu\/Kikuyu",
  25468 => "Embu",
  25469 => "Marsabit\/Moyale",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+254|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      {
        no warnings 'uninitialized';
        $number =~ s/^(?:005|0)//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;