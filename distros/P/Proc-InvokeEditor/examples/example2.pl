#!/usr/local/bin/perl -w

use strict;
use Proc::InvokeEditor;

my $editor = new Proc::InvokeEditor(editors => [ '/usr/bin/emacs' ]);
my $e = $editor->first_usable;
print "Usable = " . $e->[0] . "\n";
my @result = $editor->edit("foo\nbar\nbaz\n");

foreach my $line (@result) {
  print "Line: $line\n";
}
sleep 5;

$editor->editors(['/usr/bin/vi']);
$editor->editors_prepend(['/bin/ed']);
$editor->editors_env(['TURNIP']);
my $result = $editor->edit("something\nin\nvi\n");
print $result;

$e = $editor->first_usable;
print "Usable = " . $e->[0] . "\n";
