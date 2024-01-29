# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::KG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20231210185945;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            3(?:
              1[346]|
              [24-79]
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4})(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [235-79]|
            88
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d)(\\d{2,3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          312(?:
            5[0-79]\\d|
            9(?:
              [0-689]\\d|
              7[0-24-9]
            )
          )\\d{3}|
          (?:
            3(?:
              1(?:
                2[0-46-8]|
                3[1-9]|
                47|
                [56]\\d
              )|
              2(?:
                22|
                3[0-479]|
                6[0-7]
              )|
              4(?:
                22|
                5[6-9]|
                6\\d
              )|
              5(?:
                22|
                3[4-7]|
                59|
                6\\d
              )|
              6(?:
                22|
                5[35-7]|
                6\\d
              )|
              7(?:
                22|
                3[468]|
                4[1-9]|
                59|
                [67]\\d
              )|
              9(?:
                22|
                4[1-8]|
                6\\d
              )
            )|
            6(?:
              09|
              12|
              2[2-4]
            )\\d
          )\\d{5}
        ',
                'geographic' => '
          312(?:
            5[0-79]\\d|
            9(?:
              [0-689]\\d|
              7[0-24-9]
            )
          )\\d{3}|
          (?:
            3(?:
              1(?:
                2[0-46-8]|
                3[1-9]|
                47|
                [56]\\d
              )|
              2(?:
                22|
                3[0-479]|
                6[0-7]
              )|
              4(?:
                22|
                5[6-9]|
                6\\d
              )|
              5(?:
                22|
                3[4-7]|
                59|
                6\\d
              )|
              6(?:
                22|
                5[35-7]|
                6\\d
              )|
              7(?:
                22|
                3[468]|
                4[1-9]|
                59|
                [67]\\d
              )|
              9(?:
                22|
                4[1-8]|
                6\\d
              )
            )|
            6(?:
              09|
              12|
              2[2-4]
            )\\d
          )\\d{5}
        ',
                'mobile' => '
          312(?:
            58\\d|
            973
          )\\d{3}|
          (?:
            2(?:
              0[0-35]|
              2\\d
            )|
            5[0-24-7]\\d|
            600|
            7(?:
              [07]\\d|
              55
            )|
            88[08]|
            9(?:
              12|
              9[05-9]
            )
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '800\\d{6,7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"996362", "Batken\,\ Naryn\ region",
"9963120", "Bishkek\,\ Chuy\ region",
"9963239", "Kara\-Kulja\,\ Osh\ region",
"9963122", "Bishkek\,\ Chuy\ region",
"99631252", "Bishkek\,\ Chuy\ region",
"996312978", "Bishkek\,\ Chuy\ region",
"9963741", "Ala\-Buka\,\ Jalal\-Abat\ region",
"9963736", "Bazarkorgon\,\ Jalal\-Abat\ region",
"9963133", "Kara\-Balta\,\ Chuy\ region",
"9963942", "Ananyevo\,\ Issyk\-Ko\ region",
"9963742", "Kerben\,\ Jalal\-Abat\ region",
"9963233", "Uzgen\,\ Osh\ region",
"9963457", "Bakay\-Ata\,\ Talas\ region",
"99631290", "Bishkek\,\ Chuy\ region",
"996312979", "Bishkek\,\ Chuy\ region",
"9963139", "Lebedinovka\,\ Chuy\ region",
"9963121", "Bishkek\,\ Chuy\ region",
"9963456", "Kyzyl\-Adyr\,\ Talas\ region",
"9963943", "Cholpon\-Ata\,\ Issyk\-Ko\ region",
"9963132", "Kant\,\ Chuy\ region",
"996342", "Talas",
"9963231", "Aravan\,\ Osh\ region",
"99631298", "Bishkek\,\ Chuy\ region",
"996392", "Karakol\,\ Issyk\-Ko\ region",
"9963738", "Kazarman\,\ Jalal\-Abat\ region",
"9963123", "Bishkek\,\ Chuy\ region",
"9963749", "Kanysh\-Kya\ \(Chatkal\)\,\ Jalal\-Abat\ region",
"99631253", "Bishkek\,\ Chuy\ region",
"9963657", "Kyzylkia\,\ Naryn\ region",
"9963655", "Pulgon\,\ Naryn\ region",
"996372", "Jalal\-Abat",
"9963131", "Belovodskoe\,\ Chuy\ region",
"99631254", "Bishkek\,\ Chuy\ region",
"996312976", "Bishkek\,\ Chuy\ region",
"9963734", "Massy\/Kochkor\-Ata\,\ Jalal\-Abat\ region",
"99631259", "Bishkek\,\ Chuy\ region",
"9963458", "Kokoy\,\ Talas\ region",
"996312975", "Bishkek\,\ Chuy\ region",
"9963230", "Eski\-Nookat\,\ Osh\ region",
"99631296", "Bishkek\,\ Chuy\ region",
"9963656", "Isfana\,\ Naryn\ region",
"99631291", "Bishkek\,\ Chuy\ region",
"9963232", "Kara\-Suu\,\ Osh\ region",
"99631255", "Bishkek\,\ Chuy\ region",
"9963653", "Sulukta\,\ Naryn\ region",
"9963746", "Kara\-Kul\,\ Jalal\-Abat\ region",
"996312971", "Bishkek\,\ Chuy\ region",
"9963134", "Sokuluk\,\ Chuy\ region",
"9963536", "Chaek\/Minkush\,\ Naryn\ region",
"9963537", "Baetov\,\ Naryn\ region",
"9963745", "Tash\-Kumyr\,\ Jalal\-Abat\ region",
"9963535", "Kochkor\,\ Naryn\ region",
"99631257", "Bishkek\,\ Chuy\ region",
"9963747", "Toktogul\,\ Jalal\-Abat\ region",
"9963947", "Bokombaevo\/Kadji\-Say\,\ Issyk\-Ko\ region",
"996312970", "Bishkek\,\ Chuy\ region",
"996312974", "Bishkek\,\ Chuy\ region",
"9963945", "Tup\,\ Issyk\-Ko\ region",
"99631293", "Bishkek\,\ Chuy\ region",
"9963126", "Bishkek\,\ Chuy\ region",
"9963138", "Tokmok\,\ Chuy\ region",
"996322", "Osh",
"99631295", "Bishkek\,\ Chuy\ region",
"9963234", "Gulcha\,\ Osh\ region",
"9963127", "Bishkek\,\ Chuy\ region",
"99631251", "Bishkek\,\ Chuy\ region",
"99631256", "Bishkek\,\ Chuy\ region",
"9963946", "Kyzyl\-Suu\,\ Issyk\-Ko\ region",
"99631294", "Bishkek\,\ Chuy\ region",
"99631299", "Bishkek\,\ Chuy\ region",
"99631292", "Bishkek\,\ Chuy\ region",
"9963124", "Bishkek\,\ Chuy\ region",
"9963237", "Daroot\-Korgon\,\ Osh\ region",
"9963748", "Kok\-Jangak\/Suzak\,\ Jalal\-Abat\ region",
"996312977", "Bishkek\,\ Chuy\ region",
"9963944", "Balykchy\,\ Issyk\-Ko\ region",
"996312972", "Bishkek\,\ Chuy\ region",
"9963459", "Pokrovka\,\ Talas\ region",
"9963128", "Bishkek\,\ Chuy\ region",
"9963534", "At\-Bashy\,\ Naryn\ region",
"9963744", "Mailuu\-Suu\,\ Jalal\-Abat\ region",
"99631250", "Bishkek\,\ Chuy\ region",
"9963948", "Ak\-Suu\,\ Issyk\-Ko\ region",
"9963135", "Kemin\,\ Chuy\ region",
"9963137", "Kayndy\,\ Chuy\ region",
"996352", "Naryn",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+996|\D)//g;
      my $self = bless({ country_code => '996', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '996', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;