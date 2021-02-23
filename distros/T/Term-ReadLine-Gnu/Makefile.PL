#
#	Makefile.PL for Term::ReadLine::Gnu
#
#	Copyright (c) 1996-2021 Hiroo Hayashi.  All rights reserved.
#		<hiroo.hayashi@computer.org>
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.
#
#	OS/2 support was contributed by Ilya Zakharevich.
#		<ilya@math.ohio-state.edu>
#
# Usage: perl Makefile.PL [--prefix=...] [--includedir=...] [--libdir=...]
#		[OPTIMIZE=...]
#
#	Read INSTALL for more details.
########################################################################
use strict;
use ExtUtils::MakeMaker;
use Config;
use Getopt::Long;
use 5.008; use 5.8.1;
my ($defs, $libs, $lddflags, $RLLIB, $RLINC, @LIBPTH);

# exit 0 before creating the Makefile to be CPAN Testers friendly
# see http://wiki.cpantester.org/wiki/CPANAuthorNotes
my $err = $ENV{AUTOMATED_TESTING} ? 0 : 1;
# test /dev/tty for CPAN Testers
if ($ENV{AUTOMATED_TESTING} && !open(SESAMI, '/dev/tty')) {
    warn "cannot open /dev/tty\n";
    exit 0;
}
# test $TERM for CPAN Testers
# https://rt.cpan.org/Ticket/Display.html?id=128806
if ($ENV{AUTOMATED_TESTING} 
    && (!exists($ENV{TERM}) || !defined($ENV{TERM}) || $ENV{TERM} =~ /^(dumb|emacs|unknown|)$/)) {
    warn "wrong \$TERM value: $ENV{TERM}\n";
    exit 0;
}

$defs = ($Config{strings} =~ m|/string.h$|) ? '-DHAVE_STRING_H' : '';

# pacify warnings for -D_FORTIFY_SOURCE which perl 5.20.0 started using
if ($Config{ccflags} =~ /-D_FORTIFY_SOURCE=/) {
    $defs .= ' -O';
}

# Parse command line to specify paths for the GNU Readline Library
{
    my ($prefix, $libdir, $incdir);
    GetOptions("prefix=s" => \$prefix,
	       "libdir=s" => \$libdir,
	       "includedir=s" => \$incdir);
    if (defined $libdir) {
        foreach (split(':', $libdir)) {
            $RLLIB .= " -L$_";
            push (@LIBPTH, $_);
        }
    }
    if (defined $incdir) {
        foreach (split(':', $incdir)) {
            $RLINC .= " -I$_";
        }
    }
    if (defined $prefix) {
        foreach (split(':', $prefix)) {
            $RLLIB .= " -L$_/lib";
            push (@LIBPTH, "$_/lib");
            $RLINC .= " -I$_/include";
        }
    }
}

if ($Config{osname} eq 'os2') {
    # Check ftp://ftp.math.ohio-state.edu/pub/users/ilya/os2/
    $libs = '-lreadline_import';
    $defs .= ' -DOS2_USEDLL';
    $lddflags = '';
} else {
    # if user hasn't provided RLLIB or RLINC....
    # OS X uses libedit, but they've named it libreadline...
    # see if user has installed gnu readline via homebrew
    if ($Config{osname} eq 'darwin' && !($RLLIB || $RLINC)) {
        foreach ('readline', 'ncurses') {
            my $homebrew_prefix = `brew --prefix $_`;
            chomp $homebrew_prefix;
            if ($homebrew_prefix
                && ((substr($Config{osvers}, 0, index($Config{osvers}, '.')) > 19) || -d $homebrew_prefix)) {
                $RLLIB .= " -L$homebrew_prefix/lib";
                push (@LIBPTH, "$homebrew_prefix/lib");
                $RLINC .= " -I$homebrew_prefix/include";
            }
        }
    }

    # Search libtermcap, libtinfo, libncurses, or libcurses in this order.
    # I emulate the behavior of the configure script for bash, and don't
    # know why AIX prefers curses.
    # libtermcap.a on HPUX cannot be used for dynamically linked binary.
    # Old Cygwin may require setting false (0).
    # tinfo is for Debian. [Debian Bug Report #644423]
    my $PREFER_CURSES = $Config{osname} eq 'aix' || $Config{osname} eq 'hpux'
			|| $Config{osname} eq 'cygwin';
    my $TERMCAP_LIB = (! $PREFER_CURSES && &search_lib('-ltermcap'))
	|| &search_lib('-ltinfo')
	|| &search_lib('-lncurses')
	|| &search_lib('-lcurses');

    unless ($TERMCAP_LIB) {
        warn "Could not find neither libtermcap, libtinfo, libncurses, or libcurses.\n";
        if ($Config{osname} eq 'darwin'
            && substr($Config{osvers}, 0, index($Config{osvers}, '.')) > 19
            && $ExtUtils::MakeMaker::VERSION < 7.58) {
            warn "Install XCode or use Homebrew package.\n";
            warn "macOS Big Sur or later requires ExtUtils::MakeMaker 7.58 or later.\n";
            warn "See https://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker/issues/381 for details.\n";
        } else {
            exit $err;
        }
    } 
 
    $libs = "-lreadline $TERMCAP_LIB";
    # Latest Perl in FreeBSD does not need this hack. (Dec.2002)
    $libs .= ' -lcrypt' if ($Config{osname} =~ /freebsd/i);
    $lddflags = '';
    # If you are using old Cygwin, enable the following line.
    #$lddflags = ($Config{osname} =~ /cygwin/i) ? '-static' : '';
}

