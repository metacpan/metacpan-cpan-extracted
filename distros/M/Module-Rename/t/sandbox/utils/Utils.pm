
# Test suite utilities
######################################################################
sub cp_r {
######################################################################
    my($from, $to) = @_;

    my @files = ();

    find(sub {
        push @files, $File::Find::name if -f;
    }, $from);

    for my $file (@files) {
        my $newfile = "$to/$file";
        my $dir = dirname($newfile);
        mkd $dir unless -d $dir;
        cp $file, $newfile;
    }
}

1;
