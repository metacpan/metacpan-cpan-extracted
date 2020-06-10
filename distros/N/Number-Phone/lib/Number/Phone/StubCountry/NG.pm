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
package Number::Phone::StubCountry::NG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200606132001;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '78',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [12]|
            9(?:
              0[3-9]|
              [1-9]
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [3-7]|
            8[2-9]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2,3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[7-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[78]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{4})(\\d{4,5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[78]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{5})(\\d{5,6})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            (?:
              [1-356]\\d|
              4[02-8]|
              8[2-9]
            )\\d|
            9(?:
              0[3-9]|
              [1-9]\\d
            )
          )\\d{5}|
          7(?:
            0(?:
              [013-689]\\d|
              2[0-24-9]
            )\\d{3,4}|
            [1-79]\\d{6}
          )|
          (?:
            [12]\\d|
            4[147]|
            5[14579]|
            6[1578]|
            7[1-3578]
          )\\d{5}
        ',
                'geographic' => '
          (?:
            (?:
              [1-356]\\d|
              4[02-8]|
              8[2-9]
            )\\d|
            9(?:
              0[3-9]|
              [1-9]\\d
            )
          )\\d{5}|
          7(?:
            0(?:
              [013-689]\\d|
              2[0-24-9]
            )\\d{3,4}|
            [1-79]\\d{6}
          )|
          (?:
            [12]\\d|
            4[147]|
            5[14579]|
            6[1578]|
            7[1-3578]
          )\\d{5}
        ',
                'mobile' => '
          (?:
            702[0-24-9]|
            8(?:
              01|
              19
            )[01]
          )\\d{6}|
          (?:
            70[13-689]|
            8(?:
              0[2-9]|
              1[0-8]
            )|
            90[1-9]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(700\\d{7,11})',
                'toll_free' => '800\\d{7,11}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{2341} = "Lagos";
$areanames{en}->{2342} = "Ibadan";
$areanames{en}->{23430} = "Ado\ Ekiti";
$areanames{en}->{23431} = "Ilorin";
$areanames{en}->{23433} = "New\ Bussa";
$areanames{en}->{23434} = "Akura";
$areanames{en}->{23435} = "Oshogbo";
$areanames{en}->{23436} = "Ile\ Ife";
$areanames{en}->{23437} = "Ijebu\ Ode";
$areanames{en}->{23438} = "Oyo";
$areanames{en}->{23439} = "Abeokuta";
$areanames{en}->{23441} = "Wukari";
$areanames{en}->{23442} = "Enugu";
$areanames{en}->{23443} = "Abakaliki";
$areanames{en}->{23444} = "Makurdi";
$areanames{en}->{23445} = "Ogoja";
$areanames{en}->{23446} = "Onitsha";
$areanames{en}->{23447} = "Lafia";
$areanames{en}->{23448} = "Awka";
$areanames{en}->{23450} = "Ikare";
$areanames{en}->{23451} = "Owo";
$areanames{en}->{23452} = "Benin";
$areanames{en}->{23453} = "Warri";
$areanames{en}->{23454} = "Sapele";
$areanames{en}->{23455} = "Agbor";
$areanames{en}->{23456} = "Asaba";
$areanames{en}->{23457} = "Auchi";
$areanames{en}->{23458} = "Lokoja";
$areanames{en}->{23459} = "Okitipupa";
$areanames{en}->{23460} = "Sokobo";
$areanames{en}->{23461} = "Kafanchau";
$areanames{en}->{23462} = "Kaduna";
$areanames{en}->{23463} = "Gusau";
$areanames{en}->{23464} = "Kano";
$areanames{en}->{23465} = "Katsina";
$areanames{en}->{23466} = "Minna";
$areanames{en}->{23467} = "Kontagora";
$areanames{en}->{23468} = "Birnin\-Kebbi";
$areanames{en}->{23469} = "Zaria";
$areanames{en}->{2347020} = "Pank\ Shin";
$areanames{en}->{23471} = "Azare";
$areanames{en}->{23472} = "Gombe";
$areanames{en}->{23473} = "Jos";
$areanames{en}->{23474} = "Damaturu";
$areanames{en}->{23475} = "Yola";
$areanames{en}->{23476} = "Maiduguri";
$areanames{en}->{23477} = "Bauchi";
$areanames{en}->{23478} = "Hadejia";
$areanames{en}->{23479} = "Jalingo";
$areanames{en}->{23482} = "Aba";
$areanames{en}->{23483} = "Owerri";
$areanames{en}->{23484} = "Port\ Harcourt";
$areanames{en}->{23485} = "Uyo";
$areanames{en}->{23486} = "Ahoada";
$areanames{en}->{23487} = "Calabar";
$areanames{en}->{23488} = "Umuahia";
$areanames{en}->{23489} = "Yenegoa";
$areanames{en}->{234903} = "Abuja";
$areanames{en}->{234904} = "Abuja";
$areanames{en}->{234905} = "Abuja";
$areanames{en}->{234906} = "Abuja";
$areanames{en}->{234907} = "Abuja";
$areanames{en}->{234908} = "Abuja";
$areanames{en}->{234909} = "Abuja";
$areanames{en}->{23491} = "Abuja";
$areanames{en}->{23492} = "Abuja";
$areanames{en}->{23493} = "Abuja";
$areanames{en}->{23494} = "Abuja";
$areanames{en}->{23495} = "Abuja";
$areanames{en}->{23496} = "Abuja";
$areanames{en}->{23497} = "Abuja";
$areanames{en}->{23498} = "Abuja";
$areanames{en}->{23499} = "Abuja";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+234|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;