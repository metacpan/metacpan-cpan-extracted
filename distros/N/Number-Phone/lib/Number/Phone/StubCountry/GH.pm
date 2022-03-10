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
package Number::Phone::StubCountry::GH;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220307120118;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'intl_format' => 'NA',
                  'leading_digits' => '
            [237]|
            8[0-2]
          ',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[235]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          3082[0-5]\\d{4}|
          3(?:
            0(?:
              [237]\\d|
              8[01]
            )|
            [167](?:
              2[0-6]|
              7\\d|
              80
            )|
            2(?:
              2[0-5]|
              7\\d|
              80
            )|
            3(?:
              2[0-3]|
              7\\d|
              80
            )|
            4(?:
              2[013-9]|
              3[01]|
              7\\d|
              80
            )|
            5(?:
              2[0-7]|
              7\\d|
              80
            )|
            8(?:
              2[0-2]|
              7\\d|
              80
            )|
            9(?:
              [28]0|
              7\\d
            )
          )\\d{5}
        ',
                'geographic' => '
          3082[0-5]\\d{4}|
          3(?:
            0(?:
              [237]\\d|
              8[01]
            )|
            [167](?:
              2[0-6]|
              7\\d|
              80
            )|
            2(?:
              2[0-5]|
              7\\d|
              80
            )|
            3(?:
              2[0-3]|
              7\\d|
              80
            )|
            4(?:
              2[013-9]|
              3[01]|
              7\\d|
              80
            )|
            5(?:
              2[0-7]|
              7\\d|
              80
            )|
            8(?:
              2[0-2]|
              7\\d|
              80
            )|
            9(?:
              [28]0|
              7\\d
            )
          )\\d{5}
        ',
                'mobile' => '
          (?:
            2(?:
              [0346-8]\\d|
              5[67]
            )|
            5(?:
              [0457]\\d|
              6[01]|
              9[1-9]
            )
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '800\\d{5}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"2333720", "Tamale",
"233347", "Eastern\ Region",
"2333425", "Suhum",
"2333423", "Mpraeso",
"2333622", "Hohoe",
"2333821", "Navrongo",
"233348", "Eastern\ Region",
"2333426", "Asamankese",
"2333320", "Swedru",
"2333035", "Ada",
"2333120", "Takoradi",
"2333526", "Atebubu",
"233358", "Brong\-Ahafo\ Region",
"233392", "Wa",
"2333523", "Dormaa\ Ahenkro",
"233302", "Accra",
"2333525", "Techiman",
"2333431", "Nkawkaw",
"2333428", "Aburi",
"2333624", "Kete\-Krachi",
"233357", "Brong\-Ahafo\ Region",
"2333822", "Bawku",
"2333621", "Amedzofe",
"2333723", "Damongo",
"2333125", "Samreboi",
"2333726", "Salaga",
"233378", "Northern\ Region",
"233317", "Western\ Region",
"2333222", "Ashanti\ Mampong",
"233337", "Central\ Region",
"233338", "Central\ Region",
"233318", "Western\ Region",
"233377", "Northern\ Region",
"2333126", "Enchi",
"2333420", "Koforidua",
"2333725", "Bole",
"2333323", "Winneba",
"2333123", "Tarkwa",
"2333224", "Bekwai",
"2333221", "Konongo",
"23334292", "Akim\ Oda",
"2333520", "Sunyani",
"2333722", "Buipe",
"233328", "Ashanti\ Region",
"2333223", "Ejura",
"2333620", "Ho",
"2333225", "Obuasi",
"233327", "Ashanti\ Region",
"2333430", "Akosombo",
"2333322", "Dunkwa",
"2333122", "Elubo",
"2333724", "Yendi",
"2333721", "Walewale",
"2333121", "Axim",
"2333321", "Cape\ Coast",
"2333124", "Asankragwa",
"2333820", "Bolgatanga",
"233367", "Volta\ Region",
"233398", "Upper\ West\ Region",
"2333524", "Wenchi",
"2333527", "Yeji",
"233308", "Greater\ Accra\ Region",
"2333521", "Bechem",
"2333625", "Denu\/Aflao",
"2333220", "Kumasi",
"2333623", "Kpandu",
"233307", "Greater\ Accra\ Region",
"2333626", "Keta\/Akatsi",
"233368", "Volta\ Region",
"233397", "Upper\ West\ Region",
"233303", "Tema",
"233387", "Upper\ East\ Region",
"2333522", "Berekum",
"233388", "Upper\ East\ Region",
"2333427", "Akuapim\ Mampong",
"2333421", "Nsawam",
"2333424", "Donkorkrom",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+233|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;