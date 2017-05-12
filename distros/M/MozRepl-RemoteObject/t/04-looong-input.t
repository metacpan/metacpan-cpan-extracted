#!perl -w
use strict;
use Test::More;
use MozRepl::RemoteObject;

my $repl;
my $ok = eval {
    $repl = MozRepl::RemoteObject->install_bridge(
        #log => ['debug'] 
    );
    1;
};
if (! $ok) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
} else {
    plan tests => 2;
};

my $input_mode = $repl->expr(sprintf <<'JS', $repl->name);
    %s.getenv('inputMode');
JS
isn't $input_mode, undef, "We have an input mode";

# Test that long inputs get executed atomically
my $body = join ";\n", ('var l = "Long cat is loooong"') x 10000;

my $result = $repl->expr(<<JS);
    (function () { $body; return 1; })();
JS
is $result, 1, "Long function bodies work";
