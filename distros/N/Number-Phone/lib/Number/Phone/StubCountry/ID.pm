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
package Number::Phone::StubCountry::ID;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200511123714;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '15',
                  'pattern' => '(\\d)(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            2[124]|
            [36]1
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{5,9})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '800',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{5,7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[2-79]',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{3})(\\d{5,8})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '8[1-35-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3,4})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '1',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{6,8})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '804',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '80',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d)(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1-$2-$3',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{4})(\\d{4,5})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'intl_format' => 'NA',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2[124]\\d{7,8}|
          619\\d{8}|
          2(?:
            1(?:
              14|
              500
            )|
            2\\d{3}
          )\\d{3}|
          61\\d{5,8}|
          (?:
            2(?:
              [35][1-4]|
              6[0-8]|
              7[1-6]|
              8\\d|
              9[1-8]
            )|
            3(?:
              1|
              [25][1-8]|
              3[1-68]|
              4[1-3]|
              6[1-3568]|
              7[0-469]|
              8\\d
            )|
            4(?:
              0[1-589]|
              1[01347-9]|
              2[0-36-8]|
              3[0-24-68]|
              43|
              5[1-378]|
              6[1-5]|
              7[134]|
              8[1245]
            )|
            5(?:
              1[1-35-9]|
              2[25-8]|
              3[124-9]|
              4[1-3589]|
              5[1-46]|
              6[1-8]
            )|
            6(?:
              [25]\\d|
              3[1-69]|
              4[1-6]
            )|
            7(?:
              02|
              [125][1-9]|
              [36]\\d|
              4[1-8]|
              7[0-36-9]
            )|
            9(?:
              0[12]|
              1[013-8]|
              2[0-479]|
              5[125-8]|
              6[23679]|
              7[159]|
              8[01346]
            )
          )\\d{5,8}
        ',
                'geographic' => '
          2[124]\\d{7,8}|
          619\\d{8}|
          2(?:
            1(?:
              14|
              500
            )|
            2\\d{3}
          )\\d{3}|
          61\\d{5,8}|
          (?:
            2(?:
              [35][1-4]|
              6[0-8]|
              7[1-6]|
              8\\d|
              9[1-8]
            )|
            3(?:
              1|
              [25][1-8]|
              3[1-68]|
              4[1-3]|
              6[1-3568]|
              7[0-469]|
              8\\d
            )|
            4(?:
              0[1-589]|
              1[01347-9]|
              2[0-36-8]|
              3[0-24-68]|
              43|
              5[1-378]|
              6[1-5]|
              7[134]|
              8[1245]
            )|
            5(?:
              1[1-35-9]|
              2[25-8]|
              3[124-9]|
              4[1-3589]|
              5[1-46]|
              6[1-8]
            )|
            6(?:
              [25]\\d|
              3[1-69]|
              4[1-6]
            )|
            7(?:
              02|
              [125][1-9]|
              [36]\\d|
              4[1-8]|
              7[0-36-9]
            )|
            9(?:
              0[12]|
              1[013-8]|
              2[0-479]|
              5[125-8]|
              6[23679]|
              7[159]|
              8[01346]
            )
          )\\d{5,8}
        ',
                'mobile' => '8[1-35-9]\\d{7,10}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(804\\d{7})|(809\\d{7})|(
          (?:
            1500|
            8071\\d{3}
          )\\d{3}
        )',
                'toll_free' => '
          007803\\d{7}|
          (?:
            177\\d|
            800
          )\\d{5,7}
        ',
                'voip' => ''
              };
