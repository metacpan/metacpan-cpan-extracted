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
package Number::Phone::StubCountry::CM;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215424;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '88',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4 $5',
                  'leading_digits' => '[26]',
                  'pattern' => '(\\d)(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            22|
            33|
            4[23]
          )\\d{6}
        ',
                'geographic' => '
          2(?:
            22|
            33|
            4[23]
          )\\d{6}
        ',
                'mobile' => '6[5-9]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '88\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{237222111} = "Mbalmayo";
$areanames{en}->{237222120} = "Akonolinga";
$areanames{en}->{237222121} = "Ayos";
$areanames{en}->{237222136} = "Eséka\/Mboumnyebel";
$areanames{en}->{237222144} = "Ngoumou";
$areanames{en}->{237222180} = "Obala";
$areanames{en}->{237222182} = "Monatélé";
$areanames{en}->{237222185} = "Bafia";
$areanames{en}->{237222195} = "Nanga\ Eboko";
$areanames{en}->{23722220} = "Jamot";
$areanames{en}->{23722221} = "Jamot";
$areanames{en}->{23722222} = "Yaounde";
$areanames{en}->{23722223} = "Yaounde";
$areanames{en}->{237222241} = "Bertoua";
$areanames{en}->{237222242} = "Bertoua";
$areanames{en}->{237222250} = "N\'Gaoundéré";
$areanames{en}->{237222251} = "N\'Gaoundéré";
$areanames{en}->{237222252} = "N\'Gaoundéré";
$areanames{en}->{237222253} = "N\'Gaoundéré";
$areanames{en}->{237222254} = "Dang";
$areanames{en}->{237222256} = "Beelel\/Mbé";
$areanames{en}->{237222262} = "Batouri";
$areanames{en}->{237222264} = "Belabo";
$areanames{en}->{23722227} = "Garoua";
$areanames{en}->{237222282} = "Mengong";
$areanames{en}->{237222283} = "Ebolowa";
$areanames{en}->{237222284} = "Ebolowa";
$areanames{en}->{23722229} = "Maroua";
$areanames{en}->{23722230} = "Nkomo";
$areanames{en}->{23722231} = "Biyem\ Assi";
$areanames{en}->{237222321} = "Mfou";
$areanames{en}->{237222322} = "Soa";
$areanames{en}->{237222335} = "Abong\-Bang";
$areanames{en}->{237222347} = "N\'Gaoundal";
$areanames{en}->{237222348} = "Tibati";
$areanames{en}->{237222354} = "Galim\ Tignère";
$areanames{en}->{237222355} = "Tignère";
$areanames{en}->{237222369} = "Banyo";
$areanames{en}->{237222371} = "Meiganga";
$areanames{en}->{237222395} = "Guider";
$areanames{en}->{237222397} = "Figuil";
$areanames{en}->{237222414} = "Kousseri";
$areanames{en}->{237222426} = "Yagoua";
$areanames{en}->{237222447} = "Mora";
$areanames{en}->{237222455} = "Mokolo";
$areanames{en}->{237222461} = "Kribi";
$areanames{en}->{237222462} = "Kribi";
$areanames{en}->{237222463} = "Lolodorf";
$areanames{en}->{237222464} = "Lolodorf";
$areanames{en}->{237222478} = "Sangmelima";
$areanames{en}->{237222479} = "Meyomessala\/Efoulan";
$areanames{en}->{237222482} = "Kye\-Ossie\/Ambam";
$areanames{en}->{237233205} = "Wum";
$areanames{en}->{237233215} = "Nkambe";
$areanames{en}->{237233221} = "Kumbo";
$areanames{en}->{237233262} = "Foumban";
$areanames{en}->{237233263} = "Foumban";
$areanames{en}->{237233267} = "Foumbot";
$areanames{en}->{237233277} = "Bandjoun";
$areanames{en}->{237233296} = "Bafang";
$areanames{en}->{237233297} = "Bafang";
$areanames{en}->{237233305} = "Mbouda";
$areanames{en}->{237233313} = "Yabassi";
$areanames{en}->{237233321} = "Muyuka";
$areanames{en}->{237233322} = "Buéa";
$areanames{en}->{237233323} = "Buéa";
$areanames{en}->{237233324} = "Buéa";
$areanames{en}->{237233325} = "Buéa";
$areanames{en}->{237233326} = "Buéa";
$areanames{en}->{237233327} = "Buéa";
$areanames{en}->{237233328} = "Buéa";
$areanames{en}->{237233329} = "Buéa";
$areanames{en}->{237233331} = "Tiko";
$areanames{en}->{237233332} = "Limbé";
$areanames{en}->{237233333} = "Limbé";
$areanames{en}->{237233334} = "Limbé";
$areanames{en}->{237233335} = "Limbé";
$areanames{en}->{237233336} = "Limbé";
$areanames{en}->{237233337} = "Limbé";
$areanames{en}->{237233338} = "Limbé";
$areanames{en}->{237233339} = "Limbé";
$areanames{en}->{237233341} = "Manfé";
$areanames{en}->{237233354} = "Kumba";
$areanames{en}->{237233355} = "Kumba";
$areanames{en}->{237233360} = "Bamenda";
$areanames{en}->{237233361} = "Bamenda";
$areanames{en}->{237233362} = "Bamenda";
$areanames{en}->{237233363} = "Bamenda";
$areanames{en}->{237233364} = "Bamenda";
$areanames{en}->{237233366} = "Mbambili";
$areanames{en}->{23723337} = "Bassa";
$areanames{en}->{23723339} = "Bonabéri";
$areanames{en}->{23723340} = "Bepanda";
$areanames{en}->{23723341} = "Bepanda";
$areanames{en}->{23723342} = "Akwa\ Centre";
$areanames{en}->{23723343} = "Akwa\ Centre";
$areanames{en}->{23723344} = "Bafoussam";
$areanames{en}->{237233451} = "Dschang";
$areanames{en}->{237233452} = "Dschang";
$areanames{en}->{237233464} = "Edéa";
$areanames{en}->{23723347} = "Akwa\ North";
$areanames{en}->{237233484} = "Bangangté";
$areanames{en}->{237233489} = "Bangangté";
$areanames{en}->{237233490} = "Nkongsamba";
$areanames{en}->{237233491} = "Nkongsamba";
$areanames{en}->{237233492} = "Nkongsamba";
$areanames{en}->{237233493} = "Nkongsamba";
$areanames{en}->{237233494} = "Nkongsamba";
$areanames{en}->{237233495} = "Nkongsamba";
$areanames{en}->{237233496} = "Nkongsamba";
$areanames{en}->{237233497} = "Loum\/Mbanga";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+237|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;