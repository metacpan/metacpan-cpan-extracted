# This -*- perl -*- script writes the Makefile for RDBAL::Schema and RDBAL::Utility
# $Id: Makefile.PL,v 1.0 1998/3/13 22:30:00 aas Exp $
use ExtUtils::MakeMaker;
require 5.004;

#--- Configuration section ---

#--- End Configuration - You should not have to change anything below this line

die qq{

Your perl is too old for this version of RDBAL::Schema.

Please upgrade your perl.

} if $] < 5.004;
$Verbose = 1;

WriteMakefile(
	      'NAME'		=> 'RDBAL',
	      'DISTNAME'	=> 'RDBAL',
	      'VERSION_FROM'	=> 'RDBAL/Schema.pm',
	      'clean'       => { FILES => 'Schema.html RDBAL.html' },
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
    $_ . 
    "\n\t$pod2html_exe --infile=RDBAL/Schema.pm --outfile=Schema.html --index\n\t$pod2html_exe --infile=RDBAL.pm --outfile=RDBAL.html --index\n\trm -f pod2html-*cache\n";
}

sub MY::postamble {
' 
schema_cache :: 
	@$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) \
		cache/make_cache_dir.pl
'
}
