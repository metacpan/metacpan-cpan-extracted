
use strict;
use warnings;
use Event qw(one_event loop unloop);
use Time::HiRes qw(time);
# use GraphViz::Data::Grapher;
use Data::Dump qw(dump);
use Digest::MD5;

`touch -t 198101010101 t/master/mfs1/1/var/mosix-ha/clstat`;
`touch -t 198201010101 t/master/mfs1/2/var/mosix-ha/clstat`;
`mkdir -p              t/master/mfs1/3`;
`mkdir -p              t/master/var/mosix-ha`;
`touch                 t/master/mfs1/1/var/mosix-ha/hactl`;
`rm -rf t/scratch; cp -rp t/master t/scratch`;
my %stomlist;

sub debug
{
  my $debug = $ENV{DEBUG} || 0;
  return unless $debug;
  my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
  my $subline = (caller(0))[2];
  my $msg = join(' ',@_);
  $msg.="\n" unless $msg =~ /\n$/;
  warn time()." $$ $subroutine,$subline: $msg" if $debug;
}

sub graph
{
  my $graph = GraphViz::Data::Grapher->new(@_);
  open(F,">t/graph.ps") || die $!;
  print F $graph->as_ps;
  close F;
  unless (fork())
  {
    system("gv t/graph.ps");
    exit;
  }
  warn dump @_;
}

sub run
{
  my $seconds=shift;
  Event->timer(at=>time() + $seconds,cb=>sub{unloop()});
  loop();
}

sub stomith
{
  my $node=shift;
  # warn "STOMITH $node";
  $stomlist{$node}=1;
}

sub stomck
{
  my $node=shift;
  # warn dump \%stomlist;
  return $stomlist{$node};
}

sub stomreset
{
  %stomlist=();
}

sub md5sum
{
  my $file=shift;
  open(F,"<$file") || die $!;
  my $ctx = Digest::MD5->new;
  $ctx->addfile(*F);
  my $sum = $ctx->hexdigest;
  return $sum;
}

sub waitdown
{
  while(1)
  {
    # my $count = `ps -eaf 2>/dev/null | grep perl | grep $0 | grep -v defunct | grep -v runtests | grep -v grep | wc -l`;
    my $count = `ps -eaf 2>/dev/null | grep $0 | grep 'Cluster::Init->daemon' | grep -v grep | wc -l`;
    chomp($count);
    # warn "$count still running";
    last if $count<1;
    run(1);
  }
}

sub waitgstat
{
  my ($ha,$group,$level,$state,$timeout,$any)=@_;
  $timeout||=40;
  my $start=time;
  my @node=($ha->{mynode});
  @node=$ha->nodes() if $any;
  WAIT: while(1)
  {
    my ($hastat) = $ha->hastat(@node);
    debug dump $hastat;
    for my $node (@node)
    {
      my $cklevel=$hastat->{$group}{$node}{level} || next;
      my $ckstate=$hastat->{$group}{$node}{state} || next;
      last WAIT if $level eq $cklevel && $state eq $ckstate;
    }
  }
  continue
  {
    my $line = (caller(0))[2];
    if ($start + $timeout < time)
    {
      warn "missed line $line $group (@node) $level $state\n";
      # my ($hastat) = $ha->hastat($ha->nodes());
      # warn dump $hastat;
      warn `cat $ha->{cltab}`;
      warn `cat $ha->{clstat}`;
      warn `cat $ha->{hactl}`;
      warn `cat $ha->{hastat}`;
      return 0;
    }
    run(1);
  }
  return 1;
}

sub waitline
{
  my ($line,$timeout)=@_;
  $timeout||=15;
  my $start=time;
  while(1)
  {
    open(F,"<t/out") || die $!;
    my @F=<F>;
    my $lastline=$F[$#F];
    unless ($lastline)
    {
      run(1);
      next;
    }
    chomp($lastline);
    last if $lastline eq $line;
    if ($start + $timeout < time)
    {
      warn "got $lastline wanted $line\n";
      return 0 
    }
    run(1);
  }
  return 1;
}

sub waitstat
{
  my ($init,$group,$level,$state,$timeout)=@_;
  $timeout||=10;
  my $start=time;
  while(1)
  {
    my $out = $init->status();
    debug $out if $out;
    last if $out =~ /^$group\s+$level\s+$state$/ms;
    # warn "missed";
    return 0 if $start + $timeout < time;
    run(1);
  }
  return 1;
}

sub waitgstop
{
  my ($ha,$group,$timeout,$any)=@_;
  $timeout||=40;
  my $start=time;
  my @node=($ha->{mynode});
  @node=$ha->nodes() if $any;
  my $hastat;
  while(1)
  {
    ($hastat) = $ha->hastat(@node);
    # warn dump $hastat;
    # warn dump $hastat;
    my $count=0;
    for my $node (@node)
    {
      # $count++ if $hastat->{$group}{$node} && $hastat->{$group}{$node}{level};
      $count++ if defined($hastat->{$group}{$node}{level});
      # warn " node: $node count: $count";
    }
    last unless $count;
  }
  continue
  {
    my $line = (caller(0))[2];
    if ($start + $timeout < time)
    {
      warn "missed line $line $group (@node) stop\n";
      # warn "$start ".time;
      # my ($hastat) = $ha->hastat($ha->nodes());
      # warn dump $hastat;
      # ($hastat) = $ha->hastat(@node);
      # warn dump $hastat;
      # ($hastat) = $ha->hastat($ha->nodes());
      warn dump $hastat;
      warn `cat $ha->{cltab}`;
      warn `cat $ha->{clstat}`;
      warn `cat $ha->{hactl}`;
      warn `cat $ha->{hastat}`;
      return 0;
    }
    run(1);
  }
  return 1;
}

1;
