package Mock::Person::DE;

use base qw(Exporter);
use strict;
use utf8;
use warnings;

use List::MoreUtils qw(none);
use Readonly;

# Constants.
Readonly::Scalar our $SPACE => q{ };
Readonly::Array our @EXPORT_OK => qw(first_male first_female middle_female
	last_male last_female middle_male middle_female name name_male
	name_female);

# Variables.
our $TYPE = 'three';

# Version.
our $VERSION = 0.06;

# First and middle male names.
our @first_male = our @middle_male = qw(
Adam
Adrian
Alex
Alexander
Alexandre
Ali
Amin
Andreas
Andy
Anton
Ben
Cedric
Chris
Christian
Claus
Daniel
David
Dennis
Dominic
Dominik
Fabian
Fabio
Felix
Florian
Frank
Freddy
Frederic
Gregor
Hans
Henry
Hermann
Ingo
Jan
Jasper
Jean
Joe
Jonas
Jonathan
Julian
Kai
Kay
Kevin
Lars
Leon
Lucas
Ludwig
Lukas
Manuel
Marcel
Marco
Marcus
Mark
Markus
Martin
Marvin
Matthias
Max
Maximilian
Micha
Michael
Moeppel
Nick
Nico
Niklas
Nils
Pascal
Patrick
Paul
Peter
Phil
Philipp
Ralf
Raoul
Ray
Rene
Rico
Robert
Robin
Ryan
Sami
Samuel
Sebastian
Simon
Someone
Stefan
Steffen
Stephan
Sven
Thomas
Till
Tim
Timo
Tobias
Tom
Victor
Vincent
Vinz
Virgil
Willem
Yannik
);

# First and middle female names.
our @first_female = our @middle_female = qw(
Alexandra
Amelie
Andrea
Angela
Anja
Anjeli
Anna
Anne
Anni
Annika
Antonia
Bianca
Carina
Caro
Carolin
Charlotte
Christin
Christina
Clara
Claudia
Daniela
Diana
Emma
Esther
Eva
Franzi
Franziska
Gabi
Hanna
Hannah
Helene
Ina
Isabell
Jacqueline
Jana
Janina
Janine
Jasmin
Jennifer
Jenny
Jessica
Johanna
Judith
Jule
Julia
Julie
Kate
Katharina
Kathi
Kathrin
Katja
Kim
Kristin
Kristina
Lara
Laura
Lea
Lena
Leonie
Lina
Linda
Lisa
Luisa
Maike
Mara
Maria
Marie
Marina
Melanie
Meli
Melissa
Michelle
Miriam
Nadine
Nicole
Nina
Pia
Ramona
Rebecca
Rieke
Sabrina
Sandra
Sara
Sarah
Saskia
Silke
Simone
Sonja
Sophia
Sophie
Stefanie
Steffi
Stella
Stephanie
Svenja
Teresa
Theresa
Tina
Vanessa
Verena
);

