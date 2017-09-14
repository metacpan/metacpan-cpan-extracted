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
package Number::Phone::StubCountry::MR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113148;

my $formatters = [
                {
                  'pattern' => '([2-48]\\d)(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'personal_number' => '',
                'geographic' => '
          25[08]\\d{5}|
          35\\d{6}|
          45[1-7]\\d{5}
        ',
                'pager' => '',
                'mobile' => '[234][0-46-9]\\d{6}',
                'toll_free' => '800\\d{5}',
                'fixed_line' => '
          25[08]\\d{5}|
          35\\d{6}|
          45[1-7]\\d{5}
        ',
                'specialrate' => '',
                'voip' => ''
              };
my %areanames = (
  22245 => "Nouakchott",
  2224513 => "Néma",
  2224515 => "Aioun",
  2224533 => "Kaédi",
  2224534 => "Sélibaby",
  2224537 => "Aleg",
  2224544 => "Zouérat",
  2224546 => "Atar",
  2224550 => "Boghé",
  2224563 => "Kiffa",
  2224569 => "Rosso\/Tidjikja",
  2224574 => "Nouadhibou",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+222|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;