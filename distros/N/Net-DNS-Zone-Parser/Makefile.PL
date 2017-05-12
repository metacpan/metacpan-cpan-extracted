use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::DNS::Zone::Parser',
    'VERSION_FROM' => 'Parser.pm', # finds $VERSION
    'AUTHOR'  => 'Olaf M. Kolkman (NLnet Labs)',
    'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    'ABSTRACT'     => 'Perl DNS Zone module',
    'PREREQ_PM'    => {
		       Net::DNS       => 0.64,
		       Net::DNS::SEC  => 0.15,
		       IO::File   =>  0.0,
		       File::Temp => 0.0,
		       File::Basename => 0.0,
			},
    'PM' => { 
	'Parser.pm'    => '$(INST_LIBDIR)/Parser.pm',
    },




);

package MY;

sub postamble {
    my $content;

    $content.='
test_cover : pure_all
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover $(MAKE) test
	cover


';
#    print "$content";
    return $content;

}


