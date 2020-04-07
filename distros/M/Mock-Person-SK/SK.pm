package Mock::Person::SK;

use base qw(Exporter);
use strict;
use utf8;
use warnings;

use Readonly;

# Constants.
Readonly::Scalar our $SPACE => q{ };
Readonly::Array our @EXPORT_OK => qw(first_male first_female middle_female
	last_male last_female middle_male middle_female name);

our $VERSION = 0.05;

# First and middle male names.
our @first_male = our @middle_male = qw(
Adam
Adolf
Adrián
Alan
Albert
Albín
Aleš
Alexander
Alexej
Alfonz
Alfréd
Alojz
Ambróz
Andrej
Anton
Arnold
Arpád
Augustín
Aurel
Bartolomej
Belo
Beňadik
Benjamín
Bernard
Blahoslav
Blažej
Bohdan
Bohumil
Bohumír
Bohuš
Bohuslav
Boleslav
Boris
Branislav
Bruno
Bystrík
Ctibor
Cyprián
Cyril
Dalibor
Daniel
Dávid
Demeter
Denis
Dezider
Dionýz
Dobroslav
Dominik
Drahomír
Drahoslav
Dušan
Edmund
Eduard
Emanuel
Emil
Erik
Ernest
Ervín
Eugen
Fedor
Félix
Ferdinand
Filip
Florián
František
Frederik
Fridrich
Gabriel
Gašpar
Gejza
Gregor
Gustáv
Henrich
Hilda
Hubert
Hugo
Ignác
Igor
Imrich
Ivan
Izidor
Jakub
Ján
Jarolím
Jaromír
Jaroslav
Jerguš
Jozef
Július
Juraj
Kamil
Karol
Kazimír
Klement
Koloman
Konštantín
Kornel
Kristián
Krištof
Ladislav
Leonard
Leopold
Levoslav
Ľubomír
Ľuboš
Ľuboslav
Ľudomil
Ľudovít
Lujza
Lukáš
Marcel
Marek
Marián
Mário
Martin
Matej
Matúš
Maximilián
Medard
Metod
Michal
Mikuláš
Milan
Miloš
Miloslav
Milota
Miroslav
Mojmír
Móric
Norbert
Oldrich
Oleg
Oliver
Ondrej
Oskar
Oto
Patrik
Pavol
Peter
Pravoslav
Prokop
Radomír
Radoslav
Radovan
Radúz
Rastislav
René
Richard
Róbert
Roland
Roman
Romana
Rudolf
Samuel
Sergej
Severín
Slavomír
Stanislav
Štefan
Svätopluk
Svetozár
Tadeáš
Teodor
Tibor
Tichomír
Timotej
Tomáš
Urban
Václav
Valentín
Valér
Vasil
Vavrinec
Vendelín
Viktor
Viliam
Vincent
Vít
Víťazoslav
Vladimír
Vladislav
Vlastimil
Vojtech
Vratislav
Vratko
Zdenko
Žigmund
Zlatko
Zoltán
);

