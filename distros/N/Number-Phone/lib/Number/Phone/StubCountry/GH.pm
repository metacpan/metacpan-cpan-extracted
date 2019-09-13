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
our $VERSION = 1.20190912215426;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'intl_format' => 'NA',
                  'leading_digits' => '
            [237]|
            80
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
          3(?:
            [167]2[0-6]|
            22[0-5]|
            32[0-3]|
            4(?:
              2[013-9]|
              3[01]
            )|
            52[0-7]|
            82[0-2]
          )\\d{5}|
          3(?:
            [0-8]8|
            9[28]
          )0\\d{5}|
          3(?:
            0[237]|
            [1-9]7
          )\\d{6}
        ',
                'geographic' => '
          3(?:
            [167]2[0-6]|
            22[0-5]|
            32[0-3]|
            4(?:
              2[013-9]|
              3[01]
            )|
            52[0-7]|
            82[0-2]
          )\\d{5}|
          3(?:
            [0-8]8|
            9[28]
          )0\\d{5}|
          3(?:
            0[237]|
            [1-9]7
          )\\d{6}
        ',
                'mobile' => '
          56[01]\\d{6}|
          (?:
            2[0346-8]|
            5[0457]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '800\\d{5}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{233302} = "Accra";
$areanames{en}->{233303} = "Tema";
$areanames{en}->{2333035} = "Ada";
$areanames{en}->{233307} = "Greater\ Accra\ Region";
$areanames{en}->{233308} = "Greater\ Accra\ Region";
$areanames{en}->{2333120} = "Takoradi";
$areanames{en}->{2333121} = "Axim";
$areanames{en}->{2333122} = "Elubo";
$areanames{en}->{2333123} = "Tarkwa";
$areanames{en}->{2333124} = "Asankragwa";
$areanames{en}->{2333125} = "Samreboi";
$areanames{en}->{2333126} = "Enchi";
$areanames{en}->{233317} = "Western\ Region";
$areanames{en}->{233318} = "Western\ Region";
$areanames{en}->{2333220} = "Kumasi";
$areanames{en}->{2333221} = "Konongo";
$areanames{en}->{2333222} = "Ashanti\ Mampong";
$areanames{en}->{2333223} = "Ejura";
$areanames{en}->{2333224} = "Bekwai";
$areanames{en}->{2333225} = "Obuasi";
$areanames{en}->{233327} = "Ashanti\ Region";
$areanames{en}->{233328} = "Ashanti\ Region";
$areanames{en}->{2333320} = "Swedru";
$areanames{en}->{2333321} = "Cape\ Coast";
$areanames{en}->{2333322} = "Dunkwa";
$areanames{en}->{2333323} = "Winneba";
$areanames{en}->{233337} = "Central\ Region";
$areanames{en}->{233338} = "Central\ Region";
$areanames{en}->{2333420} = "Koforidua";
$areanames{en}->{2333421} = "Nsawam";
$areanames{en}->{2333423} = "Mpraeso";
$areanames{en}->{2333424} = "Donkorkrom";
$areanames{en}->{2333425} = "Suhum";
$areanames{en}->{2333426} = "Asamankese";
$areanames{en}->{2333427} = "Akuapim\ Mampong";
$areanames{en}->{2333428} = "Aburi";
$areanames{en}->{23334292} = "Akim\ Oda";
$areanames{en}->{2333430} = "Akosombo";
$areanames{en}->{2333431} = "Nkawkaw";
$areanames{en}->{233347} = "Eastern\ Region";
$areanames{en}->{233348} = "Eastern\ Region";
$areanames{en}->{2333520} = "Sunyani";
$areanames{en}->{2333521} = "Bechem";
$areanames{en}->{2333522} = "Berekum";
$areanames{en}->{2333523} = "Dormaa\ Ahenkro";
$areanames{en}->{2333524} = "Wenchi";
$areanames{en}->{2333525} = "Techiman";
$areanames{en}->{2333526} = "Atebubu";
$areanames{en}->{2333527} = "Yeji";
$areanames{en}->{233357} = "Brong\-Ahafo\ Region";
$areanames{en}->{233358} = "Brong\-Ahafo\ Region";
$areanames{en}->{2333620} = "Ho";
$areanames{en}->{2333621} = "Amedzofe";
$areanames{en}->{2333623} = "Kpandu";
$areanames{en}->{2333624} = "Kete\-Krachi";
$areanames{en}->{2333625} = "Denu\/Aflao";
$areanames{en}->{2333626} = "Keta\/Akatsi";
$areanames{en}->{233367} = "Volta\ Region";
$areanames{en}->{233368} = "Volta\ Region";
$areanames{en}->{2333720} = "Tamale";
$areanames{en}->{2333721} = "Walewale";
$areanames{en}->{2333722} = "Buipe";
$areanames{en}->{2333723} = "Damongo";
$areanames{en}->{2333724} = "Yendi";
$areanames{en}->{2333725} = "Bole";
$areanames{en}->{2333726} = "Salaga";
$areanames{en}->{233377} = "Northern\ Region";
$areanames{en}->{233378} = "Northern\ Region";
$areanames{en}->{2333820} = "Bolgatanga";
$areanames{en}->{2333821} = "Navrongo";
$areanames{en}->{2333822} = "Bawku";
$areanames{en}->{233387} = "Upper\ East\ Region";
$areanames{en}->{233388} = "Upper\ East\ Region";
$areanames{en}->{233392} = "Wa";
$areanames{en}->{233397} = "Upper\ West\ Region";
$areanames{en}->{233398} = "Upper\ West\ Region";

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