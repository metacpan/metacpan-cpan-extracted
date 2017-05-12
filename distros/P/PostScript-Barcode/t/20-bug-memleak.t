#!perl -T
use strict;
use warnings FATAL => 'all';

use File::Temp qw();
use GTop qw();
use IO::File qw();
use PostScript::Barcode::azteccode qw();
use Test::More tests => 1;

# let's be extra careful to not affect the testing system too badly
OOMADJUST: {
    my $oom_adjust_file = "/proc/$$/oom_adj";    # current process
    if (-e $oom_adjust_file) {
        my $f = IO::File->new($oom_adjust_file, 'w');
        unless ($f) {
            warn "could not open $oom_adjust_file for writing: $!\n";
            last OOMADJUST;
        }
        $f->print(15); # magical number for "please kill me first"
        $f->close;
    }
}

my $gtop   = GTop->new;
my $before = $gtop->proc_mem($$)->size;

{
    my $temp = File::Temp->new;
    for (1 .. 50) {
        my $code = PostScript::Barcode::azteccode->new(
            data => '1' x $_, bounding_box => [[0, 0], [400, 400]],
        );
        $code->render(-sOutputFile => $temp->filename);
    }
}

my $after = $gtop->proc_mem($$)->size;
ok 1 > log($after / $before) / log(2), 'did not leak';

# on my system:
# 0.06 = no leak
# 2.38 = with leak
