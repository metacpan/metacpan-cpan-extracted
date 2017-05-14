#!/usr/local/bin/perl -w

# The dir_find function uses File::Find's find function which uses Cwd
# which calls `pwd` which it tainted.  If one sets one's own PATH Cwd
# works, though File::Find is tainted on something else.  I consider
# it a bug, i'll worry about it later.

use strict;
use lib qw(blib/lib);
use ShellScript::Env;

#####################
print "1..3\n";

my $test = new ShellScript::Env('./t');

#################
# Test 1, just do a search for lib
my @expect = sort qw(./t/root/bin ./t/bin);
my @got = sort $test->dir_find('bin');
my $error = 0;
if (scalar(@expect) != scalar(@got)) {
  print "not ok\n";
} else {
  my $output = "ok\n";
  for (my $loop = $#{expect}; $loop >= 0; $loop--) {
    if ($expect[$loop] ne $got[$loop]) {
      $output = "not ok\n";
    }
  }
  print $output;
}
for (@got) {
    print "# $_\n";
}


####################
# Test 2, convert it to C Shell
$test->automatic();
&check($test->sh(), <<'EXPECT');
LD_LIBRARY_PATH=./t/root/lib:$LD_LIBRARY_PATH
PATH=./t/bin:./t/root/bin:$PATH
export LD_LIBRARY_PATH PATH
EXPECT


###############
# Test 3, try find_dir() with a different skip_dirs list.
$test->unset('LD_LIBRARY_PATH');
$test->unset('PATH');
push @{$test->{'skip_dirs'}}, 't/root';
$test->automatic();
&check($test->sh(), <<'EXPECT'
PATH=./t/bin:$PATH
export PATH
EXPECT
);


##################
# Little auxiliary function to save me typing.

use Data::Dumper;

sub check {
  my $got = shift;
  my $expect = shift;

  if ($got eq $expect) {
    print "ok\n";
  } else {
    print "not ok\n";
    warn "--\ngot:\n$got\nexpect:\n$expect\n--";

  }

  $got =~ s/^/\# /gm;
  print $got;
}
