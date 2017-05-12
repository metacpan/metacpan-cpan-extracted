use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# $Id: Makefile.PL,v 1.9 2002/10/27 04:53:51 lem Exp $

WriteMakefile(
    'NAME'		=> 'Net::FTPServer::PWP',
    'VERSION_FROM'	=> 'lib/Net/FTPServer/PWP.pm',
    'PREREQ_PM'		=> {
      Net::FTPServer => 0,
      Net::Radius::Packet => 1.43,
      Net::Radius::Dictionary => 1.43,
      NetAddr::IP => 3.00,
      Time::HiRes => 0,
    }, # e.g., Module::Name => 1.1
    EXE_FILES		=> [ 'bin/pwp-ftpd.pl' ],
    INSTALLSCRIPT	=> '/usr/local/sbin',
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Net/FTPServer/PWP.pm',
       AUTHOR     => 
       'Luis E. Munoz <luismunoz@cpan.org> and '
       . 'Manuel Picone <mpicone@cantv.net>') : ()),
);

package MY;

sub postamble {
'
install ::
	@echo "**************************************************************"
	@echo
	@echo "                         IMPORTANT"
	@echo
	@echo "ftpd-changes.conf contains a list of new entries that probably"
	@echo "must be added to your /etc/ftpd.conf file."
	@echo
	@echo "pwp-dictionary must be copied to a suitable place (the default"
	@echo "is /usr/local/lib). Also, its Vendor-Specific-Attributes must"
	@echo "be added to your real RADIUS server configuration and "
	@echo "dictionary."
	@echo 
	@echo "                   PLEASE PLEASE PLEASE"
	@echo 
	@echo "Do read the following documents before attempting"
	@echo "to use this module/FTP server"
	@echo 
	@echo "perldoc Net::FTPServer"
	@echo "perldoc Net::FTPServer::Full"
	@echo "perldoc Net::FTPServer::PWP"
	@echo "perldoc Net::FTPServer::PWP::Server"
	@echo
	@echo "**************************************************************"
'
};
