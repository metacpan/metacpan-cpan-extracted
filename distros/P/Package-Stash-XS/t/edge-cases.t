#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Fatal;

use Package::Stash;

{
    package Foo;
    use constant FOO => 1;
    use constant BAR => \1;
    use constant BAZ => [];
    use constant QUUX => {};
    use constant QUUUX => sub { };
    sub normal { }
    sub stub;
    sub normal_with_proto () { }
    sub stub_with_proto ();

    our $SCALAR;
    our $SCALAR_WITH_VALUE = 1;
    our @ARRAY;
    our %HASH;
}

my $stash = Package::Stash->new('Foo');
{ local $TODO = $] < 5.010
      ? "undef scalars aren't visible on 5.8"
      : undef;
ok($stash->has_symbol('$SCALAR'), '$SCALAR');
}
ok($stash->has_symbol('$SCALAR_WITH_VALUE'), '$SCALAR_WITH_VALUE');
ok($stash->has_symbol('@ARRAY'), '@ARRAY');
ok($stash->has_symbol('%HASH'), '%HASH');
is_deeply(
    [sort $stash->list_all_symbols('CODE')],
    [qw(BAR BAZ FOO QUUUX QUUX normal normal_with_proto stub stub_with_proto)],
    "can see all code symbols"
);

$stash->add_symbol('%added', {});
ok(!$stash->has_symbol('$added'), '$added');
ok(!$stash->has_symbol('@added'), '@added');
ok($stash->has_symbol('%added'), '%added');

my $constant = $stash->get_symbol('&FOO');
is(ref($constant), 'CODE', "expanded a constant into a coderef");

# ensure get doesn't prevent subsequent vivification (not sure what the deal
# was here)
is(ref($stash->get_symbol('$glob')), '', "nothing yet");
is(ref($stash->get_or_add_symbol('$glob')), 'SCALAR', "got an empty scalar");

SKIP: {
    skip "PP doesn't support anon stashes before 5.14", 4
        if $] < 5.014 && $Package::Stash::IMPLEMENTATION eq 'PP';
    skip "XS doesn't support anon stashes before 5.10", 4
        if $] < 5.010 && $Package::Stash::IMPLEMENTATION eq 'XS';
    local $TODO = "don't know how to properly inflate a stash entry in PP"
        if $Package::Stash::IMPLEMENTATION eq 'PP';

    my $anon = {}; # not using Package::Anon
    $anon->{foo} = -1;     # stub
    $anon->{bar} = '$&';   # stub with prototype
    $anon->{baz} = \"foo"; # constant

    my $stash = Package::Stash->new($anon);
    is(
        exception {
            is(ref($stash->get_symbol('&foo')), 'CODE',
               "stub expanded into a glob");
            is(ref($stash->get_symbol('&bar')), 'CODE',
               "stub with prototype expanded into a glob");
            is(ref($stash->get_symbol('&baz')), 'CODE',
               "constant expanded into a glob");
        },
        undef,
        "can call get_symbol on weird stash entries"
    );
}

{
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    my $stash = Package::Stash->new('Bar');
    $stash->add_symbol('&foo' => sub { });
    $stash->add_symbol('&foo' => sub { });
    is($warning, undef, "no redefinition warnings");
}

{
    local $TODO = $] < 5.010
        ? "undef scalars aren't visible on 5.8"
        : undef;
    my $stash = Package::Stash->new('Baz');
    $stash->add_symbol('$baz', \undef);
    ok($stash->has_symbol('$baz'), "immortal scalars are also visible");
}

{
    {
        package HasISA::Super;
        package HasISA;
        our @ISA = ('HasISA::Super');
    }
    ok(HasISA->isa('HasISA::Super'));
    my $stash = Package::Stash->new('HasISA');
    is_deeply([$stash->list_all_symbols('SCALAR')], []);
}

done_testing;
