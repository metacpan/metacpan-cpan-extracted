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
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'leading_digits' => '[2-7]',
                  'pattern' => '(\\d)(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})',
                  'leading_digits' => '0'
                }
              ];

my $validators = {
                'toll_free' => '',
                'geographic' => '01\\d{6}',
                'personal_number' => '',
                'mobile' => '0?[2-7]\\d{6}',
                'specialrate' => '',
                'fixed_line' => '01\\d{6}',
                'pager' => '',
                'voip' => ''
              };
my %areanames = (
  2410140 => "Kango",
  24101420 => "Ntoum",
  24101424 => "Cocobeach",
  2410144 => "Libreville",
  2410145 => "Libreville",
  2410146 => "Libreville",
  2410147 => "Libreville",
  2410148 => "Libreville",
  2410150 => "Gamba",
  2410154 => "Omboué",
  2410155 => "Port\-Gentil",
  2410156 => "Port\-Gentil",
  2410158 => "Lambaréné",
  2410159 => "Ndjolé",
  2410160 => "Ngouoni",
  2410162 => "Mounana",
  2410164 => "Lastoursville",
  2410165 => "Koulamoutou",
  2410166 => "Moanda",
  2410167 => "Franceville",
  2410169 => "Léconi\/Akiéni\/Okondja",
  241017 => "Libreville",
  2410182 => "Tchibanga",
  2410183 => "Mayumba",
  2410186 => "Mouila",
  2410190 => "Makokou",
  2410192 => "Mékambo",
  2410193 => "Booué",
  2410196 => "Bitam",
  2410198 => "Oyem",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+241|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;