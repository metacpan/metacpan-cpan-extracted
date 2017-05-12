print $PPERL::error ("about to process STDIO\n");
while(<STDIN>) {
	print "read: $_";
}
