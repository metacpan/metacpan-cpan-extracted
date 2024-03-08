# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20240308154351;

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
$areanames{en} = {"62408", "Unaaha",
"62426", "Mamuju",
"62420", "Enrekang",
"62652", "Sabang",
"62356", "Rembang\/Tuban",
"62713", "Prabumulih\/Talang\ Ubi",
"62549", "Sangatta",
"62538", "Kuala\ Pembuang",
"62376", "Selong",
"62462", "Banggai",
"62370", "Mataram\/Praya",
"62413", "Bulukumba\/Bantaeng",
"62383", "Larantuka",
"62263", "Cianjur",
"62342", "Blitar",
"62646", "Idi",
"62517", "Kandangan\/Barabai\/Rantau\/Negara",
"62552", "Tanjungselor",
"62726", "Menggala",
"62762", "Bangkinang\/Pasir\ Pengaraian",
"62729", "Pringsewu",
"62564", "Sanggau",
"62715", "Belinyu",
"62754", "Sijunjung",
"62231", "Cirebon",
"62721", "Bandar\ Lampung",
"62641", "Langsa",
"62385", "Labuhanbajo\/Ruteng",
"62265", "Tasikmalaya\/Banjar\/Ciamis",
"62371", "Sumbawa",
"62474", "Malili",
"62324", "Pamekasan",
"62541", "Samarinda\/Tenggarong",
"62421", "Parepare\/Pinrang",
"62902", "Agats",
"62927", "Labuha",
"62351", "Madiun\/Magetan\/Ngawi",
"62628", "Kabanjahe\/Sibolangit",
"62924", "Tobelo",
"62262", "Garut",
"62382", "Maumere",
"62343", "Pasuruan",
"62739", "Bintuhan\/Manna",
"62457", "Donggala",
"62748", "Sungai\ Penuh\/Kerinci",
"62298", "Salatiga\/Ambarawa",
"62951", "Sorong",
"62327", "Kangean\/Masalembu",
"62553", "Malinau",
"62736", "Bengkulu\ City",
"62368", "Baturiti",
"62730", "Pagar\ Alam\/Kota\ Agung",
"62763", "Selatpanjang",
"62971", "Merauke",
"62653", "Sigli",
"62528", "Purukcahu",
"62712", "Kayu\ Agung\/Tanjung\ Raja",
"62757", "Balai\ Selasa",
"62567", "Putussibau",
"62430", "Amurang",
"62463", "Bunta",
"62777", "Karimun",
"62431", "Manado\/Tomohon\/Tondano",
"62334", "Lumajang",
"62983", "Serui",
"62765", "Dumai\/Duri\/Bagan\ Batu\/Ujung\ Tanjung",
"62655", "Meulaboh",
"62254", "Serang\/Merak",
"62731", "Lahat",
"62274", "Yogyakarta",
"6261", "Medan",
"62465", "Kolonedale",
"62918", "Saumlaku",
"62956", "Fakfak",
"62733", "Lubuklinggau\/Muara\ Beliti",
"62760", "Teluk\ Kuantan",
"62338", "Situbondo",
"62766", "Bengkalis",
"62556", "Nunukan",
"62722", "Tanggamus",
"62518", "Kotabaru\/Batulicin",
"62642", "Blang\ Kejeren",
"62232", "Kuningan",
"62769", "Rengat\/Air\ Molek",
"62955", "Bintuni",
"62372", "Alas\/Taliwang",
"62659", "Blangpidie",
"62537", "Kuala\ Kurun",
"62901", "Timika",
"62352", "Ponorogo",
"62975", "Tanahmerah",
"62656", "Tapaktuan",
"62914", "Masohi",
"62542", "Balikpapan",
"62422", "Majene",
"62650", "Sinabang",
"62981", "Biak",
"62744", "Muara\ Tebo",
"62294", "Kendal",
"62624", "Panipahan\/Labuhanbatu",
"62986", "Manokwari",
"62735", "Baturaja\/Martapura\/Muaradua",
"62980", "Ransiki",
"62651", "Banda\ Aceh\/Jantho\/Lamno",
"62461", "Luwuk",
"62284", "Pemalang",
"62967", "Jayapura",
"6244", "Marisa",
"62551", "Tarakan",
"62435", "Gorontalo",
"62341", "Malang\/Batu",
"62761", "Pekanbaru",
"62373", "Dompu",
"62432", "Tahuna",
"62778", "Batam",
"62719", "Manggar\/Tanjung\ Pandan",
"62568", "Nanga\ Pinoh",
"62353", "Bojonegoro",
"62527", "Amuntai",
"62716", "Muntok",
"62423", "Makale\/Rantepao",
"62543", "Tanah\ Grogot",
"62287", "Kebumen\/Karanganyar",
"62419", "Jeneponto",
"62389", "Atambua",
"62732", "Curup",
"62643", "Takengon",
"62328", "Sumenep",
"62723", "Blambangan\ Umpu",
"62627", "Subulussalam\/Sidikalang\/Salak",
"62380", "Kupang",
"62233", "Majalengka",
"62260", "Subang",
"62458", "Tentena",
"62297", "Karimun\ Jawa",
"62747", "Muarabungo",
"62386", "Kalabahi",
"62266", "Sukabumi",
"62410", "Pangkep",
"6231", "Surabaya",
"62952", "Teminabuan",
"62917", "Dobo",
"62404", "Wanci",
"62484", "Watansoppeng",
"62261", "Sumedang",
"62381", "Ende",
"62411", "Makassar\/Maros\/Sungguminasa",
"62355", "Tulungagung\/Trenggalek",
"62534", "Ketapang",
"62545", "Melak",
"62711", "Palembang",
"6270", "Tebing\ Tinggi",
"62645", "Lhokseumawe",
"62725", "Metro",
"62634", "Padang\ Sidempuan\/Sipirok",
"6224", "Semarang\/Demak",
"62325", "Sangkapura",
"62966", "Sarmi",
"62531", "Sampit",
"62414", "Kepulauan\ Selayar",
"62481", "Watampone",
"62922", "Jailolo",
"62264", "Purwakarta\/Cikampek",
"62384", "Bajawa",
"62969", "Wamena",
"62401", "Kendari",
"62755", "Solok",
"62631", "Sibolga\/Pandan",
"62714", "Sekayu",
"62565", "Sintang",
"62728", "Liwa",
"62512", "Pelaihari",
"62639", "Gunung\ Sitoli",
"62323", "Sampang",
"62453", "Tolitoli",
"62636", "Panyabungan\/Sibuhuan",
"62767", "Bagansiapiapi",
"62332", "Bondowoso",
"62473", "Masamba",
"62753", "Lubuk\ Sikaping",
"62358", "Nganjuk",
"62272", "Klaten",
"62539", "Kuala\ Kuayan",
"62548", "Bontang",
"62428", "Polewali",
"62657", "Bakongan",
"62773", "Ranai",
"62252", "Rangkasbitung",
"62536", "Palangkaraya\/Kasongan",
"62563", "Ngabang",
"6221", "Greater\ Jakarta",
"62275", "Purworejo",
"62464", "Ampana",
"62361", "Denpasar",
"62281", "Banyumas\/Purbalingga",
"62654", "Calang",
"62916", "Tual",
"62910", "Bandanaira",
"62621", "Tebing\ Tinggi\/Sei\ Rampah",
"62291", "Demak\/Jepara\/Kudus",
"62741", "Jambi\ City",
"62764", "Siak\ Sri\ Indrapura",
"62923", "Morotai",
"62554", "Tanjung\ Redeb",
"62335", "Probolinggo",
"62717", "Pangkal\ Pinang\/Sungailiat",
"62273", "Wonogiri",
"62526", "Tamiang\ Layang\/Tanjung",
"62752", "Bukittinggi\/Padang\ Panjang\/Payakumbuh\/Batusangkar",
"62253", "Pandeglang",
"62438", "Bitung",
"62772", "Tarempa",
"62562", "Singkawang\/Sambas\/Bengkayang",
"62984", "Nabire",
"62322", "Lamongan",
"62513", "Muara\ Teweh",
"62911", "Ambon",
"62387", "Waingapu\/Waikabubak",
"62620", "Pangkalan\ Brandan",
"62267", "Karawang",
"62746", "Bangko",
"62296", "Blora",
"62452", "Poso",
"62289", "Bumiayu",
"62626", "Pangururan",
"62417", "Malino",
"62333", "Banyuwangi",
"62280", "West\ Cilacap",
"62629", "Kutacane",
"62286", "Banjarnegara\/Wonosobo",
"62738", "Muara\ Aman",
"62366", "Klungkung\/Bangli",
"62913", "Namlea",
"62511", "Banjarmasin",
"62434", "Kotamobagu",
"62331", "Jember",
"62525", "Buntok",
"62365", "Negara\/Gilimanuk",
"62285", "Pekalongan\/Batang\/Comal",
"62271", "Surakarta\/Sukoharjo\/Karanganyar\/Sragen",
"62295", "Pati\/Rembang",
"62745", "Sarolangun",
"62625", "Parapat\/Ajibata\/Simanindo",
"62734", "Muara\ Enim",
"62929", "Sanana",
"6222", "Bandung\/Cimahi",
"62251", "Bogor",
"62532", "Pangkalan\ Bun",
"62915", "Bula",
"62402", "Baubau",
"62427", "Barru",
"62658", "Singkil",
"62276", "Boyolali",
"62357", "Pacitan",
"62921", "Soasiu",
"62482", "Sinjai",
"62336", "Jember",
"62768", "Tembilahan",
"62363", "Amlapura",
"62283", "Tegal\/Brebes",
"62632", "Balige",
"62743", "Muara\ Bulian",
"62293", "Magelang\/Mungkid\/Temanggung",
"62623", "Kisaran\/Tanjung\ Balai",
"62727", "Kalianda",
"62644", "Bireuen",
"62724", "Kotabumi",
"62234", "Indramayu",
"62635", "Gunung\ Tua",
"62751", "Padang\/Pariaman",
"62561", "Pontianak\/Mempawah",
"62771", "Tanjung\ Pinang",
"62451", "Palu",
"62354", "Kediri",
"62321", "Mojokerto\/Jombang",
"62957", "Kaimana",
"62374", "Bima",
"62471", "Palopo",
"62405", "Kolaka",
"62485", "Sengkang",
"62362", "Singaraja",
"62282", "East\ Cilacap",
"62737", "Arga\ Makmur\/Mukomuko",
"62633", "Tarutung\/Dolok\ Sanggul",
"62622", "Pematangsiantar\/Pematang\ Raya\/Limapuluh",
"62388", "Kefamenanu\/Soe",
"62292", "Purwodadi",
"62742", "Kualatungkal\/Tebing\ Tinggi",
"62418", "Takalar",
"62326", "Masalembu\ Islands",
"62776", "Dabosingkep",
"62403", "Raha",
"62522", "Ampah",
"62779", "Tanjungbatu",
"62756", "Painan",
"62718", "Koba\/Toboali",};
$areanames{id} = {"62736", "Kota\ Bengkulu",
"62282", "Cilacap\ Timur",
"62741", "Kota\ Jambi",
"6221", "Jabodetabek",
"62280", "Cilacap\ Barat",};
my $timezones = {
               '' => [
                       'Asia/Jakarta',
                       'Asia/Jayapura',
                       'Asia/Makassar'
                     ],
               '007' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '1' => [
                        'Asia/Jakarta',
                        'Asia/Makassar'
                      ],
               '2' => [
                        'Asia/Jakarta'
                      ],
               '31' => [
                         'Asia/Jakarta'
                       ],
               '32' => [
                         'Asia/Jakarta'
                       ],
               '33' => [
                         'Asia/Jakarta'
                       ],
               '34' => [
                         'Asia/Jakarta'
                       ],
               '35' => [
                         'Asia/Jakarta'
                       ],
               '36' => [
                         'Asia/Makassar'
                       ],
               '37' => [
                         'Asia/Makassar'
                       ],
               '379' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '38' => [
                         'Asia/Makassar'
                       ],
               '4' => [
                        'Asia/Makassar'
                      ],
               '403' => [
                          'Asia/Jayapura',
                          'Asia/Makassar'
                        ],
               '458' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '511' => [
                          'Asia/Makassar'
                        ],
               '512' => [
                          'Asia/Makassar'
                        ],
               '513' => [
                          'Asia/Jakarta'
                        ],
               '515' => [
                          'Asia/Jakarta'
                        ],
               '516' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '517' => [
                          'Asia/Makassar'
                        ],
               '518' => [
                          'Asia/Makassar'
                        ],
               '519' => [
                          'Asia/Jakarta'
                        ],
               '522' => [
                          'Asia/Jakarta'
                        ],
               '525' => [
                          'Asia/Jakarta'
                        ],
               '526' => [
                          'Asia/Makassar'
                        ],
               '527' => [
                          'Asia/Makassar'
                        ],
               '528' => [
                          'Asia/Jakarta'
                        ],
               '53' => [
                         'Asia/Jakarta'
                       ],
               '539' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '54' => [
                         'Asia/Makassar'
                       ],
               '55' => [
                         'Asia/Makassar'
                       ],
               '56' => [
                         'Asia/Jakarta'
                       ],
               '6' => [
                        'Asia/Jakarta'
                      ],
               '7' => [
                        'Asia/Jakarta'
                      ],
               '8' => [
                        'Asia/Jakarta'
                      ],
               '80' => [
                         'Asia/Jakarta',
                         'Asia/Makassar'
                       ],
               '811' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '818' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '819' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '824' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '829' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '831' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '833' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '834' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '839' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '853' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '868' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '876' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '887' => [
                          'Asia/Jakarta',
                          'Asia/Makassar'
                        ],
               '90' => [
                         'Asia/Jayapura'
                       ],
               '91' => [
                         'Asia/Jayapura'
                       ],
               '915' => [
                          'Asia/Jakarta',
                          'Asia/Jayapura'
                        ],
               '92' => [
                         'Asia/Jayapura'
                       ],
               '920' => [
                          'Asia/Jakarta'
                        ],
               '951' => [
                          'Asia/Jayapura'
                        ],
               '952' => [
                          'Asia/Jakarta',
                          'Asia/Jayapura'
                        ],
               '955' => [
                          'Asia/Jayapura'
                        ],
               '956' => [
                          'Asia/Jayapura'
                        ],
               '957' => [
                          'Asia/Jayapura'
                        ],
               '958' => [
                          'Asia/Jakarta'
                        ],
               '962' => [
                          'Asia/Jayapura'
                        ],
               '963' => [
                          'Asia/Jakarta'
                        ],
               '966' => [
                          'Asia/Jayapura'
                        ],
               '967' => [
                          'Asia/Jayapura'
                        ],
               '969' => [
                          'Asia/Jayapura'
                        ],
               '971' => [
                          'Asia/Jayapura'
                        ],
               '975' => [
                          'Asia/Jayapura'
                        ],
               '979' => [
                          'Asia/Jakarta'
                        ],
               '98' => [
                         'Asia/Jayapura'
                       ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+62|\D)//g;
      my $self = bless({ country_code => '62', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '62', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;