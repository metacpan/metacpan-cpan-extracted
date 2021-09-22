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
package Number::Phone::StubCountry::AE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210921211828;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            60|
            8
          ',
                  'pattern' => '(\\d{3})(\\d{2,9})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [236]|
            [479][2-8]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[479]',
                  'pattern' => '(\\d{3})(\\d)(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '5',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '[2-4679][2-8]\\d{6}',
                'geographic' => '[2-4679][2-8]\\d{6}',
                'mobile' => '5[024-68]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(700[05]\\d{5})|(900[02]\\d{5})|(600[25]\\d{5})',
                'toll_free' => '
          400\\d{6}|
          800\\d{2,9}
        ',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"97166", "Sharjah\,\ Ajman\,\ Umm\ Al\-Qaiwain",
"97196", "Fujairah",
"97146", "Dubai",
"97176", "Ras\ Alkhaimah",
"97143", "Dubai",
"97147", "Dubai",
"97173", "Ras\ Alkhaimah",
"97195", "Fujairah",
"97177", "Ras\ Alkhaimah",
"97165", "Sharjah\,\ Ajman\,\ Umm\ Al\-Qaiwain",
"97197", "Fujairah",
"97163", "Sharjah\,\ Ajman\,\ Umm\ Al\-Qaiwain",
"97175", "Ras\ Alkhaimah",
"97193", "Fujairah",
"97167", "Sharjah\,\ Ajman\,\ Umm\ Al\-Qaiwain",
"9712", "Abu\ dhabi",
"97145", "Dubai",
"97194", "Fujairah",
"97192", "Fujairah",
"97162", "Sharjah\,\ Ajman\,\ Umm\ Al\-Qaiwain",
"97164", "Sharjah\,\ Ajman\,\ Umm\ Al\-Qaiwain",
"97174", "Ras\ Alkhaimah",
"97172", "Ras\ Alkhaimah",
"97144", "Dubai",
"97142", "Dubai",
"97178", "Ras\ Alkhaimah",
"97148", "Dubai",
"9713", "Al\ Ain",
"97168", "Sharjah\,\ Ajman\,\ Umm\ Al\-Qaiwain",
"97198", "Fujairah",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+971|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;