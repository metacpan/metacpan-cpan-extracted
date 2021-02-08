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
package Number::Phone::StubCountry::TO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210204173827;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '
            [2-4]|
            50|
            6[09]|
            7[0-24-69]|
            8[05]
          ',
                  'pattern' => '(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'pattern' => '(\\d{4})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[5-8]',
                  'pattern' => '(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2\\d|
            3[0-8]|
            4[0-4]|
            50|
            6[09]|
            7[0-24-69]|
            8[05]
          )\\d{3}
        ',
                'geographic' => '
          (?:
            2\\d|
            3[0-8]|
            4[0-4]|
            50|
            6[09]|
            7[0-24-69]|
            8[05]
          )\\d{3}
        ',
                'mobile' => '
          6(?:
            3[02]|
            8[5-9]
          )\\d{4}|
          (?:
            6[09]|
            7\\d|
            8[46-9]
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(55[04]\\d{4})',
                'toll_free' => '0800\\d{3}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"67629", "Pea",
"67641", "Masilamea",
"67631", "Muʻa",
"67675", "Vava\’u",
"67679", "Vava\’u",
"67635", "Nakolo",
"67650", "\‘Eua",
"67669", "Ha\’apai",
"67633", "Kolonga",
"67671", "Vava\’u",
"67685", "Niuas",
"67643", "Matangiake",
"67630", "Pea",
"67634", "Kolonga",
"67640", "Kolovai",
"67676", "Vava\’u",
"67632", "Muʻa",
"67660", "Ha\’apai",
"67642", "Masilamea",
"67680", "Niuas",
"67636", "Nakolo",
"67672", "Vava\’u",
"67637", "Vaini",
"6762", "Nuku\'alofa",
"67638", "Vaini",
"67670", "Vava\’u",
"67674", "Vava\’u",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+676|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;