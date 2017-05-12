#!./perl -w

use Symbol;
use Test;
BEGIN { plan test => 2 }

use Rc qw(walk);
use Rc::Deparse;
ok 1;

{
    my $fh=gensym;
    open $fh, ">.tmp$$" or die $!;
    Rc::set_output($fh);
    walk(join('',`cat t/trip.rc`), 'deparse');
    close $fh;
}

system "diff -u .tmp$$ t/expect.trip";
ok !$?;

END { unlink ".tmp$$" }
