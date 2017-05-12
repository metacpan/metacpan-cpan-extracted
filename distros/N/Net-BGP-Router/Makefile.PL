use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::BGP::Router',
    'VERSION_FROM'	=> 'lib/Net/BGP/Router.pm', # finds $VERSION
    'ABSTRACT'		=> 'BGP Router with Contexts, RIB and Policy Tools',
    'PREREQ_PM'		=> {
				'Net::BGP'	=> '0.04',
				'List::Util'	=> '1.01', # Actully Scalar::Util!
				'Net::ACL'	=> '0.06',
				'Net::Patricia'	=> '1.010',
				'Test::Signature'	=> '1.04',
				'Module::Signature'	=> '0.22',
				'Test::Harness'	=> '2.00', # ?
				'Test::More'	=> '0.47'
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Martin Lorensen <lorensen@cpan.org>') : ()),
);
