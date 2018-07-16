# see how CODE REFs are created and then freed
#  this tests that all coderefs on a call get saved
#
# v1.02 is good, it never tries to cleanup
#  but it also leaks memory 2 two ways, bad command-deletion  and $anon_refs
# in v1.05 and in v1.06-weaken it suffers from only the last code call on a line geting saved, and "if" can have two if it wants
#  when @codes is freed, only the last one saved in $anon_refs{$current_r} is saved,
#  so the first one keeps getting created, icalled, and then destroyed
#  leaving only one in the table when its done
# others might allow two as well
use Tcl;
use strict; use warnings;

print "1..1\n";

$| = 1;

  my $ct=0;
  my $inter=Tcl->new();

  my @queue;
  my $sub1;
  $sub1=sub{
    $ct++;
    my $rn=rand(100);
    print "rn=$rn\n";
    return (rand(100) > 50);
  };

  my $sub2; $sub2=sub{ print "hit rand $ct\n"; };
  my $sub3; $sub3=sub{ print "miss rand $ct\n"; };

  my ($newct2)=runcmd();
  if ($newct2==2) { print "ok 1\n";}
  else {
   warn "should be 2 commands in table but is $newct2\n";
   print "not ok 1 - cmdcts 2 != $newct2\n";
  }

  exit;

sub runcmd{
  my $precmd=insure_ptrarray($inter,'info', 'commands', '::perl::*');
  $ct=0;
  for my $ii (0..9) {
    my $rand=&$sub1();
    $rand =0 unless ($rand);
    $inter->SetVar ('ifrandvar', $rand);
    $inter->call('if','$ifrandvar',$sub2,$sub3);
#    $inter->call('after',200,sub{'*'});
    }
  flush_afters($inter);
  my ($newct)=newcmds($precmd);
  return $newct;
}

sub newcmds {
 my $precmd=shift;
 my $print=shift;
my $postcmd =insure_ptrarray($inter,'info', 'commands', '::perl::*');
my %start;
my $newct=0;
my @newcmds;
for my $cmd (@$precmd)  { $start{$cmd}=1; }
for my $cmd (@$postcmd) { unless ($start{$cmd}) {print $cmd."\n" if ($print); $newct++; push @newcmds,$cmd;}  }
return $newct,\@newcmds;
}


sub flush_afters{
  my $inter=shift;
  while(1) {  # wait for afters to finish
    my $info0=insure_ptrarray($inter,'after', 'info');
    last unless (scalar(@$info0));
    $inter->icall('after', 300, 'set var fafafa');
    $inter->icall('vwait', 'var'); # will wait for .3 seconds
  }
} # flush afters


sub insure_ptrarray{
  my $inter=shift;
  my $list = $inter->icall(@_);
  if (ref($list) ne 'Tcl::List') {  # v1.02
      $list=[split(' ',$list)];
      }
return $list;
}
