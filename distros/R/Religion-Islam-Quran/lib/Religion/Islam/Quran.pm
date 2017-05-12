#=Copyright Infomation
#==========================================================
#Module Name       : Religion::Islam::Quran
#Program Author   : Dr. Ahmed Amin Elsheshtawy, Ph.D. Physics, E.E.
#Home Page           : http://www.islamware.com, http://www.mewsoft.com
#Contact Email      : support@islamware.com, support@mewsoft.com
#Copyrights © 2006-2013 IslamWare. All rights reserved.
#==========================================================
package Religion::Islam::Quran;

use Carp;
use strict;
use warnings;
use Exporter;
use utf8;

our @ISA = qw(Exporter);
our @EXPORT = qw();

our $VERSION = '2.01';
our %quran;
our %OrderOfRevelation;
our @QuranLanguages;
our %surah_name;
#==========================================================
our %SajdahCompulsaryAyats = (
														32 => 15, 	#Surah 32 as-Sajdah / Ayat 15
														41 => 38, 	#Surah 41 al-Fusilat / Ayat 38
														53 => 62, 	#Surah 53 an-Najm / Ayat 62
														96 => 19	    #Surah 96 al-Alaq / Ayat 19
													);

our %SajdahRecommendedAyats = (
														7 => 206,		#Sura 7 - Al A'raf (The Elevated Places) - Ayat 206
														13 => 15,		#Sura 13 - Ar Ra'ad (The Thunder) - Ayat 15
														16 => 50,		#Sura 16 - An Nahl (The Bee) - Ayat 50
														17 => 109,	#Sura 17 - Bani Israil (The Children of Israil) - Ayat 109
														19 => 58,		#Sura 19 - Marium (Mary) - Ayat 58
														22 => 18,		#Sura 22 - Al Haj (The Pilgrimage) - Ayat 18
														25 => 60,		#Sura 25 - Al Furqan (The Criterion) - Ayat 60
														27 => 26,		#Sura 27 - An Naml (The Ant) - Ayat 26
														38 => 24,		#Sura 38 - Saad (Saad) - Ayat 24
														84 => 21		#Sura 84 - Al Inshiqaq (The Bursting Asunder) - Ayat 21
													);
	#----------------------------------------------------------------
#Surah Number Order of Revelation
%OrderOfRevelation = (
								1=>5,
								2=>87,
								3=>89,
								4=>92,
								5=>112,
								6=>55,
								7=>39,
								8=>88,
								9=>113,
								10=>51,
								11=>52,
								12=>53,
								13=>96,
								14=>72,
								15=>54,
								16=>70,
								17=>50,
								18=>69,
								19=>44,
								20=>45,
								21=>73,
								22=>103,
								23=>74,
								24=>102,
								25=>42,
								26=>47,
								27=>48,
								28=>49,
								29=>85,
								30=>84,
								31=>57,
								32=>75,
								33=>90,
								34=>58,
								35=>43,
								36=>41,
								37=>56,
								38=>38,
								39=>59,
								40=>60,
								41=>61,
								42=>62,
								43=>63,
								44=>64,
								45=>65,
								46=>66,
								47=>95,
								48=>111,
								49=>106,
								50=>34,
								51=>67,
								52=>76,
								53=>23,
								54=>37,
								55=>97,
								56=>46,
								57=>94,
								58=>105,
								59=>101,
								60=>13,
								61=>109,
								62=>110,
								63=>104,
								64=>108,
								65=>99,
								66=>107,
								67=>77,
								68=>2,
								69=>78,
								70=>79,
								71=>71,
								72=>40,
								73=>3,
								74=>4,
								75=>31,
								76=>98,
								77=>33,
								78=>80,
								79=>81,
								80=>24,
								81=>7,
								82=>82,
								83=>86,
								84=>83,
								85=>27,
								86=>36,
								87=>8,
								88=>68,
								89=>10,
								90=>35,
								91=>26,
								92=>9,
								93=>11,
								94=>12,
								95=>28,
								96=>1,
								97=>25,
								98=>100,
								99=>93,
								100=>14,
								101=>30,
								102=>16,
								103=>13,
								104=>32,
								105=>19,
								106=>29,
								107=>17,
								108=>15,
								109=>18,
								110=>114,
								111=>6,
								112=>22,
								113=>20,
								114=>21
								);

