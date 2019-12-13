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
package Number::Phone::StubCountry::GY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20191211212301;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[2-46-9]',
                  'pattern' => '(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              1[6-9]|
              2[0-35-9]|
              3[1-4]|
              5[3-9]|
              6\\d|
              7[0-24-79]
            )|
            3(?:
              2[25-9]|
              3\\d
            )|
            4(?:
              4[0-24]|
              5[56]
            )|
            77[1-57]
          )\\d{4}
        ',
                'geographic' => '
          (?:
            2(?:
              1[6-9]|
              2[0-35-9]|
              3[1-4]|
              5[3-9]|
              6\\d|
              7[0-24-79]
            )|
            3(?:
              2[25-9]|
              3\\d
            )|
            4(?:
              4[0-24]|
              5[56]
            )|
            77[1-57]
          )\\d{4}
        ',
                'mobile' => '6\\d{6}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(9008\\d{3})',
                'toll_free' => '
          (?:
            289|
            862
          )\\d{4}
        ',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{592216} = "Diamond\/Grove";
$areanames{en}->{592217} = "Mocha";
$areanames{en}->{592218} = "Georgetown\ \(S\/R\/Veldt\)";
$areanames{en}->{592219} = "Georgetown\,Sophia";
$areanames{en}->{592220} = "B\/V\ Central";
$areanames{en}->{592221} = "Mahaicony";
$areanames{en}->{592222} = "B\/V\ West";
$areanames{en}->{592223} = "Georgetown";
$areanames{en}->{592225} = "Georgetown";
$areanames{en}->{592226} = "Georgetown";
$areanames{en}->{592227} = "Georgetown";
$areanames{en}->{592228} = "Mahaica\/Belmont";
$areanames{en}->{592229} = "Enterprise\/Cove\ \&\ John";
$areanames{en}->{592231} = "Georgetown";
$areanames{en}->{592232} = "Novar\/Catherine\/Belladrum\/Bush\ Lot";
$areanames{en}->{592233} = "Agricola\/Houston\/Eccles\/Nandy\ Park";
$areanames{en}->{592234} = "B\/V\ Central";
$areanames{en}->{592253} = "La\ Grange\/Goed\ Fortuin";
$areanames{en}->{592254} = "New\ Road\/Best";
$areanames{en}->{592255} = "Paradise\/Golden\ Grove\/Haslington";
$areanames{en}->{592256} = "Victoria\/Hope\ West";
$areanames{en}->{592257} = "Cane\ Grove\/Strangroen";
$areanames{en}->{592258} = "Planters\ Hall\/Mortice";
$areanames{en}->{592259} = "Clonbrook\/Unity";
$areanames{en}->{592260} = "Tuschen\/Parika";
$areanames{en}->{592261} = "Timehri\/Long\ Creek\/Soesdyke";
$areanames{en}->{592262} = "Parika";
$areanames{en}->{592264} = "Vreed\-en\-Hoop";
$areanames{en}->{592265} = "Diamond";
$areanames{en}->{592266} = "New\ Hope\/Friendship\/Grove\/Land\ of\ Canaan";
$areanames{en}->{592267} = "Wales";
$areanames{en}->{592268} = "Leonora";
$areanames{en}->{592269} = "Windsor\ Forest";
$areanames{en}->{592270} = "Melanie\/Non\ Pariel\/Enmore";
$areanames{en}->{592271} = "Canal\ No\.\ 1\/Canal\ No\.\ 2";
$areanames{en}->{592272} = "B\/V\ West";
$areanames{en}->{592274} = "Vigilance";
$areanames{en}->{592275} = "Met\-en\-Meer\-Zorg";
$areanames{en}->{592276} = "Anna\ Catherina\/\ Cornelia\ Ida\/Hague\/Fellowship";
$areanames{en}->{592277} = "Zeeburg\/Uitvlugt";
$areanames{en}->{592279} = "Good\ Hope\/Stanleytown";
$areanames{en}->{592322} = "Kilcoy\/Hampshire\/Nigg";
$areanames{en}->{592325} = "Mibikuri\/No\:\ 34\/Joppa\/Brighton";
$areanames{en}->{592326} = "Adelphi\/Fryish\/No\.\ 40";
$areanames{en}->{592327} = "Blairmont\/Cumberland";
$areanames{en}->{592328} = "Cottage\/Tempe\/Onverwagt\/Bath\/Waterloo";
$areanames{en}->{592329} = "Willemstad\/Fort\ Wellington\/Ithaca";
$areanames{en}->{592330} = "Rosignol\/Shieldstown";
$areanames{en}->{592331} = "Adventure\/Joanna";
$areanames{en}->{592332} = "Sheet\ Anchor\/Susannah";
$areanames{en}->{592333} = "New\ Amsterdam";
$areanames{en}->{592334} = "New\ Amsterdam";
$areanames{en}->{592335} = "Crabwood\ Creek\/No\:\ 76\/Corentyne";
$areanames{en}->{592336} = "Edinburg\/Port\ Mourant";
$areanames{en}->{592337} = "Whim\/Bloomfield\/Liverpool\/Rose\ Hall";
$areanames{en}->{592338} = "Benab\/No\.\ 65\ Village\/Massiah";
$areanames{en}->{592339} = "No\:\ 52\/Skeldon";
$areanames{en}->{592440} = "Kwakwani";
$areanames{en}->{592441} = "Ituni";
$areanames{en}->{592442} = "Christianburg\/Amelia\’s\ Ward";
$areanames{en}->{592444} = "Linden\/Canvas\ City\/Wisroc";
$areanames{en}->{592455} = "Bartica";
$areanames{en}->{592456} = "Mahdia";
$areanames{en}->{592772} = "Lethem";
$areanames{en}->{592773} = "Aishalton";
$areanames{en}->{592775} = "Matthews\ Ridge";
$areanames{en}->{592777} = "Mabaruma\/Port\ Kaituma";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+592|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;