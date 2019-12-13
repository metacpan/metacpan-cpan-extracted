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
package Number::Phone::StubCountry::TR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20191211212303;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'intl_format' => 'NA',
                  'leading_digits' => '444',
                  'pattern' => '(\\d{3})(\\d)(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            512|
            8[0589]|
            90
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            5(?:
              [0-59]|
              6161
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            [24][1-8]|
            3[1-9]
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              [13][26]|
              [28][2468]|
              [45][268]|
              [67][246]
            )|
            3(?:
              [13][28]|
              [24-6][2468]|
              [78][02468]|
              92
            )|
            4(?:
              [16][246]|
              [23578][2468]|
              4[26]
            )
          )\\d{7}
        ',
                'geographic' => '
          (?:
            2(?:
              [13][26]|
              [28][2468]|
              [45][268]|
              [67][246]
            )|
            3(?:
              [13][28]|
              [24-6][2468]|
              [78][02468]|
              92
            )|
            4(?:
              [16][246]|
              [23578][2468]|
              4[26]
            )
          )\\d{7}
        ',
                'mobile' => '
          56161\\d{5}|
          5(?:
            0[15-7]|
            1[06]|
            24|
            [34]\\d|
            5[1-59]|
            9[46]
          )\\d{7}
        ',
                'pager' => '512\\d{7}',
                'personal_number' => '
          592(?:
            21[12]|
            461
          )\\d{4}
        ',
                'specialrate' => '(
          (?:
            8[89]8|
            900
          )\\d{7}
        )|(
          (?:
            444|
            850\\d{3}
          )\\d{4}
        )',
                'toll_free' => '800\\d{7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{90212} = "Istanbul\ \(Europe\)";