%surah_name = (
						'Arabic' => [
								"الفاتحة",
								"البقرة",
								"ال عمران",
								"النساء",
								"المائدة",
								"الانعام",
								"الاعراف",
								"الانفال",
								"التوبة",
								"يونس",
								"هود",
								"يوسف",
								"الرعد",
								"ابراهيم",
								"الحجر",
								"النحل",
								"الاسراء",
								"الكهف",
								"مريم",
								"طه",
								"الانبياء",
								"الحج",
								"المؤمنون",
								"النور",
								"الفرقان",
								"الشعراء",
								"النمل",
								"القصص",
								"العنكبوت",
								"الروم",
								"لقمان",
								"السجدة",
								"الاحزاب",
								"سبأ",
								"فاطر",
								"يس",
								"الصافات",
								"ص",
								"الزمر",
								"غافر",
								"فصلت",
								"الشورى",
								"الزخرف",
								"الدخان",
								"الجاثية",
								"الاحقاف",
								"محمد",
								"الفتح",
								"الحجرات",
								"ق",
								"الذاريات",
								"الطور",
								"النجم",
								"القمر",
								"الرحمن",
								"الواقعة",
								"الحديد",
								"المجادلة",
								"الحشر",
								"الممتحنة",
								"الصف",
								"الجمعة",
								"المنافقون",
								"التغابن",
								"الطلاق",
								"التحريم",
								"الملك",
								"القلم",
								"الحاقة",
								"المعارج",
								"نوح",
								"الجن",
								"المزمل",
								"المدثر",
								"القيامة",
								"الانسان",
								"المرسلات",
								"النبا",
								"النازعات",
								"عبس",
								"التكوير",
								"الانفطار",
								"المطففين",
								"الانشقاق",
								"البروج",
								"الطارق",
								"الاعلى",
								"الغاشية",
								"الفجر",
								"البلد",
								"الشمس",
								"الليل",
								"الضحى",
								"الشرح",
								"التين",
								"العلق",
								"القدر",
								"البينة",
								"الزلزلة",
								"العاديات",
								"القارعة",
								"التكاثر",
								"العصر",
								"الهمزة",
								"الفيل",
								"قريش",
								"الماعون",
								"الكوثر",
								"الكافرون",
								"النصر",
								"المسد",
								"الاخلاص",
								"الفلق",
								"الناس"
							],

					'English' => [
								"Al-Fatiha",
								"Al-Baqarah",
								"Al-'Imran",
								"An-Nisa",
								"Al-Ma'idah",
								"Al-An'am",
								"Al-A'raf",
								"Al-Anfal",
								"At-Taubah",
								"Yunus",
								"Hud",
								"Yusuf",
								"Ar-Ra'd",
								"Ibrahim",
								"Al-Hijr",
								"An-Nahl",
								"Al-Isra'",
								"Al-Kahf",
								"Maryam",
								"Ta-Ha",
								"Al-Anbiya",
								"Al-Hajj",
								"Al-Mu'minun",
								"An-Nur",
								"Al-Furqan",
								"Ash-Shu'ara",
								"An-Naml",
								"Al-Qasas",
								"Al-Ankabut",
								"Ar-Rum",
								"Luqman",
								"As-Sajdah",
								"Al-Ahzab",
								"Saba",
								"Fatir",
								"Ya-Sin",
								"As-Saffaat",
								"Saad",
								"Az-Zumar",
								"Ghafir",
								"Fussilat",
								"Ash-Shura",
								"Az-Zukhruf",
								"Ad-Dukhan",
								"Al-Jathiyah",
								"Al-Ahqaf",
								"Muhammad",
								"Al-Fath",
								"Al-Hujuraat",
								"Qaf",
								"Adh-Dhariyat",
								"At-Tur",
								"An-Najm",
								"Al-Qamar",
								"Ar-Rahman",
								"Al-Waqi'ah",
								"Al-Hadid",
								"Al-Mujadilah",
								"Al-Hashr",
								"Al-Mumtahana",
								"As-Saff",
								"Al-Jumu'ah",
								"Al-Munafiqun",
								"At-Taghabun",
								"At-Talaaq",
								"At-Tahrim",
								"Al-Mulk",
								"Al-Qalam",
								"Al-Haqqah",
								"Al-Ma'arij",
								"Nuh",
								"Al-Jinn",
								"Al-Muzzammil",
								"Al-Muddathir",
								"Al-Qiyamah",
								"Al-Insan",
								"Al-Mursalaat",
								"An-Naba",
								"An-Nazi'aat",
								"'Abasa",
								"At-Takwir",
								"Al-Infitaar",
								"Al-Mutaffifi",
								"Al-Inshiqaq",
								"Al-Buruj",
								"At-Tariq",
								"Al-A'la",
								"Al-Ghaashiya",
								"Al-Fajr",
								"Al-Balad",
								"Ash-Shams",
								"Al-Lail",
								"Ad-Duha",
								"Ash-Sharh",
								"At-Tin",
								"Al-'Alaq",
								"Al-Qadr",
								"Al-Baiyyinah",
								"Az-Zalzalah",
								"Al-'Aadiyaat",
								"Al-Qari'ah",
								"At-Takaathur",
								"Al-'Asr",
								"Al-Humazah",
								"Al-Fil",
								"Al-Quraish",
								"Al-Maa'un",
								"Al-Kauthar",
								"Al-Kaafirun",
								"An-Nasr",
								"Al-Masad",
								"Al-Ikhlaas",
								"Al-Falaq",
								"An-Naas"
							]
						);

