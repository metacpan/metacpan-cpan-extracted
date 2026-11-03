# Run the test strings of shell-subset-tests.pl and shell-subset-corpus-tests.pl through Proc::ShellSubset::Large:
# lists the strings Proc::ShellSubset rejects and the large grammar accepts, and checks those with dash -n and bash -n.
use strict; use warnings; use FindBin; use lib "$FindBin::Bin/../../lib"; use Proc::ShellSubset; use Proc::ShellSubset::Large;
$ENV{HOME} //= '/root'; delete $ENV{CDPATH};
sub syn { my ($t, @sh) = @_; my $pid = fork // die;
  unless ($pid) { open STDERR, '>', '/dev/null'; open STDOUT, '>', '/dev/null'; exec @sh, '-n', '-c', $t; exit 127 }
  waitpid $pid, 0; $? == 0 }
my (%n, %why);
for my $f (@ARGV) { open my $h, '<', $f or die "$f: $!"; my $data;
  while (<$h>) { $data ||= /^__DATA__/; next unless $data && /^(ok|rej)\s+(\S+)\s+(\S+)\s+(.*)$/;
    my ($exp, $opt, $id, $s) = ($1, $2, $3, $4); $s =~ s/\@N/\n/g; $s =~ s/\@T/\t/g; $s =~ s/\@R/\r/g;
    my %o = map +($_ => 1), grep length && $_ ne '-', split /,/, $opt;
    my $small = Proc::ShellSubset::parse($s, %o, map +($_ => 1), qw(if while for case read assign param_ops));
    next if ref $small eq 'ARRAY' && !$o{brace};
    my $r = Proc::ShellSubset::Large::parse($s, %o);
    (my $show = $s) =~ s/\n/\\n/g;
    if (ref $r eq 'ARRAY') { $n{new}++;
      my @no = grep !syn($s, $_ eq 'bash' ? ('bash', '--posix') : $_), qw(dash bash);
      $n{bad}++ if @no; printf "%s %-24s %s\n", @no ? "!! @no rejects:" : '+', $id, $show }
    else { $n{rej}++; $why{$r->{error} =~ s/'[^']*'/'…'/r}++ } } }
printf "\n%d newly accepted (%d of them rejected by a shell), %d still rejected\n", map $_ // 0, @n{qw(new bad rej)};
printf "  %4d %s\n", $why{$_}, $_ for (sort { $why{$b} <=> $why{$a} } keys %why)[0 .. 14];
