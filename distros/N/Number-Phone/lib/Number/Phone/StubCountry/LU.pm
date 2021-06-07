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
package Number::Phone::StubCountry::LU;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210602223300;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            2(?:
              0[2-689]|
              [2-9]
            )|
            [3-57]|
            8(?:
              0[2-9]|
              [13-9]
            )|
            9(?:
              0[89]|
              [2-579]
            )
          ',
                  'pattern' => '(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            2(?:
              0[2-689]|
              [2-9]
            )|
            [3-57]|
            8(?:
              0[2-9]|
              [13-9]
            )|
            9(?:
              0[89]|
              [2-579]
            )
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '20[2-689]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            2(?:
              [0367]|
              4[3-8]
            )
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{1,2})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            80[01]|
            90[015]
          ',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '20',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '6',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4 $5',
                  'leading_digits' => '
            2(?:
              [0367]|
              4[3-8]
            )
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})(\\d{1,2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            [3-57]|
            8[13-9]|
            9(?:
              0[89]|
              [2-579]
            )|
            (?:
              2|
              80
            )[2-9]
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{1,5})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            35[013-9]|
            80[2-9]|
            90[89]
          )\\d{1,8}|
          (?:
            2[2-9]|
            3[0-46-9]|
            [457]\\d|
            8[13-9]|
            9[2-579]
          )\\d{2,9}
        ',
                'geographic' => '
          (?:
            35[013-9]|
            80[2-9]|
            90[89]
          )\\d{1,8}|
          (?:
            2[2-9]|
            3[0-46-9]|
            [457]\\d|
            8[13-9]|
            9[2-579]
          )\\d{2,9}
        ',
                'mobile' => '
          6(?:
            [269][18]|
            5[158]|
            7[189]|
            81
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(801\\d{5})|(90[015]\\d{5})',
                'toll_free' => '800\\d{5}',
                'voip' => '
          20(?:
            1\\d{5}|
            [2-689]\\d{1,7}
          )
        '
              };