our @surah_ayah_count = (7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,
										135,112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,
										53,89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,
										12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,
										20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6);
#==========================================================
sub new {
my ($class, %args) = @_;
    
	my $self = bless {}, $class;
	$self->{Language} = $args{Language}? $args{Language}: 'Arabic';
	$self->{DatabasePath} = $args{DatabasePath}? $args{DatabasePath}: $INC{"Religion/Islam/Quran.pm"};
	$self->{DatabasePath} =~ s/\.pm$//;
	croak("Can't find base directory of Religion::Islam::Quran!") unless (-d $self->{DatabasePath});
	$self->{DatabaseFile} = "$self->{DatabasePath}/"."Quran". $self->{Language} .".txt";
	$self->_initialize;
    return $self;
}
#==========================================================
sub _initialize{
my ($self) = @_;
my ($line, $surah, $ayah, $description);
	
	unless (-f $self->{DatabaseFile}) {croak ("Unable to find Quran Database file $self->{DatabaseFile}: $!.");}
	open (IN, "<:encoding(UTF-8)", "$self->{DatabaseFile}") || croak("Unable to open Quran Database file $self->{DatabaseFile}: $!.");

	%quran = ();

	while ($line = <IN>) {
		chomp ($line);
		($surah, $ayah, $description) = split(/\|/, $line);
		$quran{"$surah\_$ayah"} = $description;
	}
	close IN;
	#----------------------------------------------------------------
	@QuranLanguages = ();
	opendir (DBdir, $self->{DatabasePath})  || croak("Unable to open Quran Database directory $self->{DatabasePath}: $!.");
	while (my $file = readdir(DBdir)) {
		if ($file eq "." || $file eq "..") {next;}
		$file =~ s/\.txt$//;
		$file =~ s/^Quran//;
		push @QuranLanguages, $file;
	}
}
#==========================================================
sub GetLanguages{
my ($self) = @_;
	return @QuranLanguages;
}
#==========================================================
sub SurahCount{
my ($self) = @_;
	return 114;
}
#==========================================================
sub AyahCount{
my ($self) = @_;
	return 6236;
}
#==========================================================
sub SurahAyahCount{
my ($self, $surah) = @_;
	
	if ($surah<1 || $surah>114) {return undef;}
	return $surah_ayah_count[$surah-1];
}
#==========================================================
sub SurahName{
my ($self, $surah, $lang) = @_;
	
	if ($surah<1 || $surah>114) {return undef;}
	$lang ||= $self->{Language} ||= "English";
	if (!exists $surah_name{$lang}) {
		$lang = "English";
	}
	return $surah_name{$lang}->[$surah-1];
}
#==========================================================
sub SurahsNames{
my ($self, $lang) = @_;
	$lang ||= $self->{Language} ||= "English";
	if (!exists $surah_name{$lang}) {
		$lang = "English";
	}
	return @{$surah_name{$lang}};
}
#==========================================================
sub Ayah{
my ($self, $surah, $ayah) = @_;
	$quran{"$surah\_$ayah"} || return undef;
	return $quran{"$surah\_$ayah"};
}
#==========================================================
sub Ayats{
my ($self, $surah, $fromayah, $toayah) = @_;
my (@ayats, $ayats, $ayah, $counter);
	
	wantarray || return undef;

	if ($surah<1 || $surah>114) {return undef;}
	$ayats = $surah_ayah_count[$surah-1];
	
	if ($fromayah<1 || $fromayah>$ayats) {return undef;}
	if ($toayah<1 || $toayah>$ayats) {return undef;}

	if ($fromayah > $toayah) {
		($fromayah, $toayah) = ($toayah, $fromayah);
	}
	
	$counter = 0;
	for $ayah($fromayah..$toayah) {
		$ayats[$counter++] = $quran{"$surah\_$ayah"};
	}
	return @ayats;
}
#==========================================================
sub AyatsHash{
my ($self, $surah, $fromayah, $toayah) = @_;
my (%ayats, $ayats, $ayah, $counter);
	
	if ($surah<1 || $surah>114) {return undef;}
	$ayats = $surah_ayah_count[$surah-1];
	
	if ($fromayah<1 || $fromayah>$ayats) {return undef;}
	if ($toayah<1 || $toayah>$ayats) {return undef;}

	if ($fromayah > $toayah) {
		($fromayah, $toayah) = ($toayah, $fromayah);
	}
	
	$counter = 0;
	for $ayah($fromayah..$toayah) {
		$ayats{$ayah} = $quran{"$surah\_$ayah"};
	}
	return %ayats;
}
#==========================================================
sub SearchSurah{
my ($self, $surah, $findwhat) = @_;
my (@ayats, $ayats, $ayah, $counter);
	
	if ($surah<1 || $surah>114) {return undef;}
	$ayats = $surah_ayah_count[$surah-1];
	
	$counter = 0;
	for $ayah(1..$ayats) {
		if ($quran{"$surah\_$ayah"} =~ m/$findwhat/i) {
			$ayats[$counter++] = $ayah;
		}
	}
	return @ayats;
}
#==========================================================
sub Surah{
my ($self, $surah) = @_;
my (@surah, $ayats, $ayah);

	if ($surah<1 || $surah>114) {return undef;}
	$ayats = $surah_ayah_count[$surah-1];
	for $ayah(1..$ayats) {
		$surah[$ayah] = $quran{"$surah\_$ayah"};
	}
	return @surah;
}
#==========================================================
sub SurahsAyats{
my ($self) = @_;
	return @surah_ayah_count;
}
#==========================================================
#The Wajib Sajdah of the Qur'an
#In four Surahs of the Qur'an there are ayats of sajdah that if a person reads one of these ayats, or if he hears someone else recite one of these ayats, once the ayat is finished, one must immediately go into sajdah.
#The Surahs that contain an ayat of wajib sajdah are:
#Surah 32 as-Sajdah / Ayat 15
#Surah 41 al-Fusilat / Ayat 38
#Surah 53 an-Najm / Ayat 62
#Surah 96 al-Alaq / Ayat 19
#If one forgets to perform the sajdah, whenever one remembers he must perform the sajdah.
#If the ayat of sajdah is heard over a tape recorder or things like this (CD, computer, etc...), the sajdah is not wajib.
#If one hears the ayat of sajdah over a speaker, it is wajib to perform the sajdah.
#If one hears the ayat of sajdah over the radio, in the event that the radio program is live (meaning the reciter is in the radio reciting the ayat), once the ayat is completed and the radio broadcasts it, the sajdah is wajib; but if the radio plays the ayat of sajdah from a tape of the Qur'an, the sajdah is not wajib.
#It is not wajib to recite a dhikr while in this sajdah, but it is mustahab.

