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
our $VERSION = 1.20220601185318;

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
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            11|
            [67]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '[01]1\\d{6}',
                'geographic' => '[01]1\\d{6}',
                'mobile' => '
          (?:
            (?:
              0[2-7]|
              7[467]
            )\\d|
            6(?:
              0[0-4]|
              10|
              [256]\\d
            )
          )\\d{5}|
          [2-7]\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"2410164", "Lastoursville",
"2411150", "Gamba",
"2411165", "Koulamoutou",
"2410190", "Makokou",
"2410166", "Moanda",
"2410140", "Kango",
"24111424", "Cocobeach",
"2411183", "Mayumba",
"2411196", "Bitam",
"2411144", "Libreville",
"2411182", "Tchibanga",
"2410156", "Port\-Gentil",
"2410145", "Libreville",
"2411146", "Libreville",
"2410154", "Omboué",
"2411160", "Ngouoni",
"2411155", "Port\-Gentil",
"241017", "Libreville",
"2411147", "Libreville",
"2411198", "Oyem",
"2411193", "Booué",
"2411186", "Mouila",
"2411192", "Mékambo",
"2410158", "Lambaréné",
"2411169", "Léconi\/Akiéni\/Okondja",
"2411148", "Libreville",
"2411159", "Ndjolé",
"2410167", "Franceville",
"24111420", "Ntoum",
"2410162", "Mounana",
"2410159", "Ndjolé",
"2411167", "Franceville",
"2411162", "Mounana",
"24101420", "Ntoum",
"241117", "Libreville",
"2410192", "Mékambo",
"2411158", "Lambaréné",
"2410186", "Mouila",
"2410193", "Booué",
"2410198", "Oyem",
"2410147", "Libreville",
"2410169", "Léconi\/Akiéni\/Okondja",
"2410148", "Libreville",
"2411156", "Port\-Gentil",
"2410182", "Tchibanga",
"2410144", "Libreville",
"2410183", "Mayumba",
"2410196", "Bitam",
"2411145", "Libreville",
"2411154", "Omboué",
"2410146", "Libreville",
"2410155", "Port\-Gentil",
"2410160", "Ngouoni",
"2411164", "Lastoursville",
"2411190", "Makokou",
"2410150", "Gamba",
"2410165", "Koulamoutou",
"2411166", "Moanda",
"2411140", "Kango",
"24101424", "Cocobeach",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+241|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      my $prefix = qr/^(?:0(11\d{6}|60\d{6}|61\d{6}|6[256]\d{6}|7[467]\d{6}))/;
      my @matches = $number =~ /$prefix/;
      if (defined $matches[-1]) {
        no warnings 'uninitialized';
        $number =~ s/$prefix/$1/;
      }
      else {
        $number =~ s/$prefix//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;