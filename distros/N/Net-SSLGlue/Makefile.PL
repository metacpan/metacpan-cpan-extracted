use ExtUtils::MakeMaker;
require 5.008;
my $xt = prompt( "Should I do external tests?\n".
    "These tests will fail if there is no internet connection or if a firewall\n".
    "blocks some traffic.\n".
    "[y/N]", 'n' );
WriteMakefile(
    NAME => 'Net::SSLGlue',
    VERSION_FROM => 'lib/Net/SSLGlue.pm',
    PREREQ_PM => {
	'IO::Socket::SSL' => 1.19,
    },
    $xt =~m{^y}i ? ( test => { TESTS => 't/*.t t/external/*.t' }):(),
    META_MERGE => {
	resources => {
	    repository => 'https://github.com/noxxi/p5-net-sslglue',
	},
    },
);
