#
#       Makefile.PL for Term::ReadLine::Gnu
#
#       Copyright (c) 1996-2023 Hiroo Hayashi.  All rights reserved.
#               <hiroo.hayashi@computer.org>
#
#       This program is free software; you can redistribute it and/or
#       modify it under the same terms as Perl itself.
#
#       OS/2 support was contributed by Ilya Zakharevich.
#               <ilya@math.ohio-state.edu>
#
# Usage: perl Makefile.PL [--prefix=...] [--includedir=...] [--libdir=...]
#       [OPTIMIZE=...] [verbose]
#
#       Read INSTALL for more details.
########################################################################
use strict;
use ExtUtils::MakeMaker;
use Config;
use Getopt::Long;
use 5.008; use 5.8.1;
my (@defs, @libs, @lddflags, @RLLIB, @RLINC, @LIBPTH, $verbose, $err);

# exit 0 before creating the Makefile to be CPAN Testers friendly
# see http://wiki.cpantester.org/wiki/CPANAuthorNotes
$err = $ENV{AUTOMATED_TESTING} ? 0 : 1;
# test /dev/tty for CPAN Testers
if ($ENV{AUTOMATED_TESTING} && !open(SESAMI, '/dev/tty')) {
    warn "cannot open /dev/tty\n";
    exit 0;
}

push(@defs, '-DHAVE_STRING_H') if ($Config{strings} =~ m|/string.h$|);

# pacify warnings for -D_FORTIFY_SOURCE which perl 5.20.0 started using
push(@defs, '-O') if ($Config{ccflags} =~ /-D_FORTIFY_SOURCE=/);

# Parse command line to specify paths for the GNU Readline Library
{
    my ($prefix, $libdir, $incdir);
    GetOptions("prefix=s" => \$prefix,
               "libdir=s" => \$libdir,
               "includedir=s" => \$incdir);
    if (defined $libdir) {
        foreach (split(':', $libdir)) {
            push(@RLLIB, "-L$_");
            push(@LIBPTH, $_);
        }
    }
    if (defined $incdir) {
        foreach (split(':', $incdir)) {
            push(@RLINC, "-I$_");
        }
    }
    if (defined $prefix) {
        foreach (split(':', $prefix)) {
            push(@RLLIB, "-L$_/lib");
            push(@LIBPTH, "$_/lib");
            push(@RLINC, "-I$_/include");
        }
    }
    foreach (@ARGV) {
        if ($_ eq 'verbose') {
            $verbose = 1;
            last;
        }
    }
}

# if user hasn't provided RLLIB or RLINC....
# OS X uses libedit, but they've named it libreadline...
# see if user has installed gnu readline via homebrew
if ($Config{osname} eq 'darwin' && !(@RLLIB || @RLINC)
    && system('brew -v >/dev/null 2>&1') == 0) {
    chomp(my $homebrew_prefix = `brew --prefix --installed readline`);
    if ($homebrew_prefix
        && (substr($Config{osvers}, 0, index($Config{osvers}, '.')) > 19)) {
        push(@RLLIB, "-L$homebrew_prefix/lib");
        push(@LIBPTH,  "$homebrew_prefix/lib");
        push(@RLINC, "-I$homebrew_prefix/include");

        chomp(my @deps = split(' ', `brew deps readline`));
        if (@deps) {
            foreach (@deps) {
                chomp(my $homebrew_prefix = `brew --prefix --installed $_`);
                push(@RLLIB, "-L$homebrew_prefix/lib");
                push(@LIBPTH,  "$homebrew_prefix/lib");
                push(@RLINC, "-I$homebrew_prefix/include");
            }
        }
    }
}

if ($Config{osname} eq 'os2') {
    # Check ftp://ftp.math.ohio-state.edu/pub/users/ilya/os2/
    push(@libs, '-lreadline_import');
    push(@defs, '-DOS2_USEDLL');
} else {
    push(@libs, '-lreadline');
}

