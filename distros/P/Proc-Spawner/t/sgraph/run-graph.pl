#!/usr/bin/perl
# run-graph.pl FILE.sg ... -- runs hand-written spawn graphs (item N10; EXPERIMENTAL) with every
# program replaced by sgraph/reporter, and checks that each process got exactly the fds of its
# edges (fds 0-2 not among them: the parent's), and that each pipe it read carried the names of
# exactly the processes that write into it.  Our own fds 0-2 are /dev/null and two files.
use strict; use warnings;
use FindBin; use lib map "$FindBin::Bin/../../$_", 'lib', 'blib/arch';
use Proc::Spawner::Graph;
use JSON::PP;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);
use Scalar::Util qw(refaddr);

open my $out, '>&', \*STDOUT or die; select $out; $| = 1;
my ($bad, $all) = (0, 0);
for my $file (@ARGV) {
  my $g = Proc::Spawner::Graph::parse(do { open my $f, '<', $file or die "$file: $!\n"; local $/; <$f> });
  my $tmp = tempdir(CLEANUP => 1); my $here = getcwd;
  mkdir "$tmp/$_" for qw(bin work);
  symlink "$FindBin::Bin/reporter", "$tmp/bin/$_" for grep !-e "$tmp/bin/$_", map +(split ' ', $_->{argv})[0], @{$g->{procs}};
  local $ENV{REPORT_LOG} = "$tmp/log";
  chdir "$tmp/work" or die;
  open STDIN, '<', '/dev/null'; open STDOUT, '>', "$tmp/stdout"; open STDERR, '>', "$tmp/stderr";
  my %mine = map { my $d = fdesc($_); $d ? ($_ => $d) : () } 0 .. 2;
  my @all = @{$g->{procs}};   # run() drops processes from the graph once they no longer matter
  my $res = Proc::Spawner::Graph::run($g, bin => "$tmp/bin");
  open STDERR, '>&', $out; chdir $here;
  my %rep = map { my $r = decode_json($_); (join(' ', @{$r->{argv}}) => $r) } do { open my $l, '<', "$tmp/log" or die; <$l> };
  my %ino;   # pipe name <-> inode, which must be one to one
  my @procs = grep $_->{name} ne 'Perl', @all;
  my %writers;   # pipe name => names of the started processes writing into it
  for my $p (grep $_->{st} !~ /^(pending|never)/, @procs) {
    push @{$writers{$_->[2]{pipe}}}, (split ' ', $p->{argv})[0] for grep $_->[2]{kind} eq 'w', @{$p->{edges}} }
  print "== $file\n";
  for my $p (@procs) {
    my $r = $rep{$p->{argv}}; my @why;
    if ($p->{st} =~ /^(pending|never)/) { push @why, 'started, but should not have' if $r }
    elsif (!$r) { push @why, 'did not report' }
    else {
      my %exp = %mine;
      for (@{$p->{edges}}) { my ($fd, $op, $e) = @$_;
        $exp{$fd} = $e->{kind} eq 'parent' ? $mine{$e->{fd}}
                  : [$e->{kind} eq 'file' ? $e->{path} =~ m{^/} ? $e->{path} : "$tmp/work/$e->{path}" : "pipe $e->{pipe}", Proc::Spawner::Graph::op_of($e)] }
      for my $fd (sort { $a <=> $b } keys %{{ %exp, %{$r->{fds}} }}) {
        my ($x, $got) = ($exp{$fd}, $r->{fds}{$fd});
        next if $x && $got && same($x, $got, \%ino);
        push @why, "fd $fd: " . ($x ? "$x->[1] $x->[0]" : 'none') . ' wanted, ' . ($got ? "$got->[1] $got->[0]" : 'none') . ' got' }
      for (grep $_->[2]{kind} eq 'r', @{$p->{edges}}) {
        my $w = join ' ', sort @{$writers{$_->[2]{pipe}} // []}; my $got = join ' ', @{$r->{got}{$_->[0]} // []};
        push @why, "fd $_->[0] carried '$got', wanted '$w'" if $got ne $w } }
    $all++; $bad++ if @why;
    printf "%-4s %-28s %s\n", @why ? 'DIFF' : 'ok', $p->{argv},
      @why ? join('; ', @why) : $p->{st} =~ /^(pending|never)/ ? 'not started, as its condition says' : "exit $res->{$p->{name}}" }
  if (my $perl = $res->{Perl}) {
    for my $pipe (sort keys %$perl) {
      my ($got, $w) = (join(' ', sort split /\n/, $perl->{$pipe}), join ' ', sort @{$writers{$pipe} // []});
      $all++; $bad++ if $got ne $w;
      printf "%-4s %-28s read '%s' from pipe %s%s\n", $got eq $w ? 'ok' : 'DIFF', 'Perl', $got, $pipe, $got eq $w ? '' : ", wanted '$w'" } } }
print "\n", $all - $bad, " of $all processes as drawn\n";
exit !!$bad;

sub fdesc {   # [what fd N is, how it was opened] as reporter sees it
  my $n = shift; my $what = readlink "/proc/self/fd/$n" // return;
  open my $i, '<', "/proc/self/fdinfo/$n" or return;
  my ($f) = map /^flags:\s*([0-7]+)/ ? oct $1 : (), <$i>;
  [$what, (qw(< > <>))[$f & 3]] }
sub same {   # does fd $got (from a report) match the wanted [what, access]?  Binds pipes to inodes.
  my ($x, $got, $ino) = @_;
  return 0 if $x->[1] ne $got->[1];
  my ($name) = $x->[0] =~ /^pipe (.*)/ or return $x->[0] eq $got->[0];
  my ($i) = $got->[0] =~ /^pipe:\[(\d+)\]\z/ or return 0;
  ($ino->{"n$name"} //= $i) eq $i and ($ino->{"i$i"} //= $name) eq $name }
