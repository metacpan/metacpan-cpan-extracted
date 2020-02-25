# Inspired by Test::More::UTF8
use Test::Arrow; # Turn on utf8 pragma.

my $arr = Test::Arrow->new;

$arr->ok(utf8::is_utf8("а"));

my $sym = "\x{410}";

my @warns;

local $SIG{__WARN__} = sub { push @warns, shift; };

{
    Test::Arrow->builder->failure_output->print("# $sym\n");
    $arr->ok(!@warns, 'failure_output') or $arr->diag('Have warning: ' . shift @warns);

    Test::Arrow->builder->todo_output->print("# $sym\n");
    $arr->ok(!@warns, 'todo_output') or $arr->diag('Have warning: ' . shift @warns);

    Test::Arrow->builder->output->print("# $sym\n");
    $arr->ok(!@warns, 'output') or $arr->diag('Have warning: ' . shift @warns);
}

$arr->done_testing;
