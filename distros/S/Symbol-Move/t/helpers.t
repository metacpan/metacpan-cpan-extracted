use Test::More;
use strict;
use warnings;

use Symbol::Methods;

BEGIN {
    no warnings 'once';
    *parse_symbol = Symbol::Methods->can('_parse_symbol') || die;
    *get_stash    = Symbol::Methods->can('_get_stash')    || die;
    *get_glob     = Symbol::Methods->can('_get_glob')     || die;
    *get_ref      = Symbol::Methods->can('_get_ref')      || die;
    *set_symbol   = Symbol::Methods->can('_set_symbol')   || die;
    *purge_symbol = Symbol::Methods->can('_purge_symbol') || die;
}

BEGIN {
    *subtest = sub { $_[1]->() } unless __PACKAGE__->can('subtest');
    unless (__PACKAGE__->can('done_testing')) {
        plan(tests => 38);
        *done_testing = sub { 1 };
    }
}

subtest parse_symbol => sub {
    is_deeply(
        parse_symbol('foo', 'CLASS'),
        {sym => '&CLASS::foo', name => 'foo', sigil => '&', type => 'CODE', pkg => 'CLASS'},
        "Parse simple sub"
    );

    is_deeply(
        parse_symbol('$foo', 'CLASS'),
        {sym => '$CLASS::foo', name => 'foo', sigil => '$', type => 'SCALAR', pkg => 'CLASS'},
        "Parse simple scalar"
    );

    is_deeply(
        parse_symbol('::foo', 'CLASS'),
        {sym => '&main::foo', name => 'foo', sigil => '&', type => 'CODE', pkg => 'main'},
        "Parse sub in main"
    );

    is_deeply(
        parse_symbol('$::foo', 'CLASS'),
        {sym => '$main::foo', name => 'foo', sigil => '$', type => 'SCALAR', pkg => 'main'},
        "Parse scalar in main"
    );

    is_deeply(
        parse_symbol('Foo::foo', 'CLASS'),
        {sym => '&Foo::foo', name => 'foo', sigil => '&', type => 'CODE', pkg => 'Foo'},
        "Parse sub in other package"
    );

    is_deeply(
        parse_symbol('Foo::foo', 'CLASS', '%'),
        {sym => '%Foo::foo', name => 'foo', sigil => '%', type => 'HASH', pkg => 'Foo'},
        "Parse with alternative default sigil"
    );

    is_deeply(
        parse_symbol('%Foo::foo', 'CLASS'),
        {sym => '%Foo::foo', name => 'foo', sigil => '%', type => 'HASH', pkg => 'Foo'},
        "Parse hash in other package"
    );

    my $file = __FILE__;
    my $line = __LINE__ + 1;
    ok(!eval {parse_symbol('*Foo::foo', 'CLASS')}, "bad sigil");
    like($@, qr/^Unsupported sigil '\*' at $file line $line/, "got error");
};

subtest get_stash => sub {
    my $stash = get_stash(parse_symbol('::is'));
    ok(exists $stash->{ok}, "'ok' is defined");
    ok(exists $stash->{is}, "'is' is defined");
};

subtest get_glob => sub {
    my $glob = get_glob(parse_symbol('::is'));
    is($glob, \*main::is, "got the symbols glob");
};

subtest get_ref => sub {
    ok(!get_ref(parse_symbol('$XXX', __PACKAGE__)), '$XXX does not exists');
    eval 'our $XXX = 5';
    my $ref = get_ref(parse_symbol('$XXX', __PACKAGE__));
    ok($ref, "git ref now");
    isa_ok($ref, 'SCALAR');
    is($$ref, 5, "got value");

    is(get_ref(parse_symbol('&is', __PACKAGE__)), \&is, "got sub ref");
};

subtest set_symbol => sub {
    ok(!__PACKAGE__->can('foobar'), "no foobar sub");
    set_symbol(parse_symbol('foobar', __PACKAGE__), sub { 'foo' });
    ok(__PACKAGE__->can('foobar'), "foobar sub added");
};

subtest purge_symbol => sub {
    *xyz = sub { 'xyz' };
    our $xyz = 1;
    our %xyz = (a => 1);
    our @xyz = [1, 2];

    ok(get_ref(parse_symbol('&xyz', __PACKAGE__)), "have xyz sub");
    ok(get_ref(parse_symbol('%xyz', __PACKAGE__)), "have xyz hash");
    ok(get_ref(parse_symbol('@xyz', __PACKAGE__)), "have xyz array");
    ok(get_ref(parse_symbol('$xyz', __PACKAGE__)), "have xyz scalar");

    purge_symbol(parse_symbol('&xyz', __PACKAGE__));
    ok(!get_ref(parse_symbol('&xyz', __PACKAGE__)), "have xyz sub");
    ok(get_ref(parse_symbol('%xyz', __PACKAGE__)), "have xyz hash");
    ok(get_ref(parse_symbol('@xyz', __PACKAGE__)), "have xyz array");
    ok(get_ref(parse_symbol('$xyz', __PACKAGE__)), "have xyz scalar");

    purge_symbol(parse_symbol('%xyz', __PACKAGE__));
    ok(!get_ref(parse_symbol('&xyz', __PACKAGE__)), "have xyz sub");
    ok(!get_ref(parse_symbol('%xyz', __PACKAGE__)), "have xyz hash");
    ok(get_ref(parse_symbol('@xyz', __PACKAGE__)), "have xyz array");
    ok(get_ref(parse_symbol('$xyz', __PACKAGE__)), "have xyz scalar");

    purge_symbol(parse_symbol('@xyz', __PACKAGE__));
    ok(!get_ref(parse_symbol('&xyz', __PACKAGE__)), "have xyz sub");
    ok(!get_ref(parse_symbol('%xyz', __PACKAGE__)), "have xyz hash");
    ok(!get_ref(parse_symbol('@xyz', __PACKAGE__)), "have xyz array");
    ok(get_ref(parse_symbol('$xyz', __PACKAGE__)), "have xyz scalar");

    purge_symbol(parse_symbol('$xyz', __PACKAGE__));
    ok(!get_ref(parse_symbol('&xyz', __PACKAGE__)), "have xyz sub");
    ok(!get_ref(parse_symbol('%xyz', __PACKAGE__)), "have xyz hash");
    ok(!get_ref(parse_symbol('@xyz', __PACKAGE__)), "have xyz array");
    ok(!get_ref(parse_symbol('$xyz', __PACKAGE__)), "have xyz scalar");
};

done_testing;
