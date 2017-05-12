use ExtUtils::MakeMaker;
# $Id: Makefile.PL,v 1.9 2003/06/06 18:45:02 unimlo Exp $
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::ACL',
    'VERSION_FROM'	=> 'lib/Net/ACL.pm', # finds $VERSION
    'PREREQ_PM'		=> {
				'Net::Netmask'		=> 1.9004, # 1.9003 missing 'any'
				'List::Util'		=> 1.01, # Scalar::Util - but no ver. there!
				# 'Net::BGP'		=> 0.04, # Optional!
				'IO::String'		=> '1.02',
				'Cisco::Reconfig'	=> 0.5,
				'Test::Signature'	=> '1.04',
				'Test::Harness'		=> '2.00', # ?
				'Test::More'		=> '0.47'
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Net/ACL.pm', # retrieve abstract from module
       AUTHOR     => 'Martin Lorensen <lorensen@cpan.org>') : ()),
);
