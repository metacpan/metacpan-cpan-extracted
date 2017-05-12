use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Petal::Parser::HTB',
    'VERSION_FROM'	=> 'lib/Petal/Parser/HTB.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	'Petal'             => '1.10',
        'HTML::TreeBuilder' => '3.12',
        'HTML::Parser' => '3.45',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Petal/Parser/HTB.pm', # retrieve abstract from module
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
