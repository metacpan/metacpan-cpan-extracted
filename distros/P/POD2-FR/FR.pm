package POD2::FR;

use 5.005;
use strict;
use vars qw($VERSION);
$VERSION = '0.03';

use base qw(Exporter);
our @EXPORT = qw(print_pod print_pods search_perlfunc_re);

my $pods = {
	    perl => '5.10.0',
	    perl5004delta => '',
	    perl5005delta => '',
	    perl5100delta => '',
	    perl561delta => '',
	    perl56delta => '',
	    perl570delta => '',
	    perl571delta => '',
	    perl572delta => '',
	    perl573delta => '',
	    perl581delta => '',
	    perl582delta => '',
	    perl583delta => '',
	    perl584delta => '',
	    perl585delta => '',
	    perl586delta => '',
	    perl587delta => '',
	    perl588delta => '',
	    perl58delta => '',
	    perl590delta => '',
	    perl591delta => '',
	    perl592delta => '',
	    perl593delta => '',
	    perl594delta => '',
	    perl595delta => '',
	    perlaix => '',
	    perlamiga => '',
	    perlapi => '',
	    perlapio => '5.00502',
	    perlapollo => '',
	    perlartistic => '5.10.0',
	    perlbeos => '',
	    perlbook => '5.10.0',
	    perlboot => '5.10.0',
	    perlbot => '5.10.0',
	    perlbs2000 => '',
	    perlcall => '',
	    perlce => '',
	    perlcheat => '5.8.8',
	    perlclib => '',
	    perlcn => '',
	    perlcommunity => '',
	    perlcompile => '',
	    perlcygwin => '',
	    perldata => '5.10.0',
	    perldbmfilter => '',
	    perldebguts => '5.6.0',
	    perldebtut => '5.10.0',
	    perldebug => '5.6.0',
	    perldelta => '',
	    perldgux => '',
	    perldiag => '5.00502',
	    perldoc => '',
	    perldos => '',
	    perldsc => '5.10.0',
	    perlebcdic => '',
	    perlembed => '5.00502',
	    perlepoc => '',
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
	    perlfilter => '',
	    perlfork => '',
	    perlform => '5.00502',
	    perlfreebsd => '',
	    perlfunc => '5.8.8',
	    perlglossary => '',
	    perlgpl => '',
	    perlguts => '',
	    perlhack => '',
	    perlhist => '5.10.0',
	    perlhpux => '',
	    perlhurd => '',
	    perlintern => '5.6.0',
	    perlintro => '5.10.0',
	    perliol => '',
	    perlipc => '5.6.0',
	    perlirix => '',
	    perljp => '',
	    perlko => '',
	    perllexwarn => '',
	    perllinux => '',
	    perllocale => '5.6.0',
	    perllol => '5.10.0',
	    perlmachten => '',
	    perlmacos => '',
	    perlmacosx => '',
	    perlmint => '',
	    perlmod => '5.00502',
	    perlmodinstall => '5.00502',
	    perlmodlib => '5.00502',
	    perlmodstyle => '',
	    perlmpeix => '',
	    perlnetware => '',
	    perlnewmod => '',
	    perlnumber => '5.10.0',
	    perlobj => '5.10.0',
	    perlop => '5.8.8',
	    perlopenbsd => '',
	    perlopentut => '5.10.0',
	    perlos2 => '',
	    perlos390 => '',
	    perlos400 => '',
	    perlothrtut => '',
	    perlpacktut => '',
	    perlplan9 => '',
	    perlpod => '5.10.0',
	    perlpodspec => '',
	    perlport => '5.00502',
	    perlpragma => '',
	    perlqnx => '',
	    perlre => '5.8.8',
	    perlreapi => '',
	    perlrebackslash => '',
	    perlrecharclass => '',
	    perlref => '5.8.8',
	    perlreftut => '5.10.0',
	    perlreguts => '',
	    perlrequick => '5.10.0',
	    perlreref => '5.8.8',
	    perlretut => '5.8.8',
	    perlriscos => '',
	    perlrun => '5.8.8',
	    perlsec => '5.10.0',
	    perlsolaris => '',
	    perlstyle => '5.10.0',
	    perlsub => '5.8.8',
	    perlsymbian => '',
	    perlsyn => '5.8.8',
	    perlthrtut => '5.8.0',
	    perltie => '5.10.0',
	    perltoc => '',
	    perltodo => '',
	    perltooc => '5.10.0',
	    perltoot => '5.10.0',
	    perltrap => '5.10.0',
	    perltru64 => '',
	    perltw => '',
	    perlunicode => '',
	    perlunifaq => '',
	    perluniintro => '5.8.8',
	    perlunitut => '',
	    perlutil => '5.8.8',
	    perluts => '',
	    perlvar => '5.8.8',
	    perlvmesa => '',
	    perlvms => '',
	    perlvos => '',
	    perlwin32 => '',
	    perlxs => '5.00502',
	    perlxstut => '5.00502',
	   };

