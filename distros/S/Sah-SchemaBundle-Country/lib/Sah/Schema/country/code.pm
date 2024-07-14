package Sah::Schema::country::code;

use strict;
use Locale::Codes::Country_Codes ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-26'; # DATE
our $DIST = 'Sah-SchemaBundle-Country'; # DIST
our $VERSION = '0.010'; # VERSION

my $codes = [];
my $names = [];
{
    for my $alpha2 (keys(%{ $Locale::Codes::Data{'country'}{'code2id'}{'alpha-2'} })) {
        push @$codes, $alpha2;
        my $id = $Locale::Codes::Data{'country'}{'code2id'}{'alpha-2'}{$alpha2}[0];
        push @$names, $Locale::Codes::Data{'country'}{'id2names'}{$id}[0];
    }
    for my $alpha3 (keys(%{ $Locale::Codes::Data{'country'}{'code2id'}{'alpha-3'} })) {
        push @$codes, $alpha3;
        my $id = $Locale::Codes::Data{'country'}{'code2id'}{'alpha-3'}{$alpha3}[0];
        push @$names, $Locale::Codes::Data{'country'}{'id2names'}{$id}[0];
    }

    die "Can't extract country codes from Locale::Codes::Country_Codes"
        unless @$codes;
}

our $schema = [str => {
    summary => 'Country code (alpha-2 or alpha-3)',
    description => <<'_',

Accept only current (not retired) codes. Alpha-2 or alpha-3 codes are accepted.

Code will be converted to lowercase.

_
    match => '\A[a-z]{2,3}\z',
    in => $codes,
    'x.in.summaries' => $names,
    'x.perl.coerce_rules' => ['From_str::to_lower'],
    examples => [
        {value=>'', valid=>0},
        {value=>'ID' , valid=>1, validated_value=>'id'},
        {value=>'IDN', valid=>1, validated_value=>'idn'},
        {value=>'xx', valid=>0},
        {value=>'xxx', valid=>0},
    ],
}];

1;
# ABSTRACT: Country code (alpha-2 or alpha-3)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::country::code - Country code (alpha-2 or alpha-3)

=head1 VERSION

This document describes version 0.010 of Sah::Schema::country::code (from Perl distribution Sah-SchemaBundle-Country), released on 2024-06-26.

