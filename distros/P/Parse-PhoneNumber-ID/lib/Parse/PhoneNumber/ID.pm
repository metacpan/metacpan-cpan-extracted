package Parse::PhoneNumber::ID;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-07'; # DATE
our $DIST = 'Parse-PhoneNumber-ID'; # DIST
our $VERSION = '0.170'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Function::Fallback::CoreOrPP qw(clone);
use Perinci::Sub::Util qw(gen_modified_sub);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(extract_idn_phones parse_idn_phone
                    list_idn_operators list_idn_area_codes);

# from: http://id.wikipedia.org/wiki/Daftar_kode_telepon_di_Indonesia
# last updated: 2011-03-08
my %area_codes = (
    '0627' => {province=>'aceh', cities=>'Kota Subulussalam'},
    '0629' => {province=>'aceh', cities=>'Kutacane (Kabupaten Aceh Tenggara)'},
    '0641' => {province=>'aceh', cities=>'Kota Langsa'},
    '0642' => {province=>'aceh', cities=>'Blang Kejeren (Kabupaten Gayo Lues)'},
    '0643' => {province=>'aceh', cities=>'Takengon (Kabupaten Aceh Tengah)'},
    '0644' => {province=>'aceh', cities=>'Bireuen (Kabupaten Bireuen)'},
    '0645' => {province=>'aceh', cities=>'Kota Lhokseumawe'},
    '0646' => {province=>'aceh', cities=>'Idi (Kabupaten Aceh Timur)'},
    '0650' => {province=>'aceh', cities=>'Sinabang (Kabupaten Simeulue)'},
    '0651' => {province=>'aceh', cities=>'Kota Banda Aceh - Jantho (Kabupaten Aceh Besar) - Lamno (Kabupaten Aceh Jaya)'},
    '0652' => {province=>'aceh', cities=>'Kota Sabang'},
    '0653' => {province=>'aceh', cities=>'Sigli (Kabupaten Pidie)'},
    '0654' => {province=>'aceh', cities=>'Calang (Kabupaten Aceh Jaya)'},
    '0655' => {province=>'aceh', cities=>'Meulaboh (Kabupaten Aceh Barat)'},
    '0656' => {province=>'aceh', cities=>'Tapaktuan (Kabupaten Aceh Selatan)'},
    '0657' => {province=>'aceh', cities=>'Bakongan (Kabupaten Aceh Selatan)'},
    '0658' => {province=>'aceh', cities=>'Singkil (Kabupaten Aceh Singkil)'},
    '0659' => {province=>'aceh', cities=>'Blangpidie (Kabupaten Aceh Barat Daya)'},

    '061'  => {province=>'sumut', cities=>'Kota Medan - Kota Binjai - Stabat (Kabupaten Langkat)'},
    '0620' => {province=>'sumut', cities=>'Pangkalan Brandan (Kabupaten Langkat)'},
    '0621' => {province=>'sumut', cities=>'Kota Tebing Tinggi'},
    '0622' => {province=>'sumut', cities=>'Kota Pematangsiantar'},
    '0623' => {province=>'sumut', cities=>'Kisaran (Kabupaten Asahan) - Kota Tanjung Balai'},
    '0624' => {province=>'sumut', cities=>'Rantau Prapat (Kabupaten Labuhanbatu)'},
    '0625' => {province=>'sumut', cities=>'Parapat (Kabupaten Simalungun)'},
    '0626' => {province=>'sumut', cities=>'Pangururan (Kabupaten Samosir)'},
    '0627' => {province=>'sumut', cities=>'Sidikalang (Kabupaten Dairi) - Salak (Kabupaten Pakpak Bharat)'},
    '0628' => {province=>'sumut', cities=>'Kabanjahe (Kabupaten Karo)'},
    '0630' => {province=>'sumut', cities=>'Teluk Dalam (Kabupaten Nias Selatan)'},
    '0631' => {province=>'sumut', cities=>'Kota Sibolga'},
    '0636' => {province=>'sumut', cities=>'Balige (Kabupaten Toba Samosir)'},
    '0633' => {province=>'sumut', cities=>'Tarutung (Kabupaten Tapanuli Utara)'},
    '0634' => {province=>'sumut', cities=>'Kota Padang Sidempuan'},
    '0635' => {province=>'sumut', cities=>'Gunung Tua (Kabupaten Padang Lawas Utara)'},
    '0636' => {province=>'sumut', cities=>'Panyabungan (Kabupaten Mandailing Natal)'},
    '0638' => {province=>'sumut', cities=>'Barus (Kabupaten Tapanuli Tengah)'},
    '0639' => {province=>'sumut', cities=>'Kota Gunung Sitoli'},

    '0751' => {province=>'sumbar', cities=>'Kota Padang - Kota Pariaman'},
    '0752' => {province=>'sumbar', cities=>'Kota Bukittinggi - Kota Padang Panjang - Kota Payakumbuh - Batusangkar (Kabupaten Tanah Datar)'},
    '0753' => {province=>'sumbar', cities=>'Lubuk Sikaping (Kabupaten Pasaman)'},
    '0754' => {province=>'sumbar', cities=>'Kabupaten Sijunjung'},
    '0755' => {province=>'sumbar', cities=>'Kota Solok - Kabupaten Solok Selatan - Alahan Panjang (Kabupaten Solok)'},
    '0756' => {province=>'sumbar', cities=>'Painan (Kabupaten Pesisir Selatan)'},
    '0757' => {province=>'sumbar', cities=>'Balai Selasa (Kabupaten Agam)'},
    '0759' => {province=>'sumbar', cities=>'Tuapejat (Kabupaten Kepulauan Mentawai)'},

    '0760' => {province=>'riau', cities=>'Teluk Kuantan (Kabupaten Kuantan Singingi)'},
    '0761' => {province=>'riau', cities=>'Kota Pekanbaru - Pangkalan Kerinci (Kabupaten Pelalawan)'},
    '0762' => {province=>'riau', cities=>'Bangkinang (Kabupaten Kampar)'},
    '0763' => {province=>'riau', cities=>'Selatpanjang (Kabupaten Bengkalis)'},
    '0764' => {province=>'riau', cities=>'Siak Sri Indrapura (Kabupaten Siak)'},
    '0765' => {province=>'riau', cities=>'Kota Dumai - Duri (Kabupaten Bengkalis)'},
    '0766' => {province=>'riau', cities=>'Bengkalis (Kabupaten Bengkalis)'},
    '0767' => {province=>'riau', cities=>'Bagan Siapi-api (Kabupaten Rokan Hilir)'},
    '0768' => {province=>'riau', cities=>'Tembilahan (Kabupaten Indragiri Hilir)'},
    '0769' => {province=>'riau', cities=>'Rengat - Air Molek (Kabupaten Indragiri Hulu)'},

    '0771' => {province=>'kepriau', cities=>'Kota Tanjung Pinang'},
    '0772' => {province=>'kepriau', cities=>'Tarempa (Kabupaten Kepulauan Anambas)'},
    '0773' => {province=>'kepriau', cities=>'Ranai (Kabupaten Natuna)'},
    '0776' => {province=>'kepriau', cities=>'Dabosingkep (Kabupaten Lingga)'},
    '0777' => {province=>'kepriau', cities=>'Tanjung Balai Karimun (Kabupaten Karimun)'},
    '0778' => {province=>'kepriau', cities=>'Kota Batam'},
    '0779' => {province=>'kepriau', cities=>'Tanjungbatu (Kabupaten Karimun)'},

    '0740' => {province=>'jambi', cities=>'Mendahara - Muara Sabak (Kabupaten Tanjung Jabung Timur)'},
    '0741' => {province=>'jambi', cities=>'Kota Jambi'},
    '0742' => {province=>'jambi', cities=>'Kualatungkal (Kabupaten Tanjung Jabung Barat)'},
    '0743' => {province=>'jambi', cities=>'Muara Bulian (Kabupaten Batanghari)'},
    '0744' => {province=>'jambi', cities=>'Muara Tebo (Kabupaten Tebo)'},
    '0745' => {province=>'jambi', cities=>'Sarolangun (Kabupaten Sarolangun)'},
    '0746' => {province=>'jambi', cities=>'Bangko (Kabupaten Merangin)'},
    '0747' => {province=>'jambi', cities=>'Muarabungo (Kabupaten Bungo)'},
    '0748' => {province=>'jambi', cities=>'Kota Sungai Penuh'},

    '0711' => {province=>'sumsel', cities=>'Kota Palembang - Pangkalan Balai - Betung (Kabupaten Banyuasin) - Indralaya (Kabupaten Ogan Ilir)'},
    '0712' => {province=>'sumsel', cities=>'Kayu Agung (Kabupaten Ogan Komering Ilir)'},
    '0713' => {province=>'sumsel', cities=>'Kota Prabumulih'},
    '0714' => {province=>'sumsel', cities=>'Sekayu (Kabupaten Musi Banyuasin)'},
    '0730' => {province=>'sumsel', cities=>'Kota Pagar Alam'},
    '0731' => {province=>'sumsel', cities=>'Lahat (Kabupaten Lahat)'},
    '0733' => {province=>'sumsel', cities=>'Kota Lubuklinggau - Pendopo (Kabupaten Lahat)'},
    '0734' => {province=>'sumsel', cities=>'Muara Enim (Kabupaten Muara Enim)'},
    '0735' => {province=>'sumsel', cities=>'Baturaja (Kabupaten Ogan Komering Ulu)'},

    '0715' => {province=>'kbb', cities=>'Belinyu (Kabupaten Bangka)'},
    '0716' => {province=>'kbb', cities=>'Muntok (Kabupaten Bangka Barat)'},
    '0717' => {province=>'kbb', cities=>'Kota Pangkal Pinang - Sungailiat (Kabupaten Bangka)'},
    '0718' => {province=>'kbb', cities=>'Koba (Kabupaten Bangka Tengah) - Toboali (Kabupaten Bangka Selatan)'},
    '0719' => {province=>'kbb', cities=>'Manggar (Kabupaten Belitung Timur) - Tanjung Pandan (Kabupaten Belitung)'},

    '0732' => {province=>'bengkulu', cities=>'Curup (Kabupaten Rejang Lebong)'},
    '0736' => {province=>'bengkulu', cities=>'Kota Bengkulu - Lais (Kabupaten Bengkulu Utara)'},
    '0737' => {province=>'bengkulu', cities=>'Arga Makmur (Kabupaten Bengkulu Utara) - Mukomuko (Kabupaten Mukomuko)'},
    '0738' => {province=>'bengkulu', cities=>'Muara Aman (Kabupaten Lebong)'},
    '0739' => {province=>'bengkulu', cities=>'Bintuhan (Kabupaten Kaur) - Kota Manna (Kabupaten Bengkulu Selatan)'},

    '0721' => {province=>'lampung', cities=>'Kota Bandar Lampung'},
    '0722' => {province=>'lampung', cities=>'Kota Agung (Kabupaten Tanggamus)'},
    '0723' => {province=>'lampung', cities=>'Blambangan Umpu (Kabupaten Way Kanan)'},
    '0724' => {province=>'lampung', cities=>'Kotabumi (Kabupaten Lampung Utara)'},
    '0725' => {province=>'lampung', cities=>'Kota Metro'},
    '0726' => {province=>'lampung', cities=>'Menggala (Kabupaten Tulang Bawang)'},
    '0727' => {province=>'lampung', cities=>'Kalianda (Kabupaten Lampung Selatan)'},
    '0728' => {province=>'lampung', cities=>'Kota Liwa (Kabupaten Lampung Barat)'},
    '0729' => {province=>'lampung', cities=>'Pringsewu (Kabupaten Pringsewu)'},

    '021'  => {province=>'dki/banten/jabar', cities=>'Kepulauan Seribu - Jakarta Barat - Jakarta Pusat - Jakarta Selatan - Jakarta Timur - Jakarta Utara/Tigaraksa (Kabupaten Tangerang) - Kota Tangerang - Kota Tangerang Selatan/Kota Bekasi - Cikarang (Kabupaten Bekasi) - Kota Depok - Cibinong (Kabupaten Bogor)'},

    '0252' => {province=>'banten', cities=>'Rangkasbitung (Kabupaten Lebak)'},
    '0253' => {province=>'banten', cities=>'Pandeglang - Labuan (Kabupaten Pandeglang)'},
    '0254' => {province=>'banten', cities=>'Kota Serang - Kabupaten Serang - Merak (Kota Cilegon)'},
    '0257' => {province=>'banten', cities=>'Pasauran (Kabupaten Serang)'},

    '022'  => {province=>'jabar', cities=>'Kota Bandung - Kota Cimahi - Soreang (Kabupaten Bandung) - Lembang - Ngamprah (Kabupaten Bandung Barat)'},
    '0231' => {province=>'jabar', cities=>'Kota Cirebon - Sumber - Losari (Kabupaten Cirebon)'},
    '0232' => {province=>'jabar', cities=>'Kabupaten Kuningan'},
    '0233' => {province=>'jabar', cities=>'Kadipaten (Kabupaten Majalengka)'},
    '0234' => {province=>'jabar', cities=>'Jatibarang (Kabupaten Indramayu)'},
    '0251' => {province=>'jabar', cities=>'Kota Bogor'},
    '0260' => {province=>'jabar', cities=>'Pamanukan (Kabupaten Subang)'},
    '0261' => {province=>'jabar', cities=>'Kabupaten Sumedang'},
    '0262' => {province=>'jabar', cities=>'Kabupaten Garut'},
    '0263' => {province=>'jabar', cities=>'Kabupaten Cianjur'},
    '0264' => {province=>'jabar', cities=>'Kabupaten Purwakarta - Cikampek)'},
    '0265' => {province=>'jabar', cities=>'Kota Tasikmalaya - Kadipaten - Singaparna (Kabupaten Tasikmalaya) - Kota Banjar - Ciamis - Pangandaran (Kabupaten Ciamis)'},
    '0266' => {province=>'jabar', cities=>'Kota Sukabumi - Palabuhanratu (Kabupaten Sukabumi)'},
    '0267' => {province=>'jabar', cities=>'Kabupaten Karawang'},

    '024'  => {province=>'jateng', cities=>'Semarang, Ungaran'},
    '0271' => {province=>'jateng', cities=>'Surakarta (Solo), Kartasura, Sukoharjo, Karanganyar, Sragen'},
    '0272' => {province=>'jateng', cities=>'Klaten'},
    '0273' => {province=>'jateng', cities=>'Wonogiri'},
    '0275' => {province=>'jateng', cities=>'Purworejo,Kutoarjo'},
    '0276' => {province=>'jateng', cities=>'Boyolali'},
    '0280' => {province=>'jateng', cities=>'Majenang, Sidareja (Kabupaten Cilacap bagian barat)'},
    '0281' => {province=>'jateng', cities=>'Purwokerto, Banyumas, Purbalingga'},
    '0282' => {province=>'jateng', cities=>'Cilacap (bagian timur)'},
    '0283' => {province=>'jateng', cities=>'Tegal, Slawi, Brebes'},
    '0284' => {province=>'jateng', cities=>'Pemalang'},
    '0285' => {province=>'jateng', cities=>'Pekalongan, Batang (bagian barat)'},
    '0286' => {province=>'jateng', cities=>'Banjarnegara, Wonosobo'},
    '0287' => {province=>'jateng', cities=>'Kebumen, Gombong'},
    '0289' => {province=>'jateng', cities=>'Bumiayu (Kabupaten Brebes bagian selatan)'},
    '0291' => {province=>'jateng', cities=>'Demak, Jepara, Kudus'},
    '0292' => {province=>'jateng', cities=>'Purwodadi'},
    '0293' => {province=>'jateng', cities=>'Magelang, Mungkid, Temanggung'},
    '0294' => {province=>'jateng', cities=>'Kendal, Kaliwungu, Weleri, Batang (bagian timur)'},
    '0295' => {province=>'jateng', cities=>'Pati, Rembang, Lasem'},
    '0296' => {province=>'jateng', cities=>'Blora, Cepu'},
    '0297' => {province=>'jateng', cities=>'Karimun Jawa'},
    '0298' => {province=>'jateng', cities=>'Salatiga, Ambarawa (Kabupaten Semarang bagian tengah dan selatan)'},
    '0356' => {province=>'jateng', cities=>'Rembang bagian Timur (wilayah yang berbatasan dengan Tuban)'},

    '0274' => {province=>'diy', cities=>'Yogyakarta, Sleman, Wates, Bantul, Wonosari'},

    '031'  => {province=>'jatim', cities=>'Surabaya, Gresik, Sidoarjo, Bangkalan'},
    '0321' => {province=>'jatim', cities=>'Mojokerto, Jombang'},
    '0322' => {province=>'jatim', cities=>'Lamongan, Babat'},
    '0323' => {province=>'jatim', cities=>'Sampang'},
    '0324' => {province=>'jatim', cities=>'Pamekasan'},
    '0325' => {province=>'jatim', cities=>'Sangkapura (Bawean)'},
    '0327' => {province=>'jatim', cities=>'Kepulauan Kangean, Kepulauan Masalembu'},
    '0328' => {province=>'jatim', cities=>'Sumenep'},
    '0331' => {province=>'jatim', cities=>'Jember'},
    '0332' => {province=>'jatim', cities=>'Bondowoso, Sukosari, Prajekan'},
    '0333' => {province=>'jatim', cities=>'Banyuwangi, Muncar'},
    '0334' => {province=>'jatim', cities=>'Lumajang'},
    '0335' => {province=>'jatim', cities=>'Probolinggo, Kraksaan'},
    '0336' => {province=>'jatim', cities=>'Ambulu, Puger (Kabupaten Jember bagian selatan)'},
    '0338' => {province=>'jatim', cities=>'Situbondo, Besuki'},
    '0341' => {province=>'jatim', cities=>'Malang, Kepanjen, Batu'},
    '0342' => {province=>'jatim', cities=>'Blitar, Wlingi'},
    '0343' => {province=>'jatim', cities=>'Pasuruan, Pandaan, Gempol'},
    '0351' => {province=>'jatim', cities=>'Madiun, Caruban, Magetan, Ngawi'},
    '0352' => {province=>'jatim', cities=>'Ponorogo'},
    '0353' => {province=>'jatim', cities=>'Bojonegoro'},
    '0354' => {province=>'jatim', cities=>'Kediri, Pare'},
    '0355' => {province=>'jatim', cities=>'Tulungagung, Trenggalek'},
    '0356' => {province=>'jatim', cities=>'Tuban'},
    '0357' => {province=>'jatim', cities=>'Pacitan'},
    '0358' => {province=>'jatim', cities=>'Nganjuk, Kertosono'},

    '0361' => {province=>'bali', cities=>'Denpasar, Gianyar, Kuta, Tabanan, Tampaksiring, Ubud'},
    '0362' => {province=>'bali', cities=>'Singaraja'},
    '0363' => {province=>'bali', cities=>'Amlapura'},
    '0365' => {province=>'bali', cities=>'Negara, Gilimanuk'},
    '0366' => {province=>'bali', cities=>'Klungkung, Kintamani'},
    '0368' => {province=>'bali', cities=>'Baturiti'},

    '0364' => {province=>'ntb', cities=>'Kota Mataram'},
    '0370' => {province=>'ntb', cities=>'Mataram, Praya'},
    '0371' => {province=>'ntb', cities=>'Sumbawa'},
    '0372' => {province=>'ntb', cities=>'Alas, Taliwang'},
    '0373' => {province=>'ntb', cities=>'Dompu'},
    '0374' => {province=>'ntb', cities=>'Bima'},
    '0376' => {province=>'ntb', cities=>'Selong'},

    '0380' => {province=>'ntt', cities=>'Kupang, Baa (Roti)'},
    '0381' => {province=>'ntt', cities=>'Ende'},
    '0382' => {province=>'ntt', cities=>'Maumere'},
    '0383' => {province=>'ntt', cities=>'Larantuka'},
    '0384' => {province=>'ntt', cities=>'Bajawa'},
    '0385' => {province=>'ntt', cities=>'Labuhanbajo, Ruteng'},
    '0386' => {province=>'ntt', cities=>'Kalabahi'},
    '0387' => {province=>'ntt', cities=>'Waingapu, Waikabubak'},
    '0388' => {province=>'ntt', cities=>'Kefamenanu, Soe'},
    '0389' => {province=>'ntt', cities=>'Atambua'},

    '0561' => {province=>'kalbar', cities=>'Pontianak, Mempawah'},
    '0562' => {province=>'kalbar', cities=>'Sambas, Singkawang, Bengkayang'},
    '0563' => {province=>'kalbar', cities=>'Ngabang'},
    '0564' => {province=>'kalbar', cities=>'Sanggau'},
    '0565' => {province=>'kalbar', cities=>'Sintang'},
    '0567' => {province=>'kalbar', cities=>'Putussibau'},
    '0568' => {province=>'kalbar', cities=>'Nanga Pinoh'},
    '0534' => {province=>'kalbar', cities=>'Ketapang'},

    '0513' => {province=>'kalteng', cities=>'Kuala Kapuas, Pulang Pisau'},
    '0519' => {province=>'kalteng', cities=>'Muara Teweh'},
    '0522' => {province=>'kalteng', cities=>'Ampah (Dusun Tengah, Barito Timur)'},
    '0525' => {province=>'kalteng', cities=>'Buntok'},
    '0526' => {province=>'kalteng', cities=>'Tamiang Layang'},
    '0528' => {province=>'kalteng', cities=>'Purukcahu'},
    '0531' => {province=>'kalteng', cities=>'Sampit'},
    '0532' => {province=>'kalteng', cities=>'Pangkalan Bun, Kumai'},
    '0534' => {province=>'kalteng', cities=>'Kendawangan'},
    '0536' => {province=>'kalteng', cities=>'Palangkaraya, Kasongan'},
    '0537' => {province=>'kalteng', cities=>'Kuala Kurun'},
    '0538' => {province=>'kalteng', cities=>'Kuala Pembuang'},
    '0539' => {province=>'kalteng', cities=>'Kuala Kuayan (Mentaya Hulu, Kotawaringin Timur)'},

    '0511' => {province=>'kalsel', cities=>'Banjarmasin, Banjarbaru, Martapura, Marabahan'},
    '0512' => {province=>'kalsel', cities=>'Pelaihari'},
    '0517' => {province=>'kalsel', cities=>'Kandangan, Barabai, Rantau, Negara'},
    '0518' => {province=>'kalsel', cities=>'Kotabaru, Batulicin'},
    '0526' => {province=>'kalsel', cities=>'Tanjung'},
    '0527' => {province=>'kalsel', cities=>'Amuntai'},

    '0541' => {province=>'kaltim', cities=>'Samarinda, Tenggarong'},
    '0542' => {province=>'kaltim', cities=>'Balikpapan'},
    '0543' => {province=>'kaltim', cities=>'Tanah Grogot'},
    '0545' => {province=>'kaltim', cities=>'Melak'},
    '0548' => {province=>'kaltim', cities=>'Bontang'},
    '0549' => {province=>'kaltim', cities=>'Sangatta'},
    '0551' => {province=>'kaltim', cities=>'Tarakan'},
    '0552' => {province=>'kaltim', cities=>'Tanjungselor'},
    '0553' => {province=>'kaltim', cities=>'Malinau'},
    '0554' => {province=>'kaltim', cities=>'Tanjung Redeb'},
    '0556' => {province=>'kaltim', cities=>'Nunukan'},

    '0430' => {province=>'sulut', cities=>'Amurang'},
    '0431' => {province=>'sulut', cities=>'Manado, Tomohon, Tondano'},
    '0432' => {province=>'sulut', cities=>'Tahuna'},
    '0434' => {province=>'sulut', cities=>'Kotamobagu'},
    '0438' => {province=>'sulut', cities=>'Bitung'},

    '0435' => {province=>'gorontalo', cities=>'Gorontalo, Limboto'},
    '0443' => {province=>'gorontalo', cities=>'Marisa'},

    '0450' => {province=>'sulteng', cities=>'Parigi'},
    '0451' => {province=>'sulteng', cities=>'Palu'},
    '0452' => {province=>'sulteng', cities=>'Poso'},
    '0453' => {province=>'sulteng', cities=>'Tolitoli'},
    '0457' => {province=>'sulteng', cities=>'Donggala'},
    '0458' => {province=>'sulteng', cities=>'Tentena'},
    '0461' => {province=>'sulteng', cities=>'Luwuk'},
    '0462' => {province=>'sulteng', cities=>'Banggai'},
    '0463' => {province=>'sulteng', cities=>'Bunta'},
    '0464' => {province=>'sulteng', cities=>'Ampana'},
    '0465' => {province=>'sulteng', cities=>'Kolonedale'},
    '0455' => {province=>'sulteng', cities=>'kotaraya,moutong'},

    '0422' => {province=>'sulbar', cities=>'Majene'},
    '0426' => {province=>'sulbar', cities=>'Mamuju'},
    '0428' => {province=>'sulbar', cities=>'Polewali'},

    '0410' => {province=>'sulsel', cities=>'Pangkep'},
    '0411' => {province=>'sulsel', cities=>'Makassar, Maros, Sungguminasa'},
    '0413' => {province=>'sulsel', cities=>'Bulukumba'},
    '0414' => {province=>'sulsel', cities=>'Bantaeng (Selayar)'},
    '0417' => {province=>'sulsel', cities=>'Malino'},
    '0418' => {province=>'sulsel', cities=>'Takalar'},
    '0419' => {province=>'sulsel', cities=>'Janeponto'},
    '0420' => {province=>'sulsel', cities=>'Enrekang'},
    '0421' => {province=>'sulsel', cities=>'Parepare, Pinrang'},
    '0422' => {province=>'sulsel', cities=>'Manene'},
    '0423' => {province=>'sulsel', cities=>'Makale, Rantepao'},
    '0427' => {province=>'sulsel', cities=>'Barru'},
    '0428' => {province=>'sulsel', cities=>'Wonomulyo'},
    '0471' => {province=>'sulsel', cities=>'Palopo'},
    '0472' => {province=>'sulsel', cities=>'Pitumpanua'},
    '0473' => {province=>'sulsel', cities=>'Masamba'},
    '0474' => {province=>'sulsel', cities=>'Malili'},
    '0475' => {province=>'sulsel', cities=>'Soroako'},
    '0481' => {province=>'sulsel', cities=>'Watampone'},
    '0482' => {province=>'sulsel', cities=>'Sinjai'},
    '0484' => {province=>'sulsel', cities=>'Watansoppeng'},
    '0485' => {province=>'sulsel', cities=>'Sengkang'},

    '0401' => {province=>'sultra', cities=>'Kendari'},
    '0402' => {province=>'sultra', cities=>'Baubau'},
    '0403' => {province=>'sultra', cities=>'Raha'},
    '0404' => {province=>'sultra', cities=>'Wanci'},
    '0405' => {province=>'sultra', cities=>'Kolaka'},
    '0408' => {province=>'sultra', cities=>'Unaaha'},

    '0910' => {province=>'maluku', cities=>'Bandanaira'},
    '0911' => {province=>'maluku', cities=>'Ambon'},
    '0913' => {province=>'maluku', cities=>'Namlea'},
    '0914' => {province=>'maluku', cities=>'Masohi'},
    '0915' => {province=>'maluku', cities=>'Bula'},
    '0916' => {province=>'maluku', cities=>'Tual'},
    '0917' => {province=>'maluku', cities=>'Dobo'},
    '0918' => {province=>'maluku', cities=>'Saumlaku'},
    '0921' => {province=>'maluku', cities=>'Soasiu'},
    '0922' => {province=>'maluku', cities=>'Jailolo'},
    '0923' => {province=>'maluku', cities=>'Morotai'},
    '0924' => {province=>'maluku', cities=>'Tobelo'},
    '0927' => {province=>'maluku', cities=>'Labuha'},
    '0929' => {province=>'maluku', cities=>'Sanana'},
    '0931' => {province=>'maluku', cities=>'Saparua'},
    '0901' => {province=>'maluku', cities=>'Timika, Tembagapura'},

    '0902' => {province=>'papua', cities=>'Agats (Asmat)'},
    '0951' => {province=>'papua', cities=>'Sorong'},
    '0952' => {province=>'papua', cities=>'Teminabuan'},
    '0955' => {province=>'papua', cities=>'Bintuni'},
    '0956' => {province=>'papua', cities=>'Fakfak'},
    '0957' => {province=>'papua', cities=>'Kaimana'},
    '0966' => {province=>'papua', cities=>'Sarmi'},
    '0967' => {province=>'papua', cities=>'Jayapura, Abepura'},
    '0969' => {province=>'papua', cities=>'Wamena'},
    '0971' => {province=>'papua', cities=>'Merauke'},
    '0975' => {province=>'papua', cities=>'Tanahmerah'},
    '0980' => {province=>'papua', cities=>'Ransiki'},
    '0981' => {province=>'papua', cities=>'Biak'},
    '0983' => {province=>'papua', cities=>'Serui'},
    '0984' => {province=>'papua', cities=>'Nabire'},
    '0985' => {province=>'papua', cities=>'Nabire'},
    '0986' => {province=>'papua', cities=>'Manokwari'},
);

