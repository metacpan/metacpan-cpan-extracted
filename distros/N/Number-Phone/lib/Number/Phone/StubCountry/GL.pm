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
package Number::Phone::StubCountry::GL;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20191211212301;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            19|
            [2-689]
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            19|
            3[1-7]|
            6[14689]|
            8[14-79]|
            9\\d
          )\\d{4}
        ',
                'geographic' => '
          (?:
            19|
            3[1-7]|
            6[14689]|
            8[14-79]|
            9\\d
          )\\d{4}
        ',
                'mobile' => '
          (?:
            [25][1-9]|
            4[2-9]
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '80\\d{4}',
                'voip' => '3[89]\\d{4}'
              };
my %areanames = ();
$areanames{en}->{29931} = "Nuuk";
$areanames{en}->{29932} = "Nuuk";
$areanames{en}->{29933} = "Nuuk";
$areanames{en}->{29934} = "Nuuk";
$areanames{en}->{29935} = "Nuuk";
$areanames{en}->{29936} = "Nuuk";
$areanames{en}->{29961} = "Nanortalik";
$areanames{en}->{29964} = "Qaqortoq";
$areanames{en}->{29966} = "Narsaq";
$areanames{en}->{29968} = "Paamiut";
$areanames{en}->{299691} = "Ivittuut";
$areanames{en}->{29981} = "Maniitsoq";
$areanames{en}->{29984} = "Kangerlussuaq";
$areanames{en}->{29985} = "Sisimiut";
$areanames{en}->{29986} = "Sisimiut";
$areanames{en}->{29987} = "Kangaatsiaq";
$areanames{en}->{29989} = "Aasiaat";
$areanames{en}->{29991} = "Qasigannguit";
$areanames{en}->{29992} = "Qeqertasuaq";
$areanames{en}->{29994} = "Ilulissat";
$areanames{en}->{29995} = "Uummannaq";
$areanames{en}->{29996} = "Upernavik";
$areanames{en}->{29997} = "Qaanaaq";
$areanames{en}->{29998} = "Tasiilaq";
$areanames{en}->{29999} = "Ittoqqortoormiit";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+299|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;