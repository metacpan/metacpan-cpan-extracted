use 5.005000;
use ExtUtils::MakeMaker;
use strict;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @deps;
unless (eval "use IO::Socket::SSL 0.98; 1") {
	my $choose = prompt(
		"For https proxy strict checking you need IO::Socket::SSL 0.98+\n".
		"Would you like to use https strict checking?",
		"y"
	);
	
	if ($choose =~ /y/) {
		push @deps, 'IO::Socket::SSL', '0.98';
	}
}


WriteMakefile(
    NAME              => 'Net::Proxy::Type',
    LICENSE           => 'perl',
    VERSION_FROM      => 'lib/Net/Proxy/Type.pm', # finds $VERSION
    PREREQ_PM         => { Exporter  => 0, 'IO::Socket::INET' => 0, 'IO::Select' => 0, @deps }, # e.g., Module::Name => 1.1
    META_MERGE        => { resources => {repository => 'https://github.com/olegwtf/p5-Net-Proxy-Type'} },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Proxy/Type.pm', # retrieve abstract from module
       AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