my %cell_prefixes = (
    '0811'  => {operator=>'telkomsel', product=>'halo',              is_gsm=>1},
    '0812'  => {operator=>'telkomsel', product=>'halo/simpati',      is_gsm=>1},
    '0813'  => {operator=>'telkomsel', product=>'simpati',           is_gsm=>1},
    '0814'  => {operator=>'indosat',   product=>'matrix',            is_gsm=>1},
    '0815'  => {operator=>'indosat',   product=>'matrix/mentari',    is_gsm=>1},
    '0816'  => {operator=>'indosat',   product=>'matrix/mentari',    is_gsm=>1},
    '0817'  => {operator=>'xl',                                      is_gsm=>1},
    '0818'  => {operator=>'xl',                                      is_gsm=>1},
    '0819'  => {operator=>'xl',                                      is_gsm=>1},
    '0821'  => {operator=>'telkomsel', product=>'simpati',           is_gsm=>1},
    '0822'  => {operator=>'telkomsel', product=>'simpati',           is_gsm=>1},
    '0823'  => {operator=>'telkomsel', product=>'as',                is_gsm=>1},
    '0828'  => {operator=>'sampoerna', product=>'ceria',             is_gsm=>1},
    #'08315' => {operator=>'nts',                                     is_gsm=>1},
    '0831'  => {operator=>'axis',                                    is_gsm=>1},
    '0832'  => {operator=>'axis',                                    is_gsm=>1},
    '0838'  => {operator=>'axis',                                    is_gsm=>1},
    '0852'  => {operator=>'telkomsel', product=>'as',                is_gsm=>1},
    '0853'  => {operator=>'telkomsel', product=>'as',                is_gsm=>1}, # fress
    '0855'  => {operator=>'indosat',   product=>'matrix bright',     is_gsm=>1},
    '0856'  => {operator=>'indosat',   product=>'im3',               is_gsm=>1},
    '0857'  => {operator=>'indosat',   product=>'im3',               is_gsm=>1},
    '0858'  => {operator=>'indosat',   product=>'mentari',           is_gsm=>1},
    '0859'  => {operator=>'xl',                                      is_gsm=>1},
    #'08681' => {operator=>'psn',       product=>'byru',              is_gsm=>0}, # satellite
    '0868'  => {operator=>'psn',       product=>'byru',              is_gsm=>0}, # satellite
    '0877'  => {operator=>'xl',        product=>'axiata',            is_gsm=>1},
    '0878'  => {operator=>'xl',        product=>'axiata',            is_gsm=>1},
    '0879'  => {operator=>'xl',        product=>'axiata',            is_gsm=>1},
    '0881'  => {operator=>'smartfren',                               is_cdma=>1},
    '0882'  => {operator=>'smartfren',                               is_cdma=>1},
    '0883'  => {operator=>'smartfren',                               is_cdma=>1},
    '0884'  => {operator=>'smartfren',                               is_cdma=>1},
    '0885'  => {operator=>'smartfren',                               is_cdma=>1},
    '0886'  => {operator=>'smartfren',                               is_cdma=>1},
    '0887'  => {operator=>'smartfren',                               is_cdma=>1},
    '0888'  => {operator=>'smartfren',                               is_cdma=>1},
    '0889'  => {operator=>'smartfren',                               is_cdma=>1},
    '0896'  => {operator=>'three',                                   is_gsm=>1},
    '0897'  => {operator=>'three',                                   is_gsm=>1},
    '0898'  => {operator=>'three',                                   is_gsm=>1},
    '0899'  => {operator=>'three',                                   is_gsm=>1},
);