{
    my $frlver = 'rlver';
    write_rlver("$frlver.c");

    # First compile rlver.c without specifing terminal library (for some libreadline.so).
    if (compile_rlver($frlver, "@RLINC", "@RLLIB", "@defs", "@lddflags", "@libs", 1)) {
        # If failed, compile rlver.c with terminal library.
        # See https://github.com/hirooih/perl-trg/issues/6 for details
        push(@libs, search_termlib());
        if (compile_rlver($frlver, "@RLINC", "@RLLIB", "@defs", "@lddflags", "@libs", 0)) {
            warn <<EOM;
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Could not compile $frlver.c.

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
    }
}

# Check version of GNU Readline Library (for version 4.2 and before)
{
    my ($rlmajorver, $rlminorver) = check_readline_version();
    my $rlver_hex = sprintf("0x%02x%02x", $rlmajorver, $rlminorver);

    if ($rlmajorver < 4 || $rlmajorver == 4 && $rlminorver <= 2) {
        push(@defs, "-DRL_READLINE_VERSION=$rlver_hex");
        push(@defs, "-DRL_VERSION_MAJOR=$rlmajorver");
        push(@defs, "-DRL_VERSION_MINOR=$rlminorver");
    }
    # to show GNU Readline Library version in CPAN Tester Reports
    push(@defs, "-DTRG_READLINE_VERSION=$rlver_hex");
}

# Latest Perl in FreeBSD does not need this hack. (Dec.2002)
push(@libs, '-lcrypt') if ($Config{osname} =~ /freebsd/i);
# If you are using old Cygwin, enable the following line.
#push(@lddflags, '-static') if ($Config{osname} =~ /cygwin/i);

# Check whether xmalloc has been renamed to _rl_malloc (Gentoo Linux)
if (my $extra_defs = guess_malloc_names("@RLINC", "@RLLIB", "@defs", "@lddflags", "@libs")) {
    push(@defs, $extra_defs);
}

# generate a Makefile
WriteMakefile
    (
     ABSTRACT_FROM => 'Gnu.pm',
     AUTHOR       => 'Hiroo HAYASHI <hiroo.hayashi@computer.org>',
     NAME         => 'Term::ReadLine::Gnu',
     LICENSE      => 'perl',
     EXE_FILES    => [ 'eg/perlsh' ],
     META_MERGE   => {
         resources => {
             license => 'http://dev.perl.org/licenses/',
             homepage => 'https://github.com/hirooih/perl-trg',
             bugtracker => 'https://github.com/hirooih/perl-trg/issues',
             repository => 'https://github.com/hirooih/perl-trg.git',
         },
     },
     VERSION_FROM => 'Gnu.pm',
     MIN_PERL_VERSION => '5.8.1',
     LIBS         => [ "@RLLIB @libs" ],
     LDDLFLAGS    => "@RLLIB $Config{lddlflags}",
     dynamic_lib  => { OTHERLDFLAGS => "@lddflags" },
     DEFINE       => "@defs",
     ($Config{osname} eq 'os2' ?
      (
       IMPORTS    => { xfree => 'emxlibcm.401' }, # Yuck!
      ) : () ),
     INC          => "@RLINC",
     dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
     clean        => { FILES => "rlver.c rlver$Config{_exe} rlmalloc.c rlmalloc$Config{_exe} *.dSYM .history_test" },
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
sub search_termlib {
    # Search libtermcap, libtinfo, libncurses, or libcurses in this order.
    # I emulate the behavior of the configure script for bash, and don't
    # know why AIX prefers curses.
    # libtermcap.a on HPUX cannot be used for dynamically linked binary.
    # Old Cygwin may require setting false (0).
    # tinfo is for Debian. [Debian Bug Report #644423]
    #
    # Return `-lcurses` as a last resort. This is also a work-around for
    # https://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker/issues/381.
    # macOS Big Sur or later requires ExtUtils::MakeMaker 7.58 or later.
    if ($Config{osname} eq 'aix' || $Config{osname} eq 'hpux' || $Config{osname} eq 'cygwin') {
        return (search_lib('-lncurses') || search_lib('-ltermcap')
                || search_lib('-ltinfo') || '-lcurses');
    } else {
        return (search_lib('-ltermcap') || search_lib('-ltinfo')
                || search_lib('-lncurses') || '-lcurses');
    }
}

########################################################################
# Search a library '$lib' in $Config{libpth} directories, and return
# $lib if exist or undef unless exist.

# ExtUtils::Liblist::ext() is not verbose by default any more and does much better job.
sub search_lib {
    my ($lib) = @_;
    my ($EXTRALIBS, $BSLOADLIBS, $LDLOADLIBS, $LD_RUN_PATH) = ExtUtils::Liblist->ext($lib, $verbose);
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
    my $libbase    = 'lib' . substr($lib, 2) . $Config{lib_ext};
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
#       RL_READLINE_VERSION
#       RL_VERSION_MAJOR
#       RL_VERSION_MINOR
# Someday we don't need this subroutine..
sub write_rlver {
    my ($frlver) = @_;

    # make temp file
    open(F, ">$frlver") || die "Cannot open $frlver:$!\n";
    print F <<'EOF';
/* used by Makefile.pl to check the version of the GNU Readline Library */
#include <stdio.h>
#include <readline/readline.h>
extern char *tgetstr(const char *, char **);
int main(int argc, char *argv[]) {
    if (argc > 1)  // not to be optimized away
        tgetstr("", NULL);  // force to link a terminal library
    puts(rl_library_version);
    return 0;
}
EOF
    close(F);
}

sub compile_rlver {
    my ($base, $RLINC, $RLLIB, $defs, $lddflags, $libs, $quiet) = @_;

    my $comp_cmd = "$Config{cc} $RLINC $Config{ccflags} $defs $base.c -o $base $RLLIB $lddflags $Config{ldflags} $libs";
    $comp_cmd .= " >/dev/null 2>&1" if $quiet && !$verbose;
    print $comp_cmd, "\n" if $verbose;
    system($comp_cmd);
    return $?;
}

sub check_readline_version {
    # execute rlver and get version
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

    for my $symbol_set (@symbol_sets) {
        my $xdef = join " ", map "-D$_=$symbol_set->{$_}", sort keys %$symbol_set;
        # compile it
        my $comp_cmd = "$Config{cc} $RLINC $Config{ccflags} $defs $xdef $frlmalloc -o rlmalloc $RLLIB $lddflags $Config{ldflags} $libs";
        print $comp_cmd, "\n" if $verbose;
        return $xdef if (system($comp_cmd) == 0 && `./rlmalloc` =~ /^ok\s*$/); # maybe terminated by "\r\n"
    }
    warn <<EOM;
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
I was unable to find a working xmalloc in your readline library.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOM
    exit $err;
}
# End of Makefile.PL
