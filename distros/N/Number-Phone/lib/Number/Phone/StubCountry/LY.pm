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
our $VERSION = 1.20210204173826;

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
$areanames{en} = {"218821", "Gubba",
"21882", "Haraua",
"218522", "Tawergha",
"21884", "El\ Beida",
"21851", "Misratah",
"218629", "Elmagrun",
"21824", "Sabratha",
"218524", "Kasarahmad",
"218481", "Kabaw",
"21822", "Ben\ Gashir",
"218627", "Jerdina",
"218482", "Tigi",
"21831", "Khums",
"21881", "Derna",
"21861", "Benghazi",
"218529", "Bugrain",
"218624", "Elkuwaifia",
"218685", "Tomina",
"218453", "Reyana",
"21821", "Tripoli",
"218322", "Bani\ Walid",
"218425", "Buzayan",
"218484", "Ghadames",
"21854", "Sirt",
"218224", "Swajni",
"218733", "Garda",
"218521", "Zliten",
"21826", "Taigura",
"218655", "Bisher",
"218734", "Traghen",
"218452", "Rujban",
"21847", "Nalut",
"218323", "Wadi\ Keam",
"218732", "Bergen",
"218454", "Al\ Josh",
"218623", "Gmines",
"218726", "Um\ Laranib",
"218731", "Wadi\ Atba",
"21873", "Ubary",
"218523", "Dafnia",
"218725", "Murzuk",
"218275", "Matred",
"218555", "Noflia",
"218584", "Zella",
"218723", "Edry",
"218526", "Zawyat\ Elmahjub",
"218281", "Jmail",
"218421", "Yefren",
"218582", "Sokna",
"21888", "Jaghbub",
"218681", "Tolmitha",
"218553", "Abuhadi",
"21841", "Garian",
"218653", "Ojla",
"218284", "Hugialin",
"218206", "Suk\ Elkhamis",
"218581", "Wodan",
"21823", "Zawia",
"218427", "Kikla",
"218682", "Jardas",
"218205", "Sidiessaiah",
"218325", "Tarhuna",
"218282", "Agelat\,\ Ajalat",
"218626", "Kaalifa",
"21863", "Benina",
"218422", "Mizda",
"218326", "Kussabat",
"218625", "Deriana",
"218684", "Elbayada",
"218271", "Hashan",
"218551", "Sirt",
"218852", "Massa",
"218729", "Ghrefa",
"218652", "Kofra",
"218683", "Taknes",
"218721", "Brak",
"218279", "Elmaya",
"218423", "Guassem",
"218854", "Slenta",
"218654", "Sidi\ Sultan\ Sultan",
"218628", "Seluk",
"21867", "Elmareg",
"218252", "Zahra",
"218657", "Jalo",
"218277", "Mamura",
"21857", "Hun",
"21825", "Zuara",
"218274", "Abu\ Issa",
"218554", "Wadi\ Jeref",
"218727", "Zawaya",
"218583", "Soussa",
"218272", "Azizia",
"218724", "Ghat",
"21871", "Sebha",
"218851", "Shahat",};

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