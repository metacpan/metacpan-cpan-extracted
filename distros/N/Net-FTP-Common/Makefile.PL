use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::FTP::Common',
    'VERSION_FROM'	=> 'lib/Net/FTP/Common.pm', # finds $VERSION
    'PREREQ_PM'		=> 
    { 
	Net::FTP => 1 ,
      Test::More => 0,
    }, 
);

sub MY::postamble { q{

docs : README

README: lib/Net/FTP/Common.pm
	pod2text lib/Net/FTP/Common.pm > README
	}
		}

print(<<'EOF');
			   Important Notes!
			   ---------------
Net::FTP::Common is built on top of, and requires, Net::FTP.

Net::FTP is available from the libnet distribution on CPAN.

Please visit http://kobsearch.cpan.org or http://search.cpan.org
to obtain libnet and install that before installing Net::FTP::Common.

The libnet@lists.perl.org mailing list deals with Net::FTP and
the people there are relatively helpful. Another source is
comp.lang.perl.modules. A final source is www.perlmonks.org. 
An even more final source is me, but I am not a Net::FTP expert, 
so don't expect miracles.

But of course for any issues with Net::FTP::Common, contact me
immediately please - tbone@cpan.org or through the mailing list:
net-ftp-common@yahoogroups.com.

Note: 'make test' will only work if you have correctly installed Net::FTP 
to connect to FTP sites on the open internet.

The test suite makes FTP connects to ftp.fcc.fov and fedworld.gov so if 
your installation of Net::FTP cannot connect there, then this suite will
fail.

Common reasons for Net::FTP being unable to make such FTP connections are

    * if you are firewalled and have not configured Net::FTP to negotiate your
      type of firewall (it handles everyone I have ever encounted quite well).

    * if you aren't currently connected to the internet.


Installation
------------
1- make
2- make test
3- make install

Mailing List
------------
Post message:net-ftp-common@yahoogroups.com
Subscribe: net-ftp-common-subscribe@yahoogroups.com
Unsubscribe: net-ftp-common-unsubscribe@yahoogroups.com
List owner (moi): net-ftp-common-owner@yahoogroups.com    
EOF