# First and middle female names.
our @first_female = our @middle_female = qw(
Adela
Adriána
Agáta
Agnesa
Albína
Alena
Alexandra
Alica
Alojza
Alžbeta
Amália
Anabela
Anastázia
Andrea
Anežka
Angela
Anna
Antónia
Aurélia
Barbora
Beáta
Berta
Bibiána
Blanka
Blažena
Bohdana
Bohumila
Bohuslava
Božena
Božidara
Branislava
Brigita
Bronislava
Cecília
Dagmara
Dana
Danica
Daniela
Darina
Dáša
Denisa
Diana
Dobromila
Dobroslava
Dominika
Dorota
Drahomíra
Drahoslava
Dušana
Edita
Ela
Elena
Eleonóra
Eliška
Elvíra
Ema
Emília
Erika
Estera
Etela
Eugénia
Filoména
Františka
Gabriela
Galina
Gertrúda
Gizela
Hana
Hedviga
Helena
Henrieta
Hermína
Hortenzia
Ida
Iľja
Ingrida
Irena
Irma
Ivana
Iveta
Ivica
Izabela
Jana
Jarmila
Jaroslava
Jela
Jolana
Jozefína
Judita
Júlia
Juliana
Justína
Kamila
Karolína
Katarína
Klára
Klaudia
Kornélia
Kristína
Kvetoslava
Laura
Lea
Lenka
Lesana
Liana
Libuša
Linda
Lívia
Ľubica
Ľubomíra
Ľuboslava
Lucia
Ľudmila
Ľudomila
Lýdia
Magdaléna
Malvína
Marcela
Margaréta
Margita
Mária
Marianna
Marína
Marta
Martina
Matilda
Melánia
Michaela
Milada
Milena
Milica
Miloslava
Miriama
Miroslava
Monika
Nadežda
Natália
Nataša
Nikola
Nina
Nora
Oľga
Olympia
Otília
Patrícia
Paulína
Perla
Petra
Petronela
Regína
Renáta
Rozália
Ružena
Sabína
Sára
Sidónia
Silvia
Simona
Sláva
Slávka
Slavomíra
Soňa
Stanislava
Štefánia
Stela
Svetlana
Sylva
Tamara
Tatiana
Terézia
Uršuľa
Valentína
Valéria
Vanda
Veronika
Viera
Vieroslava
Viktória
Vilma
Viola
Vladimíra
Vlasta
Xénia
Žaneta
Zdenka
Želmíra
Zina
Zita
Zlatica
Žofia
Zoja
Zora
Zuzana
);

