package Sky;

use strict;
use warnings;
use Pry;

sub main {
	my $x = 42;
	my @y = 666;
	
	print "Just about to start prying. Try doing something like \$x++.\n";
	
	pry;
	
	print "\$x = $x\n";
	print "\@y = (@y)\n";
}

main();