$areanames{en}->{90216} = "Istanbul\ \(Anatolia\)";
$areanames{en}->{90222} = "Esksehir";
$areanames{en}->{90224} = "Bursa";
$areanames{en}->{90226} = "Yalova";
$areanames{en}->{90228} = "Bilecik";
$areanames{en}->{90232} = "Izmir";
$areanames{en}->{90236} = "Manisa";
$areanames{en}->{90242} = "Antalya";
$areanames{en}->{90246} = "Isparta";
$areanames{en}->{90248} = "Burdur";
$areanames{en}->{90252} = "Mugla";
$areanames{en}->{90256} = "Aydin";
$areanames{en}->{90258} = "Denizli";
$areanames{en}->{90262} = "Kocaeli";
$areanames{en}->{90264} = "Sakarya";
$areanames{en}->{90266} = "Balikesir";
$areanames{en}->{90272} = "Afyon";
$areanames{en}->{90274} = "Kutahya";
$areanames{en}->{90276} = "Usak";
$areanames{en}->{90282} = "Tekirdag";
$areanames{en}->{90284} = "Edirne";
$areanames{en}->{90286} = "Canakkale";
$areanames{en}->{90288} = "Kirklareli";
$areanames{en}->{90312} = "Ankara";
$areanames{en}->{90318} = "Kirikkale";
$areanames{en}->{90322} = "Adana";
$areanames{en}->{90324} = "Icel";
$areanames{en}->{90326} = "Hatay";
$areanames{en}->{90328} = "Osmaniye";
$areanames{en}->{90332} = "Konya";
$areanames{en}->{90338} = "Karaman";
$areanames{en}->{90342} = "Gaziantep";
$areanames{en}->{90344} = "K\.\ Maras";
$areanames{en}->{90346} = "Sivas";
$areanames{en}->{90348} = "Kilis";
$areanames{en}->{90352} = "Kayseri";
$areanames{en}->{90354} = "Yozgat";
$areanames{en}->{90356} = "Tokat";
$areanames{en}->{90358} = "Amasya";
$areanames{en}->{90362} = "Samsun";
$areanames{en}->{90364} = "Corum";
$areanames{en}->{90366} = "Kastamonu";
$areanames{en}->{90368} = "Sinop";
$areanames{en}->{90370} = "Karabuk";
$areanames{en}->{90372} = "Zongdulak";
$areanames{en}->{90374} = "Bolu";
$areanames{en}->{90376} = "Cankiri";
$areanames{en}->{90378} = "Bartin";
$areanames{en}->{90380} = "Duzce";
$areanames{en}->{90382} = "Aksaray";
$areanames{en}->{90384} = "Nevsehir";
$areanames{en}->{90386} = "Kirsehir";
$areanames{en}->{90388} = "Nigde";
$areanames{en}->{9039} = "Northern\ Cyprus";
$areanames{en}->{90412} = "Diyarbakir";
$areanames{en}->{90414} = "Sanliurfa";
$areanames{en}->{90416} = "Adiyaman";
$areanames{en}->{90422} = "Malatya";
$areanames{en}->{90424} = "Elazig";
$areanames{en}->{90426} = "Bingol";
$areanames{en}->{90428} = "Tuniceli";
$areanames{en}->{90432} = "Van";
$areanames{en}->{90434} = "Bitlis";
$areanames{en}->{90436} = "Mus";
$areanames{en}->{90438} = "Hakkari";
$areanames{en}->{90442} = "Erzurum";
$areanames{en}->{90446} = "Erzincan";
$areanames{en}->{90452} = "Ordu";
$areanames{en}->{90454} = "Giresun";
$areanames{en}->{90456} = "Gumushane";
$areanames{en}->{90458} = "Bayburt";
$areanames{en}->{90462} = "Trabzon";
$areanames{en}->{90464} = "Rize";
$areanames{en}->{90466} = "Artvin";
$areanames{en}->{90472} = "Agri";
$areanames{en}->{90474} = "Kars";
$areanames{en}->{90476} = "Igdir";
$areanames{en}->{90478} = "Ardahan";
$areanames{en}->{90482} = "Mardin";
$areanames{en}->{90484} = "Stirt";
$areanames{en}->{90486} = "Sirnak";
$areanames{en}->{90488} = "Batman";
$areanames{tr}->{90212} = "Istanbul\ \(Avrupa\)";
$areanames{tr}->{90216} = "Istanbul\ \(Anatolia\)";
$areanames{tr}->{90222} = "Eskisehir";
$areanames{tr}->{90224} = "Bursa";
$areanames{tr}->{90226} = "Yalova";
$areanames{tr}->{90228} = "Bilecik";
$areanames{tr}->{90232} = "İzmir";
$areanames{tr}->{90236} = "Manisa";
$areanames{tr}->{90242} = "Antalya";
$areanames{tr}->{90246} = "Isparta";
$areanames{tr}->{90248} = "Burdur";
$areanames{tr}->{90252} = "Muğla";
$areanames{tr}->{90256} = "Aydın";
$areanames{tr}->{90258} = "Denizli";
$areanames{tr}->{90262} = "Kocaeli\ \(İzmit\)";
$areanames{tr}->{90264} = "Sakarya\ \(Adapazarı\)";
$areanames{tr}->{90266} = "Balıkesir";
$areanames{tr}->{90272} = "Afyon";
$areanames{tr}->{90274} = "Kütahya";
$areanames{tr}->{90276} = "Uşak";
$areanames{tr}->{90282} = "Tekirdağ";
$areanames{tr}->{90284} = "Edirne";
$areanames{tr}->{90286} = "Çanakkale";
$areanames{tr}->{90288} = "Kırklareli";
$areanames{tr}->{90312} = "Ankara";
$areanames{tr}->{90318} = "Kırıkkale";
$areanames{tr}->{90322} = "Adana";
$areanames{tr}->{90324} = "Mersin";
$areanames{tr}->{90326} = "Hatay";
$areanames{tr}->{90328} = "Osmaniye";
$areanames{tr}->{90332} = "Konya";
$areanames{tr}->{90338} = "Karaman";
$areanames{tr}->{90342} = "Gaziantep";
$areanames{tr}->{90344} = "Kahramanmaraş";
$areanames{tr}->{90346} = "Sivas";
$areanames{tr}->{90348} = "Kilis";
$areanames{tr}->{90352} = "Kayseri";
$areanames{tr}->{90354} = "Yozgat";
$areanames{tr}->{90356} = "Tokat";
$areanames{tr}->{90358} = "Amasya";
$areanames{tr}->{90362} = "Samsun";
$areanames{tr}->{90364} = "Çorum";
$areanames{tr}->{90366} = "Kastamonu";
$areanames{tr}->{90368} = "Sinop";
$areanames{tr}->{90370} = "Karabük";
$areanames{tr}->{90372} = "Zonguldak";
$areanames{tr}->{90374} = "Bolu";
$areanames{tr}->{90376} = "Çankırı";
$areanames{tr}->{90378} = "Bartın";
$areanames{tr}->{90380} = "Düzce";
$areanames{tr}->{90382} = "Aksaray";
$areanames{tr}->{90384} = "Nevşehir";
$areanames{tr}->{90386} = "Kırşehir";
$areanames{tr}->{90388} = "Niğde";
$areanames{tr}->{9039} = "Kuzey\ Kıbrıs";
$areanames{tr}->{90412} = "Diyarbakır";
$areanames{tr}->{90414} = "Şanlıurfa";
$areanames{tr}->{90416} = "Adıyaman";
$areanames{tr}->{90422} = "Malatya";
$areanames{tr}->{90424} = "Elazığ";
$areanames{tr}->{90426} = "Bingöl";
$areanames{tr}->{90428} = "Tunceli";
$areanames{tr}->{90432} = "Van";
$areanames{tr}->{90434} = "Bitlis";
$areanames{tr}->{90436} = "Muş";
$areanames{tr}->{90438} = "Hakkari";
$areanames{tr}->{90442} = "Erzurum";
$areanames{tr}->{90446} = "Erzincan";
$areanames{tr}->{90452} = "Ordu";
$areanames{tr}->{90454} = "Giresun";
$areanames{tr}->{90456} = "Gümüşhane";
$areanames{tr}->{90458} = "Bayburt";
$areanames{tr}->{90462} = "Trabzon";
$areanames{tr}->{90464} = "Rize";
$areanames{tr}->{90466} = "Artvin";
$areanames{tr}->{90472} = "Ağrı";
$areanames{tr}->{90474} = "Kars";
$areanames{tr}->{90476} = "Iğdır";
$areanames{tr}->{90478} = "Ardahan";
$areanames{tr}->{90482} = "Mardin";
$areanames{tr}->{90484} = "Siirt";
$areanames{tr}->{90486} = "Şırnak";
$areanames{tr}->{90488} = "Batman";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+90|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;