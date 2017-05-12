#!perl

use 5.010;
use strict;
use warnings;

use Proc::Find qw(find_proc find_all_proc find_any_proc proc_exists);
use Test::More 0.98;

my $table = [
  {
    cmajflt  => 1280,
    cminflt  => 1605106,
    cmndline => "init [2]  ",
    cstime   => 4170000,
    ctime    => 22030000,
    cutime   => 17860000,
    cwd      => undef,
    egid     => 0,
    euid     => 0,
    exec     => undef,
    fgid     => 0,
    flags    => 4202752,
    fname    => "init",
    fuid     => 0,
    gid      => 0,
    majflt   => 17,
    minflt   => 1310,
    pctcpu   => "  0.00",
    pctmem   => "0.00",
    pgrp     => 1,
    pid      => 1,
    ppid     => 0,
    priority => 20,
    rss      => 884736,
    sess     => 1,
    sgid     => 0,
    size     => 10903552,
    start    => 1416672533,
    state    => "sleep",
    stime    => 1340000,
    suid     => 0,
    time     => 1430000,
    ttydev   => "",
    ttynum   => 0,
    uid      => 0,
    utime    => 90000,
    wchan    => -1,
  },
  {
    cmajflt  => 0,
    cminflt  => 0,
    cmndline => "emacsclient -t t/01-basics.t",
    cstime   => 0,
    ctime    => 0,
    cutime   => 0,
    cwd      => "/mnt/home/s1/repos/perl-Proc-Find",
    egid     => 1000,
    euid     => 1000,
    exec     => "/usr/bin/emacsclient.emacs23",
    fgid     => 1000,
    flags    => 4202496,
    fname    => "emacsclient",
    fuid     => 1000,
    gid      => 1000,
    majflt   => 0,
    minflt   => 235,
    pctcpu   => "  0.00",
    pctmem   => "0.00",
    pgrp     => 12816,
    pid      => 12816,
    ppid     => 11531,
    priority => 20,
    rss      => 622592,
    sess     => 11531,
    sgid     => 1000,
    size     => 4210688,
    start    => 1416721805,
    state    => "sleep",
    stime    => 0,
    suid     => 1000,
    time     => 0,
    ttydev   => "/dev/pts/6",
    ttynum   => 34822,
    uid      => 1000,
    utime    => 0,
    wchan    => 0,
  },
  {
    cmajflt  => 0,
    cminflt  => 18639,
    cmndline => "/bin/bash",
    cstime   => 20000,
    ctime    => 60000,
    cutime   => 40000,
    cwd      => "/mnt/home/s1/repos/perl-Proc-Find",
    egid     => 1000,
    euid     => 1000,
    exec     => "/bin/bash",
    fgid     => 1000,
    flags    => 4202496,
    fname    => "bash",
    fuid     => 1000,
    gid      => 1000,
    majflt   => 0,
    minflt   => 3728,
    pctcpu   => "  0.60",
    pctmem   => 0.02,
    pgrp     => 12817,
    pid      => 12817,
    ppid     => 5462,
    priority => 20,
    rss      => 7159808,
    sess     => 12817,
    sgid     => 1000,
    size     => 28164096,
    start    => 1416721807,
    state    => "sleep",
    stime    => 10000,
    suid     => 1000,
    time     => 30000,
    ttydev   => "/dev/pts/9",
    ttynum   => 34825,
    uid      => 1000,
    utime    => 20000,
    wchan    => 0,
  },
  {
    cmajflt  => 0,
    cminflt  => 0,
    cmndline => "perl /home/s1/bin/public/dump-proc-processtable",
    cstime   => 0,
    ctime    => 0,
    cutime   => 0,
    cwd      => "/mnt/home/s1/repos/perl-Proc-Find",
    egid     => 1000,
    euid     => 1000,
    exec     => "/mnt/home/s1/perl5/perlbrew/perls/perl-5.18.2/bin/perl",
    fgid     => 1000,
    flags    => 4202496,
    fname    => "perl",
    fuid     => 1000,
    gid      => 1000,
    majflt   => 0,
    minflt   => 1875,
    pctcpu   => "  3.00",
    pctmem   => 0.02,
    pgrp     => 12871,
    pid      => 12871,
    ppid     => 12817,
    priority => 20,
    rss      => 6303744,
    sess     => 12817,
    sgid     => 1000,
    size     => 36716544,
    start    => 1416721811,
    state    => "run",
    stime    => 10000,
    suid     => 1000,
    time     => 30000,
    ttydev   => "/dev/pts/9",
    ttynum   => 34825,
    uid      => 1000,
    utime    => 20000,
    wchan    => 0,
  },
];

subtest find_proc => sub {
    # detail
    ok(!ref(find_proc(table=>$table)->[0]), "detail=0");
    is( ref(find_proc(table=>$table, detail=>1)->[0]), "HASH", "detail=1");

    # pid
    is(~~@{ find_proc(table=>$table, pid=>12816) }, 1);
    is(~~@{ find_proc(table=>$table, pid=>99999) }, 0);

    # name
    is(~~@{ find_proc(table=>$table, name=>"emacsclient") }, 1);
    is(~~@{ find_proc(table=>$table, name=>qr/emacs/) }, 1);
    is(~~@{ find_proc(table=>$table, name=>"foo") }, 0);

    # cmdline
    is(~~@{ find_proc(table=>$table, cmndline=>"emacsclient -t t/01-basics.t") }, 1);
    is(~~@{ find_proc(table=>$table, cmndline=>qr/emacs/) }, 1);
    is(~~@{ find_proc(table=>$table, cmndline=>"foo") }, 0);

    # exec
    is(~~@{ find_proc(table=>$table, exec=>"bash") }, 1);
    is(~~@{ find_proc(table=>$table, exec=>"/bin/bash") }, 1);
    is(~~@{ find_proc(table=>$table, exec=>"foo") }, 0);
    is(~~@{ find_proc(table=>$table, exec=>"/sbin/bash") }, 0);

    # user
    is(~~@{ find_proc(table=>$table, user=>1000) }, 3);
    is(~~@{ find_proc(table=>$table, user=>9999) }, 0);

    # uid
    is(~~@{ find_proc(table=>$table, uid=>1000) }, 3);
    is(~~@{ find_proc(table=>$table, uid=>9999) }, 0);

    # euser
    is(~~@{ find_proc(table=>$table, euser=>1000) }, 3);
    is(~~@{ find_proc(table=>$table, euser=>9999) }, 0);

    # euid
    is(~~@{ find_proc(table=>$table, euid=>1000) }, 3);
    is(~~@{ find_proc(table=>$table, euid=>9999) }, 0);
};

subtest proc_exists => sub {
    ok( proc_exists(table=>$table, user=>1000));
    ok(!proc_exists(table=>$table, user=>1));
};

subtest find_all_proc => sub {
    is(~~@{ find_all_proc({table=>$table, euid=>1000}, {exec=>"bash"}) }, 1);
    is(~~@{ find_all_proc({table=>$table, euid=>0}, {exec=>"bash"}) }, 0);
};

subtest find_any_proc => sub {
    is(~~@{ find_any_proc({table=>$table, euid=>0}, {exec=>"bash"}) }, 2);
};

DONE_TESTING:
done_testing;


# XXX test with real call to table()
# XXX test user=username
# XXX test euser=username
