# see how CODE REFs are created and then freed
#  this tests that coderefs are properly freed (for garbage collection)
#
# since the AV in the command table entry never gets freed
# in v1.02
#    it gains 1 for the PVCV in AV(newSVsv($sub),undef,ST(0),FLAGS) in the command table entry
#    and      1 for the PVCV in $anon_ref{'::perl::CODE...'}=$sub
#
# in v1.05
#    it gains 1 for the PVCV in AV(newSVsv($sub),undef,ST(0),FLAGS) in the command table entry
#

use Tcl;
use strict; use warnings;

  $| = 1;

  print "1..1\n";

  my $inter=Tcl->new();

  my @queue;
  my $sub;
  $sub=sub{
    return unless (scalar(@queue));
    my $line =shift @queue;
    return unless (scalar(@queue));
    $inter->call('after',300,$sub);
  };

  my @ctpre=refcts($sub);
  print '0 '.join(' ',@ctpre)."\n";

  my @ctpost;

  for my $run (1..9) {
    for my $ii (1..4) {push @queue,'ok '.$ii; }
    $inter->call('after',50,$sub);
    flush_afters($inter);
    if ($Tcl::VERSION eq '1.02') {
        # have to kinda cheat and do it by hand in 1.02
        # it didnt have code cleaup at all
        my $tclname='::perl::'.$sub;
        $inter->delete_ref($tclname);
        }
    @ctpost=refcts($sub);
    print "cycle:$run cts:".join(' ',@ctpost)."\n";
    }

  if ($ctpre[0]==$ctpost[0] && $ctpre[1]==$ctpost[1]) { print "ok 1 - refcts \n";}
  else {
   unless ($ctpre[0] == $ctpost[0]) { print STDERR "SvREFCNT $ctpre[0]!=$ctpost[0]\n"; }
   unless ($ctpre[1] == $ctpost[1]) { print STDERR "refcount $ctpre[1]!=$ctpost[1]\n"; }
   print "not ok 1 - refcts \n";
   }

  exit;

sub test_use {
 my $use=shift;
 my $useok=0;
 my $bad='';
 eval {
    $useok =eval $use.';1';
    unless ($useok) { $bad=$use; }
    };
 return $bad;
}


BEGIN {
  my $use_bad='';
  $use_bad.=test_use ('use Devel::Peek     qw( SvREFCNT Dump)');
  $use_bad.=test_use ('use Devel::Refcount qw( refcount )');
  if ($use_bad) {
    print "1..0 # skip because: not installed $use_bad \n";
    exit;
  };
}  # begin

sub refcts {
# printf "SvREFCNT=%d refcount=%d\n",SvREFCNT( $_[0] ), refcount( $_[0]) ;
  return (SvREFCNT( $_[0] ), refcount( $_[0]));
} # refcts

sub flush_afters{
  my $inter=shift;
  while(1) {  # wait for afters to finish
    my @info0=$inter->icall('after', 'info');
    last unless (scalar(@info0));
    $inter->icall('after', 300, 'set var fafafa');
    $inter->icall('vwait', 'var'); # will wait for .3 seconds
  }
} # flush afters

