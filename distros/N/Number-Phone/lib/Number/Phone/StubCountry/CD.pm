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
package Number::Phone::StubCountry::CD;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200904144528;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '88',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[1-6]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[89]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          12\\d{7}|
          [1-6]\\d{6}
        ',
                'geographic' => '
          12\\d{7}|
          [1-6]\\d{6}
        ',
                'mobile' => '
          88\\d{5}|
          (?:
            8[0-2459]|
            9[017-9]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{2431} = "Kinshasa";
$areanames{en}->{2432} = "Katanga";
$areanames{en}->{2433} = "Bas\-Congo\/Bandundu";
$areanames{en}->{2434} = "Kasai\-Oriental\/Kasai\-Occidental";
$areanames{en}->{2435} = "Oriental\ Province\ \(Kisanga\/Mbandaka\)";
$areanames{en}->{2436} = "North\ Kivu\/South\ Kivu\/Maniema";
$areanames{fr}->{2431} = "Kinshasa";
$areanames{fr}->{2432} = "Katanga";
$areanames{fr}->{2433} = "Bas\-Congo\/Bandundu";
$areanames{fr}->{2434} = "Kasai\-Oriental\/Kasai\-Occidental";
$areanames{fr}->{2435} = "Province\ Orientale\ \(Kisanga\/Mbandaka\)";
$areanames{fr}->{2436} = "Nord\-Kivu\/Sud\-Kivu\/Maniema";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+243|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;