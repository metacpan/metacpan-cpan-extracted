# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::CV;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250913135857;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-589]',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            2[1-7]|
            3[0-8]|
            4[12]|
            5[1256]|
            6\\d|
            7[1-3]|
            8[1-5]
          )\\d{4}
        ',
                'geographic' => '
          2(?:
            2[1-7]|
            3[0-8]|
            4[12]|
            5[1256]|
            6\\d|
            7[1-3]|
            8[1-5]
          )\\d{4}
        ',
                'mobile' => '
          (?:
            36|
            5[1-389]|
            9\\d
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '800\\d{4}',
                'voip' => '
          (?:
            3[3-5]|
            4[356]
          )\\d{5}
        '
              };
my %areanames = ();
$areanames{en} = {"238284", "São\ Jorge\,\ Fogo",
"238264", "Praia\,\ Santiago",
"238223", "Paúl\,\ Santo\ Antão",
"238273", "Calheta\ de\ São\ Miguel\,\ Santiago",
"238268", "São\ Domingos\,\ Santiago",
"238283", "Mosteiros\,\ Fogo",
"238263", "Praia\,\ Santiago",
"238238", "Praia\ Branca\,\ São\ Nicolau",
"238224", "Cocoli\,\ Santo\ Antão",
"238269", "Pedra\ Badejo\,\ Santiago",
"238271", "Orgão\/São\ Jorge\ \(Santiago\ Island\)",
"238281", "São\ Filipe\,\ Fogo",
"238285", "Nova\ Sintra\,\ Brava",
"238261", "Praia\,\ Santiago",
"238265", "Santa\ Catarina\,\ Santiago",
"238231", "Mindelo\,\ São\ Vicente",
"238235", "Ribeira\ Brava\,\ São\ Nicolau",
"238242", "Santa\ Maria\,\ Sal",
"238226", "Manta\ Velha\/Chã\ de\ Igreja\ \ \(Santo\ Antão\ Island\)",
"238256", "Calheta\,\ Maio",
"238236", "Tarrafal\ de\ São\ Nicolau\,\ São\ Nicolau",
"238266", "Tarrafal\,\ Santiago",
"238221", "Ribeira\ Grande\,\ Santo\ Antão",
"238225", "Ponta\ do\ Sol\,\ Santo\ Antão",
"238251", "Sal\ Rei\,\ Boa\ Vista",
"238255", "Vila\ do\ Maio\,\ Maio",
"238272", "Picos\,\ Santiago",
"238227", "Lajedos\/Alto\ Mira\ \(Santo\ Antão\ Island\)",
"238241", "Espargos\,\ Sal",
"238232", "Mindelo\,\ São\ Vicente",
"238282", "Cova\ Figueira\,\ Fogo",
"238262", "Praia\,\ Santiago",
"238237", "Fajã\,\ São\ Nicolau",
"238267", "Cidade\ Velha\,\ Santiago",
"238230", "Mindelo\,\ São\ Vicente",
"238260", "Praia\,\ Santiago",
"238222", "Porto\ Novo\,\ Santo\ Antão",
"238252", "Funda\ das\ Figueiras\,\ Boa\ Vista",};
$areanames{pt} = {};
my $timezones = {
               '' => [
                       'Atlantic/Cape_Verde'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+238|\D)//g;
      my $self = bless({ country_code => '238', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;