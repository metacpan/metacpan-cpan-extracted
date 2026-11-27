#!/bin/sh
# large-subset-rereport.sh (post-0.13): the reports and records of stored corpus runs made again with the tools of this
# tree, without running any shell: the report commands of doc/corpus.mk, in its order (make corpus-rereport).  For a
# change of a report tool or of a list a report reads (large-subset-match-known.tsv, -ai-classes.tsv), and for a
# collection of Proc-Spawner-results unpacked into CORPUS.  The records the runs themselves write stay as they are:
# large-subset-threeway-db.jsonl, -threeway-differences.tsv and the three *-calls.jsonl (make corpus-threeway,
# corpus-step3, corpus-match run again for those).  Afterwards: make corpus-stamp (large-subset-tables-used.tsv).
#
# Usage, from the distribution's directory, after make, as root (unshare -n): sh doc/large-subset/tools/large-subset-rereport.sh [CORPUS]
set -e
CORPUS=${1:-corpus-work}; PERL=${PERL:-perl}
CT=doc/large-subset/tools; CPROV=doc/large-subset/large-subset-provenance.tsv
CSTEP3=$CT/large-subset-step3.tsv; CAI=$CT/large-subset-ai-classes.tsv; CSAMPLES="$CORPUS/samples.jsonl $CORPUS/samples.tsv"
KNOWN=$CT/large-subset-match-known.tsv
test -f $CPROV || { echo "$0: run it from the distribution's directory" >&2; exit 2; }
test -f $CORPUS/samples.tsv && test -d $CORPUS/run || { echo "$0: $CORPUS holds no corpus runs" >&2; exit 2; }

echo "== corpus-provenance (blocks.pl -e and -p from the texts) and corpus-calls"
$PERL -Ilib $CT/large-subset-blocks.pl -e $CPROV -p $CSTEP3 -ai $CAI -s $CORPUS/levels.tsv -o $CORPUS/blocks.jsonl $CSAMPLES > $CORPUS/levels.txt
$PERL $CT/large-subset-calls.pl $CPROV $CORPUS/run

echo "== corpus-runreport"
$PERL $CT/large-subset-runreport.pl -q $CORPUS/q -known $KNOWN -l $CT/large-subset-run-differences.tsv $CORPUS/run > $CORPUS/runreport.txt
$PERL $CT/large-subset-runreport.pl -x -q $CORPUS/q -known $KNOWN $CORPUS/run > $CORPUS/runreport-x.txt

echo "== corpus-builtins (-reuse: the answers the run stored, the classes computed again)"
test -f $CORPUS/builtins-run.jsonl || cp $CORPUS/builtins.jsonl $CORPUS/builtins-run.jsonl
unshare -n $PERL $CT/large-subset-builtins.pl -l $CT/large-subset-builtins-differences.tsv -reuse $CORPUS/builtins-run.jsonl \
  -db $CORPUS/builtins.jsonl $CORPUS/q > $CORPUS/builtins.txt

echo "== corpus-env-variants (the comparisons only)"
rm -f $CORPUS/env/variants.tsv
for g in base sbase; do
  if test $g = base; then vs="posix utf8 sigpipe noproc tmp random private dev"; else vs="fail output mtime"; fi
  for n in $vs; do
    $PERL $CT/large-subset-runreport.pl -b $CORPUS/env/$g -bl $CORPUS/env/variants.tsv -tag $n \
      -noise $CORPUS/env/${g}2 $CORPUS/env/v-$n > $CORPUS/env/cmp-$n.txt
  done
done
mv $CORPUS/env/variants.tsv $CT/large-subset-env-variants.tsv

echo "== corpus-step3: control (the report only; the calls' record as the run made it)"
R="-run base=$CORPUS/step3/base -run base2=$CORPUS/step3/base2"; Q="-q base=$CORPUS/step3/qbase -q base2=$CORPUS/step3/qbase"
k=1; while test -d $CORPUS/step3/s$k; do R="$R -run s$k=$CORPUS/step3/s$k"; Q="$Q -q s$k=$CORPUS/step3/qs$k"; k=$((k+1)); done
P="-step3 -prov $CPROV -setups $CORPUS/step3/setup-samples.tsv -known $KNOWN"
$PERL $CT/large-subset-matchreport.pl $P -record $CT/large-subset-env-control.tsv -calls $CT/large-subset-env-control-calls.jsonl $Q $R > $CORPUS/step3/match.txt

echo "== corpus-step3-class affects-shell (the report only)"
D=$CORPUS/step3-affects-shell; C=affects-shell
R="-run base=$D/base -run base2=$D/base2"; Q="-q base=$D/qbase -q base2=$D/qbase"
k=1; while test -d $D/s$k; do R="$R -run s$k=$D/s$k"; Q="$Q -q s$k=$D/qs$k"; k=$((k+1)); done
P="-step3 -class $C -prov $CPROV -setups $D/setup-samples.tsv -known $KNOWN"
$PERL $CT/large-subset-matchreport.pl $P -o $D/match.tsv -record $CT/large-subset-env-$C.tsv -calls $CT/large-subset-env-$C-calls.jsonl $Q $R > $D/match.txt

echo "== corpus-races (the report only)"
D=$CORPUS/races; A=; for d in $D/r*/*; do test -d "$d" || continue; A="$A ${d##*/}=$d"; done
$PERL $CT/large-subset-repeat.pl -v -o $CT/large-subset-env-races.tsv $A > $D/repeat.txt

echo "== corpus-endmodes (the report only)"
D=$CORPUS/endmodes; A=; for m in shell all none; do r=1; while test -d $D/$m/r$r; do A="$A $m=$D/$m/r$r"; r=$((r+1)); done; done
$PERL $CT/large-subset-repeat.pl -v -o $CT/large-subset-endmodes.tsv $A > $D/repeat.txt

echo "== corpus-match (the reports only; the calls' record as the run made it)"
R="-run base=$CORPUS/run -run base=$CORPUS/step2/base -run base2=$CORPUS/step2/base2"
Q="-q base=$CORPUS/match/qbase -q base2=$CORPUS/match/qbase"; k=1
while test -d $CORPUS/step2/s$k; do R="$R -run s$k=$CORPUS/step2/s$k"; Q="$Q -q s$k=$CORPUS/match/qs$k"; k=$((k+1)); done
S=; for f in control:step3 affects-shell:step3-affects-shell; do F=${f%%:*}; D=$CORPUS/${f#*:}
  S="$S -setups $F=$D/setup-samples.tsv"
  R="$R -run $F/base=$D/base -run $F/base2=$D/base2"; Q="$Q -q $F/base=$D/qbase -q $F/base2=$D/qbase"; k=1
  while test -d $D/s$k; do R="$R -run $F/s$k=$D/s$k"; test -d $D/qs$k && Q="$Q -q $F/s$k=$D/qs$k"; k=$((k+1)); done; done
P="-prov $CPROV -setups $CORPUS/step2/setup-samples.tsv $S -known $KNOWN -ai $CAI"
$PERL $CT/large-subset-matchreport.pl $P -o $CT/large-subset-match.tsv -calls $CT/large-subset-match-calls.jsonl $Q $R > $CORPUS/match.txt
$PERL $CT/large-subset-matchreport.pl $P -raw -record $CT/large-subset-env-setups.tsv -calls $CT/large-subset-match-calls.jsonl $Q $R > $CORPUS/match-raw.txt
echo "== done: the records in $CT; then make corpus-stamp"
