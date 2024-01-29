# see how CODE REFs are created and then freed
#  this tests that the tracking of coderef users is correct
#
use Tcl;
use strict; use warnings;

print "1..9\n";

$| = 1;

  my $ct=0;
  my $inter=Tcl->new();

  my $sub2; $sub2=sub{ $ct++; };
  my $sub3; $sub3=sub{ $ct--; };
  my $sub2id='::perl::'.$sub2;
  my $sub3id='::perl::'.$sub3;

  my $ar=Tcl::_anon_refs_cheat ();

  $inter->call('if','1',$sub2,$sub3);

  ct_subs(1,2);
  check_users(2,'sub2',$sub2id,'=if 1'=>1);
  check_users(3,'sub3',$sub3id,'=if 1'=>1);

#use Data::Dumper; print Dumper($ar)."\n";

  $inter->call('if','1',$sub2,$sub3);
  ct_subs(4,2);
  check_users(5,'sub2',$sub2id,'=if 1'=>1);
  check_users(6,'sub3',$sub3id,'=if 1'=>1);

#use Data::Dumper; print Dumper($ar)."\n";

  $inter->call('if','2',$sub2,$sub2);
  ct_subs(7,2);
  check_users(8,'sub2',$sub2id,'=if 1'=>1,'=if 2'=>2);
  check_users(9,'sub3',$sub3id,'=if 1'=>1);

#use Data::Dumper; print Dumper($ar)."\n";

exit;
  $inter->call('after', '1000','if','1',$sub2,$sub2);
#use Data::Dumper; print Dumper($ar)."\n";
  flush_afters($inter);
#use Data::Dumper; print Dumper($ar)."\n";
exit;


sub flush_afters{
  my $inter=shift;
  while(1) {  # wait for afters to finish
    my @info0=$inter->icall('after', 'info');
    last unless (scalar(@info0));
    $inter->icall('after', 300, 'set var fafafa');
    $inter->icall('vwait', 'var'); # will wait for .3 seconds
  }
} # flush afters

sub ct_subs {
  my $test=shift;
  my $wanted=shift;
  my $nsubs=0;
  for my $sub (keys %$ar){
    next unless ($sub=~/^\:\:/);
    $nsubs++;
  }
  if ($wanted==$nsubs) { print "ok $test\n";}
  else {
   warn "should be $wanted commands in table but is $nsubs\n";
   print "not ok $test - subcount $wanted != $nsubs\n";
  }
} # ct_subs

sub check_users {
  my $test=shift;
  my $subname=shift;
  my $subid=shift;
  unless ($ar->{$subid}) {
    warn "sub $subname $subid not in table\n";
    print "not ok $test - sub $subname $subid not in table\n";
    return;
  }
  my $links=$ar->{$subid}[0][3];
  my %need=@_;
  my %users;
  my $ctu=0;
  for my $key(keys %{$ar->{$subid}[1]}){ $users{$key}=$ar->{$subid}[1]{$key}; $ctu=$ctu+$ar->{$subid}[1]{$key};}
  my @bad=();

  unless ($links==$ctu)      { push @bad,"link ct $links and userct $ctu dont match"; }
  for my $key (keys %need) {
    unless (defined ($users{$key}))      { push @bad,"user '$key' not found"; next; }
    unless ($users{$key} == $need{$key}) { push @bad,"userct for '$key' doesnt match";}
    delete $users{$key};
  }
  for my $key (keys %users) {
    push @bad,"extra user $key found";
  }
  unless (scalar(@bad)) { print "ok $test\n";}
  else {
   my $errors="for $subname ".join(', ',@bad);
   warn "$errors\n";
   print "not ok $test - $errors\n";
  }

} # check_users
