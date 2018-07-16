# see how CODE REFs are created and then freed
#  this tests that coderefs are not improperly freed (by garbage collection)
#
use Tcl;
use strict; use warnings;

  $| = 1;

  print "1..5\n";

# v1.02 is good, it never tries to cleanup
#  but it also leaks memory 2 two ways, command-deletion  and $anon_refs
# even with weakened they fail after one round in v1.05
#   1-1) the call to create_tcl_sub
#   1-1-1)  CreateCommand($tclname, $sub, undef, undef, 1) creates the tcl-> perl callback
#   1-1-2}  $anon_refs{$rname} doesnt exist
#   1-1-3}  $anon_refs{$rname} = bless [\$sub, $interp], 'Tcl::Code'; gets set
#
#   2-1) the call to create_tcl_sub
#   2-1-1)  CreateCommand($tclname, $sub, undef, undef, 1) creates the tcl-> perl callback
#   2-1-2}  $anon_refs{$rname} does exist
#   2-1-3}  $anon_refs{$rname} = bless [\$sub, $interp], 'Tcl::Code'; runs
#   2-3-3-1}  $anon_refs{$rname} gets destroyed and triggers Tcl::Code DESTROY
#   2-3-3-2)  $interp->DeleteCommand($tclname} runs and destroys the new command
#   2-3-3-3}  $anon_refs{$rname} gets recreated by bless [\$sub, $interp], 'Tcl::Code';
#
#
# but later when tcl tries to use $tclname as a command alias, its been destoryed
#   Tcl error 'invalid command name "::perl::CODE(0x8e4e2a8)"
#      at ./blib/lib/Tcl.pm line ####.
#      while invoking scalar result call:
# its just plain gone
#
# i fixed this for v1.06
#  but the "weaken" patch suffers from the same problem
#    see even tho the weakened $tclname still exists,
#   still at 2-3-3-1}  the last strong $anon_refs{$rname} gets destroyed and triggers Tcl::Code DESTROY
#

  my $inter=Tcl->new();
  my $q = 0;
  for (1 .. 5) {$inter->call('if', 1000, sub {print '+';}); }
  print "\n";

print "ok 1 - constant sub {print '+';} \n";

  my $sub2=mygen('first',sub{ });

  for (1 .. 5) {$inter->call('if', 1001, $sub2); }

print "ok 2 - constant sub pr mygen('first',sub{ }); \n";

  my $ct3=0;
  my $sub3=mygen('2nd  ',sub{$_[0]++; print $_[0];},$ct3);

  for (1 .. 5) {$inter->call('if', 1002, $sub3); }

print "ok 3 - constant sub2 \n";
myok(4,($ct3==5),'- ran '.$ct3.' files');

  my $ct5=0;
  my $sub5=mygen('2nd  ',sub{$_[0]++; print $_[0];},$ct5);

  my $tclname=$inter->create_tcl_sub($sub5, undef, undef, 'rn');
    { my $id = $inter->call('if','4',$tclname);}
    { my $id = $inter->call('if','4',$tclname);}
    { my $id = $inter->call('if','4',$tclname);}
    { my $id = $inter->call('if','4',$tclname);}
    { my $id = $inter->call('if','4',$tclname);}
myok(5,($ct5==5),'- ran '.$ct5.' files');



exit;


# returns name of module if 'use xxx' fails or empty string if 'use xxx' successful
sub test_use {
  my $use = shift;
  my $useok = eval $use.';1';
  if (!$useok || $@) { return $use }
  return '';
}

BEGIN {
  my $use_bad='';
  $use_bad.=test_use ('use Devel::Peek     qw( SvREFCNT Dump)');
  $use_bad.=test_use ('use Devel::Refcount qw( refcount )');
#  $use_bad.=test_use ('use xxx;'); $use_bad.=test_use ('use yxxx;');

 if ($use_bad) {
   print "1..0 # skip because: not installed $use_bad \n";
   exit;
   };
}





sub mygen {
     my $id=shift;
     my $sub0=shift;
     my $args=\@_;
     return sub{ print $id; &$sub0(@$args); print "\n"; }
     }

sub myok {
  my $test=shift;
  my $isgood=shift;
  print ''.($isgood?'':'not ');
  print 'ok '.$test;
  print ' '.join(' ',@_)."\n";
  }


