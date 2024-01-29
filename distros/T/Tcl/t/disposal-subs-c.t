# see how CODE REFs are created and then freed
#  this tests that code is not freed while any after is still using it
# this tests the [$sub,arg,arg,arg] form
#
# v1.02 is good, it never tries to cleanup
#  but it also leaks memory 2 two ways, command-deletion  and $anon_refs
# in  v1.05  they fail after $delay+1 sec
#   1-1) the call to create_tcl_sub
#   1-1-1)  CreateCommand($tclname, $sub, undef, undef, 1) creates the tcl-> perl callback
#   1-1-2}  $anon_refs{$rname} doesnt exist
#   1-1-3}  $anon_refs{$rname} = bless [\$sub, $interp], 'Tcl::Code'; gets set
#   1-2}  its an after command
#   1-2-1}  the constructed after command is run $interp->icall(@args)
#   1-2-2}  the calls bundled in @calls get saved to a new $anon_refs{$synthname}
#   1-2-3}  $anon_refs{$rname} gets deleted, but there is a copy in @calls/$anon_refs{$synthname}, nothing is destroyed
#   1-2-3}  after gets called in $delay+1 secs to delete $anon_refs{$synthname}
#
# that repeats until 1  second after the first delay in the after chain
#  then when the first _code_dispose($synthname) gets called
#
#   2-1)  _code_dispose($k/synthname)
#   2-1-1)  delete $anon_refs{$k};
#   2-1-2}  $anon_refs{$k} does exist  , its an array and all members get destroyed
#   2-1-2-1}  each member was its own Tcl::Code object and is singlar and gets destroyed
#   2-1-2-2)  $interp->DeleteCommand($tclname} runs and destroys the new command
#  but that same $tclname may still be scheduled in later after calls still pending
#
# but later when tcl tries to use $tclname as a command alias, its been destroyed
#   Tcl error 'invalid command name "::perl::CODE(0x8e4e2a8)"
#      at ./blib/lib/Tcl.pm line ####.
#      while invoking scalar result call:
# its just plain gone
#
# i fixed this for v1.06
#  the "weaken" patch version dealt with this a little by keeping weakened $anon_refs{$tclname} as a Tcl::Code
#   that all the other $anon_refs had a copy of, rather than a new Tcl::Code every time
#   so only when the last {$anon_refs{$rname | $synthname} copy was destroyed did the $interp->DeleteCommand($tclname} run
#  but it still suffered from other probs

use Tcl;
use strict; use warnings;

  $| = 1;

  print "1..9\n";

  my $inter=Tcl->new();

  my $ct=0;
  my @queue;
  my $sub;
  $sub=sub{
    my $arg1=shift;
    unless ($arg1 == 0) { exit;}
    return unless (scalar(@queue));
    my $line =shift @queue;
    print $line."\n";
    return unless (scalar(@queue));
    $inter->call('after',200,[$sub,$ct]);
  };

  run_cmd(1);

  flush_afters($inter);
  exit;

sub run_cmd{
  my $name=shift;
  for my $ii (1..9) {push @queue,'ok '.$ii; }
  $inter->call('after',200,[$sub,$ct]);
}

sub flush_afters{
  my $inter=shift;
  while(1) {  # wait for afters to finish
    my @info0=$inter->icall('after', 'info');
    last unless (scalar(@info0));
    $inter->icall('after', 300, 'set var fafafa');
    $inter->icall('vwait', 'var'); # will wait for .3 seconds
  }
} # flush afters

