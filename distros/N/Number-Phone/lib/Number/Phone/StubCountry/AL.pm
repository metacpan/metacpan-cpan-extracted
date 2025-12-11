# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20251210153518;

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
$areanames{en} = {"355588", "Rrasë\/Fierzë\/Kajan\/Grekan\,\ Elbasan",
"355283", "Kolsh\/Zejmen\/Shënkoll\,\ Lezhë",
"35542", "Tirana",
"355211", "Koplik",
"355597", "Kodovjat\/Poroçan\/Kukur\/Lenie\,\ Gramsh",
"355271", "Fushë\-Arrëz\/Rrapë\,\ Pukë",
"355884", "Dropull\ i\ Poshtëm\/Dropull\ i\ Sipërm\,\ Gjirokastër",
"35555", "Kavajë",
"355867", "Pojan\/Liqenas\,\ Korçë",
"355863", "Drenovë\/Mollaj\,\ Korçë",
"355368", "Poliçan\/Bogovë\,\ Skrapar",
"35552", "Durrës",
"355860", "Trebinjë\/Proptisht\/Velçan\,\ Pogradec",
"355372", "Karbunarë\/Fier\-Shegan\/Hysgjokaj\/Ballagat\,\ Lushnjë",
"355593", "Lunik\/Orenjë\/Stebleve\,\ Librazhd",
"35545", "Tirana",
"355394", "Qendër\,\ Vlorë",
"355312", "Çorovodë\,\ Skrapar",
"355575", "Xhafzotaj\/Maminas\,\ Durrës",
"355386", "Kuman\/Kurjan\/Strum\/Ruzhdie\,\ Fier",
"35534", "Fier",
"355287", "Klos\/Suç\/Lis\,\ Mat",
"355264", "Postribë\/Gur\ i\ Zi",
"355311", "Kuçovë",
"355279", "Gryk\-Çajë\/Ujmisht\/Bushtrice\/Kalis\,\ Kukës",
"355383", "Qendër\,\ Fier",
"355866", "Libonik\/Vreshtaz\,\ Korçë",
"355584", "Labinot\-Fushë\/Labinot\-Mal\/Funarë\/Gracen\,\ Elbasan",
"35585", "Sarandë",
"355371", "Divjakë\,\ Lushnjë",
"35547", "Kamëz\/Vorë\/Paskuqan\/Zall\-Herr\/Burxullë\/Prezë\,\ Tiranë",
"355596", "Pishaj\/Sult\/Tunjë\/Kushovë\/Skënderbegas\,\ Gramsh",
"355219", "Bulqizë",
"355893", "Ksamil\,\ Sarandë",
"355815", "Delvinë",
"355272", "Qerret\/Qelëz\/Gjegjan\,\ Pukë",
"355398", "Sevaster\/Brataj\/Hore\-Vranisht\,\ Vlorë",
"35582", "Korçë",
"355268", "Qendër\/Gruemirë\,\ Malësi\ e\ Madhe",
"355563", "Fushë\-Krujë",
"355364", "Vërtop\/Terpan\,\ Berat",
"355286", "Kaçinar\/Orosh\/Fan\,\ Mirditë",
"355387", "Cakran\/Frakull\,\ Fier",
"35524", "Kukës",
"355875", "Këlcyrë\,\ Përmet",
"355212", "Pukë",
"355294", "Arras\/Fushë\-Çidhën\/Lurë\,\ Dibër",
"355877", "Dishnicë\/Sukë\/Ballaban\,\ Përmet",
"355391", "Orikum\,\ Vlorë",
"35549", "Petrelë\/Baldushk\/Bërzhitë\/Krrabë\/Shengjergj\/Zall\-Bastar\,\ Tiranë",
"355576", "Katund\ i\ Ri\/Ishem\,\ Durrës",
"355261", "Vau\-Dejës",
"355385", "Portëz\/Zharëz\,\ Fier",
"355369", "Qendër\/Vendreshë\,\ Skrapar",
"355582", "Belsh\,\ Elbasan",
"355274", "Tropojë\/Llugaj\/Margegaj\,\ Tropojë",
"355813", "Përmet",
"355895", "Finiq\/Mesopotam\/Vergo\,\ Delvinë",
"355565", "Koder\-Thumane\/Cudhi\,\ Kruje",
"355881", "Libohovë\/Qendër\,\ Gjirokastër",
"355589", "Karinë\/Gjocaj\/Shezë\,\ Peqin",
"35583", "Pogradec",
"355362", "Velabisht\/Roshnik\,\ Berat",
"355214", "Krumë",
"355378", "Aranitas\/Ngracan\/Selitë\/Fratar\/Kutë\,\ Mallakastër",
"355873", "Qendër\ Bilisht\/Progër\,\ Devoll",
"355292", "Maqellarë\/Melan\,\ Dibër",
"355285", "Kthjellë\/Selitë\,\ Mirditë",
"35546", "Tirana",
"355361", "Ura\ Vajgurore\,\ Berat",
"355577", "Rrogozhinë\,\ Kavajë",
"355876", "Qendër\/Frashër\/Petran\/Çarshovë\,\ Përmet",
"355291", "Tomin\/Luzni\,\ Dibër",
"35543", "Tirana",
"355882", "Cepo\/Picar\/Lazarat\/Atigon\,\ Gjirokastër",
"355269", "Kastrat\/Shkrel\/Kelmend\,\ Malësi\ e\ Madhe",
"355581", "Cërrik\,\ Elbasan",
"355865", "Gorë\/Pirg\/Moglicë\,\ Korçë",
"355513", "Gramsh",
"355595", "Qukës\/Rajcë\,\ Librazhd",
"355218", "Peshkopi",
"355374", "Gradishtë\/Kolonjë\,\ Lushnjë",
"355573", "Sukth\,\ Durrës",
"355392", "Selenicë\,\ Vlorë",
"355278", "Bicaj\/Topojan\/Shishtavec\,\ Kukës",
"355570", "Gosë\/Lekaj\/Sinaballaj\,\ Kavajë",
"355262", "Rrethinat\/Ana\-Malit\,\ Shkodër",
"35553", "Laç\,\ Kurbin",
"355868", "Buçimas\/Udenisht\,\ Pogradec",
"35522", "Shkodër",
"355360", "Leshnje\/Potom\/Çepan\/Gjerbës\/Zhepë\,\ Skrapar",
"355363", "Otllak\/Lumas\,\ Berat",
"355872", "Qendër\ Ersekë\/Mollas\/Çlirim\,\ Kolonjë",
"355215", "Lezhë",
"355293", "Kastriot\/Muhur\/Selishtë\,\ Dibër",
"355812", "Ersekë\,\ Kolonjë",
"355275", "Bujan\/Fierzë\/Bytyc\/Lekbiba\,\ Tropojë",
"355894", "Livadhja\/Dhivër\,\ Sarandë",
"35584", "Gjirokastër",
"355564", "Nikël\/Bubq\,\ Kruje",
"355886", "Qendër\/Kurvelesh\/Lopëz\,\ Tepelenë",
"355587", "Gostime\/Klos\/Mollas\,\ Elbasan",
"355583", "Bradashesh\/Shirgjan\,\ Elbasan",
"355288", "Baz\/Komsi\/Gurrë\/Xibër\,\ Mat",
"355580", "Përparim\/Pajovë\,\ Peqin",
"355511", "Kruje",
"355571", "Shijak\,\ Durrës",
"355297", "Gjorice\/Ostren\/Trebisht\/Martanesh\,\ Bulqizë",
"355396", "Shushicë\/Armen\,\ Vlorë",
"355384", "Mbrostar\ Ura\/LIibofshë\,\ Fier",
"355367", "Perondi\/Kozarë\,\ Kuçovë",
"355266", "Bushat\/Bërdicë\,\ Shkodër",
"355572", "Manëz\,\ Durrës",
"355393", "Himarë\,\ Vlorë",
"355263", "Pult\/Shalë\/Shosh\/Temal\/Shllak\,\ Shkodër",
"35532", "Berat",
"355864", "Voskop\/Voskopojë\/Vithkuq\/Lekas\,\ Korçë",
"355586", "Gjergjan\/Papër\/Shalës\,\ Elbasan",
"35554", "Elbasan",
"355887", "Qesarat\/Krahës\/Luftinje\/Buz\,\ Tepelenë",
"355594", "Hotolisht\/Polis\/Stravaj\,\ Librazhd",
"355512", "Peqin",
"355375", "Golem\/Grabian\/Remas\,\ Lushnjë",
"355579", "Luz\ i\ Vogël\/Kryevidh\/Helmës\,\ Kavajë",
"355811", "Bilisht\,\ Devoll",
"355388", "Levan\,\ Fier",
"355883", "Lunxheri\/Odrie\/Zagorie\/Pogon\,\ Gjirokastër",
"355267", "Dajç\/Velipojë\,\ Shkodër",
"355366", "Poshnjë\/Kutalli\,\ Berat",
"355284", "Rubik\,\ Mirditë",
"35535", "Lushnje",
"355397", "Vllahinë\/Kote\,\ Vlorë",
"355296", "Fushë\-Bulqizë\/Shupenzë\/Zerqan\,\ Bulqizë",
"355871", "Leskovik\/Barmash\/Novoselë\,\ Kolonjë",
"35544", "Tirana",
"355313", "Ballsh\,\ Mallakastër",
"355395", "Novoselë\,\ Vlorë",
"355574", "Rashbull\/Gjepalaj\,\ Durrës",
"35548", "Kashar\/Vaqar\/Ndroq\/Pezë\/Farkë\/Dajt\,\ Tiranë",
"355381", "Patos\,\ Fier",
"355265", "Vig\-Mnelë\/Hajmel\,\ Shkodër",
"355862", "Qendër\,\ Korçë",
"355289", "Ulëz\/Rukaj\/Derjan\/Macukull\,\ Mat",
"35533", "Vlorë",
"355373", "Krutje\/Bubullimë\/Allkaj\,\ Lushnjë",
"355592", "Qendër\,\ Librazhd",
"355514", "Librazhd",
"355891", "Konispol\/Xare\/Markat\,\ Sarandë",
"355276", "Fajza\/Golaj\/Gjinaj\,\ Has",
"355377", "Qendër\/Greshicë\/Hekal\,\ Mallakastër",
"355885", "Memaliaj\,\ Tepelenë",
"355561", "Mamurras\,\ Kurbin",
"355869", "Çëravë\/Dardhas\,\ Pogradec",
"355282", "Kallmet\/Blinisht\/Dajç\/Ungrej\,\ Lezhë",
"355216", "Rrëshen",
"355365", "Sinjë\/Cukalat\,\ Berat",
"355281", "Shëngjin\/Balldre\,\ Lezhë",
"355874", "Hoçisht\/Miras\,\ Devoll",
"355295", "Sllovë\/Zall\-Dardhë\/Zall\-Reç\/Kala\ e\ Dodes\,\ Dibër",
"355213", "Bajram\ Curri",
"355578", "Synej\/Golem\,\ Kavajë",
"355270", "Kolsh\/Surroj\/Arren\/Malzi\,\ Kukës",
"355814", "Tepelenë",
"355892", "Aliko\/Lukovë\,\ Sarandë",
"355273", "Iballë\/Fierzë\/Blerim\/Qafë\-Mali\,\ Pukë",
"355389", "Dermenas\/Topojë\,\ Fier",
"355562", "Milot\/Fushe\-Kuqe\,\ Kurbin",
"355861", "Maliq\,\ Korçë",
"355585", "Shushicë\/Tregan\/Gjinar\/Zavalinë\,\ Elbasan",
"355591", "Përrenjas\,\ Librazhd",
"355376", "Dushk\/Tërbuf\,\ Lushnjë",
"355277", "Shtiqen\/Tërthore\/Zapod\,\ Kukës",
"355217", "Burrel",
"355382", "Roskovec\,\ Fier",};
my $timezones = {
               '' => [
                       'Europe/Tirane'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+355|\D)//g;
      my $self = bless({ country_code => '355', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '355', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;