use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Net::LDAP::Express',
    'VERSION_FROM'	=> 'Express.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    'Net::LDAP'         => '0.23',
			    'Test::More'        => 0,
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Express.pm', # retrieve abstract from module
       AUTHOR     => 'Marco Marongiu <bronto@cpan.org>') : ()),
);
