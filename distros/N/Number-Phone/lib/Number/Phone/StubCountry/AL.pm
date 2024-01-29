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
package Number::Phone::StubCountry::AL;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20231210185942;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            80|
            9
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '4[2-6]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [2358][2-5]|
            4
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[23578]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '6',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          4505[0-2]\\d{3}|
          (?:
            [2358][16-9]\\d[2-9]|
            4410
          )\\d{4}|
          (?:
            [2358][2-5][2-9]|
            4(?:
              [2-57-9][2-9]|
              6\\d
            )
          )\\d{5}
        ',
                'geographic' => '
          4505[0-2]\\d{3}|
          (?:
            [2358][16-9]\\d[2-9]|
            4410
          )\\d{4}|
          (?:
            [2358][2-5][2-9]|
            4(?:
              [2-57-9][2-9]|
              6\\d
            )
          )\\d{5}
        ',
                'mobile' => '
          6(?:
            [78][2-9]|
            9\\d
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '700[2-9]\\d{4}',
                'specialrate' => '(808[1-9]\\d\\d)|(900[1-9]\\d\\d)',
                'toll_free' => '800\\d{4}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"355814", "Tepelenë",
"355865", "Gorë\/Pirg\/Moglicë\,\ Korçë",
"355374", "Gradishtë\/Kolonjë\,\ Lushnjë",
"355398", "Sevaster\/Brataj\/Hore\-Vranisht\,\ Vlorë",
"35584", "Gjirokastër",
"355367", "Perondi\/Kozarë\,\ Kuçovë",
"355283", "Kolsh\/Zejmen\/Shënkoll\,\ Lezhë",
"355571", "Shijak\,\ Durrës",
"355863", "Drenovë\/Mollaj\,\ Korçë",
"35544", "Tirana",
"355285", "Kthjellë\/Selitë\,\ Mirditë",
"355218", "Peshkopi",
"35532", "Berat",
"355886", "Qendër\/Kurvelesh\/Lopëz\,\ Tepelenë",
"355513", "Gramsh",
"355892", "Aliko\/Lukovë\,\ Sarandë",
"355564", "Nikël\/Bubq\,\ Kruje",
"355588", "Rrasë\/Fierzë\/Kajan\/Grekan\,\ Elbasan",
"355272", "Qerret\/Qelëz\/Gjegjan\,\ Pukë",
"355361", "Ura\ Vajgurore\,\ Berat",
"355577", "Rrogozhinë\,\ Kavajë",
"35549", "Petrelë\/Baldushk\/Bërzhitë\/Krrabë\/Shengjergj\/Zall\-Bastar\,\ Tiranë",
"355266", "Bushat\/Bërdicë\,\ Shkodër",
"355389", "Dermenas\/Topojë\,\ Fier",
"355369", "Qendër\/Vendreshë\,\ Skrapar",
"355286", "Kaçinar\/Orosh\/Fan\,\ Mirditë",
"355860", "Trebinjë\/Proptisht\/Velçan\,\ Pogradec",
"35547", "Kamëz\/Vorë\/Paskuqan\/Zall\-Herr\/Burxullë\/Prezë\,\ Tiranë",
"355597", "Kodovjat\/Poroçan\/Kukur\/Lenie\,\ Gramsh",
"355381", "Patos\,\ Fier",
"355292", "Maqellarë\/Melan\,\ Dibër",
"355584", "Labinot\-Fushë\/Labinot\-Mal\/Funarë\/Gracen\,\ Elbasan",
"355872", "Qendër\ Ersekë\/Mollas\/Çlirim\,\ Kolonjë",
"355312", "Çorovodë\,\ Skrapar",
"355866", "Libonik\/Vreshtaz\,\ Korçë",
"355214", "Krumë",
"355265", "Vig\-Mnelë\/Hajmel\,\ Shkodër",
"35555", "Kavajë",
"355883", "Lunxheri\/Odrie\/Zagorie\/Pogon\,\ Gjirokastër",
"35524", "Kukës",
"355591", "Përrenjas\,\ Librazhd",
"355387", "Cakran\/Frakull\,\ Fier",
"355263", "Pult\/Shalë\/Shosh\/Temal\/Shllak\,\ Shkodër",
"355394", "Qendër\,\ Vlorë",
"355378", "Aranitas\/Ngracan\/Selitë\/Fratar\/Kutë\,\ Mallakastër",
"355885", "Memaliaj\,\ Tepelenë",
"355579", "Luz\ i\ Vogël\/Kryevidh\/Helmës\,\ Kavajë",
"35535", "Lushnje",
"355862", "Qendër\,\ Korçë",
"355876", "Qendër\/Frashër\/Petran\/Çarshovë\,\ Përmet",
"355211", "Koplik",
"355296", "Fushë\-Bulqizë\/Shupenzë\/Zerqan\,\ Bulqizë",
"355282", "Kallmet\/Blinisht\/Dajç\/Ungrej\,\ Lezhë",
"355578", "Synej\/Golem\,\ Kavajë",
"355594", "Hotolisht\/Polis\/Stravaj\,\ Librazhd",
"355587", "Gostime\/Klos\/Mollas\,\ Elbasan",
"35546", "Tirana",
"355391", "Orikum\,\ Vlorë",
"355368", "Poliçan\/Bogovë\,\ Skrapar",
"355384", "Mbrostar\ Ura\/LIibofshë\,\ Fier",
"355895", "Finiq\/Mesopotam\/Vergo\,\ Delvinë",
"355581", "Cërrik\,\ Elbasan",
"355397", "Vllahinë\/Kote\,\ Vlorë",
"355273", "Iballë\/Fierzë\/Blerim\/Qafë\-Mali\,\ Pukë",
"355217", "Burrel",
"355512", "Peqin",
"355893", "Ksamil\,\ Sarandë",
"355275", "Bujan\/Fierzë\/Bytyc\/Lekbiba\,\ Tropojë",
"355295", "Sllovë\/Zall\-Dardhë\/Zall\-Reç\/Kala\ e\ Dodes\,\ Dibër",
"355873", "Qendër\ Bilisht\/Progër\,\ Devoll",
"35583", "Pogradec",
"355313", "Ballsh\,\ Mallakastër",
"35552", "Durrës",
"355589", "Karinë\/Gjocaj\/Shezë\,\ Peqin",
"35543", "Tirana",
"355377", "Qendër\/Greshicë\/Hekal\,\ Mallakastër",
"355293", "Kastriot\/Muhur\/Selishtë\,\ Dibër",
"355561", "Mamurras\,\ Kurbin",
"355875", "Këlcyrë\,\ Përmet",
"355388", "Levan\,\ Fier",
"355364", "Vërtop\/Terpan\,\ Berat",
"355371", "Divjakë\,\ Lushnjë",
"35548", "Kashar\/Vaqar\/Ndroq\/Pezë\/Farkë\/Dajt\,\ Tiranë",
"355574", "Rashbull\/Gjepalaj\,\ Durrës",
"355262", "Rrethinat\/Ana\-Malit\,\ Shkodër",
"355276", "Fajza\/Golaj\/Gjinaj\,\ Has",
"355811", "Bilisht\,\ Devoll",
"355270", "Kolsh\/Surroj\/Arren\/Malzi\,\ Kukës",
"355882", "Cepo\/Picar\/Lazarat\/Atigon\,\ Gjirokastër",
"355219", "Bulqizë",
"355563", "Fushë\-Krujë",
"355291", "Tomin\/Luzni\,\ Dibër",
"355382", "Roskovec\,\ Fier",
"355279", "Gryk\-Çajë\/Ujmisht\/Bushtrice\/Kalis\,\ Kukës",
"355396", "Shushicë\/Armen\,\ Vlorë",
"355514", "Librazhd",
"355311", "Kuçovë",
"355565", "Koder\-Thumane\/Cudhi\,\ Kruje",
"35554", "Elbasan",
"355216", "Rrëshen",
"355871", "Leskovik\/Barmash\/Novoselë\,\ Kolonjë",
"355864", "Voskop\/Voskopojë\/Vithkuq\/Lekas\,\ Korçë",
"355375", "Golem\/Grabian\/Remas\,\ Lushnjë",
"355877", "Dishnicë\/Sukë\/Ballaban\,\ Përmet",
"355580", "Përparim\/Pajovë\,\ Peqin",
"355815", "Delvinë",
"355586", "Gjergjan\/Papër\/Shalës\,\ Elbasan",
"355813", "Përmet",
"35533", "Vlorë",
"355373", "Krutje\/Bubullimë\/Allkaj\,\ Lushnjë",
"355297", "Gjorice\/Ostren\/Trebisht\/Martanesh\,\ Bulqizë",
"355284", "Rubik\,\ Mirditë",
"355268", "Qendër\/Gruemirë\,\ Malësi\ e\ Madhe",
"355592", "Qendër\,\ Librazhd",
"355572", "Manëz\,\ Durrës",
"355288", "Baz\/Komsi\/Gurrë\/Xibër\,\ Mat",
"355264", "Postribë\/Gur\ i\ Zi",
"355277", "Shtiqen\/Tërthore\/Zapod\,\ Kukës",
"355393", "Himarë\,\ Vlorë",
"355215", "Lezhë",
"355213", "Bajram\ Curri",
"355395", "Novoselë\,\ Vlorë",
"355884", "Dropull\ i\ Poshtëm\/Dropull\ i\ Sipërm\,\ Gjirokastër",
"355868", "Buçimas\/Udenisht\,\ Pogradec",
"355891", "Konispol\/Xare\/Markat\,\ Sarandë",
"35545", "Tirana",
"355585", "Shushicë\/Tregan\/Gjinar\/Zavalinë\,\ Elbasan",
"355376", "Dushk\/Tërbuf\,\ Lushnjë",
"355362", "Velabisht\/Roshnik\,\ Berat",
"355271", "Fushë\-Arrëz\/Rrapë\,\ Pukë",
"35585", "Sarandë",
"355583", "Bradashesh\/Shirgjan\,\ Elbasan",
"355570", "Gosë\/Lekaj\/Sinaballaj\,\ Kavajë",
"355385", "Portëz\/Zharëz\,\ Fier",
"355894", "Livadhja\/Dhivër\,\ Sarandë",
"355887", "Qesarat\/Krahës\/Luftinje\/Buz\,\ Tepelenë",
"355267", "Dajç\/Velipojë\,\ Shkodër",
"355383", "Qendër\,\ Fier",
"355562", "Milot\/Fushe\-Kuqe\,\ Kurbin",
"355274", "Tropojë\/Llugaj\/Margegaj\,\ Tropojë",
"355576", "Katund\ i\ Ri\/Ishem\,\ Durrës",
"355366", "Poshnjë\/Kutalli\,\ Berat",
"355289", "Ulëz\/Rukaj\/Derjan\/Macukull\,\ Mat",
"355812", "Ersekë\,\ Kolonjë",
"355261", "Vau\-Dejës",
"355593", "Lunik\/Orenjë\/Stebleve\,\ Librazhd",
"355372", "Karbunarë\/Fier\-Shegan\/Hysgjokaj\/Ballagat\,\ Lushnjë",
"355595", "Qukës\/Rajcë\,\ Librazhd",
"355881", "Libohovë\/Qendër\,\ Gjirokastër",
"355360", "Leshnje\/Potom\/Çepan\/Gjerbës\/Zhepë\,\ Skrapar",
"35522", "Shkodër",
"355869", "Çëravë\/Dardhas\,\ Pogradec",
"35542", "Tirana",
"355212", "Pukë",
"355861", "Maliq\,\ Korçë",
"355575", "Xhafzotaj\/Maminas\,\ Durrës",
"355392", "Selenicë\,\ Vlorë",
"355573", "Sukth\,\ Durrës",
"355281", "Shëngjin\/Balldre\,\ Lezhë",
"35553", "Laç\,\ Kurbin",
"355269", "Kastrat\/Shkrel\/Kelmend\,\ Malësi\ e\ Madhe",
"355386", "Kuman\/Kurjan\/Strum\/Ruzhdie\,\ Fier",
"35582", "Korçë",
"355596", "Pishaj\/Sult\/Tunjë\/Kushovë\/Skënderbegas\,\ Gramsh",
"355278", "Bicaj\/Topojan\/Shishtavec\,\ Kukës",
"355294", "Arras\/Fushë\-Çidhën\/Lurë\,\ Dibër",
"355582", "Belsh\,\ Elbasan",
"355287", "Klos\/Suç\/Lis\,\ Mat",
"355363", "Otllak\/Lumas\,\ Berat",
"355867", "Pojan\/Liqenas\,\ Korçë",
"35534", "Fier",
"355874", "Hoçisht\/Miras\,\ Devoll",
"355365", "Sinjë\/Cukalat\,\ Berat",
"355511", "Kruje",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+355|\D)//g;
      my $self = bless({ country_code => '355', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '355', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;