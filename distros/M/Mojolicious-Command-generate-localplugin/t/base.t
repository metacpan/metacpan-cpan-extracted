#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;


use FindBin;
use lib "$FindBin::Bin/lib";

use Mojo::File qw(path tempdir);

require Mojolicious::Command::Author::generate::localplugin;

my $plugin = Mojolicious::Command::Author::generate::localplugin->new;

ok $plugin->description, 'has a description';
like $plugin->usage, qr/plugin/, 'has usage information';

my $cwd = path;
my $dir = tempdir CLEANUP => 1;
chdir $dir;

my $buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $plugin->run;
}

like $buffer, qr/MyPlugin\.pm/, 'right output';
ok -e $plugin->rel_file(
  'lib/MyPlugin.pm'),
  'class exists';
ok -e $plugin->rel_file('t/my_plugin.t'), 'test exists';

{
  note "Subtest: Run tests for MyPlugin";

  open my $fh, '-|', $^X => -I, $plugin->rel_file('lib'),
    $plugin->rel_file('t/my_plugin.t')
    or fail "Failed to open test: $!";
  print "    $_" while readline $fh;
  close $fh or fail "Failed to close test handle: $!";

  is $?, 0, "Ran tests for MyPlugin";
}

chdir $cwd;

done_testing();
