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
package Number::Phone::StubCountry::LT;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170702164948;

my $formatters = [
                {
                  'leading_digits' => '
            37|
            4(?:
              1|
              5[45]|
              6[2-4]
            )
          ',
                  'pattern' => '([34]\\d)(\\d{6})'
                },
                {
                  'pattern' => '([3-6]\\d{2})(\\d{5})',
                  'leading_digits' => '
            3[148]|
            4(?:
              [24]|
              6[09]
            )|
            528|
            6
          '
                },
                {
                  'pattern' => '([7-9]\\d{2})(\\d{2})(\\d{3})',
                  'leading_digits' => '[7-9]'
                },
                {
                  'pattern' => '(5)(2\\d{2})(\\d{4})',
                  'leading_digits' => '52[0-79]'
                }
              ];

my $validators = {
                'pager' => '',
                'toll_free' => '800\\d{5}',
                'voip' => '',
                'mobile' => '6\\d{7}',
                'fixed_line' => '
          (?:
            3[1478]|
            4[124-6]|
            52
          )\\d{6}
        ',
                'personal_number' => '700\\d{5}',
                'geographic' => '
          (?:
            3[1478]|
            4[124-6]|
            52
          )\\d{6}
        ',
                'specialrate' => '(808\\d{5})|(
          9(?:
            0[0239]|
            10
          )\\d{5}
        )|(70[67]\\d{5})'
              };
my %areanames = (
  370310 => "Varėna",
  370313 => "Druskininkai",
  370315 => "Alytus",
  370318 => "Lazdijai",
  370319 => "Birštonas\/Prienai",
  370340 => "Ukmergė",
  370342 => "Vilkaviškis",
  370343 => "Marijampolė",
  370345 => "Šakiai",
  370346 => "Kaišiadorys",
  370347 => "Kėdainiai",
  370349 => "Jonava",
  37037 => "Kaunas",
  370380 => "Šalčininkai",
  370381 => "Anykščiai",
  370382 => "Širvintos",
  370383 => "Molėtai",
  370385 => "Zarasai",
  370386 => "Ignalina\/Visaginas",
  370387 => "Švenčionys",
  370389 => "Utena",
  37041 => "Šiauliai",
  370421 => "Pakruojis",
  370422 => "Radviliškis",
  370425 => "Akmenė",
  370426 => "Joniškis",
  370427 => "Kelmė",
  370428 => "Raseiniai",
  370440 => "Skuodas",
  370441 => "Šilutė",
  370443 => "Mažeikiai",
  370444 => "Telšiai",
  370445 => "Kretinga",
  370446 => "Tauragė",
  370447 => "Jurbarkas",
  370448 => "Plungė",
  370449 => "Šilalė",
  37045 => "Panevėžys",
  370450 => "Biržai",
  370451 => "Pasvalys",
  370458 => "Rokiškis",
  370459 => "Kupiškis",
  37046 => "Klaipėda",
  370460 => "Palanga",
  370469 => "Neringa",
  3705 => "Vilnius",
  370528 => "Elektrėnai\/Trakai",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+370|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^8)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;