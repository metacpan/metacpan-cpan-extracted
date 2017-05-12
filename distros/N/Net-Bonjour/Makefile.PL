use ExtUtils::MakeMaker;

my $ans = prompt("Enable enterprise tests? [y/N]");

my $tests = 't/*.t';

if ( $ans =~ /^y/i ) {
        print "Enterprise tests enabled.\n";
        print "Enterprise test will query HTTP service records from zeroconf.org\n";
	$tests = 't/*.t t/*.ot';
} else {
        print "Enterprise tests will be skipped.\n";
}

WriteMakefile(
	'NAME' => 'Net::Bonjour',
	'VERSION_FROM' => 'lib/Net/Bonjour.pm',
	'DISTNAME' => 'Net-Bonjour',
	'PREREQ_PM' => { 'Net::DNS' => 0.50, 'Socket' => 1.75 },
	'AUTHOR' => 'George Chlipala <george@walnutcs.com>',
	'ABSTRACT' => "Module for DNS service discovery (Apple's Bonjour)",
	'LICENSE' => 'perl',
	'test' => { 'TESTS' => $tests }
)
