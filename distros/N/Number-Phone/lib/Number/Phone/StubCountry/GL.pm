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
our $VERSION = 1.20170702164948;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'geographic' => '
          (?:
            19|
            3[1-6]|
            6[14689]|
            8[14-79]|
            9\\d
          )\\d{4}
        ',
                'specialrate' => '',
                'personal_number' => '',
                'voip' => '3[89]\\d{4}',
                'pager' => '',
                'toll_free' => '80\\d{4}',
                'fixed_line' => '
          (?:
            19|
            3[1-6]|
            6[14689]|
            8[14-79]|
            9\\d
          )\\d{4}
        ',
                'mobile' => '[245][2-9]\\d{4}'
              };
my %areanames = (
  29931 => "Nuuk",
  29932 => "Nuuk",
  29933 => "Nuuk",
  29934 => "Nuuk",
  29935 => "Nuuk",
  29936 => "Nuuk",
  29961 => "Nanortalik",
  29964 => "Qaqortoq",
  29966 => "Narsaq",
  29968 => "Paamiut",
  299691 => "Ivittuut",
  29981 => "Maniitsoq",
  29984 => "Kangerlussuaq",
  29985 => "Sisimiut",
  29986 => "Sisimiut",
  29987 => "Kangaatsiaq",
  29989 => "Aasiaat",
  29991 => "Qasigannguit",
  29992 => "Qeqertasuaq",
  29994 => "Ilulissat",
  29995 => "Uummannaq",
  29996 => "Upernavik",
  29997 => "Qaanaaq",
  29998 => "Tasiilaq",
  29999 => "Ittoqqortoormiit",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+299|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;