#Following Ayaat require compulsary (wajib) sajda (indicated by *):
#1) Sura 32 - As Sajdah (The Adoration) - Ayat 15
#2) Sura 41 - Ha Mim (Ha Mim) - Ayat 38
#3) Sura 53 - An Najm (The Star) - Ayat 62
#4) Sura 96 - Al Alaq (The Clot) - Ayat 19
#
#Following Ayaat require recommended (mustahab) sajda (indicated by *):
#5) Sura 7 - Al A'raf (The Elevated Places) - Ayat 206
#6) Sura 13 - Ar Ra'ad (The Thunder) - Ayat 15
#7) Sura 16 - An Nahl (The Bee) - Ayat 50
#8) Sura 17 - Bani Israil (The Children of Israil) - Ayat 109
#9) Sura 19 - Marium (Mary) - Ayat 58
#10) Sura 22 - Al Haj (The Pilgrimage) - Ayat 18
#11) Sura 25 - Al Furqan (The Criterion) - Ayat 60
#12) Sura 27 - An Naml (The Ant) - Ayat 26
#13) Sura 38 - Saad (Saad) - Ayat 24
#14) Sura 84 - Al Inshiqaq (The Bursting Asunder) - Ayat 21
#==========================================================
sub SajdahCompulsaryAyats{
my ($self) = @_;
	return %SajdahCompulsaryAyats;
}
#==========================================================
sub IsSajdahCompulsaryAyah{
my ($self, $surah, $ayah) = @_;
	
	if ($surah<1 || $surah>114) {return 0;}
	if ($SajdahCompulsaryAyats{$surah} eq $ayah ) {
		return 1;
	}
	else {
		return 0;
	}
}
#==========================================================
sub SajdahRecommendedAyats{
my ($self) = @_;
	return %SajdahRecommendedAyats;
}
#==========================================================
sub IsSajdahRecommendedAyah{
my ($self, $surah, $ayah) = @_;
	
	if ($surah<1 || $surah>114) {return 0;}
	if ($SajdahRecommendedAyats{$surah} eq $ayah ) {
		return 1;
	}
	else {
		return 0;
	}
}
#==========================================================
sub SurahOrderOfRevelation{
my ($self, $surah) = @_;
	if ($surah<1 || $surah>114) {return undef;}
	return $OrderOfRevelation{$surah};
}
#==========================================================
sub OrderOfRevelation{
my ($self) = @_;
	return %OrderOfRevelation;
}
#==========================================================
#Where each surah revealed, Mekkah or Medianh
#Medinah surahs: 2, 3, 4, 5, 8, 9, 13, 22, 24, 33, 47, 48, 49, 55, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 76, 98, 99, 110 
#Return 1 for Medinah and 0 for Mekkah
sub SurahRevelation{
my ($self, $surah) = @_;
my (@medinah) = (2, 3, 4, 5, 8, 9, 13, 22, 24, 33, 47, 48, 49, 55, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 76, 98, 99, 110); # Medinah surahs

	if ($surah<1 || $surah>114) {return undef;}
	foreach my $medinah (@medinah) {
		if ($medinah == $surah) {
			return 1; # Revealed in Medinah
		}
	}
	return 0; # Revealed in Makkah
}
#==========================================================
sub RemoveDiacritic {
my ($self, $text) = @_;

	#Windows Arabic (1256) 
	#$Text =~ s/\xF0//g;		#ARABIC FATHATAN
	#$Text =~ s/\xF1//g;		#ARABIC DAMMATAN
	#$Text =~ s/\xF2//g;		#ARABIC KASRATAN
	#$Text =~ s/\xF3//g;		#ARABIC FATHA
	#$Text =~ s/\xF5//g;		#ARABIC DAMMA
	#$Text =~ s/\xF6//g;		#ARABIC KASRA
	#$Text =~ s/\xF8//g;		#ARABIC SHADDA
	#$Text =~ s/\xFA//g;	#ARABIC SUKUN
	$text =~ s/\xF0|\xF1|\xF2|\xF3|\xF5|\xF6|\xF8|\xFA//g;
	#Allah Isolated form: ���  = \x{e1}\x{e1}\x{e5}, = Unicode &#65010; = &#xFDF2; = &#1604;&#1604;&#1607;

	# 1256  - Uindex - UISOname 
	#	F0 064B ARABIC FATHATAN 
	#	F1 064C ARABIC DAMMATAN 
	#	F2 064D ARABIC KASRATAN 
	#	F3 064E ARABIC FATHA 
	#	F5 064F ARABIC DAMMA 
	#	F6 0650 ARABIC KASRA 
	#	F8 0651 ARABIC SHADDA 
	#	FA 0652 ARABIC SUKUN 
	
	#Unicode Hex
	#$Text =~ s/\x{064B}//g;
	#$Text =~ s/\x{064C}//g;
	#$Text =~ s/\x{064D}//g;
	#$Text =~ s/\x{064E}//g;
	#$Text =~ s/\x{064F}//g;
	#$Text =~ s/\x{0650}//g;
	#$Text =~ s/\x{0651}//g;
	#$Text =~ s/\x{0652}//g;
	
	#Unicode Decimal
	#$Text =~ s/\&\#1611\;//g;	# 064B		,	ARABIC FATHATAN
	#$Text =~ s/\&\#1612\;//g;	# 064C		,	ARABIC DAMMATAN
	#$Text =~ s/\&\#1613\;//g;	# 064D	,	ARABIC KASRATAN
	#$Text =~ s/\&\#1614\;//g;	# 064E	 	,	ARABIC FATHA
	#$Text =~ s/\&\#1615\;//g;	# 064F		,	ARABIC DAMMA
	#$Text =~ s/\&\#1616\;//g;	# 0650		,	ARABIC KASRA
	#$Text =~ s/\&\#1617\;//g;	# 0651		,	ARABIC SHADDA
	#$Text =~ s/\&\#1618\;//g;	# 0652		,	ARABIC SUKUN
	#http://www.microsoft.com/typography/unicode/1256.htm
	
	$text =~ s/\&\#1611\;|\&\#1612\;|\&\#1613\;|\&\#1614\;|\&\#1615\;|\&\#1616\;|\&\#1617\;|\&\#1618\;//g;
	return $text;
}
#==========================================================
#==========================================================
1;

