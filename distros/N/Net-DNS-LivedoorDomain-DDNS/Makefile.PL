use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::DNS::LivedoorDomain::DDNS',
    VERSION_FROM      => 'lib/Net/DNS/LivedoorDomain/DDNS.pm', # finds $VERSION
    PREREQ_PM         => {
                          Test::More => 0.62,
                          Test::MockObject => 1.06,
                      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/DNS/LivedoorDomain/DDNS.pm', # retrieve abstract from module
       AUTHOR         => 'Masahito Yoshida <masahito@cpan.org>') : ()),
);