my %fwa_prefixes = (
    30 => {operator=>'indosat', product=>'starone'},
    32 => {operator=>'telkom', product=>'flexi'},
    #39 is fixed telcom
    40 => {operator=>'telkom', product=>'flexi'},
    50 => {operator=>'telkom', product=>'flexi'},
    60 => {operator=>'indosat', product=>'starone'},
    62 => {operator=>'indosat', product=>'starone'},
    68 => {operator=>'telkom', product=>'flexi'},
    70 => {operator=>'telkom', product=>'flexi'},
    710 => {operator=>'telkom', product=>'flexi'},
    711 => {operator=>'telkom', product=>'flexi'},
    712 => {operator=>'telkom', product=>'flexi'},
    713 => {operator=>'telkom', product=>'flexi'},
    714 => {operator=>'telkom', product=>'flexi'},
    715 => {operator=>'telkom', product=>'flexi'},
    716 => {operator=>'telkom', product=>'flexi'},
    717 => {}, # land
    718 => {}, # land
    719 => {}, # land
    72 => {}, # land
    73 => {}, # land
    74 => {}, # land
    75 => {}, # land
    76 => {}, # land
    77 => {}, # land
    78 => {}, # land
    79 => {}, # land
    80 => {operator=>'esia'},
    81 => {operator=>'esia'}, # jkt
    82 => {operator=>'esia'}, # assumed 8x
    83 => {operator=>'esia'},
    84 => {operator=>'esia'}, # assumed 8x
    85 => {operator=>'esia'}, # jkt
    86 => {operator=>'esia'}, # assumed 8x
    87 => {operator=>'esia'}, # jkt
    88 => {operator=>'esia'}, # assumed 8x
    89 => {operator=>'esia'},
    90 => {operator=>'esia'}, # assumed 9x
    91 => {operator=>'esia'},
    92 => {operator=>'esia'},
    93 => {operator=>'esia'},
    94 => {operator=>'esia'}, # assumed 9x
    95 => {operator=>'esia'}, # assumed 9x
    96 => {operator=>'esia'}, # assumed 9x
    97 => {operator=>'esia'}, # assumed 9x
    98 => {operator=>'esia'},
    99 => {operator=>'esia'},
);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Parse Indonesian phone numbers',
};

