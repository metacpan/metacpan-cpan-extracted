#! /usr/bin/perl
#########################################################################
#        This Perl script is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This script is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################
use utf8;
use open ':locale';   # when was the open pragma introduced ?
#my $EncodingString = q{};
#if (($ENV{LANG} =~ /utf-?8/i) || ($ENV{LC_TYPE} =~ /utf-?8/i)) {
#    $EncodingString = ':encoding(utf8)';
#	binmode STDERR, $EncodingString;
#	binmode STDOUT, $EncodingString;
#}
if (($ENV{LANG} =~ /utf-?8/i) || ($ENV{LC_TYPE} =~ /utf-?8/i)) {
	$Brillouin = "Léon Brillouin";
	$Delbrueck = "Max Delbrück";
	$Descartes = "René Descartes";
	$Goedel    = "Kurt Gödel";
	$Levy      = "Paul Lévy";
	$Poincare  = "Henri Poincaré";
	$Schroedinger = "Erwin Schrödinger";
} else {
	$Brillouin = "L\x{e9}on Brillouin";
	$Delbrueck = "Max Delbr\x{fc}ck";
	$Descartes = "Ren\x{e9} Descartes";
	$Goedel    = "Kurt G\x{f6}del";
	$Levy      = "Paul L\x{e9}vy";
	$Poincare  = "Henri Poincar\x{e9}";
	$Schroedinger = "Erwin Schr\x{f6}dinger";
}
eval "require 'Term/Clui.pm'";
if (!$@) {
	warn "using Term::Clui\n";
} else {
	eval "require '../Clui.pm'";
	if (!$@) {
		warn "using ../Clui.pm\n";
	} else {
		eval "require 'Clui.pm'";
		if (!$@) {
			warn "using ./Clui.pm\n";
		} else {
			die "can't find Clui.pm in this dir, parent dir, or INC path\n";
		}
	}
}
import Term::Clui;

eval "require './Term/Clui/FileSelect.pm'";
if ($@) { eval "require '../Clui/FileSelect.pm'"; }
if ($@) { eval "require 'Clui/FileSelect.pm'"; }
if ($@) {
	die "can't find FileSelect.pm in this dir, parent dir, or INC path\n";
}
import Term::Clui::FileSelect;
my $colour = "";
my $paint = "";
my $name = "";

while (1) {
	my $task = &choose('Test which Clui.pm subroutine ?',
		'ask','choose','confirm','edit','view','select_file',
	);
	exit unless $task;
	eval "&test_$task()"; if ($@) { print STDERR "$@\n"; }
}

sub test_choose {
	my @colours = ('Red','Orange','Black','Grey','Blue');
	my @paints  = (
	'Bizzare extremely long name that certainly will never occur on any real artist pallette',
  	'Alizarin Crimson', 'Burnt Sienna', 'Cadmium Yellow', 'Cobalt Blue',
	'Flake White', 'Indian Red', 'Indian Yellow', 'Ivory Black', 'Lemon Yellow',
	'Naples Yellow', 'Prussian Blue', 'Raw Sienna', 'Raw Umber', 'Red Ochre',
  	'Rose Madder', 'Ultramarine Blue', 'Vandyke Brown', 'Viridian Green',
	'Yellow Ochre',
	);
	my @scientists = (
	'Luis Alvarez', 'Alain Aspect', 'Michael Barnsley', 'Johann Bernouilli',
	'Nicolas Bernouilli', 'Friedrich Wilhelm Bessel', 'John Bell',
	'Antoine Becquerel', 'Hans Bethe', 'David Bohm', 'Niels Bohr',
	'Ludwig Boltzmann', 'Hermann Bondi', 'George Boole', 'Max Born',
	'Satyendra Bose', 'Robert Boyle', $Brillouin, 'Eugenio Calabi',
	'Georg Cantor', 'James Chadwick', 'Gregory Chaitin',
	'Subrahmanyan Chandrasekar', 'Geoffrey Chew', 'Alonzo Church',
	'John Horton Conway', 'Francis Crick', 'Marie Curie', 'Charles Darwin',
	'Humphrey Davy', 'Richard Dawkins', 'Louis de Broglie', $Delbrueck,
	$Descartes, 'Willem de Sitter', 'Bruce DeWitt', 'Paul Dirac',
	'Freeman Dyson', 'Arthur Stanley Eddington', 'Albert Einstein',
	'Leonhard Euler', 'Hugh Everett', 'Michael Faraday', 'Pierre Fatou',
	'Mitchell Feigenbaum', 'Pierre de Fermat', 'Enrico Fermi',
	'Richard Feynman', 'Joseph Fraunhofer', 'Galileo Galilei',
	'Evariste Galois', 'George Gamov', 'Carl Friedrich Gauss',
	'Murray Gell-Mann', $Goedel, 'Alan Guth', 'Stephen Hawking',
	'Felix Hausdorff', 'Werner Heisenberg', 'Charles Hermite',
	'Peter Higgs', 'David Hilbert', 'Fred Hoyle', 'Edwin Hubble',
	'Christian Huygens', 'David Hilbert', 'Edwin Hubble', 'Pascual Jordan',
	'Gaston Julia', 'Marc Kac', 'Theodor Kaluza', 'Stuart Kauffman',
	'William Lord Kelvin', 'Gustav Robert Kirchhoff', 'Oskar Klein',
	'Helge von Kock', 'Willis Lamb', 'Lev Davidovich Landau', 'Paul Langevin',
	'Pierre Simon de Laplace', 'Gottfried Wilhelm Leibnitz', $Levy,
	'Hendrik Lorentz', 'James Clark Maxwell', 'Marston Morse',
	'Benoit Mandelbrot', 'Gregor Mendel', 'Dmitri Mendeleev', 'Robert Millikan',
	'Hermann Minkowski', 'John von Neumann', 'Isaac Newton', 'Emmy Noether',
	'Hans Christian Oersted', 'Lars Onsager', 'Robert Oppenheimer',
	'Abraham Pais', 'Heinz Pagels', 'Vilfredo Pareto', 'Louis Pasteur',
	'Wolfgang Pauli', 'Linus Pauling', 'Guiseppe Peano', 'Rudolf Peierls',
	'Roger Penrose', 'Arno Penzias', 'Jean Perrin', 'Max Planck',
	'Boris Podolsky', $Poincare, 'Isidor Rabi', 'Srinivasa Ramanujan',
	'Lord Rayleigh', 'Lewis Fry Richardson', 'B. Riemann', 'Nathan Rosen',
	'Ernest Rutherford', 'Abdus Salam', $Schroedinger,
	'Karl Schwarzschild', 'Julian Schwinger', 'Claude Shannon',
	'Waclaw Sierpinski', 'Leo Szilard', 'Kip Thorne', 'Alan Turning',
	'Sin-itro Tomonaga', 'Stanislaw Ulam', 'James Watson', 'Karl Weierstrauss',
	'Hermann Weyl', 'Steven Weinberg', 'John Wheeler', 'Charles Weiner',
	'Norbert Wiener', 'Eugene Wigner', 'Robert Wilson', 'Edward Witten',
	'Shing-Tung Yau', 'Chen-Ning Yang', 'Hideki Yukawa', 'George Kingsley Zipf',
	);

	my $multi = &choose('Mode ?', 'Single-choice', 'Multi-choice');
	return unless $multi;
	if ($multi eq 'Single-choice') {
		$paint = &choose("Your favourite paint ?\n".help_text(), @paints);
		my $scientist = &choose("Your favourite scientist ?", @scientists);
		$colour = &choose(<<'EOT', @colours);
Your favourite colour ?

This tests how the 'choose' subroutine handles multi-line
questions. After you choose, all but the first line should disappear,
leaving the question and answer on the screen as a record of the dialogue.
The other lines should only get displayed if there is room.
EOT
		&inform("paint=$paint, scientist=$scientist, colour=$colour\n");
	} else {
		my @fav_paints
		 = &choose("Your favourite paints ?\n".help_text('multi'),@paints);
		my @fav_scientists = &choose("Your favourite scientists ?",@scientists);
		warn "paints = ".join(', ',@fav_paints) .
			"\nscientists = ".join(', ',@fav_scientists)."\n";
	}
	return;
}

