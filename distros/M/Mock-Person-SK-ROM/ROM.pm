package Mock::Person::SK::ROM;

use base qw(Exporter);
use strict;
use utf8;
use warnings;

use List::Util 1.33 qw(none);
use Readonly;

# Constants.
Readonly::Scalar our $SPACE => q{ };
Readonly::Array our @EXPORT_OK => qw(first_male first_female middle_female
	last_male last_female middle_male middle_female name name_male
	name_female);

# Variables.
our $TYPE = 'two';

our $VERSION = 0.03;

# First and middle male names.
our @first_male = our @middle_male = qw(
Arpad
Dezo
Dezider
Dominik
Ervin
Jiří
Jolana
Josef
Kalman
Kevin
Lajos
Marian
Petr
Roman
Viliam
);

# First and middle female names.
our @first_female = our @middle_female = qw(
Anna
Elizabeth
Erza
Esmeralda
Hana
Jessika
Kamila
Luci
Marika
Marget
Mária
Monika
Nikola
Renata
Romana
Terezie
Vanessa
Žaneta
);

# Last male names.
our @last_male = qw(
Absolon
Bady
Bado
Badžo
Bagár
Balog
Balogh
Bamberger
Bandi
Banga
Bango
Bari
Báro
Barok
Barya
Bazylak
Bažo
Bednár
Bendig
Bengoro
Beňák
Beňo
Berki
Berko
Bihári
Biháryi
Bikar
Bilaj
Bogol
Bokor
Botoš
Budaj
Byl
Cirok
Cobas
Csocs
Černohorský
Červeňák
Číča
Čičák
Čisar
Čobak
Čonka
Čornej
Čurej
Čureja
Čuri
Čurko
Daďo
Daniel
Danihel
Dajdy
Danko
Dany
Danyi
David
Demeter
Deňo
Derulo
Dirda
Dudy
Dunko
Duraj
Durasko
Durda
Durňak
Dydyk
Dzudza
Dzurko
Džuga
Džuman
Ďuďa
Fábero
Fabián
Fako
Farkaš
Fečo
Fehér
Fekete
Ferenc
Ferko
Gabčo
Gábor
Gadzor
Gadžor
Galba
Gataš
Gatoš
Gaži
Giňa
Giňo
Girga
Gizman
Goga
Gondolán
Gondy
Gorol
Grondzár
Grundza
Guman
Gunar
Gunár
Hangurbadžo
Hanko
Herák
Hiňa
Holdy
Holomek
Holub
Horváth
Hrivňák
Huňák
Husar
Chanžalik
Charvát
Ištánek
Ištok
Ištván
Janeček
Jano
Jurčo
Jurko
Kaleja
Kajkoš
Karol
Kašperko
Karvaj
Kavur
Kirko
Kirvej
Klempár
Klimt
Koky
Kuky
Kotlár
Kováč
Kovács
Kramčanin
Kučeraj
Kumaj
Kurej
Kurko
Kýr
Lacko
Lagryn
Lakatoš
Latymor
Lazok
Lofas
Lomanth
Maďar
Makaj
Makuňa
Malar
Malík
Mezej
Mezga
Mézga
Miazga
Miko
Milko
Mindzár
Mirga
Mižigar
Molnar
Murka
Németh
Oláh
Ondič
Oračko
Pacaj
Pako
Petržilka
Pfeffer
Plachetka
Pocikál
Pohlodko
Polhoš
Porčogoš
Procházka
Rigo
Richter
Rusznyak
Růžička
Sakajto
Samel
Sarkozy
Sinu
Sivák
Stojka
Stylar
Surmaj
Šajko
Szajko
Šamko
Szamko
Šandor
Šándor
Šarkezy
Ščuka
Šidélko
Šimko
Špivak
Šťuko
Tancoš
Tancosz
Telvak
Tomaš
Tomko
Totorkul
Tulej
Tuleja
Turták
Vega
Veselý
Virag
Vrba
Zaječí
Zaňák
Žiga
Žolták
);

# Last female names.
our @last_female = qw(
Mižigárová
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
	if (! defined $sex || none { $sex eq $_ } qw(female male)) {
		if ((int(rand(2)) + 1 ) % 2 == 0) {
			return name_male();
		} else {
			return name_female();
		}
	} elsif ($sex eq 'female') {
		return name_female();
	} elsif ($sex eq 'male') {
		return name_male();
	}
}

