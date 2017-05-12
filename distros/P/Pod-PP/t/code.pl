#
# $Id: code.pl,v 0.1 2001/04/25 10:41:49 ram Exp $
#
#  Copyright (c) 2000-2001, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: code.pl,v $
# Revision 0.1  2001/04/25 10:41:49  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

$ENV{PATH} = "blib/script:$ENV{PATH}";

sub ok {
	my ($num, $ok) = @_;
	print "not " unless $ok;
	print "ok $num\n";
}

sub contains {
	my ($file, $pattern) = @_;
	local *FILE;
	local $_;
	open(FILE, $file) || die "can't open $file: $!\n";
	my $found = 0;
	while (<FILE>) {
		$found++ if /$pattern/;
	}
	close FILE;
	return $found;
}

1;