# Last male names.
our @last_male = qw(
Acsai
Adamec
Aina
Alt
Altnau
Amri
Andreánsky
Andrich
Anjel
Antl
Argesheimer
Auxt
Babarík
Babnič
Bacúšan
Baláž
Baliak
Balkovič
Ballinger
Bandura
Bánik
Banský
Barbírik
Barek
Barháč
Barinek
Bartánus
Bártek
Belko
Belkovič
Belopotocký
Benč
Bendík
Beňo
Beňuš
Beránek
Beraxa
Berčík
Bese
Bešenda
Betka
Bihári
Blaho
Blišťan
Bogus
Boháčik
Boroš
Borovička
Bošeľa
Bowman
Brady
Brečka
Brenkus
Brief
Brozman
Brož
Brtán
Brucháč
Bruoth
Bubelíny
Budaj
Bukovský
Bulla
Buncsek
Bunčiak
Burdy
Bursa
Butora
Bútora
Buvala
Caban
Cambel
Cesnak
Cibuľa
Cibulka
Cipciar
Citterberg
Combrink
Corrado
Couturier
Csáky
Cvanga
Čech
Čelár
Černák
Červený
Čičmanec
Čipka
Čižmár
Čmelík
Čunderlík
Datko
Daxner
Degúl
Demian
Demko
Demuth
Déneši
Deppert
Dettweiler
Divok
Dobrík
Dobrota
Dočekal
Dolinský
Dolňan
Doncsiák
Donoval
Doppler
Ďordík
Dorica
Dostál
Dovala
Dráb
Drga
Dubéci
Dubenský
Dubíny
Dudáš
Dugát
Duhan
Dunajský
Dupej
Ďurčík
Ďurčo
Durek
Ďuriš
Džuka
Eckel
Engler
Evanoff
Eyrich
Fabrícius
Farárik
Farmer
Fasco
Faschko
Faskó
Fasko
Fassco
Faška
Faško
Fedor
Fehér
Ferenc
Ferenčík
Ferianc
Ferrara
Ferster
Figľuš
Fillo
Filo
Fitkomides
Formánek
Fortiak
Francik
Franko
Franzgreb
Frgelec
Frntol
Futas
Gáfrik
Gajdoš
Gajdošík
Gašparovič
Gašperan
Gazdík
Gažura
Gažúrik
Giablo
Giertl
Giertli
Gilla
Glasmacher
Gloner
Golian
Gömöry
Gonda
Grakalskis
Gramla
Green
Grlický
Gronel
Gronell
Haas
Habovčík
Hais
Hajdúk
Hajdusik
Halaj
Hamaj
Hambálek
Handlír
Haraburda
Harmata
Harter
Harvanka
Hauck
Haviar
Havlíček
Havran
Havrila
Hawes
Heckmann
Helena
Herman
Hoechstetter
Hojčuš
Hoover
Horský
Horvát
Horváth
Hosek
Hoška
Hoško
Howard
Hrbáň
Hrbek
Hrmelár
Hrnčiarik
Hrňo
Hruška
Hrynda
Hudec
Hurdálek
Húsenica
Húska
Hutka
Huťka
Hutta
Chabada
Chamar
Chovan
Chovanec
Christ
Chudík
Ionadi
Ištván
Ivan
Ivanec
Ivaniš
Jágerčík
Jančik
Jančo
Jankovič
Jánošík
Janošková
Javorčík
Javorčík
Jávorský
Jerguš
Johan
Jokl
Juhász
Juracek
Kabar
Kaclik
Kaclík
Kadecký
Kahoun
Kachnič
Kalaský
Kamenský
Kán
Kantárik
Kantoris
Kapitán
Kappler
Kapusta
Karásek
Kardoš
Kaslik
Kelvány
Kieborz
Kieffer
Kizek
Klafczynski
Klajban
Kľavko
Klein
Kleskeň
Klíma
Klimek
Kliment
Klimo
Kloboučník
Kmetz
Knapčok
Kňaze
Kňazík
Knoško
Kocprd
Kočiš
Kodric
Koenig
Kohút
Kochan
Koľaj
Kolaj
Kolega
Kolesár
Komora
Komora
Koprda
Korbeľ
Kordulič
Korenačka
Korim
Kösegi
Kostka
Košičiar
Košík
Košius
Koštial
Kotkuliak
Kotrčka
Kotrík
Kotyra
Kováč
Kováčik
Kovalik
Koválik
Kovalík
Kozák
Kozar
Kozelnicky
Kozma
Kožiak
Kožiar
Krajčovič
Kralik
Krammer
Kraner
Krejčí
Krenický
Kresák
Krídlo
Krieger
Krištál
Krištek
Krištof
Krkoška
Krnáč
Kršák
Krupa
Kruszynski
Krušinský
Kružliak
Krystosik
Kubacký
Kubaský
Kubica
Kubička
Kubisch
Kubiš
Kubizniak
Kubos
Kubus
Kučera
Kúdelka
Kudor
Kuhnsman
Kuna
Kuntzler
Küntzler
Kupčok
Kupec
Kurajda
Kuricz
Laitman
Langhoerig
Láni
Lanz
Laubert
Laule
Laurinc
Ledbetter
Ledňa
Lefkowitz
Lehocký
Lehotský
Leitman
Leitner
Lenarth
Lepko
Lešták
Letko
Libič
Licko
Ličko
Lie
Lihan
Lichvár
Lipták
Liskay
Lisý
Litva
Lojko
Lojkovič
Lopušný
Lovecký
Luce
Ludvik
Lukáč
Lupták
Ľupták
Ľuptovčiak
Macko
Macula
Macuľa
Macz
Máček
Madda
Madro
Magic
Majerčík
Makovíni
Malatinec
Malga
Malloy
Maľo
Malus
Mangold
Marciň
Marconi
Marek
Marianek
Marinko
Martinec
Márton
Martzek
Maruška
Maruškin
Marzec
Matejovič
Matinec
Matoš
Matta
Matušák
Mauritz
Mayhew
Mazanec
Mede
Medveď
Mereš
Meyer
Mihál
Mihala
Michalčík
Michelčík
Mikloško
Mikovíny
Mikuláši
Mikulík
Mikuš
Mindek
Mindžák
Mitický
Miťko
Mitterbach
Mitterka
Mlynarčík
Mojčák
Mokoš
Molčan
Molota
Moorcroft
Moravčík
Morgenstern
Morhard
Motyka
Mühl
Müller
Muller
Multán
Murín
Murphy
Mutňan
Nagel
Náhlovský
Neal
Nelson
Nemčok
Németh
Nezbeda
Nichols
Nikel
Nikolaides
Nociar
Noellner
Noga
Nováček
Novak
Novysedlák
Nuota
Oberhauser
Obrtanec
Oceľ
Odelga
Okruhlica
Olsby
Olšiak
Omasta
Ondrášik
Ondruška
Oravec
Oravský
Pačesa
Paff
Pajtinka
Palazzo
Paleš
Palič
Pampúrik
Pančík
Panigaj
Pápai
Pápaj
Patúš
Paulen
Paulenka
Pauliak
Paulovič
Pavčiak
Pavelka
Pavlečka
Pavlík
Pavlove
Pazár
Pečienka
Pekár
Peniak
Pepich
Peško
Petljanska
Petráš
Petrin
Petruš
Pfender
Piatek
Pierce
Pikula
Pilát
Piliar
Piliarkin
Pindiak
Pipíš
Plieštik
Pltník
Pobožný
Podhoľský
Pohančanik
Pohančaník
Pohorelec
Pohorelský
Polák
Poliak
Polóny
Ponist
Pős
Posúch
Poš
Potančok
Pôbiš
Pravotiak
Prečuch
Predajňa
Profant
Puci
Račák
Radušovský
Rak
Rakita
Rastocky
Raška
Ratay
Raztocky
Ráztocký
Remenár
Remper
Repčiak
Repka
Révay
Rezníček
Ribos
Ridzoň
Riedinger
Rigaud
Robinson
Romankiewicz
Rossi
Roštár
Rozkoš
Rozložný
Rudáš
Rusnák
Sabo
Sahó
Saksa
Sanitra
Sečkáš
Seiler
Sekerák
Séleš
Senko
Sepeši
Shiller
Schaaf
Schimpf
Schlebach
Schmer
Schneider
Schnierer
Schreiner
Schvarcbacher
Sieden
Sihelský
Siládi
Siman
Sirota
Sitarčík
Sittler
Skubák
Slafkovský
Slamený
Sleziak
Složil
Slučiak
Smiešna
Smiešny
Soják
Soucz
Souček
Sperka
Spišjak
Spodniak
Springer
Srnka
Stadler
Stanček
Stančík
Stehlo
Steigauf
Stenczel
Straka
Strakota
Strass
Striežovský
Stringer
Strnad
Supala
Surový
Sutter
Sýkora
Šajgal
Šajgalík
Šebo
Šeco
Ševčík
Šimkovič
Šimon
Šimuny
Šimúny
Šindler
Šiška
Škadra
Škantár
Škoda
Škôlka
Škrovina
Škula
Šmajták
Šmejkal
Šmidt
Šmihula
Šperka
Šramko
Štádler
Šťavina
Štefanko
Števlík
Štrba
Štubňa
Štubniak
Štulrajter
Štulreiter
Šulej
Šuran
Švantner
Švarcbacher
Švelka
Švidraň
Švihra
Táborský
Tačár
Takáč
Tapajčík
Taxner
Testevič
Tešlár
Tetliak
Tilka
Tišliar
Tkáčik
Tokár
Tomajka
Tončík
Tonheiser
Toriška
Tóth
Trnavský
Trubiroh
Turčan
Turňa
Turošík
Uher
Ustak
Vajcík
Valentino
Valentko
Vandlík
Vaník
Varga
Vaslík
Vašina
Veládi
Venger
Vernársky
Vetrák
Veverka
Vičan
Vilímek
Vist
Vitello
Vlaszati
Vlčko
Vodál
Vološčuk
Vološín
Votroubek
Vrbovský
Vrunay
Wagner
Wahley
Weisenpacher
Wenger
Witcherley
Záhorec
Zahorec
Zachar
Zajac
Zajak
Zambory
Zaňák
Záturecký
Zemančík
Zemánek
Zemko
Zettlemoyer
Zeyst
Zibrín
Zingor
Zlevský
Zlúky
Zubák
Zubal
Zvara
Žďársky
Žemlička
Žiak
Žila
Žilík
);

