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
# hundred CRT names as function-like macros. A STRUCT MEMBER with one of those
# names breaks at every CALL SITE while its declaration compiles cleanly, and
# no #undef helps, because the header the consumer includes is not the one that
# did the undef. A sibling dist shipped a table with a member called `close`
# and failed on the Strawberry 5.42 smoker in its own selftest.
#
# This perl is almost certainly not an IMPLICIT_SYS one, so the test creates
# the condition: it leaves the names defined as function-like macros exactly
# where XSUB.h leaves them, then includes the real headers in Codec.xs's order
# and calls every member through the table.

plan skip_all => 'no compiler recorded in Config' unless $Config{cc};
plan skip_all => 'run from the dist root' unless -d 'include/sc';

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

static int sc_probe_close(int fd) { return fd; }
static int sc_probe_open(const char *f, int fl) { (void)f; return fl; }
static int sc_probe_read(int fd, void *b, int n) { (void)b; (void)n; return fd; }
static int sc_probe_write(int fd, const void *b, int n) { (void)b; (void)n; return fd; }
static void *sc_probe_malloc(size_t n) { return (void *)(n ? 0 : 0); }
static void sc_probe_free(void *p) { (void)p; }
#undef close
#undef open
#undef read
#undef write
#undef malloc
#undef free
#define close(fd)        sc_probe_close(fd)
#define open(f, fl)      sc_probe_open((f), (fl))
#define read(fd, b, n)   sc_probe_read((fd), (b), (n))
#define write(fd, b, n)  sc_probe_write((fd), (b), (n))
#define malloc(n)        sc_probe_malloc(n)
#define free(p)          sc_probe_free(p)

C

# THE HEADER LIST COMES FROM Codec.xs, and is not repeated here, so a header
# added later cannot be forgotten by this file.
{
    open my $xs, '<', 'Codec.xs' or plan skip_all => 'cannot read Codec.xs';
    while (my $line = <$xs>) {
        print {$fh} $line if $line =~ m{^\s*\#include\s+"(?:sc/|sc_abi)};
    }
}

print {$fh} <<'C';

/* Call every member through a pointer, which is where a member whose name is
 * a macro actually breaks. */
int sc_probe_main(pTHX) {
    const sc_abi *A = &SC_ABI;
    STRLEN need = 0;
    char buf[8];
    (void)(A->encode)(aTHX_ &PL_sv_undef);
    (void)(A->encode_to)(aTHX_ &PL_sv_undef, buf, sizeof buf, &need);
    (void)(A->decode)(aTHX_ buf, 0);
    return A->abi_version == SC_ABI_VERSION ? 0 : 1;
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
          . "under PERL_IMPLICIT_SYS. Rename the member.\n\n$cmd\n\n$log");

done_testing;
