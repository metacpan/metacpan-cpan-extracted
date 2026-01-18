#
# This file is part of the Strada Language (https://strada-lang.github.io/).
# Copyright (c) 2026 Michael J. Flickinger
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 2.
#

use strict;
use warnings;
use ExtUtils::MakeMaker;

# Find Strada runtime location
# Priority: 1) STRADA_ROOT env var  2) Command line arg  3) System install  4) Source tree
my $strada_root;

# Check for command line argument: perl Makefile.PL STRADA_ROOT=/path/to/strada
for my $arg (@ARGV) {
    if ($arg =~ /^STRADA_ROOT=(.+)$/) {
        $strada_root = $1;
        @ARGV = grep { $_ !~ /^STRADA_ROOT=/ } @ARGV;
        last;
    }
}

# Check environment variable
$strada_root //= $ENV{STRADA_ROOT};

# Check system installation locations
unless ($strada_root) {
    for my $prefix ('/usr/local', '/usr') {
        if (-f "$prefix/include/strada/strada_runtime.h") {
            $strada_root = "$prefix/include/strada";
            print "Found system Strada installation at $strada_root\n";
            last;
        }
    }
}

# Fall back to source tree (building from within strada repo)
$strada_root //= '../..';

# Determine runtime paths
my $runtime_inc;
my $runtime_src;

# Check if this looks like an installed location or source tree
if (-f "$strada_root/strada_runtime.h") {
    # Installed location: headers directly in strada_root
    $runtime_inc = $strada_root;
    $runtime_src = "$strada_root/strada_runtime.c";
} elsif (-f "$strada_root/runtime/strada_runtime.h") {
    # Source tree layout
    $runtime_inc = "$strada_root/runtime";
    $runtime_src = "$strada_root/runtime/strada_runtime.c";
} else {
    die <<"ERROR";
Cannot find strada_runtime.h

Searched in:
  $strada_root/strada_runtime.h
  $strada_root/runtime/strada_runtime.h

To specify Strada location, use one of:
  perl Makefile.PL STRADA_ROOT=/path/to/strada
  STRADA_ROOT=/path/to/strada perl Makefile.PL

If Strada is installed system-wide, ensure headers are in:
  /usr/local/include/strada/strada_runtime.h
ERROR
}

print "Using Strada runtime from: $runtime_inc\n";

# Check for runtime source file
unless (-f $runtime_src) {
    die "Cannot find strada_runtime.c at $runtime_src\n" .
        "The runtime source is required to build the Perl module.\n";
}

WriteMakefile(
    NAME         => 'Strada',
    VERSION_FROM => 'Strada.pm',
    ABSTRACT     => 'Call compiled Strada shared libraries from Perl',
    AUTHOR       => 'Michael J. Flickinger',
    LICENSE      => 'gpl_2',

    # Include paths
    INC          => "-I$runtime_inc",

    # Include Strada runtime in OBJECT list
    OBJECT       => '$(O_FILES) strada_runtime$(OBJ_EXT)',
    LIBS         => ['-ldl -lm'],

    # Compiler flags
    CCFLAGS      => '-fPIC',

    # Extra files to clean
    clean        => { FILES => '*.o strada_runtime.o' },

    # Minimum Perl version
    MIN_PERL_VERSION => '5.010',

    META_MERGE   => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://strada-lang.github.io/',
            repository => {
                type => 'git',
                url  => 'https://github.com/strada-lang/strada.git',
                web  => 'https://github.com/strada-lang/strada',
            },
        },
    },
);

# Custom target to build Strada runtime object
sub MY::postamble {
    return <<"MAKE";

# Build Strada runtime object
strada_runtime\$(OBJ_EXT): $runtime_src
\t\$(CC) \$(CCFLAGS) \$(OPTIMIZE) -fPIC -I$runtime_inc -c $runtime_src -o \$@

MAKE
}
