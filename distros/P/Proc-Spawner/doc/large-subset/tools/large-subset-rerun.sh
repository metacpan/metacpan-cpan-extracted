#!/bin/sh
# large-subset-rerun.sh (post-0.13, 2026-11-22): run some corpus samples again in every environment that the match
# (make corpus-match; large-subset-environment.md, section 11) counts them in, and match them, without a full corpus-all.
#
# Usage (as root, from the distribution's directory, after make and make corpus-parse; see
# large-subset-review.md, section 1):
#   sh doc/large-subset/tools/large-subset-rerun.sh IDS OUT [CORPUS]
# IDS: the sample IDs, one per line.  OUT: a new directory.  CORPUS: the work directory of make (default corpus-work),
# which must hold samples.jsonl and samples.tsv.
#
# What it does, as doc/corpus.mk does for all samples: the base run (corpus-run's environment); the dependences and
# setups of step 2 and of step 3 (classes control and affects-shell), made for the whole corpus as large-subset-setups.pl
# makes them, so that each setup's number is the one of a full run; the runs of the samples of IDS in each of those setups
# (-only), in the environments corpus-step2, corpus-step3 and corpus-step3-class give them; then
# large-subset-matchreport.pl over these runs: OUT/match.tsv (the columns of large-subset-match.tsv, for the samples of
# IDS) and OUT/match.txt.  large-subset-envs.pl OUT/match.tsv OUT lists, for each sample, every environment where
# ShellSpawn is not as both shells, with what the setup did and what each shell gave.
# Not done: the runs with -q and the threeway check (builtin-vs-coreutils, the last column of match.tsv; it reads "-"
# or "no such call" here), the races' 20 runs, the end modes.  About 4 seconds per sample.
set -e
IDS=$1; OUT=$2; C=${3:-corpus-work}
test -n "$IDS" && test -n "$OUT" || { echo "usage: $0 IDS OUT [CORPUS]" >&2; exit 2; }
CT=doc/large-subset/tools; CS="$C/samples.jsonl $C/samples.tsv"; CSTEP3=$CT/large-subset-step3.tsv
RUN="unshare -n perl $CT/large-subset-runcompare.pl"
E1="-env tmp,random,mtime -base /runcompare"; E3="-env cowroot,tmp,random,mtime -base /runcompare"
EA="-env cowroot,tmp,random,mtime,samearg0,pidns -base /runcompare"
mkdir -p $OUT/step2 $OUT/step3 $OUT/step3-affects-shell
$RUN -j 4 $E1 -only @$IDS $CS $OUT/base
perl -Ilib $CT/large-subset-blocks.pl -d $OUT/step2/deps.jsonl $CS > /dev/null
perl -Ilib $CT/large-subset-setups.pl -all -full 2 -one $OUT/step2/deps.jsonl $OUT/step2/setup
perl -Ilib $CT/large-subset-setups.pl -all -full 2 -one -step3 $CSTEP3 $OUT/step2/deps.jsonl $OUT/step3/setup
perl -Ilib $CT/large-subset-setups.pl -all -full 2 -one -step3 $CSTEP3 -class affects-shell $OUT/step2/deps.jsonl \
  $OUT/step3-affects-shell/setup
grep -v '^#' $OUT/step2/setup-samples.tsv | cut -f1 | grep -Fx -f $IDS > $OUT/step2/setup.ids || true
if test -s $OUT/step2/setup.ids; then
  for r in base base2; do $RUN $E1 -only @$OUT/step2/setup.ids $CS $OUT/step2/$r; done; fi
k=1; while test -e $OUT/step2/setup-$k.jsonl; do
  $RUN $E1 -only @$IDS -setup $OUT/step2/setup-$k.jsonl $CS $OUT/step2/s$k; k=`expr $k + 1`; done
for f in step3:"$E3" step3-affects-shell:"$EA"; do D=$OUT/${f%%:*}; E=${f#*:}
  for r in base base2; do $RUN $E -only @$IDS -setup $D/setup-0.jsonl $CS $D/$r; done
  k=1; while test -e $D/setup-$k.jsonl; do $RUN $E -only @$IDS -setup $D/setup-$k.jsonl $CS $D/s$k; k=`expr $k + 1`; done
done
R="-run base=$OUT/base"; test -d $OUT/step2/base && R="$R -run base=$OUT/step2/base -run base2=$OUT/step2/base2"
k=1; while test -d $OUT/step2/s$k; do R="$R -run s$k=$OUT/step2/s$k"; k=`expr $k + 1`; done
S=; for f in control:step3 affects-shell:step3-affects-shell; do F=${f%%:*}; D=$OUT/${f#*:}
  S="$S -setups $F=$D/setup-samples.tsv"; R="$R -run $F/base=$D/base -run $F/base2=$D/base2"
  k=1; while test -d $D/s$k; do R="$R -run $F/s$k=$D/s$k"; k=`expr $k + 1`; done; done
perl $CT/large-subset-matchreport.pl -prov doc/large-subset/large-subset-provenance.tsv \
  -setups $OUT/step2/setup-samples.tsv $S -known $CT/large-subset-match-known.tsv -ai $CT/large-subset-ai-classes.tsv \
  -o $OUT/match.tsv $R > $OUT/match.txt
echo "$OUT/match.tsv: `grep -vc '^#' $OUT/match.tsv` samples"
