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
our $VERSION = 1.20210309172132;

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
$areanames{en} = {"218322", "Bani\ Walid",
"218272", "Azizia",
"218453", "Reyana",
"218624", "Elkuwaifia",
"218627", "Jerdina",
"218522", "Tawergha",
"218551", "Sirt",
"218484", "Ghadames",
"218727", "Zawaya",
"218724", "Ghat",
"21823", "Zawia",
"218326", "Kussabat",
"218628", "Seluk",
"218526", "Zawyat\ Elmahjub",
"21884", "El\ Beida",
"218731", "Wadi\ Atba",
"21871", "Sebha",
"218325", "Tarhuna",
"218452", "Rujban",
"218275", "Matred",
"218421", "Yefren",
"218323", "Wadi\ Keam",
"21881", "Derna",
"21861", "Benghazi",
"218681", "Tolmitha",
"218523", "Dafnia",
"21826", "Taigura",
"21825", "Zuara",
"218626", "Kaalifa",
"21888", "Jaghbub",
"21854", "Sirt",
"218524", "Kasarahmad",
"218281", "Jmail",
"21821", "Tripoli",
"218482", "Tigi",
"218274", "Abu\ Issa",
"218277", "Mamura",
"218851", "Shahat",
"218726", "Um\ Laranib",
"21831", "Khums",
"218454", "Al\ Josh",
"218623", "Gmines",
"218224", "Swajni",
"21851", "Misratah",
"218581", "Wodan",
"21873", "Ubary",
"218625", "Deriana",
"21824", "Sabratha",
"21847", "Nalut",
"218725", "Murzuk",
"218723", "Edry",
"21863", "Benina",
"218684", "Elbayada",
"218655", "Bisher",
"218206", "Suk\ Elkhamis",
"218653", "Ojla",
"218427", "Kikla",
"218582", "Sokna",
"218554", "Wadi\ Jeref",
"218481", "Kabaw",
"21841", "Garian",
"218282", "Agelat\,\ Ajalat",
"218652", "Kofra",
"218583", "Soussa",
"218852", "Massa",
"218821", "Gubba",
"218734", "Traghen",
"218529", "Bugrain",
"21822", "Ben\ Gashir",
"21857", "Hun",
"218279", "Elmaya",
"218721", "Brak",
"218205", "Sidiessaiah",
"218422", "Mizda",
"218252", "Zahra",
"218584", "Zella",
"218553", "Abuhadi",
"218682", "Jardas",
"218555", "Noflia",
"21882", "Haraua",
"218733", "Garda",
"218629", "Elmagrun",
"218732", "Bergen",
"21867", "Elmareg",
"218654", "Sidi\ Sultan\ Sultan",
"218657", "Jalo",
"218423", "Guassem",
"218729", "Ghrefa",
"218854", "Slenta",
"218425", "Buzayan",
"218271", "Hashan",
"218685", "Tomina",
"218683", "Taknes",
"218521", "Zliten",
"218284", "Hugialin",};

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