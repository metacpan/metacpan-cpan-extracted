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
package Number::Phone::StubCountry::DZ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'pattern' => '([1-4]\\d)(\\d{2})(\\d{2})(\\d{2})',
                  'leading_digits' => '[1-4]'
                },
                {
                  'pattern' => '([5-8]\\d{2})(\\d{2})(\\d{2})(\\d{2})',
                  'leading_digits' => '[5-8]'
                },
                {
                  'leading_digits' => '9',
                  'pattern' => '(9\\d)(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'specialrate' => '(80[12]1\\d{5})|(80[3-689]1\\d{5})',
                'mobile' => '
          (?:
            5[4-6]|
            7[7-9]
          )\\d{7}|
          6(?:
            [569]\\d|
            7[0-6]
          )\\d{6}
        ',
                'toll_free' => '800\\d{6}',
                'geographic' => '
          (?:
            1\\d|
            2[013-79]|
            3[0-8]|
            4[0135689]
          )\\d{6}|
          9619\\d{5}
        ',
                'personal_number' => '',
                'pager' => '',
                'voip' => '98[23]\\d{6}',
                'fixed_line' => '
          (?:
            1\\d|
            2[013-79]|
            3[0-8]|
            4[0135689]
          )\\d{6}|
          9619\\d{5}
        '
              };
my %areanames = (
  21321 => "Algiers",
  21327 => "Chlef",
  21329 => "Ghardaia\/Illizi\/Tamanrasset",
  21331 => "Constantine",
  21332 => "El\ Oued",
  21333 => "Batna\/Beskra",
  21334 => "Béjaïa\/Jijel",
  21335 => "Bordj\ Bou\ Arreridj",
  21337 => "Tebessa",
  21338 => "Annaba\/Skikda",
  21341 => "Oran",
  21343 => "Tlemcen",
  21349 => "Adrar\/Béchar\/Tindouf",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+213|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;