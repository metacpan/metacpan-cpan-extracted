#!perl -w
use strict;

print "1..3\n";

if (eval {
  require PITA::Test::Dummy::Perl5::XS;
}) {
  print "ok 1 - load module PITA::Test::Dummy::Perl5::XS\n";
  my $class = 'PITA::Test::Dummy::Perl5::XS';
  print $class->can('dummy') ? "ok 2" : "not ok 2", " - has a dummy method\n";
  if ($class->can('dummy')) {
    print $class->dummy eq 'George' ? "ok 3" : "not ok 3", " - it's the right dummy\n";
  }
  else {
    print "ok 3 # skip - doesn't have a dummy method\n";
  }
}
else {
  print "not ok 1 - load module PITA::Test::Dummy::Perl5::XS\n";
  print "ok 2 # skip - couldn't load module\n";
  print "ok 3 # skip - couldn't load module\n";
}
