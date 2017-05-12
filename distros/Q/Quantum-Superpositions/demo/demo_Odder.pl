sub odder {
	grep($_%2, split "", $_[0]) > grep($_%2, split "", $_[1]);
}

use Quantum::Superpositions BINARY_LOGICAL => ['main::odder'];

print odder(any(1234,2468), 666), "\n";
