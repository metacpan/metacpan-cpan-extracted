#!/usr/bin/perl
# Group the corpus results into "very similar" classes and keep the shortest sample of each.
# Accepted: one-liners, and single lines of accepted script chunks that parse on their own;
#   class = skeleton of the parse tree (command names, literal words and repeated words abstracted).
# Rejected: class = error reason (builtin/keyword/variable names collapsed) + shape of the text at the error.
use strict; use warnings; use Proc::ShellSubset; use JSON::PP;   # run with perl -Ilib (the distribution's lib/)
$ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my %KEEP = map +($_ => 1), qw(: exit echo pwd time [ test true false printf kill exec);
my (%g, %n);

sub word { my $w = shift; return 'w' unless ref $w;   # coarse: the kinds of expansion in the word
  my %t = map +($$_[0] => 1), grep ref, @$w; join('', sort keys %t) || 'w' }
sub cmd { my $c = shift;
  my $r = join '', map { ($$_[0] == ($$_[1] =~ /^</ ? 0 : 1) ? '' : 'N') . $$_[1] . (ref $$_[2] || $$_[1] !~ /&/ ? word($$_[2]) : 'd') } @{$c->{redir} || []};
  return 'cd' if exists $c->{cd};
  return '(' . list($c->{sub}) . ")$r" if $c->{sub};
  return '{' . list($c->{group}) . "}$r" if $c->{group};
  my @a = @{$c->{argv}}; my $n = shift @a; $n = $KEEP{$n} ? $n : 'c';
  my %k = map +(word($_) => 1), @a; my @k = sort keys %k;   # coarse: the set of word kinds
  ($c->{exec} ? 'x:' : '') . ($c->{env} ? 'E ' : '') . join(' ', $n, @k) . ($r ? " $r" : '') }
sub uniq { my @o; for (@_) { if (@o && $o[-1] =~ /^\Q$_\E\+?$/) { $o[-1] = "$_+" } else { push @o, $_ } } @o }   # runs -> X+
sub list { join ' ; ', uniq map { my $a = $_; join ' ', map { ref eq 'ARRAY' ? pipe_($_) : $_ } @$a } @{$_[0]} }
sub pipe_ { join ' | ', uniq map { ref ? cmd($_) : '!' } @{$_[0]} }

sub feat {   # the set of features: operators, command kinds, word and redirection kinds
  my %f; my $s = list(shift);
  $f{$1}++ while $s =~ /(\|\||&&|[|;&!(){}]|\bcd\b|\bx:|\bE\b)/g;
  $f{"cmd:$1"}++ while $s =~ /(?:^|[|;&!({] |^\(|^\{)(\S+)/g;
  $f{"word:$1"}++ while $s =~ / ((?:"?\$\(?\(?|~|\*|\{\.?\.?)+)/g;
  $f{"redir:$1"}++ while $s =~ /((?:N)?(?:<>|>>|>\||<&|>&|<|>)\S*)/g;
  join ' ', sort keys %f }
sub shape { my ($t, $p) = @_; (my $s = substr $t, $p, 4) =~ s/[\s"'].*//s;   # the construct at the error
  $s =~ s/[A-Za-z_]+/a/g; $s =~ s/[0-9]+/9/g; $s }
sub reason { my $r = shift; $r =~ s/^(builtin|keyword|shell-set variable) '.*'/$1 */; $r =~ s/^'\w+\+='/'NAME+='/; $r }

sub add { my ($v, $sig, $t, $src, $id) = @_; $n{$v}++;
  my $g = $g{$v}{$sig} //= { n => 0, srcs => {} }; $g->{n}++; $g->{srcs}{$src}++;
  my $k = sub { my $x = shift; [ $x =~ /^[A-Za-z]/ && length $x >= 6 ? 0 : 1, length $x, $x ] };   # typical: a letter first, not tiny
  my ($p, $q) = ($k->($t), defined $g->{t} ? $k->($g->{t}) : undef);
  ($g->{t}, $g->{id}) = ($t, $id) if !$q || ($$p[0] <=> $$q[0] || $$p[1] <=> $$q[1] || $$p[2] cmp $$q[2]) < 0 }

open my $h, '<', 'results.jsonl' or die $!;
while (<$h>) { my $x = decode_json($_); (my $src = $x->{src}) =~ s/:.*//;
  my @t;   # [text, snippet ID]
  if ($x->{l}) { my ($pre, $l0) = $x->{l} =~ /^(.*):(\d+)$/; my @L = split /\n/, $x->{text};   # lines of a script chunk
    push @t, map [$L[$_], "$pre:" . ($l0 + $_) . ($x->{part} && $_ == $#L ? 'e' . length $L[$_] : '')],   # e: last column
      grep { $L[$_] =~ /\S/ && $L[$_] !~ /^\s*#/ } 0 .. $#L }
  else { @t = [$x->{text}, $x->{id}] }
  for (@t) { my ($t, $id) = @$_; $t =~ s/^\s+|\s+$//g; next unless length $t;
    my $r = Proc::ShellSubset::parse($t, caret => 0);
    if (ref $r eq 'ARRAY') { add(ok => feat($r), $t, $src, $id) }
    elsif (!$x->{l}) { my $e = reason($r->{error});   # (lines of accepted chunks that fail alone are skipped)
      add(rej => $e =~ /^(?:unsupported parameter|unquoted|missing word|unexpected|bash-only|no command name|'\$' starting)/
        ? "$e  @ " . shape($t, $r->{pos}) : $e, $t, $src, $id) } } }

binmode STDOUT, ':utf8';
open my $o, '>:utf8', 'groups.tsv' or die $!;
for my $v (qw(ok rej)) {
  for my $sig (sort { $g{$v}{$b}{n} <=> $g{$v}{$a}{n} || $a cmp $b } keys %{$g{$v}}) {
    my $g = $g{$v}{$sig}; print $o join("\t", $v, $g->{n}, join(',', sort keys %{$g->{srcs}}), $sig, $g->{id}, $g->{t} =~ s/\n/\@N/gr), "\n" } }
printf "%s: %d samples in %d groups\n", $_, $n{$_}, scalar keys %{$g{$_}} for qw(ok rej);
