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
package Number::Phone::StubCountry::AO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200606131956;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[29]',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2\\d(?:
            [0134][25-9]|
            [25-9]\\d
          )\\d{5}
        ',
                'geographic' => '
          2\\d(?:
            [0134][25-9]|
            [25-9]\\d
          )\\d{5}
        ',
                'mobile' => '9[1-49]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{pt}->{24422} = "Luanda";
$areanames{pt}->{244231} = "Cabinda";
$areanames{pt}->{244232} = "Zaire";
$areanames{pt}->{2442321} = "Soyo";
$areanames{pt}->{244233} = "Uíge";
$areanames{pt}->{2442342} = "Bengo";
$areanames{pt}->{2442345} = "Bengo";
$areanames{pt}->{2442346} = "Bengo";
$areanames{pt}->{2442347} = "Bengo";
$areanames{pt}->{2442348} = "Caxito";
$areanames{pt}->{2442349} = "Bengo";
$areanames{pt}->{244235} = "Kwanza\-Norte";
$areanames{pt}->{2442358} = "N\'Dalatando";
$areanames{pt}->{244236} = "Kwanza\-Sul";
$areanames{pt}->{2442363} = "Sumbe";
$areanames{pt}->{2442364} = "Porto\ Amboim";
$areanames{pt}->{244241} = "Huambo";
$areanames{pt}->{244248} = "Bié";
$areanames{pt}->{2442485} = "Kuito";
$areanames{pt}->{244249} = "Cuando\-Cubango";
$areanames{pt}->{2442498} = "Menongue";
$areanames{pt}->{244251} = "Malanje";
$areanames{pt}->{244252} = "Lunda\-Norte";
$areanames{pt}->{2442524} = "Lucapa";
$areanames{pt}->{2442526} = "Dundo";
$areanames{pt}->{2442532} = "Lunda\-Sul";
$areanames{pt}->{2442535} = "Saurimo";
$areanames{pt}->{2442536} = "Lunda\-Sul";
$areanames{pt}->{2442537} = "Lunda\-Sul";
$areanames{pt}->{2442538} = "Lunda\-Sul";
$areanames{pt}->{2442539} = "Lunda\-Sul";
$areanames{pt}->{2442542} = "Moxico";
$areanames{pt}->{2442545} = "Moxico";
$areanames{pt}->{2442546} = "Luena";
$areanames{pt}->{2442547} = "Moxico";
$areanames{pt}->{2442548} = "Moxico";
$areanames{pt}->{2442549} = "Moxico";
$areanames{pt}->{2442612} = "Lubango";
$areanames{pt}->{2442615} = "Huíla";
$areanames{pt}->{2442616} = "Huíla";
$areanames{pt}->{2442617} = "Huíla";
$areanames{pt}->{2442618} = "Huíla";
$areanames{pt}->{2442619} = "Huíla";
$areanames{pt}->{244264} = "Namibe";
$areanames{pt}->{244265} = "Cunene";
$areanames{pt}->{2442652} = "Curoca";
$areanames{pt}->{2442655} = "Ondjiva";
$areanames{pt}->{244272} = "Benguela";
$areanames{pt}->{2442722} = "Lobito";
$areanames{pt}->{2442726} = "Bela\ Vista";
$areanames{pt}->{2442728} = "Baía\ Farta";
$areanames{pt}->{2442729} = "Catumbela";
$areanames{pt}->{2442777} = "Dama\ Universal";
$areanames{en}->{24422} = "Luanda";
$areanames{en}->{244231} = "Cabinda";
$areanames{en}->{244232} = "Zaire";
$areanames{en}->{2442321} = "Soyo";
$areanames{en}->{244233} = "Uige";
$areanames{en}->{2442342} = "Bengo";
$areanames{en}->{2442345} = "Bengo";
$areanames{en}->{2442346} = "Bengo";
$areanames{en}->{2442347} = "Bengo";
$areanames{en}->{2442348} = "Caxito";
$areanames{en}->{2442349} = "Bengo";
$areanames{en}->{244235} = "Cuanza\ Norte";
$areanames{en}->{2442358} = "N\'Dalatando";
$areanames{en}->{244236} = "Cuanza\ Sul";
$areanames{en}->{2442363} = "Sumbe";
$areanames{en}->{2442364} = "Porto\ Amboim";
$areanames{en}->{244241} = "Huambo";
$areanames{en}->{244248} = "Bie";
$areanames{en}->{2442485} = "Kuito";
$areanames{en}->{244249} = "Cuando\ Cubango";
$areanames{en}->{2442498} = "Menongue";
$areanames{en}->{244251} = "Malange";
$areanames{en}->{244252} = "Lunda\ Norte";
$areanames{en}->{2442524} = "Lucapa";
$areanames{en}->{2442526} = "Dundo";
$areanames{en}->{2442532} = "Lunda\ Sul";
$areanames{en}->{2442535} = "Saurimo";
$areanames{en}->{2442536} = "Lunda\ Sul";
$areanames{en}->{2442537} = "Lunda\ Sul";
$areanames{en}->{2442538} = "Lunda\ Sul";
$areanames{en}->{2442539} = "Lunda\ Sul";
$areanames{en}->{2442542} = "Moxico";
$areanames{en}->{2442545} = "Moxico";
$areanames{en}->{2442546} = "Luena";
$areanames{en}->{2442547} = "Moxico";
$areanames{en}->{2442548} = "Moxico";
$areanames{en}->{2442549} = "Moxico";
$areanames{en}->{2442612} = "Lubango";
$areanames{en}->{2442615} = "Huila";
$areanames{en}->{2442616} = "Huila";
$areanames{en}->{2442617} = "Huila";
$areanames{en}->{2442618} = "Huila";
$areanames{en}->{2442619} = "Huila";
$areanames{en}->{244264} = "Namibe";
$areanames{en}->{244265} = "Cunene";
$areanames{en}->{2442652} = "Kuroka";
$areanames{en}->{2442655} = "Ondjiva";
$areanames{en}->{244272} = "Benguela";
$areanames{en}->{2442722} = "Lobito";
$areanames{en}->{2442726} = "Bela\ Vista";
$areanames{en}->{2442728} = "Baia\ Farta";
$areanames{en}->{2442729} = "Catumbela";
$areanames{en}->{2442777} = "Dama\ Universal";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+244|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;