# Last names.
our @last_male = our @last_female = qw(
Müller
Schmidt
Schneider
Fischer
Weber
Schäfer
Meyer
Wagner
Becker
Bauer
Hoffmann
Schulz
Koch
Richter
Klein
Wolf
Schröder
Neumann
Braun
Werner
Schwarz
Hofmann
Zimmermann
Schmitt
Hartmann
Schmid
Weiß
Schmitz
Krüger
Lange
Meier
Walter
Köhler
Maier
Beck
König
Krause
Schulze
Huber
Mayer
Frank
Lehmann
Kaiser
Fuchs
Herrmann
Lang
Thomas
Peters
Stein
Jung
Möller
Berger
Martin
Friedrich
Scholz
Keller
Groß
Hahn
Roth
Günther
Vogel
Schubert
Winkler
Schuster
Jäger
Lorenz
Ludwig
Baumann
Heinrich
Otto
Simon
Graf
Kraus
Krämer
Böhm
Schulte
Albrecht
Franke
Winter
Schumacher
Vogt
Haas
Sommer
Schreiber
Engel
Ziegler
Dietrich
Brandt
Seidel
Kuhn
Busch
Horn
Arnold
Kühn
Bergmann
Pohl
Pfeiffer
Wolff
Voigt
Sauer
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

Mock::Person::DE - Generate random sets of German names.

=head1 SYNOPSIS

 use Mock::Person::DE qw(first_male first_female last_male last_female
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

L<about.com|http://german.about.com/od/names/a/German-Surnames.htm>

=item B<Middle names>

There's usually no distinction between a first and middle name in Germany.

=item B<First names>

L<indiachildnames.com|http://www.indiachildnames.com/top100/germannames.html>

=back

=head1 SUBROUTINES

=over 8

=item B<first_male()>

Returns random first name of male person.

=item B<first_female()>

Returns random first name of female person.

=item B<last_male()>

Returns random last name of male person.

=item B<last_female()>

Returns random last name of female person.

=item B<middle_male()>

Returns random middle name of male person.

=item B<middle_female()>

Returns random middle name of female person.

=item B<name([$sex])>

Recieves scalar with sex of the person ('male' or 'female') and returns
scalar with generated name.
Default value of $sex variable is undef, that means random name.

=item B<name_male()>

Returns random male name.

=item B<name_female()>

Returns random female name.

=back

=head1 VARIABLES

=over 8

=item B<TYPE>

 Name type.
 Possible values are: 'two', 'three'.
 Default value is 'three'.

=back

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Encode qw(encode_utf8);
 use Mock::Person::DE qw(name);

 # Error.
 print encode_utf8(name())."\n";

 # Output like.
 # Cedric Nick Baumann

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Encode qw(encode_utf8);
 use Mock::Person::DE;

 # Get all last male names.
 my @last_males = @Mock::Person::DE::last_male;

 # Print out.
 print sort map { encode_utf8($_)."\n" } @last_males;

 # Output:
 # Albrecht
 # Arnold
 # Bauer
 # Baumann
 # Beck
 # Becker
 # Berger
 # Bergmann
 # Brandt
 # Braun
 # Busch
 # Böhm
 # Dietrich
 # Engel
 # Fischer
 # Frank
 # Franke
 # Friedrich
 # Fuchs
 # Graf
 # Groß
 # Günther
 # Haas
 # Hahn
 # Hartmann
 # Heinrich
 # Herrmann
 # Hoffmann
 # Hofmann
 # Horn
 # Huber
 # Jung
 # Jäger
 # Kaiser
 # Keller
 # Klein
 # Koch
 # Kraus
 # Krause
 # Krämer
 # Krüger
 # Kuhn
 # Köhler
 # König
 # Kühn
 # Lang
 # Lange
 # Lehmann
 # Lorenz
 # Ludwig
 # Maier
 # Martin
 # Mayer
 # Meier
 # Meyer
 # Möller
 # Müller
 # Neumann
 # Otto
 # Peters
 # Pfeiffer
 # Pohl
 # Richter
 # Roth
 # Sauer
 # Schmid
 # Schmidt
 # Schmitt
 # Schmitz
 # Schneider
 # Scholz
 # Schreiber
 # Schröder
 # Schubert
 # Schulte
 # Schulz
 # Schulze
 # Schumacher
 # Schuster
 # Schwarz
 # Schäfer
 # Seidel
 # Simon
 # Sommer
 # Stein
 # Thomas
 # Vogel
 # Vogt
 # Voigt
 # Wagner
 # Walter
 # Weber
 # Weiß
 # Werner
 # Winkler
 # Winter
 # Wolf
 # Wolff
 # Ziegler
 # Zimmermann

=head1 DEPENDENCIES

L<Exporter>,
L<List::MoreUtils>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Mock::Person>

Install the Mock::Person modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mock-Person-DE>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2013-2021

BSD 2-Clause License

=head1 VERSION

0.06

=cut
