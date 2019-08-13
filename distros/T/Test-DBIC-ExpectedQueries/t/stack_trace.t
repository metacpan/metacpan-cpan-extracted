use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Warnings;

use lib "lib";
use Test::DBIC::ExpectedQueries;


my $queries = Test::DBIC::ExpectedQueries->new({
    schema => "don't hit anything that uses ->schema and we'll be fine",
});


sub Test::A::abc { Test::B::def(@_) }
sub Test::B::def { shift->_stack_trace() }

*abc = "abc";

subtest "_stack_trace string has correct shape" => sub {
    my $with_newline = "new\nline";
    my $callers = Test::A::abc($queries, $with_newline, sub { "code ref" }, [], {}, \*abc);
    like(
        $callers,
        qr|^SQL executed at t.stack_trace.t line \d+
    Test::B::def\('Test::DBIC::ExpectedQueries<HASH>', 'new\^Jline', '<CODE>', '<ARRAY>', '<HASH>', '<GLOB>'\) called at t.stack_trace.t line \d+
    Test::A::abc\('Test::DBIC::ExpectedQueries<HASH>', 'new\^Jline', '<CODE>', '<ARRAY>', '<HASH>', '<GLOB>'\) called at t.stack_trace.t line \d+
    Test::More::subtest\('_stack_trace string has correct shape', '<CODE>'\) called at t.stack_trace.t line \d+|,
        "Correct frames, and shape"
    );
};

done_testing();

