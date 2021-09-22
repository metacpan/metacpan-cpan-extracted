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
package Number::Phone::StubCountry::MG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210921211832;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[23]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2072[29]\\d{4}|
          20(?:
            2\\d|
            4[47]|
            5[3467]|
            6[279]|
            7[35]|
            8[268]|
            9[245]
          )\\d{5}
        ',
                'geographic' => '
          2072[29]\\d{4}|
          20(?:
            2\\d|
            4[47]|
            5[3467]|
            6[279]|
            7[35]|
            8[268]|
            9[245]
          )\\d{5}
        ',
                'mobile' => '3[2-489]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => '22\\d{7}'
              };
my %areanames = ();
$areanames{en} = {"2612047", "Ambositra",
"2612073", "Farafangana",
"2612054", "Ambatondrazaka",
"2612069", "Maintirano",
"2612057", "Maroantsetra\/Sainte\ Marie",
"26120729", "Mananjary",
"2612056", "Moramanga",
"2612086", "Nosy\ Be",
"2612044", "Antsirabe",
"2612095", "Morondava",
"2612053", "Toamasina",
"2612082", "Antsiranana",
"2612062", "Mahajanga",
"26120722", "Manakara",
"2612092", "Taolañaro",
"2612067", "Antsohihy",
"2612088", "Sambava",
"2612075", "Fianarantsoa",
"2612094", "Toliary",
"2612022", "Antananarivo",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+261|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      my $prefix = qr/^(?:0|([24-9]\d{6})$)/;
      my @matches = $number =~ /$prefix/;
      if (defined $matches[-1]) {
        no warnings 'uninitialized';
        $number =~ s/$prefix/20$1/;
      }
      else {
        $number =~ s/$prefix//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;