=encoding utf-8

=head1 NAME

Religion::Islam::Quran - Holy Quran book searchable database multi-lingual in utf-8 unicode format

=head1 SYNOPSIS

	#---------------------------------------------------------------
	use Religion::Islam::Quran;
	#---------------------------------------------------------------
	#create new object with default options, Arabic language
	my $quran = Religion::Islam::Quran->new();

	# or select the English Language:
	my $quran = Religion::Islam::Quran->new(Language=>'English');
	
	# you can also specifiy your own database files path:
	my $quran = Religion::Islam::Quran->new(DatabasePath => './Quran/mydatabase');
	#---------------------------------------------------------------
	#Returns the available Quran databases
	@Languages = $quran->GetLanguages();
	#---------------------------------------------------------------
	# returns all the quran surahs count.
	$surahs = $quran->SurahCount; # returns 114
	#---------------------------------------------------------------
	# returns all the quran ayats count.
	$ayats = $quran->AyahCount; # returns 6236
	#---------------------------------------------------------------
	#returns all surah ayats Quran in an array.
	@surah = $quran->Surah(1); 
	#---------------------------------------------------------------
	#returns the number of surah ayats.
	$surah_number = 1; # 1 to 114
	$surah_ayats = $quran->SurahAyahCount($surah_number);
	#---------------------------------------------------------------
	# returns the surah name using the surah number from 1 to 114.
	$surah_name = $quran->SurahName($surah_number, $optional_language);
	#---------------------------------------------------------------
	# returns Quran text of specific surah ayah.
	$ayah = $quran->Ayah($surah_number, $ayah_number);
	#---------------------------------------------------------------
	# returns Quran text of specific surah ayah range in an array .
	@ayats = $quran->Ayats($surah_number, $from_ayah, $to_ayah);
	#---------------------------------------------------------------
	# returns all the Quran text of specific surah in an array.
	@ayats = $quran->Surah($surah_number);
	#---------------------------------------------------------------
	# returns the names of each surah in the Quran sort order.
	@surahs_name = $quran->SurahsNames();
	#---------------------------------------------------------------
	# returns the ayats number for each surah in the Quran sort order.
	@surahs_ayats = $quran->SurahsAyats();
	#---------------------------------------------------------------
	# search specific Surah for specific text and returns the ayahs numbers
	@ayats = $quran->SearchSurah($surah, $findwhat);
	#---------------------------------------------------------------
	#Remove Diacritic from Arabic Text
	$TextWithoutDiacritic = $quran->RemoveDiacritic($TextWithDiacritic);
	#---------------------------------------------------------------
	#The Wajib Sajdah of the Qur'an
	#In four Surahs of the Qur'an there are ayats of sajdah that if a person reads one 
	#of these ayats, or if he hears someone else recite one of these ayats, once the 
	#ayat is finished, one must immediately go into sajdah.
	#Returns the Surah=>Ayah pairs
	%SajdahCompulsaryAyats = $quran->SajdahCompulsaryAyats();
	print $quran->IsSajdahCompulsaryAyah($surah, $ayah);
	
	#The recommended (mustahab) Sajdah of the Qur'an
	#Returns the Surah=>Ayah pairs
	%SajdahRecommendedAyats = $quran->SajdahRecommendedAyats();
	print  $quran->IsSajdahRecommendedAyah($surah, $ayah);
	
	#Surah Number Order of Revelation
	#Returns surah number=>order of revelation pairs
	%OrderOfRevelation = $quran->OrderOfRevelation();
	print "Surah Order Of Revelation: " . $quran->SurahOrderOfRevelation($surah);
	
	#Where each surah revealed, Mekkah or Medianh
	#Return 1 for Medinah and 0 for Mekkah
	print $quran->SurahRevelation($surah);

