# Check if every added/updated file is smaller than a fixed limit.

my $LIMIT = 10 * 1024 * 1024;	# 10MB

# Note that this need at least version 0.29 of SVN::Look, which
# implements method 'filesize', new with Subversion 1.7.0.

PRE_COMMIT {
    my ($svnlook) = @_;
    foreach my $file ($svnlook->added(), $svnlook->updated()) {
	next if $file =~ m:/$:; # skip directories
	my $size = $svnlook->filesize($file);
	die "Added file '$file' has $size bytes, more than our current limit of $LIMIT bytes.\n"
	    if $size > $LIMIT;
    }
};

1;
