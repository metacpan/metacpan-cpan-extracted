#!/usr/bin/perl -w
use strict;
use Parallel::MPI::Simple;

# Test basic functionality and blocking
MPI_Init();
my($rank,$size);
$rank = MPI_Comm_rank(MPI_COMM_WORLD);
$size = MPI_Comm_size(MPI_COMM_WORLD);

if ($rank ==0) {
  my $msg = "Hi ho the lillies grow\n";
  MPI_Send($msg,1,0,MPI_COMM_WORLD);
  $msg = MPI_Recv(1,0,MPI_COMM_WORLD);
  print $msg;

  print "ok 2 # MPI_Send MPI_Recv\n";
  MPI_Barrier(MPI_COMM_WORLD);
}
else {
  my $msg = MPI_Recv(0,0,MPI_COMM_WORLD);
  $msg =~ s/(Hi ho).*/ok 1/;
  MPI_Send($msg, 0,0,MPI_COMM_WORLD);

  MPI_Barrier(MPI_COMM_WORLD);
  print "ok 3 # MPI_Barrier\n";
}

# Test broadcast
MPI_Barrier(MPI_COMM_WORLD);
if ($rank ==0) {
  my $msg = 4;
  $msg = MPI_Bcast($msg, 0,MPI_COMM_WORLD);
}
else {
  my $msg = MPI_Bcast(undef, 0, MPI_COMM_WORLD);
  print "ok $msg # MPI_Bcast\n";
}

# Test gather
MPI_Barrier(MPI_COMM_WORLD);
if ($rank ==0) {
  my $msg = "ok 5 # MPI_Gather\n";
  print MPI_Gather($msg, 0, MPI_COMM_WORLD);
}
else {
  my $msg = "ok 6 # MPI_Gather\n";
  print MPI_Gather($msg, 0, MPI_COMM_WORLD); # shouldn't print anything.
}

# Test Scatter
MPI_Barrier(MPI_COMM_WORLD);
{
  my $rt = MPI_Scatter(["ok 7 # MPI_Scatter\n", "ok 8\n"],
			  0, MPI_COMM_WORLD);
  print $rt if $rank ==0;
  MPI_Barrier(MPI_COMM_WORLD);
  print $rt if $rank ==1;
}

# blessed reference
MPI_Barrier(MPI_COMM_WORLD);
{ print "ok 9 # Skipped - blessed references\n" if $rank ==0; last;
  my $obj = bless {cows=>"ok 9 # blessed ref\n"}, 'ZZZZZ::Testing';
  my $sobj;
  if ($rank == 0) {
    MPI_Send($obj, 1, 0, MPI_COMM_WORLD);
  }
  else {
    $sobj = MPI_Recv($obj, 0, 0, MPI_COMM_WORLD);
    print $sobj->method;
  }
}

# Test Allgather
MPI_Barrier(MPI_COMM_WORLD);
{
  my @rt = MPI_Allgather($rank, MPI_COMM_WORLD);
  if ($rank ==0) {
    print "ok ". ($rt[0]+10) . " # MPI_Allgather\n";
    print "ok ". ($rt[1]+10) . "\n";
    MPI_Barrier(MPI_COMM_WORLD);
  }
  else {
    MPI_Barrier(MPI_COMM_WORLD);
    print "ok ". ($rt[0]+12)."\n";
    print "ok ". ($rt[1]+12)."\n";
  }
}

# Test Alltoall
{
  MPI_Barrier(MPI_COMM_WORLD);
  my @data = (14+2*$rank, 15+2*$rank);
  my @return = MPI_Alltoall(\@data, MPI_COMM_WORLD);
  if ($rank == 0) {
    print "ok $return[0] # MPI_Alltoall\n"; # 14
    MPI_Barrier(MPI_COMM_WORLD);
    print "ok $return[1]\n";
    MPI_Barrier(MPI_COMM_WORLD);
  }
  else {
    MPI_Barrier(MPI_COMM_WORLD);
    print "ok $return[0]\n";
    MPI_Barrier(MPI_COMM_WORLD);
    print "ok $return[1]\n";
  }
}

# reduce
MPI_Barrier(MPI_COMM_WORLD);
{
  my $rt = MPI_Reduce($rank, sub {$_[0] + $_[1]}, MPI_COMM_WORLD);
  if ($rank == 0) {
    print "not " unless $rt == 1;
    print "ok 18 # reduce\n";
  }
  else {
    print "not " unless $rt == 1;
    print "ok 19 # reduce\n";
  }
}

MPI_Barrier(MPI_COMM_WORLD);
{ # MPI_Comm_compare
    if (MPI_Comm_compare(MPI_COMM_WORLD,MPI_COMM_WORLD) != MPI_IDENT) {
	print "not ";
    }
    print "ok 2$rank # Comm_compare (ident)\n";
}

{
    MPI_Barrier(MPI_COMM_WORLD);
    my $dup = MPI_Comm_dup(MPI_COMM_WORLD);
    if ($rank==0&&MPI_Comm_compare($dup, MPI_COMM_WORLD) != MPI_CONGRUENT) {
	print "not ";
    }
    print "ok 22 # comm_dup\n" if $rank ==0;
    MPI_Comm_free($dup);
}

{
    MPI_Barrier(MPI_COMM_WORLD);
    if ($rank ==0 ) {
	my $newcomm = MPI_Comm_split(MPI_COMM_WORLD, $rank, 0);
	if (MPI_Comm_compare($newcomm, MPI_COMM_WORLD) !=
	    MPI_UNEQUAL) {
	    print "not ";
	}
	print "ok 23 # MPI_Comm_split\n";
	MPI_Comm_free($newcomm);
    }
    else {
	my $rt=MPI_Comm_split(MPI_COMM_WORLD, MPI_UNDEFINED, 0);
	if (defined($rt)) {print "not "}
	print "ok 24 # MPI_Comm_split, not in new\n";
    }
}

MPI_Barrier(MPI_COMM_WORLD);
if ($rank == 0) {
    my $msg = "Sending from ANY";
    MPI_Send($msg,1,0,MPI_COMM_WORLD);
    print "ok 25 # sent from ANY\n";
}
else {
    my $msg = MPI_Recv(MPI_ANY_SOURCE,0,MPI_COMM_WORLD);
    if ($msg =~ /Sending from ANY/) {
	print "ok 26 # receive from ANY_SOURCE";
    }
    else {
	print "not ok 26 # receive from ANY_SOURCE";
    }
}

MPI_Finalize();
exit(0);

package ZZZZZ::Testing;
sub method {
  return $_[0]->{cows};
}

