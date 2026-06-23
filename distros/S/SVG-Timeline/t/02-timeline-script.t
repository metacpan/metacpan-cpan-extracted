use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

# Find the bin/timeline script relative to this test file
my $script = do {
  use File::Basename qw(dirname);
  use File::Spec;
  File::Spec->catfile(dirname(__FILE__), '..', 'bin', 'timeline');
};

ok(-f $script, 'timeline script exists');

sub run_timeline {
  my ($input) = @_;
  my ($fh, $filename) = tempfile(UNLINK => 1, SUFFIX => '.txt');
  print $fh $input;
  close $fh;
  my $output = `$^X -I lib $script $filename 2>&1`;
  return ($output, $?);
}

# Test the exact example from the issue / documentation (space-separated)
{
  my ($out, $rc) = run_timeline(
    "World War I  1914 1918 red\nWorld War II 1939 1940 blue\n"
  );
  is($rc, 0, 'space-separated input with colour exits cleanly');
  like($out, qr/<svg/, 'produces SVG output');
}

# Without colour (also documented)
{
  my ($out, $rc) = run_timeline(
    "World War I  1914 1918\nWorld War II 1939 1945\n"
  );
  is($rc, 0, 'space-separated input without colour exits cleanly');
  like($out, qr/<svg/, 'produces SVG output without colour');
}

# Tab-separated (original format) still works
{
  my ($out, $rc) = run_timeline(
    "World War I\t1914\t1918\tred\nWorld War II\t1939\t1945\tblue\n"
  );
  is($rc, 0, 'tab-separated input exits cleanly');
  like($out, qr/<svg/, 'produces SVG output from tab-separated input');
}

# Full date format in start/end
{
  my ($out, $rc) = run_timeline(
    "World War I  1914-07-28 1918-11-11\n"
  );
  is($rc, 0, 'full date format exits cleanly');
  like($out, qr/<svg/, 'produces SVG output from full date input');
}

# Blank lines are skipped
{
  my ($out, $rc) = run_timeline(
    "\nWorld War I  1914 1918\n\n"
  );
  is($rc, 0, 'blank lines are skipped cleanly');
  like($out, qr/<svg/, 'produces SVG output when input has blank lines');
}

done_testing();
