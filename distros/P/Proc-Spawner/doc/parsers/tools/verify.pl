#!/usr/bin/perl
# Check parse trees against real shells: run each accepted group representative with dash and bash,
# with every external command replaced (through PATH) by a recorder that logs its argv.
# The expected log is computed from the tree: in the empty test directory and environment used,
# every parameter is unset, every command substitution prints nothing, and no pattern matches.
use strict; use warnings; use Proc::ShellSubset; use JSON::PP; use File::Temp 'tempdir';   # run with perl -Ilib (the distribution's lib/)
my $J = JSON::PP->new->canonical; my $HOME = '/nonexistent-home';
my %BUILTIN = map +($_ => 1), qw(echo printf test [ true false pwd kill : cd exit time);
my $D = tempdir(CLEANUP => 1); mkdir "$D/bin";
open my $r, '>', "$D/rec" or die; print $r <<'EOF'; close $r; chmod 0755, "$D/rec";
#!/usr/bin/perl
use JSON::PP; open my $f, '>>', $ENV{RECLOG} or die; (my $n = $0) =~ s{.*/}{};
print $f JSON::PP->new->canonical->encode([$n, @ARGV]), "\n";
EOF

my (@rec, $skip);   # expected records; reason to skip this sample
sub S { $skip //= shift; undef }
sub fields {   # Word -> list of fields, given empty expansions and no pattern matches
  my $w = shift; return $w unless ref $w;
  my ($t, $keep) = ('', 0);
  for my $p (@$w) {
    if (!ref $p) { $t .= $p; $keep = 1; next }
    my ($k, $v) = @$p;
    if ($k eq '~') { $t .= $v eq '' ? $HOME : (getpwnam $v)[7] // "~$v"; $keep = 1 }
    elsif ($k eq '*') { return S('pattern that may match outside the test directory') if "$t$v" =~ m{^/}; $t .= $v; $keep = 1 }
    elsif ($k =~ /\$\($/) { run_list($v, 1) }          # runs its commands; prints nothing
    elsif ($k =~ /\(\($/) { return S('arithmetic') }
    elsif ($k =~ /^\{/) { return S('brace') }
    elsif ($v eq 'HOME') { $t .= $HOME; $keep = 1 }     # the only parameter set
    else { $keep = 1 if $k =~ /^"/ } }                  # any other parameter: unset
  $keep ? $t : () }
sub run_cmd {   # returns status (undef: unknown)
  my $c = shift;
  for (@{$c->{redir} || []}) { my ($fd, $op, $t) = @$_;
    if ($op =~ /&/) { return S('dup of a closed descriptor') if $t =~ /^[3-9]$/; next }
    my @f = fields($t); return S('redirection target') if @f != 1;
    return S('input redirection') if $op =~ /</ && $f[0] ne '/dev/null';
    return S('target outside the test directory') if $f[0] =~ m{/|^\.\.?$} && $f[0] !~ m{^/dev/(null|stdout|stderr)$} }
  return run_list($c->{sub}, 1) if $c->{sub};
  return run_list($c->{group}, 0) if $c->{group};
  return S('cd') if exists $c->{cd};
  my @a = map fields($_), @{$c->{argv}}; fields($_) for grep ref, @{$c->{env} || []};
  return S('empty command') unless @a;
  my $n = $a[0];
  return S('command name with a slash') if $n =~ m{/};
  return S('pwd prints the directory') if $n eq 'pwd';
  if ($BUILTIN{$n} && !$c->{exec}) {
    return S('kill') if $n eq 'kill'; return S('time keyword in bash') if $n eq 'time';
    return die "EXIT\n" if $n eq 'exit';
    return $n eq 'false' ? 1 : $n =~ /^(?:test|\[)$/ ? undef : 0 }
  push @rec, \@a; 0 }
sub run_list {   # $scope: a new shell (subshell, $(), pipeline element, background chain)
  my ($l, $scope) = @_; my $st = 0;
  my $ok = eval {
    for my $ch (@$l) {
      my @c = @$ch; my $bg = $c[-1] eq '&' ? pop @c : 0;
      my $run = sub { my $s = run_pipe(shift @c);
        while (@c) { my ($op, $p) = splice @c, 0, 2;
          return S('status of [ or test decides') if !defined $s;
          $s = run_pipe($p) if ($op eq '&&') == ($s == 0) }
        $s };
      if ($bg) { my $e = eval { $run->(); 1 }; die $@ if !$e && $@ ne "EXIT\n"; $st = 0 } else { $st = $run->() } }
    1 };
  if (!$ok) { die $@ unless $@ eq "EXIT\n"; die "EXIT\n" unless $scope; $st = 0 }
  $st }
sub run_pipe {
  my $p = shift; my @c = @$p; my $neg = $c[0] eq '!' ? shift @c : 0;
  my $s; if (@c > 1) { for (@c) { my $x = eval { run_cmd($_) }; die $@ if $@ && $@ ne "EXIT\n"; $s = $x } }
  else { $s = run_cmd($c[0]) }
  return undef unless defined $s; $neg ? !$s + 0 : $s }

sub shell_run {   # run $t with $sh in a fresh directory; return the sorted records
  my ($sh, $t, $names) = @_;
  my $w = tempdir(DIR => $D); unlink glob "$D/bin/*"; symlink "$D/rec", "$D/bin/$_" for keys %$names;
  local $ENV{RECLOG} = "$w.log"; unlink "$w.log";
  my $pid = fork // die; if (!$pid) { chdir $w; open STDIN, '<', '/dev/null'; open STDOUT, '>', '/dev/null'; open STDERR, '>', '/dev/null';
    exec '/usr/bin/env', '-i', "PATH=$D/bin", "HOME=$HOME", "RECLOG=$w.log", '/usr/bin/timeout', '5', "/usr/bin/$sh", '-c', $t }   # PATH: only the recorder
  waitpid $pid, 0; select undef, undef, undef, 0.15;
  open my $f, '<', "$w.log" or return []; [ sort map { chomp; $_ } <$f> ] }

my (%res, @bad);
open my $g, '<', 'groups.tsv' or die;
while (<$g>) { chomp; my ($v, $n, $srcs, $sig, $id, $t) = split /\t/; next unless $v eq 'ok';
  $t =~ s/\@N/\n/g; @rec = (); $skip = undef;
  if ($t =~ /^-/) { $res{"skipped: string starts with - (read as an option by sh -c)"}++; next }
  my $tree = Proc::ShellSubset::parse($t, caret => 1);
  my $e = eval { run_list($tree, 0); 1 }; die $@ if !$e && $@ ne "EXIT\n";
  if ($skip) { $res{"skipped: $skip"}++; next }
  my %names = map +($$_[0] => 1), @rec;
  my $exp = [ sort map $J->encode($_), @rec ];
  for my $sh (qw(dash bash)) {
    my $got = shell_run($sh, $t, \%names);
    if ("@$got" eq "@$exp") { $res{"$sh: same"}++ } else { $res{"$sh: DIFFERENT"}++; push @bad, [$sh, $t, $exp, $got] } } }
printf "%-40s %d\n", $_, $res{$_} for sort keys %res;
for (@bad) { my ($sh, $t, $e, $g) = @$_; print "\n--- $sh: $t\n  expected: @$e\n  got:      @$g\n" }
