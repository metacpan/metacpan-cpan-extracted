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
package Number::Phone::StubCountry::AL;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200511123710;

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
$areanames{en}->{355211} = "Koplik";
$areanames{en}->{355212} = "Pukë";
$areanames{en}->{355213} = "Bajram\ Curri";
$areanames{en}->{355214} = "Krumë";
$areanames{en}->{355215} = "Lezhë";
$areanames{en}->{355216} = "Rrëshen";
$areanames{en}->{355217} = "Burrel";
$areanames{en}->{355218} = "Peshkopi";
$areanames{en}->{355219} = "Bulqizë";
$areanames{en}->{35522} = "Shkodër";
$areanames{en}->{35524} = "Kukës";
$areanames{en}->{355261} = "Vau\-Dejës";
$areanames{en}->{355262} = "Rrethinat\/Ana\-Malit\,\ Shkodër";
$areanames{en}->{355263} = "Pult\/Shalë\/Shosh\/Temal\/Shllak\,\ Shkodër";
$areanames{en}->{355264} = "Postribë\/Gur\ i\ Zi";
$areanames{en}->{355265} = "Vig\-Mnelë\/Hajmel\,\ Shkodër";
$areanames{en}->{355266} = "Bushat\/Bërdicë\,\ Shkodër";
$areanames{en}->{355267} = "Dajç\/Velipojë\,\ Shkodër";
$areanames{en}->{355268} = "Qendër\/Gruemirë\,\ Malësi\ e\ Madhe";
$areanames{en}->{355269} = "Kastrat\/Shkrel\/Kelmend\,\ Malësi\ e\ Madhe";
$areanames{en}->{355270} = "Kolsh\/Surroj\/Arren\/Malzi\,\ Kukës";
$areanames{en}->{355271} = "Fushë\-Arrëz\/Rrapë\,\ Pukë";
$areanames{en}->{355272} = "Qerret\/Qelëz\/Gjegjan\,\ Pukë";
$areanames{en}->{355273} = "Iballë\/Fierzë\/Blerim\/Qafë\-Mali\,\ Pukë";
$areanames{en}->{355274} = "Tropojë\/Llugaj\/Margegaj\,\ Tropojë";
$areanames{en}->{355275} = "Bujan\/Fierzë\/Bytyc\/Lekbiba\,\ Tropojë";
$areanames{en}->{355276} = "Fajza\/Golaj\/Gjinaj\,\ Has";
$areanames{en}->{355277} = "Shtiqen\/Tërthore\/Zapod\,\ Kukës";
$areanames{en}->{355278} = "Bicaj\/Topojan\/Shishtavec\,\ Kukës";
$areanames{en}->{355279} = "Gryk\-Çajë\/Ujmisht\/Bushtrice\/Kalis\,\ Kukës";
$areanames{en}->{355281} = "Shëngjin\/Balldre\,\ Lezhë";
$areanames{en}->{355282} = "Kallmet\/Blinisht\/Dajç\/Ungrej\,\ Lezhë";
$areanames{en}->{355283} = "Kolsh\/Zejmen\/Shënkoll\,\ Lezhë";
$areanames{en}->{355284} = "Rubik\,\ Mirditë";
$areanames{en}->{355285} = "Kthjellë\/Selitë\,\ Mirditë";
$areanames{en}->{355286} = "Kaçinar\/Orosh\/Fan\,\ Mirditë";
$areanames{en}->{355287} = "Klos\/Suç\/Lis\,\ Mat";
$areanames{en}->{355288} = "Baz\/Komsi\/Gurrë\/Xibër\,\ Mat";
$areanames{en}->{355289} = "Ulëz\/Rukaj\/Derjan\/Macukull\,\ Mat";
$areanames{en}->{355291} = "Tomin\/Luzni\,\ Dibër";
$areanames{en}->{355292} = "Maqellarë\/Melan\,\ Dibër";
$areanames{en}->{355293} = "Kastriot\/Muhur\/Selishtë\,\ Dibër";
$areanames{en}->{355294} = "Arras\/Fushë\-Çidhën\/Lurë\,\ Dibër";
$areanames{en}->{355295} = "Sllovë\/Zall\-Dardhë\/Zall\-Reç\/Kala\ e\ Dodes\,\ Dibër";
$areanames{en}->{355296} = "Fushë\-Bulqizë\/Shupenzë\/Zerqan\,\ Bulqizë";
$areanames{en}->{355297} = "Gjorice\/Ostren\/Trebisht\/Martanesh\,\ Bulqizë";
$areanames{en}->{355311} = "Kuçovë";
$areanames{en}->{355312} = "Çorovodë\,\ Skrapar";
$areanames{en}->{355313} = "Ballsh\,\ Mallakastër";
$areanames{en}->{35532} = "Berat";
$areanames{en}->{35533} = "Vlorë";
$areanames{en}->{35534} = "Fier";
$areanames{en}->{35535} = "Lushnje";
$areanames{en}->{355360} = "Leshnje\/Potom\/Çepan\/Gjerbës\/Zhepë\,\ Skrapar";
$areanames{en}->{355361} = "Ura\ Vajgurore\,\ Berat";
$areanames{en}->{355362} = "Velabisht\/Roshnik\,\ Berat";
$areanames{en}->{355363} = "Otllak\/Lumas\,\ Berat";
$areanames{en}->{355364} = "Vërtop\/Terpan\,\ Berat";
$areanames{en}->{355365} = "Sinjë\/Cukalat\,\ Berat";
$areanames{en}->{355366} = "Poshnjë\/Kutalli\,\ Berat";
$areanames{en}->{355367} = "Perondi\/Kozarë\,\ Kuçovë";
$areanames{en}->{355368} = "Poliçan\/Bogovë\,\ Skrapar";
$areanames{en}->{355369} = "Qendër\/Vendreshë\,\ Skrapar";
$areanames{en}->{355371} = "Divjakë\,\ Lushnjë";
$areanames{en}->{355372} = "Karbunarë\/Fier\-Shegan\/Hysgjokaj\/Ballagat\,\ Lushnjë";
$areanames{en}->{355373} = "Krutje\/Bubullimë\/Allkaj\,\ Lushnjë";
$areanames{en}->{355374} = "Gradishtë\/Kolonjë\,\ Lushnjë";
$areanames{en}->{355375} = "Golem\/Grabian\/Remas\,\ Lushnjë";
$areanames{en}->{355376} = "Dushk\/Tërbuf\,\ Lushnjë";
$areanames{en}->{355377} = "Qendër\/Greshicë\/Hekal\,\ Mallakastër";
$areanames{en}->{355378} = "Aranitas\/Ngracan\/Selitë\/Fratar\/Kutë\,\ Mallakastër";
$areanames{en}->{355381} = "Patos\,\ Fier";
$areanames{en}->{355382} = "Roskovec\,\ Fier";
$areanames{en}->{355383} = "Qendër\,\ Fier";
$areanames{en}->{355384} = "Mbrostar\ Ura\/LIibofshë\,\ Fier";
$areanames{en}->{355385} = "Portëz\/Zharëz\,\ Fier";
$areanames{en}->{355386} = "Kuman\/Kurjan\/Strum\/Ruzhdie\,\ Fier";
$areanames{en}->{355387} = "Cakran\/Frakull\,\ Fier";
$areanames{en}->{355388} = "Levan\,\ Fier";
$areanames{en}->{355389} = "Dermenas\/Topojë\,\ Fier";
$areanames{en}->{355391} = "Orikum\,\ Vlorë";
$areanames{en}->{355392} = "Selenicë\,\ Vlorë";
$areanames{en}->{355393} = "Himarë\,\ Vlorë";
$areanames{en}->{355394} = "Qendër\,\ Vlorë";
$areanames{en}->{355395} = "Novoselë\,\ Vlorë";
$areanames{en}->{355396} = "Shushicë\/Armen\,\ Vlorë";
$areanames{en}->{355397} = "Vllahinë\/Kote\,\ Vlorë";
$areanames{en}->{355398} = "Sevaster\/Brataj\/Hore\-Vranisht\,\ Vlorë";
$areanames{en}->{35542} = "Tirana";
$areanames{en}->{35543} = "Tirana";
$areanames{en}->{35544} = "Tirana";
$areanames{en}->{35545} = "Tirana";
$areanames{en}->{35546} = "Tirana";
$areanames{en}->{35547} = "Kamëz\/Vorë\/Paskuqan\/Zall\-Herr\/Burxullë\/Prezë\,\ Tiranë";
$areanames{en}->{35548} = "Kashar\/Vaqar\/Ndroq\/Pezë\/Farkë\/Dajt\,\ Tiranë";
$areanames{en}->{35549} = "Petrelë\/Baldushk\/Bërzhitë\/Krrabë\/Shengjergj\/Zall\-Bastar\,\ Tiranë";
$areanames{en}->{355511} = "Kruje";
$areanames{en}->{355512} = "Peqin";
$areanames{en}->{355513} = "Gramsh";
$areanames{en}->{355514} = "Librazhd";
$areanames{en}->{35552} = "Durrës";
$areanames{en}->{35553} = "Laç\,\ Kurbin";
$areanames{en}->{35554} = "Elbasan";
$areanames{en}->{35555} = "Kavajë";
$areanames{en}->{355561} = "Mamurras\,\ Kurbin";
$areanames{en}->{355562} = "Milot\/Fushe\-Kuqe\,\ Kurbin";
$areanames{en}->{355563} = "Fushë\-Krujë";
$areanames{en}->{355564} = "Nikël\/Bubq\,\ Kruje";
$areanames{en}->{355565} = "Koder\-Thumane\/Cudhi\,\ Kruje";
$areanames{en}->{355570} = "Gosë\/Lekaj\/Sinaballaj\,\ Kavajë";
$areanames{en}->{355571} = "Shijak\,\ Durrës";
$areanames{en}->{355572} = "Manëz\,\ Durrës";
$areanames{en}->{355573} = "Sukth\,\ Durrës";
$areanames{en}->{355574} = "Rashbull\/Gjepalaj\,\ Durrës";
$areanames{en}->{355575} = "Xhafzotaj\/Maminas\,\ Durrës";
$areanames{en}->{355576} = "Katund\ i\ Ri\/Ishem\,\ Durrës";
$areanames{en}->{355577} = "Rrogozhinë\,\ Kavajë";
$areanames{en}->{355578} = "Synej\/Golem\,\ Kavajë";
$areanames{en}->{355579} = "Luz\ i\ Vogël\/Kryevidh\/Helmës\,\ Kavajë";
$areanames{en}->{355580} = "Përparim\/Pajovë\,\ Peqin";
$areanames{en}->{355581} = "Cërrik\,\ Elbasan";
$areanames{en}->{355582} = "Belsh\,\ Elbasan";
$areanames{en}->{355583} = "Bradashesh\/Shirgjan\,\ Elbasan";
$areanames{en}->{355584} = "Labinot\-Fushë\/Labinot\-Mal\/Funarë\/Gracen\,\ Elbasan";
$areanames{en}->{355585} = "Shushicë\/Tregan\/Gjinar\/Zavalinë\,\ Elbasan";
$areanames{en}->{355586} = "Gjergjan\/Papër\/Shalës\,\ Elbasan";
$areanames{en}->{355587} = "Gostime\/Klos\/Mollas\,\ Elbasan";
$areanames{en}->{355588} = "Rrasë\/Fierzë\/Kajan\/Grekan\,\ Elbasan";
$areanames{en}->{355589} = "Karinë\/Gjocaj\/Shezë\,\ Peqin";
$areanames{en}->{355591} = "Përrenjas\,\ Librazhd";
$areanames{en}->{355592} = "Qendër\,\ Librazhd";
$areanames{en}->{355593} = "Lunik\/Orenjë\/Stebleve\,\ Librazhd";
$areanames{en}->{355594} = "Hotolisht\/Polis\/Stravaj\,\ Librazhd";
$areanames{en}->{355595} = "Qukës\/Rajcë\,\ Librazhd";
$areanames{en}->{355596} = "Pishaj\/Sult\/Tunjë\/Kushovë\/Skënderbegas\,\ Gramsh";
$areanames{en}->{355597} = "Kodovjat\/Poroçan\/Kukur\/Lenie\,\ Gramsh";
$areanames{en}->{355811} = "Bilisht\,\ Devoll";
$areanames{en}->{355812} = "Ersekë\,\ Kolonjë";
$areanames{en}->{355813} = "Përmet";
$areanames{en}->{355814} = "Tepelenë";
$areanames{en}->{355815} = "Delvinë";
$areanames{en}->{35582} = "Korçë";
$areanames{en}->{35583} = "Pogradec";
$areanames{en}->{35584} = "Gjirokastër";
$areanames{en}->{35585} = "Sarandë";
$areanames{en}->{355860} = "Trebinjë\/Proptisht\/Velçan\,\ Pogradec";
$areanames{en}->{355861} = "Maliq\,\ Korçë";
$areanames{en}->{355862} = "Qendër\,\ Korçë";
$areanames{en}->{355863} = "Drenovë\/Mollaj\,\ Korçë";
$areanames{en}->{355864} = "Voskop\/Voskopojë\/Vithkuq\/Lekas\,\ Korçë";
$areanames{en}->{355865} = "Gorë\/Pirg\/Moglicë\,\ Korçë";
$areanames{en}->{355866} = "Libonik\/Vreshtaz\,\ Korçë";
$areanames{en}->{355867} = "Pojan\/Liqenas\,\ Korçë";
$areanames{en}->{355868} = "Buçimas\/Udenisht\,\ Pogradec";
$areanames{en}->{355869} = "Çëravë\/Dardhas\,\ Pogradec";
$areanames{en}->{355871} = "Leskovik\/Barmash\/Novoselë\,\ Kolonjë";
$areanames{en}->{355872} = "Qendër\ Ersekë\/Mollas\/Çlirim\,\ Kolonjë";
$areanames{en}->{355873} = "Qendër\ Bilisht\/Progër\,\ Devoll";
$areanames{en}->{355874} = "Hoçisht\/Miras\,\ Devoll";
$areanames{en}->{355875} = "Këlcyrë\,\ Përmet";
$areanames{en}->{355876} = "Qendër\/Frashër\/Petran\/Çarshovë\,\ Përmet";
$areanames{en}->{355877} = "Dishnicë\/Sukë\/Ballaban\,\ Përmet";
$areanames{en}->{355881} = "Libohovë\/Qendër\,\ Gjirokastër";
$areanames{en}->{355882} = "Cepo\/Picar\/Lazarat\/Atigon\,\ Gjirokastër";
$areanames{en}->{355883} = "Lunxheri\/Odrie\/Zagorie\/Pogon\,\ Gjirokastër";
$areanames{en}->{355884} = "Dropull\ i\ Poshtëm\/Dropull\ i\ Sipërm\,\ Gjirokastër";
$areanames{en}->{355885} = "Memaliaj\,\ Tepelenë";
$areanames{en}->{355886} = "Qendër\/Kurvelesh\/Lopëz\,\ Tepelenë";
$areanames{en}->{355887} = "Qesarat\/Krahës\/Luftinje\/Buz\,\ Tepelenë";
$areanames{en}->{355891} = "Konispol\/Xare\/Markat\,\ Sarandë";
$areanames{en}->{355892} = "Aliko\/Lukovë\,\ Sarandë";
$areanames{en}->{355893} = "Ksamil\,\ Sarandë";
$areanames{en}->{355894} = "Livadhja\/Dhivër\,\ Sarandë";
$areanames{en}->{355895} = "Finiq\/Mesopotam\/Vergo\,\ Delvinë";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+355|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;