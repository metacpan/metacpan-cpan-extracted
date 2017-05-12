#!perl -- -*- mode: cperl -*-

use Test::More;
use File::Spec;

my $Id = q$Id: bap.t 26 2003-02-16 19:01:03Z k $;

my @s;
opendir my $dh, "scripts" or die "Could not opendir scripts: $!";
for my $d (readdir $dh) {
  next unless $d =~ /^\w/;
  next if $d =~ /~$/;
  next if $d =~ /svn$/;
  push @s, $d;
}

my $tests_per_loop = 5;
my $plan = scalar @s * $tests_per_loop;
plan tests => $plan;

my $devnull = File::Spec->devnull;
for my $s (1..@s) {
  my $script = "scripts/$s[$s-1]";
  my $ret = system $^X, "-cw", $script;
  ok !$ret, "$script:-c:$ret";
  $ret = system "$^X -w $script --h > $devnull";
  ok !$?, "$script:--h:$ret";
  $ret = `$^X -w $script --h`;
  ok scalar $ret =~ /[\s\[]--h(elp)?\b/, "$script\:h~\:$ret";
  $ret = `$^X $script --version`;
  ok !$?, "$script\:version\:$?";
  ok scalar $ret =~ /\d\d\d/, "$script\:version\:$ret";
}

__END__

