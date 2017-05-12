package PPI::Xref::Help;

sub short_help {
    my ($name, $fh) = @_;
    while (<$fh>) {
        last if /^=head2 Usage/;
    }
    while (<$fh>) {
        last if /^=head2/;
        print;
    }
    exit(1);
}

sub long_help {
    my ($name, $fh) = @_;
    print <$fh>;
    exit(1);
}

sub man_help {
    my ($name, $fh) = @_;
    my $man_pipe = "| pod2man --name '$name' | nroff -man";
    my $pager = $ENV{PAGER};
    unless (defined $pager) {
        $pager = "less";  # Might be assuming too much.
    }
    if ($pager =~ /less/) {
        my $less_opts = $ENV{LESS} // "";
        if ($less_opts !~ /-R/) {
            $less_opts .= " -R"
        }
        $pager .= " $less_opts";
    }
    if (defined $pager) {
        $man_pipe .= " | $pager";
    }
    if (open(my $man_fh, $man_pipe)) {
        print { $man_fh } <$fh>;
        close($man_fh);
    }
    exit(1);
}

1;
