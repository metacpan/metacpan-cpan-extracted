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
package Number::Phone::StubCountry::GA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215426;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[2-7]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '01\\d{6}',
                'geographic' => '01\\d{6}',
                'mobile' => '
          (?:
            0[2-7]|
            [2-7]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{2410140} = "Kango";
$areanames{en}->{24101420} = "Ntoum";
$areanames{en}->{24101424} = "Cocobeach";
$areanames{en}->{2410144} = "Libreville";
$areanames{en}->{2410145} = "Libreville";
$areanames{en}->{2410146} = "Libreville";
$areanames{en}->{2410147} = "Libreville";
$areanames{en}->{2410148} = "Libreville";
$areanames{en}->{2410150} = "Gamba";
$areanames{en}->{2410154} = "Omboué";
$areanames{en}->{2410155} = "Port\-Gentil";
$areanames{en}->{2410156} = "Port\-Gentil";
$areanames{en}->{2410158} = "Lambaréné";
$areanames{en}->{2410159} = "Ndjolé";
$areanames{en}->{2410160} = "Ngouoni";
$areanames{en}->{2410162} = "Mounana";
$areanames{en}->{2410164} = "Lastoursville";
$areanames{en}->{2410165} = "Koulamoutou";
$areanames{en}->{2410166} = "Moanda";
$areanames{en}->{2410167} = "Franceville";
$areanames{en}->{2410169} = "Léconi\/Akiéni\/Okondja";
$areanames{en}->{241017} = "Libreville";
$areanames{en}->{2410182} = "Tchibanga";
$areanames{en}->{2410183} = "Mayumba";
$areanames{en}->{2410186} = "Mouila";
$areanames{en}->{2410190} = "Makokou";
$areanames{en}->{2410192} = "Mékambo";
$areanames{en}->{2410193} = "Booué";
$areanames{en}->{2410196} = "Bitam";
$areanames{en}->{2410198} = "Oyem";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+241|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;