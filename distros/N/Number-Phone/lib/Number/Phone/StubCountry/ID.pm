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
our $VERSION = 1.20220307120118;

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
                  'leading_digits' => '001',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})(\\d{3})'
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
          00[17]803\\d{7}|
          (?:
            177\\d|
            800
          )\\d{5,7}|
          001803\\d{6}
        ',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"62918", "Saumlaku",
"62362", "Singaraja",
"62556", "Nunukan",
"62432", "Tahuna",
"62404", "Wanci",
"62986", "Manokwari",
"62562", "Singkawang\/Sambas\/Bengkayang",
"62356", "Rembang\/Tuban",
"62420", "Enrekang",
"62629", "Kutacane",
"62525", "Buntok",
"62916", "Tual",
"62325", "Sangkapura",
"62358", "Nganjuk",
"62482", "Sinjai",
"6270", "Tebing\ Tinggi",
"62471", "Palopo",
"62473", "Masamba",
"62975", "Tanahmerah",
"62419", "Jeneponto",
"62776", "Dabosingkep",
"62262", "Garut",
"62715", "Belinyu",
"62735", "Baturaja\/Martapura\/Muaradua",
"62651", "Banda\ Aceh\/Jantho\/Lamno",
"62653", "Sigli",
"62622", "Pematangsiantar\/Pematang\ Raya\/Limapuluh",
"62778", "Batam",
"62760", "Teluk\ Kuantan",
"62745", "Sarolangun",
"62657", "Bakongan",
"62232", "Kuningan",
"62539", "Kuala\ Kuayan",
"62635", "Gunung\ Tua",
"62254", "Serang\/Merak",
"62765", "Dumai\/Duri\/Bagan\ Batu\/Ujung\ Tanjung",
"62751", "Padang\/Pariaman",
"62753", "Lubuk\ Sikaping",
"62722", "Tanggamus",
"62645", "Lhokseumawe",
"62757", "Balai\ Selasa",
"62389", "Atambua",
"62549", "Sangatta",
"62273", "Wonogiri",
"62271", "Surakarta\/Sukoharjo\/Karanganyar\/Sragen",
"62282", "East\ Cilacap",
"62295", "Pati\/Rembang",
"62730", "Pagar\ Alam\/Kota\ Agung",
"62332", "Bondowoso",
"62462", "Banggai",
"62554", "Tanjung\ Redeb",
"62984", "Nabire",
"62532", "Pangkalan\ Bun",
"62512", "Pelaihari",
"62354", "Kediri",
"62966", "Sarmi",
"62927", "Labuha",
"62342", "Blitar",
"62729", "Pringsewu",
"62914", "Masohi",
"62542", "Balikpapan",
"62289", "Bumiayu",
"62373", "Dompu",
"62371", "Sumbawa",
"62382", "Maumere",
"62923", "Morotai",
"62952", "Teminabuan",
"62458", "Tentena",
"62921", "Soasiu",
"62902", "Agats",
"62408", "Unaaha",
"62260", "Subang",
"62725", "Metro",
"62642", "Blang\ Kejeren",
"62285", "Pekalongan\/Batang\/Comal",
"62292", "Purwodadi",
"62756", "Painan",
"62620", "Pangkalan\ Brandan",
"62654", "Calang",
"62632", "Balige",
"62276", "Boyolali",
"62762", "Bangkinang\/Pasir\ Pengaraian",
"62457", "Donggala",
"62410", "Pangkep",
"62430", "Amurang",
"62545", "Melak",
"62385", "Labuhanbajo\/Ruteng",
"62955", "Bintuni",
"62401", "Kendari",
"62403", "Raha",
"62422", "Majene",
"62453", "Tolitoli",
"62451", "Palu",
"62335", "Probolinggo",
"62465", "Kolonedale",
"62639", "Gunung\ Sitoli",
"62967", "Jayapura",
"62474", "Malili",
"62376", "Selong",
"62769", "Rengat\/Air\ Molek",
"62522", "Ampah",
"62553", "Malinau",
"62551", "Tarakan",
"62357", "Pacitan",
"62351", "Madiun\/Magetan\/Ngawi",
"62353", "Bojonegoro",
"62322", "Lamongan",
"62485", "Sengkang",
"62983", "Serui",
"62981", "Biak",
"62913", "Namlea",
"62911", "Ambon",
"62365", "Negara\/Gilimanuk",
"62435", "Gorontalo",
"62565", "Sintang",
"62924", "Tobelo",
"62380", "Kupang",
"62719", "Manggar\/Tanjung\ Pandan",
"62917", "Dobo",
"62739", "Bintuhan\/Manna",
"62374", "Bima",
"62658", "Singkil",
"62625", "Parapat\/Ajibata\/Simanindo",
"62773", "Ranai",
"62771", "Tanjung\ Pinang",
"62251", "Bogor",
"62253", "Pandeglang",
"62777", "Karimun",
"62742", "Kualatungkal\/Tebing\ Tinggi",
"62754", "Sijunjung",
"62265", "Tasikmalaya\/Banjar\/Ciamis",
"62656", "Tapaktuan",
"62712", "Kayu\ Agung\/Tanjung\ Raja",
"62280", "West\ Cilacap",
"62732", "Curup",
"62274", "Yogyakarta",
"62531", "Sampit",
"62426", "Mamuju",
"62980", "Ransiki",
"62511", "Banjarmasin",
"62324", "Pamekasan",
"62513", "Muara\ Teweh",
"62517", "Kandangan\/Barabai\/Rantau\/Negara",
"62331", "Jember",
"62333", "Banyuwangi",
"62537", "Kuala\ Kurun",
"62461", "Luwuk",
"62463", "Bunta",
"62383", "Larantuka",
"62381", "Ende",
"62372", "Alas\/Taliwang",
"62541", "Samarinda\/Tenggarong",
"62543", "Tanah\ Grogot",
"62901", "Timika",
"62405", "Kolaka",
"62951", "Sorong",
"62922", "Jailolo",
"62428", "Polewali",
"62343", "Pasuruan",
"62910", "Bandanaira",
"62957", "Kaimana",
"62341", "Malang\/Batu",
"62387", "Waingapu\/Waikabubak",
"62296", "Blora",
"62744", "Muara\ Tebo",
"62646", "Idi",
"62768", "Tembilahan",
"62231", "Cirebon",
"62233", "Majalengka",
"62766", "Bengkalis",
"62734", "Muara\ Enim",
"62283", "Tegal\/Brebes",
"62281", "Banyumas\/Purbalingga",
"62272", "Klaten",
"62727", "Kalianda",
"62298", "Salatiga\/Ambarawa",
"62929", "Sanana",
"62714", "Sekayu",
"6244", "Marisa",
"62636", "Panyabungan\/Sibuhuan",
"62723", "Blambangan\ Umpu",
"62752", "Bukittinggi\/Padang\ Panjang\/Payakumbuh\/Batusangkar",
"62721", "Bandar\ Lampung",
"62287", "Kebumen\/Karanganyar",
"62746", "Bangko",
"62718", "Koba\/Toboali",
"62294", "Kendal",
"6231", "Surabaya",
"62267", "Karawang",
"62738", "Muara\ Aman",
"62644", "Bireuen",
"62263", "Cianjur",
"62261", "Sumedang",
"62764", "Siak\ Sri\ Indrapura",
"62736", "Bengkulu\ City",
"62748", "Sungai\ Penuh\/Kerinci",
"62716", "Muntok",
"62634", "Padang\ Sidempuan\/Sipirok",
"62627", "Subulussalam\/Sidikalang\/Salak",
"62652", "Sabang",
"62623", "Kisaran\/Tanjung\ Balai",
"62621", "Tebing\ Tinggi\/Sei\ Rampah",
"62561", "Pontianak\/Mempawah",
"62563", "Ngabang",
"62326", "Masalembu\ Islands",
"6221", "Greater\ Jakarta",
"62417", "Malino",
"62363", "Amlapura",
"62361", "Denpasar",
"62915", "Bula",
"62411", "Makassar\/Maros\/Sungguminasa",
"62413", "Bulukumba\/Bantaeng",
"62567", "Putussibau",
"62431", "Manado\/Tomohon\/Tondano",
"62526", "Tamiang\ Layang\/Tanjung",
"6224", "Semarang\/Demak",
"62328", "Sumenep",
"62355", "Tulungagung\/Trenggalek",
"62481", "Watampone",
"62659", "Blangpidie",
"62528", "Purukcahu",
"62252", "Rangkasbitung",
"62743", "Muara\ Bulian",
"62741", "Jambi\ City",
"62655", "Meulaboh",
"62747", "Muarabungo",
"62628", "Kabanjahe\/Sibolangit",
"62266", "Sukabumi",
"62234", "Indramayu",
"62772", "Tarempa",
"62713", "Prabumulih\/Talang\ Ubi",
"62711", "Palembang",
"62731", "Lahat",
"62733", "Lubuklinggau\/Muara\ Beliti",
"62284", "Pemalang",
"62724", "Kotabumi",
"62737", "Arga\ Makmur\/Mukomuko",
"62717", "Pangkal\ Pinang\/Sungailiat",
"62626", "Pangururan",
"62323", "Sampang",
"62352", "Ponorogo",
"62321", "Mojokerto\/Jombang",
"62534", "Ketapang",
"62971", "Merauke",
"62527", "Amuntai",
"62552", "Tanjungselor",
"62464", "Ampana",
"62327", "Kangean\/Masalembu",
"62779", "Tanjungbatu",
"62334", "Lumajang",
"62366", "Klungkung\/Bangli",
"62370", "Mataram\/Praya",
"62568", "Nanga\ Pinoh",
"62384", "Bajawa",
"62418", "Takalar",
"62368", "Baturiti",
"6261", "Medan",
"62438", "Bitung",
"62548", "Bontang",
"62388", "Kefamenanu\/Soe",
"62421", "Parepare\/Pinrang",
"62452", "Poso",
"62423", "Makale\/Rantepao",
"62564", "Sanggau",
"62536", "Palangkaraya\/Kasongan",
"62402", "Baubau",
"62434", "Kotamobagu",
"6222", "Bandung\/Cimahi",
"62427", "Barru",
"62336", "Jember",
"62414", "Kepulauan\ Selayar",
"62956", "Fakfak",
"62538", "Kuala\ Pembuang",
"62484", "Watansoppeng",
"62518", "Kotabaru\/Batulicin",
"62386", "Kalabahi",
"62338", "Situbondo",
"62275", "Purworejo",
"62643", "Takengon",
"62641", "Langsa",
"62293", "Magelang\/Mungkid\/Temanggung",
"62291", "Demak\/Jepara\/Kudus",
"62297", "Karimun\ Jawa",
"62755", "Solok",
"62264", "Purwakarta\/Cikampek",
"62728", "Liwa",
"62631", "Sibolga\/Pandan",
"62633", "Tarutung\/Dolok\ Sanggul",
"62286", "Banjarnegara\/Wonosobo",
"62763", "Selatpanjang",
"62761", "Pekanbaru",
"62767", "Bagansiapiapi",
"62650", "Sinabang",
"62726", "Menggala",
"62624", "Panipahan\/Labuhanbatu",
"62969", "Wamena",};
$areanames{id} = {"6221", "Jabodetabek",
"62736", "Kota\ Bengkulu",
"62741", "Kota\ Jambi",
"62282", "Cilacap\ Timur",
"62280", "Cilacap\ Barat",};

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