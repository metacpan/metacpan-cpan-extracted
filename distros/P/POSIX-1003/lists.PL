#!/usr/bin/env perl
#
# This script builds .c files with constants, to be included in the XS

use Config;
use File::Spec;

use warnings;
use strict;

use blib;

sub dump_table($$$);
sub from_listing($$);

# Maybe someone uses cross-compilation
my $system = lc ($ENV{OSNAME} || $^O);

my (%sc, %cs, %posix, %pc, %ul, %rl, %poll, %sig, %fdio, %fsys, %errno, %fcntl);

from_listing \%cs,    'confstr.txt';
from_listing \%errno, 'errno.txt';
from_listing \%fcntl, 'fcntl.txt';
from_listing \%fdio,  'fdio.txt';
from_listing \%fsys,  'fsys.txt';
from_listing \%pc,    'pathconf.txt';
from_listing \%poll,  'poll.txt';
from_listing \%posix, 'posix.txt';
from_listing \%rl,    'rlimit.txt';
from_listing \%sc,    'sysconf.txt';
from_listing \%sig,   'signals.txt';
from_listing \%ul,    'ulimit.txt';

#use Data::Dumper;
#warn Dumper \%sc, \%cs, \%posix, \%pc;

dump_table(\%cs,    'cs_table',   'confstr.c'   );
dump_table(\%errno, 'errno_table','errno.c'     );
dump_table(\%fcntl, 'fcntl_table','fcntl.c'     );
dump_table(\%fdio,  'fdio_table', 'fdio.c'      );
dump_table(\%fsys,  'fsys_table', 'fsys.c'      );
dump_table(\%pc,    'pc_table',   'pathconf.c'  );
dump_table(\%poll,  'poll_table', 'poll.c'      );
dump_table(\%posix, 'pr_table',   'properties.c');
dump_table(\%rl,    'rl_table',   'rlimit.c'    );
dump_table(\%sc,    'sc_table',   'sysconf.c'   );
dump_table(\%sig,   'sig_table',  'signals.c'   );
dump_table(\%ul,    'ul_table',   'ulimit.c'    );

# System specific compilation helpers
open SYSTEM, '>', 'system.c'
    or die "cannot write to system.c: $!";

my $incl   = File::Spec->catfile('system', $system.'.c');
if(-f $incl)
{   print SYSTEM qq{#include "$incl"\n};
}

close SYSTEM
    or die "write errors to system.c: $!";

exit 0;

sub dump_table($$$)
{   my ($consts, $table, $filename) = @_;
    local *TABLE;
    open TABLE, '>', $filename
        or die "cannot write to $filename: $!\n";

    print TABLE "/* Generated */\n\n";
    foreach my $const (sort keys %$consts)
    {   my $klen = length $const;
        print TABLE <<_CONST
#ifdef $const
(void)hv_store($table, "$const", $klen, newSViv($const), 0);
#endif
_CONST
    }

    close TABLE;
}

sub from_listing($$)
{   my ($table, $filename) = @_;
    my $path =  File::Spec->catfile('lists', $filename);
    local *IN;
    open IN, '<', $path
        or die "cannot read from $path: $!";
    while(<IN>)
    {   next if m/^#|^\s*$/;
        chomp;
        $table->{$_}++;
    }
    close IN
        or die "errors while reading $path: $!";
}
