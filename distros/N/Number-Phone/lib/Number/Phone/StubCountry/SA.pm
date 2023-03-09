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
package Number::Phone::StubCountry::SA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230307181422;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '9',
                  'pattern' => '(\\d{4})(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '5',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '81',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          1(?:
            1\\d|
            2[24-8]|
            3[35-8]|
            4[3-68]|
            6[2-5]|
            7[235-7]
          )\\d{6}
        ',
                'geographic' => '
          1(?:
            1\\d|
            2[24-8]|
            3[35-8]|
            4[3-68]|
            6[2-5]|
            7[235-7]
          )\\d{6}
        ',
                'mobile' => '
          579[01]\\d{5}|
          5(?:
            [013-689]\\d|
            7[0-35-8]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(920\\d{6})|(925\\d{6})|(811\\d{7})',
                'toll_free' => '800\\d{7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{ar} = {"96616", "حائل\/القصيم",
"96614", "المدينة\ المنورة\/عرعر\/تبوك\/ينبع\ البحر",
"96617", "أبها\/نجران\/جازان",
"96612", "مكة\/جدة",
"96611", "الرياض\/الخرج",
"96613", "الدمام\/الخبر\/الظهران",};
$areanames{en} = {"96616", "Hail\/Qasim",
"96612", "Makkah\/Jeddah",
"96613", "Dammam\/Khobar\/Dahran",
"96611", "Riyadh\/Kharj",
"96614", "Madenah\/Arar\/Tabuk\/Yanbu",
"96617", "Abha\/Najran\/Jezan",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+966|\D)//g;
      my $self = bless({ country_code => '966', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '966', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;