=head1 SAH SCHEMA DEFINITION

 [
   "str",
   {
     "in" => [
       "et",
       "pg",
       "au",
       "je",
       "vg",
       "hn",
       "bo",
       "bj",
       "kh",
       "bm",
       "bt",
       "fi",
       "to",
       "so",
       "ng",
       "ws",
       "lt",
       "cv",
       "sj",
       "sm",
       "tt",
       "gb",
       "cg",
       "tm",
       "ax",
       "st",
       "my",
       "tj",
       "hr",
       "ai",
       "bd",
       "gs",
       "pk",
       "gn",
       "ba",
       "cw",
       "cf",
       "gq",
       "bl",
       "ve",
       "mh",
       "ye",
       "nf",
       "pe",
       "ki",
       "ie",
       "qa",
       "mu",
       "mc",
       "sd",
       "mx",
       "sa",
       "td",
       "ro",
       "sl",
       "ne",
       "ug",
       "pf",
       "ky",
       "ck",
       "la",
       "gr",
       "tl",
       "pw",
       "bn",
       "ae",
       "lr",
       "ga",
       "mg",
       "gd",
       "cy",
       "bs",
       "vi",
       "ht",
       "es",
       "sz",
       "sr",
       "zm",
       "tz",
       "bq",
       "tr",
       "gl",
       "ke",
       "hm",
       "mv",
       "sn",
       "af",
       "aw",
       "ss",
       "tn",
       "er",
       "ci",
       "br",
       "bz",
       "ni",
       "ls",
       "kw",
       "py",
       "kg",
       "dk",
       "za",
       "lb",
       "fk",
       "uy",
       "mk",
       "ph",
       "gt",
       "vu",
       "vc",
       "de",
       "cx",
       "ag",
       "me",
       "gm",
       "sb",
       "ch",
       "cu",
       "cc",
       "rs",
       "nc",
       "nu",
       "mw",
       "mf",
       "gp",
       "bb",
       "mz",
       "mr",
       "fr",
       "tv",
       "co",
       "dz",
       "sv",
       "ua",
       "no",
       "cm",
       "sg",
       "re",
       "lv",
       "tg",
       "gu",
       "pm",
       "yt",
       "im",
       "gh",
       "pt",
       "bv",
       "np",
       "eg",
       "it",
       "mq",
       "bg",
       "rw",
       "mn",
       "ms",
       "io",
       "cd",
       "kr",
       "kz",
       "gy",
       "se",
       "bf",
       "nl",
       "lk",
       "ca",
       "bw",
       "um",
       "tk",
       "na",
       "cl",
       "jp",
       "sk",
       "az",
       "ar",
       "il",
       "tw",
       "hu",
       "pl",
       "gi",
       "jo",
       "tf",
       "as",
       "be",
       "om",
       "va",
       "ee",
       "kn",
       "id",
       "aq",
       "pa",
       "jm",
       "gf",
       "mp",
       "pr",
       "cn",
       "gw",
       "ir",
       "si",
       "by",
       "ru",
       "li",
       "ge",
       "mm",
       "fj",
       "fm",
       "nr",
       "nz",
       "ad",
       "dm",
       "bi",
       "iq",
       "mt",
       "dj",
       "sy",
       "pn",
       "cz",
       "cr",
       "in",
       "do",
       "mo",
       "al",
       "ly",
       "vn",
       "ps",
       "is",
       "fo",
       "sh",
       "tc",
       "kp",
       "sc",
       "us",
       "th",
       "zw",
       "lc",
       "lu",
       "bh",
       "ml",
       "ao",
       "km",
       "wf",
       "ec",
       "uz",
       "sx",
       "hk",
       "at",
       "md",
       "eh",
       "gg",
       "am",
       "ma",
       "pri",
       "cck",
       "mkd",
       "ken",
       "abw",
       "uzb",
       "sle",
       "mlt",
       "irl",
       "isl",
       "fji",
       "syc",
       "dji",
       "brn",
       "jor",
       "nzl",
       "eth",
       "nru",
       "cri",
       "hrv",
       "cym",
       "pcn",
       "geo",
       "alb",
       "lbn",
       "hmd",
       "tza",
       "nor",
       "cmr",
       "sgp",
       "gtm",
       "swz",
       "mli",
       "ssd",
       "lby",
       "ecu",
       "plw",
       "msr",
       "slv",
       "mex",
       "mnp",
       "mac",
       "chn",
       "bra",
       "bgr",
       "prt",
       "btn",
       "fin",
       "sjm",
       "sur",
       "tur",
       "aia",
       "reu",
       "vat",
       "col",
       "zaf",
       "gib",
       "mus",
       "som",
       "che",
       "wsm",
       "esh",
       "jey",
       "khm",
       "afg",
       "spm",
       "pol",
       "civ",
       "wlf",
       "bhr",
       "npl",
       "grd",
       "kor",
       "mar",
       "tls",
       "moz",
       "kaz",
       "ton",
       "nfk",
       "uga",
       "iot",
       "hnd",
       "aus",
       "ven",
       "tkl",
       "tjk",
       "bvt",
       "umi",
       "blm",
       "syr",
       "yem",
       "pyf",
       "nga",
       "gnq",
       "mmr",
       "fro",
       "mys",
       "isr",
       "bel",
       "tgo",
       "sdn",
       "mrt",
       "usa",
       "dom",
       "tha",
       "vnm",
       "tcd",
       "tca",
       "flk",
       "mtq",
       "cog",
       "caf",
       "per",
       "hti",
       "kir",
       "lca",
       "swe",
       "cub",
       "blr",
       "irn",
       "pry",
       "irq",
       "are",
       "aze",
       "vut",
       "vct",
       "niu",
       "bhs",
       "gmb",
       "eri",
       "nic",
       "ago",
       "mng",
       "cpv",
       "ner",
       "ata",
       "mda",
       "sxm",
       "brb",
       "kwt",
       "deu",
       "phl",
       "mne",
       "lso",
       "ury",
       "shn",
       "arg",
       "tun",
       "blz",
       "ggy",
       "rus",
       "zmb",
       "srb",
       "dma",
       "prk",
       "ncl",
       "est",
       "ala",
       "ukr",
       "gab",
       "lux",
       "stp",
       "smr",
       "gbr",
       "guf",
       "ind",
       "mwi",
       "chl",
       "bfa",
       "nld",
       "lbr",
       "slb",
       "guy",
       "lka",
       "bwa",
       "bmu",
       "egy",
       "fsm",
       "gum",
       "svn",
       "pak",
       "jam",
       "bol",
       "lao",
       "cxr",
       "bih",
       "bes",
       "maf",
       "and",
       "qat",
       "atf",
       "ltu",
       "zwe",
       "png",
       "mco",
       "com",
       "kna",
       "gnb",
       "imn",
       "tuv",
       "myt",
       "jpn",
       "dza",
       "pse",
       "cyp",
       "cod",
       "bdi",
       "cze",
       "mhl",
       "kgz",
       "fra",
       "sen",
       "dnk",
       "lva",
       "glp",
       "asm",
       "can",
       "sgs",
       "esp",
       "vir",
       "tto",
       "gha",
       "ita",
       "pan",
       "tkm",
       "lie",
       "svk",
       "nam",
       "cok",
       "grl",
       "idn",
       "rou",
       "arm",
       "mdv",
       "omn",
       "ben",
       "mdg",
       "atg",
       "sau",
       "hkg",
       "grc",
       "aut",
       "hun",
       "twn",
       "gin",
       "rwa",
       "bgd",
       "cuw",
       "vgb",
     ],
     "match" => "\\A[a-z]{2,3}\\z",
     "x.in.summaries" => [
       "Ethiopia",
       "Papua New Guinea",
       "Australia",
       "Jersey",
       "Virgin Islands (British)",
       "Honduras",
       "Bolivia (Plurinational State of)",
       "Benin",
       "Cambodia",
       "Bermuda",
       "Bhutan",
       "Finland",
       "Tonga",
       "Somalia",
       "Nigeria",
       "Samoa",
       "Lithuania",
       "Cabo Verde",
       "Svalbard and Jan Mayen",
       "San Marino",
       "Trinidad and Tobago",
       "United Kingdom of Great Britain and Northern Ireland",
       "Congo",
       "Turkmenistan",
       "Aland Islands",
       "Sao Tome and Principe",
       "Malaysia",
       "Tajikistan",
       "Croatia",
       "Anguilla",
       "Bangladesh",
       "South Georgia and the South Sandwich Islands",
       "Pakistan",
       "Guinea",
       "Bosnia and Herzegovina",
       "Curacao",
       "Central African Republic",
       "Equatorial Guinea",
       "Saint Barthelemy",
       "Venezuela (Bolivarian Republic of)",
       "Marshall Islands",
       "Yemen",
       "Norfolk Island",
       "Peru",
       "Kiribati",
       "Ireland",
       "Qatar",
       "Mauritius",
       "Monaco",
       "Sudan",
       "Mexico",
       "Saudi Arabia",
       "Chad",
       "Romania",
       "Sierra Leone",
       "Niger",
       "Uganda",
       "French Polynesia",
       "Cayman Islands",
       "Cook Islands",
       "Lao People's Democratic Republic",
       "Greece",
       "Timor-Leste",
       "Palau",
       "Brunei Darussalam",
       "United Arab Emirates",
       "Liberia",
       "Gabon",
       "Madagascar",
       "Grenada",
       "Cyprus",
       "Bahamas",
       "Virgin Islands (U.S.)",
       "Haiti",
       "Spain",
       "Eswatini",
       "Suriname",
       "Zambia",
       "Tanzania, the United Republic of",
       "Bonaire, Sint Eustatius and Saba",
       "Turkiye",
       "Greenland",
       "Kenya",
       "Heard Island and McDonald Islands",
       "Maldives",
       "Senegal",
       "Afghanistan",
       "Aruba",
       "South Sudan",
       "Tunisia",
       "Eritrea",
       "Cote d'Ivoire",
       "Brazil",
       "Belize",
       "Nicaragua",
       "Lesotho",
       "Kuwait",
       "Paraguay",
       "Kyrgyzstan",
       "Denmark",
       "South Africa",
       "Lebanon",
       "Falkland Islands (The) [Malvinas]",
       "Uruguay",
       "North Macedonia",
       "Philippines",
       "Guatemala",
       "Vanuatu",
       "Saint Vincent and the Grenadines",
       "Germany",
       "Christmas Island",
       "Antigua and Barbuda",
       "Montenegro",
       "Gambia",
       "Solomon Islands",
       "Switzerland",
       "Cuba",
       "Cocos (Keeling) Islands",
       "Serbia",
       "New Caledonia",
       "Niue",
       "Malawi",
       "Saint Martin (French part)",
       "Guadeloupe",
       "Barbados",
       "Mozambique",
       "Mauritania",
       "France",
       "Tuvalu",
       "Colombia",
       "Algeria",
       "El Salvador",
       "Ukraine",
       "Norway",
       "Cameroon",
       "Singapore",
       "Reunion",
       "Latvia",
       "Togo",
       "Guam",
       "Saint Pierre and Miquelon",
       "Mayotte",
       "Isle of Man",
       "Ghana",
       "Portugal",
       "Bouvet Island",
       "Nepal",
       "Egypt",
       "Italy",
       "Martinique",
       "Bulgaria",
       "Rwanda",
       "Mongolia",
       "Montserrat",
       "British Indian Ocean Territory",
       "Congo (The Democratic Republic of the)",
       "Korea, The Republic of",
       "Kazakhstan",
       "Guyana",
       "Sweden",
       "Burkina Faso",
       "Netherlands (Kingdom of the)",
       "Sri Lanka",
       "Canada",
       "Botswana",
       "United States Minor Outlying Islands",
       "Tokelau",
       "Namibia",
       "Chile",
       "Japan",
       "Slovakia",
       "Azerbaijan",
       "Argentina",
       "Israel",
       "Taiwan (Province of China)",
       "Hungary",
       "Poland",
       "Gibraltar",
       "Jordan",
       "French Southern Territories",
       "American Samoa",
       "Belgium",
       "Oman",
       "Holy See",
       "Estonia",
       "Saint Kitts and Nevis",
       "Indonesia",
       "Antarctica",
       "Panama",
       "Jamaica",
       "French Guiana",
       "Northern Mariana Islands",
       "Puerto Rico",
       "China",
       "Guinea-Bissau",
       "Iran (Islamic Republic of)",
       "Slovenia",
       "Belarus",
       "Russian Federation",
       "Liechtenstein",
       "Georgia",
       "Myanmar",
       "Fiji",
       "Micronesia (Federated States of)",
       "Nauru",
       "New Zealand",
       "Andorra",
       "Dominica",
       "Burundi",
       "Iraq",
       "Malta",
       "Djibouti",
       "Syrian Arab Republic",
       "Pitcairn",
       "Czechia",
       "Costa Rica",
       "India",
       "Dominican Republic",
       "Macao",
       "Albania",
       "Libya",
       "Viet Nam",
       "Palestine, State of",
       "Iceland",
       "Faroe Islands",
       "Saint Helena, Ascension and Tristan da Cunha",
       "Turks and Caicos Islands",
       "Korea, The Democratic People's Republic of",
       "Seychelles",
       "United States of America",
       "Thailand",
       "Zimbabwe",
       "Saint Lucia",
       "Luxembourg",
       "Bahrain",
       "Mali",
       "Angola",
       "Comoros",
       "Wallis and Futuna",
       "Ecuador",
       "Uzbekistan",
       "Sint Maarten (Dutch part)",
       "Hong Kong",
       "Austria",
       "Moldova, The Republic of",
       "Western Sahara",
       "Guernsey",
       "Armenia",
       "Morocco",
       "Puerto Rico",
       "Cocos (Keeling) Islands",
       "North Macedonia",
       "Kenya",
       "Aruba",
       "Uzbekistan",
       "Sierra Leone",
       "Malta",
       "Ireland",
       "Iceland",
       "Fiji",
       "Seychelles",
       "Djibouti",
       "Brunei Darussalam",
       "Jordan",
       "New Zealand",
       "Ethiopia",
       "Nauru",
       "Costa Rica",
       "Croatia",
       "Cayman Islands",
       "Pitcairn",
       "Georgia",
       "Albania",
       "Lebanon",
       "Heard Island and McDonald Islands",
       "Tanzania, the United Republic of",
       "Norway",
       "Cameroon",
       "Singapore",
       "Guatemala",
       "Eswatini",
       "Mali",
       "South Sudan",
       "Libya",
       "Ecuador",
       "Palau",
       "Montserrat",
       "El Salvador",
       "Mexico",
       "Northern Mariana Islands",
       "Macao",
       "China",
       "Brazil",
       "Bulgaria",
       "Portugal",
       "Bhutan",
       "Finland",
       "Svalbard and Jan Mayen",
       "Suriname",
       "Turkiye",
       "Anguilla",
       "Reunion",
       "Holy See",
       "Colombia",
       "South Africa",
       "Gibraltar",
       "Mauritius",
       "Somalia",
       "Switzerland",
       "Samoa",
       "Western Sahara",
       "Jersey",
       "Cambodia",
       "Afghanistan",
       "Saint Pierre and Miquelon",
       "Poland",
       "Cote d'Ivoire",
       "Wallis and Futuna",
       "Bahrain",
       "Nepal",
       "Grenada",
       "Korea, The Republic of",
       "Morocco",
       "Timor-Leste",
       "Mozambique",
       "Kazakhstan",
       "Tonga",
       "Norfolk Island",
       "Uganda",
       "British Indian Ocean Territory",
       "Honduras",
       "Australia",
       "Venezuela (Bolivarian Republic of)",
       "Tokelau",
       "Tajikistan",
       "Bouvet Island",
       "United States Minor Outlying Islands",
       "Saint Barthelemy",
       "Syrian Arab Republic",
       "Yemen",
       "French Polynesia",
       "Nigeria",
       "Equatorial Guinea",
       "Myanmar",
       "Faroe Islands",
       "Malaysia",
       "Israel",
       "Belgium",
       "Togo",
       "Sudan",
       "Mauritania",
       "United States of America",
       "Dominican Republic",
       "Thailand",
       "Viet Nam",
       "Chad",
       "Turks and Caicos Islands",
       "Falkland Islands (The) [Malvinas]",
       "Martinique",
       "Congo",
       "Central African Republic",
       "Peru",
       "Haiti",
       "Kiribati",
       "Saint Lucia",
       "Sweden",
       "Cuba",
       "Belarus",
       "Iran (Islamic Republic of)",
       "Paraguay",
       "Iraq",
       "United Arab Emirates",
       "Azerbaijan",
       "Vanuatu",
       "Saint Vincent and the Grenadines",
       "Niue",
       "Bahamas",
       "Gambia",
       "Eritrea",
       "Nicaragua",
       "Angola",
       "Mongolia",
       "Cabo Verde",
       "Niger",
       "Antarctica",
       "Moldova, The Republic of",
       "Sint Maarten (Dutch part)",
       "Barbados",
       "Kuwait",
       "Germany",
       "Philippines",
       "Montenegro",
       "Lesotho",
       "Uruguay",
       "Saint Helena, Ascension and Tristan da Cunha",
       "Argentina",
       "Tunisia",
       "Belize",
       "Guernsey",
       "Russian Federation",
       "Zambia",
       "Serbia",
       "Dominica",
       "Korea, The Democratic People's Republic of",
       "New Caledonia",
       "Estonia",
       "Aland Islands",
       "Ukraine",
       "Gabon",
       "Luxembourg",
       "Sao Tome and Principe",
       "San Marino",
       "United Kingdom of Great Britain and Northern Ireland",
       "French Guiana",
       "India",
       "Malawi",
       "Chile",
       "Burkina Faso",
       "Netherlands (Kingdom of the)",
       "Liberia",
       "Solomon Islands",
       "Guyana",
       "Sri Lanka",
       "Botswana",
       "Bermuda",
       "Egypt",
       "Micronesia (Federated States of)",
       "Guam",
       "Slovenia",
       "Pakistan",
       "Jamaica",
       "Bolivia (Plurinational State of)",
       "Lao People's Democratic Republic",
       "Christmas Island",
       "Bosnia and Herzegovina",
       "Bonaire, Sint Eustatius and Saba",
       "Saint Martin (French part)",
       "Andorra",
       "Qatar",
       "French Southern Territories",
       "Lithuania",
       "Zimbabwe",
       "Papua New Guinea",
       "Monaco",
       "Comoros",
       "Saint Kitts and Nevis",
       "Guinea-Bissau",
       "Isle of Man",
       "Tuvalu",
       "Mayotte",
       "Japan",
       "Algeria",
       "Palestine, State of",
       "Cyprus",
       "Congo (The Democratic Republic of the)",
       "Burundi",
       "Czechia",
       "Marshall Islands",
       "Kyrgyzstan",
       "France",
       "Senegal",
       "Denmark",
       "Latvia",
       "Guadeloupe",
       "American Samoa",
       "Canada",
       "South Georgia and the South Sandwich Islands",
       "Spain",
       "Virgin Islands (U.S.)",
       "Trinidad and Tobago",
       "Ghana",
       "Italy",
       "Panama",
       "Turkmenistan",
       "Liechtenstein",
       "Slovakia",
       "Namibia",
       "Cook Islands",
       "Greenland",
       "Indonesia",
       "Romania",
       "Armenia",
       "Maldives",
       "Oman",
       "Benin",
       "Madagascar",
       "Antigua and Barbuda",
       "Saudi Arabia",
       "Hong Kong",
       "Greece",
       "Austria",
       "Hungary",
       "Taiwan (Province of China)",
       "Guinea",
       "Rwanda",
       "Bangladesh",
       "Curacao",
       "Virgin Islands (British)",
     ],
     "x.perl.coerce_rules" => ["From_str::to_lower"],
   },
 ]

