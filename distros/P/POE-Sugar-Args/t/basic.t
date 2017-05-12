use Test::More qw[no_plan];
use lib qw[lib ../lib];

BEGIN {
	use_ok 'POE::Sugar::Args';
	use_ok 'POE';
}

POE::Session->create(
	inline_states => {
		_start     => \&_start,
		construct  => \&construct,
		sweeten    => \&sweeten,
		test       => \&test,
	}
);

my $NUMBER = 42;
my @ARGS   = qw[hello there];

sub _start {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	$heap->{number} = $NUMBER;
	
	$kernel->yield( construct => @ARGS );
	$kernel->yield( sweeten   => @ARGS );
}

sub construct {
	my $poe = POE::Sugar::Args->new( @_ );

	$poe->kernel->yield( test => $poe );
}

sub sweeten {
	my $poe = sweet_args;

	$poe->kernel->yield( test => $poe );
}

sub test {
	my $poe = sweet_args;
	
	my ($test) = $poe->args->[0];

	isa_ok $test, 'POE::Sugar::Args';
	isa_ok $test->session, 'POE::Session';
	isa_ok $test->kernel,  'POE::Kernel';
}

$poe_kernel->run;
