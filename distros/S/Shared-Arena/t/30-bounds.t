#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use File::Temp ();
use File::Spec;
use Shared::Arena ();

# A REGISTRY ENTRY IS SOMEBODY ELSE'S NUMBER.
#
# Every tenant used to bind by taking the entry's `off`, checking only that it
# was inside the mapping, and then checking its own size against the entry's
# `len` - which comes OUT OF THE SHARED SEGMENT. Anybody who could write to the
# segment chose that number.
#
# Measured before the fix, with the same attacker this test compiles: a process
# that knew only the arena's name rewrote one entry to `off = total - 64,
# len = 1GB`, and the next process to bind that ring wrote about twenty-one
# kilobytes past the end of its own mapping. SIGSEGV.
#
# The POD promised at the time that "a reader will not follow a length past the
# end of a mapping". It does not any more, and this is why that sentence is
# worth having: a promise nobody checks is a comment.
#
# THE ATTACKER IS A REAL PROCESS, compiled here, not a Perl poke into the
# header. Perl cannot reach the registry - `poke` is bounded to a carved region
# - and a test that could not actually corrupt the entry would pass against the
# broken code as happily as the fixed code.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();
plan skip_all => 'named regions are POSIX shm here' if $^O eq 'MSWin32';
plan skip_all => 'no compiler recorded in Config' unless $Config{cc};
plan skip_all => 'run from the dist root' unless -d 'include/sa';

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $src = File::Spec->catfile($dir, 'hostile.c');
my $exe = File::Spec->catfile($dir, 'hostile');

open my $fh, '>', $src or plan skip_all => "cannot write $src: $!";
print {$fh} <<'C';
/* A hostile local process. It knows the name and nothing else. */
#include "sa/sa_format.h"
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, char **argv) {
    int fd;
    struct stat st;
    void *base;
    sa_header *h;
    sa_reg *regs;
    if (argc < 2) return 2;
    fd = shm_open(argv[1], O_RDWR, 0600);
    if (fd < 0) return 3;
    if (fstat(fd, &st)) return 4;
    base = mmap(NULL, (size_t)st.st_size, PROT_READ | PROT_WRITE,
                MAP_SHARED, fd, 0);
    close(fd);
    if (base == MAP_FAILED) return 5;
    h = (sa_header *)base;
    if (h->magic != SA_MAGIC || !h->reg_used) return 6;
    regs = (sa_reg *)((char *)base + h->reg_off);
    /* Just inside the end of the mapping, and claiming to be enormous. */
    regs[0].off = h->total - 64;
    regs[0].len = (uint64_t)1 << 30;
    printf("%s %llu\n", regs[0].name, (unsigned long long)h->total);
    return 0;
}
C
close $fh;

my $cc = "$Config{cc} $Config{ccflags} -Iinclude -o $exe $src 2>/dev/null";
system($cc) == 0 or plan skip_all => 'cannot build the attacker here';
plan skip_all => 'attacker did not build' unless -x $exe;

my $NAME = "sa-bounds-$$";
Shared::Arena->destroy($NAME);

# ---- the victim sets up, exactly as any program would ----------------------

{
    my $a = Shared::Arena->create(name => $NAME, size => 256 * 1024);
    ok($a, 'created a named arena');
    my $r = $a->ring('events', slots => 64, slot_size => 256);
    ok($r, 'carved a ring in it');
    $r->publish('t', 'hello');
    is($a->refused, 0, 'nothing refused yet');
}

# ---- the attacker rewrites one registry entry ------------------------------

my $out = `$exe /$NAME`;
my $rc  = $? >> 8;
is($rc, 0, 'the attacker opened the segment and rewrote an entry')
    or diag "attacker exit $rc";
like($out, qr/^events \d+/, '...the entry it rewrote was the ring');

# ---- and the victim must not follow it -------------------------------------
#
# In a child, because the whole point is that this used to be a SIGSEGV: a
# crash here would take the test file with it and report as a missing plan
# rather than as the failure it is.

{
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        my $a = Shared::Arena->attach($NAME) or exit 20;
        # Binding the tenant whose entry was rewritten. This is the call that
        # used to memset past the end of the mapping.
        my $r = eval { $a->ring('events', slots => 64, slot_size => 256) };
        exit 21 unless $r;
        # And it must have REFUSED the hostile entry rather than followed it.
        exit 22 unless $a->refused > 0;
        # The arena still works: a bad entry is skipped, not fatal.
        exit 23 unless $r->publish('t', 'still here') > 0;
        exit 0;
    }
    waitpid($pid, 0);
    my $status = $?;

    is($status & 127, 0,
       'the victim did NOT crash following a hostile registry entry')
        or diag sprintf('killed by signal %d', $status & 127);

    my $code = $status >> 8;
    isnt($code, 20, 'the victim attached');
    isnt($code, 21, 'and still got a usable ring');
    isnt($code, 22, 'and counted the entry it refused');
    isnt($code, 23, 'and the arena still works afterwards');
    is($code, 0, 'every bound check held');
}

Shared::Arena->destroy($NAME);

done_testing;
