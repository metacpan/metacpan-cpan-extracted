#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use File::Spec;

# What a perl built with PERL_IMPLICIT_SYS does to a header.
#
# Every Strawberry perl is built that way, and XSUB.h then redefines about a
# hundred CRT names as function-like macros. Two things break, and only one of
# them is fixable by #undef:
#
#   * a perl-free header that calls close(fd) stops being perl-free, and on a
#     POSIX perl configured this way it stops compiling. sa_compat.h puts the
#     names back.
#   * a STRUCT MEMBER named `close` breaks at every CALL SITE while its
#     declaration compiles cleanly. No #undef helps, because the header the
#     consumer includes is not the one that did the undef. A sibling dist in
#     this workspace shipped a table with a member called `close` and failed on
#     the Strawberry 5.42 smoker in its own selftest.
#
# This perl is almost certainly not an IMPLICIT_SYS one, so the test creates the
# condition rather than waiting for a smoker to: it leaves the names defined as
# function-like macros exactly where XSUB.h leaves them, then includes the real
# headers in Arena.xs's order and compiles.

plan skip_all => 'no compiler recorded in Config' unless $Config{cc};
plan skip_all => 'run from the dist root' unless -d 'include/sa';

my $core = File::Spec->catdir($Config{archlibexp}, 'CORE');
plan skip_all => "no perl headers at $core"
    unless -f File::Spec->catfile($core, 'perl.h');

my $dir = tempdir(CLEANUP => 1);
my $c   = File::Spec->catfile($dir, 'implicit.c');
my $o   = File::Spec->catfile($dir, 'implicit' . ($Config{obj_ext} || '.o'));

open my $fh, '>', $c or plan skip_all => "cannot write $c: $!";
print {$fh} <<'C';
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Stubs rather than the real PerlLIO_*, so this compiles on a perl with no
 * implicit-sys layer at all. The SHAPE is what matters, because the shape is
 * what fires. */
static int sa_probe_close(int fd) { return fd; }
static int sa_probe_open(const char *f, int fl) { (void)f; return fl; }
static int sa_probe_read(int fd, void *b, int n) { (void)b; (void)n; return fd; }
static int sa_probe_write(int fd, const void *b, int n) { (void)b; (void)n; return fd; }
#undef close
#undef open
#undef read
#undef write
#define close(fd)        sa_probe_close(fd)
#define open(f, fl)      sa_probe_open((f), (fl))
#define read(fd, b, n)   sa_probe_read((fd), (b), (n))
#define write(fd, b, n)  sa_probe_write((fd), (b), (n))

C

# THE HEADER LIST COMES FROM Arena.xs, and is not repeated here.
#
# It used to be a copy, and a copy went stale the first time a tenant was added:
# sa_abi_impl.h grew calls into sa_bloom.h, this file did not include it, and
# the test failed with twenty undeclared-function errors that had nothing to do
# with implicit-sys. A test that has to be edited every time the dist grows is a
# test that gets edited to pass.
{
    open my $xs, '<', 'Arena.xs' or plan skip_all => 'cannot read Arena.xs';
    while (my $line = <$xs>) {
        print {$fh} $line if $line =~ m{^\s*\#include\s+"(?:sa/|sa_abi)};
    }
}

print {$fh} <<'C';

/* Call every member of the table through a pointer, which is where a member
 * whose name is a macro actually breaks. The declarations above compile either
 * way, which is exactly why this has to be a call and not just an include. */
int main(void) {
    const sa_abi *A = &SA_ABI;
    sa_config cfg;
    sa_counts n;
    A->config_init(&cfg);
    (void)A->errstr(0);
    (void)A->region_bytes(NULL);
    (void)A->is_creator(NULL);
    (void)A->locate(NULL, "x", 1, NULL);
    (void)A->at(NULL, 0);
    (void)A->max_record(NULL);
    (void)A->ring_slots(NULL);
    (void)A->ring_position(NULL);
    A->counts(NULL, &n);
    (void)A->destroy_named("x", 1);
    return A->abi_version == SA_ABI_VERSION ? 0 : 1;
}
C
close $fh;

my $cmd = join ' ', $Config{cc}, $Config{ccflags} || (), '-c',
          '-I.', '-Iinclude', "-I\"$core\"", '-o', "\"$o\"", "\"$c\"";
my $log = `$cmd 2>&1`;
my $rc  = $?;

ok($rc == 0, 'the headers and the ABI table compile with the CRT names live '
           . 'as function-like macros')
    or diag("a member or a call site collides with a name XSUB.h redefines\n"
          . "under PERL_IMPLICIT_SYS. Rename the member - or, at a call site,\n"
          . "parenthesise it as (A->close)(...) so the name is followed by ')'\n"
          . "where a function-like macro cannot fire.\n\n$cmd\n\n$log");

done_testing;
