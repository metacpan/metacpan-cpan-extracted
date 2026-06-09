#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../blib/lib", "$Bin/../blib/arch";

BEGIN { use_ok('Strada') }

my $lib_path = "$Bin/../example/math_lib.so";
unless (-f $lib_path) {
    plan skip_all =>
        "example/math_lib.so not built " .
        "(cd example && ../../../strada --shared math_lib.strada)";
}

my $lib = Strada::Library->new($lib_path);

# A Strada `throw` should surface as a catchable Perl die, not abort the process.
subtest 'function throw is catchable' => sub {
    my $ok = eval { $lib->call('math_lib::boom', 'kaboom!'); 1 };
    ok(!$ok, 'eval traps the exception (returns false)');
    like($@, qr/kaboom!/, '$@ carries the thrown message');
};

# The runtime must recover cleanly — the try-stack/cleanup-stack stay balanced,
# so subsequent calls work.
subtest 'recovery after a function throw' => sub {
    eval { $lib->call('math_lib::boom', 'x') };
    is($lib->call('math_lib::add', 2, 3), 5, 'normal call works after a throw');
    eval { $lib->call('math_lib::boom', 'y') };
    eval { $lib->call('math_lib::boom', 'z') };
    is($lib->call('math_lib::greet', 'A'), 'Hello, A!', 'still fine after several throws');
};

# A throw from inside a method call must bridge too.
subtest 'method throw is catchable + object stays usable' => sub {
    my $c = $lib->new_object('Counter', 'count', 5);
    my $ok = eval { $c->checked_add(-1); 1 };
    ok(!$ok, 'method throw is trapped');
    like($@, qr/negative/, '$@ carries the method exception');
    is($c->checked_add(10), 15, 'the object is still usable after the throw');
};

# Throwing a blessed object yields a Strada::Object in $@.
subtest 'thrown object becomes a Strada::Object' => sub {
    my $ok = eval { $lib->call('math_lib::boom_obj'); 1 };
    ok(!$ok, 'object throw is trapped');
    my $e = $@;
    isa_ok($e, 'Strada::Object', 'exception is a wrapped object');
    is($e->strada_class, 'Counter', 'exception object class');
    is($e->count, 99, 'exception object attribute is readable');
};

# Non-throwing calls are unaffected by the try-frame.
subtest 'no-throw calls still return normally' => sub {
    is($lib->call('math_lib::multiply', 6, 7), 42, 'plain call returns');
    my $c = $lib->new_object('Counter', 'count', 1);
    is($c->add(2), 3, 'plain method returns');
};

$lib->unload();
done_testing();
