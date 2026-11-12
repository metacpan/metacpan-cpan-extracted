use strict;
use warnings;
use Test::More;
use Object::Proto;

# ClassName: a non-empty string naming a loaded package - one with a defined
# $VERSION, a non-empty @ISA or at least one sub.

package TClassName;
BEGIN { Object::Proto::define('TClassName', 'v:ClassName') }
sub set_loaded_const { v($_[0], 'Object::Proto') }
sub set_later_const  { v($_[0], 'TClassName::Later') }

package main;
my $o = TClassName->new;

sub accepts { my ($v, $what) = @_; ok(eval { $o->v($v); 1 }, "ClassName accepts $what") or diag($@) }
sub rejects { my ($v, $what) = @_; eval { $o->v($v) }; like($@, qr/Type constraint failed for 'v': expected ClassName\b/, "ClassName rejects $what") }

# loaded by exactly one rule each
{ package TClassName::Version;   our $VERSION = '1.00' }
{ package TClassName::Isa;       our @ISA = ('TClassName::Version') }
{ package TClassName::Sub;       sub method { 1 } }
{ package TClassName::Const;     use constant ANSWER => 42 }
{ package TClassName::Stub;      sub later; }
{ package TClassName::ProtoStub; sub later_proto($); }
{ package TClassName::VersionConst; use constant VERSION => '1.00' }
# the stash exists, but nothing loads it
{ package TClassName::UndefVersion; our $VERSION }
{ package TClassName::EmptyIsa;     our @ISA = () }
{ package TClassName::ScalarOnly;   our $thing = 1 }
{ package TClassName::Outer::Inner; sub method { 1 } }
{ package TClassName::UndefIsa;     our @ISA = ('TClassName::Version') }
undef *TClassName::UndefIsa::ISA;
{ package TClassName::Wiped;        sub method { 1 } }
undef %TClassName::Wiped::;
my $blessed_only = bless {}, 'TClassName::BlessedOnly';

accepts('Object::Proto',            'a loaded module');
accepts('main',                     'main');
accepts('TClassName',               'an Object::Proto class');
accepts('TClassName::Version',      'a package with only $VERSION');
accepts('TClassName::Isa',          'a package with only @ISA');
accepts('TClassName::Sub',          'a package with only a sub');
accepts('TClassName::Const',        'a package with only a constant');
accepts('TClassName::Stub',         'a package with only a sub stub');
accepts('TClassName::ProtoStub',    'a package with only a prototyped stub');
accepts('TClassName::VersionConst', 'a package with only a VERSION constant');
my $upgraded = 'TClassName::Sub';
utf8::upgrade($upgraded);
accepts($upgraded,                  'a UTF-8 flagged name');

rejects(undef,                      'undef');
rejects('',                         'the empty string');
rejects('TClassName::Nowhere',      'a package that does not exist');
rejects('TClassName::UndefVersion', 'a package with an undefined $VERSION');
rejects('TClassName::EmptyIsa',     'a package with an empty @ISA');
rejects('TClassName::ScalarOnly',   'a package with only a scalar');
rejects('TClassName::Outer',        'a namespace that only holds a nested package');
rejects('TClassName::UndefIsa',     'a package whose @ISA glob was undefined');
rejects('TClassName::BlessedOnly',  'a package objects were blessed into but nothing defined');
rejects('TClassName::Wiped',        'a package whose symbol table was undefined');
rejects('Object Proto',             'a name with a space');
rejects(42,                         'a number');
rejects(TClassName->new,            'an object');

# A constant or a sub stub sits in a symbol table as a plain scalar, not a
# glob, until something touches it as a glob - as a coverage tool walking the
# symbol tables at startup does, which would upgrade the fixtures above. So
# this one is made at run time, the way constant.pm makes it, just before the
# check: a VERSION entry that is not a glob, and the only entry in the package.
$TClassName::ProxyOnly::{VERSION} = \'1.00';
accepts('TClassName::ProxyOnly',    'a package whose only entry is a constant made at run time');
# Likewise a VERSION glob with a sub and no scalar: a tool that looks at each
# glob's SCALAR slot gives it one, so it too is made at run time, by name.
{ no strict 'refs'; *{'TClassName::VersionSub::VERSION'} = sub { '1.00' }; }
accepts('TClassName::VersionSub',   'a package with only a VERSION method');

# checking a name must not create the package
ok(!exists $main::{'TClassNameNever::'}, 'a package never mentioned has no stash');
rejects('TClassNameNever',          'that package');
ok(!exists $main::{'TClassNameNever::'}, 'and checking it did not create one');

# checking a package does not disturb an each() over its symbol table
{
    { package TClassName::Iter; our ($x, $y, $z); sub method { 1 } }
    my (%seen, $steps);
    while (my ($name) = each %TClassName::Iter::) {
        $seen{$name}++;
        $o->v('TClassName::Iter');
        last if ++$steps > 100;    # a check that reset the iterator would loop
    }
    is_deeply([sort keys %seen], [sort keys %TClassName::Iter::],
              'checking a package does not reset an each() over it');
}

# non-ASCII package names
SKIP: {
    skip 'UTF-8 package names need perl 5.16', 4 if $] < 5.016;
    for my $name ("TClassName::\x{dc}n\x{ef}", "TClassName::\x{100}bc") {
        my $src = "use utf8; package $name; sub method { 1 } 1";
        utf8::encode($src);
        eval $src or die $@;
        accepts($name,        'a loaded package with a non-ASCII name');
        rejects($name . 'x',  'a similar non-ASCII name that is not loaded');
    }
}

# A constant is checked when the call is compiled only if it passes then: a
# class loaded later still has to be accepted when the call runs.
is(TClassName::set_loaded_const($o), 'Object::Proto', 'a constant naming a loaded class is accepted');
eval { TClassName::set_later_const($o) };
like($@, qr/expected ClassName\b/, 'a constant naming a class not loaded yet is rejected');
eval 'package TClassName::Later; sub method { 1 } 1' or die $@;
is(eval { TClassName::set_later_const($o) }, 'TClassName::Later', 'and accepted once it is loaded')
    or diag($@);

ok(TClassName->new(v => 'main'), 'new() accepts a ClassName');
eval { TClassName->new(v => 'TClassName::Nowhere') };
like($@, qr/Type constraint failed for 'v' in new\(\): expected ClassName\b/, 'new() rejects an unloaded class');

ok(Object::Proto::has_type('ClassName'), 'has_type knows ClassName');
is(Object::Proto::slot_info('TClassName', 'v')->{type}, 'ClassName', 'slot_info reports ClassName');

done_testing;