# Get random male name.
sub name_male {
	if (defined $TYPE && $TYPE eq 'three') {
		my $first_male = first_male();
		my $middle_male = middle_male();
		while ($first_male eq $middle_male) {
			$middle_male = middle_male();
		}
		return $first_male.$SPACE.$middle_male.$SPACE.last_male();
	} else {
		return first_male().$SPACE.last_male();
	}
}

# Get random female name.
sub name_female {
	if (defined $TYPE && $TYPE eq 'three') {
		my $first_female = first_female();
		my $middle_female = middle_female();
		while ($first_female eq $middle_female) {
			$middle_female = middle_female();
		}
		return $first_female.$SPACE.$middle_female.$SPACE.last_female();
	} else {
		return first_female().$SPACE.last_female();
	}
}

1;

__END__

=encoding UTF-8

=cut 

=head1 NAME

Mock::Person::SK::ROM - Generate random sets of Romani names.

=head1 SYNOPSIS

 use Mock::Person::SK::ROM qw(first_male first_female last_male last_female
         middle_male middle_female name name_female name_male);

 my $first_male = first_male();
 my $first_female = first_female();
 my $last_male = last_male();
 my $last_female = last_female();
 my $middle_male = middle_male();
 my $middle_female = middle_female();
 my $name = name($sex);
 my $female_name = name_female();
 my $male_name = name_male();

=head1 DESCRIPTION

Data for this module was found on these pages:

=over

=item B<Last names>

L<cz.wikipedia.org|http://cs.wikipedia.org/wiki/Seznam_nej%C4%8Detn%C4%9Bj%C5%A1%C3%ADch_p%C5%99%C3%ADjmen%C3%AD_v_%C4%8Cesku>

=item B<Middle names>

There's usually no distinction between a first and middle name in the Czech Republic.

=item B<First names>

L<cz.wikipedia.org - male names|http://cs.wikipedia.org/wiki/Seznam_nej%C4%8Dast%C4%9Bj%C5%A1%C3%ADch_mu%C5%BEsk%C3%BDch_jmen_v_%C4%8Cesk%C3%A9_republice>,
L<cs.wikipedia.org - female names|http://cs.wikipedia.org/wiki/Seznam_nej%C4%8Dast%C4%9Bj%C5%A1%C3%ADch_%C5%BEensk%C3%BDch_jmen_v_%C4%8Cesk%C3%A9_republice>.

=back

=head1 SUBROUTINES

=head2 C<first_male>

 my $first_male = first_male();

Get random first name of male person.

Returns string.

=head2 C<first_female>

 my $first_female = first_female();

Get random first name of female person.

Returns string.

=head2 C<last_male>

 my $last_male = last_male();

Get random last name of male person.

Returns string.

=head2 C<last_female>

 my $last_female = last_female();

Get random last name of female person.

Returns string.

=head2 C<middle_male>

 my $middle_male = middle_male();

Get random middle name of male person.

Returns string.

=head2 C<middle_female>

 my $middle_female = middle_female();

Get random middle name of female person.

Returns string.

=head2 C<name>

 my $name = name($sex);

Get name defined with sex of the person ('male' or 'female').
Default value of C<$sex> variable is undef, that means random name.

Returns string.

=head2 C<name_female>

 my $female_name = name_female();

Get random female name.

Returns string.

=head2 C<name_male>

 my $male_name = name_male();

Get random male name.

Returns string.

=head1 VARIABLES

=over 8

=item B<TYPE>

Name type.

Possible values are: 'two', 'three'.

Default value is 'two'.

=back

=head1 EXAMPLE1

=for comment filename=random_name.pl

 use strict;
 use warnings;

 use Encode qw(encode_utf8);
 use Mock::Person::SK::ROM qw(name);

 # Error.
 print encode_utf8(name())."\n";

 # Output like:
 # Kevin Mižigar

=head1 EXAMPLE2

