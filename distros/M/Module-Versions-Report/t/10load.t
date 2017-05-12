
require 5;
use strict;
use Test;
my @modules;

BEGIN { 
  @modules =
  # Modules that have a $VERSION each, and have been in core for ages
  qw(
    Fcntl File::Basename File::Copy File::Path FileHandle FindBin
    Getopt::Long IO::File POSIX Text::Tabs
  );
  my $testcount = 2  +  3 * @modules;
  plan tests => $testcount;
  print "# ~ ~ ~ Expecting $testcount tests ~ ~ ~\n";
}

use Module::Versions::Report ();


ok 1;
foreach my $m (@modules) {
  print "# requiring $m...\n";
  eval "require $m;";
  die "Can't require $m: $@\nAborting" if $@;
  ok 1;
}

my $out = Module::Versions::Report::report();

{ my $o = $out; $o =~ s/^/# /mg; print "#\n#\n# Output:\n$o#\n"; }

foreach my $m (@modules) {
  my $mq = quotemeta($m);
  my $mv = quotemeta(do { no strict 'refs'; ${"$m\::VERSION"} || 'WHA' } );
  if($out =~ m/$mq/) {
    ok 1;
  } else {
    ok 0;
    print "# Can't find $mq in output\n";
  }

  if($out =~ m/$mv/) {
    ok 1;
  } else {
    ok 0;
    print "# Can't find $mv in output\n";
  }

}

print "# Byebye!\n";
ok 1;

