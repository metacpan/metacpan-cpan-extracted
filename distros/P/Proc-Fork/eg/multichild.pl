use strict;
use Proc::Fork;
use IO::Pipe;

my $num_children = 5;    # How many children we'll create
my @children;            # Store connections to them
$SIG{CHLD} = 'IGNORE';   # Don't worry about reaping zombies

# Spawn off some children
for my $num ( 1 .. $num_children ) {
	# Create a pipe for parent-child communication
	my $pipe = IO::Pipe->new;

	# Child simply echoes data it receives, until EOF
	run_fork { child {
		$pipe->reader;
		my $data;
		while ( $data = <$pipe> ) {
			chomp $data;
			print STDERR "child $num: [$data]\n";
		}
		exit;
	} };

	# Parent here
	$pipe->writer;
	push @children, $pipe;
}

# Send some data to the kids
for ( 1 .. 20 ) {
	# pick a child at random
	my $num = int rand $num_children;
	my $child = $children[$num];
	print $child "Hey there.\n";
}