# Last female names.
our @last_female = qw(
Balážová
Balogová
Horváthová
Kováčová
Lukáčová
Molnárová
Nagyová
Szabová
Tóthová
Vargová
);

# Get random first male name.
sub first_male {
	return $first_male[rand @first_male];
}

# Get random first female name.
sub first_female {
	return $first_female[rand @first_female];
}

# Get random last male name.
sub last_male {
	return $last_male[rand @last_male];
}

# Get random last female name.
sub last_female {
	return $last_female[rand @last_female];
}

# Get random middle male name.
sub middle_male {
	return $middle_male[rand @middle_male];
}

# Get random middle female name.
sub middle_female {
	return $middle_female[rand @middle_female];
}

# Get random name.
sub name {
	my $sex = shift;
	if (defined $sex && $sex eq 'female') {
		return first_female().$SPACE.middle_female().$SPACE.last_female();
	} else {
		return first_male().$SPACE.middle_male().$SPACE.last_male();
	}
}

1;

__END__

=encoding UTF-8

=cut

=head1 NAME

Mock::Person::SK - Generate random sets of Slovak names.

=head1 SYNOPSIS

 use Mock::Person::SK qw(first_male first_female last_male last_female
         middle_male middle_female name);

 my $first_male = first_male();
 my $first_female = first_female();
 my $last_male = last_male();
 my $last_female = last_female();
 my $middle_male = middle_male();
 my $middle_female = middle_female();
 my $name = name($sex);

