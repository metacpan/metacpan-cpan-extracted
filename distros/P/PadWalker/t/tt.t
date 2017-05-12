use strict;
use PadWalker;

print "1..5\n";

our %h;
my $out1 = 'out1';
my $out2 = 'out2';

sub f1() {
  my $local = 'local';
  %h = %{PadWalker::peek_my(1)};
  print (${$h{'$out1'}}  eq 'out1'  ? "ok 1\n" : "not ok 1\n");
  print (${$h{'$out2'}}  eq 'out2'  ? "ok 2\n" : "not ok 2\n");
}

f1();

eval q{
  my $in_eval = 'in_eval';
  eval q{
     () = $in_eval;
     %h = %{PadWalker::peek_my(0)};

     print (exists $h{'$out1'} && ${$h{'$out1'}} eq 'out1'
	? "ok 3\n" : "not ok 3\n");
     print (exists $h{'$out2'} && ${$h{'$out2'}} eq 'out2'
	? "ok 4\n" : "not ok 4\n");
     print (exists $h{'$in_eval'} && ${$h{'$in_eval'}} eq 'in_eval'
           ? "ok 5\n" : "not ok 5\n");
  };
  die $@ if $@;
};
die $@ if $@;
