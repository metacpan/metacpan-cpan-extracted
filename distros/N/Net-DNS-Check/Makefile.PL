use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
warn <<AMEN if $] < 5.005;

Net::DNS::Check is based on Net::DNS, so please note this:
Net::DNS has not been tested against perl v$]
The author is confident that this package will function
properly with older perls such as yours, but bugs may lurk.


AMEN
WriteMakefile(
    NAME              => 'Net::DNS::Check',
    VERSION_FROM      => 'lib/Net/DNS/Check.pm', # finds $VERSION
    PREREQ_PM         => {
		'Net::DNS'	=> 0.42,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'Perl DNS Check Module', # retrieve abstract from module
       AUTHOR         => 'Lorenzo Luconi Trombacchi <lorenzo.luconi@iit.cnr.it>') : ()),
);

