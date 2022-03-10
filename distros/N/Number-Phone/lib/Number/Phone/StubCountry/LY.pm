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
our $VERSION = 1.20220307120120;

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
$areanames{en} = {"218252", "Zahra",
"21822", "Ben\ Gashir",
"21851", "Misratah",
"218582", "Sokna",
"218206", "Suk\ Elkhamis",
"218224", "Swajni",
"218484", "Ghadames",
"218481", "Kabaw",
"21888", "Jaghbub",
"218655", "Bisher",
"21857", "Hun",
"218326", "Kussabat",
"218654", "Sidi\ Sultan\ Sultan",
"218653", "Ojla",
"218657", "Jalo",
"218683", "Taknes",
"218277", "Mamura",
"218523", "Dafnia",
"218453", "Reyana",
"218524", "Kasarahmad",
"218521", "Zliten",
"218732", "Bergen",
"218454", "Al\ Josh",
"218685", "Tomina",
"218279", "Elmaya",
"218529", "Bugrain",
"218282", "Agelat\,\ Ajalat",
"21821", "Tripoli",
"218851", "Shahat",
"218422", "Mizda",
"21823", "Zawia",
"218854", "Slenta",
"218274", "Abu\ Issa",
"218626", "Kaalifa",
"218271", "Hashan",
"218275", "Matred",
"218322", "Bani\ Walid",
"218684", "Elbayada",
"218681", "Tolmitha",
"21884", "El\ Beida",
"218726", "Um\ Laranib",
"218733", "Garda",
"218553", "Abuhadi",
"218423", "Guassem",
"218427", "Kikla",
"218323", "Wadi\ Keam",
"21861", "Benghazi",
"21863", "Benina",
"218682", "Jardas",
"21854", "Sirt",
"218425", "Buzayan",
"21826", "Taigura",
"218555", "Noflia",
"21867", "Elmareg",
"218284", "Hugialin",
"218281", "Jmail",
"218554", "Wadi\ Jeref",
"218852", "Massa",
"21882", "Haraua",
"218421", "Yefren",
"21871", "Sebha",
"218551", "Sirt",
"21873", "Ubary",
"218272", "Azizia",
"218205", "Sidiessaiah",
"218452", "Rujban",
"218821", "Gubba",
"218734", "Traghen",
"218731", "Wadi\ Atba",
"218522", "Tawergha",
"218325", "Tarhuna",
"21831", "Khums",
"218624", "Elkuwaifia",
"218629", "Elmagrun",
"218652", "Kofra",
"218526", "Zawyat\ Elmahjub",
"21824", "Sabratha",
"218725", "Murzuk",
"218721", "Brak",
"21841", "Garian",
"21825", "Zuara",
"218724", "Ghat",
"218482", "Tigi",
"21881", "Derna",
"218581", "Wodan",
"218584", "Zella",
"218729", "Ghrefa",
"218625", "Deriana",
"21847", "Nalut",
"218627", "Jerdina",
"218583", "Soussa",
"218628", "Seluk",
"218723", "Edry",
"218727", "Zawaya",
"218623", "Gmines",};

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