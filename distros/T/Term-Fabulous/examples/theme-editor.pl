#!/usr/bin/env perl

# The theme editor with the theme files of examples/themes/, one per tab,
# as `fabulous-theme-editor examples/themes/*.kdl` would start it. The
# left side previews the theme of the tab you are on with a widget of
# every family; the right side edits its settings, as a form or as the
# text of the file. F1 lists every key, F10 opens the menus, Ctrl+Q
# quits and asks about unsaved changes first. See
# Term::Fabulous::ThemeEditor.

use v5.32;
use warnings;

use FindBin;
use Term::Fabulous::ThemeEditor;

my @files = sort glob("$FindBin::Bin/themes/*.kdl");
Term::Fabulous::ThemeEditor->new( files => \@files )->run;
