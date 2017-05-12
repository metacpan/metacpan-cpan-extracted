package POD2::IT;

use 5.005;
use strict;
use vars qw($VERSION);
$VERSION = '0.13';

use base qw(Exporter);
our @EXPORT = qw(print_pod print_pods search_perlfunc_re new pod_dirs);

my $pods = {
	perl => '5.8.8',
	perlbook => '5.8.8',
	perlboot => '5.8.8',
	perlbot => '5.8.8',
	perlcheat => '5.8.8',
	perldata => '5.8.8',
	perlembed => '5.8.8',
	perlfaq => '5.8.8',
	perlfaq1 => '5.8.8',
	perlfaq2 => '5.8.8',
	perlfaq3 => '5.8.8',
	perlfaq4 => '5.8.8',
	perlfaq5 => '5.8.8',
	perlfaq6 => '5.8.8',
	perlfaq7 => '5.8.8',
	perlfaq8 => '5.8.8',
	perlfaq9 => '5.8.8',
	perlfork => '5.8.8',
	perlfunc => '5.8.8',
	perlintro => '5.8.8',
	perlipc => '5.8.8',
	perllol => '5.8.8',
	perlmod => '5.8.8',
	perlmodinstall => '5.8.8',
	perlmodstyle => '5.8.8',
	perlnewmod => '5.8.8',
	perlopentut => '5.8.8',
	perlpacktut => '5.8.8',
	perlref => '5.8.8',
	perlreftut => '5.8.8',
	perlrequick => '5.8.8',
	perlreref => '5.8.8',
	perlstyle => '5.8.8',
	perlsub => '5.8.8',
	perlsyn => '5.8.8',
	perlthrtut => '5.8.8',
	perltoot => '5.8.8',
	perlunicode => '5.8.8',
	perluniintro => '5.8.8',
	perlvar => '5.8.8',
	perlxstut => '5.8.8',
};

sub new {
	return __PACKAGE__;
}

sub pod_dirs {
	( my $mod = __PACKAGE__ . '.pm' ) =~ s|::|/|g;
	( my $dir = $INC{$mod} ) =~ s/\.pm\z//;
	return $dir;
}

sub print_pods {
	print_pod(sort keys %$pods);
}

sub print_pod {
	my @args = @_ ? @_ : @ARGV;

	while (@args) {
		(my $pod = lc(shift @args)) =~ s/\.pod$//;
		if ( exists $pods->{$pod} ) {
			print "\t'$pod' translated from Perl $pods->{$pod}\n";
		}
		else {
			print "\t'$pod' doesn't yet exists\n";
		}
	}
}

sub search_perlfunc_re {
	return 'Elenco delle funzioni Perl in ordine alfabetico';
}

1;
__END__

=head1 NAME

POD2::IT - Italian translation of Perl core documentation

=head1 SYNOPSIS

  %> perldoc POD2::IT::<podname>  

  use POD2::IT;
  print_pods();
  print_pod('pod_foo', 'pod_baz', ...); 

  %> perl -MPOD2::IT -e print_pods
  %> perl -MPOD2::IT -e print_pod <podname1> <podname2> ...

=head1 DESCRIPTION

pod2it is the italian translation project of core Perl pods. This has been (and
currently still is) a very big work! :-) 

See http://pod2it.sf.net for more details about the project. 

Once the package has been installed, the translated documentation can be
accessed with: 

  %> perldoc POD2::IT::<podname>

=head1 EXTENDING perldoc

With the translated pods, unfortunately, the useful C<perldoc>'s C<-f> and C<-q> 
switches don't work no longer.

So, we made a simple patch to F<Pod/Perldoc.pm> 3.14 in order to allow also the
syntax: 

  %> perldoc -L IT <podname>
  %> perldoc -L IT -f <function>
  %> perldoc -L IT -q <FAQregex>

The patch adds the C<-L> switch that allows to define language code for desired
language translation. If C<POD2::E<lt>codeE<gt>> package doesn't exists, the
effect of the switch will be ignored.

If you are particularly lazy you can add a system alias like:

  perldoc-it="perldoc -L IT "

in order to avoid to write the C<-L> switch every time and to type directly:

  %> perldoc-it -f map 
 
