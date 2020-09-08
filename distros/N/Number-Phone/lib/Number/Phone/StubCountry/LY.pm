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
package Number::Phone::StubCountry::LY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200904144534;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '[2-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{7})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              0[56]|
              [1-6]\\d|
              7[124579]|
              8[124]
            )|
            3(?:
              1\\d|
              2[2356]
            )|
            4(?:
              [17]\\d|
              2[1-357]|
              5[2-4]|
              8[124]
            )|
            5(?:
              [1347]\\d|
              2[1-469]|
              5[13-5]|
              8[1-4]
            )|
            6(?:
              [1-479]\\d|
              5[2-57]|
              8[1-5]
            )|
            7(?:
              [13]\\d|
              2[13-79]
            )|
            8(?:
              [124]\\d|
              5[124]|
              84
            )
          )\\d{6}
        ',
                'geographic' => '
          (?:
            2(?:
              0[56]|
              [1-6]\\d|
              7[124579]|
              8[124]
            )|
            3(?:
              1\\d|
              2[2356]
            )|
            4(?:
              [17]\\d|
              2[1-357]|
              5[2-4]|
              8[124]
            )|
            5(?:
              [1347]\\d|
              2[1-469]|
              5[13-5]|
              8[1-4]
            )|
            6(?:
              [1-479]\\d|
              5[2-57]|
              8[1-5]
            )|
            7(?:
              [13]\\d|
              2[13-79]
            )|
            8(?:
              [124]\\d|
              5[124]|
              84
            )
          )\\d{6}
        ',
                'mobile' => '9[1-6]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{218205} = "Sidiessaiah";
$areanames{en}->{218206} = "Suk\ Elkhamis";
$areanames{en}->{21821} = "Tripoli";
$areanames{en}->{21822} = "Ben\ Gashir";
$areanames{en}->{218224} = "Swajni";
$areanames{en}->{21823} = "Zawia";
$areanames{en}->{21824} = "Sabratha";
$areanames{en}->{21825} = "Zuara";
$areanames{en}->{218252} = "Zahra";
$areanames{en}->{21826} = "Taigura";
$areanames{en}->{218271} = "Hashan";
$areanames{en}->{218272} = "Azizia";
$areanames{en}->{218274} = "Abu\ Issa";
$areanames{en}->{218275} = "Matred";
$areanames{en}->{218277} = "Mamura";
$areanames{en}->{218279} = "Elmaya";
$areanames{en}->{218281} = "Jmail";
$areanames{en}->{218282} = "Agelat\,\ Ajalat";
$areanames{en}->{218284} = "Hugialin";
$areanames{en}->{21831} = "Khums";
$areanames{en}->{218322} = "Bani\ Walid";
$areanames{en}->{218323} = "Wadi\ Keam";
$areanames{en}->{218325} = "Tarhuna";
$areanames{en}->{218326} = "Kussabat";
$areanames{en}->{21841} = "Garian";
$areanames{en}->{218421} = "Yefren";
$areanames{en}->{218422} = "Mizda";
$areanames{en}->{218423} = "Guassem";
$areanames{en}->{218425} = "Buzayan";
$areanames{en}->{218427} = "Kikla";
$areanames{en}->{218452} = "Rujban";
$areanames{en}->{218453} = "Reyana";
$areanames{en}->{218454} = "Al\ Josh";
$areanames{en}->{21847} = "Nalut";
$areanames{en}->{218481} = "Kabaw";
$areanames{en}->{218482} = "Tigi";
$areanames{en}->{218484} = "Ghadames";
$areanames{en}->{21851} = "Misratah";
$areanames{en}->{218521} = "Zliten";
$areanames{en}->{218522} = "Tawergha";
$areanames{en}->{218523} = "Dafnia";
$areanames{en}->{218524} = "Kasarahmad";
$areanames{en}->{218526} = "Zawyat\ Elmahjub";
$areanames{en}->{218529} = "Bugrain";
$areanames{en}->{21854} = "Sirt";
$areanames{en}->{218551} = "Sirt";
$areanames{en}->{218553} = "Abuhadi";
$areanames{en}->{218554} = "Wadi\ Jeref";
$areanames{en}->{218555} = "Noflia";
$areanames{en}->{21857} = "Hun";
$areanames{en}->{218581} = "Wodan";
$areanames{en}->{218582} = "Sokna";
$areanames{en}->{218583} = "Soussa";
$areanames{en}->{218584} = "Zella";
$areanames{en}->{21861} = "Benghazi";
$areanames{en}->{218623} = "Gmines";
$areanames{en}->{218624} = "Elkuwaifia";
$areanames{en}->{218625} = "Deriana";
$areanames{en}->{218626} = "Kaalifa";
$areanames{en}->{218627} = "Jerdina";
$areanames{en}->{218628} = "Seluk";
$areanames{en}->{218629} = "Elmagrun";
$areanames{en}->{21863} = "Benina";
$areanames{en}->{218652} = "Kofra";
$areanames{en}->{218653} = "Ojla";
$areanames{en}->{218654} = "Sidi\ Sultan\ Sultan";
$areanames{en}->{218655} = "Bisher";
$areanames{en}->{218657} = "Jalo";
$areanames{en}->{21867} = "Elmareg";
$areanames{en}->{218681} = "Tolmitha";
$areanames{en}->{218682} = "Jardas";
$areanames{en}->{218683} = "Taknes";
$areanames{en}->{218684} = "Elbayada";
$areanames{en}->{218685} = "Tomina";
$areanames{en}->{21871} = "Sebha";
$areanames{en}->{218721} = "Brak";
$areanames{en}->{218723} = "Edry";
$areanames{en}->{218724} = "Ghat";
$areanames{en}->{218725} = "Murzuk";
$areanames{en}->{218726} = "Um\ Laranib";
$areanames{en}->{218727} = "Zawaya";
$areanames{en}->{218729} = "Ghrefa";
$areanames{en}->{21873} = "Ubary";
$areanames{en}->{218731} = "Wadi\ Atba";
$areanames{en}->{218732} = "Bergen";
$areanames{en}->{218733} = "Garda";
$areanames{en}->{218734} = "Traghen";
$areanames{en}->{21881} = "Derna";
$areanames{en}->{21882} = "Haraua";
$areanames{en}->{218821} = "Gubba";
$areanames{en}->{21884} = "El\ Beida";
$areanames{en}->{218851} = "Shahat";
$areanames{en}->{218852} = "Massa";
$areanames{en}->{218854} = "Slenta";
$areanames{en}->{21888} = "Jaghbub";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+218|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;