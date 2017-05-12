# Some very simple utility elements that are shared amongst the various test
# suites.

sub read_file
{
    my $file = shift;

    open my $fh, '<', $file or die "Error opening $file: $!";
    my $content = do { local $/ = undef; <$fh> };
    die "Error closing $file: $!" if (! close $fh);

    return $content;
}

1;