__END__
  my $tclname=    $inter->create_tcl_sub($sub, undef, undef, 'rn');
    { my $id = $inter->call('if','4',$tclname);}
    { my $id = $inter->call('if','4',$tclname);}
    { my $id = $inter->call('if','4',$tclname);}

    for my $ii (1..4) { my $id = $inter->call('after','5',sub {print '*'});}
    flush_afters($inter);
    print "\n";

    for my $ii (1..4) { my $id = $inter->call('if','3',sub {print '*'});}

    for my $ii (1..4) { my $id = $inter->call('if','2',$sub);}
    for my $ii (1..4)
    {
      my $id = $inter->call('if','1',$sub);
#      my $tclname=    $inter->create_tcl_sub($sub, undef, undef, 'rn');
#      print "105-AV       ".join(' ',refcts($sub))."\n";
#      $anon_refs{rn}=bless ([\$sub],'Tcl::Code');
#      print "105-anon{rn} ".join(' ',refcts($sub))."\n";
#      $anon_refs{ar}=[$anon_refs{rn}];
#      print "105-anon{ar} ".join(' ',refcts($sub))."\n";
#      delete $anon_refs{rn};
#      print "105-no rn    ".join(' ',refcts($sub))."\n";
#      my $id = $inter->call('if','1',$tclname);
#      my $id = $inter->icall('after','1',$tclname);
#      print  "105-stillar  ".join(' ',refcts($sub))."\n";
#      delete $anon_refs{ar};
#      print "105-no ar    ".join(' ',refcts($sub))."\n";
      }
     flush_afters($inter);
     %anon_refs=();
     print  "105-stillav  ".join(' ',refcts($sub))."\n";
    }
  print     "105-postav   ".join(' ',refcts($sub))."\n";
}

sub show105x {
  my $inter=Tcl->new();
  my $sub=sub{print '*';};
  %anon_refs=();
  print "105-start    ".join(' ',refcts($sub))."\n";
  {
    my $AV;
    for my $ii (1..4)
    {
      my $tclname="::perl::$sub";
      $AV=    $inter->CreateCommand($tclname, $sub, undef, undef, 1);
      print "105-AV       ".join(' ',refcts($sub))."\n";
      $anon_refs{rn}=bless ([\$sub],'Tcl::Code');
      print "105-anon{rn} ".join(' ',refcts($sub))."\n";
      $anon_refs{ar}=[$anon_refs{rn}];
      print "105-anon{ar} ".join(' ',refcts($sub))."\n";
      delete $anon_refs{rn};
      print "105-no rn    ".join(' ',refcts($sub))."\n";
      my $id = $inter->icall('after','1',$tclname);
      print  "105-stillar  ".join(' ',refcts($sub))."\n";
      delete $anon_refs{ar};
      print "105-no ar    ".join(' ',refcts($sub))."\n";
      }
     %anon_refs=();
     print  "105-stillav  ".join(' ',refcts($sub))."\n";
    }
  print     "105-postav   ".join(' ',refcts($sub))."\n";
}









sub show106 {
  my $sub=shift;
  %anon_refs=();
  print "105-start    ".join(' ',refcts($sub))."\n";
  {
    my $AV;
    my $AV2;
    {
      my %anon_refs;
      $anon_refs{me}=bless ([\$sub],'FakeTcl::Code');
      print "105-anon{me} ".join(' ',refcts($sub))."\n";
      $anon_refs{if}=$anon_refs{me};
      print "105-anon{if} ".join(' ',refcts($sub))."\n";
      $AV=[$sub,undef,0,1];
      print "105-AV       ".join(' ',refcts($sub))."\n";
      $AV2=$AV;
      print "105-AV2      ".join(' ',refcts($sub))."\n";
      $anon_refs{at}=[$anon_refs{if}];
      print "105-anon{at} ".join(' ',refcts($sub))."\n";
      }
     %anon_refs=();
     print  "105-preav    ".join(' ',refcts($sub))."\n";
    }
  print     "105-postav   ".join(' ',refcts($sub))."\n";
}

sub refcts {
# printf "SvREFCNT=%d refcount=%d\n",SvREFCNT( $_[0] ), refcount( $_[0]) ;
  return (SvREFCNT( $_[0] ), refcount( $_[0]));
}

sub flush_afters{
  my $inter=shift;
  while(1) {  # wait for afters to finish
    my $info0=insure_ptrarray($inter,'after', 'info');
    last unless (scalar(@$info0));
    $inter->icall('after', 1000, 'set var fafafa');
    $inter->icall('vwait', 'var'); # will wait for 1 seconds
  }
}

sub insure_ptrarray{
  my $inter=shift;
  my $list = $inter->icall(@_);
  if (ref($list) ne 'Tcl::List') {  # v1.02
      $list=[split(' ',$list)];
      }
return $list;
}

package FakeTcl::Code;