# Check version of GNU Readline Library (for version 4.2 and before)
{
    my ($rlmajorver, $rlminorver) =
	check_readline_version($RLINC, $RLLIB, $defs, $lddflags, $libs);

    if ($rlmajorver < 4 || $rlmajorver == 4 && $rlminorver <= 2) {
	$defs .= " -DRL_READLINE_VERSION=" .
	    sprintf("0x%02x%02x", $rlmajorver, $rlminorver);
	$defs .= " -DRL_VERSION_MAJOR=$rlmajorver";
	$defs .= " -DRL_VERSION_MINOR=$rlminorver";
    }
    # to show GNU Readline Library version in CPAN Tester Reports
    $defs .= " -DTRG_READLINE_VERSION=" .
	sprintf("0x%02x%02x", $rlmajorver, $rlminorver);
}

# Check whether xmalloc has been renamed to _rl_malloc (Gentoo Linux)
if (my $extra_defs = guess_malloc_names($RLINC, $RLLIB, $defs, $lddflags, $libs)) {
    $defs .= " $extra_defs";
}

# generate a Makefile
WriteMakefile
    (
     ABSTRACT_FROM => 'Gnu.pm',
     AUTHOR	  => 'Hiroo HAYASHI <hiroo.hayashi@computer.org>',
     NAME	  => 'Term::ReadLine::Gnu',
     LICENSE	  => 'perl',
     EXE_FILES	  => [ 'eg/perlsh' ],
     META_MERGE	  => {
	 resources => {
	     license => 'http://dev.perl.org/licenses/',
	     homepage => 'https://github.com/hirooih/perl-trg',
	     bugtracker => 'https://github.com/hirooih/perl-trg/issues',
	     repository => 'https://github.com/hirooih/perl-trg.git',
	 },
     },
     VERSION_FROM => 'Gnu.pm',
     MIN_PERL_VERSION => '5.8.1',
     LIBS	  => [ "$RLLIB $libs" ],
     LDDLFLAGS	  => "$RLLIB $Config{lddlflags}",
     dynamic_lib  => { OTHERLDFLAGS => $lddflags },
     DEFINE	  => $defs,
     ($Config{osname} eq 'os2' ?
      (
       IMPORTS	  => { xfree => 'emxlibcm.401' }, # Yuck!
      ) : () ),
     INC	  => $RLINC,
     dist	  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
     clean	  => { FILES => "rlver.c rlver$Config{_exe} rlmalloc.c rlmalloc$Config{_exe} .history_test" },
);

if ($Config{usesfio} eq 'true') {
    warn <<'EOM';

******************** !!!Warning!!! *********************
** Your Perl is configured as `usesfio' equals true.  **
** Term::ReadLine::Gnu may not work with your Perl.   **
** If it works, let me know your result of `perl -V'. **
********************************************************
EOM
}

exit(0);

########################################################################
# Search a library '$lib' in $Config{libpth} directories, and return
# $lib if exist or undef unless exist.

# ExtUtils::Liblist::ext() is not verbose by default any more and does much better job.
sub search_lib {
    my ($lib) = @_;
    my ($EXTRALIBS, $BSLOADLIBS, $LDLOADLIBS, $LD_RUN_PATH) = ExtUtils::Liblist->ext($lib);
    return $EXTRALIBS || $LDLOADLIBS || search_lib_sub($lib);
}

# ExtUtils::Liblist::ext() do similar job as this subroutine, but it
# warns unnecessary messages. -> TRG-1.38: Now it is used to search termcap library.
sub search_lib_sub {
    my ($lib) = @_;
    unless ($lib =~ /^-l/) {
	warn "search_lib: illegal arguments, \`$lib\'.\n";
	return undef;
    }
    my $libbase = 'lib' . substr($lib, 2) . $Config{lib_ext};
    my $libbase_so = 'lib' . substr($lib, 2) . "." . $Config{so};
    foreach (@LIBPTH) {
	if (-f $_ . '/' . $libbase) {
	    return $lib;
	} elsif (-f $_ . '/' . $libbase_so) {
	    return $lib;
	}
    }
    return undef;
}