my %areanames = ();
$areanames{en} = {"3522437", "Leudelange\/Ehlange\/Mondercange",
"3522635", "Sandweiler\/Moutfort\/Roodt\-sur\-Syre",
"3522630", "Capellen\/Kehlen",
"3522781", "Ettelbruck\/Reckange\-sur\-Mess",
"3522673", "Rosport",
"3522684", "Han\/Lesse",
"3522632", "Lintgen\/Mersch\/Steinfort",
"3522639", "Windhof\/Steinfort",
"3522774", "Wasserbillig",
"3522756", "Rumelange",
"3522783", "Vianden",
"3522671", "Betzdorf",
"35237", "Leudelange\/Ehlange\/Mondercange",
"35271", "Betzdorf",
"35259", "Soleuvre",
"3522477", "Luxembourg",
"35284", "Han\/Lesse",
"35229", "Luxembourg\/Kockelscheuer",
"3522675", "Grevenmacher\-sur\-Moselle",
"3522633", "Walferdange",
"3522799", "Troisvierges",
"35299", "Troisvierges",
"3522672", "Echternach",
"35230", "Capellen\/Kehlen",
"3522679", "Berdorf\/Consdorf",
"3522734", "Rameldange\/Senningerberg",
"3522748", "Contern\/Foetz",
"3522792", "Clervaux\/Fischbach\/Hosingen",
"35279", "Berdorf\/Consdorf",
"3522780", "Diekirch",
"3522631", "Bertrange\/Mamer\/Munsbach\/Strassen",
"3522785", "Bissen\/Roost",
"35245", "Diedrich",
"35251", "Dudelange\/Bettembourg\/Livange",
"3522795", "Wiltz",
"3522459", "Soleuvre",
"3522422", "Luxembourg\ City",
"3522420", "Luxembourg",
"3522643", "Findel\/Kirchberg",
"3522425", "Luxembourg",
"3522627", "Belair\,\ Luxembourg",
"3522657", "Esch\-sur\-Alzette\/Schifflange",
"35258", "Differdange",
"35257", "Esch\-sur\-Alzette\/Schifflange",
"3522455", "Esch\-sur\-Alzette\/Mondercange",
"35283", "Vianden",
"3522450", "Bascharage\/Petange\/Rodange",
"35239", "Windhof\/Steinfort",
"3522429", "Luxembourg\/Kockelscheuer",
"3522452", "Dudelange",
"3522642", "Plateau\ de\ Kirchberg",
"35297", "Huldange",
"3522640", "Howald",
"3522423", "Mondorf\-les\-Bains\/Bascharage\/Noerdange\/Remich",
"3522688", "Mertzig\/Wahl",
"3522451", "Dudelange\/Bettembourg\/Livange",
"3522645", "Diedrich",
"35250", "Bascharage\/Petange\/Rodange",
"3522467", "Dudelange",
"3522447", "Lintgen",
"35228", "Luxembourg\ City",
"35231", "Bertrange\/Mamer\/Munsbach\/Strassen",
"3522778", "Junglinster",
"3522421", "Weicherdange",
"35278", "Junglinster",
"3522453", "Esch\-sur\-Alzette",
"3522649", "Howald",
"3522486", "Luxembourg",
"3522749", "Howald",
"3522424", "Luxembourg",
"3522678", "Junglinster",
"35276", "Wormeldange",
"35243", "Findel\/Kirchberg",
"3522745", "Diedrich",
"3522740", "Howald",
"3522788", "Mertzig\/Wahl",
"3522742", "Plateau\ de\ Kirchberg",
"3522454", "Esch\-sur\-Alzette",
"3522476", "Wormeldange",
"3522757", "Esch\-sur\-Alzette\/Schifflange",
"35256", "Rumelange",
"3522727", "Belair\,\ Luxembourg",
"3522743", "Findel\/Kirchberg",
"3522436", "Hesperange\/Kockelscheuer\/Roeser",
"3522695", "Wiltz",
"3522487", "Larochette",
"3522685", "Bissen\/Roost",
"3522497", "Huldange",
"3522692", "Clervaux\/Fischbach\/Hosingen",
"3522648", "Contern\/Foetz",
"3522731", "Bertrange\/Mamer\/Munsbach\/Strassen",
"3522680", "Diekirch",
"3522779", "Berdorf\/Consdorf",
"3522634", "Rameldange\/Senningerberg",
"3522772", "Echternach",
"3522446", "Luxembourg",
"3522699", "Troisvierges",
"3522733", "Walferdange",
"3522775", "Grevenmacher\-sur\-Moselle",
"35242", "Plateau\ de\ Kirchberg",
"3522683", "Vianden",
"35236", "Hesperange\/Kockelscheuer\/Roeser",
"3522428", "Luxembourg\ City",
"3522771", "Betzdorf",
"3522739", "Windhof\/Steinfort",
"35285", "Bissen\/Roost",
"3522656", "Rumelange",
"3522674", "Wasserbillig",
"3522784", "Han\/Lesse",
"35244", "Luxembourg\ City",
"3522732", "Lintgen\/Mersch\/Steinfort",
"3522458", "Soleuvre\/Differdange",
"3522681", "Ettelbruck\/Reckange\-sur\-Mess",
"3522730", "Capellen\/Kehlen",
"3522773", "Rosport",
"3522735", "Sandweiler\/Moutfort\/Roodt\-sur\-Syre",
"3522647", "Lintgen",
"3522445", "Diedrich",
"3522667", "Dudelange",
"3522623", "Mondorf\-les\-Bains\/Bascharage\/Noerdange\/Remich",
"3522440", "Howald",
"3522651", "Dudelange\/Bettembourg\/Livange",
"3522488", "Mertzig\/Wahl",
"3522442", "Plateau\ de\ Kirchberg",
"3522754", "Esch\-sur\-Alzette",
"3522776", "Wormeldange",
"35255", "Esch\-sur\-Alzette\/Mondercange",
"35241", "Luxembourg\ City",
"3522449", "Howald",
"3522621", "Weicherdange",
"3522653", "Esch\-sur\-Alzette",
"3522427", "Belair\,\ Luxembourg",
"35275", "Grevenmacher",
"3522625", "Luxembourg",
"3522443", "Findel\/Kirchberg",
"3522659", "Soleuvre",
"3522622", "Luxembourg\ City",
"35249", "Howald",
"3522736", "Hesperange\/Kockelscheuer\/Roeser",
"35225", "Luxembourg",
"3522652", "Dudelange",
"3522629", "Luxembourg\/Kockelscheuer",
"3522650", "Bascharage\/Petange\/Rodange",
"3522441", "Luxembourg",
"3522655", "Esch\-sur\-Alzette\/Mondercange",
"3522457", "Esch\-sur\-Alzette\/Schifflange",
"35295", "Wiltz",
"3522472", "Echternach",
"3522470", "Luxembourg",
"3522433", "Walferdange",
"3522475", "Grevenmacher\-sur\-Moselle",
"35235", "Sandweiler\/Moutfort\/Roodt\-sur\-Syre",
"352241", "Luxembourg",
"3522787", "Larochette",
"3522797", "Huldange",
"35240", "Howald",
"3522431", "Bertrange\/Mamer\/Munsbach\/Strassen",
"3522479", "Berdorf\/Consdorf",
"35247", "Lintgen",
"3522484", "Han\/Lesse",
"35248", "Contern\/Foetz",
"3522432", "Lintgen\/Mersch\/Steinfort",
"3522430", "Capellen\/Kehlen",
"3522758", "Soleuvre\/Differdange",
"3522473", "Rosport",
"3522435", "Sandweiler\/Moutfort\/Roodt\-sur\-Syre",
"3522637", "Leudelange\/Ehlange\/Mondercange",
"352240", "Luxembourg",
"352246", "Luxembourg",
"3522728", "Luxembourg\ City",
"3522471", "Betzdorf",
"3522439", "Windhof\/Steinfort",
"3522456", "Rumelange",
"3522474", "Wasserbillig",
"35223", "Mondorf\-les\-Bains\/Bascharage\/Noerdange\/Remich",
"3522483", "Vianden",
"35234", "Rameldange\/Senningerberg",
"3522628", "Luxembourg\ City",
"35280", "Diekirch",
"3522737", "Leudelange\/Ehlange\/Mondercange",
"35232", "Mersch",
"35273", "Rosport",
"3522481", "Ettelbruck\/Reckange\-sur\-Mess",
"3522658", "Soleuvre\/Differdange",
"3522426", "Luxembourg",
"35246", "Luxembourg\ City",
"3522482", "Luxembourg",
"3522434", "Rameldange\/Senningerberg",
"3522492", "Clervaux\/Fischbach\/Hosingen",
"3522448", "Contern\/Foetz",
"3522480", "Diekirch",
"3522485", "Bissen\/Roost",
"3522697", "Huldange",
"3522495", "Wiltz",
"3522687", "Larochette",
"35288", "Mertzig\/Wahl",
"35287", "Larochette",
"35253", "Esch\-sur\-Alzette",
"3522499", "Troisvierges",
"3522489", "Luxembourg",
"35254", "Esch\-sur\-Alzette",
"3522755", "Esch\-sur\-Alzette\/Mondercange",
"3522750", "Bascharage\/Petange\/Rodange",
"3522438", "Luxembourg",
"3522444", "Luxembourg",
"3522752", "Dudelange",
"3522729", "Luxembourg\/Kockelscheuer",
"3522722", "Luxembourg\ City",
"3522759", "Soleuvre",
"3522636", "Hesperange\/Kockelscheuer\/Roeser",
"35252", "Dudelange",
"3522725", "Luxembourg",
"352249", "Luxembourg",
"35281", "Ettelbruck",
"35292", "Clervaux\/Fischbach\/Hosingen",
"3522721", "Weicherdange",
"35222", "Luxembourg\ City",
"3522478", "Junglinster",
"35274", "Wasserbillig",
"3522753", "Esch\-sur\-Alzette",
"3522654", "Esch\-sur\-Alzette",
"3522676", "Wormeldange",
"3522723", "Mondorf\-les\-Bains\/Bascharage\/Noerdange\/Remich",
"3522751", "Dudelange\/Bettembourg\/Livange",
"3522767", "Dudelange",
"35233", "Walferdange",
"3522747", "Lintgen",
"35272", "Echternach",};
$areanames{fr} = {"3522428", "Luxembourg\-Ville",
"35244", "Luxembourg\-Ville",
"35228", "Luxembourg\-Ville",
"3522422", "Luxembourg\-Ville",
"35222", "Luxembourg\-Ville",
"3522722", "Luxembourg\-Ville",
"3522628", "Luxembourg\-Ville",
"35246", "Luxembourg\-Ville",
"3522728", "Luxembourg\-Ville",
"3522622", "Luxembourg\-Ville",
"35241", "Luxembourg\-Ville",};
$areanames{de} = {"3522676", "Wormeldingen",
"3522751", "Düdelingen\/Bettemburg\/Livingen",
"3522723", "Bad\ Mondorf",
"3522767", "Düdelingen",
"35233", "Walferdingen",
"35292", "Kanton\ Clerf\/Fischbach\/Hosingen",
"3522721", "Weicherdingen",
"35222", "Luxemburg",
"3522636", "Hesperingen\/Kockelscheuer\/Roeser",
"3522722", "Luxemburg",
"35252", "Düdelingen",
"3522725", "Luxemburg",
"35281", "Ettelbrück",
"352249", "Luxemburg",
"3522755", "Esch\-sur\-Alzette\/Monnerich",
"3522750", "Bascharage\/Petingen\/Rodingen",
"3522438", "Luxemburg",
"3522444", "Luxemburg",
"3522729", "Luxemburg\/Kockelscheuer",
"3522752", "Düdelingen",
"35287", "Fels",
"3522499", "Ulflingen",
"3522489", "Luxemburg",
"3522434", "Rammeldingen\/Senningerberg",
"3522482", "Luxemburg",
"3522492", "Kanton\ Clerf\/Fischbach\/Hosingen",
"3522697", "Huldingen",
"3522687", "Fels",
"3522737", "Leudelingen\/Ehlingen\/Monnerich",
"35232", "Kanton\ Mersch",
"3522658", "Soleuvre\/Differdingen",
"3522481", "Ettelbrück\/Reckange\-sur\-Mess",
"35246", "Luxemburg",
"3522456", "Rümelingen",
"35234", "Rammeldingen\/Senningerberg",
"3522628", "Luxemburg",
"35223", "Bad\ Mondorf",
"352246", "Luxemburg",
"3522728", "Luxemburg",
"3522432", "Lintgen\/Kanton\ Mersch\/Steinfort",
"3522430", "Kanton\ Capellen\/Kehlen",
"3522758", "Soleuvre\/Differdingen",
"3522435", "Sandweiler\/Mutfort\/Roodt\-sur\-Syre",
"352240", "Luxemburg",
"3522637", "Leudelingen\/Ehlingen\/Monnerich",
"3522787", "Fels",
"3522797", "Huldingen",
"3522431", "Bartringen",
"3522433", "Walferdingen",
"3522470", "Luxemburg",
"3522475", "Distrikt\ Grevenmacher\-sur\-Moselle",
"35235", "Sandweiler\/Mutfort\/Roodt\-sur\-Syre",
"352241", "Luxemburg",
"35225", "Luxemburg",
"3522652", "Düdelingen",
"3522629", "Luxemburg\/Kockelscheuer",
"3522441", "Luxemburg",
"3522650", "Bascharage\/Petingen\/Rodingen",
"3522655", "Esch\-sur\-Alzette\/Monnerich",
"3522457", "Esch\-sur\-Alzette\/Schifflingen",
"3522427", "Belair\,\ Luxemburg",
"35275", "Distrikt\ Grevenmacher",
"3522625", "Luxemburg",
"3522736", "Hesperingen\/Kockelscheuer\/Roeser",
"3522622", "Luxemburg",
"3522621", "Weicherdingen",
"3522667", "Düdelingen",
"3522651", "Düdelingen\/Bettemburg\/Livingen",
"3522623", "Bad\ Mondorf",
"3522776", "Wormeldingen",
"35255", "Esch\-sur\-Alzette\/Monnerich",
"35241", "Luxemburg",
"3522732", "Lintgen\/Kanton\ Mersch\/Steinfort",
"35244", "Luxemburg",
"3522458", "Soleuvre\/Differdingen",
"3522681", "Ettelbrück\/Reckange\-sur\-Mess",
"3522730", "Kanton\ Capellen\/Kehlen",
"3522735", "Sandweiler\/Mutfort\/Roodt\-sur\-Syre",
"35236", "Hesperingen\/Kockelscheuer\/Roeser",
"3522656", "Rümelingen",
"3522446", "Luxemburg",
"3522699", "Ulflingen",
"3522733", "Walferdingen",
"3522775", "Distrikt\ Grevenmacher\-sur\-Moselle",
"3522487", "Fels",
"3522497", "Huldingen",
"3522731", "Bartringen",
"3522692", "Kanton\ Clerf\/Fischbach\/Hosingen",
"3522634", "Rammeldingen\/Senningerberg",
"3522727", "Belair\,\ Luxemburg",
"3522436", "Hesperingen\/Kockelscheuer\/Roeser",
"35256", "Rümelingen",
"3522757", "Esch\-sur\-Alzette\/Schifflingen",
"3522476", "Wormeldingen",
"35276", "Wormeldingen",
"35231", "Bartringen",
"3522421", "Weicherdingen",
"3522486", "Luxemburg",
"35297", "Huldingen",
"3522451", "Düdelingen\/Bettemburg\/Livingen",
"3522423", "Bad\ Mondorf",
"35250", "Bascharage\/Petingen\/Rodingen",
"3522467", "Düdelingen",
"35228", "Luxemburg",
"35257", "Esch\-sur\-Alzette\/Schifflingen",
"3522657", "Esch\-sur\-Alzette\/Schifflingen",
"35258", "Differdingen",
"3522455", "Esch\-sur\-Alzette\/Monnerich",
"3522450", "Bascharage\/Petingen\/Rodingen",
"3522452", "Düdelingen",
"3522429", "Luxemburg\/Kockelscheuer",
"3522627", "Belair\,\ Luxemburg",
"3522734", "Rammeldingen\/Senningerberg",
"3522631", "Bartringen",
"3522792", "Kanton\ Clerf\/Fischbach\/Hosingen",
"352242", "Luxemburg",
"35251", "Düdelingen\/Bettemburg\/Livingen",
"35229", "Luxemburg",
"3522477", "Luxemburg",
"3522675", "Distrikt\ Grevenmacher\-sur\-Moselle",
"3522633", "Walferdingen",
"3522799", "Ulflingen",
"35299", "Ulflingen",
"35230", "Kanton\ Capellen\/Kehlen",
"3522756", "Rümelingen",
"35237", "Leudelingen\/Ehlingen\/Monnerich",
"3522437", "Leudelingen\/Ehlingen\/Monnerich",
"3522635", "Sandweiler\/Mutfort\/Roodt\-sur\-Syre",
"3522630", "Kanton\ Capellen\/Kehlen",
"3522781", "Ettelbrück\/Reckange\-sur\-Mess",
"3522632", "Lintgen\/Kanton\ Mersch\/Steinfort",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+352|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:(15(?:0[06]|1[12]|[35]5|4[04]|6[26]|77|88|99)\d))//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;