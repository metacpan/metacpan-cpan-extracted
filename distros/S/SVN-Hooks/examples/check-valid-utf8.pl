# Check if every changed text file contains valid UTF-8 data.

PRE_COMMIT {
    my ($svnlook) = @_;
    foreach my $file ($svnlook->added(), $svnlook->updated()) {
	next if $file =~ m:/$:; # skip directories
	my $props = $svnlook->proplist($file);
	next unless exists $props->{'svn:mime-type'}; # skip files without a mime-type
	next unless $props->{'svn:mime-type'} =~ m:^text/:; # skip non-text files

	# Try to decode file contents as UTF-8 and dies if not
	require Encode;
	eval {Encode::decode_utf8($svnlook->cat($file), Encode::FB_CROAK)};
	die "New file '$file' does not contain valid UTF-8 data: $@\n" if $@;
    }
};

1;
