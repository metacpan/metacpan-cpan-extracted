# Inspired by Test::More::UTF8
use Test::Arrow 'binary'; # Turn off utf8 pragma.

my $arr = Test::Arrow->new;

$arr->ok(!utf8::is_utf8("а"));

my $sym = "\x{430}";

$arr->warnings_ok(sub {
    Test::Arrow->builder->failure_output->print("# $sym\n");
}, 'failure_output is not utf8');

$arr->warnings_ok(sub {
    Test::Arrow->builder->todo_output->print("# $sym\n");
}, 'todo_output is not utf8');

$arr->warnings_ok(sub {
    Test::Arrow->builder->output->print("# $sym\n");
}, 'output is not utf8');

$arr->done_testing;
