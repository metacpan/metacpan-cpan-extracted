
sub handler {
	print "Location: http://perl.apache.org/\n";
	print "Content-Type: text/plain\n\n";
	print "Check the mod_perl website, perl.apache.org.\n";
	return 302;
}

1;

