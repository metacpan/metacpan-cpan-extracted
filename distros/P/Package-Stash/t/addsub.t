#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Fatal;

BEGIN { $^P |= 0x210 } # PERLDBf_SUBLINE

use Package::Stash;

my $foo_stash = Package::Stash->new('Foo');

# ----------------------------------------------------------------------
## test adding a CODE

ok(!defined($Foo::{funk}), '... the &funk slot has not been created yet');

is(exception {
    $foo_stash->add_symbol('&funk' => sub { "Foo::funk", __LINE__ });
}, undef, '... created &Foo::funk successfully');

ok(defined($Foo::{funk}), '... the &funk slot was created successfully');

{
    no strict 'refs';
    ok(defined &{'Foo::funk'}, '... our &funk exists');
}

is((Foo->funk())[0], 'Foo::funk', '... got the right value from the function');

my $line = (Foo->funk())[1];
is $DB::sub{'Foo::funk'}, sprintf "%s:%d-%d", __FILE__, $line, $line,
    '... got the right %DB::sub value for funk default args';

$foo_stash->add_symbol(
    '&dunk'        => sub { "Foo::dunk" },
    filename       => "FileName",
    first_line_num => 100,
    last_line_num  => 199
);

is $DB::sub{'Foo::dunk'}, sprintf "%s:%d-%d", "FileName", 100, 199,
    '... got the right %DB::sub value for dunk with specified args';

done_testing;
