use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Petal::Mail',
    'VERSION_FROM'	=> 'lib/Petal/Mail.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Petal'             => '1.06',
        'MKDoc::XML'        => '0.61',
        'Encode'            => '1.75',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Petal/Mail.pm', # retrieve abstract from module
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