=for comment filename=list_last_male_names.pl

 use strict;
 use warnings;

 use Encode qw(encode_utf8);
 use Mock::Person::SK::ROM;

 # Get all last male names.
 my @last_males = @Mock::Person::SK::ROM::last_male;

 # Print out.
 print sort map { encode_utf8($_)."\n" } @last_males;

 # Output:
 # Absolon
 # Bado
 # Bady
 # Badžo
 # Bagár
 # Balog
 # Balogh
 # Bamberger
 # Bandi
 # Banga
 # Bango
 # Bari
 # Barok
 # Barya
 # Bazylak
 # Bažo
 # Bednár
 # Bendig
 # Bengoro
 # Berki
 # Berko
 # Beňo
 # Beňák
 # Bihári
 # Biháryi
 # Bikar
 # Bilaj
 # Bogol
 # Bokor
 # Botoš
 # Budaj
 # Byl
 # Báro
 # Chanžalik
 # Charvát
 # Cirok
 # Cobas
 # Csocs
 # Dajdy
 # Daniel
 # Danihel
 # Danko
 # Dany
 # Danyi
 # David
 # Daďo
 # Demeter
 # Derulo
 # Deňo
 # Dirda
 # Dudy
 # Dunko
 # Duraj
 # Durasko
 # Durda
 # Durňak
 # Dydyk
 # Dzudza
 # Dzurko
 # Džuga
 # Džuman
 # Fabián
 # Fako
 # Farkaš
 # Fehér
 # Fekete
 # Ferenc
 # Ferko
 # Fečo
 # Fábero
 # Gabčo
 # Gadzor
 # Gadžor
 # Galba
 # Gataš
 # Gatoš
 # Gaži
 # Girga
 # Gizman
 # Giňa
 # Giňo
 # Goga
 # Gondolán
 # Gondy
 # Gorol
 # Grondzár
 # Grundza
 # Guman
 # Gunar
 # Gunár
 # Gábor
 # Hangurbadžo
 # Hanko
 # Herák
 # Hiňa
 # Holdy
 # Holomek
 # Holub
 # Horváth
 # Hrivňák
 # Husar
 # Huňák
 # Ištok
 # Ištván
 # Ištánek
 # Janeček
 # Jano
 # Jurko
 # Jurčo
 # Kajkoš
 # Kaleja
 # Karol
 # Karvaj
 # Kavur
 # Kašperko
 # Kirko
 # Kirvej
 # Klempár
 # Klimt
 # Koky
 # Kotlár
 # Kovács
 # Kováč
 # Kramčanin
 # Kuky
 # Kumaj
 # Kurej
 # Kurko
 # Kučeraj
 # Kýr
 # Lacko
 # Lagryn
 # Lakatoš
 # Latymor
 # Lazok
 # Lofas
 # Lomanth
 # Makaj
 # Makuňa
 # Malar
 # Malík
 # Maďar
 # Mezej
 # Mezga
 # Miazga
 # Miko
 # Milko
 # Mindzár
 # Mirga
 # Mižigar
 # Molnar
 # Murka
 # Mézga
 # Németh
 # Oláh
 # Ondič
 # Oračko
 # Pacaj
 # Pako
 # Petržilka
 # Pfeffer
 # Plachetka
 # Pocikál
 # Pohlodko
 # Polhoš
 # Porčogoš
 # Procházka
 # Richter
 # Rigo
 # Rusznyak
 # Růžička
 # Sakajto
 # Samel
 # Sarkozy
 # Sinu
 # Sivák
 # Stojka
 # Stylar
 # Surmaj
 # Szajko
 # Szamko
 # Tancosz
 # Tancoš
 # Telvak
 # Tomaš
 # Tomko
 # Totorkul
 # Tulej
 # Tuleja
 # Turták
 # Vega
 # Veselý
 # Virag
 # Vrba
 # Zaječí
 # Zaňák
 # Černohorský
 # Červeňák
 # Čisar
 # Čičák
 # Čobak
 # Čonka
 # Čornej
 # Čurej
 # Čureja
 # Čuri
 # Čurko
 # Číča
 # Ďuďa
 # Šajko
 # Šamko
 # Šandor
 # Šarkezy
 # Šidélko
 # Šimko
 # Špivak
 # Šándor
 # Ščuka
 # Šťuko
 # Žiga
 # Žolták

=head1 DEPENDENCIES

L<Exporter>,
L<List::Util>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Mock::Person>

Install the Mock::Person modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mock-Person-SK-ROM>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2013-2023

BSD 2-Clause License

=head1 VERSION

0.03

=cut
