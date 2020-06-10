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
package Number::Phone::StubCountry::CH;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200606131957;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            8[047]|
            90
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            [2-79]|
            81
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4 $5',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2[12467]|
            3[1-4]|
            4[134]|
            5[256]|
            6[12]|
            [7-9]1
          )\\d{7}
        ',
                'geographic' => '
          (?:
            2[12467]|
            3[1-4]|
            4[134]|
            5[256]|
            6[12]|
            [7-9]1
          )\\d{7}
        ',
                'mobile' => '7[35-9]\\d{7}',
                'pager' => '74[0248]\\d{6}',
                'personal_number' => '878\\d{6}',
                'specialrate' => '(84[0248]\\d{6})|(90[016]\\d{6})|(5[18]\\d{7})',
                'toll_free' => '800\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{it}->{4121} = "Losanna";
$areanames{it}->{4122} = "Ginevra";
$areanames{it}->{4124} = "Yverdon\/Aigle";
$areanames{it}->{4126} = "Friburgo";
$areanames{it}->{4127} = "Sion";
$areanames{it}->{4131} = "Berna";
$areanames{it}->{4132} = "Bienne\/Neuchâtel\/Soletta\/Giura";
$areanames{it}->{4133} = "Thun";
$areanames{it}->{4134} = "Burgdorf\/Langnau\ i\.E\.";
$areanames{it}->{4141} = "Lucerna";
$areanames{it}->{4143} = "Zurigo";
$areanames{it}->{4144} = "Zurigo";
$areanames{it}->{4152} = "Winterthur";
$areanames{it}->{4155} = "Rapperswil";
$areanames{it}->{4156} = "Baden";
$areanames{it}->{4161} = "Basilea";
$areanames{it}->{4162} = "Olten";
$areanames{it}->{4171} = "San\ Gallo";
$areanames{it}->{4181} = "Coira";
$areanames{it}->{4191} = "Bellinzona";
$areanames{de}->{4121} = "Lausanne";
$areanames{de}->{4122} = "Genf";
$areanames{de}->{4124} = "Yverdon\/Aigle";
$areanames{de}->{4126} = "Freiburg";
$areanames{de}->{4127} = "Sitten";
$areanames{de}->{4131} = "Bern";
$areanames{de}->{4132} = "Biel\/Neuenburg\/Solothurn\/Jura";
$areanames{de}->{4133} = "Thun";
$areanames{de}->{4134} = "Burgdorf\/Langnau\ i\.E\.";
$areanames{de}->{4141} = "Luzern";
$areanames{de}->{4143} = "Zürich";
$areanames{de}->{4144} = "Zürich";
$areanames{de}->{4152} = "Winterthur";
$areanames{de}->{4155} = "Rapperswil";
$areanames{de}->{4156} = "Baden";
$areanames{de}->{4161} = "Basel";
$areanames{de}->{4162} = "Olten";
$areanames{de}->{4171} = "St\.\ Gallen";
$areanames{de}->{4181} = "Chur";
$areanames{de}->{4191} = "Bellinzona";
$areanames{fr}->{4121} = "Lausanne";
$areanames{fr}->{4122} = "Genève";
$areanames{fr}->{4124} = "Yverdon\/Aigle";
$areanames{fr}->{4126} = "Fribourg";
$areanames{fr}->{4127} = "Sion";
$areanames{fr}->{4131} = "Berne";
$areanames{fr}->{4132} = "Bienne\/Neuchâtel\/Soleure\/Jura";
$areanames{fr}->{4133} = "Thoune";
$areanames{fr}->{4134} = "Burgdorf\/Langnau\ i\.E\.";
$areanames{fr}->{4141} = "Lucerne";
$areanames{fr}->{4143} = "Zurich";
$areanames{fr}->{4144} = "Zurich";
$areanames{fr}->{4152} = "Winterthour";
$areanames{fr}->{4155} = "Rapperswil";
$areanames{fr}->{4156} = "Baden";
$areanames{fr}->{4161} = "Bâle";
$areanames{fr}->{4162} = "Olten";
$areanames{fr}->{4171} = "St\.\ Gall";
$areanames{fr}->{4181} = "Coire";
$areanames{fr}->{4191} = "Bellinzona";
$areanames{en}->{4121} = "Lausanne";
$areanames{en}->{4122} = "Geneva";
$areanames{en}->{4124} = "Yverdon\/Aigle";
$areanames{en}->{4126} = "Fribourg";
$areanames{en}->{4127} = "Sion";
$areanames{en}->{4131} = "Berne";
$areanames{en}->{4132} = "Bienne\/Neuchâtel\/Soleure\/Jura";
$areanames{en}->{4133} = "Thun";
$areanames{en}->{4134} = "Burgdorf\/Langnau\ i\.E\.";
$areanames{en}->{4141} = "Lucerne";
$areanames{en}->{4143} = "Zurich";
$areanames{en}->{4144} = "Zurich";
$areanames{en}->{4152} = "Winterthur";
$areanames{en}->{4155} = "Rapperswil";
$areanames{en}->{4156} = "Baden";
$areanames{en}->{4161} = "Basel";
$areanames{en}->{4162} = "Olten";
$areanames{en}->{4171} = "St\.\ Gallen";
$areanames{en}->{4181} = "Chur";
$areanames{en}->{4191} = "Bellinzona";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+41|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;