########################################################################
# Check libreadline.a version
#
# Readline 4.2a introduced the macro
#	RL_READLINE_VERSION
#	RL_VERSION_MAJOR
#	RL_VERSION_MINOR
# Someday we don't need this subroutine..
sub check_readline_version {
    my ($RLINC, $RLLIB, $defs, $lddflags, $libs) = @_;
    my $frlver = 'rlver.c';

    # make temp file
    open(F, ">$frlver") || die "Cannot open $frlver:$!\n";
    print F <<'EOF';
/* used by Makefile.pl to check the version of the GNU Readline Library */
#include <stdio.h>
#include <readline/readline.h>
int main() { puts(rl_library_version); return 0; }
EOF
    close(F);

    # compile it
    my $comp_cmd = "$Config{cc} $RLINC $Config{ccflags} $defs $frlver -o rlver $RLLIB $lddflags $Config{ldflags} $libs";
    print $comp_cmd, "\n";
    system($comp_cmd);
    if ($?) {
	warn <<EOM;
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Could not compile $frlver.

system(): $!

If you have installed the GNU Readline Library (libreadline.{a,so} and
readline/readline.h, etc.) on directories for which your perl is not
configured to search (refer the value of `ccflags' and `libpath' in
the output of `perl -V'), specify the paths as follows;

	perl Makefile.PL --includedir=/yourdir/include --libdir=/yourdir/lib
or
	perl Makefile.PL --prefix=/yourdir

Note that the GNU Readline Library version 2.0 and earlier causes error
here.  Update it to version 2.1 and/or later.

Read INSTALL for more details.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOM
    exit $err;
    }

    # execute it and get version
    my $rlver;
    chomp($rlver = `./rlver`);
    # MacOS X 10.4 has libedit by default.
    if ($rlver =~ /EditLine/) {
	warn <<EOM;
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
The libreadline you are using is the libedit library.  Use the GNU Readline Library.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOM
	exit $err;
    }
    print "<<<It seems that you have the GNU Readline Library version $rlver.>>>\n";
    # $rlver may be '8.21-beta3', '4.2a', or etc.
    return $rlver =~ /(\d+)\.(\d+)/;
}

########################################################################
# Check whether the xmalloc exported by readline is indeed called
# 'xmalloc' or whether it has been renamed to '_rl_malloc'.
# Contributed by KENTNL at cpan.org

# Gentoo Linux requires this hack, because it renames xmalloc,
# xrealloc, and xfree. It is not a good idea.  Yes, I agree with Chet.
# https://rt.cpan.org/Ticket/Display.html?id=65973

sub guess_malloc_names {
    my ($RLINC, $RLLIB, $defs, $lddflags, $libs) = @_;
    my $frlmalloc = 'rlmalloc.c';

    my @symbol_sets = (
	{
	    # try defaults first
	    # xmalloc  => 'xmalloc',
	    # xrealloc => 'xrealloc',
	    # xfree    => 'xfree',
	},
	{
	    xmalloc  => '_rl_malloc',
	    xrealloc => '_rl_realloc',
	    xfree    => '_rl_free',
	},
    );

    # make temp file
    open(my $F, ">", $frlmalloc) || die "Cannot open $frlmalloc: $!\n";
    print {$F} <<'EOF';
/* used by Makefile.pl to check the names of xmalloc etc. of the GNU Readline Library */
#include <stdio.h>
#include <readline/readline.h>

/* we assume support for ANSI C */
extern void *xmalloc(int);
extern void *xrealloc(void *, int);
extern void xfree(void *);

int main() {
    char *p;
    p = xmalloc(1);
    p[0] = 'o';
    p = xrealloc(p, 3);
    p[1] = 'k';
    p[2] = '\0';
    puts(p);
    xfree(p);
    return 0;
}
EOF
    close($F);

    my $extra_defs;
    for my $symbol_set (@symbol_sets) {
	my $xdef = join " ", map "-D$_=$symbol_set->{$_}", sort keys %$symbol_set;
	# compile it
	my $comp_cmd = "$Config{cc} $RLINC $Config{ccflags} $defs $xdef $frlmalloc -o rlmalloc $RLLIB $lddflags $Config{ldflags} $libs";
	print $comp_cmd, "\n";
	unless (system($comp_cmd) || `./rlmalloc` !~ /^ok$/ || $?) {
	    $extra_defs = $xdef;
	    last;
	}
    }

    unless (defined $extra_defs) {
	warn <<EOM;
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
I was unable to find a working xmalloc in your readline library.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOM
	exit $err;
    }

    return $extra_defs;
}
# End of Makefile.PL
