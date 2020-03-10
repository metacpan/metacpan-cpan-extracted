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
package Number::Phone::StubCountry::VE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200309202349;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '[24-689]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{7})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              12|
              3[457-9]|
              [467]\\d|
              [58][1-9]|
              9[1-6]
            )|
            [4-6]00
          )\\d{7}
        ',
                'geographic' => '
          (?:
            2(?:
              12|
              3[457-9]|
              [467]\\d|
              [58][1-9]|
              9[1-6]
            )|
            [4-6]00
          )\\d{7}
        ',
                'mobile' => '
          4(?:
            1[24-8]|
            2[46]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(90[01]\\d{7})|(501\\d{7})',
                'toll_free' => '800\\d{7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{es}->{5821} = "Distrito\ Capital\/Miranda\/Vargas";
$areanames{es}->{58234} = "Miranda";
$areanames{es}->{58235} = "Anzoátegui\/Bolívar\/Guárico";
$areanames{es}->{58237} = "Dependencias\ Federales";
$areanames{es}->{58238} = "Guárico";
$areanames{es}->{58239} = "Miranda";
$areanames{es}->{58240} = "Apure\/Barinas";
$areanames{es}->{58241} = "Carabobo";
$areanames{es}->{58242} = "Carabobo";
$areanames{es}->{58243} = "Aragua\/Carabobo";
$areanames{es}->{58244} = "Aragua";
$areanames{es}->{58245} = "Carabobo";
$areanames{es}->{58246} = "Aragua\/Guárico";
$areanames{es}->{58247} = "Apure\/Barinas\/Guárico";
$areanames{es}->{58248} = "Amazonas";
$areanames{es}->{58249} = "Carabobo";
$areanames{es}->{58251} = "Lara\/Yaracuy";
$areanames{es}->{58252} = "Lara";
$areanames{es}->{58253} = "Lara\/Yaracuy";
$areanames{es}->{58254} = "Yaracuy";
$areanames{es}->{58255} = "Portuguesa";
$areanames{es}->{58256} = "Portuguesa";
$areanames{es}->{58257} = "Portuguesa";
$areanames{es}->{58258} = "Cojedes";
$areanames{es}->{58259} = "Falcón";
$areanames{es}->{58261} = "Zulia";
$areanames{es}->{58262} = "Zulia";
$areanames{es}->{58263} = "Zulia";
$areanames{es}->{58264} = "Zulia";
$areanames{es}->{58265} = "Zulia";
$areanames{es}->{58266} = "Zulia";
$areanames{es}->{58267} = "Zulia";
$areanames{es}->{58268} = "Falcón";
$areanames{es}->{58269} = "Falcón";
$areanames{es}->{58271} = "Mérida\/Trujillo\/Zulia";
$areanames{es}->{58272} = "Trujillo";
$areanames{es}->{58273} = "Barinas";
$areanames{es}->{58274} = "Mérida";
$areanames{es}->{58275} = "Mérida\/Táchira\/Zulia";
$areanames{es}->{58276} = "Táchira";
$areanames{es}->{58277} = "Mérida\/Táchira";
$areanames{es}->{58278} = "Apure\/Barinas";
$areanames{es}->{58279} = "Falcón";
$areanames{es}->{58281} = "Anzoátegui";
$areanames{es}->{58282} = "Anzoátegui";
$areanames{es}->{58283} = "Anzoátegui";
$areanames{es}->{58284} = "Bolívar";
$areanames{es}->{58285} = "Anzoátegui\/Bolívar";
$areanames{es}->{58286} = "Anzoátegui\/Bolívar";
$areanames{es}->{58287} = "Delta\ Amacuro\/Monagas";
$areanames{es}->{58288} = "Bolívar";
$areanames{es}->{58289} = "Bolívar";
$areanames{es}->{58291} = "Monagas";
$areanames{es}->{58292} = "Anzoátegui\/Monagas";
$areanames{es}->{58293} = "Sucre";
$areanames{es}->{58294} = "Sucre";
$areanames{es}->{58295} = "Nueva\ Esparta";
$areanames{es}->{58296} = "Amazonas";
$areanames{en}->{5821} = "Caracas\/Miranda\/Vargas";
$areanames{en}->{58234} = "Miranda";
$areanames{en}->{58235} = "Anzoátegui\/Bolívar\/Guárico";
$areanames{en}->{58237} = "Federal\ Dependencies";
$areanames{en}->{58238} = "Guárico";
$areanames{en}->{58239} = "Miranda";
$areanames{en}->{58240} = "Apure\/Barinas";
$areanames{en}->{58241} = "Carabobo";
$areanames{en}->{58242} = "Carabobo";
$areanames{en}->{58243} = "Aragua\/Carabobo";
$areanames{en}->{58244} = "Aragua";
$areanames{en}->{58245} = "Carabobo";
$areanames{en}->{58246} = "Aragua\/Guárico";
$areanames{en}->{58247} = "Apure\/Barinas\/Guárico";
$areanames{en}->{58248} = "Amazonas";
$areanames{en}->{58249} = "Carabobo";
$areanames{en}->{58251} = "Lara\/Yaracuy";
$areanames{en}->{58252} = "Lara";
$areanames{en}->{58253} = "Lara\/Yaracuy";
$areanames{en}->{58254} = "Yaracuy";
$areanames{en}->{58255} = "Portuguesa";
$areanames{en}->{58256} = "Portuguesa";
$areanames{en}->{58257} = "Portuguesa";
$areanames{en}->{58258} = "Cojedes";
$areanames{en}->{58259} = "Falcón";
$areanames{en}->{58261} = "Zulia";
$areanames{en}->{58262} = "Zulia";
$areanames{en}->{58263} = "Zulia";
$areanames{en}->{58264} = "Zulia";
$areanames{en}->{58265} = "Zulia";
$areanames{en}->{58266} = "Zulia";
$areanames{en}->{58267} = "Zulia";
$areanames{en}->{58268} = "Falcón";
$areanames{en}->{58269} = "Falcón";
$areanames{en}->{58271} = "Mérida\/Trujillo\/Zulia";
$areanames{en}->{58272} = "Trujillo";
$areanames{en}->{58273} = "Barinas";
$areanames{en}->{58274} = "Mérida";
$areanames{en}->{58275} = "Táchira\/Mérida\/Zulia";
$areanames{en}->{58276} = "Táchira";
$areanames{en}->{58277} = "Táchira\/Mérida";
$areanames{en}->{58278} = "Apure\/Barinas";
$areanames{en}->{58279} = "Falcón";
$areanames{en}->{58281} = "Anzoátegui";
$areanames{en}->{58282} = "Anzoátegui";
$areanames{en}->{58283} = "Anzoátegui";
$areanames{en}->{58284} = "Bolívar";
$areanames{en}->{58285} = "Anzoátegui\/Bolívar";
$areanames{en}->{58286} = "Anzoátegui\/Bolívar";
$areanames{en}->{58287} = "Delta\ Amacuro\/Monagas";
$areanames{en}->{58288} = "Bolívar";
$areanames{en}->{58289} = "Bolívar";
$areanames{en}->{58291} = "Monagas";
$areanames{en}->{58292} = "Anzoátegui\/Monagas";
$areanames{en}->{58293} = "Sucre";
$areanames{en}->{58294} = "Sucre";
$areanames{en}->{58295} = "Nueva\ Esparta";
$areanames{en}->{58296} = "Amazonas";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+58|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;