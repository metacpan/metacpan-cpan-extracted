#!/usr/bin/perl -w

use strict;

use Test::More tests => 42;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath();
my (undef, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;

$svk->mkdir ('-m', 'trunk', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');
$svk->ps ('-m', 'set prop', 'prop', 'value', '//trunk/me');
$svk->co ('//trunk', $copath);

flush_co();

# the same prop in outdated checkout
{
    $svk->ps ('prop', 'value', "$copath/me");
    is_output($svk, 'up', ['-C', $copath], [
        "Syncing //trunk(/trunk) in $corpath to 4.",
        __(" g  $copath/me"),
    ] );
    is_output($svk, 'up', [$copath], [
        "Syncing //trunk(/trunk) in $corpath to 4.",
       __( " g  $copath/me"),
    ] );
    is_output($svk, 'st', [$copath], [
    ] );
    is_output($svk, 'di', [$copath], [
    ] );
}

flush_co();

# different prop in outdated checkout
{
    $svk->ps ('another-prop', 'value', "$copath/me");
    is_output($svk, 'up', ['-C', $copath], [
        "Syncing //trunk(/trunk) in $corpath to 4.",
        __(" U  $copath/me"),
    ] );
    is_output($svk, 'up', [$copath], [
        "Syncing //trunk(/trunk) in $corpath to 4.",
        __(" U  $copath/me"),
    ] );
    is_output($svk, 'st', [$copath], [
        __(" M  $copath/me"),
    ] );
    is_output($svk, 'di', [$copath], [
        "",
        __("Property changes on: $copath/me"),
        "___________________________________________________________________",
        "Name: another-prop",
        " +value",
        "",
    ] );
}

flush_co();

# conflict on update
{
    $svk->ps ('prop', 'another-value', "$copath/me");
    is_output($svk, 'up', ['-C', $copath], [
        "Syncing //trunk(/trunk) in $corpath to 4.",
        __(" C  $copath/me"),
        "1 conflict found.",
    ] );
    is_output($svk, 'up', [$copath], [
        "Syncing //trunk(/trunk) in $corpath to 4.",
        __(" C  $copath/me"),
        "1 conflict found.",
    ] );
    is_output($svk, 'st', [$copath], [
        __(" C  $copath/me"),
    ] );

    # XXX: this looks wierd a littl without line endings
    is_output($svk, 'di', [$copath], [
        "",
        __("Property changes on: $copath/me"),
        "___________________________________________________________________",
        "Name: prop",
        " -value",
        qr" \+>>>> YOUR VERSION Property prop of me \(/trunk\) \d+",
        qr" \+another-value==== ORIGINAL VERSION Property prop of me \d+",
        qr" \+==== THEIR VERSION Property prop of me \(/trunk\) \d+",
        qr" \+value<<<< \d+",
        " +",
        "",
    ] );
    # TODO: test resolved command, test ps command
}

# TODO: test props resolver on update


### The same tests on a dir instead of file

$svk->ps ('-m', 'set prop', 'prop', 'value', '//trunk/A');
flush_co_dir();

# the same prop on a dir in outdated checkout
{
    $svk->ps ('prop', 'value', "$copath/A");
    is_output($svk, 'up', ['-C', $copath], [
        "Syncing //trunk(/trunk) in $corpath to 5.",
        __(" g  $copath/A"),
    ] );
    is_output($svk, 'up', [$copath], [
        "Syncing //trunk(/trunk) in $corpath to 5.",
        __(" g  $copath/A"),
    ] );
    is_output($svk, 'st', [$copath], [
    ] );
    is_output($svk, 'di', [$copath], [
    ] );
}

flush_co_dir();

# different prop in outdated checkout
{
    $svk->ps ('another-prop', 'value', "$copath/A");
    is_output($svk, 'up', ['-C', $copath], [
        "Syncing //trunk(/trunk) in $corpath to 5.",
        __(" U  $copath/A"),
    ] );
    is_output($svk, 'up', [$copath], [
        "Syncing //trunk(/trunk) in $corpath to 5.",
        __(" U  $copath/A"),
    ] );
    is_output($svk, 'st', [$copath], [
        __(" M  $copath/A"),
    ] );
    is_output($svk, 'di', [$copath], [
        "",
        __("Property changes on: $copath/A"),
        "___________________________________________________________________",
        "Name: another-prop",
        " +value",
        "",
    ] );
}

flush_co_dir();

# conflict on update
{
    $svk->ps ('prop', 'another-value', "$copath/A");
    is_output($svk, 'up', ['-C', $copath], [
        "Syncing //trunk(/trunk) in $corpath to 5.",
        __(" C  $copath/A"),
        "1 conflict found.",
    ] );
    is_output($svk, 'up', [$copath], [
        "Syncing //trunk(/trunk) in $corpath to 5.",
        __(" C  $copath/A"),
        "1 conflict found.",
    ] );
    is_output($svk, 'st', [$copath], [
        __(" C  $copath/A"),
    ] );

    # XXX: this looks wierd a littl without line endings
    is_output($svk, 'di', [$copath], [
        "",
        __("Property changes on: $copath/A"),
        "___________________________________________________________________",
        "Name: prop",
        " -value",
        qr" \+>>>> YOUR VERSION Property prop of A \(/trunk\) \d+",
        qr" \+another-value==== ORIGINAL VERSION Property prop of A \d+",
        qr" \+==== THEIR VERSION Property prop of A \(/trunk\) \d+",
        qr" \+value<<<< \d+",
        " +",
        "",
    ] );
    # TODO: test resolved command, test ps command
}

# flush to required state: revert, update to revision before propset on //trunk
sub flush_co {
    $svk->revert('-R', $copath);
    $svk->up($copath);
    $svk->up('-r3', $copath);
    is_output($svk, 'up', ['-C', $copath], [
        #XXX, TODO: why it's corpath instead copath?
        "Syncing //trunk(/trunk) in $corpath to 4.",
        __(" U  $copath/me"),
    ] );
    is_output($svk, 'st', [$copath], [
    ] );
    is_output($svk, 'di', [$copath], [
    ] );
}

sub flush_co_dir {
    $svk->revert('-R', $copath);
    $svk->up($copath);
    $svk->up('-r4', $copath);
    is_output($svk, 'up', ['-C', $copath], [
        #XXX, TODO: why it's corpath instead copath?
        "Syncing //trunk(/trunk) in $corpath to 5.",
        __(" U  $copath/A"),
    ] );
    is_output($svk, 'st', [$copath], [
    ] );
    is_output($svk, 'di', [$copath], [
    ] );
}