=head1 DESCRIPTION

This module contains the full Holy Quran Book database searchable 
and provides many methods for retriving whole quran, specific surahs, or specific ayats and
information about Quran and each surah in different languages and transliterations.
Quran database files are simply text files pipe separated each line is formated as:

<SurahNumber>|<AyahNumber>|<AyahText><CRLF>

Example of Arabic database file first Surah QuranArabic.txt:

	1|1|بِسْمِ اللّهِ الرَّحْمَنِ الرَّحِيمِ
	1|2|الْحَمْدُ للّهِ رَبِّ الْعَالَمِينَ
	1|3|الرَّحْمنِ الرَّحِيمِ
	1|4|مَلِكِ يَوْمِ الدِّينِ
	1|5|إِيَّاكَ نَعْبُدُ وإِيَّاكَ نَسْتَعِينُ
	1|6|اهدِنَا الصِّرَاطَ المُستَقِيمَ
	1|7|صِرَاطَ الَّذِينَ أَنعَمتَ عَلَيهِمْ غَيرِ المَغضُوبِ عَلَيهِمْ وَلاَ الضَّالِّينَ

and the 112th Surah in QuranEnglish.txt:

	112|1|Say: He is Allah, the One and Only; 
	112|2|Allah, the Eternal, Absolute; 
	112|3|He begetteth not, nor is He begotten; 
	112|4|And there is none like unto Him. 

Database text files located in the module directory /Religion/Islam/Quran.
Default  module comes with the Quran Arabic and some other translations.
You can download more quran translations and transliterations from www.islamware.com.

Languages and databases included with the module are:

	Albanian
	Arabic
	Azerbaijani
	Chinese
	Dutch
	English
	EnglishUS
	Finnish
	French
	German
	Harun
	Indonesian
	Italian
	Japanese
	Latin
	Malaysian
	Mexican
	Persian
	Poland
	Portuguese
	Russian
	Spanish
	Swahili
	Tamil
	Thai
	Turkish

	EnglishTransliteration

Surah names are only available in English and Arabic languages.

=head2 Methods

=head1 SEE ALSO

L<Date::HijriDate>
L<Religion::Islam::Qibla>
L<Religion::Islam::PrayTime>
L<Religion::Islam::PrayerTimes>

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  <support@islamware.com> <support@mewsoft.com>
Website: http://www.islamware.com   http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2013 by Ahmed Amin Elsheshtawy support@islamware.com, support@mewsoft.com
L<http://www.islamware.com>  L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