my $extract_args = {
    text => {
        summary     => 'Text containing phone numbers to extract from',
        schema      => 'str*',
        req         => 1,
        pos         => 0,
    },
    max_numbers => {
        schema      => 'int',
    },
    default_area_code => {
        summary     => 'When encountering a number without area code, use this',
        schema      => ['str' => {
            match   => qr/^0\d{2,3}$/,
        }],
        description => <<'_',

If you want to extract numbers that doesn't contain area code (e.g. 7123 4567),
you'll need to provide this.

_
    },
    level             => {
        summary     => 'How hard should the function extract numbers (1-9)',
        schema      => ['int' => {
            default     => 5,
            between     => [1, 9],
        }],
        description => <<'_',

The higher the level, the harder this function will try finding phone numbers,
but the higher the risk of false positives will be. E.g. in text
'123456789012345' with level=5 it will not find a phone number, but with level=9
it might assume, e.g. 1234567890 to be a phone number. Normally leaving level at
default level is fine.

_
    },
};

$SPEC{extract_idn_phones} = {
    v            => 1.1,
    summary      => 'Extract phone number(s) from text',
    description  => <<'_',

Extracts phone number(s) from text. Return an array of one or more parsed phone
number structure (a hash). Understands the list of known area codes and cellular
operators, as well as other information. Understands various syntax e.g.
+62.22.1234567, (022) 123-4567, 022-123-4567 ext 102, and even things like
7123456/57 (2 adjacent numbers).

Extraction algorithm is particularly targetted at classified ads text in
Indonesian language, but should be quite suitable for any other normal text.

Non-Indonesian phone numbers (e.g. +65 12 3456 7890) will still be extracted,
but without any other detailed information other than country code.

_
    args         => $extract_args,
    result_naked => 1,
};
sub extract_idn_phones {
    my %args  = @_;
    my $text  = $args{text};
    my $level = $args{level} // 5;
    my $defac = $args{default_area_code};

    log_trace("text = %s", $text);

    my %nums;  # normalized num => {_level=>..., _order=>..., raw=>..., ...}

    # note: capital prefix means it has capturing group
    state $_Cc_prefix_local;
    state $_Kprefix_local;
    state $_Cc_karea_local_ext;
    state $_Karea_local_ext;
    state $_Prefix_local;
    state $_Klocal;
    state $_Local;
    state $_Indicator;
    state $_sep;
    state $_start_w;
    state $_start_d;
    state $_end_d;
    state $_Adjacent;
    if (!$_Prefix_local) {
        # known prefixes
        $_start_w     = '(?:\A|\b)';
        $_start_d     = '(?:\A|(?<=\D))';
        $_end_d       = '(?:\z|(?=\D))';
        my $_kprefix  =
            '(?:'.join("|",sort(keys %area_codes, keys %cell_prefixes)).')';
        my $_karea    = '(?:'.join("|",sort keys %area_codes).')';
        my @_kareanz;
        for (keys %area_codes) { s/^0//; push @_kareanz, $_ }
        my $_kareanz  = '(?:'.join("|",sort @_kareanz).')';
        # XXX currently ignores 08681
        my $_prefix   = '(?:0[1-9](?:[0-9]){1,2})';
        my $_prefixnz = '(?:[1-9](?:[0-9]){1,2})';
        $_sep         = '(?:\s+|\.|-)';
        my $_cc       = '(?:\+[1-9][0-9]{1,2})';

        $_Local       = '(\d{5,8}|(?:\d'.$_sep.'?){4,7}\d)';

        # heuristic: we know that is FWA is 7-8 digits, there is no prefix 1
        # (?). also (not for exact reason though, just minimizing false
        # negatives) be stricter (no in-between seps).
        my @_klocal;
        for (keys %fwa_prefixes) {
            my $l = length($_);
            push @_klocal, sprintf("%s\\d{%d,%d}", $_, 7-$l, 8-$l);
        }
        $_Klocal      = '(' . join("|", @_klocal, '[2-9]{5,7}'). ')';

        my $_Ext      =
            qr!((?:extension|ekstensi|ext?|ekst?)(?:\s|:|\.)*(?:\d{1,5}))!ix;

        $_Kprefix_local = # (021) 123-4567, 021-123-4567
            qr!(\(\s*$_kprefix\s*\)|$_kprefix) $_sep* $_Local!sx;
        $_Prefix_local = # same as above, but w/o checking known prefixes
            qr!(\(\s*$_prefix\s*\)|$_prefix) $_sep* $_Local!sx;
        $_Karea_local_ext = # (021) 123-4567 ext 102, mobile assumed has no ext
            qr!(\(\s*$_karea\s*\)|$_karea) $_sep*
               $_Local $_sep*
               $_Ext!sx;
        $_Cc_prefix_local = # (+62) 22 123-4567, 62 812 123-4567
            qr!(\(\s*$_cc\s*\)|$_cc) $_sep*
               (\(\s*$_prefixnz\s*\)|$_prefixnz) $_sep*
               $_Local!sx;
        $_Cc_karea_local_ext = # (+62) 22 123-4567 ext 1000
            qr!(\(\s*$_cc\s*\)|$_cc) $_sep*
               (\(\s*$_kareanz\s*\)|$_kareanz) $_sep*
               $_Local $_sep*
               $_Ext!sx;
        $_Indicator = qr!(
                             menghubungi|hubungi|hub|
                             contact|kontak|mengontak|mengkontak|
                             nomor|nomer|no|num|
                             to|ke|
                             tele?pon|tilpun|tilp|te?lp|tel|tl?|
                             phone|ph|
                             handphone|h\.?p|ponsel|cellular|cell|
                             faximile|facsimile|faksimile|fax|facs|faks|f
                         )(?:\s*|\.|:)*!ix;
        $_Adjacent = qr!(\s*/\s*\d\d?)!;
    }

    # preprocess text: 0 1 2 3 4 5 -> 012345
    if ($level >= 6) {
        state $_remove_spaces = sub {
            local $_ = shift;
            s/\s//sg;
            $_;
        };
        my $oldtext = $text;
        $text =~ s/((?:\d\s){4,}\d)/$_remove_spaces->($1)/seg;
        log_trace("Preprocess text: remove spaces: %s", $text)
            if $oldtext ne $text;
    }

    # preprocess text: O (letter O) as 0 and l/I/| as 1
    if ($level >= 6) {
        state $diglets = {o=>0, O=>0, l=>1, '|'=>1, I=>1, S=>5};
        state $lets    = join("", keys %$diglets);
        state $_replace_lets = sub {
            my ($lets) = @_;
            $lets =~ s!(.)!defined($diglets->{$1}) ? $diglets->{$1} : $1!eg;
            # when will emacs grok //? grr...
            $lets;
        };
        my $oldtext = $text;
        $text =~ s/((?:[0-9$lets](?:\s+|-|\.)?){5,})/$_replace_lets->($1)/eg;
        log_trace("Preprocess text: letters->digits: %s", $text)
            if $oldtext ne $text;
    }

    # TODO: preprocess text: words as numbers (nol satu delapan ...)

    my $i;
    my @r;

    # first, try to find numbers tacked after some indicator, e.g. Hub: blah,
    # T.blah, etc.
    if ($level >= 1) {
        $i = 0; @r = ();
        while ($text =~ m!($_start_w $_Indicator $_sep*
                              $_Cc_karea_local_ext $_end_d)!xg) {
            push @r, $1;
            my $ind = $2;
            my $num = _normalize($3, $4, $5, $6);
            $nums{$num} //= {_level=>2, _order=>++$i, raw=>$1,
                             _pat=>"ind+cc+karea+local+ext"};
            $nums{$num}{is_fax} = 1 if $ind =~ /fax|faks|\bf\b/i;
        }
        _remove_text(\$text, \@r);

        $i = 0; @r = ();
        while ($text =~ m!($_start_w $_Indicator $_sep*
                              $_Cc_prefix_local $_end_d)!xg) {
            push @r, $1;
            my $ind = $2;
            my $num = _normalize($3, $4, $5);
            $nums{$num} //= {_level=>2, _order=>++$i, raw=>$1,
                             _pat=>"ind+cc+prefix+local"};
            $nums{$num}{is_fax} = 1 if $ind =~ /fax|faks|\bf\b/i;
        }
        _remove_text(\$text, \@r);

        $i = 0; @r = ();
        while ($text =~ m!($_start_w $_Indicator $_Karea_local_ext
                              $_end_d)!xg) {
            push @r, $1;
            my $ind = $2;
            my $num = _normalize(undef, $3, $4, $5);
            $nums{$num} //= {_level=>1, _order=>++$i, raw=>$1,
                             _pat=>"ind+karea+local+ext"};
            $nums{$num}{is_fax} = 1 if $ind =~ /fax|faks|\bf\b/i;
        }
        _remove_text(\$text, \@r);

        $i = 0; @r = ();
        while ($text =~ m!($_start_w $_Indicator $_Kprefix_local
                              $_Adjacent? $_end_d)!xg) {
            push @r, $1;
            my $ind = $2;
            my $num = _normalize(undef, $3, $4);
            my $adj = $5;
            $nums{$num} //= {_level=>1, _order=>++$i, raw=>$1,
                             _pat=>"ind+kprefix+local"};
            $nums{$num}{is_fax} = 1 if $ind =~ /fax|faks|\bf\b/;
            _add_adjacent(\%nums, $num, $adj);
        }
        _remove_text(\$text, \@r);
    }
    if ($level >= 2) {
        $i = 0; @r = ();
        while (defined($defac) &&
                   $text =~ m!($_start_w $_Indicator $_sep* $_Klocal
                                  $_Adjacent? $_end_d)!xg) {
            push @r, $1;
            my $ind = $2;
            my $num = _normalize(undef, $defac, $3);
            my $adj = $4;
            $nums{$num}  //= {_level=>2, _order=>++$i, raw=>$1,
                              _pat=>"ind+klocal"};
            $nums{$num}{is_fax} = 1 if $ind =~ /fax|faks|\bf\b/i;
            _add_adjacent(\%nums, $num, $adj);
        }
        _remove_text(\$text, \@r);
    }
    if ($level >= 2) {
        $i = 0; @r = ();
        while ($text =~ m!($_start_w $_Indicator $_sep* $_Prefix_local
                          $_Adjacent? $_end_d)!xg) {
            push @r, $1;
            my $ind = $2;
            my $num = _normalize(undef, $3, $4);
            my $adj = $5;
            $nums{$num}  //= {_level=>2, _order=>++$i, raw=>$1,
                              _pat=>"ind+prefix+local"};
            $nums{$num}{is_fax} = 1 if $ind =~ /fax|faks|\bf\b/i;
            _add_adjacent(\%nums, $num, $adj);
        }
        _remove_text(\$text, \@r);

        $i = 0; @r = ();
        while (defined($defac) &&
                   $text =~ m!($_start_w $_Indicator $_sep* $_Local
                              $_Adjacent? $_end_d)!xg) {
            push @r, $1;
            my $ind = $2;
            my $num = _normalize(undef, $defac, $3);
            my $adj = $4;
            $nums{$num}  //= {_level=>2, _order=>++$i, raw=>$1,
                              _pat=>"ind+local"};
            $nums{$num}{is_fax} = 1 if $ind =~ /fax|faks|\bf\b/i;
            _add_adjacent(\%nums, $num, $adj);
        }
        _remove_text(\$text, \@r);
    }

    # try to find any cc+area+local numbers
    if ($level >= 3) {
        $i = 0; @r = ();
        while ($text =~ m!($_start_d $_Cc_karea_local_ext $_end_d)!xg) {
            push @r, $1;
            $nums{_normalize($2, $3, $4, $5)} //=
                {_level=>3, _order=>++$i, raw=>$1, _pat=>"cc+karea+local+ext"};
        }
        _remove_text(\$text, \@r);

        $i = 0; @r = ();
        while ($text =~ m!($_start_d $_Cc_prefix_local $_end_d)!xg) {
            push @r, $1;
            $nums{_normalize($2, $3, $4)} //=
                {_level=>3, _order=>++$i, raw=>$1, _pat=>"cc+prefix+local"};
        }
        _remove_text(\$text, \@r);
    }

    # try to find numbers with known area code/cell number prefixes
    if ($level >= 3) {
        $i = 0; @r = ();
        while ($text =~ m!($_start_d $_Kprefix_local $_Adjacent? $_end_d)!xg) {
            push @r, $1;
            my $num = _normalize(undef, $2, $3);
            my $adj = $4;
            $nums{$num} //=
                {_level=>3, _order=>++$i, raw=>$1, _pat=>"kprefix+local"};
            _add_adjacent(\%nums, $num, $adj);
        }
        _remove_text(\$text, \@r);
    }

    if ($level >= 5) {
        $i = 0; @r = ();
        while (defined($defac) &&
                   $text =~ m!($_start_w $_Klocal
                                  $_Adjacent? $_end_d)!xg) {
            push @r, $1;
            my $num = _normalize(undef, $defac, $2);
            my $adj = $3;
            $nums{$num}  //= {_level=>2, _order=>++$i, raw=>$1,
                              _pat=>"klocal"};
            _add_adjacent(\%nums, $num, $adj);
        }
        _remove_text(\$text, \@r);
    }

    # try to find any area+local numbers
    if ($level >= 5) {
        $i = 0; @r = ();
        while ($text =~ m!($_start_d $_Prefix_local $_Adjacent? $_end_d)!xg) {
            push @r, $1;
            my $num = _normalize(undef, $2, $3);
            my $adj = $4;
            $nums{$num} //=
                {_level=>5, _order=>++$i, raw=>$1, _pat=>"prefix+local"};
            _add_adjacent(\%nums, $num, $adj);
        }
        _remove_text(\$text, \@r);
    }

    # try to find any local numbers (6-8 digit, because 5 digits are easily
    # confused with indonesian postal code, even though they might still be used
    # in smaller cities)
    if ($level >= 5 && defined($defac)) {
        $i = 0; @r = ();
        while ($text =~ m!($_start_d $_Local $_Adjacent? $_end_d)!xg) {
            push @r, $1;
            my $num = _normalize(undef, $defac, $2);
            my $adj = $3;
            $nums{$num} //=
                {_level=>5, _order=>++$i, raw=>$1, _pat=>"local (defac)"};
            _add_adjacent(\%nums, $num, $adj);
        }
        _remove_text(\$text, \@r);
    }

    for (keys %nums) { $nums{$_}{standard} = $_ }
    log_trace("\\%%nums = %s", \%nums);

    # if we are told to extract only N max_numbers, use the lower level ones and
    # the ones at the end (they are more likely to be numbers, in the case of
    # classified ads)
    my @nums = map { $nums{$_} } sort {
        $nums{$a}{_level} <=> $nums{$b}{_level} ||
            $nums{$b}{_order} <=> $nums{$a}{_order} ||
                $nums{$b}{standard} cmp $nums{$a}{standard}
    } keys %nums;
    if (defined($args{max_numbers}) && $args{max_numbers} > 0 &&
            @nums > $args{max_numbers}
    ) {
        splice @nums, $args{max_numbers};
    }

    # sort again according to order (ascending), this is what most people expect
    @nums = sort {$a->{_order} <=> $b->{_order}} @nums;

    # remove internal data
    for my $num (@nums) {
        #for (keys %$num) { delete $num->{$_} if /^_/ }
        _add_info($num);
    }

    log_trace("\\\@nums = %s", \@nums);

    \@nums;
}

