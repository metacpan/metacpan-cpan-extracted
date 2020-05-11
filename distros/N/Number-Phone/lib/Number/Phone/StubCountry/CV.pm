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
package Number::Phone::StubCountry::CV;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200511123713;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-589]',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            2[1-7]|
            3[0-8]|
            4[12]|
            5[1256]|
            6\\d|
            7[1-3]|
            8[1-5]
          )\\d{4}
        ',
                'geographic' => '
          2(?:
            2[1-7]|
            3[0-8]|
            4[12]|
            5[1256]|
            6\\d|
            7[1-3]|
            8[1-5]
          )\\d{4}
        ',
                'mobile' => '
          (?:
            [34][36]|
            5[1-389]|
            9\\d
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '800\\d{4}',
                'voip' => ''
              };
my %areanames = ();
$areanames{pt}->{238221} = "Ribeira\ Grande\,\ Santo\ Antão";
$areanames{pt}->{238222} = "Porto\ Novo\,\ Santo\ Antão";
$areanames{pt}->{238223} = "Paúl\,\ Santo\ Antão";
$areanames{pt}->{238224} = "Cocoli\,\ Santo\ Antão";
$areanames{pt}->{238225} = "Ponta\ do\ Sol\,\ Santo\ Antão";
$areanames{pt}->{238226} = "Chã\ da\ Igreja\,\ Santo\ Antão";
$areanames{pt}->{238227} = "Ribeira\ das\ Patas\,\ Santo\ Antão";
$areanames{pt}->{238230} = "Mindelo\,\ São\ Vicente";
$areanames{pt}->{238231} = "Mindelo\,\ São\ Vicente";
$areanames{pt}->{238232} = "Mindelo\,\ São\ Vicente";
$areanames{pt}->{238235} = "Ribeira\ Brava\,\ São\ Nicolau";
$areanames{pt}->{238236} = "Tarrafal\ de\ São\ Nicolau\,\ São\ Nicolau";
$areanames{pt}->{238237} = "Fajã\,\ São\ Nicolau";
$areanames{pt}->{238238} = "Praia\ Branca\,\ São\ Nicolau";
$areanames{pt}->{238241} = "Espargos\,\ Sal";
$areanames{pt}->{238242} = "Santa\ Maria\,\ Sal";
$areanames{pt}->{238251} = "Sal\ Rei\,\ Boa\ Vista";
$areanames{pt}->{238252} = "Funda\ das\ Figueiras\,\ Boa\ Vista";
$areanames{pt}->{238255} = "Vila\ do\ Maio\,\ Maio";
$areanames{pt}->{238256} = "Calheta\,\ Maio";
$areanames{pt}->{238260} = "Praia\,\ Santiago";
$areanames{pt}->{238261} = "Praia\,\ Santiago";
$areanames{pt}->{238262} = "Praia\,\ Santiago";
$areanames{pt}->{238263} = "Praia\,\ Santiago";
$areanames{pt}->{238264} = "Praia\,\ Santiago";
$areanames{pt}->{238265} = "Santa\ Catarina\,\ Santiago";
$areanames{pt}->{238266} = "Tarrafal\,\ Santiago";
$areanames{pt}->{238267} = "Cidade\ Velha\,\ Santiago";
$areanames{pt}->{238268} = "São\ Domingos\,\ Santiago";
$areanames{pt}->{238269} = "Pedra\ Badejo\,\ Santiago";
$areanames{pt}->{238271} = "São\ Lourenço\ dos\ Órgãos\/São\ Jorge\,\ Santiago";
$areanames{pt}->{238272} = "Picos\,\ Santiago";
$areanames{pt}->{238273} = "Calheta\ de\ São\ Miguel\,\ Santiago";
$areanames{pt}->{238281} = "São\ Filipe\,\ Fogo";
$areanames{pt}->{238282} = "Cova\ Figueira\,\ Fogo";
$areanames{pt}->{238283} = "Mosteiros\,\ Fogo";
$areanames{pt}->{238284} = "São\ Jorge\,\ Fogo";
$areanames{pt}->{238285} = "Nova\ Sintra\,\ Brava";
$areanames{en}->{238221} = "Ribeira\ Grande\,\ Santo\ Antão";
$areanames{en}->{238222} = "Porto\ Novo\,\ Santo\ Antão";
$areanames{en}->{238223} = "Paúl\,\ Santo\ Antão";
$areanames{en}->{238224} = "Cocoli\,\ Santo\ Antão";
$areanames{en}->{238225} = "Ponta\ do\ Sol\,\ Santo\ Antão";
$areanames{en}->{238226} = "Chã\ da\ Igreja\,\ Santo\ Antão";
$areanames{en}->{238227} = "Ribeira\ das\ Patas\,\ Santo\ Antão";
$areanames{en}->{238230} = "Mindelo\,\ São\ Vicente";
$areanames{en}->{238231} = "Mindelo\,\ São\ Vicente";
$areanames{en}->{238232} = "Mindelo\,\ São\ Vicente";
$areanames{en}->{238235} = "Ribeira\ Brava\,\ São\ Nicolau";
$areanames{en}->{238236} = "Tarrafal\ de\ São\ Nicolau\,\ São\ Nicolau";
$areanames{en}->{238237} = "Fajã\,\ São\ Nicolau";
$areanames{en}->{238238} = "Praia\ Branca\,\ São\ Nicolau";
$areanames{en}->{238241} = "Espargos\,\ Sal";
$areanames{en}->{238242} = "Santa\ Maria\,\ Sal";
$areanames{en}->{238251} = "Sal\ Rei\,\ Boa\ Vista";
$areanames{en}->{238252} = "Funda\ das\ Figueiras\,\ Boa\ Vista";
$areanames{en}->{238255} = "Vila\ do\ Maio\,\ Maio";
$areanames{en}->{238256} = "Calheta\,\ Maio";
$areanames{en}->{238260} = "Praia\,\ Santiago";
$areanames{en}->{238261} = "Praia\,\ Santiago";
$areanames{en}->{238262} = "Praia\,\ Santiago";
$areanames{en}->{238263} = "Praia\,\ Santiago";
$areanames{en}->{238264} = "Praia\,\ Santiago";
$areanames{en}->{238265} = "Santa\ Catarina\,\ Santiago";
$areanames{en}->{238266} = "Tarrafal\,\ Santiago";
$areanames{en}->{238267} = "Cidade\ Velha\,\ Santiago";
$areanames{en}->{238268} = "São\ Domingos\,\ Santiago";
$areanames{en}->{238269} = "Pedra\ Badejo\,\ Santiago";
$areanames{en}->{238271} = "São\ Lourenço\ dos\ Órgãos\/São\ Jorge\,\ Santiago";
$areanames{en}->{238272} = "Picos\,\ Santiago";
$areanames{en}->{238273} = "Calheta\ de\ São\ Miguel\,\ Santiago";
$areanames{en}->{238281} = "São\ Filipe\,\ Fogo";
$areanames{en}->{238282} = "Cova\ Figueira\,\ Fogo";
$areanames{en}->{238283} = "Mosteiros\,\ Fogo";
$areanames{en}->{238284} = "São\ Jorge\,\ Fogo";
$areanames{en}->{238285} = "Nova\ Sintra\,\ Brava";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+238|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;