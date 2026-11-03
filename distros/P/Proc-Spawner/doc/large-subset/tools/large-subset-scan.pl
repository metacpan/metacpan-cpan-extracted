#!/usr/bin/perl
# large-subset-scan.pl (version of 2026-11-02; see doc/large-subset/large-subset-ceiling.md). For each unique sample of
# samples.jsonl (from large-subset-extract.pl; the make book is skipped): does Proc::ShellSubset (all options) accept it,
# does Proc::ShellSubset::Large; do dash -n, bash --posix -n and bash -n accept it; which bash-only constructs three
# independent detectors see in it:
#   sc: ShellCheck (shellcheck-py 0.11.0.1, `shellcheck -s dash`): its portability warnings SC3xxx;
#   rx: a regex scan (the scan of 2026-11-01, fixed: quoted text blanked first, more forms, fewer false hits);
#   pm: our own parser's messages that name bash.
# Usage: perl -Ilib large-subset-scan.pl [samples.jsonl] > large-scan.jsonl   (shellcheck in PATH)
use strict; use warnings; use Proc::ShellSubset; use Proc::ShellSubset::Large; use JSON::PP; use File::Temp 'tempdir';
my $J = JSON::PP->new->canonical; $ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my %OPT = map +($_ => 1), qw(assign param_ops if while for case read empty);
sub syn { my ($t, @sh) = @_; my $pid = fork // die;
  unless ($pid) { open STDERR, '>', '/dev/null'; open STDOUT, '>', '/dev/null'; exec @sh, '-n', '-c', $t; exit 127 }
  waitpid $pid, 0; $? == 0 }

