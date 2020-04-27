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
package Number::Phone::StubCountry::YE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120032;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [1-6]|
            7[24-68]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '7',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          78[0-7]\\d{4}|
          17\\d{6}|
          (?:
            [12][2-68]|
            3[2358]|
            4[2-58]|
            5[2-6]|
            6[3-58]|
            7[24-6]
          )\\d{5}
        ',
                'geographic' => '
          78[0-7]\\d{4}|
          17\\d{6}|
          (?:
            [12][2-68]|
            3[2358]|
            4[2-58]|
            5[2-6]|
            6[3-58]|
            7[24-6]
          )\\d{5}
        ',
                'mobile' => '7[0137]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{9671} = "Sanaa";
$areanames{en}->{96722} = "Aden";
$areanames{en}->{96723} = "Aden";
$areanames{en}->{96724} = "Dhalea";
$areanames{en}->{96725} = "Lahj";
$areanames{en}->{96726} = "Abyan";
$areanames{en}->{967280} = "Aden";
$areanames{en}->{967281} = "Aden";
$areanames{en}->{967282} = "Aden";
$areanames{en}->{967283} = "Aden";
$areanames{en}->{967284} = "Dhalea";
$areanames{en}->{9672840} = "Aden";
$areanames{en}->{967285} = "Lahj";
$areanames{en}->{967286} = "Abyan";
$areanames{en}->{9673} = "Hodaidah";
$areanames{en}->{96742} = "Taiz";
$areanames{en}->{96743} = "Taiz";
$areanames{en}->{967433} = "Ibb";
$areanames{en}->{96744} = "Ibb";
$areanames{en}->{96745} = "Ibb";
$areanames{en}->{967483} = "Taiz";
$areanames{en}->{967484} = "Ibb";
$areanames{en}->{9674840} = "Taiz";
$areanames{en}->{9674841} = "Taiz";
$areanames{en}->{9674842} = "Taiz";
$areanames{en}->{9674843} = "Taiz";
$areanames{en}->{967485} = "Ibb";
$areanames{en}->{96752} = "Shabwah";
$areanames{en}->{96753} = "Hadhrmout";
$areanames{en}->{96754} = "Hadhrmout";
$areanames{en}->{96755} = "Hadhrmout";
$areanames{en}->{967566} = "Soqatrah";
$areanames{en}->{967630} = "Maareb";
$areanames{en}->{967633} = "Maareb";
$areanames{en}->{967634} = "Aljawf";
$areanames{en}->{967636} = "Maareb";
$areanames{en}->{967638} = "Maareb";
$areanames{en}->{967639} = "Dhamar";
$areanames{en}->{96764} = "Dhamar";
$areanames{en}->{967650} = "Dhamar";
$areanames{en}->{967651} = "Dhamar";
$areanames{en}->{967652} = "Al\ Baidha";
$areanames{en}->{967653} = "Al\ Baidha";
$areanames{en}->{967654} = "Al\ Baidha";
$areanames{en}->{967655} = "Al\ Baidha";
$areanames{en}->{967656} = "Al\ Baidha";
$areanames{en}->{967657} = "Al\ Baidha";
$areanames{en}->{967682} = "Dhamar";
$areanames{en}->{967683} = "Maareb";
$areanames{en}->{967684} = "Dhamar";
$areanames{en}->{9676850} = "Al\ Baidha";
$areanames{en}->{9676853} = "Al\ Baidha";
$areanames{en}->{9676860} = "Al\ Baidha";
$areanames{en}->{9676861} = "Dhamar";
$areanames{en}->{9676862} = "Al\ Baidha";
$areanames{en}->{9676863} = "Maareb";
$areanames{en}->{9676864} = "Dhamar";
$areanames{en}->{9676865} = "Dhamar";
$areanames{en}->{9676866} = "Dhamar";
$areanames{en}->{9676867} = "Dhamar";
$areanames{en}->{9676868} = "Al\ Baidha";
$areanames{en}->{9676869} = "Al\ Baidha";
$areanames{en}->{96772} = "Hajjah";
$areanames{en}->{96774} = "Al\ Mahweet";
$areanames{en}->{96775} = "Saadah";
$areanames{en}->{96776} = "Amran";
$areanames{en}->{9677845} = "Al\ Mahweet";
$areanames{en}->{967785} = "Saadah";
$areanames{en}->{967786} = "Amran";
$areanames{en}->{9677870} = "Hajjah";
$areanames{en}->{9677871} = "Hajjah";
$areanames{en}->{9677872} = "Hajjah";
$areanames{en}->{9677873} = "Hajjah";
$areanames{en}->{9677874} = "Al\ Mahweet";
$areanames{en}->{9677875} = "Saadah";
$areanames{en}->{9677876} = "Amran";
$areanames{en}->{9677877} = "Amran";
$areanames{en}->{9677878} = "Saadah";
$areanames{en}->{9677879} = "Al\ Mahweet";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+967|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;