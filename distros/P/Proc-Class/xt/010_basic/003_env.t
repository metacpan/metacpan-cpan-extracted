use strict;
use warnings;
use Test::More;
use Proc::Class;

my $bin = '/usr/bin/env';
plan skip_all => "this test requires $bin" unless -x $bin;

$ENV{FOO_SPECIFIED_ENV} = undef;;

my $proc = Proc::Class->new(
    cmd => $bin,
    argv => [],
    env => { FOO_SPECIFIED_ENV => 'BAR' },
);
like $proc->slurp_stdout, qr/FOO_SPECIFIED_ENV=BAR/, 'specified';
is $proc->slurp_stderr, '';
is $ENV{FOO_SPECIFIED_ENV}, undef, 'restored';

my $status = $proc->waitpid;
ok $status->is_exited;
is $status->exit_status, 0;

done_testing;

