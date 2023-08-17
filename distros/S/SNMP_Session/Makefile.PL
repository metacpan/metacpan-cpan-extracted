use strict;
use warnings;

use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval($ExtUtils::MakeMaker::VERSION);

WriteMakefile(
    'ABSTRACT_FROM' => 'lib/SNMP_Session.pm',
    'AUTHOR' => [
	'Simon Leinen <simon.leinen@gmail.com>',
	'Mike Mitchell',
    ],
    'LICENSE' => 'artistic_2',
    'NAME' => 'SNMP_Session',
    'PREREQ_PM' => {
	'Carp' => 0,
	'Exporter' => 0,
	'IO::Socket' => 0,
	'IO::Socket::INET6' => 0,
	'Net::SNMP' => 0,
	'Socket' => 0,
	'Socket6' => 0,
	'strict' => 0,
	'vars' => 0,
    },
    'VERSION_FROM' => 'lib/SNMP_Session.pm', # finds $VERSION
    'dist' => {
	COMPRESS=>'gzip -9f',
	SUFFIX => 'gz',
    },
    'test' => {
        TESTS => 't/*.t'
    },
    ($EUMM_VERSION >= 6.46 ? (
	META_MERGE => {
	    test_requires => {
		'Test::More' => 0,
	    },
	    resources => {
		repository => 'https://github.com/sleinen/snmp-session',
		bugtracker => 'https://github.com/sleinen/snmp-session/issues',
	    },
	}
    ) : ()),
    ($EUMM_VERSION >= 6.48 ? (MIN_PERL_VERSION => '5.6.0') : ()),
    ($EUMM_VERSION >= 6.64 ? (
	'TEST_REQUIRES' => {
	    'Test::More' => 0,
	},
    ) : ()),
);