=head1 DESCRIPTION

Data for this module was found on these pages:

=over

=item B<Last names>

L<faskofamily.com|http://www.faskofamily.com/rodova-vetva/priezviska>

=item B<Middle names>

There's usually no distinction between a first and middle name in Slovakia.

=item B<First names>

From Slovakia calendar.

=back

=head1 SUBROUTINES

=head2 C<first_male>

 my $first_male = first_male();

Returns random first name of male person.

=head2 C<first_female>

 my $first_female = first_female();

Returns random first name of female person.

=head2 C<last_male>

 my $last_male = last_male();

Returns random last name of male person.

=head2 C<last_female>

 my $last_female = last_female();

Returns random last name of female person.

=head2 C<middle_male>

 my $middle_male = middle_male();

Returns random middle name of male person.

=head2 C<middle_female>

 my $middle_female = middle_female();

Returns random middle name of female person.

=head2 C<name>

 my $name = name($sex);

Recieves scalar with sex of the person ('male' or 'female').

Default value of $sex variable is 'male'.

Returns scalar with generated name.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Encode qw(encode_utf8);
 use Mock::Person::SK qw(name);

 # Error.
 print encode_utf8(name())."\n";

 # Output like.
 # Vratislav Svätopluk Pravotiak

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Encode qw(encode_utf8);
 use Mock::Person::SK;

 # Get all last male names.
 my @last_males = @Mock::Person::SK::last_male;

 # Print out.
 print sort map { encode_utf8($_)."\n" } @last_males;

 # Output:
 # Acsai
 # Adamec
 # Aina
 # Alt
 # Altnau
 # Amri
 # Andreánsky
 # Andrich
 # Anjel
 # Antl
 # Argesheimer
 # Auxt
 # Babarík
 # Babnič
 # Bacúšan
 # Baliak
 # Balkovič
 # Ballinger
 # Baláž
 # Bandura
 # Banský
 # Barbírik
 # Barek
 # Barháč
 # Barinek
 # Bartánus
 # Belko
 # Belkovič
 # Belopotocký
 # Bendík
 # Benč
 # Beraxa
 # Beránek
 # Berčík
 # Bese
 # Betka
 # Beňo
 # Beňuš
 # Bešenda
 # Bihári
 # Blaho
 # Blišťan
 # Bogus
 # Boháčik
 # Borovička
 # Boroš
 # Bowman
 # Bošeľa
 # Brady
 # Brenkus
 # Brečka
 # Brief
 # Brozman
 # Brož
 # Brtán
 # Brucháč
 # Bruoth
 # Bubelíny
 # Budaj
 # Bukovský
 # Bulla
 # Buncsek
 # Bunčiak
 # Burdy
 # Bursa
 # Butora
 # Buvala
 # Bánik
 # Bártek
 # Bútora
 # Caban
 # Cambel
 # Cesnak
 # Chabada
 # Chamar
 # Chovan
 # Chovanec
 # Christ
 # Chudík
 # Cibulka
 # Cibuľa
 # Cipciar
 # Citterberg
 # Combrink
 # Corrado
 # Couturier
 # Csáky
 # Cvanga
 # Datko
 # Daxner
 # Degúl
 # Demian
 # Demko
 # Demuth
 # Deppert
 # Dettweiler
 # Divok
 # Dobrota
 # Dobrík
 # Dolinský
 # Dolňan
 # Doncsiák
 # Donoval
 # Doppler
 # Dorica
 # Dostál
 # Dovala
 # Dočekal
 # Drga
 # Dráb
 # Dubenský
 # Dubéci
 # Dubíny
 # Dudáš
 # Dugát
 # Duhan
 # Dunajský
 # Dupej
 # Durek
 # Déneši
 # Džuka
 # Eckel
 # Engler
 # Evanoff
 # Eyrich
 # Fabrícius
 # Farmer
 # Farárik
 # Faschko
 # Fasco
 # Fasko
 # Faskó
 # Fassco
 # Faška
 # Faško
 # Fedor
 # Fehér
 # Ferenc
 # Ferenčík
 # Ferianc
 # Ferrara
 # Ferster
 # Figľuš
 # Fillo
 # Filo
 # Fitkomides
 # Formánek
 # Fortiak
 # Francik
 # Franko
 # Franzgreb
 # Frgelec
 # Frntol
 # Futas
 # Gajdoš
 # Gajdošík
 # Gazdík
 # Gašparovič
 # Gašperan
 # Gažura
 # Gažúrik
 # Giablo
 # Giertl
 # Giertli
 # Gilla
 # Glasmacher
 # Gloner
 # Golian
 # Gonda
 # Grakalskis
 # Gramla
 # Green
 # Grlický
 # Gronel
 # Gronell
 # Gáfrik
 # Gömöry
 # Haas
 # Habovčík
 # Hais
 # Hajdusik
 # Hajdúk
 # Halaj
 # Hamaj
 # Hambálek
 # Handlír
 # Haraburda
 # Harmata
 # Harter
 # Harvanka
 # Hauck
 # Haviar
 # Havlíček
 # Havran
 # Havrila
 # Hawes
 # Heckmann
 # Helena
 # Herman
 # Hoechstetter
 # Hojčuš
 # Hoover
 # Horský
 # Horvát
 # Horváth
 # Hosek
 # Howard
 # Hoška
 # Hoško
 # Hrbek
 # Hrbáň
 # Hrmelár
 # Hrnčiarik
 # Hruška
 # Hrynda
 # Hrňo
 # Hudec
 # Hurdálek
 # Hutka
 # Hutta
 # Huťka
 # Húsenica
 # Húska
 # Ionadi
 # Ivan
 # Ivanec
 # Ivaniš
 # Ištván
 # Jankovič
 # Janošková
 # Jančik
 # Jančo
 # Javorčík
 # Javorčík
 # Jerguš
 # Johan
 # Jokl
 # Juhász
 # Juracek
 # Jágerčík
 # Jánošík
 # Jávorský
 # Kabar
 # Kachnič
 # Kaclik
 # Kaclík
 # Kadecký
 # Kahoun
 # Kalaský
 # Kamenský
 # Kantoris
 # Kantárik
 # Kapitán
 # Kappler
 # Kapusta
 # Kardoš
 # Karásek
 # Kaslik
 # Kelvány
 # Kieborz
 # Kieffer
 # Kizek
 # Klafczynski
 # Klajban
 # Klein
 # Kleskeň
 # Klimek
 # Kliment
 # Klimo
 # Kloboučník
 # Klíma
 # Kmetz
 # Knapčok
 # Knoško
 # Kochan
 # Kocprd
 # Kodric
 # Koenig
 # Kohút
 # Kolaj
 # Kolega
 # Kolesár
 # Komora
 # Komora
 # Koprda
 # Korbeľ
 # Kordulič
 # Korenačka
 # Korim
 # Kostka
 # Kotkuliak
 # Kotrík
 # Kotrčka
 # Kotyra
 # Kovalik
 # Kovalík
 # Koválik
 # Kováč
 # Kováčik
 # Kozar
 # Kozelnicky
 # Kozma
 # Kozák
 # Kočiš
 # Koľaj
 # Košius
 # Košičiar
 # Koštial
 # Košík
 # Kožiak
 # Kožiar
 # Krajčovič
 # Kralik
 # Krammer
 # Kraner
 # Krejčí
 # Krenický
 # Kresák
 # Krieger
 # Krištek
 # Krištof
 # Krištál
 # Krkoška
 # Krnáč
 # Krupa
 # Kruszynski
 # Krušinský
 # Kružliak
 # Krystosik
 # Krídlo
 # Kršák
 # Kubacký
 # Kubaský
 # Kubica
 # Kubisch
 # Kubizniak
 # Kubička
 # Kubiš
 # Kubos
 # Kubus
 # Kudor
 # Kuhnsman
 # Kuna
 # Kuntzler
 # Kupec
 # Kupčok
 # Kurajda
 # Kuricz
 # Kučera
 # Kán
 # Kösegi
 # Kúdelka
 # Küntzler
 # Kľavko
 # Kňaze
 # Kňazík
 # Laitman
 # Langhoerig
 # Lanz
 # Laubert
 # Laule
 # Laurinc
 # Ledbetter
 # Ledňa
 # Lefkowitz
 # Lehocký
 # Lehotský
 # Leitman
 # Leitner
 # Lenarth
 # Lepko
 # Letko
 # Lešták
 # Libič
 # Lichvár
 # Licko
 # Lie
 # Lihan
 # Lipták
 # Liskay
 # Lisý
 # Litva
 # Ličko
 # Lojko
 # Lojkovič
 # Lopušný
 # Lovecký
 # Luce
 # Ludvik
 # Lukáč
 # Lupták
 # Láni
 # Macko
 # Macula
 # Macuľa
 # Macz
 # Madda
 # Madro
 # Magic
 # Majerčík
 # Makovíni
 # Malatinec
 # Malga
 # Malloy
 # Malus
 # Mangold
 # Marciň
 # Marconi
 # Marek
 # Marianek
 # Marinko
 # Martinec
 # Martzek
 # Maruška
 # Maruškin
 # Marzec
 # Matejovič
 # Matinec
 # Matoš
 # Matta
 # Matušák
 # Mauritz
 # Mayhew
 # Mazanec
 # Maľo
 # Mede
 # Medveď
 # Mereš
 # Meyer
 # Michalčík
 # Michelčík
 # Mihala
 # Mihál
 # Mikloško
 # Mikovíny
 # Mikuláši
 # Mikulík
 # Mikuš
 # Mindek
 # Mindžák
 # Mitický
 # Mitterbach
 # Mitterka
 # Miťko
 # Mlynarčík
 # Mojčák
 # Mokoš
 # Molota
 # Molčan
 # Moorcroft
 # Moravčík
 # Morgenstern
 # Morhard
 # Motyka
 # Muller
 # Multán
 # Murphy
 # Murín
 # Mutňan
 # Márton
 # Máček
 # Mühl
 # Müller
 # Nagel
 # Neal
 # Nelson
 # Nemčok
 # Nezbeda
 # Nichols
 # Nikel
 # Nikolaides
 # Nociar
 # Noellner
 # Noga
 # Novak
 # Novysedlák
 # Nováček
 # Nuota
 # Náhlovský
 # Németh
 # Oberhauser
 # Obrtanec
 # Oceľ
 # Odelga
 # Okruhlica
 # Olsby
 # Olšiak
 # Omasta
 # Ondruška
 # Ondrášik
 # Oravec
 # Oravský
 # Paff
 # Pajtinka
 # Palazzo
 # Paleš
 # Palič
 # Pampúrik
 # Panigaj
 # Pančík
 # Patúš
 # Paulen
 # Paulenka
 # Pauliak
 # Paulovič
 # Pavelka
 # Pavlečka
 # Pavlove
 # Pavlík
 # Pavčiak
 # Pazár
 # Pačesa
 # Pekár
 # Peniak
 # Pepich
 # Petljanska
 # Petrin
 # Petruš
 # Petráš
 # Pečienka
 # Peško
 # Pfender
 # Piatek
 # Pierce
 # Pikula
 # Piliar
 # Piliarkin
 # Pilát
 # Pindiak
 # Pipíš
 # Plieštik
 # Pltník
 # Pobožný
 # Podhoľský
 # Pohančanik
 # Pohančaník
 # Pohorelec
 # Pohorelský
 # Poliak
 # Polák
 # Polóny
 # Ponist
 # Posúch
 # Potančok
 # Poš
 # Pravotiak
 # Predajňa
 # Prečuch
 # Profant
 # Puci
 # Pápai
 # Pápaj
 # Pôbiš
 # Pős
 # Radušovský
 # Rak
 # Rakita
 # Rastocky
 # Ratay
 # Raztocky
 # Račák
 # Raška
 # Remenár
 # Remper
 # Repka
 # Repčiak
 # Rezníček
 # Ribos
 # Ridzoň
 # Riedinger
 # Rigaud
 # Robinson
 # Romankiewicz
 # Rossi
 # Rozkoš
 # Rozložný
 # Roštár
 # Rudáš
 # Rusnák
 # Ráztocký
 # Révay
 # Sabo
 # Sahó
 # Saksa
 # Sanitra
 # Schaaf
 # Schimpf
 # Schlebach
 # Schmer
 # Schneider
 # Schnierer
 # Schreiner
 # Schvarcbacher
 # Seiler
 # Sekerák
 # Senko
 # Sepeši
 # Sečkáš
 # Shiller
 # Sieden
 # Sihelský
 # Siládi
 # Siman
 # Sirota
 # Sitarčík
 # Sittler
 # Skubák
 # Slafkovský
 # Slamený
 # Sleziak
 # Složil
 # Slučiak
 # Smiešna
 # Smiešny
 # Soják
 # Soucz
 # Souček
 # Sperka
 # Spišjak
 # Spodniak
 # Springer
 # Srnka
 # Stadler
 # Stanček
 # Stančík
 # Stehlo
 # Steigauf
 # Stenczel
 # Straka
 # Strakota
 # Strass
 # Striežovský
 # Stringer
 # Strnad
 # Supala
 # Surový
 # Sutter
 # Séleš
 # Sýkora
 # Takáč
 # Tapajčík
 # Taxner
 # Tačár
 # Testevič
 # Tetliak
 # Tešlár
 # Tilka
 # Tišliar
 # Tkáčik
 # Tokár
 # Tomajka
 # Tonheiser
 # Tončík
 # Toriška
 # Trnavský
 # Trubiroh
 # Turošík
 # Turčan
 # Turňa
 # Táborský
 # Tóth
 # Uher
 # Ustak
 # Vajcík
 # Valentino
 # Valentko
 # Vandlík
 # Vaník
 # Varga
 # Vaslík
 # Vašina
 # Veládi
 # Venger
 # Vernársky
 # Vetrák
 # Veverka
 # Vilímek
 # Vist
 # Vitello
 # Vičan
 # Vlaszati
 # Vlčko
 # Vodál
 # Vološín
 # Vološčuk
 # Votroubek
 # Vrbovský
 # Vrunay
 # Wagner
 # Wahley
 # Weisenpacher
 # Wenger
 # Witcherley
 # Zachar
 # Zahorec
 # Zajac
 # Zajak
 # Zambory
 # Zaňák
 # Zemančík
 # Zemko
 # Zemánek
 # Zettlemoyer
 # Zeyst
 # Zibrín
 # Zingor
 # Zlevský
 # Zlúky
 # Zubal
 # Zubák
 # Zvara
 # Záhorec
 # Záturecký
 # Čech
 # Čelár
 # Černák
 # Červený
 # Čipka
 # Čičmanec
 # Čižmár
 # Čmelík
 # Čunderlík
 # Ďordík
 # Ďuriš
 # Ďurčo
 # Ďurčík
 # Ľuptovčiak
 # Ľupták
 # Šajgal
 # Šajgalík
 # Šebo
 # Šeco
 # Ševčík
 # Šimkovič
 # Šimon
 # Šimuny
 # Šimúny
 # Šindler
 # Šiška
 # Škadra
 # Škantár
 # Škoda
 # Škrovina
 # Škula
 # Škôlka
 # Šmajták
 # Šmejkal
 # Šmidt
 # Šmihula
 # Šperka
 # Šramko
 # Štefanko
 # Števlík
 # Štrba
 # Štubniak
 # Štubňa
 # Štulrajter
 # Štulreiter
 # Štádler
 # Šulej
 # Šuran
 # Švantner
 # Švarcbacher
 # Švelka
 # Švidraň
 # Švihra
 # Šťavina
 # Žemlička
 # Žiak
 # Žila
 # Žilík
 # Žďársky

=head1 DEPENDENCIES

L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Mock::Person>

Install the Mock::Person modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mock-Person-SK>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2013-2020

BSD 2-Clause License

=head1 VERSION

0.05

=cut
