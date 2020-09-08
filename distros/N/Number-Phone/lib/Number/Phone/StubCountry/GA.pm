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
package Number::Phone::StubCountry::GA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200904144532;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[2-7]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            11|
            [67]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '[01]1\\d{6}',
                'geographic' => '[01]1\\d{6}',
                'mobile' => '
          (?:
            0[2-7]|
            6[256]|
            7[47]
          )\\d{6}|
          [2-7]\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{2410140} = "Kango";
$areanames{en}->{24101420} = "Ntoum";
$areanames{en}->{24101424} = "Cocobeach";
$areanames{en}->{2410144} = "Libreville";
$areanames{en}->{2410145} = "Libreville";
$areanames{en}->{2410146} = "Libreville";
$areanames{en}->{2410147} = "Libreville";
$areanames{en}->{2410148} = "Libreville";
$areanames{en}->{2410150} = "Gamba";
$areanames{en}->{2410154} = "Omboué";
$areanames{en}->{2410155} = "Port\-Gentil";
$areanames{en}->{2410156} = "Port\-Gentil";
$areanames{en}->{2410158} = "Lambaréné";
$areanames{en}->{2410159} = "Ndjolé";
$areanames{en}->{2410160} = "Ngouoni";
$areanames{en}->{2410162} = "Mounana";
$areanames{en}->{2410164} = "Lastoursville";
$areanames{en}->{2410165} = "Koulamoutou";
$areanames{en}->{2410166} = "Moanda";
$areanames{en}->{2410167} = "Franceville";
$areanames{en}->{2410169} = "Léconi\/Akiéni\/Okondja";
$areanames{en}->{241017} = "Libreville";
$areanames{en}->{2410182} = "Tchibanga";
$areanames{en}->{2410183} = "Mayumba";
$areanames{en}->{2410186} = "Mouila";
$areanames{en}->{2410190} = "Makokou";
$areanames{en}->{2410192} = "Mékambo";
$areanames{en}->{2410193} = "Booué";
$areanames{en}->{2410196} = "Bitam";
$areanames{en}->{2410198} = "Oyem";
$areanames{en}->{2411140} = "Kango";
$areanames{en}->{24111420} = "Ntoum";
$areanames{en}->{24111424} = "Cocobeach";
$areanames{en}->{2411144} = "Libreville";
$areanames{en}->{2411145} = "Libreville";
$areanames{en}->{2411146} = "Libreville";
$areanames{en}->{2411147} = "Libreville";
$areanames{en}->{2411148} = "Libreville";
$areanames{en}->{2411150} = "Gamba";
$areanames{en}->{2411154} = "Omboué";
$areanames{en}->{2411155} = "Port\-Gentil";
$areanames{en}->{2411156} = "Port\-Gentil";
$areanames{en}->{2411158} = "Lambaréné";
$areanames{en}->{2411159} = "Ndjolé";
$areanames{en}->{2411160} = "Ngouoni";
$areanames{en}->{2411162} = "Mounana";
$areanames{en}->{2411164} = "Lastoursville";
$areanames{en}->{2411165} = "Koulamoutou";
$areanames{en}->{2411166} = "Moanda";
$areanames{en}->{2411167} = "Franceville";
$areanames{en}->{2411169} = "Léconi\/Akiéni\/Okondja";
$areanames{en}->{241117} = "Libreville";
$areanames{en}->{2411182} = "Tchibanga";
$areanames{en}->{2411183} = "Mayumba";
$areanames{en}->{2411186} = "Mouila";
$areanames{en}->{2411190} = "Makokou";
$areanames{en}->{2411192} = "Mékambo";
$areanames{en}->{2411193} = "Booué";
$areanames{en}->{2411196} = "Bitam";
$areanames{en}->{2411198} = "Oyem";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+241|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      my $prefix = qr/^(?:0(11\d{6}|6[256]\d{6}|7[47]\d{6}))/;
      my @matches = $number =~ /$prefix/;
      if (defined $matches[-1]) {
        no warnings 'uninitialized';
        $number =~ s/$prefix/$1/;
      }
      else {
        $number =~ s/$prefix//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;