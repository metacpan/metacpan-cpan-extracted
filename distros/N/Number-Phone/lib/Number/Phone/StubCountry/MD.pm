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
package Number::Phone::StubCountry::MD;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180619214156;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})',
                  'leading_digits' => '
            22|
            3
          ',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1'
                },
                {
                  'leading_digits' => '
            2[13-9]|
            [5-7]
          ',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'pattern' => '([25-7]\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'leading_digits' => '[89]',
                  'format' => '$1 $2',
                  'national_rule' => '0$1',
                  'pattern' => '([89]\\d{2})(\\d{5})'
                }
              ];

my $validators = {
                'mobile' => '
          (?:
            562|
            6\\d{2}|
            7(?:
              [189]\\d|
              6[07]|
              7[457-9]
            )
          )\\d{5}
        ',
                'specialrate' => '(808\\d{5})|(90[056]\\d{5})|(803\\d{5})',
                'geographic' => '
          (?:
            2[1-9]\\d|
            3[1-79]\\d|
            5(?:
              33|
              5[257]
            )
          )\\d{5}
        ',
                'pager' => '',
                'voip' => '3[08]\\d{6}',
                'personal_number' => '',
                'toll_free' => '800\\d{5}',
                'fixed_line' => '
          (?:
            2[1-9]\\d|
            3[1-79]\\d|
            5(?:
              33|
              5[257]
            )
          )\\d{5}
        '
              };
my %areanames = (
  373210 => "Grigoriopol",
  373215 => "Dubasari",
  373216 => "Camenca",
  373219 => "Dnestrovsk",
  37322 => "Chisinau",
  373230 => "Soroca",
  373231 => "Balţi",
  373235 => "Orhei",
  373236 => "Ungheni",
  373237 => "Straseni",
  373241 => "Cimislia",
  373242 => "Stefan\ Voda",
  373243 => "Causeni",
  373244 => "Calarasi",
  373246 => "Edineţ",
  373247 => "Briceni",
  373248 => "Criuleni",
  373249 => "Glodeni",
  373250 => "Floresti",
  373251 => "Donduseni",
  373252 => "Drochia",
  373254 => "Rezina",
  373256 => "Riscani",
  373258 => "Telenesti",
  373259 => "Falesti",
  373262 => "Singerei",
  373263 => "Leova",
  373264 => "Nisporeni",
  373265 => "Anenii\ Noi",
  373268 => "Ialoveni",
  373269 => "Hincesti",
  373271 => "Ocniţa",
  373272 => "Soldanesti",
  373273 => "Cantemir",
  373291 => "Ceadir\ Lunga",
  373293 => "Vulcanesti",
  373294 => "Taraclia",
  373297 => "Basarabeasca",
  373298 => "Comrat",
  373299 => "Cahul",
  373533 => "Tiraspol",
  373552 => "Bender",
  373555 => "Ribnita",
  373557 => "Slobozia",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+373|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;