# Quoted text blanked, quotes kept: $q1 has '...' (and $'...') blanked, $q2 also "..." (but not the $( ) in it)
sub blank { my $t = shift; my ($q1, $q2) = ('', '');
  while ($t =~ /\G(?: (\$?'[^']*'?) | (\\.) | (") | ([^'"\\]+) )/gcsx) {
    if (defined $1) { (my $b = $1) =~ s/(?<=.)[^'\n]/ /g; $q1 .= $b; $q2 .= $b }   # keeps a leading $ of $'...'
    elsif (defined $2) { $q1 .= $2; $q2 .= '  ' }
    elsif (defined $3) { $q1 .= '"'; $q2 .= '"';   # a double-quoted string: keep $( ), ${ }, $(( )) for q2 too
      while ($t =~ /\G(?: (?<e>\\.) | (?<c>") | (?<x>\$\((?<pp>(?:[^()]++|\((?&pp)\))*)\)|\$\{[^}]*\}) | (?<l>[^"\\\$]+|\$) )/gcsx) {
        if (defined $+{e}) { $q1 .= $+{e}; $q2 .= '  ' } elsif (defined $+{c}) { $q1 .= '"'; $q2 .= '"'; last }
        elsif (defined $+{x}) { $q1 .= $+{x}; $q2 .= $+{x} } else { my $l = $+{l}; $q1 .= $l; $l =~ s/[^\n]/ /g; $q2 .= $l } } }
    else { $q1 .= $4; $q2 .= $4 } }
  ($q1, $q2) }
my $C = qr/(?:^|[;&|(){}\n]|\b(?:then|do|else|elif|if|while|until)\b|!)[ \t]*/m;   # command position, roughly
sub cmd { my $w = join '|', map quotemeta, @_; qr/$C(?:\w+=\S*[ \t]+)*(?:$w)(?=[ \t;\n&|)]|$)/m }
sub opt { my ($c, $o) = @_; qr/(?:${\cmd($c)})[ \t]+(?:\S+[ \t]+)*?$o/m }
my @F = (   # [name, view (1: '...' blanked, 2: also "..." blanked), regex]
  [dbracket  => 2 => cmd('[[')],
  [dparen    => 2 => qr/$C(?:for[ \t]*)?\(\(/],
  [ansi      => 2 => qr/\$'/],
  [locale    => 2 => qr/\$"/],
  [dollar_br => 1 => qr/\$\[/],
  [procsub   => 2 => qr/[<>]\(/],
  [herestr   => 2 => qr/<<</],
  [array     => 2 => qr/(?:^|[\s;&|(])\w+=\(|\$\{\w+\[|(?:^|[\s;&|(])\w+\[[^\]\s]*\]=|\$\{#\w+\[/],
  [param_bash=> 1 => qr/\$\{(?:!|(?:[A-Za-z_]\w*|[*@])(?:\/|:[ \d]|\^|,|@[A-Za-z]))/],
  [arith_inc => 1 => qr/(?:\$\(\(|\(\()[^)]*(?:\+\+|--)/],
  [plus_eq   => 2 => qr/(?:^|[\s;&|(])[A-Za-z_]\w*\+=/m],
  [function  => 2 => qr/$C function[ \t]+\w/x],
  [bash_bi   => 2 => cmd(qw(declare typeset let shopt pushd popd dirs mapfile readarray select coproc caller compgen complete
                            compopt bind source enable builtin disown suspend logout help history))],
  [brace     => 2 => qr/(?<!\$)\{[^{}\s'"]*,[^{}\s'"]*\}|\{-?\w+\.\.-?\w+\}/],
  [fd_var    => 2 => qr/\{[A-Za-z_]\w*\}[<>]/],
  [amp_redir => 2 => qr/&>|\|&|>&[ \t]*[^\s\d\$&-]/],
  [cmd_file  => 1 => qr/\$\([ \t]*</],
  [bash_var  => 1 => qr/\$\{?(?:RANDOM|BASH\w*|SECONDS|PIPESTATUS|EUID|UID|FUNCNAME|EPOCH\w+|HOSTTYPE|OSTYPE)\b/],
  [echo_e    => 2 => opt('echo', '-[neE]*[eE]\b')],
  [read_opt  => 2 => opt('read', '-\w*[apnstdui]')],
  [trap_sig  => 2 => qr/(?:${\cmd('trap')})[^\n;|&]*\b(?:ERR|DEBUG|RETURN|SIG[A-Z]+)\b|(?:${\cmd('trap')})[ \t]+-[lp]/],
  [bi_option => 2 => qr/${\opt('export', '-\w*[fn]')}|${\opt('wait', '-[np]')}|${\opt('local', '-\w')}|${\opt('exec', '-[ac]')}
    |${\opt('hash', '-[lpdt]')}|${\opt('jobs', '-[snrx]')}|${\opt('umask', '-p')}|${\opt('readonly', '-[aAf]')}
    |${\opt('unset', '-n')}|${\opt('cd', '-e')}|${\opt('type', '-[aftpP]')}|(?:${\cmd('set')})[ \t]+[-+]o[ \t]+(?!(?:allexport|errexit|ignoreeof|monitor|noclobber|noglob|noexec|notify|nounset|verbose|xtrace|nolog)\b)\w/x],
  [pipefail  => 2 => qr/pipefail/],
);

# ShellCheck over all samples in batches: file name -> [SC codes]
sub shellcheck { my @t = @_; my $d = tempdir(CLEANUP => 1); my %c;
  for my $i (0 .. $#t) { open my $f, '>', "$d/$i.sh" or die; print $f $t[$i]; close $f }
  for (my $i = 0; $i < @t; $i += 500) { my $j = $i + 499 > $#t ? $#t : $i + 499;
    open my $p, '-|', 'shellcheck', '-s', 'dash', '-f', 'json1', '-S', 'style', map "$d/$_.sh", $i .. $j or die;
    my $out = do { local $/; <$p> }; close $p;
    for (@{ decode_json($out)->{comments} }) { my ($n) = $_->{file} =~ m{/(\d+)\.sh\z}; push @{$c{$n}}, "SC$_->{code}" } }
  map [sort { $a cmp $b } @{$c{$_} // []}], 0 .. $#t }

sub rx { my ($s) = @_; $s =~ s/^[ \t]*#.*//mg; my @v = (undef, blank($s)); map $$_[0], grep $v[$$_[1]] =~ $$_[2], @F }
if (@ARGV && $ARGV[0] eq '--rx') { shift; printf "%-40s %s\n", $_, join ',', rx($_) for @ARGV; exit }   # try the regexes
my (%seen, @S);
open my $in, '<', shift // 'samples.jsonl' or die;
while (<$in>) { my $h = decode_json $_; next if $h->{src} eq 'makebook' or $seen{"$h->{src}\0$h->{text}"}++; push @S, $h }
splice @S, 0, $ENV{SKIP} // 0;   # SKIP=N: resume after N samples (append to the earlier output)
my @sc = shellcheck(map $_->{text}, @S);
for my $i (0 .. $#S) { my $h = $S[$i]; my $t = $h->{text};
  (my $s = $t) =~ s/^[ \t]*#.*//mg; my @v = (undef, blank($s));
  my $lg = Proc::ShellSubset::Large::parse($t, empty => 1); my $cur = Proc::ShellSubset::parse($t, %OPT);
  my $why = ref $lg eq 'HASH' ? $lg->{error} : '';
  print $J->encode({ src => $h->{src}, kind => $h->{kind}, tag => $h->{tag} // '', id => $h->{id},
    cur => ref $cur eq 'ARRAY' ? 1 : 0, large => ref $lg eq 'ARRAY' ? 1 : 0, why => $why,
    dash => syn($t, 'dash') ? 1 : 0, bash => syn($t, 'bash', '--posix') ? 1 : 0, bashx => syn($t, 'bash') ? 1 : 0,
    sc => [grep /^SC3/, @{$sc[$i]}], scparse => (grep /^SC1/, @{$sc[$i]}) ? 1 : 0,
    rx => [map $$_[0], grep $v[$$_[1]] =~ $$_[2], @F], pm => $why =~ /bash/ ? 1 : 0,
    lines => scalar(grep /\S/ && !/^\s*#/, split /\n/, $t) }), "\n" }
