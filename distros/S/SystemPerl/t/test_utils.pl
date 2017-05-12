# DESCRIPTION: Perl ExtUtils: Common routines required by package tests
#
# Copyright 2001-2014 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use Config;
use IO::File;
use strict;
use vars qw($PERL);

$PERL = "$^X -Iblib/arch -Iblib/lib -I../Verilog/blib/lib -I../Verilog/blib/arch";

$ENV{SYSTEMPERL_WARN_PERL64} = 1;  # So we don't break 'make test' on 32 bits

mkdir 'test_dir',0777;

if (!$ENV{HARNESS_ACTIVE}) {
    use lib '.';
    use lib "blib/lib";
    use lib "blib/arch";
    use lib '..';
    use lib "../Verilog/blib/lib";
    use lib "../Verilog/blib/arch";
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

sub files_identical {
    my $fn1 = shift;	# got
    my $fn2 = shift;	# expected
    my $f1 = IO::File->new ($fn1) or die "%Error: $! $fn1,";
    my $f2 = IO::File->new ($fn2) or die "%Error: $! $fn2,";
    my @l1 = $f1->getlines();
    my @l2 = $f2->getlines();
    my $nl = $#l1;  $nl = $#l2 if ($#l2 > $nl);
    for (my $l=0; $l<=$nl; $l++) {
	$l1[$l] =~ s/\r\n/\n/g if defined $l1[$l];  # Cleanup if on Windows
	$l2[$l] =~ s/\r\n/\n/g if defined $l2[$l];
	if (($l1[$l]||"") ne ($l2[$l]||"")) {
	    warn ("%Warning: Line ".($l+1)." mismatches; $fn1 $fn2\n"
		  ."GOT: ".($l1[$l]||"*EOF*\n")
		  ."EXP: ".($l2[$l]||"*EOF*\n"));
	    if ($ENV{HARNESS_UPDATE_GOLDEN}) {  # Update golden files with current
		warn "%Warning: HARNESS_UPDATE_GOLDEN set: cp $fn1 $fn2\n";
		copy($fn1,$fn2);
	    }
	    return 0;
	}
    }
    return 1;
}

sub write_file {
    my $filename = shift;
    my $text = join('',@_);
    # Write text to specified filename
    my $fh = IO::File->new ($filename,"w") or die "%Error: $! writing $filename,";
    print $fh $text;
    $fh->close;
}

sub ncsc_ok {
    return ($Config{archname} =~ /linux/
	    && $ENV{NC_ROOT}
	    && -d "$ENV{NC_ROOT}/tools/systemc/include"
	    );
}

1;
