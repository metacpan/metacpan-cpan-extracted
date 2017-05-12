use ExtUtils::MakeMaker;
require 5.8.8;

# inet_pton is in Socket since 5.12
my %prereq;
use Socket;
$prereq{Socket6} = 0 if ! eval { 
    Socket->import('inet_pton');
    # make sure it is usable too
    Socket::inet_pton('127.0.0.1',AF_INET);
    1;
};

WriteMakefile(
	NAME => 'Net::PcapWriter',
	VERSION_FROM => 'lib/Net/PcapWriter.pm',
	PREREQ_PM => \%prereq,
	LICENSE => 'perl',
	META_MERGE => {
		resources => {
			repository => 'https://github.com/noxxi/p5-net-pcapwriter',
		},
	},
	MIN_PERL_VERSION => '5.8.8',
	TEST_REQUIRES => {'Test::Kwalitee' => 0,},
);
