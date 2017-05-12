# The SVNBOOK's section called "The Final Word on Merge Tracking"
# (http://svnbook.red-bean.com/en/1.7/svn.branchmerge.advanced.html#svn.branchmerge.advanced.finalword)
# says that one of Subversion's best practices is to "avoid subtree
# merges and subtree mergeinfo, perform merges only on the root of
# your branches, not on subdirectories or files".

# What follows is a pre-commit hook that checks when it's commiting
# the result of a merge and that the merge root matches on of a list
# of allowed regexes.

my @allowed_merge_roots = (
    qr@^(?:trunk|branches/[^/]+)/$@, # only on trunk and on branch roots
);

# This hook loops over every path which had the svn:mergeinfo property
# changed in this commit in string order. The first such path must be
# the merge root and it must match at least one of the allowed merge
# roots or die otherwise.

PRE_COMMIT {
    my ($svnlook) = @_;

    my $headlook;		# initialized inside the loop if needed

    foreach my $path (sort $svnlook->prop_modified()) {
	next unless exists $svnlook->proplist($path)->{'svn:mergeinfo'};

	# Get a SVN::Look to the HEAD revision in order to see what
	# has changed in this commit transaction
	$headlook ||= SVN::Look->new($svnlook->repo());

	# Try to get properties for the file in HEAD
	my $head_props = eval { $headlook->proplist($path) };

	# If path didn't exist in HEAD it must be a copy and not a
	# merge root, so we skip it.
	next unless $head_props;

	# If it didn't have the svn:mergeinfo property or if the
	# property was different then, it must be the merge root.
	if (! exists $head_props->{'svn:mergeinfo'} ||
	    $head_props->{'svn:mergeinfo'} ne $svnlook->proplist($path)->{'svn:mergeinfo'}
	) {
	    # We've found a path that had the svn:mergeinfo property
	    # modified in this commit. Since we're looking at them in
	    # string order, the first one found must be the merge
	    # root. Check if it matches any of the allowed roots or
	    # die otherwise.
	    foreach my $allowed_root (@allowed_merge_roots) {
		return if $path =~ $allowed_root;
	    }
	    die "Merge not allowed on '$path'\n";
	}
    }
    return;
};

1;
