#!/usr/bin/perl

# Test that all params related methods work.
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 15;
use Object::WithParams;

my $thingy = Object::WithParams->new;
is(ref $thingy, 'Object::WithParams', 'Object created');

$thingy->param(color => 'black');
is($thingy->param('color'), 'black', 'scalar parameter get/set');

$thingy->param(numbers => [1, 2, 3]);
is_deeply($thingy->param('numbers'), [1, 2, 3], 'arrayref parameter get/set');

$thingy->param(letters => { a => 'foo', b => 'bar', c => 'baz' });
is_deeply($thingy->param('letters'), { a => 'foo', b => 'bar', c => 'baz' }, 
    'hashref parameter get/set');

is_deeply([ sort $thingy->param ], [ sort qw/ color letters numbers /],
    'parameter list');

my $doodad = $thingy->clone;
is($doodad->param('color'), 'black', 'clone() works');

$thingy->delete('letters');
is($thingy->param('letters'), undef, 'parameter delete');

eval { $thingy->delete('foo'); };
is($EVAL_ERROR, q{}, 'deleting non-existant parameter');

eval { $thingy->delete(); };
is($EVAL_ERROR, q{}, 'deleting missing parameter');

is_deeply([ sort $thingy->param() ], [ sort qw/ color numbers /],
    'parameter list works after delete');

is($doodad->param('color'), 'black', 'clone has param after delete in orig');

$doodad->clear;
is_deeply([ sort $doodad->param() ], [], 'parameters cleared');

my $param_hash = {
    color    => 'black', 
    letters  => { a => 'foo', b => 'bar', c => 'baz' }, 
    numbers  => [1, 2, 3],
};
$doodad->param($param_hash);
is_deeply([ sort $doodad->param ], [ sort qw/ color letters numbers /],
    'set from hashref');

$thingy->param(color => &return_param);
is($thingy->param('color'), 'white', 'coderef parameter get/set');

eval { $thingy->param('veni', 'vidi', 'vici'); };
isnt($EVAL_ERROR, q{}, 'croaked on odd number of args');

sub return_param {

    return 'white';
}

1;