Base type: L<str|Data::Sah::Type::str>

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID

 "ID"  # valid, becomes "id"

 "IDN"  # valid, becomes "idn"

 "xx"  # INVALID

 "xxx"  # INVALID

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("country::code*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("country::code", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "ID";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "xx";
 my $errmsg = $validator->($data); # => "Must be one of [\"et\",\"pg\",\"au\",\"je\",\"vg\",\"hn\",\"bo\",\"bj\",\"kh\",\"bm\",\"bt\",\"fi\",\"to\",\"so\",\"ng\",\"ws\",\"lt\",\"cv\",\"sj\",\"sm\",\"tt\",\"gb\",\"cg\",\"tm\",\"ax\",\"st\",\"my\",\"tj\",\"hr\",\"ai\",\"bd\",\"gs\",\"pk\",\"gn\",\"ba\",\"cw\",\"cf\",\"gq\",\"bl\",\"ve\",\"mh\",\"ye\",\"nf\",\"pe\",\"ki\",\"ie\",\"qa\",\"mu\",\"mc\",\"sd\",\"mx\",\"sa\",\"td\",\"ro\",\"sl\",\"ne\",\"ug\",\"pf\",\"ky\",\"ck\",\"la\",\"gr\",\"tl\",\"pw\",\"bn\",\"ae\",\"lr\",\"ga\",\"mg\",\"gd\",\"cy\",\"bs\",\"vi\",\"ht\",\"es\",\"sz\",\"sr\",\"zm\",\"tz\",\"bq\",\"tr\",\"gl\",\"ke\",\"hm\",\"mv\",\"sn\",\"af\",\"aw\",\"ss\",\"tn\",\"er\",\"ci\",\"br\",\"bz\",\"ni\",\"ls\",\"kw\",\"py\",\"kg\",\"dk\",\"za\",\"lb\",\"fk\",\"uy\",\"mk\",\"ph\",\"gt\",\"vu\",\"vc\",\"de\",\"cx\",\"ag\",\"me\",\"gm\",\"sb\",\"ch\",\"cu\",\"cc\",\"rs\",\"nc\",\"nu\",\"mw\",\"mf\",\"gp\",\"bb\",\"mz\",\"mr\",\"fr\",\"tv\",\"co\",\"dz\",\"sv\",\"ua\",\"no\",\"cm\",\"sg\",\"re\",\"lv\",\"tg\",\"gu\",\"pm\",\"yt\",\"im\",\"gh\",\"pt\",\"bv\",\"np\",\"eg\",\"it\",\"mq\",\"bg\",\"rw\",\"mn\",\"ms\",\"io\",\"cd\",\"kr\",\"kz\",\"gy\",\"se\",\"bf\",\"nl\",\"lk\",\"ca\",\"bw\",\"um\",\"tk\",\"na\",\"cl\",\"jp\",\"sk\",\"az\",\"ar\",\"il\",\"tw\",\"hu\",\"pl\",\"gi\",\"jo\",\"tf\",\"as\",\"be\",\"om\",\"va\",\"ee\",\"kn\",\"id\",\"aq\",\"pa\",\"jm\",\"gf\",\"mp\",\"pr\",\"cn\",\"gw\",\"ir\",\"si\",\"by\",\"ru\",\"li\",\"ge\",\"mm\",\"fj\",\"fm\",\"nr\",\"nz\",\"ad\",\"dm\",\"bi\",\"iq\",\"mt\",\"dj\",\"sy\",\"pn\",\"cz\",\"cr\",\"in\",\"do\",\"mo\",\"al\",\"ly\",\"vn\",\"ps\",\"is\",\"fo\",\"sh\",\"tc\",\"kp\",\"sc\",\"us\",\"th\",\"zw\",\"lc\",\"lu\",\"bh\",\"ml\",\"ao\",\"km\",\"wf\",\"ec\",\"uz\",\"sx\",\"hk\",\"at\",\"md\",\"eh\",\"gg\",\"am\",\"ma\",\"pri\",\"cck\",\"mkd\",\"ken\",\"abw\",\"uzb\",\"sle\",\"mlt\",\"irl\",\"isl\",\"fji\",\"syc\",\"dji\",\"brn\",\"jor\",\"nzl\",\"eth\",\"nru\",\"cri\",\"hrv\",\"cym\",\"pcn\",\"geo\",\"alb\",\"lbn\",\"hmd\",\"tza\",\"nor\",\"cmr\",\"sgp\",\"gtm\",\"swz\",\"mli\",\"ssd\",\"lby\",\"ecu\",\"plw\",\"msr\",\"slv\",\"mex\",\"mnp\",\"mac\",\"chn\",\"bra\",\"bgr\",\"prt\",\"btn\",\"fin\",\"sjm\",\"sur\",\"tur\",\"aia\",\"reu\",\"vat\",\"col\",\"zaf\",\"gib\",\"mus\",\"som\",\"che\",\"wsm\",\"esh\",\"jey\",\"khm\",\"afg\",\"spm\",\"pol\",\"civ\",\"wlf\",\"bhr\",\"npl\",\"grd\",\"kor\",\"mar\",\"tls\",\"moz\",\"kaz\",\"ton\",\"nfk\",\"uga\",\"iot\",\"hnd\",\"aus\",\"ven\",\"tkl\",\"tjk\",\"bvt\",\"umi\",\"blm\",\"syr\",\"yem\",\"pyf\",\"nga\",\"gnq\",\"mmr\",\"fro\",\"mys\",\"isr\",\"bel\",\"tgo\",\"sdn\",\"mrt\",\"usa\",\"dom\",\"tha\",\"vnm\",\"tcd\",\"tca\",\"flk\",\"mtq\",\"cog\",\"caf\",\"per\",\"hti\",\"kir\",\"lca\",\"swe\",\"cub\",\"blr\",\"irn\",\"pry\",\"irq\",\"are\",\"aze\",\"vut\",\"vct\",\"niu\",\"bhs\",\"gmb\",\"eri\",\"nic\",\"ago\",\"mng\",\"cpv\",\"ner\",\"ata\",\"mda\",\"sxm\",\"brb\",\"kwt\",\"deu\",\"phl\",\"mne\",\"lso\",\"ury\",\"shn\",\"arg\",\"tun\",\"blz\",\"ggy\",\"rus\",\"zmb\",\"srb\",\"dma\",\"prk\",\"ncl\",\"est\",\"ala\",\"ukr\",\"gab\",\"lux\",\"stp\",\"smr\",\"gbr\",\"guf\",\"ind\",\"mwi\",\"chl\",\"bfa\",\"nld\",\"lbr\",\"slb\",\"guy\",\"lka\",\"bwa\",\"bmu\",\"egy\",\"fsm\",\"gum\",\"svn\",\"pak\",\"jam\",\"bol\",\"lao\",\"cxr\",\"bih\",\"bes\",\"maf\",\"and\",\"qat\",\"atf\",\"ltu\",\"zwe\",\"png\",\"mco\",\"com\",\"kna\",\"gnb\",\"imn\",\"tuv\",\"myt\",\"jpn\",\"dza\",\"pse\",\"cyp\",\"cod\",\"bdi\",\"cze\",\"mhl\",\"kgz\",\"fra\",\"sen\",\"dnk\",\"lva\",\"glp\",\"asm\",\"can\",\"sgs\",\"esp\",\"vir\",\"tto\",\"gha\",\"ita\",\"pan\",\"tkm\",\"lie\",\"svk\",\"nam\",\"cok\",\"grl\",\"idn\",\"rou\",\"arm\",\"mdv\",\"omn\",\"ben\",\"mdg\",\"atg\",\"sau\",\"hkg\",\"grc\",\"aut\",\"hun\",\"twn\",\"gin\",\"rwa\",\"bgd\",\"cuw\",\"vgb\"]"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("country::code", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "ID";
 my $res = $validator->($data); # => ["","id"]
 
 # a sample invalid data
 $data = "xx";
 my $res = $validator->($data); # => ["Must be one of [\"et\",\"pg\",\"au\",\"je\",\"vg\",\"hn\",\"bo\",\"bj\",\"kh\",\"bm\",\"bt\",\"fi\",\"to\",\"so\",\"ng\",\"ws\",\"lt\",\"cv\",\"sj\",\"sm\",\"tt\",\"gb\",\"cg\",\"tm\",\"ax\",\"st\",\"my\",\"tj\",\"hr\",\"ai\",\"bd\",\"gs\",\"pk\",\"gn\",\"ba\",\"cw\",\"cf\",\"gq\",\"bl\",\"ve\",\"mh\",\"ye\",\"nf\",\"pe\",\"ki\",\"ie\",\"qa\",\"mu\",\"mc\",\"sd\",\"mx\",\"sa\",\"td\",\"ro\",\"sl\",\"ne\",\"ug\",\"pf\",\"ky\",\"ck\",\"la\",\"gr\",\"tl\",\"pw\",\"bn\",\"ae\",\"lr\",\"ga\",\"mg\",\"gd\",\"cy\",\"bs\",\"vi\",\"ht\",\"es\",\"sz\",\"sr\",\"zm\",\"tz\",\"bq\",\"tr\",\"gl\",\"ke\",\"hm\",\"mv\",\"sn\",\"af\",\"aw\",\"ss\",\"tn\",\"er\",\"ci\",\"br\",\"bz\",\"ni\",\"ls\",\"kw\",\"py\",\"kg\",\"dk\",\"za\",\"lb\",\"fk\",\"uy\",\"mk\",\"ph\",\"gt\",\"vu\",\"vc\",\"de\",\"cx\",\"ag\",\"me\",\"gm\",\"sb\",\"ch\",\"cu\",\"cc\",\"rs\",\"nc\",\"nu\",\"mw\",\"mf\",\"gp\",\"bb\",\"mz\",\"mr\",\"fr\",\"tv\",\"co\",\"dz\",\"sv\",\"ua\",\"no\",\"cm\",\"sg\",\"re\",\"lv\",\"tg\",\"gu\",\"pm\",\"yt\",\"im\",\"gh\",\"pt\",\"bv\",\"np\",\"eg\",\"it\",\"mq\",\"bg\",\"rw\",\"mn\",\"ms\",\"io\",\"cd\",\"kr\",\"kz\",\"gy\",\"se\",\"bf\",\"nl\",\"lk\",\"ca\",\"bw\",\"um\",\"tk\",\"na\",\"cl\",\"jp\",\"sk\",\"az\",\"ar\",\"il\",\"tw\",\"hu\",\"pl\",\"gi\",\"jo\",\"tf\",\"as\",\"be\",\"om\",\"va\",\"ee\",\"kn\",\"id\",\"aq\",\"pa\",\"jm\",\"gf\",\"mp\",\"pr\",\"cn\",\"gw\",\"ir\",\"si\",\"by\",\"ru\",\"li\",\"ge\",\"mm\",\"fj\",\"fm\",\"nr\",\"nz\",\"ad\",\"dm\",\"bi\",\"iq\",\"mt\",\"dj\",\"sy\",\"pn\",\"cz\",\"cr\",\"in\",\"do\",\"mo\",\"al\",\"ly\",\"vn\",\"ps\",\"is\",\"fo\",\"sh\",\"tc\",\"kp\",\"sc\",\"us\",\"th\",\"zw\",\"lc\",\"lu\",\"bh\",\"ml\",\"ao\",\"km\",\"wf\",\"ec\",\"uz\",\"sx\",\"hk\",\"at\",\"md\",\"eh\",\"gg\",\"am\",\"ma\",\"pri\",\"cck\",\"mkd\",\"ken\",\"abw\",\"uzb\",\"sle\",\"mlt\",\"irl\",\"isl\",\"fji\",\"syc\",\"dji\",\"brn\",\"jor\",\"nzl\",\"eth\",\"nru\",\"cri\",\"hrv\",\"cym\",\"pcn\",\"geo\",\"alb\",\"lbn\",\"hmd\",\"tza\",\"nor\",\"cmr\",\"sgp\",\"gtm\",\"swz\",\"mli\",\"ssd\",\"lby\",\"ecu\",\"plw\",\"msr\",\"slv\",\"mex\",\"mnp\",\"mac\",\"chn\",\"bra\",\"bgr\",\"prt\",\"btn\",\"fin\",\"sjm\",\"sur\",\"tur\",\"aia\",\"reu\",\"vat\",\"col\",\"zaf\",\"gib\",\"mus\",\"som\",\"che\",\"wsm\",\"esh\",\"jey\",\"khm\",\"afg\",\"spm\",\"pol\",\"civ\",\"wlf\",\"bhr\",\"npl\",\"grd\",\"kor\",\"mar\",\"tls\",\"moz\",\"kaz\",\"ton\",\"nfk\",\"uga\",\"iot\",\"hnd\",\"aus\",\"ven\",\"tkl\",\"tjk\",\"bvt\",\"umi\",\"blm\",\"syr\",\"yem\",\"pyf\",\"nga\",\"gnq\",\"mmr\",\"fro\",\"mys\",\"isr\",\"bel\",\"tgo\",\"sdn\",\"mrt\",\"usa\",\"dom\",\"tha\",\"vnm\",\"tcd\",\"tca\",\"flk\",\"mtq\",\"cog\",\"caf\",\"per\",\"hti\",\"kir\",\"lca\",\"swe\",\"cub\",\"blr\",\"irn\",\"pry\",\"irq\",\"are\",\"aze\",\"vut\",\"vct\",\"niu\",\"bhs\",\"gmb\",\"eri\",\"nic\",\"ago\",\"mng\",\"cpv\",\"ner\",\"ata\",\"mda\",\"sxm\",\"brb\",\"kwt\",\"deu\",\"phl\",\"mne\",\"lso\",\"ury\",\"shn\",\"arg\",\"tun\",\"blz\",\"ggy\",\"rus\",\"zmb\",\"srb\",\"dma\",\"prk\",\"ncl\",\"est\",\"ala\",\"ukr\",\"gab\",\"lux\",\"stp\",\"smr\",\"gbr\",\"guf\",\"ind\",\"mwi\",\"chl\",\"bfa\",\"nld\",\"lbr\",\"slb\",\"guy\",\"lka\",\"bwa\",\"bmu\",\"egy\",\"fsm\",\"gum\",\"svn\",\"pak\",\"jam\",\"bol\",\"lao\",\"cxr\",\"bih\",\"bes\",\"maf\",\"and\",\"qat\",\"atf\",\"ltu\",\"zwe\",\"png\",\"mco\",\"com\",\"kna\",\"gnb\",\"imn\",\"tuv\",\"myt\",\"jpn\",\"dza\",\"pse\",\"cyp\",\"cod\",\"bdi\",\"cze\",\"mhl\",\"kgz\",\"fra\",\"sen\",\"dnk\",\"lva\",\"glp\",\"asm\",\"can\",\"sgs\",\"esp\",\"vir\",\"tto\",\"gha\",\"ita\",\"pan\",\"tkm\",\"lie\",\"svk\",\"nam\",\"cok\",\"grl\",\"idn\",\"rou\",\"arm\",\"mdv\",\"omn\",\"ben\",\"mdg\",\"atg\",\"sau\",\"hkg\",\"grc\",\"aut\",\"hun\",\"twn\",\"gin\",\"rwa\",\"bgd\",\"cuw\",\"vgb\"]","xx"]

Data::Sah can also create validator that returns a hash of detailed error
message. Data::Sah can even create validator that targets other language, like
JavaScript, from the same schema. Other things Data::Sah can do: show source
code for validator, generate a validator code with debug comments and/or log
statements, generate human text from schema. See its documentation for more
details.

=head2 Using with Params::Sah

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("country::code*");
     $validator->(\@args);
     ...
 }

