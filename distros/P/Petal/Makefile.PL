use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Petal',
    'VERSION_FROM'	=> 'lib/Petal.pm', # finds $VERSION
    LICENSE             => 'perl',
    'PREREQ_PM'		=> {
	'Test::Harness'	    => '2.00',
	'Scalar::Util'      => '1.07',
	'MKDoc::XML'        => '0.72',
        'Digest::MD5'       => '0',
        'Locale::Maketext::Gettext' => '0',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Petal.pm', # retrieve abstract from module
       AUTHOR     => 'Jean-Michel Hiver') : ()),
);


1;


package MY;


sub postamble {
    return <<EOF;
cover ::
	\$(RM_RF) cover_db
	PERL5OPT=-MDevel::Cover \$(MAKE) test || true
	cover -report html cover_db > /dev/null

EOF

}


1;
