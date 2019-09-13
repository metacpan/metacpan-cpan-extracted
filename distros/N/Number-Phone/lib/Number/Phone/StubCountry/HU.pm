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
package Number::Phone::StubCountry::HU;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215426;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'national_rule' => '(06 $1)',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
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
                'toll_free' => '[48]0\\d{6}',
                'voip' => '21\\d{7}'
              };
my %areanames = ();
$areanames{hu}->{361} = "Budapest";
$areanames{hu}->{3622} = "Székesfehérvár";
$areanames{hu}->{3623} = "Biatorbágy";
$areanames{hu}->{3624} = "Szigetszentmiklós";
$areanames{hu}->{3625} = "Dunaújváros";
$areanames{hu}->{3626} = "Szentendre";
$areanames{hu}->{3627} = "Vác";
$areanames{hu}->{3628} = "Gödöllő";
$areanames{hu}->{3629} = "Monor";
$areanames{hu}->{3632} = "Salgótarján";
$areanames{hu}->{3633} = "Esztergom";
$areanames{hu}->{3634} = "Tatabánya";
$areanames{hu}->{3635} = "Balassagyarmat";
$areanames{hu}->{3636} = "Eger";
$areanames{hu}->{3637} = "Gyöngyös";
$areanames{hu}->{3642} = "Nyíregyháza";
$areanames{hu}->{3644} = "Mátészalka";
$areanames{hu}->{3645} = "Kisvárda";
$areanames{hu}->{3646} = "Miskolc";
$areanames{hu}->{3647} = "Szerencs";
$areanames{hu}->{3648} = "Ózd";
$areanames{hu}->{3649} = "Mezőkövesd";
$areanames{hu}->{3652} = "Debrecen";
$areanames{hu}->{3653} = "Cegléd";
$areanames{hu}->{3654} = "Berettyóújfalu";
$areanames{hu}->{3656} = "Szolnok";
$areanames{hu}->{3657} = "Jászberény";
$areanames{hu}->{3659} = "Karcag";
$areanames{hu}->{3662} = "Szeged";
$areanames{hu}->{3663} = "Szentes";
$areanames{hu}->{3666} = "Békéscsaba";
$areanames{hu}->{3668} = "Orosháza";
$areanames{hu}->{3669} = "Mohács";
$areanames{hu}->{3672} = "Pécs";
$areanames{hu}->{3673} = "Szigetvár";
$areanames{hu}->{3674} = "Szekszárd";
$areanames{hu}->{3675} = "Paks";
$areanames{hu}->{3676} = "Kecskemét";
$areanames{hu}->{3677} = "Kiskunhalas";
$areanames{hu}->{3678} = "Kiskőrös";
$areanames{hu}->{3679} = "Baja";
$areanames{hu}->{3682} = "Kaposvár";
$areanames{hu}->{3683} = "Keszthely";
$areanames{hu}->{3684} = "Siófok";
$areanames{hu}->{3685} = "Marcali";
$areanames{hu}->{3687} = "Tapolca";
$areanames{hu}->{3688} = "Veszprém";
$areanames{hu}->{3689} = "Pápa";
$areanames{hu}->{3692} = "Zalaegerszeg";
$areanames{hu}->{3693} = "Nagykanizsa";
$areanames{hu}->{3694} = "Szombathely";
$areanames{hu}->{3695} = "Sárvár";
$areanames{hu}->{3696} = "Győr";
$areanames{hu}->{3699} = "Sopron";
$areanames{en}->{361} = "Budapest";
$areanames{en}->{3622} = "Székesfehérvár";
$areanames{en}->{3623} = "Biatorbágy";
$areanames{en}->{3624} = "Szigetszentmiklós";
$areanames{en}->{3625} = "Dunaujvaros";
$areanames{en}->{3626} = "Szentendre";
$areanames{en}->{3627} = "Vac";
$areanames{en}->{3628} = "Godollo";
$areanames{en}->{3629} = "Monor";
$areanames{en}->{3632} = "Salgotarjan";
$areanames{en}->{3633} = "Esztergom";
$areanames{en}->{3634} = "Tatabanya";
$areanames{en}->{3635} = "Balassagyarmat";
$areanames{en}->{3636} = "Eger";
$areanames{en}->{3637} = "Gyongyos";
$areanames{en}->{3642} = "Nyiregyhaza";
$areanames{en}->{3644} = "Mátészalka";
$areanames{en}->{3645} = "Kisvarda";
$areanames{en}->{3646} = "Miskolc";
$areanames{en}->{3647} = "Szerencs";
$areanames{en}->{3648} = "Ozd";
$areanames{en}->{3649} = "Mezokovesd";
$areanames{en}->{3652} = "Debrecen";
$areanames{en}->{3653} = "Cegled";
$areanames{en}->{3654} = "Berettyoujfalu";
$areanames{en}->{3656} = "Szolnok";
$areanames{en}->{3657} = "Jaszbereny";
$areanames{en}->{3659} = "Karcag";
$areanames{en}->{3662} = "Szeged";
$areanames{en}->{3663} = "Szentes";
$areanames{en}->{3666} = "Bekescsaba";
$areanames{en}->{3668} = "Oroshaza";
$areanames{en}->{3669} = "Mohacs";
$areanames{en}->{3672} = "Pecs";
$areanames{en}->{3673} = "Szigetvar";
$areanames{en}->{3674} = "Szekszard";
$areanames{en}->{3675} = "Paks";
$areanames{en}->{3676} = "Kecskemet";
$areanames{en}->{3677} = "Kiskunhalas";
$areanames{en}->{3678} = "Kiskoros";
$areanames{en}->{3679} = "Baja";
$areanames{en}->{3682} = "Kaposvar";
$areanames{en}->{3683} = "Keszthely";
$areanames{en}->{3684} = "Siofok";
$areanames{en}->{3685} = "Marcali";
$areanames{en}->{3687} = "Tapolca";
$areanames{en}->{3688} = "Veszprem";
$areanames{en}->{3689} = "Papa";
$areanames{en}->{3692} = "Zalaegerszeg";
$areanames{en}->{3693} = "Nagykanizsa";
$areanames{en}->{3694} = "Szombathely";
$areanames{en}->{3695} = "Sarvar";
$areanames{en}->{3696} = "Gyor";
$areanames{en}->{3699} = "Sopron";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+36|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:06)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;