foreach my $key (keys %$pods) {
  delete $pods->{$key} if $pods->{$key} eq '';
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
	return 'Fonctions Perl par ordre alphabétique';
}

1;
__END__

=head1 NAME

POD2::FR - French translation of Perl core documentation

=head1 SYNOPSIS

  %> perldoc POD2::FR::<podname>

  use POD2::FR;
  print_pods();
  print_pod('pod_foo', 'pod_baz', ...);

  %> perl -MPOD2::FR -e print_pods
  %> perl -MPOD2::FR -e print_pod <podname1> <podname2> ...

=head1 DESCRIPTION

pod2fr is the french translation project of core Perl pods. This has
been (and currently still is) a very big work! :-)

See http://perl.enstimac.fr for more details about the project.

Once the package has been installed, the translated documentation can
be accessed with:

  %> perldoc POD2::FR::<podname>


=head1 EXTENDING perldoc

With the translated pods, unfortunately, the useful C<perldoc>'s C<-f>
and C<-q> switches don't work no longer.

So, pod2it (italian translation project) made a simple patch to
F<Pod/Perldoc.pm> 3.14 in order to allow also the syntax:

  %> perldoc -L FR <podname>
  %> perldoc -L FR -f <function>
  %> perldoc -L FR -q <FAQregex>

The patch adds the C<-L> switch that allows to define language code
for desired language translation. If C<POD2::E<lt>codeE<gt>> package
doesn't exists, the effect of the switch will be ignored.

If you are particularly lazy you can add a system alias like:

  perldoc-fr="perldoc -L FR "

in order to avoid to write the C<-L> switch every time and to type
directly:

  %> perldoc-fr -f map

You can apply the patch with:

  %> patch -p0 `perl -MPod::Perldoc -e 'print $INC{"Pod/Perldoc.pm"}'` < /path/to/Perldoc.pm-3.14-patch

The patch lives under F<./patches/Perldoc.pm-3.14-patch> shipped in
the distribution of POD::IT package.

Note that the patch is for version 3.14 of
L<Pod::Perldoc|Pod::Perldoc> (included into Perl 5.8.7). If you have a
previous Perl distro (but E<gt>= 5.8.1) and you are impatient to apply
the patch, please upgrade your L<Pod::Perldoc|Pod::Perldoc> module to
3.14! ;-)

See C<search_perlfunc_re> API for more information.

=head1 API

The package exports following functions:

=over 4

=item * C<print_pods>

Prints all translated pods and relative Perl original version.

=item * C<print_pod>

Prints relative Perl original version of all pods passed as arguments.

=item * C<search_perlfunc_re>

Since F<Pod/Perldoc.pm>'s C<search_perlfunc> method uses hard coded
string "Alphabetical Listing of Perl Functions" (as regexp) to skip
introduction, in order to make the patch to work with other languages
with the option C<-L>, we used a simple plugin-like mechanism.

C<POD2::E<lt>codeE<gt>> language package must export
C<search_perlfunc_re> that returns a localized translation of the
paragraph string above. This string will be used to skip
F<perlfunc.pod> intro. Again, if
C<POD2::E<lt>codeE<gt>-E<gt>search_perlfunc_re> fails (or doesn't
exist), we'll come back to the default behavoiur. This mechanism
allows to add additional C<POD2::*> translations without need to patch
F<Pod/Perldoc.pm> every time.

=back

=head1 Comment fonctionne le projet de traduction

pod2fr est un projet qui est né en 1998/1999 par la volonté d'un
groupe de contributeurs du forum de discussions Perl francophone
(fr.comp.lang.perl). Il a été animé par Marc Carmier. Le site web
L<http://perl.enstimac.fr> donne l'accès à tous les documents
traduits.

À ce jour, il n'y a malheureusement plus vraiment de groupe de
traduction. Il est possible que le groupe de traducteurs/relecteurs se
réorganise et, lorsque cela arrivera, vous trouverez de plus amples
informations sur le forum ou le site cité ci-dessus.

En attendant que le projet redémarre et en se calquant sur le module
POD2::IT (merci à eux pour le travail d'intégration), nous avons créé
ce module POD2::FR afin que tout le monde puisse profiter du travail
déjà effectué. De temps à autre, de nouvelles traductions s'ajoutent
au gré des envies de chacun. Pour toute remarque ou contribution, vous
pouvez toujours me contacter : <paul.gaborit+perl AT enstimac DOT fr>.

=head1 AUTHOR

POD2::FR package is currently maintained by Paul Gaborit
<paul.gaborit+perl AT enstimac DOT fr>.

=head1 ACKNOWLEDGEMENTS

This package is based on POD2::IT package. Thank you, pod2it group.

=head1 SEE ALSO

L<perl>, L<POD2::IT>, L<POD2::LT>.

=cut
