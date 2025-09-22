#our $VERSION = 0.042_000;  # DEV NOTE: comment to avoid potential conflict w/ Dist::Zilla & friends

package MY;
BEGIN { use English; }

sub pm_to_blib {
    my $self = shift;
    my $blib = $self->SUPER::pm_to_blib(@_);

    # un-read-only blib/lib for tests to pass, files are modified at runtime there
    if ( $OSNAME eq 'MSWin32' ) {
        my ( $lastline, $start ) = qq{\t\$(NOECHO) \$(TOUCH) pm_to_blib\n};
        ( $start = index( $blib, $lastline ) ) == -1
            && die "Can't find replacement string for pm_to_blib target";
        substr( $blib, $start, 0, "\t" . 'attrib -R /S  blib/lib/*' . "\n" );
    }
    return $blib;
}

# disable PERL_DL_NONLAZY=1 to avoid C++ compile errors for GMP library (and possibly others)
sub test_via_harness {
    my $self = shift;
    my $command = $self->MM::test_via_harness(@_);
    $command =~ s/\bPERL_DL_NONLAZY=1\s+//gxms;
    return $command;
}

sub test_via_script {
    my $self = shift;
    my $command = $self->MM::test_via_script(@_);
    $command =~ s/\bPERL_DL_NONLAZY=1\s+//gxms;
    return $command;
}
