use lib 'lib', 't';
use warnings;
use strict;
use Test::More tests => 6;
use IO::All;

io->dir('t/output')->rmtree;

require TestB;
my $test = TestB->new;
no strict 'refs';
$test->quiet(1);
$test->extract_files(1);
ok(io('t/output/file1')->exists);
ok(io('t/output/file2')->exists);
ok(io('t/output/file3')->exists);
is(io('t/output/file1')->all, "TestA\n");
is(io('t/output/file2')->all, "TestB\n");
is(io('t/output/file3')->all, "TestB\n");
