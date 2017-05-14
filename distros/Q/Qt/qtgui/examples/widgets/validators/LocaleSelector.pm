package LocaleSelector;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::ComboBox );
use QtCore4::signals
    localeSelected => ['const QLocale &'];
use QtCore4::slots
    emitLocaleSelected => ['int'];

my @SUPPORTED_LOCALES = (
    {      lang => 1,     country => 0 }, # C/AnyCountry
    {      lang => 3,    country => 69 }, # Afan/Ethiopia
    {      lang => 3,   country => 111 }, # Afan/Kenya
    {      lang => 4,    country => 59 }, # Afar/Djibouti
    {      lang => 4,    country => 67 }, # Afar/Eritrea
    {      lang => 4,    country => 69 }, # Afar/Ethiopia
    {      lang => 5,   country => 195 }, # Afrikaans/SouthAfrica
    {      lang => 5,   country => 148 }, # Afrikaans/Namibia
    {      lang => 6,     country => 2 }, # Albanian/Albania
    {      lang => 7,    country => 69 }, # Amharic/Ethiopia
    {      lang => 8,   country => 186 }, # Arabic/SaudiArabia
    {      lang => 8,     country => 3 }, # Arabic/Algeria
    {      lang => 8,    country => 17 }, # Arabic/Bahrain
    {      lang => 8,    country => 64 }, # Arabic/Egypt
    {      lang => 8,   country => 103 }, # Arabic/Iraq
    {      lang => 8,   country => 109 }, # Arabic/Jordan
    {      lang => 8,   country => 115 }, # Arabic/Kuwait
    {      lang => 8,   country => 119 }, # Arabic/Lebanon
    {      lang => 8,   country => 122 }, # Arabic/LibyanArabJamahiriya
    {      lang => 8,   country => 145 }, # Arabic/Morocco
    {      lang => 8,   country => 162 }, # Arabic/Oman
    {      lang => 8,   country => 175 }, # Arabic/Qatar
    {      lang => 8,   country => 201 }, # Arabic/Sudan
    {      lang => 8,   country => 207 }, # Arabic/SyrianArabRepublic
    {      lang => 8,   country => 216 }, # Arabic/Tunisia
    {      lang => 8,   country => 223 }, # Arabic/UnitedArabEmirates
    {      lang => 8,   country => 237 }, # Arabic/Yemen
    {      lang => 9,    country => 11 }, # Armenian/Armenia
    {     lang => 10,   country => 100 }, # Assamese/India
    {     lang => 12,    country => 15 }, # Azerbaijani/Azerbaijan
    {     lang => 14,   country => 197 }, # Basque/Spain
    {     lang => 15,    country => 18 }, # Bengali/Bangladesh
    {     lang => 15,   country => 100 }, # Bengali/India
    {     lang => 16,    country => 25 }, # Bhutani/Bhutan
    {     lang => 20,    country => 33 }, # Bulgarian/Bulgaria
    {     lang => 22,    country => 20 }, # Byelorussian/Belarus
    {     lang => 23,    country => 36 }, # Cambodian/Cambodia
    {     lang => 24,   country => 197 }, # Catalan/Spain
    {     lang => 25,    country => 44 }, # Chinese/China
    {     lang => 25,    country => 97 }, # Chinese/HongKong
    {     lang => 25,   country => 126 }, # Chinese/Macau
    {     lang => 25,   country => 190 }, # Chinese/Singapore
    {     lang => 25,   country => 208 }, # Chinese/Taiwan
    {     lang => 27,    country => 54 }, # Croatian/Croatia
    {     lang => 28,    country => 57 }, # Czech/CzechRepublic
    {     lang => 29,    country => 58 }, # Danish/Denmark
    {     lang => 30,   country => 151 }, # Dutch/Netherlands
    {     lang => 30,    country => 21 }, # Dutch/Belgium
    {     lang => 31,   country => 225 }, # English/UnitedStates
    {     lang => 31,     country => 4 }, # English/AmericanSamoa
    {     lang => 31,    country => 13 }, # English/Australia
    {     lang => 31,    country => 21 }, # English/Belgium
    {     lang => 31,    country => 22 }, # English/Belize
    {     lang => 31,    country => 28 }, # English/Botswana
    {     lang => 31,    country => 38 }, # English/Canada
    {     lang => 31,    country => 89 }, # English/Guam
    {     lang => 31,    country => 97 }, # English/HongKong
    {     lang => 31,   country => 100 }, # English/India
    {     lang => 31,   country => 104 }, # English/Ireland
    {     lang => 31,   country => 107 }, # English/Jamaica
    {     lang => 31,   country => 133 }, # English/Malta
    {     lang => 31,   country => 134 }, # English/MarshallIslands
    {     lang => 31,   country => 148 }, # English/Namibia
    {     lang => 31,   country => 154 }, # English/NewZealand
    {     lang => 31,   country => 160 }, # English/NorthernMarianaIslands
    {     lang => 31,   country => 163 }, # English/Pakistan
    {     lang => 31,   country => 170 }, # English/Philippines
    {     lang => 31,   country => 190 }, # English/Singapore
    {     lang => 31,   country => 195 }, # English/SouthAfrica
    {     lang => 31,   country => 215 }, # English/TrinidadAndTobago
    {     lang => 31,   country => 224 }, # English/UnitedKingdom
    {     lang => 31,   country => 226 }, # English/UnitedStatesMinorOutlyingIslands
    {     lang => 31,   country => 234 }, # English/USVirginIslands
    {     lang => 31,   country => 240 }, # English/Zimbabwe
    {     lang => 33,    country => 68 }, # Estonian/Estonia
    {     lang => 34,    country => 71 }, # Faroese/FaroeIslands
    {     lang => 36,    country => 73 }, # Finnish/Finland
    {     lang => 37,    country => 74 }, # French/France
    {     lang => 37,    country => 21 }, # French/Belgium
    {     lang => 37,    country => 38 }, # French/Canada
    {     lang => 37,   country => 125 }, # French/Luxembourg
    {     lang => 37,   country => 142 }, # French/Monaco
    {     lang => 37,   country => 206 }, # French/Switzerland
    {     lang => 40,   country => 197 }, # Galician/Spain
    {     lang => 41,    country => 81 }, # Georgian/Georgia
    {     lang => 42,    country => 82 }, # German/Germany
    {     lang => 42,    country => 14 }, # German/Austria
    {     lang => 42,    country => 21 }, # German/Belgium
    {     lang => 42,   country => 123 }, # German/Liechtenstein
    {     lang => 42,   country => 125 }, # German/Luxembourg
    {     lang => 42,   country => 206 }, # German/Switzerland
    {     lang => 43,    country => 85 }, # Greek/Greece
    {     lang => 43,    country => 56 }, # Greek/Cyprus
    {     lang => 44,    country => 86 }, # Greenlandic/Greenland
    {     lang => 46,   country => 100 }, # Gujarati/India
    {     lang => 47,    country => 83 }, # Hausa/Ghana
    {     lang => 47,   country => 156 }, # Hausa/Niger
    {     lang => 47,   country => 157 }, # Hausa/Nigeria
    {     lang => 48,   country => 105 }, # Hebrew/Israel
    {     lang => 49,   country => 100 }, # Hindi/India
    {     lang => 50,    country => 98 }, # Hungarian/Hungary
    {     lang => 51,    country => 99 }, # Icelandic/Iceland
    {     lang => 52,   country => 101 }, # Indonesian/Indonesia
    {     lang => 57,   country => 104 }, # Irish/Ireland
    {     lang => 58,   country => 106 }, # Italian/Italy
    {     lang => 58,   country => 206 }, # Italian/Switzerland
    {     lang => 59,   country => 108 }, # Japanese/Japan
    {     lang => 61,   country => 100 }, # Kannada/India
    {     lang => 63,   country => 110 }, # Kazakh/Kazakhstan
    {     lang => 64,   country => 179 }, # Kinyarwanda/Rwanda
    {     lang => 65,   country => 116 }, # Kirghiz/Kyrgyzstan
    {     lang => 66,   country => 114 }, # Korean/RepublicOfKorea
    {     lang => 67,   country => 102 }, # Kurdish/Iran
    {     lang => 67,   country => 103 }, # Kurdish/Iraq
    {     lang => 67,   country => 207 }, # Kurdish/SyrianArabRepublic
    {     lang => 67,   country => 217 }, # Kurdish/Turkey
    {     lang => 69,   country => 117 }, # Laothian/Lao
    {     lang => 71,   country => 118 }, # Latvian/Latvia
    {     lang => 72,    country => 49 }, # Lingala/DemocraticRepublicOfCongo
    {     lang => 72,    country => 50 }, # Lingala/PeoplesRepublicOfCongo
    {     lang => 73,   country => 124 }, # Lithuanian/Lithuania
    {     lang => 74,   country => 127 }, # Macedonian/Macedonia
    {     lang => 76,   country => 130 }, # Malay/Malaysia
    {     lang => 76,    country => 32 }, # Malay/BruneiDarussalam
    {     lang => 77,   country => 100 }, # Malayalam/India
    {     lang => 78,   country => 133 }, # Maltese/Malta
    {     lang => 80,   country => 100 }, # Marathi/India
    {     lang => 82,   country => 143 }, # Mongolian/Mongolia
    {     lang => 84,   country => 150 }, # Nepali/Nepal
    {     lang => 85,   country => 161 }, # Norwegian/Norway
    {     lang => 87,   country => 100 }, # Oriya/India
    {     lang => 88,     country => 1 }, # Pashto/Afghanistan
    {     lang => 89,   country => 102 }, # Persian/Iran
    {     lang => 89,     country => 1 }, # Persian/Afghanistan
    {     lang => 90,   country => 172 }, # Polish/Poland
    {     lang => 91,   country => 173 }, # Portuguese/Portugal
    {     lang => 91,    country => 30 }, # Portuguese/Brazil
    {     lang => 92,   country => 100 }, # Punjabi/India
    {     lang => 92,   country => 163 }, # Punjabi/Pakistan
    {     lang => 95,   country => 177 }, # Romanian/Romania
    {     lang => 96,   country => 178 }, # Russian/RussianFederation
    {     lang => 96,   country => 222 }, # Russian/Ukraine
    {     lang => 99,   country => 100 }, # Sanskrit/India
    {    lang => 100,   country => 241 }, # Serbian/SerbiaAndMontenegro
    {    lang => 100,    country => 27 }, # Serbian/BosniaAndHerzegowina
    {    lang => 100,   country => 238 }, # Serbian/Yugoslavia
    {    lang => 101,   country => 241 }, # SerboCroatian/SerbiaAndMontenegro
    {    lang => 101,    country => 27 }, # SerboCroatian/BosniaAndHerzegowina
    {    lang => 101,   country => 238 }, # SerboCroatian/Yugoslavia
    {    lang => 102,   country => 195 }, # Sesotho/SouthAfrica
    {    lang => 103,   country => 195 }, # Setswana/SouthAfrica
    {    lang => 107,   country => 195 }, # Siswati/SouthAfrica
    {    lang => 108,   country => 191 }, # Slovak/Slovakia
    {    lang => 109,   country => 192 }, # Slovenian/Slovenia
    {    lang => 110,   country => 194 }, # Somali/Somalia
    {    lang => 110,    country => 59 }, # Somali/Djibouti
    {    lang => 110,    country => 69 }, # Somali/Ethiopia
    {    lang => 110,   country => 111 }, # Somali/Kenya
    {    lang => 111,   country => 197 }, # Spanish/Spain
    {    lang => 111,    country => 10 }, # Spanish/Argentina
    {    lang => 111,    country => 26 }, # Spanish/Bolivia
    {    lang => 111,    country => 43 }, # Spanish/Chile
    {    lang => 111,    country => 47 }, # Spanish/Colombia
    {    lang => 111,    country => 52 }, # Spanish/CostaRica
    {    lang => 111,    country => 61 }, # Spanish/DominicanRepublic
    {    lang => 111,    country => 63 }, # Spanish/Ecuador
    {    lang => 111,    country => 65 }, # Spanish/ElSalvador
    {    lang => 111,    country => 90 }, # Spanish/Guatemala
    {    lang => 111,    country => 96 }, # Spanish/Honduras
    {    lang => 111,   country => 139 }, # Spanish/Mexico
    {    lang => 111,   country => 155 }, # Spanish/Nicaragua
    {    lang => 111,   country => 166 }, # Spanish/Panama
    {    lang => 111,   country => 168 }, # Spanish/Paraguay
    {    lang => 111,   country => 169 }, # Spanish/Peru
    {    lang => 111,   country => 174 }, # Spanish/PuertoRico
    {    lang => 111,   country => 225 }, # Spanish/UnitedStates
    {    lang => 111,   country => 227 }, # Spanish/Uruguay
    {    lang => 111,   country => 231 }, # Spanish/Venezuela
    {    lang => 113,   country => 111 }, # Swahili/Kenya
    {    lang => 113,   country => 210 }, # Swahili/Tanzania
    {    lang => 114,   country => 205 }, # Swedish/Sweden
    {    lang => 114,    country => 73 }, # Swedish/Finland
    {    lang => 116,   country => 209 }, # Tajik/Tajikistan
    {    lang => 117,   country => 100 }, # Tamil/India
    {    lang => 118,   country => 178 }, # Tatar/RussianFederation
    {    lang => 119,   country => 100 }, # Telugu/India
    {    lang => 120,   country => 211 }, # Thai/Thailand
    {    lang => 122,    country => 67 }, # Tigrinya/Eritrea
    {    lang => 122,    country => 69 }, # Tigrinya/Ethiopia
    {    lang => 124,   country => 195 }, # Tsonga/SouthAfrica
    {    lang => 125,   country => 217 }, # Turkish/Turkey
    {    lang => 129,   country => 222 }, # Ukrainian/Ukraine
    {    lang => 130,   country => 100 }, # Urdu/India
    {    lang => 130,   country => 163 }, # Urdu/Pakistan
    {    lang => 131,   country => 228 }, # Uzbek/Uzbekistan
    {    lang => 131,     country => 1 }, # Uzbek/Afghanistan
    {    lang => 132,   country => 232 }, # Vietnamese/VietNam
    {    lang => 134,   country => 224 }, # Welsh/UnitedKingdom
    {    lang => 136,   country => 195 }, # Xhosa/SouthAfrica
    {    lang => 138,   country => 157 }, # Yoruba/Nigeria
    {    lang => 140,   country => 195 }, # Zulu/SouthAfrica
    {    lang => 141,   country => 161 }, # Nynorsk/Norway
    {    lang => 142,    country => 27 }, # Bosnian/BosniaAndHerzegowina
    {    lang => 143,   country => 131 }, # Divehi/Maldives
    {    lang => 144,   country => 224 }, # Manx/UnitedKingdom
    {    lang => 145,   country => 224 }, # Cornish/UnitedKingdom
    {    lang => 146,    country => 83 }, # Akan/Ghana
    {    lang => 147,   country => 100 }, # Konkani/India
    {    lang => 148,    country => 83 }, # Ga/Ghana
    {    lang => 149,   country => 157 }, # Igbo/Nigeria
    {    lang => 150,   country => 111 }, # Kamba/Kenya
    {    lang => 151,   country => 207 }, # Syriac/SyrianArabRepublic
    {    lang => 152,    country => 67 }, # Blin/Eritrea
    {    lang => 153,    country => 67 }, # Geez/Eritrea
    {    lang => 153,    country => 69 }, # Geez/Ethiopia
    {    lang => 154,   country => 157 }, # Koro/Nigeria
    {    lang => 155,    country => 69 }, # Sidamo/Ethiopia
    {    lang => 156,   country => 157 }, # Atsam/Nigeria
    {    lang => 157,    country => 67 }, # Tigre/Eritrea
    {    lang => 158,   country => 157 }, # Jju/Nigeria
    {    lang => 159,   country => 106 }, # Friulian/Italy
    {    lang => 160,   country => 195 }, # Venda/SouthAfrica
    {    lang => 161,    country => 83 }, # Ewe/Ghana
    {    lang => 161,   country => 212 }, # Ewe/Togo
    {    lang => 163,   country => 225 }, # Hawaiian/UnitedStates
    {    lang => 164,   country => 157 }, # Tyap/Nigeria
    {    lang => 165,   country => 129 } # Chewa/Malawi
);

my $SUPPORTED_LOCALES_COUNT = scalar @SUPPORTED_LOCALES;

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    my $curIndex = -1;
    my $curLocale = Qt::Locale();

    foreach my $i (0..$SUPPORTED_LOCALES_COUNT-1) {
        my $l = $SUPPORTED_LOCALES[$i];
        if ($l->{lang} == $curLocale->language() && $l->{country} == $curLocale->country()) {
            $curIndex = $i;
        }
        my $text = Qt::Locale::languageToString($l->{lang})
                        . '/'
                        . Qt::Locale::countryToString($l->{country});
        this->addItem($text, Qt::qVariantFromValue($l));
    }

    this->setCurrentIndex($curIndex);

    this->connect(this, SIGNAL 'activated(int)', this, SLOT 'emitLocaleSelected(int)');
}

sub emitLocaleSelected {
    my ($index) = @_;
    my $v = this->itemData($index);
    if (!$v->isValid()) {
        return;
    }
    my $l = Qt::qVariantValue($v);
    emit localeSelected(Qt::Locale($l->{lang}, $l->{country}));
}

1;
