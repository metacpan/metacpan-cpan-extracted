use strict;
use warnings;
use Test::More;
use Proc::Class;

my $bin = '/usr/bin/corelist';
plan skip_all => "this test requires $bin" unless -x $bin;

my $proc = Proc::Class->new(
    cmd => $bin,
    argv => [qw/foo/],
);
$proc->close_stdin;
like $proc->slurp_stdout, qr/\Qfoo was not in CORE (or so I think)/;
is $proc->slurp_stderr, '';

my $status = $proc->waitpid;
ok $status->is_exited;
is $status->exit_status, 0;

done_testing;

