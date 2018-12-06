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
package Number::Phone::StubCountry::ES;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20181205223703;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})',
                  'leading_digits' => '[89]00',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})',
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            [568]|
            7[0-48]|
            9(?:
              0[12]|
              [1-8]
            )
          '
                }
              ];

my $validators = {
                'voip' => '',
                'pager' => '',
                'mobile' => '
          (?:
            (?:
              6\\d|
              7[1-48]
            )\\d{5}|
            9(?:
              6906(?:
                09|
                10
              )|
              7390\\d\\d
            )
          )\\d\\d
        ',
                'fixed_line' => '
          (?:
            8(?:
              [1356]\\d|
              [28][0-8]|
              [47][1-9]
            )\\d{4}|
            9(?:
              (?:
                (?:
                  [135]\\d|
                  [28][0-8]|
                  4[1-9]
                )\\d\\d|
                7(?:
                  [124-9]\\d\\d|
                  3(?:
                    [0-8]\\d|
                    9[1-9]
                  )
                )
              )\\d\\d|
              6(?:
                [0-8]\\d{4}|
                9(?:
                  0(?:
                    [0-57-9]\\d\\d|
                    6(?:
                      0[0-8]|
                      1[1-9]|
                      [2-9]\\d
                    )
                  )|
                  [1-9]\\d{3}
                )
              )
            )
          )\\d\\d
        ',
                'personal_number' => '70\\d{7}',
                'specialrate' => '(90[12]\\d{6})|(80[367]\\d{6})|(51\\d{7})',
                'toll_free' => '[89]00\\d{6}',
                'geographic' => '
          (?:
            8(?:
              [1356]\\d|
              [28][0-8]|
              [47][1-9]
            )\\d{4}|
            9(?:
              (?:
                (?:
                  [135]\\d|
                  [28][0-8]|
                  4[1-9]
                )\\d\\d|
                7(?:
                  [124-9]\\d\\d|
                  3(?:
                    [0-8]\\d|
                    9[1-9]
                  )
                )
              )\\d\\d|
              6(?:
                [0-8]\\d{4}|
                9(?:
                  0(?:
                    [0-57-9]\\d\\d|
                    6(?:
                      0[0-8]|
                      1[1-9]|
                      [2-9]\\d
                    )
                  )|
                  [1-9]\\d{3}
                )
              )
            )
          )\\d\\d
        '
              };
my %areanames = (
  3481 => "Madrid",
  34820 => "Ávila",
  34821 => "Segovia",
  34822 => "Tenerife",
  34823 => "Salamanca",
  34824 => "Badajoz",
  34825 => "Toledo",
  34826 => "Ciudad\ Real",
  34827 => "Cáceres",
  34828 => "Las\ Palmas",
  3483 => "Barcelona",
  34841 => "La\ Rioja",
  34842 => "Cantabria",
  34843 => "Guipúzcoa",
  34844 => "Bizkaia",
  34845 => "Araba",
  34846 => "Bizkaia",
  34847 => "Burgos",
  34848 => "Navarre",
  34849 => "Guadalajara",
  34850 => "Almería",
  34851 => "Málaga",
  34852 => "Málaga",
  34853 => "Jaén",
  34854 => "Seville",
  34855 => "Seville",
  34856 => "Cádiz",
  34857 => "Cordova",
  34858 => "Granada",
  34859 => "Huelva",
  34860 => "Valencia",
  34861 => "Valencia",
  34862 => "Valencia",
  34863 => "Valencia",
  34864 => "Castellón",
  34865 => "Alicante",
  34866 => "Alicante",
  34867 => "Albacete",
  34868 => "Murcia",
  34869 => "Cuenca",
  34871 => "Balearic\ Islands",
  34872 => "Gerona",
  34873 => "Lleida",
  34874 => "Huesca",
  34875 => "Soria",
  34876 => "Zaragoza",
  34877 => "Tarragona",
  34878 => "Teruel",
  34879 => "Palencia",
  34880 => "Zamora",
  34881 => "La\ Coruña",
  34882 => "Lugo",
  34883 => "Valladolid",
  34884 => "Asturias",
  34885 => "Asturias",
  34886 => "Pontevedra",
  34887 => "León",
  34888 => "Ourense",
  3491 => "Madrid",
  34920 => "Ávila",
  34921 => "Segovia",
  34922 => "Tenerife",
  34923 => "Salamanca",
  34924 => "Badajoz",
  34925 => "Toledo",
  34926 => "Ciudad\ Real",
  34927 => "Cáceres",
  34928 => "Las\ Palmas",
  3493 => "Barcelona",
  34941 => "La\ Rioja",
  34942 => "Cantabria",
  34943 => "Guipúzcoa",
  34944 => "Bizkaia",
  34945 => "Araba",
  34946 => "Bizkaia",
  34947 => "Burgos",
  34948 => "Navarre",
  34949 => "Guadalajara",
  34950 => "Almería",
  34951 => "Málaga",
  34952 => "Málaga",
  34953 => "Jaén",
  34954 => "Seville",
  34955 => "Seville",
  34956 => "Cádiz",
  34957 => "Cordova",
  34958 => "Granada",
  34959 => "Huelva",
  34960 => "Valencia",
  34961 => "Valencia",
  34962 => "Valencia",
  34963 => "Valencia",
  34964 => "Castellón",
  34965 => "Alicante",
  34966 => "Alicante",
  34967 => "Albacete",
  34968 => "Murcia",
  34969 => "Cuenca",
  34971 => "Balearic\ Islands",
  34972 => "Gerona",
  34973 => "Lleida",
  34974 => "Huesca",
  34975 => "Soria",
  34976 => "Zaragoza",
  34977 => "Tarragona",
  34978 => "Teruel",
  34979 => "Palencia",
  34980 => "Zamora",
  34981 => "La\ Coruña",
  34982 => "Lugo",
  34983 => "Valladolid",
  34984 => "Asturias",
  34985 => "Asturias",
  34986 => "Pontevedra",
  34987 => "León",
  34988 => "Ourense",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+34|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;