# Inspired by Test::More::UTF8
use strict;
use warnings;

use Test::Arrow 'binary'; # Turn off utf8 pragma.

my $arr = Test::Arrow->new;

$arr->ok(!utf8::is_utf8("а"));

my $sym = "\x{430}";

my @warns;

local $SIG{__WARN__} = sub { push @warns, shift; };

{
    @warns = ();
    Test::Arrow->builder->failure_output->print("# $sym\n");
    $arr->ok(scalar @warns == 1, 'failure_output is not utf8')
            or $arr->diag('Have warning: ' . shift @warns);
}

{
    @warns = ();
    Test::Arrow->builder->todo_output->print("# $sym\n");
    $arr->ok(scalar @warns == 1, 'todo_output is not utf8')
            or $arr->diag('Have warning: ' . shift @warns);
}

{
    @warns = ();
    Test::Arrow->builder->output->print("# $sym\n");
    $arr->ok(scalar @warns == 1, 'output is not utf8')
            or $arr->diag('Have warning: ' . shift @warns);
}

$arr->done_testing;
