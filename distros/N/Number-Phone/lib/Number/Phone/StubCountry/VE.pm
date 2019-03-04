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
package Number::Phone::StubCountry::VE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190303205540;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'leading_digits' => '[24589]',
                  'format' => '$1-$2',
                  'pattern' => '(\\d{3})(\\d{7})'
                }
              ];

my $validators = {
                'toll_free' => '800\\d{7}',
                'personal_number' => '',
                'fixed_line' => '
          (?:
            2(?:
              12|
              3[457-9]|
              [467]\\d|
              [58][1-9]|
              9[1-6]
            )|
            50[01]
          )\\d{7}
        ',
                'specialrate' => '(900\\d{7})',
                'voip' => '',
                'pager' => '',
                'geographic' => '
          (?:
            2(?:
              12|
              3[457-9]|
              [467]\\d|
              [58][1-9]|
              9[1-6]
            )|
            50[01]
          )\\d{7}
        ',
                'mobile' => '
          4(?:
            1[24-8]|
            2[46]
          )\\d{7}
        '
              };
my %areanames = (
  5821 => "Caracas\/Miranda\/Vargas",
  58234 => "Miranda",
  58235 => "Anzoátegui\/Bolívar\/Guárico",
  58237 => "Federal\ Dependencies",
  58238 => "Guárico",
  58239 => "Miranda",
  58241 => "Carabobo",
  58242 => "Carabobo",
  58243 => "Aragua\/Carabobo",
  58244 => "Aragua",
  58245 => "Aragua\/Carabobo",
  58246 => "Aragua\/Guárico",
  58247 => "Apure\/Guárico",
  58248 => "Amazonas",
  58249 => "Carabobo\/Falcón",
  58251 => "Lara\/Yaracuy",
  58252 => "Lara",
  58253 => "Lara\/Yaracuy",
  58254 => "Yaracuy",
  58255 => "Portuguesa",
  58256 => "Portuguesa",
  58257 => "Portuguesa",
  58258 => "Cojedes",
  58259 => "Falcón",
  5826 => "Zulia",
  58260 => "Colombia",
  58268 => "Falcón",
  58269 => "Falcón",
  58270 => "Colombia",
  58271 => "Mérida\/Trujillo\/Zulia",
  58272 => "Trujillo",
  58273 => "Barinas\/Mérida",
  58274 => "Mérida",
  58275 => "Mérida\/Zulia",
  58276 => "Táchira",
  58277 => "Táchira",
  58278 => "Apure\/Barinas",
  58281 => "Anzoátegui",
  58282 => "Anzoátegui",
  58283 => "Anzoátegui",
  58285 => "Bolívar",
  58286 => "Bolívar",
  58287 => "Delta\ Amacuro\/Monagas",
  58288 => "Bolívar",
  58291 => "Monagas",
  58292 => "Monagas",
  58293 => "Sucre",
  58294 => "Sucre",
  58295 => "Nueva\ Esparta",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+58|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;