You can apply the patch with: 

  %> patch -p0 `/path/to/perl -MPod::Perldoc -e 'print $INC{"Pod/Perldoc.pm"}'` < /path/to/Perldoc.pm-3.14-patch

The patch lives under F<./patches/Perldoc.pm-3.14-patch> shipped in this
distribution.

Note that the patch is for version 3.14 of L<Pod::Perldoc|Pod::Perldoc>
(included into Perl 5.8.7 and Perl 5.8.8). If you have a previous Perl distro
(but E<gt>= 5.8.1) and you are impatient to apply the patch, please upgrade
your L<Pod::Perldoc|Pod::Perldoc> module to 3.14! ;-) 

See C<search_perlfunc_re> API for more information.

I<Note: Perl 5.10 already contains this functionality, so you don't have to apply any patch.>

=head1 API

The package exports following functions:

=over 4

=item * C<new>

Added for compatibilty with Perl 5.10.1's C<perldoc>.
Used by L<Pod::Perldoc> in order to return translation package name.

=item * C<pod_dirs>

Added for compatibilty with Perl 5.10.1's C<perldoc>.
Used by L<Pod::Perldoc> in order to find out where to look for translated pods.

=item * C<print_pods>

Prints all translated pods and relative Perl original version.

=item * C<print_pod>

Prints relative Perl original version of all pods passed as arguments.

=item * C<search_perlfunc_re>

Since F<Pod/Perldoc.pm>'s C<search_perlfunc> method uses hard coded string
"Alphabetical Listing of Perl Functions" (as regexp) to skip introduction, in
order to make the patch to work with other languages with the option C<-L>,we
used a simple plugin-like mechanism. 

C<POD2::E<lt>codeE<gt>> language package must export C<search_perlfunc_re> that
returns a localized translation of the paragraph string above. This string will
be used to skip F<perlfunc.pod> intro. Again, if
C<POD2::E<lt>codeE<gt>-E<gt>search_perlfunc_re> fails (or doesn't exist), we'll
come back to the default behavoiur. This mechanism allows to add additional
C<POD2::*> translations without need to patch F<Pod/Perldoc.pm> every time.

=back

=head1 Come funziona il progetto

pod2it è la traduzione in italiano della documentazione in lingua inglese 
che viene distribuita assieme al Perl.

L'ultima versione delle traduzioni e` disponibile a tutti,
in lettura, su un server CVS.

=head2 Accedere al server CVS

  cvs -d:pserver:anonymous@cvs.pod2it.sourceforge.net:/cvsroot/pod2it login

  cvs -z3 -d:pserver:anonymous@cvs.pod2it.sourceforge.net:/cvsroot/pod2it co modulename

Soltanto un piccolo numero di sviluppatori
registrati ha accesso in scrittura al repository. Ciascuno di questi
sviluppatori e` il responsabile di un certo numero di pagine della
documentazione. Il responsabile di un documento ne sovraintende la
traduzione, facendo da referente per l'invio di patch, traducendo
lui stesso il testo, oppure assegnando ad un collaboratore la
traduzione dell'intero documento.

La lista dei responsabili dei moduli e` consultabile a questo URL:
L<http://pod2it.sourceforge.net/pods/responsibles.html>
	
=head1 Come collaborare

Abbiamo bisogno sia di traduttori che di revisori. 
Come revisori, potete proporre patch ad un traduzione, sottoponendole
al responsabile del documento in questione.
Come traduttori, avete due strade. Potete limitarvi a tradurre un singolo
documento, mandandolo al suo responsabile. Oppure potete diventare voi
stessi responsabili per un gruppo di documenti. Per farlo e` necessario
possedere un account Sourceforge.

La lista dei responsabili dei moduli e` consultabile a questo URL:
L<http://pod2it.sourceforge.net/pods/responsibles.html>

=head1 AUTHORS

pod2it is a larger translation project owned by larsen, dree, dada, arthas, 
dakkar, bepi, shishii, frodo72, gmax, alberto-re, kral, osfameron, oha, 
TheHobbit & others.

See L<http://pod2it.sourceforge.net> for more detalis.

POD2::IT package is currently maintained by Enrico Sorcinelli <bepi at perl.it>

=head1 SEE ALSO

L<POD2::FR>, L<POD2::LT>, L<perl>.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2004-2009 Perl.it / Perl Mongers Italia

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
