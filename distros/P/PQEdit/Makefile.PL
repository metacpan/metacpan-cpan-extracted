# This -*- perl -*- script writes the Makefile for pqedit.cgi
# $Id: Makefile.PL,v 1.0 1998/3/13 22:30:00 aas Exp $
use ExtUtils::MakeMaker;
require 5.004;

#--- Configuration section ---

#--- End Configuration - You should not have to change anything below this line

die qq{

Your perl is too old for this version of PQEdit.

Please upgrade your perl.

} if $] < 5.004;
$Verbose = 1;

# Check for non-standard modules that are used by this library.
$| = 1;
my $missing_modules = 0;

WriteMakefile(
	      'NAME'		=> 'PQEdit',
	      'DISTNAME'	=> 'PQEdit',
	      'VERSION_FROM'	=> 'pqedit.PL',
	      PL_FILES      => { 'pqedit.PL' => 'pqedit.cgi' },
	      EXE_FILES     => [ 'pqedit.cgi' ],
	      PREREQ_PM     => { 'CGI' => 2,
				 'RDBAL::Schema' => 1 },
	      'clean'       => { FILES => '$(EXE_FILES) pqedit.1 pqedit.html' },
	      'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

package MY;

sub MY::test_via_harness { "" }

sub MY::test_via_script {
	my( $self, $perl, $script ) = @_;
	my $res;

	$res = $self->MM::test_via_script( $perl, $script );
	$res =~ s/(test.pl)/$1 -p $perl/;
	$res;
}

sub manifypods
{
    my $self = shift;
    local($_) = $self->SUPER::manifypods(@_);
    my($pod2man_exe) = /POD2MAN_EXE\s*\=\s*(.*)\n/m;
    $pod2man_exe =~ s/^\s*//;
    $pod2man_exe =~ s/\s*$//;
    my($pod2html_exe) = $pod2man_exe;
    $pod2html_exe =~ s/2man/2html/;
    "manifypods : pqedit.pod \n\t$pod2man_exe --section=1 pqedit.pod > pqedit.1\n\t$pod2html_exe --infile=pqedit.pod --outfile=pqedit.html --index\n\tcp pqedit.1 blib/man1/pqedit.1\n\trm -f pod2html-*cache\n";
}
