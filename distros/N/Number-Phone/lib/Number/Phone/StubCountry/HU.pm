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
package Number::Phone::StubCountry::HU;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250605193635;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'national_rule' => '(06 $1)',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [27][2-9]|
            3[2-7]|
            4[24-9]|
            5[2-79]|
            6|
            8[2-57-9]|
            9[2-69]
          ',
                  'national_rule' => '(06 $1)',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-9]',
                  'national_rule' => '06 $1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1\\d|
            [27][2-9]|
            3[2-7]|
            4[24-9]|
            5[2-79]|
            6[23689]|
            8[2-57-9]|
            9[2-69]
          )\\d{6}
        ',
                'geographic' => '
          (?:
            1\\d|
            [27][2-9]|
            3[2-7]|
            4[24-9]|
            5[2-79]|
            6[23689]|
            8[2-57-9]|
            9[2-69]
          )\\d{6}
        ',
                'mobile' => '
          (?:
            [257]0|
            3[01]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(9[01]\\d{6})|(38\\d{7})',
                'toll_free' => '
          (?:
            [48]0\\d|
            680[29]
          )\\d{5}
        ',
                'voip' => '21\\d{7}'
              };
my %areanames = ();
$areanames{en} = {"3696", "Gyor",
"3674", "Szekszard",
"3683", "Keszthely",
"3624", "Szigetszentmiklós",
"3644", "Mátészalka",
"3637", "Gyongyos",
"3663", "Szentes",
"3635", "Balassagyarmat",
"3656", "Szolnok",
"3632", "Salgotarjan",
"3685", "Marcali",
"3682", "Kaposvar",
"3669", "Mohacs",
"3654", "Berettyoujfalu",
"3668", "Oroshaza",
"361", "Budapest",
"3694", "Szombathely",
"3633", "Esztergom",
"3687", "Tapolca",
"3676", "Kecskemet",
"3662", "Szeged",
"3689", "Papa",
"3688", "Veszprem",
"3626", "Szentendre",
"3646", "Miskolc",
"3684", "Siofok",
"3699", "Sopron",
"3623", "Biatorbágy",
"3636", "Eger",
"3652", "Debrecen",
"3673", "Szigetvar",
"3695", "Sarvar",
"3692", "Zalaegerszeg",
"3657", "Jaszbereny",
"3659", "Karcag",
"3653", "Cegled",
"3672", "Pecs",
"3666", "Bekescsaba",
"3675", "Paks",
"3642", "Nyiregyhaza",
"3622", "Székesfehérvár",
"3625", "Dunaujvaros",
"3645", "Kisvarda",
"3679", "Baja",
"3648", "Ozd",
"3677", "Kiskunhalas",
"3628", "Godollo",
"3629", "Monor",
"3634", "Tatabanya",
"3647", "Szerencs",
"3693", "Nagykanizsa",
"3627", "Vac",
"3678", "Kiskoros",
"3649", "Mezokovesd",};
$areanames{hu} = {"3696", "Győr",
"3674", "Szekszárd",
"3637", "Gyöngyös",
"3632", "Salgótarján",
"3682", "Kaposvár",
"3669", "Mohács",
"3654", "Berettyóújfalu",
"3668", "Orosháza",
"3676", "Kecskemét",
"3689", "Pápa",
"3688", "Veszprém",
"3684", "Siófok",
"3673", "Szigetvár",
"3695", "Sárvár",
"3657", "Jászberény",
"3653", "Cegléd",
"3672", "Pécs",
"3666", "Békéscsaba",
"3642", "Nyíregyháza",
"3625", "Dunaújváros",
"3645", "Kisvárda",
"3648", "Ózd",
"3628", "Gödöllő",
"3634", "Tatabánya",
"3627", "Vác",
"3649", "Mezőkövesd",
"3678", "Kiskőrös",};
my $timezones = {
               '' => [
                       'Europe/Budapest'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+36|\D)//g;
      my $self = bless({ country_code => '36', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:06)//;
      $self = bless({ country_code => '36', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;