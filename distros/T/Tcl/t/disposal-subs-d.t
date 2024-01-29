# see how CODE REFs are created and then freed
#  this tests exterior creation and deletion works
#
use Tcl;
use strict; use warnings;

$| = 1;

my $anon_refs_cheat={};
$anon_refs_cheat=Tcl::_anon_refs_cheat() if (defined (&Tcl::_anon_refs_cheat)) ;

print "1..1\n";

  my $inter=Tcl->new();

  my $precmd=[$inter->icall('info', 'commands', '::perl::*')];

  my $ct1=0;
  my $sub1=sub{ $ct1++; } ;
  my $tclname=$inter->create_tcl_sub($sub1,undef,undef,'test hand 1');

    $inter->call('if','1',$tclname);
    $inter->call('after', 1000, $tclname);
    $inter->call('after', 2100, $tclname);
    $inter->call('after', 3100, $tclname);
    $inter->icall($tclname);
    $inter->icall('if','1',$tclname);

    flush_afters($inter);

    $inter->call('if','1',$tclname);

  my ($newct1)=newcmds($precmd);

# on v1.02 this works
# on v1.05 this has nothing at $anon_refs{$tclname} to delete
# on v1.06-weakend this still leaves the $anon_refs{$rname} entry so the code still lives

  if (defined (&Tcl::delete_ref)) {  $inter->delete_ref($tclname); } else {Tcl::_code_dispose($tclname); }

  my ($newct2)=newcmds($precmd);

  if ($ct1==7 && $newct1==1 && $newct2==0) {     print "ok 1 cmd counts\n"; }
    else {
      print STDERR "byhand code disposal ct1 $ct1 newct1 $newct1 newct2 $newct2 should be 7,1,0\n";
      print "not ok 1 cmd counts\n";
      }

  exit;

sub newcmds {
  my $precmd=shift;
  my $print=shift;
  my $postcmd =[$inter->icall('info', 'commands', '::perl::*')];
  my %start;
  my $newct=0;
  my @newcmds;
  for my $cmd (@$precmd)  { $start{$cmd}=1; }
  for my $cmd (@$postcmd) { unless ($start{$cmd}) {print $cmd."\n" if ($print); $newct++; push @newcmds,$cmd;}  }
  dump_refs() if ($print);
  return $newct,\@newcmds;
} # newcmds


sub dump_refs {
  for my $kk (keys %$anon_refs_cheat) {
    print ref($anon_refs_cheat->{$kk}).' '.$kk."\n";
  }
}  # dump_refs


sub flush_afters{
  my $inter=shift;
  while(1) {  # wait for afters to finish
    my @info0=$inter->icall('after', 'info');
    last unless (scalar(@info0));
    $inter->icall('after', 300, 'set var fafafa');
    $inter->icall('vwait', 'var'); # will wait for .3 seconds
  }
} # flush afters

