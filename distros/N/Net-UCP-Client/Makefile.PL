use lib 'inc';
use ExtUtils::AutoInstall(
                          -core  => [ 'Carp'         => '0.00',
                                      'IO::Socket'   => '0.00',
                                      'IO::Select'   => '0.00',
                                      'Time::HiRes'  => '0.00']
                          );
WriteMakefile(
              NAME              => 'Net::UCP::Client',
              VERSION_FROM      => 'lib/Net/UCP/Client.pm',
              PREREQ_PM          => {
		  Net::UCP => 0.39
                },
              ($] >= 5.00 ?
               (ABSTRACT_FROM  => 'lib/Net/UCP/Client.pm',
                AUTHOR         => 'Marco Romano <nemux@cpan.org>') : ()),
              );
