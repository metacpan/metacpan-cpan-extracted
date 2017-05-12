#!/usr/local/bin/perl -w

use strict;
use Proc::InvokeEditor;
use Test::More tests => 8;

# create a new object?
my $e = new Proc::InvokeEditor;
ok(defined($e), 'Object created');
is(ref($e), 'Proc::InvokeEditor', 'Object type correct');

# set and get editors
$e->editors(['vi', 'emacs', 'ed']);
my $editors = $e->editors;
ok(eq_array($editors, ['vi', 'emacs', 'ed']), 'can set editors');

# set and get cleanup
$e->cleanup(1);
my $cleanup = $e->cleanup;
is($cleanup, 1, 'Cleanup can be set');

# prepend something to editors, see if it works
$e->editors_prepend(['vim']);
$editors = $e->editors;
ok(eq_array($editors, ['vim', 'vi', 'emacs', 'ed']), 'can prepend');

# can prepend env
$ENV{FOO} = 'x';
$ENV{BAR} = 'y';
$e->editors_env(['FOO', 'BAR']);
$editors = $e->editors;
ok(eq_array($editors, ['x', 'y', 'vim', 'vi', 'emacs', 'ed']), 'can env prepend');

# can we find any first usable editor?
my $f = Proc::InvokeEditor->first_usable;
ok(defined $f, 'first usable editor was defined');
is(ref($f), 'ARRAY', 'usable editor was an array');

#my $templ = "PLEASE SAVE THIS FILE WITHOUT CHANGES\n";
#my $edited_text = Proc::InvokeEditor->edit($templ);
#is($edited_text, $templ, "template saved unchanged successfully");
#my @templ_lines = ("PLEASE SAVE THIS", "WITH NO CHANGES");
#my @edit_lines = Proc::InvokeEditor->edit(\@templ_lines);
#ok(eq_array(\@templ_lines, \@edit_lines), 'array template saved unchanged fine');
#
