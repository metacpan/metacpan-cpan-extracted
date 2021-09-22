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
our $VERSION = 1.20210921211832;

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
$areanames{en} = {"62405", "Kolaka",
"62756", "Painan",
"62623", "Kisaran\/Tanjung\ Balai",
"62567", "Putussibau",
"62431", "Manado\/Tomohon\/Tondano",
"62323", "Sampang",
"62719", "Manggar\/Tanjung\ Pandan",
"62326", "Masalembu\ Islands",
"62645", "Lhokseumawe",
"62777", "Karimun",
"62365", "Negara\/Gilimanuk",
"62741", "Jambi\ City",
"62422", "Majene",
"62512", "Pelaihari",
"62753", "Lubuk\ Sikaping",
"62233", "Majalengka",
"62718", "Koba\/Toboali",
"62761", "Pekanbaru",
"62626", "Pangururan",
"62918", "Saumlaku",
"62642", "Blang\ Kejeren",
"62644", "Bireuen",
"62261", "Sumedang",
"62733", "Lubuklinggau\/Muara\ Beliti",
"62362", "Singaraja",
"62253", "Pandeglang",
"62342", "Blitar",
"62451", "Palu",
"62463", "Bunta",
"62404", "Wanci",
"62402", "Baubau",
"62956", "Fakfak",
"62736", "Bengkulu\ City",
"62366", "Klungkung\/Bangli",
"62646", "Idi",
"62325", "Sangkapura",
"62387", "Waingapu\/Waikabubak",
"62625", "Parapat\/Ajibata\/Simanindo",
"62289", "Bumiayu",
"62721", "Bandar\ Lampung",
"62403", "Raha",
"62464", "Ampana",
"62462", "Banggai",
"62539", "Kuala\ Kuayan",
"62651", "Banda\ Aceh\/Jantho\/Lamno",
"62343", "Pasuruan",
"62527", "Amuntai",
"62755", "Solok",
"62417", "Malino",
"62363", "Amlapura",
"62252", "Rangkasbitung",
"62254", "Serang\/Merak",
"62901", "Timika",
"62734", "Muara\ Enim",
"62732", "Curup",
"62351", "Madiun\/Magetan\/Ngawi",
"62643", "Takengon",
"62538", "Kuala\ Pembuang",
"62952", "Teminabuan",
"62234", "Indramayu",
"62232", "Kuningan",
"62331", "Jember",
"62752", "Bukittinggi\/Padang\ Panjang\/Payakumbuh\/Batusangkar",
"62754", "Sijunjung",
"62297", "Karimun\ Jawa",
"6261", "Medan",
"62513", "Muara\ Teweh",
"62423", "Makale\/Rantepao",
"6231", "Surabaya",
"62631", "Sibolga\/Pandan",
"62735", "Baturaja\/Martapura\/Muaradua",
"62955", "Bintuni",
"62380", "Kupang",
"62324", "Pamekasan",
"62322", "Lamongan",
"62921", "Soasiu",
"62622", "Pematangsiantar\/Pematang\ Raya\/Limapuluh",
"62624", "Panipahan\/Labuhanbatu",
"62410", "Pangkep",
"62465", "Kolonedale",
"62426", "Mamuju",
"62545", "Melak",
"62911", "Ambon",
"62383", "Larantuka",
"62526", "Tamiang\ Layang\/Tanjung",
"62565", "Sintang",
"62420", "Enrekang",
"62413", "Bulukumba\/Bantaeng",
"62969", "Wamena",
"62484", "Watansoppeng",
"62482", "Sinjai",
"62274", "Yogyakarta",
"62272", "Klaten",
"62371", "Sumbawa",
"62458", "Tentena",
"62386", "Kalabahi",
"62485", "Sengkang",
"62293", "Magelang\/Mungkid\/Temanggung",
"62275", "Purworejo",
"62975", "Tanahmerah",
"62427", "Barru",
"62517", "Kandangan\/Barabai\/Rantau\/Negara",
"6244", "Marisa",
"62772", "Tarempa",
"62438", "Bitung",
"62769", "Rengat\/Air\ Molek",
"62542", "Balikpapan",
"62748", "Sungai\ Penuh\/Kerinci",
"62296", "Blora",
"62562", "Singkawang\/Sambas\/Bengkayang",
"62564", "Sanggau",
"62768", "Tembilahan",
"62711", "Palembang",
"62338", "Situbondo",
"62563", "Ngabang",
"62929", "Sanana",
"62627", "Subulussalam\/Sidikalang\/Salak",
"62551", "Tarakan",
"62385", "Labuhanbajo\/Ruteng",
"62543", "Tanah\ Grogot",
"62776", "Dabosingkep",
"62327", "Kangean\/Masalembu",
"62730", "Pagar\ Alam\/Kota\ Agung",
"62773", "Ranai",
"62639", "Gunung\ Sitoli",
"62757", "Balai\ Selasa",
"62525", "Buntok",
"62292", "Purwodadi",
"62294", "Kendal",
"62659", "Blangpidie",
"62957", "Kaimana",
"62737", "Arga\ Makmur\/Mukomuko",
"62728", "Liwa",
"62620", "Pangkalan\ Brandan",
"62522", "Ampah",
"62414", "Kepulauan\ Selayar",
"62295", "Pati\/Rembang",
"62273", "Wonogiri",
"62658", "Singkil",
"62276", "Boyolali",
"62471", "Palopo",
"62281", "Banyumas\/Purbalingga",
"62358", "Nganjuk",
"62729", "Pringsewu",
"62384", "Bajawa",
"62382", "Maumere",
"62981", "Biak",
"62531", "Sampit",
"62621", "Tebing\ Tinggi\/Sei\ Rampah",
"62766", "Bengkalis",
"62725", "Metro",
"62298", "Salatiga\/Ambarawa",
"62746", "Bangko",
"62321", "Mojokerto\/Jombang",
"62922", "Jailolo",
"62924", "Tobelo",
"62743", "Muara\ Bulian",
"62632", "Balige",
"62980", "Ransiki",
"62634", "Padang\ Sidempuan\/Sipirok",
"62355", "Tulungagung\/Trenggalek",
"6221", "Greater\ Jakarta",
"62280", "West\ Cilacap",
"62763", "Selatpanjang",
"62231", "Cirebon",
"62655", "Meulaboh",
"62334", "Lumajang",
"62332", "Bondowoso",
"62751", "Padang\/Pariaman",
"62635", "Gunung\ Tua",
"62251", "Bogor",
"62388", "Kefamenanu\/Soe",
"62902", "Agats",
"62731", "Lahat",
"62263", "Cianjur",
"62354", "Kediri",
"62352", "Ponorogo",
"62951", "Sorong",
"62419", "Jeneponto",
"62652", "Sabang",
"62654", "Calang",
"62335", "Probolinggo",
"62389", "Atambua",
"62724", "Kotabumi",
"62722", "Tanggamus",
"62528", "Purukcahu",
"62418", "Takalar",
"62461", "Luwuk",
"62453", "Tolitoli",
"62266", "Sukabumi",
"62537", "Kuala\ Kurun",
"62287", "Kebumen\/Karanganyar",
"62966", "Sarmi",
"62435", "Gorontalo",
"62356", "Rembang\/Tuban",
"62917", "Dobo",
"62452", "Poso",
"62401", "Kendari",
"62723", "Blambangan\ Umpu",
"62656", "Tapaktuan",
"62726", "Menggala",
"62765", "Dumai\/Duri\/Bagan\ Batu\/Ujung\ Tanjung",
"62341", "Malang\/Batu",
"62653", "Sigli",
"62641", "Langsa",
"62264", "Purwakarta\/Cikampek",
"62262", "Garut",
"62353", "Bojonegoro",
"62745", "Sarolangun",
"62361", "Denpasar",
"62568", "Nanga\ Pinoh",
"62421", "Parepare\/Pinrang",
"62511", "Banjarmasin",
"62779", "Tanjungbatu",
"62333", "Banyuwangi",
"62764", "Siak\ Sri\ Indrapura",
"62762", "Bangkinang\/Pasir\ Pengaraian",
"62548", "Bontang",
"62265", "Tasikmalaya\/Banjar\/Ciamis",
"62910", "Bandanaira",
"62633", "Tarutung\/Dolok\ Sanggul",
"62742", "Kualatungkal\/Tebing\ Tinggi",
"62744", "Muara\ Tebo",
"62778", "Batam",
"62434", "Kotamobagu",
"62432", "Tahuna",
"62923", "Morotai",
"62636", "Panyabungan\/Sibuhuan",
"62717", "Pangkal\ Pinang\/Sungailiat",
"62549", "Sangatta",
"62336", "Jember",
"62370", "Mataram\/Praya",
"62738", "Muara\ Aman",
"62282", "East\ Cilacap",
"62284", "Pemalang",
"62474", "Malili",
"62381", "Ende",
"62984", "Nabire",
"62913", "Namlea",
"62534", "Ketapang",
"62532", "Pangkalan\ Bun",
"62376", "Selong",
"62727", "Kalianda",
"62739", "Bintuhan\/Manna",
"62657", "Bakongan",
"62373", "Dompu",
"62411", "Makassar\/Maros\/Sungguminasa",
"62916", "Tual",
"62357", "Pacitan",
"62716", "Muntok",
"62628", "Kabanjahe\/Sibolangit",
"62291", "Demak\/Jepara\/Kudus",
"62328", "Sumenep",
"62285", "Pekalongan\/Batang\/Comal",
"62927", "Labuha",
"62629", "Kutacane",
"6224", "Semarang\/Demak",
"62713", "Prabumulih\/Talang\ Ubi",
"62650", "Sinabang",
"62554", "Tanjung\ Redeb",
"62552", "Tanjungselor",
"62553", "Malinau",
"62428", "Polewali",
"62518", "Kotabaru\/Batulicin",
"62561", "Pontianak\/Mempawah",
"62712", "Kayu\ Agung\/Tanjung\ Raja",
"62714", "Sekayu",
"62260", "Subang",
"62915", "Bula",
"62541", "Samarinda\/Tenggarong",
"62771", "Tanjung\ Pinang",
"62747", "Muarabungo",
"62556", "Nunukan",
"62767", "Bagansiapiapi",
"62267", "Karawang",
"62536", "Palangkaraya\/Kasongan",
"62986", "Manokwari",
"62430", "Amurang",
"6222", "Bandung\/Cimahi",
"62967", "Jayapura",
"62286", "Banjarnegara\/Wonosobo",
"62271", "Surakarta\/Sukoharjo\/Karanganyar\/Sragen",
"62481", "Watampone",
"62374", "Bima",
"62372", "Alas\/Taliwang",
"62971", "Merauke",
"62408", "Unaaha",
"6270", "Tebing\ Tinggi",
"62760", "Teluk\ Kuantan",
"62457", "Donggala",
"62715", "Belinyu",
"62914", "Masohi",
"62983", "Serui",
"62368", "Baturiti",
"62283", "Tegal\/Brebes",
"62473", "Masamba",};
$areanames{id} = {"62741", "Kota\ Jambi",
"62736", "Kota\ Bengkulu",
"62280", "Cilacap\ Barat",
"6221", "Jabodetabek",
"62282", "Cilacap\ Timur",};

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