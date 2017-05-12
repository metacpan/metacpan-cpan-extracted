#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Capture::Tiny qw(capture);
use Module::Load;
use Test::Exception;
use Test::More 0.96;

sub use_ {
    my $mod = shift;
    load $mod;
    if (@_) {
        $mod->import(@_);
    } else {
        $mod->import;
    }
}

sub no_ {
    my $mod = shift;
    $mod->unimport;
}

throws_ok { use_ "My::Target::patch::p1", -load_target=>0 } qr/before/,
    'target module must be loaded before patch module (-load_target=0)';

subtest "patch module config (left as default)" => sub {
    lives_ok { use_ "My::Target::patch::p1" } 'load ok';
    is(My::Target::foo(), "foo from p1", "sub patched");
    is(My::Target::baz(), "baz from p1", "sub added");
    is($My::Target::patch::p1::config{-v1}, 10, "default config set");
    no_ "My::Target::patch::p1";
};
is(My::Target::foo(), "original foo", "unimport works");

subtest "patch module config (set)" => sub {
    use_ "My::Target::patch::p1", -v1 => 100;
    is($My::Target::patch::p1::config{-v1}, 100, "setting works");
    no_ "My::Target::patch::p1";
};

throws_ok { use_ "My::Target::patch::p1", -v3=>1 } qr/unknown/i,
    'unknown patch module config -> dies';

dies_ok { use_ "My::Target::patch::unknownsub" }
    'unknown target sub -> dies';

subtest 'unknown module version -> unpatched' => sub {
    lives_ok { use_ "My::Target::patch::unknownver" } 'load ok';
    is(My::Target::foo(), "original foo", "sub not patched");
    no_ "My::Target::patch::unknownver";
};

subtest '-force => 1' => sub {
    my ($stdout, $stderr, @result) = capture {
        lives_ok { use_ "My::Target::patch::unknownver", -force=>1 } 'load ok';
    };
    like($stderr, qr/match/i, 'warning emitted');
    is(My::Target::foo(), "foo from unknownver", "sub patched");
    no_ "My::Target::patch::unknownver";
};

DONE_TESTING:
done_testing();
