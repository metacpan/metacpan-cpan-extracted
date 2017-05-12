use strict;
use warnings;
use Test::More;
use Proc::Class;

my $bin = '/bin/ls';
plan skip_all => "this test requires $bin" unless -x $bin;

my $proc = Proc::Class->new(
    cmd => $bin,
    argv => [],
);
like $proc->slurp_stdout, qr/Changes/;
is $proc->slurp_stderr, '';

my $status = $proc->waitpid;
ok $status->is_exited;
is $status->exit_status, 0;

done_testing;

