use strict;
use Proc::Fork;

use IO::Pipe;
my $p = IO::Pipe->new;

run_fork {
	parent {
		my $child = shift;
		$p->reader;
		print while <$p>;
		waitpid $child,0;
	}
	child {
		$p->writer;
		print $p "Line 1\n";
		print $p "Line 2\n";
		exit;
	}
	retry {
		if( $_[0] < 5 ) {
			sleep 1;
			return 1;
		}
		return 0;
	}
	error {
		die "That's all folks\n";
	}
};
