#!/usr/bin/perl
#
# Uses the script structure_layout.pl with different object files
# compiled from the example sources here.
#
# Author: Thomas Dorner
# Copyright: (C) 2007-2013 by Thomas Dorner (Artistic License)

use strict;
use warnings;

use File::Spec;

# make sure we are in the Examples directory
unless ($0 eq 'run_examples.pl')
{
    my @split_path = File::Spec->splitpath($0);
    my $path = File::Spec->catpath(@split_path[0..1]);
    chdir $path  or  die "$0: can't chdir to $path: $1\n";
}

# compile and parse example sources with different debugging formats:
my %source = (StructureLayoutTest => '.cpp');
my %output = (StructureLayoutTest =>
	      ['^sizeof\(Structure1\) == \d{1,2}$',
	       '^offsetof\(Structure1, m_04_pointer\) == \d{1,2}$',
	       '^sizeof\(l_pointer1\) == \d{1,2}$',
	       '^sizeof\(l_object1\) == \d{1,2}$',
	       '^sizeof\(l_object2a\) == \d{1,2}$',
	       '^sizeof\(l_object2b\) == \d{1,2}$',
	       '^sizeof\(l_cObject2b\) == \d{1,2}$',
	       '^sizeof\(l_object3\) == \d{1,2}$',
	       '^sizeof\(l_object4\) == \d{1,2}$',
	       '^sizeof\(l_object5\) == \d{1,2}$',
	       '^sizeof\(l_cvInt\) == \d{1,2}$',
	       '^sizeof\(l_objectU\) == \d{1,2}$',
	       '^sizeof\(l_object2_foo\) == \d{1,2}$',
	       '^sizeof\(l_object2_bar\) == \d{1,2}$']);
foreach my $base (keys %source)
{
 FORMAT:
    foreach my $format (qw(gdb stabs stabs+ coff xcoff xcoff+
			   dwarf-2 dwarf-4 vms))
    {
	foreach my $level (1..3)
	{
	    my $format_ok = 1;
	    my $object = $base.'-'.$format.'-'.$level.'.o';

	    # compile example source
	    my $command = 'g++ -Wall -Wextra -g'.$format.' -g'.$level;
	    $command .= ' -o'.$object.' -c '.$base.$source{$base};
	    open GCC, $command.' 2>&1 |'
		or  die  "$0: can't run '$command': $!\n";
	    while (<GCC>)
	    {
		if (m/ does not support .*$format.* format/)
		{
		    print 'Your system', $&, ".\n";
		    $format_ok = 0;
		}
	    }
	    close GCC  or  not $format_ok
		or  die  "$0: can't run '$command': $!";
	    next FORMAT unless $format_ok;

	    # link example source:
	    $command = 'g++ -o '.$base.' '.$object;
	    open GCC, $command.' 2>&1 |'
		or  die  "$0: can't run '$command': $!\n";
	    while (<GCC>)
	    {
		print $_;
		die 'a linker error should never happen';
	    }
	    close GCC  or  die  "$0: can't run '$command': $!";

	    # test example program:
	    $command = File::Spec->catfile('.', $base);
	    open PROG, $command.' 2>&1 |'
		or  die  "$0: can't run '$command': $!\n";
	    while (<PROG>)
	    {
 unless (defined $output{$base}->[$. - 1])
{
    die "$base,$output{$base},$.";
}
		my $match = $output{$base}->[$. - 1];
		unless (m/$match/)
		{
		    chomp;
		    print $base, ': "', $_, '" does not match /',
			$match, '/ (', $base, '-', $format, '-', $level, ")\n";
		    $format_ok = 0;
		}
	    }
	    close PROG  or  die  "$0: can't run '$command': $!";
	    next FORMAT unless $format_ok;

	    # bail out if not dwarf:
	    if ($format =~ m/^(?:stabs|x?coff|vms)/)
	    {
		print 'structure_layout.pl does not support "',
		    $format, "\" yet.\n";
		next FORMAT;
	    }

	    # test example program:
	    $command = 'perl -I'.File::Spec->catdir('..', 'lib');
	    $command .= ' '.File::Spec->catfile('structure_layout.pl');
	    $command .= ' "^S" '.$object.' >'.$object.'.layout';
	    system($command) == 0
		or  die  "$0: error running '$command': $?\n";
	    print 'Created example output "', $object, ".layout\".\n";
	}
    }
}
