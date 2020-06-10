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
package Number::Phone::StubCountry::PK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200606132001;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[89]0',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{2})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            9(?:
              2[3-8]|
              98
            )|
            (?:
              2(?:
                3[2358]|
                4[2-4]|
                9[2-8]
              )|
              45[3479]|
              54[2-467]|
              60[468]|
              72[236]|
              8(?:
                2[2-689]|
                3[23578]|
                4[3478]|
                5[2356]
              )|
              9(?:
                22|
                3[27-9]|
                4[2-6]|
                6[3569]|
                9[25-7]
              )
            )[2-9]
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{3})(\\d{6,7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            (?:
              2[125]|
              4[0-246-9]|
              5[1-35-7]|
              6[1-8]|
              7[14]|
              8[16]|
              91
            )[2-9]
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{7,8})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '58',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{5})(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '3',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{7})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            2[125]|
            4[0-246-9]|
            5[1-35-7]|
            6[1-8]|
            7[14]|
            8[16]|
            91
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[24-9]',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            (?:
              21|
              42
            )[2-9]|
            58[126]
          )\\d{7}|
          (?:
            2[25]|
            4[0146-9]|
            5[1-35-7]|
            6[1-8]|
            7[14]|
            8[16]|
            91
          )[2-9]\\d{6,7}|
          (?:
            2(?:
              3[2358]|
              4[2-4]|
              9[2-8]
            )|
            45[3479]|
            54[2-467]|
            60[468]|
            72[236]|
            8(?:
              2[2-689]|
              3[23578]|
              4[3478]|
              5[2356]
            )|
            9(?:
              2[2-8]|
              3[27-9]|
              4[2-6]|
              6[3569]|
              9[25-8]
            )
          )[2-9]\\d{5,6}
        ',
                'geographic' => '
          (?:
            (?:
              21|
              42
            )[2-9]|
            58[126]
          )\\d{7}|
          (?:
            2[25]|
            4[0146-9]|
            5[1-35-7]|
            6[1-8]|
            7[14]|
            8[16]|
            91
          )[2-9]\\d{6,7}|
          (?:
            2(?:
              3[2358]|
              4[2-4]|
              9[2-8]
            )|
            45[3479]|
            54[2-467]|
            60[468]|
            72[236]|
            8(?:
              2[2-689]|
              3[23578]|
              4[3478]|
              5[2356]
            )|
            9(?:
              2[2-8]|
              3[27-9]|
              4[2-6]|
              6[3569]|
              9[25-8]
            )
          )[2-9]\\d{5,6}
        ',
                'mobile' => '
          3(?:
            [014]\\d|
            2[0-5]|
            3[0-7]|
            55|
            64
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '122\\d{6}',
                'specialrate' => '(900\\d{5})|(
          (?:
            2(?:
              [125]|
              3[2358]|
              4[2-4]|
              9[2-8]
            )|
            4(?:
              [0-246-9]|
              5[3479]
            )|
            5(?:
              [1-35-7]|
              4[2-467]
            )|
            6(?:
              0[468]|
              [1-8]
            )|
            7(?:
              [14]|
              2[236]
            )|
            8(?:
              [16]|
              2[2-689]|
              3[23578]|
              4[3478]|
              5[2356]
            )|
            9(?:
              1|
              22|
              3[27-9]|
              4[2-6]|
              6[3569]|
              9[2-7]
            )
          )111\\d{6}
        )',
                'toll_free' => '800\\d{5}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{92212} = "Karachi";
