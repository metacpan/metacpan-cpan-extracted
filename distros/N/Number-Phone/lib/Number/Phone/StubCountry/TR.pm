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
our $VERSION = 1.20220307120124;

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
            8[01589]|
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
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '80',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{6,7})'
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
        )|(444\\d{4})',
                'toll_free' => '
          8(?:
            00\\d{7}(?:
              \\d{2,3}
            )?|
            11\\d{7}
          )
        ',
                'voip' => '850\\d{7}'
              };
my %areanames = ();
$areanames{tr} = {"90472", "Ağrı",
"90286", "Çanakkale",
"90274", "Kütahya",
"90424", "Elazığ",
"90288", "Kırklareli",
"90264", "Sakarya\ \(Adapazarı\)",
"90456", "Gümüşhane",
"90222", "Eskisehir",
"90386", "Kırşehir",
"90484", "Siirt",
"90318", "Kırıkkale",
"90380", "Düzce",
"90476", "Iğdır",
"90282", "Tekirdağ",
"90212", "Istanbul\ \(Avrupa\)",
"90232", "İzmir",
"90388", "Niğde",
"90364", "Çorum",
"90414", "Şanlıurfa",
"90384", "Nevşehir",
"90370", "Karabük",
"90486", "Şırnak",
"90376", "Çankırı",
"90344", "Kahramanmaraş",
"90262", "Kocaeli\ \(İzmit\)",
"90416", "Adıyaman",
"90256", "Aydın",
"90378", "Bartın",
"90436", "Muş",
"90428", "Tunceli",
"90372", "Zonguldak",
"90276", "Uşak",
"90324", "Mersin",
"90412", "Diyarbakır",
"90252", "Muğla",
"90426", "Bingöl",
"90266", "Balıkesir",
"9039", "Kuzey\ Kıbrıs",};
$areanames{en} = {"90432", "Van",
"90324", "Icel",
"90252", "Mugla",
"90362", "Samsun",
"90426", "Bingol",
"90412", "Diyarbakir",
"90266", "Balikesir",
"9039", "Northern\ Cyprus",
"90356", "Tokat",
"90454", "Giresun",
"90428", "Tuniceli",
"90442", "Erzurum",
"90284", "Edirne",
"90372", "Zongdulak",
"90482", "Mardin",
"90276", "Usak",
"90358", "Amasya",
"90224", "Bursa",
"90488", "Batman",
"90352", "Kayseri",
"90262", "Kocaeli",
"90422", "Malatya",
"90366", "Kastamonu",
"90256", "Aydin",
"90416", "Adiyaman",
"90436", "Mus",
"90464", "Rize",
"90378", "Bartin",
"90384", "Nevsehir",
"90370", "Karabuk",
"90486", "Sirnak",
"90272", "Afyon",
"90438", "Hakkari",
"90376", "Cankiri",
"90344", "K\.\ Maras",
"90368", "Sinop",
"90258", "Denizli",
"90474", "Kars",
"90446", "Erzincan",
"90212", "Istanbul\ \(Europe\)",
"90226", "Yalova",
"90452", "Ordu",
"90388", "Nigde",
"90232", "Izmir",
"90414", "Sanliurfa",
"90478", "Ardahan",
"90364", "Corum",
"90348", "Kilis",
"90434", "Bitlis",
"90466", "Artvin",
"90322", "Adana",
"90386", "Kirsehir",
"90484", "Stirt",
"90242", "Antalya",
"90228", "Bilecik",
"90318", "Kirikkale",
"90346", "Sivas",
"90374", "Bolu",
"90380", "Duzce",
"90476", "Igdir",
"90282", "Tekirdag",
"90338", "Karaman",
"90312", "Ankara",
"90462", "Trabzon",
"90326", "Hatay",
"90288", "Kirklareli",
"90332", "Konya",
"90424", "Elazig",
"90354", "Yozgat",
"90236", "Manisa",
"90264", "Sakarya",
"90216", "Istanbul\ \(Anatolia\)",
"90248", "Burdur",
"90456", "Gumushane",
"90222", "Esksehir",
"90286", "Canakkale",
"90472", "Agri",
"90342", "Gaziantep",
"90328", "Osmaniye",
"90246", "Isparta",
"90274", "Kutahya",
"90458", "Bayburt",
"90382", "Aksaray",};

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