sub test_confirm {
	&confirm(<<EOT) || return;
OK to proceed with the test ?

This step checks the 'confirm' subroutine and whether it handles
a multiline question OK.  After you choose Yes or No all but the
first line should disappear,  leaving the question and answer on
the screen as a record of the dialogue.
EOT

	&confirm('Did the text vanish except for the 1st line ?');
}

sub test_ask {
	my $question = <<EOT;
Enter a string :

The point of this test is to check out the behaviour of &ask
with multi-line questions; subsequent lines after the initial
question should be formatted within the window width ...
EOT
	my $string = &ask($question.help_text('ask'));

	my @colours = ('Red','Orange','Black','Grey','Blue');
	$colour = &choose('Your favourite colour ?', @colours);
	return unless $colour;
	%names = (
		Red=>'Fred', Orange=>'Solange', Black=>'Jack', Grey=>'May', Blue=>'Sue',
	);
	$name = &ask("Choose a name which rhymes with $colour :", $names{$colour});
	warn "string=$string, name=$name\n";
	my $passwd = ask_password("Enter some password:");
	warn "that password was ".length($passwd)." chars long\n";
	my $f = ask_filename("filename ?\n\ntry out the tab-filename-completion");
	warn "that filename was $f\n";
}

sub test_edit {
	$text = &edit('Your limerick', <<EOT);
 There was a brave soul called $name,
 Whose favourite colour was $colour;
   But some $paint
   ...
 And that was the end of $name.
EOT
}

sub test_view {
	&view('Your limerick:', $text||'try testing "ask" and "edit" first :-)');
}

sub test_select_file {
	my @bool_opts = ('-Chdir','-Create','-ShowAll','-DisableShowAll',
		'-SelDir','-TextFile','-Readable','-Writeable','-Executable','-Owned',
		'-Directory');
	my @text_opts = ('-FPat','-File','-Path','-Title','-TopDir');
	my $multiple = &choose('Select','Single file','Multiple files');
	if ($multiple eq 'Multiple files') { shift @bool_opts; shift @bool_opts; }
	my %opts;
	foreach (@bool_opts) {
		$opts{$_} = &choose("option $_ ?",'default','0','1');
		return unless defined $opts{$_};
		if ($opts{$_} eq 'default') { delete $opts{$_}; }
	}
	foreach (@text_opts) {
		$opts{$_} = &ask("option $_ ?", $opts{$_});
		if (! $opts{$_}) { delete $opts{$_}; }
	}
	if ($multiple eq 'Multiple files') {
		my @files = &select_file(-Chdir=>0, %opts);
		print STDERR "You selected @files\n";
	} else {
		print STDERR "You selected " .&select_file(%opts), "\n";
	}
}