=head2 Using with Perinci::CmdLine::Lite

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> (L<Perinci::CmdLine::Lite>) to create a CLI:

 # in lib/MyApp.pm
 package
   MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['country::code*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }
 1;

 # in myapp.pl
 package
   main;
 use Perinci::CmdLine::Any;
 Perinci::CmdLine::Any->new(url=>'/MyApp/myfunc')->run;

 # in command-line
 % ./myapp.pl --help
 myapp - Routine to do blah ...
 ...

 % ./myapp.pl --version

 % ./myapp.pl --arg1 ...

=head2 Using on the CLI with validate-with-sah

To validate some data on the CLI, you can use L<validate-with-sah> utility.
Specify the schema as the first argument (encoded in Perl syntax) and the data
to validate as the second argument (encoded in Perl syntax):

 % validate-with-sah '"country::code*"' '"data..."'

C<validate-with-sah> has several options for, e.g. validating multiple data,
showing the generated validator code (Perl/JavaScript/etc), or loading
schema/data from file. See its manpage for more details.


=head2 Using with Type::Tiny

To create a type constraint and type library from a schema (requires
L<Type::Tiny> as well as L<Type::FromSah>):

 package My::Types {
     use Type::Library -base;
     use Type::FromSah qw( sah2type );

     __PACKAGE__->add_type(
         sah2type('country::code*', name=>'CountryCode')
     );
 }

 use My::Types qw(CountryCode);
 CountryCode->assert_valid($data);

=head1 DESCRIPTION

Accept only current (not retired) codes. Alpha-2 or alpha-3 codes are accepted.

Code will be converted to lowercase.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Country>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Country>.

=head1 SEE ALSO

L<Sah::Schema::country::code::alpha2>

L<Sah::Schema::country::code::alpha3>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2023, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Country>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
