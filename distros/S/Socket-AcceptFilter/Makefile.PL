use 5.008008;
BEGIN {
	$^O =~ /^(?:freebsd|linux)$/
		or do{ warn "NA: $^O not supported\n"; exit 0 };
}
use inc::Module::Install;

name     'Socket-AcceptFilter';
all_from 'lib/Socket/AcceptFilter.pm';
version   my $v = '0.03';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'Test::More';
build_requires 'lib::abs', '0.90';

provides 'Socket::AcceptFilter' => {
	version => $v,
	file    => 'lib/Socket/AcceptFilter.pm',
};

auto_install;

WriteAll;