$areanames{en}->{92213} = "Karachi";
$areanames{en}->{92214} = "Karachi";
$areanames{en}->{92215} = "Karachi";
$areanames{en}->{92216} = "Karachi";
$areanames{en}->{92217} = "Karachi";
$areanames{en}->{92218} = "Karachi";
$areanames{en}->{92219} = "Karachi";
$areanames{en}->{92222} = "Hyderabad";
$areanames{en}->{92223} = "Hyderabad";
$areanames{en}->{92224} = "Hyderabad";
$areanames{en}->{92225} = "Hyderabad";
$areanames{en}->{92226} = "Hyderabad";
$areanames{en}->{92227} = "Hyderabad";
$areanames{en}->{92228} = "Hyderabad";
$areanames{en}->{92229} = "Hyderabad";
$areanames{en}->{922322} = "Tharparkar";
$areanames{en}->{922323} = "Tharparkar";
$areanames{en}->{922324} = "Tharparkar";
$areanames{en}->{922325} = "Tharparkar";
$areanames{en}->{922326} = "Tharparkar";
$areanames{en}->{922327} = "Tharparkar";
$areanames{en}->{922328} = "Tharparkar";
$areanames{en}->{922329} = "Tharparkar";
$areanames{en}->{922332} = "Mirpur\ Khas";
$areanames{en}->{922333} = "Mirpur\ Khas";
$areanames{en}->{922334} = "Mirpur\ Khas";
$areanames{en}->{922335} = "Mirpur\ Khas";
$areanames{en}->{922336} = "Mirpur\ Khas";
$areanames{en}->{922337} = "Mirpur\ Khas";
$areanames{en}->{922338} = "Mirpur\ Khas";
$areanames{en}->{922339} = "Mirpur\ Khas";
$areanames{en}->{922352} = "Sanghar";
$areanames{en}->{922353} = "Sanghar";
$areanames{en}->{922354} = "Sanghar";
$areanames{en}->{922355} = "Sanghar";
$areanames{en}->{922356} = "Sanghar";
$areanames{en}->{922357} = "Sanghar";
$areanames{en}->{922358} = "Sanghar";
$areanames{en}->{922359} = "Sanghar";
$areanames{en}->{922382} = "Umerkot";
$areanames{en}->{922383} = "Umerkot";
$areanames{en}->{922384} = "Umerkot";
$areanames{en}->{922385} = "Umerkot";
$areanames{en}->{922386} = "Umerkot";
$areanames{en}->{922387} = "Umerkot";
$areanames{en}->{922388} = "Umerkot";
$areanames{en}->{922389} = "Umerkot";
$areanames{en}->{922422} = "Naushero\ Feroze";
$areanames{en}->{922423} = "Naushero\ Feroze";
$areanames{en}->{922424} = "Naushero\ Feroze";
$areanames{en}->{922425} = "Naushero\ Feroze";
$areanames{en}->{922426} = "Naushero\ Feroze";
$areanames{en}->{922427} = "Naushero\ Feroze";
$areanames{en}->{922428} = "Naushero\ Feroze";
$areanames{en}->{922429} = "Naushero\ Feroze";
$areanames{en}->{922432} = "Khairpur";
$areanames{en}->{922433} = "Khairpur";
$areanames{en}->{922434} = "Khairpur";
$areanames{en}->{922435} = "Khairpur";
$areanames{en}->{922436} = "Khairpur";
$areanames{en}->{922437} = "Khairpur";
$areanames{en}->{922438} = "Khairpur";
$areanames{en}->{922439} = "Khairpur";
$areanames{en}->{922442} = "Nawabshah";
$areanames{en}->{922443} = "Nawabshah";
$areanames{en}->{922444} = "Nawabshah";
$areanames{en}->{922445} = "Nawabshah";
$areanames{en}->{922446} = "Nawabshah";
$areanames{en}->{922447} = "Nawabshah";
$areanames{en}->{922448} = "Nawabshah";
$areanames{en}->{922449} = "Nawabshah";
$areanames{en}->{92252} = "Dadu";
$areanames{en}->{92253} = "Dadu";
$areanames{en}->{92254} = "Dadu";
$areanames{en}->{92255} = "Dadu";
$areanames{en}->{92256} = "Dadu";
$areanames{en}->{92257} = "Dadu";
$areanames{en}->{92258} = "Dadu";
$areanames{en}->{92259} = "Dadu";
$areanames{en}->{922972} = "Badin";
$areanames{en}->{922973} = "Badin";
$areanames{en}->{922974} = "Badin";
$areanames{en}->{922975} = "Badin";
$areanames{en}->{922976} = "Badin";
$areanames{en}->{922977} = "Badin";
$areanames{en}->{922978} = "Badin";
$areanames{en}->{922979} = "Badin";
$areanames{en}->{922982} = "Thatta";
$areanames{en}->{922983} = "Thatta";
$areanames{en}->{922984} = "Thatta";
$areanames{en}->{922985} = "Thatta";
$areanames{en}->{922986} = "Thatta";
$areanames{en}->{922987} = "Thatta";
$areanames{en}->{922988} = "Thatta";
$areanames{en}->{922989} = "Thatta";
$areanames{en}->{92402} = "Sahiwal";
$areanames{en}->{92403} = "Sahiwal";
$areanames{en}->{92404} = "Sahiwal";
$areanames{en}->{92405} = "Sahiwal";
$areanames{en}->{92406} = "Sahiwal";
$areanames{en}->{92407} = "Sahiwal";
$areanames{en}->{92408} = "Sahiwal";
$areanames{en}->{92409} = "Sahiwal";
$areanames{en}->{92412} = "Faisalabad";
$areanames{en}->{92413} = "Faisalabad";
$areanames{en}->{92414} = "Faisalabad";
$areanames{en}->{92415} = "Faisalabad";
$areanames{en}->{92416} = "Faisalabad";
$areanames{en}->{92417} = "Faisalabad";
$areanames{en}->{92418} = "Faisalabad";
$areanames{en}->{92419} = "Faisalabad";
$areanames{en}->{92422} = "Lahore";
$areanames{en}->{92423} = "Lahore";
$areanames{en}->{92424} = "Lahore";
$areanames{en}->{92425} = "Lahore";
$areanames{en}->{92426} = "Lahore";
$areanames{en}->{92427} = "Lahore";
$areanames{en}->{92428} = "Lahore";
$areanames{en}->{92429} = "Lahore";
$areanames{en}->{92442} = "Okara";
$areanames{en}->{92443} = "Okara";
$areanames{en}->{92444} = "Okara";
$areanames{en}->{92445} = "Okara";
$areanames{en}->{92446} = "Okara";
$areanames{en}->{92447} = "Okara";
$areanames{en}->{92448} = "Okara";
$areanames{en}->{92449} = "Okara";
$areanames{en}->{924532} = "Bhakkar";
$areanames{en}->{924533} = "Bhakkar";
$areanames{en}->{924534} = "Bhakkar";
$areanames{en}->{924535} = "Bhakkar";
$areanames{en}->{924536} = "Bhakkar";
$areanames{en}->{924537} = "Bhakkar";
$areanames{en}->{924538} = "Bhakkar";
$areanames{en}->{924539} = "Bhakkar";
$areanames{en}->{924542} = "Khushab";
$areanames{en}->{924543} = "Khushab";
$areanames{en}->{924544} = "Khushab";
$areanames{en}->{924545} = "Khushab";
$areanames{en}->{924546} = "Khushab";
$areanames{en}->{924547} = "Khushab";
$areanames{en}->{924548} = "Khushab";
$areanames{en}->{924549} = "Khushab";
$areanames{en}->{924572} = "Pakpattan";
$areanames{en}->{924573} = "Pakpattan";
$areanames{en}->{924574} = "Pakpattan";
$areanames{en}->{924575} = "Pakpattan";
$areanames{en}->{924576} = "Pakpattan";
$areanames{en}->{924577} = "Pakpattan";
$areanames{en}->{924578} = "Pakpattan";
$areanames{en}->{924579} = "Pakpattan";
$areanames{en}->{924592} = "Mianwali";
$areanames{en}->{924593} = "Mianwali";
$areanames{en}->{924594} = "Mianwali";
$areanames{en}->{924595} = "Mianwali";
$areanames{en}->{924596} = "Mianwali";
$areanames{en}->{924597} = "Mianwali";
$areanames{en}->{924598} = "Mianwali";
$areanames{en}->{924599} = "Mianwali";
$areanames{en}->{92462} = "Toba\ Tek\ Singh";
$areanames{en}->{92463} = "Toba\ Tek\ Singh";
$areanames{en}->{92464} = "Toba\ Tek\ Singh";
$areanames{en}->{92465} = "Toba\ Tek\ Singh";
$areanames{en}->{92466} = "Toba\ Tek\ Singh";
$areanames{en}->{92467} = "Toba\ Tek\ Singh";
$areanames{en}->{92468} = "Toba\ Tek\ Singh";
$areanames{en}->{92469} = "Toba\ Tek\ Singh";
$areanames{en}->{92472} = "Jhang";
$areanames{en}->{92473} = "Jhang";
$areanames{en}->{92474} = "Jhang";
$areanames{en}->{92475} = "Jhang";
$areanames{en}->{92476} = "Jhang";
$areanames{en}->{92477} = "Jhang";
$areanames{en}->{92478} = "Jhang";
$areanames{en}->{92479} = "Jhang";
$areanames{en}->{92482} = "Sargodha";
$areanames{en}->{92483} = "Sargodha";
$areanames{en}->{92484} = "Sargodha";
$areanames{en}->{92485} = "Sargodha";
$areanames{en}->{92486} = "Sargodha";
$areanames{en}->{92487} = "Sargodha";
$areanames{en}->{92488} = "Sargodha";
$areanames{en}->{92489} = "Sargodha";
$areanames{en}->{92492} = "Kasur";
$areanames{en}->{92493} = "Kasur";
$areanames{en}->{92494} = "Kasur";
$areanames{en}->{92495} = "Kasur";
$areanames{en}->{92496} = "Kasur";
$areanames{en}->{92497} = "Kasur";
$areanames{en}->{92498} = "Kasur";
$areanames{en}->{92499} = "Kasur";
$areanames{en}->{92512} = "Islamabad\/Rawalpindi";
$areanames{en}->{92513} = "Islamabad\/Rawalpindi";
$areanames{en}->{92514} = "Islamabad\/Rawalpindi";
$areanames{en}->{92515} = "Islamabad\/Rawalpindi";
$areanames{en}->{92516} = "Islamabad\/Rawalpindi";
$areanames{en}->{92517} = "Islamabad\/Rawalpindi";
$areanames{en}->{92518} = "Islamabad\/Rawalpindi";
$areanames{en}->{92519} = "Islamabad\/Rawalpindi";
$areanames{en}->{92522} = "Sialkot";
$areanames{en}->{92523} = "Sialkot";
$areanames{en}->{92524} = "Sialkot";
$areanames{en}->{92525} = "Sialkot";
$areanames{en}->{92526} = "Sialkot";
$areanames{en}->{92527} = "Sialkot";
$areanames{en}->{92528} = "Sialkot";
$areanames{en}->{92529} = "Sialkot";
$areanames{en}->{92532} = "Gujrat";
$areanames{en}->{92533} = "Gujrat";
$areanames{en}->{92534} = "Gujrat";
$areanames{en}->{92535} = "Gujrat";
$areanames{en}->{92536} = "Gujrat";
$areanames{en}->{92537} = "Gujrat";
$areanames{en}->{92538} = "Gujrat";
$areanames{en}->{92539} = "Gujrat";
$areanames{en}->{925422} = "Narowal";
$areanames{en}->{925423} = "Narowal";
$areanames{en}->{925424} = "Narowal";
$areanames{en}->{925425} = "Narowal";
$areanames{en}->{925426} = "Narowal";
$areanames{en}->{925427} = "Narowal";
$areanames{en}->{925428} = "Narowal";
$areanames{en}->{925429} = "Narowal";
$areanames{en}->{925432} = "Chakwal";
$areanames{en}->{925433} = "Chakwal";
$areanames{en}->{925434} = "Chakwal";
$areanames{en}->{925435} = "Chakwal";
$areanames{en}->{925436} = "Chakwal";
$areanames{en}->{925437} = "Chakwal";
$areanames{en}->{925438} = "Chakwal";
$areanames{en}->{925439} = "Chakwal";
$areanames{en}->{925442} = "Jhelum";
$areanames{en}->{925443} = "Jhelum";
$areanames{en}->{925444} = "Jhelum";
$areanames{en}->{925445} = "Jhelum";
$areanames{en}->{925446} = "Jhelum";
$areanames{en}->{925447} = "Jhelum";
$areanames{en}->{925448} = "Jhelum";
$areanames{en}->{925449} = "Jhelum";
$areanames{en}->{925462} = "Mandi\ Bahauddin";
$areanames{en}->{925463} = "Mandi\ Bahauddin";
$areanames{en}->{925464} = "Mandi\ Bahauddin";
$areanames{en}->{925465} = "Mandi\ Bahauddin";
$areanames{en}->{925466} = "Mandi\ Bahauddin";
$areanames{en}->{925467} = "Mandi\ Bahauddin";
$areanames{en}->{925468} = "Mandi\ Bahauddin";
$areanames{en}->{925469} = "Mandi\ Bahauddin";
$areanames{en}->{925472} = "Hafizabad";
$areanames{en}->{925473} = "Hafizabad";
$areanames{en}->{925474} = "Hafizabad";
$areanames{en}->{925475} = "Hafizabad";
$areanames{en}->{925476} = "Hafizabad";
$areanames{en}->{925477} = "Hafizabad";
$areanames{en}->{925478} = "Hafizabad";
$areanames{en}->{925479} = "Hafizabad";
$areanames{en}->{92552} = "Gujranwala";
$areanames{en}->{92553} = "Gujranwala";
$areanames{en}->{92554} = "Gujranwala";
$areanames{en}->{92555} = "Gujranwala";
$areanames{en}->{92556} = "Gujranwala";
$areanames{en}->{92557} = "Gujranwala";
$areanames{en}->{92558} = "Gujranwala";
$areanames{en}->{92559} = "Gujranwala";
$areanames{en}->{92562} = "Sheikhupura";
$areanames{en}->{92563} = "Sheikhupura";
$areanames{en}->{92564} = "Sheikhupura";
$areanames{en}->{92565} = "Sheikhupura";
$areanames{en}->{92566} = "Sheikhupura";
$areanames{en}->{92567} = "Sheikhupura";
$areanames{en}->{92568} = "Sheikhupura";
$areanames{en}->{92569} = "Sheikhupura";
$areanames{en}->{92572} = "Attock";
$areanames{en}->{92573} = "Attock";
$areanames{en}->{92574} = "Attock";
$areanames{en}->{92575} = "Attock";
$areanames{en}->{92576} = "Attock";
$areanames{en}->{92577} = "Attock";
$areanames{en}->{92578} = "Attock";
$areanames{en}->{92579} = "Attock";
$areanames{en}->{9258} = "AJK\/FATA";
$areanames{en}->{926042} = "Rajanpur";
$areanames{en}->{926043} = "Rajanpur";
$areanames{en}->{926044} = "Rajanpur";
$areanames{en}->{926045} = "Rajanpur";
$areanames{en}->{926046} = "Rajanpur";
$areanames{en}->{926047} = "Rajanpur";
$areanames{en}->{926048} = "Rajanpur";
$areanames{en}->{926049} = "Rajanpur";
$areanames{en}->{926062} = "Layyah";
$areanames{en}->{926063} = "Layyah";
$areanames{en}->{926064} = "Layyah";
$areanames{en}->{926065} = "Layyah";
$areanames{en}->{926066} = "Layyah";
$areanames{en}->{926067} = "Layyah";
$areanames{en}->{926068} = "Layyah";
$areanames{en}->{926069} = "Layyah";
$areanames{en}->{926082} = "Lodhran";
$areanames{en}->{926083} = "Lodhran";
$areanames{en}->{926084} = "Lodhran";
$areanames{en}->{926085} = "Lodhran";
$areanames{en}->{926086} = "Lodhran";
$areanames{en}->{926087} = "Lodhran";
$areanames{en}->{926088} = "Lodhran";
$areanames{en}->{926089} = "Lodhran";
$areanames{en}->{92612} = "Multan";
$areanames{en}->{92613} = "Multan";
$areanames{en}->{92614} = "Multan";
$areanames{en}->{92615} = "Multan";
$areanames{en}->{92616} = "Multan";
$areanames{en}->{92617} = "Multan";
$areanames{en}->{92618} = "Multan";
$areanames{en}->{92619} = "Multan";
$areanames{en}->{92622} = "Bahawalpur";
$areanames{en}->{92623} = "Bahawalpur";
$areanames{en}->{92624} = "Bahawalpur";
$areanames{en}->{92625} = "Bahawalpur";
$areanames{en}->{92626} = "Bahawalpur";
$areanames{en}->{92627} = "Bahawalpur";
$areanames{en}->{92628} = "Bahawalpur";
$areanames{en}->{92629} = "Bahawalpur";
$areanames{en}->{92632} = "Bahawalnagar";
$areanames{en}->{92633} = "Bahawalnagar";
$areanames{en}->{92634} = "Bahawalnagar";
$areanames{en}->{92635} = "Bahawalnagar";
$areanames{en}->{92636} = "Bahawalnagar";
$areanames{en}->{92637} = "Bahawalnagar";
$areanames{en}->{92638} = "Bahawalnagar";
$areanames{en}->{92639} = "Bahawalnagar";
$areanames{en}->{92642} = "Dera\ Ghazi\ Khan";
$areanames{en}->{92643} = "Dera\ Ghazi\ Khan";
$areanames{en}->{92644} = "Dera\ Ghazi\ Khan";
$areanames{en}->{92645} = "Dera\ Ghazi\ Khan";
$areanames{en}->{92646} = "Dera\ Ghazi\ Khan";
$areanames{en}->{92647} = "Dera\ Ghazi\ Khan";
$areanames{en}->{92648} = "Dera\ Ghazi\ Khan";
$areanames{en}->{92649} = "Dera\ Ghazi\ Khan";
$areanames{en}->{92652} = "Khanewal";
$areanames{en}->{92653} = "Khanewal";
$areanames{en}->{92654} = "Khanewal";
$areanames{en}->{92655} = "Khanewal";
$areanames{en}->{92656} = "Khanewal";
$areanames{en}->{92657} = "Khanewal";
$areanames{en}->{92658} = "Khanewal";
$areanames{en}->{92659} = "Khanewal";
$areanames{en}->{92662} = "Muzaffargarh";
$areanames{en}->{92663} = "Muzaffargarh";
$areanames{en}->{92664} = "Muzaffargarh";
$areanames{en}->{92665} = "Muzaffargarh";
$areanames{en}->{92666} = "Muzaffargarh";
$areanames{en}->{92667} = "Muzaffargarh";
$areanames{en}->{92668} = "Muzaffargarh";
$areanames{en}->{92669} = "Muzaffargarh";
$areanames{en}->{92672} = "Vehari";
$areanames{en}->{92673} = "Vehari";
$areanames{en}->{92674} = "Vehari";
$areanames{en}->{92675} = "Vehari";
$areanames{en}->{92676} = "Vehari";
$areanames{en}->{92677} = "Vehari";
$areanames{en}->{92678} = "Vehari";
$areanames{en}->{92679} = "Vehari";
$areanames{en}->{92682} = "Rahim\ Yar\ Khan";
$areanames{en}->{92683} = "Rahim\ Yar\ Khan";
$areanames{en}->{92684} = "Rahim\ Yar\ Khan";
$areanames{en}->{92685} = "Rahim\ Yar\ Khan";
$areanames{en}->{92686} = "Rahim\ Yar\ Khan";
$areanames{en}->{92687} = "Rahim\ Yar\ Khan";
$areanames{en}->{92688} = "Rahim\ Yar\ Khan";
$areanames{en}->{92689} = "Rahim\ Yar\ Khan";
$areanames{en}->{92712} = "Sukkur";
$areanames{en}->{92713} = "Sukkur";
$areanames{en}->{92714} = "Sukkur";
$areanames{en}->{92715} = "Sukkur";
$areanames{en}->{92716} = "Sukkur";
$areanames{en}->{92717} = "Sukkur";
$areanames{en}->{92718} = "Sukkur";
$areanames{en}->{92719} = "Sukkur";
$areanames{en}->{927222} = "Jacobabad";
$areanames{en}->{927223} = "Jacobabad";
$areanames{en}->{927224} = "Jacobabad";
$areanames{en}->{927225} = "Jacobabad";
$areanames{en}->{927226} = "Jacobabad";
$areanames{en}->{927227} = "Jacobabad";
$areanames{en}->{927228} = "Jacobabad";
$areanames{en}->{927229} = "Jacobabad";
$areanames{en}->{927232} = "Ghotki";
$areanames{en}->{927233} = "Ghotki";
$areanames{en}->{927234} = "Ghotki";
$areanames{en}->{927235} = "Ghotki";
$areanames{en}->{927236} = "Ghotki";
$areanames{en}->{927237} = "Ghotki";
$areanames{en}->{927238} = "Ghotki";
$areanames{en}->{927239} = "Ghotki";
$areanames{en}->{927262} = "Shikarpur";
$areanames{en}->{927263} = "Shikarpur";
$areanames{en}->{927264} = "Shikarpur";
$areanames{en}->{927265} = "Shikarpur";
$areanames{en}->{927266} = "Shikarpur";
$areanames{en}->{927267} = "Shikarpur";
$areanames{en}->{927268} = "Shikarpur";
$areanames{en}->{927269} = "Shikarpur";
$areanames{en}->{92742} = "Larkana";
$areanames{en}->{92743} = "Larkana";
$areanames{en}->{92744} = "Larkana";
$areanames{en}->{92745} = "Larkana";
$areanames{en}->{92746} = "Larkana";
$areanames{en}->{92747} = "Larkana";
$areanames{en}->{92748} = "Larkana";
$areanames{en}->{92749} = "Larkana";
$areanames{en}->{92812} = "Quetta";
$areanames{en}->{92813} = "Quetta";
$areanames{en}->{92814} = "Quetta";
$areanames{en}->{92815} = "Quetta";
$areanames{en}->{92816} = "Quetta";
$areanames{en}->{92817} = "Quetta";
$areanames{en}->{92818} = "Quetta";
$areanames{en}->{92819} = "Quetta";
$areanames{en}->{928222} = "Zhob";
$areanames{en}->{928223} = "Zhob";
$areanames{en}->{928224} = "Zhob";
$areanames{en}->{928225} = "Zhob";
$areanames{en}->{928226} = "Zhob";
$areanames{en}->{928227} = "Zhob";
$areanames{en}->{928228} = "Zhob";
$areanames{en}->{928229} = "Zhob";
$areanames{en}->{928232} = "Killa\ Saifullah";
$areanames{en}->{928233} = "Killa\ Saifullah";
$areanames{en}->{928234} = "Killa\ Saifullah";
$areanames{en}->{928235} = "Killa\ Saifullah";
$areanames{en}->{928236} = "Killa\ Saifullah";
$areanames{en}->{928237} = "Killa\ Saifullah";
$areanames{en}->{928238} = "Killa\ Saifullah";
$areanames{en}->{928239} = "Killa\ Saifullah";
$areanames{en}->{928242} = "Loralai";
$areanames{en}->{928243} = "Loralai";
$areanames{en}->{928244} = "Loralai";
$areanames{en}->{928245} = "Loralai";
$areanames{en}->{928246} = "Loralai";
$areanames{en}->{928247} = "Loralai";
$areanames{en}->{928248} = "Loralai";
$areanames{en}->{928249} = "Loralai";
$areanames{en}->{928252} = "Chagai";
$areanames{en}->{928253} = "Chagai";
$areanames{en}->{928254} = "Chagai";
$areanames{en}->{928255} = "Chagai";
$areanames{en}->{928256} = "Chagai";
$areanames{en}->{928257} = "Chagai";
$areanames{en}->{928258} = "Chagai";
$areanames{en}->{928259} = "Chagai";
$areanames{en}->{928262} = "K\.Abdullah\/Pishin";
$areanames{en}->{928263} = "K\.Abdullah\/Pishin";
$areanames{en}->{928264} = "K\.Abdullah\/Pishin";
$areanames{en}->{928265} = "K\.Abdullah\/Pishin";
$areanames{en}->{928266} = "K\.Abdullah\/Pishin";
$areanames{en}->{928267} = "K\.Abdullah\/Pishin";
$areanames{en}->{928268} = "K\.Abdullah\/Pishin";
$areanames{en}->{928269} = "K\.Abdullah\/Pishin";
$areanames{en}->{928282} = "Musakhel";
$areanames{en}->{928283} = "Musakhel";
$areanames{en}->{928284} = "Musakhel";
$areanames{en}->{928285} = "Musakhel";
$areanames{en}->{928286} = "Musakhel";
$areanames{en}->{928287} = "Musakhel";
$areanames{en}->{928288} = "Musakhel";
$areanames{en}->{928289} = "Musakhel";
$areanames{en}->{928292} = "Barkhan\/Kohlu";
$areanames{en}->{928293} = "Barkhan\/Kohlu";
$areanames{en}->{928294} = "Barkhan\/Kohlu";
$areanames{en}->{928295} = "Barkhan\/Kohlu";
$areanames{en}->{928296} = "Barkhan\/Kohlu";
$areanames{en}->{928297} = "Barkhan\/Kohlu";
$areanames{en}->{928298} = "Barkhan\/Kohlu";
$areanames{en}->{928299} = "Barkhan\/Kohlu";
$areanames{en}->{928322} = "Bolan";
$areanames{en}->{928323} = "Bolan";
$areanames{en}->{928324} = "Bolan";
$areanames{en}->{928325} = "Bolan";
$areanames{en}->{928326} = "Bolan";
$areanames{en}->{928327} = "Bolan";
$areanames{en}->{928328} = "Bolan";
$areanames{en}->{928329} = "Bolan";
$areanames{en}->{928332} = "Sibi\/Ziarat";
$areanames{en}->{928333} = "Sibi\/Ziarat";
$areanames{en}->{928334} = "Sibi\/Ziarat";
$areanames{en}->{928335} = "Sibi\/Ziarat";
$areanames{en}->{928336} = "Sibi\/Ziarat";
$areanames{en}->{928337} = "Sibi\/Ziarat";
$areanames{en}->{928338} = "Sibi\/Ziarat";
$areanames{en}->{928339} = "Sibi\/Ziarat";
$areanames{en}->{928352} = "Dera\ Bugti";
$areanames{en}->{928353} = "Dera\ Bugti";
$areanames{en}->{928354} = "Dera\ Bugti";
$areanames{en}->{928355} = "Dera\ Bugti";
$areanames{en}->{928356} = "Dera\ Bugti";
$areanames{en}->{928357} = "Dera\ Bugti";
$areanames{en}->{928358} = "Dera\ Bugti";
$areanames{en}->{928359} = "Dera\ Bugti";
$areanames{en}->{928372} = "Jhal\ Magsi";
$areanames{en}->{928373} = "Jhal\ Magsi";
$areanames{en}->{928374} = "Jhal\ Magsi";
$areanames{en}->{928375} = "Jhal\ Magsi";
$areanames{en}->{928376} = "Jhal\ Magsi";
$areanames{en}->{928377} = "Jhal\ Magsi";
$areanames{en}->{928378} = "Jhal\ Magsi";
$areanames{en}->{928379} = "Jhal\ Magsi";
$areanames{en}->{928382} = "Jaffarabad\/Nasirabad";
$areanames{en}->{928383} = "Jaffarabad\/Nasirabad";
$areanames{en}->{928384} = "Jaffarabad\/Nasirabad";
$areanames{en}->{928385} = "Jaffarabad\/Nasirabad";
$areanames{en}->{928386} = "Jaffarabad\/Nasirabad";
$areanames{en}->{928387} = "Jaffarabad\/Nasirabad";
$areanames{en}->{928388} = "Jaffarabad\/Nasirabad";
$areanames{en}->{928389} = "Jaffarabad\/Nasirabad";
$areanames{en}->{928432} = "Mastung";
$areanames{en}->{928433} = "Mastung";
$areanames{en}->{928434} = "Mastung";
$areanames{en}->{928435} = "Mastung";
$areanames{en}->{928436} = "Mastung";
$areanames{en}->{928437} = "Mastung";
$areanames{en}->{928438} = "Mastung";
$areanames{en}->{928439} = "Mastung";
$areanames{en}->{928442} = "Kalat";
$areanames{en}->{928443} = "Kalat";
$areanames{en}->{928444} = "Kalat";
$areanames{en}->{928445} = "Kalat";
$areanames{en}->{928446} = "Kalat";
$areanames{en}->{928447} = "Kalat";
$areanames{en}->{928448} = "Kalat";
$areanames{en}->{928449} = "Kalat";
$areanames{en}->{928472} = "Kharan";
$areanames{en}->{928473} = "Kharan";
$areanames{en}->{928474} = "Kharan";
$areanames{en}->{928475} = "Kharan";
$areanames{en}->{928476} = "Kharan";
$areanames{en}->{928477} = "Kharan";
$areanames{en}->{928478} = "Kharan";
$areanames{en}->{928479} = "Kharan";
$areanames{en}->{928482} = "Khuzdar";
$areanames{en}->{928483} = "Khuzdar";
$areanames{en}->{928484} = "Khuzdar";
$areanames{en}->{928485} = "Khuzdar";
$areanames{en}->{928486} = "Khuzdar";
$areanames{en}->{928487} = "Khuzdar";
$areanames{en}->{928488} = "Khuzdar";
$areanames{en}->{928489} = "Khuzdar";
$areanames{en}->{928522} = "Kech";
$areanames{en}->{928523} = "Kech";
$areanames{en}->{928524} = "Kech";
$areanames{en}->{928525} = "Kech";
$areanames{en}->{928526} = "Kech";
$areanames{en}->{928527} = "Kech";
$areanames{en}->{928528} = "Kech";
$areanames{en}->{928529} = "Kech";
$areanames{en}->{928532} = "Lasbela";
$areanames{en}->{928533} = "Lasbela";
$areanames{en}->{928534} = "Lasbela";
$areanames{en}->{928535} = "Lasbela";
$areanames{en}->{928536} = "Lasbela";
$areanames{en}->{928537} = "Lasbela";
$areanames{en}->{928538} = "Lasbela";
$areanames{en}->{928539} = "Lasbela";
$areanames{en}->{928552} = "Panjgur";
$areanames{en}->{928553} = "Panjgur";
$areanames{en}->{928554} = "Panjgur";
$areanames{en}->{928555} = "Panjgur";
$areanames{en}->{928556} = "Panjgur";
$areanames{en}->{928557} = "Panjgur";
$areanames{en}->{928558} = "Panjgur";
$areanames{en}->{928559} = "Panjgur";
$areanames{en}->{928562} = "Awaran";
$areanames{en}->{928563} = "Awaran";
$areanames{en}->{928564} = "Awaran";
$areanames{en}->{928565} = "Awaran";
$areanames{en}->{928566} = "Awaran";
$areanames{en}->{928567} = "Awaran";
$areanames{en}->{928568} = "Awaran";
$areanames{en}->{928569} = "Awaran";
$areanames{en}->{92862} = "Gwadar";
$areanames{en}->{92863} = "Gwadar";
$areanames{en}->{92864} = "Gwadar";
$areanames{en}->{92865} = "Gwadar";
$areanames{en}->{92866} = "Gwadar";
$areanames{en}->{92867} = "Gwadar";
$areanames{en}->{92868} = "Gwadar";
$areanames{en}->{92869} = "Gwadar";
$areanames{en}->{92912} = "Peshawar\/Charsadda";
$areanames{en}->{92913} = "Peshawar\/Charsadda";
$areanames{en}->{92914} = "Peshawar\/Charsadda";
$areanames{en}->{92915} = "Peshawar\/Charsadda";
$areanames{en}->{92916} = "Peshawar\/Charsadda";
$areanames{en}->{92917} = "Peshawar\/Charsadda";
$areanames{en}->{92918} = "Peshawar\/Charsadda";
$areanames{en}->{92919} = "Peshawar\/Charsadda";
$areanames{en}->{929222} = "Kohat";
$areanames{en}->{929223} = "Kohat";
$areanames{en}->{929224} = "Kohat";
$areanames{en}->{929225} = "Kohat";
$areanames{en}->{929226} = "Kohat";
$areanames{en}->{929227} = "Kohat";
$areanames{en}->{929228} = "Kohat";
$areanames{en}->{929229} = "Kohat";
$areanames{en}->{92923} = "Nowshera";
$areanames{en}->{92924} = "Khyber\/Mohmand\ Agy";
$areanames{en}->{92925} = "Hangu\/Orakzai\ Agy";
$areanames{en}->{92926} = "Kurram\ Agency";
$areanames{en}->{92927} = "Karak";
$areanames{en}->{92928} = "Bannu\/N\.\ Waziristan";
$areanames{en}->{929322} = "Malakand";
$areanames{en}->{929323} = "Malakand";
$areanames{en}->{929324} = "Malakand";
$areanames{en}->{929325} = "Malakand";
$areanames{en}->{929326} = "Malakand";
$areanames{en}->{929327} = "Malakand";
$areanames{en}->{929328} = "Malakand";
$areanames{en}->{929329} = "Malakand";
$areanames{en}->{929372} = "Mardan";
$areanames{en}->{929373} = "Mardan";
$areanames{en}->{929374} = "Mardan";
$areanames{en}->{929375} = "Mardan";
$areanames{en}->{929376} = "Mardan";
$areanames{en}->{929377} = "Mardan";
$areanames{en}->{929378} = "Mardan";
$areanames{en}->{929379} = "Mardan";
$areanames{en}->{929382} = "Swabi";
$areanames{en}->{929383} = "Swabi";
$areanames{en}->{929384} = "Swabi";
$areanames{en}->{929385} = "Swabi";
$areanames{en}->{929386} = "Swabi";
$areanames{en}->{929387} = "Swabi";
$areanames{en}->{929388} = "Swabi";
$areanames{en}->{929389} = "Swabi";
$areanames{en}->{929392} = "Buner";
$areanames{en}->{929393} = "Buner";
$areanames{en}->{929394} = "Buner";
$areanames{en}->{929395} = "Buner";
$areanames{en}->{929396} = "Buner";
$areanames{en}->{929397} = "Buner";
$areanames{en}->{929398} = "Buner";
$areanames{en}->{929399} = "Buner";
$areanames{en}->{929422} = "Bajaur\ Agency";
$areanames{en}->{929423} = "Bajaur\ Agency";
$areanames{en}->{929424} = "Bajaur\ Agency";
$areanames{en}->{929425} = "Bajaur\ Agency";
$areanames{en}->{929426} = "Bajaur\ Agency";
$areanames{en}->{929427} = "Bajaur\ Agency";
$areanames{en}->{929428} = "Bajaur\ Agency";
$areanames{en}->{929429} = "Bajaur\ Agency";
$areanames{en}->{929432} = "Chitral";
$areanames{en}->{929433} = "Chitral";
$areanames{en}->{929434} = "Chitral";
$areanames{en}->{929435} = "Chitral";
$areanames{en}->{929436} = "Chitral";
$areanames{en}->{929437} = "Chitral";
$areanames{en}->{929438} = "Chitral";
$areanames{en}->{929439} = "Chitral";
$areanames{en}->{929442} = "Upper\ Dir";
$areanames{en}->{929443} = "Upper\ Dir";
$areanames{en}->{929444} = "Upper\ Dir";
$areanames{en}->{929445} = "Upper\ Dir";
$areanames{en}->{929446} = "Upper\ Dir";
$areanames{en}->{929447} = "Upper\ Dir";
$areanames{en}->{929448} = "Upper\ Dir";
$areanames{en}->{929449} = "Upper\ Dir";
$areanames{en}->{929452} = "Lower\ Dir";
$areanames{en}->{929453} = "Lower\ Dir";
$areanames{en}->{929454} = "Lower\ Dir";
$areanames{en}->{929455} = "Lower\ Dir";
$areanames{en}->{929456} = "Lower\ Dir";
$areanames{en}->{929457} = "Lower\ Dir";
$areanames{en}->{929458} = "Lower\ Dir";
$areanames{en}->{929459} = "Lower\ Dir";
$areanames{en}->{929462} = "Swat";
$areanames{en}->{929463} = "Swat";
$areanames{en}->{929464} = "Swat";
$areanames{en}->{929465} = "Swat";
$areanames{en}->{929466} = "Swat";
$areanames{en}->{929467} = "Swat";
$areanames{en}->{929468} = "Swat";
$areanames{en}->{929469} = "Swat";
$areanames{en}->{929632} = "Tank";
$areanames{en}->{929633} = "Tank";
$areanames{en}->{929634} = "Tank";
$areanames{en}->{929635} = "Tank";
$areanames{en}->{929636} = "Tank";
$areanames{en}->{929637} = "Tank";
$areanames{en}->{929638} = "Tank";
$areanames{en}->{929639} = "Tank";
$areanames{en}->{929652} = "South\ Waziristan";
$areanames{en}->{929653} = "South\ Waziristan";
$areanames{en}->{929654} = "South\ Waziristan";
$areanames{en}->{929655} = "South\ Waziristan";
$areanames{en}->{929656} = "South\ Waziristan";
$areanames{en}->{929657} = "South\ Waziristan";
$areanames{en}->{929658} = "South\ Waziristan";
$areanames{en}->{929659} = "South\ Waziristan";
$areanames{en}->{929662} = "D\.I\.\ Khan";
$areanames{en}->{929663} = "D\.I\.\ Khan";
$areanames{en}->{929664} = "D\.I\.\ Khan";
$areanames{en}->{929665} = "D\.I\.\ Khan";
$areanames{en}->{929666} = "D\.I\.\ Khan";
$areanames{en}->{929667} = "D\.I\.\ Khan";
$areanames{en}->{929668} = "D\.I\.\ Khan";
$areanames{en}->{929669} = "D\.I\.\ Khan";
$areanames{en}->{929692} = "Lakki\ Marwat";
$areanames{en}->{929693} = "Lakki\ Marwat";
$areanames{en}->{929694} = "Lakki\ Marwat";
$areanames{en}->{929695} = "Lakki\ Marwat";
$areanames{en}->{929696} = "Lakki\ Marwat";
$areanames{en}->{929697} = "Lakki\ Marwat";
$areanames{en}->{929698} = "Lakki\ Marwat";
$areanames{en}->{929699} = "Lakki\ Marwat";
$areanames{en}->{929922} = "Abottabad";
$areanames{en}->{929923} = "Abottabad";
$areanames{en}->{929924} = "Abottabad";
$areanames{en}->{929925} = "Abottabad";
$areanames{en}->{929926} = "Abottabad";
$areanames{en}->{929927} = "Abottabad";
$areanames{en}->{929928} = "Abottabad";
$areanames{en}->{929929} = "Abottabad";
$areanames{en}->{929952} = "Haripur";
$areanames{en}->{929953} = "Haripur";
$areanames{en}->{929954} = "Haripur";
$areanames{en}->{929955} = "Haripur";
$areanames{en}->{929956} = "Haripur";
$areanames{en}->{929957} = "Haripur";
$areanames{en}->{929958} = "Haripur";
$areanames{en}->{929959} = "Haripur";
$areanames{en}->{929962} = "Shangla";
$areanames{en}->{929963} = "Shangla";
$areanames{en}->{929964} = "Shangla";
$areanames{en}->{929965} = "Shangla";
$areanames{en}->{929966} = "Shangla";
$areanames{en}->{929967} = "Shangla";
$areanames{en}->{929968} = "Shangla";
$areanames{en}->{929969} = "Shangla";
$areanames{en}->{929972} = "Mansehra\/Batagram";
$areanames{en}->{929973} = "Mansehra\/Batagram";
$areanames{en}->{929974} = "Mansehra\/Batagram";
$areanames{en}->{929975} = "Mansehra\/Batagram";
$areanames{en}->{929976} = "Mansehra\/Batagram";
$areanames{en}->{929977} = "Mansehra\/Batagram";
$areanames{en}->{929978} = "Mansehra\/Batagram";
$areanames{en}->{929979} = "Mansehra\/Batagram";
$areanames{en}->{92998} = "Kohistan";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+92|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;