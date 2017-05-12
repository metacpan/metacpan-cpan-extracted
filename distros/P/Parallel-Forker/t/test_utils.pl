# DESCRIPTION: Perl ExtUtils: Common routines required by package tests
#
# Copyright 2003-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.
######################################################################

use IO::File;
use vars qw($PERL $GCC);

$PERL = "$^X -Iblib/arch -Iblib/lib";

mkdir 'test_dir',0777;

if (!$ENV{HARNESS_ACTIVE}) {
    use lib "blib/lib";
    use lib "blib/arch";
    use lib "..";
    use lib "../..";
}

sub run_system {
    # Run a system command, check errors
    my $command = shift;
    print "\t$command\n";
    system "$command";
    my $status = $?;
    ($status == 0) or die "%Error: Command Failed $command, $status, stopped";
}

sub wholefile {
    my $file = shift;
    my $fh = IO::File->new ($file) or die "%Error: $! $file";
    my $wholefile = join('',$fh->getlines());
    $fh->close();
    return $wholefile;
}

sub get_memory_usage {
    # Return memory usage.  Return 0 if the system doesn't look quite right.
    my $fh = IO::File->new("</proc/self/statm");
    return 0 if !$fh;

    my $stat = $fh->getline || "";
    my @stats = split /\s+/, $stat;
    return ($stats[0]||0)*4096;  # vmsize
}

1;