my %areanames = ();
$areanames{id}->{6221} = "Jabodetabek";
$areanames{id}->{6222} = "Bandung\/Cimahi";
$areanames{id}->{62231} = "Cirebon";
$areanames{id}->{62232} = "Kuningan";
$areanames{id}->{62233} = "Majalengka";
$areanames{id}->{62234} = "Indramayu";
$areanames{id}->{6224} = "Semarang\/Demak";
$areanames{id}->{62251} = "Bogor";
$areanames{id}->{62252} = "Rangkasbitung";
$areanames{id}->{62253} = "Pandeglang";
$areanames{id}->{62254} = "Serang\/Merak";
$areanames{id}->{62260} = "Subang";
$areanames{id}->{62261} = "Sumedang";
$areanames{id}->{62262} = "Garut";
$areanames{id}->{62263} = "Cianjur";
$areanames{id}->{62264} = "Purwakarta\/Cikampek";
$areanames{id}->{62265} = "Tasikmalaya\/Banjar\/Ciamis";
$areanames{id}->{62266} = "Sukabumi";
$areanames{id}->{62267} = "Karawang";
$areanames{id}->{62271} = "Surakarta\/Sukoharjo\/Karanganyar\/Sragen";
$areanames{id}->{62272} = "Klaten";
$areanames{id}->{62273} = "Wonogiri";
$areanames{id}->{62274} = "Yogyakarta";
$areanames{id}->{62275} = "Purworejo";
$areanames{id}->{62276} = "Boyolali";
$areanames{id}->{62280} = "Cilacap\ Barat";
$areanames{id}->{62281} = "Banyumas\/Purbalingga";
$areanames{id}->{62282} = "Cilacap\ Timur";
$areanames{id}->{62283} = "Tegal\/Brebes";
$areanames{id}->{62284} = "Pemalang";
$areanames{id}->{62285} = "Pekalongan\/Batang\/Comal";
$areanames{id}->{62286} = "Banjarnegara\/Wonosobo";
$areanames{id}->{62287} = "Kebumen\/Karanganyar";
$areanames{id}->{62289} = "Bumiayu";
$areanames{id}->{62291} = "Demak\/Jepara\/Kudus";
$areanames{id}->{62292} = "Purwodadi";
$areanames{id}->{62293} = "Magelang\/Mungkid\/Temanggung";
$areanames{id}->{62294} = "Kendal";
$areanames{id}->{62295} = "Pati\/Rembang";
$areanames{id}->{62296} = "Blora";
$areanames{id}->{62297} = "Karimun\ Jawa";
$areanames{id}->{62298} = "Salatiga\/Ambarawa";
$areanames{id}->{6231} = "Surabaya";
$areanames{id}->{62321} = "Mojokerto\/Jombang";
$areanames{id}->{62322} = "Lamongan";
$areanames{id}->{62323} = "Sampang";
$areanames{id}->{62324} = "Pamekasan";
$areanames{id}->{62325} = "Sangkapura";
$areanames{id}->{62326} = "Masalembu\ Islands";
$areanames{id}->{62327} = "Kangean\/Masalembu";
$areanames{id}->{62328} = "Sumenep";
$areanames{id}->{62331} = "Jember";
$areanames{id}->{62332} = "Bondowoso";
$areanames{id}->{62333} = "Banyuwangi";
$areanames{id}->{62334} = "Lumajang";
$areanames{id}->{62335} = "Probolinggo";
$areanames{id}->{62336} = "Jember";
$areanames{id}->{62338} = "Situbondo";
$areanames{id}->{62341} = "Malang\/Batu";
$areanames{id}->{62342} = "Blitar";
$areanames{id}->{62343} = "Pasuruan";
$areanames{id}->{62351} = "Madiun\/Magetan\/Ngawi";
$areanames{id}->{62352} = "Ponorogo";
$areanames{id}->{62353} = "Bojonegoro";
$areanames{id}->{62354} = "Kediri";
$areanames{id}->{62355} = "Tulungagung\/Trenggalek";
$areanames{id}->{62356} = "Rembang\/Tuban";
$areanames{id}->{62357} = "Pacitan";
$areanames{id}->{62358} = "Nganjuk";
$areanames{id}->{62361} = "Denpasar";
$areanames{id}->{62362} = "Singaraja";
$areanames{id}->{62363} = "Amlapura";
$areanames{id}->{62365} = "Negara\/Gilimanuk";
$areanames{id}->{62366} = "Klungkung\/Bangli";
$areanames{id}->{62368} = "Baturiti";
$areanames{id}->{62370} = "Mataram\/Praya";
$areanames{id}->{62371} = "Sumbawa";
$areanames{id}->{62372} = "Alas\/Taliwang";
$areanames{id}->{62373} = "Dompu";
$areanames{id}->{62374} = "Bima";
$areanames{id}->{62376} = "Selong";
$areanames{id}->{62380} = "Kupang";
$areanames{id}->{62381} = "Ende";
$areanames{id}->{62382} = "Maumere";
$areanames{id}->{62383} = "Larantuka";
$areanames{id}->{62384} = "Bajawa";
$areanames{id}->{62385} = "Labuhanbajo\/Ruteng";
$areanames{id}->{62386} = "Kalabahi";
$areanames{id}->{62387} = "Waingapu\/Waikabubak";
$areanames{id}->{62388} = "Kefamenanu\/Soe";
$areanames{id}->{62389} = "Atambua";
$areanames{id}->{62401} = "Kendari";
$areanames{id}->{62402} = "Baubau";
$areanames{id}->{62403} = "Raha";
$areanames{id}->{62404} = "Wanci";
$areanames{id}->{62405} = "Kolaka";
$areanames{id}->{62408} = "Unaaha";
$areanames{id}->{62410} = "Pangkep";
$areanames{id}->{62411} = "Makassar\/Maros\/Sungguminasa";
$areanames{id}->{62413} = "Bulukumba\/Bantaeng";
$areanames{id}->{62414} = "Kepulauan\ Selayar";
$areanames{id}->{62417} = "Malino";
$areanames{id}->{62418} = "Takalar";
$areanames{id}->{62419} = "Jeneponto";
$areanames{id}->{62420} = "Enrekang";
$areanames{id}->{62421} = "Parepare\/Pinrang";
$areanames{id}->{62422} = "Majene";
$areanames{id}->{62423} = "Makale\/Rantepao";
$areanames{id}->{62426} = "Mamuju";
$areanames{id}->{62427} = "Barru";
$areanames{id}->{62428} = "Polewali";
$areanames{id}->{62430} = "Amurang";
$areanames{id}->{62431} = "Manado\/Tomohon\/Tondano";
$areanames{id}->{62432} = "Tahuna";
$areanames{id}->{62434} = "Kotamobagu";
$areanames{id}->{62435} = "Gorontalo";
$areanames{id}->{62438} = "Bitung";
$areanames{id}->{6244} = "Marisa";
$areanames{id}->{62451} = "Palu";
$areanames{id}->{62452} = "Poso";
$areanames{id}->{62453} = "Tolitoli";
$areanames{id}->{62457} = "Donggala";
$areanames{id}->{62458} = "Tentena";
$areanames{id}->{62461} = "Luwuk";
$areanames{id}->{62462} = "Banggai";
$areanames{id}->{62463} = "Bunta";
$areanames{id}->{62464} = "Ampana";
$areanames{id}->{62465} = "Kolonedale";
$areanames{id}->{62471} = "Palopo";
$areanames{id}->{62473} = "Masamba";
$areanames{id}->{62474} = "Malili";
$areanames{id}->{62481} = "Watampone";
$areanames{id}->{62482} = "Sinjai";
$areanames{id}->{62484} = "Watansoppeng";
$areanames{id}->{62485} = "Sengkang";
$areanames{id}->{62511} = "Banjarmasin";
$areanames{id}->{62512} = "Pelaihari";
$areanames{id}->{62513} = "Muara\ Teweh";
$areanames{id}->{62517} = "Kandangan\/Barabai\/Rantau\/Negara";
$areanames{id}->{62518} = "Kotabaru\/Batulicin";
$areanames{id}->{62522} = "Ampah";
$areanames{id}->{62525} = "Buntok";
$areanames{id}->{62526} = "Tamiang\ Layang\/Tanjung";
$areanames{id}->{62527} = "Amuntai";
$areanames{id}->{62528} = "Purukcahu";
$areanames{id}->{62531} = "Sampit";
$areanames{id}->{62532} = "Pangkalan\ Bun";
$areanames{id}->{62534} = "Ketapang";
$areanames{id}->{62536} = "Palangkaraya\/Kasongan";
$areanames{id}->{62537} = "Kuala\ Kurun";
$areanames{id}->{62538} = "Kuala\ Pembuang";
$areanames{id}->{62539} = "Kuala\ Kuayan";
$areanames{id}->{62541} = "Samarinda\/Tenggarong";
$areanames{id}->{62542} = "Balikpapan";
$areanames{id}->{62543} = "Tanah\ Grogot";
$areanames{id}->{62545} = "Melak";
$areanames{id}->{62548} = "Bontang";
$areanames{id}->{62549} = "Sangatta";
$areanames{id}->{62551} = "Tarakan";
$areanames{id}->{62552} = "Tanjungselor";
$areanames{id}->{62553} = "Malinau";
$areanames{id}->{62554} = "Tanjung\ Redeb";
$areanames{id}->{62556} = "Nunukan";
$areanames{id}->{62561} = "Pontianak\/Mempawah";
$areanames{id}->{62562} = "Singkawang\/Sambas\/Bengkayang";
$areanames{id}->{62563} = "Ngabang";
$areanames{id}->{62564} = "Sanggau";
$areanames{id}->{62565} = "Sintang";
$areanames{id}->{62567} = "Putussibau";
$areanames{id}->{62568} = "Nanga\ Pinoh";
$areanames{id}->{6261} = "Medan";
$areanames{id}->{62620} = "Pangkalan\ Brandan";
$areanames{id}->{62621} = "Tebing\ Tinggi\/Sei\ Rampah";
$areanames{id}->{62622} = "Pematangsiantar\/Pematang\ Raya\/Limapuluh";
$areanames{id}->{62623} = "Kisaran\/Tanjung\ Balai";
$areanames{id}->{62624} = "Panipahan\/Labuhanbatu";
$areanames{id}->{62625} = "Parapat\/Ajibata\/Simanindo";
$areanames{id}->{62626} = "Pangururan";
$areanames{id}->{62627} = "Subulussalam\/Sidikalang\/Salak";
$areanames{id}->{62628} = "Kabanjahe\/Sibolangit";
$areanames{id}->{62629} = "Kutacane";
$areanames{id}->{62631} = "Sibolga\/Pandan";
$areanames{id}->{62632} = "Balige";
$areanames{id}->{62633} = "Tarutung\/Dolok\ Sanggul";
$areanames{id}->{62634} = "Padang\ Sidempuan\/Sipirok";
$areanames{id}->{62635} = "Gunung\ Tua";
$areanames{id}->{62636} = "Panyabungan\/Sibuhuan";
$areanames{id}->{62639} = "Gunung\ Sitoli";
$areanames{id}->{62641} = "Langsa";
$areanames{id}->{62642} = "Blang\ Kejeren";
$areanames{id}->{62643} = "Takengon";
$areanames{id}->{62644} = "Bireuen";
$areanames{id}->{62645} = "Lhokseumawe";
$areanames{id}->{62646} = "Idi";
$areanames{id}->{62650} = "Sinabang";
$areanames{id}->{62651} = "Banda\ Aceh\/Jantho\/Lamno";
$areanames{id}->{62652} = "Sabang";
$areanames{id}->{62653} = "Sigli";
$areanames{id}->{62654} = "Calang";
$areanames{id}->{62655} = "Meulaboh";
$areanames{id}->{62656} = "Tapaktuan";
$areanames{id}->{62657} = "Bakongan";
$areanames{id}->{62658} = "Singkil";
$areanames{id}->{62659} = "Blangpidie";
$areanames{id}->{6270} = "Tebing\ Tinggi";
$areanames{id}->{62711} = "Palembang";
$areanames{id}->{62712} = "Kayu\ Agung\/Tanjung\ Raja";
$areanames{id}->{62713} = "Prabumulih\/Talang\ Ubi";
$areanames{id}->{62714} = "Sekayu";
$areanames{id}->{62715} = "Belinyu";
$areanames{id}->{62716} = "Muntok";
$areanames{id}->{62717} = "Pangkal\ Pinang\/Sungailiat";
$areanames{id}->{62718} = "Koba\/Toboali";
$areanames{id}->{62719} = "Manggar\/Tanjung\ Pandan";
$areanames{id}->{62721} = "Bandar\ Lampung";
$areanames{id}->{62722} = "Tanggamus";
$areanames{id}->{62723} = "Blambangan\ Umpu";
$areanames{id}->{62724} = "Kotabumi";
$areanames{id}->{62725} = "Metro";
$areanames{id}->{62726} = "Menggala";
$areanames{id}->{62727} = "Kalianda";
$areanames{id}->{62728} = "Liwa";
$areanames{id}->{62729} = "Pringsewu";
$areanames{id}->{62730} = "Pagar\ Alam\/Kota\ Agung";
$areanames{id}->{62731} = "Lahat";
$areanames{id}->{62732} = "Curup";
$areanames{id}->{62733} = "Lubuklinggau\/Muara\ Beliti";
$areanames{id}->{62734} = "Muara\ Enim";
$areanames{id}->{62735} = "Baturaja\/Martapura\/Muaradua";
$areanames{id}->{62736} = "Kota\ Bengkulu";
$areanames{id}->{62737} = "Arga\ Makmur\/Mukomuko";
$areanames{id}->{62738} = "Muara\ Aman";
$areanames{id}->{62739} = "Bintuhan\/Manna";
$areanames{id}->{62741} = "Kota\ Jambi";
$areanames{id}->{62742} = "Kualatungkal\/Tebing\ Tinggi";
$areanames{id}->{62743} = "Muara\ Bulian";
$areanames{id}->{62744} = "Muara\ Tebo";
$areanames{id}->{62745} = "Sarolangun";
$areanames{id}->{62746} = "Bangko";
$areanames{id}->{62747} = "Muarabungo";
$areanames{id}->{62748} = "Sungai\ Penuh\/Kerinci";
$areanames{id}->{62751} = "Padang\/Pariaman";
$areanames{id}->{62752} = "Bukittinggi\/Padang\ Panjang\/Payakumbuh\/Batusangkar";
$areanames{id}->{62753} = "Lubuk\ Sikaping";
$areanames{id}->{62754} = "Sijunjung";
$areanames{id}->{62755} = "Solok";
$areanames{id}->{62756} = "Painan";
$areanames{id}->{62757} = "Balai\ Selasa";
$areanames{id}->{62760} = "Teluk\ Kuantan";
$areanames{id}->{62761} = "Pekanbaru";
$areanames{id}->{62762} = "Bangkinang\/Pasir\ Pengaraian";
$areanames{id}->{62763} = "Selatpanjang";
$areanames{id}->{62764} = "Siak\ Sri\ Indrapura";
$areanames{id}->{62765} = "Dumai\/Duri\/Bagan\ Batu\/Ujung\ Tanjung";
$areanames{id}->{62766} = "Bengkalis";
$areanames{id}->{62767} = "Bagansiapiapi";
$areanames{id}->{62768} = "Tembilahan";
$areanames{id}->{62769} = "Rengat\/Air\ Molek";
$areanames{id}->{62771} = "Tanjung\ Pinang";
$areanames{id}->{62772} = "Tarempa";
$areanames{id}->{62773} = "Ranai";
$areanames{id}->{62776} = "Dabosingkep";
$areanames{id}->{62777} = "Karimun";
$areanames{id}->{62778} = "Batam";
$areanames{id}->{62779} = "Tanjungbatu";
$areanames{id}->{62901} = "Timika";
$areanames{id}->{62902} = "Agats";
$areanames{id}->{62910} = "Bandanaira";
$areanames{id}->{62911} = "Ambon";
$areanames{id}->{62913} = "Namlea";
$areanames{id}->{62914} = "Masohi";
$areanames{id}->{62915} = "Bula";
$areanames{id}->{62916} = "Tual";
$areanames{id}->{62917} = "Dobo";
$areanames{id}->{62918} = "Saumlaku";
$areanames{id}->{62921} = "Soasiu";
$areanames{id}->{62922} = "Jailolo";
$areanames{id}->{62923} = "Morotai";
$areanames{id}->{62924} = "Tobelo";
$areanames{id}->{62927} = "Labuha";
$areanames{id}->{62929} = "Sanana";
$areanames{id}->{62951} = "Sorong";
$areanames{id}->{62952} = "Teminabuan";
$areanames{id}->{62955} = "Bintuni";
$areanames{id}->{62956} = "Fakfak";
$areanames{id}->{62957} = "Kaimana";
$areanames{id}->{62966} = "Sarmi";
$areanames{id}->{62967} = "Jayapura";
$areanames{id}->{62969} = "Wamena";
$areanames{id}->{62971} = "Merauke";
$areanames{id}->{62975} = "Tanahmerah";
$areanames{id}->{62980} = "Ransiki";
$areanames{id}->{62981} = "Biak";
$areanames{id}->{62983} = "Serui";
$areanames{id}->{62984} = "Nabire";
$areanames{id}->{62986} = "Manokwari";
$areanames{en}->{6221} = "Greater\ Jakarta";
$areanames{en}->{6222} = "Bandung\/Cimahi";
$areanames{en}->{62231} = "Cirebon";
$areanames{en}->{62232} = "Kuningan";
$areanames{en}->{62233} = "Majalengka";
$areanames{en}->{62234} = "Indramayu";
$areanames{en}->{6224} = "Semarang\/Demak";
$areanames{en}->{62251} = "Bogor";
$areanames{en}->{62252} = "Rangkasbitung";
$areanames{en}->{62253} = "Pandeglang";
$areanames{en}->{62254} = "Serang\/Merak";
$areanames{en}->{62260} = "Subang";
$areanames{en}->{62261} = "Sumedang";
$areanames{en}->{62262} = "Garut";
$areanames{en}->{62263} = "Cianjur";
$areanames{en}->{62264} = "Purwakarta\/Cikampek";
$areanames{en}->{62265} = "Tasikmalaya\/Banjar\/Ciamis";
$areanames{en}->{62266} = "Sukabumi";
$areanames{en}->{62267} = "Karawang";
$areanames{en}->{62271} = "Surakarta\/Sukoharjo\/Karanganyar\/Sragen";
$areanames{en}->{62272} = "Klaten";
$areanames{en}->{62273} = "Wonogiri";
$areanames{en}->{62274} = "Yogyakarta";
$areanames{en}->{62275} = "Purworejo";
$areanames{en}->{62276} = "Boyolali";
$areanames{en}->{62280} = "West\ Cilacap";
$areanames{en}->{62281} = "Banyumas\/Purbalingga";
$areanames{en}->{62282} = "East\ Cilacap";
$areanames{en}->{62283} = "Tegal\/Brebes";
$areanames{en}->{62284} = "Pemalang";
$areanames{en}->{62285} = "Pekalongan\/Batang\/Comal";
$areanames{en}->{62286} = "Banjarnegara\/Wonosobo";
$areanames{en}->{62287} = "Kebumen\/Karanganyar";
$areanames{en}->{62289} = "Bumiayu";
$areanames{en}->{62291} = "Demak\/Jepara\/Kudus";
$areanames{en}->{62292} = "Purwodadi";
$areanames{en}->{62293} = "Magelang\/Mungkid\/Temanggung";
$areanames{en}->{62294} = "Kendal";
$areanames{en}->{62295} = "Pati\/Rembang";
$areanames{en}->{62296} = "Blora";
$areanames{en}->{62297} = "Karimun\ Jawa";
$areanames{en}->{62298} = "Salatiga\/Ambarawa";
$areanames{en}->{6231} = "Surabaya";
$areanames{en}->{62321} = "Mojokerto\/Jombang";
$areanames{en}->{62322} = "Lamongan";
$areanames{en}->{62323} = "Sampang";
$areanames{en}->{62324} = "Pamekasan";
$areanames{en}->{62325} = "Sangkapura";
$areanames{en}->{62326} = "Masalembu\ Islands";
$areanames{en}->{62327} = "Kangean\/Masalembu";
$areanames{en}->{62328} = "Sumenep";
$areanames{en}->{62331} = "Jember";
$areanames{en}->{62332} = "Bondowoso";
$areanames{en}->{62333} = "Banyuwangi";
$areanames{en}->{62334} = "Lumajang";
$areanames{en}->{62335} = "Probolinggo";
$areanames{en}->{62336} = "Jember";
$areanames{en}->{62338} = "Situbondo";
$areanames{en}->{62341} = "Malang\/Batu";
$areanames{en}->{62342} = "Blitar";
$areanames{en}->{62343} = "Pasuruan";
$areanames{en}->{62351} = "Madiun\/Magetan\/Ngawi";
$areanames{en}->{62352} = "Ponorogo";
$areanames{en}->{62353} = "Bojonegoro";
$areanames{en}->{62354} = "Kediri";
$areanames{en}->{62355} = "Tulungagung\/Trenggalek";
$areanames{en}->{62356} = "Rembang\/Tuban";
$areanames{en}->{62357} = "Pacitan";
$areanames{en}->{62358} = "Nganjuk";
$areanames{en}->{62361} = "Denpasar";
$areanames{en}->{62362} = "Singaraja";
$areanames{en}->{62363} = "Amlapura";
$areanames{en}->{62365} = "Negara\/Gilimanuk";
$areanames{en}->{62366} = "Klungkung\/Bangli";
$areanames{en}->{62368} = "Baturiti";
$areanames{en}->{62370} = "Mataram\/Praya";
$areanames{en}->{62371} = "Sumbawa";
$areanames{en}->{62372} = "Alas\/Taliwang";
$areanames{en}->{62373} = "Dompu";
$areanames{en}->{62374} = "Bima";
$areanames{en}->{62376} = "Selong";
$areanames{en}->{62380} = "Kupang";
$areanames{en}->{62381} = "Ende";
$areanames{en}->{62382} = "Maumere";
$areanames{en}->{62383} = "Larantuka";
$areanames{en}->{62384} = "Bajawa";
$areanames{en}->{62385} = "Labuhanbajo\/Ruteng";
$areanames{en}->{62386} = "Kalabahi";
$areanames{en}->{62387} = "Waingapu\/Waikabubak";
$areanames{en}->{62388} = "Kefamenanu\/Soe";
$areanames{en}->{62389} = "Atambua";
$areanames{en}->{62401} = "Kendari";
$areanames{en}->{62402} = "Baubau";
$areanames{en}->{62403} = "Raha";
$areanames{en}->{62404} = "Wanci";
$areanames{en}->{62405} = "Kolaka";
$areanames{en}->{62408} = "Unaaha";
$areanames{en}->{62410} = "Pangkep";
$areanames{en}->{62411} = "Makassar\/Maros\/Sungguminasa";
$areanames{en}->{62413} = "Bulukumba\/Bantaeng";
$areanames{en}->{62414} = "Kepulauan\ Selayar";
$areanames{en}->{62417} = "Malino";
$areanames{en}->{62418} = "Takalar";
$areanames{en}->{62419} = "Jeneponto";
$areanames{en}->{62420} = "Enrekang";
$areanames{en}->{62421} = "Parepare\/Pinrang";
$areanames{en}->{62422} = "Majene";
$areanames{en}->{62423} = "Makale\/Rantepao";
$areanames{en}->{62426} = "Mamuju";
$areanames{en}->{62427} = "Barru";
$areanames{en}->{62428} = "Polewali";
$areanames{en}->{62430} = "Amurang";
$areanames{en}->{62431} = "Manado\/Tomohon\/Tondano";
$areanames{en}->{62432} = "Tahuna";
$areanames{en}->{62434} = "Kotamobagu";
$areanames{en}->{62435} = "Gorontalo";
$areanames{en}->{62438} = "Bitung";
$areanames{en}->{6244} = "Marisa";
$areanames{en}->{62451} = "Palu";
$areanames{en}->{62452} = "Poso";
$areanames{en}->{62453} = "Tolitoli";
$areanames{en}->{62457} = "Donggala";
$areanames{en}->{62458} = "Tentena";
$areanames{en}->{62461} = "Luwuk";
$areanames{en}->{62462} = "Banggai";
$areanames{en}->{62463} = "Bunta";
$areanames{en}->{62464} = "Ampana";
$areanames{en}->{62465} = "Kolonedale";
$areanames{en}->{62471} = "Palopo";
$areanames{en}->{62473} = "Masamba";
$areanames{en}->{62474} = "Malili";
$areanames{en}->{62481} = "Watampone";
$areanames{en}->{62482} = "Sinjai";
$areanames{en}->{62484} = "Watansoppeng";
$areanames{en}->{62485} = "Sengkang";
$areanames{en}->{62511} = "Banjarmasin";
$areanames{en}->{62512} = "Pelaihari";
$areanames{en}->{62513} = "Muara\ Teweh";
$areanames{en}->{62517} = "Kandangan\/Barabai\/Rantau\/Negara";
$areanames{en}->{62518} = "Kotabaru\/Batulicin";
$areanames{en}->{62522} = "Ampah";
$areanames{en}->{62525} = "Buntok";
$areanames{en}->{62526} = "Tamiang\ Layang\/Tanjung";
$areanames{en}->{62527} = "Amuntai";
$areanames{en}->{62528} = "Purukcahu";
$areanames{en}->{62531} = "Sampit";
$areanames{en}->{62532} = "Pangkalan\ Bun";
$areanames{en}->{62534} = "Ketapang";
$areanames{en}->{62536} = "Palangkaraya\/Kasongan";
$areanames{en}->{62537} = "Kuala\ Kurun";
$areanames{en}->{62538} = "Kuala\ Pembuang";
$areanames{en}->{62539} = "Kuala\ Kuayan";
$areanames{en}->{62541} = "Samarinda\/Tenggarong";
$areanames{en}->{62542} = "Balikpapan";
$areanames{en}->{62543} = "Tanah\ Grogot";
$areanames{en}->{62545} = "Melak";
$areanames{en}->{62548} = "Bontang";
$areanames{en}->{62549} = "Sangatta";
$areanames{en}->{62551} = "Tarakan";
$areanames{en}->{62552} = "Tanjungselor";
$areanames{en}->{62553} = "Malinau";
$areanames{en}->{62554} = "Tanjung\ Redeb";
$areanames{en}->{62556} = "Nunukan";
$areanames{en}->{62561} = "Pontianak\/Mempawah";
$areanames{en}->{62562} = "Singkawang\/Sambas\/Bengkayang";
$areanames{en}->{62563} = "Ngabang";
$areanames{en}->{62564} = "Sanggau";
$areanames{en}->{62565} = "Sintang";
$areanames{en}->{62567} = "Putussibau";
$areanames{en}->{62568} = "Nanga\ Pinoh";
$areanames{en}->{6261} = "Medan";
$areanames{en}->{62620} = "Pangkalan\ Brandan";
$areanames{en}->{62621} = "Tebing\ Tinggi\/Sei\ Rampah";
$areanames{en}->{62622} = "Pematangsiantar\/Pematang\ Raya\/Limapuluh";
$areanames{en}->{62623} = "Kisaran\/Tanjung\ Balai";
$areanames{en}->{62624} = "Panipahan\/Labuhanbatu";
$areanames{en}->{62625} = "Parapat\/Ajibata\/Simanindo";
$areanames{en}->{62626} = "Pangururan";
$areanames{en}->{62627} = "Subulussalam\/Sidikalang\/Salak";
$areanames{en}->{62628} = "Kabanjahe\/Sibolangit";
$areanames{en}->{62629} = "Kutacane";
$areanames{en}->{62631} = "Sibolga\/Pandan";
$areanames{en}->{62632} = "Balige";
$areanames{en}->{62633} = "Tarutung\/Dolok\ Sanggul";
$areanames{en}->{62634} = "Padang\ Sidempuan\/Sipirok";
$areanames{en}->{62635} = "Gunung\ Tua";
$areanames{en}->{62636} = "Panyabungan\/Sibuhuan";
$areanames{en}->{62639} = "Gunung\ Sitoli";
$areanames{en}->{62641} = "Langsa";
$areanames{en}->{62642} = "Blang\ Kejeren";
$areanames{en}->{62643} = "Takengon";
$areanames{en}->{62644} = "Bireuen";
$areanames{en}->{62645} = "Lhokseumawe";
$areanames{en}->{62646} = "Idi";
$areanames{en}->{62650} = "Sinabang";
$areanames{en}->{62651} = "Banda\ Aceh\/Jantho\/Lamno";
$areanames{en}->{62652} = "Sabang";
$areanames{en}->{62653} = "Sigli";
$areanames{en}->{62654} = "Calang";
$areanames{en}->{62655} = "Meulaboh";
$areanames{en}->{62656} = "Tapaktuan";
$areanames{en}->{62657} = "Bakongan";
$areanames{en}->{62658} = "Singkil";
$areanames{en}->{62659} = "Blangpidie";
$areanames{en}->{6270} = "Tebing\ Tinggi";
$areanames{en}->{62711} = "Palembang";
$areanames{en}->{62712} = "Kayu\ Agung\/Tanjung\ Raja";
$areanames{en}->{62713} = "Prabumulih\/Talang\ Ubi";
$areanames{en}->{62714} = "Sekayu";
$areanames{en}->{62715} = "Belinyu";
$areanames{en}->{62716} = "Muntok";
$areanames{en}->{62717} = "Pangkal\ Pinang\/Sungailiat";
$areanames{en}->{62718} = "Koba\/Toboali";
$areanames{en}->{62719} = "Manggar\/Tanjung\ Pandan";
$areanames{en}->{62721} = "Bandar\ Lampung";
$areanames{en}->{62722} = "Tanggamus";
$areanames{en}->{62723} = "Blambangan\ Umpu";
$areanames{en}->{62724} = "Kotabumi";
$areanames{en}->{62725} = "Metro";
$areanames{en}->{62726} = "Menggala";
$areanames{en}->{62727} = "Kalianda";
$areanames{en}->{62728} = "Liwa";
$areanames{en}->{62729} = "Pringsewu";
$areanames{en}->{62730} = "Pagar\ Alam\/Kota\ Agung";
$areanames{en}->{62731} = "Lahat";
$areanames{en}->{62732} = "Curup";
$areanames{en}->{62733} = "Lubuklinggau\/Muara\ Beliti";
$areanames{en}->{62734} = "Muara\ Enim";
$areanames{en}->{62735} = "Baturaja\/Martapura\/Muaradua";
$areanames{en}->{62736} = "Bengkulu\ City";
$areanames{en}->{62737} = "Arga\ Makmur\/Mukomuko";
$areanames{en}->{62738} = "Muara\ Aman";
$areanames{en}->{62739} = "Bintuhan\/Manna";
$areanames{en}->{62741} = "Jambi\ City";
$areanames{en}->{62742} = "Kualatungkal\/Tebing\ Tinggi";
$areanames{en}->{62743} = "Muara\ Bulian";
$areanames{en}->{62744} = "Muara\ Tebo";
$areanames{en}->{62745} = "Sarolangun";
$areanames{en}->{62746} = "Bangko";
$areanames{en}->{62747} = "Muarabungo";
$areanames{en}->{62748} = "Sungai\ Penuh\/Kerinci";
$areanames{en}->{62751} = "Padang\/Pariaman";
$areanames{en}->{62752} = "Bukittinggi\/Padang\ Panjang\/Payakumbuh\/Batusangkar";
$areanames{en}->{62753} = "Lubuk\ Sikaping";
$areanames{en}->{62754} = "Sijunjung";
$areanames{en}->{62755} = "Solok";
$areanames{en}->{62756} = "Painan";
$areanames{en}->{62757} = "Balai\ Selasa";
$areanames{en}->{62760} = "Teluk\ Kuantan";
$areanames{en}->{62761} = "Pekanbaru";
$areanames{en}->{62762} = "Bangkinang\/Pasir\ Pengaraian";
$areanames{en}->{62763} = "Selatpanjang";
$areanames{en}->{62764} = "Siak\ Sri\ Indrapura";
$areanames{en}->{62765} = "Dumai\/Duri\/Bagan\ Batu\/Ujung\ Tanjung";
$areanames{en}->{62766} = "Bengkalis";
$areanames{en}->{62767} = "Bagansiapiapi";
$areanames{en}->{62768} = "Tembilahan";
$areanames{en}->{62769} = "Rengat\/Air\ Molek";
$areanames{en}->{62771} = "Tanjung\ Pinang";
$areanames{en}->{62772} = "Tarempa";
$areanames{en}->{62773} = "Ranai";
$areanames{en}->{62776} = "Dabosingkep";
$areanames{en}->{62777} = "Karimun";
$areanames{en}->{62778} = "Batam";
$areanames{en}->{62779} = "Tanjungbatu";
$areanames{en}->{62901} = "Timika";
$areanames{en}->{62902} = "Agats";
$areanames{en}->{62910} = "Bandanaira";
$areanames{en}->{62911} = "Ambon";
$areanames{en}->{62913} = "Namlea";
$areanames{en}->{62914} = "Masohi";
$areanames{en}->{62915} = "Bula";
$areanames{en}->{62916} = "Tual";
$areanames{en}->{62917} = "Dobo";
$areanames{en}->{62918} = "Saumlaku";
$areanames{en}->{62921} = "Soasiu";
$areanames{en}->{62922} = "Jailolo";
$areanames{en}->{62923} = "Morotai";
$areanames{en}->{62924} = "Tobelo";
$areanames{en}->{62927} = "Labuha";
$areanames{en}->{62929} = "Sanana";
$areanames{en}->{62951} = "Sorong";
$areanames{en}->{62952} = "Teminabuan";
$areanames{en}->{62955} = "Bintuni";
$areanames{en}->{62956} = "Fakfak";
$areanames{en}->{62957} = "Kaimana";
$areanames{en}->{62966} = "Sarmi";
$areanames{en}->{62967} = "Jayapura";
$areanames{en}->{62969} = "Wamena";
$areanames{en}->{62971} = "Merauke";
$areanames{en}->{62975} = "Tanahmerah";
$areanames{en}->{62980} = "Ransiki";
$areanames{en}->{62981} = "Biak";
$areanames{en}->{62983} = "Serui";
$areanames{en}->{62984} = "Nabire";
$areanames{en}->{62986} = "Manokwari";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+62|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;