gen_modified_sub(
    output_name => 'parse_idn_phone',
    base_name   => 'extract_idn_phones',
    summary     => 'Alias for extract_idn_phones(..., max_numbers=>1)->[0]',
    remove_args => [qw/max_numbers/],
    output_code => sub {
        my %args = @_;
        my $res = extract_idn_phones(%args, max_numbers=>1);
        $res->[0];
    },
);

sub _normalize {
    my ($cc, $area, $local, $ext) = @_;
    $cc //= "62";
    for ($cc, $area, $local, $ext) { s/\D+//g if defined($_) }
    $area =~ s/^0//;
    "+$cc.$area.$local".(defined($ext) && length($ext) ? ".ext$ext" : "");
}

sub _remove_text {
    my ($textref, $strs) = @_;
    my $oldtext = $$textref;
    for (@$strs) {
        $$textref =~ s/\Q$_\E//;
    }
    log_trace("removed match, text = %s", $$textref)
        if $$textref ne $oldtext;
}

sub _add_adjacent {
    my ($nums, $num, $adj) = @_;
    return unless $adj;
    $adj =~ s/\D//g;
    my $first = substr($num, -length($adj));
    return unless abs($first - $adj) == 1;
    my $num2 = $num;
    substr($num2, -length($adj)) = $adj;
    $nums->{$num2} = clone($nums->{$num});
    $nums->{$num2}{_order} += 0.5;
}

sub _add_info {
    my ($num) = @_;
    my ($cc, $prefix, $local, $ext) =
        $num->{standard} =~ /^\+(\d+)\.(\d+)\.(\d+)(?:\.ext*(\d+))?$/
            or die "BUG: invalid standard format: $num->{standard}";
    $prefix = "0$prefix";
    $num->{country_code} = $cc;
    $num->{area_code}    = $prefix;
    $num->{local_number} = $local;
    $num->{ext}          = $ext if defined($ext);

    # XXX country calling code -> name for other countries
    $num->{country} = 'Indonesia' if $cc eq '62';
    return unless $cc eq '62';

    if (length($local) >= 8) {
        $local =~ /(....)(.+)/;
        $num->{pretty} = "$prefix-$1-$2";
    } else {
        $local =~ /(...)(.+)/;
        $num->{pretty} = "$prefix-$1-$2";
    }

    if (my $c = $cell_prefixes{$prefix}) {
        $num->{is_cell}  = 1;
        $num->{is_gsm}   = $c->{is_gsm}  ? 1:0;
        $num->{is_cdma}  = $c->{is_cdma} ? 1:0;
        $num->{operator} = $c->{operator};
        $num->{product}  = $c->{product};
    } else {
        $num->{is_cell} = 0;
    }

    if (my $a = $area_codes{$prefix}) {
        $num->{is_land}  = 1;
        $num->{province} = $a->{province};
        $num->{cities}   = $a->{cities};
        state $_fwa_prefixes;
        if (!$_fwa_prefixes) {
            $_fwa_prefixes = '(?:'.join("|", keys %fwa_prefixes).')';
        }
        if ($local =~ /^($_fwa_prefixes)/) {
            my $fwa = $fwa_prefixes{$1};
            $num->{is_cdma}  = 1;
            $num->{operator} = $fwa->{operator};
            $num->{product}  = $fwa->{product};
        }
    } else {
        $num->{is_land}  = 0;
    }
}

#$SPEC{list_idn_operators} = {
#    v            => 1.1,
#    summary      => 'Return list of known phone operators',
#    result_naked => 1,
#};
#sub list_idn_operators {
#
#}

#$SPEC{list_idn_area_codes} = {
#    v            => 1.1,
#    summary      => 'Return list of known area codes in Indonesia, '.
#        'along with area names',
#    result_naked => 1,
#};
#sub list_idn_area_codes {
#}

1;
# ABSTRACT: Parse Indonesian phone numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::PhoneNumber::ID - Parse Indonesian phone numbers

=head1 VERSION

This document describes version 0.170 of Parse::PhoneNumber::ID (from Perl distribution Parse-PhoneNumber-ID), released on 2021-05-07.

=head1 SYNOPSIS

 use Parse::PhoneNumber::ID qw(parse_idn_phone extract_idn_phones);
 use Data::Dump;

 dd parse_idn_phone(text => 'Jual dalmatian 2bl lucu2x. Hub: 7123 4567',
                    default_area_code=>'022');

Will print something like:

 { raw          => 'Hub: 7123 4567',
   pretty       => '022-7123-4567',
   standard     => '+62.22.71234567',
   is_cell      => 1,
   is_gsm       => 0,
   is_cdma      => 1,
   operator     => 'telkom',
   product      => 'flexi',
   area_code    => '022',
   province     => 'jabar',
   cities       => 'Bandung, Cimahi, ...',
   local_number => '71234567',
   country      => 'Indonesia',
   country_code => '62',
   ext          => undef, }

To extract more than one numbers in a text:

 my $phones = extract_idn_phones(text => 'some text containing phone number(s):'.
                                         '0812 2345 6789, +62-22-91234567');
 say "There are ", scalar(@$phones), "phone number(s) found in text";
 for (@$phones) { say $_->{pretty} }

=head1 FUNCTIONS


=head2 extract_idn_phones

Usage:

 extract_idn_phones(%args) -> any

Extract phone number(s) from text.

Extracts phone number(s) from text. Return an array of one or more parsed phone
number structure (a hash). Understands the list of known area codes and cellular
operators, as well as other information. Understands various syntax e.g.
+62.22.1234567, (022) 123-4567, 022-123-4567 ext 102, and even things like
7123456/57 (2 adjacent numbers).

Extraction algorithm is particularly targetted at classified ads text in
Indonesian language, but should be quite suitable for any other normal text.

Non-Indonesian phone numbers (e.g. +65 12 3456 7890) will still be extracted,
but without any other detailed information other than country code.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<default_area_code> => I<str>

When encountering a number without area code, use this.

If you want to extract numbers that doesn't contain area code (e.g. 7123 4567),
you'll need to provide this.

=item * B<level> => I<int> (default: 5)

How hard should the function extract numbers (1-9).

The higher the level, the harder this function will try finding phone numbers,
but the higher the risk of false positives will be. E.g. in text
'123456789012345' with level=5 it will not find a phone number, but with level=9
it might assume, e.g. 1234567890 to be a phone number. Normally leaving level at
default level is fine.

=item * B<max_numbers> => I<int>

=item * B<text>* => I<str>

Text containing phone numbers to extract from.


=back

Return value:  (any)



=head2 parse_idn_phone

Usage:

 parse_idn_phone(%args) -> any

Alias for extract_idn_phones(..., max_numbers=E<gt>1)-E<gt>[0].

Extracts phone number(s) from text. Return an array of one or more parsed phone
number structure (a hash). Understands the list of known area codes and cellular
operators, as well as other information. Understands various syntax e.g.
+62.22.1234567, (022) 123-4567, 022-123-4567 ext 102, and even things like
7123456/57 (2 adjacent numbers).

Extraction algorithm is particularly targetted at classified ads text in
Indonesian language, but should be quite suitable for any other normal text.

Non-Indonesian phone numbers (e.g. +65 12 3456 7890) will still be extracted,
but without any other detailed information other than country code.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<default_area_code> => I<str>

When encountering a number without area code, use this.

If you want to extract numbers that doesn't contain area code (e.g. 7123 4567),
you'll need to provide this.

=item * B<level> => I<int> (default: 5)

How hard should the function extract numbers (1-9).

The higher the level, the harder this function will try finding phone numbers,
but the higher the risk of false positives will be. E.g. in text
'123456789012345' with level=5 it will not find a phone number, but with level=9
it might assume, e.g. 1234567890 to be a phone number. Normally leaving level at
default level is fine.

=item * B<text>* => I<str>

Text containing phone numbers to extract from.


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Parse-PhoneNumber-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Parse-PhoneNumber-ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-PhoneNumber-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Parse::PhoneNumber>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
