# Check if every added/changed Perl file respects Perl::Critic's code
# standards.

PRE_COMMIT {
    my ($svnlook) = @_;
    my %violations;
    my $critic;

    foreach my $file ($svnlook->added(), $svnlook->updated()) {
	next unless $file =~ /\.p[lm]$/i;
	require Perl::Critic;
	$critic ||= Perl::Critic->new(-severity => 'stern', -top => 10);
	my $contents = $svnlook->cat($file);
	my @violations = $critic->critique(\$contents);
	$violations{$file} = \@violations if @violations;
    }

    if (%violations) {
	# FIXME: this is a lame way to format the output.
	require Data::Dumper;
	die "Perl::Critic Violations:\n", Data::Dumper::Dumper(\%violations), "\n";
    }
};

1;
