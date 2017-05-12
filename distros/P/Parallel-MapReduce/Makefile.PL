use 5.008000;
use ExtUtils::MakeMaker;

use Config;
$Config{useithreads} or die 'This Perl binary has been built without threads. But threads are needed here.';

WriteMakefile(
	      NAME              => 'Parallel::MapReduce',
	      VERSION_FROM      => 'lib/Parallel/MapReduce.pm',
	      PREREQ_PM         => {
		  'Cache::Memcached' => 1.24,
		  'IPC::Run'         => 0.80,
		  'Test::More'       => 0.72,
		  'Test::Pod'        => 1.26,
		  'Log::Log4perl'    => 1.16,
	      },
	      ABSTRACT_FROM  => 'lib/Parallel/MapReduce.pm',
	      AUTHOR         => 'Robert Barta <drrho@cpan.org>',
);


package MY;

sub depend {
    return <<MAKE

upload:
	cpan-upload-http Parallel-MapReduce-\$(VERSION).tar.gz

dependencies:
	perl support/dependencies.pl

network_test:
	export MR_ONLINE=1 ; make disttest ; export MR_ONLINE=0

MAKE
}
