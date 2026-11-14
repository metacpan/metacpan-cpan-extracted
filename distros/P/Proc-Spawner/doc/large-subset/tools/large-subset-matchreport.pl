#!/usr/bin/perl
# large-subset-matchreport.pl (X27; post-0.11, 2026-11-10): the match of dash, bash --posix and ours across the
# environments a sample ran in, beside the snippet's own level.  Two axes (the user, 2026-11-10):
#   the snippet: its level from the text alone (large-subset-provenance.tsv: strict, held, almost strict, undecided), and
#     partially decided: an undecided snippet whose every dependence was named exactly and tried in example
#     environments (step 2: the samples of large-subset-env-setups.tsv);
#   the match, over the environments it ran in (the base run; for the samples with setups also those, and, since
#     2026-11-13, step 3's: each family's base run and its setups, -run FAMILY/LABEL=DIR; a sample counts once, in the
#     box its classes over all of them give, as with one family):
#     shells  agree (dash and bash agree beyond the messages in every environment), some (in some), differ (in none),
#             timeout (a shell ran out of time in every one);
#     ours    where they agree: as them, or differs; where they differ: with dash, with bash, with neither, or mixed;
#     why     for every environment where ours is not as both shells: a rule from KNOWN, else A4 (ours ended with status 248
#             and its message that a form outside the subset showed up at run time; post-0.11), else A5 (ours as dash where
#             the shells differ at run time), else messages on standard output, else a rule by the snippet's own codes
#             (interactive: B2; start: $0), else builtin-vs-coreutils (-calls, -q: in that environment ours runs
#             echo, printf, test, [, kill or pwd, which ours does as coreutils, with arguments for which the
#             coreutils program answers otherwise than the builtin of each shell ours differs from, in status or
#             output, and ours alone answers as the program; post-0.11), else chance by the snippet's own codes
#             (pid, time, random, race, path-proc, path-root, listing: not repeatable; a guess from the text, so
#             after the check), else none: why is yes, proposed (by a rule not decided yet), chance (not
#             repeatable), open (a known difference in TODO), or no;
#     stable  base and base2 (a second run of the same environment) in the same class, or unstable.
# Messages are not counted (a difference in wording only is agreement), as in large-subset-runreport.pl's classes; and
# (post-0.11) not on standard output or in files either: lines starting with a shell's message prefix are dropped from
# standard output, and files compare by their hash without such lines (files_nomsg; runs since post-0.11); -raw: as before.
#
# Usage: perl large-subset-matchreport.pl -prov large-subset-provenance.tsv [-setups PREFIX-samples.tsv]
#        [-known large-subset-match-known.tsv] [-o MATCH.tsv] [-record large-subset-env-setups.tsv]
#        [-calls THREEWAY-DB.jsonl -q LABEL=QDIR ...] [-raw] -run LABEL=DIR ...
#   LABEL: base, base2, s1, s2, ... (the environments); DIR: large-subset-runcompare.pl's OUTDIR.  A later -run of the
#   same label replaces an earlier one's results sample by sample (a full run first, then the step-2 runs).
#   -setups [FAMILY=]FILE: large-subset-setups.pl's list of the samples it gave setups, their dependences and what each
#   setup did; without FAMILY, those of the labels s1, s2, ... (step 2); with it, of FAMILY/s1, ... (step 3, post-0.11,
#   2026-11-13: -setups control=... -run control/base=... -run control/s1=...).  A sample's environments: base, s1, ...,
#   then each family's base, s1, ... (FAMILY/base2: that family's second base run, for stable only).  The partially
#   decided: the undecided (U in the provenance) with setups of any family.  -record: writes the step-2 record
#   (large-subset-env-setups.tsv) of the samples of the setups without FAMILY, from base and s1, ... alone.
#   -step3 [-class affects-shell]: the record is step 3's (large-subset-env-control.tsv: the class control, the default;
#   large-subset-env-affects-shell.tsv), with its own header lines first.
#   -ai large-subset-ai-classes.tsv (2026-11-13): the samples classified by reading count in the level table as N+M=T
#   (found by the programs + classified by reading = all): AI-strict in strict, AI-values passed on unchanged and on split
#   in those rows; the others of them stay undecided, all classified by reading.
#   -q LABEL=QDIR (LABEL as for -run): the logging run (large-subset-runcompare.pl -q) of that environment, for its calls of echo, printf,
#   test, [, kill, pwd; -calls: large-subset-threeway.pl -db over those runs, each call's answers by dash's builtin,
#   bash's builtin and the program.  Without them builtin-vs-coreutils is never found.
use strict; use warnings; use JSON::PP; use Getopt::Long; binmode STDOUT, ':utf8';
sub records {   # (post-0.11) a log's records: one per line, but an argument or a variable may hold a newline; a record
  my ($t, $start) = @_; my @r;   # starts as $start says, a line that does not continues the record before it
  for (split /\n/, $t // '') { if (/$start/ || !@r) { push @r, $_ } else { $r[-1] .= "\n$_" } } @r }
my ($PROV, @SETUPS, $KNOWN, $OUT, $RECOUT, @RUNS, $CALLS, @QRUNS, $RAW, $STEP3, $CLASS, $AIF);
GetOptions('prov=s' => \$PROV, 'setups=s' => \@SETUPS, 'known=s' => \$KNOWN, 'o=s' => \$OUT, 'record=s' => \$RECOUT, 'run=s' => \@RUNS, 'calls=s' => \$CALLS, 'q=s' => \@QRUNS, 'raw' => \$RAW, 'step3' => \$STEP3, 'class=s' => \$CLASS, 'ai=s' => \$AIF)
  && $PROV && @RUNS or die "usage: $0 -prov PROVENANCE.tsv [-setups SAMPLES.tsv] [-known KNOWN.tsv] [-o MATCH.tsv] [-record OUT.tsv] -run LABEL=DIR ...\n";

# The classes, as large-subset-runreport.pl computes them (its norm and classify, copied).
my @P = qw(status out rec files);
my %PFX = (dash => qr/(?:\S*\/)?dash: \d+: /, bash => qr/(?:\S*\/)?bash: (?:line \d+: )?/, ours => qr/(?:^|(?<=\n))sh: /);
my $MSGLINE = qr/^(?:(?:\S*\/)?dash: \d+: |(?:\S*\/)?bash: (?:line \d+: )?|sh: ).*(?:\n|\z)/m;   # as large-subset-runcompare.pl
sub norm { my ($r, $sh) = @_; my %n = %$r; $n{err} =~ s/$PFX{$sh}//g;
  unless ($RAW) { $n{out} =~ s/$MSGLINE//g; $n{files} = $r->{files_nomsg} if defined $r->{files_nomsg} }   # messages count nowhere
  $n{err} = join '', sort split //, $n{err} =~ s/\n//gr;
  $n{rec} = join "\n", sort split /\n/, $n{rec} =~ s/\n\z//r, -1; \%n }   # (empty lines kept: an argument's newline makes one)
sub classify { my $s = shift; my ($d, $b, $o) = map norm($s->{$_}, $_), qw(dash bash ours);
  my $diff = sub { my ($x, $y) = @_; grep $x->{$_} ne $y->{$_}, @P };
  return 'timeout' if grep { $_->{status} =~ /^(?:124|137)\z/ } $d, $b, $o;
  if (!$diff->($d, $b) && !$diff->($d, $o)) { return $d->{err} eq $b->{err} && $d->{err} eq $o->{err} ? 'same'
    : $o->{err} eq $d->{err} ? 'msg=dash' : $o->{err} eq $b->{err} ? 'msg=bash' : 'msg-own' }
  return 'OURS' if !$diff->($d, $b);
  !$diff->($o, $d) ? '=dash' : !$diff->($o, $b) ? '=bash' : 'neither' }
sub classify_out { my $s = shift;   # as classify, with each shell's prefix also taken off standard output (2>&1, messages)
  my %t = map { my $sh = $_; ($sh => { %{$s->{$sh}}, out => ($s->{$sh}{out} // '') =~ s/$PFX{$sh}//gr }) } qw(dash bash ours);
  classify(\%t) }

my %LV;   # id => S, H, A, U (the provenance), P (partially decided)
my %CODE;   # id => its code in the provenance (the undecided codes, for the rules by code below)
{ open my $in, '<', $PROV or die "$PROV: $!"; while (<$in>) { next if /^#/; chomp; my ($id, $code) = split /\t/; $LV{$id} = substr $code, 0, 1; $CODE{$id} = $code } }
sub by_code { my $id = shift; my ($u) = ($CODE{$id} // '') =~ /^U:([^\/]*)/;   # (2026-11-13: also the codes inside passthrough(...),
  ($u) = ($CODE{$id} // '') =~ /^A:.*passthrough\(([^)]*)\)/ unless defined $u; defined $u or return undef;   # since step 3)
  my %u = map +($_ => 1), split /,/, $u;   # rules by
  return 'B2: interactive builtins (history, fc, bind, help, compopt, logout) do nothing here' if $u{interactive};   # the snippet's
  return '$0: each shell has its own name (how the shell is started; code start)' if $u{start};                     # own codes
  my @ch = grep $u{$_}, qw(pid time random race path-proc path-root listing);
  return "chance: the result is not repeatable (code @ch)" if @ch; undef }
sub code_or_bvc { my ($id, $bvc) = @_; my $r = by_code($id);   # chance by the codes is only a guess from the text:
  defined $r && $r !~ /^chance:/ ? $r : $bvc // $r }             # a checked builtin-vs-coreutils goes before it
my (%DEP, %DEPS, %DOES, %BLK);   # id => its dependences' keys (dep:CODE, dep:CODE:KIND:NAME), of every family; and by family
for my $sf (@SETUPS) { my ($fam, $file) = $sf =~ /^([\w-]+)=(.+)\z/ ? ($1, $2) : ('', $sf);   # (''): as written; what setup K did
  open my $in, '<:utf8', $file or die "$file: $!"; while (<$in>) { next if /^#/; chomp; my ($id, $blk, $deps, @does) = split /\t/, $_, -1;
    next unless $LV{$id}; $LV{$id} = 'P' if $LV{$id} eq 'U'; $DEPS{$fam}{$id} = $deps; $DOES{$fam}{$id} = \@does; $BLK{$fam}{$id} = $blk;
    my %h = map +($_ => 1), @{$DEP{$id} // []};
    $DEP{$id} = [keys %h, grep !$h{$_}++, map { my @d = split /:/, $_, 3; ("dep:$d[0]", "dep:" . join ':', @d) } split / (?=\w[\w-]*:)/, $deps] } }
my (%KN, @KDOES);   # "WHO\tENV" => rule; WHO a sample id, or dep:CODE or dep:CODE:KIND:NAME (every sample with that
  # dependence); ENV a label or * (a FAMILY/LABEL environment takes the rows of FAMILY/LABEL, then of LABEL).  WHO does:REGEX: every setup whose description (what it did) matches.  A rule whose
  # name ends in "(proposed)" makes why proposed (a rule not decided yet).
if ($KNOWN) { open my $in, '<:utf8', $KNOWN or die "$KNOWN: $!"; while (<$in>) { next if /^#/ || !/\S/; chomp; my ($who, $env, $rule) = split /\t/;
    if ($who =~ /^does:(.*)/s) { push @KDOES, [qr/$1/, $rule] } else { $KN{"$who\t$env"} = $rule } } }
sub known { my ($id, $env) = @_;   # the rule for this sample in this environment, if KNOWN has one
  my ($fam, $lab) = $env =~ m{^([\w-]+)/(.+)\z} ? ($1, $2) : ('', $env);
  for my $w ($id, @{$DEP{$id} // []}) { for my $e (grep(defined, $env, $fam ne '' ? $lab : undef), '*') { my $r = $KN{"$w\t$e"}; 
      next if defined $r && !$RAW && $r =~ /^(?:A5, and )?messages/;   # rules for messages: only for -raw (else compensated)
      return $r if defined $r } }
  my ($k) = $lab =~ /^s(\d+)\z/ or return undef; my $d = $DOES{$fam}{$id} && $DOES{$fam}{$id}[$k - 1] // return undef;
  for (@KDOES) { return $_->[1] if $d =~ $_->[0] } undef }
my (%C, %TXT, %MSGOUT, %A4);   # (%A4: id => label => ours ended as A4 decides) id => label => class; id => text; id => label => the class with messages off stdout, if other
for my $r (@RUNS) { my ($label, $dir) = $r =~ m{^([\w-]+(?:/[\w-]+)?)=(.+)\z} or die "-run $r: LABEL=DIR\n";
  my @f = glob "$dir/run-*.jsonl" or die "-run $r: no run-*.jsonl\n";
  for my $f (@f) { open my $in, '<', $f or die; while (<$in>) { my $s = eval { decode_json($_) } or next; next unless $s->{dash} && $s->{bash} && $s->{ours};
    my $cl = classify($s); $C{$s->{id}}{$label} = $cl; $TXT{$s->{id}} //= $s->{text};
    $A4{$s->{id}}{$label} = 1 if ($s->{ours}{status} // '') eq '248' && ($s->{ours}{err} // '') =~ /^Proc::ShellSubset::Large: .* is not supported$/m;   # (post-0.11)
    if ($cl =~ /^(?:OURS|=bash|neither)\z/) { my $c2 = classify_out($s); $MSGOUT{$s->{id}}{$label} = $c2 if $c2 ne $cl } } } }

# builtin-vs-coreutils: each call's answers (status and output) by dash's builtin, bash's builtin and the program; the
# calls ours made, per sample and environment (as large-subset-threeway.pl collects them: made by our shell itself).
my (%ANS, %QC); my %TOOL = map +($_ => 1), qw(echo printf test [ kill pwd);
if ($CALLS) { open my $in, '<', $CALLS or die "$CALLS: $!"; while (<$in>) { my $r = decode_json($_);
    $ANS{join "\037", @{$r->{call}}} = { map +($_ => "$r->{$_}{status}\0$r->{$_}{out}"), grep $r->{$_}, qw(dash bash program ours) } } }
for my $q (@QRUNS) { my ($label, $dir) = $q =~ m{^([\w-]+(?:/[\w-]+)?)=(.+)\z} or die "-q $q: LABEL=DIR\n";
  my @f = glob "$dir/run-*.jsonl" or die "-q $q: no run-*.jsonl\n";
  for my $f (@f) { open my $in, '<', $f or die; while (<$in>) { my $s = eval { decode_json($_) } or next; my $c = $QC{$s->{id}}{$label} = [];
    for my $l (records($s->{ours}{rec}, qr/^[^\035\037]*\035/)) { next unless $l =~ s/^perl[^\035\037]*\035//; my ($n) = split /\037/, $l;   # a program (kill)
      push @$c, $l if defined $n && $TOOL{$n} }
    for my $b (records($s->{ours}{builtins}, qr/^[^\035\036\037]*\035/)) { my ($h, undef, $l) = split /\035/, $b, 3;   # inside Perl (IP1)
      next unless $h eq 'Proc::ShellSpawn::inproc' && defined $l; my ($n) = split /\037/, $l; push @$c, $l if defined $n && $TOOL{$n} } } } }
my %BVC;   # id => label => 1 (applies), 0 (calls, none answers otherwise), 'nocall', 'unrecorded'
sub bvc_of { my $v = $BVC{$_[0]} or return '-'; my @v = values %$v;   # over the environments where ours is not as both shells
  grep($_ eq 'unrecorded', @v) ? 'not recorded (some environment)' : !grep($_ ne '1', @v) ? 'applies in every one'
    : grep($_ eq '1', @v) ? 'applies in some' : grep($_ eq '0', @v) ? 'does not apply: such calls, none answers otherwise'
    : 'does not apply: no such call' }
sub coreutils { my ($id, $label, $k) = @_; return undef unless $CALLS;
  my $calls = $QC{$id}{$label} or do { $BVC{$id}{$label} = 'unrecorded'; return undef };
  @$calls or do { $BVC{$id}{$label} = 'nocall'; return undef };
  for my $x ($k eq '=dash' ? 'bash' : $k eq '=bash' ? 'dash' : ('dash', 'bash')) {   # each shell ours differs from
    grep({ my $a = $ANS{$_}; $a && $a->{program} ne $a->{$x} && (!defined $a->{ours} || $a->{ours} eq $a->{program}) } @$calls) or do { $BVC{$id}{$label} = 0; return undef } }
  $BVC{$id}{$label} = 1; 'builtin-vs-coreutils: ours does echo, printf, test, [, kill, pwd as coreutils; the builtin of the shell it differs from answers otherwise' }

my %AGREE = map +($_ => 1), qw(same msg=dash msg=bash msg-own OURS);
my (%T1, %T2, %T3, %N, @rows, %unex, @REC, %RULEN, %BOX, %WHY, %RUL, %MANY);
my %AIC;   # -ai: id => its category; the rows the categories go to (the others stay undecided)
my %AIROW = ('AI-strict' => 'S', 'AI-values passed on unchanged' => 'A1', 'AI-values passed on split' => 'A2');
if ($AIF) { open my $in, '<:utf8', $AIF or die "$AIF: $!"; while (<$in>) { next if /^#/ || /^id\t/; chomp; my ($id, $cat) = split /\t/; $AIC{$id} = $cat } }
my %FAMS = map { m{^([\w-]+)/} ? ($1 => 1) : () } map keys %$_, values %C;
sub setups_of { my ($c, $p) = @_; sort { ($a =~ /(\d+)\z/)[0] <=> ($b =~ /(\d+)\z/)[0] } grep /^\Q$p\Es\d+\z/, keys %$c }
for my $id (sort keys %C) { my $lv = $LV{$id} or next; my $c = $C{$id}; next unless $c->{base};
  my @env = ('base', setups_of($c, ''), map { my $f = $_; (grep(defined $c->{$_}, "$f/base"), setups_of($c, "$f/")) } sort keys %FAMS);
  my $row = $lv ne 'A' ? $lv : ($CODE{$id} // '') =~ /splitglob/ ? 'A2' : ($CODE{$id} // '') =~ /passthrough/ ? 'A1' : 'A';   # the rows (LV1)
  my $ai = defined $AIC{$id} ? 1 : 0; $row = $AIROW{$AIC{$id}} // $row if $ai;   # (-ai) found by the programs: 0; by reading: 1
  $MANY{$row} = 1 if @env > 1;
  my @cl = map $c->{$_}, @env; my @nt = grep $cl[$_] ne 'timeout', 0 .. $#cl;
  my $shells = !@nt ? 'timeout' : !grep(!$AGREE{$cl[$_]}, @nt) ? 'agree' : !grep($AGREE{$cl[$_]}, @nt) ? 'differ' : 'some';
  my $oa = grep({ $cl[$_] eq 'OURS' } @nt) ? 'differs' : grep({ $AGREE{$cl[$_]} } @nt) ? 'as them' : '';
  my %side = map +({ '=dash' => 'dash', '=bash' => 'bash', neither => 'neither' }->{$cl[$_]} => 1), grep !$AGREE{$cl[$_]}, @nt;
  my $od = !%side ? '' : keys %side == 1 ? (keys %side)[0] : 'mixed (' . join('+', sort keys %side) . ')';
  my (%rules, $prop, $none, $chance, $open);
  for my $i (@nt) { my $k = $cl[$i]; next unless $k =~ /^(?:OURS|=dash|=bash|neither)\z/;
    my $bvc = coreutils($id, $env[$i], $k);   # checked wherever ours is not as both shells, whatever other rule applies
    my $mo = $MSGOUT{$id}{$env[$i]};   # the difference is (also) in messages on standard output, each shell's own prefix
    my $r = known($id, $env[$i]) // ($A4{$id}{$env[$i]} ? 'A4: outside the subset at run time (status 248)' : $k eq '=dash' ? 'A5' : defined $mo && $mo =~ /^(?:same|msg)/ ? 'messages on standard output'
      : defined $mo && $mo eq '=dash' ? 'A5' : code_or_bvc($id, $bvc));
    if (!defined $r) { $none = 1; $rules{'none'} = 1 } else { $rules{$r} = 1; $prop = 1 if $r =~ /\(proposed\)\z/;
      $chance = 1 if $r =~ /^chance:/; $open = 1 if $r =~ /^open:/ } }
  my $why = !%rules ? '-' : $none ? 'no' : $open ? 'open' : $chance ? 'chance' : $prop ? 'proposed' : 'yes';
  my @pairs = grep defined $c->{$_->[0]} && defined $c->{$_->[1]}, ['base', 'base2'], map ["$_/base", "$_/base2"], sort keys %FAMS;
  my $stable = !@pairs ? '' : grep($c->{$_->[0]} ne $c->{$_->[1]}, @pairs) ? 'unstable' : 'stable';
  my $ours = join ' / ', grep length, ($oa ? "where they agree: $oa" : ''), ($od ? "where they differ: with $od" : '');
  $T1{$row}{$shells}[$ai]++; $N{$row}[$ai]++;
  $T2{$shells}{$oa || '-'}{$od || '-'}{$why}++;
  $unex{$row}++ if $why eq 'no';
  $RULEN{$_}++ for keys %rules;
  push @{$BOX{$shells eq 'timeout' ? 'timeout' : $shells eq 'agree' ? ($oa eq 'as them' ? 'all' : 'OURS') : $od}}, $id;
  $WHY{$id} = $why; $RUL{$id} = [sort keys %rules];
  push @rows, join "\t", $id, $lv, scalar(@env), $shells, $oa || '-', $od || '-', $why, join(' | ', sort keys %rules) || '-', $stable || '-',
    join(' ', map "$env[$_]:$cl[$_]", 0 .. $#env), $CALLS ? bvc_of($id) : ()
    unless $shells eq 'agree' && $oa eq 'as them';   # -o: every sample but those where all three agree everywhere
  if (defined $DEPS{''}{$id}) { my @s = map $c->{$_}, setups_of($c, ''); my $b = $cl[0];   # the step-2 record (its own environments)
    my %with = map +($_ => 1), qw(same msg=dash msg=bash msg-own =dash =bash);   # ours on the side of a shell (or both)
    my $o = !grep($_ ne $b, @s) ? 'unchanged' : grep({ $_ ne $b && !$with{$_} } @s) ? 'neither' : 'changed';
    push @REC, join "\t", $id, ($BLK{''}{$id} // 1) > 1 ? 'several' : 'one', $o, $b, $c->{base2} // '-', join(' ', @s), $DEPS{''}{$id} // '', join(' || ', @{$DOES{''}{$id} // []}) } }

# The rows (LV1, the user, 2026-11-13): almost strict apart from the samples that are so only by step 3's assumptions,
# passthrough (A1) and passthrough with splitglob (A2; none needs splitglob alone), which the user trusts less.
my %LN = (S => 'strict', H => 'held', A => 'almost strict', A1 => 'with values passed on unchanged, not in preceding rows',
  A2 => 'with values passed on split, not in preceding rows', P => 'partially decided', U => 'undecided (the rest)');
my %SHN = (agree => 'dash and bash agree', some => 'agree in some environments', differ => 'agree in none', timeout => 'timeout');
my @SH = qw(agree some differ timeout);
print "Snippets by level (rows) and whether dash and bash agree beyond the messages (columns), over the environments each ran in:\n";
printf "| %-54s | %13s | %s |\n", 'level', 'samples', join ' | ', map sprintf('%13s', $SHN{$_}), @SH;
sub pm { my $v = $_[0] // []; my ($p, $a) = ($v->[0] // 0, $v->[1] // 0); $a ? sprintf('%s+%s=%s', fmtn($p), fmtn($a), fmtn($p + $a)) : fmtn($p) }   # N+M=T, or N
for my $l (grep $N{$_}, qw(S H A A1 A2 P U)) { printf "| %-54s | %13s | %s |\n", $LN{$l}, pm($N{$l}), join ' | ',   # some: only where it ran in
  map { $_ eq 'some' && !$MANY{$l} ? sprintf('%13s', 'N/A') : sprintf('%13s', pm($T1{$l}{$_})) } @SH }   # several environments
print "N+M=T: N found by the programs (the parse trees, step 3's rules), M classified by reading (AI-...), T both.\n" if $AIF;

# The two trees (post-0.11, the user's layout, 2026-11-11): every sample in one box by the match; the columns by
# builtin-vs-coreutils; tree 2 splits each box by legalization.  Then the totals, the commands, the rulings, the rest.
my ($TB, $EB, $VB) = ("\x{251C}\x{2500}\x{2500} ", "\x{2514}\x{2500}\x{2500} ", "\x{2502}");
my @SUP = ("\x{00B9}", "\x{00B2}", "\x{00B3}", "\x{2074}", "\x{2075}", "\x{2076}", "\x{2077}", "\x{2078}", "\x{2079}");
my $WD = 62;
sub fmtn { my $x = reverse shift; $x =~ s/(\d{3})(?=\d)/$1,/g; scalar reverse $x }
sub anycall { my $q = $QC{$_[0]} or return 0; grep @$_, values %$q }   # one of the six commands, in some environment
sub col { !$CALLS ? 1 : !anycall($_[0]) ? 1 : bvc_of($_[0]) eq 'applies in every one' ? 0 : 2 }
sub cols { my @c = (0, 0, 0); $c[col($_)]++ for @{$_[0]}; \@c }
sub row { my ($t, $c) = @_; return $t unless $c; $t . (' ' x ($WD - length $t > 0 ? $WD - length $t : 1)) . sprintf('%9s  %9s  %4s', map fmtn($_), @$c) }
sub short { my $r = shift; return 'A5 + messages' if $r =~ /^A5, and messages/; return 'messages' if $r =~ /^messages/;
  return 'rule E' if $r =~ /^rule E/; return 'the runner' if $r =~ /^the runner/; return 'builtin-vs-coreutils' if $r =~ /^builtin-vs/;
  return 'Q2' if $r =~ /^Q2/; (my $x = $r) =~ s/:.*//s; $x }
sub cat_of { my $w = $WHY{$_[0]}; $w eq 'yes' ? 'L' : $w eq 'proposed' ? 'P' : $w eq 'chance' ? 'C' : 'N' }
my (@FN, @OUT);
sub catlabel { my ($k, $ids) = @_;
  if ($k eq 'L') { my %n; for my $id (@$ids) { my %u = map +(short($_) => 1), @{$RUL{$id}}; $n{$_}++ for keys %u }
    my @r = sort { $n{$b} <=> $n{$a} || $a cmp $b } keys %n; return "legalized by the ruling $r[0]" if @r == 1;
    push @FN, join(', ', map "$_ $n{$_}", @r) . '.'; return 'legalized by rulings' . $SUP[$#FN] }
  return '~ with HOME empty: awaiting A12' if $k eq 'P' && !grep { !grep /^~ with HOME empty/, @{$RUL{$_}} } @$ids;
  return 'awaiting a decision (a proposed rule)' if $k eq 'P';
  return 'chance' if $k eq 'C';
  my $o = grep $WHY{$_} eq 'open', @$ids; 'not legalized' . ($o ? " ($o already in TODO)" : '') }
sub box { my ($pre, $branch, $nw, $label, $ids, $sub) = @_;
  my %g; push @{$g{cat_of($_)}}, $_ for @$ids; my @c = map [$_, $g{$_}], grep $g{$_}, qw(L P C N);
  my $head = $pre . $branch . sprintf("%${nw}s", fmtn(scalar @$ids)) . "  $label";
  my $kp = $pre . ($branch eq $TB ? "$VB   " : '    ') . (' ' x ($nw + 2));
  if ($sub && @c == 1) { my $cl = catlabel(@{$c[0]}); my $l = "$head: $cl";
    if (length $l < $WD) { push @OUT, row($l, cols($ids)) } else { push @OUT, row($head, cols($ids)), "$kp   $cl" } return $kp }
  push @OUT, row($head, cols($ids)); return $kp unless $sub && @c > 1;
  my $w = length fmtn(scalar @{$c[0][1]}); $w < length fmtn(scalar @{$_->[1]}) and $w = length fmtn(scalar @{$_->[1]}) for @c;
  for my $i (0 .. $#c) { push @OUT, row($kp . ($i == $#c ? $EB : $TB) . sprintf("%${w}s", fmtn(scalar @{$c[$i][1]})) . '  ' . catlabel(@{$c[$i]}), cols($c[$i][1])) }
  $kp }
my %MIX = ('mixed (bash+dash)' => 'ours = dash in some, = bash in others', 'mixed (dash+neither)' => "ours = dash in some, \x{2260} both in others",
  'mixed (bash+neither)' => "ours = bash in some, \x{2260} both in others", 'mixed (bash+dash+neither)' => "ours = dash, = bash, \x{2260} both, by environment");
my @REST = map @{$BOX{$_} // []}, grep !/^(?:all|timeout)\z/, keys %BOX;   # ours is not as both shells somewhere
for my $sub (0, 1) { @OUT = (); @FN = ('');   # $FN[0]: the note on the 38,773 ($SUP[0])
  my $total = 0; $total += @$_ for values %BOX;
  push @OUT, fmtn($total) . '  all snippets the parser accepts; each run by dash, bash and ours', $VB,
    row($VB, ["\x{2260}coreutil", "\x{00AC}coreutil", 'rest']);
  push @OUT, $TB . sprintf('%6s', fmtn(scalar @{$BOX{all} // []})) . "  ours = dash = bash, in every environment$SUP[0]";
  box('', $TB, 6, 'timeout', $BOX{timeout} // [], 0);   # nothing to legalize
  box('', $TB, 6, "dash = bash; ours \x{2260} them", $BOX{OURS} // [], $sub);
  my @d = map @{$BOX{$_} // []}, grep /^(?:dash|bash|neither|mixed)/, keys %BOX;
  push @OUT, row($EB . sprintf('%6s', fmtn(scalar @d)) . "  dash \x{2260} bash, in some or all environments");
  my @mk = grep @{$BOX{$_} // []}, 'mixed (bash+dash)', 'mixed (dash+neither)', 'mixed (bash+neither)', 'mixed (bash+dash+neither)'; my @mix = map @{$BOX{$_}}, @mk;
  my @l2 = grep @{$_->[1]}, (['ours = dash', $BOX{dash} // []], ['ours = bash', $BOX{bash} // []], ["ours \x{2260} dash, ours \x{2260} bash", $BOX{neither} // []],
    ['depends on the environment', \@mix]);
  for my $i (0 .. $#l2) { my $kp = box('     ', $i == $#l2 ? $EB : $TB, 5, @{$l2[$i]}, $l2[$i][0] =~ /^depends/ ? 0 : $sub);
    next unless $l2[$i][0] =~ /^depends/;
    for my $j (0 .. $#mk) { box($kp, $j == $#mk ? $EB : $TB, 1, $MIX{$mk[$j]}, $BOX{$mk[$j]}, $sub) } }
  push @OUT, (' ' x $WD) . join('  ', "\x{2500}" x 9, "\x{2500}" x 9, "\x{2500}" x 4),
    row('', cols([@REST, @{$BOX{timeout} // []}]));
  print "\nTree ", $sub + 1, ":\n", map("$_\n", @OUT), "$SUP[0] Their commands were not recorded: nothing in them needs a reason.\n";
  print map("$SUP[$_] $FN[$_]\n", 1 .. $#FN) if $sub }
{ my %t; $t{cat_of($_)}++ for @REST; my $o = grep $WHY{$_} eq 'open', @REST;
  printf "\nThe %s where ours is not as both shells: legalized by rulings %s, awaiting A12 %s, chance %s, not legalized %s (%d already in TODO).\n",
    fmtn(scalar @REST), map(fmtn($t{$_} // 0), qw(L P C N)), $o }
if ($CALLS) { my (%k, %sn);   # the commands those samples run, each run alone four ways
  for my $id (@REST) { for my $c (values %{$QC{$id} // {}}) { for (@$c) { $k{$_} = 1; $sn{$id} = 1 } } }
  my %cl; my ($msg, $oe, $n) = (0, 0, 0);
  open my $in, '<', $CALLS or die; while (<$in>) { my $r = decode_json($_); my $key = join "\037", @{$r->{call}}; next unless $k{$key}; $n++;
    my $c = { same => 'coreutils = dash = bash', 'messages only' => 'coreutils = dash = bash', 'bash=program, dash differs' => "coreutils = bash \x{2260} dash",
      'dash=program, bash differs' => "coreutils = dash \x{2260} bash", 'all three differ' => "coreutils \x{2260} dash \x{2260} bash \x{2260} coreutils",
      'dash=bash, program differs' => "coreutils \x{2260} dash = bash" }->{$r->{class}}; $cl{$c}++; $msg++ if $r->{class} eq 'messages only';
    $oe++ if $r->{ours} && $r->{ours}{status} eq $r->{program}{status} && $r->{ours}{out} eq $r->{program}{out} }
  my @s = map col($_), keys %sn; my ($a0, $a2) = (scalar(grep $_ == 0, @s), scalar(grep $_ == 2, @s));
  print "\nThe commands (each run alone by coreutils, dash's builtin, bash's builtin and ours; status and output):\n";
  printf "%-40s %3d%s\n", $_, $cl{$_} // 0, $_ eq 'coreutils = dash = bash' && $msg ? "   ($msg of them differ only in the wording of messages)" : ''
    for 'coreutils = dash = bash', "coreutils = bash \x{2260} dash", "coreutils = dash \x{2260} bash", "coreutils \x{2260} dash \x{2260} bash \x{2260} coreutils", "coreutils \x{2260} dash = bash";
  printf "%-40s %3s\n%-40s %3d   %s\n", '', "\x{2500}" x 3, "run by $a0 + $a2 snippets", $n, $oe == $n ? 'ALL: ours = coreutils' : "ours = coreutils: $oe" }
{ my %n; for my $id (@REST) { my %u = map +(short($_) => 1), grep !/^(?:chance:|open:|none\z)|\(proposed\)\z/, @{$RUL{$id}}; $n{$_}++ for keys %u }
  print "\nThe rulings, by how many snippets each legalizes (a snippet may need more than one):\n",
    map sprintf("| %-22s | %5s |\n", $_, fmtn($n{$_})), sort { $n{$b} <=> $n{$a} || $a cmp $b } keys %n }
print "\nNot legalized:\n", map { (my $t = $TXT{$_} // '') =~ s/\n/ \x{23CE} /g; sprintf "  %s%s\t%s\n", $_, $WHY{$_} eq 'open' ? ' (TODO)' : '', substr($t, 0, 100) }
  sort grep { cat_of($_) eq 'N' } @REST;
if ($CALLS) { my %n; $n{bvc_of($_)}++ for keys %BVC;
  print "\nbuiltin-vs-coreutils, checked wherever ours is not as both shells (whatever other rule applies):\n",
    map sprintf("| %5d | %s |\n", $n{$_}, $_), sort keys %n }
if ($RECOUT) { open my $o, '>:utf8', $RECOUT or die; print $o $STEP3 ? head3() : (), <<'H', map "$_\n", @REC }
# large-subset-env-setups.tsv (X27, step 2; 2026-11-10): every undecided sample whose comparison may depend only on files,
# variables, standard input, arguments, the directory cd goes to, or HOME, each named exactly by the text (the partially
# decided), with its class in each environment it ran in; written by large-subset-matchreport.pl -record from the runs of
# large-subset-runcompare.pl -setup (all with -env tmp,random,mtime).  How it was made and what it says:
# large-subset-environment.md, sections 10 and 11.  Columns (tab): id; blocks (one: a single command carries the undecided
# codes; several); outcome (unchanged: the same class in every setup as in base; changed: another class in some setup,
# ours still with dash, bash or both; neither: in some setup ours agreed with neither shell or a shell timed out, where
# it did not in base); the class (large-subset-state.md, section 7) in base and in base2 (the same environment again);
# the classes in setups 1, 2, ... (3 for one dependence; 9 for two, every combination; 3 + 3m for m more, each alone);
# the dependences (CODE:KIND:NAME, as large-subset-blocks.pl -d); what each setup did (in order, joined by " || ").
H
if ($OUT) { open my $o, '>:utf8', $OUT or die; print $o <<'H', map "$_\n", @rows }
# The match of each sample across the environments it ran in (large-subset-matchreport.pl; large-subset-environment.md,
# section 11).  Columns (tab): id; level (S strict, H held, A almost strict, P partially decided, U undecided);
# environments (the base run, its setups, step 3's base runs and setups); shells (agree, some, differ, timeout: beyond the messages); ours where the
# shells agree (as them, differs); ours where they differ (dash, bash, neither, mixed); why (yes, proposed, chance, open, no, -); the
# rules found; stable (base and base2 alike) or unstable; the class in each environment; builtin-vs-coreutils, checked in
# every environment where ours is not as both shells, whatever other rule applies (applies in every one, in some, does
# not apply: such calls but none answers otherwise, or no such call; - where there is nothing to check).  Messages count
# nowhere (post-0.11: also not on standard output or in files; large-subset-match-raw.md has the former comparison).
H
sub head3 { my $c = $CLASS // 'control'; my $env = $c eq 'control' ? 'cowroot,tmp,random,mtime' : 'cowroot,tmp,random,mtime,samearg0,pidns,clock';
  return <<"H3" }
# large-subset-env-$c.tsv (X27, step 3; post-0.11, 2026-11-12): the undecided samples of step 3's class $c
# (large-subset-step3.tsv), run in example setups by large-subset-runcompare.pl -setup, every run in a root of its own
# (-env $env), the programs the step-3 record names as stand-ins, the programs' answer as one more
# dependence (large-subset-setups.pl -step3 -class $c); written by large-subset-matchreport.pl -step3 -record.  What it
# says: large-subset-environment.md, section 12.  The columns as in large-subset-env-setups.tsv, below:
H3
