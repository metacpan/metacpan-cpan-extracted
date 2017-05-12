while (<STDIN>) {
    chomp;
    if (/^C=+\s*([\w\.]*)/) {
	$file = lc($1);
	$file =~ s/\.for$/.f/;
	close FILE if $open;
	if ($file ne '') {
	    open FILE, ">$file";
	    print "FILE: '$file'\n";
	    $open = 1;
	}
    } else {
	print FILE "$_\n" if $open;
#	print "$_\n" if $open;
    }
}
