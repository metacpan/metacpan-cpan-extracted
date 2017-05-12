#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Fatal;
use Test::LeakTrace;

BEGIN { $^P |= 0x210 } # PERLDBf_SUBLINE

use Package::Stash;
use Symbol;

{
    package Bar;
}

{
    package Baz;
    our $foo;
    sub bar { }
    use constant baz => 1;
    our %quux = (a => 'b');
}

{
    no_leaks_ok {
        Package::Stash->new('Foo');
    } "object construction doesn't leak";
}

{
    no_leaks_ok {
        Package::Stash->new('Bar');
    } "object construction doesn't leak, with an existing package";
}

{
    no_leaks_ok {
        Package::Stash->new('Baz');
    } "object construction doesn't leak, with an existing package with things in it";
}

{
    my $foo = Package::Stash->new('Foo');
    no_leaks_ok {
        $foo->name;
    } "name accessor doesn't leak";
    no_leaks_ok {
        $foo->namespace;
    } "namespace accessor doesn't leak";
}

{
    my $foo = Package::Stash->new('Foo');
    no_leaks_ok {
        $foo->add_symbol('$scalar');
    } "add_symbol scalar with no initializer doesn't leak";
    no_leaks_ok {
        $foo->add_symbol('@array');
    } "add_symbol array with no initializer doesn't leak";
    no_leaks_ok {
        $foo->add_symbol('%hash');
    } "add_symbol hash with no initializer doesn't leak";
    { local $TODO = "not sure why this leaks";
    no_leaks_ok {
        $foo->add_symbol('io');
    } "add_symbol io with no initializer doesn't leak";
    }
}

{
    my $foo = Package::Stash->new('Foo');
    no_leaks_ok {
        $foo->add_symbol('$scalar_init' => 1);
    } "add_symbol scalar doesn't leak";
    no_leaks_ok {
        $foo->add_symbol('@array_init' => []);
    } "add_symbol array doesn't leak";
    no_leaks_ok {
        $foo->add_symbol('%hash_init' => {});
    } "add_symbol hash doesn't leak";
    no_leaks_ok {
        $foo->add_symbol('&code_init' => sub { "foo" });
    } "add_symbol code doesn't leak";
    no_leaks_ok {
        $foo->add_symbol('io_init' => Symbol::geniosym);
    } "add_symbol io doesn't leak";
    is(exception {
        is(Foo->code_init, 'foo', "sub installed correctly")
    }, undef, "code_init exists");
}

{
    my $foo = Package::Stash->new('Foo');
    no_leaks_ok {
        $foo->remove_symbol('$scalar_init');
    } "remove_symbol scalar doesn't leak";
    no_leaks_ok {
        $foo->remove_symbol('@array_init');
    } "remove_symbol array doesn't leak";
    no_leaks_ok {
        $foo->remove_symbol('%hash_init');
    } "remove_symbol hash doesn't leak";
    no_leaks_ok {
        $foo->remove_symbol('&code_init');
    } "remove_symbol code doesn't leak";
    no_leaks_ok {
        $foo->remove_symbol('io_init');
    } "remove_symbol io doesn't leak";
}

{
    my $foo = Package::Stash->new('Foo');
    $foo->add_symbol("${_}glob") for ('$', '@', '%', '');
    no_leaks_ok {
        $foo->remove_glob('glob');
    } "remove_glob doesn't leak";
}

{
    my $foo = Package::Stash->new('Foo');
    no_leaks_ok {
        $foo->has_symbol('io');
    } "has_symbol io doesn't leak";
    no_leaks_ok {
        $foo->has_symbol('%hash');
    } "has_symbol hash doesn't leak";
    no_leaks_ok {
        $foo->has_symbol('@array_init');
    } "has_symbol array doesn't leak";
    no_leaks_ok {
        $foo->has_symbol('$glob');
    } "has_symbol nonexistent scalar doesn't leak";
    no_leaks_ok {
        $foo->has_symbol('&something_else');
    } "has_symbol nonexistent code doesn't leak";
}

{
    my $foo = Package::Stash->new('Foo');
    no_leaks_ok {
        $foo->get_symbol('io');
    } "get_symbol io doesn't leak";
    no_leaks_ok {
        $foo->get_symbol('%hash');
    } "get_symbol hash doesn't leak";
    no_leaks_ok {
        $foo->get_symbol('@array_init');
    } "get_symbol array doesn't leak";
    no_leaks_ok {
        $foo->get_symbol('$glob');
    } "get_symbol nonexistent scalar doesn't leak";
    no_leaks_ok {
        $foo->get_symbol('&something_else');
    } "get_symbol nonexistent code doesn't leak";
}

{
    my $foo = Package::Stash->new('Foo');
    ok(!$foo->has_symbol('$glob'));
    ok(!$foo->has_symbol('@array_init'));
    no_leaks_ok {
        $foo->get_or_add_symbol('io');
        $foo->get_or_add_symbol('%hash');
        my @super = ('Exporter');
        @{$foo->get_or_add_symbol('@ISA')} = @super;
        $foo->get_or_add_symbol('$glob');
    } "get_or_add_symbol doesn't leak";
    { local $TODO = $] < 5.010
        ? "undef scalars aren't visible on 5.8"
        : undef;
    ok($foo->has_symbol('$glob'));
    }
    is(ref($foo->get_symbol('$glob')), 'SCALAR');
    ok($foo->has_symbol('@ISA'));
    is(ref($foo->get_symbol('@ISA')), 'ARRAY');
    is_deeply($foo->get_symbol('@ISA'), ['Exporter']);
    isa_ok('Foo', 'Exporter');
}

{
    my $foo = Package::Stash->new('Foo');
    my $baz = Package::Stash->new('Baz');
    no_leaks_ok {
        $foo->list_all_symbols;
        $foo->list_all_symbols('SCALAR');
        $foo->list_all_symbols('CODE');
        $baz->list_all_symbols('CODE');
    } "list_all_symbols doesn't leak";
}

{
    package Blah;
    use constant 'baz';
}

{
    my $foo = Package::Stash->new('Foo');
    my $blah = Package::Stash->new('Blah');
    no_leaks_ok {
        $foo->get_all_symbols;
        $foo->get_all_symbols('SCALAR');
        $foo->get_all_symbols('CODE');
        $blah->get_all_symbols('CODE');
    } "get_all_symbols doesn't leak";
}

# mimic CMOP::create_anon_class
{
    local $TODO = $] < 5.010 ? "deleting stashes is inherently leaky on 5.8"
                             : undef;
    my $i = 0;
    no_leaks_ok {
        $i++;
        eval "package Quux$i; 1;";
        my $quux = Package::Stash->new("Quux$i");
        $quux->get_or_add_symbol('@ISA');
        delete $::{'Quux' . $i . '::'};
    } "get_symbol doesn't leak during glob expansion";
}

{
    my $foo = Package::Stash->new('Foo');
    no_leaks_ok {
        eval { $foo->add_symbol('&blorg') };
    } "doesn't leak on errors";
}

done_testing;
