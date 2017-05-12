# $Id: Makefile.PL,v 1.4 2012/04/28 18:07:15 dk Exp $
use ExtUtils::MakeMaker;
eval "use POE::Test::Loops;";
goto NO_POE if $@;

unless (-t STDIN) {
	warn "STDIN is not a terminal. Assuming --default.\n";
	push @ARGV, "--default";
}

# Should we skip the network tests?
my $prompt = <<PROMPT;
Some of POE::Loop::Prima's tests require a functional network. 
You can skip these network tests if you'd like. 
Would you like to skip the network tests?
PROMPT
chomp $prompt;

my $ret = "n";
if (grep /^--default$/, @ARGV) {
	print $prompt, " [$ret] $ret\n\n";
}
else {
	$ret = prompt($prompt, "n");
}

my $marker = 'run_network_tests';
unlink $marker;
unless ($ret =~ /^Y$/i) {
	open(TOUCH,"+>$marker") and close TOUCH;
}

POE::Test::Loops::generate( 't', [ 'POE::Loop::Prima' ], 0 );

NO_POE:

WriteMakefile(
	NAME           => 'POE::Loop::Prima',
	AUTHOR         => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	ABSTRACT_FROM  => 'lib/POE/Loop/Prima.pm',
	VERSION_FROM   => 'lib/POE/Loop/Prima.pm',
	PREREQ_PM      => { POE => 0, Prima => 0 },
	# Add support for POE::Test::Loops
	test           => { TESTS => 't/*.t t/poe_loop_prima/*.t' },
	clean          => { FILES => 't/poe_loop_prima/*.t t/poe_loop_prima ' . $marker },
	META_MERGE     => {
		build_requires => { 'POE::Test::Loops' => '1.034' },
		resources => {
			repository => 'http://github.com/dk/POE-Loop-Prima'
		},
	},
);
